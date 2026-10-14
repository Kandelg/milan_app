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
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.network(
                        profile.primaryPhoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.82),
                              ],
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      profile.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (profile
                                        .currentLocation
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              profile.currentLocation,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (age != null ||
                                  profile.heightLabel != null) ...<Widget>[
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    if (age != null)
                                      Text(
                                        '$age years',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    if (profile.heightLabel != null)
                                      Text(
                                        profile.heightLabel!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (profile.occupation.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        profile.occupation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (profile.bio.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(profile.bio, style: theme.textTheme.bodyLarge),
                    ],
                    if (profile.birthDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(Icons.cake_outlined,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${profile.birthDate!.year.toString().padLeft(4, '0')}-'
                            '${profile.birthDate!.month.toString().padLeft(2, '0')}-'
                            '${profile.birthDate!.day.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          _VisibilityButton(
                            value: profile.birthDateVisibility,
                            onChanged: (String value) => _saveVisibility(
                              context,
                              ref,
                              profile,
                              birthDateVisibility: value,
                            ),
                          ),
                        ],
                      ),
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
                          const Spacer(),
                          _VisibilityButton(
                            value: profile.phoneVisibility,
                            onChanged: (String value) => _saveVisibility(
                              context,
                              ref,
                              profile,
                              phoneVisibility: value,
                            ),
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
                        children: _details(profile, strings)
                            .map(
                              (_ProfileDetail detail) => Chip(
                                avatar: Icon(
                                  detail.icon,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                label: Text(detail.label),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(strings.editProfile),
                      subtitle: Text(strings.editProfileSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.editProfile),
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

Future<void> _saveVisibility(
  BuildContext context,
  WidgetRef ref,
  Profile profile, {
  String? birthDateVisibility,
  String? phoneVisibility,
}) async {
  try {
    await ref.read(myProfileControllerProvider.notifier).save(
      profile.copyWith(
        birthDateVisibility: birthDateVisibility,
        phoneVisibility: phoneVisibility,
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy setting saved.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save privacy setting: $error')),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (value) {
      'public' => (Icons.public, 'Public'),
      'friends' => (Icons.people_outline, 'Friends'),
      _ => (Icons.lock_outline, 'Only me'),
    };
    return PopupMenuButton<String>(
      tooltip: 'Who can see this?',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'public',
          child: ListTile(
            leading: Icon(Icons.public),
            title: Text('Public'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'friends',
          child: ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Friends (mutual matches)'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'only_me',
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Only me'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
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
