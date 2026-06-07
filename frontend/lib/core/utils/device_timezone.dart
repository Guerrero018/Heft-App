import 'package:flutter_timezone/flutter_timezone.dart';

/// IANA timezone del dispositivo (p. ej. Europe/Madrid).
Future<String> resolveDeviceTimezone() async {
  try {
    final id = await FlutterTimezone.getLocalTimezone();
    if (id.isNotEmpty) {
      return id;
    }
  } catch (_) {
    // Fallback si el plugin no está disponible en la plataforma.
  }
  return 'Europe/Madrid';
}
