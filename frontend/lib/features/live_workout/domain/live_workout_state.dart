import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routines/domain/routine_model.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class WorkoutSetData {
  final String id;
  final String type; // 'warmup', 'normal', 'dropset', 'failure'
  final double weight;
  final int reps;
  final double? rpe;
  final int? rir;
  final bool isCompleted;
  final double? prevWeight;
  final int? prevReps;

  final bool wasModifiedWeight;
  final bool wasModifiedReps;
  final bool wasModifiedRpe;
  final bool wasModifiedRir;

  WorkoutSetData({
    String? id,
    this.type = 'normal',
    this.weight = 0.0,
    this.reps = 0,
    this.rpe,
    this.rir,
    this.isCompleted = false,
    this.prevWeight,
    this.prevReps,
    this.wasModifiedWeight = false,
    this.wasModifiedReps = false,
    this.wasModifiedRpe = false,
    this.wasModifiedRir = false,
  }) : id = id ?? uuid.v4();

  WorkoutSetData copyWith({
    String? id,
    String? type,
    double? weight,
    int? reps,
    double? rpe,
    int? rir,
    bool? isCompleted,
    double? prevWeight,
    int? prevReps,
    bool? wasModifiedWeight,
    bool? wasModifiedReps,
    bool? wasModifiedRpe,
    bool? wasModifiedRir,
  }) {
    return WorkoutSetData(
      id: id ?? this.id,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      isCompleted: isCompleted ?? this.isCompleted,
      prevWeight: prevWeight ?? this.prevWeight,
      prevReps: prevReps ?? this.prevReps,
      wasModifiedWeight: wasModifiedWeight ?? this.wasModifiedWeight,
      wasModifiedReps: wasModifiedReps ?? this.wasModifiedReps,
      wasModifiedRpe: wasModifiedRpe ?? this.wasModifiedRpe,
      wasModifiedRir: wasModifiedRir ?? this.wasModifiedRir,
    );
  }
}

class ActiveExercise {
  final RoutineExercise routineExercise;
  final List<WorkoutSetData> sets;

  ActiveExercise({required this.routineExercise, required this.sets});

  ActiveExercise copyWith({
    RoutineExercise? routineExercise,
    List<WorkoutSetData>? sets,
  }) {
    return ActiveExercise(
      routineExercise: routineExercise ?? this.routineExercise,
      sets: sets ?? this.sets,
    );
  }
}

class LiveWorkoutState {
  final bool isActive;
  final Routine? routine;
  final String sessionName;
  final DateTime? startTime;
  final int elapsedSeconds;
  final List<ActiveExercise> activeExercises;

  // Timer for resting
  final bool isResting;
  final int restSecondsRemaining;

  // Settings
  final bool enableRestTimer;
  final bool enableRpe;
  final bool enableRir;
  final bool isLoading;

  LiveWorkoutState({
    this.isActive = false,
    this.routine,
    this.sessionName = '',
    this.startTime,
    this.elapsedSeconds = 0,
    this.activeExercises = const [],
    this.isResting = false,
    this.restSecondsRemaining = 0,
    this.enableRestTimer = false,
    this.enableRpe = false,
    this.enableRir = false,
    this.isLoading = false,
  });

  LiveWorkoutState copyWith({
    bool? isActive,
    Routine? routine,
    String? sessionName,
    DateTime? startTime,
    int? elapsedSeconds,
    List<ActiveExercise>? activeExercises,
    bool? isResting,
    int? restSecondsRemaining,
    bool? enableRestTimer,
    bool? enableRpe,
    bool? enableRir,
    bool? isLoading,
  }) {
    return LiveWorkoutState(
      isActive: isActive ?? this.isActive,
      routine: routine ?? this.routine,
      sessionName: sessionName ?? this.sessionName,
      startTime: startTime ?? this.startTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      activeExercises: activeExercises ?? this.activeExercises,
      isResting: isResting ?? this.isResting,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      enableRestTimer: enableRestTimer ?? this.enableRestTimer,
      enableRpe: enableRpe ?? this.enableRpe,
      enableRir: enableRir ?? this.enableRir,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
