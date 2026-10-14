import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/features/auth/auth_controller.dart';

/// Email + password registration. The full profile is collected in the
/// onboarding wizard that follows a successful sign-up.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      showAppSnack(context, 'Please accept the terms to continue', error: true);
      return;
    }

    setState(() => _busy = true);
    final String? error = await ref.read(authControllerProvider).signUp(
      email: _email.text,
      password: _password.text,
      fullName: _name.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showAppSnack(context, error, error: true);
      return;
    }

    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.createAccount,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It only takes a minute',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const <String>[AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (String? value) =>
                      (value ?? '').trim().length < 2 ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.email,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                  validator: (String? value) {
                    final String text = (value ?? '').trim();
                    if (text.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$').hasMatch(text)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
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
                  validator: (String? value) =>
                      (value ?? '').length < 6 ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: strings.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (String? value) =>
                      value != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (bool? value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I am at least 18 years old and accept the terms of use',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  onPressed: _busy ? null : _submit,
                  loading: _busy,
                  label: strings.createAccount,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(strings.haveAccount),
                    TextButton(
                      onPressed: _busy ? null : () => context.pop(),
                      child: Text(strings.signIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
