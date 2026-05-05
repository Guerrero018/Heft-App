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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCustomExercise({
    required String name,
    required String muscleGroup,
    required String exerciseType,
    String? description,
    List<String>? instructions,
    String? gifUrl,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await apiClient.post('exercises/', data: {
        'name': name,
        'muscle_group': muscleGroup,
        'exercise_type': exerciseType,
        'description': description ?? '',
        'instructions': instructions ?? [],
        'gif_url': gifUrl ?? '',
        'is_global': false,
      });
      
      final newExercise = Exercise.fromJson(response.data);
      state = state.copyWith(
        exercises: [newExercise, ...state.exercises],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Exercise?> fetchExerciseById(int id) async {
    try {
      final response = await apiClient.get('exercises/$id/');
      return Exercise.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

final exerciseProvider = NotifierProvider<ExerciseNotifier, ExerciseState>(() {
  return ExerciseNotifier();
});
