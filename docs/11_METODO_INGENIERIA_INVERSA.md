# 11 — MÉTODO DE INGENIERÍA INVERSA

Heredado de los proyectos Emagic Unitor8 y TASCAM FW-1884 (plantilla común), adaptado a un **programa**: aquí se
estudian los ficheros que CherryPicker lee y escribe (`.midnam`) y cómo los usa Digital Performer 11.36.

> **Observar → comprobar → documentar → implementar.**
> No: suponer → implementar → considerar confirmado porque funciona.

## Niveles de evidencia

| Nivel | Fuente |
|---|---|
| A | Observado en este proyecto con el destino real: DP 11.36 leyendo el fichero, o el módulo respondiendo a la audición (captura reproducible) |
| B | Programa original en ejecución (sistema histórico o VM) **o ficheros generados por él** (los `.midnam` del usuario con `<Author>CherryPicker`) |
| C | Código abierto de terceros contrastado (otros lectores/editores de midnam) |
| D | Documentación: especificación y DTD MIDINameDocument (MMA), manual y notas de CherryPicker, documentación MIDI de cada módulo; análisis estático del binario y sus recursos |

Un dato es **CONFIRMED** solo con nivel A o B, o con C+D coincidentes. El resto es OBSERVED / HYPOTHESIS.

## Estados (ver `protocol/PROTOCOL_INDEX.md`)

CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED

Cada área del protocolo vive en `protocol/<estado>/` cuando necesita más de una línea del índice. Lo descartado se
conserva con el motivo: evita volver a probarlo.

## Reglas para ficheros y aparatos

- Ficheros del usuario: solo lectura. Las pruebas de escritura se hacen sobre copias y se comparan con el original
  (ida y vuelta sin pérdidas: mismo contenido semántico; las diferencias de formato se documentan).
- DP: copiar un fichero a la carpeta de la que lee DP, o tocar sus preferencias, solo con permiso del usuario y
  dejando constancia de cómo deshacerlo.
- Audición: solo Bank Select (CC0/CC32) y Program Change al destino que elija el usuario, con su permiso. **Nunca**
  SysEx, volcados ni mensajes que cambien la memoria del módulo.
- La app original no se ejecuta en este Mac (ppc/i386); no se instala Rosetta ni emuladores sin permiso.
- Cada prueba se registra en `13_REGISTRO_DE_EXPERIMENTOS.md` con fecha, herramienta, entrada y resultado.

## Flujo de un experimento

1. Hipótesis escrita (en `protocol/hypotheses/` o en la tarea).
2. EXP con su número **antes** de probar: objetivo y procedimiento.
3. Captura reproducible en `captures/<área>/` (salida de la herramienta, volcado, fotografía descrita).
4. Resultado y conclusión con su nivel; actualizar `PROTOCOL_INDEX.md`.

## Herramientas habituales (sin instalar nada sin permiso)

| Para | Herramienta |
|---|---|
| XML midnam | `xmllint` (validación contra la DTD), `plutil`, scripts propios en `tools/` |
| MIDI | Configuración de Audio MIDI, utilidades propias con CoreMIDI en `tools/` (monitor, envío de PC/Bank Select) |
| Recursos de la app | `plutil -p`, nibs compilados con `plutil`/`ibtool` si está disponible, `textutil` para `.rtf` |
| Binarios originales | `otool`, `nm`, `strings`, Ghidra en modo headless con scripts en `tools/ghidra/` |
| Paquetes antiguos | `pkgutil --expand`, `hdiutil` (sin instalar: solo extraer en `reference/extracted/`) |
