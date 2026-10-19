# Protocol Index — Cherrypicker

Estados: CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED. Niveles de evidencia en `docs/11_METODO_INGENIERIA_INVERSA.md`.

| Área | Estado | Fuente | Código/tests |
|---|---|---|---|
| Arranque de CherryPicker 3.0 en el Mac actual | CONFIRMED: no arranca (ppc/i386 en arm64) | EXP-001 (A) | — |
| Estructura midnam que escribe CherryPicker (modos, canales, bancos, listas) | OBSERVED | EXP-001 (B ejemplos + D `CPXMLStrings.plist`); `protocol/observed/midnam_cherrypicker.md` | — |
| Bank select: ninguno, por banco o por preset (`PatchMIDICommands`) | OBSERVED | EXP-001 (B) | — |
| Listas de controles con nombre (`ControlNameList`) | UNKNOWN | — | — |
| Dónde y cómo lee DP 11.36 los `.midnam` | OBSERVED: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/` | EXP-002 (usuario + D); `protocol/observed/dp_carpeta_midnam.md` | — |
| Audición por CoreMIDI | UNKNOWN | — | — |
