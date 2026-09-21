import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inv =>
      _db.collection(AppConstants.inventoryCollection);
  CollectionReference<Map<String, dynamic>> get _movements =>
      _db.collection(AppConstants.stockMovementsCollection);
  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection(AppConstants.stockTransfersCollection);

  String _itemId(String storeId, String productId) => '${storeId}_$productId';

  Stream<List<InventoryModel>> getStoreInventoryStream(String storeId) {
    return _inv.where('storeId', isEqualTo: storeId).snapshots().map((snap) =>
        snap.docs.map(InventoryModel.fromFirestore).toList());
  }

  Future<List<InventoryModel>> getStoreInventory(String storeId,
      {bool lowStockOnly = false}) async {
    final snap = await _inv.where('storeId', isEqualTo: storeId).get();
    var items = snap.docs.map(InventoryModel.fromFirestore).toList();
    if (lowStockOnly) {
      items = items.where((i) => i.isLowStock).toList();
    }
    return items;
  }

  Stream<List<InventoryModel>> getLowStockStream(String storeId) {
    return getStoreInventoryStream(storeId)
        .map((items) => items.where((i) => i.isLowStock).toList());
  }

  Future<InventoryModel?> getInventoryItem(
      String storeId, String productId) async {
    final doc = await _inv.doc(_itemId(storeId, productId)).get();
    if (!doc.exists) return null;
    return InventoryModel.fromFirestore(doc);
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
    await _changeStock(
      storeId: storeId,
      productId: productId,
      productName: productName,
      delta: quantity,
      type: StockMovementType.receipt,
      userId: userId,
      userName: userName,
      reason: notes,
      referenceId: purchaseOrderId,
    );
  }

  Future<void> deductForSale({
    required String storeId,
    required String productId,
    required String productName,
    required int quantity,
    required String userId,
    required String userName,
    String? saleId,
  }) async {
    await _changeStock(
      storeId: storeId,
      productId: productId,
      productName: productName,
      delta: -quantity,
      type: StockMovementType.sale,
      userId: userId,
      userName: userName,
      referenceId: saleId,
    );
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
    await _changeStock(
      storeId: storeId,
      productId: productId,
      productName: productName,
      delta: quantityChange,
      type: quantityChange < 0 && reason == AdjustmentReason.damage
          ? StockMovementType.damaged
          : StockMovementType.adjustment,
      userId: userId,
      userName: userName,
      reason: notes,
      adjustmentReason: reason,
    );
  }

  Future<StockTransfer> initiateTransfer({
    required String sourceStoreId,
    required String destinationStoreId,
    required String productId,
    required String productName,
    required int quantity,
    required String initiatedByUserId,
    required String initiatedByUserName,
    String? notes,
  }) async {
    await _changeStock(
      storeId: sourceStoreId,
      productId: productId,
      productName: productName,
      delta: -quantity,
      type: StockMovementType.transferOut,
      userId: initiatedByUserId,
      userName: initiatedByUserName,
      reason: notes,
    );

    final ref = _transfers.doc();
    final transfer = StockTransfer(
      id: ref.id,
      sourceStoreId: sourceStoreId,
      destinationStoreId: destinationStoreId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      initiatedByUserId: initiatedByUserId,
      initiatedByUserName: initiatedByUserName,
      initiatedAt: DateTime.now(),
      notes: notes,
    );
    await ref.set(transfer.toFirestore());
    return transfer;
  }

  Future<void> confirmTransfer({
    required String transferId,
    required String confirmedByUserId,
    required String confirmedByUserName,
  }) async {
    final ref = _transfers.doc(transferId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Transfer not found');
    final transfer = StockTransfer.fromFirestore(snap);
    if (transfer.status != TransferStatus.pending) {
      throw Exception('Transfer is not pending');
    }

    await _changeStock(
      storeId: transfer.destinationStoreId,
      productId: transfer.productId,
      productName: transfer.productName,
      delta: transfer.quantity,
      type: StockMovementType.transferIn,
      userId: confirmedByUserId,
      userName: confirmedByUserName,
      referenceId: transferId,
    );

    await ref.update({
      'status': TransferStatus.confirmed.name,
      'confirmedByUserId': confirmedByUserId,
      'confirmedByUserName': confirmedByUserName,
      'confirmedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<StockMovement>> getMovementHistoryStream(
      String storeId, String productId) {
    return _movements.where('storeId', isEqualTo: storeId).snapshots().map((snap) {
      var list = snap.docs.map(StockMovement.fromFirestore).toList();
      if (productId.isNotEmpty) {
        list = list.where((m) => m.productId == productId).toList();
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<StockTransfer>> getPendingTransfersStream(String storeId) {
    return _transfers
        .where('destinationStoreId', isEqualTo: storeId)
        .snapshots()
        .map((snap) => snap.docs
            .map(StockTransfer.fromFirestore)
            .where((t) => t.status == TransferStatus.pending)
            .toList());
  }

  Future<void> _changeStock({
    required String storeId,
    required String productId,
    required String productName,
    required int delta,
    required StockMovementType type,
    required String userId,
    required String userName,
    String? reason,
    AdjustmentReason? adjustmentReason,
    String? referenceId,
  }) async {
    final invRef = _inv.doc(_itemId(storeId, productId));
    int before = 0;
    int after = 0;
    String category = '';

    await _db.runTransaction((tx) async {
      final snap = await tx.get(invRef);
      if (snap.exists) {
        final data = snap.data()!;
        before = (data['currentStock'] as num?)?.toInt() ?? 0;
        category = data['category'] as String? ?? '';
      }
      after = before + delta;
      if (after < 0) {
        throw Exception('Insufficient stock');
      }
      tx.set(
        invRef,
        {
          'storeId': storeId,
          'productId': productId,
          'productName': productName,
          'category': category,
          'currentStock': after,
          'minimumStockLevel': snap.exists
              ? (snap.data()!['minimumStockLevel'] ??
                  AppConstants.defaultMinStockLevel)
              : AppConstants.defaultMinStockLevel,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await _movements.add({
      'storeId': storeId,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': delta.abs(),
      'stockBefore': before,
      'stockAfter': after,
      'reason': reason,
      'adjustmentReason': adjustmentReason?.name,
      'referenceId': referenceId,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }
}
