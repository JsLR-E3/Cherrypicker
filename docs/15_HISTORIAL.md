# 15 — HISTORIAL DE TAREAS

Tareas cerradas, una línea cada una, más recientes arriba. El detalle está en el commit y en los EXP citados; aquí no se
copia. Se consulta por `grep` (p. ej. `grep T-012 docs/15_HISTORIAL.md`), no se lee entero al empezar una sesión.

| ID | Cerrada | Resultado (y cómo se verificó) | Commit · EXP · D |
|---|---|---|---|
| T-017 | 2026-10-20 | Hoja Bank Selects contrastada con CherryPicker 3 en Snow Leopard: la opción 2 estaba mal deducida y se corrige; las tres reproducen el original byte a byte | este commit · EXP-009 |
| T-015 | 2026-10-20 | App AppKit decidida (D-006) y esqueleto en `src/CherryPickerApp`: abre un `.midnam` y muestra Patch Banks; `swift test` 1/1 y prueba abriendo el fichero de EXP-006 | este commit · EXP-007 · D-006 |
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
