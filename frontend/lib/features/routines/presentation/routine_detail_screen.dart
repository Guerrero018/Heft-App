import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/label_translations.dart';
import '../../live_workout/domain/live_workout_provider.dart';
import '../../live_workout/presentation/screens/live_workout_screen.dart';
import '../../workouts/domain/workout_model.dart';
import '../../workouts/presentation/screens/workout_detail_screen.dart';
import '../data/routine_progress_provider.dart';
import '../data/routine_provider.dart';
import '../domain/routine_model.dart';
import '../domain/routine_progress.dart';
import 'create_routine_screen.dart';
import 'widgets/routine_options_sheet.dart';

class RoutineDetailScreen extends ConsumerWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  Routine _currentRoutine(WidgetRef ref) {
    ref.watch(routineProvider);
    return ref.read(routineProvider.notifier).findById(routine.id) ?? routine;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoutine = _currentRoutine(ref);
    final progressAsync = ref.watch(routineProgressProvider(currentRoutine.id));
    final progress = progressAsync.value ?? const RoutineProgress();
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    final muscleGroups = currentRoutine.exercises
        .map((e) => translateMuscleGroup(e.muscleGroup))
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await ref.read(routineProvider.notifier).fetchRoutines();
          ref.invalidate(routineProgressProvider(currentRoutine.id));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: AppTheme.surfaceColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () =>
                      showRoutineOptionsSheet(
                        context,
                        ref,
                        currentRoutine,
                        popHostOnDelete: true,
                      ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  currentRoutine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                        AppTheme.surfaceColor,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.view_list_rounded,
                      size: 64,
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!currentRoutine.isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.archive_outlined,
                                color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Rutina archivada',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (currentRoutine.description.isNotEmpty) ...[
                      Text(
                        currentRoutine.description,
                        style: const TextStyle(
                          color: AppTheme.hintColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (muscleGroups.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: muscleGroups
                            .map(
                              (muscle) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  muscle.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(liveWorkoutProvider.notifier)
                              .startWorkout(currentRoutine);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LiveWorkoutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar entrenamiento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Progreso',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (progressAsync.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    else if (progressAsync.hasError)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No se pudo cargar el progreso de esta rutina.',
                          style: TextStyle(color: AppTheme.hintColor),
                        ),
                      )
                    else if (progress.totalSessions == 0)
                      _EmptyProgressCard(
                        onStart: () {
                          ref
                              .read(liveWorkoutProvider.notifier)
                              .startWorkout(currentRoutine);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LiveWorkoutScreen(),
                            ),
                          );
                        },
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'SESIONES',
                              value: '${progress.totalSessions}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'VOLUMEN',
                              value: '${progress.totalVolumeKg.toInt()} kg',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'DURACIÓN MEDIA',
                              value: progress.averageDurationLabel,
                            ),
                          ),
                        ],
                      ),
                      if (progress.lastSessionDate != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Última sesión: ${dateFormat.format(progress.lastSessionDate!)}',
                          style: const TextStyle(
                            color: AppTheme.hintColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (progress.exerciseProgress.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Progreso por ejercicio',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...progress.exerciseProgress.map(
                          (item) => _ExerciseProgressTile(progress: item),
                        ),
                      ],
                      if (progress.recentSessions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Sesiones recientes',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...progress.recentSessions.map(
                          (session) => _RecentSessionTile(
                            session: session,
                            dateFormat: dateFormat,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkoutDetailScreen(workout: session),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ejercicios',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateRoutineScreen(
                                  existingRoutine: currentRoutine,
                                ),
                              ),
                            );
                          },
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentRoutine.exercises.isEmpty)
                      const Text(
                        'Esta rutina no tiene ejercicios todavía.',
                        style: TextStyle(color: AppTheme.hintColor),
                      )
                    else
                      ...currentRoutine.exercises.map(
                        (exercise) => _RoutineExerciseTile(exercise: exercise),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.hintColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProgressCard extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyProgressCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.insights_outlined,
              color: AppTheme.hintColor, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay sesiones con esta rutina',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.hintColor),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onStart,
            child: const Text('Iniciar primera sesión'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseProgressTile extends StatelessWidget {
  final RoutineExerciseProgress progress;

  const _ExerciseProgressTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.exerciseName,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.lastWeight != null && progress.lastReps != null
                      ? 'Último: ${progress.lastWeight!.toStringAsFixed(progress.lastWeight! % 1 == 0 ? 0 : 1)} kg x ${progress.lastReps}'
                      : 'Sin datos recientes',
                  style: const TextStyle(
                    color: AppTheme.hintColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'MEJOR',
                style: TextStyle(
                  color: AppTheme.hintColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progress.bestWeight.toStringAsFixed(progress.bestWeight % 1 == 0 ? 0 : 1)} kg x ${progress.bestReps}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  final WorkoutSession session;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _RecentSessionTile({
    required this.session,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          session.name.isEmpty ? 'Entrenamiento' : session.name,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${dateFormat.format(session.date)} · ${session.duration} · ${session.totalVolume.toInt()} kg',
          style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.hintColor),
      ),
    );
  }
}

class _RoutineExerciseTile extends StatelessWidget {
  final RoutineExercise exercise;

  const _RoutineExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translateMuscleGroup(exercise.muscleGroup),
                  style: const TextStyle(
                    color: AppTheme.hintColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${exercise.targetSets} x ${exercise.targetReps}'
            '${exercise.targetWeight > 0 ? ' · ${exercise.targetWeight.toStringAsFixed(exercise.targetWeight % 1 == 0 ? 0 : 1)} kg' : ''}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
