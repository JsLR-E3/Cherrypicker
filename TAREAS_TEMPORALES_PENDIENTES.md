# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-23 · local (`main`) · T-020 COMPLETADA: pestaña Device probada en la app y en DP (EXP-016).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha** (diseño en `docs/20`, D-005/D-007; app AppKit en `src/CherryPickerApp`, D-006):
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`. Hechas y probadas en la app y en DP 11.36:
  pestaña Patch Banks (EXP-010/011) con Merge, Find y Zap Dups (EXP-014/015), pestaña Device (EXP-016) y ventana
  Patch Names (EXP-013), con Tab y flechas al editar (P10). `swift test` 58/58.
- **Original** en Snow Leopard (Mac mini del usuario) para contrastar (EXP-009, EXP-012). Allí queda un `.middev`
  «Prueba / Prueba» del asistente del original (EXP-012), lo borra el usuario cuando quiera.
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` («CP Canales»,
  EXP-011; «CP Patches», EXP-013; «CP Zap» con «Prueba zap», «… sin zap» y «… orden», EXP-015; «Prueba device» en CP Canales, EXP-016). Deshacer: borrar esa carpeta.
- Base: MidnamKit sin pérdidas y validación DTD (fase 1); cómo lee DP los `.midnam` (fase 2); estados en
  `protocol/PROTOCOL_INDEX.md`.

## EN PROGRESO

- T-021 (ficha abajo).

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-021 | A | EN PROGRESO | Pestaña MIDI y audición (D-002) | T-020 | Ficha T-021 |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

**T-021 — Pestaña MIDI y audición** (D-002, P5; docs/20 §4 flujo 5).
- Hecho: `CherryPickerCore/Audition.swift` (bytes; solo CC0/CC32/Program Change; 4 tests, 62/62), `MIDIOut.swift`
  (CoreMIDI, UMP MIDI 1.0), pestaña MIDI (Device Out, Enable MIDI desactivado al abrir), envío al seleccionar un
  patch en la lista y Audition Ch editable en Device (recordados por fabricante y modelo en la app).
- Verificado con un destino virtual (EXP-017): bytes y canales correctos; CPU 0,0 % en reposo.
- Falta: probar con un módulo real (permiso del usuario, solo esos mensajes) y documentar la pestaña en `docs/20`.

## SIGUIENTE PASO EXACTO

1. **Abrir T-021 con el usuario:** proponerle una de estas (docs/20 §3): Copy... en la lista de presets, Import
   desde otros `.midnam`, la pestaña Controllers o Categories, la pestaña MIDI con la audición (Audition Ch, D-002) o
   el asistente New. Decidir también el Find de la lista de patches (filtrar o seleccionar, docs/20 §3.2).
2. Menor, con el usuario y DP abierto: T-014.
