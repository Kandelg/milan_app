import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:milan_app/features/onboarding/screens/steps/details_step.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Form for updating the signed-in user's profile details.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _currentLocationController =
      TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _maritalStatus;
  String? _zodiacSign;
  String? _selectedOccupation;
  bool _loadingProfile = true;
  bool _saving = false;
  bool _fetchingLocation = false;
  String? _loadError;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _permanentAddressController.dispose();
    _currentLocationController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });

    try {
      final User? user = _supabase.auth.currentUser;
      if (user == null) {
        throw StateError('Please sign in to edit your profile.');
      }

      final Map<String, dynamic>? profile = await _supabase
          .from('profiles')
          .select(
            'marital_status, zodiac_sign, permanent_address, current_location, occupation, height_cm',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (profile != null) {
        _maritalStatus = _validOrNull(
          profile['marital_status'] as String?,
          _maritalStatuses,
        );
        _zodiacSign = _validOrNull(
          profile['zodiac_sign'] as String?,
          _zodiacSigns,
        );
        _permanentAddressController.text =
            profile['permanent_address'] as String? ?? '';
        _currentLocationController.text =
            profile['current_location'] as String? ?? '';
        final String occupation = profile['occupation'] as String? ?? '';
        if (DetailsStep.occupations.contains(occupation)) {
          _selectedOccupation = occupation;
        } else if (occupation.isNotEmpty) {
          _selectedOccupation = 'Other';
          _occupationController.text = occupation;
        }
        final int? heightCm = profile['height_cm'] as int?;
        _heightController.text = heightCm?.toString() ?? '';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load profile: $error');
      _showSnackBar(_loadError!, isError: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String? _validOrNull(String? value, List<String> allowedValues) {
    return allowedValues.contains(value) ? value : null;
  }

  Future<void> _fetchCurrentLocation() async {
    if (_fetchingLocation) return;
    setState(() => _fetchingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(
          'Turn on your device location services and try again.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is permanently denied. Enable it in Settings.',
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw StateError('No readable place was found for your location.');
      }

      final Placemark place = placemarks.first;
      final String locality = (place.locality ?? '').trim();
      final String subArea = (place.subAdministrativeArea ?? '').trim();
      final String country = (place.country ?? '').trim();
      final List<String> parts = <String>[
        if (locality.isNotEmpty) locality,
        if (subArea.isNotEmpty && subArea != locality) subArea,
        if (country.isNotEmpty) country,
      ];
      if (parts.isEmpty) {
        throw StateError('No readable place was found for your location.');
      }

      if (!mounted) return;
      _currentLocationController.text = parts.join(', ');
      _showSnackBar('Current location updated.');
    } catch (error) {
      if (mounted) {
        _showSnackBar('Could not fetch location: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final User? user = _supabase.auth.currentUser;
      if (user == null) {
        throw StateError('Please sign in to update your profile.');
      }

      await _supabase
          .from('profiles')
          .update(<String, dynamic>{
            'marital_status': _maritalStatus,
            'zodiac_sign': _zodiacSign,
            'permanent_address': _permanentAddressController.text.trim(),
            'current_location': _currentLocationController.text.trim(),
            'occupation': _selectedOccupation == 'Other'
                ? _occupationController.text.trim()
                : _selectedOccupation ?? '',
            'height_cm': int.tryParse(_heightController.text.trim()),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      if (mounted) _showSnackBar('Profile updated successfully.');
    } catch (error) {
      if (mounted) {
        _showSnackBar('Could not update profile: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile settings')),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _LoadErrorView(message: _loadError!, onRetry: _loadProfile)
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: <Widget>[
                    Text(
                      'Your details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep your profile information up to date.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOccupation,
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: DetailsStep.occupations
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(growable: false),
                      validator: (String? value) =>
                          value == null ? 'Select your profession' : null,
                      onChanged: _saving
                          ? null
                          : (String? value) => setState(() {
                              _selectedOccupation = value;
                              if (value != 'Other') {
                                _occupationController.clear();
                              }
                            }),
                    ),
                    if (_selectedOccupation == 'Other') ...<Widget>[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _occupationController,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Specify your profession',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        validator: (String? value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your profession'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        hintText: '122–213 cm (4′0″–7′0″)',
                        suffixText: 'cm',
                        prefixIcon: Icon(Icons.height_outlined),
                      ),
                      validator: (String? value) {
                        final String input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        final int? heightCm = int.tryParse(input);
                        if (heightCm == null ||
                            heightCm < 122 ||
                            heightCm > 213) {
                          return 'Enter a height from 122 cm to 213 cm (4′0″–7′0″)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
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
                      validator: (String? value) =>
                          value == null ? 'Select your marital status' : null,
                      onChanged: _saving
                          ? null
                          : (String? value) =>
                                setState(() => _maritalStatus = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _zodiacSign,
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
                      validator: (String? value) =>
                          value == null ? 'Select your zodiac sign' : null,
                      onChanged: _saving
                          ? null
                          : (String? value) =>
                                setState(() => _zodiacSign = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _permanentAddressController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Permanent Address',
                        hintText: 'Your fixed home address',
                        prefixIcon: Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (String? value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your permanent address'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentLocationController,
                      enabled: !_saving && !_fetchingLocation,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Current Location',
                        hintText: 'City or area',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: _fetchingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Use device location',
                                onPressed: _saving
                                    ? null
                                    : _fetchCurrentLocation,
                                icon: const Icon(Icons.my_location_rounded),
                              ),
                      ),
                      validator: (String? value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter or fetch your current location'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _saving || _fetchingLocation
                          ? null
                          : _saveProfile,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Saving…' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
