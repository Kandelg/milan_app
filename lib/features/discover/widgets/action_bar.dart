import 'dart:ui';

import 'package:flutter/material.dart';

/// Pass / like / rewind / super-like buttons under the swipe deck.
///
/// Each button is a frosted-glass circle so it sits cleanly on the gradient.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.onPass,
    required this.onLike,
    required this.onUndo,
    this.onSuperLike,
  });

  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onUndo;
  final VoidCallback? onSuperLike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _GlassCircleButton(
            icon: Icons.rotate_left,
            color: Colors.amber.shade700,
            size: 48,
            tooltip: 'Rewind',
            onPressed: onUndo,
          ),
          _GlassCircleButton(
            icon: Icons.close,
            color: Colors.red.shade400,
            size: 64,
            tooltip: 'Pass',
            onPressed: onPass,
          ),
          _GlassCircleButton(
            icon: Icons.star,
            color: Colors.blue.shade400,
            size: 52,
            tooltip: 'Super like',
            onPressed: onSuperLike,
          ),
          _GlassCircleButton(
            icon: Icons.favorite,
            color: const Color(0xFFEE2E31),
            size: 64,
            tooltip: 'Like',
            onPressed: onLike,
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? color.withValues(alpha: 0.16)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: enabled ? 0.25 : 0.08),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Icon(
                  icon,
                  color: enabled ? color : theme.colorScheme.outline,
                  size: size * 0.42,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

