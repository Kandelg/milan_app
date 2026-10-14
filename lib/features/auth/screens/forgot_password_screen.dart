import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/features/auth/auth_controller.dart';

/// Sends a password-reset email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final String? error = await ref
        .read(authControllerProvider)
        .resetPassword(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = error == null;
    });

    showAppSnack(
      context,
      error ?? 'Reset link sent. Check your inbox.',
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24),
                Icon(
                  Icons.lock_reset,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Reset password', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and we will send you a link to choose a '
                  'new password.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send reset link'),
                ),
                if (_sent) ...<Widget>[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.signIn),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to sign in'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
