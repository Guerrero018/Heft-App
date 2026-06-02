// dead_code: según placeholder vs firebase_options generado
// ignore_for_file: dead_code

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/home/home_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await dotenv.load(fileName: ".env");
  await _initFirebaseAndNotifications();
  runApp(const ProviderScope(child: HeftApp()));
}

Future<void> _initFirebaseAndNotifications() async {
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
    } else {
      debugPrint(
        'Firebase: coloca android/app/google-services.json y ejecuta '
        'dart run tool/generate_firebase_options.dart',
      );
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      await NotificationService.instance.init().timeout(
        const Duration(seconds: 15),
      );
    }
  } catch (e, st) {
    debugPrint('Firebase/Notifications init failed: $e\n$st');
  }
}

class HeftApp extends ConsumerWidget {
  const HeftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heft',
      theme: AppTheme.darkTheme,
      home: authState.isInitializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isAuthenticated
              ? const HomeScreen()
              : const AuthScreen(),
    );
  }
}
