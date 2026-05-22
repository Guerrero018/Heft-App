import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BodyProgressEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const BodyProgressEmpty({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.hintColor.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.hintColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
