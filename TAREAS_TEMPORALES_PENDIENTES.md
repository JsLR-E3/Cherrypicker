# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-030: `M3000 optimizado.midnam` generado y revisado contra el manual; falta que el usuario lo mire en el aparato y en DP.

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
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él), `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023) y `M3000 optimizado.midnam` (T-030).
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
| T-030 | A | PENDIENTE-LOCAL | Optimizar el `.midnam` del M3000 contra el manual, el addendum y la especificación MIDI (en `incoming/`) | — | Ver ficha. Aceptación: el usuario confirma en el aparato los nombres dudosos y en DP 11.36 que los bancos nuevos cambian bien de preset (EXP nuevo) |

## Fichas

- **T-030 (M3000):** hecho sobre una copia, sin tocar `M3000 prueba.midnam`: `reference/midnam_trabajo/M3000 optimizado.midnam`,
  válido contra la DTD. Comprobado con script (sin aparato): los 904 patches originales siguen en la misma dirección
  (Channel Set, CC0, CC32, PC), con la regla de la especificación MIDI de TC: programa = 128 × CC0 + PC (Single: fábrica 0–3,
  RAM 4–5, Card 6–7; Combined: fábrica 0, RAM 1, Snapshots 2, Card 3). Cambios: 40 nombres (erratas y mayúsculas, según
  el manual); bancos Halls Natural 21–63 (ya sin comandos por patch) / Super-natural 64–136, Outdoor Medium 410–415
  aparte, «Outdoot XXL» → «Outdoor XXL», Combined Music 1–50 / Film 51–95 / Surround 96–100, y Card 1, Card 2 y
  Combined Card nuevos (vacíos, como RAM). Se dejan CC32 y los nombres RAM vacíos (decisión del usuario). No se añaden
  ControlNameList, porque DP no los muestra (EXP-027).
  **Falta:** (1) que el usuario mire en la pantalla del M3000 los dudosos: 7, 13, 65, 80, 125, 128, 210, 249, 439, 453,
  492 (nombre distinto del manual) y 76, 148, 156, 164, 184, 201, 202, 204 (mayúsculas o espacios); (2) instalarlo en DP
  con su permiso y probar los bancos nuevos (EXP); (3) archivar los 3 PDF del M3000 de `incoming/` en `reference/`.

## SIGUIENTE PASO EXACTO

0. T-030: aplicar los nombres que el usuario lea en el M3000 (lista en la ficha) y probar en DP. Después, mismo
   proceso con DSP-128 Plus, LXP-15, LXP-15 II, PCM-81 o PCM-91, con sus manuales en `incoming/`.
1. **Con el usuario, decidir el siguiente bloque:** preparar la app para compartir (D-007: nombre e icono propios,
   revisar textos cortos de los nibs con `grep -rn '"[A-Z][^"]\{20,\}"' src/CherryPickerApp/Sources/CherryPicker`,
   licencia) o Note Lists (fuera por ahora, docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
