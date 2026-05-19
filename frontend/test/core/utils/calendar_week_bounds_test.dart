import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/workout_week_streak.dart';

void main() {
  test('nueva semana empieza el lunes', () {
    final monday = DateTime(2026, 5, 18);
    final bounds = calendarWeekBounds(monday);
    expect(bounds.start, monday);
    expect(bounds.end, DateTime(2026, 5, 24));
  });
}
