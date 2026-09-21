import 'package:flutter/foundation.dart';
import '../models/inventory_model.dart';
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

  Stream<List<InventoryModel>> watchInventory(String storeId) =>
      _service.getStoreInventoryStream(storeId);

  Stream<List<InventoryModel>> watchLowStock(String storeId) =>
      _service.getLowStockStream(storeId);

  Stream<List<StockTransfer>> watchPendingTransfers(String storeId) =>
      _service.getPendingTransfersStream(storeId);

  Future<InventoryModel?> getItem(String storeId, String productId) =>
      _service.getInventoryItem(storeId, productId);

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

  Stream<List<StockMovement>> watchMovements(
          String storeId, String productId) =>
      _service.getMovementHistoryStream(storeId, productId);
}
