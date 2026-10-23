# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-22 · local (`main`) · T-018 COMPLETADA: ventana Patch Names probada en la app y en DP (EXP-013).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha** (diseño en `docs/20`, D-005/D-007; app AppKit en `src/CherryPickerApp`, D-006):
  `tools/empaquetar_app.sh` → `build/CherryPicker.app`; `swift test` 37/37. Hechas y probadas en la app y en DP 11.36:
  pestaña Patch Banks (EXP-010/011) y ventana Patch Names (EXP-013), con Tab y flechas al editar (P10).
- **Original** en Snow Leopard (Mac mini del usuario) para contrastar (EXP-009, EXP-012). Allí queda un `.middev`
  «Prueba / Prueba» del asistente del original (EXP-012), lo borra el usuario cuando quiera.
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` («CP Canales»,
  EXP-011; «CP Patches», EXP-013). Deshacer: borrar esa carpeta.
- Base: MidnamKit sin pérdidas y validación DTD (fase 1); cómo lee DP los `.midnam` (fase 2); estados en
  `protocol/PROTOCOL_INDEX.md`.

## EN PROGRESO

- T-019 (ficha abajo).

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-019 | A | EN PROGRESO | Patch Banks: Merge, Find (ventana Finder) y Zap Dups | T-016, T-018 | Ficha T-019 |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

**T-019 — Merge / Find / Zap Dups** (docs/20 §3.1, §3.3 MergeSheet, §3.4 Finder; manual del original, «Banks Tab»
y «Custom Banks»).
- Lógica en `CherryPickerCore/BankTools.swift` con tests: `findPatches` (nombre contiene el texto, sin distinguir
  mayúsculas, en todos los bancos), `addBank(…withPatches:)` (banco nuevo con copias; cada patch sigue sonando con su
  bank select), `mergeBanks` (banco nuevo con los patches de los seleccionados en el orden de la tabla; borra los
  originales salvo Option-Add), `duplicatePatches` / `zapDuplicates`.
- Zap Dups (deducido, el manual no define «duplicado»): en cada Channel Set, se borran de los bancos con bank select
  los patches cuyo bank select efectivo + Program Change ya está en un banco sin bank select (Custom). A contrastar con
  el original en el Mac mini.
- Interfaz: botones Merge (con ≥ 2 bancos), Find y Zap Dups en Patch Banks; hoja «Name for Merged Bank»; ventana
  Finder con campo de búsqueda, «Add New Bank With Patches», «Remove Duplicates», − y arrastre a una lista.
- Aceptación: tests verdes; probado a mano en la app (EXP-014) y un fichero con Custom Bank zapeado abierto en DP.

## SIGUIENTE PASO EXACTO

1. **Abrir T-019 con el usuario:** leer `docs/20` §3.1–3.2 y §7 y proponerle una de estas: Merge / Find / Zap Dups
   en Patch Banks (ayudan a montar Custom Banks), Copy... en la lista de presets, una pestaña (Device, MIDI,
   Controllers, Categories) o el asistente New. Con la elegida, ficha en «Fichas» y empezar por la lógica con tests en
   `CherryPickerCore`.
2. Menor, con el usuario y DP abierto: T-014.
