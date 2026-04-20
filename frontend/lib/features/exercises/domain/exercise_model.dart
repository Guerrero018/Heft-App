class Exercise {
  final int id;
  final String? externalId;
  final String name;
  final String description;
  final List<String> instructions;
  final String muscleGroup;
  final String? target;
  final List<String> secondaryMuscles;
  final String? equipment;
  final String? difficulty;
  final String? category;
  final String? gifUrl;
  final String exerciseType;
  final bool isGlobal;

  Exercise({
    required this.id,
    this.externalId,
    required this.name,
    this.description = '',
    this.instructions = const [],
    required this.muscleGroup,
    this.target,
    this.secondaryMuscles = const [],
    this.equipment,
    this.difficulty,
    this.category,
    this.gifUrl,
    required this.exerciseType,
    required this.isGlobal,
  });

  // Getter para compatibilidad con la pantalla de detalle
  String? get effectiveGifUrl => gifUrl;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      externalId: json['external_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructions: List<String>.from(json['instructions'] ?? []),
      muscleGroup: json['muscle_group'] ?? '',
      target: json['target'],
      secondaryMuscles: List<String>.from(json['secondary_muscles'] ?? []),
      equipment: json['equipment'],
      difficulty: json['difficulty'],
      category: json['category'],
      gifUrl: json['gif_url'],
      exerciseType: json['exercise_type'] ?? 'otro',
      isGlobal: json['is_global'] ?? false,
    );
  }
}
