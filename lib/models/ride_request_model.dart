class RideRequestModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String? passengerPhotoUrl;
  final int seatsRequested;
  final RequestStatus status;
  final DateTime createdAt;
  final String? message;

  RideRequestModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    this.passengerPhotoUrl,
    required this.seatsRequested,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      passengerPhotoUrl: json['passengerPhotoUrl'],
      seatsRequested: json['seatsRequested'] ?? 1,
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhotoUrl': passengerPhotoUrl,
      'seatsRequested': seatsRequested,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
    };
  }
}

enum RequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}
