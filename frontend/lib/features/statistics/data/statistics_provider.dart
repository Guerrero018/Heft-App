import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/auth_provider.dart';
import '../../exercises/data/exercise_provider.dart';
import '../../exercises/domain/exercise_model.dart';
import '../../workouts/data/workout_provider.dart';
import '../../workouts/domain/workout_model.dart';
import '../domain/statistics_model.dart';
import 'statistics_api_service.dart';
import 'statistics_local_service.dart';

class StatisticsState {
  final UserStatistics? data;
  final bool isLoading;
  final String? error;
  final String selectedPeriod;
  final UserStatistics? muscleMapWeekData;
  final bool muscleMapLoading;
  final String? muscleMapError;

  StatisticsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'Mes',
    this.muscleMapWeekData,
    this.muscleMapLoading = false,
    this.muscleMapError,
  });

  StatisticsState copyWith({
    UserStatistics? data,
    bool? isLoading,
    String? error,
    String? selectedPeriod,
    UserStatistics? muscleMapWeekData,
    bool? muscleMapLoading,
    String? muscleMapError,
    bool clearError = false,
    bool clearMuscleMapError = false,
  }) {
    return StatisticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      muscleMapWeekData: muscleMapWeekData ?? this.muscleMapWeekData,
      muscleMapLoading: muscleMapLoading ?? this.muscleMapLoading,
      muscleMapError:
          clearMuscleMapError ? null : (muscleMapError ?? this.muscleMapError),
    );
  }
}

class StatisticsNotifier extends Notifier<StatisticsState> {
  Dio get _api => ref.read(apiClientProvider);

  List<WorkoutSession>? _cachedWorkouts;
  Map<int, String>? _cachedMuscleMap;
  Future<void>? _baseDataLoadFuture;

  @override
  StatisticsState build() {
    Future.microtask(_loadInitial);
    return StatisticsState(isLoading: true, muscleMapLoading: true);
  }

  Future<void> _loadInitial() async {
    await _ensureBaseData(forceReload: true);
    state = state.copyWith(
      data: await _buildStats('month'),
      muscleMapWeekData: await _buildMuscleMapStats(),
      isLoading: false,
      muscleMapLoading: false,
      clearError: true,
      clearMuscleMapError: true,
    );
  }

  Future<void> fetchStatistics(String uiPeriod, {bool forceReload = false}) async {
    await _refreshCharts(uiPeriod, forceReload: forceReload);
  }

  Future<void> fetchMuscleMapWeek({bool forceReload = false}) async {
    await _refreshMuscleMap(forceReload: forceReload);
  }

  Future<void> _refreshCharts(String uiPeriod, {bool forceReload = false}) async {
    final apiPeriod = statisticsPeriodToApi(uiPeriod);
    state = state.copyWith(
      isLoading: true,
      selectedPeriod: uiPeriod,
      clearError: true,
    );

    try {
      await _ensureBaseData(forceReload: forceReload);
      state = state.copyWith(
        data: await _buildStats(apiPeriod),
        isLoading: false,
        clearError: true,
      );
    } catch (e, stack) {
      debugPrint('Statistics charts error: $e\n$stack');
      if (_cachedWorkouts != null) {
        state = state.copyWith(
          data: await _buildStats(apiPeriod),
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudieron cargar las estadísticas. Comprueba tu conexión.',
        );
      }
    }
  }

  Future<void> _refreshMuscleMap({bool forceReload = false}) async {
    state = state.copyWith(muscleMapLoading: true, clearMuscleMapError: true);

    try {
      await _ensureBaseData(forceReload: forceReload);
      state = state.copyWith(
        muscleMapWeekData: await _buildMuscleMapStats(),
        muscleMapLoading: false,
        clearMuscleMapError: true,
      );
    } catch (e, stack) {
      debugPrint('Muscle map error: $e\n$stack');
      if (_cachedWorkouts != null) {
        state = state.copyWith(
          muscleMapWeekData: await _buildMuscleMapStats(),
          muscleMapLoading: false,
          clearMuscleMapError: true,
        );
      } else {
        state = state.copyWith(
          muscleMapLoading: false,
          muscleMapError:
              'No se pudo cargar el mapa muscular. Comprueba tu conexión.',
        );
      }
    }
  }

  /// Una sola carga compartida (evita carreras entre gráficos y mapa).
  Future<void> _ensureBaseData({bool forceReload = false}) async {
    if (!forceReload && _cachedWorkouts != null && _cachedMuscleMap != null) {
      return;
    }

    if (_baseDataLoadFuture != null && !forceReload) {
      await _baseDataLoadFuture;
      return;
    }

    _baseDataLoadFuture = _loadBaseData(forceReload);
    try {
      await _baseDataLoadFuture;
    } finally {
      _baseDataLoadFuture = null;
    }
  }

  Future<void> _loadBaseData(bool forceReload) async {
    if (!forceReload && _cachedWorkouts != null && _cachedMuscleMap != null) {
      return;
    }

    List<WorkoutSession> workouts = [];
    Map<int, String> muscleMap = {};

    try {
      workouts = await _loadWorkoutsWithSets(forceReload: forceReload);
    } catch (e, stack) {
      debugPrint('Workouts load error: $e\n$stack');
      workouts = _cachedWorkouts ?? [];
    }

    try {
      muscleMap = await _fetchExerciseMuscleMap(forceReload: forceReload);
    } catch (e, stack) {
      debugPrint('Exercises map error: $e\n$stack');
      muscleMap = _cachedMuscleMap ?? {};
    }

    _cachedWorkouts = workouts;
    _cachedMuscleMap = muscleMap;
  }

  Future<void> ensureWorkoutsForStreak() => _ensureBaseData();

  List<WorkoutSession> get cachedWorkoutsForStreak => _cachedWorkouts ?? [];

  UserStatistics _buildStatsLocal(String apiPeriod) {
    final user = ref.read(authProvider).user;
    final daysPerWeek = (user?['workout_days_per_week'] as num?)?.toInt() ?? 3;
    return buildStatisticsFromWorkouts(
      workouts: _cachedWorkouts ?? [],
      exerciseMuscleById: _cachedMuscleMap ?? {},
      apiPeriod: apiPeriod,
      workoutDaysPerWeek: daysPerWeek,
    );
  }

  Future<UserStatistics> _buildStats(String apiPeriod) async {
    final local = _buildStatsLocal(apiPeriod);
    final fromApi = await fetchUserStatisticsFromApi(apiPeriod, client: _api);
    if (fromApi == null) return local;
    return _mergeWithLocal(fromApi, local);
  }

  Future<UserStatistics> _buildMuscleMapStats() async {
    final local = _buildStatsLocal(muscleMapApiPeriod);
    final fromApi = await fetchUserStatisticsFromApi(
      muscleMapApiPeriod,
      client: _api,
    );
    if (fromApi == null) return local;
    return _mergeWithLocal(fromApi, local);
  }

  /// API para agregados; local para progreso completo por ejercicio.
  UserStatistics _mergeWithLocal(
    UserStatistics api,
    UserStatistics local,
  ) {
    final progressById = {
      for (final e in local.exerciseProgress) e.exerciseId: e,
    };
    final mergedProgress = <ExerciseProgress>[];
    final seen = <int>{};
    for (final e in api.exerciseProgress) {
      mergedProgress.add(progressById[e.exerciseId] ?? e);
      seen.add(e.exerciseId);
    }
    for (final e in local.exerciseProgress) {
      if (!seen.contains(e.exerciseId)) {
        mergedProgress.add(e);
      }
    }

    return api.copyWith(exerciseProgress: mergedProgress);
  }

  Future<List<WorkoutSession>> _loadWorkoutsWithSets({
    bool forceReload = false,
  }) async {
    if (!forceReload && _cachedWorkouts != null) {
      return _cachedWorkouts!;
    }

    await ref.read(workoutHistoryProvider.notifier).fetchWorkouts();
    var workouts = ref.read(workoutHistoryProvider).workouts;
    if (workouts.isEmpty) {
      workouts = await fetchAllWorkoutSessionsSafe(client: _api);
    }
    return _ensureWorkoutsHaveSets(workouts);
  }

  Future<List<WorkoutSession>> _ensureWorkoutsHaveSets(
    List<WorkoutSession> workouts,
  ) async {
    final missing = workouts
        .where((w) => w.id != null && w.sets.isEmpty)
        .toList();
    if (missing.isEmpty) return workouts;

    missing.sort((a, b) => b.startTime.compareTo(a.startTime));
    final idsToFetch = missing.take(20).map((w) => w.id!).toList();

    final details = await Future.wait(
      idsToFetch.map((id) async {
        try {
          final response = await _api.get('workouts/$id/');
          return MapEntry(
            id,
            WorkoutSession.fromJson(
              Map<String, dynamic>.from(response.data as Map),
            ),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    final byId = <int, WorkoutSession>{
      for (final entry in details)
        if (entry != null) entry.key: entry.value,
    };

    return workouts
        .map((w) => w.id != null && byId.containsKey(w.id!) ? byId[w.id!]! : w)
        .toList();
  }

  Future<Map<int, String>> _fetchExerciseMuscleMap({
    bool forceReload = false,
  }) async {
    if (!forceReload && _cachedMuscleMap != null) {
      return _cachedMuscleMap!;
    }

    if (!forceReload) {
      final fromProvider = ref.read(exerciseProvider);
      if (fromProvider.exercises.isNotEmpty) {
        return _muscleMapFromExercises(fromProvider.exercises);
      }
    }

    final all = <Exercise>[];
    String? nextUrl = 'exercises/';

    while (nextUrl != null) {
      final response = await _api.get(nextUrl);
      all.addAll(_parseExerciseList(response.data));
      nextUrl = _nextPagePath(response.data);
    }

    return _muscleMapFromExercises(all);
  }

  Map<int, String> _muscleMapFromExercises(List<Exercise> exercises) {
    final map = <int, String>{};
    for (final e in exercises) {
      map[e.id] = e.muscleGroup;
    }
    return map;
  }

  List<Exercise> _parseExerciseList(dynamic data) {
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['results'] is List) {
      list = data['results'] as List;
    }

    final exercises = <Exercise>[];
    for (final item in list) {
      try {
        if (item is! Map) continue;
        final raw = Map<String, dynamic>.from(item);
        final id = raw['id'];
        if (id == null) continue;
        exercises.add(Exercise.fromJson(raw));
      } catch (_) {
        continue;
      }
    }
    return exercises;
  }

  String? _nextPagePath(dynamic data) {
    if (data is! Map) return null;
    final next = data['next'];
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
}

/// Parseo tolerante de sesiones.
Future<List<WorkoutSession>> fetchAllWorkoutSessionsSafe({Dio? client}) async {
  final dio = client ?? apiClient;
  final all = <WorkoutSession>[];
  String? nextUrl = 'workouts/';

  while (nextUrl != null) {
    final response = await dio.get(
      nextUrl,
      queryParameters:
          nextUrl == 'workouts/' ? {'ordering': '-start_time'} : null,
    );

    final data = response.data;
    if (data is List) {
      for (final item in data) {
        try {
          if (item is Map) {
            all.add(WorkoutSession.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (_) {}
      }
      break;
    }

    if (data is Map) {
      final results = data['results'];
      if (results is List) {
        for (final item in results) {
          try {
            if (item is Map) {
              all.add(
                WorkoutSession.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          } catch (_) {}
        }
      }
      final next = data['next'];
      if (next is String && next.isNotEmpty) {
        final uri = Uri.parse(next);
        var path = uri.path;
        const apiPrefix = '/api/';
        if (path.startsWith(apiPrefix)) {
          path = path.substring(apiPrefix.length);
        } else if (path.startsWith('/')) {
          path = path.substring(1);
        }
        nextUrl = uri.hasQuery ? '$path?${uri.query}' : path;
      } else {
        nextUrl = null;
      }
    } else {
      break;
    }
  }

  return all;
}

final statisticsProvider =
    NotifierProvider<StatisticsNotifier, StatisticsState>(() {
  return StatisticsNotifier();
});
