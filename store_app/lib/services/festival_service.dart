import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/festival_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Festival planning, calendars, and logical demand alerts synced to Firestore.
class FestivalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _festivals =>
      _db.collection(AppConstants.festivalsCollection);

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection(AppConstants.festivalAlertsCollection);

  static const Map<String, double> categoryMultipliers = {
    'Sweets': 3.0,
    'Dry Fruits': 2.5,
    'Dairy': 2.0,
    'Snacks': 2.0,
    'Beverages': 1.8,
    'Groceries': 1.5,
    'Grocery': 1.5,
    'Household': 1.3,
    'Personal Care': 1.2,
    'Cleaning': 1.2,
    'Bakery': 2.0,
    'Fruits & Vegetables': 1.8,
    'Frozen Foods': 1.6,
  };

  Future<FestivalModel> createFestival(FestivalModel festival) async {
    final ref = _festivals.doc();
    final start = DateTime(
      festival.startDate.year,
      festival.startDate.month,
      festival.startDate.day,
    );
    var end = DateTime(
      festival.endDate.year,
      festival.endDate.month,
      festival.endDate.day,
    );
    if (end.isBefore(start)) end = start;

    final created = FestivalModel(
      id: ref.id,
      name: festival.name.trim(),
      startDate: start,
      endDate: end,
      advanceOrderDays: festival.advanceOrderDays.clamp(3, 90),
      isActive: true,
      createdAt: DateTime.now(),
      storeId: festival.storeId,
      createdBy: festival.createdBy,
    );
    await ref.set(created.toFirestore());
    return created;
  }

  List<FestivalModel> overlappingFestivals({
    required DateTime start,
    required DateTime end,
    required List<FestivalModel> existing,
    String? ignoreId,
  }) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return existing.where((f) {
      if (ignoreId != null && f.id == ignoreId) return false;
      if (f.isPast) return false;
      return !e.isBefore(f.startDay) && !s.isAfter(f.endDay);
    }).toList();
  }

  Future<void> updateFestival(String festivalId, Map<String, dynamic> data) async {
    await _festivals.doc(festivalId).update(data);
  }

  Future<void> deleteFestival(String festivalId) async {
    await _festivals.doc(festivalId).delete();
  }

  Stream<List<FestivalModel>> getFestivalsStream({bool activeOnly = true}) {
    return _festivals.snapshots().map((snap) {
      var list = snap.docs.map(FestivalModel.fromFirestore).toList();
      if (activeOnly) {
        list = list.where((f) => f.isActive).toList();
      }
      list.sort((a, b) => a.startDate.compareTo(b.startDate));
      return list;
    });
  }

  Stream<List<FestivalModel>> getUpcomingFestivalsStream() {
    return getFestivalsStream().map((festivals) {
      return festivals.where((f) => !f.isPast).toList();
    });
  }

  Future<List<FestivalModel>> getAllFestivals() async {
    final snap = await _festivals.get();
    final list = snap.docs
        .map(FestivalModel.fromFirestore)
        .where((f) => f.isActive)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  Future<List<FestivalModel>> getUpcomingFestivals() async {
    final all = await getAllFestivals();
    return all.where((f) => !f.isPast).toList();
  }

  Stream<List<FestivalDemandAlert>> getStoreFestivalAlertsStream(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _alerts.where('storeId', isEqualTo: storeId).snapshots().map((snap) {
      final list = snap.docs.map(FestivalDemandAlert.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<FestivalDemandAlert>> getFestivalDemandAlertsStream(String storeId) {
    return getStoreFestivalAlertsStream(storeId).map(
      (alerts) => alerts.where((a) => !a.isAcknowledged).toList(),
    );
  }

  double getRecommendedMultiplier(String category) {
    return categoryMultipliers[category] ?? 1.5;
  }

  int recommendedFestivalStock(InventoryModel item) {
    final multiplier = getRecommendedMultiplier(item.category);
    final baseline = item.minimumStockLevel > 0
        ? item.minimumStockLevel
        : (item.currentStock > 0 ? item.currentStock : 10);
    return (baseline * multiplier).ceil();
  }

  String timelineAlertId(String storeId, String festivalId, FestivalPhase phase) {
    return 'alert_${storeId}_${festivalId}_timeline_${phase.name}';
  }

  String stockAlertId(String storeId, String festivalId, String productId) {
    return 'alert_${storeId}_${festivalId}_stock_$productId';
  }

  /// Creates/updates festival timing alerts in Firestore.
  /// Fires when a festival enters the order window, is within 7 days, or is ongoing.
  Future<void> syncLogicalAlerts({
    required String storeId,
    required String managerId,
    required List<FestivalModel> festivals,
    List<InventoryModel> inventory = const [],
  }) async {
    if (storeId.isEmpty) return;

    final actionable = festivals.where((f) => f.isActive && f.requiresManagerAction);
    final existingSnap = await _alerts.where('storeId', isEqualTo: storeId).get();
    final existing = {
      for (final doc in existingSnap.docs) doc.id: doc.data(),
    };

    final writes = <_AlertWrite>[];

    for (final festival in actionable) {
      writes.add(_buildTimelineAlert(
        storeId: storeId,
        festival: festival,
      ));
    }

    final batch = _db.batch();
    var ops = 0;
    var sentNotification = false;

    for (final write in writes) {
      final prior = existing[write.id];
      if (prior != null && prior['isAcknowledged'] == true) {
        continue;
      }

      final isNew = prior == null;
      final unchanged = prior != null &&
          prior['currentStock'] == write.data['currentStock'] &&
          prior['recommendedStock'] == write.data['recommendedStock'] &&
          prior['stockShortfall'] == write.data['stockShortfall'] &&
          prior['phase'] == write.data['phase'] &&
          prior['message'] == write.data['message'] &&
          prior['severity'] == write.data['severity'];

      if (unchanged) continue;

      if (isNew) {
        write.data['createdAt'] = Timestamp.fromDate(DateTime.now());
        write.data['isAcknowledged'] = false;
        batch.set(_alerts.doc(write.id), write.data);
      } else {
        final update = Map<String, dynamic>.from(write.data)
          ..remove('createdAt')
          ..remove('isAcknowledged');
        batch.update(_alerts.doc(write.id), update);
      }
      ops++;

      if (isNew && write.notify && !sentNotification && managerId.isNotEmpty) {
        sentNotification = true;
        unawaited(_notificationService.createNotification(
          title: write.notifyTitle,
          message: write.notifyBody,
          type: NotificationType.festival,
          targetUserId: managerId,
          targetStoreId: storeId,
          data: {
            'festivalId': write.data['festivalId'],
            'kind': write.data['kind'],
            'route': '/manager/festivals',
          },
          sendPush: true,
        ));
      }
    }

    if (ops > 0) {
      await batch.commit();
      debugPrint('Festival alerts synced: $ops writes for store $storeId');
    }
  }

  _AlertWrite _buildTimelineAlert({
    required String storeId,
    required FestivalModel festival,
  }) {
    final phase = festival.phase;
    final days = festival.daysUntilStart;
    String severity;
    String message;
    switch (phase) {
      case FestivalPhase.urgent:
        severity = 'urgent';
        message =
            '${festival.name} starts in $days day${days == 1 ? '' : 's'}. '
            'Finalize festival stock orders immediately.';
        break;
      case FestivalPhase.ongoing:
        severity = 'warning';
        message =
            '${festival.name} is ongoing. Watch fast movers and replenish before stock-outs.';
        break;
      case FestivalPhase.orderWindow:
        severity = 'warning';
        message =
            'Order window is open for ${festival.name}. Place supplier orders by '
            '${_fmtDate(festival.alertDate)} (${festival.advanceOrderDays}-day buffer).';
        break;
      default:
        severity = 'info';
        message = '${festival.name} is approaching. Review category buffers.';
    }

    final id = timelineAlertId(storeId, festival.id, phase);
    return _AlertWrite(
      id: id,
      notify: phase == FestivalPhase.urgent || phase == FestivalPhase.orderWindow,
      notifyTitle: phase == FestivalPhase.urgent
          ? 'Urgent: ${festival.name} in $days days'
          : 'Festival alert: ${festival.name}',
      notifyBody: message,
      data: {
        'festivalId': festival.id,
        'festivalName': festival.name,
        'productId': '',
        'productName': festival.name,
        'storeId': storeId,
        'historicalAvgSales': 0,
        'recommendedStock': 0,
        'currentStock': 0,
        'stockShortfall': 0,
        'kind': 'timeline',
        'severity': severity,
        'phase': phase.name,
        'message': message,
        'category': '',
      },
    );
  }

  Future<void> acknowledgeFestivalAlert(String alertId) async {
    await _alerts.doc(alertId).update({'isAcknowledged': true});
  }

  Future<void> checkFestivalAlerts(String storeId, String managerId) async {
    final festivals = await getUpcomingFestivals();
    for (final festival in festivals) {
      if (!festival.requiresManagerAction) continue;
      await _notificationService.createNotification(
        title: 'Festival Alert: ${festival.name}',
        message: festival.phase == FestivalPhase.urgent
            ? 'Starts in ${festival.daysUntilStart} days. Prepare stock buffers now.'
            : 'Order window is open. Place advance stock before ${_fmtDate(festival.alertDate)}.',
        type: NotificationType.festival,
        targetUserId: managerId,
        targetStoreId: storeId,
        sendPush: true,
      );
    }
  }

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
    final id = stockAlertId(storeId, festivalId, productId);
    final alert = FestivalDemandAlert(
      id: id,
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
      kind: 'stock',
      severity: 'warning',
      message:
          '$productName is short for $festivalName. Current $currentStock / required $recommendedStock.',
    );
    await _alerts.doc(id).set(alert.toFirestore(), SetOptions(merge: true));
  }

  String _fmtDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _AlertWrite {
  final String id;
  final Map<String, dynamic> data;
  final bool notify;
  final String notifyTitle;
  final String notifyBody;

  _AlertWrite({
    required this.id,
    required this.data,
    required this.notify,
    required this.notifyTitle,
    required this.notifyBody,
  });
}
