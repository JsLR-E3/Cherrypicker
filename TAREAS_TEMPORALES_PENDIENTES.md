# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-20 · local · T-013 integrada en `main` (fast-forward); T-016 completada (bancos editables; DP lo lee, EXP-011). Siguiente: T-018, lista de patches.

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha:** diseño acordado (`docs/20`, D-005, mejoras y copyright D-007); app AppKit en
  `src/CherryPickerApp` (D-006) con la pestaña Patch Banks editable; DP lee lo que guarda (EXP-011). App original
  disponible en Snow Leopard para contrastar (EXP-009). Compilar: `tools/empaquetar_app.sh`.
- **Fase 1 hecha** (`docs/14`): `src/MidnamKit` lee y reescribe `.midnam` sin pérdidas y valida contra la DTD 1.0
  (`swift test`, 12 tests). Alcance en D-001; audición D-002; DOCTYPE D-003; ficheros del usuario privados D-004.
- La app original 3.0 no arranca en este Mac (ppc/i386, EXP-001); hay 25 nibs, el manual web y los `.plist` de recursos
  en `reference/` para reproducir su interfaz.
- **Cómo lee DP 11.36 los `.midnam`** (EXP-002, EXP-006): de `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`;
  *Master Names* = nombre de fichero; menú de presets = nombre de la `PatchNameList` + «Number Name» (lista y banco con
  el mismo nombre); un modelo nuevo necesita `.middev`; DP no recarga solo: volver a elegir en *Master Names*. Los
  controles con nombre no salen en el menú de controladores de la pista. Estados en `protocol/PROTOCOL_INDEX.md`.
- Proyecto migrado a la plantilla nueva de Claude Code (T-013), integrado en `main` y subido; rama borrada (2026-10-20).

## EN PROGRESO

- Nada.

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-018 | A | PENDIENTE | Fase 3: ventana «Patch Names» (botón P): tabla B0 · B32 · # · Patch Name · Ascii editable, + / −, Renumber, pegar lista con delimitador (hoja New Patches), arrastrar entre listas, Find | — | Tests de la lógica; contraste con el original en Snow Leopard donde haya dudas; prueba a mano |
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
- **Siguiente paso ejecutable:** operaciones de patches en CherryPickerCore con tests.

## SIGUIENTE PASO EXACTO

1. **T-018:** ventana Patch Names (ficha arriba).
2. Usuario: decidir si se retira ya la instalación de EXP-011 (`/Library/Audio/MIDI Devices/MOTU/Cherrypicker/`).
3. Menor, con el usuario y DP abierto: T-014.
