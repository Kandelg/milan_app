import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:milan_app/data/models.dart';

/// One photo tile in the Liked grid: the person's photo, their name/age on a
/// bottom scrim and a love button pinned to the bottom-right corner.
class LikedPhotoCard extends StatelessWidget {
  const LikedPhotoCard({
    super.key,
    required this.profile,
    required this.onLike,
    this.busy = false,
  });

  final Profile profile;
  final VoidCallback onLike;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final String? photo = profile.primaryPhoto;
    final int? age = profile.age;
    final ThemeData theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Photo (or a placeholder when none is set).
          if (photo != null && photo.isNotEmpty)
            CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest),
              errorWidget: (_, _, _) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.person, size: 48),
              ),
            )
          else
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.person, size: 48),
            ),

          // Bottom scrim with name + age.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Text(
                age != null ? '${profile.fullName}, $age' : profile.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Love button — bottom-right corner.
          Positioned(
            right: 8,
            bottom: 34,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: busy ? null : onLike,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFF9F43), Color(0xFFEE2E31)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFEE2E31).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
