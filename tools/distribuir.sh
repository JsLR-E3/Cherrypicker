#!/bin/sh
# Monta Midnamer.app universal y la comprime para repartirla: build/Midnamer-<VERSION>.zip (T-037).
# Firma ad hoc (sin cuenta de Apple Developer): quien la reciba la abre la primera vez con «Open Anyway» (README).
set -eu
cd "$(dirname "$0")/.."
UNIVERSAL=1 tools/empaquetar_app.sh release >/dev/null
app=build/Midnamer.app
[ "$(lipo -archs "$app/Contents/MacOS/Midnamer")" = "x86_64 arm64" ] || { echo "no es universal" >&2; exit 1; }
codesign --verify --strict "$app"
zip="build/Midnamer-$(cat VERSION).zip"
rm -f "$zip"
# ditto conserva la firma y los atributos del paquete (zip no).
ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"
echo "$zip"
