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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'rir': rir,
        'is_completed': isCompleted,
        'prev_weight': prevWeight,
        'prev_reps': prevReps,
        'was_modified_weight': wasModifiedWeight,
        'was_modified_reps': wasModifiedReps,
        'was_modified_rpe': wasModifiedRpe,
        'was_modified_rir': wasModifiedRir,
      };

  factory WorkoutSetData.fromJson(Map<String, dynamic> json) {
    return WorkoutSetData(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'normal',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      rpe: (json['rpe'] as num?)?.toDouble(),
      rir: json['rir'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      prevWeight: (json['prev_weight'] as num?)?.toDouble(),
      prevReps: json['prev_reps'] as int?,
      wasModifiedWeight: json['was_modified_weight'] as bool? ?? false,
      wasModifiedReps: json['was_modified_reps'] as bool? ?? false,
      wasModifiedRpe: json['was_modified_rpe'] as bool? ?? false,
      wasModifiedRir: json['was_modified_rir'] as bool? ?? false,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'routine_exercise': routineExercise.toJson(),
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ActiveExercise.fromJson(Map<String, dynamic> json) {
    return ActiveExercise(
      routineExercise: RoutineExercise.fromJson(
        Map<String, dynamic>.from(json['routine_exercise'] as Map),
      ),
      sets: (json['sets'] as List? ?? [])
          .map((s) => WorkoutSetData.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
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

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'routine': routine?.toJson(),
        'session_name': sessionName,
        'start_time': startTime?.toUtc().toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
        'active_exercises': activeExercises.map((e) => e.toJson()).toList(),
        'is_resting': isResting,
        'rest_seconds_remaining': restSecondsRemaining,
        'enable_rest_timer': enableRestTimer,
        'enable_rpe': enableRpe,
        'enable_rir': enableRir,
        'is_loading': isLoading,
      };

  factory LiveWorkoutState.fromJson(Map<String, dynamic> json) {
    return LiveWorkoutState(
      isActive: json['is_active'] as bool? ?? false,
      routine: json['routine'] != null
          ? Routine.fromJson(Map<String, dynamic>.from(json['routine'] as Map))
          : null,
      sessionName: json['session_name'] as String? ?? '',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String).toLocal()
          : null,
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
      activeExercises: (json['active_exercises'] as List? ?? [])
          .map((e) => ActiveExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isResting: json['is_resting'] as bool? ?? false,
      restSecondsRemaining: json['rest_seconds_remaining'] as int? ?? 0,
      enableRestTimer: json['enable_rest_timer'] as bool? ?? false,
      enableRpe: json['enable_rpe'] as bool? ?? false,
      enableRir: json['enable_rir'] as bool? ?? false,
      isLoading: json['is_loading'] as bool? ?? false,
    );
  }
}

enum FinishWorkoutResult {
  success,
  savedOffline,
  noCompletedSets,
  failed,
}
