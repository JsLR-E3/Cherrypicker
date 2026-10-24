#!/bin/sh
# Compila src/CherryPickerApp y monta build/Midnamer.app (firma ad hoc, solo para este Mac). T-015; nombre e icono, D-011.
# Uso: tools/empaquetar_app.sh [debug|release]   (por defecto release)
set -eu
cd "$(dirname "$0")/.."
conf="${1:-release}"
pkg=src/CherryPickerApp
swift build -c "$conf" --package-path "$pkg"
bin="$(swift build -c "$conf" --package-path "$pkg" --show-bin-path)/Midnamer"
app=build/Midnamer.app
rm -rf "$app" build/Midnamer.iconset
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/Midnamer"
sed "s/<string>VERSION<\/string>/<string>$(cat VERSION)<\/string>/" "$pkg/Info.plist" > "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist" >/dev/null
swift tools/icono/dibujar_icono.swift build/Midnamer.iconset
iconutil -c icns -o "$app/Contents/Resources/Midnamer.icns" build/Midnamer.iconset
codesign --force --sign - "$app"
echo "$app"
