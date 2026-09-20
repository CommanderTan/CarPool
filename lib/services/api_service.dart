import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static const Duration _timeout = Duration(seconds: 10);
  final http.Client _client = http.Client();

  Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> verifyStudent(String prn, DateTime dateOfBirth) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/verify-student'),
        headers: _getHeaders(),
        body: jsonEncode({
          'prn': prn,
          'dateOfBirth': dateOfBirth.toIso8601String(),
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Student verification failed: $e');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
        body: jsonEncode(userData),
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Create user failed: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch user profile');
    } catch (e) {
      throw Exception('Get user profile failed: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  Future<List<dynamic>> getAvailableRides({
    String? pickupLocation,
    String? dropLocation,
  }) async {
    try {
      var url = '$baseUrl/rides/available';
      final queryParams = <String, String>{};

      if (pickupLocation != null) queryParams['pickup'] = pickupLocation;
      if (dropLocation != null) queryParams['drop'] = dropLocation;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to fetch rides');
    } catch (e) {
      throw Exception('Get available rides failed: $e');
    }
  }

  Future<List<dynamic>> getUserRides(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/rides/user/$userId'),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to fetch user rides');
    } catch (e) {
      throw Exception('Get user rides failed: $e');
    }
  }

  Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rides'),
        headers: _getHeaders(),
        body: jsonEncode(rideData),
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create ride');
    } catch (e) {
      throw Exception('Create ride failed: $e');
    }
  }

  Future<void> requestRide(String rideId, String passengerId, int seats) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rides/$rideId/request'),
        headers: _getHeaders(),
        body: jsonEncode({
          'passengerId': passengerId,
          'seatsRequested': seats,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        throw Exception('Failed to request ride');
      }
    } catch (e) {
      throw Exception('Request ride failed: $e');
    }
  }

  Future<List<dynamic>> getRideRequests(String rideId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/rides/$rideId/requests'),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to fetch ride requests');
    } catch (e) {
      throw Exception('Get ride requests failed: $e');
    }
  }

  Future<void> respondToRideRequest(String requestId, bool accept) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/requests/$requestId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': accept ? 'accepted' : 'rejected',
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to respond to request');
      }
    } catch (e) {
      throw Exception('Respond to request failed: $e');
    }
  }

  Future<void> cancelRide(String rideId) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/rides/$rideId/cancel'),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel ride');
      }
    } catch (e) {
      throw Exception('Cancel ride failed: $e');
    }
  }

  Future<List<dynamic>> getRideHistory(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/rides/history/$userId'),
        headers: _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to fetch ride history');
    } catch (e) {
      throw Exception('Get ride history failed: $e');
    }
  }

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/reviews'),
        headers: _getHeaders(),
        body: jsonEncode(reviewData),
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      throw Exception('Submit review failed: $e');
    }
  }

  Future<void> reportUser(Map<String, dynamic> reportData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/reports'),
        headers: _getHeaders(),
        body: jsonEncode(reportData),
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      throw Exception('Submit report failed: $e');
    }
  }

  Future<double> getSmartFare(String pickupLocation, String dropLocation) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rides/calculate-fare'),
        headers: _getHeaders(),
        body: jsonEncode({
          'pickupLocation': pickupLocation,
          'dropLocation': dropLocation,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['recommendedFare'] ?? 0.0).toDouble();
      }
      throw Exception('Failed to calculate fare');
    } catch (e) {
      throw Exception('Get smart fare failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
