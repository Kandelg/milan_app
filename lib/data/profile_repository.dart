import 'package:milan_app/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the signed-in user's `profiles` row.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Streams the current user's profile so edits reflect immediately.
  Stream<Profile?> watchMyProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((List<Map<String, dynamic>> rows) {
          if (rows.isEmpty) return null;
          return Profile.fromJson(rows.first);
        });
  }

  /// One-shot fetch, used when a stream is not appropriate.
  Future<Profile?> fetchProfile(String userId) async {
    final Map<String, dynamic>? row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  /// Inserts or updates the caller's own profile (RLS-restricted).
  Future<void> saveProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toUpsertJson());
  }
}
