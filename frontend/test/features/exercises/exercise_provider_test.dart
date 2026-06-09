import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/achievements/data/achievements_provider.dart';
import 'package:frontend/features/achievements/domain/achievement_model.dart';
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
        achievementsProvider.overrideWith(_EmptyAchievementsNotifier.new),
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

  test('fetchPopularExercises loads popular list', () async {
    when(() => mockDio.get('exercises/popular/')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/popular/'),
        data: [
          {
            'id': 9,
            'name': 'Popular',
            'muscle_group': 'pecho',
            'exercise_type': 'barra',
            'is_global': true,
          },
        ],
      ),
    );

    await container.read(exerciseProvider.notifier).fetchPopularExercises();
    expect(container.read(exerciseProvider).popularExercises.first.name, 'Popular');
  });

  test('createCustomExercise prepends created exercise', () async {
    when(() => mockDio.post('exercises/', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/'),
        data: {
          'id': 50,
          'name': 'Mi ejercicio',
          'muscle_group': 'espalda',
          'exercise_type': 'mancuerna',
          'is_global': false,
        },
      ),
    );

    await container.read(exerciseProvider.notifier).createCustomExercise(
          name: 'Mi ejercicio',
          muscleGroup: 'espalda',
          exerciseType: 'mancuerna',
        );

    expect(container.read(exerciseProvider).exercises.first.id, 50);
  });

  test('fetchExerciseById returns exercise or null', () async {
    when(() => mockDio.get('exercises/7/')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'exercises/7/'),
        data: {
          'id': 7,
          'name': 'Row',
          'muscle_group': 'espalda',
          'exercise_type': 'barra',
          'is_global': true,
        },
      ),
    );
    when(() => mockDio.get('exercises/99/')).thenThrow(
      DioException(requestOptions: RequestOptions(path: 'exercises/99/')),
    );

    final found =
        await container.read(exerciseProvider.notifier).fetchExerciseById(7);
    final missing =
        await container.read(exerciseProvider.notifier).fetchExerciseById(99);

    expect(found?.name, 'Row');
    expect(missing, isNull);
  });

  test('ExerciseQuery toQueryParams includes search and type', () {
    const query = ExerciseQuery(
      search: ' press ',
      muscleGroup: 'pecho',
      exerciseType: 'barra',
    );
    expect(query.toQueryParams(), {
      'search': 'press',
      'muscle_group': 'pecho',
      'exercise_type': 'barra',
    });
  });
}

class _EmptyAchievementsNotifier extends AchievementsNotifier {
  @override
  AchievementsState build() => const AchievementsState();

  @override
  Future<void> sync({Set<String>? unlockedBaseline}) async {}
}
