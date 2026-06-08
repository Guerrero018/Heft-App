import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/offline/connectivity_provider.dart';
import 'package:frontend/core/offline/offline_storage_service.dart';
import 'package:frontend/core/offline/offline_sync_provider.dart';
import 'package:frontend/features/live_workout/domain/live_workout_provider.dart';
import 'package:frontend/features/live_workout/domain/live_workout_state.dart';
import 'package:frontend/features/routines/domain/routine_model.dart';

class MockDio extends Mock implements Dio {}

class OfflineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() =>
      const ConnectivityState(hasNetworkInterface: false, isOnline: false);
}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;
  late OfflineStorageService storage;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = OfflineStorageService(prefs);

    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        connectivityProvider.overrideWith(OfflineConnectivity.new),
        offlineStorageServiceProvider.overrideWith((ref) async => storage),
      ],
    );

    when(() => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));
  });

  tearDown(() {
    container.dispose();
  });

  test('finishWorkout without connection saves to pending queue', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);

    final exercise = RoutineExercise(
      id: 1,
      exerciseId: 101,
      exerciseName: 'Curl',
      muscleGroup: 'Biceps',
      order: 1,
      targetSets: 1,
      targetReps: 10,
      targetWeight: 15,
    );
    notifier.addExercise(exercise);

    final setId =
        container.read(liveWorkoutProvider).activeExercises[0].sets[0].id;
    notifier.updateSet(0, setId, reps: 10, weight: 15);

    final result = await notifier.finishWorkout();

    expect(result, FinishWorkoutResult.savedOffline);
    expect(container.read(liveWorkoutProvider).isActive, false);
    expect(storage.readPendingWorkouts().length, 1);
    expect(
      container.read(offlineSyncProvider).pendingCount,
      1,
    );
    verifyNever(() => mockDio.post(any(), data: any(named: 'data')));
  });

  test('finishWorkout with no completed sets keeps session active', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);

    final exercise = RoutineExercise(
      id: 1,
      exerciseId: 101,
      exerciseName: 'Curl',
      muscleGroup: 'Biceps',
      order: 1,
      targetSets: 1,
      targetReps: 10,
      targetWeight: 15,
    );
    notifier.addExercise(exercise);

    final result = await notifier.finishWorkout();

    expect(result, FinishWorkoutResult.noCompletedSets);
    expect(container.read(liveWorkoutProvider).isActive, true);
    expect(storage.readPendingWorkouts(), isEmpty);
  });
}
