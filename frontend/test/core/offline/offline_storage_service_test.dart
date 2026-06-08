import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/offline/offline_storage_service.dart';
import 'package:frontend/core/offline/pending_workout_model.dart';
import 'package:frontend/features/live_workout/domain/live_workout_state.dart';
import 'package:frontend/features/routines/domain/routine_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OfflineStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = OfflineStorageService(prefs);
  });

  test('saves and restores active workout draft', () async {
    final state = LiveWorkoutState(
      isActive: true,
      sessionName: 'Push Day',
      startTime: DateTime(2026, 6, 8, 10, 0),
      activeExercises: [
        ActiveExercise(
          routineExercise: RoutineExercise(
            id: 1,
            exerciseId: 10,
            exerciseName: 'Press',
            muscleGroup: 'pecho',
            order: 1,
            targetSets: 3,
            targetReps: 10,
            targetWeight: 60,
          ),
          sets: [
            WorkoutSetData(weight: 60, reps: 10, isCompleted: true),
          ],
        ),
      ],
    );

    await storage.saveActiveWorkoutDraft(state.toJson());
    final restored = storage.readActiveWorkoutDraft();

    expect(restored, isNotNull);
    final parsed = LiveWorkoutState.fromJson(restored!);
    expect(parsed.sessionName, 'Push Day');
    expect(parsed.activeExercises.length, 1);
    expect(parsed.activeExercises.first.sets.first.isCompleted, true);
  });

  test('enqueues and removes pending workouts', () async {
    final workout = PendingWorkout(
      payload: {
        'name': 'Leg Day',
        'sets': [],
      },
    );

    await storage.enqueuePendingWorkout(workout);
    expect(storage.readPendingWorkouts().length, 1);

    await storage.removePendingWorkout(workout.localId);
    expect(storage.readPendingWorkouts(), isEmpty);
  });
}
