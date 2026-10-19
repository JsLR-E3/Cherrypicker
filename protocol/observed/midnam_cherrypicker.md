# midnam tal como lo escribe CherryPicker 3.0 — OBSERVED

Fuentes: `reference/app_3.0/…/Resources/CPXMLRead.plist` y `CPXMLStrings.plist` (D) y los 4 `.midnam` del usuario
con `<Author>CherryPicker` (B). EXP-001.

## Cabecera

- `<?xml version="1.0" encoding="UTF-8"?>` + `<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 1.0//EN" …>`
- Sangría con tabuladores, fin de línea LF. Los ficheros de MOTU (convertidos de FreeMIDI) usan DTD 0.7.

## Jerarquía usada en los ejemplos

```
MIDINameDocument
  Author
  MasterDeviceNames
    Manufacturer, Model
    CustomDeviceMode Name
      ChannelNameSetAssignments / ChannelNameSetAssign Channel NameSet
    ChannelNameSet Name
      AvailableForChannels / AvailableChannel Channel Available
      PatchBank Name [ROM]
        MIDICommands / ControlChange Control Value      ← bank select del banco (opcional)
        UsesPatchNameList Name   o   PatchNameList (en línea)
    PatchNameList Name
      Patch Number Name ProgramChange                 ← forma corta
      Patch Number Name > PatchMIDICommands > ControlChange…, ProgramChange Number   ← forma con comandos propios
```

## Puntos a respetar al reescribir

- `Patch Number` es texto de pantalla (puede llevar espacios o ceros: `"  1"`, `"065"`); `ProgramChange` es 0–127.
- Bank select en tres formas: ninguna (bancos solo de agrupación), por banco (`MIDICommands` del `PatchBank`) y por
  preset (`PatchMIDICommands`). Varios bancos pueden compartir la misma combinación CC0/CC32.
- Elementos que lee y no aparecen en los ejemplos: `StandardDeviceMode`, `DeviceModeEnable`, `SysEx`,
  `SysExDeviceID`, `DeviceID`, `MIDIDeviceType`, `ExtendingDeviceNames`, `ControlNameList`/`Control`,
  `NoteNameList`/`NoteGroup`/`Note`, `UsesNoteNameList`. Hay que conservarlos al abrir ficheros de otros orígenes.
- Opciones de escritura (`Defaults.plist`): `CP_writeBankSx`, `CP_writePatchMidi`, `CP_writeControllers`,
  `CP_writeNotelist`, `CP_writeModeName`, `CP_writeModeSx`, `CP_emptyBanks`, `CP_128PatchLimit`.
