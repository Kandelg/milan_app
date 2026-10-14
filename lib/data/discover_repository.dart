import 'package:milan_app/core/constants.dart';
import 'package:milan_app/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads candidate profiles and records swipes.
class DiscoverRepository {
  DiscoverRepository(this._client);

  final SupabaseClient _client;

  /// Fetches one page of candidates. The RPC already excludes the caller,
  /// people already swiped, existing matches, blocked users and
  /// gender-incompatible profiles.
  Future<List<Profile>> fetchCandidates(
    DiscoverFilters filters, {
    int limit = kDiscoveryPageSize,
    int offset = 0,
  }) async {
    final List<dynamic> rows = await _client.rpc(
      'discover_profiles',
      params: filters.toRpcParams(limit: limit, offset: offset),
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(Profile.fromJson)
        .toList(growable: false);
  }

  /// Records a swipe and reports whether it created a mutual match.
  ///
  /// The matching decision lives in the `record_swipe` RPC so that duplicate
  /// swipes and both orderings are handled atomically in Postgres.
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeDirection direction,
  }) async {
    final dynamic result = await _client.rpc(
      'record_swipe',
      params: <String, dynamic>{
        'p_target_id': targetId,
        'p_direction': direction.value,
      },
    );

    if (result is Map<String, dynamic>) {
      final dynamic matchId = result['match_id'];
      return SwipeResult(
        matched: result['matched'] == true,
        matchId: matchId is String ? matchId : null,
      );
    }
    return const SwipeResult(matched: false);
  }
}

/// Photo / text stories that disappear 24 hours after posting.
///
/// Reads go through the `stories_feed` view so every story already carries
/// the author's name and photo; the view (and RLS) only exposes fresh rows.
class StoryRepository {
  StoryRepository(this._client);

  final SupabaseClient _client;

  /// Fresh stories, newest first. The view already filters expired rows, but
  /// the client filters again so clock skew can never show a dead story.
  Future<List<Story>> fetchFeed({int limit = 60}) async {
    final List<dynamic> rows = await _client
        .from('stories_feed')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .cast<Map<String, dynamic>>()
        .map(Story.fromJson)
        .where((Story s) => s.isFresh)
        .toList(growable: false);
  }

  /// Posts a photo story; returns the created row.
  Future<Story> postPhoto({
    required String userId,
    required String mediaUrl,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('stories')
        .insert(<String, dynamic>{
          'user_id': userId,
          'kind': StoryKind.photo.value,
          'media_url': mediaUrl,
        })
        .select()
        .single();
    return Story.fromJson(row);
  }

  /// Posts a written status on a coloured background.
  Future<Story> postText({
    required String userId,
    required String body,
    required String background,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('stories')
        .insert(<String, dynamic>{
          'user_id': userId,
          'kind': StoryKind.text.value,
          'body': body.trim(),
          'background': background,
        })
        .select()
        .single();
    return Story.fromJson(row);
  }

  /// Deletes a story (RLS allows only the author's own rows).
  Future<void> deleteStory(String storyId) async {
    await _client.from('stories').delete().eq('id', storyId);
  }
}


/// Filters accepted by the `discover_profiles` RPC.
class DiscoverFilters {
  const DiscoverFilters({
    this.minAge = kFilterMinAge,
    this.maxAge = kFilterMaxAge,
    this.gender,
    this.city,
    this.interests = const <String>[],
  });

  final int minAge;
  final int maxAge;

  /// `male` / `female` / `other`; `null` means "any".
  final String? gender;

  final String? city;
  final List<String> interests;

  DiscoverFilters copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    String? city,
    List<String>? interests,
  }) {
    return DiscoverFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      interests: interests ?? this.interests,
    );
  }

  Map<String, dynamic> toRpcParams({required int limit, required int offset}) {
    return <String, dynamic>{
      'p_min_age': minAge,
      'p_max_age': maxAge,
      'p_gender': gender,
      'p_city': (city == null || city!.trim().isEmpty) ? null : city!.trim(),
      'p_interests': interests.isEmpty ? null : interests,
      'p_limit': limit,
      'p_offset': offset,
    };
  }

  /// How many filters are currently active (for the badge on the filter button).
  int get activeCount {
    int count = 0;
    if (minAge != kFilterMinAge || maxAge != kFilterMaxAge) count++;
    if (gender != null) count++;
    if (city != null && city!.trim().isNotEmpty) count++;
    if (interests.isNotEmpty) count++;
    return count;
  }
}
