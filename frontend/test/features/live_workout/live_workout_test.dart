import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/live_workout/domain/live_workout_provider.dart';
import 'package:frontend/features/live_workout/domain/live_workout_state.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/offline/connectivity_provider.dart';
import 'package:frontend/core/offline/offline_storage_service.dart';
import 'package:frontend/features/routines/domain/routine_model.dart';

class MockDio extends Mock implements Dio {}

class OnlineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() =>
      const ConnectivityState(hasNetworkInterface: true, isOnline: true);
}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = OfflineStorageService(prefs);

    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        connectivityProvider.overrideWith(OnlineConnectivity.new),
        offlineStorageServiceProvider.overrideWith((ref) async => storage),
      ],
    );

    // Default mock for previous sessions
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

  test('Initial state has rest timer and RPE disabled', () {
    final state = container.read(liveWorkoutProvider);
    expect(state.enableRestTimer, false);
    expect(state.enableRpe, false);
    expect(state.isActive, false);
  });

  test('Toggling RPE updates state', () {
    final notifier = container.read(liveWorkoutProvider.notifier);
    
    notifier.toggleRpe(true);
    expect(container.read(liveWorkoutProvider).enableRpe, true);
    
    notifier.toggleRpe(false);
    expect(container.read(liveWorkoutProvider).enableRpe, false);
  });

  test('Toggling RIR updates state', () {
    final notifier = container.read(liveWorkoutProvider.notifier);
    
    notifier.toggleRir(true);
    expect(container.read(liveWorkoutProvider).enableRir, true);
    
    notifier.toggleRir(false);
    expect(container.read(liveWorkoutProvider).enableRir, false);
  });

  test('Toggling rest timer updates state', () {
    final notifier = container.read(liveWorkoutProvider.notifier);
    
    notifier.toggleRestTimer(true);
    expect(container.read(liveWorkoutProvider).enableRestTimer, true);
    
    notifier.toggleRestTimer(false);
    expect(container.read(liveWorkoutProvider).enableRestTimer, false);
  });

  test('Adding and updating sets works correctly', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    
    await notifier.startWorkout(null, sessionName: 'Test Workout');
    
    final exercise = RoutineExercise(
      id: 1,
      exerciseId: 101,
      exerciseName: 'Squat',
      muscleGroup: 'Legs',
      order: 1,
      targetSets: 3,
      targetReps: 10,
      targetWeight: 60,
    );
    
    notifier.addExercise(exercise);
    
    var state = container.read(liveWorkoutProvider);
    expect(state.activeExercises.length, 1);
    expect(state.activeExercises[0].sets.length, 1);
    
    final setId = state.activeExercises[0].sets[0].id;
    notifier.updateSet(0, setId, weight: 70, reps: 12);
    
    state = container.read(liveWorkoutProvider);
    expect(state.activeExercises[0].sets[0].weight, 70);
    expect(state.activeExercises[0].sets[0].reps, 12);
    expect(state.activeExercises[0].sets[0].wasModifiedWeight, true);
  });

  test('Auto-complete works when rest timer is disabled', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);
    notifier.toggleRestTimer(false);
    
    final exercise = RoutineExercise(
      id: 1,
      exerciseId: 101,
      exerciseName: 'Push Up',
      muscleGroup: 'Chest',
      order: 1,
      targetSets: 1,
      targetReps: 10,
      targetWeight: 0,
    );
    notifier.addExercise(exercise);
    
    final setId = container.read(liveWorkoutProvider).activeExercises[0].sets[0].id;
    
    // Update reps should trigger auto-complete
    notifier.updateSet(0, setId, reps: 15);
    
    expect(container.read(liveWorkoutProvider).activeExercises[0].sets[0].isCompleted, true);
  });

  test('Finish workout sends only completed sets', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);
    
    final exercise = RoutineExercise(
      id: 1,
      exerciseId: 101,
      exerciseName: 'Curl',
      muscleGroup: 'Biceps',
      order: 1,
      targetSets: 2,
      targetReps: 10,
      targetWeight: 15,
    );
    notifier.addExercise(exercise);
    notifier.addSet(0); // Total 2 sets
    
    final stateBefore = container.read(liveWorkoutProvider);
    final set1Id = stateBefore.activeExercises[0].sets[0].id;
    final set2Id = stateBefore.activeExercises[0].sets[1].id;
    
    // Complete only set 1
    // Note: Since rest timer is disabled by default, updateSet with reps will auto-complete it
    notifier.updateSet(0, set1Id, reps: 10, weight: 15);
    
    // Set 2 remains incomplete
    
    // Mock successful post
    when(() => mockDio.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
          data: {'id': 1},
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        ));
        
    final result = await notifier.finishWorkout();
    expect(result, FinishWorkoutResult.success);
    
    // Verify that only 1 set was sent to the server
    verify(() => mockDio.post(
      'workouts/',
      data: any(named: 'data', that: isA<Map>().having(
        (m) => (m['sets'] as List).length,
        'number of sets',
        1,
      )),
    )).called(1);
    
    // Verify state reset
    expect(container.read(liveWorkoutProvider).isActive, false);
  });

  test('Removing an exercise updates state correctly', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);
    
    final ex1 = RoutineExercise(id: 1, exerciseId: 101, exerciseName: 'A', muscleGroup: 'M', order: 1, targetSets: 1, targetReps: 1, targetWeight: 1);
    final ex2 = RoutineExercise(id: 2, exerciseId: 102, exerciseName: 'B', muscleGroup: 'M', order: 2, targetSets: 1, targetReps: 1, targetWeight: 1);
    
    notifier.addExercise(ex1);
    notifier.addExercise(ex2);
    expect(container.read(liveWorkoutProvider).activeExercises.length, 2);
    
    notifier.removeExercise(0); // Remove first
    expect(container.read(liveWorkoutProvider).activeExercises.length, 1);
    expect(container.read(liveWorkoutProvider).activeExercises[0].routineExercise.exerciseName, 'B');
  });

  test('Replacing an exercise updates state and resets sets', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);
    
    final ex1 = RoutineExercise(id: 1, exerciseId: 101, exerciseName: 'Old', muscleGroup: 'M', order: 1, targetSets: 3, targetReps: 10, targetWeight: 20);
    notifier.addExercise(ex1);
    
    final ex2 = RoutineExercise(id: 2, exerciseId: 102, exerciseName: 'New', muscleGroup: 'M', order: 1, targetSets: 1, targetReps: 5, targetWeight: 10);
    notifier.replaceExercise(0, ex2);
    
    final state = container.read(liveWorkoutProvider);
    expect(state.activeExercises[0].routineExercise.exerciseName, 'New');
    // Note: our implementation resets sets to [WorkoutSetData()]
    expect(state.activeExercises[0].sets.length, 1);
  });

  test('Reordering exercises updates their position', () async {
    final notifier = container.read(liveWorkoutProvider.notifier);
    await notifier.startWorkout(null);
    
    final ex1 = RoutineExercise(id: 1, exerciseId: 101, exerciseName: 'First', muscleGroup: 'M', order: 1, targetSets: 1, targetReps: 1, targetWeight: 1);
    final ex2 = RoutineExercise(id: 2, exerciseId: 102, exerciseName: 'Second', muscleGroup: 'M', order: 2, targetSets: 1, targetReps: 1, targetWeight: 1);
    
    notifier.addExercise(ex1);
    notifier.addExercise(ex2);
    
    // Swap 0 and 1
    // oldIndex = 0, newIndex = 2 (in ReorderableListView, moving 0 to the end means newIndex is 2)
    notifier.reorderExercises(0, 2);
    
    final state = container.read(liveWorkoutProvider);
    expect(state.activeExercises[0].routineExercise.exerciseName, 'Second');
    expect(state.activeExercises[1].routineExercise.exerciseName, 'First');
  });
}
