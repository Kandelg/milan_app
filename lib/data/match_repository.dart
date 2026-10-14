import 'package:milan_app/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Match list and messaging, backed by Postgres + Realtime.
class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;

  /// Live list of the user's matches, newest activity first.
  ///
  /// `unread_count` is produced by the `matches_with_details` view.
  Stream<List<Match>> watchMatches(String userId) {
    return _client
        .from('matches_with_details')
        .stream(primaryKey: ['id'])
        .map((List<Map<String, dynamic>> rows) {
          final List<Match> matches = rows
              .map(
                (Map<String, dynamic> row) =>
                    Match.fromJson(row, currentUserId: userId),
              )
              .toList();
          matches.sort((Match a, Match b) {
            final DateTime aKey =
                a.lastMessage?.createdAt ?? a.createdAt;
            final DateTime bKey =
                b.lastMessage?.createdAt ?? b.createdAt;
            return bKey.compareTo(aKey);
          });
          return matches;
        });
  }

  /// Live list of messages inside a single match, oldest first.
  Stream<List<Message>> watchMessages(String matchId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: true)
        .map(
          (List<Map<String, dynamic>> rows) =>
              rows.map(Message.fromJson).toList(growable: false),
        );
  }

  /// Inserts a message. RLS guarantees the sender is a match participant.
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String body,
  }) async {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _client.from('messages').insert(<String, dynamic>{
      'match_id': matchId,
      'sender_id': senderId,
      'body': trimmed,
    });
  }

  /// Marks every incoming message of a match as read.
  Future<void> markAsRead({
    required String matchId,
    required String userId,
  }) async {
    await _client
        .from('messages')
        .update(<String, dynamic>{'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('match_id', matchId)
        .neq('sender_id', userId)
        .filter('read_at', 'is', null);
  }

  /// Removes a match for both participants.
  Future<void> unmatch(String matchId) async {
    await _client.from('matches').delete().eq('id', matchId);
  }
}
