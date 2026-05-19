import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/domain/statistics_model.dart';

void main() {
  test('UserStatistics.fromJson parsea respuesta del API', () {
    final stats = UserStatistics.fromJson({
      'period': 'month',
      'period_label': 'Mes',
      'period_start': '2026-05-01',
      'period_end': '2026-05-15',
      'summary': {
        'total_workouts': 4,
        'total_volume_kg': 12000,
        'total_sets': 40,
        'workout_days': 3,
        'expected_workout_days': 6,
        'adherence_percent': 50,
        'streak_days': 2,
      },
      'daily_volume': [],
      'volume_by_muscle_group': [
        {'muscle_group': 'pecho', 'label': 'Pecho', 'volume': 5000},
      ],
      'muscle_map': {
        'front': {'chest': 0.8},
        'back': {},
      },
      'exercise_progress': [
        {
          'exercise_id': 1,
          'exercise_name': 'Press',
          'muscle_group': 'pecho',
          'muscle_group_label': 'Pecho',
          'volume_trend_percent': 10,
          'max_weight_trend_percent': 5,
          'data_points': [
            {'date': '2026-05-10', 'max_weight': 80, 'volume': 640},
          ],
        },
      ],
    });

    expect(stats.period, 'month');
    expect(stats.summary.totalWorkouts, 4);
    expect(stats.muscleMap.front['chest'], 0.8);
    expect(stats.exerciseProgress.first.periodMaxWeight, 80);
  });
}
