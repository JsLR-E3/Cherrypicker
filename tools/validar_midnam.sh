#!/bin/bash
# Valida .midnam contra la DTD MIDINameDocument 1.0 (copias locales en reference/dtd, sin red).
# Trabaja sobre copias temporales: sustituye el DOCTYPE por el canónico de la 1.0, porque el de CherryPicker
# lleva identificador de sistema "" (los validadores lo leen como el propio documento) y el de MOTU apunta a la 0.7.
# Uso: tools/validar_midnam.sh fichero.midnam...   Sale con 1 si alguno no es válido.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
CAT="file://$(python3 -I -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "$RAIZ/tools/midnam_catalog.xml")"
for d in MIDINameDocument10.dtd MIDIEvents10.dtd; do
	[ -f "$RAIZ/reference/dtd/$d" ] || { echo "Falta reference/dtd/$d" >&2; exit 2; }
done
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
DOCTYPE='<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 1.0//EN" "http://www.midi.org/dtds/MIDINameDocument10.dtd">'
fallos=0
for f in "$@"; do
	c="$TMP/$(basename "$f")"
	python3 -I - "$f" "$c" "$DOCTYPE" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s, n = re.subn(r"<!DOCTYPE\s+MIDINameDocument[^>]*>", sys.argv[3], s, count=1)
if n == 0:
    s = re.sub(r"(<\?xml[^>]*\?>\s*)?", lambda m: (m.group(0) or "") + sys.argv[3] + "\n", s, count=1)
open(sys.argv[2], "w", encoding="utf-8").write(s)
PY
	if out=$(XML_CATALOG_FILES="$CAT" xmllint --noout --nonet --valid "$c" 2>&1); then
		echo "VÁLIDO   $(basename "$f")"
	else
		echo "INVÁLIDO $(basename "$f")"
		echo "$out" | sed "s#$TMP/##" | head -20
		fallos=1
	fi
done
exit $fallos
