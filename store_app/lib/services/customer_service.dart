import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection(AppConstants.customersCollection);
  CollectionReference<Map<String, dynamic>> get _loyalty =>
      _db.collection(AppConstants.loyaltyAccountsCollection);
  CollectionReference<Map<String, dynamic>> get _loyaltyTx =>
      _db.collection(AppConstants.loyaltyTransactionsCollection);

  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    final snap = await _customers.where('phone', isEqualTo: phone.trim()).get();
    if (snap.docs.isEmpty) return null;
    return CustomerModel.fromFirestore(snap.docs.first);
  }

  Future<CustomerModel?> findByPhone(String phone) => getCustomerByPhone(phone);

  Future<LoyaltyAccount?> getLoyaltyAccount(String phone) async {
    final doc = await _loyalty.doc(phone.trim()).get();
    if (!doc.exists) return null;
    return LoyaltyAccount.fromFirestore(doc);
  }

  Future<List<CustomerModel>> getStoreCustomers(String storeId) async {
    final snap =
        await _customers.where('registeredStoreId', isEqualTo: storeId).get();
    return snap.docs.map(CustomerModel.fromFirestore).toList();
  }

  Stream<List<CustomerModel>> getCustomersStream({String? storeId}) {
    Query<Map<String, dynamic>> q = _customers;
    if (storeId != null) {
      q = q.where('registeredStoreId', isEqualTo: storeId);
    }
    return q.snapshots().map(
        (snap) => snap.docs.map(CustomerModel.fromFirestore).toList());
  }

  Stream<List<CustomerModel>> getStoreCustomersStream(String storeId) =>
      getCustomersStream(storeId: storeId);

  Future<CustomerModel> registerCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    required String storeId,
    String? userId,
    String? registeredByUserId,
  }) async {
    final existing = await getCustomerByPhone(phone);
    if (existing != null) return existing;

    final ref = _customers.doc();
    final now = DateTime.now();
    final customer = CustomerModel(
      id: ref.id,
      name: name.trim(),
      phone: phone.trim(),
      email: email,
      address: address,
      registeredAt: now,
      registeredStoreId: storeId,
      registeredByUserId: registeredByUserId ?? userId ?? '',
    );
    await ref.set(customer.toFirestore());

    await _loyalty.doc(phone.trim()).set({
      'primaryCustomerId': customer.id,
      'phone': phone.trim(),
      'totalPoints': 0,
      'redeemedPoints': 0,
      'availablePoints': 0,
      'createdAt': Timestamp.fromDate(now),
      'lastActivity': Timestamp.fromDate(now),
    });

    return customer;
  }

  Future<List<LoyaltyTransaction>> getLoyaltyTransactions(String phone) async {
    final snap = await _loyaltyTx.where('phone', isEqualTo: phone.trim()).get();
    final list = snap.docs.map(LoyaltyTransaction.fromFirestore).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Stream<List<LoyaltyTransaction>> getLoyaltyHistoryStream(String phone) {
    return _loyaltyTx.where('phone', isEqualTo: phone.trim()).snapshots().map(
      (snap) {
        final list = snap.docs.map(LoyaltyTransaction.fromFirestore).toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      },
    );
  }

  Future<void> applySaleLoyalty({
    required String phone,
    String? customerId,
    String? customerName,
    required String saleId,
    required String storeId,
    required String storeName,
    required String processedByUserId,
    required String processedByUserName,
    required int pointsEarned,
    required double rupeesRedeemed,
  }) async {
    final key = phone.trim();
    var account = await getLoyaltyAccount(key);
    if (account == null) {
      final customer = await getCustomerByPhone(key);
      final now = DateTime.now();
      account = LoyaltyAccount(
        id: key,
        primaryCustomerId: customer?.id ?? customerId ?? '',
        phone: key,
        totalPoints: 0,
        redeemedPoints: 0,
        availablePoints: 0,
        createdAt: now,
        lastActivity: now,
      );
      await _loyalty.doc(key).set(account.toFirestore());
    }

    final redeemPoints = (rupeesRedeemed / AppConstants.pointsToRupeeValue)
        .round()
        .clamp(0, account.availablePoints);

    if (redeemPoints > 0) {
      await _loyalty.doc(key).update({
        'redeemedPoints': FieldValue.increment(redeemPoints),
        'availablePoints': FieldValue.increment(-redeemPoints),
        'lastActivity': FieldValue.serverTimestamp(),
      });
      await _loyaltyTx.add({
        'loyaltyAccountId': key,
        'phone': key,
        'customerId': customerId,
        'customerName': customerName,
        'type': LoyaltyTransactionType.redeem.name,
        'points': redeemPoints,
        'saleId': saleId,
        'storeId': storeId,
        'storeName': storeName,
        'processedByUserId': processedByUserId,
        'processedByUserName': processedByUserName,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'notes': 'Redeemed at POS',
      });
    }

    if (pointsEarned > 0) {
      await _loyalty.doc(key).update({
        'totalPoints': FieldValue.increment(pointsEarned),
        'availablePoints': FieldValue.increment(pointsEarned),
        'lastActivity': FieldValue.serverTimestamp(),
      });
      await _loyaltyTx.add({
        'loyaltyAccountId': key,
        'phone': key,
        'customerId': customerId,
        'customerName': customerName,
        'type': LoyaltyTransactionType.earn.name,
        'points': pointsEarned,
        'saleId': saleId,
        'storeId': storeId,
        'storeName': storeName,
        'processedByUserId': processedByUserId,
        'processedByUserName': processedByUserName,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'notes': 'Earned from sale',
      });
    }
  }
}
