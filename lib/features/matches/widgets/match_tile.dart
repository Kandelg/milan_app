import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';

/// A single row in the Matches / Messages lists.
///
/// Shows the other person's avatar and name, the last message (or a
/// "say hi" hint for brand-new matches), when it happened and an unread
/// badge. Tapping the row opens the conversation.
class MatchTile extends ConsumerWidget {
  const MatchTile({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Message? last = match.lastMessage;
    final AppStrings strings = AppStrings.of(context);
    final bool isNewMatch = last == null;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push(AppRoutes.chat(match.id)),
      child: Row(
        children: <Widget>[
          AppAvatar(photoUrl: match.other.primaryPhoto, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  match.other.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  isNewMatch
                      ? strings.newMatchSayHi
                      : (last.body.isEmpty ? strings.photo : last.body),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNewMatch
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight:
                        isNewMatch ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                DateFormat.MMMd().format(last?.createdAt ?? match.createdAt),
                style: theme.textTheme.labelSmall,
              ),
              if (match.unreadCount > 0) ...<Widget>[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFF9F43), Color(0xFFEE2E31)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${match.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
