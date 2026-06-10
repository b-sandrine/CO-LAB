import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../../../shared/models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationActionsProvider.notifier).markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Failed to load: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 56, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) =>
                _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationActionsProvider.notifier).markRead(notification.id);
        }
      },
      child: Container(
        color: notification.isRead ? Colors.transparent : AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: notification.type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, allowFromNow: true),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;
  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.eventReminder => (Icons.event_outlined, AppColors.primary),
      NotificationType.clanAnnouncement => (Icons.campaign_outlined, AppColors.teal),
      NotificationType.teamInvitation => (Icons.group_add_outlined, AppColors.amber),
      NotificationType.newMessage => (Icons.chat_bubble_outline, AppColors.teal),
      NotificationType.newOpportunity => (Icons.lightbulb_outline, AppColors.amber),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}
