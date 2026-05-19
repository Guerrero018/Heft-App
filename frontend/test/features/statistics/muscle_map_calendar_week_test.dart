import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/workout_week_streak.dart';
import 'package:frontend/features/statistics/data/statistics_local_service.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';

WorkoutSession _session(String dayIso, {double weight = 80, int reps = 8}) {
  final day = DateTime.parse(dayIso);
  return WorkoutSession(
    id: 1,
    name: 'Test',
    startTime: day,
    endTime: day.add(const Duration(hours: 1)),
    date: day,
    isCompleted: true,
    sets: [
      WorkoutSet(
        id: 1,
        exerciseId: 10,
        exerciseName: 'Press',
        setNumber: 1,
        setType: 'normal',
        weight: weight,
        reps: reps,
        isCompleted: true,
      ),
    ],
  );
}

void main() {
  test('calendarWeekBounds es lunes a domingo', () {
    // Miércoles 14 may 2026
    final wed = DateTime(2026, 5, 14);
    final bounds = calendarWeekBounds(wed);
    expect(bounds.start, DateTime(2026, 5, 11));
    expect(bounds.end, DateTime(2026, 5, 17));
  });

  test('mapa muscular solo incluye sesiones de la semana calendario', () {
    final ref = DateTime(2026, 5, 14); // miércoles
    final stats = buildStatisticsFromWorkouts(
      workouts: [
        _session('2026-05-12'), // martes de esta semana
        _session('2026-05-05'), // lunes semana anterior
        _session('2026-05-19'), // lunes semana siguiente
      ],
      exerciseMuscleById: {10: 'pecho'},
      apiPeriod: muscleMapApiPeriod,
      workoutDaysPerWeek: 3,
      referenceDate: ref,
    );

    expect(stats.summary.totalWorkouts, 1);
    expect(stats.muscleMap.front['chest'], isNotNull);
    expect(stats.muscleMap.front['chest'], greaterThan(0));
  });
}
