class Exercise {
  final int id;
  final String name;
  final String muscleGroup;
  final String? equipment;
  final String exerciseType;
  final bool isGlobal;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.equipment,
    required this.exerciseType,
    required this.isGlobal,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      equipment: json['equipment'],
      exerciseType: json['exercise_type'] ?? 'weight_reps',
      isGlobal: json['is_global'] ?? false,
    );
  }
}
