class StatisticsSummary {
  final int totalWorkouts;
  final double totalVolumeKg;
  final int totalSets;
  final int workoutDays;
  final int expectedWorkoutDays;
  final int adherencePercent;
  final int streakDays;

  StatisticsSummary({
    required this.totalWorkouts,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.workoutDays,
    required this.expectedWorkoutDays,
    required this.adherencePercent,
    required this.streakDays,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalWorkouts: json['total_workouts'] ?? 0,
      totalVolumeKg: (json['total_volume_kg'] ?? 0).toDouble(),
      totalSets: json['total_sets'] ?? 0,
      workoutDays: json['workout_days'] ?? 0,
      expectedWorkoutDays: json['expected_workout_days'] ?? 0,
      adherencePercent: json['adherence_percent'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
    );
  }
}

class DailyVolumePoint {
  final String date;
  final String label;
  final double volume;

  DailyVolumePoint({
    required this.date,
    required this.label,
    required this.volume,
  });

  factory DailyVolumePoint.fromJson(Map<String, dynamic> json) {
    return DailyVolumePoint(
      date: json['date'] ?? '',
      label: json['label'] ?? '',
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }
}

class MuscleVolumeItem {
  final String muscleGroup;
  final String label;
  final double volume;

  MuscleVolumeItem({
    required this.muscleGroup,
    required this.label,
    required this.volume,
  });

  factory MuscleVolumeItem.fromJson(Map<String, dynamic> json) {
    return MuscleVolumeItem(
      muscleGroup: json['muscle_group'] ?? '',
      label: json['label'] ?? '',
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }
}

class ExerciseProgressPoint {
  final String date;
  final double volume;
  final double maxWeight;

  ExerciseProgressPoint({
    required this.date,
    required this.volume,
    required this.maxWeight,
  });

  factory ExerciseProgressPoint.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressPoint(
      date: json['date'] ?? '',
      volume: (json['volume'] ?? 0).toDouble(),
      maxWeight: (json['max_weight'] ?? 0).toDouble(),
    );
  }
}

class ExerciseProgress {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String muscleGroupLabel;
  final double volumeTrendPercent;
  final double maxWeightTrendPercent;
  final List<ExerciseProgressPoint> dataPoints;

  ExerciseProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.muscleGroupLabel,
    required this.volumeTrendPercent,
    required this.maxWeightTrendPercent,
    required this.dataPoints,
  });

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      exerciseId: json['exercise_id'] ?? 0,
      exerciseName: json['exercise_name'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      muscleGroupLabel: json['muscle_group_label'] ?? '',
      volumeTrendPercent: (json['volume_trend_percent'] ??
              json['trend_percent'] ??
              0)
          .toDouble(),
      maxWeightTrendPercent:
          (json['max_weight_trend_percent'] ?? 0).toDouble(),
      dataPoints: (json['data_points'] as List? ?? [])
          .map((e) => ExerciseProgressPoint.fromJson(e))
          .toList(),
    );
  }
}

class MuscleMapData {
  final Map<String, double> front;
  final Map<String, double> back;

  MuscleMapData({required this.front, required this.back});

  factory MuscleMapData.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseSide(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    final muscleMap = json['muscle_map'] ?? json;
    return MuscleMapData(
      front: parseSide(muscleMap['front']),
      back: parseSide(muscleMap['back']),
    );
  }
}

class UserStatistics {
  final String period;
  final String periodLabel;
  final String? periodStart;
  final String periodEnd;
  final StatisticsSummary summary;
  final List<DailyVolumePoint> dailyVolume;
  final List<MuscleVolumeItem> volumeByMuscleGroup;
  final MuscleMapData muscleMap;
  final List<ExerciseProgress> exerciseProgress;

  UserStatistics({
    required this.period,
    required this.periodLabel,
    this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.dailyVolume,
    required this.volumeByMuscleGroup,
    required this.muscleMap,
    required this.exerciseProgress,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      period: json['period'] ?? 'week',
      periodLabel: json['period_label'] ?? 'Semana',
      periodStart: json['period_start'],
      periodEnd: json['period_end'] ?? '',
      summary: StatisticsSummary.fromJson(json['summary'] ?? {}),
      dailyVolume: (json['daily_volume'] as List? ?? [])
          .map((e) => DailyVolumePoint.fromJson(e))
          .toList(),
      volumeByMuscleGroup: (json['volume_by_muscle_group'] as List? ?? [])
          .map((e) => MuscleVolumeItem.fromJson(e))
          .toList(),
      muscleMap: MuscleMapData.fromJson(json),
      exerciseProgress: (json['exercise_progress'] as List? ?? [])
          .map((e) => ExerciseProgress.fromJson(e))
          .toList(),
    );
  }

  bool get hasData =>
      summary.totalWorkouts > 0 || summary.totalSets > 0 || summary.totalVolumeKg > 0;
}

/// Mapeo de periodos UI -> query API
String statisticsPeriodToApi(String uiPeriod) {
  switch (uiPeriod) {
    case 'Mes':
      return 'month';
    case '3 Meses':
      return '3months';
    case 'Año':
      return 'year';
    case 'Todo':
      return 'all';
    default:
      return 'week';
  }
}
