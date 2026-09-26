import 'package:cloud_firestore/cloud_firestore.dart';

enum POStatus {
  draft,
  submitted,
  approved,
  rejected,
  inTransit,
  received,
  cancelled,
}

enum POPaymentStatus {
  pending,
  partial,
  paid,
}

class PurchaseOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  const PurchaseOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ??
          (map['orderedQuantity'] as num?)?.toInt() ??
          0,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

class PurchaseOrderModel {
  final String id;
  final String poNumber;
  final String storeId;
  final String storeName;
  final String supplierId;
  final String supplierName;
  final List<PurchaseOrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final POStatus status;
  final POPaymentStatus paymentStatus;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? receivedAt;
  final String? receivedBy;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final String? rejectionReason;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.storeId,
    required this.storeName,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.approvedAt,
    this.approvedBy,
    this.receivedAt,
    this.receivedBy,
    this.expectedDeliveryDate,
    this.notes,
    this.rejectionReason,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'poNumber': poNumber,
      'storeId': storeId,
      'storeName': storeName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'receivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
      'receivedBy': receivedBy,
      'expectedDeliveryDate': expectedDeliveryDate != null ? Timestamp.fromDate(expectedDeliveryDate!) : null,
      'notes': notes,
      'rejectionReason': rejectionReason,
    };
  }

  factory PurchaseOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrderModel(
      id: doc.id,
      poNumber: data['poNumber'] as String,
      storeId: data['storeId'] as String,
      storeName: data['storeName'] as String,
      supplierId: data['supplierId'] as String,
      supplierName: data['supplierName'] as String,
      items: (data['items'] as List<dynamic>)
          .map((item) => PurchaseOrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num).toDouble(),
      taxAmount: (data['taxAmount'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      status: POStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => POStatus.draft,
      ),
      paymentStatus: POPaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => POPaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      createdByName: data['createdByName'] as String,
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      approvedBy: data['approvedBy'] as String?,
      receivedAt: data['receivedAt'] != null ? (data['receivedAt'] as Timestamp).toDate() : null,
      receivedBy: data['receivedBy'] as String?,
      expectedDeliveryDate: data['expectedDeliveryDate'] != null ? (data['expectedDeliveryDate'] as Timestamp).toDate() : null,
      notes: data['notes'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  PurchaseOrderModel copyWith({
    String? id,
    String? poNumber,
    String? storeId,
    String? storeName,
    String? supplierId,
    String? supplierName,
    List<PurchaseOrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    POStatus? status,
    POPaymentStatus? paymentStatus,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? receivedAt,
    String? receivedBy,
    DateTime? expectedDeliveryDate,
    String? notes,
    String? rejectionReason,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedBy: receivedBy ?? this.receivedBy,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
