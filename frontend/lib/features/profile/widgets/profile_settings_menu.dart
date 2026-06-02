import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_provider.dart';
import '../edit_profile_screen.dart';
import '../notifications/notification_settings_screen.dart';

enum ProfileMenuAction {
  personalInfo,
  notifications,
  privacy,
  help,
  logout,
}

class ProfileSettingsMenu extends ConsumerWidget {
  const ProfileSettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ProfileMenuAction>(
      icon: const Icon(Icons.menu, color: Colors.white, size: 28),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 48),
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (context) => [
        _item(ProfileMenuAction.personalInfo, Icons.person_outline, 'Información personal'),
        _item(ProfileMenuAction.notifications, Icons.notifications_none, 'Notificaciones'),
        _item(ProfileMenuAction.privacy, Icons.security, 'Privacidad y seguridad'),
        _item(ProfileMenuAction.help, Icons.help_outline, 'Ayuda y soporte'),
        const PopupMenuDivider(),
        _item(ProfileMenuAction.logout, Icons.logout, 'Cerrar sesión', isDestructive: true),
      ],
    );
  }

  PopupMenuItem<ProfileMenuAction> _item(
    ProfileMenuAction value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.redAccent : AppTheme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, ProfileMenuAction action) {
    switch (action) {
      case ProfileMenuAction.personalInfo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
      case ProfileMenuAction.notifications:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
        );
      case ProfileMenuAction.privacy:
        _showPlaceholder(context, 'Privacidad', 'Próximamente.');
      case ProfileMenuAction.help:
        _showPlaceholder(context, 'Ayuda', 'Próximamente.');
      case ProfileMenuAction.logout:
        ref.read(authProvider.notifier).logout();
    }
  }

  void _showPlaceholder(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: AppTheme.hintColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
