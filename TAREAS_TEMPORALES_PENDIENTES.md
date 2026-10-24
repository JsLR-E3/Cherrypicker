# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-029 completada: uso con los `.midnam` reales, arreglos de interfaz y P21 (EXP-029).

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
- **Copias de trabajo del usuario** en `reference/midnam_trabajo/` (privadas, no versionadas; no se borran ni se
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él) y `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023).
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

0. El usuario sigue optimizando sus `.midnam` en otro chat sobre `reference/midnam_trabajo/`: al empezar, preguntarle
   si de ahí salió algo para la app (fallos o funciones) y anotarlo como tarea.
1. **Con el usuario, decidir el siguiente bloque:** preparar la app para compartir (D-007: nombre e icono propios,
   revisar textos cortos de los nibs con `grep -rn '"[A-Z][^"]\{20,\}"' src/CherryPickerApp/Sources/CherryPicker`,
   licencia) o Note Lists (fuera por ahora, docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
