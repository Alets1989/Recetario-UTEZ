// Etapa 5 — Tarjeta, pantalla y raíz de la app.
//   flutter test test/etapa5_vistas_test.dart -r expanded

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recetario_utez/app.dart';
import 'package:recetario_utez/dominio/falla_red.dart';
import 'package:recetario_utez/dominio/receta.dart';
import 'package:recetario_utez/presentacion/recetas_pagina.dart';
import 'package:recetario_utez/presentacion/recetas_view_model.dart';
import 'package:recetario_utez/presentacion/tarjeta_receta.dart';

import 'soporte/repositorio_falso.dart';

void main() {
  group('TarjetaReceta', () {
    Future<void> montar(WidgetTester tester, Receta r) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TarjetaReceta(receta: r)),
      ),
    );

    testWidgets('muestra nombre, cocina, dificultad, tiempo, porciones y '
        'calificación con un decimal', (tester) async {
      await montar(tester, recetasEjemplo.first);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Classic Margherita Pizza'), findsOneWidget);
      expect(find.text('Italian · Fácil'), findsOneWidget);
      expect(find.text('Tiempo: 35 min · Porciones: 4'), findsOneWidget);
      expect(find.text('Calificación: 4.6'), findsOneWidget);
      expect(find.text('Rápida'), findsNothing);
    });

    testWidgets('marca las recetas rápidas y redondea la calificación', (
      tester,
    ) async {
      await montar(tester, recetasEjemplo[2]);
      expect(find.text('Rápida'), findsOneWidget);
      expect(find.text('Calificación: 4.4'), findsOneWidget);
    });
  });

  group('RecetasPagina', () {
    late RepositorioFalso repo;
    late RecetasViewModel vm;

    setUp(() {
      repo = RepositorioFalso();
      vm = RecetasViewModel(repo);
    });

    tearDown(() => vm.dispose());

    Future<void> montar(WidgetTester tester) =>
        tester.pumpWidget(MaterialApp(home: RecetasPagina(vm: vm)));

    FilledButton boton(WidgetTester tester) => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Buscar recetas'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );

    testWidgets('al abrir no busca: espera el botón', (tester) async {
      await montar(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.busquedas, isEmpty);
      expect(
        find.text('Escribe una receta o déjalo vacío y toca Buscar recetas.'),
        findsOneWidget,
      );
    });

    testWidgets('texto + botón → indicador y botón apagado → tarjetas', (
      tester,
    ) async {
      repo.espera = Completer<void>();
      await montar(tester);

      await tester.enterText(find.byKey(const Key('busqueda')), 'pizza');
      await tester.tap(find.byKey(const Key('buscar')));
      await tester.pump();
      expect(repo.busquedas, ['pizza']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(boton(tester).onPressed, isNull);

      repo.espera!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaReceta), findsNWidgets(3));
      expect(
        find.text('Mostrando 3 de 50 recetas · Rápidas: 2'),
        findsOneWidget,
      );
      expect(boton(tester).onPressed, isNotNull);
    });

    testWidgets('vacío con texto dice qué se buscó; sin texto, otro mensaje', (
      tester,
    ) async {
      repo.pagina = const PaginaRecetas(recetas: [], total: 0);
      await montar(tester);

      await tester.enterText(find.byKey(const Key('busqueda')), 'zzz');
      await tester.tap(find.byKey(const Key('buscar')));
      await tester.pumpAndSettle();
      expect(find.text('No encontramos recetas para "zzz".'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('busqueda')), '');
      await tester.tap(find.byKey(const Key('buscar')));
      await tester.pumpAndSettle();
      expect(find.text('No hay recetas disponibles.'), findsOneWidget);
    });

    testWidgets('error → mensaje y Reintentar repite la misma búsqueda', (
      tester,
    ) async {
      repo.error = const SinConexion();
      await montar(tester);

      await tester.enterText(find.byKey(const Key('busqueda')), 'tacos');
      await tester.tap(find.byKey(const Key('buscar')));
      await tester.pumpAndSettle();
      expect(
        find.text('Sin conexión. Revisa tu red e intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.byType(TarjetaReceta), findsNothing);

      repo.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.busquedas, ['tacos', 'tacos']);
      expect(find.byType(TarjetaReceta), findsNWidgets(3));
    });

    testWidgets('Enter en el teclado también busca', (tester) async {
      await montar(tester);
      await tester.enterText(find.byKey(const Key('busqueda')), 'pasta');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(repo.busquedas, ['pasta']);
    });
  });

  testWidgets('AppRecetario arma todo con el repositorio que recibe', (
    tester,
  ) async {
    final repo = RepositorioFalso();
    await tester.pumpWidget(AppRecetario(repositorio: repo));

    expect(find.text('Recetario UTEZ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('buscar')));
    await tester.pumpAndSettle();
    expect(find.byType(TarjetaReceta), findsNWidgets(3));
    expect(repo.busquedas, ['']);
  });
}
