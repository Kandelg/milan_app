import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/discover/widgets/match_dialog.dart';
import 'package:milan_app/features/home/home_controller.dart';
import 'package:milan_app/features/home/widgets/person_action_card.dart';

/// Which side of the request list we're looking at.
enum _RequestSide { received, sent }

/// "Requested" tab — inbound and outbound connection requests.
///
/// A top toggle switches between **Received** (people who requested me) and
/// **Sent** (people I requested). On the Received side, accepting likes the
/// person back (a mutual like creates a match) and declining passes them.
class RequestedTab extends ConsumerStatefulWidget {
  const RequestedTab({super.key});

  @override
  ConsumerState<RequestedTab> createState() => _RequestedTabState();
}

class _RequestedTabState extends ConsumerState<RequestedTab> {
  _RequestSide _side = _RequestSide.received;
  final Set<String> _busy = <String>{};

  Future<void> _accept(Profile profile) async {
    if (_busy.contains(profile.id)) return;
    setState(() => _busy.add(profile.id));
    try {
      final String? matchId = await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.like);
      ref.invalidate(myRequestsProvider);
      if (matchId != null && mounted) {
        await MatchDialog.show(context, profile: profile, matchId: matchId);
      }
    } catch (error) {
      if (mounted) showAppSnack(context, 'Accept failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(profile.id));
    }
  }

  Future<void> _decline(Profile profile) async {
    if (_busy.contains(profile.id)) return;
    setState(() => _busy.add(profile.id));
    try {
      await ref
          .read(discoverControllerProvider.notifier)
          .swipe(profile: profile, direction: SwipeDirection.pass);
      ref.invalidate(myRequestsProvider);
    } catch (error) {
      if (mounted) showAppSnack(context, 'Decline failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final AsyncValue<List<Profile>> profiles = _side == _RequestSide.received
        ? ref.watch(myRequestsProvider)
        : ref.watch(sentRequestsProvider);

    return Column(
      children: <Widget>[
        _SideToggle(
          receivedLabel: strings.received,
          sentLabel: strings.sent,
          side: _side,
          onChanged: (_RequestSide value) => setState(() => _side = value),
        ),
        Expanded(
          child: profiles.when(
            loading: () => const AppLoader(),
            error: (Object error, StackTrace stack) =>
                AppErrorView(error: error),
            data: (List<Profile> list) {
              final bool received = _side == _RequestSide.received;
              if (list.isEmpty) {
                return AppEmptyState(
                  icon: received
                      ? Icons.mark_email_unread_outlined
                      : Icons.outbox_outlined,
                  title: received
                      ? strings.noRequestsTitle
                      : strings.noSentRequestsTitle,
                  message: received
                      ? strings.noRequestsBody
                      : strings.noSentRequestsBody,
                );
              }

              final FutureProvider<List<Profile>> active =
                  received ? myRequestsProvider : sentRequestsProvider;

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(active),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final Profile profile = list[index];
                    final bool busy = _busy.contains(profile.id);
                    return PersonActionCard(
                      profile: profile,
                      busy: busy,
                      actionLabel:
                          received ? strings.acceptRequest : strings.pending,
                      actionIcon: received
                          ? Icons.check
                          : Icons.hourglass_empty,
                      onAction: received ? () => _accept(profile) : null,
                      onDismiss: received ? () => _decline(profile) : null,
                      dismissIcon: Icons.close,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A small two-segment toggle (Received / Sent).
class _SideToggle extends StatelessWidget {
  const _SideToggle({
    required this.receivedLabel,
    required this.sentLabel,
    required this.side,
    required this.onChanged,
  });

  final String receivedLabel;
  final String sentLabel;
  final _RequestSide side;
  final ValueChanged<_RequestSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentButton(
              label: receivedLabel,
              selected: side == _RequestSide.received,
              onTap: () => onChanged(_RequestSide.received),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SegmentButton(
              label: sentLabel,
              selected: side == _RequestSide.sent,
              onTap: () => onChanged(_RequestSide.sent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
