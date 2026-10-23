# Cherrypicker — instrucciones para Claude

<!-- Este fichero se carga en cada sesión: solo reglas y punteros. Los procedimientos van en .claude/skills/,
     el detalle en docs/. Los comentarios HTML como este no gastan contexto. -->

Proyecto para recuperar en macOS actual el programa descontinuado **CherryPicker** (Alterspective), editor de ficheros
`.midnam` (nombres de bancos, presets y controles de módulos MIDI) para usarlos en **Digital Performer 11.36**.
**Proyecto de programa, no de aparato:** se investigan sus **formatos de fichero** y cómo los lee DP, no un protocolo de
hardware. Objetivo y fases: `docs/14_ROADMAP.md` (alcance en D-001). **El repositorio es la memoria del proyecto:** lo
que no esté commiteado y subido no existe para la sesión siguiente (la memoria automática de Claude es local de cada
máquina y no viaja entre el Mac y la nube).

## Sesión

- **Empezar:** `/inicio` (o «ponme al día»). **Terminar:** `/cierre`. Estado y tareas: `TAREAS_TEMPORALES_PENDIENTES.md`.
- **Qué leer para cada tarea:** tabla de `docs/00_MASTER_INDEX.md`. No explorar todo el proyecto ni releer conversaciones.
- **Si el contexto se acaba:** parar, anotar en TAREAS `EN PROGRESO` con lo hecho y el siguiente paso exacto, commit, y
  no empezar nada nuevo.
- No sobrescribir un fichero entero sin comprobar antes su versión actual en el repositorio.

## Reglas que no se negocian

1. **Observar → comprobar → documentar → implementar.** Nada es CONFIRMED por conjetura ni «porque funciona»
   (niveles de evidencia en `docs/11_METODO_INGENIERIA_INVERSA.md`; estados en `protocol/PROTOCOL_INDEX.md`).
2. **Ficheros del usuario:** solo lectura. Los `.midnam` de `reference/midnam_usuario/` son **privados** (D-004): nunca
   se sobrescriben (se trabaja sobre copias en el scratchpad o `captures/`), ni se versionan ni se publican; las capturas
   guardan estructura y recuentos, no su contenido, y para tests en el repo se usan copias anonimizadas o ficheros
   propios, previa consulta.
3. **Nada se instala ni se copia en las carpetas de DP** (`/Library/Audio/MIDI Devices/…`) **ni del sistema** sin permiso
   del usuario, anotando cómo deshacerlo. **Privacidad** (usuario): pedir permiso antes de leer o escribir fuera de la
   carpeta del proyecto.
4. **MIDI a módulos reales** (audición, D-002): solo Bank Select (CC0/CC32) y Program Change, al destino que elija el
   usuario y con su permiso. **Nunca** SysEx, volcados ni mensajes que cambien la memoria del módulo.
5. Cada prueba (con la app original, con DP o con un módulo) se registra en `docs/13_REGISTRO_DE_EXPERIMENTOS.md`
   (EXP-NNN, con su entorno), también si falla.
6. `reference/` e `incoming/` no se versionan (material de terceros). **Nunca `git add -A` ni `git add .`:** se añade
   por ruta.
7. **Git.** En el Mac, Claude hace commit en la rama actual y el `fetch` y el `push` los hace el usuario (frase de
   paso SSH). En la nube, la sesión trabaja solo en su rama `claude/…` y hace commit y push de esa rama antes de
   terminar (el contenedor se borra); nunca en `main`. En ningún lado merge sin que lo pida el usuario, rebase de ramas
   ajenas ni `push --force`. Protocolo: `docs/10_TRABAJO_CON_CLAUDE.md` §2.
8. **Lo que necesita el Mac, Xcode, DP 11.36, un módulo o MIDI y no se ha ejecutado de verdad** queda
   `PENDIENTE-LOCAL`, nunca `COMPLETADA`. No se afirma ninguna prueba que no se haya ejecutado; se anota el comando y el
   resultado real.
9. Instalar o descargar software requiere permiso del usuario. Nada de secretos (tokens, claves, contraseñas) en el
   repositorio ni en los documentos.
10. **El software original es la base de la interfaz:** se reproduce la organización y los nombres de CherryPicker
    (nibs, manual, capturas). Mejorarlo o añadir funciones es bienvenido (D-007): se propone, se acuerda con el
    usuario y se marca [PROPUESTA] en `docs/20`. **Copyright** (D-007): código propio, sin copiar binarios, nibs,
    iconos ni textos largos del original; nada de `reference/` se distribuye; antes de compartir la app, nombre e
    icono propios.
11. **CPU:** tras cada cambio relevante de lo que corre en segundo plano, medirla (`top`) y anotarla en el EXP.
12. **Sistema de prueba:** no actualizar macOS ni DP 11.36 sin comprobar antes que el flujo sigue funcionando. La app
    original (ppc/i386) no arranca en este Mac (EXP-001); no se instalan Rosetta, emuladores ni VMs sin permiso.
13. **DOCTYPE** de los ficheros nuevos: el de la 1.0 con la URL de midi.org; los ficheros abiertos conservan el suyo
    (D-003).

## Compilar y probar

- **App** (AppKit, D-006): `cd src/CherryPickerApp && swift test`; `tools/empaquetar_app.sh` monta
  `build/CherryPicker.app` (no versionado).
- **MidnamKit** (lectura/escritura de `.midnam`): `cd src/MidnamKit && swift test` (12 tests: ida y vuelta byte a byte
  de los ejemplos y validación contra la DTD de lo que escribe).
- **Validar un `.midnam` contra la DTD 1.0:** `tools/validar_midnam.sh fichero.midnam…` (sin red; necesita
  `reference/dtd/MIDINameDocument10.dtd` y `MIDIEvents10.dtd`).
- **Ver la app sin pedir capturas al usuario:** `tools/capturar_app.sh [carpeta]` guarda en PNG solo las ventanas de
  CherryPicker (nunca el resto de la pantalla; permiso del usuario, 2026-10-23). Claude no puede hacer clic: el usuario
  maneja la app y Claude mira.
- Comprobación de la documentación y del repositorio: `.claude/scripts/comprobar.py`.

## Economía de contexto

- **Antes de investigar, buscar si ya está hecho:** `grep` del tema en `docs/13`, `protocol/` y `docs/12_DECISIONES.md`.
  Un resultado registrado vale mientras su entorno (macOS, versión de DP, commit) no cambie; si cambió, se repite la
  prueba.
- Búsquedas concretas (Grep/Glob) y lectura de fragmentos. No releer lo que ya se leyó en la sesión y no ha cambiado.
- **Capturas, volcados, binarios, nibs y `reference/` nunca enteros:** `head`, `grep`, `strings | grep`,
  `plutil -p … | head`, `wc`. Un análisis largo de material de referencia se delega en el agente `analista-referencia`.
- Salidas largas filtradas sin ocultar errores ni el código de salida (`… 2>&1 | tail -40; echo "exit=${PIPESTATUS[0]}"`).
  Primero la prueba concreta, después la batería completa.
- Lo determinista (estado de git, IDs libres, enlaces) lo resuelven los scripts de `.claude/scripts/`, no el razonamiento.

Documentación y commits en español.
