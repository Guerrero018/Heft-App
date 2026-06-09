import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../achievements/data/achievements_provider.dart';
import '../domain/exercise_model.dart';

class ExerciseQuery {
  final String search;
  final String muscleGroup;
  final String exerciseType;

  const ExerciseQuery({
    this.search = '',
    this.muscleGroup = 'all',
    this.exerciseType = 'all',
  });

  ExerciseQuery copyWith({
    String? search,
    String? muscleGroup,
    String? exerciseType,
  }) {
    return ExerciseQuery(
      search: search ?? this.search,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      exerciseType: exerciseType ?? this.exerciseType,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (muscleGroup != 'all') {
      params['muscle_group'] = muscleGroup;
    }
    if (exerciseType != 'all') {
      params['exercise_type'] = exerciseType;
    }
    return params;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseQuery &&
          search == other.search &&
          muscleGroup == other.muscleGroup &&
          exerciseType == other.exerciseType;

  @override
  int get hashCode => Object.hash(search, muscleGroup, exerciseType);
}

class ExerciseState {
  final List<Exercise> exercises;
  final List<Exercise> popularExercises;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextPageUrl;
  final int totalCount;
  final ExerciseQuery query;
  final String? error;

  ExerciseState({
    this.exercises = const [],
    this.popularExercises = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.nextPageUrl,
    this.totalCount = 0,
    this.query = const ExerciseQuery(),
    this.error,
  });

  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;

  ExerciseState copyWith({
    List<Exercise>? exercises,
    List<Exercise>? popularExercises,
    bool? isLoading,
    bool? isLoadingMore,
    String? nextPageUrl,
    bool clearNextPageUrl = false,
    int? totalCount,
    ExerciseQuery? query,
    String? error,
    bool clearError = false,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      popularExercises: popularExercises ?? this.popularExercises,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageUrl: clearNextPageUrl ? null : (nextPageUrl ?? this.nextPageUrl),
      totalCount: totalCount ?? this.totalCount,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExerciseNotifier extends Notifier<ExerciseState> {
  Dio get _api => ref.read(apiClientProvider);

  @override
  ExerciseState build() {
    return ExerciseState();
  }

  List<Exercise> _parseExerciseList(dynamic data) {
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['results'] is List) {
      list = data['results'] as List;
    }
    return list.map((json) => Exercise.fromJson(json)).toList();
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

  ({List<Exercise> items, String? next, int? count}) _parsePage(dynamic data) {
    if (data is List) {
      return (items: _parseExerciseList(data), next: null, count: data.length);
    }
    if (data is Map) {
      return (
        items: _parseExerciseList(data),
        next: _nextPagePath(data['next']),
        count: data['count'] is int ? data['count'] as int : null,
      );
    }
    return (items: <Exercise>[], next: null, count: null);
  }

  Future<void> fetchExercises({ExerciseQuery? query}) async {
    final q = query ?? state.query;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      query: q,
      exercises: [],
      clearNextPageUrl: true,
      totalCount: 0,
    );

    try {
      final response = await _api.get(
        'exercises/',
        queryParameters: q.toQueryParams(),
      );
      final page = _parsePage(response.data);
      state = state.copyWith(
        exercises: page.items,
        isLoading: false,
        nextPageUrl: page.next,
        clearNextPageUrl: page.next == null,
        totalCount: page.count ?? page.items.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final nextUrl = state.nextPageUrl;
    if (nextUrl == null || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final response = await _api.get(nextUrl);
      final page = _parsePage(response.data);
      state = state.copyWith(
        exercises: [...state.exercises, ...page.items],
        isLoadingMore: false,
        nextPageUrl: page.next,
        clearNextPageUrl: page.next == null,
        totalCount: page.count ?? state.totalCount,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> fetchPopularExercises() async {
    try {
      final response = await _api.get('exercises/popular/');
      final items = _parseExerciseList(response.data);
      if (items.isNotEmpty) {
        state = state.copyWith(popularExercises: items);
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
    final unlockedBaseline = {
      for (final a in ref.read(achievementsProvider).achievements)
        if (a.isUnlocked) a.id,
    };
    try {
      final response = await _api.post(
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
        totalCount: state.totalCount + 1,
      );
      await ref.read(achievementsProvider.notifier).sync(
            unlockedBaseline: unlockedBaseline,
          );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Exercise?> fetchExerciseById(int id) async {
    try {
      final response = await _api.get('exercises/$id/');
      return Exercise.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

final exerciseProvider = NotifierProvider<ExerciseNotifier, ExerciseState>(() {
  return ExerciseNotifier();
});
