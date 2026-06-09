import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/workout_week_streak.dart';

void main() {
  test('calendar week bounds sanity check', () {
    final bounds = calendarWeekBounds(DateTime(2026, 5, 15));
    expect(bounds.start.weekday, DateTime.monday);
    expect(bounds.end.weekday, DateTime.sunday);
  });
}
