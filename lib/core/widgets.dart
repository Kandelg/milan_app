import 'package:flutter/material.dart';

/// Small, reusable building blocks shared across screens.

/// Full-bleed circular progress indicator, used for first-load states.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Empty-state placeholder with an icon, title and optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    this.iconWidget,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ??
                Icon(icon, size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Error placeholder with a retry button.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  final Object error;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title,
      message: _friendlyMessage(error),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
    );
  }

  /// Strips noisy prefixes so the user sees a readable sentence.
  String _friendlyMessage(Object error) {
    String text = error.toString();
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length);
    }
    if (text.length > 200) text = '${text.substring(0, 200)}…';
    return text;
  }
}

/// Rounded avatar with graceful fallback when the photo is missing.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.photoUrl,
    this.radius = 28,
    this.iconSize,
    this.placeholderIcon = Icons.person,
  });

  final String? photoUrl;
  final double radius;
  final double? iconSize;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? url = photoUrl;

    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(
          placeholderIcon,
          size: iconSize ?? radius,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage: NetworkImage(url),
      child: Icon(
        placeholderIcon,
        size: iconSize ?? radius,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Section label used above form groups.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Convenience helper for showing a snackbar from anywhere with a context.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
