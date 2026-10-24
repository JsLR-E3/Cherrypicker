# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-025 completada (Categories, Find con «Select Matches», nota de prueba D-008; EXP-024).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 casi completa** (diseño `docs/20`; app AppKit `src/CherryPickerApp`, D-006; `swift test` 79/79;
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`). Probado en la app y en DP 11.36: Patch Banks (Merge, Find, Zap
  Dups, Import), Patch Names (Find con «Filter» / «Select Matches»), Device, MIDI (audición; Test Note con el MKS-50,
  D-008), Categories, asistente New e «Install in DP…». Fases 4 y 6 hechas. Uso en `docs/30`.
- Falta en la fase 3: Copy... en la lista de presets y arrastrar entre documentos. Fase 5 (Controllers) con T-014.
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de CherryPicker); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.
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
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

- —

## SIGUIENTE PASO EXACTO

1. **Elegir T-026 con el usuario:** Controllers (fase 5; antes T-014 con DP abierto: «Other Controller…» de una pista
   MIDI con un `.midnam` que tenga `ControlNameList`), Copy... de la lista de presets (nib CPPatchExport, docs/20 §2) o
   arrastrar bancos y presets entre documentos (docs/20 §3.1). Con la elegida, ficha y lógica con tests en
   `CherryPickerCore`.
