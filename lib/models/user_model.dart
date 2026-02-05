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
  final VerificationStatus? idVerificationStatus;
  final VerificationStatus? facialVerificationStatus;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastActive;
  final DateTime? trialStartDate;
  final String? businessLocation;
  final double? costPerKg;
  final double? minShippingFee;
  final Map<String, dynamic>? shippingRules;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    required this.status,
    this.verificationStatus,
    this.idVerificationStatus,
    this.facialVerificationStatus,
    this.profileImage,
    required this.createdAt,
    this.lastActive,
    this.trialStartDate,
    this.businessLocation,
    this.costPerKg,
    this.minShippingFee,
    this.shippingRules,
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
      idVerificationStatus: data['idVerificationStatus'] != null
          ? _parseVerificationStatus(data['idVerificationStatus'])
          : null,
      facialVerificationStatus: data['facialVerificationStatus'] != null
          ? _parseVerificationStatus(data['facialVerificationStatus'])
          : null,
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      trialStartDate: (data['trialStartDate'] as Timestamp?)?.toDate(),
      businessLocation: data['businessLocation'],
      costPerKg: (data['costPerKg'] ?? 0.0).toDouble(),
      minShippingFee: (data['minShippingFee'] ?? 0.0).toDouble(),
      shippingRules: data['shippingRules'] != null
          ? Map<String, dynamic>.from(data['shippingRules'] as Map)
          : null,
      metadata: data['metadata'],
    );
  }

  factory UserModel.fromRealtimeDatabase(
    String id,
    Map<dynamic, dynamic> data,
  ) {
    return UserModel(
      id: id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString(),
      userType: _parseUserType(data['userType']),
      status: _parseUserStatus(data['status']),
      verificationStatus: data['verificationStatus'] != null
          ? _parseVerificationStatus(data['verificationStatus'])
          : null,
      idVerificationStatus: data['idVerificationStatus'] != null
          ? _parseVerificationStatus(data['idVerificationStatus'])
          : null,
      facialVerificationStatus: data['facialVerificationStatus'] != null
          ? _parseVerificationStatus(data['facialVerificationStatus'])
          : null,
      profileImage: data['profileImage']?.toString(),
      createdAt: _parseDateTime(data['createdAt']),
      lastActive: _parseDateTime(data['lastActive'], isOptional: true),
      trialStartDate: _parseDateTime(data['trialStartDate'], isOptional: true),
      businessLocation: data['businessLocation']?.toString(),
      costPerKg: (data['costPerKg'] ?? 0.0).toDouble(),
      minShippingFee: (data['minShippingFee'] ?? 0.0).toDouble(),
      shippingRules: data['shippingRules'] != null
          ? Map<String, dynamic>.from(data['shippingRules'] as Map)
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
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
      'idVerificationStatus': idVerificationStatus?.name,
      'facialVerificationStatus': facialVerificationStatus?.name,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'trialStartDate': trialStartDate != null
          ? Timestamp.fromDate(trialStartDate!)
          : null,
      'businessLocation': businessLocation,
      'costPerKg': costPerKg,
      'minShippingFee': minShippingFee,
      'shippingRules': shippingRules,
      'metadata': metadata,
    };
  }

  static DateTime _parseDateTime(dynamic value, {bool isOptional = false}) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
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
    VerificationStatus? idVerificationStatus,
    VerificationStatus? facialVerificationStatus,
    String? profileImage,
    DateTime? lastActive,
    DateTime? trialStartDate,
    String? businessLocation,
    double? costPerKg,
    double? minShippingFee,
    Map<String, dynamic>? shippingRules,
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
      idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
      facialVerificationStatus:
          facialVerificationStatus ?? this.facialVerificationStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      businessLocation: businessLocation ?? this.businessLocation,
      costPerKg: costPerKg ?? this.costPerKg,
      minShippingFee: minShippingFee ?? this.minShippingFee,
      shippingRules: shippingRules ?? this.shippingRules,
      metadata: metadata ?? this.metadata,
    );
  }
}
