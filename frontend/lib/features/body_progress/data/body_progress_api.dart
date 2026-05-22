import 'package:dio/dio.dart';

String friendlyBodyProgressError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 404) {
    return 'El servidor no tiene activado el seguimiento corporal.\n'
        'Despliega el backend actualizado en Render o usa API_BASE_URL en .env apuntando a tu servidor local.';
  }
  if (status == 401) {
    return 'Sesión expirada. Vuelve a iniciar sesión.';
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'El servidor tarda en responder. Inténtalo de nuevo.';
  }
  return 'No se pudo conectar con el servidor.';
}
