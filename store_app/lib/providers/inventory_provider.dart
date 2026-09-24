import 'dart:async';
import 'package:flutter/foundation.dart';
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
  // Each storeId gets a StreamController that immediately replays the last
  // cached value to new subscribers — fixing the "missed first event" issue
  // with Firestore's asBroadcastStream() on Web.
  final Map<String, StreamController<List<InventoryModel>>> _inventoryControllers = {};
  final Map<String, List<InventoryModel>> _inventoryCache = {};
  final Map<String, StreamSubscription<List<InventoryModel>>> _inventoryFirestoreSubs = {};

  Map<String, Stream<List<StockTransfer>>>? _pendingTransferStreams;
  Map<String, Stream<List<StockTransfer>>> get _safePendingTransferStreams =>
      _pendingTransferStreams ??= <String, Stream<List<StockTransfer>>>{};

  Map<String, Stream<List<StockTransfer>>>? _allTransferStreams;
  Map<String, Stream<List<StockTransfer>>> get _safeAllTransferStreams =>
      _allTransferStreams ??= <String, Stream<List<StockTransfer>>>{};

  Map<String, Stream<List<DamagedProduct>>>? _damageReportStreams;
  Map<String, Stream<List<DamagedProduct>>> get _safeDamageReportStreams =>
      _damageReportStreams ??= <String, Stream<List<DamagedProduct>>>{};

  /// Replay-capable inventory stream.
  /// New subscribers immediately receive the last known value (like BehaviorSubject),
  /// then continue to receive live Firestore updates.
  Stream<List<InventoryModel>> watchInventory(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();

    // Return existing controller's stream if already set up
    if (_inventoryControllers.containsKey(storeId)) {
      final controller = _inventoryControllers[storeId]!;
      // Replay last known value immediately to the new subscriber
      final cached = _inventoryCache[storeId];
      if (cached != null) {
        // Schedule the replay on the next microtask so the listener is ready
        Future.microtask(() {
          if (!controller.isClosed) controller.add(cached);
        });
      }
      return controller.stream;
    }

    // First time: create a broadcast StreamController
    final controller = StreamController<List<InventoryModel>>.broadcast();
    _inventoryControllers[storeId] = controller;

    // Subscribe to the real Firestore stream
    final firestoreSub = _service.getStoreInventoryStream(storeId).listen(
      (items) {
        _inventoryCache[storeId] = items;
        // Merge into flat _inventory cache
        _inventory = [
          ..._inventory.where((i) => i.storeId != storeId),
          ...items,
        ];
        if (!controller.isClosed) controller.add(items);
        notifyListeners();
      },
      onError: (err) {
        debugPrint('Firestore inventory stream error ($storeId): $err');
        if (!controller.isClosed) controller.addError(err);
      },
    );
    _inventoryFirestoreSubs[storeId] = firestoreSub;

    return controller.stream;
  }

  Stream<List<InventoryModel>> watchLowStock(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    // Derive low-stock stream from the replay-capable watchInventory
    return watchInventory(storeId)
        .map((items) => items.where((i) => i.isLowStock).toList());
  }

  Map<String, Stream<List<RestockModel>>>? _restockStreams;
  Map<String, Stream<List<RestockModel>>> get _safeRestockStreams =>
      _restockStreams ??= <String, Stream<List<RestockModel>>>{};

  /// Real-time stream of restock events from the dedicated `restocks` collection.
  Stream<List<RestockModel>> watchRestocks(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _safeRestockStreams.putIfAbsent(
      storeId,
      () => _service.getRestocksStream(storeId).asBroadcastStream(),
    );
  }

  /// One-time fetch of restock history (useful for reports/analytics).
  Future<List<RestockModel>> fetchRestocks(String storeId, {int limit = 50}) =>
      _service.getRestocksForStore(storeId, limit: limit);

  Stream<List<StockTransfer>> watchPendingTransfers(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _safePendingTransferStreams.putIfAbsent(
      storeId,
      () => _service.getPendingTransfersStream(storeId).asBroadcastStream(),
    );
  }

  Stream<List<StockTransfer>> watchAllTransfers(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _safeAllTransferStreams.putIfAbsent(
      storeId,
      () => _service.getAllTransfersStream(storeId).asBroadcastStream(),
    );
  }

  Stream<List<DamagedProduct>> watchDamageReports(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _safeDamageReportStreams.putIfAbsent(
      storeId,
      () => _service.getDamageReportsStream(storeId).asBroadcastStream(),
    );
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
          String storeId, String productId) =>
      _service.getMovementHistoryStream(storeId, productId);
}
