# 12 — DECISIONES

Decisiones técnicas y acuerdos con el usuario que condicionan el trabajo futuro. Una entrada por decisión, más
recientes arriba; no se borran: si una decisión cambia, se añade otra que la **sustituye** y se marca la antigua.
Lo que es solo una propuesta va en la tarea o en `docs/remoto/`, no aquí.

<!--
## D-001 · AAAA-MM-DD · Título breve
- **Decisión:** …
- **Motivo:** … (EXP-…, documento, medida)
- **Alternativas descartadas:** … y por qué
- **Quién:** usuario / propuesta de Claude aceptada por el usuario
- **Estado:** vigente · sustituida por D-…
-->

## D-005 · 2026-10-20 · Diseño de la app (fase 3): `docs/20_DISENO_APP.md`

- **Decisión:** la app reproduce las ventanas y nombres de CherryPicker descritos en `docs/20` (en inglés). Entran Patch
  Banks, listas de patches, Custom Banks, Find, Zap Dups, Merge, Categories, Import desde otros `.midnam`, Device (modos
  y Channel Sets), Controllers, Preview y Device Setup. Quedan fuera por ahora Note Lists, el thru del teclado y el
  reproductor de ficheros MIDI (se añaden si hacen falta). La audición solo envía CC0/CC32 + Program Change.
  Se aceptan las propuestas P1–P7 de `docs/20` §5: solo formato DP, `PatchNameList` con el nombre del banco,
  «Instalar en DP…» con confirmación, comprobación al guardar, sin SysEx, deshacer y textos en inglés.
- **Motivo:** uso declarado por el usuario; comportamiento de DP 11.36 (EXP-002, EXP-006); regla 10.
- **Alternativas descartadas:** mantener los formatos ProTools/Cubase/FreeMIDI y los XML Filters (solo hay un destino,
  D-001).
- **Quién:** usuario (respuestas a `docs/20` §7, 2026-10-20) sobre la propuesta de Claude.
- **Estado:** vigente.

## D-004 · 2026-10-19 · Los `.midnam` del usuario son privados

- **Decisión:** los ficheros de `reference/midnam_usuario/` no se versionan ni se publican; para tests en el repo se
  usan copias anonimizadas o ficheros propios, previa consulta. Las capturas versionadas guardan estructura y recuentos,
  no nombres de presets.
- **Motivo:** son trabajo personal del usuario.
- **Quién:** usuario.
- **Estado:** vigente.

## D-003 · 2026-10-19 · DOCTYPE de los ficheros nuevos

- **Decisión:** los `.midnam` que cree la app llevan el DOCTYPE de MIDINameDocument 1.0 con la URL de midi.org
  (validable); los ficheros que se abren conservan el suyo al reescribirlos.
- **Motivo:** el DOCTYPE de CherryPicker (identificador de sistema `""`) no es validable tal cual (EXP-005); DP 11.36
  acepta el de midi.org (EXP-006, nivel A).
- **Alternativas descartadas:** copiar el DOCTYPE de CherryPicker o el de MOTU (DTD 0.7).
- **Quién:** usuario (commit 9cf1545).
- **Estado:** vigente (`MidnamFile.newFileProlog`).

## D-002 · 2026-10-19 · Audición por CoreMIDI, solo Bank Select y Program Change

- **Decisión:** la app podrá enviar Bank Select (CC0/CC32) y Program Change al módulo elegido desde la lista, para
  probar antes de exportar. Nunca SysEx ni volcados.
- **Motivo:** función que el usuario usaba en CherryPicker; los mensajes de selección no cambian la memoria del módulo.
- **Quién:** usuario (T-005).
- **Estado:** vigente.

## D-001 · 2026-10-19 · Alcance: app nativa parecida a CherryPicker para DP 11.36

- **Decisión:** programa de destino **Digital Performer 11.36**; editor como **app nativa de macOS parecida a
  CherryPicker** (misma organización y nombres; las mejoras se proponen antes) para crear `.midnam` desde cero y editar
  los existentes sin pérdidas, con bancos agrupados por nombre, bank select configurable por banco, controles con nombre
  y audición (D-002). Tabla de funciones y fases 1–6 en `docs/14_ROADMAP.md`.
- **Motivo:** uso declarado por el usuario (T-005); la app 3.0 no arranca en el Mac actual (EXP-001).
- **Alternativas descartadas (por ahora):** Sibelius, Cubase/FreeMIDI/OMS, Gigastudio y mapas de notas.
- **Quién:** usuario (commit 11ae25b).
- **Estado:** vigente.
