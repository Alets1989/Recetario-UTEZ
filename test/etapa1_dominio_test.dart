// Etapa 1 — Dominio: receta, dificultad, página y fallas de red.
//   flutter test test/etapa1_dominio_test.dart -r expanded

import 'package:flutter_test/flutter_test.dart';
import 'package:recetario_utez/dominio/falla_red.dart';
import 'package:recetario_utez/dominio/receta.dart';

Receta receta({int preparacion = 10, int coccion = 10}) => Receta(
  id: 1,
  nombre: 'Prueba',
  cocina: 'Mexican',
  dificultad: Dificultad.facil,
  minutosPreparacion: preparacion,
  minutosCoccion: coccion,
  porciones: 2,
  calificacion: 4.5,
);

void main() {
  test('Receta guarda lo que recibe y sus listas empiezan vacías', () {
    final r = receta();
    expect(r.id, 1);
    expect(r.nombre, 'Prueba');
    expect(r.cocina, 'Mexican');
    expect(r.dificultad, Dificultad.facil);
    expect(r.porciones, 2);
    expect(r.calificacion, 4.5);
    expect(r.etiquetas, isEmpty);
    expect(r.ingredientes, isEmpty);
  });

  test('tiempoTotal suma preparación y cocción', () {
    expect(receta(preparacion: 20, coccion: 15).tiempoTotal, 35);
  });

  test('esRapida: 30 minutos sí, 31 no', () {
    expect(umbralRapidaMinutos, 30);
    expect(receta(preparacion: 15, coccion: 15).esRapida, isTrue);
    expect(receta(preparacion: 16, coccion: 15).esRapida, isFalse);
  });

  test('Dificultad tiene cuatro valores con su etiqueta en español', () {
    expect(Dificultad.values, hasLength(4));
    expect(Dificultad.facil.etiqueta, 'Fácil');
    expect(Dificultad.media.etiqueta, 'Media');
    expect(Dificultad.dificil.etiqueta, 'Difícil');
    expect(Dificultad.desconocida.etiqueta, 'Sin dato');
  });

  test('PaginaRecetas guarda las recetas y el total', () {
    final p = PaginaRecetas(recetas: [receta()], total: 50);
    expect(p.recetas, hasLength(1));
    expect(p.total, 50);
  });

  test(
    'las cinco fallas son FallaRed y Exception; dos recuerdan el código',
    () {
      const fallas = <FallaRed>[
        SinConexion(),
        TiempoAgotado(),
        ErrorDelServidor(503),
        PeticionRechazada(404),
        RespuestaInvalida(),
      ];
      for (final f in fallas) {
        expect(f, isA<Exception>());
      }
      expect(const ErrorDelServidor(503).codigo, 503);
      expect(const PeticionRechazada(404).codigo, 404);
    },
  );
}
