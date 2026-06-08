import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/achievement_model.dart';
import 'achievements_api_service.dart';

final achievementsApiServiceProvider = Provider<AchievementsApiService>((ref) {
  return AchievementsApiService(ref.read(apiClientProvider));
});

class AchievementsNotifier extends Notifier<AchievementsState> {
  @override
  AchievementsState build() {
    Future.microtask(load);
    return const AchievementsState(isLoading: true);
  }

  Future<void> load({bool force = false}) async {
    if (state.isLoading && state.achievements.isNotEmpty && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result =
          await ref.read(achievementsApiServiceProvider).fetchUserAchievements();
      state = result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// [unlockedBaseline] — IDs desbloqueados antes de la acción (p. ej. guardar
  /// entreno). Evita perder celebraciones cuando el backend ya sincronizó vía signal.
  Future<void> sync({Set<String>? unlockedBaseline}) async {
    final baseline = unlockedBaseline ??
        {
          for (final a in state.achievements)
            if (a.isUnlocked) a.id,
        };

    try {
      final result =
          await ref.read(achievementsApiServiceProvider).syncUserAchievements();

      final nowUnlocked = {
        for (final a in result.achievements)
          if (a.isUnlocked) a.id,
      };
      final clientNewly = nowUnlocked.difference(baseline);
      final combined = {
        ...result.pendingCelebrations,
        ...clientNewly,
      }.toList();

      state = result.copyWith(pendingCelebrations: combined);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearPendingCelebrations() {
    if (state.pendingCelebrations.isEmpty) return;
    state = state.copyWith(pendingCelebrations: const []);
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
  AchievementsNotifier.new,
);
