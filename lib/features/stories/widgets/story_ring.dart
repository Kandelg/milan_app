import 'package:flutter/material.dart';

/// Gradient ring (pink -> purple) around avatars that have a fresh story.
class StoryRing extends StatelessWidget {
  const StoryRing({super.key, required this.hasStory, required this.child});

  final bool hasStory;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!hasStory) {
      return Padding(padding: const EdgeInsets.all(3), child: child);
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFF6B4A), Color(0xFFEE2E31)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: child,
      ),
    );
  }
}
