import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/product_model.dart';
import '../services/inventory_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  ProductProvider() {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    _sub = _col.snapshots().listen(
      (snap) {
        _products = snap.docs.map(ProductModel.fromFirestore).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.productsCollection);

  List<ProductModel> get filteredProducts {
    var list = _products.where((p) => p.isActive).toList();
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              (p.barcode?.contains(q) ?? false))
          .toList();
    }
    return list;
  }

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  Stream<List<ProductModel>> get productsStream =>
      _col.snapshots().map((snap) =>
          snap.docs.map(ProductModel.fromFirestore).toList());

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _col.get();
      _products = snap.docs.map(ProductModel.fromFirestore).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<ProductModel> addProduct(
    ProductModel product, {
    int initialStock = 0,
    int minStock = AppConstants.defaultMinStockLevel,
    String? storeId,
    String? userId,
    String? userName,
  }) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final created = ProductModel(
      id: ref.id,
      name: product.name,
      category: product.category,
      description: product.description,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      unit: product.unit,
      barcode: product.barcode,
      supplierId: product.supplierId,
      imageUrl: product.imageUrl,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(created.toFirestore());

    // Automatically initialize inventory for the store so the product can be sold immediately
    final targetStore = (storeId != null && storeId.isNotEmpty) ? storeId : 'store_01';
    await _inventoryService.initializeInventoryForProduct(
      storeId: targetStore,
      productId: created.id,
      productName: created.name,
      category: created.category,
      initialStock: initialStock,
      minStock: minStock,
      userId: userId,
      userName: userName,
    );

    return created;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (data.containsKey('purchasePrice')) {
      payload['purchasePrice'] = data['purchasePrice'];
    }
    if (data.containsKey('sellingPrice')) {
      payload['sellingPrice'] = data['sellingPrice'];
    }
    if (data.containsKey('name')) payload['name'] = data['name'];
    if (data.containsKey('category')) payload['category'] = data['category'];
    if (data.containsKey('description')) {
      payload['description'] = data['description'];
    }
    if (data.containsKey('unit')) payload['unit'] = data['unit'];
    if (data.containsKey('barcode')) payload['barcode'] = data['barcode'];
    await _col.doc(productId).update(payload);
    await loadProducts();
  }

  Future<void> deactivateProduct(String productId) async {
    await _col.doc(productId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await loadProducts();
  }

  ProductModel? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProductModel? getByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}
