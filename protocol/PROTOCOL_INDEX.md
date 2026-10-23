# Protocol Index — Cherrypicker

Estados: CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED. Niveles de evidencia en `docs/11_METODO_INGENIERIA_INVERSA.md`.

| Área | Estado | Fuente | Código/tests |
|---|---|---|---|
| Arranque de CherryPicker 3.0 en el Mac actual | CONFIRMED: no arranca (ppc/i386 en arm64) | EXP-001 (A) | — |
| Estructura midnam que escribe CherryPicker (modos, canales, bancos, listas) | OBSERVED | EXP-001 (B ejemplos + D `CPXMLStrings.plist`); `protocol/observed/midnam_cherrypicker.md` | `src/MidnamKit` (modelo) |
| Formato exacto de escritura (sangría, escapes, prólogo) | CONFIRMED | EXP-003 (B reproducido byte a byte + D); `protocol/confirmed/midnam_formato_escritura.md` | `src/MidnamKit`, `swift test` |
| Reglas de la DTD 1.0 (orden de hijos, obligatorios, valores por defecto) | CONFIRMED | EXP-004 (D DTD + B ejemplos) | `Model.swift`; `tools/validar_midnam.sh`; `DTDValidationTests` (EXP-005) |
| Bank select: ninguno, por banco o por preset (`PatchMIDICommands`) | OBSERVED | EXP-001 (B) | `PatchBank.Item.midiCommands`, `Patch.Item.patchMIDICommands` |
| Listas de controles con nombre (`ControlNameList`) | PARTIAL: DP conoce `UsesControlNameList` (EXP-002) pero no la usa en el menú de controladores de la pista (EXP-006); falta «Other Controller…» | EXP-006 (A) | `ControlNameList`, `Control` |
| Dónde y cómo lee DP 11.36 los `.midnam` | OBSERVED: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` | EXP-002 (usuario + D); `protocol/observed/dp_carpeta_midnam.md` | — |
| `.middev` para que un fabricante/modelo nuevo salga en la lista de Audio MIDI | CONFIRMED (a mano también funcionaría: por confirmar) | EXP-006 (A) | — |
| DP acepta el DOCTYPE de midi.org; *Master Names* = nombre de fichero; menú de presets = nombre de `PatchNameList` + «Number Name»; recarga al volver a elegir en *Master Names* | CONFIRMED | EXP-006 (A); EXP-013 (A): orden del fichero, patch sin nombre = solo «Number» | `MidnamFile.newFileProlog` |
| Hoja Bank Selects del original: qué hace cada opción con los patches | CONFIRMED | EXP-009 (B, reproducido byte a byte) | `BankEditing.swift`, `testBankSelectOptionsMatchOriginal` |
| DP 11.36 lee lo que escribe la app; bancos por canal según `ChannelNameSet`; un solo banco en el juego = presets sin submenú | CONFIRMED | EXP-011 (A) | `src/CherryPickerApp` |
| DP 11.36 con el mismo sonido (bank select + Program Change) en dos bancos: tras elegirlo desde un Custom Bank, el menú marca el banco de fábrica; sin el duplicado (Zap Dups) se queda en el Custom Bank; poner el Custom Bank delante no cambia nada | CONFIRMED | EXP-015 (A) | `BankTools.swift` (`zapDuplicates`) |
| DP 11.36 con canales sin `ChannelNameSetAssign` en el modo: «No Patches» en ese canal; un banco vacío no sale en el menú | CONFIRMED | EXP-016 (A) | `DeviceEditing.swift` |
| Audición por CoreMIDI (CC0/CC32 + Program Change, UMP MIDI 1.0) | CONFIRMED | EXP-017 (A, destino virtual), EXP-018 (A, M3000) | `Audition.swift`, `MIDIOut.swift` |
