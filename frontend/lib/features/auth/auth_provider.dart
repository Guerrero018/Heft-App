import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isOnboarded;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isOnboarded = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isOnboarded,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    // Verificamos la sesión en el siguiente frame para no bloquear el build
    Future.microtask(() => checkAuth());
    return AuthState(isLoading: true);
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await apiClient.post(
        'auth/check-email/',
        data: {'email': email},
      );
      return response.data['exists'] ?? false;
    } catch (e) {
      return false;
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
        final access = response.data['access'];
        final refresh = response.data['refresh'];

        await _storage.write(key: AppConstants.tokenKey, value: access);
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);

        final user = response.data['user'];
        final isOnboarded = user != null ? user['is_onboarded'] == true : false;
        
        // Guardar estado de onboarding y datos del usuario localmente
        await _storage.write(key: AppConstants.onboardedKey, value: isOnboarded.toString());
        if (user != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(user));
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOnboarded: isOnboarded,
          user: user,
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? e.response?.data['error'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> register(String username, String email, String password, {Map<String, dynamic>? onboardingData}) async {
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
          final isOnboarded = user != null ? user['is_onboarded'] == true : false;
          
          // Guardar estado de onboarding y datos del usuario localmente
          await _storage.write(key: AppConstants.onboardedKey, value: isOnboarded.toString());
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
      String message = 'Registration failed';
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
    
    // Reiniciamos el estado a cero
    state = AuthState(isAuthenticated: false, user: null, isOnboarded: false);
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final googleSignIn = gsi.GoogleSignIn(
      serverClientId: '945196821861-6u6hcooaoq5h3s5tv4k2t3r9osa20aa1.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    try {
      print('🚀 Iniciando loginWithGoogle...');
      state = state.copyWith(isLoading: true, error: null);
      
      try {
        print('⏳ Intentando signOut previo...');
        await googleSignIn.signOut();
      } catch (e) {
        print('ℹ️ Error al cerrar sesión previa (puede ignorarse): $e');
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
        state = state.copyWith(isLoading: false, error: 'No se pudo obtener el token de Google');
        return;
      }
      
      print('📡 Enviando token al servidor: ${AppConstants.baseUrl}auth/social/google/');
      final response = await apiClient.post(
        'auth/social/google/', 
        data: {
          'access_token': idToken, 
          'code': '',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 Respuesta del servidor recibida. Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];

        await _storage.write(key: AppConstants.tokenKey, value: access);
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);

        final user = response.data['user'];
        final isOnboarded = user != null ? user['is_onboarded'] == true : false;
        
        // Guardar estado de onboarding y datos locales
        await _storage.write(key: AppConstants.onboardedKey, value: isOnboarded.toString());
        if (user != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(user));
        }
        
        print('🎊 Login exitoso! Onboarded: $isOnboarded');

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOnboarded: isOnboarded,
          user: user,
        );
      }
    } on DioException catch (e) {
      print('🔥 Error en la petición API: ${e.response?.statusCode}');
      
      String message = 'Error con el servidor de Google';
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        message = data['detail'] ?? data['error'] ?? message;
      } else if (e.response?.data != null && e.response?.data is String) {
        // El servidor devolvió una página HTML de error (probablemente error 500)
        message = 'Error del servidor (HTML): ${e.response?.statusCode}';
      }

      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      print('💥 Error inesperado: $e');
      state = state.copyWith(isLoading: false, error: 'Error inesperado: $e');
    }
  }

  Future<void> updateProfile({Map<String, dynamic>? data, String? imagePath}) async {
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

      final response = await apiClient.patch(
        'auth/profile/update/',
        data: sendData,
      );

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
      }
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Error al actualizar perfil';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Fallo al guardar perfil');
    }
  }

  Future<void> checkAuth() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final onboardedStr = await _storage.read(key: AppConstants.onboardedKey);
      final localUserData = await _storage.read(key: 'user_data');
      
      print('🔍 Verificando sesión... Token: ${token != null ? 'SÍ' : 'NO'}');

      if (token != null) {
        // CARGA RÁPIDA: Si tenemos datos locales, los ponemos ya mismo
        if (localUserData != null) {
          try {
            final user = jsonDecode(localUserData);
            state = state.copyWith(
              isAuthenticated: true,
              isOnboarded: user['is_onboarded'] == true,
              user: user,
              isLoading: false,
            );
          } catch (_) {}
        }

        // SINCRONIZACIÓN: Intentar cargar el perfil fresco desde el servidor
        try {
          final response = await apiClient.get('auth/profile/update/');
          if (response.statusCode == 200) {
            final userData = response.data;
            await _storage.write(key: 'user_data', value: jsonEncode(userData));
            state = state.copyWith(
              isAuthenticated: true,
              isOnboarded: userData['is_onboarded'] == true,
              user: userData,
              isLoading: false,
            );
            return;
          }
        } catch (e) {
          print('⚠️ Error al sincronizar perfil: $e');
        }

        // Si falló la sincronización pero no teníamos carga rápida, al menos ponemos el estado básico
        if (state.user == null) {
          state = state.copyWith(
            isAuthenticated: true,
            isOnboarded: onboardedStr == 'true',
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      print('❌ Error al verificar sesión: $e');
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
