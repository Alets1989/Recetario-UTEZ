// Etapa 2 — Del JSON de DummyJSON a objetos Dart.
//   flutter test test/etapa2_json_test.dart -r expanded

import 'package:flutter_test/flutter_test.dart';
import 'package:recetario_utez/datos/recetas_json.dart';
import 'package:recetario_utez/dominio/receta.dart';

import 'soporte/json_dummy.dart';

void main() {
  group('dificultadDesdeTexto', () {
    test('traduce Easy, Medium y Hard', () {
      expect(dificultadDesdeTexto('Easy'), Dificultad.facil);
      expect(dificultadDesdeTexto('Medium'), Dificultad.media);
      expect(dificultadDesdeTexto('Hard'), Dificultad.dificil);
    });

    test('lo desconocido o ausente es Dificultad.desconocida, no un error', () {
      expect(dificultadDesdeTexto('Extreme'), Dificultad.desconocida);
      expect(dificultadDesdeTexto(null), Dificultad.desconocida);
      expect(dificultadDesdeTexto(3), Dificultad.desconocida);
    });
  });

  group('recetaDesdeJson', () {
    test('convierte una receta completa', () {
      final r = recetaDesdeJson(recetaPizza());
      expect(r.id, 1);
      expect(r.nombre, 'Classic Margherita Pizza');
      expect(r.cocina, 'Italian');
      expect(r.dificultad, Dificultad.facil);
      expect(r.minutosPreparacion, 20);
      expect(r.minutosCoccion, 15);
      expect(r.porciones, 4);
      expect(r.calificacion, 4.6);
      expect(r.etiquetas, ['Pizza', 'Italian']);
      expect(r.ingredientes, hasLength(3));
    });

    test('acepta una calificación entera como double', () {
      final r = recetaDesdeJson(recetaSalsa());
      expect(r.calificacion, isA<double>());
      expect(r.calificacion, 5.0);
    });

    test('sin tags ni ingredients deja listas vacías', () {
      final r = recetaDesdeJson(recetaSalsa());
      expect(r.etiquetas, isEmpty);
      expect(r.ingredientes, isEmpty);
    });

    test('una dificultad desconocida no impide leer la receta', () {
      expect(recetaDesdeJson(recetaRara()).dificultad, Dificultad.desconocida);
    });

    test('falta un campo obligatorio → FormatException', () {
      for (final campo in [
        'id',
        'name',
        'cuisine',
        'prepTimeMinutes',
        'cookTimeMinutes',
        'servings',
        'rating',
      ]) {
        expect(
          () => recetaDesdeJson(recetaPizza()..remove(campo)),
          throwsFormatException,
          reason: 'sin $campo',
        );
      }
    });

    test('tipo equivocado → FormatException', () {
      expect(
        () => recetaDesdeJson(recetaPizza()..['servings'] = '4'),
        throwsFormatException,
      );
      expect(
        () => recetaDesdeJson(recetaPizza()..['tags'] = ['Pizza', 7]),
        throwsFormatException,
      );
      expect(
        () => recetaDesdeJson(recetaPizza()..['tags'] = 'Pizza'),
        throwsFormatException,
      );
    });
  });

  group('paginaDesdeJson', () {
    test('convierte la página y conserva el total del servidor', () {
      final p = paginaDesdeJson(paginaTres());
      expect(p.recetas, hasLength(3));
      expect(p.total, 50);
      expect(p.recetas[1].nombre, 'Mango Salsa Chicken');
    });

    test('sin resultados regresa una página vacía, no un error', () {
      final p = paginaDesdeJson(paginaVacia());
      expect(p.recetas, isEmpty);
      expect(p.total, 0);
    });

    test(
      'sin "recipes", sin "total" o con un elemento raro → FormatException',
      () {
        expect(
          () => paginaDesdeJson(paginaTres()..remove('recipes')),
          throwsFormatException,
        );
        expect(
          () => paginaDesdeJson(paginaTres()..remove('total')),
          throwsFormatException,
        );
        expect(
          () => paginaDesdeJson(paginaTres()..['recipes'] = [1, 2]),
          throwsFormatException,
        );
        expect(() => paginaDesdeJson(Map.of(error503)), throwsFormatException);
      },
    );
  });
}
