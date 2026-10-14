import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/onboarding/screens/steps/details_step.dart';
import 'package:milan_app/features/profile/profile_controller.dart';

/// Shows the signed-in user's own profile, with logout and account actions.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Profile?> profileAsync = ref.watch(
      myProfileControllerProvider,
    );
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      appBar: GlassAppBar(
        title: strings.myProfile,
        actions: <Widget>[
          IconButton(
            tooltip: strings.settings,
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const AppLoader(),
        error: (Object error, StackTrace stack) => AppErrorView(error: error),
        data: (Profile? profile) {
          if (profile == null) {
            return const AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'No profile yet',
              message: 'Finish onboarding to appear in Discover.',
            );
          }

          final int? age = profile.age;

          return ListView(
            children: <Widget>[
              if (profile.primaryPhoto != null)
                Image.network(
                  profile.primaryPhoto!,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 320,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            profile.fullName,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        if (age != null)
                          Text(
                            '$age',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (profile.city.isNotEmpty ||
                        profile.occupation.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        <String>[
                          profile.occupation,
                          profile.city,
                        ].where((String s) => s.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (profile.bio.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(profile.bio, style: theme.textTheme.bodyLarge),
                    ],
                    if (profile.phone.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+977 ${profile.phone}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    if (profile.interests.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 20),
                      AppSectionTitle(strings.interests),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.interests
                            .map((String i) => Chip(label: Text(i)))
                            .toList(),
                      ),
                    ],
                    if (_details(profile, strings).isNotEmpty) ...<Widget>[
                      const SizedBox(height: 20),
                      AppSectionTitle(
                        strings.language == AppLanguage.nepali
                            ? 'विवरण'
                            : 'Details',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _details(profile, strings).map(
                          (_ProfileDetail detail) => Chip(
                            avatar: Icon(
                              detail.icon,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(detail.label),
                          ),
                        ).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(strings.editProfile),
                      subtitle: Text(strings.editProfileSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.onboarding),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// One lifestyle row on My Profile (icon + label).
class _ProfileDetail {
  const _ProfileDetail(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Icon chips for the new lifestyle fields (height, religion, ...).
List<_ProfileDetail> _details(Profile profile, AppStrings strings) {
  final List<_ProfileDetail> details = <_ProfileDetail>[];
  final String? height = profile.heightLabel;
  if (height != null) {
    details.add(_ProfileDetail(height, profileDetailIcon('height')));
  }
  if (profile.religion != null && profile.religion!.isNotEmpty) {
    details.add(
      _ProfileDetail(
        strings.lifestyleLabel(profile.religion!),
        profileDetailIcon('religion'),
      ),
    );
  }
  if (profile.education != null && profile.education!.isNotEmpty) {
    details.add(
      _ProfileDetail(
        strings.lifestyleLabel(profile.education!),
        profileDetailIcon('education'),
      ),
    );
  }
  if (profile.diet != null && profile.diet!.isNotEmpty) {
    details.add(
      _ProfileDetail(
        strings.lifestyleLabel(profile.diet!),
        profileDetailIcon('diet'),
      ),
    );
  }
  if (profile.smoking != null && profile.smoking!.isNotEmpty) {
    details.add(
      _ProfileDetail(
        strings.lifestyleLabel(profile.smoking!),
        profileDetailIcon('smoking'),
      ),
    );
  }
  return details;
}
