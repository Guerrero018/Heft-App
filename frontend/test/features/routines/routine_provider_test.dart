import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/achievements/data/achievements_provider.dart';
import 'package:frontend/features/achievements/domain/achievement_model.dart';
import 'package:frontend/features/routines/data/routine_provider.dart';
import 'package:frontend/features/routines/domain/routine_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.get('routines/')).thenAnswer(
      (_) async => Response(
        data: [],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        achievementsProvider.overrideWith(() => _EmptyAchievementsNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('activeRoutines and archivedRoutines split routines by isActive', () async {
    when(() => mockDio.get('routines/')).thenAnswer(
      (_) async => Response(
        data: [
          {
            'id': 1,
            'name': 'Active',
            'description': '',
            'is_active': true,
            'exercises': [],
          },
          {
            'id': 2,
            'name': 'Archived',
            'description': '',
            'is_active': false,
            'exercises': [],
          },
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await container.read(routineProvider.notifier).fetchRoutines();
    final state = container.read(routineProvider);

    expect(state.routines.length, 2);
    expect(state.activeRoutines.map((r) => r.name), ['Active']);
    expect(state.archivedRoutines.map((r) => r.name), ['Archived']);
  });

  test('duplicateRoutine posts a copy with exercises', () async {
    when(() => mockDio.post('routines/', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'id': 99},
        statusCode: 201,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final routine = Routine(
      id: 1,
      name: 'Leg Day',
      description: 'Piernas',
      isActive: true,
      exercises: [
        RoutineExercise(
          id: 10,
          exerciseId: 101,
          exerciseName: 'Squat',
          muscleGroup: 'piernas',
          order: 0,
          targetSets: 4,
          targetReps: 8,
          targetWeight: 80,
        ),
      ],
    );

    await container.read(routineProvider.notifier).duplicateRoutine(routine);
    final state = container.read(routineProvider);

    expect(state.routines.any((r) => r.id == 99), isTrue);
    verify(
      () => mockDio.post(
        'routines/',
        data: {
          'name': 'Leg Day (copia)',
          'description': 'Piernas',
          'exercises': [
            {
              'exercise': 101,
              'order': 0,
              'target_sets': 4,
              'target_reps': 8,
              'target_weight': 80,
            },
          ],
        },
      ),
    ).called(1);
  });

  test('createRoutineWithExercises appends new routine', () async {
    when(() => mockDio.post('routines/', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'id': 42,
          'name': 'Push',
          'description': 'Pecho',
          'is_active': true,
          'exercises': [],
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final created = await container
        .read(routineProvider.notifier)
        .createRoutineWithExercises('Push', 'Pecho', []);

    expect(created.id, 42);
    expect(container.read(routineProvider).routines.any((r) => r.id == 42), true);
  });

  test('updateRoutine replaces routine in list', () async {
    when(() => mockDio.get('routines/')).thenAnswer(
      (_) async => Response(
        data: [
          {
            'id': 1,
            'name': 'Old',
            'description': '',
            'is_active': true,
            'exercises': [],
          },
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    when(() => mockDio.put('routines/1/', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'id': 1,
          'name': 'Updated',
          'description': 'Nueva',
          'is_active': true,
          'exercises': [],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await container.read(routineProvider.notifier).fetchRoutines();
    await container.read(routineProvider.notifier).updateRoutine(
          1,
          'Updated',
          'Nueva',
          [],
        );

    expect(container.read(routineProvider).routines.first.name, 'Updated');
  });

  test('setRoutineActive archives and restores routine', () async {
    when(() => mockDio.get('routines/')).thenAnswer(
      (_) async => Response(
        data: [
          {
            'id': 1,
            'name': 'Legs',
            'description': '',
            'is_active': true,
            'exercises': [],
          },
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    when(() => mockDio.patch('routines/1/', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await container.read(routineProvider.notifier).fetchRoutines();
    await container.read(routineProvider.notifier).setRoutineActive(1, false);
    expect(container.read(routineProvider).activeRoutines, isEmpty);

    await container.read(routineProvider.notifier).setRoutineActive(1, true);
    expect(container.read(routineProvider).activeRoutines, hasLength(1));
  });

  test('deleteRoutine updates list immediately without refetch', () async {
    when(() => mockDio.get('routines/')).thenAnswer(
      (_) async => Response(
        data: [
          {
            'id': 1,
            'name': 'To delete',
            'description': '',
            'is_active': true,
            'exercises': [],
          },
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    when(() => mockDio.delete(any())).thenAnswer(
      (_) async => Response(
        statusCode: 204,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await container.read(routineProvider.notifier).fetchRoutines();
    await container.read(routineProvider.notifier).deleteRoutine(1);

    expect(container.read(routineProvider).routines, isEmpty);
    verify(() => mockDio.delete('routines/1/')).called(1);
  });
}

class _EmptyAchievementsNotifier extends AchievementsNotifier {
  @override
  AchievementsState build() => const AchievementsState();

  @override
  Future<void> sync({Set<String>? unlockedBaseline}) async {}
}
