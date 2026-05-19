import '../../../core/utils/workout_week_streak.dart';
import '../../workouts/domain/workout_model.dart';
import '../domain/muscle_map_config.dart';
import '../domain/statistics_model.dart';

const _periodDays = {
  'week': 7,
  'month': 30,
  '3months': 90,
  'year': 365,
  'all': null,
};

String _muscleLabel(String muscle) {
  const labels = {
    'pecho': 'Pecho',
    'espalda': 'Espalda',
    'hombros': 'Hombros',
    'cuadriceps': 'Cuádriceps',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'abdominales': 'Abs',
    'gluteos': 'Glúteos',
    'gemelos': 'Gemelos',
    'isquiotibiales': 'Isquios',
    'trapecios': 'Hombros',
    'cardio': 'Cardio',
    'otros': 'Otros',
  };
  return labels[muscle] ?? muscle.replaceAll('_', ' ');
}

const _periodLabels = {
  'week': 'Semana',
  'month': 'Mes',
  '3months': '3 Meses',
  'year': 'Año',
  'all': 'Todo',
};

/// Reexportado desde [kDbToMuscleMapKey] (BD → mapa).
(String, String) _mapKeyForDbMuscle(String muscle) {
  final m = kDbToMuscleMapKey[muscle] ?? ('abs', 'front');
  return (m.$1, m.$2);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Mapa muscular: semana natural (lunes–domingo), reinicia cada lunes a las 00:00.
const _muscleMapPeriodKey = 'calendar_week';

/// Mismo criterio que el historial: fecha de sesión dentro del rango.
({DateTime? start, DateTime end}) _periodBounds(
  String periodKey, {
  DateTime? referenceDate,
}) {
  final today = _dateOnly(referenceDate ?? DateTime.now());
  if (periodKey == _muscleMapPeriodKey) {
    final week = calendarWeekBounds(today);
    return (start: week.start, end: week.end);
  }
  final days = _periodDays[periodKey];
  if (days == null) {
    return (start: null, end: today);
  }
  return (start: today.subtract(Duration(days: days - 1)), end: today);
}

bool _isSessionInPeriod(WorkoutSession session, DateTime? start, DateTime end) {
  final sessionDay = _dateOnly(session.date);
  if (sessionDay.isAfter(end)) return false;
  if (start == null) return true;
  return !sessionDay.isBefore(start);
}

bool _setCountsForStats(WorkoutSet set) => set.weight > 0 && set.reps > 0;

bool _sessionHasTraining(WorkoutSession session) =>
    session.sets.any(_setCountsForStats);

/// Periodo del API para el mapa muscular (semana calendario lunes–domingo).
const muscleMapApiPeriod = _muscleMapPeriodKey;

/// Volumen en kg por clave del mapa SVG (suma de grupos BD).
Map<String, double> absoluteVolumeByMapKey(List<MuscleVolumeItem> items) {
  final result = <String, double>{};
  for (final item in items) {
    final mapping = kDbToMuscleMapKey[item.muscleGroup];
    if (mapping == null) continue;
    result[mapping.$1] = (result[mapping.$1] ?? 0) + item.volume;
  }
  return result;
}

UserStatistics buildStatisticsFromWorkouts({
  required List<WorkoutSession> workouts,
  required Map<int, String> exerciseMuscleById,
  required String apiPeriod,
  required int workoutDaysPerWeek,
  DateTime? referenceDate,
  ({DateTime? start, DateTime end})? boundsOverride,
}) {
  final periodKey = _periodDays.containsKey(apiPeriod) ||
          apiPeriod == _muscleMapPeriodKey
      ? apiPeriod
      : 'week';
  final bounds =
      boundsOverride ?? _periodBounds(periodKey, referenceDate: referenceDate);

  final allSessionDates = <DateTime>{};
  for (final session in workouts) {
    if (!_sessionHasTraining(session)) continue;
    allSessionDates.add(_dateOnly(session.date));
  }

  final filtered = workouts.where((w) {
    if (!_sessionHasTraining(w)) return false;
    return _isSessionInPeriod(w, bounds.start, bounds.end);
  }).toList();

  double totalVolume = 0;
  var totalSets = 0;
  final volumeByMuscle = <String, double>{};
  final volumeByDay = <String, double>{};
  final sessionDates = <DateTime>{};
  final exerciseData = <int, _ExerciseAgg>{};

  for (final session in filtered) {
    sessionDates.add(_dateOnly(session.date));
    final dayKey = _dayKey(session.date);

    for (final set in session.sets) {
      if (!_setCountsForStats(set)) continue;

      final volume = set.weight * set.reps;
      totalVolume += volume;
      totalSets += 1;
      volumeByDay[dayKey] = (volumeByDay[dayKey] ?? 0) + volume;

      final muscle = exerciseMuscleById[set.exerciseId] ?? 'otros';
      volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?? 0) + volume;

      final agg = exerciseData.putIfAbsent(
        set.exerciseId,
        () => _ExerciseAgg(
          exerciseId: set.exerciseId,
          exerciseName: set.exerciseName,
          muscleGroup: muscle,
        ),
      );

      final sessionKey = session.startTime.toIso8601String();
      agg.points.putIfAbsent(
        sessionKey,
        () => _SessionPoint(sessionKey: sessionKey, date: dayKey),
      );
      final point = agg.points[sessionKey]!;
      if (set.weight > point.maxWeight) point.maxWeight = set.weight;
      point.volume += volume;
      agg.totalVolume += volume;
    }
  }

  final now = referenceDate ?? DateTime.now();
  final daysInPeriod = periodKey == _muscleMapPeriodKey
      ? 7
      : (_periodDays[periodKey] ??
      _daysBetween(
            sessionDates.isEmpty
                ? now
                : sessionDates.reduce((a, b) => a.isBefore(b) ? a : b),
            now,
          ));
  final weeksInPeriod = (daysInPeriod / 7).clamp(1.0, double.infinity);
  final expectedSessions = (workoutDaysPerWeek * weeksInPeriod).round().clamp(1, 9999);
  final workoutDays = sessionDates.length;
  final adherencePercent = workoutDays == 0
      ? 0
      : ((workoutDays / expectedSessions) * 100).round().clamp(0, 100);

  final maxMuscleVol = volumeByMuscle.values.fold<double>(0, (m, v) => v > m ? v : m);
  final frontLoads = <String, double>{};
  final backLoads = <String, double>{};

  for (final entry in volumeByMuscle.entries) {
    final normalized = maxMuscleVol > 0 ? entry.value / maxMuscleVol : 0.0;
    final mapping = _mapKeyForDbMuscle(entry.key);
    if (mapping.$2 == 'back') {
      final current = backLoads[mapping.$1] ?? 0;
      if (normalized > current) backLoads[mapping.$1] = normalized;
    } else {
      final current = frontLoads[mapping.$1] ?? 0;
      if (normalized > current) frontLoads[mapping.$1] = normalized;
    }
  }

  final topExercises = exerciseData.values.toList()
    ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

  final exerciseProgress = topExercises.map((ex) {
    final points = ex.points.values.toList()
      ..sort((a, b) => a.sessionKey.compareTo(b.sessionKey));

    final volumeTrend = _progressTrend(
      points.map((p) => p.volume).toList(),
    );
    final maxWeightTrend = _progressTrend(
      points.map((p) => p.maxWeight).toList(),
    );

    return ExerciseProgress(
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      muscleGroup: ex.muscleGroup,
      muscleGroupLabel: _muscleLabel(ex.muscleGroup),
      volumeTrendPercent: volumeTrend,
      maxWeightTrendPercent: maxWeightTrend,
      dataPoints: points
          .map(
            (p) => ExerciseProgressPoint(
              date: p.date,
              volume: p.volume,
              maxWeight: p.maxWeight,
            ),
          )
          .toList(),
    );
  }).toList();

  final volumeByMuscleGroup = volumeByMuscle.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final dailyKeys = volumeByDay.keys.toList()..sort();
  List<String> dayKeys;
  if (periodKey == 'week' || dailyKeys.length <= 7) {
    dayKeys = dailyKeys.length > 7 ? dailyKeys.sublist(dailyKeys.length - 7) : dailyKeys;
  } else {
    final step = (dailyKeys.length / 7).ceil().clamp(1, dailyKeys.length);
    dayKeys = [for (var i = 0; i < dailyKeys.length; i += step) dailyKeys[i]].take(7).toList();
  }

  return UserStatistics(
    period: periodKey,
    periodLabel: periodKey == _muscleMapPeriodKey
        ? 'Esta semana'
        : (_periodLabels[periodKey] ?? 'Semana'),
    periodStart: bounds.start != null ? _dayKey(bounds.start!) : null,
    periodEnd: _dayKey(bounds.end),
    summary: StatisticsSummary(
      totalWorkouts: filtered.length,
      totalVolumeKg: totalVolume,
      totalSets: totalSets,
      workoutDays: workoutDays,
      expectedWorkoutDays: expectedSessions,
      adherencePercent: adherencePercent,
      streakDays: computeWeekStreakWeekCount(allSessionDates, workoutDaysPerWeek),
    ),
    dailyVolume: dayKeys
        .map(
          (d) => DailyVolumePoint(
            date: d,
            label: _formatDayLabel(d),
            volume: volumeByDay[d] ?? 0,
          ),
        )
        .toList(),
    volumeByMuscleGroup: volumeByMuscleGroup.take(8).map((e) {
      return MuscleVolumeItem(
        muscleGroup: e.key,
        label: _muscleLabel(e.key),
        volume: e.value,
      );
    }).toList(),
    muscleMap: MuscleMapData(front: frontLoads, back: backLoads),
    exerciseProgress: exerciseProgress,
  );
}

int _daysBetween(DateTime start, DateTime end) {
  return end.difference(start).inDays + 1;
}

double _progressTrend(List<double> values) {
  if (values.length < 2) return 0;
  final first = values.first;
  final last = values.last;
  if (first <= 0) return 0;
  return double.parse((((last - first) / first) * 100).toStringAsFixed(1));
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatDayLabel(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  return '${parts[2]}/${parts[1]}';
}

class _ExerciseAgg {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final Map<String, _SessionPoint> points = {};
  double totalVolume = 0;

  _ExerciseAgg({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
  });
}

class _SessionPoint {
  final String sessionKey;
  final String date;
  double maxWeight = 0;
  double volume = 0;

  _SessionPoint({required this.sessionKey, required this.date});
}
