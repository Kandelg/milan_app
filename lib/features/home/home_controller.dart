import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/chat/chat_controller.dart';

/// Profiles that liked me (Liked tab).
final likedMeProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(socialRepositoryProvider).getLikedMe();
});

/// Pending inbound connection requests (Requested tab → "Received").
final myRequestsProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(socialRepositoryProvider).getMyRequests();
});

/// Pending outbound connection requests (Requested tab → "Sent").
final sentRequestsProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(socialRepositoryProvider).getSentRequests();
});

/// Profiles that joined this month (New tab).
final newThisMonthProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(socialRepositoryProvider).fetchNewThisMonth();
});

/// Live notifications feed (bell + notifications screen).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(socialRepositoryProvider).watchNotifications();
});

/// Number of unread notifications, derived live from [notificationsProvider].
///
/// Recomputes on every realtime change, so the bell badge updates smoothly
/// with no extra polling.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final List<AppNotification>? items =
      ref.watch(notificationsProvider).value;
  if (items == null) return 0;
  return items.where((AppNotification n) => !n.isRead).length;
});

/// Number of brand-new matches (no conversation yet), for the Matches nav
/// badge. Derived from the live [matchesProvider].
final newMatchesCountProvider = Provider<int>((ref) {
  final List<Match>? matches = ref.watch(matchesProvider).value;
  if (matches == null) return 0;
  return matches.where((Match m) => m.lastMessage == null).length;
});

/// Reloads the Home profile lists at once (pull-to-refresh, after an action
/// removes a card, etc.).
Future<void> refreshHomeTabs(WidgetRef ref) async {
  ref.invalidate(likedMeProvider);
  ref.invalidate(myRequestsProvider);
  ref.invalidate(sentRequestsProvider);
  ref.invalidate(newThisMonthProvider);
}
