import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  lowStock,
  saleCompleted,
  stockTransfer,
  customerRegistered,
  custom,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? targetUserId;
  final String? targetStoreId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetUserId,
    this.targetStoreId,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Notification document is null');
    }
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'custom'),
        orElse: () => NotificationType.custom,
      ),
      targetUserId: data['targetUserId'] as String?,
      targetStoreId: data['targetStoreId'] as String?,
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'targetUserId': targetUserId,
      'targetStoreId': targetStoreId,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? targetUserId,
    String? targetStoreId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      targetStoreId: targetStoreId ?? this.targetStoreId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
