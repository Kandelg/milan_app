import 'package:milan_app/data/models.dart';

/// One author (or the "you" tile) inside the horizontal stories tray.
class StoryAuthor {
  const StoryAuthor({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.stories,
    this.isMine = false,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<Story> stories;
  final bool isMine;
}

/// Groups a flat story feed by author, newest story first per author.
List<StoryAuthor> groupStoriesByAuthor(List<Story> feed, String? myUserId) {
  final Map<String, List<Story>> byUser = <String, List<Story>>{};
  for (final Story story in feed) {
    byUser.putIfAbsent(story.userId, () => <Story>[]).add(story);
  }
  final List<StoryAuthor> authors = <StoryAuthor>[];
  for (final MapEntry<String, List<Story>> entry in byUser.entries) {
    final List<Story> stories = entry.value
      ..sort((Story a, Story b) => b.createdAt.compareTo(a.createdAt));
    final Story first = stories.first;
    authors.add(
      StoryAuthor(
        userId: entry.key,
        displayName: first.authorName.isEmpty ? 'Someone' : first.authorName,
        photoUrl: first.authorPhoto,
        stories: stories,
        isMine: myUserId != null && entry.key == myUserId,
      ),
    );
  }
  authors.sort(
    (StoryAuthor a, StoryAuthor b) =>
        b.stories.first.createdAt.compareTo(a.stories.first.createdAt),
  );
  return authors;
}

/// Parses a `#RRGGBB` / `#AARRGGBB` hex string into an opaque [Color] value.
int parseStoryColor(String hex, {int fallback = 0xFFFF6B4A}) {
  String cleaned = hex.trim().replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  return int.tryParse(cleaned, radix: 16) ?? fallback;
}
