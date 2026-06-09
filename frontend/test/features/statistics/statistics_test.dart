import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/statistics/data/statistics_local_service.dart';
import 'package:frontend/features/statistics/data/statistics_provider.dart';
import 'package:frontend/features/statistics/domain/statistics_model.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';

UserStatistics _emptyStats() {
  return UserStatistics(
    period: 'week',
    periodLabel: 'Semana',
    periodEnd: '2026-05-18',
    summary: StatisticsSummary(
      totalWorkouts: 0,
      totalVolumeKg: 0,
      totalSets: 0,
      workoutDays: 0,
      expectedWorkoutDays: 3,
      adherencePercent: 0,
      streakDays: 0,
    ),
    dailyVolume: [],
    volumeByMuscleGroup: [],
    muscleMap: MuscleMapData(front: {}, back: {}),
    exerciseProgress: [],
  );
}

void main() {
  test('StatisticsState copyWith clears errors', () {
    final state = StatisticsState(
      isLoading: true,
      error: 'fail',
      muscleMapError: 'map fail',
    );
    final next = state.copyWith(
      isLoading: false,
      clearError: true,
      clearMuscleMapError: true,
    );
    expect(next.isLoading, false);
    expect(next.error, isNull);
    expect(next.muscleMapError, isNull);
  });

  test('buildStatisticsFromWorkouts respects calendar week bounds', () {
    final stats = buildStatisticsFromWorkouts(
      workouts: [
        WorkoutSession(
          id: 1,
          name: 'Push',
          date: DateTime(2026, 5, 14),
          startTime: DateTime(2026, 5, 14, 10),
          endTime: DateTime(2026, 5, 14, 11),
          isCompleted: true,
          sets: [
            WorkoutSet(
              id: 1,
              exerciseId: 10,
              exerciseName: 'Press',
              setNumber: 1,
              setType: 'normal',
              weight: 60,
              reps: 10,
              isCompleted: true,
            ),
          ],
        ),
      ],
      exerciseMuscleById: {10: 'pecho'},
      apiPeriod: muscleMapApiPeriod,
      workoutDaysPerWeek: 3,
      referenceDate: DateTime(2026, 5, 15),
    );

    expect(stats.period, muscleMapApiPeriod);
    expect(stats.summary.totalWorkouts, 1);
    expect(stats.summary.totalVolumeKg, 600);
  });

  test('fake statistics notifier exposes stable state', () {
    final container = ProviderContainer(
      overrides: [
        statisticsProvider.overrideWith(_FakeStatisticsNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(statisticsProvider);
    expect(state.data?.periodLabel, 'Semana');
    expect(state.isLoading, false);
  });
}

class _FakeStatisticsNotifier extends StatisticsNotifier {
  @override
  StatisticsState build() {
    final week = _emptyStats();
    return StatisticsState(data: week, muscleMapWeekData: week);
  }

  @override
  Future<void> fetchStatistics(String uiPeriod, {bool forceReload = false}) async {}

  @override
  Future<void> fetchMuscleMapWeek({bool forceReload = false}) async {}
}
