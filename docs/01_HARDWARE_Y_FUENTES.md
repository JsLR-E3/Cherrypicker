# 01 — PROGRAMA, EQUIPOS Y FUENTES

## Equipos

| Equipo | Detalle |
|---|---|
| Cherrypicker | Programa, no aparato: editor de ficheros de nombres de patches y bancos MIDI. Versión 3.0 (2009), autor Rob Martin (alterSpective). DonationWare. Bundle `com.alterSpective.cherrypicker26` |
| Binario | Mach-O universal ppc_7400 + i386; Cocoa/Objective-C. Enlaza Cocoa, CoreMIDI, AudioToolbox, CoreServices y **Message.framework** (eliminado en macOS modernos). Sin x86_64/arm64: **no arranca desde macOS 10.15** |
| Mac de destino | macOS 15.7.9 (este Mac). Programas que usarán los ficheros: por confirmar con el usuario (T-005) |
| Sistema histórico | Snow Leopard (10.6) con Rosetta; README 2.7 pide OS X 10.3 o superior. Fuente de nivel B si se dispone de una máquina o VM |

## Formatos que maneja (según Info.plist, README y clases)

| Formato | Rol en la app | Notas |
|---|---|---|
| Midnam XML (`.midnam`) | Editor | MIDINameDocument DTD 0.7 (MMA). Formato principal; lo usan los 6 ejemplos del usuario |
| Middev XML (`.middev`) | Editor | Variante de MOTU (Digital Performer); `CPMiddevEditor`, `CPmiddevRead.plist` |
| FreeMIDI | Editor | Texto, tipos `TEXT`/`utxt` |
| Cubase (`.txt`) | Editor | `CPCubaseModule` |
| OMS (`omNP`/`OmsN`) | Solo lectura | Name Sets de OMS |
| Exportación | — | Sibelius Sound Sets (`CPSibeliusExporter`, `sibInstr.plist`), Gigastudio (`CPGigastudio`), MIDI file (`CPMIDIFile`) |

Funciones visibles en el manual y las notas 2.62: edición de bancos, bank select, channel sets, controladores, notas
(drum maps), filtros, categorías GM/E-MU, audición de patches por CoreMIDI, renumerar, duplicados, fusión,
multi-modelo, conversión de bancos custom a estándar (para Pro Tools) y comprobación de errores.

Clases propias (i386, `otool -oV`): CPDeviceDocument, CPDeviceDB, CPDeviceFile, CPMode, CPChannelSet, CPBank,
CPBankSelect, CPPatch, CPPatchList, CPNoteList, CPControllerList, CPCategories, CPSynth, CPXMLCallback, CPMergeSheet,
CPDuplicates, CPErrorChecker, CPMultiModelSheet, CPRenumberSheet, CPPreview, CPImportBrowser, CPSetupWizard y otras.
Recursos en `.nib` compilados (keyedobjects) para 25 ventanas y hojas.

## Fuentes (en `reference/`)

| Fuente | Uso |
|---|---|
| `reference/app_3.0/` | Programa original 3.0: comportamiento, recursos (`.plist` de lectura XML, categorías, nombres de controladores, instrumentos de Sibelius), nibs |
| `reference/extracted/CherryPicker262/` | Versión 2.62 y sus notas de versión (cambios 2.6–2.62) |
| `reference/web_alterspective/` | Manual original (`docs/introC.html`: filtros, edición y acciones de bancos y patchlists) y capturas; 20 imágenes perdidas en Wayback |
| `reference/midnam_usuario/` | Ejemplos reales del usuario (privados) para validar lectura/escritura sin pérdidas |
| Externas (no descargadas) | DTD MIDINameDocument (sonosphere.com), digicake.com/midnam: enlazadas desde la web original |
