import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/data/statistics_local_service.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';

WorkoutSession _session({
  required String startIso,
  required String dayIso,
  required List<WorkoutSet> sets,
}) {
  return WorkoutSession(
    id: 1,
    name: 'Test',
    startTime: DateTime.parse(startIso),
    endTime: DateTime.parse(startIso).add(const Duration(hours: 1)),
    date: DateTime.parse(dayIso),
    isCompleted: true,
    sets: sets,
  );
}

WorkoutSet _set({
  required double weight,
  required int reps,
  int setNumber = 1,
}) {
  return WorkoutSet(
    id: setNumber,
    exerciseId: 10,
    exerciseName: 'Press Banca',
    setNumber: setNumber,
    setType: 'normal',
    weight: weight,
    reps: reps,
    isCompleted: true,
  );
}

void main() {
  test('volumen de sesión = suma de peso × reps por ejercicio', () {
    final stats = buildStatisticsFromWorkouts(
      workouts: [
        _session(
          startIso: '2026-05-10T10:00:00',
          dayIso: '2026-05-10',
          sets: [
            _set(weight: 80, reps: 8, setNumber: 1),
            _set(weight: 75, reps: 10, setNumber: 2),
          ],
        ),
      ],
      exerciseMuscleById: {10: 'pecho'},
      apiPeriod: 'month',
      workoutDaysPerWeek: 3,
    );

    expect(stats.exerciseProgress, hasLength(1));
    final progress = stats.exerciseProgress.first;
    expect(progress.dataPoints, hasLength(1));
    expect(progress.dataPoints.first.volume, 80 * 8 + 75 * 10);
    expect(progress.dataPoints.first.maxWeight, 80);
  });

  test('tendencia usa volumen entre primera y última sesión', () {
    final stats = buildStatisticsFromWorkouts(
      workouts: [
        _session(
          startIso: '2026-05-10T10:00:00',
          dayIso: '2026-05-10',
          sets: [_set(weight: 100, reps: 5)],
        ),
        _session(
          startIso: '2026-05-12T10:00:00',
          dayIso: '2026-05-12',
          sets: [_set(weight: 100, reps: 10)],
        ),
      ],
      exerciseMuscleById: {10: 'pecho'},
      apiPeriod: 'month',
      workoutDaysPerWeek: 3,
    );

    final progress = stats.exerciseProgress.first;
    expect(progress.dataPoints[0].volume, 500);
    expect(progress.dataPoints[1].volume, 1000);
    expect(progress.volumeTrendPercent, 100);
    expect(progress.maxWeightTrendPercent, 0);
  });

  test('tendencia de peso máximo entre sesiones', () {
    final stats = buildStatisticsFromWorkouts(
      workouts: [
        _session(
          startIso: '2026-05-10T10:00:00',
          dayIso: '2026-05-10',
          sets: [_set(weight: 80, reps: 5)],
        ),
        _session(
          startIso: '2026-05-12T10:00:00',
          dayIso: '2026-05-12',
          sets: [_set(weight: 90, reps: 3)],
        ),
      ],
      exerciseMuscleById: {10: 'pecho'},
      apiPeriod: 'month',
      workoutDaysPerWeek: 3,
    );

    final progress = stats.exerciseProgress.first;
    expect(progress.dataPoints[0].maxWeight, 80);
    expect(progress.dataPoints[1].maxWeight, 90);
    expect(progress.maxWeightTrendPercent, 12.5);
  });
}
