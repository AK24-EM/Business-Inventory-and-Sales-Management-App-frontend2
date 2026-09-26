import 'package:cloud_firestore/cloud_firestore.dart';

enum FestivalPhase { upcoming, orderWindow, urgent, ongoing, past }

enum FestivalAlertKind { timeline, stock }

class FestivalModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int advanceOrderDays;
  final bool isActive;
  final DateTime createdAt;
  final String? storeId;
  final String? createdBy;

  const FestivalModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.advanceOrderDays = 14,
    this.isActive = true,
    required this.createdAt,
    this.storeId,
    this.createdBy,
  });

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get startDay =>
      DateTime(startDate.year, startDate.month, startDate.day);

  DateTime get endDay => DateTime(endDate.year, endDate.month, endDate.day);

  bool get isUpcoming => startDay.isAfter(_today);
  bool get isOngoing => !_today.isBefore(startDay) && !_today.isAfter(endDay);
  bool get isPast => _today.isAfter(endDay);

  int get daysUntilStart => startDay.difference(_today).inDays;
  int get durationDays {
    final days = endDay.difference(startDay).inDays;
    return days < 1 ? 1 : days;
  }

  DateTime get alertDate =>
      startDay.subtract(Duration(days: advanceOrderDays));

  bool get needsAlert =>
      !_today.isBefore(alertDate) && _today.isBefore(startDay);

  bool get isUrgent => isUpcoming && daysUntilStart <= 7;

  FestivalPhase get phase {
    if (isPast) return FestivalPhase.past;
    if (isOngoing) return FestivalPhase.ongoing;
    if (isUrgent) return FestivalPhase.urgent;
    if (needsAlert) return FestivalPhase.orderWindow;
    return FestivalPhase.upcoming;
  }

  bool get requiresManagerAction =>
      phase == FestivalPhase.orderWindow ||
      phase == FestivalPhase.urgent ||
      phase == FestivalPhase.ongoing;

  factory FestivalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FestivalModel(
      id: doc.id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      advanceOrderDays: data['advanceOrderDays'] ?? 14,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storeId: data['storeId'] as String?,
      createdBy: data['createdBy'] as String?,
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
      if (storeId != null) 'storeId': storeId,
      if (createdBy != null) 'createdBy': createdBy,
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
  final String kind;
  final String severity;
  final String phase;
  final String message;
  final String category;

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
    this.kind = 'stock',
    this.severity = 'warning',
    this.phase = '',
    this.message = '',
    this.category = '',
  });

  FestivalAlertKind get alertKind => kind == 'timeline'
      ? FestivalAlertKind.timeline
      : FestivalAlertKind.stock;

  factory FestivalDemandAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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
      kind: data['kind'] ?? 'stock',
      severity: data['severity'] ?? 'warning',
      phase: data['phase'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? '',
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
      'kind': kind,
      'severity': severity,
      'phase': phase,
      'message': message,
      'category': category,
    };
  }
}
