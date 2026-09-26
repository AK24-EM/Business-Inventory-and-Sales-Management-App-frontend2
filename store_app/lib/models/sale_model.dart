import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMode { cash, upi, card }

extension PaymentModeExtension on PaymentMode {
  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
    }
  }

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMode.cash,
    );
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SaleItem.fromMap(Map<String, dynamic> data) {
    return SaleItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class SaleModel {
  final String id;
  final String storeId;
  final String storeName;
  final List<SaleItem> items;
  final double subtotal;
  final double discountAmount;
  final double loyaltyPointsRedeemed;
  final double totalAmount;
  final PaymentMode paymentMode;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final int loyaltyPointsEarned;
  final String employeeId;
  final String employeeName;
  final DateTime timestamp;
  final String? invoiceNumber;
  final bool isReturned;

  const SaleModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.loyaltyPointsRedeemed = 0,
    required this.totalAmount,
    required this.paymentMode,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.loyaltyPointsEarned = 0,
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    this.invoiceNumber,
    this.isReturned = false,
  });

  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  factory SaleModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Sale document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Sale document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> saleData = data as Map<String, dynamic>;
    final itemsList = (saleData['items'] as List<dynamic>?)
            ?.map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SaleModel(
      id: doc.id,
      storeId: saleData['storeId'] ?? '',
      storeName: saleData['storeName'] ?? '',
      items: itemsList,
      subtotal: (saleData['subtotal'] ?? 0).toDouble(),
      discountAmount: (saleData['discountAmount'] ?? 0).toDouble(),
      loyaltyPointsRedeemed: (saleData['loyaltyPointsRedeemed'] ?? 0).toDouble(),
      totalAmount: (saleData['totalAmount'] ?? 0).toDouble(),
      paymentMode: PaymentModeExtension.fromString(saleData['paymentMode'] ?? 'cash'),
      customerId: saleData['customerId'],
      customerName: saleData['customerName'],
      customerPhone: saleData['customerPhone'],
      loyaltyPointsEarned: saleData['loyaltyPointsEarned'] ?? 0,
      employeeId: saleData['employeeId'] ?? '',
      employeeName: saleData['employeeName'] ?? '',
      timestamp: (saleData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invoiceNumber: saleData['invoiceNumber'],
      isReturned: saleData['isReturned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'loyaltyPointsRedeemed': loyaltyPointsRedeemed,
      'totalAmount': totalAmount,
      'paymentMode': paymentMode.name,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'loyaltyPointsEarned': loyaltyPointsEarned,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'timestamp': Timestamp.fromDate(timestamp),
      'invoiceNumber': invoiceNumber,
      'isReturned': isReturned,
    };
  }
}
