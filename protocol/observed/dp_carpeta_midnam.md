# Dónde y cómo usa DP 11.36 los .midnam — OBSERVED

EXP-002. Carpeta: `/Library/Audio/MIDI Devices/MOTU/<Fabricante>/<Modelo>.midnam` (escribible sin administrador).
Los `.middev` (MIDIDeviceTypes 0.3) van por fabricante: `MOTU/<Fabricante>.middev` o `MOTU/<Fabricante>/<Fabricante>.middev`.

DP 11.36 (`MidiSystem.framework`) conoce DTD 1.0, incluidos `UsesControlNameList` y `ExtendingDeviceNames`.

## Cómo se asigna en DP (A: usuario + captura `captures/exp002/dp_bundles_midi_device_properties.png`)

1. El dispositivo se crea en Configuración de Audio MIDI (nombre, fabricante, modelo) y se conecta a un puerto.
2. En DP, *Bundles → MIDI Devices → MIDI Device Properties → Patches*: **Port** y **Master Names** (el `.midnam`).
3. DP lista los `PatchBank` del fichero por su nombre y en su orden, con **Override** por banco (`Default`).
4. ~~No hace falta `.middev`~~ **Corregido en EXP-006:** *Manufacturer* y *Model* del dispositivo salen de los
   `.middev`; el M3000 está en `Digidesign Device List.middev`. Un modelo nuevo necesita su `.middev` además del
   `.midnam`. La app tendrá que crear o actualizar ambos.

## Pendiente (A, con permiso del usuario)

- ¿Recarga DP un `.midnam` cambiado sin reiniciar, o hay que volver a elegirlo en *Master Names*?
- ¿Qué nombre muestra *Master Names*: `Model` del fichero, nombre de fichero o `CustomDeviceMode`?
- `M3000.midnam copia` (resto de pruebas): ¿lo lee DP? Retirarlo lo decide el usuario.
