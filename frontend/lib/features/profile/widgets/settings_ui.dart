import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SettingsSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingsSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryColor,
      secondary: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withValues(alpha: 0.35),
        size: 22,
      ),
      onTap: onTap,
    );
  }
}

class SettingsInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const SettingsInfoBanner({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
