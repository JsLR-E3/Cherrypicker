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

## Pendiente

- Contrastar con la DTD 1.0 de la MMA (descarga pendiente de permiso del usuario): orden de hijos válido, atributos
  obligatorios y forma de `Control` con valores con nombre.
- `NoteNameList`, `StandardDeviceMode`, `SysEx` se conservan sin tipo (fuera del alcance actual).
