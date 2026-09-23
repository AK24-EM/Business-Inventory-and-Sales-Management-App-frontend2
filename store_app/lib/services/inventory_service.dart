import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/inventory_model.dart';
import '../models/supplier_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inv =>
      _db.collection(AppConstants.inventoryCollection);
  CollectionReference<Map<String, dynamic>> get _movements =>
      _db.collection(AppConstants.stockMovementsCollection);
  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection(AppConstants.stockTransfersCollection);
  CollectionReference<Map<String, dynamic>> get _damaged =>
      _db.collection(AppConstants.damagedProductsCollection);

  String _itemId(String storeId, String productId) => 'inv_${storeId}_$productId';

  Stream<List<InventoryModel>> getStoreInventoryStream(String storeId) {
    return _inv.where('storeId', isEqualTo: storeId).snapshots().map((snap) {
      final map = <String, InventoryModel>{};
      for (final doc in snap.docs) {
        final item = InventoryModel.fromFirestore(doc);
        map[item.productId] = item;
      }
      return map.values.toList();
    });
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
    var doc = await _inv.doc(_itemId(storeId, productId)).get();
    if (!doc.exists) {
      doc = await _inv.doc('inv_${storeId}_$productId').get();
    }
    if (!doc.exists) return null;
    return InventoryModel.fromFirestore(doc);
  }

  Future<void> initializeInventoryForProduct({
    required String storeId,
    required String productId,
    required String productName,
    required String category,
    int initialStock = 0,
    int minStock = AppConstants.defaultMinStockLevel,
    String? userId,
    String? userName,
  }) async {
    final invRef = _inv.doc(_itemId(storeId, productId));
    final snap = await invRef.get();
    if (!snap.exists) {
      await invRef.set({
        'storeId': storeId,
        'productId': productId,
        'productName': productName,
        'category': category,
        'currentStock': initialStock,
        'minimumStockLevel': minStock,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      if (initialStock > 0) {
        await _movements.add({
          'storeId': storeId,
          'productId': productId,
          'productName': productName,
          'type': StockMovementType.receipt.name,
          'quantity': initialStock,
          'stockBefore': 0,
          'stockAfter': initialStock,
          'reason': 'Initial product stock creation',
          'userId': userId ?? 'system',
          'userName': userName ?? 'Manager',
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      }
    }
  }

  Future<void> quickRestock({
    required String storeId,
    required String productId,
    required String productName,
    required int quantity,
    required String userId,
    required String userName,
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
      reason: notes ?? 'Quick Restock from Manager Hub',
    );
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
    Query<Map<String, dynamic>> query = _movements
        .where('storeId', isEqualTo: storeId)
        .orderBy('timestamp', descending: true);
    
    if (productId.isNotEmpty) {
      query = query.where('productId', isEqualTo: productId);
    }
    
    return query.snapshots().map((snap) =>
        snap.docs.map(StockMovement.fromFirestore).toList());
  }

  Stream<List<StockTransfer>> getPendingTransfersStream(String storeId) {
    return _transfers
        .where('destinationStoreId', isEqualTo: storeId)
        .where('status', isEqualTo: TransferStatus.pending.name)
        .orderBy('initiatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StockTransfer.fromFirestore).toList());
  }

  /// Real-time stream of all transfers (both inbound and outbound) for a store
  Stream<List<StockTransfer>> getAllTransfersStream(String storeId) {
    return _transfers
        .orderBy('initiatedAt', descending: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(StockTransfer.fromFirestore).toList();
          return list
              .where((t) =>
                  t.sourceStoreId == storeId || t.destinationStoreId == storeId)
              .toList();
        });
  }

  Future<void> cancelTransfer({
    required String transferId,
    required String cancelledByUserId,
    required String cancelledByUserName,
    String? reason,
  }) async {
    final ref = _transfers.doc(transferId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Transfer not found');
    final transfer = StockTransfer.fromFirestore(snap);
    if (transfer.status != TransferStatus.pending) {
      throw Exception('Only pending transfers can be cancelled');
    }

    // Revert stock back to source store
    await _changeStock(
      storeId: transfer.sourceStoreId,
      productId: transfer.productId,
      productName: transfer.productName,
      delta: transfer.quantity,
      type: StockMovementType.adjustment,
      userId: cancelledByUserId,
      userName: cancelledByUserName,
      reason: 'Transfer cancelled: ${reason ?? "Returned to source stock"}',
      referenceId: transferId,
    );

    await ref.update({
      'status': TransferStatus.cancelled.name,
      'confirmedByUserId': cancelledByUserId,
      'confirmedByUserName': cancelledByUserName,
      'confirmedAt': Timestamp.fromDate(DateTime.now()),
      'notes': transfer.notes != null
          ? '${transfer.notes} | Cancelled: $reason'
          : 'Cancelled: $reason',
    });
  }

  /// Reports a damaged product from an employee or manager.
  /// 1. Immediately records the stock deduction in inventory movements.
  /// 2. Saves the incident to the damagedProducts collection in Firestore.
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
    // 1. Deduct stock immediately with a damaged stock movement
    await _changeStock(
      storeId: storeId,
      productId: productId,
      productName: productName,
      delta: -quantity,
      type: StockMovementType.damaged,
      userId: userId,
      userName: userName,
      reason: 'Damage Incident ($reason)${notes != null && notes.isNotEmpty ? ": $notes" : ""}',
      adjustmentReason: AdjustmentReason.damage,
    );

    // 2. Add to damagedProducts collection
    final ref = _damaged.doc();
    final item = DamagedProduct(
      id: ref.id,
      productId: productId,
      productName: productName,
      supplierId: supplierId ?? '',
      supplierName: supplierName ?? 'Direct Inventory',
      storeId: storeId,
      quantity: quantity,
      estimatedLoss: estimatedLoss,
      reason: reason,
      reportedAt: DateTime.now(),
      reportedByUserId: userId,
      reportedByUserName: userName,
      notes: notes,
      status: 'pending',
    );
    await ref.set(item.toFirestore());
    return item;
  }

  /// Real-time stream of all damaged product reports for a store
  Stream<List<DamagedProduct>> getDamageReportsStream(String storeId) {
    return _damaged
        .where('storeId', isEqualTo: storeId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(DamagedProduct.fromFirestore).toList());
  }

  /// Manager signs off on or rejects a damaged product report
  Future<void> updateDamageReportStatus({
    required String reportId,
    required String status, // 'approved' or 'rejected'
    required String userId,
    required String userName,
    String? note,
  }) async {
    final ref = _damaged.doc(reportId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Damage report not found');
    final damage = DamagedProduct.fromFirestore(snap);

    // If manager rejects, restore the deducted stock
    if (status == 'rejected' && damage.status != 'rejected') {
      await _changeStock(
        storeId: damage.storeId,
        productId: damage.productId,
        productName: damage.productName,
        delta: damage.quantity,
        type: StockMovementType.adjustment,
        userId: userId,
        userName: userName,
        reason: 'Damage report rejected: ${note ?? "Stock restored"}',
        adjustmentReason: AdjustmentReason.countCorrection,
      );
    }

    await ref.update({
      'status': status,
      'approvedByUserId': userId,
      'approvedByUserName': userName,
      'approvedAt': FieldValue.serverTimestamp(),
      if (note != null && note.isNotEmpty)
        'notes': damage.notes != null && damage.notes!.isNotEmpty
            ? '${damage.notes} | Review note: $note'
            : 'Review note: $note',
    });
  }

  /// Stock Audit & Scan reconciliation:
  /// Updates inventory currentStock to match physical count,
  /// logs discrepancy variance as an adjustment stock movement,
  /// and updates the lastUpdated timestamp in Firestore.
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
    final variance = countedQty - currentStock;
    if (variance != 0) {
      await _changeStock(
        storeId: storeId,
        productId: productId,
        productName: productName,
        delta: variance,
        type: StockMovementType.adjustment,
        userId: userId,
        userName: userName,
        reason: 'Stock Audit Discrepancy: System: $currentStock, Counted: $countedQty (Variance: ${variance > 0 ? "+$variance" : "$variance"})${notes != null && notes.isNotEmpty ? " • $notes" : ""}',
        adjustmentReason: AdjustmentReason.countCorrection,
      );
    } else {
      final invRef = _inv.doc(_itemId(storeId, productId));
      await invRef.set({
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _movements.add({
        'storeId': storeId,
        'productId': productId,
        'productName': productName,
        'type': StockMovementType.adjustment.name,
        'quantity': 0,
        'stockBefore': currentStock,
        'stockAfter': currentStock,
        'reason': 'Stock Audit Verified: Count verified at $currentStock units${notes != null && notes.isNotEmpty ? " • $notes" : ""}',
        'adjustmentReason': AdjustmentReason.countCorrection.name,
        'userId': userId,
        'userName': userName,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    }
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
    var invRef = _inv.doc(_itemId(storeId, productId));
    int before = 0;
    int after = 0;
    String category = '';

    bool transactionSucceeded = false;
    if (!kIsWeb) {
      try {
        await _db.runTransaction((tx) async {
          var snap = await tx.get(invRef);
          if (!snap.exists) {
            final altRef = _inv.doc('${storeId}_$productId');
            final altSnap = await tx.get(altRef);
            if (altSnap.exists) {
              invRef = altRef;
              snap = altSnap;
            }
          }

          if (snap.exists) {
            final data = snap.data()!;
            before = (data['currentStock'] as num?)?.toInt() ?? 0;
            category = data['category'] as String? ?? '';
          }
          
          after = before + delta;
          if (after < 0) {
            if (type == StockMovementType.sale) {
              after = 0;
            } else {
              throw Exception('Insufficient stock. Available: $before units, attempted: ${delta.abs()} units.');
            }
          }

          tx.set(
            invRef,
            {
              'storeId': storeId,
              'productId': productId,
              'productName': productName,
              if (category.isNotEmpty) 'category': category,
              'currentStock': after,
              'minimumStockLevel': snap.exists
                  ? (snap.data()!['minimumStockLevel'] ??
                      snap.data()!['minStockLevel'] ??
                      AppConstants.defaultMinStockLevel)
                  : AppConstants.defaultMinStockLevel,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });
        transactionSucceeded = true;
      } catch (e) {
        if (e.toString().contains('Insufficient stock')) {
          rethrow;
        }
        debugPrint('Firestore transaction fallback in _changeStock: $e');
      }
    }

    if (!transactionSucceeded) {
      // Direct atomic write - primary path on Web to avoid gRPC-WebSocket WatchChangeAggregator assertion
      var snap = await invRef.get();
      if (!snap.exists) {
        final altRef = _inv.doc('${storeId}_$productId');
        final altSnap = await altRef.get();
        if (altSnap.exists) {
          invRef = altRef;
          snap = altSnap;
        }
      }

      if (snap.exists) {
        final data = snap.data()!;
        before = (data['currentStock'] as num?)?.toInt() ?? 0;
        category = data['category'] as String? ?? '';
      }

      after = before + delta;
      if (after < 0) {
        if (type == StockMovementType.sale) {
          after = 0;
        } else {
          throw Exception('Insufficient stock. Available: $before units, attempted: ${delta.abs()} units.');
        }
      }

      await invRef.set(
        {
          'storeId': storeId,
          'productId': productId,
          'productName': productName,
          if (category.isNotEmpty) 'category': category,
          'currentStock': after,
          'minimumStockLevel': snap.exists
              ? (snap.data()!['minimumStockLevel'] ??
                  snap.data()!['minStockLevel'] ??
                  AppConstants.defaultMinStockLevel)
              : AppConstants.defaultMinStockLevel,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

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
