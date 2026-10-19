# Dónde lee DP 11.36 los .midnam — OBSERVED

EXP-002. Carpeta: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/<Modelo>.midnam` (escribible sin administrador).
Los `.middev` (MIDIDeviceTypes 0.3) van por fabricante: `MOTU/<Fabricante>.middev` o `MOTU/<Fabricante>/<Fabricante>.middev`.

DP 11.36 (`MidiSystem.framework`) conoce DTD 1.0, incluidos `UsesControlNameList` y `ExtendingDeviceNames`.

## Pendiente de comprobar en DP (nivel A, con el usuario)

1. ¿Aparece un modelo sin entrada en ningún `.middev` (M3000, LXP-15 II)? Si aparece, el `.middev` no es necesario.
2. ¿Carga DP ficheros que no terminan en `.midnam` (`M3000.midnam copia`)?
3. ¿Hay que reiniciar DP tras añadir o cambiar un fichero?
