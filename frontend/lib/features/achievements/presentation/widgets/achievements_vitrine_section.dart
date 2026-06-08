import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/achievements_provider.dart';
import '../../domain/achievement_model.dart';
import '../achievements_screen.dart';
import 'achievement_card.dart';

class AchievementsVitrineSection extends ConsumerWidget {
  const AchievementsVitrineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vitrina de logros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!state.isLoading)
                Text(
                  '${state.unlockedCount}/${state.totalCount}',
                  style: const TextStyle(
                    color: AppTheme.hintColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.hintColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.isLoading && state.achievements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (state.error != null && state.achievements.isEmpty)
            _ErrorBanner(
              message: state.error!,
              onRetry: () =>
                  ref.read(achievementsProvider.notifier).refresh(force: true),
            )
          else
            _VitrineRow(
              items: state.vitrineCandidates,
              onOpenAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AchievementsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VitrineRow extends StatelessWidget {
  final List<UserAchievement> items;
  final VoidCallback onOpenAll;

  const _VitrineRow({
    required this.items,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock_open,
              color: Colors.white.withValues(alpha: 0.25),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              'Entrena para desbloquear tus primeros logros',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onOpenAll, child: const Text('Ver todos')),
          ],
        ),
      );
    }

    final display = items.length >= 2 ? items.take(2).toList() : items;

    return Row(
      children: [
        for (var i = 0; i < display.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: AchievementCard(
              achievement: display[i],
              onTap: onOpenAll,
            ),
          ),
        ],
        if (display.length == 1) const SizedBox(width: 12),
        if (display.length == 1)
          Expanded(
            child: GestureDetector(
              onTap: onOpenAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ver todos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'los logros',
                      style: TextStyle(color: AppTheme.hintColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ),
        ],
      ),
    );
  }
}
