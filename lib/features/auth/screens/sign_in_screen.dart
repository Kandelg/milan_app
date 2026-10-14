import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/features/auth/auth_controller.dart';
import 'package:milan_app/features/profile/profile_controller.dart';

/// Email + password sign in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _linkSent = false;

  bool get _ne => ref.read(localeControllerProvider) == AppLanguage.nepali;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final String? error = await ref
        .read(authControllerProvider)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showAppSnack(context, error, error: true);
      return;
    }
    // Load the profile first so we know whether onboarding is needed;
    // otherwise the router's redirect sees "incomplete" while the
    // profile is still loading and sends the user to /onboarding.
    // A failure here must not trap the user on a spinning button: let
    // the router/splash decide once navigation happens.
    try {
      await ref.read(myProfileControllerProvider.future);
    } catch (_) {
      // Ignore and continue to navigation below.
    }
    if (!mounted) return;
    final bool complete = ref.read(isOnboardingCompleteProvider);
    context.go(complete ? AppRoutes.home : AppRoutes.onboarding);
  }

  /// Sends a Magic Link login email and shows a success message.
  Future<void> _sendMagicLink() async {
    final String emailText = _email.text.trim();
    if (emailText.isEmpty) {
      showAppSnack(context, 'Please enter your email first', error: true);
      return;
    }
    final RegExp emailRegex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(emailText)) {
      showAppSnack(context, 'Enter a valid email', error: true);
      return;
    }

    setState(() => _busy = true);
    final String? error = await ref
        .read(authControllerProvider)
        .sendMagicLink(
          email: emailText,
          emailRedirectTo: 'io.supabase.milanapp://login-callback/',
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _linkSent = error == null;
    });

    final AppStrings strings = AppStrings.of(context);
    if (error != null) {
      showAppSnack(context, error, error: true);
    } else {
      showAppSnack(context, strings.checkYourInbox);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFFFF9A62),
                              Color(0xFFFF4D69),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.72),
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFFE94B55)
                                  .withValues(alpha: 0.25),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Transform.translate(
                              offset: const Offset(-10, -5),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(11, 7),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 29,
                                color: const Color(0xFFFFD6C7)
                                    .withValues(alpha: 0.96),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      strings.welcomeBack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_linkSent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strings.checkYourInbox,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.email,
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const <String>[AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: strings.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: Text(strings.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassButton(
                      onPressed: _busy ? null : _submit,
                      loading: _busy,
                      label: strings.signIn,
                    ),
                    const SizedBox(height: 16),
                    // Divider with "or"
                    Row(
                      children: <Widget>[
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _ne ? 'वा' : 'or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Magic Link sign in
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _sendMagicLink,
                      icon: const Icon(Icons.link_outlined),
                      label: Text(strings.signInWithMagicLink),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(strings.noAccount),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.pushReplacement(AppRoutes.signUp),
                          child: Text(strings.signUp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    final RegExp emailRegex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    if ((value ?? '').length < 6) return 'At least 6 characters';
    return null;
  }
}
