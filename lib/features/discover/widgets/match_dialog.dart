import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/models.dart';

/// Celebratory dialog shown when a swipe is mutual.
class MatchDialog extends StatelessWidget {
  const MatchDialog({super.key, required this.profile, this.matchId});

  final Profile profile;

  /// Present when the backend created a match row for this swipe.
  final String? matchId;

  /// Shows the dialog; resolves when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    required Profile profile,
    String? matchId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) =>
          MatchDialog(profile: profile, matchId: matchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFE7DC), Color(0xFFFFEFE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFFF6B4A).withValues(alpha: 0.35),
              blurRadius: 30,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.favorite, size: 64, color: Color(0xFFEE2E31)),
              const SizedBox(height: 12),
              Text(
                strings.itsAMatch,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You and ${profile.fullName} liked each other.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (profile.primaryPhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    profile.primaryPhoto!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              GlassButton(
                label: strings.sendMessage,
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (matchId != null) {
                    context.push(AppRoutes.chat(matchId!));
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.keepSwiping),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
