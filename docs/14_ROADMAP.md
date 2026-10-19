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
| Audición, Sibelius, Cubase/FreeMIDI/OMS, Gigastudio, notas (drum maps) | CherryPicker | — | Por decidir |

## Fases

| Fase | Objetivo | Viabilidad | Riesgo principal | Estado |
|---|---|---|---|---|
| 1 | — | — | — | — |

Restricciones globales: —
