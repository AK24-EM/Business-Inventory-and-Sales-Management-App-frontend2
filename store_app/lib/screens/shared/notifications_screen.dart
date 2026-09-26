import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  String _filterType = 'all';
  DateTime? _lastUpdateTime;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _lastUpdateTime = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_lastUpdateTime != null)
              Text(
                'Live • Updated ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.all_inbox), text: 'All'),
            Tab(icon: Icon(Icons.mark_email_unread), text: 'Unread'),
          ],
        ),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _filterType,
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All Types')),
              const PopupMenuItem(value: 'lowStock', child: Text('Low Stock')),
              const PopupMenuItem(value: 'saleCompleted', child: Text('Sales')),
              const PopupMenuItem(value: 'stockTransfer', child: Text('Transfers')),
              const PopupMenuItem(value: 'customerRegistered', child: Text('Customers')),
            ],
          ),
          // Mark all read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all read',
            onPressed: () => _markAllRead(context, user.id),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(user, showUnreadOnly: false),
          _buildNotificationsList(user, showUnreadOnly: true),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(user, {required bool showUnreadOnly}) {
    Query query = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(100);

    // Filter by read status
    if (showUnreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    // Filter by user/store
    if (!user.canAccessAllStores && user.assignedStoreId != null) {
      query = query.where('targetStoreId', isEqualTo: user.assignedStoreId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        // Update last sync time
        if (snap.hasData && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _lastUpdateTime = DateTime.now();
              });
            }
          });
        }

        if (snap.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            message: 'Unable to load notifications',
            color: AppColors.error,
          );
        }

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var notifications = snap.data?.docs
                .map((d) => NotificationModel.fromFirestore(d))
                .toList() ??
            [];

        // Apply type filter
        if (_filterType != 'all') {
          notifications = notifications
              .where((n) => n.type.name == _filterType)
              .toList();
        }

        if (notifications.isEmpty) {
          return _buildEmptyState(
            icon: showUnreadOnly
                ? Icons.mark_email_read
                : Icons.notifications_none_outlined,
            message: showUnreadOnly
                ? 'No unread notifications'
                : 'No notifications yet',
            color: AppColors.textTertiary,
          );
        }

        // Group notifications by date
        final grouped = _groupByDate(notifications);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final entry = grouped[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateHeader(date: entry.key),
                const SizedBox(height: 12),
                ...entry.value.map((notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NotificationCard(notification: notification),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, List<NotificationModel>>> _groupByDate(
      List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    for (final notification in notifications) {
      final date = notification.createdAt;
      String key;

      if (_isSameDay(date, now)) {
        key = 'Today';
      } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
        key = 'Yesterday';
      } else if (date.isAfter(now.subtract(const Duration(days: 7)))) {
        key = DateFormat('EEEE').format(date); // Day name
      } else {
        key = DateFormat('MMM dd, yyyy').format(date);
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped.entries.toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _markAllRead(BuildContext context, String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _DateHeader extends StatelessWidget {
  final String date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        date,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  Color _typeColor() {
    switch (notification.type) {
      case NotificationType.lowStock:
        return AppColors.warning;
      case NotificationType.saleCompleted:
        return AppColors.success;
      case NotificationType.stockTransfer:
        return AppColors.info;
      case NotificationType.customerRegistered:
        return AppColors.primary;
      case NotificationType.festival:
        return const Color(0xFFEA580C);
      case NotificationType.custom:
        return AppColors.accent;
    }
  }

  IconData _typeIcon() {
    switch (notification.type) {
      case NotificationType.lowStock:
        return Icons.warning_amber_rounded;
      case NotificationType.saleCompleted:
        return Icons.check_circle_outline;
      case NotificationType.stockTransfer:
        return Icons.swap_horiz_rounded;
      case NotificationType.customerRegistered:
        return Icons.person_add_outlined;
      case NotificationType.festival:
        return Icons.celebration_rounded;
      case NotificationType.custom:
        return Icons.notifications_outlined;
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(notification.createdAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Notification'),
              content: const Text(
                  'Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        FirebaseFirestore.instance
            .collection(AppConstants.notificationsCollection)
            .doc(notification.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Restore notification
                FirebaseFirestore.instance
                    .collection(AppConstants.notificationsCollection)
                    .doc(notification.id)
                    .set(notification.toFirestore());
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await FirebaseFirestore.instance
                .collection(AppConstants.notificationsCollection)
                .doc(notification.id)
                .update({'isRead': true});
          }
          
          // Handle notification action based on type
          _handleNotificationTap(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.surface
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : color.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: notification.isRead
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(), color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (notification.type) {
      case NotificationType.lowStock:
        return 'LOW STOCK';
      case NotificationType.saleCompleted:
        return 'SALE';
      case NotificationType.stockTransfer:
        return 'TRANSFER';
      case NotificationType.customerRegistered:
        return 'CUSTOMER';
      case NotificationType.festival:
        return 'FESTIVAL';
      case NotificationType.custom:
        return 'INFO';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.lowStock:
        // Navigate to inventory screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to inventory screen'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case NotificationType.saleCompleted:
        // Navigate to sales details
        break;
      case NotificationType.stockTransfer:
        // Navigate to stock transfer screen
        break;
      case NotificationType.customerRegistered:
        // Navigate to customer details
        break;
      case NotificationType.festival:
        final role = Provider.of<AuthProvider>(context, listen: false)
            .currentUser
            ?.role;
        if (role == UserRole.manager) {
          context.go('/manager/festivals');
        } else if (role == UserRole.owner || role == UserRole.admin) {
          context.go('/owner/festivals');
        }
        break;
      case NotificationType.custom:
        // Show details or do nothing
        break;
    }
  }
}
