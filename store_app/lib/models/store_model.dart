import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String managerId;
  final bool isActive;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.managerId,
    this.isActive = true,
    required this.createdAt,
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      managerId: data['managerId'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'managerId': managerId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  StoreModel copyWith({
    String? name,
    String? address,
    String? city,
    String? phone,
    String? email,
    String? managerId,
    bool? isActive,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      managerId: managerId ?? this.managerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
