// Racha por semanas cumpliendo el objetivo de días de entreno del usuario.

class WeekStreakStatus {
  /// Semanas seguidas cumpliendo el objetivo (incluye la semana en curso si ya se cumplió).
  final int consecutiveWeeks;

  /// Días con entreno registrados en la semana actual (lunes–domingo).
  final int currentWeekWorkoutDays;

  final int targetDaysPerWeek;

  /// Aún puede alcanzar el objetivo esta semana.
  final bool currentWeekStillAchievable;

  const WeekStreakStatus({
    required this.consecutiveWeeks,
    required this.currentWeekWorkoutDays,
    required this.targetDaysPerWeek,
    required this.currentWeekStillAchievable,
  });

  bool get currentWeekGoalMet =>
      currentWeekWorkoutDays >= targetDaysPerWeek;
}

DateTime weekStartMonday(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Cuenta semanas consecutivas (hacia atrás desde la actual) con al menos
/// [targetDaysPerWeek] días distintos con entreno.
///
/// La semana en curso no rompe la racha hasta que ya no sea posible llegar al objetivo.
WeekStreakStatus computeWeekStreakStatus(
  Iterable<DateTime> sessionDays,
  int targetDaysPerWeek, {
  DateTime? referenceDate,
}) {
  final target = targetDaysPerWeek.clamp(1, 7);

  final daysByWeek = <int, Set<String>>{};
  for (final raw in sessionDays) {
    final day = DateTime(raw.year, raw.month, raw.day);
    final weekKey = weekStartMonday(day).millisecondsSinceEpoch;
    daysByWeek.putIfAbsent(weekKey, () => {}).add(_dayKey(day));
  }

  final today = referenceDate ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final currentWeekStart = weekStartMonday(todayDate);
  final currentCount =
      daysByWeek[currentWeekStart.millisecondsSinceEpoch]?.length ?? 0;

  // Días restantes en la semana (incluye hoy): lun=7 … dom=1
  final daysRemaining = 7 - todayDate.weekday + 1;
  final stillAchievable = currentCount + daysRemaining >= target;

  var streak = 0;
  var weekStart = currentWeekStart;

  for (var i = 0; i < 520; i++) {
    final key = weekStart.millisecondsSinceEpoch;
    final count = daysByWeek[key]?.length ?? 0;
    final isCurrentWeek = weekStart == currentWeekStart;

    if (count >= target) {
      streak++;
    } else if (isCurrentWeek && stillAchievable) {
      // Semana en curso aún recuperable: no suma, pero tampoco corta.
    } else {
      break;
    }

    weekStart = weekStart.subtract(const Duration(days: 7));
  }

  return WeekStreakStatus(
    consecutiveWeeks: streak,
    currentWeekWorkoutDays: currentCount,
    targetDaysPerWeek: target,
    currentWeekStillAchievable: stillAchievable,
  );
}

/// Compatibilidad con API/backend: valor numérico = semanas de racha.
int computeWeekStreakWeekCount(
  Iterable<DateTime> sessionDays,
  int targetDaysPerWeek, {
  DateTime? referenceDate,
}) {
  return computeWeekStreakStatus(
    sessionDays,
    targetDaysPerWeek,
    referenceDate: referenceDate,
  ).consecutiveWeeks;
}
