import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../models/analytics_model.dart';
import '../models/sale_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service;

  // Selected period state
  String _selectedPeriod = 'Last 30 Days';
  DateTimeRange _customRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Cached BehaviorSubject streams by cacheKey for instant replay
  final Map<String, BehaviorSubject<AnalyticsBundle>> _bundleSubjects = {};
  final Map<String, StreamSubscription<AnalyticsBundle>> _bundleSubscriptions = {};

  DateTime _lastSyncTime = DateTime.now();

  AnalyticsProvider(this._service);

  String get selectedPeriod => _selectedPeriod;
  DateTime get lastSyncTime => _lastSyncTime;

  DateTimeRange get currentRange {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Yesterday':
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(y.year, y.month, y.day),
          end: DateTime(y.year, y.month, y.day, 23, 59, 59),
        );
      case 'Last 7 Days':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'Last Month':
        final lmStart = DateTime(now.year, now.month - 1, 1);
        final lmEnd = DateTime(now.year, now.month, 1)
            .subtract(const Duration(seconds: 1));
        return DateTimeRange(start: lmStart, end: lmEnd);
      case 'Last 3 Months':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 89)),
          end: now,
        );
      case 'Custom':
        return _customRange;
      case 'Last 30 Days':
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    }
  }

  void setPeriod(String period, {DateTimeRange? customRange}) {
    if (_selectedPeriod == period && customRange == null) return;
    _selectedPeriod = period;
    if (customRange != null) {
      _customRange = customRange;
    }
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Real-time stream of synchronized analytics data (KPIs, Products, Trends, Customers, Sales).
  /// Automatically updates on every new sale or transaction.
  /// Uses BehaviorSubject for instant replay of last value to new subscribers.
  Stream<AnalyticsBundle> watchBundle({
    String? storeId,
    List<String>? storeIds,
    DateTimeRange? range,
  }) {
    final effectiveRange = range ?? currentRange;
    final startKey = effectiveRange.start.toIso8601String().substring(0, 10);
    final endKey = effectiveRange.end.toIso8601String().substring(0, 10);
    final key = '${storeId ?? storeIds?.join(',') ?? "all"}_${startKey}_$endKey';

    // Return existing subject's stream if already set up
    if (_bundleSubjects.containsKey(key)) {
      return _bundleSubjects[key]!.stream.distinct();
    }

    // Create new BehaviorSubject
    final subject = BehaviorSubject<AnalyticsBundle>();
    _bundleSubjects[key] = subject;

    // Subscribe to analytics service stream
    final subscription = _service
        .watchAnalytics(
          storeId: storeId,
          storeIds: storeIds,
          from: effectiveRange.start,
          to: effectiveRange.end,
        )
        .listen(
          (bundle) {
            _lastSyncTime = DateTime.now();
            if (!subject.isClosed) {
              subject.add(bundle);
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Analytics bundle stream error ($key): $error');
            // Don't close subject on error, keep it alive
          },
          cancelOnError: false,
        );
    
    _bundleSubscriptions[key] = subscription;

    return subject.stream.distinct();
  }

  /// Real-time stream of raw sales with date range
  Stream<List<SaleModel>> watchSales({
    String? storeId,
    List<String>? storeIds,
    DateTimeRange? range,
  }) {
    final effectiveRange = range ?? currentRange;
    return watchBundle(
      storeId: storeId,
      storeIds: storeIds,
      range: effectiveRange,
    ).map((bundle) => bundle.sales);
  }

  /// Real-time stream of product performance
  Stream<List<ProductPerformance>> watchProducts({
    String? storeId,
    DateTimeRange? range,
    int limit = 20,
  }) {
    final effectiveRange = range ?? currentRange;
    return watchBundle(
      storeId: storeId,
      range: effectiveRange,
    ).map((b) => b.products.take(limit).toList());
  }

  /// Real-time stream of daily trends
  Stream<List<SalesTrend>> watchTrends({
    String? storeId,
    DateTimeRange? range,
  }) {
    final effectiveRange = range ?? currentRange;
    return watchBundle(
      storeId: storeId,
      range: effectiveRange,
    ).map((b) => b.trends);
  }

  /// Real-time stream of customer insights
  Stream<List<CustomerInsight>> watchCustomers({
    DateTimeRange? range,
  }) {
    final effectiveRange = range ?? currentRange;
    return watchBundle(
      range: effectiveRange,
    ).map((b) => b.customers);
  }

  @override
  void dispose() {
    // Close all BehaviorSubjects
    for (final subject in _bundleSubjects.values) {
      subject.close();
    }
    // Cancel all subscriptions
    for (final sub in _bundleSubscriptions.values) {
      sub.cancel();
    }
    _bundleSubjects.clear();
    _bundleSubscriptions.clear();
    super.dispose();
  }
}
