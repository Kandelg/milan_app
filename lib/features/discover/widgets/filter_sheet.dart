import 'package:flutter/material.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/discover_repository.dart';

/// Bottom sheet for narrowing the deck by age, gender, city and interests.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.initial});

  final DiscoverFilters initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late double _minAge = widget.initial.minAge.toDouble();
  late double _maxAge = widget.initial.maxAge.toDouble();
  late String? _gender = widget.initial.gender;
  late final TextEditingController _city = TextEditingController(
    text: widget.initial.city ?? '',
  );
  late final Set<String> _interests = <String>{...widget.initial.interests};

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _minAge = kFilterMinAge.toDouble();
      _maxAge = kFilterMaxAge.toDouble();
      _gender = null;
      _city.clear();
      _interests.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DiscoverFilters(
        minAge: _minAge.round(),
        maxAge: _maxAge.round(),
        gender: _gender,
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        interests: _interests.toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings.filters,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: _reset, child: Text(strings.reset)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Age: ${_minAge.round()} – ${_maxAge.round()}',
              style: theme.textTheme.bodyMedium,
            ),
            RangeSlider(
              min: kFilterMinAge.toDouble(),
              max: kFilterMaxAge.toDouble(),
              divisions: kFilterMaxAge - kFilterMinAge,
              values: RangeValues(_minAge, _maxAge),
              labels: RangeLabels(
                _minAge.round().toString(),
                _maxAge.round().toString(),
              ),
              onChanged: (RangeValues values) => setState(() {
                _minAge = values.start;
                _maxAge = values.end;
              }),
            ),
            const SizedBox(height: 8),
            Text(strings.showMe, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Anyone'),
                  selected: _gender == null,
                  onSelected: (_) => setState(() => _gender = null),
                ),
                ...kGenders.map((String gender) {
                  return ChoiceChip(
                    label: Text(strings.genderLabel(gender)),
                    selected: _gender == gender,
                    onSelected: (_) => setState(() => _gender = gender),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text(strings.interests, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kInterests.map((String interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: _interests.contains(interest),
                  onSelected: (bool selected) => setState(() {
                    if (selected) {
                      _interests.add(interest);
                    } else {
                      _interests.remove(interest);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _apply,
              child: Text(strings.showResults),
            ),
          ],
        ),
      ),
    );
  }
}

