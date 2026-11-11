
import 'package:dio/dio.dart';

import '../dominio/falla_red.dart';

/// Traduce un error de Dio al vocabulario del dominio.
/// El switch cubre todos los valores de [DioExceptionType]:
/// si Dio agrega uno, esto deja de compilar y nos obliga a decidir qué hacer.
FallaRed traducirError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TiempoAgotado();

    case DioExceptionType.badResponse:
      final codigo = e.response?.statusCode ?? 0;
      return codigo >= 500
          ? ErrorDelServidor(codigo)
          : PeticionRechazada(codigo);

    case DioExceptionType.unknown:
      return e.error is FormatException
          ? const RespuestaInvalida()
          : const SinConexion();

    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.connectionError:
      return const SinConexion();
  }
}
