import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/data/statistics_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
  });

  test('fetchUserStatisticsFromApi returns parsed stats', () async {
    when(
      () => mockDio.get(
        'statistics/',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'statistics/'),
        data: {
          'period': 'week',
          'period_label': 'Semana',
          'period_end': '2026-05-15',
          'summary': {
            'total_workouts': 1,
            'total_volume_kg': 500,
            'total_sets': 5,
            'workout_days': 1,
            'expected_workout_days': 3,
            'adherence_percent': 33,
            'streak_days': 1,
          },
          'daily_volume': [],
          'volume_by_muscle_group': [],
          'muscle_map': {'front': {}, 'back': {}},
          'exercise_progress': [],
        },
      ),
    );

    final stats = await fetchUserStatisticsFromApi('week', client: mockDio);
    expect(stats, isNotNull);
    expect(stats!.period, 'week');
    expect(stats.summary.totalVolumeKg, 500);
  });

  test('fetchUserStatisticsFromApi returns null on error', () async {
    when(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'statistics/'),
        type: DioExceptionType.connectionError,
      ),
    );

    final stats = await fetchUserStatisticsFromApi('week', client: mockDio);
    expect(stats, isNull);
  });
}
