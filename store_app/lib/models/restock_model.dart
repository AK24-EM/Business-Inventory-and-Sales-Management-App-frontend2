import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single restock event stored in the dedicated `restocks` collection.
/// This is separate from `stockMovements` (which tracks ALL stock changes).
/// The `restocks` collection only contains stock-IN events initiated by managers.
class RestockModel {
  final String id;
  final String storeId;
  final String storeName;
  final String productId;
  final String productName;
  final String category;
  final int quantity;        // Units added
  final int stockBefore;
  final int stockAfter;
  final double unitCost;     // Purchase price per unit (0 if unknown)
  final double totalCost;    // quantity × unitCost
  final String? supplierId;
  final String supplierName;
  final String? purchaseOrderId;
  final String performedByUserId;
  final String performedByUserName;
  final String source;       // 'quick_restock' | 'purchase_order' | 'manual'
  final String? notes;
  final DateTime timestamp;

  const RestockModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.unitCost = 0.0,
    this.totalCost = 0.0,
    this.supplierId,
    this.supplierName = '',
    this.purchaseOrderId,
    required this.performedByUserId,
    required this.performedByUserName,
    this.source = 'quick_restock',
    this.notes,
    required this.timestamp,
  });

  /// Source label for display
  String get sourceLabel {
    switch (source) {
      case 'purchase_order':
        return 'Purchase Order';
      case 'manual':
        return 'Manual Entry';
      default:
        return 'Quick Restock';
    }
  }

  factory RestockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RestockModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      stockBefore: (data['stockBefore'] as num?)?.toInt() ?? 0,
      stockAfter: (data['stockAfter'] as num?)?.toInt() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      supplierId: data['supplierId'],
      supplierName: data['supplierName'] ?? '',
      purchaseOrderId: data['purchaseOrderId'],
      performedByUserId: data['performedByUserId'] ?? '',
      performedByUserName: data['performedByUserName'] ?? '',
      source: data['source'] ?? 'quick_restock',
      notes: data['notes'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'productId': productId,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      'unitCost': unitCost,
      'totalCost': totalCost,
      if (supplierId != null) 'supplierId': supplierId,
      'supplierName': supplierName,
      if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
      'performedByUserId': performedByUserId,
      'performedByUserName': performedByUserName,
      'source': source,
      if (notes != null) 'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
