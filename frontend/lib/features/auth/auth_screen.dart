import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isCheckingEmail = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Introduce un email válido');
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    // Simulamos un poco de feedback visual
    final exists = await ref.read(authProvider.notifier).checkEmail(email);

    if (mounted) {
      if (exists) {
        // El usuario existe, pedimos contraseña (Login)
        setState(() {
          _showPassword = true;
          _isCheckingEmail = false;
        });
      } else {
        // Usuario nuevo, lo llevamos al registro directamente
        setState(() => _isCheckingEmail = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegisterScreen(initialEmail: email),
          ),
        );
      }
    }
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) return;

    await ref.read(authProvider.notifier).login(email, password);
    
    final authState = ref.read(authProvider);
    if (authState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              
              // Header / Identity
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: AppTheme.primaryColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HEFT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lleva tus marcas al siguiente nivel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),

              // Social Section
              ElevatedButton.icon(
                onPressed: authState.isLoading ? null : () => ref.read(authProvider.notifier).loginWithGoogle(),
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google__G__Logo.svg',
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.blue),
                ),
                label: authState.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continuar con Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'o usa tu correo',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                ],
              ),
              
              const SizedBox(height: 24),

              // Manual Section
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_showPassword && !authState.isLoading,
                decoration: InputDecoration(
                  hintText: 'Email',
                  errorText: _emailError,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.hintColor),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              
              if (_showPassword) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.hintColor),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: authState.isLoading || _isCheckingEmail
                    ? null
                    : (_showPassword ? _handleLogin : _handleContinue),
                child: (authState.isLoading || _isCheckingEmail)
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(_showPassword ? 'Iniciar Sesión' : 'Continuar'),
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
