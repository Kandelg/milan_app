import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/discover_repository.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/discover/widgets/action_bar.dart';
import 'package:milan_app/features/discover/widgets/match_dialog.dart';
import 'package:milan_app/features/discover/widgets/profile_card.dart';
import 'package:milan_app/features/discover/widgets/safety_sheet.dart';

/// "For You" tab — the random swipe deck.
///
/// Reuses the existing [DiscoverController] and swipe widgets. On first load
/// it widens the filters to every age (no age / city matching) so the deck is
/// a truly random set of people, as requested.
class ForYouTab extends ConsumerStatefulWidget {
  const ForYouTab({super.key});

  @override
  ConsumerState<ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends ConsumerState<ForYouTab> {
  final CardSwiperController _swiperController = CardSwiperController();

  bool _swiping = false;
  bool _filtersApplied = false;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  /// Widen the filters once (18 → 100, no city) so the deck is random.
  void _ensureWideFilters() {
    if (_filtersApplied) return;
    _filtersApplied = true;
    const DiscoverFilters wide = DiscoverFilters(minAge: 18, maxAge: 100);
    ref.read(discoverControllerProvider.notifier).applyFilters(wide).ignore();
  }

  Future<void> _handleSwipe(Profile profile, SwipeDirection direction) async {
    if (_swiping) return;
    _swiping = true;
    try {
      final String? matchId = await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: direction);

      if (matchId != null && mounted) {
        await MatchDialog.show(context, profile: profile, matchId: matchId);
      }
    } catch (error) {
      if (mounted) showAppSnack(context, 'Swipe failed: $error', error: true);
    } finally {
      _swiping = false;
    }
  }

  Future<void> _openSafetySheet(Profile profile) async {
    final bool? blocked = await SafetySheet.show(
      context,
      targetId: profile.id,
      targetName: profile.fullName,
    );
    if (blocked == true) {
      ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.pass)
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Open the deck wide (random) the first time this tab is shown.
    _ensureWideFilters();

    final AsyncValue<List<Profile>> deck = ref.watch(
      discoverControllerProvider,
    );
    final AppStrings strings = AppStrings.of(context);

    return deck.when(
      loading: () => const AppLoader(message: 'Finding people for you…'),
      error: (Object error, StackTrace stack) => AppErrorView(
        error: error,
        onRetry: () =>
            ref.read(discoverControllerProvider.notifier).applyFilters(
                  ref.read(discoverControllerProvider.notifier).filters,
                ),
      ),
      data: (List<Profile> profiles) {
        if (profiles.isEmpty) {
          return AppEmptyState(
            icon: Icons.explore_off_outlined,
            title: strings.noOneNew,
            message: 'You have seen everyone for now. Check back later!',
          );
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: profiles.length,
                numberOfCardsDisplayed: profiles.length < 3
                    ? profiles.length
                    : 3,
                backCardOffset: const Offset(0, 40),
                padding: const EdgeInsets.all(16),
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                onSwipe:
                    (
                      int previousIndex,
                      int? currentIndex,
                      CardSwiperDirection direction,
                    ) {
                      final Profile profile = profiles[previousIndex];
                      final bool isLike = direction.isCloseTo(
                        CardSwiperDirection.right,
                      );
                      _handleSwipe(
                        profile,
                        isLike ? SwipeDirection.like : SwipeDirection.pass,
                      );
                      return true;
                    },
                cardBuilder:
                    (
                      BuildContext context,
                      int index,
                      int offsetX,
                      int offsetY,
                    ) {
                      final Profile profile = profiles[index];
                      return ProfileCard(
                        profile: profile,
                        onMenu: () => _openSafetySheet(profile),
                      );
                    },
              ),
            ),
            ActionBar(
              onPass: () =>
                  _swiperController.swipe(CardSwiperDirection.left),
              onLike: () =>
                  _swiperController.swipe(CardSwiperDirection.right),
              onUndo: () =>
                  ref.read(discoverControllerProvider.notifier).undoLastSwipe(),
              onSuperLike: () =>
                  _handleSwipe(profiles.first, SwipeDirection.superLike),
            ),
          ],
        );
      },
    );
  }
}
