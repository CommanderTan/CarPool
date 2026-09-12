class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String? driverPhotoUrl;
  final String pickupLocation;
  final String dropLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final DateTime rideDate;
  final int totalSeats;
  final int availableSeats;
  final double farePerSeat;
  final RideStatus status;
  final List<String> passengerIds;
  final DateTime createdAt;
  final String? vehicleNumber;
  final String? vehicleModel;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhotoUrl,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.rideDate,
    required this.totalSeats,
    required this.availableSeats,
    required this.farePerSeat,
    required this.status,
    required this.passengerIds,
    required this.createdAt,
    this.vehicleNumber,
    this.vehicleModel,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhotoUrl: json['driverPhotoUrl'],
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0.0).toDouble(),
      dropLat: (json['dropLat'] ?? 0.0).toDouble(),
      dropLng: (json['dropLng'] ?? 0.0).toDouble(),
      rideDate: DateTime.parse(json['rideDate']),
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      farePerSeat: (json['farePerSeat'] ?? 0.0).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RideStatus.pending,
      ),
      passengerIds: List<String>.from(json['passengerIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      vehicleNumber: json['vehicleNumber'],
      vehicleModel: json['vehicleModel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhotoUrl': driverPhotoUrl,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'rideDate': rideDate.toIso8601String(),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'farePerSeat': farePerSeat,
      'status': status.toString().split('.').last,
      'passengerIds': passengerIds,
      'createdAt': createdAt.toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
    };
  }
}

enum RideStatus {
  pending,
  accepted,
  ongoing,
  completed,
  cancelled,
}
