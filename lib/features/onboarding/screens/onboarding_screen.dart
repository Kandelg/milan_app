import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/profile/profile_controller.dart';
import 'package:milan_app/features/onboarding/screens/steps/basics_and_birth_steps.dart';
import 'package:milan_app/features/onboarding/screens/steps/details_step.dart';
import 'package:milan_app/features/onboarding/screens/steps/photos_step.dart';

/// Multi-step wizard that turns a fresh account into a discoverable profile.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _stepCount = 4;

  late final PageController _pageController;
  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _permanentAddress = TextEditingController();
  final TextEditingController _currentLocation = TextEditingController();
  final TextEditingController _occupation = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _height = TextEditingController();

  int _step = 0;

  DateTime? _birthDate;
  String? _gender;
  String _interestedIn = kGenderEveryone;
  final Set<String> _interests = <String>{};
  final List<String> _photoUrls = <String>[];

  /// Optional lifestyle details (all nullable = "not set").
  int? _heightCm;
  String? _selectedOccupation;
  String? _religion;
  String? _education;
  String? _diet;
  String? _smoking;
  String? _maritalStatus;
  String? _zodiacSign;

  bool _busy = false;
  bool _fetchingLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill all saved data and resume at the first required step that is
    // incomplete. This also lets existing accounts finish a partial profile.
    final Profile? existing = ref.read(myProfileControllerProvider).value;
    if (existing != null) {
      _name.text = existing.fullName;
      _bio.text = existing.bio;
      _permanentAddress.text = existing.permanentAddress;
      _currentLocation.text = existing.currentLocation;
      if (DetailsStep.occupations.contains(existing.occupation)) {
        _selectedOccupation = existing.occupation;
      } else if (existing.occupation.isNotEmpty) {
        _selectedOccupation = 'Other';
        _occupation.text = existing.occupation;
      }
      _phone.text = existing.phone;
      _height.text = existing.heightCm?.toString() ?? '';
      _birthDate = existing.birthDate;
      _gender = existing.gender;
      _interestedIn = existing.interestedIn;
      _interests.addAll(existing.interests);
      _photoUrls.addAll(existing.photoUrls);
      _heightCm = existing.heightCm;
      _religion = existing.religion;
      _education = existing.education;
      _diet = existing.diet;
      _smoking = existing.smoking;
      _maritalStatus = existing.maritalStatus;
      _zodiacSign = existing.zodiacSign;
    }
    _step = _firstIncompleteStep();
    _pageController = PageController(initialPage: _step);
  }

  int _firstIncompleteStep() {
    for (int step = 0; step < _stepCount; step++) {
      if (!_isStepComplete(step)) return step;
    }
    return 0;
  }

  bool _isStepComplete(int step) {
    switch (step) {
      case 0:
        return _name.text.trim().isNotEmpty && _gender != null;
      case 1:
        final DateTime? dob = _birthDate;
        return dob != null && _ageOf(dob) >= kMinAge;
      case 2:
        return _photoUrls.isNotEmpty;
      case 3:
        return _selectedOccupation != null &&
            (_selectedOccupation != 'Other' || _occupation.text.trim().isNotEmpty) &&
            _maritalStatus != null &&
            _zodiacSign != null &&
            _isHeightValid &&
            _height.text.trim().isNotEmpty &&
            _bio.text.trim().isNotEmpty &&
            _permanentAddress.text.trim().isNotEmpty &&
            _currentLocation.text.trim().isNotEmpty &&
            _phone.text.trim().isNotEmpty &&
            _interests.isNotEmpty &&
            _religion != null &&
            _education != null &&
            _diet != null &&
            _smoking != null;
      default:
        return false;
    }
  }

  bool get _isProfileFullyComplete =>
      List<bool>.generate(_stepCount, _isStepComplete).every((bool done) => done);

  @override
  void dispose() {
    _pageController.dispose();
    _name.dispose();
    _height.dispose();
    _bio.dispose();
    _permanentAddress.dispose();
    _currentLocation.dispose();
    _occupation.dispose();
    _phone.dispose();
    super.dispose();
  }

  int _ageOf(DateTime dob) {
    final DateTime now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  bool get _isStepValid {
    switch (_step) {
      case 0:
        return _isStepComplete(0);
      case 1:
        return _isStepComplete(1);
      case 2:
        return _isStepComplete(2);
      case 3:
        return _isStepComplete(3);
      default:
        return true;
    }
  }

  String get _stepError {
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) return 'Please enter your name';
        if (_gender == null) return 'Please select your gender';
        return '';
      case 1:
        if (_birthDate == null) return 'Please pick your date of birth';
        return 'You must be at least $kMinAge years old';
      case 2:
        return 'Please add at least one photo';
      case 3:
        if (_selectedOccupation == null) return 'Please select your profession';
        if (_selectedOccupation == 'Other' && _occupation.text.trim().isEmpty) {
          return 'Please enter your profession';
        }
        if (_maritalStatus == null) return 'Please select your marital status';
        if (_zodiacSign == null) return 'Please select your zodiac sign';
        if (_height.text.trim().isEmpty) return 'Please enter your height';
        if (!_isHeightValid) {
          return 'Enter a height from 122 cm to 213 cm (4′0″–7′0″)';
        }
        if (_selectedOccupation == null) return 'Please select your profession';
        if (_selectedOccupation == 'Other' && _occupation.text.trim().isEmpty) {
          return 'Please enter your profession';
        }
        if (_maritalStatus == null) return 'Please select your marital status';
        if (_zodiacSign == null) return 'Please select your zodiac sign';
        if (_height.text.trim().isEmpty) return 'Please enter your height';
        if (_bio.text.trim().isEmpty) return 'Please add an About me description';
        if (_permanentAddress.text.trim().isEmpty) {
          return 'Please enter your permanent address';
        }
        if (_currentLocation.text.trim().isEmpty) {
          return 'Please enter your current location';
        }
        if (_phone.text.trim().isEmpty) return 'Please enter your phone number';
        if (_interests.isEmpty) return 'Please select at least one interest';
        if (_religion == null) return 'Please select your religion';
        if (_education == null) return 'Please select your education';
        if (_diet == null) return 'Please select your diet';
        if (_smoking == null) return 'Please select your smoking preference';
        return 'Please check your profile details';
      default:
        return '';
    }
  }

  bool get _isHeightValid {
    final String input = _height.text.trim();
    if (input.isEmpty) return true;
    final int? value = int.tryParse(input);
    return value != null && value >= 122 && value <= 213;
  }

  void _next() {
    if (_step == 3 && !(_detailsFormKey.currentState?.validate() ?? false)) {
      setState(() => _error = _stepError);
      return;
    }
    if (!_isStepValid) {
      setState(() => _error = _stepError);
      return;
    }
    setState(() => _error = null);
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickPhoto() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final XFile? file = await ref.read(storageRepositoryProvider).pickImage();
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final String url = await ref
          .read(storageRepositoryProvider)
          .uploadProfilePhoto(
            userId: userId,
            fileName: file.name,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _photoUrls.add(url);
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not upload the photo: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    final String url = _photoUrls[index];
    setState(() => _photoUrls.removeAt(index));
    await ref.read(storageRepositoryProvider).deleteProfilePhoto(url);
  }

  /// Requests foreground location permission and resolves the device position
  /// to a readable locality. No coordinates are stored in the profile.
  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Enable location services and try again.');
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
          'Location permission is disabled. Enable it in your device settings.',
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
        throw StateError(
          'Could not find a readable address for this location.',
        );
      }

      final Placemark place = placemarks.first;
      final List<String> parts = <String>[
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.subAdministrativeArea ?? '').trim().isNotEmpty &&
            place.subAdministrativeArea!.trim() != place.locality?.trim())
          place.subAdministrativeArea!.trim(),
        if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
      ];
      if (parts.isEmpty) {
        throw StateError(
          'Could not find a readable address for this location.',
        );
      }

      if (!mounted) return;
      _currentLocation.text = parts.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch location: $error')),
      );
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _finish() async {
    final String? userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final int? parsedHeight = int.tryParse(_height.text.trim());
    _heightCm = parsedHeight;

    final Profile profile = Profile(
      id: userId,
      fullName: _name.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      interestedIn: _interestedIn,
      bio: _bio.text.trim(),
      permanentAddress: _permanentAddress.text.trim(),
      currentLocation: _currentLocation.text.trim(),
      occupation: _selectedOccupation == 'Other'
          ? _occupation.text.trim()
          : _selectedOccupation ?? '',
      phone: _phone.text.trim(),
      interests: _interests.toList(growable: false),
      photoUrls: List<String>.unmodifiable(_photoUrls),
      heightCm: _heightCm,
      religion: _religion,
      education: _education,
      diet: _diet,
      smoking: _smoking,
      maritalStatus: _maritalStatus,
      zodiacSign: _zodiacSign,
    );

    try {
      if (!_isProfileFullyComplete) {
        setState(() {
          _busy = false;
          _error = _stepError;
        });
        return;
      }
      await ref.read(myProfileControllerProvider.notifier).save(profile);
      if (!mounted) return;
      context.go(widget.isEditing ? AppRoutes.profile : AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save your profile: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isEditing,
        title: Text(
          widget.isEditing
              ? 'Edit profile · Step ${_step + 1} of $_stepCount'
              : 'Step ${_step + 1} of $_stepCount',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: (_step + 1) / _stepCount),
            duration: const Duration(milliseconds: 250),
            builder: (BuildContext context, double value, Widget? child) =>
                LinearProgressIndicator(value: value, minHeight: 4),
          ),
        ),
      ),
      body: GlassBackground(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int index) => setState(() {
                  _step = index;
                  _error = null;
                }),
                children: <Widget>[
                  BasicsStep(
                    nameController: _name,
                    gender: _gender,
                    interestedIn: _interestedIn,
                    onGenderChanged: (String? value) =>
                        setState(() => _gender = value),
                    onInterestedInChanged: (String value) =>
                        setState(() => _interestedIn = value),
                  ),
                  BirthDateStep(
                    birthDate: _birthDate,
                    onChanged: (DateTime? value) =>
                        setState(() => _birthDate = value),
                  ),
                  PhotosStep(
                    photoUrls: _photoUrls,
                    busy: _busy,
                    onAdd: _pickPhoto,
                    onRemove: _removePhoto,
                  ),
                  DetailsStep(
                    formKey: _detailsFormKey,
                    bioController: _bio,
                    permanentAddressController: _permanentAddress,
                    currentLocationController: _currentLocation,
                    fetchingLocation: _fetchingLocation,
                    onFetchLocation: _fetchCurrentLocation,
                    occupationController: _occupation,
                    selectedOccupation: _selectedOccupation,
                    onOccupationChanged: (String? value) => setState(() {
                      _selectedOccupation = value;
                      if (value != 'Other') _occupation.clear();
                    }),
                    phoneController: _phone,
                    heightController: _height,
                    interests: _interests,
                    onToggleInterest: (String interest) => setState(() {
                      if (!_interests.remove(interest)) {
                        _interests.add(interest);
                      }
                    }),
                    religion: _religion,
                    onReligionChanged: (String? v) =>
                        setState(() => _religion = v),
                    education: _education,
                    onEducationChanged: (String? v) =>
                        setState(() => _education = v),
                    diet: _diet,
                    onDietChanged: (String? v) => setState(() => _diet = v),
                    smoking: _smoking,
                    onSmokingChanged: (String? v) =>
                        setState(() => _smoking = v),
                    maritalStatus: _maritalStatus,
                    onMaritalStatusChanged: (String? v) =>
                        setState(() => _maritalStatus = v),
                    zodiacSign: _zodiacSign,
                    onZodiacSignChanged: (String? v) =>
                        setState(() => _zodiacSign = v),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: <Widget>[
                    if (_step > 0) ...<Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _back,
                          child: Text(strings.back),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _next,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _step == _stepCount - 1
                                    ? strings.finish
                                    : strings.next,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
