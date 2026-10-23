# 20 — DISEÑO DE LA APP (fase 3, T-010)

> **Estado: ACORDADO con el usuario el 2026-10-20 (D-005).** Respuestas en §7. Mejoras y copyright: D-007. Regla 10 de `CLAUDE.md`: se reproduce la organización y los nombres de
> CherryPicker; lo que se aparta del original va marcado **[PROPUESTA]** (P1–P7, aceptadas).

- **Origen:** CherryPicker 3.0 (Alterspective), `reference/app_3.0/CherryPicker.app` (ppc/i386, no arranca: EXP-001):
  25 nibs (`English.lproj/*.nib` y `MergeSheet.nib`), `Localizable.strings`, `.plist` de recursos; manual web
  `reference/web_alterspective/cherrypicker/docs/introC.html`.
- **Cómo se extrajo:** sin instalar ni ejecutar nada. Manual convertido a texto con `textutil`; nibs con `plutil`
  sobre copias en el scratchpad (inventario: §6).
- **Comportamiento de DP 11.36 que condiciona el diseño:** EXP-002 y EXP-006 (ver `protocol/PROTOCOL_INDEX.md`).

## 1. Qué hacía CherryPicker (según el manual)

Editor de «patchfiles» (`.midnam`, y también OMS, FreeMIDI y Cubase) que:

- Al arrancar recorre `/Library/Audio/MIDI Devices` y crea una base de datos de fabricantes y modelos a partir de los
  `.middev`; si al abrir un `.midnam` falta su entrada en un `.middev`, la crea (DP no ve un modelo sin `.middev`).
- **File ▸ New** abre el *New Device Setup Assistant*: fabricante y modelo (autocompletados con la base de datos), si
  todos los bancos suenan en todos los canales, y crea el `.middev` o la entrada que falte.
- **Ventana principal** de cada documento con pestañas: **Patch Banks**, **Note Lists**, **Controllers**, **Device**
  (modos, *Channel Sets*, editor de `.middev`) y **MIDI** (conexión del módulo y del teclado, interruptor de MIDI).
  Además: *Save Format* (Digital Performer / ProTools / Cubase), **XML Filters…** y **Preview** (el XML que se va a
  escribir).
- **Patch Banks:** tabla de bancos (botón **P** para abrir su lista, nombre único, **S0**/**S32** = bank select,
  *Channel Set* en un popup). Cambio múltiple pulsando la cabecera de columna (hoja para S0/S32 o Channel Set). Arrastrar
  para reordenar dentro de su Channel Set o entre documentos. Botones **+ / −**, **Merge**, **Sibelius**, **Zap Dups**,
  **C->S**, **Link**, **Import** (expansiones MOTU), **Find**.
- **Bank Selects** de un banco: hoja que pregunta cómo afectan los valores nuevos a los bank select de cada patch.
  «-» = no se usa (0 es un valor válido).
- **Custom Banks:** bancos sin bank select propio cuyos patches llevan cada uno el del banco «real». Al añadir banco se
  pueden crear de golpe las categorías GM o E-mu.
- **Ventana de lista de patches** (una por banco, varias abiertas a la vez): columnas de número, **B0**/**B32**, nombre y
  **Ascii** (etiqueta del panel del módulo, no es el número de programa). **+ / −**, ordenar por cabecera, arrastrar
  dentro y entre listas, **Copy…** (hoja de exportación de campos al portapapeles o a TextEdit), **Renumber** (número
  MIDI y/o Ascii; todos o los seleccionados), campo **Find**, controles de audición abajo, popup de Note List del patch.
- **Pegar o soltar texto** en una lista: hoja con la numeración y el **delimitador** (*Quotes, Commas, Tabs,
  End-Of-Lines*); reconoce volcados de GigaStudio y Cakewalk y el formato `número=nombre`.
- **Find** (en Patch Banks): lista de todos los patches cuyo nombre contiene el texto, con botón para crear un Custom
  Bank con lo encontrado.
- **Device:** modos (`CustomDeviceMode`) con **+ / −**; *Channel Sets* con **Active Channels** (`1-7, 9, 11-16`) y
  **Audition Ch**; el **+** se desactiva si los 16 canales están asignados. Editor de `.middev` (**+ / −**, **Copy** /
  **Paste**, **Save**) o **Show Duplicates** si hay entradas repetidas.
- **Controllers:** listas de controles con nombre; **+** crea «Default Control Names» con los controles estándar.
- **MIDI / Auditioning:** al seleccionar un patch envía el cambio de programa; teclado *thru*; reproductor de ficheros
  MIDI (**Audition Files…**, ⌘M) con **Auto** y **Play/Stop**.
- **Save / Save As…:** formato, accesos directos a las carpetas de patchfiles (Preferencias) y nombre de fichero
  compatible con el formato.
- **Preferencias:** buscar actualizaciones, crear carpeta de fabricante, rutas de las carpetas de patchfiles, ruta de
  `MIDI Devices` y de las expansiones MOTU.

## 2. Alcance de la app nueva (D-001, `docs/14`)

| Función original | ¿En la app nueva? | Motivo |
|---|---|---|
| Abrir y guardar `.midnam` sin pérdidas | **Sí** | MidnamKit (fase 1) |
| New Device Setup Assistant (fabricante, modelo, canales) y crear `.middev` | **Sí** | DP necesita el `.middev` (EXP-006) |
| Patch Banks: tabla, S0/S32, Channel Set, + / −, reordenar, cambio múltiple por cabecera | **Sí** | Uso declarado (T-005) |
| Hoja Bank Selects (cómo afectan a los patches) | **Sí** | Bank select por banco |
| Custom Banks y arrastrar patches entre bancos | **Sí** | Agrupar por categorías en DP |
| Find y «crear banco con lo encontrado» | **Sí** | Ayuda a montar Custom Banks |
| Pestaña Categories (categorías GM/E-mu → bancos) | **Sí** (§7.2) | Crea de golpe los Custom Banks por categoría |
| Import desde otros `.midnam` (ImportBrowser) | **Sí** (§7.2) | El nib lo muestra como importador de `.midnam`, no de Cubase/OMS |
| Hoja de comprobación antes de guardar (CPCheckSheet) | **Sí**, con las comprobaciones de DP | Evita ficheros que DP no lee bien |
| Zap Dups | **Sí** | Pensado para el problema de DP con Custom Banks |
| Merge | **Sí** (menor) | Barato con el modelo |
| Lista de patches: + / −, ordenar, arrastrar, Renumber | **Sí** | |
| Pegar o soltar texto con delimitador | **Sí** | Uso declarado (T-005) |
| Copy… (exportar campos al portapapeles) | Más adelante | Útil, no pedido |
| Device: modos y Channel Sets | **Sí** | Estructura del fichero |
| Controllers (`ControlNameList`) | **Sí** (fase 5) | DP no los muestra en el menú de pista (EXP-006, T-014) |
| Audición: Bank Select + Program Change al seleccionar un patch | **Sí** (fase 4) | D-002: solo esos mensajes |
| Teclado thru y reproductor de ficheros MIDI | **No por ahora** (§7.3) | Se añadirán si hacen falta |
| Preview del XML | **Sí** | Barato; útil para comprobar |
| Save Format ProTools/Cubase/FreeMIDI, XML Filters, Zap Custom (C->S) | **No** | Solo DP 11.36 (D-001) |
| Note Lists (drum maps) | **No por ahora** | D-001 |
| Abrir OMS, FreeMIDI, Cubase; importar GigaStudio, Cakewalk, expansiones MOTU | **No por ahora** | D-001 |
| Sibelius, Link, actualizaciones, registro (Kagi) | **No** | Fuera de alcance |
| Editor de `.middev` completo y Show Duplicates | **No por ahora**; solo crear la entrada que falte | Mínimo para que DP vea el modelo |

## 3. Ventanas de la app nueva

Mismos nombres y organización que el original (textos literales de los nibs, §6). Se omite lo que queda fuera de §2.
**Disposición contrastada con capturas del original (EXP-009):** ventana alta y estrecha; arriba de las pestañas,
«Save Format», «XML Filters...» y «Preview» (en la app nueva solo «Preview», P1); en Patch Banks, botones encima de la
tabla y leyenda de colores a la derecha (nombre del banco: Normal negro, Empty rojo, Mixed azul).

### 3.1 Ventana de documento (MainWindow)

Una por `.midnam` abierto; varias a la vez (se arrastran bancos y patches entre ellas). Pestañas, en el orden del nib:

| Pestaña | Contenido en la app nueva |
|---|---|
| **MIDI** | Caja «MIDI Connections»: popup «Device Out» (destinos de CoreMIDI; se recuerda por fabricante y modelo) y casilla «Enable MIDI» (desactivada al abrir, P5). Al seleccionar un solo patch se envían CC0/CC32 (si no son «-») y Program Change por el «Audition Ch» de su Channel Set (editable en Device; se recuerda en la app, no en el fichero). Sin notas ni secuencias: con multiefectos no sirven y pueden cambiar el efecto (T-021). («Controller In», el teclado, solo si se decide el thru, §7.) |
| **Device** | «Manufacturer:» y «Model:» (solo lectura, ligados al `.middev`); caja «Modes» con tabla y + / −; caja «Channel Sets» con tabla y + / −, «Active Channels», «Audition Ch:» y el aviso «(Add disabled: No free channels in mode)». Sin «MIDI Initialization… / Send Now» (SysEx, regla 4). |
| **Patch Banks** | Tabla `P` · `S0` · `S32` · `Patch Bank` · `#` · `Channel Set` y leyenda «• Normal / • Mixed / • Empty». Botones + / −, «Merge», «Import», «Find», «Zap Dups». Sin «Bank Initialization / Transmit», «Zap Custom» ni «Sibelius». |
| **Note Lists** | No por ahora (§7.1): sin pestaña; las listas de notas de un fichero abierto se conservan al guardar. |
| **Controllers** | Tablas «Control Name Lists» (+ / −) y `Ctl` · `Name`; + crea «Default Control Names». |
| **Categories** | Tablas «Categories» y «Bank Names» con + / −, «Add To Banks», «Dup». |

Arriba a la derecha: **«Preview»**. Sin popup «Save Format» ni «XML Filters...»: el formato es siempre el de DP (§5).

### 3.2 Lista de patches (PatchWindow, «Patch Names»)

Una por banco, desde el botón **P**. Tabla `B0` · `B32` · `#` · `Patch Name` · `Ascii`, editables y ordenables por
cabecera (reordena la lista del fichero); arrastrar para reordenar o llevar a otra lista (copia). Campo «Find»
(filtra la tabla por nombre; el manual dice que el original *selecciona* los que coinciden y, al arrastrar uno, se
mueven todos: pendiente de decidir con el usuario) y «Count:» (filas visibles). Botones «Renumber» y + / −. «Copy...»
más adelante (§2). Al seleccionar un patch con «Enable MIDI» activo, se envían Bank Select + Program Change (D-002). Sin
el bloque «Audition Riff» (§7).

### 3.3 Hojas

| Hoja (nib) | Cuándo | Contenido |
|---|---|---|
| Add a Single Bank (BankSheet) | + en Patch Banks | «Channel Set», «Name» (único), «B Sel0», «B Sel32» (`-` = no se usa), «Cancel» / «Add» |
| Name for Merged Bank (MergeSheet) | Merge | Igual; «(Use <Option Add> to keep original banks)» |
| Bank Selects (BankSelectSheet) | Doble clic en S0/S32 o en su cabecera con varios bancos | «Apply to all patches» / «Apply ONLY to patches without Bank Selects» / «Apply Only to patches with Bank Selects», «B Sel 0», «B Sel 32» |
| Channel Set de varios bancos | Clic en la cabecera «Channel Set» | Popup de Channel Set (deducido del manual) |
| New Channel Set (AddChSet) | + en Channel Sets | «Name», «Channels» (`1-9, 11-16`), «Free:» |
| Reassign Banks To (ReassignCS) | − en un Channel Set con bancos | Popup del Channel Set de destino |
| New Patches (CPAddPatchSheet) | + en la lista, o pegar/soltar texto | «Start At:», «Start Ascii», «Quantity», «Set Bank Selects to Bank values», «Patch Delimiter» = End of line / Comma / Quote / Tab ; por defecto Start At 0, Start Ascii 001; se inserta en la posición seleccionada (EXP-012); casilla según P9 |
| Renumber Patches (CPRenumberSheet) | Renumber | «MIDI starts at:», «Display starts at:», «All» / «Selection» |
| Comprobación (CPCheckSheet) | Al guardar, si hay problemas | «The following potential problems were found», «Cancel and Fix» / «Continue Anyway» |
| Model (CPMultiModel) | Guardar un fichero con varios `<Model>` | Popup «Model» |

Hoja Bank Selects, **contrastada con el original (EXP-009, nivel B)**: las tres opciones ponen los valores al banco.
«Apply to all patches»: todos los patches pasan a la forma corta (heredan). «…ONLY to patches without…»: los patches
cuyo `PatchMIDICommands` solo lleva el Program Change (el «-» del original) reciben los valores como propios.
«…Only to patches with…»: los que tienen CC0/CC32 propios pasan a los nuevos valores. Restricciones de la DTD: no
se puede borrar ni sacar el último banco de un Channel Set (`PatchBank+`).

### 3.4 Otras ventanas

- **Device Setup** (SetupWizard), con File ▸ New: 1) «Manufacturer:» / «Model:» con autocompletado desde los `.middev`;
  2) aviso de `.middev` creado o actualizado; 3) «Do all patch banks play on all channels?» y número de grupos;
  4) tabla «Name» / «Uses Channels»; 5) «Setup Finished». Sin «Launch AudioMIDI Setup» (DP no lo necesita, EXP-006).
- **Finder** (FoundWindow): búsqueda en todos los bancos (el nombre contiene el texto), columnas sin editar, «Add New
  Bank With Patches» (hoja de banco con todos los de la lista), «Remove Duplicates» (deducido: quita los que suenan
  igual que uno anterior) y − (quita de la lista, no del fichero); se arrastran a cualquier lista (copia). T-019.
- **Zap Dups** (T-019; deducido, el manual no define «duplicado»): en cada Channel Set, borra de los bancos con bank
  select los patches cuyo bank select efectivo + Program Change está en un banco sin bank select (Custom Bank). A
  contrastar con el original. Con bancos seleccionados, P12. El fallo de DP que evita existe en DP 11.36 (EXP-015).
- **Patchlist Importer** (ImportBrowser): «Files You Can Import From» y la asignación de bancos de destino.
- **Preview**: el XML exacto que se escribirá.
- **Preferences**: carpeta de `MIDI Devices` (por defecto `/Library/Audio/MIDI Devices`) y «Create new folders inside
  default folder». Sin actualizaciones ni atajos de ProTools/Cubase.
- **Menús**: CherryPicker (About, Preferences… ⌘,, Quit), File (New ⌘N, Open… ⌘O, Open Recent, Close ⌘W, Save ⌘S,
  Save As… ⇧⌘S, Revert To Saved ⌘R), Edit (Cut, Copy, Paste ⌘V para pegar listas de nombres, Delete, Select All),
  Window (estándar de macOS) y Help.

## 4. Flujos

1. **Fichero nuevo:** File ▸ New → Device Setup → documento con un modo, sus Channel Sets y ningún banco → Patch Banks ▸ +
   (Add a Single Bank) → **P** → pegar la lista de nombres (⌘V) → New Patches (delimitador, numeración) → Save.
2. **Editar uno existente:** Open → si falta la entrada del `.middev`, aviso y propuesta de crearla → edición → Save
   (sin pérdidas: lo que la app no entiende se conserva, MidnamKit).
3. **Custom Bank:** + banco con S0/S32 en `-` → arrastrar patches desde otras listas o desde Finder (cada patch conserva
   su bank select) → «Zap Dups» si DP muestra el banco original (manual).
4. **Bank select de varios bancos:** seleccionar → cabecera S0/S32 → hoja Bank Selects.
5. **Audición:** MIDI ▸ Enable MIDI + Device Out → abrir una lista → seleccionar patches (clic o flechas) → la app envía
   CC0/CC32 (si no son `-`) + Program Change por el «Audition Ch» del Channel Set del banco.
6. **Llevarlo a DP:** Save → comprobación → [PROPUESTA] «Instalar en DP» (§5) → volver a elegir el fichero en
   *Master Names* de DP (DP no recarga solo, EXP-006).

## 5. Lo que se aparta del original [PROPUESTAS]

| # | Propuesta | Motivo |
|---|---|---|
| P1 | Sin «Save Format» ni «XML Filters»: se escribe siempre como lo lee DP 11.36, con el DOCTYPE de D-003 | Único destino (D-001) |
| P2 | El nombre de la `PatchNameList` lo pone la app y es siempre igual al del banco; el usuario solo ve el banco | DP muestra «lista + número nombre» (EXP-006); el original lo dejaba a la vista con «Link» |
| P3 | Acción «Instalar en DP…» (aparte de Save): copia a `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`, crea o completa el `.middev`, pide confirmación y recuerda volver a elegir en *Master Names* | DP lee de ahí (EXP-002); escribir en esa carpeta exige confirmación del usuario (regla 3) |
| P4 | La comprobación antes de guardar incluye lo aprendido con DP: nombres de banco únicos, ≤ 128 patches por banco, bank select 0–127 o `-`, `.middev` presente y validación DTD | EXP-004/005/006 |
| P5 | Audición solo con CC0/CC32 + Program Change; «Enable MIDI» desactivado al abrir; sin SysEx en ningún sitio | D-002 y regla 4 |
| P6 | Deshacer/rehacer (⌘Z) en todas las ediciones | Estándar de macOS; el original no lo tenía en el menú Edit |
| P7 | Textos de la interfaz en inglés, como el original, con los mismos nombres | Regla 10; a confirmar (§7) |
| P8 | Con varios bancos seleccionados, cambiar el popup de Channel Set de uno los cambia todos (además de la cabecera del original) | Más directo; aceptada por el usuario al probarla (EXP-010) |
| P9 | «Set Bank Selects to Bank values» igual con + que al pegar: marcada (o banco sin bank select), los patches nuevos heredan del banco (forma corta); sin marcar en un banco con bank select, «-» (solo Program Change). El banco conserva su bank select aunque algún patch lleve otro (no pasa a «-»). Al arrastrar a otra lista, cada patch sigue sonando con el mismo bank select | El original es incoherente (EXP-012: 5/0 propios con y sin la casilla en +; «-» o 1/1 fijo al pegar); aceptada por el usuario (2026-10-21) |
| P10 | Lista de patches: al editar una celda, Tab / ⇧Tab recorren las celdas saltando de fila al final de cada una, y ↑ / ↓ pasan a la misma columna del patch de arriba o de abajo; ← / → pasan a la celda de al lado cuando el cursor está en el borde del texto o todo él seleccionado. En Patch Banks (solo se escribe el nombre), Tab / ↓ y ⇧Tab / ↑ pasan al nombre del banco siguiente o anterior | Edición más rápida; en el original Tab salía de la tabla a los botones. Pedida por el usuario (EXP-013) |
| P11 | Zap Dups pide confirmación con el número de patches que borrará (o avisa si no hay ninguno) | Borra patches; el original lo hacía sin preguntar (manual: «haz copia antes») |
| P12 | Zap Dups con bancos seleccionados: se conservan esos y sus patches se borran de todos los demás bancos de su Channel Set, tengan bank select o no; sin selección, la regla del original (se conservan los bancos sin bank select). El aviso dice cuántos se borran de cada banco | Con la regla sola, un banco de origen sin bank select se toma por Custom y no se limpia nunca (EXP-014); pedida por el usuario |
| P13 | Un Channel Set nuevo (+ en Channel Sets o al crear un modo) lleva un banco vacío «New Bank»; nombres de modo y de Channel Set únicos | La DTD exige `PatchBank+`: el original los dejaba vacíos y con nombres repetidos, y el fichero no validaba (EXP-012); aceptada por el usuario (2026-10-23) |

## 6. Inventario de los nibs

Extraído de `keyedobjects.nib` con `plutil`/`plistlib`, sin ejecutar la app. Nivel D (`docs/11`): sale del binario
y no se ha visto la app funcionando. Textos literales entre comillas; columnas como `identificador`:«cabecera».

| Nib | Ventana · clase propietaria | ¿Entra? |
|---|---|---|
| MainWindow | ventana de documento con pestañas MIDI / Device / Patch Banks / Note Lists / Controllers / Categories; panel «XML Filters» · CPMainWindow | Sí (sin XML Filters) |
| PatchWindow | «Patch Names» · CPPatchListController | Sí |
| FoundWindow | «Finder» · FoundWindowController | Sí |
| BankSheet, MergeSheet, BankSelectSheet, AddChSet, ReassignCS | hojas de banco y Channel Set | Sí |
| CPAddPatchSheet, CPRenumberSheet | hojas de patches | Sí |
| CPCheckSheet, CPMultiModel | hojas al guardar | Sí |
| SetupWizard | «Device Setup» · CPSetupWizard | Sí |
| Preview | «Preview» · CPPreview | Sí |
| ImportBrowser | «Patchlist Importer» · CPImportBrowser (importa de otros `.midnam`) | Sí |
| CPPatchExport | «Copy Fields To Clipboard» · CPCopySheet | Más adelante |
| MiddevEditor, CPDuplicates | «Middev Editor», «Duplicate Middev Entries» | No por ahora |
| NoteWindow | «Note Names» · NoteWindowController | No por ahora (§7.1) |
| MIDIFileUI | «Audition Files» · RiffPlayerUI | No por ahora |
| SavePanel | vista del diálogo de guardar (formato y atajos) | No (P1) |
| CPSibelius, UKFeedbackProvider, AboutPanel, MainMenu | Sibelius, comentarios, Acerca de, menús y Preferencias | Solo About, menús y Preferencias |

Pendiente de concretar con la app viva (no posible, EXP-001): contenido de los popups que se rellenaban en ejecución,
el significado exacto de la leyenda Normal / Mixed / Empty (deducido: banco con bank select propio, Custom Bank y banco
vacío) y las posiciones exactas (están en `NSFrame` y no se han volcado).

## 7. Preguntas abiertas para el usuario

1. ~~**Note Lists (drum maps):** ¿fuera por ahora, como dice D-001, o los usabas?~~ **Respondida (usuario,
   2026-10-20):** fuera por ahora; se implementan si hicieran falta. MidnamKit ya conserva las que traiga un fichero.
2. ~~**Categories** (crear Custom Banks por categorías GM/E-mu) e **Import** desde otros `.midnam`: ¿entran?~~
   **Respondida (usuario, 2026-10-20):** sí, entran las dos.
3. ~~**Audición:** ¿basta con enviar el cambio de programa y tocar desde tu teclado por DP, o quieres también el thru del
   teclado o el reproductor de ficheros MIDI del original?~~ **Respondida (usuario, 2026-10-20):** de momento solo el
   cambio de programa (CC0/CC32 + Program Change); thru y reproductor, más adelante si hacen falta.
4. ~~**Propuestas P1–P7:** ¿de acuerdo? Especialmente P3 (la app escribe en la carpeta de DP tras confirmar) y P7
   (interfaz en inglés).~~ **Respondida (usuario, 2026-10-20):** sí, las siete.
5. **Tecnología** (pendiente: se decide en T-015, `docs/16`): SwiftUI con tablas AppKit donde haga falta arrastrar y editar
   celdas; requisito de versión de macOS.
