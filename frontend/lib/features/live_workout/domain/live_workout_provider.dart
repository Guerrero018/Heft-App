import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routines/domain/routine_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/offline/connectivity_provider.dart';
import '../../../core/offline/offline_storage_service.dart';
import '../../../core/offline/offline_sync_provider.dart';
import '../../achievements/data/achievements_provider.dart';
import '../../statistics/data/statistics_provider.dart';
import '../../workouts/data/workout_provider.dart';
import 'live_workout_state.dart';

final liveWorkoutProvider = NotifierProvider<LiveWorkoutNotifier, LiveWorkoutState>(() {
  return LiveWorkoutNotifier();
});

class LiveWorkoutNotifier extends Notifier<LiveWorkoutState> {
  Timer? _workoutTimer;
  Timer? _restTimer;
  Timer? _persistDebounce;
  OfflineStorageService? _storage;
  bool _draftRestored = false;

  @override
  LiveWorkoutState build() {
    Future.microtask(_restoreDraftIfNeeded);
    return LiveWorkoutState();
  }

  Dio get _api => ref.read(apiClientProvider);

  Future<OfflineStorageService> _getStorage() async {
    if (_storage != null) return _storage!;
    _storage = await ref.read(offlineStorageServiceProvider.future);
    return _storage!;
  }

  Future<void> _restoreDraftIfNeeded() async {
    if (_draftRestored || state.isActive) return;
    _draftRestored = true;

    final storage = await _getStorage();
    final draft = storage.readActiveWorkoutDraft();
    if (draft == null) return;

    try {
      final restored = LiveWorkoutState.fromJson(draft);
      if (!restored.isActive || restored.startTime == null) {
        await storage.clearActiveWorkoutDraft();
        return;
      }

      final elapsed = DateTime.now().difference(restored.startTime!).inSeconds;
      state = restored.copyWith(
        elapsedSeconds: elapsed.clamp(0, 86400),
        isResting: false,
        restSecondsRemaining: 0,
        isLoading: false,
      );
      _startWorkoutTimer();
    } catch (e) {
      print('Error restoring workout draft: $e');
      await storage.clearActiveWorkoutDraft();
    }
  }

  void _schedulePersistDraft() {
    if (!state.isActive) return;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    if (!state.isActive) return;
    try {
      final storage = await _getStorage();
      await storage.saveActiveWorkoutDraft(state.toJson());
    } catch (e) {
      print('Error persisting workout draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    _persistDebounce?.cancel();
    try {
      final storage = await _getStorage();
      await storage.clearActiveWorkoutDraft();
    } catch (e) {
      print('Error clearing workout draft: $e');
    }
  }

  void _commitState(LiveWorkoutState newState) {
    state = newState;
    _schedulePersistDraft();
  }

  Future<void> startWorkout(Routine? routine, {String? sessionName}) async {
    if (state.isActive || state.isLoading) return;

    state = state.copyWith(
      isActive: true,
      isLoading: true,
      routine: routine,
      sessionName: sessionName ?? (routine != null ? routine.name : 'Entrenamiento Rápido'),
    );

    List<ActiveExercise> activeExercises = [];

    if (routine != null) {
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

    _commitState(state.copyWith(
      isLoading: false,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      activeExercises: activeExercises,
      isResting: false,
      restSecondsRemaining: 0,
    ));

    _startWorkoutTimer();
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isActive) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
        if (state.elapsedSeconds % 10 == 0) {
          _schedulePersistDraft();
        }
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

    _commitState(state.copyWith(
      activeExercises: [...state.activeExercises, newActiveExercise],
    ));
  }

  void removeExercise(int index) {
    if (!state.isActive || index < 0 || index >= state.activeExercises.length) return;

    final newList = List<ActiveExercise>.from(state.activeExercises)..removeAt(index);
    _commitState(state.copyWith(activeExercises: newList));
  }

  void replaceExercise(int index, RoutineExercise newExercise) {
    if (!state.isActive || index < 0 || index >= state.activeExercises.length) return;

    final newActiveExercise = ActiveExercise(
      routineExercise: newExercise,
      sets: [WorkoutSetData()],
    );

    final newList = List<ActiveExercise>.from(state.activeExercises);
    newList[index] = newActiveExercise;
    _commitState(state.copyWith(activeExercises: newList));
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (!state.isActive) return;

    final newList = List<ActiveExercise>.from(state.activeExercises);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);

    _commitState(state.copyWith(activeExercises: newList));
  }

  void addSet(int exerciseIndex) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];

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

    _commitState(state.copyWith(activeExercises: newExercises));
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
          isCompleted: (!state.enableRestTimer && reps != null) ? true : set.isCompleted,
        );
      }
      return set;
    }).toList();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    _commitState(state.copyWith(activeExercises: newExercises));
  }

  void removeSet(int exerciseIndex, String setId) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    if (exercise.sets.length <= 1) return;

    final updatedSets = exercise.sets.where((set) => set.id != setId).toList();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    _commitState(state.copyWith(activeExercises: newExercises));
  }

  void removeLastSet(int exerciseIndex) {
    if (!state.isActive || exerciseIndex >= state.activeExercises.length) return;

    final exercise = state.activeExercises[exerciseIndex];
    if (exercise.sets.length <= 1) return;

    final updatedSets = List<WorkoutSetData>.from(exercise.sets)..removeLast();

    final newExercises = List<ActiveExercise>.from(state.activeExercises);
    newExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    _commitState(state.copyWith(activeExercises: newExercises));
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

    _commitState(state.copyWith(activeExercises: newExercises));

    if (!wasCompletedBefore && isCompletedNow && state.enableRestTimer) {
      _startRestTimer(90);
    }
  }

  void toggleRestTimer(bool enabled) {
    _commitState(state.copyWith(enableRestTimer: enabled));
    if (!enabled && state.isResting) {
      stopRestTimer();
    }
  }

  void toggleRpe(bool enabled) {
    _commitState(state.copyWith(enableRpe: enabled));
  }

  void toggleRir(bool enabled) {
    _commitState(state.copyWith(enableRir: enabled));
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

  List<Map<String, dynamic>> _buildCompletedSetsPayload(LiveWorkoutState savedState) {
    final List<Map<String, dynamic>> sets = [];
    for (var activeExercise in savedState.activeExercises) {
      for (final setData in activeExercise.sets) {
        if (setData.isCompleted) {
          sets.add({
            'exercise': activeExercise.routineExercise.exerciseId,
            'set_number': sets.length + 1,
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
    return sets;
  }

  Map<String, dynamic> _buildWorkoutPayload(
    LiveWorkoutState savedState,
    DateTime endTime,
    List<Map<String, dynamic>> sets,
  ) {
    return {
      'routine': savedState.routine?.id,
      'name': savedState.sessionName,
      'start_time': savedState.startTime?.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_completed': true,
      'sets': sets,
    };
  }

  bool _isNetworkError(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  bool _isRetryableError(Object error) {
    if (_isNetworkError(error)) return true;
    if (error is DioException) {
      final code = error.response?.statusCode;
      return code != null && code >= 500;
    }
    return false;
  }

  Future<void> _postWorkoutWithRetry(
    Map<String, dynamic> payload, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _api.post('workouts/', data: payload);
        return;
      } catch (e) {
        lastError = e;
        if (!_isRetryableError(e) || attempt == maxAttempts) {
          throw e;
        }
        await Future.delayed(Duration(milliseconds: 350 * attempt));
      }
    }
    if (lastError != null) throw lastError;
  }

  void _syncAfterWorkoutSaved(Set<String> unlockedBaseline) {
    ref.read(workoutHistoryProvider.notifier).fetchWorkouts();
    ref.invalidate(statisticsProvider);
    unawaited(
      ref.read(achievementsProvider.notifier).sync(
            unlockedBaseline: unlockedBaseline,
          ),
    );
  }

  Future<FinishWorkoutResult> finishWorkout() async {
    if (!state.isActive) return FinishWorkoutResult.failed;

    final endTime = DateTime.now();

    _workoutTimer?.cancel();
    _restTimer?.cancel();
    final savedState = state;
    state = state.copyWith(isActive: false, isLoading: true);

    final sets = _buildCompletedSetsPayload(savedState);
    if (sets.isEmpty) {
      state = savedState.copyWith(isActive: true, isLoading: false);
      _startWorkoutTimer();
      return FinishWorkoutResult.noCompletedSets;
    }

    final payload = _buildWorkoutPayload(savedState, endTime, sets);
    final unlockedBaseline = {
      for (final a in ref.read(achievementsProvider).achievements)
        if (a.isUnlocked) a.id,
    };

    final isOnline = ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        await _postWorkoutWithRetry(payload);
        _syncAfterWorkoutSaved(unlockedBaseline);
        await _clearDraft();
        state = LiveWorkoutState();
        return FinishWorkoutResult.success;
      } catch (e) {
        print('Error finishing workout online: $e');
        if (!_isRetryableError(e)) {
          state = savedState.copyWith(isActive: true, isLoading: false);
          _startWorkoutTimer();
          return FinishWorkoutResult.failedRetryable;
        }
      }
    }

    try {
      await ref.read(offlineSyncProvider.notifier).enqueueWorkout(payload);
      await _clearDraft();
      state = LiveWorkoutState();
      return FinishWorkoutResult.savedOffline;
    } catch (e) {
      print('Error saving workout offline: $e');
      state = savedState.copyWith(isActive: true, isLoading: false);
      _startWorkoutTimer();
      return FinishWorkoutResult.failedRetryable;
    }
  }

  void cancelWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    unawaited(_clearDraft());
    state = LiveWorkoutState();
  }
}
