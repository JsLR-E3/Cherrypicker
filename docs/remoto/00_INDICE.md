# Trabajo remoto — índice

> Trabajo hecho **fuera del Mac del proyecto** (sin hardware, a veces sin macOS ni compilar).
> Solo lectura del repositorio y documentos nuevos en esta carpeta. **Ningún archivo existente se modifica.**
> Rama: `claude/remoto-…` (anotar aquí el nombre y el commit de `main` del que parte).
> Todo lo de aquí son propuestas: se aplican, se descartan o se prueban en el Mac del proyecto.

| Doc | Contenido | Estado |
|---|---|---|
| `PARA_LOCAL.md` | **Buzón remoto → Mac del proyecto** (solo lo escribe la sesión remota) | — |
| `PARA_REMOTO.md` | **Buzón Mac del proyecto → remoto** (solo lo escribe el Mac del proyecto) | — |

## Cómo incorporarlo en el Mac del proyecto

```
git fetch origin <rama remota>
git diff --stat main origin/<rama remota>     # solo debe listar docs/remoto/
git merge origin/<rama remota>               # estando en main
```
