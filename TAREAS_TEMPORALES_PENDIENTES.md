# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-025 a T-027 y T-014 completadas (Categories, Find, nota de prueba D-008; arrastrar entre documentos; Copy...; DP no usa la ControlNameList, EXP-024 a EXP-027).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 completa** (diseño `docs/20`; app AppKit `src/CherryPickerApp`, D-006; `swift test` 79/79;
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`). Probado en la app y en DP 11.36: Patch Banks (Merge, Find, Zap
  Dups, Import), Patch Names (Find con «Filter» / «Select Matches»), Device, MIDI (audición; Test Note con el MKS-50,
  D-008), Categories, arrastrar bancos y patches entre documentos (P18), Copy... (P19), asistente New e «Install in
  DP…». Fases 3, 4 y 6 hechas. Uso en `docs/30`.
- Fase 5 (Controllers): DP 11.36 no muestra los nombres de `ControlNameList` (EXP-006, EXP-027); falta que el usuario
  decida si se hace la pestaña igualmente o se deja fuera (MidnamKit ya conserva las listas de un fichero abierto).
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de CherryPicker); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022 y EXP-027; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.
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

1. **Fase 5 con el usuario:** con EXP-027 (DP no usa los controles con nombre), decidir si la pestaña Controllers se
   hace igualmente (p. ej. para otros programas) o queda fuera; anotarlo como D-009 y en `docs/14` y `docs/20` §2.
