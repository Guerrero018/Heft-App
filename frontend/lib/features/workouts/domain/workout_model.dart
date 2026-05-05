class WorkoutSet {
  final int? id;
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final String setType;
  final double weight;
  final int reps;
  final int? rpe;
  final int? rir;
  final bool isCompleted;

  WorkoutSet({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.setType,
    required this.weight,
    required this.reps,
    this.rpe,
    this.rir,
    this.isCompleted = false,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'],
      exerciseId: json['exercise'],
      exerciseName: json['exercise_name'] ?? '',
      setNumber: json['set_number'] ?? 0,
      setType: json['set_type'] ?? 'normal',
      weight: (json['weight'] ?? 0).toDouble(),
      reps: json['reps'] ?? 0,
      rpe: json['rpe'],
      rir: json['rir'],
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class WorkoutSession {
  final int? id;
  final int? routineId;
  final String? routineName;
  final String name;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final String notes;
  final bool isCompleted;
  final List<WorkoutSet> sets;

  WorkoutSession({
    this.id,
    this.routineId,
    this.routineName,
    required this.name,
    required this.date,
    required this.startTime,
    this.endTime,
    this.notes = '',
    this.isCompleted = false,
    this.sets = const [],
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      routineId: json['routine'],
      routineName: json['routine_name'],
      name: json['name'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      notes: json['notes'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      sets: (json['sets'] as List? ?? [])
          .map((s) => WorkoutSet.fromJson(s))
          .toList(),
    );
  }

  // Helper method to calculate total volume
  double get totalVolume {
    return sets.fold(0, (sum, item) => sum + (item.weight * item.reps));
  }

  // Helper method to get unique exercise count
  int get uniqueExercisesCount {
    return sets.map((s) => s.exerciseId).toSet().length;
  }

  // Helper method to format duration
  String get duration {
    if (endTime == null) return '--';
    final diff = endTime!.difference(startTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
