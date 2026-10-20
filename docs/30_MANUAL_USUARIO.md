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
- **Preview:** el XML exacto que se guardará.
- **Llevarlo a DP:** copiar el `.midnam` (y un `.middev` si el modelo es nuevo) a
  `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`; DP necesita reiniciarse para un `.middev` nuevo y, tras cambiar un
  fichero, volver a elegirlo en *Master Names*. («Instalar en DP…», P3, aún no está hecho.)

## 3. Diagnóstico y limitaciones

- Solo se lee `.midnam` en UTF-8.
- Aún no hay: lista de presets (botón P), New (asistente), pestañas MIDI, Device, Controllers y Categories.
- Un Channel Set no puede quedarse sin bancos (lo exige el formato).
