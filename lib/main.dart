import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/app/app.dart';
import 'package:milan_app/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
      return true;
    };

    if (AppConfig.isBackendConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseAnonKey,
        );
      } catch (error, stack) {
        debugPrint('Warning: Supabase initialization failed: $error\n$stack');
      }
    } else {
      debugPrint(
        'Supabase credentials are missing. Configure SUPABASE_URL and '
        'SUPABASE_ANON_KEY in env.json and launch with '
        '--dart-define-from-file=env.json.',
      );
    }

    runApp(const ProviderScope(child: MilanApp()));
  }, (Object error, StackTrace stack) {
    if (kDebugMode) debugPrint('Zone error: $error\n$stack');
  });
}