import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'notification_preferences_model.dart';

class NotificationPreferencesState {
  final NotificationPreferences? prefs;
  final bool isLoading;
  final String? error;

  const NotificationPreferencesState({
    this.prefs,
    this.isLoading = false,
    this.error,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferences? prefs,
    bool? isLoading,
    String? error,
  }) {
    return NotificationPreferencesState(
      prefs: prefs ?? this.prefs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferencesState> {
  @override
  NotificationPreferencesState build() {
    Future.microtask(load);
    return const NotificationPreferencesState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('notifications/preferences/');
      final prefs = NotificationPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      state = state.copyWith(prefs: prefs, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?.toString() ?? 'Error al cargar preferencias',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado al cargar preferencias',
      );
    }
  }

  /// Optimistically updates UI then patches the backend.
  Future<void> update(NotificationPreferences updated) async {
    final previous = state.prefs;
    state = state.copyWith(prefs: updated);
    try {
      await apiClient.patch(
        'notifications/preferences/',
        data: updated.toJson(),
      );
    } on DioException catch (e) {
      // Revert on failure
      state = state.copyWith(
        prefs: previous,
        error: e.response?.data?.toString() ?? 'Error al guardar preferencias',
      );
    } catch (_) {
      state = state.copyWith(
        prefs: previous,
        error: 'Error inesperado al guardar preferencias',
      );
    }
  }
}

final notificationPreferencesProvider = NotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>(
  NotificationPreferencesNotifier.new,
);
