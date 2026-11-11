import '../dominio/receta.dart';

/// Contrato: de dónde vienen las recetas no le importa a quien lo use.
abstract class RecetasRepositorio {
  Future<PaginaRecetas> buscar({String texto = ''});
}
