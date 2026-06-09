import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/workouts/data/workout_fetch_service.dart';
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

  test('fetchAllWorkoutSessions parses list response', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'workouts/'),
        data: [
          {
            'id': 1,
            'name': 'Push',
            'date': '2026-05-10',
            'start_time': '2026-05-10T10:00:00Z',
            'is_completed': true,
            'sets': [],
          },
        ],
      ),
    );

    final sessions = await fetchAllWorkoutSessions(client: mockDio);
    expect(sessions, hasLength(1));
    expect(sessions.first.name, 'Push');
  });

  test('fetchAllWorkoutSessions follows pagination', () async {
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
              'id': 1,
              'name': 'A',
              'date': '2026-05-10',
              'start_time': '2026-05-10T10:00:00Z',
              'sets': [],
            },
          ],
          'next': 'http://localhost/api/workouts/?page=2',
        },
      ),
    );

    when(() => mockDio.get('workouts/?page=2')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'workouts/?page=2'),
        data: {
          'results': [
            {
              'id': 2,
              'name': 'B',
              'date': '2026-05-11',
              'start_time': '2026-05-11T10:00:00Z',
              'sets': [],
            },
          ],
          'next': null,
        },
      ),
    );

    final sessions = await fetchAllWorkoutSessions(client: mockDio);
    expect(sessions.map((s) => s.name).toList(), ['A', 'B']);
  });
}
