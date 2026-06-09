import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/workouts/data/workout_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mockDio)],
    );
  });

  tearDown(() => container.dispose());

  test('fetchWorkouts loads sessions', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'workouts/'),
        data: [
          {
            'id': 3,
            'name': 'Legs',
            'date': '2026-05-12',
            'start_time': '2026-05-12T09:00:00Z',
            'sets': [],
          },
        ],
      ),
    );

    await container.read(workoutHistoryProvider.notifier).fetchWorkouts();
    final state = container.read(workoutHistoryProvider);
    expect(state.workouts, hasLength(1));
    expect(state.workouts.first.name, 'Legs');
    expect(state.isLoading, false);
  });

}
