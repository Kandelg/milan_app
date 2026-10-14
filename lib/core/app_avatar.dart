import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar with graceful placeholders for missing photos.
///
/// Centralises the avatar look used across matches, likes, requests and
/// notifications so every list stays visually consistent.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.photoUrl, this.radius = 26});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Icon(Icons.person, size: radius, color: scheme.onSurfaceVariant),
    );
  }
}
