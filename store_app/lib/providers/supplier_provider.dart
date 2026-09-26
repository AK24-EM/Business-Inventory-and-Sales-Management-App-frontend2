import 'package:flutter/foundation.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _supplierService;

  SupplierProvider(this._supplierService);

  // State
  List<SupplierModel> _suppliers = [];
  List<PurchaseOrder> _purchaseOrders = [];
  List<DamagedProduct> _damagedProducts = [];
  bool _isLoading = false;
  String? _error;

  // Selected items for detail view
  SupplierModel? _selectedSupplier;
  PurchaseOrder? _selectedOrder;

  // Getters
  List<SupplierModel> get suppliers => _suppliers;
  List<SupplierModel> get activeSuppliers =>
      _suppliers.where((s) => s.isActive).toList();
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  List<DamagedProduct> get damagedProducts => _damagedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SupplierModel? get selectedSupplier => _selectedSupplier;
  PurchaseOrder? get selectedOrder => _selectedOrder;

  /// Load all suppliers
  Future<void> loadSuppliers() async {
    _setLoading(true);
    _error = null;

    try {
      _suppliers = await _supplierService.getAllSuppliers();
      _suppliers.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = 'Failed to load suppliers: $e';
      _suppliers = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Add new supplier
  Future<bool> addSupplier({
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    required String address,
    List<String>? productIds,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final supplier = SupplierModel(
        id: '',
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        productIds: productIds ?? [],
        createdAt: DateTime.now(),
      );

      final created = await _supplierService.addSupplier(supplier);
      _suppliers.add(created);
      _suppliers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add supplier: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update supplier
  Future<bool> updateSupplier(
    String supplierId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      await _supplierService.updateSupplier(supplierId, data);
      
      // Update local state
      final index = _suppliers.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        final supplier = _suppliers[index];
        _suppliers[index] = supplier.copyWith(
          name: data['name'] ?? supplier.name,
          contactPerson: data['contactPerson'] ?? 
                        data['contact_person'] ?? 
                        supplier.contactPerson,
          phone: data['phone'] ?? supplier.phone,
          email: data['email'] ?? supplier.email,
          address: data['address'] ?? supplier.address,
          productIds: data['productIds'] ?? 
                     data['product_ids'] ?? 
                     supplier.productIds,
          isActive: data['isActive'] ?? 
                   data['is_active'] ?? 
                   supplier.isActive,
        );
        _suppliers.sort((a, b) => a.name.compareTo(b.name));
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update supplier: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle supplier active status
  Future<bool> toggleSupplierStatus(String supplierId) async {
    final supplier = _suppliers.firstWhere((s) => s.id == supplierId);
    return await updateSupplier(supplierId, {'isActive': !supplier.isActive});
  }

  /// Get supplier by ID
  SupplierModel? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Select supplier for detail view
  void selectSupplier(String supplierId) {
    _selectedSupplier = getSupplierById(supplierId);
    notifyListeners();
  }

  /// Clear selected supplier
  void clearSelectedSupplier() {
    _selectedSupplier = null;
    notifyListeners();
  }

  /// Create purchase order
  Future<bool> createPurchaseOrder({
    required String supplierId,
    required List<PurchaseOrderItem> items,
    required String targetStoreId,
    required String userId,
    required String userName,
    String storeName = '',
    String? supplierName,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      if (supplierId.isEmpty) {
        _error = 'Select a supplier before dispatching.';
        return false;
      }
      if (targetStoreId.isEmpty) {
        _error = 'No store selected. Choose a store and try again.';
        return false;
      }
      if (items.isEmpty) {
        _error = 'Add at least one product to the purchase order.';
        return false;
      }

      SupplierModel? supplier;
      try {
        supplier = await _supplierService.getSupplierById(supplierId);
      } catch (_) {
        supplier = null;
      }

      final resolvedName = (supplier?.name.isNotEmpty == true)
          ? supplier!.name
          : (supplierName ?? '').trim();
      if (resolvedName.isEmpty) {
        _error = 'Supplier not found. Add a real supplier before dispatching.';
        return false;
      }

      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final order = PurchaseOrder(
        id: '',
        supplierId: supplierId,
        supplierName: resolvedName,
        items: items,
        totalAmount: totalAmount,
        status: PurchaseOrderStatus.sent,
        createdByUserId: userId,
        createdByUserName: userName,
        createdAt: DateTime.now(),
        expectedDeliveryDate: expectedDeliveryDate,
        notes: notes,
        targetStoreId: targetStoreId,
        storeName: storeName,
      );

      final created = await _supplierService.createPurchaseOrder(order);
      _purchaseOrders.add(created);
      _purchaseOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create purchase order: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load purchase orders
  Future<void> loadPurchaseOrders({String? storeId}) async {
    // This will be handled by stream subscription in the UI
    // For now, just clear error
    _error = null;
    notifyListeners();
  }

  /// Update purchase orders from stream
  void updatePurchaseOrders(List<PurchaseOrder> orders) {
    _purchaseOrders = orders;
    _purchaseOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Select order for detail view
  void selectOrder(String orderId) {
    try {
      _selectedOrder = _purchaseOrders.firstWhere((o) => o.id == orderId);
      notifyListeners();
    } catch (e) {
      _selectedOrder = null;
    }
  }

  /// Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  /// Get orders by status
  List<PurchaseOrder> getOrdersByStatus(PurchaseOrderStatus status) {
    return _purchaseOrders.where((o) => o.status == status).toList();
  }

  /// Get orders by supplier
  List<PurchaseOrder> getOrdersBySupplier(String supplierId) {
    return _purchaseOrders.where((o) => o.supplierId == supplierId).toList();
  }

  /// Record damaged product
  Future<bool> recordDamagedProduct({
    required String productId,
    required String productName,
    required String supplierId,
    required String storeId,
    required int quantity,
    required double estimatedLoss,
    required String reason,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final supplier = await _supplierService.getSupplierById(supplierId);
      if (supplier == null) {
        _error = 'Supplier not found';
        return false;
      }

      final damaged = DamagedProduct(
        id: '',
        productId: productId,
        productName: productName,
        supplierId: supplierId,
        supplierName: supplier.name,
        storeId: storeId,
        quantity: quantity,
        estimatedLoss: estimatedLoss,
        reason: reason,
        reportedAt: DateTime.now(),
        reportedByUserId: userId,
        reportedByUserName: userName,
        notes: notes,
      );

      final created = await _supplierService.recordDamagedProduct(damaged);
      _damagedProducts.add(created);
      _damagedProducts.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to record damaged product: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update damaged products from stream
  void updateDamagedProducts(List<DamagedProduct> products) {
    _damagedProducts = products;
    _damagedProducts.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    notifyListeners();
  }

  /// Get damaged products by supplier
  List<DamagedProduct> getDamagedBySupplier(String supplierId) {
    return _damagedProducts.where((d) => d.supplierId == supplierId).toList();
  }

  /// Calculate supplier statistics
  Map<String, dynamic> getSupplierStats(String supplierId) {
    final orders = getOrdersBySupplier(supplierId);
    final damaged = getDamagedBySupplier(supplierId);

    final totalOrders = orders.length;
    final completedOrders =
        orders.where((o) => o.status == PurchaseOrderStatus.received).length;
    final pendingOrders = orders.where((o) =>
        o.status == PurchaseOrderStatus.sent ||
        o.status == PurchaseOrderStatus.draft).length;

    final totalOrderValue =
        orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalDamagedValue =
        damaged.fold<double>(0, (sum, d) => sum + d.estimatedLoss);
    final totalDamagedItems = damaged.fold<int>(0, (sum, d) => sum + d.quantity);

    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'totalOrderValue': totalOrderValue,
      'totalDamagedItems': totalDamagedItems,
      'totalDamagedValue': totalDamagedValue,
      'damagedPercentage': totalOrderValue > 0
          ? (totalDamagedValue / totalOrderValue) * 100
          : 0.0,
    };
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
