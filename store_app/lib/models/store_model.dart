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
    if (!doc.exists) {
      throw Exception('Store document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Store document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> storeData = data as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: storeData['name'] ?? '',
      address: storeData['address'] ?? '',
      city: storeData['city'] ?? '',
      phone: storeData['phone'] ?? '',
      email: storeData['email'] ?? '',
      managerId: storeData['managerId'] ?? '',
      isActive: storeData['isActive'] ?? true,
      createdAt: (storeData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
