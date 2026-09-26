import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _suppliers =>
      _db.collection(AppConstants.suppliersCollection);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConstants.purchaseOrdersCollection);
  CollectionReference<Map<String, dynamic>> get _damaged =>
      _db.collection(AppConstants.damagedProductsCollection);

  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final ref = _suppliers.doc();
    final created = SupplierModel(
      id: ref.id,
      name: supplier.name,
      contactPerson: supplier.contactPerson,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      productIds: supplier.productIds,
      createdAt: DateTime.now(),
    );
    await ref.set(created.toFirestore());
    return created;
  }

  Future<void> updateSupplier(
      String supplierId, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{};
    if (data['name'] != null) payload['name'] = data['name'];
    if (data['contact_person'] != null) {
      payload['contactPerson'] = data['contact_person'];
    }
    if (data['contactPerson'] != null) {
      payload['contactPerson'] = data['contactPerson'];
    }
    if (data['phone'] != null) payload['phone'] = data['phone'];
    if (data['email'] != null) payload['email'] = data['email'];
    if (data['address'] != null) payload['address'] = data['address'];
    if (data['product_ids'] != null) payload['productIds'] = data['product_ids'];
    if (data['productIds'] != null) payload['productIds'] = data['productIds'];
    if (data['is_active'] != null) payload['isActive'] = data['is_active'];
    if (data['isActive'] != null) payload['isActive'] = data['isActive'];
    if (payload.isNotEmpty) {
      await _suppliers.doc(supplierId).update(payload);
    }
  }

  Stream<List<SupplierModel>> getSuppliersStream() {
    return _suppliers.snapshots().map(
        (snap) => snap.docs.map(SupplierModel.fromFirestore).toList());
  }

  Future<List<SupplierModel>> getAllSuppliers() async {
    final snap = await _suppliers.get();
    return snap.docs.map(SupplierModel.fromFirestore).toList();
  }

  Future<SupplierModel?> getSupplierById(String id) async {
    final doc = await _suppliers.doc(id).get();
    if (!doc.exists) return null;
    return SupplierModel.fromFirestore(doc);
  }

  String _generatePONumber() {
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString();
    return 'PO-${now.year}${now.month.toString().padLeft(2, '0')}-${suffix.substring(suffix.length - 6)}';
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder order) async {
    if (order.targetStoreId.isEmpty) {
      throw Exception('Select a store before dispatching a purchase order.');
    }
    if (order.items.isEmpty) {
      throw Exception('Add at least one item before dispatching.');
    }

    final ref = _orders.doc();
    final created = PurchaseOrder(
      id: ref.id,
      poNumber: order.poNumber.isNotEmpty ? order.poNumber : _generatePONumber(),
      supplierId: order.supplierId,
      supplierName: order.supplierName,
      items: order.items,
      totalAmount: order.totalAmount,
      status: order.status,
      createdByUserId: order.createdByUserId,
      createdByUserName: order.createdByUserName,
      createdAt: DateTime.now(),
      expectedDeliveryDate: order.expectedDeliveryDate,
      notes: order.notes,
      targetStoreId: order.targetStoreId,
      storeName: order.storeName,
    );
    await ref.set(created.toFirestore());
    return created;
  }

  Stream<List<PurchaseOrder>> getPurchaseOrdersStream({String? storeId}) {
    return _orders.snapshots().map((snap) {
      final orders = snap.docs
          .map((doc) {
            try {
              return PurchaseOrder.fromFirestore(doc);
            } catch (_) {
              return null;
            }
          })
          .whereType<PurchaseOrder>()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (storeId == null || storeId.isEmpty) return orders;
      return orders
          .where((o) =>
              o.targetStoreId == storeId || o.targetStoreId.isEmpty)
          .toList();
    });
  }

  Future<DamagedProduct> recordDamagedProduct(DamagedProduct damaged) async {
    final ref = _damaged.doc();
    final created = DamagedProduct(
      id: ref.id,
      productId: damaged.productId,
      productName: damaged.productName,
      supplierId: damaged.supplierId,
      supplierName: damaged.supplierName,
      storeId: damaged.storeId,
      quantity: damaged.quantity,
      estimatedLoss: damaged.estimatedLoss,
      reason: damaged.reason,
      reportedAt: DateTime.now(),
      reportedByUserId: damaged.reportedByUserId,
      reportedByUserName: damaged.reportedByUserName,
      notes: damaged.notes,
    );
    await ref.set(created.toFirestore());
    return created;
  }

  Stream<List<DamagedProduct>> getDamagedProductsStream({String? storeId}) {
    Query<Map<String, dynamic>> q = _damaged;
    if (storeId != null && storeId.isNotEmpty) {
      q = q.where('storeId', isEqualTo: storeId);
    }
    return q.snapshots().map(
        (snap) => snap.docs.map(DamagedProduct.fromFirestore).toList());
  }

  Stream<List<DamagedProduct>> getDamagedBySupplierStream(
      String supplierId, String storeId) {
    return getDamagedProductsStream(storeId: storeId).map(
      (list) => list.where((d) => d.supplierId == supplierId).toList(),
    );
  }
}
