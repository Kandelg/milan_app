import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/discover/widgets/match_dialog.dart';
import 'package:milan_app/features/home/home_controller.dart';
import 'package:milan_app/features/home/widgets/person_action_card.dart';

/// "New" tab — people who joined this month.
///
/// A simple vertical list with a Like button per row; a mutual like shows the
/// match celebration and the row drops out.
class NewTab extends ConsumerStatefulWidget {
  const NewTab({super.key});

  @override
  ConsumerState<NewTab> createState() => _NewTabState();
}

class _NewTabState extends ConsumerState<NewTab> {
  final Set<String> _busy = <String>{};

  Future<void> _like(Profile profile) async {
    if (_busy.contains(profile.id)) return;
    setState(() => _busy.add(profile.id));
    try {
      final String? matchId = await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.like);
      ref.invalidate(newThisMonthProvider);
      if (matchId != null && mounted) {
        await MatchDialog.show(context, profile: profile, matchId: matchId);
      }
    } catch (error) {
      if (mounted) showAppSnack(context, 'Like failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Profile>> newUsers = ref.watch(newThisMonthProvider);
    final AppStrings strings = AppStrings.of(context);

    return newUsers.when(
      loading: () => const AppLoader(),
      error: (Object error, StackTrace stack) =>
          AppErrorView(error: error),
      data: (List<Profile> profiles) {
        if (profiles.isEmpty) {
          return AppEmptyState(
            icon: Icons.person_add_alt_1_outlined,
            title: strings.noNewThisMonthTitle,
            message: strings.noNewThisMonthBody,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(newThisMonthProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: profiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Profile profile = profiles[index];
              return PersonActionCard(
                profile: profile,
                busy: _busy.contains(profile.id),
                actionLabel: strings.likeBack,
                actionIcon: Icons.favorite,
                onAction: () => _like(profile),
              );
            },
          ),
        );
      },
    );
  }
}
