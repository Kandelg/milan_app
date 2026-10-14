import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth and keeps `profiles` in sync on sign-up.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Currently signed-in user, or `null`.
  User? get currentUser => _client.auth.currentUser;

  /// Emits on login, logout, token refresh and initial restore.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a Magic Link (email OTP) to the given email address.
  ///
  /// When the user clicks the link in their inbox, Supabase redirects back
  /// to the app via the deep link and the session is established
  /// automatically — no password needed.
  Future<void> signInWithMagicLink({
    required String email,
    String? emailRedirectTo,
  }) {
    return _client.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: emailRedirectTo,
    );
  }

  /// Creates the auth user plus an initial (empty) profile row.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final AuthResponse response = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': fullName.trim()},
    );

    final User? user = response.user;
    if (user != null && response.session != null) {
      await _client.from('profiles').upsert(<String, dynamic>{
        'id': user.id,
        'full_name': fullName.trim(),
      });
    }

    return response;
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Deletes the account; requires the `delete-account` edge function
  /// (see supabase/functions/delete-account) or manual dashboard removal.
  Future<void> deleteAccount() async {
    final User? user = currentUser;
    if (user == null) return;
    await _client.functions.invoke('delete-account');
  }
}
