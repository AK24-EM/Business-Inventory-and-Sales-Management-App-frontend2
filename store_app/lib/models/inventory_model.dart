import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores per-store stock levels for each product
class InventoryModel {
  final String id; // storeId_productId
  final String storeId;
  final String productId;
  final String productName;
  final String category;
  final int currentStock;
  final int minimumStockLevel;
  final int maximumStockLevel;
  final String? imageUrl;
  final DateTime lastUpdated;

  const InventoryModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.category,
    required this.currentStock,
    required this.minimumStockLevel,
    this.maximumStockLevel = 0,
    this.imageUrl,
    required this.lastUpdated,
  });

  bool get isLowStock => currentStock <= minimumStockLevel;
  bool get isOutOfStock => currentStock == 0;
  int get stockDeficit =>
      isLowStock ? minimumStockLevel - currentStock : 0;

  factory InventoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InventoryModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      currentStock: data['currentStock'] ?? 0,
      minimumStockLevel: data['minimumStockLevel'] ?? 0,
      maximumStockLevel: data['maximumStockLevel'] ?? 0,
      imageUrl: data['imageUrl'],
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'productId': productId,
      'productName': productName,
      'category': category,
      'currentStock': currentStock,
      'minimumStockLevel': minimumStockLevel,
      'maximumStockLevel': maximumStockLevel,
      'imageUrl': imageUrl,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  InventoryModel copyWith({
    int? currentStock,
    int? minimumStockLevel,
    int? maximumStockLevel,
    String? productName,
    String? imageUrl,
  }) {
    return InventoryModel(
      id: id,
      storeId: storeId,
      productId: productId,
      productName: productName ?? this.productName,
      category: category,
      currentStock: currentStock ?? this.currentStock,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      maximumStockLevel: maximumStockLevel ?? this.maximumStockLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: DateTime.now(),
    );
  }
}

enum StockMovementType {
  receipt,    // Stock received from supplier
  sale,       // Stock sold
  adjustment, // Manual correction
  transferOut, // Sent to another store
  transferIn,  // Received from another store
  damaged,    // Damaged/expired
}

extension StockMovementTypeExtension on StockMovementType {
  String get displayName {
    switch (this) {
      case StockMovementType.receipt:
        return 'Stock Receipt';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.transferOut:
        return 'Transfer Out';
      case StockMovementType.transferIn:
        return 'Transfer In';
      case StockMovementType.damaged:
        return 'Damaged/Expired';
    }
  }

  bool get isIncrease =>
      this == StockMovementType.receipt ||
      this == StockMovementType.transferIn;

  static StockMovementType fromString(String value) {
    return StockMovementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockMovementType.adjustment,
    );
  }
}

enum AdjustmentReason { damage, expiry, countCorrection, other }

extension AdjustmentReasonExtension on AdjustmentReason {
  String get displayName {
    switch (this) {
      case AdjustmentReason.damage:
        return 'Damage';
      case AdjustmentReason.expiry:
        return 'Expiry';
      case AdjustmentReason.countCorrection:
        return 'Count Correction';
      case AdjustmentReason.other:
        return 'Other';
    }
  }

  static AdjustmentReason fromString(String value) {
    return AdjustmentReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdjustmentReason.other,
    );
  }
}

class StockMovement {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity; // always positive; direction inferred from type
  final int stockBefore;
  final int stockAfter;
  final String? reason;
  final AdjustmentReason? adjustmentReason;
  final String? referenceId; // saleId / transferId / purchaseOrderId
  final String userId;
  final String userName;
  final DateTime timestamp;

  const StockMovement({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.reason,
    this.adjustmentReason,
    this.referenceId,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory StockMovement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockMovement(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: StockMovementTypeExtension.fromString(data['type'] ?? ''),
      quantity: data['quantity'] ?? 0,
      stockBefore: data['stockBefore'] ?? 0,
      stockAfter: data['stockAfter'] ?? 0,
      reason: data['reason'],
      adjustmentReason: data['adjustmentReason'] != null
          ? AdjustmentReasonExtension.fromString(data['adjustmentReason'])
          : null,
      referenceId: data['referenceId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      'reason': reason,
      'adjustmentReason': adjustmentReason?.name,
      'referenceId': referenceId,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class StockTransfer {
  final String id;
  final String sourceStoreId;
  final String destinationStoreId;
  final String productId;
  final String productName;
  final int quantity;
  final String initiatedByUserId;
  final String initiatedByUserName;
  final DateTime initiatedAt;
  final String? confirmedByUserId;
  final String? confirmedByUserName;
  final DateTime? confirmedAt;
  final TransferStatus status;
  final String? notes;

  const StockTransfer({
    required this.id,
    required this.sourceStoreId,
    required this.destinationStoreId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.initiatedByUserId,
    required this.initiatedByUserName,
    required this.initiatedAt,
    this.confirmedByUserId,
    this.confirmedByUserName,
    this.confirmedAt,
    this.status = TransferStatus.pending,
    this.notes,
  });

  factory StockTransfer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockTransfer(
      id: doc.id,
      sourceStoreId: data['sourceStoreId'] ?? '',
      destinationStoreId: data['destinationStoreId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      initiatedByUserId: data['initiatedByUserId'] ?? '',
      initiatedByUserName: data['initiatedByUserName'] ?? '',
      initiatedAt:
          (data['initiatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedByUserId: data['confirmedByUserId'],
      confirmedByUserName: data['confirmedByUserName'],
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      status: TransferStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TransferStatus.pending,
      ),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sourceStoreId': sourceStoreId,
      'destinationStoreId': destinationStoreId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'initiatedByUserId': initiatedByUserId,
      'initiatedByUserName': initiatedByUserName,
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'confirmedByUserId': confirmedByUserId,
      'confirmedByUserName': confirmedByUserName,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'status': status.name,
      'notes': notes,
    };
  }
}

enum TransferStatus { pending, confirmed, cancelled }
