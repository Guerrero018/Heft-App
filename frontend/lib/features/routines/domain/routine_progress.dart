import '../../workouts/domain/workout_model.dart';

class RoutineExerciseProgress {
  final int exerciseId;
  final String exerciseName;
  final double bestWeight;
  final int bestReps;
  final double? lastWeight;
  final int? lastReps;
  final DateTime? lastSessionDate;

  const RoutineExerciseProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.bestWeight,
    required this.bestReps,
    this.lastWeight,
    this.lastReps,
    this.lastSessionDate,
  });
}

class RoutineProgress {
  final int totalSessions;
  final DateTime? lastSessionDate;
  final double totalVolumeKg;
  final String averageDurationLabel;
  final List<RoutineExerciseProgress> exerciseProgress;
  final List<WorkoutSession> recentSessions;

  const RoutineProgress({
    this.totalSessions = 0,
    this.lastSessionDate,
    this.totalVolumeKg = 0,
    this.averageDurationLabel = '--',
    this.exerciseProgress = const [],
    this.recentSessions = const [],
  });
}

RoutineProgress buildRoutineProgress({
  required List<WorkoutSession> sessions,
  Set<int>? routineExerciseIds,
  int recentLimit = 5,
}) {
  bool countsForRoutine(WorkoutSet set) {
    if (routineExerciseIds == null || routineExerciseIds.isEmpty) {
      return true;
    }
    return routineExerciseIds.contains(set.exerciseId);
  }
  if (sessions.isEmpty) {
    return const RoutineProgress();
  }

  final completed = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  if (completed.isEmpty) {
    return const RoutineProgress();
  }

  double totalVolume = 0;
  var totalDurationMinutes = 0;
  var sessionsWithDuration = 0;

  final exerciseStats = <int, _ExerciseAgg>{};

  for (final session in completed) {
    for (final set in session.sets) {
      if (!set.isCompleted || set.weight <= 0 || set.reps <= 0) continue;
      if (!countsForRoutine(set)) continue;
      totalVolume += set.weight * set.reps;
    }
    if (session.endTime != null) {
      totalDurationMinutes += session.endTime!.difference(session.startTime).inMinutes;
      sessionsWithDuration += 1;
    }

    for (final set in session.sets) {
      if (!set.isCompleted || set.weight <= 0 || set.reps <= 0) continue;
      if (!countsForRoutine(set)) continue;
      final agg = exerciseStats.putIfAbsent(
        set.exerciseId,
        () => _ExerciseAgg(
          exerciseId: set.exerciseId,
          exerciseName: set.exerciseName,
        ),
      );

      final isBetter = set.weight > agg.bestWeight ||
          (set.weight == agg.bestWeight && set.reps > agg.bestReps);
      if (isBetter) {
        agg.bestWeight = set.weight;
        agg.bestReps = set.reps;
      }

      if (agg.lastSessionDate == null ||
          session.startTime.isAfter(agg.lastSessionDate!)) {
        agg.lastWeight = set.weight;
        agg.lastReps = set.reps;
        agg.lastSessionDate = session.startTime;
      }
    }
  }

  final avgMinutes = sessionsWithDuration == 0
      ? 0
      : (totalDurationMinutes / sessionsWithDuration).round();
  final avgLabel = sessionsWithDuration == 0
      ? '--'
      : avgMinutes >= 60
          ? '${avgMinutes ~/ 60}h ${avgMinutes % 60}m'
          : '${avgMinutes}m';

  final exerciseProgress = exerciseStats.values
      .map(
        (agg) => RoutineExerciseProgress(
          exerciseId: agg.exerciseId,
          exerciseName: agg.exerciseName,
          bestWeight: agg.bestWeight,
          bestReps: agg.bestReps,
          lastWeight: agg.lastWeight,
          lastReps: agg.lastReps,
          lastSessionDate: agg.lastSessionDate,
        ),
      )
      .toList()
    ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

  return RoutineProgress(
    totalSessions: completed.length,
    lastSessionDate: completed.first.startTime,
    totalVolumeKg: totalVolume,
    averageDurationLabel: avgLabel,
    exerciseProgress: exerciseProgress,
    recentSessions: completed.take(recentLimit).toList(),
  );
}

class _ExerciseAgg {
  final int exerciseId;
  final String exerciseName;
  double bestWeight = 0;
  int bestReps = 0;
  double? lastWeight;
  int? lastReps;
  DateTime? lastSessionDate;

  _ExerciseAgg({
    required this.exerciseId,
    required this.exerciseName,
  });
}
