# reference/ (no versionado)

Material de terceros: drivers, programas, manuales, firmware, código abierto de referencia. Se conserva localmente y
no se sube a GitHub. Lo que llega a `incoming/` se archiva aquí (T-003) conservando la estructura original del usuario.

| Carpeta | Contenido | Origen y fecha |
|---|---|---|
| `app_3.0/CherryPicker.app` | CherryPicker 3.0 (© 2003-2009 Rob Martin, alterSpective), binario universal ppc_7400 + i386. SHA-256 del ejecutable `21595a85…` | Usuario, incoming 2026-10-19 |
| `web_alterspective/` | Web original `alterspective.com/cherrypicker/` desde Wayback: manual `docs/introC.html`, páginas de capturas, CSS, `CherryPicker262.dmg` y `CherryMangler.dmg`. Imágenes perdidas detalladas en `LEEME_DESCARGA.txt` | web.archive.org, descargado 2026-10-19 |
| `extracted/CherryPicker262/` | Contenido del dmg 2.62 (montado solo lectura): app 2.62 + `2.62 Release Notes.rtf` | De `CherryPicker262.dmg`, 2026-10-19 |
| `midnam_usuario/` | **PRIVADO.** 6 ficheros `.midnam` del usuario: DSP-128 Plus, LXP-15, LXP-15 II, M3000 (hechos con CherryPicker), PCM-81 y PCM-91 (convertidos de FreeMIDI por MOTU). Muestras de prueba; nunca se publican ni se copian a `tests/` sin permiso | Usuario, incoming 2026-10-19 |
| `midnam_trabajo/` | **PRIVADO.** Copias de trabajo del usuario editadas con la app (no son originales): `DSP-128 Plus.midnam` con presets agrupados en bancos (EXP-029) `M3000 optimizado.midnam` (T-030, instalada en DP, EXP-030) y `M3000 prueba.midnam`, la copia corregida de EXP-023 que está instalada en DP (sha256 `ca606485a51d1837…`, igual a la instalada). El usuario sigue optimizándola; no se borra ni se sobrescribe sin su permiso | Usuario, 2026-10-24 |
| `manuales/DSP-128 Plus/` | Digitech DSP 128 plus: manual de usuario (PDF escaneado, sin texto: se lee con OCR) y «cheatsheet» de algoritmos | Usuario, incoming 2026-10-24 |
| `manuales/LXP-15/` | Lexicon LXP-15 y LXP-15 II: manuales de usuario (PDF con texto) | Usuario, incoming 2026-10-24 |
| `manuales/M3000/` | TC Electronic M3000: manual (inglés), addendum «Film and Post Production» rev. 1.3 y «M3000 MIDI specification» v1.01 (PDF) | Usuario, incoming 2026-10-24 |

| `dtd/MIDIEvents10.dtd` | DTD MIDIEvents 1.0 de la MMA (incluida por la anterior), 6363 bytes. Copia de Wayback (captura 2003-08-22) | web.archive.org, descargado 2026-10-19 con permiso |
| `dtd/MIDINameDocument10.dtd` | DTD MIDINameDocument 1.0 de la MMA (19-01-2003), 4498 bytes, CRLF. midi.org da 404; copia de Wayback (captura 2003-08-22) | web.archive.org, descargado 2026-10-19 con permiso |

`CherryMangler.dmg` está **truncado** en Wayback (130 789 de 211 823 bytes originales): no monta ni se puede reconstruir.

`extracted/`: contenido de instaladores, imágenes de disco y paquetes extraídos **sin instalar** (`pkgutil --expand`,
`hdiutil attach -readonly`).
