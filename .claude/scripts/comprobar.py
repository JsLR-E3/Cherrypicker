#!/usr/bin/env python3
"""Comprobaciones deterministas del repositorio y su documentación (sin dependencias externas).

Uso: .claude/scripts/comprobar.py            (desde la raíz del proyecto; también funciona desde otra carpeta)
Errores (salida 1): marcadores {{…}} sin rellenar, enlaces Markdown rotos, IDs duplicados, material de terceros
versionado, posibles secretos. Avisos (salida 0): referencias `….md` que no existen, TAREAS demasiado largo o con
tareas COMPLETADAS que deberían estar en el historial, estados desconocidos.
"""
import os, re, subprocess, sys
from collections import Counter

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.chdir(RAIZ)
TAREAS = "TAREAS_TEMPORALES_PENDIENTES.md"
ESTADOS = {"PENDIENTE", "EN PROGRESO", "BLOQUEADA", "IMPLEMENTADA", "PENDIENTE-LOCAL", "COMPLETADA"}
MAX_TAREAS = 150
errores, avisos = [], []


def git(*a):
    r = subprocess.run(["git", *a], capture_output=True, text=True)
    return r.stdout.splitlines() if r.returncode == 0 else []


def ficheros_md():
    for d, subdirs, fs in os.walk("."):
        subdirs[:] = [s for s in subdirs if s not in (".git", "reference", "incoming", "node_modules", "build", "DerivedData")]
        for f in fs:
            if f.endswith((".md", ".txt")):
                yield os.path.normpath(os.path.join(d, f))


def sin_codigo(texto):
    # Quita bloques ``` y comentarios HTML: lo que hay dentro son ejemplos, no referencias reales.
    texto = re.sub(r"```.*?```", "", texto, flags=re.S)
    return re.sub(r"<!--.*?-->", "", texto, flags=re.S)


PLANTILLA_RUTA = re.compile(r"NNN|AAAA|[0-9]x_|…|<|>|\*|\{")

nombres = {os.path.basename(f) for f in ficheros_md()}
for f in ficheros_md():
    texto = open(f, encoding="utf-8", errors="replace").read()
    for n, linea in enumerate(texto.splitlines(), 1):
        for m in re.findall(r"\{\{[A-Z_]+\}\}", linea):
            errores.append(f"{f}:{n}: marcador sin rellenar {m}")
    util = sin_codigo(texto)
    base = os.path.dirname(f)
    for destino in re.findall(r"\]\(([^)\s]+)\)", util):
        if re.match(r"[a-z]+:", destino) or destino.startswith("#"):
            continue
        ruta = destino.split("#")[0]
        if ruta and not os.path.exists(os.path.join(base, ruta)):
            errores.append(f"{f}: enlace roto ({destino})")
    for ref in set(re.findall(r"`([^`\s]+\.md)`", util)):
        if PLANTILLA_RUTA.search(ref):
            continue
        cands = [os.path.join(base, ref), ref, os.path.join("docs", ref)]
        if "/" not in ref and ref in nombres:  # nombre sin ruta de un documento que existe en otra carpeta
            continue
        if not any(os.path.exists(c) for c in cands):
            avisos.append(f"{f}: menciona `{ref}`, que no existe")

# TAREAS
if os.path.exists(TAREAS):
    lineas = open(TAREAS, encoding="utf-8").read().splitlines()
    if len(lineas) > MAX_TAREAS:
        avisos.append(f"{TAREAS}: {len(lineas)} líneas (> {MAX_TAREAS}); mover lo cerrado a docs/15_HISTORIAL.md y resumir ESTADO")
    ids, seccion = [], ""
    for linea in lineas:
        if linea.startswith("## "):
            seccion = linea
        m = re.match(r"\|\s*(T-\d+)\s*\|", linea)
        if not m or "## TAREAS" not in seccion:
            continue
        ids.append(m.group(1))
        celdas = [c.strip() for c in linea.strip().strip("|").split("|")]
        estado = celdas[2] if len(celdas) > 2 else ""
        if not any(estado.startswith(e) for e in ESTADOS):
            avisos.append(f"{TAREAS}: {m.group(1)} con estado desconocido «{estado}»")
        if estado.startswith("COMPLETADA"):
            avisos.append(f"{TAREAS}: {m.group(1)} COMPLETADA sigue en la tabla; pasarla a docs/15_HISTORIAL.md")
    for i, c in Counter(ids).items():
        if c > 1:
            errores.append(f"{TAREAS}: {i} aparece {c} veces en la tabla")
    if os.path.exists("docs/15_HISTORIAL.md"):
        cerradas = set(re.findall(r"^\|\s*(T-\d+)", open("docs/15_HISTORIAL.md", encoding="utf-8").read(), flags=re.M))
        for i in sorted(cerradas & set(ids)):
            avisos.append(f"{i} está a la vez en TAREAS y en el historial")

# IDs duplicados en los registros
for f, patron in (("docs/13_REGISTRO_DE_EXPERIMENTOS.md", r"^## (EXP-\d+)"), ("docs/12_DECISIONES.md", r"^## (D-\d+)")):
    if os.path.exists(f):
        for i, c in Counter(re.findall(patron, sin_codigo(open(f, encoding="utf-8").read()), flags=re.M)).items():
            if c > 1:
                errores.append(f"{f}: {i} definido {c} veces")

# Git: material de terceros y secretos
versionados = git("ls-files")
for f in versionados:
    if (f.startswith("reference/") and f != "reference/README.md") or f.startswith("incoming/"):
        errores.append(f"versionado por error (material de terceros o bandeja): {f}  → git rm --cached")
SECRETOS = re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----|\bgh[pousr]_[A-Za-z0-9]{30,}|\bsk-ant-[A-Za-z0-9_-]{20,}"
                      r"|\bAKIA[0-9A-Z]{16}\b|\bxox[baprs]-[A-Za-z0-9-]{10,}")
for f in versionados:
    try:
        if os.path.getsize(f) > 2_000_000:
            continue
        for n, linea in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
            if SECRETOS.search(linea):
                errores.append(f"{f}:{n}: parece contener un secreto (no se muestra)")
    except OSError:
        pass

for a in avisos:
    print("AVISO  ", a)
for e in errores:
    print("ERROR  ", e)
print(f"comprobar: {len(errores)} error(es), {len(avisos)} aviso(s)")
sys.exit(1 if errores else 0)
