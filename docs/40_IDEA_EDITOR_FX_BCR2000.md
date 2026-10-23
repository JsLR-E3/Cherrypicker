# 40 — Idea para un proyecto futuro: editor de efectos con el BCR2000

Anotada: 2026-10-23 (conversación con el usuario). **No es una tarea de Cherrypicker** ni entra en su alcance (D-001).
**Cuándo:** al terminar los proyectos de BCR2000 y Cherrypicker, para aprovechar lo hecho en los dos. Lo que sigue es una
primera valoración de viabilidad, de memoria y **sin comprobar**: todo dato sobre los aparatos es una hipótesis hasta
contrastarlo con sus manuales y probarlo.

## La idea

Una app para el Mac que conecte por MIDI con los efectos del usuario (**TC Electronic M3000, Lexicon PCM91, PCM81…**) y
use el **BCR2000** para editar sus parámetros según el manual de cada uno, como ahora con los presets que el usuario tiene
hechos en el BCR, pero además:

- ver en pantalla todos los parámetros con su nombre y su valor en unidades reales (ms, Hz, dB, %);
- una representación gráfica de los parámetros (curva del EQ, envolvente de la reverb, tiempos de delay…);
- grabar: librería de presets propia en el Mac, y enviarlos al aparato o pedírselos.

## Esquema previsto

```
BCR2000 ──CC/NRPN──▶ app (Mac) ──SysEx──▶ M3000 / PCM91 / PCM81
   ▲                    │  ▲
   └──valores (anillos)─┘  └──volcados de parámetros y nombres
```

- **BCR2000 con un preset genérico fijo**: los mandos envían CC/NRPN y la app decide qué parámetro controla cada uno
  según aparato, algoritmo y página. Ya no hace falta un preset del BCR por aparato.
- **La app traduce** cada movimiento al mensaje del aparato (normalmente SysEx de edición de parámetro).
- **Respuesta al BCR**: la app devuelve los valores y los anillos de LED se colocan solos al cambiar de preset o de página.
- **La pantalla pone los nombres** (el BCR no tiene pantalla de texto).

## Dificultades previstas

1. **Documentación por aparato**: describir cada parámetro (dirección, rango, cómo se muestra el valor, dependencias).
   Es el grueso del trabajo; se parece a lo hecho con los `.midnam` y probablemente convenga un formato de fichero propio
   de «perfil de aparato».
2. **Parámetros que cambian con el algoritmo** (los PCM tienen un juego distinto en cada algoritmo): el mapa del BCR
   tiene que cambiar al cambiar el algoritmo.
3. **Resolución**: el BCR envía 7 bits por defecto; para parámetros finos, NRPN de 14 bits (a comprobar en el BCR).
4. **Seguridad de los aparatos**: este proyecto **sí** escribiría en su memoria, justo lo que Cherrypicker prohíbe
   (regla 4, D-002). Necesitará sus propias reglas; la primera, hacer una copia completa de cada aparato antes de tocar
   nada, y probar primero solo lectura.
5. **Equipos antiguos**: posibles límites de velocidad MIDI, volcados con checksum y reparto de puertos o merge MIDI.

## Fases propuestas

1. Un solo aparato (el que tenga la especificación SysEx más completa; candidato: PCM91): leer un preset y mostrarlo,
   solo lectura.
2. Edición en los dos sentidos con el BCR y los anillos siguiendo los valores.
3. Librería en el Mac (guardar, enviar, pedir).
4. Resto de aparatos.

## Qué aprovechar de los proyectos actuales

- **Cherrypicker**: CoreMIDI en Swift, la app en AppKit, empaquetado, captura de ventanas, el método de observar,
  comprobar, documentar e implementar (`11`), el registro de experimentos (`13`) y la organización del repositorio y de
  las sesiones con Claude (`10`, `/inicio`, `/cierre`).
- **Proyecto BCR2000**: lo que se sepa allí del BCR (presets, CC/NRPN, respuesta de los anillos, SysEx del BCR) y los
  presets que el usuario ya usa con estos efectos, como punto de partida de los mapas.

## Preguntas abiertas para cuando empiece

- ¿Qué documentación MIDI/SysEx hay de cada aparato (manual, apéndices, especificaciones aparte)?
- ¿Qué editores existentes hubo para estos aparatos (como referencia de interfaz, no para copiar)?
- ¿Un BCR2000 para todos los aparatos a la vez o uno cada vez? ¿Hace falta BCF2000 o BCR adicional?
- ¿Se integra con DP 11.36 (por ejemplo, convivir en los mismos puertos MIDI) o funciona aparte?
