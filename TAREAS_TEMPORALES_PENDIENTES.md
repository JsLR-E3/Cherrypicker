# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-032: LXP-15 (dos sets: II en presets, I en registros) en dos ficheros, instalados; falta probarlos en DP.

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fases 1 a 6 del roadmap completadas** (`docs/14`). App AppKit `src/CherryPickerApp` (D-006; `swift test` 94/94;
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`) con todas las pestañas: MIDI (audición y Test Note, D-008),
  Device, Patch Banks, Controllers (D-009; DP no la usa, EXP-027) y Categories; Patch Names con Find, Copy...,
  arrastre entre documentos y banco nuevo desde la selección (P21); asistente New; «Install in DP…». Uso en `docs/30`.
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de CherryPicker); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022 y EXP-027; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.
  Además, `MOTU/TC Electronic/M3000 optimizado.midnam` (EXP-030) y
  `MOTU/Digitech/DSP-128 Plus optimizado.midnam` (EXP-031, con `sudo`),
  `MOTU/Lexicon/LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (EXP-032, con `sudo`); deshacer: borrar esos ficheros. Los demás de esas
  carpetas son del usuario.
- **Copias de trabajo del usuario** en `reference/midnam_trabajo/` (privadas, no versionadas; no se borran ni se
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él), `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023) y `M3000 optimizado.midnam` (T-030) y `DSP-128 Plus optimizado.midnam` (T-031),
  `LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (T-032).
- **Antes de compartir la app** (D-007): nombre e icono propios, revisar textos cortos tomados de los nibs, licencia.
- **Idea para un proyecto futuro:** `docs/40_IDEA_EDITOR_FX_BCR2000.md` (fuera del alcance).

## EN PROGRESO

- —

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-032 | A | PENDIENTE-LOCAL | Optimizar los `.midnam` del LXP-15 convertido a II (presets = set II, registros = set I) contra los dos manuales (`reference/manuales/LXP-15/`) | — | Ver ficha. Aceptación: el usuario los prueba en DP 11.36 con las unidades (EXP nuevo) |

## Fichas

- **T-032 (LXP-15 I/II):** caso del usuario: dos LXP-15 con la ROM del II; los 128 presets son los del II y los 128
  registros guardan los del I. *Pgm Chg* (página Global) decide a qué afecta el Program Change: Pre, Reg u Off, o Map
  (tabla de 128 entradas que manda cada PC a un preset o registro). Ni Bank Select ni otra forma documentada sin SysEx
  para cambiarlo: el usuario lo cambia a mano y elige en DP el fichero del set. Idea comentada: una unidad fija en Pre y
  la otra en Reg. Ficheros nuevos (originales de `reference/midnam_usuario/` sin tocar), VÁLIDOS contra la DTD:
  `LXP-15 II Presets.midnam` (Pgm Chg = Pre) y `LXP-15 I Registers.midnam` (Pgm Chg = Reg); el nombre del fichero es lo
  que sale en *Master Names*. Bancos sin Bank Select con el estilo del SPX2000 del usuario (banco general y sub-bancos
  con «- »): II = All Presets, Studio (- Halls, - Rooms, - Plates, - Gates, - Delay/Pitch/Mod), Stage; I = All
  Registers, General (- Halls, - Rooms, - Plates, - Gates, - Delay/Pitch, - Chorus/Mod, - Special), Guitar/Bass,
  Guitar/Keyboard, Keyboards, FX (tipos según el algoritmo de cada preset en los manuales). Marcas al final del nombre,
  sacadas de la columna «Patch» de los manuales: [F] pedal, [M] controlado por MIDI (rueda, aftertouch, sustain, reloj),
  [E] nivel de entrada (60 en el II, 44 en el I). Único error: I 86 «RoomChrEnv» (repetido) → «Spacious5th^». Comprobado
  con script: 128 PC, un nombre por PC, canales iguales; el resto de nombres sin cambios. DP solo muestra un nivel de
  submenús (EXP-006, EXP-011).
  Instalados por el usuario con `sudo` en `MOTU/Lexicon/` (EXP-032, cómo deshacerlo allí). Propuesto (sin aplicar):
  rango en el nombre del banco («- Halls 1–6»), quitar «Studio» en el II, y probar «└»/«›» en vez de «- ».
  **Falta:** la prueba del usuario en DP (EXP-032).

## SIGUIENTE PASO EXACTO

0. T-032: resultado de la prueba en DP (EXP-032). Después, otro `.midnam` como en T-030/T-031 (`docs/15`, EXP-030 y EXP-031): PCM-81 o PCM-91, con sus manuales en `incoming/`
   (se archivan en `reference/manuales/<modelo>/`).
1. **Con el usuario, decidir el siguiente bloque:** preparar la app para compartir (D-007: nombre e icono propios,
   revisar textos cortos de los nibs con `grep -rn '"[A-Z][^"]\{20,\}"' src/CherryPickerApp/Sources/CherryPicker`,
   licencia) o Note Lists (fuera por ahora, docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
