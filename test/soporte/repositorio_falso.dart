// Repositorio falso para probar ViewModel y pantallas sin Dio ni red.

import 'dart:async';

import 'package:recetario_utez/datos/recetas_repositorio.dart';
import 'package:recetario_utez/dominio/receta.dart';

class RepositorioFalso implements RecetasRepositorio {
  RepositorioFalso({PaginaRecetas? pagina}) : pagina = pagina ?? paginaEjemplo;

  // Lo que regresa si no hay error ni espera.
  PaginaRecetas pagina;
  // Si no es null, se lanza en lugar de regresar la página.
  Object? error;
  // Si no es null, la respuesta espera a que la prueba lo complete.
  Completer<void>? espera;
  // Textos con los que lo llamaron, en orden.
  final busquedas = <String>[];

  @override
  Future<PaginaRecetas> buscar({String texto = ''}) async {
    busquedas.add(texto);
    if (espera != null) await espera!.future;
    if (error != null) throw error!;
    return pagina;
  }
}

const recetasEjemplo = [
  Receta(
    id: 1,
    nombre: 'Classic Margherita Pizza',
    cocina: 'Italian',
    dificultad: Dificultad.facil,
    minutosPreparacion: 20,
    minutosCoccion: 15,
    porciones: 4,
    calificacion: 4.6,
  ),
  Receta(
    id: 7,
    nombre: 'Mango Salsa Chicken',
    cocina: 'Mexican',
    dificultad: Dificultad.media,
    minutosPreparacion: 10,
    minutosCoccion: 15,
    porciones: 2,
    calificacion: 5,
  ),
  Receta(
    id: 8,
    nombre: 'Quinoa Salad',
    cocina: 'Mediterranean',
    dificultad: Dificultad.facil,
    minutosPreparacion: 20,
    minutosCoccion: 10,
    porciones: 3,
    calificacion: 4.44,
  ),
];

const paginaEjemplo = PaginaRecetas(recetas: recetasEjemplo, total: 50);
