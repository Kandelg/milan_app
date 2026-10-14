import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';

/// Icon shown next to each lifestyle detail (height, religion, ...).
IconData profileDetailIcon(String kind) {
  switch (kind) {
    case 'height':
      return Icons.height_outlined;
    case 'religion':
      return Icons.temple_hindu_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'diet':
      return Icons.restaurant_outlined;
    case 'smoking':
      return Icons.smoking_rooms_outlined;
    case 'occupation':
      return Icons.work_outline;
    case 'city':
      return Icons.location_city_outlined;
    default:
      return Icons.info_outline;
  }
}

/// Step 4 — bio, city, occupation, height, lifestyle and interests.
class DetailsStep extends StatelessWidget {
  static const List<String> occupations = <String>[
    'Student',
    'Teacher',
    'Healthcare Professional',
    'Engineer',
    'IT Professional',
    'Business Owner',
    'Government Employee',
    'Finance Professional',
    'Lawyer',
    'Artist / Designer',
    'Hospitality Professional',
    'Homemaker',
    'Other',
  ];

  const DetailsStep({
    super.key,
    required this.formKey,
    required this.bioController,
    required this.permanentAddressController,
    required this.currentLocationController,
    required this.fetchingLocation,
    required this.onFetchLocation,
    required this.occupationController,
    required this.selectedOccupation,
    required this.onOccupationChanged,
    required this.phoneController,
    required this.heightController,
    required this.interests,
    required this.onToggleInterest,
    required this.religion,
    required this.onReligionChanged,
    required this.education,
    required this.onEducationChanged,
    required this.diet,
    required this.onDietChanged,
    required this.smoking,
    required this.onSmokingChanged,
    required this.maritalStatus,
    required this.onMaritalStatusChanged,
    required this.zodiacSign,
    required this.onZodiacSignChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final TextEditingController permanentAddressController;
  final TextEditingController currentLocationController;
  final bool fetchingLocation;
  final VoidCallback onFetchLocation;
  final TextEditingController occupationController;
  final String? selectedOccupation;
  final ValueChanged<String?> onOccupationChanged;
  final TextEditingController phoneController;
  final TextEditingController heightController;
  final Set<String> interests;
  final ValueChanged<String> onToggleInterest;
  final String? religion;
  final ValueChanged<String?> onReligionChanged;
  final String? education;
  final ValueChanged<String?> onEducationChanged;
  final String? diet;
  final ValueChanged<String?> onDietChanged;
  final String? smoking;
  final ValueChanged<String?> onSmokingChanged;
  final String? maritalStatus;
  final ValueChanged<String?> onMaritalStatusChanged;
  final String? zodiacSign;
  final ValueChanged<String?> onZodiacSignChanged;

  static const List<String> _maritalStatuses = <String>[
    'Unmarried',
    'Divorced',
    'Widowed',
  ];

  static const List<String> _zodiacSigns = <String>[
    'Aries (मेष)',
    'Taurus (वृष)',
    'Gemini (मिथुन)',
    'Cancer (कर्कट)',
    'Leo (सिंह)',
    'Virgo (कन्या)',
    'Libra (तुला)',
    'Scorpio (वृश्चिक)',
    'Sagittarius (धनु)',
    'Capricorn (मकर)',
    'Aquarius (कुम्भ)',
    'Pisces (मीन)',
  ];

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('A bit more', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Tell people what makes you, you.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: bioController,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'About me',
              hintText: 'Coffee lover, weekend trekker…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: permanentAddressController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Permanent Address',
              prefixIcon: const Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: currentLocationController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Current Location',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: fetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Use device location',
                      onPressed: onFetchLocation,
                      icon: const Icon(Icons.my_location_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedOccupation,
            decoration: InputDecoration(
              labelText: strings.occupation,
              prefixIcon: Icon(profileDetailIcon('occupation')),
            ),
            items: occupations
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(growable: false),
            onChanged: onOccupationChanged,
          ),
          if (selectedOccupation == 'Other') ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: occupationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Specify your profession',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (String? value) =>
                  selectedOccupation == 'Other' &&
                      (value == null || value.trim().isEmpty)
                  ? 'Please enter your profession'
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: heightController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: strings.height,
              hintText: '122–213 cm (4′0″–7′0″)',
              prefixIcon: Icon(profileDetailIcon('height')),
              suffixText: 'cm',
            ),
            validator: (String? value) {
              final String input = value?.trim() ?? '';
              if (input.isEmpty) return null;
              final int? heightCm = int.tryParse(input);
              if (heightCm == null || heightCm < 122 || heightCm > 213) {
                return 'Enter a height from 122 cm to 213 cm (4′0″–7′0″)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: strings.phone,
              hintText: strings.phoneHint,
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+977 ',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Marital Status',
              prefixIcon: Icon(Icons.people_outline),
            ),
            items: _maritalStatuses
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(growable: false),
            validator: (String? value) => value == null || value.isEmpty
                ? 'Please select your marital status'
                : null,
            onChanged: onMaritalStatusChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: zodiacSign,
            decoration: const InputDecoration(
              labelText: 'Zodiac Sign',
              prefixIcon: Icon(Icons.auto_awesome_outlined),
            ),
            items: _zodiacSigns
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(growable: false),
            validator: (String? value) => value == null || value.isEmpty
                ? 'Please select your zodiac sign'
                : null,
            onChanged: onZodiacSignChanged,
          ),
          const SizedBox(height: 24),
          AppSectionTitle(strings.religion),
          _OptionChips(
            options: kReligions,
            selected: religion,
            onChanged: onReligionChanged,
          ),
          const SizedBox(height: 16),
          AppSectionTitle(strings.education),
          _OptionChips(
            options: kEducations,
            selected: education,
            onChanged: onEducationChanged,
          ),
          const SizedBox(height: 16),
          AppSectionTitle(strings.diet),
          _OptionChips(
            options: kDiets,
            selected: diet,
            onChanged: onDietChanged,
          ),
          const SizedBox(height: 16),
          AppSectionTitle(strings.smoking),
          _OptionChips(
            options: kSmokings,
            selected: smoking,
            onChanged: onSmokingChanged,
          ),
          const SizedBox(height: 24),
          const AppSectionTitle('Interests'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kInterests.map((String interest) {
              return FilterChip(
                label: Text(interest),
                selected: interests.contains(interest),
                onSelected: (_) => onToggleInterest(interest),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Single-select chips with a "not set" state (tap again to clear).
class _OptionChips extends StatelessWidget {
  const _OptionChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((String value) {
        return ChoiceChip(
          label: Text(strings.lifestyleLabel(value)),
          selected: selected == value,
          onSelected: (_) => onChanged(selected == value ? null : value),
        );
      }).toList(),
    );
  }
}
