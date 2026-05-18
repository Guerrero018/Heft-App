import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_message.dart';
import 'auth_provider.dart';
import 'forgot_password_screen.dart';
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
  String? _loginError;
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

    final exists = await ref.read(authProvider.notifier).checkEmail(email);

    if (mounted) {
      setState(() => _isCheckingEmail = false);
      
      if (exists == null) {
        // Hubo un error de conexión (el error ya se guardó en el provider)
        final error = ref.read(authProvider).error;
        AppMessage.showError(context, error ?? 'Error de conexión');
        return;
      }

      if (exists) {
        // El usuario existe, pedimos contraseña (Login)
        setState(() {
          _showPassword = true;
          _loginError = null;
        });
      } else {
        // Usuario nuevo, lo llevamos al registro directamente
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

    setState(() => _loginError = null);
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      setState(() {
        _showPassword = true;
        _loginError = authState.error;
      });
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
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/HeftLogo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tus metas te esperan.\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Empieza ahora.',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),

              // Social Section
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(authProvider.notifier)
                              .loginWithGoogle();
                          if (!mounted) return;
                          final state = ref.read(authProvider);
                          if (state.error != null) {
                            AppMessage.showError(context, state.error!);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: authState.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continuar con Google',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
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
                  onChanged: (_) {
                    if (_loginError != null) {
                      setState(() => _loginError = null);
                      ref.read(authProvider.notifier).clearError();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.hintColor),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  AppMessage.banner(_loginError!, isError: true),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(
                                  initialEmail: _emailController.text.trim(),
                                ),
                              ),
                            );
                          },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
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
