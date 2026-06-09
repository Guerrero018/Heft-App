import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/auth/auth_provider.dart';
import 'package:frontend/features/statistics/data/statistics_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _apiStatsPayload() => {
      'period': 'month',
      'period_label': 'Mes',
      'period_start': '2026-05-01',
      'period_end': '2026-05-15',
      'summary': {
        'total_workouts': 2,
        'total_volume_kg': 3000,
        'total_sets': 10,
        'workout_days': 2,
        'expected_workout_days': 8,
        'adherence_percent': 25,
        'streak_days': 1,
      },
      'daily_volume': [],
      'volume_by_muscle_group': [],
      'muscle_map': {'front': {}, 'back': {}},
      'exercise_progress': [
        {
          'exercise_id': 10,
          'exercise_name': 'Press',
          'muscle_group': 'pecho',
          'muscle_group_label': 'Pecho',
          'volume_trend_percent': 0,
          'max_weight_trend_percent': 0,
          'data_points': [],
        },
      ],
    };

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    when(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      final params = invocation.namedArguments[#queryParameters] as Map?;
      if (path == 'statistics/') {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: _apiStatsPayload(),
        );
      }
      if (path == 'workouts/') {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {
              'id': 1,
              'name': 'Push',
              'date': '2026-05-10',
              'start_time': '2026-05-10T10:00:00Z',
              'is_completed': true,
              'sets': [
                {
                  'id': 1,
                  'exercise': 10,
                  'exercise_name': 'Press',
                  'set_number': 1,
                  'set_type': 'normal',
                  'weight': 60,
                  'reps': 10,
                  'is_completed': true,
                },
              ],
            },
          ],
        );
      }
      if (path == 'exercises/') {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: {
            'results': [
              {
                'id': 10,
                'name': 'Press',
                'muscle_group': 'pecho',
                'exercise_type': 'barra',
                'is_global': true,
              },
            ],
            'next': null,
          },
        );
      }
      if (path.startsWith('workouts/')) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: {'id': 1, 'sets': []},
        );
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        data: params,
      );
    });

    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        authProvider.overrideWith(_FakeAuthNotifier.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('fetchStatistics loads merged data from API and workouts', () async {
    final notifier = container.read(statisticsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await notifier.fetchStatistics('Mes');

    final state = container.read(statisticsProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.data?.period, 'month');
    expect(state.data?.summary.totalWorkouts, 2);
    expect(state.selectedPeriod, 'Mes');
  });

  test('fetchMuscleMapWeek updates muscle map data', () async {
    final notifier = container.read(statisticsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await notifier.fetchMuscleMapWeek(forceReload: true);

    final state = container.read(statisticsProvider);
    expect(state.muscleMapLoading, false);
    expect(state.muscleMapWeekData, isNotNull);
  });

  test('ensureWorkoutsForStreak exposes cached workouts', () async {
    final notifier = container.read(statisticsProvider.notifier);
    await notifier.fetchStatistics('Mes');
    await notifier.ensureWorkoutsForStreak();
    expect(notifier.cachedWorkoutsForStreak, isNotEmpty);
  });

  test('fetchAllWorkoutSessionsSafe parses paginated workouts', () async {
    when(
      () => mockDio.get(
        'workouts/',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'workouts/'),
        data: {
          'results': [
            {
              'id': 5,
              'name': 'Pull',
              'date': '2026-05-11',
              'start_time': '2026-05-11T09:00:00Z',
              'sets': [],
            },
          ],
          'next': null,
        },
      ),
    );

    final sessions = await fetchAllWorkoutSessionsSafe(client: mockDio);
    expect(sessions, hasLength(1));
    expect(sessions.first.name, 'Pull');
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        isAuthenticated: true,
        user: {'workout_days_per_week': 3},
      );
}
