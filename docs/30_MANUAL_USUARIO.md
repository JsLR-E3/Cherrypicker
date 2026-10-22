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
  presets con bank select distinto del banco.
- **Lista de presets (botón P de un banco):** una ventana por banco con B0 · B32 · # · Patch Name · Ascii, todo
  editable con doble clic (B0/B32 igual al banco = hereda del banco; vacío o `-` en los dos = solo Program Change);
  al editar, Tab / ⇧Tab pasan a la celda siguiente o anterior (y al siguiente preset) y ↑ / ↓ al preset de arriba o
  de abajo. Clic en un título de
  columna ordena la lista (es el orden del menú de DP; otro clic invierte). **+** abre «New Patches» (Start At,
  Start Ascii, Quantity, «Set Bank Selects to Bank values»); los nuevos van delante del seleccionado o al final.
  Pegar (⌘V) o soltar texto abre la misma hoja con un preset por línea, coma, tabulador o entre comillas
  («Patch Delimiter»). **−** o Supr borran; **Renumber** numera todos o los seleccionados. Arrastrar reordena; a la
  ventana de otro banco del mismo fichero, copia (cada preset sigue sonando con su bank select). **Find** filtra por
  nombre y «Count:» cuenta lo que se ve.
- **Preview:** el XML exacto que se guardará.
- **Llevarlo a DP:** copiar el `.midnam` (y un `.middev` si el modelo es nuevo) a
  `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`; DP necesita reiniciarse para un `.middev` nuevo y, tras cambiar un
  fichero, volver a elegirlo en *Master Names*. («Instalar en DP…», P3, aún no está hecho.)

## 3. Diagnóstico y limitaciones

- Solo se lee `.midnam` en UTF-8.
- Aún no hay: Copy… y audición en la lista de presets, arrastrar presets entre ficheros, New (asistente), pestañas MIDI, Device, Controllers y Categories.
- Un Channel Set no puede quedarse sin bancos (lo exige el formato).
