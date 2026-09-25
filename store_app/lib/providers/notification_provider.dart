import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  DateTime? _lastUpdateTime;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;
  
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get hasUnread => _unreadCount > 0;

  /// Initialize notification stream for user
  void initializeForUser(String userId) {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    
    // Listen to notifications stream
    _notificationsSubscription = _service
        .getUserNotificationsStream(userId)
        .listen((notifications) {
      _notifications = notifications;
      _lastUpdateTime = DateTime.now();
      notifyListeners();
    });
    
    // Listen to unread count stream
    _unreadCountSubscription = _service
        .getUnreadCountStream(userId)
        .listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
  }

  /// Send custom notification
  Future<void> sendCustomNotification({
    required String title,
    required String message,
    String? userId,
    String? storeId,
    bool sendPush = false,
  }) async {
    await _service.sendCustomNotification(
      title: title,
      message: message,
      userId: userId,
      storeId: storeId,
      sendPush: sendPush,
    );
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
