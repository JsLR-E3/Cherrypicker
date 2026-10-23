# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-23 · local (`main`) · T-019 a T-024 completadas: Merge/Find/Zap Dups, Device, MIDI y audición, Import, asistente New e «Install in DP…».

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 casi completa** (diseño `docs/20`; app AppKit `src/CherryPickerApp`, D-006; `swift test` 72/72;
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`). Probado en la app y en DP 11.36: Patch Banks con Merge, Find,
  Zap Dups e Import; ventana Patch Names; pestañas Device y MIDI (audición con el M3000, EXP-018); asistente New;
  «Install in DP…». Fases 4 y 6 del roadmap hechas. Uso en `docs/30`.
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de CherryPicker); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.

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

1. **Abrir T-025 con el usuario:** leer `docs/20` §3.1–3.2 y proponerle Controllers (con T-014), Categories o Copy...
   en la lista de presets; con la elegida, ficha y lógica con tests en `CherryPickerCore`. Decidir también el Find de
   la lista de patches (filtrar o seleccionar como el original, docs/20 §3.2) y si se quiere una nota de prueba
   opcional para módulos de sonido (ampliaría D-002).
2. Menor, con el usuario y DP abierto: T-014.
