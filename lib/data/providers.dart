import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/data/auth_repository.dart';
import 'package:milan_app/data/discover_repository.dart';
import 'package:milan_app/data/feedback_repository.dart';
import 'package:milan_app/data/match_repository.dart';
import 'package:milan_app/data/profile_repository.dart';
import 'package:milan_app/data/safety_repository.dart';
import 'package:milan_app/data/social_repository.dart';
import 'package:milan_app/data/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single [SupabaseClient] for the app (throws a clear message when the
/// app was started without `--dart-define` credentials).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.isBackendConfigured) {
    throw StateError(
      'Supabase is not configured. Run the app with:\n'
      'flutter run --dart-define-from-file=env.json',
    );
  }
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref.watch(supabaseClientProvider)),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(supabaseClientProvider)),
);

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(ref.watch(supabaseClientProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(ref.watch(supabaseClientProvider)),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(supabaseClientProvider)),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(ref.watch(supabaseClientProvider)),
);

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(ref.watch(supabaseClientProvider), ImagePicker()),
);

/// Current auth session; `null` when signed out.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Convenience accessor for the signed-in user id.
///
/// Watches [authStateProvider] so the value is recomputed on every
/// sign-in / sign-out / token refresh instead of returning the value
/// cached from app startup (which caused a redirect loop back to
/// /sign-in after a successful login).
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser?.id;
});
