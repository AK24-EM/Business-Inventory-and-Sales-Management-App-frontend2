import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, manager, employee, admin, customer }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Business Owner';
      case UserRole.manager:
        return 'Store Manager';
      case UserRole.employee:
        return 'Store Employee';
      case UserRole.admin:
        return 'System Administrator';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String get value {
    return name;
  }

  /// Post-login home path decided from the role returned by Firestore/GCP.
  String get homeRoute {
    switch (this) {
      case UserRole.owner:
      case UserRole.admin:
        return '/owner';
      case UserRole.manager:
        return '/manager';
      case UserRole.employee:
        return '/employee';
      case UserRole.customer:
        return '/customer';
    }
  }

  /// Roles the owner may assign (never self-registered).
  bool get isOwnerAssignable =>
      this == UserRole.manager || this == UserRole.employee;

  bool get isStaff =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.employee;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.employee,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? assignedStoreId; // null for owner/admin
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedStoreId,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.fcmToken,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isEmployee => role == UserRole.employee;
  bool get isAdmin => role == UserRole.admin;
  bool get isCustomer => role == UserRole.customer;
  bool get canAccessAllStores => role == UserRole.owner || role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'employee'),
      assignedStoreId: data['assignedStoreId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'assignedStoreId': assignedStoreId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? assignedStoreId,
    bool? isActive,
    DateTime? lastLogin,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedStoreId: assignedStoreId ?? this.assignedStoreId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
