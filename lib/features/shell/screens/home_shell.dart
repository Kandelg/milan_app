import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/features/home/home_controller.dart';

/// Bottom-navigation shell shared by Home, Messages, Matches and Profile.
///
/// The bar itself is a frosted-glass [GlassBackground]-style surface so it
/// blends with the gradient behind it. The Home tab shows the unread
/// notifications count and the Matches tab shows the count of brand-new
/// matches, both derived live from realtime providers.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = GoRouter.of(context);
    final String location = router.state.uri.toString();
    final AppStrings strings = AppStrings.of(context);

    // Live badge counts — both recompute automatically on realtime changes.
    final int unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final int newMatches = ref.watch(newMatchesCountProvider);

    final List<_ShellTab> tabs = <_ShellTab>[
      _ShellTab(
        path: AppRoutes.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: strings.home,
        badgeCount: unreadNotifications,
      ),
      _ShellTab(
        path: AppRoutes.messages,
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble_rounded,
        label: strings.messages,
      ),
      _ShellTab(
        path: AppRoutes.matches,
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: strings.matches,
        badgeCount: newMatches,
      ),
      _ShellTab(
        path: AppRoutes.profile,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: strings.profile,
      ),
    ];

    final int selectedIndex = tabs.indexWhere(
      (_ShellTab tab) => location.startsWith(tab.path),
    );

    return Scaffold(
      extendBody: true,
      body: GlassBackground(child: child),
      bottomNavigationBar: _GlassNavBar(
        tabs: tabs,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (int index) {
          final String path = tabs[index].path;
          if (location != path) router.go(path);
        },
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.10
                    : 0.45,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFFF6B4A).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List<Widget>.generate(tabs.length, (int index) {
                final _ShellTab tab = tabs[index];
                final bool selected = index == selectedIndex;
                return _NavItem(
                  tab: tab,
                  selected: selected,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  onTap: () => onSelected(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _BadgedIcon(
                icon: selected ? tab.selectedIcon : tab.icon,
                color: color,
                count: tab.badgeCount,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Number shown in the small badge on the icon (0 hides the badge).
  final int badgeCount;
}

/// An icon with an optional count badge pinned to its top-right corner.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Widget image = Icon(icon, color: color, size: 24);
    if (count <= 0) return image;

    final String label = count > 9 ? '9+' : '$count';
    return Badge(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: const Color(0xFFEE2E31),
      offset: const Offset(-6, 6),
      child: image,
    );
  }
}

