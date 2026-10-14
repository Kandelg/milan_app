import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/home/home_controller.dart';

/// Full list of the user's notifications; marks them read on open.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  void _markRead() {
    if (_markedRead) return;
    _markedRead = true;
    ref.read(socialRepositoryProvider).markAllRead().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AppNotification>> feed = ref.watch(
      notificationsProvider,
    );
    final AppStrings strings = AppStrings.of(context);

    // Mark everything read once the user opens this screen.
    _markRead();

    return Scaffold(
      appBar: GlassAppBar(title: strings.notifications),
      body: feed.when(
        loading: () => const AppLoader(),
        error: (Object error, StackTrace stack) =>
            AppErrorView(error: error),
        data: (List<AppNotification> items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_none,
              title: strings.noNotificationsTitle,
              message: strings.noNotificationsBody,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final AppNotification n = items[index];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);
    final Profile? actor = notification.actor;
    final String? photo = actor?.primaryPhoto;

    final IconData icon;
    final Color color;
    switch (notification.type) {
      case NotificationType.match:
        icon = Icons.favorite;
        color = const Color(0xFFEE2E31);
      case NotificationType.request:
        icon = Icons.mark_email_unread_outlined;
        color = const Color(0xFFFF9F43);
      case NotificationType.like:
        icon = Icons.thumb_up_alt_outlined;
        color = const Color(0xFFFF6B4A);
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundImage:
                    (photo != null && photo.isNotEmpty)
                        ? CachedNetworkImageProvider(photo)
                        : null,
                child: (photo == null || photo.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(icon, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  actor?.fullName ?? strings.profile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.notificationBody(notification.type),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFEE2E31),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
