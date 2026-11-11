// Las formas en que puede fallar una consulta, vistas desde el dominio.
// Son "sealed": al hacer un switch el compilador obliga a cubrir todas.

sealed class FallaRed implements Exception {
  const FallaRed();
}

/// No hubo red: modo avión, Wi-Fi apagado, DNS que no resuelve...
final class SinConexion extends FallaRed {
  const SinConexion();
}

/// El servidor no respondió a tiempo.
final class TiempoAgotado extends FallaRed {
  const TiempoAgotado();
}

/// El servidor respondió con un código 5xx.
final class ErrorDelServidor extends FallaRed {
  const ErrorDelServidor(this.codigo);
  final int codigo;
}

/// El servidor respondió con un código que no es 2xx ni 5xx (4xx...).
final class PeticionRechazada extends FallaRed {
  const PeticionRechazada(this.codigo);
  final int codigo;
}

/// Llegó una respuesta, pero no tiene la forma esperada.
final class RespuestaInvalida extends FallaRed {
  const RespuestaInvalida();
}
