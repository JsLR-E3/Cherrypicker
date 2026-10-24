# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-025 a T-028 y T-014 completadas; fases 3 y 5 terminadas (EXP-024 a EXP-028, D-008, D-009).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fases 1 a 6 del roadmap completadas** (`docs/14`). App AppKit `src/CherryPickerApp` (D-006; `swift test` 92/92;
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`) con todas las pestañas: MIDI (audición y Test Note, D-008),
  Device, Patch Banks, Controllers (D-009; DP no la usa, EXP-027) y Categories; Patch Names con Find, Copy... y
  arrastre entre documentos; asistente New; «Install in DP…». Uso en `docs/30`.
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de CherryPicker); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022 y EXP-027; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.
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

## Fichas

- —

## SIGUIENTE PASO EXACTO

1. **Con el usuario, decidir el siguiente bloque:** usarla con sus `.midnam` reales (sobre copias) y anotar lo que
   falle o falte; preparar la app para compartir (D-007: nombre e icono propios, revisar textos de los nibs, licencia);
   o Note Lists (fuera por ahora, docs/20 §7.1). Lo elegido, como T-029 con su ficha.
