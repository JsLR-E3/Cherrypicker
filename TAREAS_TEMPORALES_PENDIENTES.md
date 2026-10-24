# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-031: `DSP-128 Plus optimizado.midnam` generado (10 familias); instalado; falta probarlo en DP.

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
  Además, `MOTU/TC Electronic/M3000 optimizado.midnam` (EXP-030) y
  `MOTU/Digitech/DSP-128 Plus optimizado.midnam` (EXP-031, con `sudo`); deshacer: borrar esos ficheros. Los demás de esas
  carpetas son del usuario.
- **Copias de trabajo del usuario** en `reference/midnam_trabajo/` (privadas, no versionadas; no se borran ni se
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él), `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023) y `M3000 optimizado.midnam` (T-030) y `DSP-128 Plus optimizado.midnam` (T-031).
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
| T-031 | A | PENDIENTE-LOCAL | Optimizar el `.midnam` del DSP-128 Plus contra su manual (`reference/manuales/DSP-128 Plus/`) | — | Ver ficha. Aceptación: el usuario lo prueba en DP 11.36 con el aparato (EXP nuevo) |

## Fichas

- **T-031 (DSP-128 Plus):** sobre una copia, sin tocar `DSP-128 Plus.midnam` (la de EXP-029):
  `reference/midnam_trabajo/DSP-128 Plus optimizado.midnam`, VÁLIDO contra la DTD. El manual es un escaneo: texto
  sacado con OCR (Vision de macOS, sin instalar nada), nivel B con ruido de OCR. Fuentes: el aparato no tiene bancos;
  responde a Program Change 0–127 = P 1–128 en su canal (1 por defecto). Los 128 nombres del fichero coinciden en orden
  con «Comments» de Appendix B (desarrollados: «with» por «w/»). Cambios (decisión del usuario): bancos All Programs
  (1–128) + 10 familias de la referencia rápida (Large/Medium/Small Rooms, Gated, Reverse, Halls, Multi-tap Delays,
  Parametric EQ, Graphic EQ, Mute & Dry), sin Bank Select; 28 nombres (Parametriq → Parametric ×20, Barroque → Baroque,
  «Brite Lg Room» → «Bright Large Room», mayúsculas y dobles espacios). Comprobado con script: los 128 PC, un nombre por
  PC, canales sin cambios. Todos los presets del aparato son de fábrica (usuario).
  Instalado por el usuario con `sudo` en `MOTU/Digitech/` (carpeta de root; EXP-031, cómo deshacerlo allí).
  **Falta:** la prueba del usuario en DP con el aparato (EXP-031).

## SIGUIENTE PASO EXACTO

0. T-031: resultado de la prueba en DP (EXP-031). Después, otro `.midnam` como en T-030 (`docs/15` y EXP-030): LXP-15, LXP-15 II, PCM-81 o PCM-91, con sus manuales en `incoming/`
   (se archivan en `reference/manuales/<modelo>/`).
1. **Con el usuario, decidir el siguiente bloque:** preparar la app para compartir (D-007: nombre e icono propios,
   revisar textos cortos de los nibs con `grep -rn '"[A-Z][^"]\{20,\}"' src/CherryPickerApp/Sources/CherryPicker`,
   licencia) o Note Lists (fuera por ahora, docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
