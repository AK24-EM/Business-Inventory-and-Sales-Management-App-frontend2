import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/inventory_model.dart';
import '../models/restock_model.dart';
import '../models/supplier_model.dart';
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;

  List<InventoryModel> _inventory = [];
  List<StockMovement> _movements = [];
  List<StockTransfer> _pendingTransfers = [];
  bool _isLoading = false;
  String? _error;

  InventoryProvider(this._service);

  List<InventoryModel> get inventory => _inventory;
  List<InventoryModel> get lowStockItems =>
      _inventory.where((i) => i.isLowStock).toList();
  List<StockMovement> get movements => _movements;
  List<StockTransfer> get pendingTransfers => _pendingTransfers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Replay-capable broadcast streams (BehaviorSubject pattern) ───────────
  // Each storeId gets a BehaviorSubject that immediately replays the last
  // cached value to new subscribers — fixing the "missed first event" issue
  // with Firestore's asBroadcastStream() on Web.
  final Map<String, BehaviorSubject<List<InventoryModel>>> _inventorySubjects = {};
  final Map<String, StreamSubscription<List<InventoryModel>>> _inventoryFirestoreSubs = {};

  Map<String, BehaviorSubject<List<StockTransfer>>>? _pendingTransferSubjects;
  Map<String, BehaviorSubject<List<StockTransfer>>> get _safePendingTransferSubjects =>
      _pendingTransferSubjects ??= <String, BehaviorSubject<List<StockTransfer>>>{};

  Map<String, BehaviorSubject<List<StockTransfer>>>? _allTransferSubjects;
  Map<String, BehaviorSubject<List<StockTransfer>>> get _safeAllTransferSubjects =>
      _allTransferSubjects ??= <String, BehaviorSubject<List<StockTransfer>>>{};

  Map<String, BehaviorSubject<List<DamagedProduct>>>? _damageReportSubjects;
  Map<String, BehaviorSubject<List<DamagedProduct>>> get _safeDamageReportSubjects =>
      _damageReportSubjects ??= <String, BehaviorSubject<List<DamagedProduct>>>{};

  /// Replay-capable inventory stream with debouncing and error recovery.
  /// New subscribers immediately receive the last known value (BehaviorSubject),
  /// then continue to receive live Firestore updates.
  Stream<List<InventoryModel>> watchInventory(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();

    // Return existing subject's stream if already set up
    if (_inventorySubjects.containsKey(storeId)) {
      return _inventorySubjects[storeId]!.stream
          .distinct() // Prevent duplicate emissions
          .handleError((error) {
            debugPrint('Inventory stream error ($storeId): $error');
            // Return empty list on error to keep UI functional
            return <InventoryModel>[];
          });
    }

    // First time: create a BehaviorSubject with debouncing
    final subject = BehaviorSubject<List<InventoryModel>>();
    _inventorySubjects[storeId] = subject;

    // Subscribe to the real Firestore stream with debouncing and error handling
    final firestoreSub = _service.getStoreInventoryStream(storeId)
      .distinct() // Skip duplicate events from Firestore
      .debounceTime(const Duration(milliseconds: 300)) // Debounce rapid updates
      .handleError((err) {
        debugPrint('Firestore inventory stream error ($storeId): $err');
        // Don't propagate error to UI - just log it
      })
      .listen(
        (items) {
          // Update cache
          _inventory = [
            ..._inventory.where((i) => i.storeId != storeId),
            ...items,
          ];
          
          // Emit to all subscribers
          if (!subject.isClosed) {
            subject.add(items);
          }
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Inventory subscription error ($storeId): $err');
          // Emit empty list to keep UI functional
          if (!subject.isClosed) {
            subject.add([]);
          }
        },
        cancelOnError: false, // Keep subscription alive on errors
      );
    
    _inventoryFirestoreSubs[storeId] = firestoreSub;

    return subject.stream
        .distinct() // Additional distinct for safety
        .handleError((error) {
          debugPrint('Subject stream error ($storeId): $error');
          return <InventoryModel>[];
        });
  }

  Stream<List<InventoryModel>> watchLowStock(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    // Derive low-stock stream from the replay-capable watchInventory
    return watchInventory(storeId)
        .map((items) => items.where((i) => i.isLowStock).toList())
        .distinct();
  }

  Map<String, BehaviorSubject<List<RestockModel>>>? _restockSubjects;
  Map<String, BehaviorSubject<List<RestockModel>>> get _safeRestockSubjects =>
      _restockSubjects ??= <String, BehaviorSubject<List<RestockModel>>>{};

  /// Real-time stream of restock events from the dedicated `restocks` collection.
  Stream<List<RestockModel>> watchRestocks(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    
    return _safeRestockSubjects.putIfAbsent(
      storeId,
      () {
        final subject = BehaviorSubject<List<RestockModel>>();
        _service.getRestocksStream(storeId)
          .distinct()
          .debounceTime(const Duration(milliseconds: 300))
          .handleError((err) {
            debugPrint('Restocks stream error ($storeId): $err');
          })
          .listen(
            (data) {
              if (!subject.isClosed) subject.add(data);
            },
            onError: (err) {
              debugPrint('Restocks subscription error: $err');
              if (!subject.isClosed) subject.add([]);
            },
            cancelOnError: false,
          );
        return subject;
      },
    ).stream.distinct();
  }

  /// One-time fetch of restock history (useful for reports/analytics).
  Future<List<RestockModel>> fetchRestocks(String storeId, {int limit = 50}) =>
      _service.getRestocksForStore(storeId, limit: limit);

  Stream<List<StockTransfer>> watchPendingTransfers(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    
    return _safePendingTransferSubjects.putIfAbsent(
      storeId,
      () {
        final subject = BehaviorSubject<List<StockTransfer>>();
        _service.getPendingTransfersStream(storeId)
          .distinct()
          .debounceTime(const Duration(milliseconds: 300))
          .handleError((err) {
            debugPrint('Pending transfers stream error ($storeId): $err');
          })
          .listen(
            (data) {
              if (!subject.isClosed) subject.add(data);
            },
            onError: (err) {
              debugPrint('Pending transfers error: $err');
              if (!subject.isClosed) subject.add([]);
            },
            cancelOnError: false,
          );
        return subject;
      },
    ).stream.distinct();
  }

  Stream<List<StockTransfer>> watchAllTransfers(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    
    return _safeAllTransferSubjects.putIfAbsent(
      storeId,
      () {
        final subject = BehaviorSubject<List<StockTransfer>>();
        _service.getAllTransfersStream(storeId)
          .distinct()
          .debounceTime(const Duration(milliseconds: 300))
          .handleError((err) {
            debugPrint('All transfers stream error ($storeId): $err');
          })
          .listen(
            (data) {
              if (!subject.isClosed) subject.add(data);
            },
            onError: (err) {
              debugPrint('All transfers error: $err');
              if (!subject.isClosed) subject.add([]);
            },
            cancelOnError: false,
          );
        return subject;
      },
    ).stream.distinct();
  }

  Stream<List<DamagedProduct>> watchDamageReports(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    
    return _safeDamageReportSubjects.putIfAbsent(
      storeId,
      () {
        final subject = BehaviorSubject<List<DamagedProduct>>();
        _service.getDamageReportsStream(storeId)
          .distinct()
          .debounceTime(const Duration(milliseconds: 300))
          .handleError((err) {
            debugPrint('Damage reports stream error ($storeId): $err');
          })
          .listen(
            (data) {
              if (!subject.isClosed) subject.add(data);
            },
            onError: (err) {
              debugPrint('Damage reports error: $err');
              if (!subject.isClosed) subject.add([]);
            },
            cancelOnError: false,
          );
        return subject;
      },
    ).stream.distinct();
  }

  Future<InventoryModel?> getItem(String storeId, String productId) =>
      _service.getInventoryItem(storeId, productId);

  Future<void> quickRestock({
    required String storeId,
    required String productId,
    required String productName,
    required int quantity,
    required String userId,
    required String userName,
    String? storeName,
    String? category,
    String? supplierId,
    String? supplierName,
    double unitCost = 0.0,
    String? notes,
  }) async {
    try {
      await _service.quickRestock(
        storeId: storeId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        userId: userId,
        userName: userName,
        storeName: storeName,
        category: category,
        supplierId: supplierId,
        supplierName: supplierName,
        unitCost: unitCost,
        notes: notes,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> receiveStock({
    required String storeId,
    required String productId,
    required String productName,
    required int quantity,
    required String userId,
    required String userName,
    String? purchaseOrderId,
    String? notes,
  }) async {
    try {
      await _service.receiveStock(
        storeId: storeId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        userId: userId,
        userName: userName,
        purchaseOrderId: purchaseOrderId,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> adjustStock({
    required String storeId,
    required String productId,
    required String productName,
    required int quantityChange,
    required AdjustmentReason reason,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    try {
      await _service.adjustStock(
        storeId: storeId,
        productId: productId,
        productName: productName,
        quantityChange: quantityChange,
        reason: reason,
        userId: userId,
        userName: userName,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<StockTransfer> initiateTransfer({
    required String sourceStoreId,
    required String destinationStoreId,
    required String productId,
    required String productName,
    required int quantity,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    try {
      return await _service.initiateTransfer(
        sourceStoreId: sourceStoreId,
        destinationStoreId: destinationStoreId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        initiatedByUserId: userId,
        initiatedByUserName: userName,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> confirmTransfer({
    required String transferId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _service.confirmTransfer(
        transferId: transferId,
        confirmedByUserId: userId,
        confirmedByUserName: userName,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> cancelTransfer({
    required String transferId,
    required String userId,
    required String userName,
    String? reason,
  }) async {
    try {
      await _service.cancelTransfer(
        transferId: transferId,
        cancelledByUserId: userId,
        cancelledByUserName: userName,
        reason: reason,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<DamagedProduct> reportDamage({
    required String storeId,
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    required int quantity,
    required double estimatedLoss,
    required String reason,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    try {
      return await _service.reportDamage(
        storeId: storeId,
        productId: productId,
        productName: productName,
        supplierId: supplierId,
        supplierName: supplierName,
        quantity: quantity,
        estimatedLoss: estimatedLoss,
        reason: reason,
        userId: userId,
        userName: userName,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateDamageReportStatus({
    required String reportId,
    required String status,
    required String userId,
    required String userName,
    String? note,
  }) async {
    try {
      await _service.updateDamageReportStatus(
        reportId: reportId,
        status: status,
        userId: userId,
        userName: userName,
        note: note,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> logStockAudit({
    required String storeId,
    required String productId,
    required String productName,
    required int countedQty,
    required int currentStock,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    try {
      await _service.logStockAudit(
        storeId: storeId,
        productId: productId,
        productName: productName,
        countedQty: countedQty,
        currentStock: currentStock,
        userId: userId,
        userName: userName,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Stream<List<StockMovement>> watchMovements(
          String storeId, String productId) {
    return _service.getMovementHistoryStream(storeId, productId)
        .distinct()
        .debounceTime(const Duration(milliseconds: 300))
        .handleError((err) {
          debugPrint('Movements stream error ($storeId/$productId): $err');
          return <StockMovement>[];
        });
  }

  @override
  void dispose() {
    // Close all BehaviorSubjects
    for (final subject in _inventorySubjects.values) {
      subject.close();
    }
    for (final subject in _safeRestockSubjects.values) {
      subject.close();
    }
    for (final subject in _safePendingTransferSubjects.values) {
      subject.close();
    }
    for (final subject in _safeAllTransferSubjects.values) {
      subject.close();
    }
    for (final subject in _safeDamageReportSubjects.values) {
      subject.close();
    }
    
    // Cancel all Firestore subscriptions
    for (final sub in _inventoryFirestoreSubs.values) {
      sub.cancel();
    }
    
    _inventorySubjects.clear();
    _inventoryFirestoreSubs.clear();
    
    super.dispose();
  }
}
