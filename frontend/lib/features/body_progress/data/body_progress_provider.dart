import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../achievements/data/achievements_provider.dart';
import '../domain/body_measure_model.dart';
import 'body_progress_api.dart';

class BodyProgressState {
  final List<BodyMeasureEntry> entries;
  final List<WeightHistoryPoint> weightHistory;
  final bool isLoading;
  final String? error;

  const BodyProgressState({
    this.entries = const [],
    this.weightHistory = const [],
    this.isLoading = false,
    this.error,
  });

  List<BodyMeasureEntry> get photoEntries =>
      entries.where((e) => e.hasPhoto).toList();

  BodyProgressState copyWith({
    List<BodyMeasureEntry>? entries,
    List<WeightHistoryPoint>? weightHistory,
    bool? isLoading,
    String? error,
  }) {
    return BodyProgressState(
      entries: entries ?? this.entries,
      weightHistory: weightHistory ?? this.weightHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BodyProgressNotifier extends Notifier<BodyProgressState> {
  @override
  BodyProgressState build() => const BodyProgressState();

  Future<void> loadAll({bool force = false}) async {
    if (!force && state.entries.isNotEmpty && !state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('body-measures/');
      final entries = _parseEntries(response.data);
      final history = _weightHistoryFromEntries(entries);

      state = state.copyWith(
        entries: entries,
        weightHistory: history,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyBodyProgressError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  List<BodyMeasureEntry> _parseEntries(dynamic data) {
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['results'] is List) {
      list = data['results'] as List;
    }
    final entries = list
        .map((json) => BodyMeasureEntry.fromJson(json as Map<String, dynamic>))
        .toList();
    entries.sort(compareBodyMeasureEntriesDesc);
    return entries;
  }

  List<WeightHistoryPoint> _weightHistoryFromEntries(
    List<BodyMeasureEntry> entries,
  ) {
    final sorted = [...entries]..sort(compareBodyMeasureEntriesAsc);
    return sorted
        .map((e) => WeightHistoryPoint(date: e.date, weight: e.weight))
        .toList();
  }

  Future<bool> createEntry({
    required double weight,
    required DateTime date,
    String notes = '',
    List<String> imagePaths = const [],
    double? neckCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? shouldersCm,
    double? bicepLeftCm,
    double? bicepRightCm,
    double? thighLeftCm,
    double? thighRightCm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final unlockedBaseline = {
      for (final a in ref.read(achievementsProvider).achievements)
        if (a.isUnlocked) a.id,
    };
    try {
      final formMap = <String, dynamic>{
        'weight': weight,
        'date': _formatDate(date),
        if (notes.isNotEmpty) 'notes': notes,
        if (neckCm != null) 'neck_cm': neckCm,
        if (chestCm != null) 'chest_cm': chestCm,
        if (waistCm != null) 'waist_cm': waistCm,
        if (hipsCm != null) 'hips_cm': hipsCm,
        if (shouldersCm != null) 'shoulders_cm': shouldersCm,
        if (bicepLeftCm != null) 'bicep_left_cm': bicepLeftCm,
        if (bicepRightCm != null) 'bicep_right_cm': bicepRightCm,
        if (thighLeftCm != null) 'thigh_left_cm': thighLeftCm,
        if (thighRightCm != null) 'thigh_right_cm': thighRightCm,
      };

      final hasImages = imagePaths.isNotEmpty;
      dynamic payload = formMap;
      if (hasImages) {
        final formData = FormData.fromMap(formMap);
        for (var i = 0; i < imagePaths.length; i++) {
          formData.files.add(
            MapEntry(
              'photos',
              await MultipartFile.fromFile(
                imagePaths[i],
                filename: 'progress_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                contentType: DioMediaType('image', 'jpeg'),
              ),
            ),
          );
        }
        payload = formData;
      }

      await apiClient.post('body-measures/', data: payload);
      await loadAll(force: true);
      await ref.read(achievementsProvider.notifier).sync(
            unlockedBaseline: unlockedBaseline,
          );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyBodyProgressError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      await apiClient.delete('body-measures/$id/');
      await loadAll(force: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.message ?? 'No se pudo eliminar el registro',
      );
      return false;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final bodyProgressProvider =
    NotifierProvider<BodyProgressNotifier, BodyProgressState>(
  BodyProgressNotifier.new,
);
