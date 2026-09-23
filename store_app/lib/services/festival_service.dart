import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/festival_model.dart';
import 'notification_service.dart';

/// Service for managing festivals and demand planning
class FestivalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _festivals =>
      _db.collection('festivals');

  /// Create a new festival
  Future<FestivalModel> createFestival(FestivalModel festival) async {
    final ref = _festivals.doc();
    final created = FestivalModel(
      id: ref.id,
      name: festival.name,
      startDate: festival.startDate,
      endDate: festival.endDate,
      advanceOrderDays: festival.advanceOrderDays,
      isActive: festival.isActive,
      createdAt: DateTime.now(),
    );
    await ref.set(created.toFirestore());
    return created;
  }

  /// Update festival
  Future<void> updateFestival(String festivalId, Map<String, dynamic> data) async {
    await _festivals.doc(festivalId).update(data);
  }

  /// Delete festival
  Future<void> deleteFestival(String festivalId) async {
    await _festivals.doc(festivalId).delete();
  }

  /// Get all festivals
  Future<List<FestivalModel>> getAllFestivals() async {
    final snap = await _festivals
        .where('isActive', isEqualTo: true)
        .orderBy('startDate')
        .get();
    return snap.docs.map(FestivalModel.fromFirestore).toList();
  }

  /// Get festivals stream
  Stream<List<FestivalModel>> getFestivalsStream() {
    return _festivals
        .where('isActive', isEqualTo: true)
        .orderBy('startDate')
        .snapshots()
        .map((snap) => snap.docs.map(FestivalModel.fromFirestore).toList());
  }

  /// Get upcoming festivals (next 90 days)
  Future<List<FestivalModel>> getUpcomingFestivals() async {
    final now = DateTime.now();
    final ninetyDaysFromNow = now.add(const Duration(days: 90));
    
    final snap = await _festivals
        .where('isActive', isEqualTo: true)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(ninetyDaysFromNow))
        .orderBy('startDate')
        .get();
    
    return snap.docs.map(FestivalModel.fromFirestore).toList();
  }

  /// Get festivals by date range
  Future<List<FestivalModel>> getFestivalsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snap = await _festivals
        .where('isActive', isEqualTo: true)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('startDate')
        .get();
    
    return snap.docs.map(FestivalModel.fromFirestore).toList();
  }

  /// Check if alert is needed for upcoming festivals
  Future<void> checkFestivalAlerts(String storeId, String managerId) async {
    final festivals = await getUpcomingFestivals();
    
    for (final festival in festivals) {
      if (festival.needsAlert) {
        await _notificationService.sendCustomNotification(
          title: '🎊 Festival Alert: ${festival.name}',
          message:
              'Festival starts in ${festival.startDate.difference(DateTime.now()).inDays} days. '
              'Prepare stock buffers now!',
          userId: managerId,
          storeId: storeId,
          sendPush: true,
        );
      }
    }
  }

  /// Calculate recommended stock multiplier for a category during festival
  double getRecommendedMultiplier(String category) {
    // Default multipliers by category
    final Map<String, double> multipliers = {
      'Sweets': 3.0,
      'Dry Fruits': 2.5,
      'Dairy': 2.0,
      'Snacks': 2.0,
      'Beverages': 1.8,
      'Groceries': 1.5,
      'Household': 1.3,
      'Personal Care': 1.2,
      'Cleaning': 1.2,
    };

    return multipliers[category] ?? 1.5; // Default 1.5x for unknown categories
  }

  /// Get festival demand alerts for a store
  Stream<List<FestivalDemandAlert>> getFestivalDemandAlertsStream(String storeId) {
    return _db
        .collection('festivalDemandAlerts')
        .where('storeId', isEqualTo: storeId)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(FestivalDemandAlert.fromFirestore).toList());
  }

  /// Create festival demand alert
  Future<void> createFestivalDemandAlert({
    required String festivalId,
    required String festivalName,
    required String productId,
    required String productName,
    required String storeId,
    required int historicalAvgSales,
    required int recommendedStock,
    required int currentStock,
  }) async {
    final ref = _db.collection('festivalDemandAlerts').doc();
    final alert = FestivalDemandAlert(
      id: ref.id,
      festivalId: festivalId,
      festivalName: festivalName,
      productId: productId,
      productName: productName,
      storeId: storeId,
      historicalAvgSales: historicalAvgSales,
      recommendedStock: recommendedStock,
      currentStock: currentStock,
      stockShortfall: recommendedStock - currentStock,
      isAcknowledged: false,
      createdAt: DateTime.now(),
    );
    await ref.set(alert.toFirestore());
  }

  /// Acknowledge festival demand alert
  Future<void> acknowledgeFestivalAlert(String alertId) async {
    await _db.collection('festivalDemandAlerts').doc(alertId).update({
      'isAcknowledged': true,
    });
  }

  /// Calculate festival stock requirements
  Future<Map<String, Map<String, dynamic>>> calculateFestivalStockRequirements({
    required String festivalId,
    required String storeId,
    required Map<String, int> currentStock, // productId -> quantity
    required Map<String, String> productCategories, // productId -> category
  }) async {
    final Map<String, Map<String, dynamic>> requirements = {};

    for (final entry in currentStock.entries) {
      final productId = entry.key;
      final current = entry.value;
      final category = productCategories[productId] ?? 'General';
      final multiplier = getRecommendedMultiplier(category);
      
      // Calculate recommended festival stock
      final recommended = (current * multiplier).ceil();
      final shortfall = recommended - current;

      if (shortfall > 0) {
        requirements[productId] = {
          'currentStock': current,
          'recommendedStock': recommended,
          'shortfall': shortfall,
          'category': category,
          'multiplier': multiplier,
        };
      }
    }

    return requirements;
  }

  /// Get historical festival sales data (placeholder for future implementation)
  Future<Map<String, int>> getHistoricalFestivalSales({
    required String festivalName,
    required String storeId,
    int yearsBack = 1,
  }) async {
    // TODO: Implement historical sales analysis
    // Query sales collection for previous year's festival period
    // Return productId -> unitsSold mapping
    return {};
  }
}
