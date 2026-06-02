import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    await NotificationService.instance.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase/Notifications init skipped: $e');
  }
  runApp(const ProviderScope(child: HeftApp()));
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
