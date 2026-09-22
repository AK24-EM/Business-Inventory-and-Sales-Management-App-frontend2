import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/sale_model.dart';
import 'customer_service.dart';
import 'inventory_service.dart';

class SalesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final InventoryService _inventoryService;
  final CustomerService _customerService;

  SalesService(this._inventoryService, this._customerService);

  CollectionReference<Map<String, dynamic>> get _sales =>
      _db.collection(AppConstants.salesCollection);

  Future<SaleModel> completeSale({
    required String storeId,
    required String storeName,
    required List<SaleItem> items,
    required PaymentMode paymentMode,
    required String employeeId,
    required String employeeName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double discountAmount = 0,
    double loyaltyPointsRedeemed = 0,
  }) async {
    final subtotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final total = (subtotal - discountAmount - loyaltyPointsRedeemed)
        .clamp(0.0, double.infinity);
    final pointsEarned = (total * AppConstants.pointsPerRupee).round();
    final now = DateTime.now();
    final ref = _sales.doc();

    final sale = SaleModel(
      id: ref.id,
      storeId: storeId,
      storeName: storeName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      loyaltyPointsRedeemed: loyaltyPointsRedeemed,
      totalAmount: total,
      paymentMode: paymentMode,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      loyaltyPointsEarned: pointsEarned,
      employeeId: employeeId,
      employeeName: employeeName,
      timestamp: now,
      invoiceNumber: 'INV-${now.millisecondsSinceEpoch}',
    );

    await ref.set(sale.toFirestore());

    for (final item in items) {
      await _inventoryService.deductForSale(
        storeId: storeId,
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        userId: employeeId,
        userName: employeeName,
        saleId: sale.id,
      );
    }

    if (customerPhone != null && customerPhone.isNotEmpty) {
      await _customerService.applySaleLoyalty(
        phone: customerPhone,
        customerId: customerId,
        customerName: customerName,
        saleId: sale.id,
        storeId: storeId,
        storeName: storeName,
        processedByUserId: employeeId,
        processedByUserName: employeeName,
        pointsEarned: pointsEarned,
        rupeesRedeemed: loyaltyPointsRedeemed,
      );
    }

    return sale;
  }

  Stream<List<SaleModel>> getSalesByStoreStream(
      String storeId, DateTime from, DateTime to) {
    return Stream.fromFuture(getSalesByStore(storeId, from, to));
  }

  Future<List<SaleModel>> getSalesByStore(
      String storeId, DateTime from, DateTime to) async {
    // Use Firestore query with orderBy for optimal performance
    final snap = await _sales
        .where('storeId', isEqualTo: storeId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(SaleModel.fromFirestore).toList();
  }

  Future<List<SaleModel>> getAllSales(DateTime from, DateTime to) async {
    final snap = await _sales.get();
    final sales = snap.docs
        .map(SaleModel.fromFirestore)
        .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
        .toList();
    // Sort by timestamp descending (newest first)
    sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sales;
  }

  Future<List<SaleModel>> getCustomerSales(String customerId) async {
    // Use Firestore query with orderBy for optimal performance
    final snap = await _sales
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(SaleModel.fromFirestore).toList();
  }

  Future<List<SaleModel>> getSalesByCustomerPhone(String phone) async {
    // Query by customer phone number with timestamp sorting
    final snap = await _sales
        .where('customerPhone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(SaleModel.fromFirestore).toList();
  }

  Stream<List<SaleModel>> getSalesByCustomerPhoneStream(String phone) {
    // Real-time stream of customer purchases sorted by newest first
    return _sales
        .where('customerPhone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SaleModel.fromFirestore).toList());
  }

  Stream<List<SaleModel>> getTodaySalesStream(String storeId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    // Use Firestore query with orderBy and timestamp filter
    return _sales
        .where('storeId', isEqualTo: storeId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SaleModel.fromFirestore).toList());
  }
}
