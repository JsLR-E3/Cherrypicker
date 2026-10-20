# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-20 · local · T-013 integrada en `main` (fast-forward); T-017 hecha: Bank Selects reproduce el original byte a byte (EXP-009); siguiente: disposición de la ventana según las capturas.

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fase 3 en marcha:** diseño acordado (`docs/20`, D-005); app AppKit en `src/CherryPickerApp` (D-006) que abre un
  `.midnam` y muestra la tabla de bancos (EXP-007). Compilar: `tools/empaquetar_app.sh`.
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
| T-016 | A | IMPLEMENTADA | Fase 3: pestaña Patch Banks editable (nombre, S0/S32 con la hoja Bank Selects, Channel Set, + / −, reordenar, deshacer) y Save | — | Se edita y se guarda un fichero de prueba; lo guardado valida contra la DTD y DP lo lee (EXP) |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

### T-016 · Patch Banks editable (fase 3)
- **Objetivo:** editar bancos como en el original (docs/20 §3.1 y §3.3): doble clic en nombre (único) y S0/S32,
  hoja Bank Selects, popup de Channel Set (y cambio múltiple por cabecera), + (hoja Add a Single Bank) / −, arrastrar
  para reordenar dentro del Channel Set, deshacer; guardar.
- **Referencias:** `docs/20` §3, D-005, D-006, `src/CherryPickerApp`, EXP-007; nibs BankSheet y BankSelectSheet.
- **Aceptación:** tests de la lógica en CherryPickerCore; prueba con un fichero propio (nunca uno del usuario sin
  copia): editar, guardar, `tools/validar_midnam.sh` sin errores; comprobación en DP, PENDIENTE-LOCAL con el usuario.
- **Hecho (2026-10-20):** `CherryPickerCore/BankEditing.swift` (renombrar con su lista, Bank Selects, añadir, borrar,
  mover de Channel Set, reordenar; restricciones de la DTD) con 15 tests, uno de ellos valida contra la DTD lo editado;
  interfaz: nombre editable, doble clic en S0/S32 → hoja Bank Selects, popup Channel Set, + (Add a Single Bank) / −,
  arrastrar, deshacer (copia del modelo por edición). Compila; la app abre y muestra la pestaña.
- **Prueba interactiva (EXP-008):** todo funciona tras dos arreglos (e738d6d).
- **Guardado:** válido contra la DTD y solo con los cambios hechos (EXP-008).
- **Falta:** ver en DP (PENDIENTE-LOCAL); cambio múltiple por cabecera
  (hojas Bank Selects y Channel Set con varios bancos); disposición de la ventana y las hojas según las capturas
  (EXP-009): botones encima de la tabla, leyenda de colores, Preview arriba.

## SIGUIENTE PASO EXACTO

1. **T-016:** disposición según las capturas (EXP-009: botones encima de la tabla, leyenda de colores, Preview arriba,
   hojas); cambio múltiple por cabecera (hojas Bank Selects y Channel Set con varios bancos seleccionados) y
   un fichero de prueba con varios Channel Sets para el popup; después, ver en DP con el usuario.
2. Menor, con el usuario y DP abierto: T-014.
