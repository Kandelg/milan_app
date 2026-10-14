import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/chat/chat_controller.dart';
import 'package:milan_app/features/matches/widgets/match_tile.dart';

/// New matches — people who liked you back but haven't started chatting yet.
///
/// Matches that already have a conversation live in the Messages tab.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Match>> matches = ref.watch(matchesProvider);
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      appBar: GlassAppBar(title: strings.matches),
      body: matches.when(
        loading: () => const AppLoader(message: 'Loading your matches…'),
        error: (Object error, StackTrace stack) =>
            AppErrorView(error: error),
        data: (List<Match> list) {
          // A "new" match has no conversation yet.
          final List<Match> newMatches = list
              .where((Match m) => m.lastMessage == null)
              .toList();

          if (newMatches.isEmpty) {
            return AppEmptyState(
              icon: Icons.favorite_rounded,
              iconWidget: SizedBox(
                width: 80,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      left: 10,
                      top: 16,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
              title: strings.noNewMatchesTitle,
              message: strings.noNewMatchesBody,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: newMatches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return MatchTile(match: newMatches[index]);
              },
            ),
          );
        },
      ),
    );
  }
}


