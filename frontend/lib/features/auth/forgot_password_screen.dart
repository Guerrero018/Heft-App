import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _debugCode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Introduce un email valido', isError: true);
      return;
    }

    final response = await ref.read(authProvider.notifier).requestPasswordReset(
          email,
        );
    if (!mounted) return;

    if (response == null) {
      _showSnackBar(
        ref.read(authProvider).error ?? 'No se pudo enviar el codigo',
        isError: true,
      );
      return;
    }

    setState(() {
      _codeSent = true;
      _debugCode = response['debug_code']?.toString();
    });

    _showSnackBar(
      response['detail']?.toString() ?? 'Codigo enviado correctamente',
    );
  }

  Future<void> _confirmReset() async {
    if (_codeController.text.trim().length != 6) {
      _showSnackBar('Introduce el codigo de 6 digitos', isError: true);
      return;
    }

    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Completa la nueva contrasena dos veces', isError: true);
      return;
    }

    final success = await ref.read(authProvider.notifier).confirmPasswordReset(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (!mounted) return;

    if (!success) {
      _showSnackBar(
        ref.read(authProvider).error ?? 'No se pudo actualizar la contrasena',
        isError: true,
      );
      return;
    }

    _showSnackBar('Contrasena actualizada. Ya puedes iniciar sesion.');
    Navigator.of(context).pop(_emailController.text.trim());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recuperar contrasena'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                _codeSent
                    ? 'Introduce el codigo que te hemos enviado y elige una nueva contrasena.'
                    : 'Te enviaremos un codigo de 6 digitos a tu email para restablecer la contrasena.',
                style: const TextStyle(
                  color: AppTheme.hintColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent && !authState.isLoading,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_codeSent) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    hintText: 'Codigo de 6 digitos',
                    prefixIcon: Icon(
                      Icons.mark_email_read_outlined,
                      color: AppTheme.hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Nueva contrasena',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.hintColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppTheme.hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Repite la nueva contrasena',
                    prefixIcon: const Icon(
                      Icons.lock_reset_outlined,
                      color: AppTheme.hintColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppTheme.hintColor,
                      ),
                    ),
                  ),
                ),
                if (_debugCode != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'Codigo de desarrollo: $_debugCode',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading ? null : _requestCode,
                    child: const Text('Reenviar codigo'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : (_codeSent ? _confirmReset : _requestCode),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(_codeSent ? 'Actualizar contrasena' : 'Enviar codigo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
