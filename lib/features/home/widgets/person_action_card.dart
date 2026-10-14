import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/data/models.dart';

/// A compact profile row used by the New / Requested tabs: avatar, name/age,
/// optional city line and a configurable action button.
class PersonActionCard extends StatelessWidget {
  const PersonActionCard({
    super.key,
    required this.profile,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = Icons.favorite,
    this.busy = false,
    this.onDismiss,
    this.dismissIcon = Icons.close,
  });

  final Profile profile;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final bool busy;

  /// Optional secondary action (e.g. decline a request).
  final VoidCallback? onDismiss;
  final IconData dismissIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? photo = profile.primaryPhoto;
    final int? age = profile.age;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundImage:
                (photo != null && photo.isNotEmpty)
                    ? CachedNetworkImageProvider(photo)
                    : null,
            child: (photo == null || photo.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  age != null ? '${profile.fullName}, $age' : profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (profile.city.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    profile.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onDismiss != null) ...<Widget>[
            IconButton.outlined(
              onPressed: busy ? null : onDismiss,
              icon: Icon(dismissIcon, size: 20),
              tooltip: 'Decline',
            ),
            const SizedBox(width: 6),
          ],
          FilledButton.icon(
            onPressed: busy ? null : onAction,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(actionIcon, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
