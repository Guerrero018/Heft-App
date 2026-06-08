import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_constants.dart';
import 'pending_workout_model.dart';

class OfflineStorageService {
  OfflineStorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> saveActiveWorkoutDraft(Map<String, dynamic> draft) async {
    await _prefs.setString(
      OfflineConstants.activeWorkoutDraftKey,
      jsonEncode(draft),
    );
  }

  Map<String, dynamic>? readActiveWorkoutDraft() {
    final raw = _prefs.getString(OfflineConstants.activeWorkoutDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveWorkoutDraft() async {
    await _prefs.remove(OfflineConstants.activeWorkoutDraftKey);
  }

  List<PendingWorkout> readPendingWorkouts() {
    final raw = _prefs.getString(OfflineConstants.pendingWorkoutsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingWorkout.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePendingWorkouts(List<PendingWorkout> workouts) async {
    if (workouts.isEmpty) {
      await _prefs.remove(OfflineConstants.pendingWorkoutsKey);
      return;
    }
    final encoded = jsonEncode(workouts.map((w) => w.toJson()).toList());
    await _prefs.setString(OfflineConstants.pendingWorkoutsKey, encoded);
  }

  Future<void> enqueuePendingWorkout(PendingWorkout workout) async {
    final current = readPendingWorkouts();
    current.add(workout);
    await savePendingWorkouts(current);
  }

  Future<void> removePendingWorkout(String localId) async {
    final current = readPendingWorkouts()
      ..removeWhere((w) => w.localId == localId);
    await savePendingWorkouts(current);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final offlineStorageServiceProvider = FutureProvider<OfflineStorageService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return OfflineStorageService(prefs);
});
