#!/usr/bin/env bash
# Práctica evaluada Recetario UTEZ — verificación de capas, cliente HTTP y evidencias
#
#   bash verificar_recetario.sh
#
# Se corre desde la raíz de recetario_utez/ (o desde la carpeta que lo contiene).
# Las pruebas (flutter test) revisan que la app FUNCIONE; este script revisa
# que cada capa haga solo lo suyo, que el cliente sea prudente y que la
# evidencia esté completa.
#
# NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.
#
# Si el archivo llegó con saltos de línea de Windows (CRLF), se corre una copia limpia. Esta línea debe terminar en "#".
if grep -q $'\r' "$0" 2>/dev/null; then d=$(cd "$(dirname "$0")" && pwd); limpio="${TMPDIR:-/tmp}/verificar_recetario_lf.sh"; tr -d '\r' < "$0" > "$limpio"; VERIFICAR_DIR="$d" exec bash "$limpio" "$@"; fi #

aqui="${VERIFICAR_DIR:-$(cd "$(dirname "$0")" && pwd)}"

proyecto=""
for candidato in "$aqui" "$aqui/recetario_utez" "$PWD" "$PWD/recetario_utez"; do
  if [ -f "$candidato/pubspec.yaml" ] && grep -q "^name: recetario_utez" "$candidato/pubspec.yaml"; then
    proyecto="$candidato"
    break
  fi
done

if [ -z "$proyecto" ]; then
  echo "No encuentro el proyecto recetario_utez (falta pubspec.yaml con name: recetario_utez)."
  echo "Copien este script a la raíz de recetario_utez/ y córranlo desde ahí."
  exit 1
fi

cd "$proyecto" || exit 1
echo "Proyecto: $proyecto"

fallas=0

ok()    { echo "  OK     $1"; }
falta() { echo "  FALTA  $1"; fallas=$((fallas + 1)); }

importa() { grep -rqnE "^[[:space:]]*import[[:space:]]+['\"].*$1" "$2"; }
codigo() { grep -vhE "^[[:space:]]*//" "$@"; }
usa() { local patron="$1"; shift; codigo "$@" | grep -qE "$patron"; }

cliente=lib/datos/cliente_http.dart
bitacora=lib/datos/bitacora_interceptor.dart
vm=lib/presentacion/recetas_view_model.dart
pagina=lib/presentacion/recetas_pagina.dart
tarjeta=lib/presentacion/tarjeta_receta.dart

echo
echo "1) Archivos del contrato"
for f in \
  lib/dominio/receta.dart \
  lib/dominio/falla_red.dart \
  lib/datos/recetas_json.dart \
  "$cliente" \
  "$bitacora" \
  lib/datos/traducir_error.dart \
  lib/datos/recetas_repositorio.dart \
  lib/datos/dummyjson_repositorio.dart \
  lib/presentacion/mensajes.dart \
  "$vm" \
  "$tarjeta" \
  "$pagina" \
  lib/app.dart \
  lib/main.dart \
  docs/evidencias.md; do
  if [ -f "$f" ]; then ok "$f"; else falta "$f no existe"; fi
done

echo
echo "2) El dominio es Dart puro"
if [ -d lib/dominio ] && ! importa "package:(flutter|dio)" lib/dominio; then
  ok "lib/dominio no importa Flutter ni Dio"
else
  falta "lib/dominio no existe o importa Flutter o Dio"
fi
if [ -f lib/dominio/falla_red.dart ] && usa "sealed[[:space:]]+class[[:space:]]+FallaRed" lib/dominio/falla_red.dart; then
  ok "FallaRed es sealed"
else
  falta "FallaRed debe ser sealed class"
fi
if [ -f lib/dominio/receta.dart ] && usa "fromJson|json\[" lib/dominio/receta.dart; then
  falta "lib/dominio/receta.dart lee JSON: eso va en lib/datos/recetas_json.dart"
else
  ok "el dominio no sabe de JSON"
fi

echo
echo "3) Dio vive solo en lib/datos"
intrusos=$(grep -rlE "^[[:space:]]*import[[:space:]]+['\"]package:dio" lib 2>/dev/null | grep -v "^lib/datos/")
if [ -z "$intrusos" ]; then
  ok "solo lib/datos importa package:dio"
else
  for i in $intrusos; do falta "$i importa package:dio"; done
fi
if [ -d lib/datos ] && ! importa "package:flutter" lib/datos; then
  ok "lib/datos no importa Flutter"
else
  falta "lib/datos no existe o importa Flutter"
fi

echo
echo "4) El cliente HTTP es prudente"
if [ -f "$cliente" ]; then
  if usa "https://" "$cliente" && ! usa "['\"]http://" "$cliente"; then ok "$cliente usa HTTPS"; else falta "$cliente debe usar https://"; fi
  if usa "connectTimeout" "$cliente"; then ok "$cliente define connectTimeout"; else falta "$cliente no define connectTimeout"; fi
  if usa "receiveTimeout" "$cliente"; then ok "$cliente define receiveTimeout"; else falta "$cliente no define receiveTimeout"; fi
  if usa "BitacoraInterceptor" "$cliente"; then ok "$cliente agrega la bitácora"; else falta "$cliente no agrega BitacoraInterceptor"; fi
else
  falta "$cliente no existe"
fi
if [ -f lib/datos/dummyjson_repositorio.dart ] && usa "queryParameters" lib/datos/dummyjson_repositorio.dart; then
  ok "el repositorio usa queryParameters (no arma la URL a mano)"
else
  falta "lib/datos/dummyjson_repositorio.dart debe usar queryParameters"
fi

echo
echo "5) La bitácora no filtra datos"
if [ -f "$bitacora" ]; then
  if usa "extends[[:space:]]+Interceptor" "$bitacora"; then ok "BitacoraInterceptor extiende Interceptor"; else falta "BitacoraInterceptor no extiende Interceptor"; fi
  if usa "queryParameters|\.uri|headers|\.data\b|\.realUri" "$bitacora"; then
    falta "$bitacora toca query, uri, encabezados o cuerpo"
  else
    ok "$bitacora solo registra método, ruta, código y tiempo"
  fi
  if usa "handler\.next" "$bitacora"; then ok "$bitacora llama handler.next"; else falta "$bitacora nunca llama handler.next"; fi
else
  falta "$bitacora no existe"
fi

echo
echo "6) El ViewModel coordina, no dibuja ni sabe de HTTP"
if [ -f "$vm" ]; then
  if importa "material.dart" "$vm"; then falta "$vm importa material.dart (usen foundation.dart)"; else ok "$vm no importa material.dart"; fi
  if usa "extends[[:space:]]+ChangeNotifier" "$vm"; then ok "RecetasViewModel extiende ChangeNotifier"; else falta "RecetasViewModel no extiende ChangeNotifier"; fi
  if usa "sealed[[:space:]]+class[[:space:]]+EstadoRecetas" "$vm"; then ok "EstadoRecetas es sealed"; else falta "EstadoRecetas debe ser sealed class"; fi
  if usa "DummyJsonRepositorio|dummyjson|DioException" "$vm"; then falta "$vm conoce DummyJSON o DioException"; else ok "$vm solo conoce el contrato RecetasRepositorio"; fi
else
  falta "$vm no existe"
fi

echo
echo "7) Las vistas solo dibujan"
for v in "$pagina" "$tarjeta"; do
  if [ -f "$v" ]; then
    if importa "datos/" "$v"; then falta "$v importa algo de lib/datos"; else ok "$v no importa lib/datos"; fi
    if usa "\b(e|err|error|ex|excepcion|falla)\.toString\(\)|\\\$\{?(e|err|error|ex|excepcion|falla)\b|DioException|FallaRed" "$v"; then falta "$v muestra detalles técnicos (la excepción, DioException o FallaRed)"; else ok "$v no muestra detalles técnicos"; fi
  else
    falta "$v no existe"
  fi
done

echo
echo "8) Solo main.dart elige la fuente de datos y no quedaron pruebas manuales"
intrusos=$(grep -rlE "^[[:space:]]*import[[:space:]]+['\"].*dummyjson_repositorio" lib 2>/dev/null | grep -vE "^lib/main\.dart$")
if [ -z "$intrusos" ]; then
  ok "DummyJsonRepositorio solo se importa en main.dart"
else
  for i in $intrusos; do falta "$i importa DummyJsonRepositorio"; done
fi
if [ -f lib/main.dart ] && usa "AppRecetario" lib/main.dart && usa "crearDioRecetas" lib/main.dart; then
  ok "lib/main.dart arranca AppRecetario con crearDioRecetas"
else
  falta "lib/main.dart no arranca AppRecetario con crearDioRecetas"
fi
if [ -d lib ] && usa "['\"]delay['\"]|/http/[0-9]|\.invalid" $(find lib -name '*.dart'); then
  falta "quedó en lib/ un cambio temporal de la etapa 6 (delay, /http/... o .invalid). Regrésenlo."
else
  ok "no quedaron cambios temporales (delay, /http/..., .invalid) en lib/"
fi

echo
echo "9) La app puede salir a internet"
manifiesto=android/app/src/main/AndroidManifest.xml
if [ -f "$manifiesto" ] && grep -q "android.permission.INTERNET" "$manifiesto"; then
  ok "$manifiesto declara INTERNET"
else
  falta "$manifiesto no declara android.permission.INTERNET"
fi

echo
echo "10) Evidencias de la etapa 6"
if [ -f docs/evidencias.md ]; then
  for e in "Éxito" "Vacío" "Error del servidor" "Sin red" "Tiempo agotado"; do
    if grep -qi "$e" docs/evidencias.md; then ok "docs/evidencias.md menciona: $e"; else falta "docs/evidencias.md no menciona: $e"; fi
  done
else
  falta "docs/evidencias.md no existe"
fi
capturas=$(find docs/capturas -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | wc -l | tr -d ' ')
if [ "${capturas:-0}" -ge 5 ]; then
  ok "docs/capturas tiene $capturas imágenes"
else
  falta "docs/capturas debe tener al menos 5 imágenes (tiene ${capturas:-0})"
fi

echo
if [ "$fallas" -eq 0 ]; then
  echo "Resultado: todo OK. Ahora corran: flutter test"
  exit 0
else
  echo "Resultado: $fallas punto(s) en FALTA."
  exit 1
fi
