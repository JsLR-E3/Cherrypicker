# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Fichero de continuidad de trabajo: estado actual, pendientes y reglas. Una sesión nueva debería poder continuar leyendo solo esto.
> Actualizado: 2026-10-19, T-005 (alcance cerrado con el usuario). Proyecto en `/Volumes/E3 M4/Proyectos IA/Cherrypicker`. La historia está en los EXP de docs/13.

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
- **Sistema de prueba:** no actualizar macOS ni DP 11.36 sin comprobar antes que el flujo sigue funcionando.
- **Los `.midnam` de `reference/midnam_usuario/` son privados** (usuario, 2026-10-19): no se versionan ni se publican; para tests en el repo se usan copias anonimizadas o ficheros propios, previa consulta.
<!-- Reglas propias del proyecto: añadir aquí, con «(usuario, AAAA-MM-DD)» si las decide el usuario. -->

## ESTADO ACTUAL (2026-10-19)

- Material archivado en `reference/` e inventariado en `docs/01` (T-003): app 3.0 (ppc+i386, no arranca en macOS ≥10.15), app 2.62 extraída del dmg de Wayback, manual web original (sin 20 imágenes), 6 `.midnam` privados del usuario. `CherryMangler.dmg` truncado, irrecuperable.
- Alcance decidido (T-005, `docs/14`): app nativa parecida a CherryPicker para crear `.midnam` desde cero para **DP 11.36**, con bancos agrupados por nombre, bank select por banco, controles con nombre y audición por CoreMIDI. Fases 1–6 en `docs/14`.
- Sin experimentos todavía.

## TAREAS

| ID | Tarea | Estado |
|---|---|---|
| T-001 | Estructura del proyecto desde la plantilla, git local | COMPLETADA 2026-10-19 |
| T-002 | Repo GitHub privado y remoto configurado (lo crea el usuario): `JsLR-E3/Cherrypicker` | COMPLETADA 2026-10-19 |
| T-003 | Archivar `incoming/` en `reference/` con su estructura e inventariarlo en `docs/01` y `reference/README.md` | COMPLETADA 2026-10-19 |
| T-004 | EXP-001: intentar abrir la app 3.0 en este Mac (macOS 15.7.9) y registrar el fallo; estudio estático de recursos y del formato midnam con los ejemplos | PENDIENTE |
| T-005 | Definir el alcance con el usuario: qué funciones se usan, con qué programas (DP, Logic, Pro Tools…) y qué se quiere recuperar (`docs/14`) | COMPLETADA 2026-10-19 |
| T-006 | Adaptar `CLAUDE.md` y `docs/11` de «aparato» a «programa» (formatos de fichero en vez de protocolo de hardware) | COMPLETADA 2026-10-19 |
| T-007 | Fase 1: especificación del formato midnam en `protocol/` (DTD + ejemplos) y paquete Swift de lectura/escritura con test de ida y vuelta | PENDIENTE |
| T-008 | Fase 2: EXP — localizar dónde lee DP 11.36 los `.midnam` y comprobarlo con un ejemplo del usuario | PENDIENTE |

## SIGUIENTE PASO EXACTO (retomar en sesión nueva)

1. T-006 (adaptar reglas y método a programa) y T-004 (intento de arranque + estudio estático).
2. T-007 (formato y modelo) y T-008 (DP 11.36) pueden avanzar en paralelo.
