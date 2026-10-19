# Cherrypicker — instrucciones para Claude

1. **Empieza siempre por `TAREAS_TEMPORALES_PENDIENTES.md`** y `git status`. Ahí están las reglas, el estado y el
   siguiente paso exacto. No releas conversaciones ni explores todo el proyecto.
2. Método y niveles de evidencia: `docs/11_METODO_INGENIERIA_INVERSA.md`. Nada se da por confirmado por conjetura.
3. **Escrituras en el aparato** (registros, SysEx que cambie su memoria, firmware): solo con permiso explícito del
   usuario y respaldadas por el software original o por código abierto contrastado. Nunca actualizadores de firmware.
4. Cada prueba con el aparato se registra en `docs/13_REGISTRO_DE_EXPERIMENTOS.md` (EXP-NNN), también si falla.
5. `reference/` e `incoming/` no se versionan (material de terceros). Nada de `git add -A` sin revisar.
6. El push lo hace el usuario. Instalar o descargar software requiere su permiso.
7. Antes de cerrar la sesión o si el contexto se acaba: actualizar TAREAS (estado, `EN PROGRESO`, siguiente paso).
8. Documentación y commits en español.
