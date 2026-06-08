import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/achievement_model.dart';

class AchievementBadge extends StatelessWidget {
  final UserAchievement achievement;
  final double size;
  final bool showTierRing;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 52,
    this.showTierRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final tier = achievement.tier;
    final unlocked = achievement.isUnlocked;
    final accent = achievement.accentColor;
    final dimmed = !unlocked;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dimmed
            ? Colors.white.withValues(alpha: 0.04)
            : accent.withValues(alpha: 0.14),
        border: Border.all(
          color: dimmed
              ? Colors.white.withValues(alpha: 0.08)
              : (showTierRing && tier != null
                  ? accent.withValues(alpha: 0.65)
                  : AppTheme.primaryColor.withValues(alpha: 0.45)),
          width: showTierRing && tier != null ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (unlocked && achievement.imageUrl != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: achievement.imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  achievement.icon,
                  color: accent,
                  size: size * 0.46,
                ),
              ),
            )
          else
            Icon(
              achievement.icon,
              color: dimmed
                  ? Colors.white.withValues(alpha: 0.2)
                  : accent,
              size: size * 0.46,
            ),
          if (!unlocked)
            Icon(
              Icons.lock,
              size: size * 0.28,
              color: Colors.white.withValues(alpha: 0.25),
            ),
        ],
      ),
    );
  }
}
