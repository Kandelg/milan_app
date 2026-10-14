import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/profile/profile_controller.dart';

/// Screen shown when a Magic Link is clicked. It listens for auth state
/// changes and navigates the user to the correct destination once the
/// session is established.
class AuthStateScreen extends ConsumerStatefulWidget {
  const AuthStateScreen({super.key});

  @override
  ConsumerState<AuthStateScreen> createState() => _AuthStateScreenState();
}

class _AuthStateScreenState extends ConsumerState<AuthStateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Listen for auth state changes (Magic Link verification)
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Listens to Supabase auth state changes to handle Magic Link verification.
  void _listenToAuthChanges() {
    // Trigger initial check
    _checkAuthState();

    // Listen to auth state stream for changes
    ref.listen(
      authStateProvider,
      (previous, next) {
        _checkAuthState();
      },
    );
  }

  /// Checks the current auth state and navigates if verified.
  void _checkAuthState() {
    final state = ref.read(authStateProvider);
    final session = state.value?.session;
    final user = session?.user;

    if (session != null && user != null) {
      // Verify profile data exists
      Future.microtask(() async {
        if (mounted) {
          await ref.read(myProfileControllerProvider.future);
          final isOnboardingComplete = ref.read(isOnboardingCompleteProvider);
          if (mounted) {
            if (!_verified) {
              _verified = true;
              _controller.forward();
            }
            // Navigate to home if onboarding is complete, otherwise to onboarding
            if (isOnboardingComplete) {
              context.go(AppRoutes.home);
            } else {
              context.go(AppRoutes.onboarding);
            }
          }
        }
      });
    } else if (mounted) {
      // User signed out during this process
      if (!_verified) {
        _verified = false;
        _controller.reverse();
        context.go(AppRoutes.signIn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                strings.verifying,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.pleaseWait,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!_verified)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
