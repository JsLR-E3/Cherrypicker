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

## EXP-002 · 2026-10-19 · Dónde lee Digital Performer 11.36 los `.midnam`

- **Herramienta:** `ls`, `find`, `cmp`, `plutil`, `strings` (solo lectura; no se ha copiado ni cambiado nada).
- **Procedimiento:** inventario de `/Library/Audio/MIDI Devices`, `/Library/Audio/MIDI Patch Names` y sus equivalentes
  en `~/Library`; comparar los ficheros instalados con `reference/midnam_usuario/`; buscar en DP 11.36 las cadenas
  del formato.
- **Captura:** `captures/exp002/carpetas_dp.txt`
- **Resultado:**
  - `/Library/Audio/MIDI Devices/MOTU/` (carpeta del usuario, 2026-10-19): 341 `.midnam` y 58 `.middev`, organizados
    como `.middev` por fabricante (sueltos o dentro de su carpeta, p. ej. `Lexicon/Lexicon.middev`) y
    `<Fabricante>/<Modelo>.midnam`. `MOTU/` tiene permisos `drwxrwxrwx`: se puede escribir sin administrador.
  - Los 6 ficheros del usuario están instalados ahí y son **idénticos** a los de `reference/`: `TC Electronic/M3000`,
    `Lexicon/LXP-15`, `Lexicon/LXP-15 II`, `Lexicon/PCM-81`, `Lexicon/PCM-91`, `Digitech/DSP-128 Plus`.
  - Hay además `TC Electronic/M3000.midnam copia` (distinto del actual) y **ninguna** `.middev` de TC Electronic;
    `Lexicon.middev` no incluye LXP-15 II.
  - `~/Library/Audio/MIDI Devices` no existe. `/Library/Audio/MIDI Patch Names/Avid/` (286 `.midnam`) es de Pro Tools.
  - DP 11.36 (`com.motu.DigitalPerformer`, x86_64 + arm64): `MidiSystem.framework` contiene el DOCTYPE
    `MIDINameDocument 1.0`, la DTD de midi.org y los elementos `CustomDeviceMode`, `StandardDeviceMode`,
    `ChannelNameSet`, `UsesPatchNameList`, `PatchMIDICommands`, `NoteNameList`, `ControlNameList`,
    `UsesControlNameList`, `ExtendingDeviceNames`, y las extensiones `midnam`/`middev`. La ruta no aparece como
    cadena literal.
- **Conclusión:** DP 11.36 lee de `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` (usuario, que los usa a diario, +
  ficheros instalados idénticos; D por las cadenas de DP). DP entiende `UsesControlNameList` (DTD 1.0), que
  CherryPicker 3.0 no lee: las listas de controles deberán escribirse en forma 1.0. Pendiente (A): si DP necesita
  `.middev` para un modelo, si lee `* copia` y si hay que reiniciarlo tras instalar.
- **Respuestas del usuario (2026-10-19) y captura** `captures/exp002/dp_bundles_midi_device_properties.png`:
  1. Los modelos sin `.middev` funcionan: en DP, *Bundles → MIDI Devices*, cada dispositivo (creado antes en
     Configuración de Audio MIDI, p. ej. M3000 con fabricante TC Electronic) tiene *MIDI Device Properties → Patches*
     con **Port** y **Master Names**, donde se elige el `.midnam` (`M3000`). DP muestra entonces la lista de bancos
     del fichero en su orden (`Top 20`, `Halls`, `Rooms`, `Plates`, `Gated Reverb`…) con una columna **Override**
     (`Default`) por banco. Ya hay dispositivos A/B por puerto para LXP-15 y LXP-15 II.
  2. `M3000.midnam copia` es un resto de pruebas del usuario.
  3. No recuerda si DP recarga solo; cree que hay que volver a elegirlo en *MIDI Device Properties*. Por probar.
- **Conclusión ampliada:** el `.middev` no es necesario para usar un `.midnam` (usuario + captura: A). Los nombres de
  `PatchBank` son lo que el usuario ve en DP, en el orden del fichero (A).

## EXP-003 · 2026-10-19 · Ida y vuelta sin pérdidas de los .midnam con MidnamKit (T-007)

- **Herramienta:** `src/MidnamKit` (`swift test`); lee **copias** de `reference/midnam_usuario/` en un directorio
  temporal, nunca los originales.
- **Procedimiento:** para cada ejemplo, leer → reescribir desde el árbol y desde el modelo tipado → comparar byte a
  byte con el original; contar elementos sin tipo y presets tipados. Tests sintéticos para estilo CherryPicker y MOTU,
  elemento desconocido, atributo extra, orden no canónico, documento nuevo y errores.
- **Resultado:** 8 tests, 0 fallos; compilación limpia sin avisos. Los 6 ejemplos salen **idénticos** desde el árbol
  y desde el modelo, con 0 elementos sin tipo. Presets: DSP-128 Plus 128, LXP-15 128, LXP-15 II 128, M3000 1112,
  PCM-81 900, PCM-91 800.
- **Conclusión:** formato de escritura de CherryPicker y de MOTU confirmado (B reproducido + D):
  `protocol/confirmed/midnam_formato_escritura.md`.
