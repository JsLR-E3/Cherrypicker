# 30 — MANUAL DE USUARIO (borrador)

## 1. Instalación

Sin instalador todavía. Compilar y montar la app (este Mac, Xcode 26 / Swift 6.2):

```
tools/empaquetar_app.sh        # → build/CherryPicker.app (firma ad hoc, no versionado)
```

Abrir un `.midnam` con **File ▸ Open…** o arrastrándolo a la app. La app no guarda sola: solo con **Save** (⌘S).

## 2. Uso

- **Patch Banks:** doble clic en el nombre para cambiarlo (único; su lista de presets se renombra con él); doble clic
  en **S0**/**S32** abre la hoja Bank Selects (`-` = no se usa; las tres opciones hacen lo mismo que el original);
  popup **Channel Set** (con varios bancos seleccionados, cambia todos); **+** abre «Add a Single Bank», **−** borra
  los seleccionados; arrastrar para reordenar dentro del Channel Set; con varios seleccionados, clic en el título de
  la columna S0/S32 o Channel Set los cambia todos. ⌘Z / ⇧⌘Z deshacen y rehacen. Nombre en rojo = banco vacío; azul =
  presets con bank select distinto del banco. Al editar un nombre, Tab / ↓ pasan al banco siguiente y ⇧Tab / ↑ al
  anterior.
- **Lista de presets (botón P de un banco):** una ventana por banco con B0 · B32 · # · Patch Name · Ascii, todo
  editable con doble clic (B0/B32 igual al banco = hereda del banco; vacío o `-` en los dos = solo Program Change);
  al editar, Tab / ⇧Tab pasan a la celda siguiente o anterior (y al siguiente preset), ↑ / ↓ al preset de arriba o
  de abajo, y ← / → a la celda de al lado cuando el cursor está al principio o al final del texto. Clic en un título de
  columna ordena la lista (es el orden del menú de DP; otro clic invierte). **+** abre «New Patches» (Start At,
  Start Ascii, Quantity, «Set Bank Selects to Bank values»); los nuevos van delante del seleccionado o al final.
  Pegar (⌘V) o soltar texto abre la misma hoja con un preset por línea, coma, tabulador o entre comillas
  («Patch Delimiter»). **−** o Supr borran; **Renumber** numera todos o los seleccionados. Arrastrar reordena; a la
  ventana de otro banco, del mismo fichero o de otro abierto, copia (cada preset sigue sonando con su bank select). **Find** filtra por
  nombre y «Count:» cuenta lo que se ve; en el menú de la lupa, «Select Matches» selecciona los que coinciden sin
  ocultar el resto (para arrastrarlos todos de una vez a otro banco). El modo elegido se recuerda. Con el botón
  derecho (o Edit ▸ «New Bank from Selection…»), los seleccionados se copian a un banco nuevo al final de su Channel
  Set; también se pueden soltar en la lista de bancos: entre dos bancos crea uno nuevo ahí, encima de un banco los
  añade al final.
- **Patch Banks, más botones:** **Merge** (con dos o más bancos) junta sus presets en un banco nuevo y borra los
  originales (con Option al pulsar «Add», los conserva). **Zap Dups** borra los presets repetidos: con bancos
  seleccionados, conserva esos y borra los repetidos de los demás bancos de su Channel Set; sin selección, borra de
  los bancos con bank select los que ya están en un banco sin bank select (Custom Bank). Sirve para que DP recuerde el
  Custom Bank desde el que elegiste un preset (EXP-015), a cambio de dejar huecos en el banco original. **Import** trae
  listas de otros `.midnam` de una carpeta (por defecto la de DP del fabricante): cada lista llena un banco o crea
  uno («Add as New Bank»). **Find** abre el Finder: busca presets por nombre en todos los bancos; «Add New Bank With
  Patches» crea un banco con los que quedan en la lista, − y «Remove Duplicates» solo quitan filas de la lista, y se
  pueden arrastrar a la lista de un banco.
- **Copy...** (lista de presets): copia al portapapeles una línea por preset con los campos marcados (Name, Patch
  Number, Bank Selects, Display Number) en el orden de «Field Order» (se arrastran), separados por coma, tabulador o
  espacio; «Quote Names» pone los nombres entre comillas, «Print Bank Name» añade antes el nombre del banco, «TextEdit
  Export» lo abre también en TextEdit y «Selection» copia solo los seleccionados. Para pegarlo, por ejemplo, en Logic.
- **Patch Banks entre ficheros:** arrastrar uno o varios bancos a la tabla de otro documento abierto los copia (el
  de origen no cambia) al Channel Set de la fila de encima de donde se sueltan, con su bank select y sus presets; si
  el nombre ya existe, llega como «nombre 2».
- **Device:** fabricante y modelo (solo lectura), modos y Channel Sets con + / − y doble clic para renombrar,
  «Active Channels» (p. ej. `1-9, 11-16`) y «Audition Ch» (canal por el que suena la audición; vacío = el más bajo).
  El + de Channel Sets solo funciona si quedan canales libres; un Channel Set nuevo trae un banco vacío. Al borrar uno
  con presets, pregunta a qué Channel Set pasan sus bancos.
- **MIDI (audición):** elegir «Device Out» y marcar «Enable MIDI» (se desmarca al abrir). Al seleccionar un preset en
  su lista se envían su bank select y su Program Change. Con **Test Note** marcado (para módulos de sonido; apagado
  en multiefectos), además suena una nota corta (Note, Velocity, Length en ms; por defecto C3, 100, 500) poco después
  del cambio; al cambiar de preset, la anterior se corta. Se recuerda por fabricante y modelo. Nunca se envía SysEx.
- **Controllers:** listas de nombres de controladores. **+** a la izquierda crea «Default Control Names» con los
  controladores estándar; a la derecha, + / − y doble clic para cambiar número (0–127, sin repetir) o nombre; la lista
  se ordena por número. «Used by Channel Sets» marca qué Channel Sets usan la lista seleccionada.
- **Categories:** juegos de nombres de banco. «GM Categories» y «EMU Categories» vienen de serie y no se editan:
  **Dup** hace una copia tuya que sí (doble clic para renombrar, + / − en las dos tablas). Tus juegos valen para
  todos los documentos. **Add To Banks** crea en el documento un Custom Bank vacío (sin bank select) por cada nombre
  seleccionado, o por todos si no hay selección; si hay varios Channel Sets, pregunta en cuál, y los nombres que ya
  son de un banco no se crean (avisa). Luego se llenan arrastrando presets desde otras listas.
- **File ▸ New (⌘N):** asistente Device Setup: fabricante y modelo (se autocompletan con los de DP), si todos los
  bancos suenan en todos los canales y, si no, los grupos de canales. Crea un documento sin guardar con un banco vacío
  por grupo.
- **Preview:** el XML exacto que se guardará.
- **Llevarlo a DP: File ▸ Install in DP… (⌘I).** Copia el fichero a `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`
  con el nombre que verás en *Master Names* y, si el modelo es nuevo, puede añadirlo a «<Fabricante>
  (CherryPicker).middev» para que salga en la lista de modelos (sin él también funciona si escribes fabricante y
  modelo exactos en Configuración de Audio MIDI). Pide confirmación, guarda copia de lo que sustituye y dice cómo
  deshacerlo. Después, reiniciar DP o volver a elegir el fichero en *Master Names*.
- **Ventanas:** la del documento se abre donde la dejaste (también en otra pantalla).

## 3. Diagnóstico y limitaciones

- Solo se lee `.midnam` en UTF-8.
- Aún no hay: Note Lists.
- DP 11.36 no muestra los nombres de la pestaña Controllers (EXP-027): sirven para otros programas.
- Un Channel Set no puede quedarse sin bancos (lo exige el formato).
