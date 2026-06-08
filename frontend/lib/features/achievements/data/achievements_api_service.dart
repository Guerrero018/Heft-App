import 'package:dio/dio.dart';

import '../domain/achievement_model.dart';

class AchievementsApiService {
  final Dio _api;

  AchievementsApiService(this._api);

  Future<AchievementsState> fetchUserAchievements() async {
    final response = await _api.get('achievements/');
    return AchievementsState.fromApiResponse(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AchievementsState> syncUserAchievements() async {
    final response = await _api.post('achievements/');
    final data = response.data as Map<String, dynamic>;
    final newlyUnlocked = (data['newly_unlocked'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return AchievementsState.fromApiResponse(
      data,
      pendingCelebrations: newlyUnlocked,
    );
  }
}
