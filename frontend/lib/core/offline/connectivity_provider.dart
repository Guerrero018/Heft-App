import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

/// True when the device reports a network interface and the API is reachable.
class ConnectivityState {
  final bool hasNetworkInterface;
  final bool isOnline;

  const ConnectivityState({
    this.hasNetworkInterface = true,
    this.isOnline = true,
  });

  bool get isOffline => !isOnline;
}

class ConnectivityNotifier extends Notifier<ConnectivityState> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityState build() {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });
    ref.onDispose(() => _subscription?.cancel());

    Future.microtask(_refresh);
    return const ConnectivityState();
  }

  Future<void> _refresh() async {
    final results = await Connectivity().checkConnectivity();
    await _onConnectivityChanged(results);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) {
      state = const ConnectivityState(
        hasNetworkInterface: false,
        isOnline: false,
      );
      return;
    }

    state = ConnectivityState(
      hasNetworkInterface: true,
      isOnline: await _canReachApi(),
    );
  }

  Future<bool> _canReachApi() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        'exercises/',
        queryParameters: {'limit': 1},
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      return response.statusCode != null && response.statusCode! < 500;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return false;
      }
      // Auth errors, 404, etc. mean the server is reachable.
      return e.response != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => _refresh();
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityState>(
  ConnectivityNotifier.new,
);
