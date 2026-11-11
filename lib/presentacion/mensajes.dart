import '../dominio/falla_red.dart';

const mensajeInesperado = 'Algo salió mal. Intenta de nuevo.';

/// Texto para personas: claro y sin detalles técnicos.
String mensajePara(FallaRed falla) => switch (falla) {
  SinConexion() => 'Sin conexión. Revisa tu red e intenta de nuevo.',
  TiempoAgotado() =>
    'El recetario tardó demasiado en responder. Intenta de nuevo.',
  ErrorDelServidor(:final codigo) =>
    'El recetario no está disponible ($codigo). Intenta más tarde.',
  PeticionRechazada() =>
    'No pudimos hacer esa búsqueda. Avisa al equipo de desarrollo.',
  RespuestaInvalida() => 'Las recetas llegaron con un formato inesperado.',
};
