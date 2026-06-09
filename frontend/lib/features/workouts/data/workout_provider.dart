import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/workout_model.dart';
import 'workout_fetch_service.dart';

class WorkoutHistoryState {
  final List<WorkoutSession> workouts;
  final bool isLoading;
  final String? error;

  WorkoutHistoryState({
    this.workouts = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutHistoryState copyWith({
    List<WorkoutSession>? workouts,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutHistoryState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkoutHistoryNotifier extends Notifier<WorkoutHistoryState> {
  Dio get _api => ref.read(apiClientProvider);

  @override
  WorkoutHistoryState build() {
    Future.microtask(() => fetchWorkouts());
    return WorkoutHistoryState();
  }

  Future<void> fetchWorkouts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final workouts = await fetchAllWorkoutSessions(client: _api);
      state = state.copyWith(workouts: workouts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteWorkout(int id) async {
    try {
      await _api.delete('workouts/$id/');
      state = state.copyWith(
        workouts: state.workouts.where((w) => w.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al eliminar entrenamiento');
    }
  }
}

final workoutHistoryProvider = NotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>(() {
  return WorkoutHistoryNotifier();
});
