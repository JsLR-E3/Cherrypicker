# reference/ (no versionado)

Material de terceros: drivers, programas, manuales, firmware, código abierto de referencia. Se conserva localmente y
no se sube a GitHub. Lo que llega a `incoming/` se archiva aquí (T-003) conservando la estructura original del usuario.

| Carpeta | Contenido | Origen y fecha |
|---|---|---|
| `app_3.0/CherryPicker.app` | CherryPicker 3.0 (© 2003-2009 Rob Martin, alterSpective), binario universal ppc_7400 + i386. SHA-256 del ejecutable `21595a85…` | Usuario, incoming 2026-10-19 |
| `web_alterspective/` | Web original `alterspective.com/cherrypicker/` desde Wayback: manual `docs/introC.html`, páginas de capturas, CSS, `CherryPicker262.dmg` y `CherryMangler.dmg`. Imágenes perdidas detalladas en `LEEME_DESCARGA.txt` | web.archive.org, descargado 2026-10-19 |
| `extracted/CherryPicker262/` | Contenido del dmg 2.62 (montado solo lectura): app 2.62 + `2.62 Release Notes.rtf` | De `CherryPicker262.dmg`, 2026-10-19 |
| `midnam_usuario/` | **PRIVADO.** 6 ficheros `.midnam` del usuario: DSP-128 Plus, LXP-15, LXP-15 II, M3000 (hechos con CherryPicker), PCM-81 y PCM-91 (convertidos de FreeMIDI por MOTU). Muestras de prueba; nunca se publican ni se copian a `tests/` sin permiso | Usuario, incoming 2026-10-19 |

`CherryMangler.dmg` está **truncado** en Wayback (130 789 de 211 823 bytes originales): no monta ni se puede reconstruir.

`extracted/`: contenido de instaladores, imágenes de disco y paquetes extraídos **sin instalar** (`pkgutil --expand`,
`hdiutil attach -readonly`).
