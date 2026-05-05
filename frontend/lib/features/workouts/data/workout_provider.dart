import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/workout_model.dart';

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
  @override
  WorkoutHistoryState build() {
    // Fetch workouts immediately when the provider is first used
    Future.microtask(() => fetchWorkouts());
    return WorkoutHistoryState();
  }

  Future<void> fetchWorkouts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('workouts/', queryParameters: {
        'ordering': '-date', // Most recent first
      });
      
      if (response.data is List) {
        final List<WorkoutSession> workouts = (response.data as List)
            .map((json) => WorkoutSession.fromJson(json))
            .toList();
        state = state.copyWith(workouts: workouts, isLoading: false);
      } else if (response.data is Map && response.data.containsKey('results')) {
        final List<WorkoutSession> workouts = (response.data['results'] as List)
            .map((json) => WorkoutSession.fromJson(json))
            .toList();
        state = state.copyWith(workouts: workouts, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteWorkout(int id) async {
    try {
      await apiClient.delete('workouts/$id/');
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
