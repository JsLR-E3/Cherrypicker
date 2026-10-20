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
