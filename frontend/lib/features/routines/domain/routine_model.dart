class Routine {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final List<RoutineExercise> exercises;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.exercises,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => RoutineExercise.fromJson(e))
          .toList(),
    );
  }
}

class RoutineExercise {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int order;
  final int targetSets;
  final int targetReps;
  final double targetWeight;

  RoutineExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.order,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      id: json['id'],
      exerciseId: json['exercise'],
      exerciseName: json['exercise_name'] ?? 'Ejercicio',
      muscleGroup: json['muscle_group'] ?? 'Desconocido',
      order: json['order'] ?? 0,
      targetSets: json['target_sets'] ?? 0,
      targetReps: json['target_reps'] ?? 0,
      targetWeight: (json['target_weight'] ?? 0.0).toDouble(),
    );
  }
}
