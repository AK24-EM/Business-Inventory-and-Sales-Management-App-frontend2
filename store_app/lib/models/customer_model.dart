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
    if (!doc.exists) {
      throw Exception('Customer document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Customer document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> customerData = data as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: customerData['name'] ?? '',
      phone: customerData['phone'] ?? '',
      email: customerData['email'],
      address: customerData['address'],
      registeredAt:
          (customerData['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registeredStoreId: customerData['registeredStoreId'] ?? '',
      registeredByUserId: customerData['registeredByUserId'] ?? '',
      isActive: customerData['isActive'] ?? true,
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
    if (!doc.exists) {
      throw Exception('Loyalty account document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Loyalty account document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> loyaltyData = data as Map<String, dynamic>;
    return LoyaltyAccount(
      id: doc.id,
      primaryCustomerId: loyaltyData['primaryCustomerId'] ?? '',
      phone: loyaltyData['phone'] ?? '',
      totalPoints: loyaltyData['totalPoints'] ?? 0,
      redeemedPoints: loyaltyData['redeemedPoints'] ?? 0,
      availablePoints: loyaltyData['availablePoints'] ?? 0,
      createdAt: (loyaltyData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity:
          (loyaltyData['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    if (!doc.exists) {
      throw Exception('Loyalty transaction document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Loyalty transaction document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> txData = data as Map<String, dynamic>;
    return LoyaltyTransaction(
      id: doc.id,
      loyaltyAccountId: txData['loyaltyAccountId'] ?? '',
      phone: txData['phone'] ?? '',
      customerId: txData['customerId'],
      customerName: txData['customerName'],
      type: LoyaltyTransactionType.values.firstWhere(
        (e) => e.name == (txData['type'] ?? 'earn'),
        orElse: () => LoyaltyTransactionType.earn,
      ),
      points: txData['points'] ?? 0,
      saleId: txData['saleId'],
      storeId: txData['storeId'] ?? '',
      storeName: txData['storeName'] ?? '',
      processedByUserId: txData['processedByUserId'] ?? '',
      processedByUserName: txData['processedByUserName'] ?? '',
      timestamp:
          (txData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: txData['notes'],
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
