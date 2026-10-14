import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable "liquid glass" building blocks for the Bihe & Date UI.
///
/// The whole look relies on three ingredients:
///  1. a soft sunset (pink → orange → red) gradient background
///     ([GlassBackground]),
///  2. frosted translucent panels ([GlassCard]) using `BackdropFilter`,
///  3. gradient-filled primary buttons ([GlassButton]).

/// Animated gradient background with soft colour "blobs".
///
/// Wrap any screen body in this to get the signature glass backdrop.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[
                  Color(0xFF2E1512),
                  Color(0xFF3D1C16),
                  Color(0xFF1E0E0C),
                ]
              : const <Color>[
                  Color(0xFFFFE7DC),
                  Color(0xFFFFEFE0),
                  Color(0xFFFFEDE6),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _Blob(
            alignment: const Alignment(-1.1, -1.1),
            size: 320,
            color: const Color(0xFFFF8E72)
                .withValues(alpha: isDark ? 0.35 : 0.55),
          ),
          _Blob(
            alignment: const Alignment(1.2, -0.7),
            size: 280,
            color: const Color(0xFFFFC16B)
                .withValues(alpha: isDark ? 0.32 : 0.5),
          ),
          _Blob(
            alignment: const Alignment(0.9, 1.1),
            size: 300,
            color: const Color(0xFFFF6B6B)
                .withValues(alpha: isDark ? 0.28 : 0.45),
          ),
          ? child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

/// A frosted-glass panel. Used for cards, sheets and list tiles.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.65),
              width: 1.3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFFF6B4A)
                    .withValues(alpha: isDark ? 0.16 : 0.10),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return margin == null
          ? panel
          : Padding(padding: margin!, child: panel);
    }
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: panel,
        ),
      ),
    );
  }
}

/// Primary action button with a pink→purple gradient fill.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.height = 54,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;
  final double height;

  static const List<Color> _gradient = <Color>[
    Color(0xFFFF9F43),
    Color(0xFFFF6B4A),
    Color(0xFFEE2E31),
  ];

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFFF6B4A).withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transparent, glass-outlined secondary button.
class GlassOutlinedButton extends StatelessWidget {
  const GlassOutlinedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.height = 54,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_back, color: scheme.primary, size: 20),
        label: Text(
          label,
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.white.withValues(
            alpha:
                Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.35,
          ),
        ),
      ),
    );
  }
}
/// A translucent pill used for chips / tags on top of photos or glass.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: base),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: base,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted app bar with a translucent surface and no hard edges.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, required this.title, this.actions, this.leading});

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
          child: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: leading,
            title: Text(
              title,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: actions,
            iconTheme: IconThemeData(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}


