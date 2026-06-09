import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/achievements/domain/achievement_model.dart';

void main() {
  UserAchievement achievement({
    required String id,
    bool unlocked = false,
    double progress = 0,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      id: id,
      category: AchievementCategory.strength,
      tier: AchievementTier.bronze,
      title: id,
      subtitle: '',
      description: '',
      iconKey: 'emoji_events',
      isUnlocked: unlocked,
      progress: progress,
      unlockedAt: unlockedAt,
    );
  }

  test('AchievementsState.fromApiResponse parses counts', () {
    final state = AchievementsState.fromApiResponse({
      'achievements': [
        {
          'id': 'a1',
          'title': 'A',
          'subtitle': '',
          'description': '',
          'category': 'strength',
          'icon_key': 'emoji_events',
          'is_unlocked': true,
        },
        {
          'id': 'a2',
          'title': 'B',
          'subtitle': '',
          'description': '',
          'category': 'volume',
          'icon_key': 'emoji_events',
          'is_unlocked': false,
          'progress': 0.5,
        },
      ],
      'unlocked_count': 1,
      'total_count': 2,
    });

    expect(state.unlockedCount, 1);
    expect(state.totalCount, 2);
    expect(state.unlocked, hasLength(1));
    expect(state.locked, hasLength(1));
  });

  test('vitrineCandidates prefers two unlocked sorted by date', () {
    final state = AchievementsState(
      achievements: [
        achievement(
          id: 'old',
          unlocked: true,
          unlockedAt: DateTime(2026, 1, 1),
        ),
        achievement(
          id: 'new',
          unlocked: true,
          unlockedAt: DateTime(2026, 6, 1),
        ),
      ],
    );

    expect(state.vitrineCandidates.map((a) => a.id), ['new', 'old']);
  });

  test('vitrineCandidates mixes unlocked with in-progress locked', () {
    final state = AchievementsState(
      achievements: [
        achievement(id: 'done', unlocked: true),
        achievement(id: 'next', progress: 0.8),
        achievement(id: 'low', progress: 0.1),
      ],
    );

    expect(state.vitrineCandidates.map((a) => a.id), ['done', 'next']);
  });
}
