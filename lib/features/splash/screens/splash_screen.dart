import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/profile/profile_controller.dart';

/// Decides where the user lands after the app opens:
///
/// 1. no backend credentials → setup instructions
/// 2. not signed in          → sign in
/// 3. profile incomplete     → onboarding
/// 4. otherwise              → discovery
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Non-null when [_resolve] failed (network/profile error).
  Object? _error;

  /// True when compile-time Supabase credentials are missing; navigation is
  /// impossible in that case, so the spinner must not run forever.
  bool _backendMissing = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame so navigation does not happen during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (!mounted) return;

    if (!AppConfig.isBackendConfigured) {
      // No credentials → the app can never reach a real screen. Show a
      // static hint (plus the setup dialog) instead of spinning forever.
      setState(() => _backendMissing = true);
      _showSetupHelp();
      return;
    }

    try {
      // Give the restored session a chance to arrive.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Read the live Supabase auth state (same as the router redirect);
      // `currentUserIdProvider` is stream-cached and can lag right after
      // session restore.
      final bool isSignedIn =
          ref.read(authRepositoryProvider).currentUser != null;
      if (!isSignedIn) {
        context.go(AppRoutes.signIn);
        return;
      }

      // Ensure the profile has been loaded before deciding on onboarding.
      // A timeout guards against a hung request leaving splash spinning.
      await ref
          .read(myProfileControllerProvider.future)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      final bool complete = ref.read(isOnboardingCompleteProvider);
      context.go(complete ? AppRoutes.home : AppRoutes.onboarding);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _showSetupHelp() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Connect Supabase'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('This build has no backend credentials.'),
            SizedBox(height: 12),
            Text('1. Create a project at supabase.com'),
            Text('2. Copy env.example.json to env.json'),
            Text('3. Fill in the URL and anon key'),
            SizedBox(height: 8),
            Text('Then run:'),
            SizedBox(height: 6),
            SelectableText(
              'flutter run --dart-define-from-file=env.json',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFF9F43), Color(0xFFEE2E31)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                      blurRadius: 30,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bihe & Date',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Find your person'),
              const SizedBox(height: 32),
              if (_error != null)
                _SetupStatus(
                  icon: Icons.error_outline,
                  message:
                      'Could not reach the server.\nCheck your connection and try again.',
                  action: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _error = null);
                      _resolve();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                )
              else if (_backendMissing)
                _SetupStatus(
                  icon: Icons.cloud_off,
                  message:
                      'Supabase credentials are missing.\n'
                      'Run with: flutter run --dart-define-from-file=env.json',
                )
              else
                const AppLoader(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status block used on the splash screen for error / setup messages.
class _SetupStatus extends StatelessWidget {
  const _SetupStatus({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Icon(icon, size: 32, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
      ],
    );
  }
}
