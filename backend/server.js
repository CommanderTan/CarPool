'use strict';

const express = require('express');
const cors = require('cors');
const { randomUUID } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const XLSX = require('@e965/xlsx');
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');

const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

const dataPath = process.env.CAR_POOL_DATA_PATH || path.join(__dirname, 'data.json');
const excelFilePath = path.join(__dirname, 'allowed_prns.xlsx');
const rootExcelFilePath = path.join(__dirname, '..', 'students.xlsx');

// Initialize Firebase Admin SDK
let db = null;
try {
  if (getApps().length === 0) {
    const serviceAccountPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(__dirname, '..', 'serviceAccountKey.json');

    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      initializeApp({
        credential: cert(serviceAccount),
      });
      console.log('Firebase Admin initialized using serviceAccountKey.json');
    } else {
      initializeApp();
      console.log('Firebase Admin initialized using default credentials');
    }
  }
  db = getFirestore();
} catch (err) {
  console.error('Failed to initialize Firebase Admin SDK:', err.message);
}

const emptyStore = () => ({
  users: {},
  rides: [],
  rideRequests: [],
  reviews: [],
  reports: [],
});

function getStudentsFromExcel() {
  const targetFile = fs.existsSync(excelFilePath)
    ? excelFilePath
    : fs.existsSync(rootExcelFilePath)
    ? rootExcelFilePath
    : null;

  if (!targetFile) return [];
  try {
    const workbook = XLSX.readFile(targetFile);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    return XLSX.utils.sheet_to_json(worksheet);
  } catch (err) {
    console.error('Error reading Excel whitelist:', err.message);
    return [];
  }
}

function readStore() {
  if (!fs.existsSync(dataPath)) return emptyStore();
  try {
    const parsed = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    return {
      ...emptyStore(),
      ...parsed,
      users: parsed.users || {},
      rides: parsed.rides || [],
      rideRequests: parsed.rideRequests || [],
      reviews: parsed.reviews || [],
      reports: parsed.reports || [],
    };
  } catch (error) {
    console.error('Unable to read local API data:', error.message);
    return emptyStore();
  }
}

function writeStore(store) {
  try {
    const temporaryPath = `${dataPath}.tmp`;
    fs.writeFileSync(temporaryPath, `${JSON.stringify(store, null, 2)}\n`);
    fs.renameSync(temporaryPath, dataPath);
  } catch (err) {
    console.error('Failed to write local store:', err.message);
  }
}

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isValidDate(value) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value));
}

function normalizeRide(input) {
  return {
    id: input.id || randomUUID(),
    driverId: input.driverId,
    driverName: input.driverName,
    driverPhotoUrl: input.driverPhotoUrl || null,
    pickupLocation: (input.pickupLocation || '').trim(),
    dropLocation: (input.dropLocation || '').trim(),
    pickupLat: Number(input.pickupLat) || 0,
    pickupLng: Number(input.pickupLng) || 0,
    dropLat: Number(input.dropLat) || 0,
    dropLng: Number(input.dropLng) || 0,
    rideDate: input.rideDate,
    totalSeats: Number(input.totalSeats),
    availableSeats: Number(input.availableSeats ?? input.totalSeats),
    farePerSeat: Number(input.farePerSeat),
    status: input.status || 'pending',
    passengerIds: Array.isArray(input.passengerIds) ? input.passengerIds : [],
    createdAt: input.createdAt || new Date().toISOString(),
    vehicleNumber: input.vehicleNumber || null,
    vehicleModel: input.vehicleModel || null,
  };
}

function validateRide(ride) {
  if (!hasText(ride.driverId) || !hasText(ride.driverName)) {
    return 'A driver is required to create a ride.';
  }
  if (!hasText(ride.pickupLocation) || !hasText(ride.dropLocation)) {
    return 'Pickup and drop locations are required.';
  }
  if (!isValidDate(ride.rideDate)) return 'A valid ride date is required.';
  if (!Number.isInteger(ride.totalSeats) || ride.totalSeats < 1) {
    return 'Total seats must be at least one.';
  }
  if (!Number.isInteger(ride.availableSeats) || ride.availableSeats < 0 || ride.availableSeats > ride.totalSeats) {
    return 'Available seats must be between zero and total seats.';
  }
  if (!Number.isFinite(ride.farePerSeat) || ride.farePerSeat < 0) {
    return 'Fare per seat must be zero or more.';
  }
  return null;
}

function matchesLocation(location, query) {
  if (!location) return false;
  return !query || location.toLowerCase().includes(query.toLowerCase());
}

function calculateFare(pickupLocation, dropLocation) {
  const route = `${pickupLocation.trim().toLowerCase()}-${dropLocation.trim().toLowerCase()}`;
  const score = [...route].reduce((total, character) => total + character.charCodeAt(0), 0);
  return 30 + (score % 8) * 10;
}

// Health check endpoint
app.get(['/api', '/api/', '/api/health'], async (req, res) => {
  let dbStatus = 'disconnected';
  let ridesCount = 0;
  if (db) {
    try {
      const snap = await db.collection('rides').get();
      ridesCount = snap.size;
      dbStatus = 'connected (Cloud Firestore)';
    } catch (e) {
      dbStatus = `error: ${e.message}`;
    }
  } else {
    const store = readStore();
    ridesCount = store.rides.length;
    dbStatus = 'local-fallback (JSON)';
  }

  res.json({
    status: 'ok',
    service: 'Car Pool Firebase API',
    database: dbStatus,
    rides: ridesCount,
  });
});

// Student verification endpoint
const verifyStudentHandler = async (req, res) => {
  const { prn, rollNum, rollNumber } = req.body || {};
  const inputRoll = rollNum || rollNumber;

  if (!prn && !inputRoll) {
    return res.status(400).json({ error: 'Please provide either a PRN or Roll Number.' });
  }

  const searchPrn = prn ? String(prn).trim().toUpperCase() : null;
  const searchRoll = inputRoll ? String(inputRoll).trim() : null;

  // 1. Query Cloud Firestore
  if (db && searchPrn) {
    try {
      const docRef = db.collection('students').doc(searchPrn);
      const docSnap = await docRef.get();

      if (docSnap.exists) {
        const studentData = docSnap.data();

        // Cross-check Roll Number if both PRN and Roll Number are provided
        if (searchRoll && studentData.rollNum) {
          if (String(studentData.rollNum).trim() !== searchRoll) {
            return res.status(400).json({ error: 'Roll Number does not match official college records for this PRN.' });
          }
        }

        const isRegistered =
          studentData.isRegistered === true ||
          String(studentData.isRegistered).toLowerCase() === 'true';

        if (isRegistered) {
          return res.status(400).json({ error: 'This student account is already registered. Please login.' });
        }

        return res.json({
          verified: true,
          message: 'Student record verified successfully via Cloud Firestore!',
          data: {
            prn: studentData.prn || searchPrn,
            rollNum: studentData.rollNum || (searchRoll ? Number(searchRoll) : null),
            rollNumber: studentData.rollNum ? String(studentData.rollNum) : searchRoll,
          },
        });
      }
    } catch (err) {
      console.error('Firestore verify student error:', err.message);
    }
  }

  // 2. Fallback to Excel whitelist
  const allowedStudents = getStudentsFromExcel();
  if (allowedStudents.length === 0) {
    return res.status(500).json({ error: 'Database error: Student whitelist not found or empty.' });
  }

  const studentRecord = allowedStudents.find((student) => {
    const matchPrn = searchPrn && String(student.prn).trim().toUpperCase() === searchPrn;
    const matchRoll = searchRoll && String(student.rollNum).trim() === searchRoll;
    if (searchPrn && searchRoll) {
      return matchPrn && matchRoll;
    }
    return matchPrn || matchRoll;
  });

  if (!studentRecord) {
    return res.status(403).json({ error: 'Access denied. Details not found in official college records.' });
  }

  const isRegistered =
    studentRecord.isRegistered === true ||
    String(studentRecord.isRegistered).toLowerCase() === 'true';

  if (isRegistered) {
    return res.status(400).json({ error: 'This student account is already registered. Please login.' });
  }

  return res.json({
    verified: true,
    message: 'Student record verified successfully!',
    data: {
      prn: String(studentRecord.prn),
      rollNum: Number(studentRecord.rollNum),
      rollNumber: String(studentRecord.rollNum),
    },
  });
};

app.post('/api/auth/verify-student', verifyStudentHandler);
app.post('/api/verify-student', verifyStudentHandler);

// User Profile management
app.post('/api/users', async (req, res) => {
  const body = req.body || {};
  if (!hasText(body.id) || !hasText(body.name) || !hasText(body.email) || !isValidDate(body.dateOfBirth)) {
    return res.status(400).json({ error: 'id, name, email, and dateOfBirth are required.' });
  }

  const rollVal = body.rollNumber || body.rollNum || '';

  const user = {
    ...body,
    id: body.id,
    rollNumber: rollVal,
    rollNum: rollVal,
    updatedAt: new Date().toISOString(),
  };

  if (db) {
    try {
      await db.collection('users').doc(user.id).set(user, { merge: true });
      if (user.prn) {
        const prnUpper = String(user.prn).trim().toUpperCase();
        await db.collection('students').doc(prnUpper).set({ isRegistered: true }, { merge: true });
      }
      return res.status(201).json(user);
    } catch (err) {
      console.error('Firestore create user error:', err.message);
    }
  }

  const store = readStore();
  store.users[user.id] = { ...store.users[user.id], ...user };
  writeStore(store);
  return res.status(201).json(store.users[user.id]);
});


app.get('/api/users/:id', async (req, res) => {
  const userId = req.params.id;
  if (db) {
    try {
      const docSnap = await db.collection('users').doc(userId).get();
      if (docSnap.exists) {
        return res.json(docSnap.data());
      }
    } catch (err) {
      console.error('Firestore get user error:', err.message);
    }
  }

  const store = readStore();
  const user = store.users[userId];
  return user ? res.json(user) : res.status(404).json({ error: 'User not found.' });
});

app.put('/api/users/:id', async (req, res) => {
  const userId = req.params.id;
  const updates = { ...req.body, id: userId, updatedAt: new Date().toISOString() };

  if (db) {
    try {
      await db.collection('users').doc(userId).set(updates, { merge: true });
      const docSnap = await db.collection('users').doc(userId).get();
      return res.json(docSnap.data());
    } catch (err) {
      console.error('Firestore update user error:', err.message);
    }
  }

  const store = readStore();
  if (!store.users[userId]) return res.status(404).json({ error: 'User not found.' });
  store.users[userId] = { ...store.users[userId], ...updates };
  writeStore(store);
  return res.json(store.users[userId]);
});

// Ride management
app.get('/api/rides/available', async (req, res) => {
  const pickup = req.query.pickup;
  const drop = req.query.drop;

  if (db) {
    try {
      const snapshot = await db.collection('rides').get();
      const rides = [];
      snapshot.forEach((doc) => {
        const ride = doc.data();
        if (
          ride.availableSeats > 0 &&
          !['cancelled', 'completed'].includes(ride.status) &&
          matchesLocation(ride.pickupLocation, pickup) &&
          matchesLocation(ride.dropLocation, drop)
        ) {
          rides.push(ride);
        }
      });
      return res.json(rides);
    } catch (err) {
      console.error('Firestore get available rides error:', err.message);
    }
  }

  const store = readStore();
  const rides = store.rides.filter(
    (ride) =>
      ride.availableSeats > 0 &&
      !['cancelled', 'completed'].includes(ride.status) &&
      matchesLocation(ride.pickupLocation, pickup) &&
      matchesLocation(ride.dropLocation, drop)
  );
  return res.json(rides);
});

app.get('/api/rides/user/:userId', async (req, res) => {
  const userId = req.params.userId;
  if (db) {
    try {
      const snapshot = await db.collection('rides').get();
      const rides = [];
      snapshot.forEach((doc) => {
        const ride = doc.data();
        const passengerIds = Array.isArray(ride.passengerIds) ? ride.passengerIds : [];
        if (ride.driverId === userId || passengerIds.includes(userId)) {
          rides.push(ride);
        }
      });
      return res.json(rides);
    } catch (err) {
      console.error('Firestore get user rides error:', err.message);
    }
  }

  const store = readStore();
  return res.json(
    store.rides.filter(
      (ride) =>
        ride.driverId === userId ||
        (Array.isArray(ride.passengerIds) && ride.passengerIds.includes(userId))
    )
  );
});

app.post('/api/rides', async (req, res) => {
  const ride = normalizeRide(req.body || {});
  const validationError = validateRide(ride);
  if (validationError) return res.status(400).json({ error: validationError });

  if (db) {
    try {
      await db.collection('rides').doc(ride.id).set(ride);
      return res.status(201).json(ride);
    } catch (err) {
      console.error('Firestore create ride error:', err.message);
    }
  }

  const store = readStore();
  store.rides.unshift(ride);
  writeStore(store);
  return res.status(201).json(ride);
});

// Ride Requests
app.post('/api/rides/:id/request', async (req, res) => {
  const rideId = req.params.id;
  const { passengerId, seatsRequested, message } = req.body || {};
  const seats = Number(seatsRequested);

  if (!hasText(passengerId) || !Number.isInteger(seats) || seats < 1) {
    return res.status(400).json({ error: 'A passenger and valid seat count are required.' });
  }

  if (db) {
    try {
      const rideDoc = await db.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return res.status(404).json({ error: 'Ride not available.' });
      const ride = rideDoc.data();
      if (['cancelled', 'completed'].includes(ride.status)) {
        return res.status(404).json({ error: 'Ride not available.' });
      }
      if (passengerId === ride.driverId) {
        return res.status(400).json({ error: 'Drivers cannot request their own ride.' });
      }

      const existingSnap = await db
        .collection('rideRequests')
        .where('rideId', '==', rideId)
        .where('passengerId', '==', passengerId)
        .where('status', '==', 'pending')
        .get();

      if (!existingSnap.empty) {
        return res.status(409).json({ error: 'A pending request already exists for this ride.' });
      }

      let passengerName = 'Passenger';
      let passengerPhotoUrl = null;
      const userDoc = await db.collection('users').doc(passengerId).get();
      if (userDoc.exists) {
        const u = userDoc.data();
        passengerName = u.name || passengerName;
        passengerPhotoUrl = u.profilePictureUrl || null;
      }

      const rideRequest = {
        id: randomUUID(),
        rideId,
        passengerId,
        passengerName,
        passengerPhotoUrl,
        seatsRequested: seats,
        status: 'pending',
        createdAt: new Date().toISOString(),
        message: typeof message === 'string' ? message : null,
      };

      await db.collection('rideRequests').doc(rideRequest.id).set(rideRequest);
      return res.status(201).json(rideRequest);
    } catch (err) {
      console.error('Firestore request ride error:', err.message);
    }
  }

  const store = readStore();
  const ride = store.rides.find((candidate) => candidate.id === rideId);
  if (!ride || ['cancelled', 'completed'].includes(ride.status)) {
    return res.status(404).json({ error: 'Ride not available.' });
  }
  if (passengerId === ride.driverId) return res.status(400).json({ error: 'Drivers cannot request their own ride.' });
  if (store.rideRequests.some((item) => item.rideId === rideId && item.passengerId === passengerId && item.status === 'pending')) {
    return res.status(409).json({ error: 'A pending request already exists for this ride.' });
  }
  const passenger = store.users[passengerId];
  const rideRequest = {
    id: randomUUID(),
    rideId,
    passengerId,
    passengerName: passenger?.name || 'Passenger',
    passengerPhotoUrl: passenger?.profilePictureUrl || null,
    seatsRequested: seats,
    status: 'pending',
    createdAt: new Date().toISOString(),
    message: typeof message === 'string' ? message : null,
  };
  store.rideRequests.unshift(rideRequest);
  writeStore(store);
  return res.status(201).json(rideRequest);
});

app.get('/api/rides/:id/requests', async (req, res) => {
  const rideId = req.params.id;
  if (db) {
    try {
      const snap = await db.collection('rideRequests').where('rideId', '==', rideId).get();
      const requests = [];
      snap.forEach((doc) => requests.push(doc.data()));
      return res.json(requests);
    } catch (err) {
      console.error('Firestore get ride requests error:', err.message);
    }
  }

  const store = readStore();
  return res.json(store.rideRequests.filter((rr) => rr.rideId === rideId));
});

app.put('/api/requests/:requestId', async (req, res) => {
  const requestId = req.params.requestId;
  const { status } = req.body || {};
  if (!['accepted', 'rejected'].includes(status)) {
    return res.status(400).json({ error: 'Status must be accepted or rejected.' });
  }

  if (db) {
    try {
      const reqRef = db.collection('rideRequests').doc(requestId);
      const reqSnap = await reqRef.get();
      if (!reqSnap.exists) return res.status(404).json({ error: 'Ride request not found.' });

      const rideRequest = reqSnap.data();
      const rideRef = db.collection('rides').doc(rideRequest.rideId);
      const rideSnap = await rideRef.get();
      if (!rideSnap.exists) return res.status(404).json({ error: 'Ride not found.' });

      const ride = rideSnap.data();
      if (status === 'accepted' && ride.availableSeats < rideRequest.seatsRequested) {
        return res.status(409).json({ error: 'Not enough available seats.' });
      }

      if (rideRequest.status === 'pending' && status === 'accepted') {
        const updatedSeats = ride.availableSeats - rideRequest.seatsRequested;
        const passengerIds = Array.isArray(ride.passengerIds) ? [...ride.passengerIds] : [];
        if (!passengerIds.includes(rideRequest.passengerId)) {
          passengerIds.push(rideRequest.passengerId);
        }
        await rideRef.update({
          availableSeats: updatedSeats,
          passengerIds: passengerIds,
          status: 'accepted',
        });
      }

      await reqRef.update({ status });
      return res.json({ ...rideRequest, status });
    } catch (err) {
      console.error('Firestore respond request error:', err.message);
    }
  }

  const store = readStore();
  const rideRequest = store.rideRequests.find((candidate) => candidate.id === requestId);
  if (!rideRequest) return res.status(404).json({ error: 'Ride request not found.' });
  const ride = store.rides.find((candidate) => candidate.id === rideRequest.rideId);
  if (!ride) return res.status(404).json({ error: 'Ride not found.' });

  if (status === 'accepted' && ride.availableSeats < rideRequest.seatsRequested) {
    return res.status(409).json({ error: 'Not enough available seats.' });
  }
  if (rideRequest.status === 'pending' && status === 'accepted') {
    ride.availableSeats -= rideRequest.seatsRequested;
    if (!ride.passengerIds.includes(rideRequest.passengerId)) ride.passengerIds.push(rideRequest.passengerId);
    ride.status = 'accepted';
  }
  rideRequest.status = status;
  writeStore(store);
  return res.json(rideRequest);
});

app.put('/api/rides/:id/cancel', async (req, res) => {
  const rideId = req.params.id;

  if (db) {
    try {
      const rideRef = db.collection('rides').doc(rideId);
      const rideSnap = await rideRef.get();
      if (!rideSnap.exists) return res.status(404).json({ error: 'Ride not found.' });

      await rideRef.update({ status: 'cancelled' });
      const reqSnap = await db
        .collection('rideRequests')
        .where('rideId', '==', rideId)
        .where('status', '==', 'pending')
        .get();

      const batch = db.batch();
      reqSnap.forEach((doc) => {
        batch.update(doc.ref, { status: 'cancelled' });
      });
      await batch.commit();

      const updatedDoc = await rideRef.get();
      return res.json(updatedDoc.data());
    } catch (err) {
      console.error('Firestore cancel ride error:', err.message);
    }
  }

  const store = readStore();
  const ride = store.rides.find((candidate) => candidate.id === rideId);
  if (!ride) return res.status(404).json({ error: 'Ride not found.' });
  ride.status = 'cancelled';
  store.rideRequests.forEach((rideRequest) => {
    if (rideRequest.rideId === rideId && rideRequest.status === 'pending') rideRequest.status = 'cancelled';
  });
  writeStore(store);
  return res.json(ride);
});

app.get('/api/rides/history/:userId', async (req, res) => {
  const userId = req.params.userId;
  if (db) {
    try {
      const snapshot = await db.collection('rides').get();
      const rides = [];
      snapshot.forEach((doc) => {
        const ride = doc.data();
        const passengerIds = Array.isArray(ride.passengerIds) ? ride.passengerIds : [];
        if (
          (ride.driverId === userId || passengerIds.includes(userId)) &&
          ['completed', 'cancelled'].includes(ride.status)
        ) {
          rides.push(ride);
        }
      });
      return res.json(rides);
    } catch (err) {
      console.error('Firestore ride history error:', err.message);
    }
  }

  const store = readStore();
  const rides = store.rides.filter(
    (ride) =>
      (ride.driverId === userId ||
        (Array.isArray(ride.passengerIds) && ride.passengerIds.includes(userId))) &&
      ['completed', 'cancelled'].includes(ride.status)
  );
  return res.json(rides);
});

app.post('/api/rides/calculate-fare', (req, res) => {
  const { pickupLocation, dropLocation } = req.body || {};
  if (!hasText(pickupLocation) || !hasText(dropLocation)) {
    return res.status(400).json({ error: 'Pickup and drop locations are required.' });
  }
  return res.json({
    recommendedFare: calculateFare(pickupLocation, dropLocation),
    currency: 'INR',
    mode: 'firestore-connected',
  });
});

app.post('/api/reviews', async (req, res) => {
  const review = { id: randomUUID(), ...req.body, createdAt: req.body?.createdAt || new Date().toISOString() };
  if (db) {
    try {
      await db.collection('reviews').doc(review.id).set(review);
      return res.status(201).json(review);
    } catch (err) {
      console.error('Firestore create review error:', err.message);
    }
  }
  const store = readStore();
  store.reviews.unshift(review);
  writeStore(store);
  return res.status(201).json(review);
});

app.post('/api/reports', async (req, res) => {
  const report = { id: randomUUID(), ...req.body, createdAt: req.body?.createdAt || new Date().toISOString() };
  if (db) {
    try {
      await db.collection('reports').doc(report.id).set(report);
      return res.status(201).json(report);
    } catch (err) {
      console.error('Firestore create report error:', err.message);
    }
  }
  const store = readStore();
  store.reports.unshift(report);
  writeStore(store);
  return res.status(201).json(report);
});

exports.api = onRequest({ cors: true }, app);

if (require.main === module || !process.env.FUNCTION_TARGET) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, '0.0.0.0', () => {
    console.log(`Car Pool Firebase API listening on http://localhost:${port}/api`);
  });
}