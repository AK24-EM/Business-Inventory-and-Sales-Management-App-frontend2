import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String? email;
  final String address;
  final List<String> productIds; // products supplied
  final bool isActive;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    this.productIds = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierModel(
      id: doc.id,
      name: data['name'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'] ?? '',
      productIds: List<String>.from(data['productIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'productIds': productIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SupplierModel copyWith({
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    List<String>? productIds,
    bool? isActive,
  }) {
    return SupplierModel(
      id: id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      productIds: productIds ?? this.productIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final PurchaseOrderStatus status;
  final String createdByUserId;
  final String createdByUserName;
  final DateTime createdAt;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final String targetStoreId;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    this.status = PurchaseOrderStatus.draft,
    required this.createdByUserId,
    required this.createdByUserName,
    required this.createdAt,
    this.expectedDeliveryDate,
    this.notes,
    required this.targetStoreId,
  });

  factory PurchaseOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrder(
      id: doc.id,
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => PurchaseOrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: PurchaseOrderStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'draft'),
        orElse: () => PurchaseOrderStatus.draft,
      ),
      createdByUserId: data['createdByUserId'] ?? '',
      createdByUserName: data['createdByUserName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDeliveryDate:
          (data['expectedDeliveryDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      targetStoreId: data['targetStoreId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expectedDeliveryDate': expectedDeliveryDate != null
          ? Timestamp.fromDate(expectedDeliveryDate!)
          : null,
      'notes': notes,
      'targetStoreId': targetStoreId,
    };
  }
}

class PurchaseOrderItem {
  final String productId;
  final String productName;
  final int orderedQuantity;
  final int? receivedQuantity;
  final double unitPrice;
  final double totalPrice;

  const PurchaseOrderItem({
    required this.productId,
    required this.productName,
    required this.orderedQuantity,
    this.receivedQuantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> data) {
    return PurchaseOrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      orderedQuantity: data['orderedQuantity'] ?? 0,
      receivedQuantity: data['receivedQuantity'],
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'orderedQuantity': orderedQuantity,
      'receivedQuantity': receivedQuantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

enum PurchaseOrderStatus { draft, sent, received, partiallyReceived, cancelled }

class DamagedProduct {
  final String id;
  final String productId;
  final String productName;
  final String supplierId;
  final String supplierName;
  final String storeId;
  final int quantity;
  final double estimatedLoss;
  final String reason;
  final DateTime reportedAt;
  final String reportedByUserId;
  final String reportedByUserName;
  final String? notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedByUserId;
  final String? approvedByUserName;
  final DateTime? approvedAt;

  const DamagedProduct({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.storeId,
    required this.quantity,
    required this.estimatedLoss,
    required this.reason,
    required this.reportedAt,
    required this.reportedByUserId,
    required this.reportedByUserName,
    this.notes,
    this.status = 'pending',
    this.approvedByUserId,
    this.approvedByUserName,
    this.approvedAt,
  });

  factory DamagedProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DamagedProduct(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      storeId: data['storeId'] ?? '',
      quantity: data['quantity'] ?? 0,
      estimatedLoss: (data['estimatedLoss'] ?? 0).toDouble(),
      reason: data['reason'] ?? '',
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedByUserId: data['reportedByUserId'] ?? '',
      reportedByUserName: data['reportedByUserName'] ?? '',
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      approvedByUserId: data['approvedByUserId'],
      approvedByUserName: data['approvedByUserName'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'storeId': storeId,
      'quantity': quantity,
      'estimatedLoss': estimatedLoss,
      'reason': reason,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'reportedByUserId': reportedByUserId,
      'reportedByUserName': reportedByUserName,
      'notes': notes,
      'status': status,
      'approvedByUserId': approvedByUserId,
      'approvedByUserName': approvedByUserName,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  DamagedProduct copyWith({
    String? status,
    String? approvedByUserId,
    String? approvedByUserName,
    DateTime? approvedAt,
  }) {
    return DamagedProduct(
      id: id,
      productId: productId,
      productName: productName,
      supplierId: supplierId,
      supplierName: supplierName,
      storeId: storeId,
      quantity: quantity,
      estimatedLoss: estimatedLoss,
      reason: reason,
      reportedAt: reportedAt,
      reportedByUserId: reportedByUserId,
      reportedByUserName: reportedByUserName,
      notes: notes,
      status: status ?? this.status,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      approvedByUserName: approvedByUserName ?? this.approvedByUserName,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
