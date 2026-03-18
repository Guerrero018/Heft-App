import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    await ref.read(authProvider.notifier).register(username, email, password);

    // If registration is successful and the widget is still mounted, pop the screen
    if (mounted && ref.read(authProvider).isAuthenticated) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the Heft community today',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.hintColor, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Username Input
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: const InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.hintColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Input
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.lock_clock_outlined,
                    color: AppTheme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Show error message if any
              if (ref.watch(authProvider).error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    ref.watch(authProvider).error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Register Button
              ElevatedButton(
                onPressed: ref.watch(authProvider).isLoading
                    ? null
                    : _handleRegister,
                child: ref.watch(authProvider).isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('CREATE ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
