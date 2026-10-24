# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · D-010 («• » y árbol ├ └) en todos los `.midnam` hechos (M3000, DSP-128, LXP-15 I/II, SPX2000), probados en DP (EXP-035).

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
  `MOTU/Lexicon/LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (EXP-032/034, con `sudo`),
  `MOTU/Yamaha/SPX2000 optimizado.midnam` (EXP-034), `MOTU/Lexicon/PCM-81 optimizado.midnam` (EXP-037); deshacer: borrar esos ficheros. Los demás de esas
  carpetas son del usuario.
- **Permisos de DP cambiados por el usuario** (2026-10-24, con `sudo chown jslr`): las carpetas `MOTU/Digitech`,
  `MOTU/Lexicon` y `MOTU/Yamaha` son del usuario (antes `root:wheel`, `drwxrwxr-x`; los ficheros de dentro no se tocaron)
  para copiar sin contraseña; `MOTU/TC Electronic` ya era suya. Los ficheros copiados antes con `sudo` siguen siendo de root:
  se sustituyen con `cp -f` o desde el Finder. **Deshacer:** `sudo chown root` sobre las tres carpetas. Una
  actualización de DP podría devolverlas a root.
- **Copias de trabajo del usuario** en `reference/midnam_trabajo/` (privadas, no versionadas; no se borran ni se
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él), `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023) y `M3000 optimizado.midnam` (T-030) y `DSP-128 Plus optimizado.midnam` (T-031),
  `LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (T-032), `SPX2000.midnam`
  (copia del instalado en DP) y `SPX2000 optimizado.midnam` (EXP-034).
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
| T-033 | B | PENDIENTE | App: viñeta «• » y sub-bancos en árbol «├ »/«└ » (D-010) gestionados desde Patch Banks (P22 en `docs/20`) | — | Diseñar con el usuario (controles, qué pasa al reordenar y al abrir ficheros con «- »), implementar con tests en `CherryPickerCore` y probar en DP con un fichero de prueba |

## Fichas

- —

## SIGUIENTE PASO EXACTO

0. PCM-91 (sus PDF ya están en `incoming/`; mismo método que PCM-81, EXP-037). Después, otro `.midnam` como en T-030/T-031 (`docs/15`, EXP-030 y EXP-031), con la viñeta y el árbol de D-010: PCM-81 o PCM-91, con sus manuales en `incoming/`
   (se archivan en `reference/manuales/<modelo>/`).
1. **Con el usuario, decidir el siguiente bloque:** preparar la app para compartir (D-007: nombre e icono propios,
   revisar textos cortos de los nibs con `grep -rn '"[A-Z][^"]\{20,\}"' src/CherryPickerApp/Sources/CherryPicker`,
   licencia) o Note Lists (fuera por ahora, docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
