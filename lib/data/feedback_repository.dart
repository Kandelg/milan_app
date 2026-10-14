import 'package:supabase_flutter/supabase_flutter.dart';

/// Collects in-app feedback into the `feedbacks` table.
///
/// `user_id` is filled from the current session when signed in; the column is
/// nullable so anonymous submissions are still accepted by RLS.
class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  /// Inserts a feedback row. Throws on failure so the caller can show an error.
  Future<void> send(String message) async {
    final String? me = _client.auth.currentUser?.id;
    await _client.from('feedbacks').insert(<String, dynamic>{
      'user_id': me,
      'message': message,
    });
  }
}