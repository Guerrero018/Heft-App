import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/auth_provider.dart';
import '../../../routines/domain/routine_model.dart';
import '../../domain/live_workout_provider.dart';
import '../../domain/live_workout_state.dart';
import '../../../exercises/presentation/exercise_catalog_screen.dart';
import '../../../exercises/presentation/exercise_detail_screen.dart';
import '../../../exercises/domain/exercise_model.dart';
import '../../../exercises/data/exercise_provider.dart';

class LiveWorkoutScreen extends ConsumerWidget {
  const LiveWorkoutScreen({super.key});

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0)
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    final state = ref.read(liveWorkoutProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configuraciones de Sesión',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.hintColor),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                'Temporizador de Descanso',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Inicia automáticamente el descanso al completar una serie',
                style: TextStyle(color: AppTheme.hintColor),
              ),
              value: state.enableRestTimer,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRestTimer(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Campo RPE (Esfuerzo)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Añade una casilla para anotar el esfuerzo percibido (1-10)',
                style: TextStyle(color: AppTheme.hintColor),
              ),
              value: state.enableRpe,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRpe(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Campo RIR (Repes en Reserva)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Añade una casilla para anotar cuántas repeticiones te quedaban (0-5)',
                style: TextStyle(color: AppTheme.hintColor),
              ),
              value: state.enableRir,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).toggleRir(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Cancelar Entrenamiento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro? Se perderá todo el progreso de la sesión actual.',
          style: TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Seguir Entrenando',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveWorkoutProvider);
    final trackRpe = state.enableRpe;
    final trackRir = state.enableRir;

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            children: [
              Text(
                state.sessionName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(state.elapsedSeconds),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            // Solo Configuración arriba a la derecha
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppTheme.hintColor,
                  size: 20,
                ),
              ),
              onPressed: () => _showSettings(context, ref),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (state.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            else
              ListView(
                padding: const EdgeInsets.only(bottom: 60, top: 16),
                children: [
                  if (state.activeExercises.isEmpty)
                    _buildEmptyState(context),
                  
                  ...state.activeExercises.asMap().entries.map((entry) {
                    return _ActiveExerciseCard(
                      exerciseIndex: entry.key,
                      exercise: entry.value,
                      trackRpe: trackRpe,
                      trackRir: trackRir,
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Botón Añadir Ejercicio (Al final de la lista)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newExercise = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ExerciseCatalogScreen(
                              isSelectionMode: true,
                            ),
                          ),
                        );

                        if (newExercise != null) {
                          final routineEx = RoutineExercise(
                            id: 0, // Temp ID
                            exerciseId: newExercise.id,
                            exerciseName: newExercise.name,
                            muscleGroup: newExercise.muscleGroup,
                            externalId: newExercise.externalId,
                            gifUrl: newExercise.gifUrl,
                            order: state.activeExercises.length,
                            targetSets: 3, // Default values
                            targetReps: 10,
                            targetWeight: 0,
                          );
                          ref
                              .read(liveWorkoutProvider.notifier)
                              .addExercise(routineEx);
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('AÑADIR EJERCICIO'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botones de Acción (Finalizar y Descartar)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Descartar (Más pequeño)
                        SizedBox(
                          width: 45,
                          height: 45,
                          child: IconButton(
                            onPressed: () => _confirmCancel(context, ref),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Finalizar (Prominente)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(liveWorkoutProvider.notifier)
                                  .finishWorkout();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'FINALIZAR ENTRENAMIENTO',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),

            // Rest Timer Panel (Vuelve a estar abajo fijo si se activa)
            if (state.isResting)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _RestTimerPanel(restSeconds: state.restSecondsRemaining),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppTheme.hintColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Entrenamiento Vacío',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade un ejercicio para empezar a entrenar.',
            style: TextStyle(color: AppTheme.hintColor),
          ),
        ],
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Eliminar Ejercicio',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este ejercicio de la sesión actual?',
          style: TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
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
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual para deslizar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              exercise.routineExercise.exerciseName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.hintColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

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
                    id: 0, // Temp ID
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
            const Divider(color: Colors.white10, height: 32),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withOpacity(0.05)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(0.3),
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
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    'REORDENAR EJERCICIOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('LISTO'),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Ejercicio
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        exercise.routineExercise.exerciseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () async {
                        // Fetch full exercise details
                        final fullExercise = await ref
                            .read(exerciseProvider.notifier)
                            .fetchExerciseById(exercise.routineExercise.exerciseId);

                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(
                                exercise: fullExercise ??
                                    Exercise(
                                      id: exercise.routineExercise.exerciseId,
                                      name: exercise.routineExercise.exerciseName,
                                      muscleGroup: exercise.routineExercise.muscleGroup,
                                      gifUrl: exercise.routineExercise.gifUrl,
                                      externalId: exercise.routineExercise.externalId,
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
                        size: 16,
                        color: AppTheme.hintColor.withOpacity(0.4),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppTheme.hintColor),
                onPressed: () => _showExerciseActions(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cabeceras de tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    'Serie',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'Anterior',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 50,
                  child: Text(
                    'kg',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                  child: Text(
                    'Repet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (trackRpe)
                  const SizedBox(
                    width: 50,
                    child: Text(
                      'RPE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (trackRir)
                  const SizedBox(
                    width: 50,
                    child: Text(
                      'RIR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 35,
                  child: Icon(Icons.check, size: 16, color: AppTheme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de Series
          for (int i = 0; i < exercise.sets.length; i++)
            _SetRow(
              exerciseIndex: exerciseIndex,
              setIndex: i,
              setData: exercise.sets[i],
              trackRpe: trackRpe,
              trackRir: trackRir,
            ),

          const SizedBox(height: 16),

          // Botones Serie
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(liveWorkoutProvider.notifier).addSet(exerciseIndex);
                },
                icon: const Icon(Icons.add, color: AppTheme.hintColor),
                label: const Text(
                  'Añadir Serie',
                  style: TextStyle(color: AppTheme.hintColor),
                ),
              ),
              if (exercise.sets.length > 1) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(liveWorkoutProvider.notifier)
                        .removeLastSet(exerciseIndex);
                  },
                  icon: const Icon(Icons.remove, color: Colors.redAccent),
                  label: const Text(
                    'Quitar Serie',
                    style: TextStyle(color: Colors.redAccent),
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
        ? AppTheme.primaryColor.withOpacity(0.12)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: Row(
        children: [
          // Type & Number
          SizedBox(
            width: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(
                  setData.type,
                ).withOpacity(isCompleted ? 1 : 0.2),
                borderRadius: BorderRadius.circular(6),
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

          // Previous Value
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                setData.prevWeight != null
                    ? '${setData.prevWeight.toString().replaceAll(RegExp(r'\.0$'), '')}k x ${setData.prevReps}'
                    : '-',
                style: TextStyle(
                  color: isCompleted
                      ? AppTheme.primaryColor.withOpacity(0.6)
                      : AppTheme.hintColor,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Weight Input
          SizedBox(
            width: 50,
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
                  ref
                      .read(liveWorkoutProvider.notifier)
                      .updateSet(exerciseIndex, setData.id, weight: weight);
                }
              },
            ),
          ),

          // Reps Input
          SizedBox(
            width: 50,
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
                  ref
                      .read(liveWorkoutProvider.notifier)
                      .updateSet(exerciseIndex, setData.id, reps: reps);
                }
              },
            ),
          ),

          // RPE Input
          if (trackRpe)
            SizedBox(
              width: 50,
              child: _buildInput(
                value: setData.wasModifiedRpe
                    ? (setData.rpe?.toString() ?? '')
                    : '',
                hint: '-',
                isCompleted: isCompleted,
                isModified: setData.wasModifiedRpe,
                onChanged: (val) {
                  final rpe = double.tryParse(val);
                  ref
                      .read(liveWorkoutProvider.notifier)
                      .updateSet(exerciseIndex, setData.id, rpe: rpe);
                },
              ),
            ),

          // RIR Input
          if (trackRir)
            SizedBox(
              width: 50,
              child: _buildInput(
                value: setData.wasModifiedRir
                    ? (setData.rir?.toString() ?? '')
                    : '',
                hint: '-',
                isCompleted: isCompleted,
                isModified: setData.wasModifiedRir,
                onChanged: (val) {
                  final rir = int.tryParse(val);
                  ref
                      .read(liveWorkoutProvider.notifier)
                      .updateSet(exerciseIndex, setData.id, rir: rir);
                },
              ),
            ),

          // Complete Toggle
          SizedBox(
            width: 35,
            child: IconButton(
              icon: Icon(
                Icons.check_circle,
                color: isCompleted
                    ? AppTheme.primaryColor
                    : AppTheme.hintColor.withOpacity(0.3),
                size: 20,
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
      textColor = AppTheme.textColor; // White
    } else {
      textColor = AppTheme.hintColor; // Gray
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.transparent
            : Colors.white.withOpacity(0.05),
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
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.hintColor.withOpacity(0.3),
            fontWeight: FontWeight.normal,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.black, size: 28),
            const SizedBox(width: 12),
            Text(
              _formatTime(restSeconds),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  ref.read(liveWorkoutProvider.notifier).adjustRestTimer(-10),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: const Text('-10s'),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(liveWorkoutProvider.notifier).adjustRestTimer(30),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: const Text('+30s'),
            ),
            IconButton(
              onPressed: () =>
                  ref.read(liveWorkoutProvider.notifier).stopRestTimer(),
              icon: const Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
