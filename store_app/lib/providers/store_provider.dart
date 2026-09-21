import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/store_model.dart';

/// Stores are persisted in Firestore (same auth session as login).
/// Cloud Run SQL is not used here — POST /stores was returning 401 for
/// Firebase-only accounts, which blocked Add Store in the UI.
class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<StoreModel> _stores = [];
  StoreModel? _selectedStore;
  bool _isLoading = false;
  String? _error;

  List<StoreModel> get stores => _stores;
  StoreModel? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.storesCollection);

  Future<void> loadStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snap = await _col.get();
      _stores = snap.docs
          .map(StoreModel.fromFirestore)
          .where((s) => s.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (_stores.isNotEmpty &&
          (_selectedStore == null ||
              _stores.every((s) => s.id != _selectedStore!.id))) {
        _selectedStore = _stores.first;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void selectStore(StoreModel store) {
    _selectedStore = store;
    notifyListeners();
  }

  Future<StoreModel> addStore(StoreModel store) async {
    final activeCount = _stores.where((s) => s.isActive).length;
    if (activeCount >= AppConstants.maxStores) {
      throw Exception('You can add at most ${AppConstants.maxStores} stores.');
    }

    final ref = _col.doc();
    final created = StoreModel(
      id: ref.id,
      name: store.name,
      address: store.address,
      city: store.city,
      phone: store.phone,
      email: store.email,
      managerId: store.managerId,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await ref.set(created.toFirestore());
    _stores.add(created);
    _selectedStore ??= created;
    notifyListeners();
    return created;
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{};
    if (data.containsKey('name')) payload['name'] = data['name'];
    if (data.containsKey('address')) payload['address'] = data['address'];
    if (data.containsKey('city')) payload['city'] = data['city'];
    if (data.containsKey('phone')) payload['phone'] = data['phone'];
    if (data.containsKey('email')) payload['email'] = data['email'];
    if (data.containsKey('manager_id')) {
      payload['managerId'] = data['manager_id'];
    }
    if (data.containsKey('managerId')) {
      payload['managerId'] = data['managerId'];
    }
    if (data.containsKey('is_active')) payload['isActive'] = data['is_active'];
    if (data.containsKey('isActive')) payload['isActive'] = data['isActive'];
    if (payload.isNotEmpty) {
      await _col.doc(storeId).update(payload);
    }
    await loadStores();
  }

  StoreModel? getStoreById(String id) {
    try {
      return _stores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
