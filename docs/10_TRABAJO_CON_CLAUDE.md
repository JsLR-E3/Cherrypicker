# 10 — TRABAJO CON CLAUDE CODE

Cómo se trabaja con Claude en este proyecto para gastar el contexto y el uso del plan en lo que importa. Se consulta por
secciones (lo indica `docs/00_MASTER_INDEX.md`); no hace falta leerlo al empezar cada sesión.
Funciones de Claude Code comprobadas en su documentación oficial (code.claude.com/docs) en 2026-10; los nombres de
modelos, comandos y límites cambian con las versiones: si algo no coincide, manda la documentación vigente.

## 1. Qué se carga y cuándo

| Qué | Cuándo entra en el contexto | Tamaño previsto |
|---|---|---|
| `CLAUDE.md` (reglas y punteros) | Siempre, al empezar | ~60 líneas |
| Descripciones de las skills `/inicio` y `/cierre` y del agente | Siempre (solo la descripción) | 3 líneas |
| Salida de `.claude/scripts/estado.sh` (hook `SessionStart`) | Al empezar una sesión o tras `/clear` | ~20–30 líneas |
| `TAREAS_TEMPORALES_PENDIENTES.md` | Lo lee `/inicio` | < 150 líneas |
| Cuerpo de una skill | Solo al invocarla | ~40 líneas |
| Resto de `docs/`, `protocol/`, código | Solo lo que pida la tarea (tabla de `00`) | — |
| `reference/`, `captures/` | Nunca enteros; fragmentos o agente `analista-referencia` | — |

El hook es opcional: si se prefiere, se borra de `.claude/settings.json` y `/inicio` ejecuta el script él mismo.

## 2. Local (Mac) ↔ nube

**Principio:** GitHub es el único punto de intercambio. Una sesión en la nube clona el repositorio de GitHub: no ve los
cambios sin commit ni sin push del Mac, ni aplicaciones abiertas, ni Xcode, ni DP 11.36, ni los módulos, ni puertos MIDI. Y su
contenedor se borra: lo que no suba a su rama se pierde.

### 2.1 Al dejar el Mac (antes de abrir una sesión en la nube)

1. `/cierre` en la sesión local (deja TAREAS al día y hace commit).
2. El usuario hace `git push`. Comprobar: `git status` limpio y `git log origin/main..main` vacío.
3. Lo que haya quedado sin subir a propósito se anota en TAREAS («en el Mac sin subir: …») para que la nube no lo rehaga.

### 2.2 En la nube

Hay dos modos; la sesión dice cuál usa en su resumen de inicio.

| | **Secuencial** (lo normal: el Mac está parado) | **Paralelo** (el Mac sigue trabajando) |
|---|---|---|
| Rama | La suya, `claude/…`, desde `main` actualizado | La suya, `claude/remoto-…` |
| Qué puede cambiar | Código, documentos y TAREAS | Solo ficheros **nuevos** en `docs/remoto/` y el buzón `PARA_LOCAL.md` |
| Pruebas con Mac/DP/Xcode/MIDI | No se hacen: van a «PENDIENTE DE VALIDACIÓN LOCAL» | Se proponen en el buzón |
| Al terminar | `/cierre`: commit y `git push -u origin <rama>` | Igual, y mensaje en `PARA_LOCAL.md` |

En la nube, siempre: nunca commit en `main`, nunca merge (salvo que el usuario lo pida expresamente), nunca
`push --force`. Si al
empezar hay otra rama `claude/…` sin integrar en `main` con trabajo de una sesión anterior, se avisa al usuario antes de
trabajar: o se integra primero, o la sesión parte de esa rama (lo decide el usuario), para no bifurcar el estado.

### 2.3 De vuelta en el Mac

`estado.sh` (al iniciar) avisa de las ramas `claude/…` sin integrar según el último `fetch`. El usuario hace el fetch;
después:

```
git fetch origin
git log --oneline main..origin/<rama>            # qué trae
git diff --stat main...origin/<rama>             # qué ficheros toca (modo paralelo: solo docs/remoto/)
git merge --no-ff origin/<rama>                  # estando en main y con el árbol limpio
```

O bien se fusiona su pull request en GitHub y se hace `git pull`. Después se ejecuta lo que esté en «PENDIENTE DE
VALIDACIÓN LOCAL», se registra cada prueba como EXP y la tarea pasa a COMPLETADA (o vuelve a EN PROGRESO si falla).

Para seguir en el terminal una sesión de la nube: `claude --teleport` (exige árbol limpio; el fetch que hace no puede
pedir la frase SSH, así que hay que tener la clave cargada en `ssh-agent`).

### 2.4 Conflictos y pérdidas de trabajo

- Cambios sin commit que no son de esta sesión: no se descartan ni se sobrescriben; se pregunta al usuario.
- Nada de `git reset --hard`, `git checkout -- .`, `git clean`, `stash` sin anotar ni `push --force`.
- Conflicto en TAREAS: se resuelve tarea por tarea conservando el estado más reciente de cada una; nunca aceptando un
  lado entero a ciegas. Conflicto en código: se pregunta si los dos lados cambian la misma lógica.
- Buzones de `docs/remoto/`: cada lado escribe solo en el suyo, así que no chocan.
- Secretos: nunca en el repositorio. Los de la nube se configuran en el entorno de Claude Code, no en ficheros.

## 3. Modelo y esfuerzo según la tarea

Se optimiza el **consumo por tarea terminada**, no por mensaje: un modelo barato que necesita tres intentos sale más
caro que uno capaz que acierta a la primera. Se cambia con `/model <alias>` y `/effort <nivel>` (`low`, `medium`,
`high`, `xhigh`, `max`, según el modelo). Los nombres y precios cambian: ver `/model` en cada momento.

| Tipo | Ejemplos | Modelo | Esfuerzo | Forma de trabajo |
|---|---|---|---|---|
| Mecánica | Actualizar tablas, renombrar, formato, mover tareas al historial, commit | El más económico disponible que sea fiable | `low` | Sin planificar ni subagentes; los scripts hacen lo determinista |
| Habitual | Implementar con especificación clara, utilidad de prueba, corrección localizada | Intermedio (el predeterminado) | `medium` | Leer la ficha y el código afectado; prueba concreta |
| Investigación compleja | Protocolo desconocido, análisis de binarios, comparar fuentes | Intermedio o el más capaz | `high` | Modo plan; volcados al agente `analista-referencia`; EXP antes de probar |
| Arquitectura o depuración difícil | Fallos intermitentes, concurrencia, drivers del sistema, rendimiento | El más capaz | `high`–`xhigh` | Modo plan; hipótesis escritas; decisiones en `12` |

Criterios:
- **Subir** de nivel tras dos intentos fallidos con la misma hipótesis, en vez de un tercero a ciegas.
- **Bajar** cuando el plan está aprobado y lo que queda es ejecución mecánica.
- Subagentes solo para lecturas voluminosas o investigaciones independientes; no para tareas pequeñas ni para dos
  cosas que tocan los mismos ficheros.
- Tareas no relacionadas: sesión nueva (o `/clear` en local) en vez de arrastrar contexto.

## 4. Herramientas y resultados

- Búsquedas concretas (Grep/Glob con patrón y ruta) en vez de listar o leer carpetas enteras.
- Leer el fragmento pertinente (rango de líneas) cuando basta; no volver a leer lo que no ha cambiado.
- Salidas de compilación y pruebas filtradas, conservando errores y código de salida:
  `make 2>&1 | grep -E 'error|warning' | head -40; echo "exit=${PIPESTATUS[0]}"`.
- Primero la prueba concreta del cambio; la batería completa, al final.
- Los resultados se resumen (qué falló, dónde); no se pegan ficheros ni salidas enteras en los documentos.
- Lo repetitivo se convierte en script de `tools/` o `.claude/scripts/` en cuanto se hace por segunda vez.
- Antes de terminar: `git diff` revisado y `.claude/scripts/comprobar.py` sin errores.

## 5. No repetir trabajo

- **Antes de investigar:** `grep` del tema en `docs/13`, `docs/12`, `docs/15`, `protocol/` (y `protocol/discarded/`).
- **Validez:** un resultado vale mientras su entorno (macOS, firmware, commit, dependencias) siga igual. Si cambió, se
  repite la prueba y el EXP antiguo se marca «Sustituido por EXP-NNN»: no se borra (es historia) ni se reutiliza (está
  obsoleto).
- **Una sola copia de cada dato:** el detalle vive en su documento (EXP, D-, protocolo) y los demás lo citan por ID.
- Los cambios evidentes no se explican en largo: el commit dice qué y por qué; el diff dice el resto.

## 6. Medición del consumo

No se afirma ningún ahorro sin medirlo. Lo que hay disponible:

| Métrica | Cómo | Tipo |
|---|---|---|
| Tokens de entrada, salida y caché de la sesión | `/usage` (bloque *Session*) al terminar la tarea | Observada |
| Ocupación del contexto por partes | `/context` | Observada |
| Tokens, llamadas a herramientas, ficheros leídos y relecturas de una sesión | `python3 .claude/scripts/medir.py sesion --ultima` (lee el registro local de la sesión) | Observada (formato interno de Claude Code: puede cambiar) |
| Tamaño del contexto inicial fijo | `python3 .claude/scripts/medir.py contexto` | Estimación (caracteres / 4) |
| Iteraciones y repeticiones de investigaciones | Turnos del usuario (medir.py) y EXP repetidos sin cambio de entorno | Indirecta |
| Calidad | Pruebas superadas, tareas que vuelven de COMPLETADA a EN PROGRESO | Observada |

`medir.py` lee el registro de la máquina donde corre: en el Mac mide las sesiones del Mac; en la nube, la sesión en
curso. `/usage` en un plan de suscripción muestra además el reparto por skills y subagentes.

### Comparación antes/después

1. Elegir tres tareas representativas y repetibles sobre el mismo commit: una mecánica (p. ej. mover dos tareas al
   historial y actualizar el estado), una habitual (p. ej. una utilidad pequeña de `tools/`) y una investigación (p. ej.
   localizar en un binario de `reference/` la función que envía un mensaje).
2. Ejecutar cada una en una sesión nueva con el sistema anterior y con el nuevo (misma petición, mismo modelo y esfuerzo).
3. Anotar por sesión: tokens (entrada, salida, lectura y escritura de caché) de `/usage` o `medir.py`, contexto inicial
   de `/context`, ficheros leídos y releídos, llamadas a herramientas, turnos del usuario hasta terminar, si las pruebas
   pasan y si hizo falta corregir algo después.
4. Comparar por tarea terminada con buen resultado. Con una sola ejecución por caso la diferencia es indicativa, no
   concluyente: los modelos no son deterministas.

| Tarea | Sistema | Tokens entrada / salida / caché | Ficheros leídos (relecturas) | Turnos | Pruebas | Notas |
|---|---|---|---|---|---|---|
| — | antes | — | — | — | — | — |
| — | después | — | — | — | — | — |
