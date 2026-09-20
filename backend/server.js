'use strict';

const http = require('node:http');
const { randomUUID } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const XLSX = require('@e965/xlsx');

const port = Number(process.env.PORT || 3000);
const dataPath = process.env.CAR_POOL_DATA_PATH || path.join(__dirname, 'data.json');
const excelFilePath = path.join(__dirname, 'allowed_prns.xlsx');

const emptyStore = () => ({
  users: {},
  rides: [],
  rideRequests: [],
  reviews: [],
  reports: [],
});

// Helper function to read student records from Excel
function getStudentsFromExcel() {
  if (!fs.existsSync(excelFilePath)) return [];
  try {
    const workbook = XLSX.readFile(excelFilePath);
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
  const temporaryPath = `${dataPath}.tmp`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(store, null, 2)}\n`);
  fs.renameSync(temporaryPath, dataPath);
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  response.end(JSON.stringify(body));
}

function sendError(response, statusCode, message) {
  sendJson(response, statusCode, { error: message });
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.setEncoding('utf8');
    request.on('data', (chunk) => {
      body += chunk;
      if (body.length > 1024 * 1024) {
        reject(new Error('Request body is too large.'));
        request.destroy();
      }
    });
    request.on('end', () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (_) {
        reject(new Error('Request body must be valid JSON.'));
      }
    });
    request.on('error', reject);
  });
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
    pickupLocation: input.pickupLocation.trim(),
    dropLocation: input.dropLocation.trim(),
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
  return !query || location.toLowerCase().includes(query.toLowerCase());
}

function calculateFare(pickupLocation, dropLocation) {
  const route = `${pickupLocation.trim().toLowerCase()}-${dropLocation.trim().toLowerCase()}`;
  const score = [...route].reduce((total, character) => total + character.charCodeAt(0), 0);
  return 30 + (score % 8) * 10;
}

async function handleRequest(request, response) {
  if (request.method === 'OPTIONS') return sendJson(response, 204, {});

  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  const { pathname, searchParams } = url;
  const store = readStore();

  if (request.method === 'GET' && (pathname === '/api' || pathname === '/api/' || pathname === '/api/health')) {
    return sendJson(response, 200, {
      status: 'ok',
      service: 'Car Pool local development API',
      rides: store.rides.length,
    });
  }

  // Student verification route (verifies against allowed_prns.xlsx)
  if (request.method === 'POST' && (pathname === '/api/auth/verify-student' || pathname === '/api/verify-student')) {
    const body = await readJsonBody(request);
    const { prn, rollNum } = body;

    if (!prn && !rollNum) {
      return sendError(response, 400, 'Please provide either a PRN or Roll Number.');
    }

    const allowedStudents = getStudentsFromExcel();
    if (allowedStudents.length === 0) {
      return sendError(response, 500, 'Database error: allowed_prns.xlsx file missing or empty.');
    }

    const studentRecord = allowedStudents.find((student) => {
      const matchPrn = prn && String(student.prn).trim().toUpperCase() === String(prn).trim().toUpperCase();
      const matchRoll = rollNum && String(student.rollNum).trim() === String(rollNum).trim();
      return matchPrn || matchRoll;
    });

    if (!studentRecord) {
      return sendError(response, 403, 'Access denied. Details not found in official college records.');
    }

    const isRegistered =
      studentRecord.isRegistered === true ||
      String(studentRecord.isRegistered).toLowerCase() === 'true';

    if (isRegistered) {
      return sendError(response, 400, 'This student account is already registered. Please login.');
    }

    return sendJson(response, 200, {
      verified: true,
      message: 'Student record verified successfully!',
      data: {
        prn: String(studentRecord.prn),
        rollNum: Number(studentRecord.rollNum),
      },
    });
  }

  if (request.method === 'POST' && pathname === '/api/users') {
    const body = await readJsonBody(request);
    if (!hasText(body.id) || !hasText(body.name) || !hasText(body.email) || !isValidDate(body.dateOfBirth)) {
      return sendError(response, 400, 'id, name, email, and dateOfBirth are required.');
    }
    const user = { ...body, id: body.id, updatedAt: new Date().toISOString() };
    store.users[user.id] = { ...store.users[user.id], ...user };
    writeStore(store);
    return sendJson(response, 201, store.users[user.id]);
  }

  const userMatch = pathname.match(/^\/api\/users\/([^/]+)$/);
  if (userMatch) {
    const userId = decodeURIComponent(userMatch[1]);
    if (request.method === 'GET') {
      const user = store.users[userId];
      return user ? sendJson(response, 200, user) : sendError(response, 404, 'User not found.');
    }
    if (request.method === 'PUT') {
      if (!store.users[userId]) return sendError(response, 404, 'User not found.');
      const body = await readJsonBody(request);
      store.users[userId] = {
        ...store.users[userId],
        ...body,
        id: userId,
        updatedAt: new Date().toISOString(),
      };
      writeStore(store);
      return sendJson(response, 200, store.users[userId]);
    }
  }

  if (request.method === 'GET' && pathname === '/api/rides/available') {
    const pickup = searchParams.get('pickup');
    const drop = searchParams.get('drop');
    const rides = store.rides.filter((ride) =>
      ride.availableSeats > 0 &&
      !['cancelled', 'completed'].includes(ride.status) &&
      matchesLocation(ride.pickupLocation, pickup) &&
      matchesLocation(ride.dropLocation, drop),
    );
    return sendJson(response, 200, rides);
  }

  const userRidesMatch = pathname.match(/^\/api\/rides\/user\/([^/]+)$/);
  if (request.method === 'GET' && userRidesMatch) {
    const userId = decodeURIComponent(userRidesMatch[1]);
    return sendJson(response, 200, store.rides.filter((ride) =>
      ride.driverId === userId || ride.passengerIds.includes(userId),
    ));
  }

  if (request.method === 'POST' && pathname === '/api/rides') {
    const body = await readJsonBody(request);
    const ride = normalizeRide(body);
    const validationError = validateRide(ride);
    if (validationError) return sendError(response, 400, validationError);
    store.rides.unshift(ride);
    writeStore(store);
    return sendJson(response, 201, ride);
  }

  const rideRequestMatch = pathname.match(/^\/api\/rides\/([^/]+)\/request$/);
  if (request.method === 'POST' && rideRequestMatch) {
    const rideId = decodeURIComponent(rideRequestMatch[1]);
    const ride = store.rides.find((candidate) => candidate.id === rideId);
    if (!ride || ['cancelled', 'completed'].includes(ride.status)) {
      return sendError(response, 404, 'Ride not available.');
    }
    const body = await readJsonBody(request);
    const seatsRequested = Number(body.seatsRequested);
    if (!hasText(body.passengerId) || !Number.isInteger(seatsRequested) || seatsRequested < 1) {
      return sendError(response, 400, 'A passenger and valid seat count are required.');
    }
    if (body.passengerId === ride.driverId) return sendError(response, 400, 'Drivers cannot request their own ride.');
    if (store.rideRequests.some((item) => item.rideId === rideId && item.passengerId === body.passengerId && item.status === 'pending')) {
      return sendError(response, 409, 'A pending request already exists for this ride.');
    }
    const passenger = store.users[body.passengerId];
    const rideRequest = {
      id: randomUUID(),
      rideId,
      passengerId: body.passengerId,
      passengerName: passenger?.name || 'Passenger',
      passengerPhotoUrl: passenger?.profilePictureUrl || null,
      seatsRequested,
      status: 'pending',
      createdAt: new Date().toISOString(),
      message: typeof body.message === 'string' ? body.message : null,
    };
    store.rideRequests.unshift(rideRequest);
    writeStore(store);
    return sendJson(response, 201, rideRequest);
  }

  const rideRequestsMatch = pathname.match(/^\/api\/rides\/([^/]+)\/requests$/);
  if (request.method === 'GET' && rideRequestsMatch) {
    const rideId = decodeURIComponent(rideRequestsMatch[1]);
    return sendJson(response, 200, store.rideRequests.filter((rideRequest) => rideRequest.rideId === rideId));
  }

  const cancelRideMatch = pathname.match(/^\/api\/rides\/([^/]+)\/cancel$/);
  if (request.method === 'PUT' && cancelRideMatch) {
    const rideId = decodeURIComponent(cancelRideMatch[1]);
    const ride = store.rides.find((candidate) => candidate.id === rideId);
    if (!ride) return sendError(response, 404, 'Ride not found.');
    ride.status = 'cancelled';
    store.rideRequests.forEach((rideRequest) => {
      if (rideRequest.rideId === rideId && rideRequest.status === 'pending') rideRequest.status = 'cancelled';
    });
    writeStore(store);
    return sendJson(response, 200, ride);
  }

  const historyMatch = pathname.match(/^\/api\/rides\/history\/([^/]+)$/);
  if (request.method === 'GET' && historyMatch) {
    const userId = decodeURIComponent(historyMatch[1]);
    const rides = store.rides.filter((ride) =>
      (ride.driverId === userId || ride.passengerIds.includes(userId)) &&
      ['completed', 'cancelled'].includes(ride.status),
    );
    return sendJson(response, 200, rides);
  }

  const requestMatch = pathname.match(/^\/api\/requests\/([^/]+)$/);
  if (request.method === 'PUT' && requestMatch) {
    const requestId = decodeURIComponent(requestMatch[1]);
    const rideRequest = store.rideRequests.find((candidate) => candidate.id === requestId);
    if (!rideRequest) return sendError(response, 404, 'Ride request not found.');
    const body = await readJsonBody(request);
    if (!['accepted', 'rejected'].includes(body.status)) {
      return sendError(response, 400, 'Status must be accepted or rejected.');
    }
    const ride = store.rides.find((candidate) => candidate.id === rideRequest.rideId);
    if (!ride) return sendError(response, 404, 'Ride not found.');
    if (body.status === 'accepted' && ride.availableSeats < rideRequest.seatsRequested) {
      return sendError(response, 409, 'Not enough available seats.');
    }
    if (rideRequest.status === 'pending' && body.status === 'accepted') {
      ride.availableSeats -= rideRequest.seatsRequested;
      if (!ride.passengerIds.includes(rideRequest.passengerId)) ride.passengerIds.push(rideRequest.passengerId);
      ride.status = 'accepted';
    }
    rideRequest.status = body.status;
    writeStore(store);
    return sendJson(response, 200, rideRequest);
  }

  if (request.method === 'POST' && pathname === '/api/rides/calculate-fare') {
    const body = await readJsonBody(request);
    if (!hasText(body.pickupLocation) || !hasText(body.dropLocation)) {
      return sendError(response, 400, 'Pickup and drop locations are required.');
    }
    return sendJson(response, 200, {
      recommendedFare: calculateFare(body.pickupLocation, body.dropLocation),
      currency: 'INR',
      mode: 'local-development',
    });
  }

  if (request.method === 'POST' && pathname === '/api/reviews') {
    const body = await readJsonBody(request);
    const review = { id: randomUUID(), ...body, createdAt: body.createdAt || new Date().toISOString() };
    store.reviews.unshift(review);
    writeStore(store);
    return sendJson(response, 201, review);
  }

  if (request.method === 'POST' && pathname === '/api/reports') {
    const body = await readJsonBody(request);
    const report = { id: randomUUID(), ...body, createdAt: body.createdAt || new Date().toISOString() };
    store.reports.unshift(report);
    writeStore(store);
    return sendJson(response, 201, report);
  }

  return sendError(response, 404, `No route matches ${request.method} ${pathname}`);
}

const server = http.createServer((request, response) => {
  handleRequest(request, response).catch((error) => {
    console.error(error);
    sendError(response, 400, error.message || 'Unable to process the request.');
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Car Pool local API listening on http://localhost:${port}/api`);
});

function stopServer() {
  server.close(() => process.exit(0));
}

process.on('SIGINT', stopServer);
process.on('SIGTERM', stopServer);