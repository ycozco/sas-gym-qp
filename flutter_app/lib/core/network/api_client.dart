import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  static VoidCallback? onUnauthorized;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Registrar interceptores
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Obtener token e inquilino guardados
          final token = await SecureStorage.getToken();
          final tenantId = await SecureStorage.getTenantId();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (tenantId != null) {
            options.headers['X-Tenant-ID'] = tenantId;
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Si el servidor retorna 401 Unauthorized, limpiar sesión y redirigir
          if (e.response?.statusCode == 401) {
            await SecureStorage.clearAll();
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    // Si corre en simulador Android, usar la IP alias del host
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    // Windows u otros entornos de escritorio / iOS
    return 'http://localhost:3000/api/v1';
  }
}
