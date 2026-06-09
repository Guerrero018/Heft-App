import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/exercises/data/exercise_provider.dart';
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
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('fetchExercises loads first page with filters', () async {
    when(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/'),
        data: {
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 1,
              'name': 'Press Banca',
              'muscle_group': 'pecho',
              'exercise_type': 'barra',
              'is_global': true,
            },
          ],
        },
      ),
    );

    await container.read(exerciseProvider.notifier).fetchExercises(
          query: const ExerciseQuery(muscleGroup: 'pecho'),
        );

    final state = container.read(exerciseProvider);
    expect(state.exercises.length, 1);
    expect(state.exercises.first.name, 'Press Banca');
    expect(state.hasMore, false);
    expect(state.isLoading, false);

    verify(
      () => mockDio.get(
        'exercises/',
        queryParameters: {'muscle_group': 'pecho'},
      ),
    ).called(1);
  });

  test('loadMore appends next page', () async {
    when(
      () => mockDio.get(
        'exercises/',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/'),
        data: {
          'count': 2,
          'next': 'http://localhost/api/exercises/?page=2',
          'results': [
            {
              'id': 1,
              'name': 'A',
              'muscle_group': 'pecho',
              'exercise_type': 'barra',
              'is_global': true,
            },
          ],
        },
      ),
    );

    when(() => mockDio.get('exercises/?page=2')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/?page=2'),
        data: {
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'name': 'B',
              'muscle_group': 'espalda',
              'exercise_type': 'barra',
              'is_global': true,
            },
          ],
        },
      ),
    );

    final notifier = container.read(exerciseProvider.notifier);
    await notifier.fetchExercises();
    await notifier.loadMore();

    final state = container.read(exerciseProvider);
    expect(state.exercises.map((e) => e.name).toList(), ['A', 'B']);
    expect(state.hasMore, false);
  });
}
