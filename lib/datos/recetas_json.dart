// Frontera entre el JSON de DummyJSON y los objetos del dominio.
// Aquí se decide qué es obligatorio y qué se tolera.

import '../dominio/receta.dart';

/// Easy/Medium/Hard se traducen; cualquier otra cosa es `desconocida`.
/// Nunca lanza: una dificultad nueva no debe tumbar la pantalla.
Dificultad dificultadDesdeTexto(Object? valor) => switch (valor) {
  'Easy' => Dificultad.facil,
  'Medium' => Dificultad.media,
  'Hard' => Dificultad.dificil,
  _ => Dificultad.desconocida,
};

/// Convierte un objeto JSON en una [Receta].
/// Lanza [FormatException] si falta un campo obligatorio o trae otro tipo.
Receta recetaDesdeJson(Map<String, dynamic> json) {
  switch (json) {
    case {
      'id': int id,
      'name': String nombre,
      'cuisine': String cocina,
      'prepTimeMinutes': int preparacion,
      'cookTimeMinutes': int coccion,
      'servings': int porciones,
      'rating': num calificacion,
    }:
      return Receta(
        id: id,
        nombre: nombre,
        cocina: cocina,
        dificultad: dificultadDesdeTexto(json['difficulty']),
        minutosPreparacion: preparacion,
        minutosCoccion: coccion,
        porciones: porciones,
        // rating puede llegar como 5 (int) o 4.6 (double).
        calificacion: calificacion.toDouble(),
        etiquetas: _listaDeTextos(json['tags'], 'tags'),
        ingredientes: _listaDeTextos(json['ingredients'], 'ingredients'),
      );
    default:
      throw const FormatException(
        'Receta con campos obligatorios ausentes o de tipo equivocado',
      );
  }
}

/// Convierte la respuesta de /recipes o /recipes/search en una [PaginaRecetas].
PaginaRecetas paginaDesdeJson(Map<String, dynamic> json) {
  switch (json) {
    case {'recipes': List<dynamic> lista, 'total': int total}:
      final recetas = <Receta>[];
      for (final elemento in lista) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException('Un elemento de "recipes" no es un objeto');
        }
        recetas.add(recetaDesdeJson(elemento));
      }
      return PaginaRecetas(recetas: recetas, total: total);
    default:
      throw const FormatException('Falta "recipes" (lista) o "total" (entero)');
  }
}

/// Lista de textos opcional: si falta → vacía; si no es lista de textos → error.
List<String> _listaDeTextos(Object? valor, String campo) {
  if (valor == null) return const [];
  if (valor is! List<dynamic>) {
    throw FormatException('"$campo" debe ser una lista');
  }
  final textos = <String>[];
  for (final elemento in valor) {
    if (elemento is! String) {
      throw FormatException('"$campo" contiene un elemento que no es texto');
    }
    textos.add(elemento);
  }
  return textos;
}
