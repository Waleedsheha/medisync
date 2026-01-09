import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../models/notification_model.dart';
import '../data/notifications_repository.dart';

final notificationsStreamProvider = StreamProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return AppScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          onPressed: () async {
            await ref.read(notificationsRepositoryProvider).markAllAsRead();
            ref.invalidate(notificationsStreamProvider);
          },
          icon: const Icon(LucideIcons.checkCheck),
          tooltip: 'Mark all as read',
        ),
      ],
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 64,
                    color: GlassTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: GlassTheme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationTile(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (!item.read) {
          await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
          ref.invalidate(notificationsStreamProvider);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.read
              ? GlassTheme.cardBackground
              : GlassTheme.neonCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.read
                ? GlassTheme.glassBorder
                : GlassTheme.neonCyan.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.read ? LucideIcons.bell : LucideIcons.bellRing,
              color: item.read ? GlassTheme.textMuted : GlassTheme.neonCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: item.read
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: const TextStyle(color: GlassTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      color: GlassTheme.textMuted.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
