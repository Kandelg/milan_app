import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/auth/screens/auth_state_screen.dart';
import 'package:milan_app/features/auth/screens/sign_in_screen.dart';
import 'package:milan_app/features/auth/screens/sign_up_screen.dart';
import 'package:milan_app/features/auth/screens/forgot_password_screen.dart';
import 'package:milan_app/features/chat/screens/chat_screen.dart';
import 'package:milan_app/features/discover/screens/discover_screen.dart';
import 'package:milan_app/features/home/screens/home_screen.dart';
import 'package:milan_app/features/home/screens/notifications_screen.dart';
import 'package:milan_app/features/matches/screens/matches_screen.dart';
import 'package:milan_app/features/matches/screens/messages_screen.dart';
import 'package:milan_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:milan_app/features/profile/screens/my_profile_screen.dart';
import 'package:milan_app/features/profile/screens/settings_screen.dart';
import 'package:milan_app/features/profile/profile_controller.dart';
import 'package:milan_app/features/shell/screens/home_shell.dart';
import 'package:milan_app/features/splash/screens/splash_screen.dart';

/// Route paths, kept in one place to avoid stringly-typed navigation.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String authVerify = '/auth-verify';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';

  static String chat(String matchId) => '/chat/$matchId';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate `redirect` whenever the auth session or the profile changes.
  // Without this, GoRouter only runs `redirect` on navigation, so a cached
  // signed-out read can bounce a fresh login back to /sign-in in a loop.
  final ValueNotifier<int> refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(() => refreshListenable.dispose());
  void bump() => refreshListenable.value++;
  ref.listen(authStateProvider, (_, _) => bump());
  ref.listen(myProfileControllerProvider, (_, _) => bump());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;

      // Never redirect away from the splash screen; it performs the real
      // navigation once the auth state and profile are known.
      if (location == AppRoutes.splash) return null;

      // Read the auth repository directly (live Supabase state) instead of
      // `currentUserIdProvider`: that provider is cached and only refreshes
      // when the auth stream emits, so right after a sign-in it can still be
      // null and bounce the user back to /sign-in in a loop.
      final bool isSignedIn =
          ref.read(authRepositoryProvider).currentUser != null;
      // Profile reads are asynchronous. Do not treat a still-loading profile
      // as incomplete and send an existing user through onboarding; the splash
      // screen waits for the profile and routes based on its actual contents.
      final profileState = ref.read(myProfileControllerProvider);
      if (profileState.isLoading || profileState.hasError) {
        return AppRoutes.splash;
      }
      final bool isOnboardingComplete = ref.read(isOnboardingCompleteProvider);

      final bool isAuthRoute =
          location == AppRoutes.signIn ||
          location == AppRoutes.signUp ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.authVerify;

      if (!isSignedIn) {
        return isAuthRoute ? null : AppRoutes.signIn;
      }

      if (!isOnboardingComplete) {
        return location == AppRoutes.onboarding ||
                location == AppRoutes.editProfile
            ? null
            : AppRoutes.onboarding;
      }

      if (isAuthRoute || location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.authVerify,
        name: 'authVerify',
        builder: (context, state) => const AuthStateScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            name: 'discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.matches,
            name: 'matches',
            builder: (context, state) => const MatchesScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const MyProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const OnboardingScreen(isEditing: true),
      ),
      GoRoute(
        path: '/chat/:matchId',
        name: 'chat',
        builder: (context, state) =>
            ChatScreen(matchId: state.pathParameters['matchId']!),
      ),
    ],
  );
});
