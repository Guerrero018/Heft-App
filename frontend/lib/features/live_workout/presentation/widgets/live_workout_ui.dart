import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/label_translations.dart';

/// Paleta auxiliar solo para la pantalla de entreno en vivo.
abstract final class LiveWorkoutUi {
  static const Color shell = Color(0xFF0A0A0B);
  static const Color panel = Color(0xFF161618);
  static const Color panelRaised = Color(0xFF1F1F23);
  static const Color inset = Color(0xFF0E0E10);
  static const Color border = Color(0xFF2A2A30);

  static BoxDecoration headerGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A1A14), shell],
    ),
  );

  static BoxDecoration cardDecoration({bool accent = false}) => BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );
}

/// Misma etiqueta que en las tarjetas de rutina del inicio.
class MuscleGroupTag extends StatelessWidget {
  final String muscleGroup;

  const MuscleGroupTag({super.key, required this.muscleGroup});

  @override
  Widget build(BuildContext context) {
    final label = translateMuscleGroup(muscleGroup);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
