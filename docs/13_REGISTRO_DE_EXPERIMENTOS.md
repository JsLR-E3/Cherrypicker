# 13 — REGISTRO DE EXPERIMENTOS

Formato: ID · fecha · objetivo · procedimiento · resultado · conclusión (nivel). Más antiguos arriba; se busca por
`grep` (ID o tema) en vez de leer el fichero entero. Un EXP cerrado no se reescribe: si otro lo corrige, se añade al
antiguo una línea «**Sustituido por EXP-NNN**». El **entorno** (macOS, versión de DP, commit) dice cuándo deja de
valer un resultado.

<!--
## EXP-001 · AAAA-MM-DD · Objetivo en una línea

- **Herramienta:** `tools/…` (solo lectura / escribe en …, con permiso del usuario)
- **Entorno:** macOS …, DP …, commit `…` (local; las pruebas con DP o con módulos no se hacen en la nube)
- **Procedimiento:** …
- **Captura:** `captures/<área>/…`
- **Resultado:** …
- **CPU:** (si aplica)
- **Conclusión:** … (A/B/C/D)
-->

## EXP-001 · 2026-10-19 · Arranque de CherryPicker 3.0 en este Mac y estudio estático de recursos y ejemplos

- **Herramienta:** `lipo`, ejecución directa y `arch`, `otool`, `plutil`, `xmllint --nonet`, script de recuento en
  Python (solo lectura; los `.midnam` del usuario no se modifican).
- **Procedimiento:** (1) ejecutar el binario de `reference/app_3.0/` directamente, con `arch -x86_64` y `arch -i386`;
  (2) comprobar los frameworks enlazados; (3) volcar los `.plist` de recursos; (4) recuento de elementos, DTD, formato
  de `Number` y combinaciones de bank select de los 6 `.midnam` (sin copiar nombres de presets).
- **Captura:** `captures/exp001/arranque.txt`, `captures/exp001/midnam_estructura.txt`
- **Resultado:**
  - macOS 15.7.9 arm64: «Bad CPU type in executable» en los tres casos. Rosetta está instalada pero solo traduce
    x86_64; el binario es ppc7400 + i386. Los frameworks (incluido Message.framework) siguen en la caché dyld, pero
    no en i386: **la app no puede arrancar aquí**.
  - `CPXMLRead.plist` lista los 36 elementos midnam que lee; `CPXMLStrings.plist` contiene la plantilla exacta con la
    que escribe cada uno (atributos y orden, p. ej. `<Patch Number="%@" Name="%@" ProgramChange="%@" />`).
  - `Defaults.plist`: carpetas por defecto `/Library/Audio/MIDI Devices/MOTU` (patches de MOTU/DP),
    `/Library/Audio/MIDI Patch Names/Digidesign`; opciones de escritura `CP_writeBankSx`, `CP_writePatchMidi`,
    `CP_writeControllers`, `CP_writeNotelist`, `CP_writeModeName`; categorías GM y E-MU en `Categories.plist`.
  - Ejemplos: los 4 de CherryPicker declaran DTD 1.0; los 2 de MOTU, DTD 0.7. Todos bien formados, LF, sangría con
    tabuladores. `Patch Number` es una **etiqueta de pantalla** (`"  1"`, `"065"`, `"400"`) y `ProgramChange` el valor
    MIDI. Bank select: LXP-15/LXP-15 II/DSP-128 Plus sin bank select (bancos solo de agrupación); PCM-81/91 una
    combinación CC0/CC32 por banco; M3000 23 bancos con 7 combinaciones y 155 presets con `PatchMIDICommands` propios
    (CC0+CC32+ProgramChange por preset). Ningún ejemplo usa `ControlNameList` ni `NoteNameList`.
- **Conclusión:** la app original no es ejecutable en el Mac de destino (A). Plantillas de escritura y elementos
  leídos: D (recursos de la app). Estructura de los ficheros que generó CherryPicker: B. Tres formas de bank select en
  uso: ninguna, por banco y por preset.

## EXP-002 · 2026-10-19 · Dónde lee Digital Performer 11.36 los `.midnam`

- **Herramienta:** `ls`, `find`, `cmp`, `plutil`, `strings` (solo lectura; no se ha copiado ni cambiado nada).
- **Procedimiento:** inventario de `/Library/Audio/MIDI Devices`, `/Library/Audio/MIDI Patch Names` y sus equivalentes
  en `~/Library`; comparar los ficheros instalados con `reference/midnam_usuario/`; buscar en DP 11.36 las cadenas
  del formato.
- **Captura:** `captures/exp002/carpetas_dp.txt`
- **Resultado:**
  - `/Library/Audio/MIDI Devices/MOTU/` (carpeta del usuario, 2026-10-19): 341 `.midnam` y 58 `.middev`, organizados
    como `.middev` por fabricante (sueltos o dentro de su carpeta, p. ej. `Lexicon/Lexicon.middev`) y
    `<Fabricante>/<Modelo>.midnam`. `MOTU/` tiene permisos `drwxrwxrwx`: se puede escribir sin administrador.
  - Los 6 ficheros del usuario están instalados ahí y son **idénticos** a los de `reference/`: `TC Electronic/M3000`,
    `Lexicon/LXP-15`, `Lexicon/LXP-15 II`, `Lexicon/PCM-81`, `Lexicon/PCM-91`, `Digitech/DSP-128 Plus`.
  - Hay además `TC Electronic/M3000.midnam copia` (distinto del actual) y **ninguna** `.middev` de TC Electronic;
    `Lexicon.middev` no incluye LXP-15 II.
  - `~/Library/Audio/MIDI Devices` no existe. `/Library/Audio/MIDI Patch Names/Avid/` (286 `.midnam`) es de Pro Tools.
  - DP 11.36 (`com.motu.DigitalPerformer`, x86_64 + arm64): `MidiSystem.framework` contiene el DOCTYPE
    `MIDINameDocument 1.0`, la DTD de midi.org y los elementos `CustomDeviceMode`, `StandardDeviceMode`,
    `ChannelNameSet`, `UsesPatchNameList`, `PatchMIDICommands`, `NoteNameList`, `ControlNameList`,
    `UsesControlNameList`, `ExtendingDeviceNames`, y las extensiones `midnam`/`middev`. La ruta no aparece como
    cadena literal.
- **Conclusión:** DP 11.36 lee de `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` (usuario, que los usa a diario, +
  ficheros instalados idénticos; D por las cadenas de DP). DP entiende `UsesControlNameList` (DTD 1.0), que
  CherryPicker 3.0 no lee: las listas de controles deberán escribirse en forma 1.0. Pendiente (A): si DP necesita
  `.middev` para un modelo, si lee `* copia` y si hay que reiniciarlo tras instalar.
- **Respuestas del usuario (2026-10-19) y captura** `captures/exp002/dp_bundles_midi_device_properties.png`:
  1. Los modelos sin `.middev` funcionan: en DP, *Bundles → MIDI Devices*, cada dispositivo (creado antes en
     Configuración de Audio MIDI, p. ej. M3000 con fabricante TC Electronic) tiene *MIDI Device Properties → Patches*
     con **Port** y **Master Names**, donde se elige el `.midnam` (`M3000`). DP muestra entonces la lista de bancos
     del fichero en su orden (`Top 20`, `Halls`, `Rooms`, `Plates`, `Gated Reverb`…) con una columna **Override**
     (`Default`) por banco. Ya hay dispositivos A/B por puerto para LXP-15 y LXP-15 II.
  2. `M3000.midnam copia` es un resto de pruebas del usuario.
  3. No recuerda si DP recarga solo; cree que hay que volver a elegirlo en *MIDI Device Properties*. Por probar.
- **Conclusión ampliada:** el `.middev` no es necesario para usar un `.midnam` (usuario + captura: A). Los nombres de
  `PatchBank` son lo que el usuario ve en DP, en el orden del fichero (A).

## EXP-003 · 2026-10-19 · Ida y vuelta sin pérdidas de los .midnam con MidnamKit (T-007)

- **Herramienta:** `src/MidnamKit` (`swift test`); lee **copias** de `reference/midnam_usuario/` en un directorio
  temporal, nunca los originales.
- **Procedimiento:** para cada ejemplo, leer → reescribir desde el árbol y desde el modelo tipado → comparar byte a
  byte con el original; contar elementos sin tipo y presets tipados. Tests sintéticos para estilo CherryPicker y MOTU,
  elemento desconocido, atributo extra, orden no canónico, documento nuevo y errores.
- **Resultado:** 8 tests, 0 fallos; compilación limpia sin avisos. Los 6 ejemplos salen **idénticos** desde el árbol
  y desde el modelo, con 0 elementos sin tipo. Presets: DSP-128 Plus 128, LXP-15 128, LXP-15 II 128, M3000 1112,
  PCM-81 900, PCM-91 800.
- **Conclusión:** formato de escritura de CherryPicker y de MOTU confirmado (B reproducido + D):
  `protocol/confirmed/midnam_formato_escritura.md`.

## EXP-004 · 2026-10-19 · Contraste con la DTD MIDINameDocument 1.0 (T-009)

- **Herramienta:** `curl` (descarga con permiso del usuario), lectura de la DTD, `swift test`.
- **Procedimiento:** midi.org ya no sirve `dtds/MIDINameDocument10.dtd` (404); se descarga la captura de Wayback del
  2003-08-22 (`id_`), 4498 bytes, igual a `x-archive-orig-content-length`, fechada en la propia DTD el 19-01-2003.
  Se guarda en `reference/dtd/` y se compara elemento a elemento con lo observado y con el modelo.
- **Resultado:** todo lo observado en los ejemplos es válido según la DTD. `Patch Number` es CDATA (etiqueta libre),
  `ProgramChange` opcional, `PatchBank Name` opcional, `ROM` por defecto false, `Available` por defecto true.
  Formas que el modelo no tipaba y la DTD permite: `ControlNameList` en línea en `ChannelNameSet`,
  `UsesControlNameList` por preset y `Control` sin `Type` (7bit por defecto). Añadidas a `Model.swift` con un test;
  9 tests, 0 fallos, los 6 ejemplos siguen idénticos.
- **Conclusión:** reglas de la DTD en `protocol/confirmed/midnam_formato_escritura.md` (D + B). La validación
  automática necesita `MIDIEvents10.dtd`, que la DTD incluye y no está descargada.

## EXP-005 · 2026-10-19 · Validación con xmllint contra la DTD 1.0 (T-011)

- **Herramienta:** `tools/validar_midnam.sh` (nuevo) + `tools/midnam_catalog.xml` (catálogo XML que resuelve las DTD
  de la MMA a `reference/dtd/`, sin red); `xmllint --valid --nonet` (libxml 2.9.13). Trabaja sobre copias temporales.
- **Procedimiento:** descarga con permiso de `MIDIEvents10.dtd` (incluida por la DTD 1.0; define `ControlChange`,
  `ProgramChange`…) desde Wayback, captura 2003-08-22, 6363 bytes = `x-archive-orig-content-length`. Validar los 6
  ejemplos, un fichero inválido a propósito y lo que escribe MidnamKit (tests `DTDValidationTests`).
- **Resultado:**
  - El DOCTYPE de CherryPicker (`PUBLIC "…1.0//EN" ""`) **no sirve para validar**: el identificador de sistema vacío
    hace que el validador cargue el propio documento como DTD («Content error in the external subset»). El de MOTU
    apunta a la DTD 0.7 de sonosphere.com. El script sustituye el DOCTYPE por el canónico de la 1.0 en la copia.
  - Los 6 ejemplos son **válidos** según la DTD 1.0. Un `ChannelNameSet` sin `PatchBank` se rechaza con el mensaje
    de la DTD.
  - El test detectó que la muestra sintética de estilo MOTU de los tests estaba incompleta (sin `CustomDeviceMode` ni
    `AvailableForChannels`); corregida. 11 tests, 0 fallos.
- **Conclusión:** lo que escribe MidnamKit se valida automáticamente contra la DTD 1.0 en cada `swift test` (D).
  Decisión pendiente para la app: escribir en los ficheros nuevos el DOCTYPE con la URL de midi.org (validable) en vez
  del `""` de CherryPicker; DP acepta ambos según EXP-002 (por confirmar con un fichero nuevo).

## EXP-006 · 2026-10-19 · Fichero nuevo de MidnamKit en DP 11.36 (T-012)

- **Herramienta:** `swift run midnam-prueba <salida> [versión]` (genera el fichero), `tools/validar_midnam.sh`;
  instalación con permiso del usuario en `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (carpeta nueva).
  Deshacer: borrar esa carpeta.
- **Fichero:** `captures/exp006/CP Prueba fichero.midnam` (versión 1, válido contra la DTD 1.0). Nombres distintos a
  propósito para saber cuál muestra DP: fichero «CP Prueba fichero», `Manufacturer` «Cherrypicker», `Model`
  «CP Prueba modelo», modo «CP Prueba modo». Contenido: DOCTYPE con la URL de midi.org; 4 bancos: A (CC0=0), B (CC0=1),
  «CP Agrupacion sin BS» (sin bank select) y «CP BS por preset» (`PatchMIDICommands` CC0=2 + PC); etiquetas `A01`…;
  `UsesControlNameList` «CP Controles» con CC7, CC12, CC13.
- **Preguntas:** (1) ¿Aparece y se puede elegir? (2) ¿Qué nombre sale en *Manufacturer*, *Model* y *Master Names*?
  (3) ¿Salen los 4 bancos en orden y los presets con su etiqueta? (4) ¿Se ven los nombres de controles en algún sitio
  (lista de controladores, lane de automatización)? (5) Recarga: con la versión 2 (nombres con « v2») instalada encima,
  ¿cambia sin reiniciar DP, al volver a elegirla, o solo al reiniciar?
- **Resultado parcial 1 (usuario, 2026-10-19):** para asignar nombres a un dispositivo externo nuevo hay que elegir
  *Manufacturer* y *Model*, que deben coincidir con el fichero; «Cherrypicker / CP Prueba modelo» **no aparece**.
  Causa observada: esos desplegables salen de los `.middev` (MIDIDeviceTypes), no de los `.midnam`. El M3000 se
  puede elegir porque `Digidesign Device List.middev` (raíz de `MIDI Devices/`) declara `TC Electronic / M3000`
  (y `Lexicon / LXP-15`); ningún `.middev` declaraba el modelo de prueba. Corrige EXP-002: el `.middev` **sí** hace
  falta para un modelo nuevo. Coherente con CherryPicker, que tenía editor de `.middev` (`MiddevEditor.nib`,
  `CPmiddevRead.plist`, `CP_middevMfgFolders`).
- **Corrección:** añadido `MOTU/Cherrypicker/Cherrypicker.middev` (MIDIDeviceTypes 0.3, formato de los de MOTU) con
  `Manufacturer="Cherrypicker" Model="CP Prueba modelo"`, efecto, recibe Program Change y Bank Select MSB/LSB. Copia en
  `captures/exp006/`. DP estaba abierto: hay que reiniciarlo para que lea el `.middev`.
- **Resultado parcial 2 (usuario + captura `captures/exp006/dp_master_names_prueba.png`):**
  - Con el `.middev`, en Configuración de Audio MIDI se elige fabricante «Cherrypicker» y modelo «CP Prueba modelo» y
    el dispositivo aparece en DP sin problema (A).
  - DP **acepta el fichero nuevo con el DOCTYPE de midi.org** (A).
  - *Master Names* muestra **«CP Prueba fichero»: el nombre del fichero** sin `.midnam`, no `Model` ni el modo (A).
  - *Patches* lista los 4 bancos por su nombre y en el orden del fichero, incluidos el banco sin bank select y el de
    bank select por preset (A).
  - El usuario recuerda haber escrito a mano fabricante y modelo de un aparato que no estaba en la lista y poder
    asignarle nombres igualmente: el `.middev` sería una comodidad (aparecer en la lista), no un requisito. Por
    confirmar.
- **Resultado parcial 3 (capturas `captures/exp006/dp_menu_presets.png`, `dp_menu_controladores.png`):**
  - Menú de presets de una pista: un submenú por banco, pero **con el nombre de la `PatchNameList`** («CP Lista A»…),
    no el del `PatchBank` («CP Banco A (CC0=0)», que solo sale en *MIDI Device Properties*). Cada preset se muestra
    como **«`Number` `Name`»** («B01 B preset 1») (A). En los ficheros de CherryPicker del usuario el nombre de cada
    lista es siempre igual al de su banco (M3000 23/23, LXP-15 5/5, LXP-15 II 2/2), por eso en DP coinciden.
  - Menú de controladores de la pista: nombres estándar (1 modulation, 2 breath, 7 volume, 64 Sustain…); **no
    aparecen** «CP Mezcla/Tiempo/Feedback» ni CC12/CC13. DP 11.36 no usa `ControlNameList` en ese menú (A); falta
    mirar «Other Controller…».
- **Recarga:** 2026-10-20 00:03:55, con DP abierto, instalada la versión 2 encima de la 1 (comprobado antes que la
  instalada era la 1 sin cambios). Copia en `captures/exp006/CP Prueba fichero v2.midnam`. Cambian los nombres de
  banco y de preset (sufijo « v2»); los nombres de las listas («CP Lista A»…) y del fichero no cambian.
- **Resultado de la recarga (usuario):** sin hacer nada, la pista sigue mostrando la versión 1 (DP **no** vigila el
  fichero). Al elegir otro fichero en *Master Names* y volver a «CP Prueba fichero», DP **carga la versión 2** sin
  reiniciar (A).
- **Conclusión:** DP 11.36 acepta ficheros nuevos de MidnamKit (DOCTYPE de midi.org incluido); *Master Names* = nombre
  de fichero; menú de presets = nombre de la `PatchNameList` + «Number Name»; un modelo nuevo necesita `.middev` para
  salir en la lista de Audio MIDI; tras guardar, basta con volver a elegir el fichero en *Master Names*. Queda
  «Other Controller…» para los controles con nombre.
- **Estado:** COMPLETADO salvo «Other Controller…». 2026-10-20: a petición del usuario, `MOTU/Cherrypicker/` retirada
  de `/Library/Audio/MIDI Devices/` (movida a la Papelera como «Cherrypicker (prueba T-012)»); copias idénticas en
  `captures/exp006/`. El dispositivo «CP Prueba modelo» de Audio MIDI/DP lo borra el usuario si quiere.

## EXP-007 · 2026-10-20 · Esqueleto de la app AppKit abre un `.midnam` (T-015)

- **Entorno:** macOS 15.7.9 (24G830), Xcode 26.3, Swift 6.2.4, commit de este EXP.
- **Comandos:** `cd src/CherryPickerApp && swift test` → 1 test, 0 fallos. `tools/empaquetar_app.sh` → compila sin
  avisos y monta `build/CherryPicker.app`. `open -a build/CherryPicker.app "captures/exp006/CP Prueba fichero.midnam"`.
- **Observado:** `mdls` da a los `.midnam` el tipo `com.apple.traditional-mac-plain-text` (no hay un tipo propio en el
  sistema); por eso la app los reconoce por extensión (`MidnamDocumentController`). La app arranca, abre el fichero y
  muestra la ventana con las pestañas MIDI / Device / Patch Banks / Controllers / Categories y la tabla P · S0 · S32 ·
  Patch Bank · # · Channel Set con los 4 bancos: A 0/0 10, B 1/0 10, «CP Agrupacion sin BS» -/- 5, «CP BS por preset»
  -/- 5, todos en «CP Juego». Recuentos contrastados con `awk` sobre el fichero (10, 10, 5, 5). Captura de la ventana
  (solo esa ventana): `captures/exp007/ventana_patch_banks.png`. Primer intento: la ventana salía a 560×360 (tamaño
  mínimo del contenido); corregido fijando el tamaño tras asignar el contenido.
- **No probado:** guardar (no se editó nada; la ida y vuelta la cubren los tests de MidnamKit), Preview, el panel Open.
- **Estado:** COMPLETADO.

## EXP-008 · 2026-10-20 · Pestaña Patch Banks editable, prueba interactiva (T-016)

- **Entorno:** macOS 15.7.9, Swift 6.2.4; commits ad79cdc y e738d6d. Fichero: copia de
  `captures/exp006/CP Prueba fichero.midnam` en el scratchpad (`Prueba T-016.midnam`).
- **Comandos:** `cd src/CherryPickerApp && swift test` → 16 tests, 0 fallos (incluye validación DTD de un fichero
  editado con varias operaciones). `tools/empaquetar_app.sh`; la app abierta con la copia.
- **Compilación:** Swift 6.2.4 en `-c release` se cae («Owned function parameter without lifetime ending uses»,
  `CopyPropagation`) al convertir `[[NSButton]]` en `[[NSView]]` con `+` dentro de un `init` de subclase; se evita
  construyendo el array `[[NSView]]` explícitamente (`BankSheets.swift`).
- **Resultado (usuario):** renombrar, hoja Bank Selects, + / −, arrastrar, deshacer/rehacer y Preview funcionan.
  Dos fallos, corregidos en e738d6d y comprobados de nuevo por el usuario: el título de la caja de las hojas tapaba la
  primera fila; el doble clic en el nombre solo funcionaba la primera vez (la tabla se recargaba durante el fin de
  edición).
- **Guardar (usuario, ⌘S):** `tools/validar_midnam.sh` → VÁLIDO. `diff` con el original: solo los dos bancos
  renombrados («CP Banco Aa…», «CP Banco Ba…»), con su `UsesPatchNameList` y su `PatchNameList` renombradas igual (P2),
  y CC0 del banco A de 0 a 5. Nada más cambia (orden, sangría, resto de bancos y presets).
- **No probado:** popup de Channel Set con varios juegos (el fichero solo tiene uno), DP.
- **Estado:** COMPLETADO (salvo lo no probado).

## EXP-009 · 2026-10-20 · Hoja Bank Selects y ventanas en CherryPicker 3 original (T-017)

- **Entorno:** CherryPicker 3 en Snow Leopard, Mac mini antiguo del usuario; prueba hecha por el usuario siguiendo el
  procedimiento de la sesión. Análisis aquí: `diff`, `swift test` (commit de este EXP).
- **Ficheros:** `captures/exp009/` (sintéticos, fabricante «360 Systems», modelo «MIDIBass», presets sin nombre):
  `BS base.midnam` con banco «normal» (CC0=1, CC32=0, presets en forma corta) y banco «custom» sin bank select, con dos
  presets con CC0/CC32 propios y uno sin (`PatchMIDICommands` con solo `ProgramChange`); `BS opcion1/2/3.midnam`: la
  hoja Bank Selects sobre «custom» con B Sel 0 = 5, B Sel 32 = 0 y cada opción. Capturas (19, se ven carpetas del
  usuario): `reference/capturas_snow_leopard/` (no versionado).
- **Resultado (B):**
  - Las tres opciones ponen `MIDICommands` CC0=5/CC32=0 al banco.
  - «Apply to all patches»: todos los presets pasan a la forma corta `ProgramChange="n"`, también el que no tenía bank
    select.
  - «Apply ONLY to patches without Bank Selects»: el preset con solo Program Change recibe CC0=5/CC32=0 propios; los
    que tenían los suyos no cambian. (Lo deducido en T-016 era «solo cambia el banco»: **corregido**.)
  - «Apply Only to patches with Bank Selects»: los presets con CC propios pasan a 5/0; el otro no cambia.
  - Un preset con «-» en un banco sin bank select se escribe como `PatchMIDICommands` con solo `ProgramChange`.
  - Nada más cambia en el fichero. Sin observar: la opción 2 con presets en forma corta.
- **Contraste:** `BankEditingTests.testBankSelectOptionsMatchOriginal` carga `BS base.midnam`, aplica cada opción con
  `setBankSelect` y reproduce byte a byte los tres ficheros del original (17 tests, 0 fallos).
- **Interfaz (capturas, B):** ventana de documento alta y estrecha; arriba «Save Format», «XML Filters...» y «Preview»;
  en Patch Banks los botones van **encima** de la tabla (+ − Merge Sibelius Zap Dups Zap Custom Import Find) con la
  leyenda a la derecha (• Normal negro, • Empty rojo, • Mixed azul: color del nombre del banco; «custom» sale en azul);
  debajo, «Bank Initialization» y «Transmit». La columna P es un botón cuadrado. Add a Single Bank: Name; «B Sel0» y
  «B Sel32» en una fila; Channel Set. Bank Selects: «B Sel 0» y «B Sel 32» arriba con Cancel/OK a la derecha y las tres
  opciones debajo. El asistente se llama «New Device Setup Assistant». La ventana de búsqueda se titula «CPPatch Finder».
  Zap Dups pide confirmación con un aviso. Import: «Files You Can Import From», «Available Patch Lists», «Type», «#»,
  «Select Destination Bank», «Set midnam folder...».
- **Estado:** COMPLETADO.

## EXP-010 · 2026-10-20 · Varios Channel Sets y cambio múltiple por cabecera (T-016)

- **Entorno:** macOS 15.7.9, Swift 6.2.4; commit de este EXP.
- **Fichero propio:** `captures/exp010/Prueba canales.midnam` (escrito para la prueba, estilo CherryPicker):
  «Melodicos» (canales 1–9 y 11–16) con Pianos 0/0, Cuerdas 0/1, Sintes 1/0; «Bateria» (canal 10) con Kits 2/0 y
  Kits extra 2/1; 3 presets por banco. `tools/validar_midnam.sh` → VÁLIDO.
- **Tests:** `swift test` → 20 tests, 0 fallos; `testTwoChannelSetsFile` (se lee, se reescribe idéntico y se mueven
  dos bancos a «Bateria») y `testMoveSeveralBanks` (varios bancos a la vez; error y sin cambios si un Channel Set
  quedaría vacío).
- **App:** abre una copia y muestra los 5 bancos con su Channel Set en el popup (captura en la sesión).
- **Interfaz nueva (sin probar a mano todavía):** con bancos seleccionados, clic en la cabecera S0/S32 → hoja Bank
  Selects aplicada a todos; clic en la cabecera Channel Set → hoja con popup de Channel Set (su aspecto en el original
  no se ha visto: deducido del manual).
- **Prueba a mano (usuario, sobre una copia):** al principio el cambio múltiple solo cambiaba un banco: el clic en la
  cabecera seleccionaba la columna y quitaba la selección de filas; corregido con `allowsColumnSelection = false`.
  Añadido P8 (popup de una fila seleccionada cambia todas las seleccionadas). Tras el arreglo, cambian todos a la vez
  (popup y cabeceras). Al cambiar de Channel Set el banco pasa al final del grupo de destino: **el original hace lo
  mismo** (usuario, Snow Leopard).
- **Estado:** COMPLETADO.

## EXP-011 · 2026-10-20 · Fichero editado con la app, en DP 11.36 (T-016)

- **Entorno:** macOS 15.7.9, DP 11.36 abierto; app en el commit bdf93f5.
- **Fichero:** copia de `captures/exp010/Prueba canales.midnam` editada y guardada **por el usuario con la app**
  (renombrar, Bank Selects, cambiar Channel Set): `captures/exp011/Prueba canales.midnam`, `tools/validar_midnam.sh` →
  VÁLIDO. Resultado: «Melodicos» (canales 1–9, 11–16) con Kits 2/0; «Bateria» (canal 10) con Kits extra 2/1,
  Pianos CP 4/0 (lista renombrada con el banco), Cuerdas 5/0 y Sintes 1/0. `.middev` para `Cherrypicker / CP Canales`:
  `captures/exp011/Cherrypicker.middev` (el de EXP-006 con otro modelo).
- **Instalación (permiso del usuario, 2026-10-20):** carpeta nueva `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` con
  los dos ficheros (`cmp` idéntico). **Deshacer:** borrar esa carpeta (o moverla a la Papelera).
- **Preguntas:** (1) ¿Aparece «CP Canales» tras reiniciar DP? (2) ¿*Master Names* muestra «Prueba canales»? (3) ¿Salen
  los bancos con los nombres editados y en el orden del fichero? (4) ¿Los bancos dependen del canal (canal 10: los de
  «Bateria»; otros: «Kits»)?
- **Resultado (usuario, capturas `captures/exp011/dp_*.png`, A):**
  1. Tras reiniciar DP, el dispositivo «CP Canales» (Cherrypicker / CP Canales) se crea y DP lo muestra.
  2. *MIDI Device Properties ▸ Patches*: *Master Names* «Prueba canales»; lista los 5 bancos (Kits, Kits extra,
     Pianos CP, Cuerdas, Sintes) con «Override: Default».
  3. Pista en el **canal 10**: menú con los 4 bancos de «Bateria» en el orden del fichero (Kits extra, Pianos CP,
     Cuerdas, Sintes), con los nombres editados; cada uno abre «Number Name» (`001 Kits extra 1`…).
  4. Pista en el **canal 1**: solo los presets de «Kits», **sin submenú de banco** (un solo banco en ese Channel Set).
  **DP respeta los Channel Sets por canal** y lee sin problemas lo que escribe la app.
- **Estado:** COMPLETADO. Instalación sin retirar todavía (ver «Deshacer»).

## EXP-012 · 2026-10-21 · Patches nuevos y pegados en CherryPicker 3 original (T-018)

- **Entorno:** CherryPicker 3 en Snow Leopard, Mac mini antiguo del usuario; prueba hecha por el usuario. Análisis
  aquí: `grep` de los ficheros guardados, `tools/validar_midnam.sh`.
- **Ficheros:** `captures/exp012/` (sintéticos, presets sin nombre o «uno», «dos», «tres»). `prueba2.midnam`
  (360 Systems / MIDIBass): banco «sin bank sel» y banco «con bank sel0=0 sel32=0» (S0/S32 = `-` en Patch Banks; el
  0/0 está solo en los patches), 9 patches en cada uno: pegar 3 líneas, + ×3 con la casilla, + ×3 sin ella.
  `Prueba3.midnam` (documento nuevo, Prueba / Prueba): banco «prueba» creado con la hoja Add a Single Bank con
  B Sel 0 = 5, B Sel 32 = 0; en su lista, + ×2 con la casilla, + ×2 sin ella, pegar 2 líneas con la casilla, pegar 2
  líneas sin ella. Capturas: `reference/capturas_snow_leopard/exp012_23…26.tiff` (no versionadas; se ven carpetas del
  usuario).
- **Resultado (B):**
  - Hoja New Patches al pegar: «Start At» 0, «Start Ascii» 001, delimitador End of line / Comma / Quote / Tab. Los
    patches se insertan en la posición seleccionada.
  - Cada patch nuevo: `Number` = Ascii (`001`, `002`…, la columna Ascii) y Program Change = Start At + i (la columna
    `#`). Los de + llevan `Name=""`.
  - Banco sin bank select (y sin patches con bank select propio): todo en forma corta `ProgramChange="n"`, con o sin la
    casilla.
  - «prueba2», banco «con bank sel…» (S0/S32 `-`): con la casilla, CC0/CC32 propios 0/0; sin ella, `-`
    (`PatchMIDICommands` con solo Program Change). De dónde sale el 0/0 sin bank select de banco: sin aclarar.
  - «Prueba3», banco con 5/0 de banco: + con y sin la casilla dan 5/0 **propios**; pegar con la casilla da `-`; pegar
    sin ella da **1/1** (en la primera prueba del usuario también salieron B0 1 · B32 1 al pegar). La casilla no se
    comporta de forma coherente entre + y pegar.
  - En cuanto los patches de un banco tienen bank select distintos, el banco pasa a `-` en S0/S32, sale en azul
    («Mixed») y **se guarda sin `MIDICommands`**: cada patch lleva los suyos.
  - El original guarda Channel Sets sin `PatchBank` y con el nombre repetido («New Channel Set» ×2): `prueba2.midnam`
    **no valida** contra la DTD (`PatchBank+`). DOCTYPE con identificador de sistema vacío (`""`).
  - Al guardar con un fabricante/modelo nuevos («Prueba / Prueba») aparece «New Device Setup Assistant»: crea un
    `.middev` con valores por defecto (carpeta no vista), ofrece abrir Configuración de Audio MIDI y pregunta «Do all
    patch banks play on all channels?» (Yes/No). Relacionado con P3.
- **Conclusión:** el comportamiento de «Set Bank Selects to Bank values» en el original es incoherente; no se
  reproduce tal cual (regla propia a acordar con el usuario en `docs/20`, T-018). Sí se reproduce: Start At / Start
  Ascii, delimitadores, inserción en la selección, `Number` = Ascii.
- **Estado:** COMPLETADO.

## EXP-013 · 2026-10-22 · Prueba a mano de la ventana Patch Names (T-018)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` del commit `92fad61` (`tools/empaquetar_app.sh`).
  Fichero: copia de `captures/exp012/Prueba3.midnam` en el scratchpad (sintético). Prueba hecha por el usuario con la
  lista de la ficha de T-018.
- **Resultado (A, observado por el usuario):**
  - La ventana del banco se abría en otra pantalla (se colocaba en coordenadas fijas de la pantalla).
  - Las celdas solo se editaban manteniendo el clic; el doble clic no editaba.
  - Al borrar el valor de B0/B32 daba error en vez de quedar «-».
  - El resto de la lista (+, pegar, −, Renumber, ordenar, Find, arrastrar, deshacer) «parece ok».
- **Corrección (sin volver a probar en la app):** la ventana se abre a la derecha de la principal, en su pantalla y en
  cascada (o encima si no cabe); doble clic edita la celda; un bank select vacío es «-» (patches y hojas de banco;
  test nuevo, 37/37).
- **Segunda prueba** (app de `1294be0`): el usuario confirma las tres correcciones («todo parece ok»). Pide que Tab
  no salga de la tabla al final de la fila → P10 (Tab / ⇧Tab saltan de fila, ↑ / ↓ cambian de patch al editar),
  hecha sin probar en la app. Pide también ← / → entre columnas: añadidas a P10 (solo con el cursor en el borde
  del texto, para no perder el movimiento del cursor dentro de la celda).
- **Tercera prueba** (app de `341c2b4`): P10 en la lista de patches confirmada por el usuario («mucho más cómodo»).
  Pide lo mismo en Patch Banks: Tab / ↓ y ⇧Tab / ↑ entre nombres de banco (única columna que se escribe), sin probar.
- **Cuarta prueba** (app de `53ff646`): P10 en Patch Banks confirmada por el usuario («todo ok»). Fichero guardado
  por el usuario (14 patches): `tools/validar_midnam.sh` → VÁLIDO.
- **Conclusión:** la ventana Patch Names y P10 funcionan en la app según el usuario; el fichero que escribe es válido.
  Queda abrirlo en DP 11.36.
- **Instalación para DP** (permiso del usuario, 2026-10-22): `captures/exp013/Prueba patches.midnam` = el fichero
  guardado con Manufacturer/Model cambiados a `Cherrypicker` / `CP Patches` (solo esas dos etiquetas; VÁLIDO) y
  `captures/exp013/Cherrypicker.middev` = el de EXP-011 más el modelo «CP Patches», copiados a
  `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (`cmp` idéntico). Bancos «pruebassss» (sin bank select; patches
  con 5/5, 5/-, 5/0, 1/1, «-» y forma corta) y «pp» (5/5). **Deshacer:** borrar `Prueba patches.midnam` y volver a
  copiar `captures/exp011/Cherrypicker.middev` (o borrar la carpeta entera, con lo de EXP-011).
- **Preguntas para DP:** (1) tras reiniciar DP, ¿sale «CP Patches»? (2) ¿*Master Names* muestra «Prueba patches»?
  (3) ¿Los bancos y la lista de patches salen con los nombres y en el orden del fichero?
- **Resultado en DP 11.36 (A, usuario con capturas):** tras reiniciar, el dispositivo «CP Patches» (Cherrypicker /
  CP Patches) se crea; *Master Names* = «Prueba patches»; bancos «pruebassss» y «pp». Los menús muestran los patches
  en el orden del fichero (el que dejó ordenar por cabecera), como «Number Name»: 9 en «pruebassss» y 5 en «pp»; los
  patches sin nombre salen solo con su Number («002», «003»).
- **Conclusión:** T-018 verificada: lo que escribe la ventana Patch Names lo lee DP tal cual.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-014 · 2026-10-23 · Prueba a mano de Merge, Find y Zap Dups (T-019)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` del commit `53b453b` más los arreglos de abajo
  (`tools/empaquetar_app.sh`). Fichero: copia de `Prueba3_exp013.midnam` (sintético). Prueba hecha por el usuario.
- **Primera prueba:** el Finder no mostraba nada al escribir. Arreglo: la búsqueda se relanza también con cada cambio
  del texto (`controlTextDidChange`, como el Find de la lista de patches). Aclarado: Find busca nombres de patch, no
  de banco (manual del original).
- **Segunda prueba:** «Todo parece funcionar bien» (usuario), salvo que la columna «Ascii» de la lista de patches salía
  recortada al abrir (captura del usuario). Causa: las columnas suman más que la tabla al crearse la ventana. Arreglo:
  `sizeToFit` tras colocar la tabla, ventana a 520 de ancho; en el Finder lo mismo (600 de ancho, solo «Patch Name»
  se estira).
- **Tercera prueba:** columnas bien al abrir («Perfecto ahora», usuario).
- **Zap Dups solo borraba de uno de los bancos de origen** (usuario). Causa deducida, sin reproducir con su fichero: el
  otro banco de origen no tenía bank select y la regla lo toma por Custom Bank (no se borra de él). Acordado con el
  usuario → P12: con bancos seleccionados se conservan esos y se borra de todos los demás de su Channel Set (2 tests,
  49/49); sin probar aún en la app.
- **Conclusión:** Merge, Find y Zap Dups funcionan en la app según el usuario. Queda abrir en DP 11.36 un fichero con
  un Custom Bank tras Zap Dups (EXP-015).
- **Estado:** COMPLETADO.

## EXP-015 · 2026-10-23 · DP 11.36 con un fichero tras Find y Zap Dups (T-019)

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; CherryPickerCore del commit `74af700`.
- **Ficheros** (`captures/exp014/`, sintéticos, VÁLIDOS con `tools/validar_midnam.sh`): `Prueba zap base.midnam`
  (Cherrypicker / CP Zap; banco «ROM A», 0/0, 8 patches en forma corta), `Prueba zap sin zap.midnam` (= base + Find
  «piano» y «rhodes» → «Add New Bank With Patches» «Mis Pianos» sin bank select, 3 patches con 0/0 propios) y
  `Prueba zap.midnam` (= lo anterior + Zap Dups: 3 borrados de «ROM A», que queda con 5). Generados con la lógica de
  la app (test temporal, no versionado). `Cherrypicker.middev` = el de EXP-013 + el modelo «CP Zap».
- **Instalación** (permiso del usuario, 2026-10-23): copiar `Cherrypicker.middev` y `Prueba zap.midnam` a
  `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (la copia la hace el usuario: el modo automático no dejó a Claude
  sobrescribir el `.middev`). **Deshacer:** borrar `Prueba zap.midnam` y volver a copiar
  `captures/exp013/Cherrypicker.middev`.
- **Preguntas para DP:** (1) tras reiniciar DP, ¿sale «CP Zap»? (2) ¿*Master Names* muestra «Prueba zap» con «ROM A»
  (5 patches) y «Mis Pianos» (3)? (3) Al elegir un patch de «Mis Pianos», ¿se queda en ese banco?
- **Resultado (A, capturas del usuario):** el usuario copió los dos ficheros (`cmp` idénticos). DP muestra el
  dispositivo «CP Zap» con *Master Names* «Prueba zap» y los bancos «ROM A» y «Mis Pianos»; el menú de la pista da
  «Mis Pianos» → «001 Grand Piano», «002 Bright Piano», «004 Rhodes», y tras elegir Grand Piano el menú marca «Mis
  Pianos» y ese patch. «Todo ok» (usuario).
- **Segunda prueba, sin Zap Dups** (pedida por el usuario): Claude copia `Prueba zap sin zap.midnam` (fichero nuevo,
  `cmp` idéntico) a la misma carpeta; el usuario lo elige en *Master Names*, elige «Mis Pianos ▸ Grand Piano» y al
  volver al menú DP marca «ROM A»: «no recuerda MIS PIANOS y se va al ROM A» (usuario, A).
- **Conclusión:** DP 11.36 lee bien un Custom Bank hecho con Find y un fichero tras Zap Dups, y **el fallo que describe
  el manual del original existe en DP 11.36**: con el mismo sonido (bank select + Program Change) en dos bancos, DP
  muestra el de fábrica aunque se eligiera desde el Custom Bank. Zap Dups lo evita (primera prueba).
- **Tercera prueba, orden de los bancos** (hipótesis de Claude: DP se queda con el primer banco del fichero que tiene el
  sonido): `Prueba zap orden.midnam` = «sin zap» con «Mis Pianos» delante de «ROM A» (VÁLIDO; copiado por Claude con
  permiso del usuario, `cmp` idéntico). Resultado (usuario, A): «siempre se va a ROM A al abrir y cerrar».
  **Hipótesis descartada:** el orden no influye. Deducido, sin probar: DP parece preferir el banco cuyo bank select
  de banco (`MIDICommands`) coincide con el del patch, y «Mis Pianos» no lleva bank select de banco.
- **Estado:** COMPLETADO. Instalación sin retirar: también `Prueba zap sin zap.midnam` y `Prueba zap orden.midnam`
  (deshacer: borrarlos).

## EXP-016 · 2026-10-23 · Pestaña Device en la app y en DP (T-020)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` del commit `d9e30cf`. Fichero: copia de
  `captures/exp011/Prueba canales.midnam` en el scratchpad (sintético). Prueba hecha por el usuario con la lista de la
  sesión (disposición, Active Channels, + / − de Channel Sets con Reassign Banks To, modos, renombrar, deshacer).
- **Resultado en la app (A, usuario):** «parece que todo está correcto».
- **Fichero para DP:** `captures/exp016/Prueba device.midnam` (generado con la lógica de la app, test temporal no
  versionado; VÁLIDO): mismo dispositivo que EXP-011 (Cherrypicker / CP Canales), «Melodicos» 1-8, «Bateria» 10,
  «Bajos» 11-12 (nuevo, con «New Bank» vacío y «Kits extra»); canales 9 y 13-16 **libres** (sin
  `ChannelNameSetAssign`).
- **Preguntas para DP:** (1) ¿*Master Names* muestra «Prueba device»? (2) Canal 11: ¿bancos «New Bank» y «Kits extra»?
  (3) Canal 1: ¿solo «Kits»? (4) Canal 9 o 13 (libres): ¿qué muestra DP?
- **Instalación** (permiso del usuario, 2026-10-23): Claude copia `Prueba device.midnam` a
  `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (fichero nuevo, `cmp` idéntico). **Deshacer:** borrarlo.
- **Resultado en DP 11.36 (A, capturas del usuario):** (1) *Master Names* «Prueba device» con los 6 bancos (Kits,
  Pianos CP, Cuerdas, Sintes, New Bank, Kits extra). (2) Canal 11: solo «Kits extra» → 001–003; **el banco vacío no
  sale en el menú**. (3) Canal 1: presets de «Kits» sin submenú. (4) Canal 9 (libre): «No Patches».
- **Conclusión:** DP acepta modos con canales sin asignar (los muestra como «No Patches») y Channel Sets nuevos; un
  banco vacío (P13) no estorba en el menú.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-017 · 2026-10-23 · Audición a un destino MIDI virtual (T-021)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` del commit `7f3b42a`. Fichero: copia de
  `captures/exp011/Prueba canales.midnam` en el scratchpad. Destino: «CP Monitor», destino CoreMIDI virtual creado por
  Claude en el scratchpad (`captures/exp017/monitor_main.swift`) que solo anota lo que recibe. **Ningún módulo real.**
- **Procedimiento (usuario):** MIDI ▸ Device Out «CP Monitor» ▸ Enable MIDI; clic y flechas en patches de «Kits»
  (Channel Set Melodicos, canal 1; banco 2/0) y «Kits extra» (Bateria, canal 10; banco 2/1); después Device ▸ Bateria
  ▸ Audition Ch 11 y más clics en «Kits extra».
- **Resultado (A, `captures/exp017/recibido.log`):** 48 mensajes, en grupos de tres: `B0 00 02`, `B0 20 00`, `C0 0n`
  (Kits, canal 1); `B9 00 02`, `B9 20 01`, `C9 0n` (Kits extra, canal 10); `BA 00 02`, `BA 20 01`, `CA 0n` (canal 11
  tras cambiar Audition Ch). Program Change 0–2 según el patch. Solo CC0, CC32 y Program Change; nada más.
- **CPU:** `top` con la app abierta en reposo (cliente CoreMIDI creado): 0,0 %.
- **Conclusión:** la audición envía exactamente lo previsto (D-002, regla 4), en el canal del Channel Set o en el
  Audition Ch elegido. Falta probarla con un módulo real (con permiso del usuario).
- **Estado:** COMPLETADO.

## EXP-018 · 2026-10-23 · Audición con un módulo real: TC Electronic M3000 (T-021)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` del commit `7f3b42a`. Módulo: multiefectos
  TC Electronic M3000 en la Unitor8, puerto 1 (elegido por el usuario, con su permiso). Fichero: copia en el
  scratchpad del `M3000.midnam` del usuario (carpeta de DP; el original no se toca ni se versiona): 3 canales
  («Engine 1-2» 1-2, «Combined» 3) y 23 bancos con bank select por banco o por preset.
- **Al empezar:** la Unitor8 no salía entre los destinos de CoreMIDI que veía Claude (solo IAC, «Network …» y FW-1884);
  tenía el USB desconectado. Cadena (usuario): Unitor8 → USB → MU4 → USB → Mac; al reconectarla, aparece en «Device Out».
- **Procedimiento (usuario):** MIDI ▸ Device Out = puerto de la Unitor8 ▸ Enable MIDI; con audio por el M3000, abrir
  bancos y seleccionar presets. Solo se envían CC0/CC32 y Program Change (EXP-017).
- **Resultado (A, usuario):** «Todo perfecto»: el M3000 cambia al preset seleccionado.
- **Conclusión:** la audición sirve con un aparato real; no se envía nada más que el cambio de preset (D-002).
- **Estado:** COMPLETADO.

## EXP-019 · 2026-10-23 · Import en la app (T-022)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` de `8f70157` y los arreglos de abajo. Fichero:
  copias de `captures/exp016/Prueba device.midnam` en el scratchpad; carpeta de importación por defecto
  `/Library/Audio/MIDI Devices/MOTU/Cherrypicker` (6 `.midnam` de prueba; solo se leen). Prueba hecha por el usuario.
- **Primera prueba:** columnas del Importer cortadas; y «New Bank» como destino llenó el banco existente «New Bank»
  (creado en EXP-016, P13) en vez de crear «ROM A»: dos entradas con el mismo título. Arreglos (`0a3fdd0`): columnas
  al ancho de su texto; la opción pasa a «Add as New Bank» y los bancos se identifican por `representedObject`.
- **Segunda prueba** (captura del usuario): «Ahora sí aparece ROM A», pero la tabla de ficheros (36 % fijo) cortaba
  «Type». Arreglo (`736c531`): la tabla toma el ancho de sus columnas y la hoja crece si hace falta.
- **Tercera prueba:** «Ahora sí» (usuario).
- **Desde aquí:** Claude ve las ventanas de la app con `tools/capturar_app.sh` (solo las de CherryPicker; permiso del
  usuario). Probado: captura de la ventana del documento.
- **Conclusión:** Import funciona en la app (llenar un banco existente y crear uno nuevo con «Add as New Bank»).
- **Estado:** COMPLETADO.

## EXP-020 · 2026-10-23 · Asistente Device Setup y pestaña Device en la app (T-023)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` de `205cc79` y los arreglos de abajo. Prueba
  hecha por el usuario; Claude mira con `tools/capturar_app.sh` (solo ventanas de CherryPicker).
- **Primera prueba:** ⌘N → asistente → «TC Electronic» / «INVENT» (sin `.middev`), No, 2 grupos → Go → guardado como
  «borrar» (carpeta del usuario). Captura: Patch Banks con «New Bank» (Presets) y «New Bank 2» (Drums), vacíos;
  lista de patches vacía. Fallos (usuario): el autocompletado no admitía minúsculas y el desplegable era corto.
  Arreglo (`f9b8bca`): fuente de datos propia sin distinguir mayúsculas, 16 filas, y al avanzar se escribe como en el
  `.middev`.
- **Pestaña Device** del fichero (capturas): Mode 1; Presets 1-9, 11-16 (Audition Ch 1); Drums 10 (10); + desactivado
  con «(Add disabled…)». A petición del usuario (`912fc26`): Manufacturer y Model en recuadros separados (parecían un
  solo nombre) y barras de desplazamiento solo cuando hacen falta; confirmado en captura.
- **Segunda prueba:** «las minúsculas funcionan» (usuario).
- **Pedido del usuario** (dos pantallas): que la ventana se abra donde se dejó. Hecho: la ventana de documento guarda
  su sitio y pantalla (en cascada si hay otra; centrada si esa pantalla ya no está), el asistente recuerda el suyo y
  el Finder se abre junto al documento (`07acda2`). Probado por el usuario (mover a la otra pantalla, ⌘Q, reabrir):
  «todo funciona».
- **Estado:** COMPLETADO.

## EXP-021 · 2026-10-23 · ¿Necesita DP la entrada del `.middev`? (para T-024)

- **Pregunta:** EXP-006 dejó por confirmar si un modelo que no está en ningún `.middev` se puede usar en DP escribiendo
  a mano fabricante y modelo. De ello depende si «Instalar en DP…» (P3) tiene que escribir en un `.middev`.
- **Fichero:** `captures/exp021/Prueba sin middev.midnam`, creado con la lógica del asistente (test temporal no
  versionado; VÁLIDO): Cherrypicker / «CP Sin middev», banco «Banco SM» con «SM uno/dos/tres» (PC 0–2). `grep` de
  «CP Sin middev» en `/Library/Audio/MIDI Devices`: en ningún `.middev`.
- **Instalación** (permiso del usuario, 2026-10-23): Claude lo copia a `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/`
  (fichero nuevo, `cmp` idéntico). **Deshacer:** borrarlo.
- **Preguntas para DP:** (1) ¿Se puede crear el dispositivo escribiendo a mano «Cherrypicker» / «CP Sin middev»?
  (2) ¿*Master Names* ofrece «Prueba sin middev»? (3) ¿Sale «Banco SM» con sus 3 presets en la pista?
- **Resultado (A, capturas del usuario):** el desplegable de modelos de DP no ofrece «CP Sin middev» (solo lista lo de
  los `.middev`). En Configuración de Audio MIDI sí se puede escribir a mano: con un modelo distinto («CP Sin middev a
  mano») *Master Names* solo da «Default Names» / «General MIDI»; con el modelo **exacto** («CP Sin middev»), tras
  reiniciar DP, *Master Names* = «Prueba sin middev», banco «Banco SM» y en la pista «001 SM uno», «002 SM dos»,
  «003 SM tres».
- **Conclusión:** la entrada del `.middev` **no es necesaria** para que DP use un `.midnam`; basta con que fabricante y
  modelo del dispositivo coincidan exactamente con los del fichero. El `.middev` es una comodidad: que el modelo salga
  en los desplegables. Corrige la fila de `PROTOCOL_INDEX` (EXP-006). El usuario prefiere que «Instalar en DP…» lo
  cree igualmente (opcional).
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-022 · 2026-10-23 · «Install in DP…» (T-024)

- **Entorno:** macOS 15.7.9, Mac del proyecto; `build/CherryPicker.app` de `7f55a86` y `a610111`. Documento nuevo del
  asistente: Cherrypicker / «CP Instalar», todos los canales (un banco vacío). Prueba hecha por el usuario; Claude
  mira con `tools/capturar_app.sh` y comprueba los ficheros.
- **Primera vista de la hoja** (captura): más ancha que la ventana (título de la casilla largo), nombre propuesto
  «Untitled» y «Device: Cherrypicker CP Instalar» en una línea. Arreglo (`a610111`): casilla corta con nota aparte,
  fabricante y modelo en dos filas, nombre propuesto = modelo. ⌘I pareció no responder una vez: con la ventana del
  documento activa, sí (el atajo va a la ventana activa).
- **Segunda vista** (captura): correcta salvo la carpeta, cortada en «…/MOTU/» (la segunda línea no se veía); arreglo
  posterior: ruta en una línea.
- **Instalación** (pulsada por el usuario; permiso, 2026-10-23): aviso final con lo hecho y cómo deshacerlo. Ficheros
  en `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/`: `CP Instalar.midnam` (VÁLIDO) y `Cherrypicker
  (CherryPicker).middev` nuevo con «Cherrypicker / CP Instalar»; `Cherrypicker.middev` sin tocar; sin copias de
  seguridad (no se sustituyó nada). **Deshacer:** borrar esos dos ficheros.
- **Resultado en DP 11.36 (A, capturas del usuario, tras reiniciar DP):** el desplegable de modelos de «Cherrypicker»
  ofrece CP Canales, **CP Instalar**, CP Patches y CP Zap (DP junta los dos `.middev` de la carpeta); con «CP
  Instalar», *Master Names* = «CP Instalar» y el banco «New Bank».
- **Conclusión:** «Install in DP…» deja el fichero listo para DP, y el `.middev` propio hace que el modelo salga en
  la lista sin escribirlo a mano. Un segundo `.middev` en la misma carpeta no estorba.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-023 · 2026-10-23 · M3000: bancos de usuario e instantáneas por MIDI (consulta aledaña)

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36. Fuentes: manual del M3000 (español e inglés) y
  «M3000 MIDI specification» v1.01 de TC (firmware 2.03), en `incoming/` (no versionado). Fichero de partida:
  `reference/midnam_usuario/M3000.midnam` (privado, D-004), sin tocar.
- **Lo que dicen las fuentes (B, documentación del fabricante):** 500 sencillos y 100 combinados de fábrica; 250
  sencillos y 50 combinados de usuario (RAM 1: 1–128, RAM 2: 129–250). Con *Program Bank Change = External*, el CC0
  desplaza el Program Change en 128 × CC0. Numeración de la especificación: sencillos de fábrica 1–512, de usuario
  513–768, de tarjeta 769–1024; combinados de fábrica 1–128, de usuario 129–256, **instantáneas 257–384**, de tarjeta
  385–512. El manual no dice que las instantáneas se carguen por MIDI.
- **Fichero del usuario (estructura):** canales 1-2 «Engine 1-2» y canal 3 «Combined»; bancos de fábrica con CC0 0–3
  y RAM 1/2 con CC0 4/5, coherentes con la especificación. Discrepancias: «Combined RAM 1» y «Combined RAM 2»
  (CC0 1 y 2) con 128 entradas cada uno (el aparato guarda 50, y CC0 = 2 es el rango de las instantáneas); «RAM 2»
  con 128 entradas (existen 122). Las entradas de los cuatro bancos de usuario no tienen nombre.
- **Copia corregida** (scratchpad, `M3000_corregido.midnam`, VÁLIDO contra la DTD 1.0; DOCTYPE conservado, D-003):
  «Combined RAM 1» con 50 entradas; «Combined RAM 2» sustituido por «Snapshots» (CC0 = 2, Program Change 1–4,
  «Snapshot 1–4»); «RAM 2» con 122 entradas numeradas 129–250. El resto, idéntico.
- **Instalación** (permiso del usuario, 2026-10-23 22:07): `/Library/Audio/MIDI Devices/MOTU/TC Electronic/M3000
  prueba.midnam` (sha256 `ca606485a51d1837…`), junto a `M3000.midnam`, que sigue idéntico al de `reference/`.
  **Deshacer:** borrar `M3000 prueba.midnam`.
- **Prueba pendiente (usuario, DP 11.36 y M3000; solo CC0/CC32 y Program Change, D-002):** en el aparato, *Program Bank
  Change = External* y algo reconocible en la instantánea 1; en DP, *Master Names* = «M3000 prueba». Comprobar en el
  monitor MIDI del aparato (SHIFT + UTIL/MIDI): combinados de usuario 1 y 50 por el canal 3, **Snapshot 1** (¿carga la
  instantánea o da «ILLEGAL PRESET»?) y RAM 2 129 y 250 por el canal 1.
- **Resultado (usuario, 2026-10-23, DP 11.36 y M3000 con «M3000 prueba»):** «todo funciona». Las **instantáneas se
  seleccionan sin problema** desde «Snapshots» por el canal 3 (CC0 = 2 + Program Change 1–4) (A). El usuario solo tiene
  2 combinados de usuario guardados y los dos se eligen desde «Combined RAM 1» (CC0 = 1); las posiciones vacías (hasta
  la 50) no se pueden comprobar.
- **Conclusión:** la numeración de la especificación vale para DP con *Program Bank Change = External*: combinados de
  usuario en CC0 = 1 e instantáneas en CC0 = 2 por el canal de combinados. Las instantáneas sirven como cuatro escenas
  completas (los dos motores y el routing) desde una sola pista de DP.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»); `M3000.midnam` del usuario sin cambios.

## EXP-024 · 2026-10-24 · Pestaña Categories, Find con «Select Matches» y nota de prueba (T-025)

- **Entorno:** macOS 15.7.9, Mac del proyecto; árbol de trabajo sobre `1dbf7e6`; `build/CherryPicker.app` montado con
  `tools/empaquetar_app.sh`. Documento: copia en el scratchpad de `captures/exp010/Prueba canales.midnam` (fichero
  propio, dos Channel Sets).
- **Qué hacía el original** (nivel D: nib `MainWindow` y símbolos del binario 3.0, sin ver la app funcionando):
  controlador `CPCategoryController` con tablas `categoryTV` («Categories») y `bankTV` («Bank Names»), acciones
  `addCat:` / `deleteCat:`, `addBank:` / `deleteBank:`, `duplicate:` («Dup») y `addToSynth:` («Add To Banks»);
  recurso `Categories.plist` con «GM Categories» (16) y «EMU Categories» (26); método `newUserBankNamed:`. El manual
  2.6.2 solo dice que se pueden crear de golpe los Custom Banks de las categorías GM o E-mu. Sin datos de dónde guardaba
  los juegos propios ni de qué hacía con nombres de banco repetidos: decisiones propias en P17.
- **Tests:** `cd src/CherryPickerApp && swift test` → 79/79 (6 nuevos en `CategoriesTests`, incluida la validación DTD
  de un fichero con los 26 bancos E-mu añadidos; 1 nuevo en `AuditionTests` para la nota de prueba).
- **Categories en la app** (A: lo maneja el usuario y Claude mira con `tools/capturar_app.sh`; commit `1fa1782`):
  - Al abrir: «GM Categories» y «EMU Categories» en gris, sus 16 / 26 nombres, + / − de Bank Names desactivados.
  - «Dup» de GM → «GM Categories copy» editable con los 16 nombres. En la copia: renombrar «Piano» → «Pianos», + →
    «Favoritos», − de «Organ», renombrar el juego → «Mis categorías»: todo correcto.
  - Nombre repetido («Pianos» → «Bass»): aviso «“Bass” is already in this category.» y el nombre se queda. Doble clic
    en «GM Categories»: pitido y no se edita (lo dice el usuario).
  - «Add To Banks» con «Pianos» y «Favoritos» en el Channel Set «Melodicos» (el fichero tiene dos y la app pregunta):
    «1 custom bank added», con el aviso de que «Pianos» ya existía (era un banco del fichero). En Patch Banks,
    «Favoritos» al final de «Melodicos», en rojo (Empty), S0/S32 «-», # 0. ⌘Z lo quita.
  - Tras salir sin guardar (⌘Q) y volver a abrir, «Mis categorías» sigue con sus cambios (preferencias de la app).
- **Find en la lista de patches** (banco «Pianos», patches «Pianos 1–3»): en «Filter», «1» deja solo «Pianos 1» y
  «Count: 1». En el menú de la lupa, «Select Matches»: se ven los 3, con «pianos» (en minúsculas) quedan los 3
  seleccionados y «Count: 3». Arrastrar uno de ellos a la lista de «Cuerdas» copia los 3 (Count: 6), cada uno con su
  bank select 0/0 (P9). El Find de «Cuerdas» abre ya en «Find (select)»: el modo se recuerda.
- **Nota de prueba** (A, oído por el usuario; permiso del usuario para enviar MIDI, 2026-10-24): Roland MKS-50 en la
  Unitor8, canal 1 (Audition Ch por defecto de «Melodicos»). Device Out = puerto de la Unitor, Enable MIDI, Test Note
  con 60 / 100 / 500. Al seleccionar «Pianos 1–3», el MKS-50 cambia de programa (PC 0–2; no usa CC0/CC32) y toca la
  nota. Con Length 3000 y dos clics rápidos se oyen dos notas seguidas, como dos pulsaciones: la primera se corta al
  cambiar de patch y no queda ninguna colgada. Sin Test Note solo cambia de programa y no suena (usuario).
- **Observación (usuario):** si al cambiar de patch aún suena la nota anterior, el patch nuevo suena dos veces: una
  corta y luego la nota con su duración. Sin solapamiento, una sola vez. La app envía Note Off, CC0/CC32 + PC y,
  150 ms después, un solo Note On. **Comprobado (B, usuario):** con Length 300 y esperando a que acabe la cola antes
  de cambiar, suena una sola vez. Es el solapamiento: el MKS-50 aplica el patch nuevo a la voz que aún suena. **Se
  deja como está** (decisión del usuario, 2026-10-24): sin más espera ni All Sound Off.
- **CPU** (`top -l 3 -s 2 -pid …`, app abierta y en reposo tras la prueba): 0,0 %, 52 MB.
- **Conclusión:** Categories, el Find en sus dos modos y la nota de prueba funcionan como se diseñaron (docs/20 §3.1,
  §3.2, P15–P17, D-008).
- **Estado:** COMPLETADO.

## EXP-025 · 2026-10-24 · Arrastrar bancos y patches entre documentos (T-026)

- **Entorno:** macOS 15.7.9, Mac del proyecto; árbol de trabajo sobre `32496cc`; `build/CherryPicker.app` de
  `tools/empaquetar_app.sh`. Documentos: copias en el scratchpad de `captures/exp010/Prueba canales.midnam` (origen) y
  `captures/exp013/Prueba patches.midnam` (destino; Channel Set «Presets», bancos «pruebassss» y «pp» 5/5). Lo maneja el
  usuario; Claude mira con `tools/capturar_app.sh` (A).
- **Tests:** `swift test` → 83/83 (4 nuevos en `TransferTests`, incluida la validación DTD del destino).
- **Bancos:** «Cuerdas» (0/1, 3 patches) soltado debajo de «pp» → llega al final de «Presets» con 0/1 y 3 patches; el
  origen no cambia. Otra vez → «Cuerdas 2». «Kits» y «Kits extra» juntos, soltados encima de «pruebassss» → quedan
  los dos primeros, en su orden, con 2/0 y 2/1.
- **Patches:** «Pianos 2» (0/0, PC 1) de la lista de «Pianos» a la de «pp» → llega al final con 0/0 (no toma el 5/5
  del banco).
- **Deshacer:** cuatro ⌘Z en «Prueba patches» quitan las cuatro copias; vuelve a «pruebassss» y «pp» con sus 5
  patches.
- **No probado en la app:** el aviso de listas de notas o de controles que faltan en el destino (solo en los tests).
- **Conclusión:** P18 funciona como se diseñó. **Estado:** COMPLETADO.

## EXP-026 · 2026-10-24 · «Copy...» de la lista de patches (T-027)

- **Entorno:** macOS 15.7.9, Mac del proyecto; árbol de trabajo sobre `6bc7c72`; `build/CherryPicker.app` de
  `tools/empaquetar_app.sh`; Swift 6.2.4 (Xcode, SDK 26.2). Documento: copia en el scratchpad de
  `captures/exp013/Prueba patches.midnam`, banco «pp» (5 patches, 5/5). Lo maneja el usuario; Claude mira con
  `tools/capturar_app.sh` y lee el portapapeles con `pbpaste` (texto de prueba, puesto por la app).
- **Qué hacía el original** (nivel D, nib `CPPatchExport`): hoja «Copy Fields To Clipboard» con casillas Name, Patch
  Number, Bank Selects, Display Number; «Field Order (Drag to reorder)»; «Delimiter» Comma / Tab / Space; «Quote
  Names», «Print Bank Name», «TextEdit Export»; Cancel / OK. El manual («Bank Export»): botón «Copy...» arriba a la
  izquierda de la lista; OK copia al portapapeles; con TextEdit Export abre además TextEdit.
- **Compilación:** `swift build` (debug) bien, pero `tools/empaquetar_app.sh` (release, `-O`) hacía caer el compilador
  (`signal 6`, «Owned function parameter without lifetime ending uses!» en `CopyFieldsSheet.init(hasSelection:)`, pase
  CopyPropagation). Arreglo: la preparación de la hoja va en un método aparte (`setUp`) llamado tras `super.init`.
- **Tests:** `swift test` → 87/87 (4 nuevos en `PatchExportTests`).
- **En la app:** la hoja sale con «Name» marcado, Tab, «All» y «Selection» desactivada sin selección. OK → portapapeles
  con los 5 nombres, uno por línea. Con los cuatro campos, «Display Number» arrastrado arriba, Comma, Quote Names y
  Print Bank Name → `"pp"` y `001,"dos",0,5,5` … (`"df,fjgsdf"` entre comillas). Con 2 seleccionados, «Selection» y
  TextEdit Export → portapapeles con la línea del banco y esos 2; `pp.txt` en la carpeta temporal de la app y TextEdit
  abierto con esas tres líneas (lo copia el usuario).
- **Conclusión:** Copy... funciona como se diseñó (P19). **Estado:** COMPLETADO.

## EXP-027 · 2026-10-24 · ¿Usa DP 11.36 la `ControlNameList` en «Other Controller…»? (T-014)

- **Entorno:** macOS 15.7.9, Mac del proyecto; DP 11.36 abierto (usuario). Fichero `captures/exp027/CP Controles.midnam`:
  `captures/exp013/Prueba patches.midnam` (modelo «CP Patches», ya en `Cherrypicker.middev`) más `UsesControlNameList
  «CP Controles»` en el Channel Set «Presets» (canales 1–16) y la lista con CC7 «CP Mezcla (CC7)», CC12 «CP Tiempo
  (CC12)», CC13 «CP Feedback (CC13)» y CC85 «CP Sin definir (CC85)»; VÁLIDO contra la DTD 1.0.
- **Instalación** (permiso del usuario, 2026-10-24): copiado a `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/CP
  Controles.midnam` a las 13:52:01, idéntico (`cmp`); no sustituía nada. **Deshacer:** borrar ese fichero.
- **Resultado (A, capturas del usuario en `captures/exp027/`):**
  - *MIDI Device Properties* del dispositivo «CP Patches»: Master Names = «CP Controles», bancos «pruebassss» y «pp»
    (`dp_device_master_names.png`): DP lee el fichero.
  - Menú Insert de una pista MIDI con salida «CP Patches-1»: tipos de evento y los controladores estándar de DP
    (1 modulation, 2 breath, 5 porta time, 6 data, 7 volume, 11, 64 Sustain), sin ningún nombre del fichero
    (`dp_menu_insert.png`).
  - «Other Controller…»: diálogo «Enter Controller» que pide un número («Enter controller number for insertion
    (0-121)»), sin lista ni nombres (`dp_other_controller.png`).
  - *Setup ▸ Legend ▸ MIDI Controller Names*, con la pista en «CP Patches» / «CP Controles»: nombres de la
    especificación (7 volume, 12 Effect Control 1 (coarse), 13 Effect Control 2 (coarse)…), ninguno del fichero
    (`dp_legend_controller_names.png`).
- **Manual** (*Digital Performer User Guide* de DP 11, PDF en el proyecto TASCAM FW1884,
  `reference/Manuales/DP11/`, leído allí y pasado a texto en el scratchpad para buscar, sin copiarlo): no menciona
  MIDNAM ni nombres de controladores por dispositivo; los nombres de instrumento solo salen para patches («The patch
  list», p. 147) y notas (Drum Editor). El menú Insert (p. 400) solo dice que inserta cualquier dato MIDI. La Legend
  (p. 362) lista los 128 controladores con su nombre de la especificación «y los personalizados», sin decir dónde se
  personalizan; «Cont. Data Icons» (p. 441) solo trata iconos y colores.
- **Conclusión:** DP 11.36 lee el fichero, pero no muestra los nombres de `ControlNameList` en el menú de
  controladores, en «Other Controller…» ni en la Legend, y el manual no los menciona. Junto con EXP-006, DP no usa los
  controles con nombre. Sin mirar: los lanes de automatización del editor.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-028 · 2026-10-24 · Pestaña Controllers (T-028)

- **Entorno:** macOS 15.7.9, Mac del proyecto; árbol de trabajo sobre `d0090d1`; `build/CherryPicker.app` de
  `tools/empaquetar_app.sh`. Documentos: copias en el scratchpad de `captures/exp027/CP Controles.midnam` (con la lista
  «CP Controles» usada por «Presets») y `captures/exp010/Prueba canales.midnam` (sin listas; «Melodicos» y «Bateria»).
  Lo maneja el usuario; Claude mira con `tools/capturar_app.sh` (A).
- **Qué hacía el original** (nivel D): `CPControllerVC` con tablas «Control Name Lists» y `Ctl` · `Name`, + / −;
  «Default Control Names» y el recurso `ControllerNames.plist` (72 nombres estándar). La lista estándar de la app es
  propia, de la especificación MIDI 1.0 (41 controladores; D-007).
- **Tests:** `swift test` → 92/92 (5 nuevos en `ControllersTests`, incluida la validación DTD).
- **En la app:**
  - «CP Controles»: la lista con 7, 12, 13 y 85 y «Presets» marcado en «Used by Channel Sets» (P20).
  - «Prueba canales»: + crea «Default Control Names» con los estándar; «Melodicos» y «Bateria» sin marcar. Marcar
    «Melodicos», + a la derecha («New Control», 96), renombrar, número 7 → aviso «Controller 7 is already in this
    list.», número 85, − de dos controles: correcto (usuario). Renombrar la lista a «Synth»: Preview con la
    `ControlNameList Name="Synth"` detrás de las `PatchNameList`. ⌘Z lo deshace todo.
  - A petición del usuario, la lista se ordena por número al añadir o cambiar un número; probado: 96 → 85 queda entre
    84 y 91, y 1 → 3 entre 2 y 4, seleccionado.
- **No visto en la app:** el `UsesControlNameList` dentro de «Melodicos» en Preview (fuera de la captura; lo cubre el
  test de posición y la validación DTD).
- **Conclusión:** la pestaña funciona como se diseñó. **Estado:** COMPLETADO.

## EXP-029 · 2026-10-24 · Uso con los `.midnam` reales del usuario (T-029)

- **Entorno:** macOS 15.7.9, Mac del proyecto; árbol de trabajo sobre `0029202`; `build/CherryPicker.app` de
  `tools/empaquetar_app.sh`. Documentos: copias en el scratchpad de los 6 ficheros de `reference/midnam_usuario/`
  (privados, D-004; originales sin tocar), los 6 VÁLIDOS contra la DTD 1.0 con `tools/validar_midnam.sh`. Lo maneja
  el usuario; Claude mira con `tools/capturar_app.sh` (A).
- **Se abren bien** DSP-128 Plus, PCM-91 y M3000 (bancos, bank select y recuentos coherentes con EXP-003).
- **Hallazgos del usuario y arreglos:**
  - Botón **P** demasiado grande: ahora cuadrado de 13 pt centrado; las celdas de Patch Banks se centran en vertical
    (el texto del popup Channel Set salía más bajo que el resto).
  - Columna **Channel Set** fuera de la ventana al abrir (había que redimensionar): «Patch Bank» empieza con 120 pt y
    se ensancha sola.
  - La lista de patches se abría **encima de la principal** cuando no cabía a la derecha: ahora prueba a la derecha,
    luego a la izquierda y solo después encima.
  - Para copiar parte de un banco a uno nuevo había que crearlo antes: **P21** («New Bank from Selection…» y soltar
    patches en Patch Banks). Primera versión: el banco iba debajo del de origen; el usuario lo prefirió al final del
    Channel Set, como + y Find.
- **Tests:** `swift test` → 94/94 (2 nuevos en `TransferTests`: banco nuevo con patches de otro documento, en medio o al
  final, y nombre ocupado).
- **Probado por el usuario:** menú contextual (OK, también con el banco al final del Channel Set), arrastre de patches a Patch Banks
  (OK), Tab al renombrar bancos tras el cambio de celdas (OK).
- **Guardar y reabrir:** el usuario agrupa presets de DSP-128 Plus en bancos nuevos, guarda y vuelve a abrir (OK).
  Lo guardado: VÁLIDO contra la DTD 1.0; DOCTYPE y cabecera idénticos al original (D-003); 7 bancos (antes 1), 147
  patches (128 + 19 copiados), cada banco con su lista. El original de `reference/` sigue sin tocar (fecha de 2020).
- **Resto de ficheros:** el usuario abre los demás y van bien; lo da por bueno por ahora.
- **Estado:** COMPLETADO. Copia de trabajo de DSP-128 guardada en `reference/midnam_trabajo/` (no versionada).


## EXP-030 · 2026-10-24 · M3000 optimizado en DP 11.36 (T-030)

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `77deec1`. Fichero:
  `reference/midnam_trabajo/M3000 optimizado.midnam` (privado, D-004; VÁLIDO contra la DTD 1.0; sha256
  `992c7b15bee0bd75…`), sacado de `M3000 prueba.midnam` con los cambios de la ficha T-030. Fuentes: manual, addendum
  «Film and Post Production» (rev. 1.3) y «M3000 MIDI specification» v1.01, en `incoming/`.
- **Comprobado sin aparato (script):** las 904 direcciones (Channel Set, CC0, CC32, PC) de `M3000 prueba` siguen en
  el mismo sitio; 300 nuevas en Card 1/2 (CC0 6/7) y Combined Card (CC0 3), con PC = (n − 1) mod 128; 53 nombres
  cambiados. Los 13 dudosos los leyó el usuario en la pantalla del M3000 (A); 249 y 245 no coinciden con el manual.
- **Estado de la carpeta antes de instalar:** en `/Library/Audio/MIDI Devices/MOTU/TC Electronic/` el usuario había
  renombrado lo de EXP-023: `M3000.midnam` = «M3000 prueba» (sha256 `ca606485…`) y `M3000 MIO.midnam` = su original
  (= `reference/midnam_usuario/M3000.midnam`, `1349ddf2…`); también está `M3000.midnam copia` (`7495fced…`). No se tocan.
- **Instalación** (permiso del usuario, 2026-10-24 19:56): copia como `M3000 optimizado.midnam` en esa carpeta, sin
  sobrescribir nada. **Deshacer:** borrar `/Library/Audio/MIDI Devices/MOTU/TC Electronic/M3000 optimizado.midnam`.
- **Prueba pendiente (usuario, DP 11.36 y M3000 con *Program Bank Change = External*; solo CC0/CC32 y Program Change,
  D-002):** en DP, *Master Names* = «M3000 optimizado». Mirar que salen los bancos nuevos (Halls Natural/Super-natural,
  Outdoor Medium, Outdoor XXL, Combined Music/Film/Surround, Card 1/2, Combined Card) y elegir, viendo el número en el
  aparato: 21 y 63 (Halls Natural, ahora sin comandos por patch), 64 y 136 (Super-natural, cruza el 128), 410 y 415
  (Outdoor Medium), un Combined Film (p. ej. 51) y uno Surround (96) por el canal 3. Card solo si hay tarjeta.
- **Resultado (usuario, 2026-10-24, DP 11.36 y M3000 con «M3000 optimizado»):** «todo funciona» (A).
- **Conclusión:** la reorganización de bancos vale en DP: un banco sin comandos por patch (Halls Natural, CC0 en el
  banco) y otro que cruza el 128 con comandos por patch (Super-natural) cambian bien de preset; los Combined partidos
  también por el canal 3. Los PDF del M3000 quedan archivados en `reference/manuales/M3000/`.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»); los demás ficheros de la carpeta, sin cambios.

## EXP-031 · 2026-10-24 · DSP-128 Plus optimizado en DP 11.36 (T-031)

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `04276a4`. Fichero:
  `reference/midnam_trabajo/DSP-128 Plus optimizado.midnam` (privado, D-004; VÁLIDO contra la DTD 1.0; sha256
  `0c1e11ed1ee59443…`), sacado de `DSP-128 Plus.midnam` (EXP-029) con los cambios de la ficha T-031. Fuente: manual
  del DSP 128 plus (escaneo, leído con OCR de Vision) en `reference/manuales/DSP-128 Plus/`.
- **Comprobado sin aparato (script):** 11 bancos sin Bank Select (All Programs + 10 familias); los 128 PC 0–127 con un
  solo nombre cada uno, patch n → PC n − 1; canales y `CustomDeviceMode` idénticos; 28 nombres cambiados.
- **Instalación:** `/Library/Audio/MIDI Devices/MOTU/Digitech/` es de root y Claude no puede escribir en ella
  (`cp` → «Permission denied»). La copia la hizo el usuario con `sudo cp -n` (2026-10-24 20:14), como
  `DSP-128 Plus optimizado.midnam`, idéntica a la de trabajo (misma sha256). `DSP-128 Plus.midnam` del usuario, sin
  cambios (= `reference/midnam_usuario/`, `2cc90bd1…`). **Deshacer:** `sudo rm "/Library/Audio/MIDI Devices/MOTU/Digitech/DSP-128 Plus optimizado.midnam"`.
- **Prueba pendiente (usuario, DP 11.36 y DSP-128 Plus; solo Program Change, D-002):** en DP, *Master Names* =
  «DSP-128 Plus optimizado»; que salgan los 11 bancos y que 1, 17, 50, 70, 100 y 128 pongan el aparato en P 1, P 17,
  P 50, P 70, P 100 y P 128.
- **Resultado (usuario, 2026-10-24, DP 11.36 y DSP-128 Plus con «DSP-128 Plus optimizado»):** «todo funciona» (A).
- **Conclusión:** bancos sin Bank Select para un aparato sin bancos funcionan en DP: cada banco es solo una forma de
  agrupar, y el patch n manda PC n − 1 (P n en el aparato).
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»); los demás ficheros de la carpeta, sin cambios.

## EXP-032 · 2026-10-24 · LXP-15 I/II optimizado en DP 11.36 (T-032)

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `76e762b`. Ficheros (privados, D-004;
  VÁLIDOS contra la DTD 1.0): `reference/midnam_trabajo/LXP-15 II Presets.midnam` (sha256 `719b3878bdbddbbc…`, de
  `LXP-15 II.midnam`) y `LXP-15 I Registers.midnam` (`181bfd321549f22c…`, de `LXP-15.midnam`), con los cambios de la
  ficha T-032. Fuentes: manuales del LXP-15 y del LXP-15 II en `reference/manuales/LXP-15/`.
- **Comprobado sin aparato (script):** en los dos, 128 PC 0–127 con un solo nombre cada uno (patch n → PC n − 1, como
  dicen los manuales: PC 0 = preset 1), bancos sin Bank Select, `CustomDeviceMode` y canales iguales que el original;
  nombres iguales salvo las marcas [F]/[M]/[E] y I 86 → «Spacious5th^».
- **Instalación:** `/Library/Audio/MIDI Devices/MOTU/Lexicon/` es de root; la copia la hizo el usuario con `sudo cp -n`
  (2026-10-24 20:42), idéntica a la de trabajo (misma sha256). `LXP-15 II.midnam` y `LXP-15.midnam` del usuario, sin
  cambios (`d071c56f…`, `9756ae28…`, = `reference/midnam_usuario/`). **Deshacer:**
  `sudo rm "/Library/Audio/MIDI Devices/MOTU/Lexicon/LXP-15 II Presets.midnam" "/Library/Audio/MIDI Devices/MOTU/Lexicon/LXP-15 I Registers.midnam"`.
- **Prueba pendiente (usuario, DP 11.36 y LXP-15 con ROM del II; solo Program Change, D-002):** con *Pgm Chg* = Pre y
  *Master Names* = «LXP-15 II Presets», bancos y algunos presets (p. ej. 1, 27, 65, 128); con *Pgm Chg* = Reg y «LXP-15 I
  Registers», lo mismo y el 86 («Spacious5th^»). Mirar si DP muestra bien los corchetes y si los «- » se ven como en el
  SPX2000.
- **Resultado (usuario, 2026-10-24, DP 11.36 y LXP-15 con ROM del II, con los dos ficheros):** «todo funciona muy bien»
  (A): bancos con sub-bancos «- » y marcas [F]/[M]/[E] se ven bien. El usuario deja la organización así; no quiere
  los rangos en el nombre del banco ni quitar «Studio». La prueba de otros símbolos va en EXP-033.
- **Estado:** COMPLETADO. Instalación sin retirar (ver «Deshacer»).

## EXP-033 · 2026-10-24 · ¿Qué símbolos muestra DP 11.36 delante del nombre de un banco?

- **Objetivo:** ver si hay algo más claro que «- » para que un banco parezca colgar de otro en el menú de presets
  (DP solo muestra un nivel de submenús, EXP-006 y EXP-011), sin que DP lo muestre mal ni lo recorte.
- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `d5dd608`.
- **Fichero:** `CP Prueba simbolos.midnam` (scratchpad de la sesión; VÁLIDO contra la DTD 1.0; DOCTYPE de midi.org, D-003;
  sha256 `09ea87e9efaa0ffe…`), Lexicon / LXP-15, hecho a partir de `LXP-15 II Presets` (privado, no se versiona).
  Bancos: «All Presets» (1–128) y diez bancos con los presets 1–6, cada uno con un prefijo: `- `, `└ `, `├ `, `› `,
  `▸ `, `→ `, `· `, `— `, tres espacios («(espacios)») y tres espacios duros U+00A0 («(nbsp)»).
- **Instalación:** hecha por el usuario con `sudo cp -n` (2026-10-24 20:58), idéntica (misma sha256), como
  `/Library/Audio/MIDI Devices/MOTU/Lexicon/CP Prueba simbolos.midnam`. **Deshacer:**
  `sudo rm "/Library/Audio/MIDI Devices/MOTU/Lexicon/CP Prueba simbolos.midnam"`.
- **Prueba (usuario):** en DP, *Master Names* = «CP Prueba simbolos»; abrir el menú de presets y mirar cómo sale cada
  banco (símbolo bien, cuadro vacío o «?», espacios recortados o no). Con *Pgm Chg* = Pre se puede elegir un preset.
- **Resultado (usuario, 2026-10-24, DP 11.36; captura del menú pasada en el chat, no versionada: se ve su lista de dispositivos):** DP
  muestra **los diez prefijos bien**, en el orden del fichero (A): `- `, `└ `, `├ `, `› `, `▸ `, `→ `, `· ` y `— ` se ven
  como símbolos (ni cuadros ni «?»), y **no recorta los espacios del principio**: «   Halls (espacios)» y el de espacios
  duros salen sangrados, con «Halls» a la misma altura que el texto de los demás. Al abrir un banco se ven sus presets
  y las marcas («004 Compress Hall [E]»).
- **Conclusión:** en los nombres de banco de DP 11.36 valen Unicode (flechas, dibujo de cajas) y los espacios iniciales;
  se puede sangrar de verdad o dibujar un árbol (├ en medio, └ en el último).
- **Estado:** COMPLETADO. Fichero de prueba retirado de DP (EXP-034).

## EXP-034 · 2026-10-24 · Sub-bancos en árbol (D-010) en LXP-15 I/II y SPX2000

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `bd5ce77`.
- **Ficheros** (privados, D-004; VÁLIDOS contra la DTD 1.0; en `reference/midnam_trabajo/`):
  - `LXP-15 II Presets.midnam` (sha256 `93ebf1056a0fb2d1…`) y `LXP-15 I Registers.midnam` (`500543f0384e0742…`): los
    de EXP-032 con «- » cambiado por «├ »/«└ » y «● » delante de All Presets / All Registers, en banco,
    `UsesPatchNameList` y `PatchNameList` (`diff`: solo esas líneas).
  - `SPX2000.midnam`: copia del instalado `MOTU/Yamaha/SPX2000.midnam` (sha256 `c463e3246e1c6ddb…`, del usuario; leído
    con su permiso). `SPX2000 optimizado.midnam` (`9ce72158f805ebcb…`): lo mismo («● PRESET»), y «- Samplig» → «└ Sampling». Bank
    Select (CC0/CC32 por banco) y patches sin cambios (`diff`: solo nombres de banco).
- **Instalación (usuario, 2026-10-24 21:05–21:07; SPX2000 desde el Finder, LXP-15 con `sudo cp`; las tres copias idénticas
  a las de trabajo, misma sha256; `SPX2000.midnam` sin cambios):** sustituir en `MOTU/Lexicon/` los dos LXP-15
  de EXP-032 (son ficheros de la sesión, no del usuario), añadir `MOTU/Yamaha/SPX2000 optimizado.midnam` junto a su
  `SPX2000.midnam` (sin tocar) y retirar `MOTU/Lexicon/CP Prueba simbolos.midnam` (EXP-033). Retirado por el usuario con `sudo rm` (comprobado). **Deshacer:** borrar
  `MOTU/Yamaha/SPX2000 optimizado.midnam` y los dos LXP-15 (o volver a copiar los de EXP-032, sha256 `719b3878…` y
  `181bfd32…`).
- **Prueba (usuario):** en DP, el árbol en los menús de «LXP-15 II Presets», «LXP-15 I Registers» y «SPX2000
  optimizado»; en el SPX2000, un preset de PRESET, CLASSIC y USER.
- **Resultado (usuario, 2026-10-24, DP 11.36; capturas del menú de los dos LXP-15 en el chat, no versionadas):** el
  árbol se ve bien y en orden («General», «├ Halls»… «└ Special»; «Studio», «├ Halls»… «└ Delay/Pitch/Mod»), igual que
  las marcas [F]/[E] (A). El usuario ve **demasiado grande** el «● » de «● All Presets»/«● All Registers».
- **Cambio:** «● » → «• » (U+2022) en los tres (D-010). Nuevas sha256: `LXP-15 II Presets` `e983a89410e2d14c…`,
  `LXP-15 I Registers` `c867b02b0dbcb11e…`, `SPX2000 optimizado` `3f16cb4a312611b7…`; VÁLIDOS. Copiados por el usuario con
  `sudo cp` (2026-10-24), idénticos (misma sha256); `SPX2000.midnam` sin cambios. 
- **Resultado final (usuario, 2026-10-24, DP 11.36):** la viñeta «• » y el SPX2000 optimizado se ven bien (A).
- **Conclusión:** D-010 vale en DP: «• » para el banco con todos y árbol «├ »/«└ » para los sub-bancos.
- **Estado:** COMPLETADO. Instalaciones sin retirar (ver «Deshacer»).

## EXP-035 · 2026-10-24 · Viñeta y árbol (D-010) en M3000 y DSP-128 Plus

- **Entorno:** macOS 15.7.9, Mac del proyecto, DP 11.36; árbol de trabajo sobre `02c7232`.
- **Ficheros** (privados, D-004; VÁLIDOS contra la DTD 1.0; en `reference/midnam_trabajo/`):
  - `M3000 optimizado.midnam` (sha256 `669bb13e357d42f4…`): bancos padre nuevos «Halls» (21–136, Bank Select por patch),
    «Indoor» (251–399, por patch), «Outdoor» (410–439, CC0 3 en el banco) y «Combined» (1–100, CC0 0), cada uno justo
    encima de sus sub-bancos, renombrados «├ Natural» / «└ Super-natural», «├ Indoor Mini» … «└ Indoor XXL», «├ Outdoor
    Medium» … «└ Outdoor XXL» y «├ Music» / «├ Film» / «└ Surround» (nombre completo en Indoor y Outdoor para que las
    listas no se repitan). Sin banco «todos» (Top 20 es una selección).
  - `DSP-128 Plus optimizado.midnam` (`7895a475df33b341…`): «• All Programs», «Rooms» (1–49) con «├ Large», «├ Medium»,
    «└ Small» y «EQ» (100–126) con «├ Parametric», «└ Graphic»; las demás familias, sueltas.
- **Comprobado con script:** M3000, las 904 direcciones de `M3000 prueba` siguen igual (más las 300 de Card), un solo
  nombre por dirección y número mostrado coherente con CC0/PC; DSP-128, los 128 PC con un nombre cada uno; nombres de
  patch sin cambios en los dos.
- **Instalación (pendiente, el usuario con `sudo`):** sustituir `MOTU/TC Electronic/M3000 optimizado.midnam` (EXP-030) y
  `MOTU/Digitech/DSP-128 Plus optimizado.midnam` (EXP-031); son ficheros de la sesión. **Deshacer:** borrarlos.
- **Prueba (usuario):** menús en DP; en el M3000, un preset de «Halls» por encima de 128 (p. ej. 130) y uno de «Indoor»
  (p. ej. 300) desde el banco padre.
- **Resultado:** —
- **Estado:** EN CURSO.
