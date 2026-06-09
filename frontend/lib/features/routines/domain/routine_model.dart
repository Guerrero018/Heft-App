class RoutineAuthor {
  final int id;
  final String username;

  const RoutineAuthor({required this.id, required this.username});

  factory RoutineAuthor.fromJson(Map<String, dynamic> json) {
    return RoutineAuthor(
      id: json['id'] as int,
      username: json['username']?.toString() ?? '',
    );
  }
}

class Routine {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final bool isPublic;
  final String? shareCode;
  final int timesImported;
  final List<RoutineExercise> exercises;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    this.isPublic = false,
    this.shareCode,
    this.timesImported = 0,
    required this.exercises,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      isPublic: json['is_public'] == true,
      shareCode: json['share_code']?.toString(),
      timesImported: (json['times_imported'] as num?)?.toInt() ?? 0,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => RoutineExercise.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive,
        'is_public': isPublic,
        if (shareCode != null) 'share_code': shareCode,
        'times_imported': timesImported,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  Routine copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    bool? isPublic,
    String? shareCode,
    int? timesImported,
    List<RoutineExercise>? exercises,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      shareCode: shareCode ?? this.shareCode,
      timesImported: timesImported ?? this.timesImported,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// Plantilla de la biblioteca pública o vista previa por código.
class RoutineTemplate {
  final int id;
  final String name;
  final String description;
  final bool isOfficial;
  final int timesImported;
  final RoutineAuthor author;
  final int exerciseCount;
  final List<RoutineExercise> exercises;

  const RoutineTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.isOfficial,
    required this.timesImported,
    required this.author,
    required this.exerciseCount,
    this.exercises = const [],
  });

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) {
    return RoutineTemplate(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isOfficial: json['is_official'] == true,
      timesImported: (json['times_imported'] as num?)?.toInt() ?? 0,
      author: RoutineAuthor.fromJson(
        Map<String, dynamic>.from(json['author'] as Map),
      ),
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ??
          (json['exercises'] as List?)?.length ??
          0,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => RoutineExercise.fromJson(e))
          .toList(),
    );
  }

  Routine toRoutinePreview() {
    return Routine(
      id: id,
      name: name,
      description: description,
      isActive: true,
      exercises: exercises,
    );
  }
}

class RoutineExercise {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String? externalId;
  final String? gifUrl;
  final int order;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restTimeSeconds;

  RoutineExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.externalId,
    this.gifUrl,
    required this.order,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    this.restTimeSeconds = 60,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      id: json['id'],
      exerciseId: json['exercise'],
      exerciseName: json['exercise_name'] ?? 'Ejercicio',
      muscleGroup: json['muscle_group'] ?? 'Desconocido',
      externalId: json['external_id'],
      gifUrl: json['gif_url'],
      order: json['order'] ?? 0,
      targetSets: json['target_sets'] ?? 0,
      targetReps: json['target_reps'] ?? 0,
      targetWeight: (json['target_weight'] ?? 0.0).toDouble(),
      restTimeSeconds: (json['rest_time_seconds'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
        'external_id': externalId,
        'gif_url': gifUrl,
        'order': order,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_weight': targetWeight,
        'rest_time_seconds': restTimeSeconds,
      };
}
