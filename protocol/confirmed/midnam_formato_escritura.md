# Formato de escritura de .midnam (CherryPicker 3.0 y MOTU) — CONFIRMED

EXP-003. Reproducido byte a byte por `src/MidnamKit` en los 6 ejemplos del usuario (B: 4 escritos por CherryPicker,
2 convertidos por MOTU) y coherente con las plantillas de `CPXMLStrings.plist` (D). Estructura: ver
`protocol/observed/midnam_cherrypicker.md`.

## Reglas

| Aspecto | Regla |
|---|---|
| Prólogo | Literal: `<?xml version="1.0" encoding="UTF-8"?>`, DOCTYPE, línea en blanco. CherryPicker: DTD 1.0 con identificador de sistema `""`; MOTU: DTD 0.7 con la URL de sonosphere.com |
| Sangría | Un tabulador por nivel; raíz sin sangría; fin de línea LF |
| Abrir con atributos | `<Elem A="v" B="w" >` (espacio antes de `>`) |
| Abrir sin atributos | `<Elem>` |
| Vacío con atributos | `<Elem A="v" />` |
| Vacío sin atributos | `<Elem/>` (plantilla `SysExDeviceID`; no aparece en los ejemplos) |
| Texto | En la misma línea: `<Author>CherryPicker</Author>` |
| Orden de atributos | El de `CPXMLStrings.plist` (p. ej. `Patch`: Number, Name, ProgramChange) |
| Escapes | `&` `<` `>` `"` siempre; `'` → `&apos;` en CherryPicker, sin escapar en MOTU |
| Final | CherryPicker: salto de línea tras `</MIDINameDocument>`; MOTU: sin él |

## Cómo lo aplica MidnamKit

- Lee a un árbol que conserva el orden de atributos e hijos, el prólogo y el final literales, y detecta el estilo de
  escape (`XMLWriteStyle`).
- El modelo tipado (`MIDINameDocument` → `MasterDeviceNames` → modos, `ChannelNameSet`, `PatchBank`, `PatchNameList`,
  `Patch`, `MIDICommand`, `ControlNameList`) solo tipa un elemento si su forma coincide; lo demás queda en `.other`
  en su sitio, y los atributos no previstos en `extraAttributes`.
- Los ficheros nuevos se escriben con el estilo de CherryPicker.

## Reglas de la DTD 1.0 que debe cumplir la app al crear ficheros (EXP-004)

Fuente: `reference/dtd/MIDINameDocument10.dtd` (MMA, 19-01-2003; copia de Wayback de midi.org, 4498 bytes, igual a
su `Content-Length` original). Coinciden con todo lo observado en los ejemplos (D + B → CONFIRMED).

| Elemento | Hijos, en este orden | Atributos |
|---|---|---|
| `MIDINameDocument` | `Author`, luego `MasterDeviceNames`+ (o `ExtendingDeviceNames`+ o `StandardDeviceMode`+) | — |
| `MasterDeviceNames` | `Manufacturer`, `Model`+ · `CustomDeviceMode`+ (o `SupportsStandardDeviceMode`) · `ChannelNameSet`* · listas con nombre (`PatchNameList`, `NoteNameList`, `ControlNameList`, `ValueNameList`) en cualquier orden | — |
| `CustomDeviceMode` | `DeviceModeEnable`?, `DeviceModeDisable`?, `ChannelNameSetAssignments`, listas* | `Name` obligatorio |
| `ChannelNameSetAssign` | — | `Channel`, `NameSet` obligatorios |
| `ChannelNameSet` | `AvailableForChannels`, (`NoteNameList`\|`UsesNoteNameList`)?, (`ControlNameList`\|`UsesControlNameList`)?, `PatchBank`+ | `Name` obligatorio |
| `AvailableChannel` | — | `Channel` obligatorio; `Available` true/false, por defecto true |
| `PatchBank` | `MIDICommands`?, `UsesPatchNameList` **o** `PatchNameList` | `Name` opcional; `ROM` true/false, por defecto false |
| `PatchNameList` | `Patch`* | `Name` opcional (en línea, sin nombre) |
| `Patch` | `PatchMIDICommands`?, `ChannelNameSetAssignments`?, notas?, controles? | `Number` y `Name` obligatorios (`Number` es CDATA: etiqueta libre); `ProgramChange` opcional |
| `ControlNameList` | `Control`+ | `Name` opcional |
| `Control` | `Values`? (con `ValueNameList` o `UsesValueNameList`) | `Type` 7bit/14bit/RPN/NRPN, por defecto 7bit; `Number`, `Name` obligatorios |
| `MIDICommands` | `MIDIDelay`, mensajes de canal (MIDIEvents 1.0) o `SysEx`, uno o más | — |
| `PatchMIDICommands` | `MIDIDelay` o mensajes de canal, uno o más (sin SysEx) | — |

Consecuencias para la app:
- Un `ChannelNameSet` necesita al menos un `PatchBank`; un `MasterDeviceNames`, al menos un modo.
- En el juego de canales, las notas van antes que los controles, y ambos antes de los bancos.
- Las listas de controles pueden ir por juego de canales **o por preset** (`Patch` → `UsesControlNameList`).
- `MIDICommands` y `PatchMIDICommands` no pueden quedar vacíos: un banco sin bank select no lleva el elemento.

## Pendiente

- Validación: `tools/validar_midnam.sh fichero.midnam…` (EXP-005). Los 6 ejemplos son válidos. El DOCTYPE de
  CherryPicker (sistema `""`) no permite validar tal cual; el script usa el canónico en una copia.
- Decidir con el usuario el DOCTYPE de los ficheros nuevos: `""` (como CherryPicker) o la URL de midi.org.
- `NoteNameList`, `StandardDeviceMode`, `SysEx` y `Values` se conservan sin tipo (fuera del alcance actual).
