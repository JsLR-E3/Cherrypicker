# 14 — ROADMAP Y VIABILIDAD

## Alcance

Funciones que el usuario usaba de CherryPicker y estado en el Mac actual (decidido con el usuario, T-005).

Uso declarado (usuario, 2026-10-19): crear **desde cero** ficheros `.midnam` de módulos de efectos para elegir sus
programas desde **Digital Performer**, con los presets **agrupados en bancos con los nombres originales** del aparato
(Halls, Rooms, Plates…) para moverse rápido por los menús de DP y saltar a un banco concreto.

Fuente de los datos (usuario, 2026-10-19): la documentación original de cada módulo (implementación MIDI, nombres de
bancos y presets). Cada aparato es distinto: bank select por CC0, CC32, ambos o ninguno, rangos de Program Change
propios. A veces el usuario escribe sus propias listas de presets y de **controles** (CC con nombre).

Cómo lo resuelven sus ejemplos (`reference/midnam_usuario/`, observado): un `ChannelNameSet` con varios `PatchBank`
con nombre de categoría, cada uno con su `PatchNameList`; el bank select (CC0/CC32) puede repetirse entre bancos, de
modo que un banco es una agrupación por nombre y no un banco físico del aparato (p. ej. M3000: «Top 20», «Halls»,
«Rooms» con CC0=0/1). PCM-81/91 usan CC32 por banco físico (P0 Halls, P1 Rooms…).

| Función | Con el software original | En el Mac actual | ¿Recuperar? |
|---|---|---|---|
| Crear un `.midnam` nuevo (fabricante, modelo, modo, canales) | CherryPicker 3.0 | La app no arranca (ppc/i386) | **Sí** |
| Bancos con nombre y bank select (CC0/CC32) por banco | CherryPicker | — | **Sí** |
| Escribir/pegar listas de nombres de presets en un banco | CherryPicker (pegar texto con delimitador) | — | **Sí** |
| Mover/copiar presets entre bancos de agrupación | CherryPicker (arrastrar) | — | **Sí** |
| Bank select configurable por banco según la implementación MIDI de cada aparato (CC0, CC32, ambos, ninguno) | CherryPicker | — | **Sí** |
| Listas de controles con nombre (`ControlNameList`) | CherryPicker (`CPControllerList`) | — | **Sí** |
| Abrir y editar los `.midnam` existentes sin pérdidas | CherryPicker | — | **Sí** |
| Que DP lea el fichero y muestre los bancos agrupados | DP | Por comprobar con la versión actual de DP | **Sí** (criterio de éxito) |
| Audición: enviar Bank Select + Program Change al módulo desde la lista para probar antes de exportar | CherryPicker (CoreMIDI) | — | **Sí** (usuario, 2026-10-19) |
| Sibelius, Cubase/FreeMIDI/OMS, Gigastudio, notas (drum maps) | CherryPicker | — | No por ahora |

Decisiones (usuario, 2026-10-19): DAW de destino **Digital Performer 11.36**; editor como **app nativa de macOS parecida
a CherryPicker** (misma organización y nombres; las mejoras se proponen antes).

## Fases

| Fase | Objetivo | Viabilidad | Riesgo principal | Estado |
|---|---|---|---|---|
| 1 | Modelo de datos midnam + lectura/escritura sin pérdidas (paquete Swift con tests) | Alta: XML documentado (DTD 0.7/1.0 MMA) y 6 ejemplos reales | Elementos poco usados que se pierdan al reescribir | COMPLETADA (MidnamKit, EXP-003/004/005) |
| 2 | Dónde y cómo lee DP 11.36 los `.midnam`; prueba con un ejemplo del usuario | Alta | Ruta o caché propia de DP sin documentar | COMPLETADA (EXP-002, EXP-006, T-012) |
| 3 | App: documento, modos/canales, bancos con bank select por banco, listas de presets, pegar listas con delimitador, arrastrar entre bancos | Alta | Volumen de UI; partir de las ventanas de CherryPicker (nibs y manual) | EN PROGRESO (diseño `docs/20`, D-005, D-006) |
| 4 | Audición por CoreMIDI (Bank Select + Program Change al destino elegido) | Alta | Enviar a un aparato real: solo con permiso; solo mensajes de selección, nunca SysEx | COMPLETADA (T-021, EXP-017/018) |
| 5 | Listas de controles con nombre (`ControlNameList`) | Alta | Cómo las muestra DP | PENDIENTE |
| 6 | Exportar/instalar en la carpeta que lee DP y validar en DP 11.36 | Alta | — | COMPLETADA («Install in DP…», T-024, EXP-022) |

Restricciones globales: Mac de destino Apple Silicon (arm64) con macOS 15.7.9; la app original no puede ejecutarse aquí,
así que su comportamiento se toma del manual, las notas de versión, los recursos y los ficheros que generó.
