import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/chat/chat_controller.dart';
import 'package:milan_app/features/matches/widgets/match_tile.dart';

/// Active conversations — matches where at least one message has been sent.
///
/// Brand-new matches (no chat yet) live in the Matches tab.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Match>> matches = ref.watch(matchesProvider);
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      appBar: GlassAppBar(title: strings.messages),
      body: matches.when(
        loading: () => const AppLoader(message: 'Loading your messages…'),
        error: (Object error, StackTrace stack) =>
            AppErrorView(error: error),
        data: (List<Match> list) {
          // A conversation is a match that already has a message.
          final List<Match> conversations = list
              .where((Match m) => m.lastMessage != null)
              .toList();

          if (conversations.isEmpty) {
            return AppEmptyState(
              icon: Icons.chat_bubble_outline,
              title: strings.noMessagesTitle,
              message: strings.noMessagesBody,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: conversations.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return MatchTile(match: conversations[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
