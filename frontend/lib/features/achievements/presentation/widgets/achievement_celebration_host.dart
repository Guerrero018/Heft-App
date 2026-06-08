import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/achievements_provider.dart';
import '../../domain/achievement_model.dart';
import 'achievement_badge.dart';

/// Escucha logros recién desbloqueados y muestra un diálogo de celebración.
class AchievementCelebrationHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementCelebrationHost({super.key, required this.child});

  @override
  ConsumerState<AchievementCelebrationHost> createState() =>
      _AchievementCelebrationHostState();
}

class _AchievementCelebrationHostState
    extends ConsumerState<AchievementCelebrationHost> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(achievementsProvider, (previous, next) {
      if (_showing || next.pendingCelebrations.isEmpty) return;

      final slugs = next.pendingCelebrations;
      final unlocked = next.achievements
          .where((a) => slugs.contains(a.id) && a.isUnlocked)
          .toList();
      if (unlocked.isEmpty) {
        ref.read(achievementsProvider.notifier).clearPendingCelebrations();
        return;
      }

      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showCelebrationDialog(context, unlocked);
        if (mounted) {
          ref.read(achievementsProvider.notifier).clearPendingCelebrations();
          _showing = false;
        }
      });
    });

    return widget.child;
  }

  Future<void> _showCelebrationDialog(
    BuildContext context,
    List<UserAchievement> achievements,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CelebrationDialog(achievements: achievements),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  final List<UserAchievement> achievements;

  const _CelebrationDialog({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final primary = achievements.first;
    final extra = achievements.length - 1;

    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '¡Logro desbloqueado!',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AchievementBadge(achievement: primary, size: 80),
            const SizedBox(height: 16),
            Text(
              primary.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              primary.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.hintColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (extra > 0) ...[
              const SizedBox(height: 12),
              Text(
                extra == 1
                    ? '+1 logro más desbloqueado'
                    : '+$extra logros más desbloqueados',
                style: TextStyle(
                  color: primary.accentColor.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '¡Genial!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
