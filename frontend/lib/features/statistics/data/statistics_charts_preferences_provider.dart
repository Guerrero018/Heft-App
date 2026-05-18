import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../exercises/domain/exercise_model.dart';

const _storageKeyV2 = 'statistics_pinned_exercise_charts';
const _legacyIdsKey = 'statistics_pinned_exercise_ids';

/// Ejercicio fijado en la pestaña Gráficos (persiste hasta que el usuario lo quite).
class PinnedExerciseRef {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;

  const PinnedExerciseRef({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
  });

  factory PinnedExerciseRef.fromExercise(Exercise exercise) {
    return PinnedExerciseRef(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.muscleGroup,
    );
  }

  factory PinnedExerciseRef.fromJson(Map<String, dynamic> json) {
    return PinnedExerciseRef(
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
      };
}

class PinnedExerciseChartsNotifier extends Notifier<List<PinnedExerciseRef>> {
  @override
  List<PinnedExerciseRef> build() {
    Future.microtask(_loadFromPrefs);
    return const [];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKeyV2);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        state = list
            .map((e) => PinnedExerciseRef.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
        return;
      } catch (_) {}
    }

    final legacy = prefs.getStringList(_legacyIdsKey) ?? [];
    if (legacy.isNotEmpty) {
      state = legacy
          .map(
            (id) => PinnedExerciseRef(
              exerciseId: int.parse(id),
              exerciseName: '',
              muscleGroup: '',
            ),
          )
          .toList();
      await _save();
      await prefs.remove(_legacyIdsKey);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKeyV2, encoded);
  }

  Future<void> pin(Exercise exercise) async {
    final next = [
      ...state.where((e) => e.exerciseId != exercise.id),
      PinnedExerciseRef.fromExercise(exercise),
    ];
    state = next;
    await _save();
  }

  Future<void> unpin(int exerciseId) async {
    state = state.where((e) => e.exerciseId != exerciseId).toList();
    await _save();
  }

  Set<int> get pinnedIds => state.map((e) => e.exerciseId).toSet();
}

final pinnedExerciseChartsProvider =
    NotifierProvider<PinnedExerciseChartsNotifier, List<PinnedExerciseRef>>(
  PinnedExerciseChartsNotifier.new,
);
