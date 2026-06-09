import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../live_workout/domain/live_workout_provider.dart';
import '../../../live_workout/presentation/screens/live_workout_screen.dart';
import '../../data/routine_provider.dart';
import '../../domain/routine_model.dart';
import '../create_routine_screen.dart';
import '../routine_detail_screen.dart';

Future<void> showRoutineOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  Routine routine, {
  bool popHostOnDelete = false,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _RoutineOptionsSheet(
      sheetContext: sheetContext,
      hostContext: context,
      routine: routine,
      popHostOnDelete: popHostOnDelete,
    ),
  );
}

class _RoutineOptionsSheet extends ConsumerWidget {
  final BuildContext sheetContext;
  final BuildContext hostContext;
  final Routine routine;
  final bool popHostOnDelete;

  const _RoutineOptionsSheet({
    required this.sheetContext,
    required this.hostContext,
    required this.routine,
    this.popHostOnDelete = false,
  });

  Routine _currentRoutine(WidgetRef ref) {
    return ref.read(routineProvider.notifier).findById(routine.id) ?? routine;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMutating = ref.watch(routineProvider).isMutating;
    final currentRoutine = _currentRoutine(ref);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            currentRoutine.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isMutating) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _OptionItem(
            icon: Icons.visibility_outlined,
            title: 'Ver detalle',
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(hostContext).push(
                MaterialPageRoute(
                  builder: (context) =>
                      RoutineDetailScreen(routine: currentRoutine),
                ),
              );
            },
          ),
          _OptionItem(
            icon: Icons.play_arrow_rounded,
            title: 'Iniciar entrenamiento',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(sheetContext);
              ref.read(liveWorkoutProvider.notifier).startWorkout(currentRoutine);
              Navigator.of(hostContext).push(
                MaterialPageRoute(
                  builder: (context) => const LiveWorkoutScreen(),
                ),
              );
            },
          ),
          _OptionItem(
            icon: Icons.edit_outlined,
            title: 'Editar rutina',
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(hostContext).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CreateRoutineScreen(existingRoutine: currentRoutine),
                ),
              );
            },
          ),
          _OptionItem(
            icon: Icons.copy_outlined,
            title: 'Duplicar rutina',
            enabled: !isMutating,
            onTap: () => _duplicate(hostContext, ref, currentRoutine),
          ),
          _OptionItem(
            icon: currentRoutine.isPublic
                ? Icons.public_off_outlined
                : Icons.public_outlined,
            title: currentRoutine.isPublic
                ? 'Quitar de biblioteca pública'
                : 'Publicar en biblioteca',
            enabled: !isMutating && currentRoutine.exercises.isNotEmpty,
            onTap: () => _togglePublish(hostContext, ref, currentRoutine),
          ),
          _OptionItem(
            icon: Icons.ios_share_outlined,
            title: 'Compartir con código',
            enabled: !isMutating && currentRoutine.exercises.isNotEmpty,
            onTap: () => _shareWithCode(hostContext, ref, currentRoutine),
          ),
          _OptionItem(
            icon: currentRoutine.isActive
                ? Icons.archive_outlined
                : Icons.unarchive_outlined,
            title:
                currentRoutine.isActive ? 'Archivar rutina' : 'Restaurar rutina',
            onTap: () => _setActive(hostContext, ref, currentRoutine),
          ),
          _OptionItem(
            icon: Icons.delete_outline_rounded,
            title: 'Eliminar rutina',
            color: Colors.redAccent,
            onTap: () => _confirmDelete(
              hostContext,
              ref,
              currentRoutine,
              popHostOnDelete: popHostOnDelete,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _togglePublish(
    BuildContext context,
    WidgetRef ref,
    Routine currentRoutine,
  ) async {
    Navigator.pop(sheetContext);
    try {
      final notifier = ref.read(routineProvider.notifier);
      if (currentRoutine.isPublic) {
        await notifier.unpublishRoutine(currentRoutine.id);
        if (context.mounted) {
          AppMessage.showSuccess(context, 'Rutina retirada de la biblioteca');
        }
      } else {
        await notifier.publishRoutine(currentRoutine.id);
        if (context.mounted) {
          AppMessage.showSuccess(context, 'Rutina publicada en la biblioteca');
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.showError(
          context,
          'No se pudo actualizar la visibilidad de la rutina',
        );
      }
    }
  }

  Future<void> _shareWithCode(
    BuildContext context,
    WidgetRef ref,
    Routine currentRoutine,
  ) async {
    Navigator.pop(sheetContext);
    try {
      final code =
          await ref.read(routineProvider.notifier).shareRoutine(currentRoutine.id);
      if (!context.mounted || code.isEmpty) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Código de compartir',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comparte este código con otro usuario de Heft para que importe tu rutina:',
                style: TextStyle(color: AppTheme.hintColor),
              ),
              const SizedBox(height: 16),
              SelectableText(
                code,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
                AppMessage.showSuccess(context, 'Código copiado');
              },
              child: const Text(
                'Copiar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppMessage.showError(context, 'No se pudo generar el código');
      }
    }
  }

  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    Routine currentRoutine,
  ) async {
    Navigator.pop(sheetContext);
    try {
      await ref.read(routineProvider.notifier).duplicateRoutine(currentRoutine);
      if (context.mounted) {
        AppMessage.showSuccess(context, 'Rutina duplicada');
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.showError(context, 'No se pudo duplicar la rutina');
      }
    }
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    Routine currentRoutine,
  ) async {
    Navigator.pop(sheetContext);
    final nextActive = !currentRoutine.isActive;
    try {
      await ref
          .read(routineProvider.notifier)
          .setRoutineActive(currentRoutine.id, nextActive);
      if (context.mounted) {
        AppMessage.showSuccess(
          context,
          nextActive ? 'Rutina restaurada' : 'Rutina archivada',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.showError(
          context,
          nextActive
              ? 'No se pudo restaurar la rutina'
              : 'No se pudo archivar la rutina',
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Routine currentRoutine, {
    required bool popHostOnDelete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Eliminar Rutina',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la rutina "${currentRoutine.name}"?',
          style: const TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.hintColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    try {
      await ref
          .read(routineProvider.notifier)
          .deleteRoutine(currentRoutine.id);
      if (context.mounted) {
        AppMessage.showSuccess(context, 'Rutina eliminada');
        if (popHostOnDelete && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.showError(context, 'Error al eliminar la rutina');
      }
    }
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  const _OptionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.white,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: enabled ? color : Colors.white38, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? color : Colors.white38,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
