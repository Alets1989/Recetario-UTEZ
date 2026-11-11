// Adaptador HTTP falso: Dio le entrega cada petición y la prueba decide qué
// responde. Así ninguna prueba depende de internet.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Responder = FutureOr<ResponseBody> Function(RequestOptions opciones);

class AdaptadorFalso implements HttpClientAdapter {
  AdaptadorFalso(this.responder);

  // Qué responder. Se puede cambiar a mitad de una prueba.
  Responder responder;
  // Cada petición que llegó a la "red".
  final peticiones = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticiones.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}

  // Respuesta JSON con el código indicado.
  static ResponseBody json(Object? datos, {int codigo = 200}) =>
      texto(jsonEncode(datos), codigo: codigo);

  // Respuesta con un cuerpo crudo (sirve para mandar JSON roto).
  static ResponseBody texto(String cuerpo, {int codigo = 200}) {
    return ResponseBody.fromString(
      cuerpo,
      codigo,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
