import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routines/domain/routine_model.dart';
import 'live_workout_state.dart';

final liveWorkoutProvider = NotifierProvider<LiveWorkoutNotifier, LiveWorkoutState>(() {
  return LiveWorkoutNotifier();
});

class LiveWorkoutNotifier extends Notifier<LiveWorkoutState> {
  Timer? _workoutTimer;
  Timer? _restTimer;

  @override
  LiveWorkoutState build() {
    return LiveWorkoutState();
  }

  void startWorkout(Routine? routine, {String? sessionName}) {
    if (state.isActive) return;

    List<ActiveExercise> activeExercises = [];
    
    if (routine != null) {
      // Map routine exercises to active exercises
      activeExercises = routine.exercises.map((routineEx) {
        return ActiveExercise(
          routineExercise: routineEx,
          sets: List.generate(
            routineEx.targetSets,
            (index) => WorkoutSetData(
              weight: routineEx.targetWeight,
              reps: routineEx.targetReps,
              type: 'normal',
            ),
          ),
        );
      }).toList();
    }

    state = state.copyWith(
      isActive: true,
      routine: routine,
      sessionName: sessionName ?? (routine != null ? routine.name : 'Entrenamiento Rápido'),
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      activeExercises: activeExercises,
      isResting: false,
      restSecondsRemaining: 0,
    );

    _startWorkoutTimer();
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isActive) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      } else {
        timer.cancel();
      }
    });
  }

  void addExercise(RoutineExercise exercise) {
    if (!state.isActive) return;
    
    final newActiveExercise = ActiveExercise(
      routineExercise: exercise,
      sets: [WorkoutSetData()],
    );
    
    state = state.copyWith(
      activeExercises: [...state.activeExercises, newActiveExercise],
    );
  }

  void addSet(int exerciseIndex) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    
    // Copy the last set's weight and reps as a template
    double templateWeight = 0;
    int templateReps = 0;
    
    if (exercise.sets.isNotEmpty) {
      final lastSet = exercise.sets.last;
      templateWeight = lastSet.weight;
      templateReps = lastSet.reps;
    }

    final newSet = WorkoutSetData(
      weight: templateWeight,
      reps: templateReps,
      type: 'normal',
    );

    final updatedExercise = exercise.copyWith(
      sets: [...exercise.sets, newSet],
    );

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(activeExercises: newExercises);
  }

  void updateSet(int exerciseIndex, String setId, {double? weight, int? reps, String? type, double? rpe}) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    final updatedSets = exercise.sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          weight: weight,
          reps: reps,
          type: type,
          rpe: rpe,
        );
      }
      return set;
    }).toList();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(activeExercises: newExercises);
  }

  void removeSet(int exerciseIndex, String setId) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    // Don't remove the last set
    if (exercise.sets.length <= 1) return;

    final updatedSets = exercise.sets.where((set) => set.id != setId).toList();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(activeExercises: newExercises);
  }

  void toggleSetComplete(int exerciseIndex, String setId) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    bool wasCompletedBefore = false;
    bool isCompletedNow = false;

    final updatedSets = exercise.sets.map((set) {
      if (set.id == setId) {
        wasCompletedBefore = set.isCompleted;
        isCompletedNow = !set.isCompleted;
        return set.copyWith(isCompleted: isCompletedNow);
      }
      return set;
    }).toList();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(activeExercises: newExercises);

    // If it was just marked as completed (and wasn't before), trigger rest timer
    if (!wasCompletedBefore && isCompletedNow) {
      // Note: Here we would get the rest_time_seconds from the model's routine if we had added it to the frontend!
      // For now, default to 90 seconds. We can update this when syncing the new model fields. 
      _startRestTimer(90);
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(isResting: true, restSecondsRemaining: seconds);
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restSecondsRemaining > 1) {
        state = state.copyWith(restSecondsRemaining: state.restSecondsRemaining - 1);
      } else {
        stopRestTimer();
      }
    });
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restSecondsRemaining: 0);
  }

  void adjustRestTimer(int secondsDelta) {
    if (!state.isResting) return;
    final newValue = state.restSecondsRemaining + secondsDelta;
    if (newValue <= 0) {
      stopRestTimer();
    } else {
      state = state.copyWith(restSecondsRemaining: newValue);
    }
  }

  Future<void> finishWorkout() async {
    if (!state.isActive) return;

    _workoutTimer?.cancel();
    _restTimer?.cancel();

    // TODO: Send data to the backend API via Workout repository

    state = LiveWorkoutState(); // Reset state
  }

  void cancelWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    state = LiveWorkoutState();
  }
}
