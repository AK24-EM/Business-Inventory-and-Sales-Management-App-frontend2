import 'package:cloud_firestore/cloud_firestore.dart';

class FestivalModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int advanceOrderDays; // days before festival to place order
  final bool isActive;
  final DateTime createdAt;

  const FestivalModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.advanceOrderDays = 14,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  DateTime get alertDate =>
      startDate.subtract(Duration(days: advanceOrderDays));

  bool get needsAlert =>
      DateTime.now().isAfter(alertDate) && DateTime.now().isBefore(startDate);

  factory FestivalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FestivalModel(
      id: doc.id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      advanceOrderDays: data['advanceOrderDays'] ?? 14,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'advanceOrderDays': advanceOrderDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class FestivalDemandAlert {
  final String id;
  final String festivalId;
  final String festivalName;
  final String productId;
  final String productName;
  final String storeId;
  final int historicalAvgSales;
  final int recommendedStock;
  final int currentStock;
  final int stockShortfall;
  final bool isAcknowledged;
  final DateTime createdAt;

  const FestivalDemandAlert({
    required this.id,
    required this.festivalId,
    required this.festivalName,
    required this.productId,
    required this.productName,
    required this.storeId,
    required this.historicalAvgSales,
    required this.recommendedStock,
    required this.currentStock,
    required this.stockShortfall,
    this.isAcknowledged = false,
    required this.createdAt,
  });

  factory FestivalDemandAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FestivalDemandAlert(
      id: doc.id,
      festivalId: data['festivalId'] ?? '',
      festivalName: data['festivalName'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      storeId: data['storeId'] ?? '',
      historicalAvgSales: data['historicalAvgSales'] ?? 0,
      recommendedStock: data['recommendedStock'] ?? 0,
      currentStock: data['currentStock'] ?? 0,
      stockShortfall: data['stockShortfall'] ?? 0,
      isAcknowledged: data['isAcknowledged'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'festivalId': festivalId,
      'festivalName': festivalName,
      'productId': productId,
      'productName': productName,
      'storeId': storeId,
      'historicalAvgSales': historicalAvgSales,
      'recommendedStock': recommendedStock,
      'currentStock': currentStock,
      'stockShortfall': stockShortfall,
      'isAcknowledged': isAcknowledged,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
