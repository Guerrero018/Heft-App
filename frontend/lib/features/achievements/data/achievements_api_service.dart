import 'package:dio/dio.dart';

import '../domain/achievement_model.dart';

String friendlyAchievementsError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 404) {
    return 'El servidor aún no tiene activados los logros.\n'
        'Despliega el backend actualizado en Render o usa API_BASE_URL en .env apuntando a tu servidor local.';
  }
  if (status == 401) {
    return 'Sesión expirada. Vuelve a iniciar sesión.';
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'El servidor tarda en responder. Inténtalo de nuevo.';
  }
  return 'No se pudieron cargar los logros.';
}

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
