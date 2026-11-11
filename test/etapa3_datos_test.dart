// Etapa 3 — Cliente Dio, bitácora, traducción de errores y repositorio.
//   flutter test test/etapa3_datos_test.dart -r expanded

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recetario_utez/datos/bitacora_interceptor.dart';
import 'package:recetario_utez/datos/cliente_http.dart';
import 'package:recetario_utez/datos/dummyjson_repositorio.dart';
import 'package:recetario_utez/datos/recetas_repositorio.dart';
import 'package:recetario_utez/dominio/falla_red.dart';

import 'soporte/adaptador_falso.dart';
import 'soporte/json_dummy.dart';

void main() {
  group('crearDioRecetas', () {
    test('apunta a DummyJSON por HTTPS y tiene timeouts razonables', () {
      final o = crearDioRecetas().options;
      expect(urlDummyJson, 'https://dummyjson.com');
      expect(o.baseUrl, urlDummyJson);
      expect(o.connectTimeout, isNotNull);
      expect(o.receiveTimeout, isNotNull);
      expect(o.connectTimeout!.inSeconds, inInclusiveRange(1, 30));
      expect(o.receiveTimeout!.inSeconds, inInclusiveRange(1, 30));
    });

    test('trae la bitácora y respeta los interceptores extra', () {
      final extra = InterceptorsWrapper();
      final dio = crearDioRecetas(interceptores: [extra]);
      expect(dio.interceptors.whereType<BitacoraInterceptor>(), hasLength(1));
      expect(dio.interceptors, contains(extra));
    });
  });

  group('BitacoraInterceptor', () {
    Dio dioCon(List<String> lineas, Responder responder) =>
        Dio(BaseOptions(baseUrl: urlDummyJson))
          ..interceptors.add(BitacoraInterceptor(escribir: lineas.add))
          ..httpClientAdapter = AdaptadorFalso(responder);

    test('escribe método, ruta y código, pero no lo que se buscó', () async {
      final lineas = <String>[];
      final dio = dioCon(lineas, (_) => AdaptadorFalso.json(paginaTres()));

      await DummyJsonRepositorio(dio).buscar(texto: 'enchiladas');

      expect(lineas.first, '→ GET /recipes/search');
      expect(lineas.last, startsWith('← 200 GET /recipes/search'));
      expect(lineas.join('\n'), isNot(contains('enchiladas')));
      expect(lineas.join('\n'), isNot(contains('limit')));
    });

    test('en un error escribe una línea con ✗ y el código', () async {
      final lineas = <String>[];
      final dio = dioCon(
        lineas,
        (_) => AdaptadorFalso.json(error503, codigo: 503),
      );

      await expectLater(
        DummyJsonRepositorio(dio).buscar(),
        throwsA(isA<FallaRed>()),
      );
      expect(lineas.last, startsWith('✗'));
      expect(lineas.last, contains('503'));
    });
  });

  group('DummyJsonRepositorio', () {
    late AdaptadorFalso red;
    late DummyJsonRepositorio repo;

    setUp(() {
      red = AdaptadorFalso((_) => AdaptadorFalso.json(paginaTres()));
      repo = DummyJsonRepositorio(crearDioRecetas()..httpClientAdapter = red);
    });

    test('cumple el contrato RecetasRepositorio', () {
      expect(repo, isA<RecetasRepositorio>());
    });

    test('sin texto pide GET /recipes con limit y sin q', () async {
      await repo.buscar();
      final o = red.peticiones.single;
      expect(o.method, 'GET');
      expect(o.path, '/recipes');
      expect(o.queryParameters, {'limit': recetasPorPagina});
      expect(recetasPorPagina, 10);
    });

    test('con texto pide GET /recipes/search con q limpio y limit', () async {
      await repo.buscar(texto: '  pasta ');
      final o = red.peticiones.single;
      expect(o.path, '/recipes/search');
      expect(o.queryParameters, {'q': 'pasta', 'limit': 10});
    });

    test('solo espacios cuenta como "sin texto"', () async {
      await repo.buscar(texto: '   ');
      expect(red.peticiones.single.path, '/recipes');
    });

    test('200 → PaginaRecetas', () async {
      final p = await repo.buscar();
      expect(p.recetas, hasLength(3));
      expect(p.total, 50);
    });

    test('200 sin resultados → página vacía', () async {
      red.responder = (_) => AdaptadorFalso.json(paginaVacia());
      expect((await repo.buscar(texto: 'zzz')).recetas, isEmpty);
    });

    final casos = <String, (Responder, Matcher)>{
      '503 → ErrorDelServidor(503)': (
        (_) => AdaptadorFalso.json(error503, codigo: 503),
        isA<ErrorDelServidor>().having((f) => f.codigo, 'codigo', 503),
      ),
      '500 → ErrorDelServidor(500)': (
        (_) => AdaptadorFalso.json({}, codigo: 500),
        isA<ErrorDelServidor>().having((f) => f.codigo, 'codigo', 500),
      ),
      '404 → PeticionRechazada(404)': (
        (_) => AdaptadorFalso.json({}, codigo: 404),
        isA<PeticionRechazada>().having((f) => f.codigo, 'codigo', 404),
      ),
      'sin red → SinConexion': (
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'prueba',
        ),
        isA<SinConexion>(),
      ),
      'connectTimeout → TiempoAgotado': (
        (o) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 5),
          requestOptions: o,
        ),
        isA<TiempoAgotado>(),
      ),
      'receiveTimeout → TiempoAgotado': (
        (o) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: o,
        ),
        isA<TiempoAgotado>(),
      ),
      'una lista en lugar de objeto → RespuestaInvalida': (
        (_) => AdaptadorFalso.json([recetaPizza()]),
        isA<RespuestaInvalida>(),
      ),
      'JSON mal escrito → RespuestaInvalida': (
        (_) => AdaptadorFalso.texto('{"recipes": ['),
        isA<RespuestaInvalida>(),
      ),
      'receta sin nombre → RespuestaInvalida': (
        (_) => AdaptadorFalso.json({
          'recipes': [recetaPizza()..remove('name')],
          'total': 1,
        }),
        isA<RespuestaInvalida>(),
      ),
    };

    casos.forEach((nombre, caso) {
      test(nombre, () async {
        red.responder = caso.$1;
        await expectLater(repo.buscar(), throwsA(caso.$2));
      });
    });
  });
}
