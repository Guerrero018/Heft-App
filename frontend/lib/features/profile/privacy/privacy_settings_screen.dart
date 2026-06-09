import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_provider.dart';
import '../../auth/forgot_password_screen.dart';
import '../../export/presentation/export_data_screen.dart';
import '../data/privacy_preferences_provider.dart';
import '../widgets/settings_ui.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(privacyPreferencesProvider);
    final prefs = prefsState.prefs;
    final userEmail = ref.watch(authProvider).user?['email']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacidad y seguridad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsInfoBanner(
            icon: Icons.shield_outlined,
            message:
                'Controla qué información se muestra en tu perfil y gestiona la seguridad de tu cuenta.',
          ),

          const SettingsSectionTitle(icon: Icons.lock_outline, title: 'Seguridad'),
          SettingsSectionCard(
            children: [
              SettingsNavRow(
                icon: Icons.password,
                label: 'Cambiar contraseña',
                subtitle: userEmail ?? 'Recibirás un código por email',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordScreen(initialEmail: userEmail),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SettingsSectionTitle(
            icon: Icons.visibility_outlined,
            title: 'Visibilidad del perfil',
          ),
          SettingsSectionCard(
            children: [
              SettingsToggleRow(
                icon: Icons.alternate_email,
                label: 'Mostrar email en el perfil',
                subtitle: 'Visible solo para ti en la pantalla de perfil',
                value: prefs.showEmailOnProfile,
                onChanged: (v) => ref
                    .read(privacyPreferencesProvider.notifier)
                    .update(prefs.copyWith(showEmailOnProfile: v)),
              ),
              const Divider(color: Colors.white10),
              SettingsToggleRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Mostrar peso y altura',
                subtitle: 'Oculta tus medidas en la vista de perfil',
                value: prefs.showStatsOnProfile,
                onChanged: (v) => ref
                    .read(privacyPreferencesProvider.notifier)
                    .update(prefs.copyWith(showStatsOnProfile: v)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SettingsSectionTitle(icon: Icons.storage_outlined, title: 'Tus datos'),
          SettingsSectionCard(
            children: [
              SettingsNavRow(
                icon: Icons.download_outlined,
                label: 'Exportar mis datos',
                subtitle: 'CSV o PDF con filtros personalizados',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExportDataScreen()),
                  );
                },
              ),
              const Divider(color: Colors.white10),
              SettingsNavRow(
                icon: Icons.info_outline,
                label: 'Qué datos guardamos',
                onTap: () => _showDataInfoDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDataInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Datos almacenados',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Heft guarda tu perfil, rutinas, historial de entrenamientos, '
          'medidas corporales y preferencias de notificación asociadas a tu cuenta. '
          'Las fotos de progreso se almacenan de forma segura en la nube.\n\n'
          'Puedes solicitar la eliminación de tu cuenta escribiendo a soporte desde '
          'la sección de Ayuda.',
          style: TextStyle(color: AppTheme.hintColor, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
