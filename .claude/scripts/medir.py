#!/usr/bin/env python3
"""Medición del consumo sin dependencias ni telemetría (docs/10_TRABAJO_CON_CLAUDE.md §6).

  medir.py contexto                  Tamaño de lo que entra fijo al empezar (ESTIMACIÓN: caracteres / 4).
  medir.py sesion --ultima           Métricas OBSERVADAS de la última sesión de este proyecto en esta máquina.
  medir.py sesion RUTA.jsonl [...]   Ídem para registros concretos (p. ej. los de subagentes, en <sesión>/subagents/).

Lee los registros locales de Claude Code (~/.claude/projects/<proyecto>/<sesión>.jsonl). Su formato es interno y puede
cambiar: si faltan campos, el script lo dice en vez de inventar cifras.
"""
import glob, json, os, re, subprocess, sys
from collections import Counter

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def contexto():
    partes = [("CLAUDE.md", open(os.path.join(RAIZ, "CLAUDE.md"), encoding="utf-8").read())]
    if os.path.exists(os.path.join(RAIZ, "CLAUDE.local.md")):
        partes.append(("CLAUDE.local.md", open(os.path.join(RAIZ, "CLAUDE.local.md"), encoding="utf-8").read()))
    # Las descripciones de skills y agentes están siempre en el contexto; el cuerpo, solo al usarlos.
    for f in sorted(glob.glob(os.path.join(RAIZ, ".claude", "skills", "*", "SKILL.md")) +
                    glob.glob(os.path.join(RAIZ, ".claude", "agents", "*.md"))):
        m = re.search(r"^description:\s*(.*)$", open(f, encoding="utf-8").read(), flags=re.M)
        partes.append((os.path.relpath(f, RAIZ) + " (descripción)", m.group(1) if m else ""))
    estado = os.path.join(RAIZ, ".claude", "scripts", "estado.sh")
    if os.path.exists(estado):
        salida = subprocess.run([estado], capture_output=True, text=True, cwd=RAIZ).stdout
        partes.append(("salida de estado.sh (hook)", salida))
    t = os.path.join(RAIZ, "TAREAS_TEMPORALES_PENDIENTES.md")
    if os.path.exists(t):
        partes.append(("TAREAS (lo lee /inicio)", open(t, encoding="utf-8").read()))
    total = 0
    print(f"{'Parte':58} {'líneas':>6} {'caract.':>8} {'~tokens':>8}")
    for nombre, texto in partes:
        if nombre == "CLAUDE.md":  # los comentarios HTML de bloque no llegan al modelo
            texto = re.sub(r"(?m)^\s*<!--.*?-->\s*$\n?", "", texto, flags=re.S)
        total += len(texto)
        print(f"{nombre:58} {texto.count(chr(10)):6} {len(texto):8} {len(texto)//4:8}")
    print(f"{'TOTAL fijo del proyecto al empezar':58} {'':6} {total:8} {total//4:8}")
    print("~tokens = caracteres/4: ESTIMACIÓN (el español suele dar algo más). Para la cifra real, `/context` en la sesión.")
    print("No incluye lo que añade Claude Code (instrucciones del sistema, herramientas, memoria automática).")


def carpeta_proyecto():
    slug = re.sub(r"[^A-Za-z0-9]", "-", RAIZ)
    d = os.path.expanduser(os.path.join("~/.claude/projects", slug))
    if not os.path.isdir(d):
        sys.exit(f"No encuentro {d}. Pasa la ruta del .jsonl de la sesión (ver ~/.claude/projects/).")
    return d


def sesion(rutas):
    uso, vistos = Counter(), {}
    herramientas, lecturas = Counter(), Counter()
    turnos, sin_uso, t0, t1 = 0, 0, None, None
    for ruta in rutas:
        for linea in open(ruta, encoding="utf-8"):
            try:
                d = json.loads(linea)
            except ValueError:
                continue
            ts = d.get("timestamp")
            if ts:
                t0, t1 = min(t0 or ts, ts), max(t1 or ts, ts)
            m = d.get("message") or {}
            if d.get("type") == "user" and isinstance(m.get("content"), str) and not d.get("isMeta"):
                turnos += 1
            elif d.get("type") == "user" and isinstance(m.get("content"), list):
                if any(b.get("type") == "text" for b in m["content"] if isinstance(b, dict)) and \
                   not any(b.get("type") == "tool_result" for b in m["content"] if isinstance(b, dict)):
                    turnos += 1
            if d.get("type") != "assistant":
                continue
            u = m.get("usage")
            if u is None:
                sin_uso += 1
            else:  # una misma respuesta aparece en varias líneas con el mismo id: se cuenta una vez
                vistos[m.get("id") or d.get("uuid")] = u
            for b in m.get("content") or []:
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    herramientas[b.get("name")] += 1
                    entrada = b.get("input") or {}
                    if b.get("name") == "Read" and entrada.get("file_path"):
                        lecturas[os.path.relpath(entrada["file_path"], RAIZ)] += 1
    for u in vistos.values():
        for k in ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"):
            uso[k] += u.get(k) or 0
    print(f"Registros: {', '.join(os.path.basename(r) for r in rutas)}")
    print(f"Periodo: {t0} → {t1}")
    print(f"Respuestas del modelo: {len(vistos)} · turnos del usuario: {turnos}")
    print(f"Tokens (OBSERVADOS): entrada {uso['input_tokens']:,} · salida {uso['output_tokens']:,} · "
          f"lectura de caché {uso['cache_read_input_tokens']:,} · escritura de caché {uso['cache_creation_input_tokens']:,}")
    if sin_uso:
        print(f"AVISO: {sin_uso} línea(s) de respuesta sin datos de uso: las cifras pueden quedarse cortas")
    print("Herramientas: " + (", ".join(f"{k} {v}" for k, v in herramientas.most_common()) or "ninguna"))
    print(f"Ficheros leídos con Read: {len(lecturas)} distintos, {sum(lecturas.values())} lecturas "
          "(las lecturas con cat/sed/head dentro de Bash cuentan como Bash)")
    rel = [(f, n) for f, n in lecturas.most_common() if n > 1]
    if rel:
        print("Releídos: " + ", ".join(f"{f} ×{n}" for f, n in rel[:10]))
    print("No incluye subagentes salvo que se pasen sus .jsonl (carpeta <sesión>/subagents/).")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["contexto"]:
        contexto()
    elif a[:1] == ["sesion"] and a[1:] == ["--ultima"]:
        fs = sorted(glob.glob(os.path.join(carpeta_proyecto(), "*.jsonl")), key=os.path.getmtime)
        if not fs:
            sys.exit("No hay sesiones registradas para este proyecto en esta máquina.")
        sesion(fs[-1:])
    elif a[:1] == ["sesion"] and a[1:]:
        sesion(a[1:])
    else:
        sys.exit(__doc__)
