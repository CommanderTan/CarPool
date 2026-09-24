class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final DateTime dateOfBirth;
  final String division;
  final String department;
  final String prn;
  final String rollNumber;
  final String mobileNumber;
  final double rating;
  final int totalRides;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    required this.dateOfBirth,
    required this.division,
    required this.department,
    required this.prn,
    this.rollNumber = '',
    required this.mobileNumber,
    this.rating = 0.0,
    this.totalRides = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      division: json['division'] ?? '',
      department: json['department'] ?? '',
      prn: json['prn'] ?? '',
      rollNumber: json['rollNumber']?.toString() ?? json['rollNum']?.toString() ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'division': division,
      'department': department,
      'prn': prn,
      'rollNumber': rollNumber,
      'mobileNumber': mobileNumber,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePictureUrl,
    DateTime? dateOfBirth,
    String? division,
    String? department,
    String? prn,
    String? rollNumber,
    String? mobileNumber,
    double? rating,
    int? totalRides,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      division: division ?? this.division,
      department: department ?? this.department,
      prn: prn ?? this.prn,
      rollNumber: rollNumber ?? this.rollNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

