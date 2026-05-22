import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../routines/domain/routine_model.dart';
import '../../domain/live_workout_provider.dart';
import '../../domain/live_workout_state.dart';
import '../../../exercises/presentation/exercise_catalog_screen.dart';
import '../../../exercises/presentation/exercise_detail_screen.dart';
import '../../../exercises/domain/exercise_model.dart';
import '../../../exercises/data/exercise_provider.dart';
import '../widgets/live_workout_ui.dart';

class LiveWorkoutScreen extends ConsumerWidget {
  const LiveWorkoutScreen({super.key});

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  ({int completed, int total}) _setProgress(LiveWorkoutState state) {
    var completed = 0;
    var total = 0;
    for (final exercise in state.activeExercises) {
      total += exercise.sets.length;
      completed += exercise.sets.where((s) => s.isCompleted).length;
    }
    return (completed: completed, total: total);
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    final state = ref.read(liveWorkoutProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: LiveWorkoutUi.panelRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajustes del entrenamiento en curso',
              style: TextStyle(color: AppTheme.hintColor, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _SettingsTile(
              title: 'Temporizador de descanso',
              subtitle:
                  'Inicia automáticamente el descanso al completar una serie',
              value: state.enableRestTimer,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRestTimer(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              title: 'Campo RPE (esfuerzo)',
              subtitle: 'Anota el esfuerzo percibido (1-10)',
              value: state.enableRpe,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRpe(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              title: 'Campo RIR (repes en reserva)',
              subtitle: 'Cuántas repeticiones te quedaban (0-5)',
              value: state.enableRir,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRir(val);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiveWorkoutUi.panelRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar entrenamiento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro? Se perderá todo el progreso de la sesión actual.',
          style: TextStyle(color: AppTheme.hintColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(liveWorkoutProvider.notifier).cancelWorkout();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final state = ref.read(liveWorkoutProvider);
    final newExercise = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (newExercise != null) {
      final routineEx = RoutineExercise(
        id: 0,
        exerciseId: newExercise.id,
        exerciseName: newExercise.name,
        muscleGroup: newExercise.muscleGroup,
        externalId: newExercise.externalId,
        gifUrl: newExercise.gifUrl,
        order: state.activeExercises.length,
        targetSets: 3,
        targetReps: 10,
        targetWeight: 0,
      );
      ref.read(liveWorkoutProvider.notifier).addExercise(routineEx);
    }
  }

  Future<void> _finishWorkout(BuildContext context, WidgetRef ref) async {
    final saved = await ref.read(liveWorkoutProvider.notifier).finishWorkout();
    if (!context.mounted) return;
    if (saved) {
      AppMessage.showSuccess(
        context,
        'Entrenamiento guardado correctamente',
      );
      Navigator.of(context).pop();
    } else {
      AppMessage.showError(context, 'No se pudo guardar el entrenamiento');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveWorkoutProvider);
    final trackRpe = state.enableRpe;
    final trackRir = state.enableRir;
    final progress = _setProgress(state);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final restPadding = state.isResting ? 88.0 : 0.0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: LiveWorkoutUi.shell,
        body: Stack(
          children: [
            Column(
              children: [
                _SessionHeader(
                  sessionName: state.sessionName,
                  elapsedLabel: _formatTime(state.elapsedSeconds),
                  completedSets: progress.completed,
                  totalSets: progress.total,
                  onMinimize: () => Navigator.of(context).pop(),
                  onSettings: () => _showSettings(context, ref),
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24 + bottomInset + restPadding,
                          ),
                          children: [
                            if (state.activeExercises.isEmpty)
                              _buildEmptyState(),
                            ...state.activeExercises.asMap().entries.map(
                              (entry) => _ActiveExerciseCard(
                                exerciseIndex: entry.key,
                                exercise: entry.value,
                                trackRpe: trackRpe,
                                trackRir: trackRir,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _AddExerciseTile(
                              onTap: () => _addExercise(context, ref),
                            ),
                            const SizedBox(height: 24),
                            _WorkoutBottomBar(
                              onDiscard: () => _confirmCancel(context, ref),
                              onFinish: () => _finishWorkout(context, ref),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                ),
              ],
            ),
            if (state.isResting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RestTimerPanel(
                  restSeconds: state.restSecondsRemaining,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Entrenamiento vacío',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade un ejercicio para empezar a entrenar.',
            style: TextStyle(
              color: AppTheme.hintColor.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final String sessionName;
  final String elapsedLabel;
  final int completedSets;
  final int totalSets;
  final VoidCallback onMinimize;
  final VoidCallback onSettings;

  const _SessionHeader({
    required this.sessionName,
    required this.elapsedLabel,
    required this.completedSets,
    required this.totalSets,
    required this.onMinimize,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final progress = totalSets == 0 ? 0.0 : completedSets / totalSets;

    return Container(
      width: double.infinity,
      decoration: LiveWorkoutUi.headerGradient,
      padding: EdgeInsets.fromLTRB(4, top + 2, 4, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMinimize,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      sessionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      elapsedLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.tune_rounded, size: 20),
                color: AppTheme.hintColor,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  totalSets == 0
                      ? 'Sin series'
                      : '$completedSets / $totalSets',
                  style: const TextStyle(
                    color: AppTheme.hintColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutBottomBar extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onFinish;

  const _WorkoutBottomBar({
    required this.onDiscard,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onDiscard,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.redAccent,
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Finalizar entrenamiento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              style: BorderStyle.solid,
            ),
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Añadir ejercicio',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LiveWorkoutUi.inset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiveWorkoutUi.border),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
        ),
        value: value,
        activeThumbColor: AppTheme.primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActiveExerciseCard extends ConsumerWidget {
  final int exerciseIndex;
  final ActiveExercise exercise;
  final bool trackRpe;
  final bool trackRir;

  const _ActiveExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.trackRpe,
    required this.trackRir,
  });

  void _confirmDeleteExercise(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiveWorkoutUi.panelRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar ejercicio',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este ejercicio de la sesión actual?',
          style: TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(liveWorkoutProvider.notifier).removeExercise(index);
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LiveWorkoutUi.panelRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              exercise.routineExercise.exerciseName.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppTheme.hintColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              icon: Icons.reorder_rounded,
              title: 'Reordenar ejercicios',
              onTap: () {
                Navigator.pop(ctx);
                _showReorderDialog(context, ref);
              },
            ),
            const SizedBox(height: 8),
            _buildActionTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Reemplazar ejercicio',
              onTap: () async {
                Navigator.pop(ctx);
                final newExercise = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const ExerciseCatalogScreen(isSelectionMode: true),
                  ),
                );
                if (newExercise != null) {
                  final routineEx = RoutineExercise(
                    id: 0,
                    exerciseId: newExercise.id,
                    exerciseName: newExercise.name,
                    muscleGroup: newExercise.muscleGroup,
                    externalId: newExercise.externalId,
                    gifUrl: newExercise.gifUrl,
                    order: exercise.routineExercise.order,
                    targetSets: exercise.sets.length,
                    targetReps: exercise.sets.first.reps,
                    targetWeight: exercise.sets.first.weight,
                  );
                  ref
                      .read(liveWorkoutProvider.notifier)
                      .replaceExercise(exerciseIndex, routineEx);
                }
              },
            ),
            const Divider(color: LiveWorkoutUi.border, height: 28),
            _buildActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Eliminar de la sesión',
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteExercise(context, ref, exerciseIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withValues(alpha: 0.08)
              : LiveWorkoutUi.inset,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.redAccent.withValues(alpha: 0.2)
                : LiveWorkoutUi.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.85), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.35),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showReorderDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LiveWorkoutUi.panelRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final exercises = ref.watch(liveWorkoutProvider).activeExercises;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reordenar ejercicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mantén pulsado y arrastra para reordenar',
                    style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(liveWorkoutProvider.notifier)
                            .reorderExercises(oldIndex, newIndex);
                      },
                      children: [
                        for (int i = 0; i < exercises.length; i++)
                          ListTile(
                            key: ValueKey('reorder_$i'),
                            tileColor: LiveWorkoutUi.inset,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const Icon(
                              Icons.drag_indicator,
                              color: AppTheme.hintColor,
                            ),
                            title: Text(
                              exercises[i].routineExercise.exerciseName,
                            ),
                            trailing: Text(
                              '${i + 1}º',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedSets =
        exercise.sets.where((s) => s.isCompleted).length;
    final muscleGroup = exercise.routineExercise.muscleGroup;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: LiveWorkoutUi.cardDecoration(
        accent: completedSets == exercise.sets.length && exercise.sets.isNotEmpty,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${exerciseIndex + 1}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.routineExercise.exerciseName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final fullExercise = await ref
                                .read(exerciseProvider.notifier)
                                .fetchExerciseById(
                                  exercise.routineExercise.exerciseId,
                                );

                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ExerciseDetailScreen(
                                    exercise: fullExercise ??
                                        Exercise(
                                          id: exercise
                                              .routineExercise.exerciseId,
                                          name: exercise
                                              .routineExercise.exerciseName,
                                          muscleGroup: exercise
                                              .routineExercise.muscleGroup,
                                          gifUrl:
                                              exercise.routineExercise.gifUrl,
                                          externalId: exercise
                                              .routineExercise.externalId,
                                          exerciseType: 'otro',
                                          isGlobal: true,
                                        ),
                                    showAddButton: false,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppTheme.hintColor.withValues(alpha: 0.6),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: AppTheme.hintColor,
                          ),
                          onPressed: () => _showExerciseActions(context, ref),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    if (muscleGroup.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      MuscleGroupTag(muscleGroup: muscleGroup),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$completedSets / ${exercise.sets.length} series hechas',
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            decoration: BoxDecoration(
              color: LiveWorkoutUi.inset,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LiveWorkoutUi.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 32,
                        child: Text(
                          '#',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 58,
                        child: Text(
                          'Ant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(
                        width: 48,
                        child: Text(
                          'KG',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 48,
                        child: Text(
                          'REPS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (trackRpe)
                        const SizedBox(
                          width: 44,
                          child: Text(
                            'RPE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.hintColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (trackRir)
                        const SizedBox(
                          width: 44,
                          child: Text(
                            'RIR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.hintColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(
                        width: 36,
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppTheme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (int i = 0; i < exercise.sets.length; i++)
                  _SetRow(
                    exerciseIndex: exerciseIndex,
                    setIndex: i,
                    setData: exercise.sets[i],
                    trackRpe: trackRpe,
                    trackRir: trackRir,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(liveWorkoutProvider.notifier).addSet(exerciseIndex);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir serie'),
              ),
              if (exercise.sets.length > 1) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(liveWorkoutProvider.notifier)
                        .removeLastSet(exerciseIndex);
                  },
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('Quitar serie'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerWidget {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSetData setData;
  final bool trackRpe;
  final bool trackRir;

  const _SetRow({
    required this.exerciseIndex,
    required this.setIndex,
    required this.setData,
    required this.trackRpe,
    required this.trackRir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = setData.isCompleted;
    final rowColor = isCompleted
        ? AppTheme.primaryColor.withValues(alpha: 0.14)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(10),
        border: isCompleted
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: _getTypeColor(setData.type)
                    .withValues(alpha: isCompleted ? 1 : 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getTypeLetter(setData.type, setIndex + 1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isCompleted
                        ? Colors.black
                        : _getTypeColor(setData.type),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Center(
              child: Text(
                setData.prevWeight != null
                    ? '${setData.prevWeight.toString().replaceAll(RegExp(r'\.0$'), '')}k x ${setData.prevReps}'
                    : '-',
                style: TextStyle(
                  color: isCompleted
                      ? AppTheme.primaryColor.withValues(alpha: 0.65)
                      : AppTheme.hintColor,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 48,
            child: _buildInput(
              value: setData.wasModifiedWeight
                  ? setData.weight.toString().replaceAll(RegExp(r'\.0$'), '')
                  : '',
              hint: setData.prevWeight != null
                  ? setData.prevWeight.toString().replaceAll(
                      RegExp(r'\.0$'),
                      '',
                    )
                  : (setData.weight > 0
                        ? setData.weight.toString().replaceAll(
                            RegExp(r'\.0$'),
                            '',
                          )
                        : '0'),
              isCompleted: isCompleted,
              isModified: setData.wasModifiedWeight,
              onChanged: (val) {
                final weight = double.tryParse(val);
                if (weight != null) {
                  ref.read(liveWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setData.id,
                        weight: weight,
                      );
                }
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: _buildInput(
              value: setData.wasModifiedReps ? setData.reps.toString() : '',
              hint: setData.prevReps != null
                  ? setData.prevReps.toString()
                  : (setData.reps > 0 ? setData.reps.toString() : '0'),
              isCompleted: isCompleted,
              isModified: setData.wasModifiedReps,
              onChanged: (val) {
                final reps = int.tryParse(val);
                if (reps != null) {
                  ref.read(liveWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setData.id,
                        reps: reps,
                      );
                }
              },
            ),
          ),
          if (trackRpe)
            SizedBox(
              width: 44,
              child: _buildInput(
                value: setData.wasModifiedRpe
                    ? (setData.rpe?.toString() ?? '')
                    : '',
                hint: '-',
                isCompleted: isCompleted,
                isModified: setData.wasModifiedRpe,
                onChanged: (val) {
                  final rpe = double.tryParse(val);
                  ref.read(liveWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setData.id,
                        rpe: rpe,
                      );
                },
              ),
            ),
          if (trackRir)
            SizedBox(
              width: 44,
              child: _buildInput(
                value: setData.wasModifiedRir
                    ? (setData.rir?.toString() ?? '')
                    : '',
                hint: '-',
                isCompleted: isCompleted,
                isModified: setData.wasModifiedRir,
                onChanged: (val) {
                  final rir = int.tryParse(val);
                  ref.read(liveWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setData.id,
                        rir: rir,
                      );
                },
              ),
            ),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isCompleted
                    ? AppTheme.primaryColor
                    : AppTheme.hintColor.withValues(alpha: 0.35),
                size: 22,
              ),
              onPressed: () {
                ref
                    .read(liveWorkoutProvider.notifier)
                    .toggleSetComplete(exerciseIndex, setData.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String value,
    String hint = '0',
    required bool isCompleted,
    bool isModified = true,
    required Function(String) onChanged,
  }) {
    Color textColor;
    if (isCompleted) {
      textColor = AppTheme.primaryColor;
    } else if (isModified) {
      textColor = AppTheme.textColor;
    } else {
      textColor = AppTheme.hintColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: isCompleted || isModified
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.hintColor.withValues(alpha: 0.35),
            fontWeight: FontWeight.normal,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }

  String _getTypeLetter(String type, int index) {
    switch (type) {
      case 'warmup':
        return 'W';
      case 'dropset':
        return 'D';
      case 'failure':
        return 'F';
      default:
        return '$index';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'warmup':
        return Colors.orange;
      case 'dropset':
        return Colors.blue;
      case 'failure':
        return Colors.red;
      default:
        return AppTheme.hintColor;
    }
  }
}

class _RestTimerPanel extends ConsumerWidget {
  final int restSeconds;

  const _RestTimerPanel({required this.restSeconds});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descanso',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatTime(restSeconds),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () =>
                ref.read(liveWorkoutProvider.notifier).adjustRestTimer(-10),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black.withValues(alpha: 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('-10s'),
          ),
          TextButton(
            onPressed: () =>
                ref.read(liveWorkoutProvider.notifier).adjustRestTimer(30),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black.withValues(alpha: 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('+30s'),
          ),
          IconButton(
            onPressed: () =>
                ref.read(liveWorkoutProvider.notifier).stopRestTimer(),
            icon: const Icon(Icons.close_rounded, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
