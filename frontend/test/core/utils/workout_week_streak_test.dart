import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/workout_week_streak.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('computeWeekStreakStatus', () {
    test('cuenta semanas consecutivas al cumplir objetivo', () {
      final today = _d(2025, 5, 15); // jueves
      final monday = weekStartMonday(today);
      final days = <DateTime>[
        for (var w = 0; w < 3; w++)
          for (var d = 0; d < 4; d++)
            monday.subtract(Duration(days: w * 7)).add(Duration(days: d)),
      ];

      final status = computeWeekStreakStatus(days, 4, referenceDate: today);
      expect(status.consecutiveWeeks, 3);
      expect(status.targetDaysPerWeek, 4);
    });

    test('rompe racha si semana pasada no alcanza objetivo', () {
      final today = _d(2025, 5, 15);
      final lastWeek = weekStartMonday(today).subtract(const Duration(days: 7));
      final days = [
        lastWeek,
        lastWeek.add(const Duration(days: 1)),
        lastWeek.add(const Duration(days: 2)),
      ];

      final status = computeWeekStreakStatus(days, 4, referenceDate: today);
      expect(status.consecutiveWeeks, 0);
    });

    test('semana actual con 3 de 4 no rompe si aún es alcanzable', () {
      final today = _d(2025, 5, 14); // miércoles: quedan 5 días incl. hoy
      final weekStart = weekStartMonday(today);
      final days = [
        weekStart,
        weekStart.add(const Duration(days: 1)),
        weekStart.add(const Duration(days: 2)),
      ];

      final status = computeWeekStreakStatus(days, 4, referenceDate: today);
      expect(status.currentWeekWorkoutDays, 3);
      expect(status.currentWeekStillAchievable, isTrue);
      expect(status.consecutiveWeeks, 0);
    });

    test('semana actual imposible de cumplir rompe racha previa', () {
      final today = _d(2025, 5, 18); // domingo
      final monday = weekStartMonday(today);
      final days = [
        monday,
        monday.add(const Duration(days: 1)),
        monday.subtract(const Duration(days: 7)),
        monday.subtract(const Duration(days: 6)),
        monday.subtract(const Duration(days: 5)),
        monday.subtract(const Duration(days: 4)),
      ];

      final status = computeWeekStreakStatus(days, 4, referenceDate: today);
      expect(status.currentWeekStillAchievable, isFalse);
      expect(status.consecutiveWeeks, 0);
    });

    test('cuenta un solo entreno por día aunque haya dos sesiones', () {
      final today = _d(2025, 5, 12);
      final weekStart = weekStartMonday(today);
      final day = weekStart;
      final days = [day, day.add(const Duration(hours: 3))];

      final status = computeWeekStreakStatus(days, 1, referenceDate: today);
      expect(status.currentWeekWorkoutDays, 1);
      expect(status.currentWeekGoalMet, isTrue);
    });
  });
}
