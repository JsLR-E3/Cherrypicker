#!/bin/sh
# Compila src/CherryPickerApp y monta build/Midnamer.app (firma ad hoc, solo para este Mac). T-015; nombre e icono, D-011.
# Uso: tools/empaquetar_app.sh [debug|release]   (por defecto release)
#      UNIVERSAL=1 tools/empaquetar_app.sh        → arm64 + x86_64 (para repartir, T-037; lo usa tools/distribuir.sh)
set -eu
cd "$(dirname "$0")/.."
conf="${1:-release}"
pkg=src/CherryPickerApp
archs=""
[ "${UNIVERSAL:-0}" = 1 ] && archs="--arch arm64 --arch x86_64"
# shellcheck disable=SC2086
swift build -c "$conf" $archs --package-path "$pkg"
# shellcheck disable=SC2086
bin="$(swift build -c "$conf" $archs --package-path "$pkg" --show-bin-path)/Midnamer"
app=build/Midnamer.app
rm -rf "$app" build/Midnamer.iconset
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/Midnamer"
sed "s/<string>VERSION<\/string>/<string>$(cat VERSION)<\/string>/" "$pkg/Info.plist" > "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist" >/dev/null
cp README.md "$app/Contents/Resources/README.md"   # Help ▸ Midnamer Help (T-036)
cp LICENSE "$app/Contents/Resources/LICENSE"       # GPL-3.0 (D-011)
swift tools/icono/dibujar_icono.swift build/Midnamer.iconset
iconutil -c icns -o "$app/Contents/Resources/Midnamer.icns" build/Midnamer.iconset
codesign --force --sign - "$app"
echo "$app"
