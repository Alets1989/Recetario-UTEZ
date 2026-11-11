import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Bitácora segura: solo método, ruta, código, tipo de error y tiempo.
/// No registra lo que la persona busca (viaja en la query), ni encabezados,
/// ni el cuerpo de la respuesta. Por eso usa `options.path` y no la URL completa.
class BitacoraInterceptor extends Interceptor {
  BitacoraInterceptor({void Function(String linea)? escribir})
    : _escribir = escribir ?? _escribirEnConsola;

  final void Function(String linea) _escribir;

  static const _llaveCronometro = 'bitacora_cronometro';

  static void _escribirEnConsola(String linea) =>
      developer.log(linea, name: 'recetario');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_llaveCronometro] = Stopwatch()..start();
    _escribir('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final pedido = response.requestOptions;
    _escribir(
      '← ${response.statusCode} ${pedido.method} ${pedido.path} '
      '(${_milisegundos(pedido)} ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final pedido = err.requestOptions;
    final codigo = err.response?.statusCode;
    _escribir(
      '✗ ${err.type.name}${codigo == null ? '' : ' $codigo'} '
      '${pedido.method} ${pedido.path} (${_milisegundos(pedido)} ms)',
    );
    handler.next(err);
  }

  int _milisegundos(RequestOptions pedido) {
    final cronometro = pedido.extra[_llaveCronometro];
    return cronometro is Stopwatch ? cronometro.elapsedMilliseconds : 0;
  }
}
