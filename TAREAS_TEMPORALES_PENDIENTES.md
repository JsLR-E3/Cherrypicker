# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-23 · local (`main`) · T-019 COMPLETADA: Merge, Find y Zap Dups probados en la app y en DP (EXP-014/015).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha** (diseño en `docs/20`, D-005/D-007; app AppKit en `src/CherryPickerApp`, D-006):
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`. Hechas y probadas en la app y en DP 11.36:
  pestaña Patch Banks (EXP-010/011) con Merge, Find y Zap Dups (EXP-014/015) y ventana Patch Names (EXP-013), con
  Tab y flechas al editar (P10). `swift test` 49/49.
- **Original** en Snow Leopard (Mac mini del usuario) para contrastar (EXP-009, EXP-012). Allí queda un `.middev`
  «Prueba / Prueba» del asistente del original (EXP-012), lo borra el usuario cuando quiera.
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` («CP Canales»,
  EXP-011; «CP Patches», EXP-013; «CP Zap» con «Prueba zap», «… sin zap» y «… orden», EXP-015). Deshacer: borrar esa carpeta.
- Base: MidnamKit sin pérdidas y validación DTD (fase 1); cómo lee DP los `.midnam` (fase 2); estados en
  `protocol/PROTOCOL_INDEX.md`.

## EN PROGRESO

- T-020 (ficha abajo).

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-020 | A | EN PROGRESO | Pestaña Device: modos y Channel Sets | T-016 | Ficha T-020 |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

**T-020 — Pestaña Device** (docs/20 §3.1 y §3.3; manual «Modes» y «Channel Sets»; captura del original
`reference/capturas_snow_leopard/12.tiff`).
- Lógica en `CherryPickerCore/DeviceEditing.swift` con 8 tests (57/57): leer fabricante/modelo, modos y Channel Sets
  por modo; Active Channels («1-7, 9, 11-16»), canales libres, + / − y renombrar modos y Channel Sets (nombres
  únicos), Reassign Banks To; P13 (Channel Set nuevo con banco vacío). Audition Ch se muestra (canal más bajo), sin
  guardar (acordado con el usuario).
- Interfaz: Manufacturer/Model, cajas Modes y Channel Sets con + / −, Active Channels, Audition Ch y el aviso «(Add
  disabled: No free channels in mode)»; hojas New Channel Set y Reassign Banks To.
- Sin comprobar: qué escribe el original para canales libres (aquí se omiten en `ChannelNameSetAssignments`) y si
  DP lo acepta.
- Probada a mano en la app (EXP-016). Falta: `captures/exp016/Prueba device.midnam` en DP (canales libres).
- Aceptación: tests verdes; probado a mano (EXP-016); fichero con dos Channel Sets editados abierto en DP.

## SIGUIENTE PASO EXACTO

1. **Abrir T-020 con el usuario:** proponerle una de estas (docs/20 §3): Copy... en la lista de presets, Import
   desde otros `.midnam`, una pestaña (Device, MIDI, Controllers, Categories) o el asistente New. Decidir también el
   Find de la lista de patches (filtrar, como ahora, o seleccionar, como el original; docs/20 §3.2).
2. Menor, con el usuario y DP abierto: T-014.
