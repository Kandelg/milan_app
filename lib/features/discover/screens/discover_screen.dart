import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/discover_repository.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/discover/widgets/action_bar.dart';
import 'package:milan_app/features/discover/widgets/filter_sheet.dart';
import 'package:milan_app/features/discover/widgets/match_dialog.dart';
import 'package:milan_app/features/discover/widgets/profile_card.dart';
import 'package:milan_app/features/discover/widgets/safety_sheet.dart';
import 'package:milan_app/features/home/home_controller.dart';
import 'package:milan_app/features/profile/profile_controller.dart';
import 'package:milan_app/features/stories/story_helpers.dart';
import 'package:milan_app/features/stories/widgets/story_composer.dart';
import 'package:milan_app/features/stories/widgets/story_tray.dart';
import 'package:milan_app/features/stories/widgets/story_viewer.dart';

/// The swipe deck: the main screen of the app.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  bool _swiping = false;
  String? _busyProfileId;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  /// Records the swipe and, when it is mutual, celebrates it.
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

  Future<void> _sendProfileAction(
    Profile profile,
    SwipeDirection direction,
  ) async {
    if (_busyProfileId != null) return;
    setState(() => _busyProfileId = profile.id);
    try {
      final String? matchId = await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: direction);
      ref.invalidate(likedMeProvider);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(sentRequestsProvider);
      if (!mounted) return;
      if (matchId != null) {
        await MatchDialog.show(context, profile: profile, matchId: matchId);
      } else {
        showAppSnack(
          context,
          direction == SwipeDirection.request
              ? 'Connection request sent to ${profile.fullName}.'
              : 'You are interested in ${profile.fullName}.',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Could not send action: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _busyProfileId = null);
    }
  }

  /// Super like = swipe up (positive, so it can also create a match).
  Future<void> _superLike(Profile profile) async {
    await _handleSwipe(profile, SwipeDirection.superLike);
  }

  /// Opens the block / report sheet; blocking removes the card from the deck.
  Future<void> _openSafetySheet(Profile profile) async {
    final bool? blocked = await SafetySheet.show(
      context,
      targetId: profile.id,
      targetName: profile.fullName,
    );
    if (blocked == true) {
      // Silently drop the card — the backend deck excludes them from now on.
      ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.pass)
          .ignore();
    }
  }

  Future<void> _openFilters(DiscoverFilters current) async {
    final DiscoverFilters? result = await showModalBottomSheet<DiscoverFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => FilterSheet(initial: current),
    );
    if (result == null) return;
    await ref.read(discoverControllerProvider.notifier).applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Profile>> deck = ref.watch(
      discoverControllerProvider,
    );
    final AsyncValue<List<Story>> stories = ref.watch(storyControllerProvider);
    final DiscoverFilters filters = ref
        .read(discoverControllerProvider.notifier)
        .filters;
    final AppStrings strings = AppStrings.of(context);
    final int unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                stories.when(
                  loading: () => const SizedBox(height: 112),
                  error: (_, _) => const SizedBox(height: 112),
                  data: (List<Story> items) {
                    final String? myId = ref.watch(currentUserIdProvider);
                    final Profile? me = ref
                        .watch(myProfileControllerProvider)
                        .value;
                    return StoryTray(
                      stories: items,
                      myUserId: myId,
                      myPhotoUrl: me?.primaryPhoto,
                      onAdd: () => StoryComposer.show(context),
                      onOpen: (StoryAuthor author, List<StoryAuthor> all) =>
                          StoryViewer.show(context, author: author, all: all),
                    );
                  },
                ),
                Expanded(
                  child: deck.when(
                    loading: () =>
                        const AppLoader(message: 'Finding people near you…'),
                    error: (Object error, StackTrace stack) => AppErrorView(
                      error: error,
                      onRetry: () => ref
                          .read(discoverControllerProvider.notifier)
                          .applyFilters(filters),
                    ),
                    data: (List<Profile> profiles) {
                      if (profiles.isEmpty) {
                        return AppEmptyState(
                          icon: Icons.explore_off_outlined,
                          title: strings.noOneNew,
                          message:
                              'You have seen everyone matching your filters. '
                              'Try widening them or check back later.',
                          action: OutlinedButton.icon(
                            onPressed: () => _openFilters(filters),
                            icon: const Icon(Icons.tune),
                            label: Text(strings.changeFilters),
                          ),
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
                              allowedSwipeDirection:
                                  const AllowedSwipeDirection.only(
                                    left: true,
                                    right: true,
                                  ),
                              onSwipe:
                                  (
                                    int previousIndex,
                                    int? currentIndex,
                                    CardSwiperDirection direction,
                                  ) {
                                    final Profile profile =
                                        profiles[previousIndex];
                                    final bool isLike = direction.isCloseTo(
                                      CardSwiperDirection.right,
                                    );
                                    _handleSwipe(
                                      profile,
                                      isLike
                                          ? SwipeDirection.like
                                          : SwipeDirection.pass,
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
                                      busy: _busyProfileId == profile.id,
                                      onLike: () => _sendProfileAction(
                                        profile,
                                        SwipeDirection.like,
                                      ),
                                      onConnect: () => _sendProfileAction(
                                        profile,
                                        SwipeDirection.request,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          ActionBar(
                            onPass: () => _swiperController.swipe(
                              CardSwiperDirection.left,
                            ),
                            onLike: () => _swiperController.swipe(
                              CardSwiperDirection.right,
                            ),
                            onUndo: () => ref
                                .read(discoverControllerProvider.notifier)
                                .undoLastSwipe(),
                            onSuperLike: () => _superLike(profiles.first),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 0,
              child: _DiscoveryNotificationButton(
                count: unread,
                tooltip: strings.notifications,
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ),
            Positioned(
              right: 12,
              top: MediaQuery.sizeOf(context).height * 0.34,
              child: Column(
                children: <Widget>[
                  _DiscoveryActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: strings.messages,
                    onPressed: () => context.go(AppRoutes.messages),
                  ),
                  const SizedBox(height: 14),
                  _DiscoveryActionButton(
                    icon: Icons.auto_awesome,
                    tooltip: 'Astrology',
                    onPressed: () => _showAstrology(context),
                  ),
                  const SizedBox(height: 14),
                  _DiscoveryActionButton(
                    icon: Icons.favorite_rounded,
                    tooltip: 'Like',
                    emphasized: true,
                    onPressed: () =>
                        _swiperController.swipe(CardSwiperDirection.right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAstrology(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Cosmic connection',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore zodiac compatibility together.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DiscoveryNotificationButton extends StatelessWidget {
  const _DiscoveryNotificationButton({
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFEE2E31),
        elevation: 8,
        shadowColor: const Color(0xFFEE2E31).withValues(alpha: 0.35),
        clipBehavior: Clip.antiAlias,
        shape: const _NotificationCutout(),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 70,
            height: 62,
            child: Stack(
              alignment: const Alignment(0.15, -0.12),
              children: <Widget>[
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 27,
                ),
                if (count > 0)
                  Positioned(
                    top: 9,
                    right: 13,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Color(0xFFEE2E31),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCutout extends ShapeBorder {
  const _NotificationCutout();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.left, rect.top)
    ..lineTo(rect.right, rect.top)
    ..lineTo(rect.right, rect.bottom - 15)
    ..quadraticBezierTo(
      rect.right - 24,
      rect.bottom + 3,
      rect.left + 20,
      rect.bottom - 8,
    )
    ..lineTo(rect.left, rect.bottom)
    ..close();

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _DiscoveryActionButton extends StatelessWidget {
  const _DiscoveryActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFFEE2E31);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: emphasized
            ? accent.withValues(alpha: 0.90)
            : Colors.black.withValues(alpha: 0.34),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.76),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
