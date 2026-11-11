import 'package:dio/dio.dart';

import '../dominio/falla_red.dart';
import '../dominio/receta.dart';
import 'recetas_json.dart';
import 'recetas_repositorio.dart';
import 'traducir_error.dart';

const recetasPorPagina = 10;

class DummyJsonRepositorio implements RecetasRepositorio {
  DummyJsonRepositorio(this._dio);

  final Dio _dio;

  @override
  Future<PaginaRecetas> buscar({String texto = ''}) async {
    final limpio = texto.trim();
    try {
      // La query siempre va en queryParameters: Dio la codifica por nosotros.
      final respuesta = await _dio.get<Object?>(
        limpio.isEmpty ? '/recipes' : '/recipes/search',
        queryParameters: {
          if (limpio.isNotEmpty) 'q': limpio,
          'limit': recetasPorPagina,
        },
      );
      final cuerpo = respuesta.data;
      if (cuerpo is! Map<String, dynamic>) {
        throw const RespuestaInvalida();
      }
      return paginaDesdeJson(cuerpo);
    } on DioException catch (e) {
      throw traducirError(e);
    } on FormatException {
      throw const RespuestaInvalida();
    }
  }
}
