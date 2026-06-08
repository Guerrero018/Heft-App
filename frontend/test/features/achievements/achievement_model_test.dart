import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/achievements/domain/achievement_model.dart';

void main() {
  test('UserAchievement.fromJson parses API payload', () {
    final achievement = UserAchievement.fromJson({
      'id': 'bench_press_gold',
      'category': 'strength',
      'tier': 'gold',
      'title': 'Press de banca — Oro',
      'subtitle': '≥ 140 kg',
      'description': 'Levanta al menos 140 kg...',
      'icon_key': 'fitness_center',
      'image_url': null,
      'is_unlocked': true,
      'progress': 1.0,
      'progress_label': '140 / 140 kg',
      'unlocked_at': '2025-06-01T10:00:00Z',
    });

    expect(achievement.id, 'bench_press_gold');
    expect(achievement.category, AchievementCategory.strength);
    expect(achievement.tier, AchievementTier.gold);
    expect(achievement.isUnlocked, isTrue);
    expect(achievement.progress, 1.0);
  });

  test('AchievementsState.fromApiResponse uses API counts', () {
    final state = AchievementsState.fromApiResponse({
      'unlocked_count': 3,
      'total_count': 75,
      'achievements': [
        {
          'id': 'first_workout',
          'category': 'consistency',
          'tier': null,
          'title': 'Primer entreno',
          'subtitle': '1 sesión',
          'description': 'Completa tu primer entrenamiento',
          'icon_key': 'emoji_events',
          'is_unlocked': true,
          'progress': 1.0,
        },
      ],
    });

    expect(state.unlockedCount, 3);
    expect(state.totalCount, 75);
    expect(state.achievements, hasLength(1));
  });
}
