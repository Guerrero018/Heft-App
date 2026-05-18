import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../statistics/data/statistics_provider.dart';
import '../../workouts/domain/workout_model.dart';
import '../../../core/utils/workout_week_streak.dart';

bool _sessionCountsForStreak(WorkoutSession session) =>
    session.sets.any((s) => s.weight > 0 && s.reps > 0);

final weekStreakProvider = FutureProvider<WeekStreakStatus>((ref) async {
  await ref.read(statisticsProvider.notifier).ensureWorkoutsForStreak();
  final workouts = ref.read(statisticsProvider.notifier).cachedWorkoutsForStreak;

  final sessionDays = <DateTime>[];
  for (final session in workouts) {
    if (!_sessionCountsForStreak(session)) continue;
    final d = session.date;
    sessionDays.add(DateTime(d.year, d.month, d.day));
  }

  final user = ref.read(authProvider).user;
  final target = (user?['workout_days_per_week'] as num?)?.toInt() ?? 3;

  return computeWeekStreakStatus(sessionDays, target);
});
