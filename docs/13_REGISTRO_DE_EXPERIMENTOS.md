# 13 — REGISTRO DE EXPERIMENTOS

Formato: ID · fecha · objetivo · procedimiento · resultado · conclusión (nivel).

<!--
## EXP-001 · AAAA-MM-DD · Objetivo en una línea

- **Herramienta:** `tools/…` (solo lectura / escribe en …, con permiso del usuario)
- **Procedimiento:** …
- **Captura:** `captures/<área>/…`
- **Resultado:** …
- **CPU:** (si aplica)
- **Conclusión:** … (A/B/C/D)
-->

## EXP-001 · 2026-10-19 · Arranque de CherryPicker 3.0 en este Mac y estudio estático de recursos y ejemplos

- **Herramienta:** `lipo`, ejecución directa y `arch`, `otool`, `plutil`, `xmllint --nonet`, script de recuento en
  Python (solo lectura; los `.midnam` del usuario no se modifican).
- **Procedimiento:** (1) ejecutar el binario de `reference/app_3.0/` directamente, con `arch -x86_64` y `arch -i386`;
  (2) comprobar los frameworks enlazados; (3) volcar los `.plist` de recursos; (4) recuento de elementos, DTD, formato
  de `Number` y combinaciones de bank select de los 6 `.midnam` (sin copiar nombres de presets).
- **Captura:** `captures/exp001/arranque.txt`, `captures/exp001/midnam_estructura.txt`
- **Resultado:**
  - macOS 15.7.9 arm64: «Bad CPU type in executable» en los tres casos. Rosetta está instalada pero solo traduce
    x86_64; el binario es ppc7400 + i386. Los frameworks (incluido Message.framework) siguen en la caché dyld, pero
    no en i386: **la app no puede arrancar aquí**.
  - `CPXMLRead.plist` lista los 36 elementos midnam que lee; `CPXMLStrings.plist` contiene la plantilla exacta con la
    que escribe cada uno (atributos y orden, p. ej. `<Patch Number="%@" Name="%@" ProgramChange="%@" />`).
  - `Defaults.plist`: carpetas por defecto `/Library/Audio/MIDI Devices/MOTU` (patches de MOTU/DP),
    `/Library/Audio/MIDI Patch Names/Digidesign`; opciones de escritura `CP_writeBankSx`, `CP_writePatchMidi`,
    `CP_writeControllers`, `CP_writeNotelist`, `CP_writeModeName`; categorías GM y E-MU en `Categories.plist`.
  - Ejemplos: los 4 de CherryPicker declaran DTD 1.0; los 2 de MOTU, DTD 0.7. Todos bien formados, LF, sangría con
    tabuladores. `Patch Number` es una **etiqueta de pantalla** (`"  1"`, `"065"`, `"400"`) y `ProgramChange` el valor
    MIDI. Bank select: LXP-15/LXP-15 II/DSP-128 Plus sin bank select (bancos solo de agrupación); PCM-81/91 una
    combinación CC0/CC32 por banco; M3000 23 bancos con 7 combinaciones y 155 presets con `PatchMIDICommands` propios
    (CC0+CC32+ProgramChange por preset). Ningún ejemplo usa `ControlNameList` ni `NoteNameList`.
- **Conclusión:** la app original no es ejecutable en el Mac de destino (A). Plantillas de escritura y elementos
  leídos: D (recursos de la app). Estructura de los ficheros que generó CherryPicker: B. Tres formas de bank select en
  uso: ninguna, por banco y por preset.
