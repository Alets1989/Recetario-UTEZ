import 'package:flutter/material.dart';

import 'app.dart';
import 'datos/cliente_http.dart';
import 'datos/dummyjson_repositorio.dart';

void main() {
  runApp(AppRecetario(repositorio: DummyJsonRepositorio(crearDioRecetas())));
}
