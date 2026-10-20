# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-20 · local · T-013 integrada en `main` (fast-forward); T-010 completada (diseño acordado, D-005); siguiente T-015.

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

- Nada.

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| T-015 | A | PENDIENTE | Fase 3: tecnología de la app (SwiftUI/AppKit, versión mínima de macOS) en `docs/16` y esqueleto con la ventana de documento | — | Decisión acordada (D-NNN); proyecto que compila, abre un `.midnam` con MidnamKit y muestra la pestaña Patch Banks |
| T-014 | C | PENDIENTE | Mirar con el usuario si «Other Controller…» de DP usa la `ControlNameList` | DP abierto (usuario) | EXP registrado; fila `ControlNameList` de `PROTOCOL_INDEX` actualizada |

## Fichas

### T-015 · Tecnología y esqueleto de la app (fase 3)
- **Objetivo:** decidir con el usuario la tecnología (SwiftUI con tablas AppKit donde haga falta arrastrar y editar
  celdas) y la versión mínima de macOS; documentarlo en `docs/16`; crear el proyecto de la app sobre MidnamKit.
- **Referencias:** `docs/20_DISENO_APP.md` (ventanas, flujos, P1–P7), D-005, `docs/16`, `src/MidnamKit`.
- **Aceptación:** D-NNN en `docs/12`; la app compila, abre un `.midnam` de ejemplo y muestra la tabla de bancos
  (`P`, `S0`, `S32`, `Patch Bank`, `#`, `Channel Set`). Lo que necesite Xcode y no se haya ejecutado, PENDIENTE-LOCAL.
- **Siguiente paso ejecutable:** proponer al usuario las opciones de tecnología con sus pros y contras.

## SIGUIENTE PASO EXACTO

1. **T-015:** proponer al usuario la tecnología de la app (ficha arriba) y, una vez acordada, crear el esqueleto.
2. Menor, con el usuario y DP abierto: T-014.
