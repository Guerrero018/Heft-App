import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../features/achievements/data/achievements_provider.dart';
import '../../features/statistics/data/statistics_provider.dart';
import '../../features/workouts/data/workout_provider.dart';
import 'connectivity_provider.dart';
import 'offline_storage_service.dart';
import 'pending_workout_model.dart';

class OfflineSyncState {
  final List<PendingWorkout> pendingWorkouts;
  final bool isSyncing;
  final String? lastError;

  const OfflineSyncState({
    this.pendingWorkouts = const [],
    this.isSyncing = false,
    this.lastError,
  });

  int get pendingCount => pendingWorkouts.length;

  OfflineSyncState copyWith({
    List<PendingWorkout>? pendingWorkouts,
    bool? isSyncing,
    String? lastError,
  }) {
    return OfflineSyncState(
      pendingWorkouts: pendingWorkouts ?? this.pendingWorkouts,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError,
    );
  }
}

class OfflineSyncNotifier extends Notifier<OfflineSyncState> {
  OfflineStorageService? _storage;
  bool _initialized = false;

  @override
  OfflineSyncState build() {
    ref.listen(connectivityProvider, (previous, next) {
      if (previous?.isOnline == false && next.isOnline) {
        syncPendingWorkouts();
      }
    });

    Future.microtask(_init);
    return const OfflineSyncState();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _getStorage();
    await reloadPending();
    if (ref.read(connectivityProvider).isOnline) {
      await syncPendingWorkouts();
    }
  }

  Future<OfflineStorageService> _getStorage() async {
    if (_storage != null) return _storage!;
    _storage = await ref.read(offlineStorageServiceProvider.future);
    return _storage!;
  }

  Future<void> reloadPending() async {
    final storage = await _getStorage();
    state = state.copyWith(
      pendingWorkouts: storage.readPendingWorkouts(),
      lastError: null,
    );
  }

  Future<bool> enqueueWorkout(Map<String, dynamic> payload) async {
    final storage = await _getStorage();
    final pending = PendingWorkout(payload: payload);
    await storage.enqueuePendingWorkout(pending);
    await reloadPending();
    return true;
  }

  Future<void> syncPendingWorkouts() async {
    if (state.isSyncing) return;
    if (!ref.read(connectivityProvider).isOnline) return;

    final storage = await _getStorage();
    final pending = storage.readPendingWorkouts();
    if (pending.isEmpty) return;

    state = state.copyWith(isSyncing: true, lastError: null);
    final dio = ref.read(apiClientProvider);
    final unlockedBaseline = {
      for (final a in ref.read(achievementsProvider).achievements)
        if (a.isUnlocked) a.id,
    };

    var syncedAny = false;
    String? lastError;

    for (final workout in pending) {
      try {
        await dio.post('workouts/', data: workout.payload);
        await storage.removePendingWorkout(workout.localId);
        syncedAny = true;
      } on DioException catch (e) {
        lastError = e.message ?? 'Error de red';
        debugPrint('Offline sync failed for ${workout.localId}: $e');
        final updated = workout.copyWith(retryCount: workout.retryCount + 1);
        final remaining = storage.readPendingWorkouts();
        final index = remaining.indexWhere((w) => w.localId == workout.localId);
        if (index >= 0) {
          remaining[index] = updated;
          await storage.savePendingWorkouts(remaining);
        }
        break;
      } catch (e) {
        lastError = e.toString();
        debugPrint('Offline sync unexpected error: $e');
        break;
      }
    }

    await reloadPending();

    if (syncedAny) {
      ref.read(workoutHistoryProvider.notifier).fetchWorkouts();
      ref.invalidate(statisticsProvider);
      await ref.read(achievementsProvider.notifier).sync(
            unlockedBaseline: unlockedBaseline,
          );
    }

    state = state.copyWith(
      isSyncing: false,
      lastError: state.pendingWorkouts.isNotEmpty ? lastError : null,
    );
  }
}

final offlineSyncProvider =
    NotifierProvider<OfflineSyncNotifier, OfflineSyncState>(
  OfflineSyncNotifier.new,
);
