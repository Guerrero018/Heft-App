import '../../../core/api/api_client.dart';
import '../domain/workout_model.dart';

/// Carga todas las sesiones del usuario (con paginación si el API la usa).
Future<List<WorkoutSession>> fetchAllWorkoutSessions() async {
  final all = <WorkoutSession>[];
  String? nextUrl = 'workouts/';

  while (nextUrl != null) {
    final response = await apiClient.get(
      nextUrl,
      queryParameters: nextUrl == 'workouts/'
          ? {'ordering': '-start_time'}
          : null,
    );

    final data = response.data;
    if (data is List) {
      all.addAll(
        data.map(
          (json) => WorkoutSession.fromJson(Map<String, dynamic>.from(json)),
        ),
      );
      break;
    }

    if (data is Map) {
      final results = data['results'];
      if (results is List) {
        all.addAll(
          results.map(
            (json) => WorkoutSession.fromJson(Map<String, dynamic>.from(json)),
          ),
        );
      }
      nextUrl = _nextPagePath(data['next']);
    } else {
      break;
    }
  }

  return all;
}

String? _nextPagePath(dynamic next) {
  if (next == null || next is! String || next.isEmpty) return null;
  final uri = Uri.parse(next);
  var path = uri.path;
  const apiPrefix = '/api/';
  if (path.startsWith(apiPrefix)) {
    path = path.substring(apiPrefix.length);
  } else if (path.startsWith('/')) {
    path = path.substring(1);
  }
  return uri.hasQuery ? '$path?${uri.query}' : path;
}
