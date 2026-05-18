import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/workout_week_streak.dart';
import '../../data/week_streak_provider.dart';

class WeekStreakCard extends ConsumerWidget {
  const WeekStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(weekStreakProvider);

    return streakAsync.when(
      loading: () => const _WeekStreakCardSkeleton(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (status) => _WeekStreakCardContent(status: status),
    );
  }
}

class _WeekStreakCardSkeleton extends StatelessWidget {
  const _WeekStreakCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _WeekStreakCardContent extends StatelessWidget {
  final WeekStreakStatus status;

  const _WeekStreakCardContent({required this.status});

  @override
  Widget build(BuildContext context) {
    final weeks = status.consecutiveWeeks;
    final target = status.targetDaysPerWeek;
    final current = status.currentWeekWorkoutDays;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    final weekLabel = weeks == 1 ? 'semana' : 'semanas';
    final title = weeks > 0 ? '$weeks $weekLabel de racha' : 'Sin racha activa';

    final Color weekBadgeColor;
    if (status.currentWeekGoalMet) {
      weekBadgeColor = AppTheme.primaryColor;
    } else if (status.currentWeekStillAchievable) {
      weekBadgeColor = AppTheme.hintColor;
    } else {
      weekBadgeColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.12),
            Theme.of(context).cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            weeks > 0
                ? Icons.local_fire_department_rounded
                : Icons.local_fire_department_outlined,
            color: weeks > 0 ? Colors.orangeAccent : AppTheme.hintColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$current/$target',
                      style: TextStyle(
                        color: weekBadgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: status.currentWeekGoalMet
                        ? AppTheme.primaryColor
                        : status.currentWeekStillAchievable
                            ? AppTheme.primaryColor.withOpacity(0.7)
                            : Colors.redAccent.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
