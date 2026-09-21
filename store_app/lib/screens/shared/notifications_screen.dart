import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    Query query = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(50);

    // Filter notifications relevant to this user's role and store
    if (!user.canAccessAllStores && user.assignedStoreId != null) {
      query = query.where('targetStoreId', isEqualTo: user.assignedStoreId);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context, user.id),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          // 400 / permission-denied means the collection doesn't exist yet
          // or the Firestore rules rejected the query. Show empty state
          // gracefully instead of crashing or spinning forever.
          if (snap.hasError) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('No notifications',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snap.data?.docs
                  .map((d) => AppNotification.fromFirestore(d))
                  .toList() ??
          [];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('No notifications',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _NotificationCard(notification: notifications[i]),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    // Scope to the current user's notifications only — querying all unread
    // docs across the collection is denied by Firestore rules for non-owners.
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  Color _typeColor() {
    switch (notification.type) {
      case NotificationType.lowStock:
        return AppColors.warning;
      case NotificationType.festivalAlert:
        return AppColors.accent;
      case NotificationType.restockingRequired:
        return AppColors.error;
      case NotificationType.transferPending:
        return AppColors.info;
      case NotificationType.transferConfirmed:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _typeIcon() {
    switch (notification.type) {
      case NotificationType.lowStock:
        return Icons.warning_amber_rounded;
      case NotificationType.festivalAlert:
        return Icons.celebration_outlined;
      case NotificationType.restockingRequired:
        return Icons.refresh_rounded;
      case NotificationType.transferPending:
        return Icons.swap_horiz_rounded;
      case NotificationType.transferConfirmed:
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await FirebaseFirestore.instance
              .collection(AppConstants.notificationsCollection)
              .doc(notification.id)
              .update({'isRead': true});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 13)),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(notification.createdAt),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
