import 'package:dio/dio.dart';

class ApiErrorMessage {
  static String fromDio(
    DioException error, {
    String fallback = 'Error de conexión con el servidor.',
  }) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Tiempo de espera agotado. Revisa la red local y que la API este levantada.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con la API. Verifica la URL local y la red WiFi.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Sesión expirada. Inicia sesión nuevamente.';
    }
    if (statusCode == 403) {
      return 'No tienes permisos para realizar esta acción.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'La API tuvo un error interno. Revisa los logs del contenedor.';
    }

    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['reason'] ?? data['error'];
      if (message is List) return message.join('\n');
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return fallback;
  }
}
