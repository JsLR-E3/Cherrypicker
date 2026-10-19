# Cherrypicker — instrucciones para Claude

1. **Empieza siempre por `TAREAS_TEMPORALES_PENDIENTES.md`** y `git status`. Ahí están las reglas, el estado y el
   siguiente paso exacto. No releas conversaciones ni explores todo el proyecto.
2. Método y niveles de evidencia: `docs/11_METODO_INGENIERIA_INVERSA.md`. Nada se da por confirmado por conjetura.
3. **Proyecto de programa, no de aparato:** se recupera CherryPicker (editor de `.midnam` para Digital Performer 11.36).
   Lo que se investiga son **formatos de fichero** y cómo los lee DP, no un protocolo de hardware.
4. **Ficheros del usuario:** los `.midnam` de `reference/midnam_usuario/` son privados; nunca se sobrescriben (se
   trabaja sobre copias en el scratchpad o `captures/`) ni se versionan.
5. **MIDI a aparatos reales** (audición): solo Bank Select y Program Change, con permiso del usuario. Nunca SysEx ni
   volcados. Nada se instala en las carpetas de DP ni del sistema sin permiso.
6. Cada prueba (con la app original, con DP o con un módulo) se registra en `docs/13_REGISTRO_DE_EXPERIMENTOS.md`
   (EXP-NNN), también si falla.
7. `reference/` e `incoming/` no se versionan (material de terceros). Nada de `git add -A` sin revisar.
8. El push lo hace el usuario. Instalar o descargar software requiere su permiso.
9. Antes de cerrar la sesión o si el contexto se acaba: actualizar TAREAS (estado, `EN PROGRESO`, siguiente paso).
10. Documentación y commits en español.
