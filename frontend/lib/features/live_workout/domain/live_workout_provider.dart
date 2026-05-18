import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routines/domain/routine_model.dart';
import '../../../core/api/api_client.dart';
import '../../workouts/data/workout_provider.dart';
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

  Dio get _api => ref.read(apiClientProvider);

  Future<void> startWorkout(Routine? routine, {String? sessionName}) async {
    if (state.isActive || state.isLoading) return;

    // Set loading state immediately
    state = state.copyWith(
      isActive: true, 
      isLoading: true,
      routine: routine,
      sessionName: sessionName ?? (routine != null ? routine.name : 'Entrenamiento Rápido'),
    );

    List<ActiveExercise> activeExercises = [];
    
    if (routine != null) {
      // Fetch previous session for this routine to get "ghost" values
      Map<int, List<Map<String, dynamic>>> previousData = {};
      try {
        final response = await _api.get(
          'workouts/',
          queryParameters: {
            'routine': routine.id,
            'limit': 1,
            'ordering': '-start_time',
          },
        );
        
        if (response.data != null && (response.data as List).isNotEmpty) {
          final lastSession = response.data[0];
          final List setsList = lastSession['sets'] ?? [];
          for (var setData in setsList) {
            final exId = setData['exercise'];
            if (exId != null) {
              previousData.putIfAbsent(exId, () => []).add(setData);
            }
          }
        }
      } catch (e) {
        print('Error fetching previous session: $e');
      }

      // Map routine exercises to active exercises
      activeExercises = routine.exercises.map((routineEx) {
        final prevSets = previousData[routineEx.exerciseId];
        
        return ActiveExercise(
          routineExercise: routineEx,
          sets: List.generate(
            routineEx.targetSets,
            (index) {
              double? prevW;
              int? prevR;
              
              if (prevSets != null && index < prevSets.length) {
                prevW = double.tryParse(prevSets[index]['weight'].toString());
                prevR = int.tryParse(prevSets[index]['reps'].toString());
              }

              return WorkoutSetData(
                weight: routineEx.targetWeight,
                reps: routineEx.targetReps,
                type: 'normal',
                prevWeight: prevW,
                prevReps: prevR,
                wasModifiedWeight: false,
                wasModifiedReps: false,
              );
            },
          ),
        );
      }).toList();
    }

    state = state.copyWith(
      isLoading: false,
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

  void removeExercise(int index) {
    if (!state.isActive || index < 0 || index >= state.activeExercises.length) return;
    
    final newList = List<ActiveExercise>.from(state.activeExercises)..removeAt(index);
    state = state.copyWith(activeExercises: newList);
  }

  void replaceExercise(int index, RoutineExercise newExercise) {
    if (!state.isActive || index < 0 || index >= state.activeExercises.length) return;
    
    final newActiveExercise = ActiveExercise(
      routineExercise: newExercise,
      sets: [WorkoutSetData()], // Reset sets for the new exercise
    );
    
    final newList = List<ActiveExercise>.from(state.activeExercises);
    newList[index] = newActiveExercise;
    state = state.copyWith(activeExercises: newList);
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (!state.isActive) return;
    
    final newList = List<ActiveExercise>.from(state.activeExercises);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    
    state = state.copyWith(activeExercises: newList);
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

    // Check if there is previous data for this specific set index
    double? prevW;
    int? prevR;
    
    // We would need to store the raw previous data in the state to access it here, 
    // or just assume we don't have it for manually added sets beyond the initial ones.
    // For now, let's just keep it simple. If we wanted to be perfect, we'd store the previousData Map in the state.

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

  void updateSet(int exerciseIndex, String setId, {double? weight, int? reps, String? type, double? rpe, int? rir}) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    final updatedSets = exercise.sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          weight: weight,
          reps: reps,
          type: type,
          rpe: rpe,
          rir: rir,
          wasModifiedWeight: weight != null ? true : set.wasModifiedWeight,
          wasModifiedReps: reps != null ? true : set.wasModifiedReps,
          wasModifiedRpe: rpe != null ? true : set.wasModifiedRpe,
          wasModifiedRir: rir != null ? true : set.wasModifiedRir,
          // Auto-complete if rest timer is disabled and reps were provided
          isCompleted: (!state.enableRestTimer && reps != null) ? true : set.isCompleted,
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

  void removeLastSet(int exerciseIndex) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    if (exercise.sets.length <= 1) return;

    final updatedSets = List<WorkoutSetData>.from(exercise.sets)..removeLast();

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
    if (!wasCompletedBefore && isCompletedNow && state.enableRestTimer) {
      // Note: Here we would get the rest_time_seconds from the model's routine if we had added it to the frontend!
      // For now, default to 90 seconds. We can update this when syncing the new model fields. 
      _startRestTimer(90);
    }
  }

  void toggleRestTimer(bool enabled) {
    state = state.copyWith(enableRestTimer: enabled);
    // If we are currently resting and disable the timer, stop it
    if (!enabled && state.isResting) {
      stopRestTimer();
    }
  }

  void toggleRpe(bool enabled) {
    state = state.copyWith(enableRpe: enabled);
  }

  void toggleRir(bool enabled) {
    state = state.copyWith(enableRir: enabled);
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

  Future<bool> finishWorkout() async {
    if (!state.isActive) return false;

    final endTime = DateTime.now();
    
    // Stop timers immediately and set state as not active
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    final savedState = state; // Keep a copy for the API call
    state = state.copyWith(isActive: false, isLoading: true); // Show loading while saving

    // Prepare the sets data (ONLY completed sets)
    final List<Map<String, dynamic>> sets = [];
    for (var activeExercise in savedState.activeExercises) {
      for (int i = 0; i < activeExercise.sets.length; i++) {
        final setData = activeExercise.sets[i];
        if (setData.isCompleted) {
          sets.add({
            'exercise': activeExercise.routineExercise.exerciseId,
            'set_number': sets.length + 1, // Re-index to be sequential
            'set_type': setData.type,
            'weight': setData.weight,
            'reps': setData.reps,
            'rpe': setData.rpe?.round(),
            'rir': setData.rir,
            'is_completed': true,
          });
        }
      }
    }

    try {
      print('DEBUG: Finishing workout. Start: ${savedState.startTime}, End: $endTime');
      final response = await _api.post('workouts/', data: {
        'routine': savedState.routine?.id,
        'name': savedState.sessionName,
        'start_time': savedState.startTime?.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'is_completed': true,
        'sets': sets,
      });
      
      print('Workout saved successfully: ${response.data}');
      
      // Refresh history immediately so the new workout appears at the top
      ref.read(workoutHistoryProvider.notifier).fetchWorkouts();
      
      state = LiveWorkoutState(); // Reset state
      return true;
    } catch (e) {
      print('Error finishing workout: $e');
      state = LiveWorkoutState();
      return false;
    }
  }

  void cancelWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    state = LiveWorkoutState();
  }
}
