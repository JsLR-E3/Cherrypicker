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

## D-007 · 2026-10-20 · Mejoras sobre el original y copyright

- **Decisión:** (1) se puede mejorar CherryPicker o añadir funciones cuando se considere necesario; cada mejora se
  propone, se acuerda con el usuario y queda marcada [PROPUESTA] en `docs/20`. (2) Pensando en distribuir o compartir
  la app: el código es propio y se escribe desde cero (no se copian ni se descompilan binarios ni nibs del original;
  de los nibs y capturas solo se toman la organización y las etiquetas cortas de la interfaz); no se copian el icono,
  las imágenes, el manual ni textos largos (avisos, ayudas); los recursos con listas (p. ej. categorías de
  `Categories.plist`) se rehacen, no se copian; nada de `reference/` se distribuye (ya no se versiona); los ficheros de
  prueba del repositorio son propios. **Antes de compartir la app** hace falta: nombre e icono propios (CherryPicker y
  su cereza son de Alterspective), revisar los textos cortos tomados de los nibs (tooltips) y confirmar la licencia del
  repositorio (`LICENSE` es la GPL-3.0 que venía con la plantilla, sin decidir).
- **Motivo:** indicación del usuario (2026-10-20).
- **Quién:** usuario; el detalle de las medidas, propuesta de Claude.
- **Estado:** vigente.

## D-006 · 2026-10-20 · La app se hace con AppKit (macOS 13 o posterior)

- **Decisión:** app AppKit (NSDocument, NSTableView, hojas), construida en código sin nibs, como paquete Swift
  (`src/CherryPickerApp`) que depende de MidnamKit; `tools/empaquetar_app.sh` monta `build/CherryPicker.app` con firma
  ad hoc. Versión mínima: macOS 13, igual que MidnamKit.
- **Motivo:** el original es AppKit (sus 26 nibs), así que las ventanas se traducen casi una a una (regla 10); las
  tablas de AppKit resuelven edición de celdas, arrastrar entre ventanas, clic en cabecera y deshacer, que en SwiftUI
  dan problemas. Sin proyecto Xcode: se compila y se prueba con `swift build`/`swift test` también desde la terminal.
- **Alternativas descartadas:** SwiftUI (tablas insuficientes para lo que pide `docs/20`); mezcla SwiftUI + AppKit
  (dos tecnologías y un puente que mantener).
- **Quién:** usuario, sobre la recomendación de Claude (2026-10-20); el empaquetado sin Xcode, propuesta de Claude.
- **Estado:** vigente.

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
