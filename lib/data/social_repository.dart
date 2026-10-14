import 'package:milan_app/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend for the Home screen's social tabs.
///
/// Inbound likes / requests are read through SECURITY DEFINER RPCs
/// ([getLikedMe] / [getMyRequests]) because the `swipes` table is private by
/// RLS — a client can never query "who liked me" directly without leaking
/// everyone's swipes. New-this-month and notifications are plain, RLS-safe
/// queries.
class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  /// Profiles that liked me and are not matched yet.
  Future<List<Profile>> getLikedMe({
    int limit = 30,
    int offset = 0,
  }) async {
    final dynamic rows = await _client.rpc(
      'get_liked_me',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': offset},
    );
    return _filterOutMatched(_parseProfiles(rows));
  }

  /// Pending inbound connection requests (not yet matched).
  Future<List<Profile>> getMyRequests({
    int limit = 30,
    int offset = 0,
  }) async {
    final dynamic rows = await _client.rpc(
      'get_my_requests',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': offset},
    );
    return _filterOutMatched(_parseProfiles(rows));
  }

  /// Pending outbound connection requests — people I sent a 'request' to but
  /// who have not accepted yet (still unmatched).
  Future<List<Profile>> getSentRequests({
    int limit = 30,
    int offset = 0,
  }) async {
    final dynamic rows = await _client.rpc(
      'get_sent_requests',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': offset},
    );
    return _parseProfiles(rows);
  }

  /// Profiles created this calendar month, newest first.
  ///
  /// Excludes me, people I already matched / swiped, and blocked users so the
  /// list never repeats people from the other tabs.
  Future<List<Profile>> fetchNewThisMonth({int limit = 40}) async {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    final List<dynamic> rows = await _client
        .from('profiles')
        .select()
        .gte('created_at', monthStart.toUtc().toIso8601String())
        .neq('id', _client.auth.currentUser?.id ?? '')
        .order('created_at', ascending: false)
        .limit(limit);

    final List<Profile> all = rows
        .cast<Map<String, dynamic>>()
        .map(Profile.fromJson)
        .where((Profile p) => p.isComplete)
        .toList(growable: false);
    return _filterOutMatched(all);
  }

  /// Realtime stream of my notifications, newest first, with the actor joined.
  Stream<List<AppNotification>> watchNotifications() {
    final String? myId = _client.auth.currentUser?.id;
    if (myId == null) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', myId)
        .order('created_at', ascending: false)
        .map(
          (List<Map<String, dynamic>> rows) => rows
              .map(AppNotification.fromJson)
              .toList(growable: false),
        );
  }

  /// One-shot fetch of my notifications with the actor profile joined in.
  Future<List<AppNotification>> fetchNotifications({int limit = 60}) async {
    final List<dynamic> rows = await _client
        .from('notifications')
        .select(
          '*, actor:profiles!notifications_actor_id_fkey'
          '(id, full_name, photo_urls)',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  /// Marks all my notifications as read.
  Future<void> markAllRead() async {
    await _client.rpc('mark_notifications_read');
  }

  /// Counts unread notifications (used for the bell badge).
  Future<int> countUnread() async {
    final List<dynamic> rows = await _client
        .from('notifications')
        .select('id')
        .eq('is_read', false);
    return rows.length;
  }

  List<Profile> _parseProfiles(dynamic rows) {
    if (rows is! List) return const <Profile>[];
    return rows
        .cast<Map<String, dynamic>>()
        .map(Profile.fromJson)
        .toList(growable: false);
  }

  Future<List<Profile>> _filterOutMatched(List<Profile> input) async {
    final String? myId = _client.auth.currentUser?.id;
    if (myId == null) return input;

    final List<dynamic> matches = await _client
        .from('matches')
        .select('user_a, user_b')
        .or('user_a.eq.$myId,user_b.eq.$myId');

    final Set<String> matchedIds = <String>{};
    for (final dynamic row in matches) {
      final Map<String, dynamic> m = row as Map<String, dynamic>;
      matchedIds.add(m['user_a'] as String);
      matchedIds.add(m['user_b'] as String);
    }
    matchedIds.remove(myId);

    return input
        .where((Profile p) => !matchedIds.contains(p.id))
        .toList(growable: false);
  }
}
