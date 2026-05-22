import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  /// Debe terminar en `/api/`. Override con `API_BASE_URL` en `.env`.
  static String get baseUrl {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/') ? fromEnv : '$fromEnv/';
    }
    return 'https://heft-backend-ywi0.onrender.com/api/';
  }

  static const String tokenKey = 'heft_access_token';
  static const String refreshTokenKey = 'heft_refresh_token';
  static const String onboardedKey = 'heft_is_onboarded';
}
