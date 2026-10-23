#!/bin/bash
# Captura solo las ventanas de la app (no el resto de la pantalla del usuario) en PNG, para revisar la interfaz.
# Uso: tools/capturar_app.sh [carpeta_destino] [proceso]   (por defecto: build/capturas, CherryPicker)
# Necesita permiso de Grabación de pantalla para el terminal. Compila tools/ventanas_app.swift la primera vez.
set -euo pipefail
cd "$(dirname "$0")/.."
destino="${1:-build/capturas}"
proceso="${2:-CherryPicker}"
mkdir -p "$destino" build
bin=build/ventanas_app
[ -x "$bin" ] && [ "$bin" -nt tools/ventanas_app.swift ] || swiftc -O tools/ventanas_app.swift -o "$bin"
n=0
while IFS=$'\t' read -r id titulo tam; do
	id="${id// /}"
	[ -n "$id" ] || continue
	nombre=$(echo "$titulo" | sed 's/^ *//;s/ *$//;s/[^A-Za-z0-9._-]/_/g')
	f="$destino/${id}_${nombre:-ventana}.png"
	screencapture -x -o -l "$id" "$f"
	echo "$f ($tam )"
	n=$((n + 1))
done < <("$bin" "$proceso")
[ "$n" -gt 0 ] || { echo "No hay ventanas de $proceso en pantalla" >&2; exit 1; }
