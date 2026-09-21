import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';
import '../services/sales_service.dart';

class CartItem {
  final String productId;
  final String productName;
  final String category;
  final double unitPrice;
  int quantity;
  final int availableStock;

  CartItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    required this.availableStock,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        productName: productName,
        category: category,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        availableStock: availableStock,
      );
}

class SalesProvider extends ChangeNotifier {
  final SalesService _service;

  // Cart state
  final List<CartItem> _cart = [];
  String? _customerPhone;
  String? _customerId;
  String? _customerName;
  int _availableLoyaltyPoints = 0;
  double _pointsRedeemed = 0;
  PaymentMode _paymentMode = PaymentMode.cash;
  bool _isProcessing = false;
  String? _error;

  SalesProvider(this._service);

  // Cart getters
  List<CartItem> get cart => List.unmodifiable(_cart);
  bool get cartIsEmpty => _cart.isEmpty;
  int get cartItemCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get subtotal => _cart.fold(0.0, (s, i) => s + i.totalPrice);
  double get pointsDiscount => _pointsRedeemed;
  double get totalAmount =>
      (subtotal - pointsDiscount).clamp(0.0, double.infinity);
  int get pointsToEarn => (totalAmount * 1).round();

  // Customer
  String? get customerPhone => _customerPhone;
  String? get customerId => _customerId;
  String? get customerName => _customerName;
  int get availableLoyaltyPoints => _availableLoyaltyPoints;

  // Other
  PaymentMode get paymentMode => _paymentMode;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  void addToCart(CartItem item) {
    final idx = _cart.indexWhere((c) => c.productId == item.productId);
    if (idx != -1) {
      final existing = _cart[idx];
      if (existing.quantity + item.quantity <= existing.availableStock) {
        _cart[idx] = existing.copyWith(
            quantity: existing.quantity + item.quantity);
      }
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final idx = _cart.indexWhere((c) => c.productId == productId);
    if (idx != -1) {
      if (quantity <= 0) {
        _cart.removeAt(idx);
      } else if (quantity <= _cart[idx].availableStock) {
        _cart[idx] = _cart[idx].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((c) => c.productId == productId);
    notifyListeners();
  }

  void setCustomer({
    required String phone,
    String? id,
    String? name,
    int availablePoints = 0,
  }) {
    _customerPhone = phone;
    _customerId = id;
    _customerName = name;
    _availableLoyaltyPoints = availablePoints;
    notifyListeners();
  }

  void clearCustomer() {
    _customerPhone = null;
    _customerId = null;
    _customerName = null;
    _availableLoyaltyPoints = 0;
    _pointsRedeemed = 0;
    notifyListeners();
  }

  void redeemPoints(double amount) {
    _pointsRedeemed = amount.clamp(0, subtotal * 0.20);
    notifyListeners();
  }

  void setPaymentMode(PaymentMode mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _customerPhone = null;
    _customerId = null;
    _customerName = null;
    _availableLoyaltyPoints = 0;
    _pointsRedeemed = 0;
    _paymentMode = PaymentMode.cash;
    _error = null;
    notifyListeners();
  }

  Future<SaleModel?> completeSale({
    required String storeId,
    required String storeName,
    required String employeeId,
    required String employeeName,
  }) async {
    if (_cart.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final items = _cart
          .map((c) => SaleItem(
                productId: c.productId,
                productName: c.productName,
                category: c.category,
                quantity: c.quantity,
                unitPrice: c.unitPrice,
                totalPrice: c.totalPrice,
              ))
          .toList();

      final sale = await _service.completeSale(
        storeId: storeId,
        storeName: storeName,
        items: items,
        paymentMode: _paymentMode,
        employeeId: employeeId,
        employeeName: employeeName,
        customerId: _customerId,
        customerName: _customerName,
        customerPhone: _customerPhone,
        loyaltyPointsRedeemed: _pointsRedeemed,
      );

      clearCart();
      return sale;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Stream<List<SaleModel>> watchTodaySales(String storeId) =>
      _service.getTodaySalesStream(storeId);
}
