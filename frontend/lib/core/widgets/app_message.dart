import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mensajes flotantes con el estilo de recuperación de contraseña.
class AppMessage {
  AppMessage._();

  static const Color errorAccent = Color(0xFFFF7A7A);
  static const Color successAccent = Color(0xFF7EE2A8);

  static SnackBar snackBar(String message, {bool isError = false}) {
    final accentColor = isError ? errorAccent : successAccent;
    final backgroundColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.14),
      AppTheme.cardColor,
    );

    return SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      snackBar(message, isError: isError),
    );
  }

  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  /// Banner fijo en pantalla (mismo estilo que el snackbar de recuperación).
  static Widget banner(String message, {bool isError = false}) {
    final accentColor = isError ? errorAccent : successAccent;
    final backgroundColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.14),
      AppTheme.cardColor,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
