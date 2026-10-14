import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/providers.dart';

/// Thrown by [AuthController] when the backend rejects the request.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sign-in / sign-up / sign-out actions.
class AuthController {
  const AuthController(this._ref);

  final Ref _ref;

  /// Signs in and returns `null` on success, or an error message.
  Future<String?> signIn({required String email, required String password}) async {
    try {
      final response = await _ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email.trim(), password: password);
      // gotrue can complete without throwing yet still return no session
      // (e.g. the email is unconfirmed). Treating that as success would send
      // the user into an onboarding/discover redirect loop, because the
      // router would still see them as signed out.
      if (response.session == null) {
        return 'Sign-in did not return a session. If your email is '
            'unconfirmed, confirm it first (check your inbox), then try again.';
      }
      return null;
    } catch (error) {
      return _message(error, 'Could not sign in. Please try again.');
    }
  }

  /// Creates the account. Returns `null` on success.
  ///
  /// When the project has "Confirm email" enabled Supabase returns a user
  /// without a session; that case is surfaced so the UI can ask the user to
  /// check their inbox.
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _ref.read(authRepositoryProvider).signUp(
        email: email.trim(),
        password: password,
        fullName: fullName,
      );
      if (response.session == null) {
        return 'Account created. Please check your email to confirm, then sign in.';
      }
      return null;
    } catch (error) {
      return _message(error, 'Could not create the account. Please try again.');
    }
  }

  /// Sends a password-reset email. Returns `null` on success.
  Future<String?> resetPassword(String email) async {
    try {
      await _ref.read(authRepositoryProvider).sendPasswordReset(email);
      return null;
    } catch (error) {
      return _message(error, 'Could not send the reset email.');
    }
  }

  /// Sends a Magic Link login email. Returns `null` on success.
  Future<String?> sendMagicLink({
    required String email,
    String? emailRedirectTo,
  }) async {
    try {
      await _ref.read(authRepositoryProvider).signInWithMagicLink(
        email: email,
        emailRedirectTo: emailRedirectTo,
      );
      return null;
    } catch (error) {
      return _message(error, 'Could not send the login link. Please try again.');
    }
  }

  Future<void> signOut() => _ref.read(authRepositoryProvider).signOut();

  /// Turns Supabase/network exceptions into short, readable text.
  String _message(Object error, String fallback) {
    String text = error.toString();
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length);
    }
    if (text.startsWith('AuthException')) {
      final int colon = text.indexOf(':');
      if (colon >= 0) text = text.substring(colon + 1).trim();
    }
    if (text.isEmpty) text = fallback;
    return text;
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);
