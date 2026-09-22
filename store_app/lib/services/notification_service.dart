import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_constants.dart';
import '../models/notification_model.dart';

/// Service for managing notifications (push and local)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(AppConstants.notificationsCollection);

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Skip FCM initialization on web for now
      // Web push notifications require additional setup with service workers
      if (kIsWeb) {
        print('⚠️ Running on web - FCM push notifications disabled');
        print('💡 Use Firestore notifications collection for web notifications');
        _initialized = true;
        return;
      }

      // Initialize local notifications (mobile only)
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permission
      await _requestPermission();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Setup message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      _initialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('⚠️ Error initializing notifications: $e');
      print('💡 Continuing without push notifications - using Firestore only');
      _initialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('⚠️ Notification permission denied');
    }
  }

  /// Get FCM token for this device
  String? get fcmToken => _fcmToken;

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message: ${message.notification?.title}');
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('👆 Notification tapped: ${message.notification?.title}');
    // Navigate to relevant screen based on message data
  }

  /// Handle background messages (must be top-level function)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('🔔 Background message: ${message.notification?.title}');
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    // Navigate based on payload
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'storeiq_channel',
      'StoreIQ Notifications',
      channelDescription: 'Important notifications for StoreIQ',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Create notification in Firestore
  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? targetUserId,
    String? targetStoreId,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    final ref = _notifications.doc();
    final notification = NotificationModel(
      id: ref.id,
      title: title,
      message: message,
      type: type,
      targetUserId: targetUserId,
      targetStoreId: targetStoreId,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await ref.set(notification.toFirestore());

    // Send push notification if enabled
    if (sendPush && targetUserId != null) {
      await _sendPushToUser(targetUserId, title, message);
    }
  }

  /// Send push notification to specific user
  Future<void> _sendPushToUser(
    String userId,
    String title,
    String body,
  ) async {
    // This would typically call a Cloud Function to send FCM message
    // For now, we'll show a local notification
    await _showLocalNotification(title: title, body: body);
  }

  /// Get notifications for user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _notifications
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  /// Get notifications for store
  Stream<List<NotificationModel>> getStoreNotificationsStream(String storeId) {
    return _notifications
        .where('targetStoreId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return _notifications
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _notifications
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  /// Send low stock alert
  Future<void> sendLowStockAlert({
    required String productName,
    required int currentStock,
    required int minimumStock,
    required String storeId,
    String? managerId,
  }) async {
    await createNotification(
      title: '⚠️ Low Stock Alert',
      message:
          '$productName is low on stock. Current: $currentStock, Minimum: $minimumStock',
      type: NotificationType.lowStock,
      targetUserId: managerId,
      targetStoreId: storeId,
      data: {
        'productName': productName,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
      },
      sendPush: true,
    );
  }

  /// Send sale completed notification
  Future<void> sendSaleCompletedNotification({
    required String invoiceNumber,
    required double totalAmount,
    required String employeeName,
    required String storeId,
    String? managerId,
  }) async {
    await createNotification(
      title: '💰 Sale Completed',
      message:
          'Sale $invoiceNumber completed by $employeeName - ₹${totalAmount.toStringAsFixed(2)}',
      type: NotificationType.saleCompleted,
      targetUserId: managerId,
      targetStoreId: storeId,
      data: {
        'invoiceNumber': invoiceNumber,
        'totalAmount': totalAmount,
        'employeeName': employeeName,
      },
      sendPush: false, // Don't push for every sale
    );
  }

  /// Send stock transfer notification
  Future<void> sendStockTransferNotification({
    required String productName,
    required int quantity,
    required String fromStore,
    required String toStore,
    required String toStoreManagerId,
  }) async {
    await createNotification(
      title: '📦 Stock Transfer Received',
      message:
          '$quantity units of $productName transferred from $fromStore to your store',
      type: NotificationType.stockTransfer,
      targetUserId: toStoreManagerId,
      targetStoreId: toStore,
      data: {
        'productName': productName,
        'quantity': quantity,
        'fromStore': fromStore,
      },
      sendPush: true,
    );
  }

  /// Send custom notification
  Future<void> sendCustomNotification({
    required String title,
    required String message,
    String? userId,
    String? storeId,
    bool sendPush = false,
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: NotificationType.custom,
      targetUserId: userId,
      targetStoreId: storeId,
      sendPush: sendPush,
    );
  }
}
