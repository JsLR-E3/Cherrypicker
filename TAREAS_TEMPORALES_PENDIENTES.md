# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-23 · local (`main`) · T-023 COMPLETADA: asistente Device Setup probado en la app (EXP-020).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha** (diseño en `docs/20`, D-005/D-007; app AppKit en `src/CherryPickerApp`, D-006):
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`. Hechas y probadas en la app y en DP 11.36:
  pestaña Patch Banks (EXP-010/011) con Merge, Find, Zap Dups (EXP-014/015) e Import (EXP-019), pestaña Device (EXP-016), pestaña MIDI con audición (EXP-017/018) y ventana
  Patch Names (EXP-013), con Tab y flechas al editar (P10). `swift test` 69/69. Asistente Device Setup con File ▸ New (EXP-020). Claude ve la app con `tools/capturar_app.sh`.
- **Original** en Snow Leopard (Mac mini del usuario) para contrastar (EXP-009, EXP-012). Allí queda un `.middev`
  «Prueba / Prueba» del asistente del original (EXP-012), lo borra el usuario cuando quiera.
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` («CP Canales»,
  EXP-011; «CP Patches», EXP-013; «CP Zap» con «Prueba zap», «… sin zap» y «… orden», EXP-015; «Prueba device» en CP Canales, EXP-016; «Prueba sin middev», EXP-021). Deshacer: borrar esa carpeta.
- Base: MidnamKit sin pérdidas y validación DTD (fase 1); cómo lee DP los `.midnam` (fase 2); estados en
  `protocol/PROTOCOL_INDEX.md`.

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

1. **Abrir T-024 con el usuario:** «Instalar en DP…» (P3: copiar el `.midnam` y, opcional, crear la entrada del
   `.middev`, con confirmación; EXP-021: el `.middev` no es imprescindible, solo hace que el modelo salga en las listas), Copy... en la lista de presets, o las pestañas
   Controllers o Categories. Decidir también el Find de la lista
   de patches (filtrar o seleccionar, docs/20 §3.2) y si se quiere una nota de prueba opcional para módulos de sonido
   (ampliaría D-002).
2. Menor, con el usuario y DP abierto: T-014.
