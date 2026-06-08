import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_provider.dart';
import '../edit_profile_screen.dart';
import '../help/help_support_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../privacy/privacy_settings_screen.dart';

class ProfileSettingsMenu extends ConsumerWidget {
  const ProfileSettingsMenu({super.key});

  void _openSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ProfileSettingsSheet(
        username: user?['username']?.toString() ?? 'Usuario',
        email: user?['email']?.toString() ?? '',
        picture: user?['profile_picture']?.toString(),
        onAction: (action) {
          Navigator.pop(sheetContext);
          _handleAction(context, ref, action);
        },
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, _ProfileSheetAction action) {
    switch (action) {
      case _ProfileSheetAction.personalInfo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
      case _ProfileSheetAction.notifications:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
        );
      case _ProfileSheetAction.privacy:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
        );
      case _ProfileSheetAction.help:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
        );
      case _ProfileSheetAction.logout:
        _confirmLogout(context, ref);
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro que quieres salir de tu cuenta?',
          style: TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _openSheet(context, ref),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

enum _ProfileSheetAction {
  personalInfo,
  notifications,
  privacy,
  help,
  logout,
}

class _ProfileSettingsSheet extends StatelessWidget {
  final String username;
  final String email;
  final String? picture;
  final ValueChanged<_ProfileSheetAction> onAction;

  const _ProfileSettingsSheet({
    required this.username,
    required this.email,
    required this.picture,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.surfaceColor,
                    backgroundImage: (picture != null && picture!.isNotEmpty)
                        ? CachedNetworkImageProvider(picture!)
                        : const CachedNetworkImageProvider(
                            'https://res.cloudinary.com/dcmhsvy2l/image/upload/v1776343470/DefaultProfile.png',
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppTheme.hintColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10, height: 1),
            _SheetTile(
              icon: Icons.person_outline_rounded,
              label: 'Información personal',
              subtitle: 'Nombre, foto y objetivos',
              onTap: () => onAction(_ProfileSheetAction.personalInfo),
            ),
            _SheetTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notificaciones',
              subtitle: 'Recordatorios y resúmenes',
              onTap: () => onAction(_ProfileSheetAction.notifications),
            ),
            _SheetTile(
              icon: Icons.shield_outlined,
              label: 'Privacidad y seguridad',
              subtitle: 'Contraseña y visibilidad',
              onTap: () => onAction(_ProfileSheetAction.privacy),
            ),
            _SheetTile(
              icon: Icons.help_outline_rounded,
              label: 'Ayuda y soporte',
              subtitle: 'FAQ y contacto',
              onTap: () => onAction(_ProfileSheetAction.help),
            ),
            const Divider(color: Colors.white10, height: 1),
            _SheetTile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              iconColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              showChevron: false,
              onTap: () => onAction(_ProfileSheetAction.logout),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showChevron;

  const _SheetTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: labelColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppTheme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
