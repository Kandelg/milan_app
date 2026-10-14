import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/onboarding/screens/steps/details_step.dart';

/// One swipeable profile card: photo, gradient scrim, glass details and a
/// block/report menu.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile, this.onMenu});

  final Profile profile;

  /// Opens the block / report sheet; provided by [DiscoverScreen].
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final String? photo = profile.primaryPhoto;
    final int? age = profile.age;
    final AppStrings strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFFF6B4A).withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (photo != null)
              Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              )
            else
              const Center(child: Icon(Icons.person, size: 96)),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black87],
                  stops: <double>[0.35, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),

            if (onMenu != null)
              Positioned(
                top: 12,
                right: 12,
                child: _GlassIconButton(
                  icon: Icons.more_vert,
                  onPressed: onMenu!,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          profile.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            shadows: <Shadow>[
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      if (age != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Text(
                          '$age',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            shadows: <Shadow>[
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_locationLine.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      _locationLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: <Shadow>[
                          Shadow(blurRadius: 6, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                  if (profile.bio.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      profile.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, height: 1.3),
                    ),
                  ],
                  if (_detailChips(strings).isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _detailChips(strings)
                          .map(
                            (_DetailChip chip) => GlassPill(
                              label: chip.label,
                              icon: chip.icon,
                              color: Colors.white,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (profile.interests.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: profile.interests
                          .take(4)
                          .map(
                            (String interest) =>
                                GlassPill(label: interest, color: Colors.white),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _locationLine => <String>[
    profile.occupation,
    profile.currentLocation,
  ].where((String s) => s.isNotEmpty).join(' · ');

  /// Icon chips for height, religion, education, diet and smoking.
  List<_DetailChip> _detailChips(AppStrings strings) {
    final List<_DetailChip> chips = <_DetailChip>[];
    final String? height = profile.heightLabel;
    if (height != null) {
      chips.add(_DetailChip(height, profileDetailIcon('height')));
    }
    if (profile.religion != null && profile.religion!.isNotEmpty) {
      chips.add(
        _DetailChip(
          strings.lifestyleLabel(profile.religion!),
          profileDetailIcon('religion'),
        ),
      );
    }
    if (profile.education != null && profile.education!.isNotEmpty) {
      chips.add(
        _DetailChip(
          strings.lifestyleLabel(profile.education!),
          profileDetailIcon('education'),
        ),
      );
    }
    if (profile.diet != null && profile.diet!.isNotEmpty) {
      chips.add(
        _DetailChip(
          strings.lifestyleLabel(profile.diet!),
          profileDetailIcon('diet'),
        ),
      );
    }
    if (profile.smoking != null && profile.smoking!.isNotEmpty) {
      chips.add(
        _DetailChip(
          strings.lifestyleLabel(profile.smoking!),
          profileDetailIcon('smoking'),
        ),
      );
    }
    return chips;
  }
}

class _DetailChip {
  const _DetailChip(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
