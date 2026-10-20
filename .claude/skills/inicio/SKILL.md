---
name: inicio
description: "Puesta al día al empezar una sesión (local o en la nube): estado de git y ramas, tareas, siguiente paso y contexto mínimo para la tarea. Usar al empezar o cuando el usuario pida ponerse al día."
argument-hint: "[tarea o T-NNN opcional]"
allowed-tools:
  - "Bash(.claude/scripts/estado.sh*)"
  - "Bash(git status*)"
  - "Bash(git log*)"
  - "Bash(git diff*)"
  - "Bash(git branch*)"
  - "Read"
  - "Grep"
  - "Glob"
---

# Inicio de sesión

Objetivo: dejar claro qué se hace en esta sesión leyendo lo mínimo. Tarea pedida por el usuario: $ARGUMENTS

1. **Estado real.** Si la salida de `estado.sh` ya está en el contexto (hook de inicio) y no ha pasado nada desde
   entonces, úsala; si no, ejecuta `.claude/scripts/estado.sh`. No repitas a mano los comandos de git que ya resume.
2. **Resolver avisos antes de nada** (no se arreglan solos y no se descartan sin preguntar):
   - Cambios sin commit o stash: averiguar de qué son (`git diff --stat`); si no son de esta sesión, preguntar.
   - Rama por detrás de su upstream: en la nube, `git pull --ff-only`; en el Mac, pedir al usuario el `git pull`.
   - Ramas `claude/…` sin integrar en `main`: decírselo al usuario con lo que traen (`git log --oneline main..<rama>`) y
     el procedimiento de `docs/10_TRABAJO_CON_CLAUDE.md` §2.3. Si se trabaja sin integrarlas, el usuario decide la base.
   - Buzón con mensaje sin responder (solo en el Mac): leer ese mensaje de `docs/remoto/PARA_LOCAL.md`, no el fichero entero.
3. **Leer `TAREAS_TEMPORALES_PENDIENTES.md`** (está pensado para una lectura). No leer `docs/15_HISTORIAL.md` ni el
   registro de experimentos enteros.
4. **Elegir la tarea**, por este orden: la que pida el usuario → `EN PROGRESO` → `SIGUIENTE PASO EXACTO` → la de mayor
   prioridad con dependencias cumplidas **que se pueda hacer en este entorno** (en la nube, nada que necesite el Mac,
   Xcode, DP 11.36, un módulo o MIDI; sí lo preparatorio: código, herramientas, análisis, procedimientos de prueba).
5. **Contexto de la tarea:** la fila de la tabla «Qué leer según la tarea» de `docs/00_MASTER_INDEX.md` y la ficha de la
   tarea. Antes de investigar algo, `grep` del tema en `docs/13`, `docs/12`, `protocol/`: si ya está resuelto y su entorno
   no ha cambiado, se usa. Del código, solo lo afectado (Grep y fragmentos).
6. **Resumen breve** (≤ 15 líneas, sin repetir la documentación):

   ```
   Estado: …                         (1–2 líneas; avisos de git si los hay)
   Entorno: local | nube (modo secuencial/paralelo) · rama …
   Objetivo de la sesión: T-NNN …
   Leído: …                          (solo lo consultado)
   Archivos probablemente afectados: …
   Criterios de aceptación: …
   Pruebas: aquí … · pendientes de validación local: …
   Bloqueos o dudas: …
   Tipo de tarea: mecánica | habitual | investigación | arquitectura → modelo/esfuerzo sugerido (docs/10 §3)
   ```

Si el usuario solo pidió ponerse al día, termina con el resumen y espera. Si pidió una tarea, continúa con ella.
