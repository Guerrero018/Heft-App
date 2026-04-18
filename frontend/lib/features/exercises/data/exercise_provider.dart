import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/exercise_model.dart';
import 'package:dio/dio.dart';

class ExerciseState {
  final List<Exercise> exercises;
  final bool isLoading;
  final String? error;

  ExerciseState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseState copyWith({
    List<Exercise>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExerciseNotifier extends Notifier<ExerciseState> {
  @override
  ExerciseState build() {
    return ExerciseState();
  }

  Future<void> fetchExercises() async {
    if (state.exercises.isNotEmpty) return; // Ya cargados
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('exercises/');
      if (response.data is List) {
        final List<Exercise> exercises = (response.data as List)
            .map((json) => Exercise.fromJson(json))
            .toList();
        state = state.copyWith(exercises: exercises, isLoading: false);
      } else if (response.data is Map && response.data.containsKey('results')) {
        final List<Exercise> exercises = (response.data['results'] as List)
            .map((json) => Exercise.fromJson(json))
            .toList();
        state = state.copyWith(exercises: exercises, isLoading: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final exerciseProvider = NotifierProvider<ExerciseNotifier, ExerciseState>(() {
  return ExerciseNotifier();
});
