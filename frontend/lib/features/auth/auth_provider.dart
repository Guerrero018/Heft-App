import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.error});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    // We can check auth here or in main.dart
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await apiClient.post(
        'auth/login/',
        data: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];

        await _storage.write(key: AppConstants.tokenKey, value: access);
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);

        state = state.copyWith(isLoading: false, isAuthenticated: true);
      }
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await apiClient.post(
        'auth/register/',
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final tokens = response.data['tokens'];
        if (tokens != null) {
          final access = tokens['access'];
          final refresh = tokens['refresh'];

          await _storage.write(key: AppConstants.tokenKey, value: access);
          await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: refresh,
          );

          state = state.copyWith(isLoading: false, isAuthenticated: true);
        } else {
          await login(username, password);
        }
      }
    } on DioException catch (e) {
      String message = 'Registration failed';
      if (e.response != null) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          message =
              data['detail'] ??
              (data['username'] != null ? data['username'][0] : null) ??
              (data['email'] != null ? data['email'][0] : null) ??
              (data['password'] != null ? data['password'][0] : null) ??
              data.toString();
        } else {
          message = 'Server error: ${e.response?.statusCode}';
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    state = AuthState(isAuthenticated: false);
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
