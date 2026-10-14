import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/stories/story_helpers.dart';
import 'package:milan_app/features/stories/widgets/story_ring.dart';

/// Horizontal Instagram-style tray shown above the swipe deck.
class StoryTray extends StatelessWidget {
  const StoryTray({
    super.key,
    required this.stories,
    required this.myUserId,
    required this.myPhotoUrl,
    required this.onAdd,
    required this.onOpen,
  });

  final List<Story> stories;
  final String? myUserId;
  final String? myPhotoUrl;
  final VoidCallback onAdd;
  final void Function(StoryAuthor author, List<StoryAuthor> all) onOpen;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final List<StoryAuthor> authors = groupStoriesByAuthor(stories, myUserId);
    final bool iHaveStory =
        myUserId != null && authors.any((StoryAuthor a) => a.isMine);

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: authors.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _AddTile(
              photoUrl: myPhotoUrl,
              label: strings.yourStory,
              hasStory: iHaveStory,
              onTap: onAdd,
            );
          }
          final StoryAuthor author = authors[index - 1];
          return _AuthorTile(
            author: author,
            onTap: () => onOpen(author, authors),
          );
        },
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.photoUrl,
    required this.label,
    required this.hasStory,
    required this.onTap,
  });

  final String? photoUrl;
  final String label;
  final bool hasStory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              StoryRing(
                hasStory: hasStory,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundImage:
                      (photoUrl != null && photoUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(photoUrl!)
                          : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: scheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Icon(Icons.add, size: 14, color: scheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 68,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorTile extends StatelessWidget {
  const _AuthorTile({required this.author, required this.onTap});

  final StoryAuthor author;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Story latest = author.stories.first;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StoryRing(
            hasStory: true,
            child: CircleAvatar(
              radius: 30,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundImage:
                  (author.photoUrl != null && author.photoUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(author.photoUrl!)
                      : null,
              child: (author.photoUrl == null || author.photoUrl!.isEmpty)
                  ? Text(
                      author.displayName.isEmpty
                          ? '?'
                          : author.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 68,
            child: Text(
              author.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Text(
            latest.remainingLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
