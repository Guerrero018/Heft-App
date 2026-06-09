import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../achievements/data/achievements_provider.dart';
import '../domain/routine_model.dart';

class RoutineState {
  final List<Routine> routines;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  const RoutineState({
    this.routines = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.error,
  });

  RoutineState copyWith({
    List<Routine>? routines,
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Routine> get activeRoutines =>
      routines.where((routine) => routine.isActive).toList();

  List<Routine> get archivedRoutines =>
      routines.where((routine) => !routine.isActive).toList();
}

class RoutineNotifier extends Notifier<RoutineState> {
  Dio get _api => ref.read(apiClientProvider);

  int _fetchGeneration = 0;
  int _mutationEpoch = 0;
  Future<void>? _inFlightFetch;

  @override
  RoutineState build() {
    Future.microtask(() => fetchRoutines());
    return const RoutineState(isLoading: true);
  }

  List<Routine> _parseRoutines(dynamic data) {
    if (data is List) {
      return data
          .map((json) => Routine.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => Routine.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  Future<void> fetchRoutines({bool silent = false}) {
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    final fetch = _fetchRoutines(silent: silent);
    _inFlightFetch = fetch;
    return fetch.whenComplete(() {
      if (identical(_inFlightFetch, fetch)) {
        _inFlightFetch = null;
      }
    });
  }

  Future<void> _fetchRoutines({bool silent = false}) async {
    final generation = ++_fetchGeneration;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await _api.get('routines/');
      if (generation != _fetchGeneration) return;

      if (state.isMutating) {
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(
        routines: _parseRoutines(response.data),
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      if (generation != _fetchGeneration) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Error al cargar las rutinas',
      );
    } catch (e) {
      if (generation != _fetchGeneration) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  void _syncAchievementsInBackground() {
    final unlockedBaseline = {
      for (final a in ref.read(achievementsProvider).achievements)
        if (a.isUnlocked) a.id,
    };
    unawaited(
      ref.read(achievementsProvider.notifier).sync(
            unlockedBaseline: unlockedBaseline,
          ),
    );
  }

  Future<Routine> createRoutineWithExercises(
    String name,
    String description,
    List<Map<String, dynamic>> exercises, {
    Routine? template,
  }) async {
    if (state.isMutating) {
      throw StateError('Ya hay una operación de rutina en curso');
    }

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await _api.post('routines/', data: {
        'name': name,
        'description': description,
        'exercises': exercises,
      });

      final created = _routineFromResponse(
        Map<String, dynamic>.from(response.data as Map),
        fallbackName: name,
        fallbackDescription: description,
        fallbackExercises: exercises,
        template: template,
      );

      state = state.copyWith(
        routines: [...state.routines, created],
        isMutating: false,
        isLoading: false,
        clearError: true,
      );

      _syncAchievementsInBackground();
      return created;
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        error: 'Error al crear la rutina: $e',
      );
      rethrow;
    }
  }

  Future<void> updateRoutine(
    int id,
    String name,
    String description,
    List<Map<String, dynamic>> exercises,
  ) async {
    if (state.isMutating) {
      throw StateError('Ya hay una operación de rutina en curso');
    }

    final previous = state.routines;
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final response = await _api.put('routines/$id/', data: {
        'name': name,
        'description': description,
        'exercises': exercises,
      });

      final updated = _routineFromResponse(
        Map<String, dynamic>.from(response.data as Map),
        fallbackName: name,
        fallbackDescription: description,
        fallbackExercises: exercises,
        template: findById(id),
      );

      state = state.copyWith(
        routines: previous
            .map((routine) => routine.id == id ? updated : routine)
            .toList(),
        isMutating: false,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        routines: previous,
        isMutating: false,
        error: 'Error al actualizar la rutina: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteRoutine(int routineId) async {
    final epoch = ++_mutationEpoch;
    _fetchGeneration++;
    final previous = state.routines;

    state = state.copyWith(
      routines: previous.where((routine) => routine.id != routineId).toList(),
      isMutating: true,
      clearError: true,
    );

    try {
      await _api.delete('routines/$routineId/');
      if (epoch != _mutationEpoch) return;

      state = state.copyWith(
        routines: state.routines
            .where((routine) => routine.id != routineId)
            .toList(),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      if (epoch != _mutationEpoch) return;
      state = state.copyWith(
        routines: previous,
        isMutating: false,
        error: 'Error al eliminar la rutina: $e',
      );
      rethrow;
    }
  }

  Future<void> setRoutineActive(int routineId, bool isActive) async {
    final epoch = ++_mutationEpoch;
    _fetchGeneration++;
    final previous = state.routines;
    state = state.copyWith(
      routines: previous
          .map(
            (routine) => routine.id == routineId
                ? routine.copyWith(isActive: isActive)
                : routine,
          )
          .toList(),
      isMutating: true,
      clearError: true,
    );

    try {
      await _api.patch('routines/$routineId/', data: {
        'is_active': isActive,
      });
      if (epoch != _mutationEpoch) return;
      state = state.copyWith(isMutating: false, clearError: true);
    } catch (e) {
      if (epoch != _mutationEpoch) return;
      state = state.copyWith(
        routines: previous,
        isMutating: false,
        error: isActive
            ? 'Error al restaurar la rutina: $e'
            : 'Error al archivar la rutina: $e',
      );
      rethrow;
    }
  }

  Future<void> publishRoutine(int routineId) async {
    final response = await _api.post('routines/$routineId/publish/');
    _applyRoutineUpdate(Routine.fromJson(response.data));
  }

  Future<void> unpublishRoutine(int routineId) async {
    final response = await _api.post('routines/$routineId/unpublish/');
    _applyRoutineUpdate(Routine.fromJson(response.data));
  }

  Future<String> shareRoutine(int routineId) async {
    final response = await _api.post('routines/$routineId/share/');
    final code = response.data['share_code']?.toString() ?? '';
    final current = findById(routineId);
    if (current != null && code.isNotEmpty) {
      _applyRoutineUpdate(current.copyWith(shareCode: code));
    }
    return code;
  }

  void _applyRoutineUpdate(Routine updated) {
    state = state.copyWith(
      routines: state.routines
          .map((routine) => routine.id == updated.id ? updated : routine)
          .toList(),
      clearError: true,
    );
  }

  Future<void> duplicateRoutine(Routine routine) async {
    final exercises = routine.exercises.asMap().entries.map((entry) {
      final exercise = entry.value;
      return {
        'exercise': exercise.exerciseId,
        'order': entry.key,
        'target_sets': exercise.targetSets,
        'target_reps': exercise.targetReps,
        'target_weight': exercise.targetWeight,
        'rest_time_seconds': exercise.restTimeSeconds,
      };
    }).toList();

    await createRoutineWithExercises(
      '${routine.name} (copia)',
      routine.description,
      exercises,
      template: routine,
    );
  }

  Routine? findById(int id) {
    for (final routine in state.routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  Routine _routineFromResponse(
    Map<String, dynamic> data, {
    required String fallbackName,
    required String fallbackDescription,
    required List<Map<String, dynamic>> fallbackExercises,
    Routine? template,
  }) {
    if (data['id'] != null && data['exercises'] is List) {
      return Routine.fromJson(data);
    }

    if (template != null) {
      return template.copyWith(
        id: data['id'] as int,
        name: (data['name'] as String?) ?? fallbackName,
        description: (data['description'] as String?) ?? fallbackDescription,
        isActive: data['is_active'] as bool? ?? true,
      );
    }

    return Routine(
      id: data['id'] as int,
      name: (data['name'] as String?) ?? fallbackName,
      description: (data['description'] as String?) ?? fallbackDescription,
      isActive: data['is_active'] as bool? ?? true,
      exercises: fallbackExercises.asMap().entries.map((entry) {
        final exerciseData = entry.value;
        return RoutineExercise(
          id: entry.key,
          exerciseId: exerciseData['exercise'] as int,
          exerciseName: 'Ejercicio',
          muscleGroup: 'otros',
          order: exerciseData['order'] as int? ?? entry.key,
          targetSets: exerciseData['target_sets'] as int? ?? 0,
          targetReps: exerciseData['target_reps'] as int? ?? 0,
          targetWeight: (exerciseData['target_weight'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
    );
  }
}

final routineProvider = NotifierProvider<RoutineNotifier, RoutineState>(() {
  return RoutineNotifier();
});
