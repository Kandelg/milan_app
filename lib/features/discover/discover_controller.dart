import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/discover_repository.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';

/// Background colours offered for text stories.
const List<String> kStoryBackgrounds = <String>[
  '#E8437E',
  '#7C3AED',
  '#0EA5E9',
  '#10B981',
  '#F59E0B',
  '#111827',
];

/// Holds the stories feed (fresh stories only, newest first).
class StoryController extends AsyncNotifier<List<Story>> {
  @override
  Future<List<Story>> build() async {
    return _load();
  }

  Future<List<Story>> _load() async {
    final StoryRepository repo = ref.read(storyRepositoryProvider);
    return repo.fetchFeed();
  }

  /// Reloads the feed (pull-to-refresh, after posting / deleting).
  Future<void> refresh() async {
    state = const AsyncLoading<List<Story>>();
    state = await AsyncValue.guard(_load);
  }

  /// Posts a photo story from gallery bytes.
  Future<void> postPhoto({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    final String url = await ref
        .read(storageRepositoryProvider)
        .uploadStoryPhoto(userId: userId, fileName: fileName, bytes: bytes);
    await ref
        .read(storyRepositoryProvider)
        .postPhoto(userId: userId, mediaUrl: url);
    await refresh();
  }

  /// Posts a written status on a coloured background.
  Future<void> postText({required String body, required String background}) async {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) throw ArgumentError('Story text is empty');
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    await ref
        .read(storyRepositoryProvider)
        .postText(userId: userId, body: trimmed, background: background);
    await refresh();
  }

  /// Deletes one of the user's own stories.
  Future<void> deleteStory(String storyId) async {
    await ref.read(storyRepositoryProvider).deleteStory(storyId);
    await refresh();
  }
}

final storyControllerProvider =
    AsyncNotifierProvider<StoryController, List<Story>>(StoryController.new);

/// Holds the swipe deck plus the active filters.
/// Holds the swipe deck plus the active filters.
class DiscoverController extends AsyncNotifier<List<Profile>> {
  /// Current filters; mutated by the filter sheet.
  DiscoverFilters _filters = const DiscoverFilters();

  DiscoverFilters get filters => _filters;

  /// Ids of profiles swiped away during this session, so the card swiper and
  /// the fetched list stay in sync without a round-trip per swipe.
  final Set<String> _swipedIds = <String>{};

  /// Card restored by [undoLastSwipe].
  Profile? _lastSwiped;

  @override
  Future<List<Profile>> build() async {
    _swipedIds.clear();
    return _loadPage(offset: 0);
  }

  Future<List<Profile>> _loadPage({required int offset}) async {
    final List<Profile> candidates = await ref
        .read(discoverRepositoryProvider)
        .fetchCandidates(_filters, offset: offset);

    return candidates
        .where((Profile p) => !_swipedIds.contains(p.id))
        .toList(growable: false);
  }

  /// Loads the next page and appends it to the deck.
  Future<void> loadMore() async {
    final List<Profile> current = state.value ?? const <Profile>[];
    if (current.isEmpty) return;

    final List<Profile> nextPage = await _loadPage(offset: current.length);
    final Set<String> seen = current.map((Profile p) => p.id).toSet();

    state = AsyncData<List<Profile>>([
      ...current,
      ...nextPage.where((Profile p) => !seen.contains(p.id)),
    ]);
  }

  /// Applies new filters and reloads the deck.
  Future<void> applyFilters(DiscoverFilters filters) async {
    _filters = filters;
    state = const AsyncLoading<List<Profile>>();
    state = await AsyncValue.guard(() async {
      _swipedIds.clear();
      return _loadPage(offset: 0);
    });
  }

  /// Records the swipe locally and remotely.
  ///
  /// Returns the id of the new match when the swipe was mutual, otherwise
  /// `null` â€” the caller shows the "It's a match" celebration.
  Future<String?> swipe({
    required Profile profile,
    required SwipeDirection direction,
  }) async {
    _swipedIds.add(profile.id);

    // Optimistically remove the card so the animation feels instant.
    state = AsyncData<List<Profile>>(
      (state.value ?? const <Profile>[])
          .where((Profile p) => p.id != profile.id)
          .toList(growable: false),
    );

    try {
      final SwipeResult result = await ref
          .read(discoverRepositoryProvider)
          .swipe(targetId: profile.id, direction: direction);

      _lastSwiped = profile;

      return result.matched ? result.matchId : null;
    } catch (_) {
      // Re-add the card so the user can retry the swipe.
      _swipedIds.remove(profile.id);
      state = AsyncData<List<Profile>>([
        profile,
        ...(state.value ?? const <Profile>[]),
      ]);
      rethrow;
    }
  }

  /// Brings the previously swiped card back to the front of the deck.
  ///
  /// Only the local deck is restored; the swipe row stays in the database so
  /// the same person does not reappear after a reload.
  Future<void> undoLastSwipe() async {
    final Profile? last = _lastSwiped;
    if (last == null) return;

    _swipedIds.remove(last.id);
    state = AsyncData<List<Profile>>([
      last,
      ...(state.value ?? const <Profile>[]),
    ]);
    _lastSwiped = null;
  }
}

final discoverControllerProvider =
    AsyncNotifierProvider<DiscoverController, List<Profile>>(
      DiscoverController.new,
    );
