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

## Confirmado en EXP-006 (A)

- DP 11.36 acepta ficheros nuevos de MidnamKit con el DOCTYPE de midi.org.
- *Master Names* = **nombre del fichero** sin extensión. La app debe proponer el nombre de fichero pensando en eso.
- *Manufacturer*/*Model* se eligen en Configuración de Audio MIDI; la lista sale de los `.middev`. Con `.middev` el
  modelo aparece en la lista; a mano también funcionaría (usuario, por confirmar).

- Menú de presets de la pista: submenú = nombre de la **`PatchNameList`**; preset = «`Number` `Name`». El nombre del
  `PatchBank` solo se ve en *MIDI Device Properties*. Regla para la app (como CherryPicker): lista y banco con el
  mismo nombre.
- Menú de controladores de la pista: no usa `ControlNameList` (nombres estándar de DP).

- Recarga: DP no detecta solo un fichero cambiado; se recarga al volver a elegirlo en *Master Names* (sin
  reiniciar). La app debe recordarlo al guardar sobre un fichero instalado.

## Pendiente (A, con permiso del usuario)

- `M3000.midnam copia` (resto de pruebas): ¿lo lee DP? Retirarlo lo decide el usuario.
- ¿Usa DP las `ControlNameList` en «Other Controller…» o en otro sitio?
- ¿Basta escribir a mano fabricante y modelo en Audio MIDI sin `.middev`? (recuerdo del usuario)
