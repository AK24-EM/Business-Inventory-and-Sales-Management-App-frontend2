import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/customer_model.dart';

class LoyaltyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _loyalty =>
      _db.collection(AppConstants.loyaltyAccountsCollection);
  CollectionReference<Map<String, dynamic>> get _loyaltyTx =>
      _db.collection(AppConstants.loyaltyTransactionsCollection);
  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection(AppConstants.customersCollection);

  /// Get loyalty account by phone number
  Future<LoyaltyAccount?> getLoyaltyAccount(String phone) async {
    final doc = await _loyalty.doc(phone.trim()).get();
    if (!doc.exists) return null;
    return LoyaltyAccount.fromFirestore(doc);
  }

  /// Get loyalty account stream for real-time updates
  Stream<LoyaltyAccount?> getLoyaltyAccountStream(String phone) {
    return _loyalty.doc(phone.trim()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LoyaltyAccount.fromFirestore(doc);
    });
  }

  /// Get loyalty transaction history
  Future<List<LoyaltyTransaction>> getTransactions(String phone,
      {int limit = 50}) async {
    final snap = await _loyaltyTx
        .where('phone', isEqualTo: phone.trim())
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(LoyaltyTransaction.fromFirestore).toList();
  }

  /// Get loyalty transaction stream
  Stream<List<LoyaltyTransaction>> getTransactionsStream(String phone,
      {int limit = 50}) {
    return _loyaltyTx
        .where('phone', isEqualTo: phone.trim())
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(LoyaltyTransaction.fromFirestore).toList());
  }

  /// Calculate points that can be earned for a given amount
  int calculatePointsToEarn(double amount) {
    return (amount * AppConstants.pointsPerRupee).round();
  }

  /// Calculate rupees value of loyalty points
  double calculatePointsValue(int points) {
    return points * AppConstants.pointsToRupeeValue;
  }

  /// Validate if redemption is possible
  Future<Map<String, dynamic>> validateRedemption({
    required String phone,
    required int pointsToRedeem,
    required double billAmount,
  }) async {
    final account = await getLoyaltyAccount(phone);

    if (account == null) {
      return {
        'valid': false,
        'reason': 'No loyalty account found',
      };
    }

    if (pointsToRedeem <= 0) {
      return {
        'valid': false,
        'reason': 'Points must be greater than 0',
      };
    }

    if (pointsToRedeem > account.availablePoints) {
      return {
        'valid': false,
        'reason':
            'Insufficient points. Available: ${account.availablePoints}',
      };
    }

    final redemptionValue = calculatePointsValue(pointsToRedeem);
    if (redemptionValue > billAmount) {
      return {
        'valid': false,
        'reason': 'Redemption value exceeds bill amount',
      };
    }

    // Check max redemption limit (e.g., 50% of bill)
    final maxRedeemable = billAmount * AppConstants.maxRedemptionPercentage;
    if (redemptionValue > maxRedeemable) {
      return {
        'valid': false,
        'reason':
            'Maximum ${(AppConstants.maxRedemptionPercentage * 100).toInt()}% of bill can be redeemed',
      };
    }

    return {
      'valid': true,
      'redemptionValue': redemptionValue,
      'remainingPoints': account.availablePoints - pointsToRedeem,
    };
  }

  /// Calculate maximum points that can be redeemed for a bill
  Future<int> getMaxRedeemablePoints(String phone, double billAmount) async {
    final account = await getLoyaltyAccount(phone);
    if (account == null || account.availablePoints == 0) return 0;

    // Calculate max based on bill percentage limit
    final maxRedemptionAmount = billAmount * AppConstants.maxRedemptionPercentage;
    final maxPointsByAmount =
        (maxRedemptionAmount / AppConstants.pointsToRupeeValue).floor();

    // Return the lower of: available points or max allowed by bill amount
    return maxPointsByAmount < account.availablePoints
        ? maxPointsByAmount
        : account.availablePoints;
  }

  /// Manual points adjustment (for corrections, bonuses, expirations)
  Future<void> adjustPoints({
    required String phone,
    required int pointsChange,
    required String reason,
    required String storeId,
    required String storeName,
    required String userId,
    required String userName,
  }) async {
    final account = await getLoyaltyAccount(phone);
    if (account == null) {
      throw Exception('Loyalty account not found');
    }

    final type = pointsChange >= 0
        ? LoyaltyTransactionType.adjust
        : LoyaltyTransactionType.adjust;
    final absolutePoints = pointsChange.abs();

    // Update account
    await _loyalty.doc(phone.trim()).update({
      if (pointsChange > 0) ...{
        'totalPoints': FieldValue.increment(absolutePoints),
        'availablePoints': FieldValue.increment(absolutePoints),
      } else ...{
        'redeemedPoints': FieldValue.increment(absolutePoints),
        'availablePoints': FieldValue.increment(-absolutePoints),
      },
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Record transaction
    await _loyaltyTx.add({
      'loyaltyAccountId': phone.trim(),
      'phone': phone.trim(),
      'customerId': account.primaryCustomerId,
      'customerName': null,
      'type': type.name,
      'points': absolutePoints,
      'saleId': null,
      'storeId': storeId,
      'storeName': storeName,
      'processedByUserId': userId,
      'processedByUserName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'notes': reason,
    });
  }

  /// Get loyalty statistics for analytics
  Future<Map<String, dynamic>> getLoyaltyStats({String? storeId}) async {
    // Get all loyalty accounts
    final accountsSnap = await _loyalty.get();
    final accounts =
        accountsSnap.docs.map(LoyaltyAccount.fromFirestore).toList();

    // Get transactions (optionally filtered by store)
    Query<Map<String, dynamic>> txQuery = _loyaltyTx;
    if (storeId != null) {
      txQuery = txQuery.where('storeId', isEqualTo: storeId);
    }
    final txSnap = await txQuery.get();
    final transactions =
        txSnap.docs.map(LoyaltyTransaction.fromFirestore).toList();

    final totalAccounts = accounts.length;
    final activeAccounts =
        accounts.where((a) => a.availablePoints > 0).length;
    final totalPointsIssued =
        accounts.fold<int>(0, (sum, a) => sum + a.totalPoints);
    final totalPointsRedeemed =
        accounts.fold<int>(0, (sum, a) => sum + a.redeemedPoints);
    final totalPointsAvailable =
        accounts.fold<int>(0, (sum, a) => sum + a.availablePoints);

    final earnTransactions = transactions
        .where((t) => t.type == LoyaltyTransactionType.earn)
        .length;
    final redeemTransactions = transactions
        .where((t) => t.type == LoyaltyTransactionType.redeem)
        .length;

    return {
      'totalAccounts': totalAccounts,
      'activeAccounts': activeAccounts,
      'totalPointsIssued': totalPointsIssued,
      'totalPointsRedeemed': totalPointsRedeemed,
      'totalPointsAvailable': totalPointsAvailable,
      'redemptionRate':
          totalPointsIssued > 0 ? totalPointsRedeemed / totalPointsIssued : 0,
      'earnTransactions': earnTransactions,
      'redeemTransactions': redeemTransactions,
      'avgPointsPerAccount':
          totalAccounts > 0 ? totalPointsAvailable / totalAccounts : 0,
    };
  }

  /// Search customers by phone or name
  Future<List<CustomerModel>> searchCustomers(String query,
      {String? storeId}) async {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return [];

    Query<Map<String, dynamic>> customersQuery = _customers;
    if (storeId != null) {
      customersQuery =
          customersQuery.where('registeredStoreId', isEqualTo: storeId);
    }

    final snap = await customersQuery.get();
    final customers = snap.docs.map(CustomerModel.fromFirestore).toList();

    // Filter by phone or name (client-side filtering)
    return customers.where((c) {
      return c.phone.contains(trimmedQuery) ||
          c.name.toLowerCase().contains(trimmedQuery);
    }).toList();
  }

  /// Get top customers by loyalty points
  Future<List<Map<String, dynamic>>> getTopLoyaltyCustomers(
      {int limit = 10}) async {
    final accountsSnap =
        await _loyalty.orderBy('totalPoints', descending: true).limit(limit).get();
    
    final results = <Map<String, dynamic>>[];
    
    for (final doc in accountsSnap.docs) {
      final account = LoyaltyAccount.fromFirestore(doc);
      
      // Get customer details
      CustomerModel? customer;
      if (account.primaryCustomerId.isNotEmpty) {
        final customerDoc = await _customers.doc(account.primaryCustomerId).get();
        if (customerDoc.exists) {
          customer = CustomerModel.fromFirestore(customerDoc);
        }
      }
      
      results.add({
        'account': account,
        'customer': customer,
        'phone': account.phone,
        'name': customer?.name ?? 'Unknown',
        'totalPoints': account.totalPoints,
        'availablePoints': account.availablePoints,
        'redeemedPoints': account.redeemedPoints,
      });
    }
    
    return results;
  }
}
