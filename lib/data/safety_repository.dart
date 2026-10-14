import 'package:supabase_flutter/supabase_flutter.dart';

/// Reason options surfaced in the "Report" sheet.
class ReportReason {
  const ReportReason(this.value, this.label);

  final String value;
  final String label;

  static const List<ReportReason> all = <ReportReason>[
    ReportReason('inappropriate_photos', 'Inappropriate photos'),
    ReportReason('harassment', 'Harassment or abuse'),
    ReportReason('fake_profile', 'Fake or spam profile'),
    ReportReason('underage', 'Appears to be under 18'),
    ReportReason('other', 'Something else'),
  ];
}

/// Safety actions: blocking and reporting other users.
///
/// Blocking is immediate and hides the person from both decks; reporting files
/// a record that moderators review with the service role.
class SafetyRepository {
  SafetyRepository(this._client);

  final SupabaseClient _client;

  /// Hides [blockedId] from the current user (and vice-versa).
  Future<void> block(String blockedId) async {
    final String? me = _client.auth.currentUser?.id;
    if (me == null) return;
    await _client.from('blocks').upsert(
      <String, dynamic>{'blocker_id': me, 'blocked_id': blockedId},
      onConflict: 'blocker_id,blocked_id',
    );
  }

  /// Removes a block so the person can appear again.
  Future<void> unblock(String blockedId) async {
    await _client.from('blocks').delete().eq('blocked_id', blockedId);
  }

  /// Ids the current user has blocked (used to filter the deck client-side).
  Future<Set<String>> blockedIds() async {
    final List<dynamic> rows = await _client.from('blocks').select('blocked_id');
    return rows
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> r) => r['blocked_id'] as String)
        .toSet();
  }

  /// Files a report against [reportedId].
  Future<void> report({
    required String reportedId,
    required String reason,
  }) async {
    await _client.from('reports').insert(<String, dynamic>{
      'reported_id': reportedId,
      'reason': reason,
    });
  }
}
