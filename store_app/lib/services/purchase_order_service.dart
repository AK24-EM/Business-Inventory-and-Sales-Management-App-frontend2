import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderService {
  static final PurchaseOrderService _instance = PurchaseOrderService._internal();
  factory PurchaseOrderService() => _instance;
  PurchaseOrderService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> get _purchaseOrders =>
      _db.collection('purchaseOrders');

  /// Generate unique PO number
  String _generatePONumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'PO-${now.year}${now.month.toString().padLeft(2, '0')}-${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  /// Create new purchase order
  Future<PurchaseOrderModel> createPurchaseOrder({
    required String storeId,
    required String storeName,
    required String supplierId,
    required String supplierName,
    required List<PurchaseOrderItem> items,
    required String createdBy,
    required String createdByName,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final taxAmount = subtotal * 0.18; // 18% GST
    final totalAmount = subtotal + taxAmount;

    final po = PurchaseOrderModel(
      id: '',
      poNumber: _generatePONumber(),
      storeId: storeId,
      storeName: storeName,
      supplierId: supplierId,
      supplierName: supplierName,
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      status: POStatus.submitted,
      paymentStatus: POPaymentStatus.pending,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      createdByName: createdByName,
      expectedDeliveryDate: expectedDeliveryDate,
      notes: notes,
    );

    final docRef = await _purchaseOrders.add(po.toFirestore());
    return po.copyWith(id: docRef.id);
  }

  /// Get purchase order by ID
  Future<PurchaseOrderModel?> getPurchaseOrderById(String id) async {
    final doc = await _purchaseOrders.doc(id).get();
    if (!doc.exists) return null;
    return PurchaseOrderModel.fromFirestore(doc);
  }

  /// Get purchase orders by store
  Future<List<PurchaseOrderModel>> getPurchaseOrdersByStore(String storeId) async {
    final snapshot = await _purchaseOrders
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => PurchaseOrderModel.fromFirestore(doc)).toList();
  }

  /// Stream purchase orders by store
  Stream<List<PurchaseOrderModel>> watchPurchaseOrdersByStore(String storeId) {
    return _purchaseOrders
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Get purchase orders by status
  Future<List<PurchaseOrderModel>> getPurchaseOrdersByStatus(
    String storeId,
    POStatus status,
  ) async {
    final snapshot = await _purchaseOrders
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => PurchaseOrderModel.fromFirestore(doc)).toList();
  }

  /// Stream purchase orders by status
  Stream<List<PurchaseOrderModel>> watchPurchaseOrdersByStatus(
    String storeId,
    POStatus status,
  ) {
    return _purchaseOrders
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Get pending purchase orders (submitted, approved, inTransit)
  Stream<List<PurchaseOrderModel>> watchPendingPurchaseOrders(String storeId) {
    return _purchaseOrders
        .where('storeId', isEqualTo: storeId)
        .where('status', whereIn: [POStatus.submitted.name, POStatus.approved.name, POStatus.inTransit.name])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Approve purchase order
  Future<void> approvePurchaseOrder(
    String poId,
    String approvedBy,
  ) async {
    await _purchaseOrders.doc(poId).update({
      'status': POStatus.approved.name,
      'approvedAt': Timestamp.now(),
      'approvedBy': approvedBy,
    });
  }

  /// Reject purchase order
  Future<void> rejectPurchaseOrder(
    String poId,
    String rejectionReason,
  ) async {
    await _purchaseOrders.doc(poId).update({
      'status': POStatus.rejected.name,
      'rejectionReason': rejectionReason,
    });
  }

  /// Mark as in transit
  Future<void> markInTransit(String poId) async {
    await _purchaseOrders.doc(poId).update({
      'status': POStatus.inTransit.name,
    });
  }

  /// Receive purchase order (mark as received and update inventory)
  Future<void> receivePurchaseOrder(
    String poId,
    String receivedBy,
  ) async {
    await _purchaseOrders.doc(poId).update({
      'status': POStatus.received.name,
      'receivedAt': Timestamp.now(),
      'receivedBy': receivedBy,
    });

    // TODO: Update inventory stock levels
    // This should be handled by a separate inventory update function
  }

  /// Cancel purchase order
  Future<void> cancelPurchaseOrder(String poId) async {
    await _purchaseOrders.doc(poId).update({
      'status': POStatus.cancelled.name,
    });
  }

  /// Update purchase order
  Future<void> updatePurchaseOrder(
    String poId,
    Map<String, dynamic> updates,
  ) async {
    await _purchaseOrders.doc(poId).update(updates);
  }

  /// Delete purchase order (only if draft or rejected)
  Future<void> deletePurchaseOrder(String poId) async {
    final po = await getPurchaseOrderById(poId);
    if (po != null && (po.status == POStatus.draft || po.status == POStatus.rejected)) {
      await _purchaseOrders.doc(poId).delete();
    } else {
      throw Exception('Can only delete draft or rejected purchase orders');
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getPurchaseOrderStats(String storeId) async {
    final allPOs = await getPurchaseOrdersByStore(storeId);
    
    final activePOs = allPOs.where((po) => 
      po.status == POStatus.submitted || 
      po.status == POStatus.approved || 
      po.status == POStatus.inTransit
    ).length;
    
    final committedValue = allPOs
        .where((po) => po.status == POStatus.approved || po.status == POStatus.inTransit)
        .fold<double>(0, (sum, po) => sum + po.totalAmount);
    
    final receivedThisMonth = allPOs.where((po) {
      if (po.receivedAt == null) return false;
      final now = DateTime.now();
      return po.receivedAt!.year == now.year && po.receivedAt!.month == now.month;
    }).length;

    return {
      'activePOs': activePOs,
      'committedValue': committedValue,
      'receivedThisMonth': receivedThisMonth,
      'totalPOs': allPOs.length,
    };
  }
}
