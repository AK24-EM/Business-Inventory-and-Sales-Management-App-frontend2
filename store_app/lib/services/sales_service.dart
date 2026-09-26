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

  // PERFORMANCE FIX: Store separate streams per date range, not just per store
  final Map<String, Stream<List<SaleModel>>> _cachedStreams = {};
  Timer? _cacheCleanupTimer;

  Stream<List<SaleModel>> _getRawStoreSalesStream(String storeId) {
    return _storeSalesStreams.putIfAbsent(storeId, () {
      return _sales
          .where('storeId', isEqualTo: storeId)
          .orderBy('timestamp', descending: true) // Sort at Firestore level
          .limit(500) // Limit to recent 500 sales to prevent loading all history
          .snapshots()
          .map((snap) {
            return snap.docs.map(SaleModel.fromFirestore).toList();
          })
          .asBroadcastStream();
    });
  }

  Stream<List<SaleModel>> _getRawAllSalesStream() {
    return _allSalesStream ??= _sales
        .orderBy('timestamp', descending: true) // Sort at Firestore level
        .limit(1000) // Limit to recent 1000 sales to prevent loading entire database
        .snapshots()
        .map((snap) {
          return snap.docs.map(SaleModel.fromFirestore).toList();
        })
        .asBroadcastStream();
  }

  // OPTIMIZED: Create stream with Firestore-level date filtering
  Stream<List<SaleModel>> _getDateRangeStream({
    String? storeId,
    List<String>? storeIds,
    required DateTime from,
    required DateTime to,
  }) {
    final cacheKey = '${storeId ?? storeIds?.join(',') ?? 'all'}_${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}';
    
    return _cachedStreams.putIfAbsent(cacheKey, () {
      Query<Map<String, dynamic>> query = _sales;
      
      // Apply store filter
      if (storeId != null) {
        query = query.where('storeId', isEqualTo: storeId);
      } else if (storeIds != null && storeIds.isNotEmpty) {
        if (storeIds.length <= 10) {
          query = query.where('storeId', whereIn: storeIds);
        }
      }
      
      // CRITICAL: Apply date filter at Firestore level
      final fromTimestamp = Timestamp.fromDate(from);
      final toTimestamp = Timestamp.fromDate(to);
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: fromTimestamp)
          .where('timestamp', isLessThanOrEqualTo: toTimestamp)
          .orderBy('timestamp', descending: true);
      
      // Schedule cleanup of old cache entries
      _scheduleCacheCleanup();
      
      return query
          .snapshots()
          .map((snap) => snap.docs.map(SaleModel.fromFirestore).toList())
          .asBroadcastStream();
    });
  }

  void _scheduleCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer(const Duration(minutes: 5), () {
      // Keep only the 3 most recent cache entries
      if (_cachedStreams.length > 3) {
        final keysToRemove = _cachedStreams.keys.take(_cachedStreams.length - 3).toList();
        for (final key in keysToRemove) {
          _cachedStreams.remove(key);
        }
      }
    });
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
  /// OPTIMIZED: Uses Firestore-level date filtering for better performance.
  Stream<List<SaleModel>> getSalesByStoreStream(
      String storeId, DateTime from, DateTime to) {
    return _getDateRangeStream(
      storeId: storeId,
      from: from,
      to: to,
    );
  }

  /// Real-time stream of all sales across all stores (or filtered by storeIds).
  /// OPTIMIZED: Uses Firestore-level date filtering for better performance.
  Stream<List<SaleModel>> getSalesStream({
    List<String>? storeIds,
    required DateTime from,
    required DateTime to,
  }) {
    return _getDateRangeStream(
      storeIds: storeIds,
      from: from,
      to: to,
    );
  }

  Future<List<SaleModel>> getSalesByStore(
      String storeId, DateTime from, DateTime to) async {
    try {
      // OPTIMIZED: Use Firestore-level date filtering
      final fromTimestamp = Timestamp.fromDate(from);
      final toTimestamp = Timestamp.fromDate(to);
      
      final snap = await _sales
          .where('storeId', isEqualTo: storeId)
          .where('timestamp', isGreaterThanOrEqualTo: fromTimestamp)
          .where('timestamp', isLessThanOrEqualTo: toTimestamp)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snap.docs.map(SaleModel.fromFirestore).toList();
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

