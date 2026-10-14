import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';

/// Loads and edits the signed-in user's profile.
///
/// The controller is an [AsyncNotifier] so the UI can render loading/error
/// states without extra plumbing.
class MyProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final String? userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(profileRepositoryProvider).fetchProfile(userId);
  }

  /// Re-reads the profile from the database.
  Future<void> refresh() async {
    state = const AsyncLoading<Profile?>();
    state = await AsyncValue.guard(() => build());
  }

  /// Persists changes and updates local state.
  ///
  /// On failure the error is stored in [state] **and rethrown** so callers
  /// (e.g. the onboarding Finish button) can stop their spinner and show the
  /// real error. Swallowing it here previously left the button spinning
  /// forever because the write had actually failed.
  Future<void> save(Profile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    state = const AsyncLoading<Profile?>();
    try {
      await repository.saveProfile(profile);
      state = AsyncData<Profile?>(profile);
    } catch (error, stackTrace) {
      state = AsyncError<Profile?>(error, stackTrace);
      rethrow;
    }
  }
}

final myProfileControllerProvider =
    AsyncNotifierProvider<MyProfileController, Profile?>(
      MyProfileController.new,
    );

/// Convenience selector: is onboarding finished?
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final AsyncValue<Profile?> value = ref.watch(myProfileControllerProvider);
  return value.value?.isComplete ?? false;
});
