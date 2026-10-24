# Protocol Index — Cherrypicker

Estados: CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED. Niveles de evidencia en `docs/11_METODO_INGENIERIA_INVERSA.md`.

| Área | Estado | Fuente | Código/tests |
|---|---|---|---|
| Arranque de CherryPicker 3.0 en el Mac actual | CONFIRMED: no arranca (ppc/i386 en arm64) | EXP-001 (A) | — |
| Estructura midnam que escribe CherryPicker (modos, canales, bancos, listas) | OBSERVED | EXP-001 (B ejemplos + D `CPXMLStrings.plist`); `protocol/observed/midnam_cherrypicker.md` | `src/MidnamKit` (modelo) |
| Formato exacto de escritura (sangría, escapes, prólogo) | CONFIRMED | EXP-003 (B reproducido byte a byte + D); `protocol/confirmed/midnam_formato_escritura.md` | `src/MidnamKit`, `swift test` |
| Reglas de la DTD 1.0 (orden de hijos, obligatorios, valores por defecto) | CONFIRMED | EXP-004 (D DTD + B ejemplos) | `Model.swift`; `tools/validar_midnam.sh`; `DTDValidationTests` (EXP-005) |
| Bank select: ninguno, por banco o por preset (`PatchMIDICommands`) | OBSERVED | EXP-001 (B) | `PatchBank.Item.midiCommands`, `Patch.Item.patchMIDICommands` |
| Listas de controles con nombre (`ControlNameList`) | CONFIRMED (no se usan): DP 11.36 conoce `UsesControlNameList` (EXP-002) y lee el fichero, pero no muestra los nombres en el menú de controladores de la pista (EXP-006) ni en «Other Controller…», que solo pide un número, ni en la Legend; el manual de DP 11 no los menciona (EXP-027) | EXP-006, EXP-027 (A; manual) | `ControlNameList`, `Control` |
| Dónde y cómo lee DP 11.36 los `.midnam` | OBSERVED: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` | EXP-002 (usuario + D); `protocol/observed/dp_carpeta_midnam.md` | — |
| `.middev` para que un fabricante/modelo nuevo salga en la lista de Audio MIDI | CONFIRMED: sin él no sale en los desplegables, pero escribiéndolo a mano en Configuración de Audio MIDI (fabricante y modelo exactos) DP usa el `.midnam` igual | EXP-006 (A), EXP-021 (A) | — |
| DP acepta el DOCTYPE de midi.org; *Master Names* = nombre de fichero; menú de presets = nombre de `PatchNameList` + «Number Name»; recarga al volver a elegir en *Master Names* | CONFIRMED | EXP-006 (A); EXP-013 (A): orden del fichero, patch sin nombre = solo «Number» | `MidnamFile.newFileProlog` |
| Hoja Bank Selects del original: qué hace cada opción con los patches | CONFIRMED | EXP-009 (B, reproducido byte a byte) | `BankEditing.swift`, `testBankSelectOptionsMatchOriginal` |
| DP 11.36 lee lo que escribe la app; bancos por canal según `ChannelNameSet`; un solo banco en el juego = presets sin submenú | CONFIRMED | EXP-011 (A) | `src/CherryPickerApp` |
| DP 11.36 con el mismo sonido (bank select + Program Change) en dos bancos: tras elegirlo desde un Custom Bank, el menú marca el banco de fábrica; sin el duplicado (Zap Dups) se queda en el Custom Bank; poner el Custom Bank delante no cambia nada | CONFIRMED | EXP-015 (A) | `BankTools.swift` (`zapDuplicates`) |
| DP 11.36 lee varios `.middev` en la misma carpeta de fabricante y junta sus modelos en la lista | CONFIRMED | EXP-022 (A) | `InstallInDP.swift` |
| Menú de presets de DP 11.36: un solo nivel de submenús, en el orden del fichero; nombres de banco con Unicode («• », «├ », «└ », flechas…) y espacios iniciales se ven bien; «●» se ve demasiado grande | CONFIRMED | EXP-033, EXP-034 (A) | D-010; Patch Banks (P22) |
| DP 11.36 sin barrido de presets por teclado: *Next/Previous Patch* (Commands, grupo Sound Selection) cambian el *Default Patch*, que solo se manda con REC y Play; los menús no responden a flechas ni a escribir | CONFIRMED | EXP-036 (A + B manual) | Audición de la app (↑/↓) |
| Bank Select de los aparatos optimizados (CC0/CC32 por banco o por patch, Program Change) contrastado con sus manuales y probado en DP | CONFIRMED | EXP-030 a EXP-032, EXP-035, EXP-037, EXP-038, EXP-044 (A) | — |
| DP 11.36 con canales sin `ChannelNameSetAssign` en el modo: «No Patches» en ese canal; un banco vacío no sale en el menú | CONFIRMED | EXP-016 (A) | `DeviceEditing.swift` |
| Audición por CoreMIDI (CC0/CC32 + Program Change, UMP MIDI 1.0) | CONFIRMED | EXP-017 (A, destino virtual), EXP-018 (A, M3000) | `Audition.swift`, `MIDIOut.swift` |
