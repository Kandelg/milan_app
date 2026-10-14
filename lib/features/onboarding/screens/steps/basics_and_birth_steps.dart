import 'package:flutter/material.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';

/// Step 1 — name, my gender and who I want to see.
class BasicsStep extends StatelessWidget {
  const BasicsStep({
    super.key,
    required this.nameController,
    required this.gender,
    required this.interestedIn,
    required this.onGenderChanged,
    required this.onInterestedInChanged,
  });

  final TextEditingController nameController;
  final String? gender;
  final String interestedIn;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String> onInterestedInChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          strings.aboutYou,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'This is what other people will see first.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: strings.fullName,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 24),
        AppSectionTitle(strings.iAm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kGenders.map((String value) {
            return ChoiceChip(
              label: Text(strings.genderLabel(value)),
              selected: gender == value,
              onSelected: (_) => onGenderChanged(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        AppSectionTitle(strings.interestedIn),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>[...kGenders, kGenderEveryone].map((String value) {
            return ChoiceChip(
              label: Text(strings.genderLabel(value)),
              selected: interestedIn == value,
              onSelected: (_) => onInterestedInChanged(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Step 2 — date of birth with an 18+ guard.
class BirthDateStep extends StatelessWidget {
  const BirthDateStep({
    super.key,
    required this.birthDate,
    required this.onChanged,
  });

  final DateTime? birthDate;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 22),
      firstDate: DateTime(now.year - kMaxAge),
      lastDate: DateTime(now.year - kMinAge, now.month, now.day),
      helpText: 'Select your date of birth',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? dob = birthDate;
    final AppStrings strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(strings.yourBirthday, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'You must be at least $kMinAge years old to use ${strings.appName}.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: Text(
              dob == null
                  ? 'Not selected'
                  : '${dob.day.toString().padLeft(2, '0')}/'
                        '${dob.month.toString().padLeft(2, '0')}/'
                        '${dob.year}',
            ),
            subtitle: Text(dob == null ? 'Tap to choose' : 'Tap to change'),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pick(context),
          ),
        ),
      ],
    );
  }
}

