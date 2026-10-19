# 11 — MÉTODO DE INGENIERÍA INVERSA

Heredado de los proyectos Emagic Unitor8 y TASCAM FW-1884 (plantilla común).

> **Observar → comprobar → documentar → implementar.**
> No: suponer → implementar → considerar confirmado porque funciona.

## Niveles de evidencia

| Nivel | Fuente |
|---|---|
| A | Observado con el hardware real en este proyecto (captura reproducible) |
| B | Comportamiento del driver o programa original observado en ejecución (sistema histórico) |
| C | Código abierto de terceros contrastado (p. ej. drivers de Linux) |
| D | Documentación del fabricante o análisis estático de binarios |

Un dato es **CONFIRMED** solo con nivel A o B, o con C+D coincidentes. El resto es OBSERVED / HYPOTHESIS.

## Estados (ver `protocol/PROTOCOL_INDEX.md`)

CONFIRMED · PARTIAL · OBSERVED · UNKNOWN · DISCARDED

Cada área del protocolo vive en `protocol/<estado>/` cuando necesita más de una línea del índice. Lo descartado se
conserva con el motivo: evita volver a probarlo.

## Reglas para el hardware

- Lecturas de identificación (descriptores, versiones, registros de identificación): permitidas.
- Escrituras (registros, SysEx que cambie la memoria del aparato, volcados): solo lo documentado por el software
  original o por código abierto contrastado, y con permiso del usuario. Antes de cambiar la memoria del aparato, hacer
  copia de lo que contiene si el protocolo lo permite.
- **Nunca** actualizadores de firmware.
- Cada prueba se registra en `13_REGISTRO_DE_EXPERIMENTOS.md` con fecha, herramienta, entrada y resultado.

## Flujo de un experimento

1. Hipótesis escrita (en `protocol/hypotheses/` o en la tarea).
2. EXP con su número **antes** de probar: objetivo y procedimiento.
3. Captura reproducible en `captures/<área>/` (salida de la herramienta, volcado, fotografía descrita).
4. Resultado y conclusión con su nivel; actualizar `PROTOCOL_INDEX.md`.

## Herramientas habituales (sin instalar nada sin permiso)

| Para | Herramienta |
|---|---|
| USB | `system_profiler SPUSBDataType`, `ioreg -p IOUSB -l -w0`, descriptores con IOUSBHost |
| FireWire | `ioreg -c IOFireWireDevice`, IOFireWireLib |
| MIDI | Configuración de Audio MIDI, utilidades propias con CoreMIDI en `tools/` |
| Binarios originales | `otool`, `nm`, `strings`, Ghidra en modo headless con scripts en `tools/ghidra/` |
| Paquetes antiguos | `pkgutil --expand`, `hdiutil` (sin instalar: solo extraer en `reference/extracted/`) |
