/// Puente entre el cliente HTTP y el estado de autenticación (Riverpod).
class SessionManager {
  SessionManager._();

  static Future<void> Function()? onSessionExpired;

  static Future<void> notifySessionExpired() async {
    final handler = onSessionExpired;
    if (handler != null) {
      await handler();
    }
  }
}
