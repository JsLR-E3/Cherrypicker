# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-22 · local (`main`) · T-018: ventana Patch Names hecha (compila, 36/36 tests); falta probarla a mano.

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha.** Diseño acordado en `docs/20` (D-005; mejoras y copyright D-007). App AppKit en
  `src/CherryPickerApp` (D-006): `tools/empaquetar_app.sh` → `build/CherryPicker.app`; `swift test` 37/37. Pestaña
  Patch Banks editable y guardar; DP 11.36 lee lo guardado y respeta los Channel Sets (EXP-011).
- **App original disponible** en Snow Leopard (Mac mini del usuario) para contrastar: la hoja Bank Selects se reproduce
  byte a byte (EXP-009); patches nuevos y pegados en EXP-012 (su casilla de bank select no se copia: P9). Ficheros del
  usuario por `incoming/` (los de EXP-012 ya archivados en `captures/exp012/` y `reference/capturas_snow_leopard/`).
- En el Mac mini, el asistente del original creó un `.middev` para «Prueba / Prueba» (EXP-012): lo borra el usuario
  cuando quiera.
- **Instalación de prueba que se deja a propósito** (usuario, 2026-10-20): `/Library/Audio/MIDI Devices/MOTU/
  Cherrypicker/` (`Prueba canales.midnam` + `.middev` de «CP Canales», EXP-011). Deshacer: borrar esa carpeta.
- Base: MidnamKit sin pérdidas y validación DTD (fase 1); cómo lee DP los `.midnam` (fase 2, EXP-002/006/011);
  estados en `protocol/PROTOCOL_INDEX.md`.

## EN PROGRESO

- **T-018:** lógica con 16 tests (`PatchEditing.swift`, ahora también ordenar por cabecera) y ventana AppKit
  `PatchWindowController.swift` + `PatchSheets.swift` (New Patches, Renumber Patches), abierta con el botón P.
  Compila y se empaqueta; **sin probar a mano** (nada de la interfaz se ha ejecutado aún).

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-018 | A | IMPLEMENTADA | Fase 3: ventana «Patch Names» (botón P): tabla B0 · B32 · # · Patch Name · Ascii editable, + / −, Renumber, pegar lista con delimitador (hoja New Patches), arrastrar entre listas, Find | — | Tests de la lógica; contraste con el original en Snow Leopard donde haya dudas; prueba a mano |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

### T-018 · Ventana Patch Names (fase 3)
- **Objetivo:** la lista de patches de un banco como en el original (nib PatchWindow, captura 5 de EXP-009): `B0`,
  `B32`, `#`, `Patch Name`, `Ascii` editables; + (hoja New Patches: Start At, Start Ascii, Quantity, «Set Bank Selects
  to Bank values», Patch Delimiter) / −; Renumber; pegar o soltar texto con delimitador; arrastrar dentro y entre
  listas; Find y Count. Sin Audition Riff (D-005) ni Copy... (más adelante).
- **Referencias:** `docs/20` §3.2–3.3, EXP-009 (forma de escribir el bank select por patch), `BankEditing.swift`.
- **Dudas para el original (Snow Leopard):** cómo numera al pegar; qué escribe un patch nuevo con y sin «Set Bank
  Selects to Bank values» en un banco con y sin bank select.
- **Hecho:** lógica con tests (`PatchEditing.swift`); dudas resueltas en EXP-012 y P9 (`docs/20`). Delimitador
  Quote: deducido (texto entre comillas), sin contrastar.
- **Ventana:** hecha (Find filtra por nombre, deducido; arrastrar a otra lista copia; pegar/soltar texto → New
  Patches). Fuera: Copy..., audición, arrastrar entre documentos, volcados GigaStudio/Cakewalk y «n=nombre».
- **Siguiente paso ejecutable:** prueba a mano con una copia de `captures/exp012/Prueba3.midnam` (EXP-013): editar
  celdas, +, pegar, −, Renumber, ordenar, Find, arrastrar dentro y a otro banco, ⌘Z; guardar, validar con
  `tools/validar_midnam.sh` y abrir en DP.

## SIGUIENTE PASO EXACTO

1. **T-018:** EXP-013 en curso: correcciones y P10 de la lista confirmadas; falta P10 en Patch Banks; después
   guardar, `tools/validar_midnam.sh` y abrir en DP.
2. Menor, con el usuario y DP abierto: T-014.
