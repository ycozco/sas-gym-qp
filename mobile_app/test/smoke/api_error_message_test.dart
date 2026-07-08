import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/api_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions request() => RequestOptions(path: '/test');

  test('maps connection errors to local api guidance', () {
    final message = ApiErrorMessage.fromDio(
      DioException(
        requestOptions: request(),
        type: DioExceptionType.connectionError,
        error: 'connection refused',
      ),
    );

    expect(message, contains('Verifica la URL local'));
  });

  test('maps unauthorized responses to session message', () {
    final message = ApiErrorMessage.fromDio(
      DioException(
        requestOptions: request(),
        response: Response(
          requestOptions: request(),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      ),
    );

    expect(message, 'Sesión expirada. Inicia sesión nuevamente.');
  });

  test('uses backend validation message when available', () {
    final message = ApiErrorMessage.fromDio(
      DioException(
        requestOptions: request(),
        response: Response(
          requestOptions: request(),
          statusCode: 400,
          data: {
            'message': ['Campo requerido', 'Formato inválido'],
          },
        ),
      ),
    );

    expect(message, 'Campo requerido\nFormato inválido');
  });
}
