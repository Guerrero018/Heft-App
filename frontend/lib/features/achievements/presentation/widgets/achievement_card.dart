import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/achievement_model.dart';
import 'achievement_badge.dart';

class AchievementCard extends StatelessWidget {
  final UserAchievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final accent = achievement.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unlocked
                  ? accent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              AchievementBadge(achievement: achievement, size: 48),
              const SizedBox(height: 12),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unlocked
                    ? achievement.subtitle
                    : (achievement.progressLabel ?? achievement.subtitle),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked
                      ? accent.withValues(alpha: 0.85)
                      : AppTheme.hintColor,
                  fontSize: 11,
                ),
              ),
              if (!unlocked && achievement.progress > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: accent.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
