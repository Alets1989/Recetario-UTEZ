# Evidencias — Recetario UTEZ

**Nombre:** Martin Alejandro Jimenez Lorenzo
**Matrícula:** I20233TN217
**Fecha:** 10 de noviembre de 2026
**Dispositivo donde se probó:** Windows, con el cliente Dio de la app contra DummyJSON

## 1. Del JSON a Dart

| JSON | Campo Dart | Tipo | Regla (obligatorio, tolerado, valor por defecto) |
|---|---|---|---|
| `id` | `id` | `int` | Obligatorio. Si falta o no es entero, `FormatException`. |
| `name` | `nombre` | `String` | Obligatorio. |
| `cuisine` | `cocina` | `String` | Obligatorio. |
| `difficulty` | `dificultad` | `Dificultad` | Tolerado. `Easy` → Fácil, `Medium` → Media, `Hard` → Difícil. Si falta o trae otro valor, `desconocida` (Sin dato). No tumba la receta. |
| `prepTimeMinutes` | `minutosPreparacion` | `int` | Obligatorio. |
| `cookTimeMinutes` | `minutosCoccion` | `int` | Obligatorio. |
| `servings` | `porciones` | `int` | Obligatorio. |
| `rating` | `calificacion` | `double` | Obligatorio, pero se lee como `num`. Llega entero (`5`) o decimal (`4.9`) y se pasa a `double` con `toDouble()`. En chicken, Biryani llegó como 5 y se muestra 5.0. |
| `tags` | `etiquetas` | `List<String>` | Tolerado. Si falta, lista vacía. Si no es una lista de textos, `FormatException`. |
| `ingredients` | `ingredientes` | `List<String>` | Igual que `tags`. |
| `recipes` | `PaginaRecetas.recetas` | `List<Receta>` | Obligatorio en la página. Cada elemento tiene que ser un objeto. |
| `total` | `PaginaRecetas.total` | `int` | Obligatorio. Se conserva el total del servidor, no el largo de la lista. |

`skip`, `limit`, `image` y el resto de campos de DummyJSON no se usan. `tiempoTotal` y `esRapida` no vienen del JSON: se calculan en el dominio.

## 2. Escenarios probados con el servicio real

| Escenario | Cómo lo provoqué | Qué vio la persona | Línea de la bitácora | Captura | Prueba del kit que lo cubre |
|---|---|---|---|---|---|
| Éxito | Busqué `chicken` en DummyJSON (`GET /recipes/search?q=chicken&limit=10`). | 8 tarjetas. Encabezado: «Mostrando 8 de 8 recetas · Rápidas: 1». La primera es Chicken Alfredo Pasta, Italian · Media, 35 min, 4 porciones, calificación 4.9. Solo Teriyaki Chicken Stir-Fry lleva el chip Rápida. | `→ GET /recipes/search` y `← 200 GET /recipes/search (683 ms)` | `docs/capturas/01_exito.png` | `200 → PaginaRecetas` y `texto + botón → indicador y botón apagado → tarjetas` |
| Vacío | Busqué `zzzz`. | «No encontramos recetas para "zzzz".» Sin tarjetas y sin botón Reintentar. | `→ GET /recipes/search` y `← 200 GET /recipes/search (756 ms)` | `docs/capturas/02_vacio.png` | `200 sin resultados → página vacía` y `sin resultados → Vacias, recordando qué se buscó` |
| Error del servidor | Interceptor temporal: la ruta pasó a `/http/503` para que DummyJSON respondiera 503. Luego se quitó. | «El recetario no está disponible (503). Intenta más tarde.» y el botón Reintentar. | `→ GET /recipes/search` y `✗ badResponse 503 GET /http/503 (300 ms)` | `docs/capturas/03_error_servidor.png` | `503 → ErrorDelServidor(503)` y `FallaRed → Fallidas con el mensaje de mensajePara` |
| Sin red | Interceptor temporal: `baseUrl` a `https://recetario.invalid`. No hubo respuesta HTTP. Luego se quitó. | «Sin conexión. Revisa tu red e intenta de nuevo.» y Reintentar. | `→ GET /recipes/search` y `✗ connectionError GET /recipes/search (38 ms)` | `docs/capturas/04_sin_red.png` | `sin red → SinConexion` |
| Tiempo agotado | Interceptor temporal: `delay=5000` y timeouts de conexión y lectura en 2 s. Luego se quitó. | «El recetario tardó demasiado en responder. Intenta de nuevo.» y Reintentar. | `→ GET /recipes/search` y `✗ receiveTimeout GET /recipes/search (2107 ms)` | `docs/capturas/05_tiempo_agotado.png` | `receiveTimeout → TiempoAgotado` |

La bitácora anota la ruta en el `onRequest`, antes de que el interceptor temporal cambie el path. Por eso el 503 sale como `GET /recipes/search` al salir y como `GET /http/503` al fallar. En Chrome el mismo tiempo agotado a veces llega como `connectionTimeout`; los dos se traducen a `TiempoAgotado` y el texto de la pantalla es el mismo.

## 3. Preguntas de reflexión

1. En «Error del servidor» sí hubo HTTP: la conexión se hizo y DummyJSON contestó 503. En «Sin red» no hubo respuesta HTTP; la petición ni siquiera completó la conexión (`connectionError`, sin código). Los dos terminan en la pantalla de error, pero uno es un fallo del servidor y el otro es que no se pudo hablar con él.

2. «Vacío» no es un error porque el servicio respondió 200 con `"recipes": []`. La búsqueda funcionó; simplemente no hay recetas para ese texto. Por eso la pantalla usa `RecetasVacias` y dice qué se buscó, en vez de `RecetasFallidas` y Reintentar.

3. La bitácora no escribe la búsqueda porque viaja en la query (`q`). El interceptor registra `options.path` (método y ruta), el código y el tiempo. No usa `options.uri` ni `queryParameters`, así que no guarda lo que la persona escribió, ni encabezados, ni el cuerpo.

4. Si DummyJSON cambiara `rating` por `score`, solo habría que modificar `lib/datos/recetas_json.dart`. Esa clase es la frontera con el JSON: lee `rating`, lo convierte a `double` y lo guarda en `calificacion`. El dominio, el ViewModel y las vistas hablan de `calificacion` y no conocen la llave del servidor.
