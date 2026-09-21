import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone; // unique identifier
  final String? email;
  final String? address;
  final DateTime registeredAt;
  final String registeredStoreId;
  final String registeredByUserId;
  final bool isActive;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.registeredAt,
    required this.registeredStoreId,
    required this.registeredByUserId,
    this.isActive = true,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      registeredAt:
          (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registeredStoreId: data['registeredStoreId'] ?? '',
      registeredByUserId: data['registeredByUserId'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredStoreId': registeredStoreId,
      'registeredByUserId': registeredByUserId,
      'isActive': isActive,
    };
  }

  CustomerModel copyWith({
    String? name,
    String? email,
    String? address,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      address: address ?? this.address,
      registeredAt: registeredAt,
      registeredStoreId: registeredStoreId,
      registeredByUserId: registeredByUserId,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Loyalty account — one per mobile number (shared across family)
class LoyaltyAccount {
  final String id; // same as customer phone
  final String primaryCustomerId;
  final String phone;
  final int totalPoints;
  final int redeemedPoints;
  final int availablePoints;
  final DateTime createdAt;
  final DateTime lastActivity;

  const LoyaltyAccount({
    required this.id,
    required this.primaryCustomerId,
    required this.phone,
    required this.totalPoints,
    required this.redeemedPoints,
    required this.availablePoints,
    required this.createdAt,
    required this.lastActivity,
  });

  factory LoyaltyAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyAccount(
      id: doc.id,
      primaryCustomerId: data['primaryCustomerId'] ?? '',
      phone: data['phone'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      redeemedPoints: data['redeemedPoints'] ?? 0,
      availablePoints: data['availablePoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity:
          (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'primaryCustomerId': primaryCustomerId,
      'phone': phone,
      'totalPoints': totalPoints,
      'redeemedPoints': redeemedPoints,
      'availablePoints': availablePoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
    };
  }
}

class LoyaltyTransaction {
  final String id;
  final String loyaltyAccountId;
  final String phone;
  final String? customerId;
  final String? customerName;
  final LoyaltyTransactionType type;
  final int points;
  final String? saleId;
  final String storeId;
  final String storeName;
  final String processedByUserId;
  final String processedByUserName;
  final DateTime timestamp;
  final String? notes;

  const LoyaltyTransaction({
    required this.id,
    required this.loyaltyAccountId,
    required this.phone,
    this.customerId,
    this.customerName,
    required this.type,
    required this.points,
    this.saleId,
    required this.storeId,
    required this.storeName,
    required this.processedByUserId,
    required this.processedByUserName,
    required this.timestamp,
    this.notes,
  });

  factory LoyaltyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyTransaction(
      id: doc.id,
      loyaltyAccountId: data['loyaltyAccountId'] ?? '',
      phone: data['phone'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'],
      type: LoyaltyTransactionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'earn'),
        orElse: () => LoyaltyTransactionType.earn,
      ),
      points: data['points'] ?? 0,
      saleId: data['saleId'],
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      processedByUserId: data['processedByUserId'] ?? '',
      processedByUserName: data['processedByUserName'] ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'loyaltyAccountId': loyaltyAccountId,
      'phone': phone,
      'customerId': customerId,
      'customerName': customerName,
      'type': type.name,
      'points': points,
      'saleId': saleId,
      'storeId': storeId,
      'storeName': storeName,
      'processedByUserId': processedByUserId,
      'processedByUserName': processedByUserName,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }
}

enum LoyaltyTransactionType { earn, redeem, adjust, expire }
