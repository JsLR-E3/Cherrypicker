# TAREAS TEMPORALES PENDIENTES — Cherrypicker

> Continuidad: **solo el estado vivo.** Reglas en `CLAUDE.md`; procedimientos en `/inicio` y `/cierre`.
> Al cerrar, lo COMPLETADO sale de aquí a `docs/15_HISTORIAL.md` (una línea por tarea) y ESTADO ACTUAL se reescribe,
> no se amplía. Objetivo: que este fichero quepa en una lectura (< 150 líneas).
> Actualizado: 2026-10-24 · local (`main`) · T-035: Midnamer, con icono y textos propios y GPL-3.0 (D-011, EXP-041); T-036: guía en inglés en README y en Help (D-012, EXP-042); T-037: 0.9.0 universal en .zip (D-013, EXP-043).

<!-- Estados: PENDIENTE · EN PROGRESO · BLOQUEADA (por qué) · IMPLEMENTADA (sin verificar) ·
     PENDIENTE-LOCAL (hecha; falta probarla en el Mac/aparato) · COMPLETADA (verificada: qué se ejecutó y resultado).
     Prioridad: A (lo siguiente) · B · C. Una tarea con varios pasos o archivos lleva su ficha en «Fichas». -->

## ESTADO ACTUAL

- **Fases 1 a 6 del roadmap completadas** (`docs/14`). App AppKit `src/CherryPickerApp` (D-006; `swift test` 111/111;
  `tools/empaquetar_app.sh` → `build/Midnamer.app`; nombre, icono y licencia GPL-3.0 de D-011) con todas las pestañas: MIDI (audición y Test Note, D-008),
  Device, Patch Banks, Controllers (D-009; DP no la usa, EXP-027) y Categories; Patch Names con Find, Copy...,
  arrastre entre documentos y banco nuevo desde la selección (P21); árbol de D-010 en Patch Banks (P22, EXP-039: Indent ⌘→, Outdent ⌘←, Mark as All Patches); asistente New; «Install in DP…». Guía en inglés en `README.md` y en Help (D-012; al cambiar la app, actualizarla); detalle en `docs/30`.
- Claude ve la app con `tools/capturar_app.sh` (solo ventanas de Midnamer); el usuario la maneja.
- **Original** en Snow Leopard (Mac mini) para contrastar (EXP-009, EXP-012); allí queda un `.middev` «Prueba / Prueba».
- **Instalación de prueba que se deja a propósito:** `/Library/Audio/MIDI Devices/MOTU/Cherrypicker/` (EXP-011 a
  EXP-022, EXP-027 y EXP-039, que añadió «CP Arbol» a su `.middev`; cada EXP dice cómo deshacer lo suyo). Deshacer todo: borrar esa carpeta.
  Además, `MOTU/TC Electronic/M3000 optimizado.midnam` (EXP-030) y
  `MOTU/Digitech/DSP-128 Plus optimizado.midnam` (EXP-031, con `sudo`),
  `MOTU/Lexicon/LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (EXP-032/034, con `sudo`),
  `MOTU/Yamaha/SPX2000 optimizado.midnam` (EXP-034), `MOTU/Lexicon/PCM-81 optimizado.midnam` (EXP-037), `MOTU/Lexicon/PCM-91 optimizado.midnam` (EXP-038); deshacer: borrar esos ficheros. Los demás de esas
  carpetas son del usuario.
- **Permisos de DP cambiados por el usuario** (2026-10-24, con `sudo chown jslr`): las carpetas `MOTU/Digitech`,
  `MOTU/Lexicon` y `MOTU/Yamaha` son del usuario (antes `root:wheel`, `drwxrwxr-x`; los ficheros de dentro no se tocaron)
  para copiar sin contraseña; `MOTU/TC Electronic` ya era suya. Los ficheros copiados antes con `sudo` siguen siendo de root:
  se sustituyen con `cp -f` o desde el Finder. **Deshacer:** `sudo chown root` sobre las tres carpetas. Una
  actualización de DP podría devolverlas a root.
- **Copias de trabajo del usuario** en `reference/midnam_trabajo/` (privadas, no versionadas; no se borran ni se
  sobrescriben sin su permiso): `DSP-128 Plus.midnam` (la sigue optimizando él), `M3000 prueba.midnam` (= la instalada
  en DP, EXP-023) y `M3000 optimizado.midnam` (T-030) y `DSP-128 Plus optimizado.midnam` (T-031),
  `LXP-15 II Presets.midnam` y `LXP-15 I Registers.midnam` (T-032), `SPX2000.midnam`
  (copia del instalado en DP) y `SPX2000 optimizado.midnam` (EXP-034).
- **Idea para un proyecto futuro:** `docs/40_IDEA_EDITOR_FX_BCR2000.md` (fuera del alcance).

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

0. Si llega otro `.midnam` del usuario: como en T-030/T-031 (EXP-030, EXP-031); el árbol de D-010 ya se hace en la
   app (Patch Banks: Convert, ⌘→/⌘←, Mark as All Patches; EXP-039). Manuales en `incoming/` → `reference/manuales/<modelo>/`.
1. **Con el usuario, decidir el siguiente bloque:** repartir `build/Midnamer-0.9.0.zip` (`tools/distribuir.sh`; dónde
   publicarlo y el código fuente que pide la GPL los decide el usuario) y recoger comentarios para la 1.0 o Note Lists (fuera por ahora,
   docs/20 §7.1). Lo que salga del uso real de la app, como tarea nueva.
