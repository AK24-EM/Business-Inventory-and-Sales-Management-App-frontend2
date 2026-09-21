import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  lowStock,
  festivalAlert,
  restockingRequired,
  transferPending,
  transferConfirmed,
  systemAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.lowStock:
        return 'Low Stock Alert';
      case NotificationType.festivalAlert:
        return 'Festival Demand Alert';
      case NotificationType.restockingRequired:
        return 'Restocking Required';
      case NotificationType.transferPending:
        return 'Transfer Pending';
      case NotificationType.transferConfirmed:
        return 'Transfer Confirmed';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.systemAlert,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? storeId;
  final String? referenceId; // productId, transferId, etc.
  final bool isRead;
  final List<String> targetRoles; // which roles should see this
  final String? targetStoreId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.storeId,
    this.referenceId,
    this.isRead = false,
    this.targetRoles = const [],
    this.targetStoreId,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationTypeExtension.fromString(data['type'] ?? 'systemAlert'),
      storeId: data['storeId'],
      referenceId: data['referenceId'],
      isRead: data['isRead'] ?? false,
      targetRoles: List<String>.from(data['targetRoles'] ?? []),
      targetStoreId: data['targetStoreId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'storeId': storeId,
      'referenceId': referenceId,
      'isRead': isRead,
      'targetRoles': targetRoles,
      'targetStoreId': targetStoreId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      storeId: storeId,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      targetRoles: targetRoles,
      targetStoreId: targetStoreId,
      createdAt: createdAt,
    );
  }
}
