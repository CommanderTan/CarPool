import 'package:flutter/foundation.dart';

import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../services/api_service.dart';

class RideProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<RideModel> _availableRides = [];
  List<RideModel> _myRides = [];
  List<RideRequestModel> _rideRequests = [];
  RideModel? _currentRide;
  bool _isLoading = false;
  String? _errorMessage;

  List<RideModel> get availableRides => _availableRides;
  List<RideModel> get myRides => _myRides;
  List<RideRequestModel> get rideRequests => _rideRequests;
  RideModel? get currentRide => _currentRide;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAvailableRides({
    String? pickupLocation,
    String? dropLocation,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getAvailableRides(
        pickupLocation: pickupLocation,
        dropLocation: dropLocation,
      );
      _availableRides = data.map((json) => RideModel.fromJson(json)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch rides: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyRides(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getUserRides(userId);
      _myRides = data.map((json) => RideModel.fromJson(json)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch your rides: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRide(Map<String, dynamic> rideData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.createRide(rideData);
      final newRide = RideModel.fromJson(data);
      _myRides.insert(0, newRide);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create ride: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestRide(String rideId, String passengerId, int seats) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.requestRide(rideId, passengerId, seats);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to request ride: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideRequests(String rideId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getRideRequests(rideId);
      _rideRequests = data
          .map((json) => RideRequestModel.fromJson(json))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch ride requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToRequest(String requestId, bool accept) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.respondToRideRequest(requestId, accept);
      await fetchRideRequests(_rideRequests.first.rideId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to respond to request: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRide(String rideId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.cancelRide(rideId);
      _myRides.removeWhere((ride) => ride.id == rideId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel ride: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
