---
name: cierre
description: "Cierre de sesión o de tarea: registrar solo lo nuevo, actualizar TAREAS (implementado, verificado, pendiente local), comprobar, commit y push según el entorno. Usar al terminar una tarea o la sesión, o cuando el contexto se acabe."
allowed-tools:
  - "Bash(.claude/scripts/estado.sh*)"
  - "Bash(.claude/scripts/comprobar.py*)"
  - "Bash(git status*)"
  - "Bash(git diff*)"
  - "Bash(git log*)"
  - "Bash(git add *)"
  - "Bash(git commit *)"
  - "Read"
  - "Grep"
  - "Glob"
  - "Edit"
---

# Cierre de sesión

Objetivo: que una sesión nueva pueda seguir sin esta conversación. Registrar solo lo nuevo; no resumir la historia.

1. **Revisar lo hecho:** `git status`, `git diff --stat` y el `git diff` de lo propio. Buscar errores, ficheros que no
   deberían ir (`reference/`, `incoming/`, binarios, capturas enormes) y secretos.
2. **Clasificar cada cosa hecha** (sin adornar):
   - **Verificada:** se ejecutó la prueba; anotar comando y resultado real.
   - **Implementada sin verificar:** falta una prueba que sí se puede hacer aquí → estado `IMPLEMENTADA`.
   - **Pendiente de validación local:** necesita el Mac, Xcode, DP 11.36, un módulo o MIDI y no se ha ejecutado →
     `PENDIENTE-LOCAL` y fila en «PENDIENTE DE VALIDACIÓN LOCAL» con qué probar, cómo y en qué rama/commit.
   Nunca se marca `COMPLETADA` algo no verificado.
3. **Documentar solo lo nuevo, cada cosa en su sitio** (tabla de `docs/00_MASTER_INDEX.md`): prueba → EXP en `docs/13`
   con su entorno; cambio de lo que se sabe → `protocol/PROTOCOL_INDEX.md`; decisión → D-NNN en `docs/12` con su motivo;
   cambio visible para el usuario → `docs/30`. Citar por ID en vez de copiar. Si algo quedó obsoleto, marcarlo
   («Sustituido por …») en vez de borrarlo; si estaba duplicado, dejar una sola copia.
4. **Actualizar `TAREAS_TEMPORALES_PENDIENTES.md`:**
   - Línea «Actualizado»: fecha · local o nube (rama) · qué se hizo en una frase.
   - ESTADO ACTUAL: **reescribirlo** (≤ 10 líneas), no añadir debajo.
   - Estados de las tareas; las `COMPLETADA` salen de la tabla a `docs/15_HISTORIAL.md` (una línea, arriba, con cómo se
     verificó y commit/EXP). Tareas nuevas con el ID que da `estado.sh`.
   - EN PROGRESO: lo hecho y lo que falta, si algo queda a medias.
   - SIGUIENTE PASO EXACTO: algo ejecutable (comando, fichero, prueba), no «seguir con T-NNN».
5. **Comprobar:** `.claude/scripts/comprobar.py`; corregir los errores (los avisos, si son de esta sesión).
6. **Commit** por rutas (nunca `git add -A` ni `git add .`), mensaje en español con qué y por qué, citando T-/EXP-/D-.
7. **Subir según el entorno** (`docs/10_TRABAJO_CON_CLAUDE.md` §2):
   - **Mac:** no hacer push; decir al usuario que lo haga (y si hay ramas que integrar).
   - **Nube:** `git push -u origin <rama actual>` (nunca `main`, nunca `--force`); en modo paralelo, además, mensaje en
     `docs/remoto/PARA_LOCAL.md`. Sin push el trabajo se pierde al borrarse el contenedor.
8. **Informe final** (≤ 12 líneas): hecho y verificado (con la prueba) · implementado sin verificar · pendiente de
   validación local · decisiones pendientes del usuario · siguiente paso · commit y rama (y si falta el push).
