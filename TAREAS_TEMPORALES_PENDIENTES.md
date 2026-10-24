# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-25 · local (`main`) · `.midnam` del usuario optimizados y probados en DP (8 aparatos, EXP-030 a EXP-038 y EXP-044; D-010).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **App Midnamer** (antes CherryPicker; D-006, D-011): fases 1–6 completadas (`docs/14`), `swift test` 111/111,
  `tools/empaquetar_app.sh` → `build/Midnamer.app`, 0.9.0 en `.zip` (D-013). Árbol de D-010 en Patch Banks (P22, EXP-039).
  Guía en `README.md` y Help (D-012); detalle en `docs/30`. Claude ve la app con `tools/capturar_app.sh`.
- **`.midnam` del usuario optimizados y probados en DP:** M3000, DSP-128 Plus, LXP-15 I/II, SPX2000, PCM-81, PCM-91 y
  EFX 100 (EXP-030–038, EXP-044), con la norma D-010 (• y ├ └) y marcas [F]/[M]/[E]/[T]. Copias de trabajo privadas en
  `reference/midnam_trabajo/`; manuales en `reference/manuales/<modelo>/`.
- **Instalado en DP a propósito** (cada EXP dice cómo deshacerlo): `MOTU/Cherrypicker/` (pruebas EXP-011–039) y los
  «… optimizado» / «LXP-15 … Presets|Registers» de `MOTU/TC Electronic`, `Digitech`, `Lexicon`, `Yamaha` y `Viscount`.
- **Permisos:** `MOTU/Digitech`, `Lexicon` y `Yamaha` son del usuario desde 2026-10-24 (deshacer: `sudo chown root` sobre
  las tres); `TC Electronic` ya lo era; `Viscount` es del usuario `E3` (hace falta `sudo`).
- Original en Snow Leopard para contrastar (EXP-009, EXP-012). Idea futura: `docs/40_IDEA_EDITOR_FX_BCR2000.md`.

## EN PROGRESO

- —

## PENDIENTE DE VALIDACIÓN LOCAL

Trabajo hecho (a menudo en la nube) que solo se puede dar por bueno tras probarlo en el Mac del proyecto.

| Tarea | Qué probar y cómo | Necesita | Rama/commit |
|---|---|---|---|
| — | — | — | — |

## TAREAS

| ID | Pri | Estado | Tarea (objetivo) | Depende de | Siguiente paso / criterio de aceptación |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Fichas

- —

## SIGUIENTE PASO EXACTO

0. Si llega otro `.midnam` del usuario: copiarlo a `reference/midnam_trabajo/`, leer el manual (`swift tools/pdf_a_texto.swift`;
   si es un escaneo, `swift tools/ocr_pdf.swift`; salida al scratchpad), comparar nombres y Bank Select, decidir con él y aplicar D-010, como en EXP-037/EXP-044; el árbol de D-010 ya se hace en la
   app (Patch Banks: Convert, ⌘→/⌘←, Mark as All Patches; EXP-039). Manuales en `incoming/` → `reference/manuales/<modelo>/`.
1. **Con el usuario, decidir el siguiente bloque:** repartir `build/Midnamer-0.9.0.zip` (`tools/distribuir.sh`; dónde
   publicarlo y el código fuente que pide la GPL los decide el usuario) y recoger comentarios para la 1.0 o Note Lists (fuera por ahora,
   docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
