# 16 — ARQUITECTURA

Se escribe cuando el roadmap fije los componentes. Patrón que funcionó en la FW-1884: un **helper de usuario**
(LaunchAgent, sin kext) que habla con el aparato y publica puertos virtuales; drivers ligeros del sistema (CoreMIDI,
Core Audio) que solo hablan con el helper; una app para el usuario; un canal de servicio propio entre ellos.

| Componente | Proceso | Habla con | Ficheros |
|---|---|---|---|
| MidnamKit | Biblioteca (paquete Swift) | Ficheros `.midnam` | `src/MidnamKit/` — árbol XML propio (`XMLReader`/`XMLWriter`, orden y estilo conservados) y modelo tipado (`Model.swift`) |
| CherryPickerCore | Biblioteca | MidnamKit | `src/CherryPickerApp/Sources/CherryPickerCore/` — lógica sin interfaz de las ventanas (filas de tablas…), con tests |
| CherryPicker (app) | App AppKit (D-006) | CherryPickerCore, MidnamKit; CoreMIDI en la fase 4 | `src/CherryPickerApp/Sources/CherryPicker/` — `MidnamDocument` (NSDocument, sin autoguardado; reconoce `.midnam` por extensión), ventana de documento con pestañas, menús en código; `Info.plist` y `tools/empaquetar_app.sh` → `build/CherryPicker.app` |
