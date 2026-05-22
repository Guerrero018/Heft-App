import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../auth/auth_provider.dart';
import '../data/body_progress_provider.dart';
import '../domain/body_measure_model.dart';

Future<void> confirmDeleteBodyEntry(
  BuildContext context,
  WidgetRef ref,
  BodyMeasureEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: const Text('Eliminar registro', style: TextStyle(color: Colors.white)),
      content: const Text(
        '¿Eliminar este registro de progreso?',
        style: TextStyle(color: AppTheme.hintColor),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final ok = await ref.read(bodyProgressProvider.notifier).deleteEntry(entry.id);
  if (!context.mounted) return;

  if (ok) {
    await ref.read(authProvider.notifier).syncProfile();
    AppMessage.showSuccess(context, 'Registro eliminado');
  } else {
    AppMessage.showError(context, ref.read(bodyProgressProvider).error ?? 'Error');
  }
}
