/// App-wide compile-time configuration.
///
/// Values are supplied at build/run time so that no secret is committed:
///
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// where `env.json` looks like:
/// ```json
/// {
///   "SUPABASE_URL": "https://xxxx.supabase.co",
///   "SUPABASE_ANON_KEY": "eyJhbGciOi..."
/// }
/// ```
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// `true` when the Supabase credentials were provided at build time.
  static bool get isBackendConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Interest tags offered while building a profile.
const List<String> kInterests = <String>[
  'Travel',
  'Music',
  'Movies',
  'Trekking',
  'Cricket',
  'Cooking',
  'Books',
  'Gaming',
  'Yoga',
  'Photography',
  'Dance',
  'Coffee',
  'Pets',
  'Cycling',
  'Art',
  'Football',
];

/// Genders used for both "my gender" and "who I want to see".
const List<String> kGenders = <String>['male', 'female', 'other'];

const String kGenderEveryone = 'everyone';

/// Religions offered in onboarding / edit profile.
const List<String> kReligions = <String>[
  'hindu',
  'buddhist',
  'muslim',
  'christian',
  'other',
];

/// Education levels offered in onboarding / edit profile.
const List<String> kEducations = <String>[
  'high_school',
  'bachelor',
  'master',
  'phd',
  'other',
];

/// Diet choices: vegetarian or non-vegetarian.
const List<String> kDiets = <String>['veg', 'non_veg'];

/// Smoking choices.
const List<String> kSmokings = <String>['smoker', 'non_smoker'];

/// Minimum age allowed by the app (and by the database constraint).
const int kMinAge = 18;

const int kMaxAge = 100;

/// Age bounds exposed by the discovery filter.
const int kFilterMinAge = 18;

const int kFilterMaxAge = 60;

/// How many candidate profiles to fetch per page in discovery.
const int kDiscoveryPageSize = 20;

/// Public storage bucket used for profile photos.
const String kPhotoBucket = 'profile-photos';

/// Public storage bucket used for story photos.
const String kStoryBucket = 'story-media';

/// How long a story stays visible after posting.
const Duration kStoryLifetime = Duration(hours: 24);

/// How long each story page shows in the viewer before auto-advancing.
const Duration kStoryPageDuration = Duration(seconds: 5);
