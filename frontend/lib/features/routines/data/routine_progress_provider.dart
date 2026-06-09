import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../workouts/domain/workout_model.dart';
import '../domain/routine_progress.dart';
import 'routine_provider.dart';

final routineProgressProvider =
    FutureProvider.autoDispose.family<RoutineProgress, int>((ref, routineId) async {
  final routine = ref.read(routineProvider.notifier).findById(routineId);
  final routineExerciseIds =
      routine?.exercises.map((e) => e.exerciseId).toSet() ?? <int>{};

  try {
    final response = await ref.read(apiClientProvider).get(
      'workouts/',
      queryParameters: {
        'routine': routineId,
        'ordering': '-start_time',
      },
    );

    final sessions = _sessionsForRoutine(
      _parseWorkouts(response.data),
      routineId,
    );

    return buildRoutineProgress(
      sessions: sessions,
      routineExerciseIds: routineExerciseIds,
    );
  } on DioException catch (e) {
    throw Exception(e.message ?? 'Error al cargar el progreso');
  }
});

List<WorkoutSession> _sessionsForRoutine(
  List<WorkoutSession> sessions,
  int routineId,
) {
  return sessions.where((session) => session.routineId == routineId).toList();
}

List<WorkoutSession> _parseWorkouts(dynamic data) {
  if (data is List) {
    return data
        .map((json) => WorkoutSession.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
  if (data is Map && data['results'] is List) {
    return (data['results'] as List)
        .map((json) => WorkoutSession.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
  return [];
}
