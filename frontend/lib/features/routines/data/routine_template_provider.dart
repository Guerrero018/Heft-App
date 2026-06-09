import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/routine_model.dart';
import 'routine_provider.dart';
import 'routine_template_api.dart';

class RoutineTemplateState {
  final List<RoutineTemplate> templates;
  final bool isLoading;
  final bool isImporting;
  final String? error;
  final String searchQuery;
  final bool officialOnly;

  const RoutineTemplateState({
    this.templates = const [],
    this.isLoading = false,
    this.isImporting = false,
    this.error,
    this.searchQuery = '',
    this.officialOnly = false,
  });

  RoutineTemplateState copyWith({
    List<RoutineTemplate>? templates,
    bool? isLoading,
    bool? isImporting,
    String? error,
    String? searchQuery,
    bool? officialOnly,
    bool clearError = false,
  }) {
    return RoutineTemplateState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      officialOnly: officialOnly ?? this.officialOnly,
    );
  }
}

class RoutineTemplateNotifier extends Notifier<RoutineTemplateState> {
  Dio get _api => ref.read(apiClientProvider);

  @override
  RoutineTemplateState build() => const RoutineTemplateState();

  List<RoutineTemplate> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((json) => RoutineTemplate.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => RoutineTemplate.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  Future<void> fetchTemplates({
    String? search,
    bool? officialOnly,
  }) async {
    final query = search ?? state.searchQuery;
    final official = officialOnly ?? state.officialOnly;

    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      officialOnly: official,
      clearError: true,
    );

    try {
      final params = <String, dynamic>{};
      if (query.trim().isNotEmpty) {
        params['search'] = query.trim();
      }
      if (official) {
        params['official'] = 'true';
      }

      final response = await _api.get(
        'routine-templates/',
        queryParameters: params.isEmpty ? null : params,
      );

      state = state.copyWith(
        templates: _parseList(response.data),
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyRoutineTemplatesError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  Future<RoutineTemplate?> fetchTemplateDetail(int id) async {
    try {
      final response = await _api.get('routine-templates/$id/');
      return RoutineTemplate.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Routine?> importTemplate(int templateId) async {
    state = state.copyWith(isImporting: true, clearError: true);
    try {
      final response = await _api.post(
        'routine-templates/$templateId/import_template/',
      );
      final routine = Routine.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await ref.read(routineProvider.notifier).fetchRoutines(silent: true);
      state = state.copyWith(isImporting: false, clearError: true);
      return routine;
    } on DioException catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: friendlyRoutineTemplatesError(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      rethrow;
    }
  }

  Future<RoutineTemplate?> previewByShareCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final response = await _api.get('routines/shared/$normalized/');
      return RoutineTemplate.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Routine?> importByShareCode(String code) async {
    final normalized = code.trim().toUpperCase();
    state = state.copyWith(isImporting: true, clearError: true);
    try {
      final response = await _api.post('routines/shared/$normalized/import/');
      final routine = Routine.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await ref.read(routineProvider.notifier).fetchRoutines(silent: true);
      state = state.copyWith(isImporting: false, clearError: true);
      return routine;
    } on DioException catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: friendlyRoutineTemplatesError(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      rethrow;
    }
  }
}

final routineTemplateProvider =
    NotifierProvider<RoutineTemplateNotifier, RoutineTemplateState>(
  RoutineTemplateNotifier.new,
);
