import 'package:flutter/foundation.dart';

import '../datos/recetas_repositorio.dart';
import '../dominio/falla_red.dart';
import '../dominio/receta.dart';
import 'mensajes.dart';

/// Estados excluyentes: la pantalla está en uno y solo uno a la vez.
sealed class EstadoRecetas {
  const EstadoRecetas();
}

final class RecetasInicial extends EstadoRecetas {
  const RecetasInicial();
}

final class RecetasCargando extends EstadoRecetas {
  const RecetasCargando();
}

final class RecetasListas extends EstadoRecetas {
  const RecetasListas(this.recetas, this.total);
  final List<Receta> recetas;
  final int total;
}

final class RecetasVacias extends EstadoRecetas {
  const RecetasVacias(this.busqueda);
  final String busqueda;
}

final class RecetasFallidas extends EstadoRecetas {
  const RecetasFallidas(this.mensaje);
  final String mensaje;
}

class RecetasViewModel extends ChangeNotifier {
  RecetasViewModel(this._repositorio);

  final RecetasRepositorio _repositorio;

  EstadoRecetas _estado = const RecetasInicial();
  String _ultimaBusqueda = '';
  bool _liberado = false;

  EstadoRecetas get estado => _estado;

  bool get cargando => _estado is RecetasCargando;

  String get ultimaBusqueda => _ultimaBusqueda;

  int get rapidas => switch (_estado) {
    RecetasListas(:final recetas) => recetas.where((r) => r.esRapida).length,
    _ => 0,
  };

  Future<void> buscar(String texto) async {
    if (cargando) return;

    _ultimaBusqueda = texto.trim();
    _estado = const RecetasCargando();
    notifyListeners();

    try {
      final pagina = await _repositorio.buscar(texto: _ultimaBusqueda);
      _estado = pagina.recetas.isEmpty
          ? RecetasVacias(_ultimaBusqueda)
          : RecetasListas(pagina.recetas, pagina.total);
    } on FallaRed catch (falla) {
      _estado = RecetasFallidas(mensajePara(falla));
    } catch (_) {
      // Cualquier otro error: que la pantalla nunca se quede cargando.
      _estado = const RecetasFallidas(mensajeInesperado);
    }

    // Si la pantalla se cerró mientras viajaba la petición, no avisamos.
    if (!_liberado) notifyListeners();
  }

  Future<void> reintentar() => buscar(_ultimaBusqueda);

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
