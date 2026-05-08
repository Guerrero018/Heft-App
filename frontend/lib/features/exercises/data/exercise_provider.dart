import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/exercise_model.dart';
import 'package:dio/dio.dart';

class ExerciseState {
  final List<Exercise> exercises;
  final List<Exercise> popularExercises;
  final bool isLoading;
  final String? error;

  ExerciseState({
    this.exercises = const [],
    this.popularExercises = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseState copyWith({
    List<Exercise>? exercises,
    List<Exercise>? popularExercises,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      popularExercises: popularExercises ?? this.popularExercises,
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
    if (state.exercises.isNotEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('exercises/');
      final data = response.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data.containsKey('results')) {
        list = data['results'];
      }
      
      if (list.isNotEmpty) {
        final List<Exercise> exercises = list
            .map((json) => Exercise.fromJson(json))
            .toList();
        state = state.copyWith(exercises: exercises, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchPopularExercises() async {
    try {
      final response = await apiClient.get('exercises/popular/');
      final dynamic data = response.data;
      List<dynamic> list = [];
      
      if (data is List) {
        list = data;
      } else if (data is Map && data.containsKey('results')) {
        list = data['results'];
      }

      if (list.isNotEmpty) {
        final List<Exercise> popular = list
            .map((json) => Exercise.fromJson(json))
            .toList();
        state = state.copyWith(popularExercises: popular);
      }
    } catch (e) {
      // Error silencioso en producción
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
      final response = await apiClient.post(
        'exercises/',
        data: {
          'name': name,
          'muscle_group': muscleGroup,
          'exercise_type': exerciseType,
          'description': description ?? '',
          'instructions': instructions ?? [],
          'gif_url': gifUrl ?? '',
          'is_global': false,
        },
      );

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
