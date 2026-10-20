#!/bin/bash
# Estado del proyecto en ~25 líneas, para empezar una sesión sin gastar razonamiento en comandos de git.
# Lo ejecuta el hook SessionStart (.claude/settings.json) y /inicio. Solo lee; nunca modifica nada.
# En la nube (CLAUDE_CODE_REMOTE=true) hace `git fetch`; en el Mac no, porque el fetch puede pedir la frase SSH
# y lo lanza el usuario: ahí se usan los remotos del último fetch. `--fetch` lo fuerza.
# Compatible con el bash 3.2 de macOS y con Linux.

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || { echo "estado.sh: no es un repositorio git"; exit 0; }

T=TAREAS_TEMPORALES_PENDIENTES.md
NUBE=no; [ "${CLAUDE_CODE_REMOTE:-}" = true ] && NUBE=si
RAMA=$(git branch --show-current 2>/dev/null); [ -n "$RAMA" ] || RAMA="(HEAD separado)"

echo "== Estado del proyecto (.claude/scripts/estado.sh) =="
if [ "$NUBE" = si ]; then echo "Entorno: NUBE · sin Mac, Xcode, DP ni MIDI: esas pruebas quedan PENDIENTE-LOCAL"
else echo "Entorno: local"; fi

# Remotos
if git remote | grep -q .; then
	if [ "$NUBE" = si ] || [ "${1:-}" = --fetch ]; then
		TO=; command -v timeout >/dev/null && TO="timeout 30"
		# Sin preguntas interactivas: si hiciera falta la frase SSH, falla en vez de bloquear la sesión.
		if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" $TO git fetch --quiet --prune origin 2>/dev/null; then
			REM="remotos actualizados ahora"
		else REM="AVISO: git fetch falló; remotos según el último fetch"; fi
	else
		FH="$(git rev-parse --git-dir)/FETCH_HEAD"
		if [ ! -e "$FH" ]; then REM="remotos: nunca se ha hecho fetch"
		elif [ -n "$(find "$FH" -mmin +720 2>/dev/null)" ]; then REM="remotos según un fetch de hace más de 12 h (lo lanza el usuario)"
		else REM="remotos según el último fetch (menos de 12 h)"; fi
	fi
else REM="sin remoto configurado"; fi

echo "Rama: $RAMA · HEAD $(git log -1 --format='%h %cd «%s»' --date=format:'%Y-%m-%d %H:%M' 2>/dev/null) · $REM"
if UP=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
	set -- $(git rev-list --left-right --count "HEAD...$UP" 2>/dev/null)
	echo "Frente a $UP: $1 commit(s) sin subir, $2 por traer"
elif [ "$RAMA" != "(HEAD separado)" ]; then echo "La rama no tiene upstream (no se ha subido nunca)"; fi

BASE=main; git rev-parse -q --verify origin/main >/dev/null && BASE=origin/main
git rev-parse -q --verify "$BASE" >/dev/null || BASE=
if [ -n "$BASE" ] && [ "$RAMA" != main ]; then
	set -- $(git rev-list --left-right --count "HEAD...$BASE" 2>/dev/null)
	echo "Frente a $BASE: $1 commit(s) propios, $2 de $BASE que esta rama no tiene"
fi

# Cambios sin commit
N=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$N" != 0 ]; then
	echo "AVISO: $N fichero(s) con cambios sin commit (no descartarlos sin preguntar):"
	git status --porcelain | head -10 | sed 's/^/  /'
	[ "$N" -gt 10 ] && echo "  …"
fi
[ -n "$(git stash list 2>/dev/null)" ] && echo "AVISO: hay stash guardados: $(git stash list | wc -l | tr -d ' ')"

# Ramas claude/ sin integrar en main (trabajo de sesiones en la nube)
if [ -n "$BASE" ]; then
	PEND=$(git for-each-ref --format='%(refname:short)' 'refs/remotes/origin/claude/' 2>/dev/null | while read -r r; do
		[ "$r" = "origin/$RAMA" ] && continue
		c=$(git rev-list --count "$BASE..$r" 2>/dev/null)
		[ "${c:-0}" -gt 0 ] && echo "  $r: $c commit(s), último $(git log -1 --format='%cd' --date=short "$r")"
	done)
	[ -n "$PEND" ] && { echo "Ramas claude/ con commits que no están en $BASE (integrar o descartar con el usuario):"; echo "$PEND" | head -8; }
fi

if git rev-parse -q --verify HEAD >/dev/null; then echo "Últimos commits:"; git log -5 --format='  %h %cd %s' --date=short
else echo "Sin commits todavía"; fi

# TAREAS
if [ -f "$T" ]; then
	echo "-- $T ($(wc -l <"$T" | tr -d ' ') líneas) --"
	grep -m1 '^> Actualizado' "$T" | sed 's/^> //'
	sec() { awk -v s="$1" '/^## /{p=($0 ~ s)} p && !/^## / && NF && !/^<!--/' "$T"; }
	EP=$(sec '^## EN PROGRESO' | grep -v -E '^- Nada([ .]|$)' | head -6)
	[ -n "$EP" ] && { echo "EN PROGRESO:"; echo "$EP"; }
	PL=$(sec 'VALIDACI' | grep -E '^\| *T-' | wc -l | tr -d ' ')
	[ "$PL" != 0 ] && echo "Pendiente de validación local: $PL tarea(s)"
	echo "Siguiente paso exacto:"; sec 'SIGUIENTE PASO' | head -6
fi

# IDs libres: solo cuentan filas de tabla (T-) y cabeceras (EXP-, D-) fuera de comentarios HTML (ahí van los ejemplos)
ids() { cat "$@" 2>/dev/null | perl -0pe 's/<!--.*?-->//gs'; }
next() { n=$(grep -o -E "$2" | grep -o -E '[0-9]+$' | sort -n | tail -1); printf '%s-%03d' "$1" $(( 10#${n:-0} + 1 )); }
echo "IDs libres: $(ids "$T" docs/15_HISTORIAL.md | next T '^\| *T-[0-9]+') · $(ids docs/13_REGISTRO_DE_EXPERIMENTOS.md | next EXP '^## EXP-[0-9]+') · $(ids docs/12_DECISIONES.md | next D '^## D-[0-9]+')"

# Buzón de trabajo en paralelo
if [ -f docs/remoto/PARA_LOCAL.md ]; then
	M=$(grep -o -E '^## Mensaje [0-9]+' docs/remoto/PARA_LOCAL.md | head -1 | grep -o -E '[0-9]+$')
	R=$(grep -o -E 'atiende «Mensaje [0-9]+' docs/remoto/PARA_REMOTO.md 2>/dev/null | head -1 | grep -o -E '[0-9]+$')
	[ -n "$M" ] && [ "${R:-0}" -lt "$M" ] && echo "Buzón: Mensaje $M de docs/remoto/PARA_LOCAL.md sin respuesta en PARA_REMOTO.md"
fi
exit 0
