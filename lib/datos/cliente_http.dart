import 'package:dio/dio.dart';

import 'bitacora_interceptor.dart';

const urlDummyJson = 'https://dummyjson.com';

/// Crea el Dio de la app: HTTPS, timeouts y bitácora segura.
/// La bitácora va primero; después los interceptores extra que reciba.
Dio crearDioRecetas({List<Interceptor> interceptores = const []}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: urlDummyJson,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors
    ..add(BitacoraInterceptor())
    ..addAll(interceptores);
  return dio;
}
