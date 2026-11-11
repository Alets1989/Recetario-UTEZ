// Etapa 4 — Mensajes para personas y ViewModel con estados sellados.
//   flutter test test/etapa4_viewmodel_test.dart -r expanded

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recetario_utez/dominio/falla_red.dart';
import 'package:recetario_utez/dominio/receta.dart';
import 'package:recetario_utez/presentacion/mensajes.dart';
import 'package:recetario_utez/presentacion/recetas_view_model.dart';

import 'soporte/repositorio_falso.dart';

void main() {
  test('mensajePara: un texto claro por falla, sin detalles técnicos', () {
    expect(
      mensajePara(const SinConexion()),
      'Sin conexión. Revisa tu red e intenta de nuevo.',
    );
    expect(
      mensajePara(const TiempoAgotado()),
      'El recetario tardó demasiado en responder. Intenta de nuevo.',
    );
    expect(
      mensajePara(const ErrorDelServidor(503)),
      'El recetario no está disponible (503). Intenta más tarde.',
    );
    expect(
      mensajePara(const PeticionRechazada(404)),
      'No pudimos hacer esa búsqueda. Avisa al equipo de desarrollo.',
    );
    expect(
      mensajePara(const RespuestaInvalida()),
      'Las recetas llegaron con un formato inesperado.',
    );
    expect(mensajeInesperado, 'Algo salió mal. Intenta de nuevo.');
  });

  group('RecetasViewModel', () {
    late RepositorioFalso repo;
    late RecetasViewModel vm;

    setUp(() {
      repo = RepositorioFalso();
      vm = RecetasViewModel(repo);
    });

    tearDown(() => vm.dispose());

    test('es ChangeNotifier, empieza en Inicial y no busca solo', () {
      expect(vm, isA<ChangeNotifier>());
      expect(vm.estado, isA<RecetasInicial>());
      expect(vm.cargando, isFalse);
      expect(repo.busquedas, isEmpty);
    });

    test('Inicial → Cargando → Listas, con exactamente dos avisos', () async {
      final vistos = <EstadoRecetas>[];
      vm.addListener(() => vistos.add(vm.estado));

      await vm.buscar('pizza');

      expect(vistos, hasLength(2));
      expect(vistos.first, isA<RecetasCargando>());
      expect(
        vistos.last,
        isA<RecetasListas>()
            .having((e) => e.recetas, 'recetas', hasLength(3))
            .having((e) => e.total, 'total', 50),
      );
    });

    test('limpia espacios del texto antes de buscar', () async {
      await vm.buscar('  pizza  ');
      expect(repo.busquedas.single, 'pizza');
      expect(vm.ultimaBusqueda, 'pizza');
    });

    test('cargando es verdadero mientras espera', () async {
      repo.espera = Completer<void>();
      final b = vm.buscar('');
      expect(vm.cargando, isTrue);
      repo.espera!.complete();
      await b;
      expect(vm.cargando, isFalse);
    });

    test('sin resultados → Vacias, recordando qué se buscó', () async {
      repo.pagina = const PaginaRecetas(recetas: [], total: 0);
      await vm.buscar(' zzz ');
      expect(
        vm.estado,
        isA<RecetasVacias>().having((e) => e.busqueda, 'busqueda', 'zzz'),
      );
    });

    test('FallaRed → Fallidas con el mensaje de mensajePara', () async {
      repo.error = const ErrorDelServidor(503);
      await vm.buscar('');
      expect(
        vm.estado,
        isA<RecetasFallidas>().having(
          (e) => e.mensaje,
          'mensaje',
          'El recetario no está disponible (503). Intenta más tarde.',
        ),
      );
    });

    test('un error no previsto no deja la pantalla cargando', () async {
      repo.error = StateError('bug');
      await vm.buscar('');
      expect(
        vm.estado,
        isA<RecetasFallidas>().having(
          (e) => e.mensaje,
          'mensaje',
          mensajeInesperado,
        ),
      );
    });

    test('dos búsquedas seguidas hacen una sola petición', () async {
      repo.espera = Completer<void>();
      final a = vm.buscar('pizza');
      final b = vm.buscar('pasta');
      repo.espera!.complete();
      await Future.wait([a, b]);
      expect(repo.busquedas, ['pizza']);
    });

    test('reintentar repite la última búsqueda', () async {
      repo.error = const SinConexion();
      await vm.buscar('tacos');
      expect(vm.estado, isA<RecetasFallidas>());

      repo.error = null;
      await vm.reintentar();
      expect(repo.busquedas, ['tacos', 'tacos']);
      expect(vm.estado, isA<RecetasListas>());
    });

    test('rapidas es derivado: 0 sin datos, 2 con el ejemplo', () async {
      expect(vm.rapidas, 0);
      await vm.buscar('');
      expect(vm.rapidas, 2);
    });
  });
}
