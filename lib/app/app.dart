import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/theme.dart';

/// Root widget: hosts the [GoRouter] and the app theme.
///
/// It also watches [localeControllerProvider] so the whole UI rebuilds when the
/// user switches between English and Nepali.
class MilanApp extends ConsumerWidget {
  const MilanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    final AppLanguage language = ref.watch(localeControllerProvider);
    final AppStrings strings = AppStrings(language);

    return MaterialApp.router(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

