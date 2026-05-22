import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/session_manager.dart';
import 'constants.dart';

/// Renueva el access token con `auth/refresh/` y reintenta peticiones con 401.
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required Dio refreshDio,
    FlutterSecureStorage? storage,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final Dio _refreshDio;
  final FlutterSecureStorage _storage;

  Completer<String?>? _refreshCompleter;

  static bool _shouldSkipRefresh(RequestOptions options) {
    final path = options.uri.path.toLowerCase();
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/register') ||
        path.contains('/auth/check-email') ||
        path.contains('/auth/password-reset') ||
        path.contains('/auth/social/');
  }

  Future<String?> _getNewAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null || refresh.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        'auth/refresh/',
        data: {'refresh': refresh},
      );

      final access = response.data?['access'] as String?;
      if (access == null || access.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      await _storage.write(key: AppConstants.tokenKey, value: access);

      final newRefresh = response.data?['refresh'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefresh,
        );
      }

      _refreshCompleter!.complete(access);
      return access;
    } on DioException {
      _refreshCompleter!.complete(null);
      return null;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await SessionManager.notifySessionExpired();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_shouldSkipRefresh(err.requestOptions)) {
      return handler.next(err);
    }

    final newAccess = await _getNewAccessToken();
    if (newAccess == null) {
      await _clearSession();
      return handler.next(err);
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final response = await _dio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
