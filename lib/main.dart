import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/app/app.dart';
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

    try {
      final envString = await rootBundle.loadString('env.json');
      final decoded = jsonDecode(envString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object in env.json.');
      }

      final url = decoded['SUPABASE_URL'];
      final anonKey = decoded['SUPABASE_ANON_KEY'];
      if (url is! String || url.trim().isEmpty ||
          anonKey is! String || anonKey.trim().isEmpty) {
        throw const FormatException(
          'env.json must contain non-empty SUPABASE_URL and SUPABASE_ANON_KEY strings.',
        );
      }

      await Supabase.initialize(url: url, publishableKey: anonKey);
    } on FlutterError catch (error) {
      debugPrint('Warning: Could not load env.json asset: $error');
    } on FormatException catch (error) {
      debugPrint('Warning: env.json is not configured correctly: $error');
    } catch (error, stack) {
      debugPrint('Warning: Supabase initialization failed: $error\n$stack');
    }

    runApp(const ProviderScope(child: MilanApp()));
  }, (Object error, StackTrace stack) {
    if (kDebugMode) debugPrint('Zone error: $error\n$stack');
  });
}