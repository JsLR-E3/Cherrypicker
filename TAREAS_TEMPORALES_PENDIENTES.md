# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Fichero de continuidad de trabajo: estado actual, pendientes y reglas. Una sesión nueva debería poder continuar leyendo solo esto.
> Actualizado: 2026-10-19, T-011/EXP-005. Proyecto en `/Volumes/E3 M4/Proyectos IA/Cherrypicker`. La historia está en los EXP de docs/13.

## REGLA DE CONTINUIDAD

Antes de modificar código:
0. Si existe una rama de trabajo remoto (ver `docs/remoto/00_INDICE.md`): `git fetch` de esa rama; si trae commits
   nuevos, comprobar que solo cambian `docs/remoto/`, integrarlos y leer el mensaje más reciente de
   `docs/remoto/PARA_LOCAL.md` que no esté atendido en `docs/remoto/PARA_REMOTO.md`. (El fetch lo lanza el usuario.)
1. Leer SOLO este fichero y `git status`/`git diff`.
2. Leer únicamente los archivos directamente relacionados con la tarea activa.
3. NO releer conversaciones ni explorar todo el proyecto salvo que una dependencia concreta lo exija.
4. Una tarea no se marca COMPLETADA hasta que: archivo guardado + compilación/tests pertinentes + resultado registrado aquí.
5. Si el límite de contexto está próximo, detenerse y actualizar este fichero con `EN PROGRESO`, cambios realizados y siguiente paso exacto. No iniciar una tarea nueva.
6. No sobrescribir archivos completos sin comprobar antes la versión actual en el repositorio.

## REGLAS DEL PROYECTO

- **El repo manda:** nada se da por resuelto por conjetura. Método en `docs/11_METODO_INGENIERIA_INVERSA.md`; estados en `protocol/PROTOCOL_INDEX.md`.
- **Ficheros del usuario solo lectura;** las escrituras se prueban sobre copias. Copiar a las carpetas de DP solo con permiso.
- **Audición con permiso del usuario:** solo Bank Select y Program Change; nunca SysEx ni volcados al módulo.
- Material de terceros en `reference/`, **no versionado**. No usar `git add -A` sin revisar.
- El push lo hace el usuario. Instalar o descargar software requiere permiso.
- **Software original como base:** al reproducir apps o paneles del fabricante, partir de su organización y nombres; las mejoras se proponen y se acuerdan antes.
- **CPU:** tras cada cambio relevante de lo que corre en segundo plano, medirla (`top`) y anotarla en el EXP.
- **DOCTYPE de los ficheros nuevos:** el de la 1.0 con la URL de midi.org, validable; los ficheros abiertos conservan el suyo (usuario, 2026-10-19). Confirmado en DP (EXP-006).
- **Sistema de prueba:** no actualizar macOS ni DP 11.36 sin comprobar antes que el flujo sigue funcionando.
- **Los `.midnam` de `reference/midnam_usuario/` son privados** (usuario, 2026-10-19): no se versionan ni se publican; para tests en el repo se usan copias anonimizadas o ficheros propios, previa consulta.
<!-- Reglas propias del proyecto: añadir aquí, con «(usuario, AAAA-MM-DD)» si las decide el usuario. -->

## ESTADO ACTUAL (2026-10-19)

- Material archivado en `reference/` e inventariado en `docs/01` (T-003): app 3.0 (ppc+i386, no arranca en macOS ≥10.15), app 2.62 extraída del dmg de Wayback, manual web original (sin 20 imágenes), 6 `.midnam` privados del usuario. `CherryMangler.dmg` truncado, irrecuperable.
- Alcance decidido (T-005, `docs/14`): app nativa parecida a CherryPicker para crear `.midnam` desde cero para **DP 11.36**, con bancos agrupados por nombre, bank select por banco, controles con nombre y audición por CoreMIDI. Fases 1–6 en `docs/14`.
- EXP-001: la app 3.0 no arranca en macOS 15.7.9 arm64 (ppc/i386). Plantillas de escritura en `CPXMLStrings.plist`; estructura observada en `protocol/observed/midnam_cherrypicker.md`: `Patch Number` es etiqueta, bank select en tres formas (ninguna, por banco, por preset). 
- EXP-005: validación contra la DTD 1.0 con `tools/validar_midnam.sh` (catálogo local, sin red); los 6 ejemplos son válidos y `swift test` valida lo que escribe MidnamKit. El DOCTYPE `""` de CherryPicker no es validable tal cual.
- EXP-004: DTD 1.0 descargada (Wayback) a `reference/dtd/`; todo lo observado es válido; modelo ampliado (controles en línea, por preset, `Control` sin `Type`). Reglas para crear ficheros en `protocol/confirmed/midnam_formato_escritura.md`.
- EXP-003: `src/MidnamKit` lee y reescribe los 6 ejemplos byte a byte (árbol y modelo tipado); formato confirmado en `protocol/confirmed/`.
- EXP-002: DP 11.36 lee de `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` (los 6 ficheros del usuario están ahí, idénticos). DP conoce DTD 1.0 con `UsesControlNameList`. En DP se asigna en *Bundles → MIDI Device Properties → Patches → Master Names*; no hace falta `.middev`; DP muestra los `PatchBank` por nombre y en orden. **Un modelo nuevo necesita también `.middev`** (EXP-006): DP saca *Manufacturer*/*Model* de los `.middev`. Abierto: recarga sin reiniciar y qué nombre usa *Master Names*.

## TAREAS

| ID | Tarea | Estado |
|---|---|---|
| T-001 | Estructura del proyecto desde la plantilla, git local | COMPLETADA 2026-10-19 |
| T-002 | Repo GitHub privado y remoto configurado (lo crea el usuario): `JsLR-E3/Cherrypicker` | COMPLETADA 2026-10-19 |
| T-003 | Archivar `incoming/` en `reference/` con su estructura e inventariarlo en `docs/01` y `reference/README.md` | COMPLETADA 2026-10-19 |
| T-004 | EXP-001: intentar abrir la app 3.0 en este Mac (macOS 15.7.9) y registrar el fallo; estudio estático de recursos y del formato midnam con los ejemplos | COMPLETADA 2026-10-19 |
| T-005 | Definir el alcance con el usuario: qué funciones se usan, con qué programas (DP, Logic, Pro Tools…) y qué se quiere recuperar (`docs/14`) | COMPLETADA 2026-10-19 |
| T-006 | Adaptar `CLAUDE.md` y `docs/11` de «aparato» a «programa» (formatos de fichero en vez de protocolo de hardware) | COMPLETADA 2026-10-19 |
| T-007 | Fase 1: especificación del formato midnam en `protocol/` (DTD + ejemplos) y paquete Swift de lectura/escritura con test de ida y vuelta | COMPLETADA 2026-10-19 (EXP-003) |
| T-009 | Descargar la DTD MIDINameDocument 1.0 (con permiso) a `reference/` y contrastar `protocol/confirmed/midnam_formato_escritura.md` y el modelo | COMPLETADA 2026-10-19 (EXP-004) |
| T-011 | Test de validación con `xmllint --dtdvalid` de los ficheros que escriba MidnamKit (necesita `MIDIEvents10.dtd`, descarga con permiso) | COMPLETADA 2026-10-19 (EXP-005) |
| T-012 | EXP con el usuario: instalar en `MOTU/<Fabricante>/` (con permiso) un `.midnam` nuevo de MidnamKit y comprobar en DP 11.36 que lo acepta con el DOCTYPE de midi.org, qué nombre muestra *Master Names* y si recarga sin reiniciar | EN PROGRESO (EXP-006: `.midnam` + `.middev` instalados en `MOTU/Cherrypicker/`; DP acepta el fichero y el DOCTYPE; *Master Names* = nombre de fichero; faltan menú de presets, controles y recarga v2) |
| T-010 | Fase 3: diseño de la app a partir de las ventanas de CherryPicker (nibs, manual, capturas) en `docs/2x`, para acordar con el usuario antes de programar | PENDIENTE |
| T-008 | Fase 2: EXP — localizar dónde lee DP 11.36 los `.midnam` y comprobarlo con un ejemplo del usuario | COMPLETADA 2026-10-19 (EXP-002) |

## SIGUIENTE PASO EXACTO (retomar en sesión nueva)

1. T-010 (análisis de las ventanas de CherryPicker → diseño de la app). Tests: `cd src/MidnamKit && swift test`.
2. Cuando haya un fichero generado por la app: EXP con el usuario para la recarga en DP y el nombre de *Master Names* (ver `protocol/observed/dp_carpeta_midnam.md`).
