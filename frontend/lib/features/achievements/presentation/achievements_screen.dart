import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/achievements_provider.dart';
import '../domain/achievement_model.dart';
import 'widgets/achievement_badge.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory? _filter;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(achievementsProvider.notifier).load(force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Logros',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && state.achievements.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: AppTheme.cardColor,
              onRefresh: () =>
                  ref.read(achievementsProvider.notifier).sync(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SummaryHeader(
                    unlocked: state.unlockedCount,
                    total: state.totalCount,
                  ),
                  const SizedBox(height: 16),
                  _CategoryChips(
                    selected: _filter,
                    onSelected: (cat) => setState(() => _filter = cat),
                  ),
                  const SizedBox(height: 20),
                  ..._buildSections(state),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSections(AchievementsState state) {
    final categories = AchievementCategory.values;
    final widgets = <Widget>[];

    for (final category in categories) {
      if (_filter != null && _filter != category) continue;

      final items = state.achievements
          .where((a) => a.category == category)
          .toList();
      if (items.isEmpty) continue;

      final unlockedInCat = items.where((a) => a.isUnlocked).length;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$unlockedInCat/${items.length}',
                style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      );

      widgets.addAll(
        items.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AchievementListTile(achievement: a),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }
}

class _SummaryHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _SummaryHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                '$unlocked de $total desbloqueados',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onSelected;

  const _CategoryChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Todos',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...AchievementCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: cat.label,
                selected: selected == cat,
                onTap: () => onSelected(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.08),
      ),
      showCheckmark: false,
    );
  }
}

class _AchievementListTile extends StatelessWidget {
  final UserAchievement achievement;

  const _AchievementListTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final tier = achievement.tier;
    final unlocked = achievement.isUnlocked;
    final accent = achievement.accentColor;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked
                  ? accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              AchievementBadge(achievement: achievement, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        color: unlocked
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unlocked
                          ? achievement.description
                          : (achievement.progressLabel ?? achievement.subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    if (!unlocked && achievement.progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tier != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    tier.label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            AchievementBadge(achievement: achievement, size: 72),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.subtitle,
              style: TextStyle(
                color: achievement.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.hintColor,
                height: 1.45,
              ),
            ),
            if (!achievement.isUnlocked && achievement.progressLabel != null) ...[
              const SizedBox(height: 14),
              Text(
                'Progreso: ${achievement.progressLabel}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'Desbloqueado el ${_formatDate(achievement.unlockedAt!)}',
                style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
