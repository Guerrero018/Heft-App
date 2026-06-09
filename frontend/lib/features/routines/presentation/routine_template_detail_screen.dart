import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/label_translations.dart';
import '../../../core/widgets/app_message.dart';
import '../data/routine_template_provider.dart';
import '../domain/routine_model.dart';

class RoutineTemplateDetailScreen extends ConsumerStatefulWidget {
  final int templateId;

  const RoutineTemplateDetailScreen({super.key, required this.templateId});

  @override
  ConsumerState<RoutineTemplateDetailScreen> createState() =>
      _RoutineTemplateDetailScreenState();
}

class _RoutineTemplateDetailScreenState
    extends ConsumerState<RoutineTemplateDetailScreen> {
  RoutineTemplate? _template;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final template = await ref
        .read(routineTemplateProvider.notifier)
        .fetchTemplateDetail(widget.templateId);
    if (mounted) {
      setState(() {
        _template = template;
        _loading = false;
      });
    }
  }

  Future<void> _import() async {
    try {
      final routine = await ref
          .read(routineTemplateProvider.notifier)
          .importTemplate(widget.templateId);
      if (!mounted) return;
      if (routine != null) {
        AppMessage.showSuccess(context, 'Rutina añadida a tu biblioteca');
        Navigator.pop(context, routine);
      }
    } catch (_) {
      if (mounted) {
        AppMessage.showError(context, 'No se pudo importar la plantilla');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImporting = ref.watch(routineTemplateProvider).isImporting;
    final template = _template;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          template?.name ?? 'Plantilla',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : template == null
              ? const Center(
                  child: Text(
                    'No se pudo cargar la plantilla',
                    style: TextStyle(color: AppTheme.hintColor),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (template.isOfficial)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Plantilla oficial Heft',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Text(
                            template.description.isNotEmpty
                                ? template.description
                                : 'Sin descripción',
                            style: const TextStyle(
                              color: AppTheme.hintColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por @${template.author.username}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Ejercicios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...template.exercises.map(_exerciseTile),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isImporting ? null : _import,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isImporting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Añadir a mis rutinas',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _exerciseTile(RoutineExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  translateMuscleGroup(exercise.muscleGroup),
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${exercise.targetSets}×${exercise.targetReps} @ ${exercise.targetWeight.toStringAsFixed(exercise.targetWeight % 1 == 0 ? 0 : 1)} kg',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
