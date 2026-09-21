import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/loyalty_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _loyaltyService;

  LoyaltyProvider(this._loyaltyService);

  // Current state
  LoyaltyAccount? _currentAccount;
  List<LoyaltyTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Search and filter state
  List<CustomerModel> _searchResults = [];
  bool _isSearching = false;

  // Getters
  LoyaltyAccount? get currentAccount => _currentAccount;
  List<LoyaltyTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CustomerModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  bool get hasAccount => _currentAccount != null;
  int get availablePoints => _currentAccount?.availablePoints ?? 0;
  int get totalPoints => _currentAccount?.totalPoints ?? 0;
  int get redeemedPoints => _currentAccount?.redeemedPoints ?? 0;

  /// Load loyalty account by phone
  Future<void> loadAccount(String phone) async {
    _setLoading(true);
    _error = null;

    try {
      _currentAccount = await _loyaltyService.getLoyaltyAccount(phone);
      if (_currentAccount != null) {
        await loadTransactions(phone);
      }
    } catch (e) {
      _error = 'Failed to load loyalty account: $e';
      _currentAccount = null;
      _transactions = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load transaction history
  Future<void> loadTransactions(String phone, {int limit = 50}) async {
    try {
      _transactions = await _loyaltyService.getTransactions(phone, limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  /// Refresh current account
  Future<void> refresh() async {
    if (_currentAccount != null) {
      await loadAccount(_currentAccount!.phone);
    }
  }

  /// Calculate points to earn for an amount
  int calculatePointsToEarn(double amount) {
    return _loyaltyService.calculatePointsToEarn(amount);
  }

  /// Calculate rupees value of points
  double calculatePointsValue(int points) {
    return _loyaltyService.calculatePointsValue(points);
  }

  /// Validate redemption
  Future<Map<String, dynamic>> validateRedemption({
    required String phone,
    required int pointsToRedeem,
    required double billAmount,
  }) async {
    return await _loyaltyService.validateRedemption(
      phone: phone,
      pointsToRedeem: pointsToRedeem,
      billAmount: billAmount,
    );
  }

  /// Get max redeemable points for a bill
  Future<int> getMaxRedeemablePoints(String phone, double billAmount) async {
    return await _loyaltyService.getMaxRedeemablePoints(phone, billAmount);
  }

  /// Manual points adjustment
  Future<bool> adjustPoints({
    required String phone,
    required int pointsChange,
    required String reason,
    required String storeId,
    required String storeName,
    required String userId,
    required String userName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _loyaltyService.adjustPoints(
        phone: phone,
        pointsChange: pointsChange,
        reason: reason,
        storeId: storeId,
        storeName: storeName,
        userId: userId,
        userName: userName,
      );
      
      // Reload account to reflect changes
      await loadAccount(phone);
      return true;
    } catch (e) {
      _error = 'Failed to adjust points: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search customers
  Future<void> searchCustomers(String query, {String? storeId}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _loyaltyService.searchCustomers(
        query,
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('Error searching customers: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Clear current account
  void clearAccount() {
    _currentAccount = null;
    _transactions = [];
    _error = null;
    notifyListeners();
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

  /// Get loyalty statistics
  Future<Map<String, dynamic>> getLoyaltyStats({String? storeId}) async {
    return await _loyaltyService.getLoyaltyStats(storeId: storeId);
  }

  /// Get top loyalty customers
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    return await _loyaltyService.getTopLoyaltyCustomers(limit: limit);
  }
}
