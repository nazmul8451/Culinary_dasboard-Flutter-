import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { buyer, seller, courier }

enum UserStatus { active, banned, suspended }

enum VerificationStatus { pending, verified, rejected }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserType userType;
  final UserStatus status;
  final VerificationStatus? verificationStatus;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastActive;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    required this.status,
    this.verificationStatus,
    this.profileImage,
    required this.createdAt,
    this.lastActive,
    this.metadata,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      userType: _parseUserType(data['userType']),
      status: _parseUserStatus(data['status']),
      verificationStatus: data['verificationStatus'] != null
          ? _parseVerificationStatus(data['verificationStatus'])
          : null,
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.name,
      'status': status.name,
      'verificationStatus': verificationStatus?.name,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'metadata': metadata,
    };
  }

  static UserType _parseUserType(dynamic value) {
    if (value is String) {
      return UserType.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => UserType.buyer,
      );
    }
    return UserType.buyer;
  }

  static UserStatus _parseUserStatus(dynamic value) {
    if (value is String) {
      return UserStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => UserStatus.active,
      );
    }
    return UserStatus.active;
  }

  static VerificationStatus _parseVerificationStatus(dynamic value) {
    if (value is String) {
      return VerificationStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => VerificationStatus.pending,
      );
    }
    return VerificationStatus.pending;
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    UserStatus? status,
    VerificationStatus? verificationStatus,
    String? profileImage,
    DateTime? lastActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
