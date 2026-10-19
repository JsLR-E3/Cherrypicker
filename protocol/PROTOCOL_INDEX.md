# Protocol Index — Cherrypicker

Estados: CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED. Niveles de evidencia en `docs/11_METODO_INGENIERIA_INVERSA.md`.

| Área | Estado | Fuente | Código/tests |
|---|---|---|---|
| Arranque de CherryPicker 3.0 en el Mac actual | CONFIRMED: no arranca (ppc/i386 en arm64) | EXP-001 (A) | — |
| Estructura midnam que escribe CherryPicker (modos, canales, bancos, listas) | OBSERVED | EXP-001 (B ejemplos + D `CPXMLStrings.plist`); `protocol/observed/midnam_cherrypicker.md` | `src/MidnamKit` (modelo) |
| Formato exacto de escritura (sangría, escapes, prólogo) | CONFIRMED | EXP-003 (B reproducido byte a byte + D); `protocol/confirmed/midnam_formato_escritura.md` | `src/MidnamKit`, `swift test` |
| Reglas de la DTD 1.0 (orden de hijos, obligatorios, valores por defecto) | CONFIRMED | EXP-004 (D DTD + B ejemplos) | `Model.swift`; `tools/validar_midnam.sh`; `DTDValidationTests` (EXP-005) |
| Bank select: ninguno, por banco o por preset (`PatchMIDICommands`) | OBSERVED | EXP-001 (B) | `PatchBank.Item.midiCommands`, `Patch.Item.patchMIDICommands` |
| Listas de controles con nombre (`ControlNameList`) | PARTIAL: DP conoce `UsesControlNameList` (EXP-002); sin ejemplos | — | `ControlNameList`, `Control` (sin probar en DP) |
| Dónde y cómo lee DP 11.36 los `.midnam` | OBSERVED: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` | EXP-002 (usuario + D); `protocol/observed/dp_carpeta_midnam.md` | — |
| `.middev` necesario para que un fabricante/modelo nuevo aparezca en DP | OBSERVED (falta confirmar tras reiniciar DP) | EXP-006 | — |
| Audición por CoreMIDI | UNKNOWN | — | — |
