import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/discover/widgets/match_dialog.dart';
import 'package:milan_app/features/home/home_controller.dart';
import 'package:milan_app/features/home/widgets/liked_photo_card.dart';

/// "Liked" tab — people who liked me.
///
/// Renders a photo grid. Tapping the heart in the bottom-right of a photo
/// likes them back; a mutual like creates a match and the card disappears.
class LikedTab extends ConsumerStatefulWidget {
  const LikedTab({super.key});

  @override
  ConsumerState<LikedTab> createState() => _LikedTabState();
}

class _LikedTabState extends ConsumerState<LikedTab> {
  final Set<String> _busy = <String>{};

  Future<void> _likeBack(Profile profile) async {
    if (_busy.contains(profile.id)) return;
    setState(() => _busy.add(profile.id));
    try {
      final String? matchId = await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.like);

      ref.invalidate(likedMeProvider);

      if (matchId != null && mounted) {
        await MatchDialog.show(context, profile: profile, matchId: matchId);
      } else if (mounted) {
        showAppSnack(context, 'You liked ${profile.fullName}!');
      }
    } catch (error) {
      if (mounted) showAppSnack(context, 'Like failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Profile>> liked = ref.watch(likedMeProvider);
    final AppStrings strings = AppStrings.of(context);

    return liked.when(
      loading: () => const AppLoader(),
      error: (Object error, StackTrace stack) => AppErrorView(error: error),
      data: (List<Profile> profiles) {
        if (profiles.isEmpty) {
          return AppEmptyState(
            icon: Icons.favorite_border,
            title: strings.noLikedTitle,
            message: strings.noLikedBody,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(likedMeProvider),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // Landscape photo cards: width-to-height ratio of 16:9.
              childAspectRatio: 16 / 9,
            ),
            itemCount: profiles.length,
            itemBuilder: (BuildContext context, int index) {
              final Profile profile = profiles[index];
              return LikedPhotoCard(
                profile: profile,
                busy: _busy.contains(profile.id),
                onLike: () => _likeBack(profile),
              );
            },
          ),
        );
      },
    );
  }
}
