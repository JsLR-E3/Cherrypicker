# Dónde lee DP 11.36 los .midnam — HYPOTHESIS

- `Defaults.plist` de CherryPicker 3.0 usa `/Library/Audio/MIDI Devices/MOTU` como carpeta de patches de MOTU y
  `/Library/Audio/MIDI Devices` para los `.middev` (D, EXP-001).
- Por comprobar en T-008 (solo lectura): qué hay hoy en esa carpeta y en `~/Library/Audio/MIDI Devices`, si DP 11.36
  sigue leyendo de ahí y si necesita reiniciarse o tiene caché. Copiar ficheros allí solo con permiso del usuario.
