import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: authState.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
