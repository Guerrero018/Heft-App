import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';
import '../../core/auth/session_manager.dart';
import '../../core/notifications/notification_service.dart';

String extractApiErrorMessage(
  dynamic data, {
  required List<String> keys,
  required String fallback,
}) {
  if (data is! Map) {
    return fallback;
  }

  for (final key in keys) {
    final value = data[key];
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value != null) {
      return value.toString();
    }
  }

  return fallback;
}

class AuthState {
  final bool isAuthenticated;

  /// Carga de login/registro/Google (no debe reemplazar toda la app).
  final bool isLoading;

  /// Solo verificación de sesión al arrancar (splash en main.dart).
  final bool isInitializing;
  final bool isOnboarded;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = false,
    this.isOnboarded = false,
    this.user,
    this.error,
  });

  static const Object _unset = Object();

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    bool? isOnboarded,
    Map<String, dynamic>? user,
    Object? error = _unset,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      user: user ?? this.user,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

String _mapLoginErrorMessage(String? message) {
  if (message == null || message.isEmpty) {
    return 'La contraseña es incorrecta';
  }
  final lower = message.toLowerCase();
  if (lower.contains('credential') ||
      lower.contains('password') ||
      lower.contains('contraseña') ||
      lower.contains('incorrect') ||
      lower.contains('invalid') ||
      lower.contains('no active account')) {
    return 'La contraseña es incorrecta';
  }
  return message;
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  Future<String?> _restoreAccessTokenWithRefresh() async {
    final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refresh == null || refresh.isEmpty) {
      return null;
    }

    final baseOptions = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    );
    final refreshClient = Dio(baseOptions);

    try {
      final response = await refreshClient.post<Map<String, dynamic>>(
        'auth/refresh/',
        data: {'refresh': refresh},
      );
      final access = response.data?['access'] as String?;
      if (access == null || access.isEmpty) {
        return null;
      }

      await _storage.write(key: AppConstants.tokenKey, value: access);
      final rotatedRefresh = response.data?['refresh'] as String?;
      if (rotatedRefresh != null && rotatedRefresh.isNotEmpty) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: rotatedRefresh,
        );
      }
      return access;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    } finally {
      refreshClient.close();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  AuthState build() {
    SessionManager.onSessionExpired = logout;
    Future.microtask(() => checkAuth());
    return AuthState(isInitializing: true);
  }

  Future<bool?> checkEmail(String email) async {
    try {
      final response = await apiClient.post(
        'auth/check-email/',
        data: {'email': email},
      );
      return response.data['exists'] ?? false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        state = state.copyWith(
          error: 'El servidor está despertando, por favor intenta de nuevo',
        );
      } else {
        state = state.copyWith(error: 'Error de conexión. Revisa tu internet.');
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Error inesperado');
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await apiClient.post(
        'auth/login/',
        data: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'] as String?;
        final refresh = response.data['refresh'] as String?;

        if (access == null || refresh == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Respuesta inesperada del servidor.',
          );
          return;
        }

        await _storage.write(key: AppConstants.tokenKey, value: access);
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);

        final user = response.data['user'];
        final isOnboarded = user != null ? user['is_onboarded'] == true : false;

        await _storage.write(
          key: AppConstants.onboardedKey,
          value: isOnboarded.toString(),
        );
        if (user != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(user));
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOnboarded: isOnboarded,
          user: user,
        );

        // Register FCM token (fire-and-forget)
        final fcmToken = NotificationService.instance.currentToken;
        if (fcmToken != null) {
          NotificationService.instance.registerTokenWithBackend(fcmToken);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error inesperado del servidor (${response.statusCode}).',
        );
      }
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      if (isTimeout) {
        state = state.copyWith(
          isLoading: false,
          error: 'El servidor tardó demasiado. Inténtalo de nuevo en unos segundos.',
        );
        return;
      }
      final raw = e.response?.data['detail'] ?? e.response?.data['error'];
      final message = _mapLoginErrorMessage(raw?.toString());
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ha ocurrido un error inesperado',
      );
    }
  }

  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await apiClient.post(
        'auth/password-reset/request/',
        data: {'email': email.trim()},
      );

      state = state.copyWith(isLoading: false, error: null);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final message = extractApiErrorMessage(
        e.response?.data,
        keys: const ['detail', 'email', 'non_field_errors'],
        fallback: 'No se pudo solicitar el código de recuperación',
      );
      state = state.copyWith(isLoading: false, error: message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado al solicitar la recuperación',
      );
      return null;
    }
  }

  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await apiClient.post(
        'auth/password-reset/confirm/',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      state = state.copyWith(isLoading: false, error: null);
      return true;
    } on DioException catch (e) {
      final message = extractApiErrorMessage(
        e.response?.data,
        keys: const [
          'detail',
          'code',
          'new_password',
          'confirm_password',
          'email',
          'non_field_errors',
        ],
        fallback: 'No se pudo actualizar la contraseña',
      );
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado al restablecer la contraseña',
      );
      return false;
    }
  }

  Future<void> register(
    String username,
    String email,
    String password, {
    Map<String, dynamic>? onboardingData,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final registerData = {
        'username': username,
        'email': email,
        'password': password,
        ...?onboardingData,
      };

      final response = await apiClient.post(
        'auth/register/',
        data: registerData,
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

          final user = tokens['user'];
          final isOnboarded = user != null
              ? user['is_onboarded'] == true
              : false;

          // Guardar estado de onboarding y datos del usuario localmente
          await _storage.write(
            key: AppConstants.onboardedKey,
            value: isOnboarded.toString(),
          );
          if (user != null) {
            await _storage.write(key: 'user_data', value: jsonEncode(user));
          }

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            isOnboarded: isOnboarded,
            user: user,
          );
        } else {
          await login(username, password);
        }
      }
    } on DioException catch (e) {
      String message = 'Error al registrarse';
      if (e.response != null) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          message =
              data['detail'] ??
              data['error'] ??
              (data['username'] != null ? data['username'][0] : null) ??
              (data['email'] != null ? data['email'][0] : null) ??
              (data['password'] != null ? data['password'][0] : null) ??
              data.toString();
        } else {
          message = 'Error del servidor: ${e.response?.statusCode}';
        }
      } else {
        message = 'Error de red: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado: $e');
    }
  }

  Future<void> logout() async {
    // Fire-and-forget: deactivate FCM token without blocking the logout flow
    NotificationService.instance.deactivateToken();

    try {
      // Intentar cerrar sesión de Google si existe
      final googleSignIn = gsi.GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      print('ℹ️ No había sesión de Google activa o falló el cierre: $e');
    }

    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.onboardedKey);
    await _storage.delete(key: 'user_data');

    state = AuthState(
      isAuthenticated: false,
      user: null,
      isOnboarded: false,
      isInitializing: false,
    );
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final googleSignIn = gsi.GoogleSignIn(
      serverClientId:
          '945196821861-6u6hcooaoq5h3s5tv4k2t3r9osa20aa1.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    try {
      print('🚀 Iniciando loginWithGoogle...');
      state = state.copyWith(isLoading: true, error: null);

      try {
        await googleSignIn.signOut().timeout(const Duration(seconds: 5));
      } catch (e) {
        // Ignorable: previous session may not exist or Play Services slow
      }

      print('🔑 Abriendo selector de cuentas de Google...');
      final gsi.GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        print('❌ Usuario canceló la selección de cuenta');
        state = state.copyWith(isLoading: false);
        return;
      }

      print('✅ Cuenta seleccionada: ${account.email}');
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      print('🎫 Token de Google obtenido: ${idToken != null ? 'SÍ' : 'NO'}');

      if (idToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo obtener el token de Google',
        );
        return;
      }

      print(
        '📡 Enviando token al servidor: ${AppConstants.baseUrl}auth/social/google/',
      );
      final response = await apiClient.post(
        'auth/social/google/',
        data: {'access_token': idToken, 'code': ''},
      );

      print(
        '📥 Respuesta del servidor recibida. Status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final access = response.data['access'] as String?;
        final refresh = response.data['refresh'] as String?;

        if (access == null || refresh == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Respuesta inesperada del servidor. Inténtalo de nuevo.',
          );
          return;
        }

        await _storage.write(key: AppConstants.tokenKey, value: access);
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);

        final user = response.data['user'];
        final isOnboarded = user != null ? user['is_onboarded'] == true : false;

        await _storage.write(
          key: AppConstants.onboardedKey,
          value: isOnboarded.toString(),
        );
        if (user != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(user));
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOnboarded: isOnboarded,
          user: user,
        );

        // Register FCM token (fire-and-forget, only if Firebase is configured)
        final fcmToken = NotificationService.instance.currentToken;
        if (fcmToken != null) {
          NotificationService.instance.registerTokenWithBackend(fcmToken);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error inesperado del servidor (${response.statusCode}).',
        );
      }
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;

      if (isTimeout) {
        state = state.copyWith(
          isLoading: false,
          error: 'El servidor tardó en responder. Inténtalo de nuevo en unos segundos.',
        );
        return;
      }

      String message = 'Error con el servidor de Google';
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        message = data['detail'] ?? data['error'] ?? message;
      } else if (e.response?.data != null && e.response?.data is String) {
        message = 'Error del servidor: ${e.response?.statusCode}';
      }

      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado: $e');
    }
  }

  Future<void> updateProfile({
    Map<String, dynamic>? data,
    String? imagePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      dynamic sendData;

      if (imagePath != null) {
        final formData = FormData.fromMap({
          if (data != null) ...data,
          'profile_picture': await MultipartFile.fromFile(
            imagePath,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        });
        sendData = formData;
      } else {
        sendData = data;
      }

      // Usamos PUT en lugar de PATCH si hay imagen, ya que es más robusto con Multipart
      final response = await (imagePath != null
          ? apiClient.post(
              'auth/profile/update/',
              data: sendData,
            ) // Usamos POST como alternativa si PATCH falla
          : apiClient.patch('auth/profile/update/', data: sendData));

      if (response.statusCode == 200) {
        final updatedUser = response.data;
        await _storage.write(key: AppConstants.onboardedKey, value: 'true');
        await _storage.write(key: 'user_data', value: jsonEncode(updatedUser));
        state = state.copyWith(
          isOnboarded: true,
          isLoading: false,
          user: updatedUser,
          isAuthenticated: true,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Error al actualizar perfil';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fallo al guardar perfil',
      );
    }
  }

  Future<void> syncProfile() async {
    try {
      final response = await apiClient.get('auth/profile/');
      if (response.statusCode == 200) {
        final user = response.data;
        await _storage.write(key: 'user_data', value: jsonEncode(user));
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isOnboarded: user['is_onboarded'] == true,
          isInitializing: false,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      } else {
        print('Error syncing profile: $e');
      }
    } catch (e) {
      print('Error syncing profile: $e');
    }
  }

  Future<void> checkAuth() async {
    try {
      var token = await _storage.read(key: AppConstants.tokenKey);
      final localUserData = await _storage.read(key: 'user_data');
      final refreshToken = await _storage.read(
        key: AppConstants.refreshTokenKey,
      );

      print('🔍 Verificando sesión... Token: ${token != null ? 'SÍ' : 'NO'}');

      // Si el access no existe pero el refresh sigue vigente, intentamos recuperar sesión.
      if ((token == null || token.isEmpty) &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        token = await _restoreAccessTokenWithRefresh();
      }

      if (token != null && token.isNotEmpty) {
        // CARGA RÁPIDA: Si tenemos datos locales, los ponemos ya mismo
        if (localUserData != null) {
          try {
            final user = jsonDecode(localUserData);
            state = state.copyWith(
              isAuthenticated: true,
              isOnboarded: user['is_onboarded'] == true,
              user: user,
              isInitializing: false,
            );
          } catch (_) {}
        }

        await syncProfile();
        state = state.copyWith(isInitializing: false);

        // Re-register FCM token in case it rotated since last session
        final fcmToken = NotificationService.instance.currentToken;
        if (fcmToken != null) {
          await NotificationService.instance.registerTokenWithBackend(fcmToken);
        }
      } else {
        state = state.copyWith(isInitializing: false, isAuthenticated: false);
      }
    } catch (e) {
      print('❌ Error al verificar sesión: $e');
      state = state.copyWith(isInitializing: false, isAuthenticated: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
