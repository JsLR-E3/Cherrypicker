# 16 — ARQUITECTURA

Se escribe cuando el roadmap fije los componentes. Patrón que funcionó en la FW-1884: un **helper de usuario**
(LaunchAgent, sin kext) que habla con el aparato y publica puertos virtuales; drivers ligeros del sistema (CoreMIDI,
Core Audio) que solo hablan con el helper; una app para el usuario; un canal de servicio propio entre ellos.

| Componente | Proceso | Habla con | Ficheros |
|---|---|---|---|
| — | — | — | — |
