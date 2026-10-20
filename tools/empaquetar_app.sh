#!/bin/sh
# Compila src/CherryPickerApp y monta build/CherryPicker.app (firma ad hoc, solo para este Mac). T-015.
# Uso: tools/empaquetar_app.sh [debug|release]   (por defecto release)
set -eu
cd "$(dirname "$0")/.."
conf="${1:-release}"
pkg=src/CherryPickerApp
swift build -c "$conf" --package-path "$pkg"
bin="$(swift build -c "$conf" --package-path "$pkg" --show-bin-path)/CherryPicker"
app=build/CherryPicker.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/CherryPicker"
sed "s/<string>VERSION<\/string>/<string>$(cat VERSION)<\/string>/" "$pkg/Info.plist" > "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist" >/dev/null
codesign --force --sign - "$app"
echo "$app"
