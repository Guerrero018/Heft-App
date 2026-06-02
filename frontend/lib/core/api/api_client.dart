import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants.dart';
import 'token_refresh_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  late final Dio _refreshDio;

  ApiClient() {
    final baseOptions = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    );

    _dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);

    _dio.interceptors.add(
      TokenRefreshInterceptor(dio: _dio, refreshDio: _refreshDio),
    );
  }

  Dio get client => _dio;
}

final apiClient = ApiClient().client;

final apiClientProvider = Provider<Dio>((ref) => apiClient);
