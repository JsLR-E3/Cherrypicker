# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-20 · local · T-013 integrada en `main` (fast-forward); T-010: borrador de diseño en `docs/20`, esperando respuestas del usuario.

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

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

- **T-010:** borrador `docs/20_DISENO_APP.md` escrito (manual + inventario de los 26 nibs). Falta: respuestas del
  usuario a §7 (Note Lists, Categories/Import, audición, propuestas P1–P7), ajustar el documento y anotar D-NNN.

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-010 | A | EN PROGRESO | Fase 3: diseño de la app a partir de las ventanas de CherryPicker (nibs, manual, capturas) en `docs/2x` | — | Documento de diseño acordado con el usuario antes de programar (D-NNN en `docs/12`) |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

### T-010 · Diseño de la app (fase 3)
- **Objetivo:** documento de diseño de las ventanas y flujos de la app nueva, partiendo de la organización y los
  nombres de CherryPicker (regla 10 de `CLAUDE.md`), para acordarlo con el usuario antes de programar.
- **Evidencias/referencias:** 25 nibs en `reference/app_3.0/…/Resources`, manual
  `reference/web_alterspective/cherrypicker/docs/introC.html`, `CPXMLStrings.plist`/`CPXMLRead.plist`, EXP-001, EXP-006,
  D-001, D-002, `docs/14` (tabla de funciones).
- **Tener en cuenta (EXP-006):** lista y banco con el mismo nombre; *Master Names* = nombre de fichero; crear también
  el `.middev`; avisar de volver a elegir en *Master Names* tras guardar.
- **Aceptación:** `docs/2x_…` con ventanas, controles y flujos; mejoras sobre el original señaladas como propuestas;
  acuerdo del usuario anotado en `docs/12`.
- **Siguiente paso ejecutable:** inventario de los nibs (`plutil`/`strings | grep`, o el agente `analista-referencia`)
  y lectura del manual por secciones.

## SIGUIENTE PASO EXACTO

1. **T-010:** el usuario responde las preguntas de `docs/20_DISENO_APP.md` §7; ajustar el documento y registrar el
   acuerdo como D-005 en `docs/12`.
2. Menor, con el usuario y DP abierto: T-014.
