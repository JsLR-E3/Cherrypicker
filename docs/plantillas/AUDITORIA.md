# 3x · Auditoría general (AAAA-MM-DD)

Qué ha cambiado desde la anterior. Sin escrituras en el aparato ni cambios de código: solo lectura, compilación,
medidas y comparación con lo instalado.
Gravedad: **Alta** (puede romper algo fuera del proyecto o perder datos), **Media** (falla en un caso real), **Baja**
(caso raro o molestia), **Trivial**; **O** = optimización, **D** = documentación. Estado: CONFIRMADO (visto o
reproducido), PROBABLE (deducido del código, sin reproducir).

## 1. Resumen

## 2. Método

1. Compilación desde cero de todos los componentes; análisis estático (`clang --analyze`).
2. Lo instalado frente a lo compilado; permisos de ficheros, sockets, registros y preferencias.
3. Lectura del código cambiado desde la auditoría anterior.
4. CPU de lo que corre en segundo plano.
5. Estado de lo abierto en auditorías anteriores.

## 3. Hallazgos

| ID | Gravedad | Estado | Dónde | Qué pasa | Arreglo propuesto |
|---|---|---|---|---|---|

## 4. Plan acordado con el usuario
