import 'dart:async';
import 'package:flutter/foundation.dart';
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

  final Map<String, Stream<List<SaleModel>>> _storeSalesStreams = {};
  Stream<List<SaleModel>>? _allSalesStream;

  Stream<List<SaleModel>> _getRawStoreSalesStream(String storeId) {
    return _storeSalesStreams.putIfAbsent(storeId, () {
      return _sales
          .where('storeId', isEqualTo: storeId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(SaleModel.fromFirestore).toList();
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return list;
          })
          .asBroadcastStream();
    });
  }

  Stream<List<SaleModel>> _getRawAllSalesStream() {
    return _allSalesStream ??= _sales
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(SaleModel.fromFirestore).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        })
        .asBroadcastStream();
  }

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

    print('💰 Attempting to save sale:');
    print('   Invoice: ${sale.invoiceNumber}');
    print('   Customer: ${sale.customerName} (${sale.customerPhone})');
    print('   Total: ₹${sale.totalAmount}');
    print('   Store: ${sale.storeName} (${sale.storeId})');
    print('   Items: ${sale.items.length}');
    
    // 1. Primary Operation: Save Sale to Firestore first
    try {
      await ref.set(sale.toFirestore());
      print('✅ Sale saved successfully to Firestore! ID: ${sale.id}');
    } catch (e) {
      print('❌ ERROR saving sale to Firestore: $e');
      rethrow;
    }

    // 2. Inventory deduction (guarded so inventory discrepancies don't abort a recorded sale)
    for (final item in items) {
      try {
        await _inventoryService.deductForSale(
          storeId: storeId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          userId: employeeId,
          userName: employeeName,
          saleId: sale.id,
        );
      } catch (e) {
        print('⚠️ Inventory deduction warning for ${item.productName}: $e');
      }
    }

    // 3. Loyalty & Customer profile update
    if (customerPhone != null && customerPhone.isNotEmpty) {
      try {
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
      } catch (e) {
        print('⚠️ Loyalty update warning for $customerPhone: $e');
      }
    }

    return sale;
  }

  /// Real-time stream of sales for a specific store and date range.
  /// Reuses single store broadcast stream to prevent Firestore Web connection flapping.
  Stream<List<SaleModel>> getSalesByStoreStream(
      String storeId, DateTime from, DateTime to) {
    return _getRawStoreSalesStream(storeId).map((list) {
      return list
          .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
          .toList();
    });
  }

  /// Real-time stream of all sales across all stores (or filtered by storeIds).
  Stream<List<SaleModel>> getSalesStream({
    List<String>? storeIds,
    required DateTime from,
    required DateTime to,
  }) {
    if (storeIds != null && storeIds.length == 1) {
      return getSalesByStoreStream(storeIds.first, from, to);
    }
    return _getRawAllSalesStream().map((list) {
      return list.where((s) {
        if (storeIds != null && storeIds.isNotEmpty && !storeIds.contains(s.storeId)) {
          return false;
        }
        return !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to);
      }).toList();
    });
  }

  Future<List<SaleModel>> getSalesByStore(
      String storeId, DateTime from, DateTime to) async {
    try {
      final snap = await _sales
          .where('storeId', isEqualTo: storeId)
          .get();
      final list = snap.docs.map(SaleModel.fromFirestore).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list
          .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
          .toList();
    } catch (e) {
      debugPrint('getSalesByStore error: $e');
      return [];
    }
  }

  /// Efficient recent sales query using server-side date filter + limit.
  /// Avoids full collection scan — only fetches sales within the last [limitDays] days.
  Future<List<SaleModel>> getSalesByStoreRecent(
      String storeId, {int limitDays = 30, int maxResults = 200}) async {
    try {
      final from = DateTime.now().subtract(Duration(days: limitDays));
      final snap = await _sales
          .where('storeId', isEqualTo: storeId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(from))
          .orderBy('timestamp', descending: true)
          .limit(maxResults)
          .get();
      return snap.docs.map(SaleModel.fromFirestore).toList();
    } catch (e) {
      // Fallback for missing composite index: try without date filter but with limit
      debugPrint('getSalesByStoreRecent index miss, falling back: $e');
      try {
        final snap = await _sales
            .where('storeId', isEqualTo: storeId)
            .limit(maxResults)
            .get();
        final from = DateTime.now().subtract(Duration(days: limitDays));
        final list = snap.docs.map(SaleModel.fromFirestore).toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list.where((s) => !s.timestamp.isBefore(from)).toList();
      } catch (e2) {
        debugPrint('getSalesByStoreRecent fallback also failed: $e2');
        return [];
      }
    }
  }

  /// Real-time stream of all sales across all stores
  Stream<List<SaleModel>> getAllSalesStream(DateTime from, DateTime to) {
    return _getRawAllSalesStream().map((list) {
      return list
          .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
          .toList();
    });
  }

  Future<List<SaleModel>> getAllSales(DateTime from, DateTime to) async {
    final snap = await _sales.get();
    final list = snap.docs.map(SaleModel.fromFirestore).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list
        .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
        .toList();
  }

  Future<List<SaleModel>> getCustomerSales(String customerId) async {
    final snap = await _sales
        .where('customerId', isEqualTo: customerId)
        .get();
    final list = snap.docs.map(SaleModel.fromFirestore).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<List<SaleModel>> getSalesByCustomerPhone(String phone) async {
    final snap = await _sales
        .where('customerPhone', isEqualTo: phone)
        .get();
    final list = snap.docs.map(SaleModel.fromFirestore).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Stream<List<SaleModel>> getSalesByCustomerPhoneStream(String phone) {
    return _sales
        .where('customerPhone', isEqualTo: phone)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(SaleModel.fromFirestore).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// Real-time stream of today's sales for a store
  Stream<List<SaleModel>> getTodaySalesStream(String storeId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _getRawStoreSalesStream(storeId).map((list) {
      return list.where((s) => !s.timestamp.isBefore(start)).toList();
    });
  }
}

