# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-025 en curso: Categories, Find con «Select Matches» y nota de prueba (D-008); falta la prueba del usuario (EXP-024).

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
- **Idea para un proyecto futuro** (tras BCR2000 y Cherrypicker): `docs/40_IDEA_EDITOR_FX_BCR2000.md`. Fuera del
  alcance; al empezar ese proyecto se lleva a su repositorio como documento de partida.

## EN PROGRESO

- **T-025** (ficha abajo): código y tests hechos (79/79); falta la prueba del usuario en la app (EXP-024).

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-025 | A | EN PROGRESO | Pestaña Categories; Find con «Select Matches»; nota de prueba opcional (D-008) | — | Prueba del usuario en la app (EXP-024) y respuesta a P17 |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

**T-025 · Categories, Find y nota de prueba** (elegido por el usuario, 2026-10-24)
- Hecho: `CherryPickerCore/Categories.swift` (juegos GM y E-mu de serie, propios; `addCustomBanks`), pestaña
  `CategoriesViewController` (juegos propios en las preferencias, clave `userCategories`); Find con menú «Filter» /
  «Select Matches» (clave `patchFindSelects`); «Test Note» en la pestaña MIDI (`TestNote`, claves `testNoteOn.*` y
  `testNote.*`; 150 ms tras el Program Change). Docs: D-008, regla 4 de CLAUDE.md, docs/20 §3.1, §3.2, P15–P17.
- Probar con el usuario: (1) Categories: Dup de GM, editar la copia, + / −, Add To Banks con y sin selección y con
  nombres repetidos, elegir Channel Set; reabrir la app y ver que la copia sigue. (2) Find en los dos modos y arrastrar
  las coincidencias a otro banco. (3) Test Note con un módulo de sonido (con permiso y el destino que elija).
- Dudas para el usuario: P17 (comportamiento propio); la lista E-mu coincide con la del recurso del original y D-007
  pide rehacerla: decidir si se deja (nombres de categoría, datos) o se rehace desde la documentación de E-mu.
- Al terminar: docs/30 (manual de uso), docs/14 si cambia la fase, EXP-024 COMPLETADO.

## SIGUIENTE PASO EXACTO

1. **T-025:** prueba del usuario en la app (lista en la ficha) y registrar el resultado en EXP-024; resolver P17 y
   la lista E-mu.
2. Menor, con el usuario y DP abierto: T-014.
