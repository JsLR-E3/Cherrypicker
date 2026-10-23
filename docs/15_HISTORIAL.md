# 15 — HISTORIAL DE TAREAS

Tareas cerradas, una línea cada una, más recientes arriba. El detalle está en el commit y en los EXP citados; aquí no se
copia. Se consulta por `grep` (p. ej. `grep T-012 docs/15_HISTORIAL.md`), no se lee entero al empezar una sesión.

| ID | Cerrada | Resultado (y cómo se verificó) | Commit · EXP · D |
|---|---|---|---|
| T-024 | 2026-10-23 | «Install in DP…» (File, ⌘I; P3): copia a `MOTU/<Fabricante>/` con confirmación, `.middev` propio opcional, copia de seguridad y cómo deshacer. 3 tests (72/72); probado en la app y en DP 11.36 (el modelo sale en la lista y en Master Names) | 7f55a86…e4ebba6 · EXP-021, EXP-022 |
| T-023 | 2026-10-23 | Asistente Device Setup (File ▸ New): fabricante/modelo con autocompletado desde los `.middev` (sin distinguir mayúsculas), aviso de `.middev`, grupos de canales; documento nuevo válido con un banco vacío por grupo. 4 tests (69/69); probado a mano por el usuario | 45189f5…912fc26 · EXP-020 |
| T-022 | 2026-10-23 | Import desde otros `.midnam` (Patchlist Importer): ficheros de una carpeta con su Type, listas con destino (mismo nombre, otro banco o «Add as New Bank», P14). 3 tests (65/65); probado a mano por el usuario (2 arreglos) | 8f70157…736c531 · EXP-019 |
| T-021 | 2026-10-23 | Pestaña MIDI y audición por CoreMIDI: Device Out, Enable MIDI (P5), envío de CC0/CC32 + Program Change al seleccionar un patch, Audition Ch editable. 4 tests (62/62); bytes comprobados con un destino virtual y probada con el M3000 en la Unitor8 | 7f3b42a…ed52e4a · EXP-017, EXP-018 · D-002 |
| T-020 | 2026-10-23 | Pestaña Device: Manufacturer/Model, modos y Channel Sets con + / − y renombrar, Active Channels, Audition Ch (solo se muestra), hojas New Channel Set y Reassign Banks To, P13. 9 tests (58/58); probada a mano por el usuario y en DP 11.36 (canales libres = «No Patches») | addf13e…271264b · EXP-016 |
| T-019 | 2026-10-23 | Patch Banks: Merge (hoja con Option-Add), Find (ventana Finder: Add New Bank With Patches, Remove Duplicates, −, arrastrar a listas) y Zap Dups (P11 confirmación, P12 con selección). 12 tests (49/49); probada a mano por el usuario (2 arreglos) y en DP 11.36 | 64c8594…73e8505 · EXP-014, EXP-015 |
| T-018 | 2026-10-22 | Ventana Patch Names (botón P): tabla B0 · B32 · # · Patch Name · Ascii editable, + / pegar / soltar texto (New Patches, regla P9), − , Renumber, ordenar por cabecera, Find y Count, arrastrar dentro y a otra lista, deshacer; Tab y flechas al editar (P10). 17 tests de la lógica; probada a mano por el usuario y en DP 11.36 (menús en el orden del fichero) | 8e3d36e…0f82aeb · EXP-012, EXP-013 |
| T-016 | 2026-10-20 | Pestaña Patch Banks editable (renombrar, Bank Selects, + / −, Channel Set, reordenar, cambio múltiple, deshacer) y guardar; disposición como el original; DP 11.36 lee el fichero editado y respeta los Channel Sets | ad79cdc…774b9e6 · EXP-008, EXP-010, EXP-011 |
| T-017 | 2026-10-20 | Hoja Bank Selects contrastada con CherryPicker 3 en Snow Leopard: la opción 2 estaba mal deducida y se corrige; las tres reproducen el original byte a byte | 73840f2 · EXP-009 |
| T-015 | 2026-10-20 | App AppKit decidida (D-006) y esqueleto en `src/CherryPickerApp`: abre un `.midnam` y muestra Patch Banks; `swift test` 1/1 y prueba abriendo el fichero de EXP-006 | cbf25d5 · EXP-007 · D-006 |
| T-010 | 2026-10-20 | Diseño de la app acordado (`docs/20`): manual + inventario de los 26 nibs, propuestas P1–P7 aceptadas | 0916426 · D-005 |
| T-013 | 2026-10-20 | Proyecto migrado a la plantilla nueva de Claude Code (`CLAUDE.md`, `.claude/`, `docs/10`, `12`, `15`, índice y TAREAS); `comprobar.py` sin errores y `swift test` 12/12 | 030bceb (integrado en `main`) |
| T-012 | 2026-10-20 | DP 11.36 acepta un `.midnam` nuevo de MidnamKit con el DOCTYPE de midi.org; *Master Names* = nombre de fichero; menú de presets = nombre de `PatchNameList` + «Number Name»; modelo nuevo necesita `.middev`; recarga al volver a elegir en *Master Names*; ficheros de prueba retirados | e07e569, 6c84dd5 · EXP-006 · D-003 |
| T-011 | 2026-10-19 | Validación con `xmllint --dtdvalid` (catálogo local, `tools/validar_midnam.sh`); los 6 ejemplos y lo que escribe MidnamKit son válidos | dedb2d1 · EXP-005 |
| T-009 | 2026-10-19 | DTD MIDINameDocument 1.0 descargada (Wayback) a `reference/dtd/`; reglas de escritura contrastadas y modelo ampliado | 0edbbcf · EXP-004 |
| T-008 | 2026-10-19 | DP 11.36 lee `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`; asignación en *Master Names* | efe1dd8, c0ec5dd · EXP-002 |
| T-007 | 2026-10-19 | Fase 1: `src/MidnamKit` lee y reescribe los 6 ejemplos byte a byte; `swift test` | 6894e6b · EXP-003 |
| T-006 | 2026-10-19 | `CLAUDE.md` y `docs/11` adaptados de aparato a programa | e7de990 |
| T-005 | 2026-10-19 | Alcance y fases acordados con el usuario (`docs/14`) | 0ebd5b7, 11ae25b · D-001, D-002 |
| T-004 | 2026-10-19 | La app 3.0 no arranca en macOS 15.7.9 arm64 (ppc/i386); estructura midnam observada | e866c32 · EXP-001 |
| T-003 | 2026-10-19 | `incoming/` archivado en `reference/` e inventariado en `docs/01` | 5458556 |
| T-002 | 2026-10-19 | Repo GitHub privado `JsLR-E3/Cherrypicker` y remoto configurados | bc02486 |
| T-001 | 2026-10-19 | Estructura del proyecto desde la plantilla y git local | 5458556 |
