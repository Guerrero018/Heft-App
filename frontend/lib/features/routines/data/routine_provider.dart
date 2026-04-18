import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/routine_model.dart';
import 'package:dio/dio.dart';

class RoutineState {
  final List<Routine> routines;
  final bool isLoading;
  final String? error;

  RoutineState({
    this.routines = const [],
    this.isLoading = false,
    this.error,
  });

  RoutineState copyWith({
    List<Routine>? routines,
    bool? isLoading,
    String? error,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RoutineNotifier extends Notifier<RoutineState> {
  @override
  RoutineState build() {
    // Iniciamos la carga en el siguiente microtask para no bloquear el build
    Future.microtask(() => fetchRoutines());
    return RoutineState(isLoading: true);
  }

  Future<void> fetchRoutines() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('routines/');
      print('DEBUG: Routine response data: ${response.data}');
      if (response.data is List) {
        final List<Routine> routines = (response.data as List)
            .map((json) => Routine.fromJson(json))
            .toList();
        state = state.copyWith(routines: routines, isLoading: false);
      } else if (response.data is Map && response.data.containsKey('results')) {
        // En caso de que esté paginado
        final List<Routine> routines = (response.data['results'] as List)
            .map((json) => Routine.fromJson(json))
            .toList();
        state = state.copyWith(routines: routines, isLoading: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Error fetching routines',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<void> createRoutineWithExercises(String name, String description, List<Map<String, dynamic>> exercises) async {
    state = state.copyWith(isLoading: true);
    try {
      await apiClient.post('routines/', data: {
        'name': name,
        'description': description,
        'exercises': exercises,
      });
      await fetchRoutines();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create routine: $e');
      rethrow;
    }
  }
}

final routineProvider = NotifierProvider<RoutineNotifier, RoutineState>(() {
  return RoutineNotifier();
});
