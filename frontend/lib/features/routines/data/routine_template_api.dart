import 'package:dio/dio.dart';

String friendlyRoutineTemplatesError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 404) {
    return 'El servidor aún no tiene activada la biblioteca de plantillas.\n'
        'Despliega el backend actualizado en Render o configura API_BASE_URL en .env '
        'apuntando a tu servidor local (python manage.py runserver).';
  }
  if (status == 401) {
    return 'Sesión expirada. Vuelve a iniciar sesión.';
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return 'No hay conexión con el servidor. Comprueba que el backend está en marcha.';
  }
  final detail = e.response?.data;
  if (detail is Map && detail['detail'] != null) {
    return detail['detail'].toString();
  }
  return 'No se pudo cargar la biblioteca de plantillas.';
}
