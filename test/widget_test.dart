// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:car_pool/models/ride_model.dart';
import 'package:car_pool/models/ride_request_model.dart';
import 'package:car_pool/models/user_model.dart';

void main() {
  group('RideModel', () {
    test('round-trips a ride without losing its important fields', () {
      final ride = RideModel(
        id: 'ride-42',
        driverId: 'driver-1',
        driverName: 'Aarav',
        pickupLocation: 'College Gate',
        dropLocation: 'Railway Station',
        pickupLat: 18.5204,
        pickupLng: 73.8567,
        dropLat: 18.5280,
        dropLng: 73.8740,
        rideDate: DateTime.utc(2026, 9, 10, 9),
        totalSeats: 4,
        availableSeats: 2,
        farePerSeat: 55.0,
        status: RideStatus.accepted,
        passengerIds: const ['passenger-1', 'passenger-2'],
        createdAt: DateTime.utc(2026, 9, 9),
        vehicleNumber: 'MH 12 AB 1234',
        vehicleModel: 'Swift',
      );

      final restored = RideModel.fromJson(ride.toJson());

      expect(restored.id, ride.id);
      expect(restored.status, RideStatus.accepted);
      expect(restored.availableSeats, 2);
      expect(restored.passengerIds, ride.passengerIds);
      expect(restored.vehicleNumber, 'MH 12 AB 1234');
    });

    test('uses pending when an API response contains an unknown status', () {
      final ride = RideModel.fromJson({
        'rideDate': '2026-09-10T09:00:00.000Z',
        'createdAt': '2026-09-09T00:00:00.000Z',
        'status': 'unexpected-status',
      });

      expect(ride.status, RideStatus.pending);
    });
  });

  group('UserModel and RideRequestModel', () {
    test('serializes user updates and request status correctly', () {
      final user = UserModel(
        id: 'user-1',
        name: 'Maya',
        email: 'maya@example.com',
        dateOfBirth: DateTime.utc(2004, 5, 18),
        division: 'B',
        department: 'Computer Engineering',
        prn: 'PRN-101',
        mobileNumber: '9876543210',
        createdAt: DateTime.utc(2026, 9, 1),
      ).copyWith(rating: 4.5, totalRides: 8);

      final request = RideRequestModel.fromJson({
        'id': 'request-9',
        'rideId': 'ride-42',
        'passengerId': user.id,
        'passengerName': user.name,
        'seatsRequested': 1,
        'status': 'accepted',
        'createdAt': '2026-09-10T08:00:00.000Z',
      });

      expect(UserModel.fromJson(user.toJson()).rating, 4.5);
      expect(UserModel.fromJson(user.toJson()).totalRides, 8);
      expect(request.status, RequestStatus.accepted);
      expect(request.toJson()['seatsRequested'], 1);
    });
  });
}
