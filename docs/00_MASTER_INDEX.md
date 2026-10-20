# 00 — ÍNDICE MAESTRO

## Qué leer según la tarea

Leer **solo** la fila de la tarea, y de cada documento la parte pertinente (`grep` del tema o del ID antes que leerlo
entero). Si falta información, buscarla primero aquí y en `docs/13`, `protocol/` y `docs/12` antes de investigar.

| Tarea | Leer | Actualizar al terminar |
|---|---|---|
| Cualquiera (inicio) | `TAREAS_TEMPORALES_PENDIENTES.md` (lo hace `/inicio`) | TAREAS (lo hace `/cierre`) |
| Prueba con DP 11.36 o un módulo MIDI (solo en el Mac, con permiso) | `11` (flujo y reglas), fila del área en `../protocol/PROTOCOL_INDEX.md`, EXP citados (EXP-002, EXP-006 para DP) | `13`, `PROTOCOL_INDEX`, `../captures/` |
| Formato `.midnam` y cómo lo lee DP: qué se sabe y con qué certeza | `../protocol/PROTOCOL_INDEX.md` → `../protocol/<estado>/` del área (p. ej. `../protocol/confirmed/midnam_formato_escritura.md`) | `PROTOCOL_INDEX` |
| Analizar CherryPicker (nibs, recursos, manual) o diseñar su interfaz (T-010) | `01` (fuentes), `14` (funciones), `plantillas/ANALISIS_COMPONENTE.md`, D-001 | `2x_….md` nuevo, `PROTOCOL_INDEX`, `12` |
| Implementar o corregir código (`src/MidnamKit`, app) | Ficha de la tarea, `16` (componente afectado), código afectado; `swift test` | TAREAS, `16` si cambia la arquitectura, `30` si cambia lo que ve el usuario |
| Decidir alcance, fases o arquitectura | `14`, `16`, `12` | `12` (D-NNN), `14`/`16` |
| Auditoría | `plantillas/AUDITORIA.md`, auditoría anterior | `3x_AUDITORIA_AAAA-MM-DD.md` |
| Trabajo en la nube o integrar lo hecho allí | `10` §2, `remoto/00_INDICE.md` | TAREAS (PENDIENTE-LOCAL), buzones de `remoto/` |
| Elegir modelo y esfuerzo, medir consumo | `10` §3 y §6 | — |
| ¿Ya se probó / se decidió esto? | `grep` en `13`, `12`, `15`, `../protocol/discarded/` | — |

## Documentos

| Doc | Contenido |
|---|---|
| `01_HARDWARE_Y_FUENTES.md` | Equipos, entorno y material disponible |
| `10_TRABAJO_CON_CLAUDE.md` | Contexto, local ↔ nube, modelo y esfuerzo por tipo de tarea, herramientas, medición |
| `11_METODO_INGENIERIA_INVERSA.md` | Método y niveles de evidencia |
| `12_DECISIONES.md` | Decisiones vigentes y sustituidas (D-NNN) |
| `13_REGISTRO_DE_EXPERIMENTOS.md` | Experimentos (EXP-NNN) |
| `14_ROADMAP.md` | Alcance, fases, riesgos y viabilidad |
| `15_HISTORIAL.md` | Tareas cerradas, una línea cada una |
| `16_ARQUITECTURA.md` | Arquitectura de componentes |
| `20_DISENO_APP.md` | Diseño de la app a partir de CherryPicker: ventanas, flujos, propuestas e inventario de nibs (T-010, borrador) |
| `30_MANUAL_USUARIO.md` | Manual de usuario (borrador) |
| `plantillas/` | Formatos de documentos recurrentes (auditoría, análisis de un componente original) |
| `remoto/` | Buzones y propuestas de sesiones en paralelo fuera del Mac (índice en `remoto/00_INDICE.md`) |
| `../protocol/PROTOCOL_INDEX.md` | Índice canónico del formato `.midnam` y de cómo lo lee DP: hallazgos confirmados, observados, hipótesis, descartes |
| `../TAREAS_TEMPORALES_PENDIENTES.md` | Estado vivo y tareas |

Dónde va cada cosa: **hallazgo** → EXP + `PROTOCOL_INDEX` (con su estado) · **hipótesis o pregunta abierta** →
`protocol/hypotheses/` o la ficha de la tarea · **decisión** → `12` · **incidencia conocida** → tarea en TAREAS (y,
si afecta al usuario, `30` §3) · **procedimiento de prueba** → EXP (procedimiento) o `tools/` · **pendiente** → TAREAS.

Numeración: 00–09 índice y fuentes · 10–19 método, trabajo con Claude, decisiones, registro, roadmap, historial,
arquitectura · 20–29 análisis del software original (uno por componente) · 30–39 manual, auditorías fechadas y diseños
de fases grandes.

Carpetas: `protocol/{confirmed,observed,hypotheses,discarded}`, `captures/` (capturas propias), `tools/` (utilidades),
`src/`, `tests/`, `experiments/`, `design/`, `reference/` (terceros, no versionado), `incoming/` (bandeja, no versionada),
`.claude/` (skills `/inicio` y `/cierre`, agente, scripts y hook de inicio).
