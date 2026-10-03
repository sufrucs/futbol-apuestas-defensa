# 13b. Código: `graficas.py`, función por función

[← `datos_dashboard.py`](13a_codigo_datos_dashboard.md) · [Índice](README.md) · [Siguiente: `index.qmd` →](13c_codigo_index_quarto.md)

> **Versión que se explica:** la entregada (rama `main`, commit `e3bd43f`, 30-sep-2026). El archivo tiene **374 líneas**;
> "líneas 86–114" se refiere a ese archivo. Los ejemplos con cifras salen de las tablas que calcula
> [`datos_dashboard.py`](13a_codigo_datos_dashboard.md) (ejecutado con Python 3.10); los pocos números que no estaban en
> ese capítulo (los títulos con dos decimales, el punto de cruce de la gráfica de Elo, los contrastes de color) los calculó
> esta guía el 3-oct-2026 y se marcan como **cálculo propio**. **Para este capítulo no se ejecutó R ni Quarto:** todos los
> bloques de R están marcados **ilustrativo** (código razonado, no probado). Lo marcado **"observado"** o "se comprobó en el
> sitio" se vio en el **sitio publicado** (<https://pitirringo.github.io/futbol-apuestas/>) el 3-oct-2026: se contaron las trazas,
> formas y anotaciones de las 11 gráficas, se leyó el tipo de eje de la de Poisson y se miraron los tooltips; es lo que
> permite decir cómo se **ven**, no sólo cómo se escriben. Abre el sitio al lado de este capítulo.
> Capítulos relacionados: el diseño del tablero ([13](13_dashboard.md)), las cifras que alimentan cada gráfica
> ([13a](13a_codigo_datos_dashboard.md)), `index.qmd`, `estilos.scss` y `redibujar.html`
> ([13c](13c_codigo_index_quarto.md)) y las decisiones **D43–D46** del [capítulo 19](19_decisiones_y_alternativas.md).
> **Formato de los recuadros de decisión:** una línea con cuatro partes separadas por "·" (*Decisión · Alternativas ·
> Por qué ésta · Si preguntan*). Una alternativa dice "no se probó" cuando de verdad no se probó; las que sí se
> observaron en el proyecto se señalan.

---

## 13b.0 Panorama

### Para qué existe

`graficas.py` es la **capa visual** del tablero: convierte las tablas que prepara `datos_dashboard.py` en **figuras de
Plotly con un mismo estilo**. Tiene tres partes:

1. **Constantes** (paleta de colores, fuente, configuración de plotly.js y una *plantilla* de Plotly) que fijan el estilo
   una sola vez para todo el tablero.
2. **Una función por gráfica**: 11 funciones que reciben una tabla y devuelven un `go.Figure` (la figura aún sin
   mostrar), más tres ayudantes (`mostrar`, `_pct`, `_anotacion`).
3. **`tabla_html`**, que convierte un `DataFrame` en una tabla HTML (la "vista de tabla" de algunas gráficas).

El docstring del módulo (líneas 1–16) enuncia las seis reglas de diseño. Así se cumple cada una en el código:

| Regla del docstring | Cómo se cumple | Se explica en |
|---|---|---|
| El color codifica entidades fijas (azul = modelo, naranja = mercado, verde = local, violeta = visitante, gris = contexto) | cinco constantes de color y ninguna gráfica usa un color "por omisión" | [13b.1.2](#13b12-la-paleta-un-color-un-significado) |
| El título de cada tarjeta dice el hallazgo; la gráfica no repite el título | ninguna figura define `title`: el título vive en `index.qmd` (`::: {.card title="…"}`) | cada función y [13c](13c_codigo_index_quarto.md) |
| Barras siempre desde cero; puntos y líneas cuando el cero no es relevante | `rangemode="tozero"` o `range=[0, …]` en las barras; las barras con signo (`brecha_por_resultado`) tienen el cero en el centro | [13b.2.4](#13b24-mejora_sobre_ingenua), [13b.2.11](#13b211-brecha_por_resultado) |
| Etiquetas directas selectivas; la leyenda, cuando hace falta, va en HTML en el subtítulo de la tarjeta | `text=` en las barras y anotaciones al final de las líneas; `showlegend=False` en `mostrar` | [13b.2.1](#13b21-mostrar), [13b.2.5](#13b25-resultados_por_temporada) |
| Gráficas de lectura: sin zoom ni arrastre; los tooltips siguen activos | `CONFIG`, `dragmode=False` y `fixedrange=True` | [13b.1.4](#13b14-config), [13b.2.1](#13b21-mostrar) |
| Las figuras se construyen dentro de funciones | cada gráfica es una función que devuelve la figura; `mostrar` devuelve `None` | [13b.2.1](#13b21-mostrar) |

**Lo que `graficas.py` NO hace:**

- **No lee archivos ni calcula el modelo.** Ni siquiera importa `datos_dashboard`: recibe tablas ya calculadas
  (por eso se podría probar con tablas inventadas). Si cambia un dato, no hay que tocar las gráficas; si cambia un color,
  no hay que tocar los datos ([capítulo 13, 13.4](13_dashboard.md)).
- **No escribe la narrativa.** Títulos de tarjeta, subtítulos, leyendas HTML y "lecturas" están en `index.qmd`.
- **Sólo hace aritmética de presentación**, y muy poca: la *mejora* sobre la ingenua (`ingenua − predictor`) en
  `mejora_sobre_ingenua`, la interpolación del punto de cruce (`np.interp`), la correlación **r** de
  `modelo_vs_mercado` (`np.corrcoef`), los brazos del intervalo de `efectos` y los límites de algunos ejes.
  De todo eso, **r = 0.94 es el único estadístico que nace en este archivo**; no lo calcula `datos_dashboard.py`, así
  que la verificación "17 de 17" del tablero ([13a.7.6](13a_codigo_datos_dashboard.md#13a76-tabla_verificacion)) no lo
  cubre.

### Cómo se usa desde `index.qmd`

Al principio de `index.qmd` hay un chunk de preparación que importa los dos módulos y calcula todo **una vez**:

```python
import datos_dashboard as dd
import graficas as gr

d = dd.preparar_todo()
g, fav, met, sim, sens = d["general"], d["favorito"], d["metricas"], d["simulador"], d["sensibilidad"]
```

Después, cada tarjeta que lleva una gráfica tiene un chunk de **una sola línea**: `gr.mostrar(gr.función(datos))`.
Por ejemplo, la tarjeta "Ni el favorito es garantía" (página *¿Qué ocurre?*):

````markdown
::: {.card title="Ni el favorito es garantía"}
<p class="subtitulo">Resultado según el favorito de Bet365.</p>

```{python}
gr.mostrar(gr.resultado_favorito(fav))
```
:::
````

La llamada de **adentro** (`gr.resultado_favorito(fav)`) construye la figura a partir de la tabla; la de **afuera**
(`gr.mostrar(...)`) le pone la plantilla, fija los ejes y la dibuja en la salida del chunk. En total `index.qmd` hace
**11 llamadas a `gr.mostrar`** (una por gráfica) y **7 a `gr.tabla_html`** (las tablas).

**En R (ilustrativo).** En `flexdashboard` o R Markdown sería exactamente la misma idea: un archivo `graficas.R` con las
funciones, `source("graficas.R")` en el chunk de preparación y un chunk de una línea por tarjeta:

````markdown
### Ni el favorito es garantía

```{r}
mostrar(resultado_favorito(fav))
```
````

### Dónde encaja en la cadena

```text
Limpieza de datos.ipynb ─► E0_consolidado.csv ─► wc_predictor.py + Analisis.ipynb ─► premier_training_data.csv
                                                              │
                                                              ▼
                                           datos_dashboard.py   preparar_todo() ─► diccionario `d` (28 entradas)
                                                              │      d["temporadas"], d["elo"], d["metricas"], …
                                                              ▼
 index.qmd ──► gr.mostrar( gr.<función>( d["…"] ) ) ◄── graficas.py   ◄ este capítulo
      │                  │              └─ la función arma un go.Figure: trazas + anotaciones + ejes
      │                  └─ mostrar(): plantilla + ejes fijos + sin leyenda ─► fig.show(config=CONFIG)
      ▼
 quarto render ─► _site/index.html (con plotly.js) ─► GitHub Pages
      ▲
 redibujar.html (JavaScript): vuelve a dibujar cada gráfica cuando su tarjeta estaba oculta (D46)
```

- **Entra:** una tabla (`DataFrame`) o un diccionario por gráfica, ya con las columnas que la función necesita.
- **Sale:** una figura de Plotly en la salida del chunk; Quarto la incrusta en la tarjeta como HTML + JavaScript
  (plotly.js), no como imagen.
- **Vecinos:** [13a](13a_codigo_datos_dashboard.md) explica cómo se calcula cada tabla de entrada;
  [13c](13c_codigo_index_quarto.md) explica el texto, el CSS (`estilos.scss`: tarjetas, leyendas HTML, tablas) y el
  script `redibujar.html`.

### Todas las piezas del archivo

**Constantes y plantilla**

| Pieza | Línea | Qué es | La usan | Aquí |
|---|---|---|---|---|
| Docstring e importaciones | 1–25 | reglas de diseño y librerías | — | [13b.1.1](#13b11-docstring-e-importaciones) |
| `MODELO` | 28 | azul `#2a78d6`: **el modelo** | `mejora_sobre_ingenua` (M0), `ajuste_poisson` (rombos), `brecha_por_resultado` (donde ganó el modelo), `efectos`, `calibracion_modelos`; primer color de `colorway` | [13b.1.2](#13b12-la-paleta-un-color-un-significado) |
| `MERCADO` | 29 | naranja `#eb6834`: **el mercado** (cuotas) | `mejora_sobre_ingenua`, `calibracion_mercado`, `delta_vs_m0`, `brecha_por_resultado` (donde ganó el mercado), `calibracion_modelos` | ídem |
| `LOCAL` | 30 | verde `#008300`: **gana el local** | `resultados_por_temporada`, `resultado_por_diferencia_elo` | ídem |
| `VISITA` | 31 | violeta `#4a3aa7`: **gana el visitante** | las mismas dos | ídem |
| `CONTEXTO` | 32 | gris `#898781`: empate, referencias y especificaciones secundarias | `mejora_sobre_ingenua` (M4), las dos de resultados (empate), `resultado_favorito`, `ajuste_poisson` (observado), `delta_vs_m0` (M1–M4) | ídem |
| `TINTA` | 33 | casi negro `#0b0b0b`: texto principal | nombres de categoría del eje y (5 gráficas), letra del tooltip, "r = 0.94" | ídem |
| `TINTA_2` | 34 | gris oscuro `#52514e`: texto secundario | letra base, títulos de ejes, anotaciones, rótulos de barras, líneas de cero, puntos de `modelo_vs_mercado` | ídem |
| `TENUE` | 35 | gris `#898781` (el mismo valor que `CONTEXTO`) | números de los ejes, flechas, anotaciones discretas | ídem |
| `REJILLA` | 36 | gris claro `#e1e0d9` | rejilla, borde del tooltip | ídem |
| `BASE` | 37 | gris `#c3c2b7` | líneas de referencia: Elo 0, las tres diagonales, el 0 de `efectos` | ídem |
| `BANDA` | 38 | gris muy claro `#f3f2ee` | bandas de entrenamiento y prueba en `resultados_por_temporada` | ídem |
| `AZULES` | 39 | ocho tonos de azul, de `#eef5fd` a `#0d366b` | **ninguna función de este archivo** (ver [13b.3](#13b3-detalles-raros-y-textos-escritos-a-mano)) | ídem |
| `FUENTE` | 41 | pila de fuentes del sistema | `PLANTILLA` (letra base y tooltip) | [13b.1.3](#13b13-fuente) |
| `CONFIG` | 42 | opciones de plotly.js (sin barra, sin zoom con rueda ni doble clic) | `mostrar` | [13b.1.4](#13b14-config) |
| `PLANTILLA` | 44–61 | plantilla de Plotly: fuente, fondo, rejilla, tooltip, separadores | `mostrar` | [13b.1.5](#13b15-plantilla) |

**Funciones** (en el orden del archivo; "tarjeta · página" es el título tal como aparece en `index.qmd`)

| # | Pieza | Líneas | Recibe (`d[...]`) | Tipo de gráfica | Tarjeta · página | Aquí |
|---|---|---|---|---|---|---|
| 1 | `mostrar(fig)` | 64–72 | una figura | — (la dibuja de sólo lectura) | las 11 gráficas | [13b.2.1](#13b21-mostrar) |
| 2 | `_pct(x, dec)` | 75–76 | un número | — (formato "42.6%") | rótulos de `resultados_por_temporada` y `resultado_favorito` | [13b.2.2](#13b22-_pct) |
| 3 | `_anotacion(...)` | 79–82 | figura + texto | — (anotación con flecha) | **nadie la usa** | [13b.2.3](#13b23-_anotacion) |
| 4 | `mejora_sobre_ingenua` | 86–114 | `metricas` | barras horizontales agrupadas | "El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo" · Resumen | [13b.2.4](#13b24-mejora_sobre_ingenua) |
| 5 | `resultados_por_temporada` | 118–151 | `temporadas` | líneas con marcadores + bandas de fondo | "Jugar en casa siempre ayuda… salvo sin público" · ¿Qué ocurre? | [13b.2.5](#13b25-resultados_por_temporada) |
| 6 | `resultado_favorito` | 154–166 | `favorito` (dict) | barras horizontales simples | "Ni el favorito es garantía" · ¿Qué ocurre? | [13b.2.6](#13b26-resultado_favorito) |
| 7 | `resultado_por_diferencia_elo` | 170–204 | `elo`, `ventaja_elo` | líneas suavizadas con marcadores | "A más ventaja de Elo, más victorias locales" · Patrones | [13b.2.7](#13b27-resultado_por_diferencia_elo) |
| 8 | `calibracion_mercado` | 207–231 | `calibracion_mercado` | diagrama de calibración (puntos + diagonal) | "Las cuotas están bien calibradas" · Patrones | [13b.2.8](#13b28-calibracion_mercado) |
| 9 | `ajuste_poisson` | 234–254 | `poisson` | barras + rombos, dos paneles | "Los goles se comportan como un conteo de Poisson" · Patrones (pestaña) | [13b.2.9](#13b29-ajuste_poisson) |
| 10 | `delta_vs_m0` | 258–283 | `delta_m0` | mancuernas (dos puntos unidos por una línea) | "Agregar variables no generaliza" · El modelo | [13b.2.10](#13b210-delta_vs_m0) |
| 11 | `brecha_por_resultado` | 286–306 | `brecha` | barras horizontales con signo | "No es una derrota..." · El modelo | [13b.2.11](#13b211-brecha_por_resultado) |
| 12 | `efectos` | 309–329 | `efectos` | puntos con intervalo de 95 %, dos paneles | "Qué variables pesan más" · El modelo (pestaña) | [13b.2.12](#13b212-efectos) |
| 13 | `calibracion_modelos` | 332–345 | `calibracion_modelos` | diagrama de calibración con dos series | "Calibración: modelo vs. mercado" · El modelo (pestaña) | [13b.2.13](#13b213-calibracion_modelos) |
| 14 | `modelo_vs_mercado` | 348–363 | `partido_a_partido` | dispersión de 419 puntos + diagonal | "Modelo vs. mercado, partido a partido" · El modelo (pestaña) | [13b.2.14](#13b214-modelo_vs_mercado) |
| 15 | `tabla_html(df, clase)` | 367–374 | un `DataFrame` | tabla HTML | 7 tablas (ver [13b.2.15](#13b215-tabla_html)) | [13b.2.15](#13b215-tabla_html) |

Los nombres de las entradas `d[...]` y la función que calcula cada una están en el [13a, 13a.8](13a_codigo_datos_dashboard.md#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906).

### Las decisiones de este capítulo

Hay **28 recuadros de decisión** en este capítulo (para estudiar: a cualquiera le pueden preguntar "¿por qué eligieron eso?").
El [capítulo 19](19_decisiones_y_alternativas.md) resume las del tablero en **D43** (Plotly con plantilla única y paleta con
significado: #1–#5, #26 y #27), **D45** (una historia en seis páginas con títulos que dicen la conclusión: #28) y **D46**
(`redibujar.html`: complementa a #6); **D44** (el simulador) se explica en el
[13c](13c_codigo_index_quarto.md). El [13a](13a_codigo_datos_dashboard.md) trae las decisiones sobre **qué se calcula**; aquí están las de
**cómo se dibuja**.

| # | Decisión | Dónde |
|---|---|---|
| 1 | `plotly.graph_objects` y no `plotly.express` | [13b.1.1](#13b11-docstring-e-importaciones) |
| 2 | Cinco colores con significado fijo y gris para lo demás | [13b.1.2](#13b12-la-paleta-un-color-un-significado) |
| 3 | Fuente del sistema, la misma que usa el CSS | [13b.1.3](#13b13-fuente) |
| 4 | Gráficas de sólo lectura: sin barra, sin zoom, con tooltips | [13b.1.4](#13b14-config) |
| 5 | Una sola plantilla, aplicada en `mostrar` | [13b.1.5](#13b15-plantilla) |
| 6 | Sin leyenda de Plotly: las leyendas van en HTML | [13b.2.1](#13b21-mostrar) |
| 7 | Mejora sobre la ingenua, en barras horizontales desde cero | [13b.2.4](#13b24-mejora_sobre_ingenua) |
| 8 | Color = entidad, opacidad = periodo | [13b.2.4](#13b24-mejora_sobre_ingenua) |
| 9 | Orden fijo y narrativo de las filas (mercado, M0, M4) | [13b.2.4](#13b24-mejora_sobre_ingenua) |
| 10 | Tres líneas sobre un eje que parte de 0 % (temporadas) | [13b.2.5](#13b25-resultados_por_temporada) |
| 11 | Etiquetas directas y nota del COVID en la franja vacía | [13b.2.5](#13b25-resultados_por_temporada) |
| 12 | Bandas de fondo para entrenamiento, validación y prueba | [13b.2.5](#13b25-resultados_por_temporada) |
| 13 | Barras simples, todas grises (favorito) | [13b.2.6](#13b26-resultado_favorito) |
| 14 | Deciles de Elo con líneas suavizadas | [13b.2.7](#13b27-resultado_por_diferencia_elo) |
| 15 | Círculo y anotación para "lo que vale jugar en casa" | [13b.2.7](#13b27-resultado_por_diferencia_elo) |
| 16 | Diagrama de calibración con diagonal y ejes cuadrados | [13b.2.8](#13b28-calibracion_mercado) |
| 17 | Barras observadas y rombos de Poisson en dos paneles | [13b.2.9](#13b29-ajuste_poisson) |
| 18 | Mancuernas (dos puntos y una línea) contra M0 | [13b.2.10](#13b210-delta_vs_m0) |
| 19 | Hueco/relleno para el periodo y sentido escrito bajo el eje | [13b.2.10](#13b210-delta_vs_m0) |
| 20 | Brecha descompuesta por resultado, con color según quién ganó | [13b.2.11](#13b211-brecha_por_resultado) |
| 21 | Eje simétrico alrededor del cero | [13b.2.11](#13b211-brecha_por_resultado) |
| 22 | Gráfico de efectos (punto + intervalo) estandarizados | [13b.2.12](#13b212-efectos) |
| 23 | Dos paneles con escala propia | [13b.2.12](#13b212-efectos) |
| 24 | Modelo y mercado en el mismo diagrama de calibración | [13b.2.13](#13b213-calibracion_modelos) |
| 25 | Dispersión partido a partido con la diagonal y r | [13b.2.14](#13b214-modelo_vs_mercado) |
| 26 | Función propia para las tablas HTML | [13b.2.15](#13b215-tabla_html) |
| 27 | Vista de tabla sólo para 5 de las 11 gráficas | [13b.2.15](#la-vista-de-tabla-qué-gráficas-la-tienen) |
| 28 | Títulos de tarjeta que dicen el hallazgo; la figura no lleva título | [13b.5](#contar-una-historia-storytelling) |

### Cómo comprobar el módulo

**Qué hay y qué no.** No existen pruebas automáticas de las gráficas. La tabla "verificación: 17 de 17 ✓" del sitio
([13a.7.6](13a_codigo_datos_dashboard.md#13a76-tabla_verificacion)) comprueba **cifras** (LogLoss, aciertos…) contra las
salidas del notebook; no comprueba que una figura tenga sus trazas o que una etiqueta no se encime. Las gráficas se
revisan **mirándolas** en el sitio (cuatro páginas, una pestaña oculta y una ventana angosta).

**Revisión por figura, sin renderizar todo el sitio** (no ejecutado para esta guía; es el procedimiento). Desde la
carpeta `Dashboard-o-pagina`:

```python
import tempfile, pathlib
import datos_dashboard as dd
import graficas as gr

d = dd.preparar_todo()                      # ≈ 8-12 s: calcula todo una vez
figuras = {
    "mejora_sobre_ingenua":         gr.mejora_sobre_ingenua(d["metricas"]),
    "resultados_por_temporada":     gr.resultados_por_temporada(d["temporadas"]),
    "resultado_favorito":           gr.resultado_favorito(d["favorito"]),
    "resultado_por_diferencia_elo": gr.resultado_por_diferencia_elo(d["elo"], d["ventaja_elo"]),
    "calibracion_mercado":          gr.calibracion_mercado(d["calibracion_mercado"]),
    "ajuste_poisson":               gr.ajuste_poisson(d["poisson"]),
    "delta_vs_m0":                  gr.delta_vs_m0(d["delta_m0"]),
    "brecha_por_resultado":         gr.brecha_por_resultado(d["brecha"]),
    "efectos":                      gr.efectos(d["efectos"]),
    "calibracion_modelos":          gr.calibracion_modelos(d["calibracion_modelos"]),
    "modelo_vs_mercado":            gr.modelo_vs_mercado(d["partido_a_partido"]),
}
carpeta = pathlib.Path(tempfile.mkdtemp())
for nombre, fig in figuras.items():
    print(f"{nombre:30s} trazas={len(fig.data):2d}  formas={len(fig.layout.shapes)}  anotaciones={len(fig.layout.annotations)}")
    fig.update_layout(template=gr.PLANTILLA, showlegend=False)     # lo que haría mostrar()
    fig.write_html(carpeta / f"{nombre}.html", config=gr.CONFIG)   # abrir en el navegador
print(carpeta)
```

**Qué debería imprimir** (derivado de **leer el código** y **comprobado contra el sitio publicado** el 3-oct-2026: en la
consola del navegador se contaron `data`, `layout.shapes` y `layout.annotations` de cada una de las 11 gráficas y **coinciden
todas**; "formas" = líneas y bandas dibujadas con `add_vline` / `add_vrect`; las anotaciones de las figuras con paneles
incluyen los títulos de los paneles):

| Función | Trazas | Formas | Anotaciones | De dónde salen |
|---|---|---|---|---|
| `mejora_sobre_ingenua` | 2 | 0 | 0 | una traza de barras por periodo |
| `resultados_por_temporada` | 3 | 3 | 7 | 3 series; 3 bandas; 3 rótulos de banda + 3 rótulos de serie + la anotación del COVID |
| `resultado_favorito` | 1 | 0 | 0 | una traza de barras |
| `resultado_por_diferencia_elo` | 4 | 1 | 5 | 3 series + el marcador del cruce; línea en 0; "Elo igual" + 3 rótulos + la explicación |
| `calibracion_mercado` | 2 | 0 | 2 | diagonal + puntos; dos anotaciones |
| `ajuste_poisson` | 4 | 0 | 2 | (barras + rombos) × 2 paneles; 2 títulos de panel |
| `delta_vs_m0` | 15 | 1 | 3 | 5 predictores × (línea + hueco + relleno); línea en 0; "M0 (base)" + 2 sentidos |
| `brecha_por_resultado` | 1 | 1 | 2 | una traza de barras; línea en 0; 2 sentidos |
| `efectos` | 2 | 2 | 2 | una traza por panel; una línea en 0 por panel; 2 títulos de panel |
| `calibracion_modelos` | 3 | 0 | 0 | diagonal + mercado + M0 |
| `modelo_vs_mercado` | 2 | 0 | 1 | diagonal + puntos; "r = 0.94" |

Si un conteo no coincide, alguien cambió la función (o este capítulo quedó desactualizado).

---

## 13b.1 Constantes y plantilla (líneas 1–61)

Antes de cualquier función, el archivo fija **todo lo que es común**: los colores, la fuente, las opciones de plotly.js
y una plantilla de Plotly. Así cada gráfica sólo describe **sus datos**; el estilo se hereda.

### 13b.1.1 Docstring e importaciones

El docstring (líneas 1–16) es la lista de reglas de diseño que ya se vio en el [panorama](#para-qué-existe). Las
importaciones (líneas 18–25):

```python
from __future__ import annotations

import html

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
```

| Línea | Qué hace | Quién lo usa |
|---|---|---|
| `from __future__ import annotations` | las anotaciones de tipo (`pd.DataFrame`, `go.Figure`) se guardan como texto y no se evalúan al definir la función; no cambia el comportamiento, sólo documenta | todas las firmas |
| `import html` | `html.escape`: convierte `<`, `>`, `&` y comillas en entidades HTML | `modelo_vs_mercado`, `tabla_html` |
| `import numpy as np` | `np.column_stack` (datos extra del tooltip), `np.interp`, `np.corrcoef`, `np.abs`, `np.concatenate` | varias funciones |
| `import pandas as pd` | sólo para las anotaciones de tipo; las operaciones (`.set_index`, `.iloc`, `.itertuples`) se hacen sobre las tablas que llegan | firmas |
| `import plotly.graph_objects as go` | `go.Figure`, `go.Bar`, `go.layout.Template` | todas |
| `from plotly.subplots import make_subplots` | figuras con varios paneles | `ajuste_poisson`, `efectos` |

**En R (ilustrativo):**

```r
library(plotly)      # plot_ly() ≈ go.Figure; subplot() ≈ make_subplots
library(ggplot2)     # las versiones con ggplot2 + ggplotly()
library(dplyr)       # las operaciones sobre las tablas (filter, mutate, left_join…)
library(forcats)     # fct_rev(), fct_inorder()
library(htmltools)   # htmlEscape() ≈ html.escape
library(scales)      # percent() ≈ _pct
```

> **Decisión:** `plotly.graph_objects` (`go`), la interfaz detallada de Plotly, en lugar de `plotly.express`. ·
> **Alternativas:** (a) `plotly.express` (`px.bar`, `px.line`…) — a favor: una línea por gráfica sencilla y ejes y colores
> automáticos; en contra: casi todas las gráficas de este tablero llevan algo a medida (anotaciones con flecha, bandas de
> fondo, barras de error asimétricas, líneas de referencia, tooltips con varias columnas) y habría que terminar editando
> la figura con `update_traces`/`add_*` de todos modos (no se probó); (b) imágenes estáticas con `matplotlib` (no se
> probó; ver [13b.1.4](#13b14-config)). · **Por qué ésta:** con `go` cada elemento visible es una traza, una forma o una
> anotación explícita, así que cada gráfica se lee de arriba abajo y se puede explicar línea por línea. · **Si
> preguntan:** "`px` es para gráficas rápidas; como las nuestras llevan anotaciones, bandas e intervalos hechos a
> medida, usamos `graph_objects`, que es la misma librería con control total". (Analogía en R: `px` es a `go` lo que
> `ggplot2` + `ggplotly()` es a `plot_ly()`: lo rápido contra lo detallado.)

### 13b.1.2 La paleta: un color, un significado

Líneas 27–39:

```python
# ── Paleta ────────────────────────────────────────────────────────────────────
MODELO = "#2a78d6"
MERCADO = "#eb6834"
LOCAL = "#008300"
VISITA = "#4a3aa7"
CONTEXTO = "#898781"      # gris: empate, referencias y especificaciones secundarias
TINTA = "#0b0b0b"
TINTA_2 = "#52514e"
TENUE = "#898781"
REJILLA = "#e1e0d9"
BASE = "#c3c2b7"
BANDA = "#f3f2ee"
AZULES = ["#eef5fd", "#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#184f95", "#0d366b"]
```

Cada color es una constante con **nombre de significado**, no de aspecto (`MERCADO`, no `NARANJA`). En las funciones
nunca aparece un hex escrito a mano (salvo `"#ebeae4"`, la banda de validación, línea 124): se usa el nombre. Las doce
constantes de color se dividen en dos familias.

**Colores de entidad: el color dice *quién* es** (son los cinco de la fila "El color se reserva para lo importante" del
[capítulo 13, 13.3](13_dashboard.md)):

| Constante | Hex | Significado | Dónde se ve |
|---|---|---|---|
| `MODELO` | `#2a78d6` (azul) | el modelo (M0) | barra de M0; rombos de Poisson; barras de la brecha donde **ganó el modelo**; puntos de `efectos`; línea de M0 en la calibración |
| `MERCADO` | `#eb6834` (naranja) | las cuotas del mercado | barra del mercado; puntos de Bet365; mancuerna del mercado; barras de la brecha donde **ganó el mercado**; línea del mercado |
| `LOCAL` | `#008300` (verde) | gana el equipo local | líneas "Local" de las dos gráficas de resultados |
| `VISITA` | `#4a3aa7` (violeta) | gana el visitante | líneas "Visitante" de las dos gráficas de resultados |
| `CONTEXTO` | `#898781` (gris) | todo lo que no es protagonista: el empate, las referencias, M1–M4 ("especificaciones secundarias") y los datos observados | línea de empate; barras de "Ni el favorito es garantía"; M4 en el Resumen; mancuernas de M1–M4; barras observadas de Poisson |

**Colores de apoyo: el color dice *qué papel juega* el trazo** (tinta, rejilla, referencias):

| Constante | Hex | Papel | Dónde se ve |
|---|---|---|---|
| `TINTA` | `#0b0b0b` | texto que hay que leer sí o sí | nombres de las categorías del eje vertical, tooltip, "r = 0.94" |
| `TINTA_2` | `#52514e` | texto y trazos secundarios | letra base, títulos de ejes, anotaciones, rótulos al final de las barras, línea del cero, puntos de `modelo_vs_mercado` |
| `TENUE` | `#898781` | texto y trazos discretos (**mismo valor que `CONTEXTO`**) | números de los ejes, flechas de las anotaciones, "Elo igual", "← mejor que M0" |
| `REJILLA` | `#e1e0d9` | rejilla | líneas horizontales y verticales de fondo; borde del tooltip |
| `BASE` | `#c3c2b7` | líneas de referencia | línea de Elo = 0; la diagonal de calibración (3 gráficas); el cero de `efectos` |
| `BANDA` | `#f3f2ee` | superficies de fondo | bandas de entrenamiento y prueba en `resultados_por_temporada` |
| `AZULES` | 8 tonos | escala secuencial de azul (clara a oscura) | **no se usa en este archivo**; sus extremos se copiaron a mano en `index.qmd` (ver [13b.3](#13b3-detalles-raros-y-textos-escritos-a-mano)) |

**Cómo se reparte cada color en las 11 gráficas** (es la tabla para responder "¿qué significa el naranja aquí?"):

| Gráfica | Colores | Qué significan en esa gráfica |
|---|---|---|
| `mejora_sobre_ingenua` | naranja · azul · gris | mercado · M0 · M4; la **opacidad** marca el periodo (tenue = validación) |
| `resultados_por_temporada` | verde · violeta · gris | local · visitante · empate |
| `resultado_favorito` | gris | no hay protagonistas: las tres barras son "contexto" |
| `resultado_por_diferencia_elo` | verde · violeta · gris | local · visitante · empate |
| `calibracion_mercado` | naranja | las cuotas de Bet365 |
| `ajuste_poisson` | gris · azul | datos observados · Poisson, que es el supuesto del modelo |
| `delta_vs_m0` | naranja · gris | mercado · M1–M4; el **relleno** del punto marca el periodo (hueco = validación) |
| `brecha_por_resultado` | naranja · azul | quién fue mejor en esos partidos: mercado · modelo |
| `efectos` | azul | los coeficientes de M0 |
| `calibracion_modelos` | naranja · azul | mercado · M0 |
| `modelo_vs_mercado` | gris oscuro (`TINTA_2`) | puntos sin significado propio (el resultado va en el tooltip) |

**Contraste contra blanco** (**cálculo propio**, razón de contraste de la WCAG 2.x; el criterio 1.4.3 pide 4.5:1 para texto
pequeño y el 1.4.11 pide 3:1 para elementos gráficos necesarios para entender el contenido):

| Constante | Contraste | Constante | Contraste |
|---|---|---|---|
| `MODELO` | 4.42:1 | `TINTA` | 19.68:1 |
| `MERCADO` | **3.20:1** | `TINTA_2` | 7.94:1 |
| `LOCAL` | 4.95:1 | `TENUE` / `CONTEXTO` | 3.59:1 |
| `VISITA` | 8.56:1 | `BASE` | 1.79:1 |
| `REJILLA` | 1.32:1 | `BANDA` | 1.12:1 |

Lectura honesta: los **cinco colores de entidad llegan a 3:1** como mínimo (los más bajos son el naranja y el gris),
suficiente para trazos y barras; la rejilla, las bandas y la línea de referencia son **decorativas a propósito** (es el
"menos tinta" del [cierre](#13b5-principios-de-visualización-aplicados)); y lo único flojo es que los **números de los
ejes** (`TENUE`, 3.59:1, letra de 12 px) quedan por debajo de los 4.5:1 que la WCAG pide para texto pequeño.

**Sobre la validación para daltonismo.** El docstring dice que la paleta se validó (separación entre pares y contraste
sobre fondo blanco). En la carpeta del tablero **no hay un script que repita esa validación**; lo que sí está documentado
es el cambio que provocó: el gris del empate junto a un tono aqua no se distinguía con deuteranopía y el local pasó a
verde ([capítulo 13, 13.3](13_dashboard.md) y [D43](19_decisiones_y_alternativas.md#d43-plotly-con-plantilla-única-y-paleta-con-significado--razonada)).
Esta guía **no repitió** la prueba de daltonismo; sólo calculó los contrastes de arriba.

**La paleta vive en tres lugares.** `graficas.py` (los gráficos), `estilos.scss` (variables CSS `--modelo`, `--mercado`,
`--local`, `--visita`, `--contexto`, con **los mismos cinco hex**) e `index.qmd` (las leyendas HTML escriben el hex a
mano, p. ej. `style="background:#898781"`). Los **neutros no coinciden** (en el CSS `--tinta` es `#171717`, `--tinta-2`
`#5f6368` y `--rejilla` `#eceef1`): sólo los cinco colores de entidad se mantuvieron idénticos. Si alguien cambia un
color, tiene que cambiarlo en los tres archivos.

**En R (ilustrativo):**

```r
# Una sola lista con nombre: el color depende de la entidad, no de la gráfica
colores <- c(modelo = "#2a78d6", mercado = "#eb6834", local = "#008300",
             visita = "#4a3aa7", contexto = "#898781")
TINTA <- "#0b0b0b"; TINTA_2 <- "#52514e"; TENUE <- "#898781"
REJILLA <- "#e1e0d9"; BASE <- "#c3c2b7"; BANDA <- "#f3f2ee"

# plot_ly:   marker = list(color = colores[["mercado"]])
# ggplot2:   scale_color_manual(values = colores) / scale_fill_manual(values = colores)
```

> **Decisión:** cinco colores con significado fijo en todo el tablero (azul = modelo, naranja = mercado, verde = local,
> violeta = visitante, gris = contexto), y gris para todo lo demás. · **Alternativas:** (a) la paleta por omisión de
> Plotly — a favor: cero trabajo; en contra: el color no significaría nada y el mismo azul podría ser el modelo en una
> gráfica y el local en otra (no se probó); (b) un color distinto para cada elemento (M0, M1, …, empate, periodos) — a
> favor: todo se distingue sin leyenda; en contra: "arcoíris" sin jerarquía, justo lo contrario de reservar el color
> "para lo importante"; (c) sólo grises y un acento — a favor: sobrio; en contra: el tablero tiene dos protagonistas (modelo
> y mercado) y tres resultados que hay que distinguir a la vez, un solo acento no alcanza; (d) el local en aqua — se usó
> al principio y se cambió a verde porque, con deuteranopía, el gris del empate se confundía con él (cap. 13/D43). · **Por
> qué ésta:** el lector aprende la clave una vez ("naranja = mercado") y la aplica en las cuatro páginas; la comparación
> modelo contra mercado, que es la pregunta del proyecto, siempre es azul contra naranja. · **Si preguntan:** "Cada color
> significa siempre lo mismo: azul el modelo, naranja el mercado, verde el local, violeta el visitante y gris el
> contexto. Así se puede leer cualquier gráfica sin consultar una leyenda nueva."

### 13b.1.3 `FUENTE`

Línea 41:

```python
FUENTE = 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'
```

Una **pila de fuentes del sistema**: el navegador usa la primera que exista en el dispositivo (`system-ui` es la fuente
de interfaz del sistema operativo; `-apple-system` la de Apple; `"Segoe UI"` la de Windows; `Roboto`, la de Android;
`Helvetica Neue` y `Arial`, respaldos; `sans-serif`, el último recurso). Es **la misma pila** que `$font-family-sans-serif`
de `estilos.scss`, así que la letra de las gráficas y la del resto de la página coinciden. Las comillas externas son
simples y las internas dobles porque dos nombres llevan espacio.

**En R (ilustrativo):** `FUENTE <- 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'`; en
`plot_ly`, `layout(font = list(family = FUENTE))`; en `ggplot2` las gráficas estáticas usan las fuentes que conozca R
(`theme(text = element_text(family = "sans"))`), pero con `ggplotly()` el navegador sí respeta esta pila.

> **Decisión:** fuente del sistema, la misma pila que usa el CSS del sitio. · **Alternativas:** (a) una fuente web
> (p. ej. de Google Fonts) — a favor: se ve idéntica en todos los equipos; en contra: pide un archivo externo (más lento,
> falla sin internet) y la letra puede llegar "a destiempo", justo cuando Plotly ya midió los textos con otra (no se
> probó); (b) una sola fuente fija (`Arial`) — a favor: casi universal; en contra: ajena al resto del sitio (no se probó);
> (c) la fuente por omisión de Plotly (`"Open Sans", verdana, arial, sans-serif`) — a favor: cero código; en contra:
> no coincide con la página (no se probó). · **Por qué ésta:** misma letra en gráficas y página, sin descargas y sin que
> el texto cambie de ancho después de dibujarse. · **Si preguntan:** "Usamos la fuente del sistema de cada dispositivo,
> la misma del resto del sitio: no se descarga nada y el texto de las gráficas no se mueve al cargar."

### 13b.1.4 `CONFIG`

Línea 42:

```python
CONFIG = {"displayModeBar": False, "responsive": True, "scrollZoom": False, "doubleClick": False}
```

Son opciones de **plotly.js** (el motor que corre en el navegador), no de la figura; `mostrar` las pasa en
`fig.show(config=CONFIG)`.

| Opción | Valor | Qué hace | Por qué |
|---|---|---|---|
| `displayModeBar` | `False` | oculta la barra flotante de herramientas (descargar imagen, acercar, mover, restablecer) | gráficas de **lectura**: la barra distrae, ocupa sitio y ofrece justo las herramientas (zoom, mover) que se quitaron |
| `responsive` | `True` | la figura se redimensiona cuando cambia el tamaño de la ventana o de la tarjeta | las tarjetas tienen anchos en porcentaje (62 %/38 %, 64 %/36 %…) y el sitio se ve en pantallas de tamaños muy distintos |
| `scrollZoom` | `False` | la rueda del ratón **no** hace zoom sobre la gráfica | la página se desplaza (`scrolling: true`) y casi siempre el puntero está sobre una gráfica; así la rueda sigue moviendo la página. Para ejes cartesianos Plotly ya lo trae apagado: se escribe explícito para dejar la intención |
| `doubleClick` | `False` | el doble clic no restablece el rango de los ejes | sin zoom no hay nada que restablecer; evita acciones accidentales (p. ej. un doble toque en el celular). *Inferencia razonada: ni el docstring ni el commit lo justifican por separado.* |

Se complementa en `mostrar` con `dragmode=False` (no se arrastra para hacer zoom ni mover) y `fixedrange=True` en cada eje
(los ejes no se pueden escalar ni con gestos táctiles). Los **tooltips siguen activos**: son la parte interactiva que se
conservó.

**En R (ilustrativo):**

```r
fig |> config(displayModeBar = FALSE, responsive = TRUE, scrollZoom = FALSE, doubleClick = FALSE) |>
       layout(dragmode = FALSE, xaxis = list(fixedrange = TRUE), yaxis = list(fixedrange = TRUE))
```

(`config()` de `plotly` acepta las mismas opciones de plotly.js. Con `subplot()` hay que repetir `fixedrange` para
`xaxis2` y `yaxis2`; en Python `update_xaxes` / `update_yaxes` ya recorren todos los ejes.)

> **Decisión:** gráficas de sólo lectura: sin barra de herramientas, sin zoom (ni con la rueda, ni arrastrando, ni con
> doble clic) y con los tooltips activos. · **Alternativas:** (a) dejar la interactividad completa de Plotly — a favor: el
> lector puede acercarse a lo que quiera; en contra: un arrastre accidental dejaba la gráfica ampliada y sin forma visible
> de regresar (así estaba al principio, se observó y se corrigió; docstring y D43); (b) imágenes estáticas (`ggplot2` o
> `matplotlib`) — a favor: se ven igual en todos lados y no dependen de JavaScript; en contra: sin tooltips, que es donde
> viven el LogLoss, el número de casos y los intervalos (no se probó); (c) dejar el zoom y poner un botón de restablecer
> visible — a favor: conserva la exploración; en contra: más elementos en cada tarjeta y más cosas que pueden fallar en
> el celular (no se probó). · **Por qué ésta:** el tablero cuenta una historia, no es una herramienta de exploración (para
> explorar están el simulador y las tablas); cada gráfica tiene una sola lectura y el detalle sigue en el tooltip. ·
> **Si preguntan:** "Quitamos el zoom porque un arrastre sin querer dejaba la gráfica ampliada y sin forma de regresar;
> las gráficas cuentan una historia, y el detalle sigue en los tooltips y en las tablas."

### 13b.1.5 `PLANTILLA`

Líneas 44–61:

```python
PLANTILLA = go.layout.Template(layout=dict(
    font=dict(family=FUENTE, size=13, color=TINTA_2),
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="rgba(0,0,0,0)",
    colorway=[MODELO, MERCADO, LOCAL, VISITA, CONTEXTO],
    margin=dict(l=8, r=24, t=16, b=8),
    xaxis=dict(showgrid=True, gridcolor=REJILLA, gridwidth=1, zeroline=False, showline=False,
               ticks="", tickfont=dict(color=TENUE, size=12), title=dict(font=dict(size=12, color=TINTA_2)),
               automargin=True),
    yaxis=dict(showgrid=True, gridcolor=REJILLA, gridwidth=1, zeroline=False, showline=False,
               ticks="", tickfont=dict(color=TENUE, size=12), title=dict(font=dict(size=12, color=TINTA_2)),
               automargin=True),
    legend=dict(orientation="h", x=0, xanchor="left", y=1.02, yanchor="bottom",
                bgcolor="rgba(0,0,0,0)", font=dict(size=12, color=TINTA_2), title=dict(text="")),
    hoverlabel=dict(bgcolor="white", bordercolor=REJILLA, font=dict(family=FUENTE, size=12, color=TINTA)),
    hovermode="closest",
    separators=".,",
))
```

Una **plantilla** de Plotly es un conjunto de valores por omisión para el diseño (`layout`) y para cada tipo de traza.
Aquí sólo lleva diseño. Se aplica con `fig.update_layout(template=PLANTILLA)` (en `mostrar`). **Regla de precedencia:** lo
que una función fija por su cuenta (por ejemplo, su propio `margin`) **gana** a la plantilla; la plantilla sólo rellena
lo que la figura no dijo. Y `layout.xaxis` de la plantilla vale para **todos** los ejes x de la figura (también `xaxis2`
de los paneles).

| Ajuste | Valor | Qué hace |
|---|---|---|
| `font` | `FUENTE`, 13 px, `TINTA_2` | letra base: gris oscuro (no negro puro); lo que debe leerse con más fuerza (nombres de categoría) se pinta aparte con `TINTA` |
| `paper_bgcolor`, `plot_bgcolor` | `rgba(0,0,0,0)` | fondo **transparente** del lienzo y del área de dibujo: se ve el fondo de la tarjeta y no hay recuadro blanco |
| `colorway` | los cinco colores de entidad | colores por omisión de una traza que no fija el suyo. Ninguna función depende de esto (todas fijan color); es una red de seguridad coherente con la paleta |
| `margin` | `l=8, r=24, t=16, b=8` px | márgenes mínimos: la tarjeta ya trae su relleno. Muchas funciones los redefinen (p. ej. `r=110` para los rótulos de línea) |
| `xaxis`/`yaxis` · `showgrid`, `gridcolor`, `gridwidth` | `True`, `REJILLA`, 1 | rejilla fina y clara |
| · `zeroline`, `showline`, `ticks` | `False`, `False`, `""` | sin línea del cero, sin línea de eje, sin marcas: menos tinta |
| · `tickfont` | `TENUE`, 12 px | números de los ejes, discretos |
| · `title.font` | 12 px, `TINTA_2` | títulos de ejes |
| · `automargin` | `True` | el margen crece lo necesario para que no se corten etiquetas o títulos |
| `legend` | horizontal, arriba a la izquierda, fondo transparente, sin título | **inerte**: `mostrar` apaga la leyenda. Sirve sólo si alguien muestra una figura sin pasar por `mostrar` |
| `hoverlabel` | fondo blanco, borde `REJILLA`, `FUENTE` 12 px `TINTA` | tooltip claro y legible |
| `hovermode` | `"closest"` | el tooltip es del punto más cercano al puntero (`resultados_por_temporada` lo cambia a `"x unified"`) |
| `separators` | `".,"` | primero el separador **decimal** y luego el de **millares**: "54.2%", "9,160". Es también el valor por omisión de Plotly; se deja escrito para constatar que el tablero usa punto decimal y coma de millares (convención de México, la misma de los textos de `index.qmd`) |

**En R (ilustrativo).** En `plotly` para R no se suele armar una plantilla: se escribe una función que aplica el mismo
`layout()` y se llama al final de cada gráfica; en `ggplot2`, el equivalente natural es un `theme_...()` propio.

```r
tema_dashboard <- function(fig) {
  eje <- list(showgrid = TRUE, gridcolor = REJILLA, gridwidth = 1, zeroline = FALSE, showline = FALSE,
              ticks = "", tickfont = list(color = TENUE, size = 12),
              title = list(font = list(size = 12, color = TINTA_2)), automargin = TRUE)
  fig |> layout(
    font = list(family = FUENTE, size = 13, color = TINTA_2),
    paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
    colorway = unname(colores), margin = list(l = 8, r = 24, t = 16, b = 8),
    xaxis = eje, yaxis = eje,
    hoverlabel = list(bgcolor = "white", bordercolor = REJILLA, font = list(family = FUENTE, size = 12, color = TINTA)),
    hovermode = "closest", separators = ".,")
}

# versión ggplot2 (luego ggplotly()):
theme_dashboard <- function() {
  theme_minimal(base_size = 13) +
    theme(text = element_text(color = TINTA_2),
          panel.grid.major = element_line(color = REJILLA, linewidth = 0.4), panel.grid.minor = element_blank(),
          axis.text = element_text(color = TENUE, size = 12), axis.title = element_text(color = TINTA_2, size = 12),
          axis.ticks = element_blank(), legend.position = "none",
          plot.background = element_rect(fill = NA, color = NA), panel.background = element_rect(fill = NA, color = NA))
}
```

> **Decisión:** una sola `PLANTILLA`, aplicada en `mostrar`, con la fuente, los fondos transparentes, la rejilla clara y el
> tooltip del tablero. · **Alternativas:** (a) repetir esos ajustes con `update_layout` dentro de cada función — a favor: cada
> función es autosuficiente; en contra: 11 copias que mantener (cambiar la fuente obligaría a tocar 11 sitios); (b) fijarla
> como plantilla global (`pio.templates.default`) — a favor: aplica a todas las figuras sin llamar a `mostrar`; en contra:
> efecto "invisible" y global, separado del resto de la configuración visual (`CONFIG`, ejes fijos) que sí vive en `mostrar`
> (no se probó); (c) una plantilla incluida en Plotly (`plotly_white`, `simple_white`) — a favor: cero código; en contra: no
> cambian la fuente ni los colores como se quería y habría que ajustar igualmente (no se probó). · **Por qué ésta:** el
> estilo vive en un solo lugar y las funciones sólo describen datos; la plantilla y `CONFIG` se aplican juntas, en el
> único punto por el que pasa toda gráfica. · **Si preguntan:** "Hay una plantilla para todo el tablero, con la fuente, los
> fondos transparentes y la rejilla suave; cada gráfica sólo dice qué datos dibuja, y por eso todas se ven como una familia."

---

## 13b.2 Las funciones, en el orden del archivo

Cada función se explica con el mismo guion: **qué pregunta responde** y qué tabla recibe, **el código real**, **qué dibuja y
cómo** (trazas, ejes, anotaciones, tooltip), **un ejemplo con las cifras reales**, su **equivalente en R (ilustrativo)** y
el **recuadro de decisión** donde hubo una elección de diseño.

**Vocabulario mínimo de Plotly** (para leer el código sin conocer la librería):

| Término | Qué es | Equivalente en R |
|---|---|---|
| traza (`add_bar`, `add_scatter`) | una serie de datos dibujada de un modo (barras, puntos, líneas) | `add_bars()`, `add_markers()`, `add_lines()` o `add_trace()` en `plot_ly`; una `geom_*` en `ggplot2` |
| `layout` (`update_layout`, `update_xaxes`) | todo lo que no son datos: márgenes, ejes, leyenda, modo de barras | `layout()` |
| anotación (`add_annotation`) | un texto, con flecha opcional, puesto en coordenadas de los datos o de la figura | `add_annotations()` / `annotate()` |
| forma (`add_vline`, `add_vrect`) | línea o rectángulo en coordenadas de datos o de "papel" | `layout(shapes = list(...))` / `geom_vline()`, `annotate("rect")` |
| `xref`/`yref="paper"` | coordenadas **relativas a la figura** (de 0 a 1) en vez de a los datos | igual |
| `hovertemplate` | plantilla del texto del tooltip, con `%{x}`, `%{y}` y `%{customdata[0]}` | igual en `plot_ly`; en `ggplot2`, `aes(text = …)` + `ggplotly(tooltip = "text")` |
| `customdata` | columnas extra que viajan con cada punto, para usarlas en el tooltip | `customdata =` en `plot_ly` |
| `make_subplots` | una rejilla de paneles | `subplot()` / `facet_wrap()` |

**Formatos numéricos del tooltip y de los ejes** (sintaxis de d3, la que usa plotly.js; no es la de Python):

| Formato | Número | Resultado |
|---|---|---|
| `%{y:.1%}` | 0.5425 | 54.2% |
| `%{x:.3f}` | 0.053715 | 0.054 |
| `%{x:+.4f}` | −0.0109 | −0.0109 (siempre con signo) |
| `%{customdata:,}` | 9160 | 9,160 |
| `tickformat=".0%"` | 0.3 | 30% |

### Ayudantes

#### 13b.2.1 `mostrar`

Líneas 64–72. **Recibe** una figura ya construida por cualquiera de las 11 funciones de gráfica y **devuelve `None`**: su
trabajo es dibujarla.

```python
def mostrar(fig: go.Figure) -> None:
    """Muestra una figura de sólo lectura, adaptada al tamaño de la tarjeta.

    Sin barra de herramientas, sin zoom ni arrastre (ejes fijos) y sin leyenda interna.
    """
    fig.update_layout(template=PLANTILLA, autosize=True, dragmode=False, showlegend=False)
    fig.update_xaxes(fixedrange=True)
    fig.update_yaxes(fixedrange=True)
    fig.show(config=CONFIG)
```

| Línea | Qué hace |
|---|---|
| `update_layout(template=PLANTILLA, …)` | aplica la plantilla ([13b.1.5](#13b15-plantilla)): fuente, fondos, rejilla, tooltip |
| `autosize=True` | la figura toma el tamaño de su contenedor (la tarjeta) en vez de uno fijo |
| `dragmode=False` | arrastrar con el ratón no hace zoom ni mueve la gráfica |
| `showlegend=False` | **apaga la leyenda interna** de todas las figuras (las leyendas van en HTML; ver el recuadro) |
| `update_xaxes(fixedrange=True)`, `update_yaxes(...)` | los ejes no se pueden escalar ni mover (tampoco con gestos táctiles); en figuras con paneles recorren **todos** los ejes |
| `fig.show(config=CONFIG)` | envía la figura a la salida del chunk con las opciones de plotly.js de [13b.1.4](#13b14-config) |

**Por qué devuelve `None`.** Quarto (motor Jupyter) imprime también las expresiones sueltas de un chunk que devuelven un
objeto. Si `mostrar` devolviera la figura, el chunk la mostraría **otra vez**, ahora con la configuración por omisión de
Plotly (con barra de herramientas). Por eso la línea de cada tarjeta es una sola expresión que ya no devuelve nada. Es la
razón de la última regla del docstring: *"las figuras se construyen dentro de funciones: el motor de Quarto imprime cualquier
expresión suelta que devuelva una figura (p. ej. una línea `fig.update_layout(...)`)"*. Si el código de una gráfica
estuviera suelto en el chunk, **cada** línea `fig.update_layout(...)` se imprimiría como una figura.

**En R (ilustrativo).** No hace falta un `show()`: `knitr` imprime el objeto `plotly` que devuelve el chunk. (En R pasa
algo parecido a lo de Quarto: en un chunk se imprime el valor visible de **cada** expresión de nivel superior, así que un
`fig |> add_trace(...)` suelto también dibujaría una figura; la costumbre es encadenar todo con `|>` en una sola
expresión, o dentro de una función como aquí.)

```r
mostrar <- function(fig) {
  fig |>
    tema_dashboard() |>                                   # ≈ template=PLANTILLA
    layout(autosize = TRUE, dragmode = FALSE, showlegend = FALSE,
           xaxis = list(fixedrange = TRUE), yaxis = list(fixedrange = TRUE)) |>
    config(displayModeBar = FALSE, responsive = TRUE, scrollZoom = FALSE, doubleClick = FALSE)
}
```

> **Decisión:** ninguna figura muestra su leyenda de Plotly (`showlegend=False`); las leyendas que hacen falta (la opacidad
> = periodo, hueco = validación, rombo = Poisson…) van como HTML dentro del subtítulo de la tarjeta, en `index.qmd`. ·
> **Alternativas:** (a) la leyenda de Plotly — a favor: se genera sola con el `name` de cada traza; en contra: Plotly mide
> mal sus leyendas cuando la página del tablero está oculta al dibujarse la gráfica y las entradas se enciman (problema
> observado; docstring y D46); (b) etiquetar directamente cada serie, sin leyenda — a favor: el lector no tiene que ir y
> volver con la vista (se hace en `resultados_por_temporada` y `resultado_por_diferencia_elo`); en contra: no sirve para
> codificaciones como la opacidad o hueco/relleno (se hace donde se puede); (c) dibujar la leyenda con anotaciones de
> Plotly — a favor: queda dentro de la figura; en contra: más código frágil y los mismos problemas de medida (no se
> probó). · **Por qué ésta:** una leyenda en HTML no depende de cómo mida Plotly y se estiliza con el mismo CSS que el resto
> de la tarjeta (muestras de color con la clase `.muestra`, [13c](13c_codigo_index_quarto.md)). · **Si preguntan:** "Las
> leyendas de Plotly se enciman cuando la gráfica se dibuja en una página oculta; las pusimos en HTML, en el subtítulo
> de cada tarjeta, y donde se puede etiquetamos directamente las líneas."

> **Complemento (D46):** aun con esto, una gráfica dibujada en una pestaña oculta se mide mal (todo mide 0 px). Lo resuelve
> `redibujar.html`, un script que vuelve a dibujar cada gráfica cuando su tarjeta se vuelve visible; está en
> [13c, 3.3](13c_codigo_index_quarto.md) y en [D46](19_decisiones_y_alternativas.md#d46-redibujarhtml-para-las-gráficas-en-pestañas-ocultas--razonada).

#### 13b.2.2 `_pct`

Líneas 75–76:

```python
def _pct(x, dec=1):
    return f"{x * 100:.{dec}f}%"
```

Convierte una proporción en texto con porcentaje. El f-string anidado `.{dec}f` toma el número de decimales del argumento
`dec` (por omisión 1). **Ejemplo:** `_pct(0.273684)` → `"27.4%"` (el empate de 2025/26). Sin espacio antes del `%`: así
salen también los tooltips (`%{y:.1%}`).

**Quién lo usa:** los rótulos al final de las líneas de `resultados_por_temporada` ("Local 42.6%") y los rótulos de las
barras de `resultado_favorito` ("54.2%"). Las otras gráficas formatean con sus propias cadenas (`f"{v:.3f}"`).

**Por qué existe:** el texto de las anotaciones y de `text=` es una cadena fija; Plotly **no** le aplica los formatos de d3
(`.1%`) que sí aplica en los tooltips y ejes. (Para las barras también habría servido `texttemplate="%{x:.1%}"`.)

**En R (ilustrativo):** `scales::percent(x, accuracy = 0.1)` → `"27.4%"`, o `sprintf("%.1f%%", x * 100)` (el `%%` escribe un `%`).

#### 13b.2.3 `_anotacion`

Líneas 79–82:

```python
def _anotacion(fig, texto, x, y, ax=0, ay=-40, xref="x", yref="y", align="left", **kw):
    fig.add_annotation(text=texto, x=x, y=y, xref=xref, yref=yref, ax=ax, ay=ay,
                       showarrow=ax != 0 or ay != 0, arrowhead=0, arrowwidth=1, arrowcolor=TENUE,
                       font=dict(size=12, color=TINTA_2), align=align, bgcolor="rgba(255,255,255,0.85)", **kw)
```

Un ayudante para poner un texto con una **flecha delgada sin punta** (`arrowhead=0`: sólo una línea que lo une al punto) y
un fondo blanco semitransparente. Cómo se leen los argumentos de una anotación de Plotly:

- `x`, `y`: el **punto señalado** (donde termina la flecha).
- `ax`, `ay`: el **otro extremo de la flecha**, donde se coloca el texto. Por omisión son **desplazamientos en píxeles**
  desde `(x, y)` (aquí `ay=-40`: el texto queda 40 px **arriba**, porque en pantalla el eje vertical crece hacia abajo).
  Si se agrega `axref="x"` / `ayref="y"`, se leen como **coordenadas de los datos** (así lo hacen las anotaciones que sí
  se usan).
- `showarrow=ax != 0 or ay != 0`: se dibuja la flecha sólo si hay desplazamiento; si no, el texto queda sobre el punto.
- `**kw` deja pasar más argumentos (`xanchor`, `xshift`…).

> **Detalle:** `_anotacion` **no se usa en ninguna parte del proyecto** (código muerto). Las gráficas repiten el mismo bloque
> `add_annotation(... arrowhead=0, arrowwidth=1, arrowcolor=TENUE ...)` a mano, con un fondo de 0.9 en vez de 0.85. Una
> limpieza futura podría sustituir esos bloques por llamadas a `_anotacion(..., axref="x", ayref="y")`; no afecta al
> resultado.

**En R (ilustrativo):**

```r
anotacion <- function(fig, texto, x, y, ax = 0, ay = -40, ...) {
  fig |> add_annotations(text = texto, x = x, y = y, ax = ax, ay = ay,
                         showarrow = (ax != 0 || ay != 0), arrowhead = 0, arrowwidth = 1, arrowcolor = TENUE,
                         font = list(size = 12, color = TINTA_2), bgcolor = "rgba(255,255,255,0.85)", ...)
}
# ggplot2: annotate("label", x, y, label = texto) + annotate("segment", ...) para la línea de unión
```

### Resumen

#### 13b.2.4 `mejora_sobre_ingenua`

**Qué pregunta responde:** ¿cuánto mejora cada predictor a una referencia ingenua y qué tan cerca queda el modelo del
mercado? Es la gráfica principal de la portada (página *Resumen*, 62 % del ancho); el título de la tarjeta ya es la
conclusión: *"El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo"*.

**Recibe:** `met` = `d["metricas"]` ([13a.5.4](13a_codigo_datos_dashboard.md#13a54-tabla_metricas)): 18 filas (9 predictores ×
2 periodos) con las columnas `conjunto`, `predictor`, `nombre`, `partidos`, `logloss`, `prob_resultado_real`, `aciertos`,
`p_empate_media`, `mae_promedio`. Esta función usa `conjunto`, `predictor`, `logloss` y `aciertos`. (El LogLoss y la referencia
ingenua se definen en el [capítulo 9](09_evaluacion_y_validacion.md): menos LogLoss es mejor.)

**El código** (líneas 86–114), en tres bloques. Primero, **qué se compara y cómo se calcula la mejora**:

```python
def mejora_sobre_ingenua(metricas: pd.DataFrame) -> go.Figure:
    """Barras agrupadas: mejora de LogLoss respecto a la referencia ingenua."""
    filas = [("Mercado_apertura", "Mercado (cuotas de apertura)", MERCADO),
             ("M0_Base", "Modelo base M0 · 3 variables", MODELO),
             ("M4_Completo", "Modelo completo M4 · 9 variables", CONTEXTO)]
    fig = go.Figure()
    for conjunto, opacidad, etiqueta_periodo in [("Validación", 0.4, "Validación 2024/25"),
                                                  ("Prueba", 1.0, "Prueba 2025/26 – sep 2026")]:
        m = metricas[metricas["conjunto"] == conjunto].set_index("predictor")
        base = m.loc["Ingenua", "logloss"]
        x = [base - m.loc[p, "logloss"] for p, _, _ in filas]
```

- `filas`: lista de tuplas `(clave del predictor, etiqueta en español, color)` **en el orden en que se dibujan**:
  mercado, M0, M4. Las etiquetas "· 3 variables" y "· 9 variables" están escritas a mano (son ciertas: M0 tiene 3 variables
  por ecuación y M4, 9; ver [13b.3](#13b3-detalles-raros-y-textos-escritos-a-mano)).
- El bucle da **dos vueltas**, una por periodo, con su opacidad (0.4 la validación, 1.0 la prueba) y la etiqueta que irá en
  el tooltip. Los periodos son los de la partición del proyecto: validación = temporada 2024/25; prueba = 2025/26 más los
  partidos de 2026/27 hasta el 14-sep-2026.
- `m`: las filas de ese periodo, con el nombre del predictor como índice (`set_index`), de modo que `m.loc["Ingenua",
  "logloss"]` es el LogLoss de la referencia ingenua en ese periodo (R: `m$logloss[m$predictor == "Ingenua"]`).
- `x = [base - m.loc[p, "logloss"] for p, _, _ in filas]`: la **mejora** = LogLoss de la ingenua − LogLoss del predictor.
  Positivo = mejor que la ingenua. (`for p, _, _ in filas` desempaqueta cada tupla y se queda sólo con la clave; el
  guion bajo `_` es el nombre convencional de "no me interesa".)

Segundo bloque: **la traza de barras** (una por periodo):

```python
        fig.add_bar(
            y=[n for _, n, _ in filas], x=x, orientation="h", name=etiqueta_periodo, showlegend=False,
            marker=dict(color=[c for _, _, c in filas], opacity=opacidad, cornerradius=4),
            text=[f"{v:.3f}" for v in x], textposition="outside", cliponaxis=False, constraintext="none",
            textfont=dict(color=TINTA_2, size=12),
            customdata=np.column_stack([[m.loc[p, "logloss"] for p, _, _ in filas],
                                        [m.loc[p, "aciertos"] for p, _, _ in filas]]),
            hovertemplate=("<b>%{y}</b><br>" + etiqueta_periodo +
                           "<br>Mejora vs. ingenua: %{x:.3f}<br>LogLoss: %{customdata[0]:.3f}"
                           "<br>Aciertos: %{customdata[1]:.1%}<extra></extra>"),
        )
```

| Argumento | Qué hace |
|---|---|
| `y=[nombres]`, `x=mejoras`, `orientation="h"` | barras **horizontales**: la longitud es la mejora; las categorías van en el eje vertical |
| `marker.color=[tres colores]` | un color **por barra** (naranja, azul, gris), no por traza |
| `marker.opacity` | 0.4 (tenue) o 1.0 (sólido): **codifica el periodo** |
| `marker.cornerradius=4` | esquinas redondeadas de 4 px (cosmético; propiedad reciente de Plotly: una razón para dejar fija la versión en `requirements.txt`, `plotly==5.24.1`) |
| `text`, `textposition="outside"` | la cifra con 3 decimales **al final** de cada barra (etiqueta directa) |
| `cliponaxis=False` | el rótulo puede salirse del área de dibujo (hay 48 px de margen derecho) en vez de cortarse |
| `constraintext="none"` | Plotly no encoge ni gira el rótulo para que quepa |
| `customdata` | una matriz de 3 × 2 con el LogLoss y los aciertos de cada barra, para el tooltip (`np.column_stack` pega las dos listas como columnas) |
| `hovertemplate` | HTML mínimo (`<b>`, `<br>`) con `%{y}`, `%{x:.3f}`, `%{customdata[0]:.3f}`, `%{customdata[1]:.1%}`; `<extra></extra>` oculta el cuadro secundario con el nombre de la traza |
| `showlegend=False`, `name` | el `name` sólo se usa en el tooltip; la leyenda va en el HTML de la tarjeta |

Tercer bloque: **el diseño**.

```python
    # El color identifica la entidad y la opacidad el periodo; la leyenda de la opacidad va en
    # el subtítulo de la tarjeta (HTML).
    fig.update_layout(barmode="group", bargap=0.35, bargroupgap=0.12, margin=dict(l=8, r=48, t=8, b=8))
    fig.update_xaxes(title_text="Reducción del LogLoss respecto a la referencia ingenua (más es mejor)",
                     rangemode="tozero", tickformat=".2f")
    fig.update_yaxes(autorange="reversed", showgrid=False, tickfont=dict(color=TINTA, size=13))
    return fig
```

- `barmode="group"`: las dos barras de cada predictor van **lado a lado** (no apiladas). `bargap=0.35` es el espacio entre
  predictores y `bargroupgap=0.12` el espacio entre las dos barras de un mismo predictor.
- Eje x: título que dice qué es y hacia dónde es mejor ("más es mejor"), `rangemode="tozero"` (el eje siempre incluye el 0:
  **barras desde cero**) y 2 decimales en las marcas.
- Eje y: `autorange="reversed"` pone la **primera categoría arriba** (como se lee una lista; Plotly por omisión la pone
  abajo); sin rejilla; nombres en `TINTA`, 13 px.

**Ejemplo con las cifras reales** (el texto de cada barra es la columna "mejora"; entre paréntesis, lo que muestra el
tooltip). Referencia ingenua: LogLoss 1.079361 en validación y 1.086791 en prueba.

| Predictor | Validación 2024/25 | Prueba 2025/26 – sep 2026 |
|---|---|---|
| Mercado (cuotas de apertura) | **0.109** (LogLoss 0.971; aciertos 54.2 %) | **0.067** (1.020; 48.9 %) |
| Modelo base M0 · 3 variables | **0.090** (0.990; 53.2 %) | **0.054** (1.033; 48.0 %) |
| Modelo completo M4 · 9 variables | **0.101** (0.979; 53.7 %) | **0.050** (1.037; 47.5 %) |

**Cómo se lee:** en prueba, M0 llega a 0.054 de los 0.067 que logra el mercado (0.0537 / 0.0668 = **80 %**, la cifra de la
*value box* "Ventaja del mercado que alcanza el modelo"; [13a.5.5](13a_codigo_datos_dashboard.md#13a55-fraccion_de_mejora)).
Y la gráfica cuenta además la historia de la página *El modelo*: en validación M4 supera a M0 (0.101 contra 0.090), pero
en prueba el orden se **invierte** (0.050 contra 0.054): más variables no generalizan mejor. (Observado en el sitio: dentro de
cada par, la barra tenue —validación— queda **arriba** y la sólida —prueba— **abajo**, porque el eje y está invertido.)

**En R (ilustrativo, no ejecutado):**

```r
mejora_sobre_ingenua <- function(metricas) {
  filas <- tibble::tribble(
    ~predictor,         ~nombre,                             ~color,
    "Mercado_apertura", "Mercado (cuotas de apertura)",      MERCADO,
    "M0_Base",          "Modelo base M0 · 3 variables",      MODELO,
    "M4_Completo",      "Modelo completo M4 · 9 variables",  CONTEXTO)
  fig <- plot_ly()
  for (cj in c("Validación", "Prueba")) {
    m    <- filter(metricas, conjunto == cj)
    base <- m$logloss[m$predictor == "Ingenua"]
    s    <- left_join(filas, select(m, predictor, logloss, aciertos), by = "predictor") |>
              mutate(mejora = base - logloss)
    fig  <- fig |> add_bars(
      y = factor(s$nombre, levels = filas$nombre),          # en R el orden de las categorías sale de los niveles
      x = s$mejora, orientation = "h",
      marker = list(color = s$color, opacity = if (cj == "Validación") 0.4 else 1),
      text = sprintf("%.3f", s$mejora), textposition = "outside", cliponaxis = FALSE,
      customdata = cbind(s$logloss, s$aciertos),
      hovertemplate = paste0("<b>%{y}</b><br>", cj, "<br>Mejora vs. ingenua: %{x:.3f}",
                             "<br>LogLoss: %{customdata[0]:.3f}<br>Aciertos: %{customdata[1]:.1%}<extra></extra>"))
  }
  fig |> layout(barmode = "group", bargap = 0.35, bargroupgap = 0.12, margin = list(r = 48),
                xaxis = list(title = "Reducción del LogLoss respecto a la referencia ingenua (más es mejor)",
                             rangemode = "tozero", tickformat = ".2f"),
                yaxis = list(autorange = "reversed", showgrid = FALSE))
}
# ggplot2: datos en formato largo + geom_col(position = "dodge", aes(alpha = conjunto)) + scale_alpha_manual(c(0.4, 1))
#          + geom_text(hjust = -0.1) + scale_y_discrete(limits = rev) y luego ggplotly()
```

> **Decisión:** barras horizontales agrupadas, desde cero, que muestran la **mejora** respecto a la referencia ingenua
> (ingenua − predictor) y no el LogLoss mismo. · **Alternativas:** (a) barras con el LogLoss — a favor: es la métrica
> tal cual; en contra: 0.971, 0.990 y 1.087 se ven casi iguales desde cero (las diferencias están en la segunda y tercera
> cifra) y "menos es mejor" confunde a quien no conoce el LogLoss; (b) el LogLoss con el eje recortado (no desde cero) — a
> favor: separa los valores; en contra: exagera las diferencias, justo lo que no debe hacerse con barras; (c) puntos o
> *lollipops* — a favor: no exigen el cero; en contra: menos fuerza visual para una conclusión que debe leerse en 20
> segundos; (d) sólo una tabla — a favor: precisión; en contra: no se lee de un vistazo (y los valores sí están en
> "Métricas completas"). Ninguna se probó. · **Por qué ésta:** con la ingenua en cero, "más largo = mejor" y la barra de cada
> predictor es **cuánto** mejora; la conclusión del título se ve comparando la barra azul con la naranja (0.054 contra
> 0.067 en prueba). · **Si preguntan:** "La barra es cuánto baja el error respecto a una referencia que sólo conoce las
> frecuencias históricas: el modelo llega a 0.054 y el mercado a 0.067 en prueba, o sea, el modelo alcanza el 80 % de lo
> que logra el mercado."

> **Decisión:** el color identifica a la entidad (naranja mercado, azul M0, gris M4) y la **opacidad** al periodo (tenue =
> validación, sólido = prueba), con la clave en el subtítulo (HTML). · **Alternativas:** (a) un panel por periodo — a favor:
> nada se codifica con la opacidad; en contra: duplica el espacio y separa las dos barras de cada predictor, justo las que
> hay que comparar; (b) un color por periodo — a favor: se distingue sin clave aparte; en contra: rompe el significado fijo
> de los colores (azul = modelo); (c) superponer o apilar los dos periodos — a favor: ocupa menos; en contra: se
> confunden. Ninguna se probó. · **Por qué ésta:** conserva el significado del color y deja pegados los dos periodos de
> cada predictor; además la opacidad es una diferencia de claridad, que se distingue también con daltonismo. · **Si
> preguntan:** "El color dice quién es —naranja el mercado, azul el modelo— y lo tenue o sólido dice el periodo; la
> clave está en el subtítulo de la tarjeta."

> **Decisión:** el orden de las filas es fijo y narrativo (mercado, M0, M4) y no se ordena por valor. · **Alternativas:**
> (a) ordenar de mayor a menor mejora — a favor: lectura "ranking"; en contra: el orden cambia entre validación y prueba
> (en validación M4 > M0; en prueba M0 > M4) y no hay un orden único para las dos barras de cada fila; (b) M0 primero —
> a favor: el protagonista arriba; en contra: se pierde la lectura "referencia (mercado) y luego el modelo". Ninguna se
> probó. · **Por qué ésta:** el mercado es la vara de medir, M0 el protagonista y M4 el contraste. · **Si preguntan:**
> "Las filas van en orden de la historia: el mercado como referencia, el modelo base y el modelo completo."

### ¿Qué ocurre?

#### 13b.2.5 `resultados_por_temporada`

**Qué pregunta responde:** ¿ganar en casa es una ventaja constante?, ¿cómo se ha repartido cada temporada entre local,
empate y visitante?, ¿y qué temporadas usa el modelo? Es la gráfica principal de la página *¿Qué ocurre?* (64 % del ancho),
con el título *"Jugar en casa siempre ayuda… salvo sin público"* y el subtítulo *"Las bandas grises marcan los periodos que
usa el modelo."*

**Recibe:** `t` = `d["temporadas"]` = `resumen_temporadas()` ([13a.4.2](13a_codigo_datos_dashboard.md#13a42-resumen_temporadas)):
**25 filas, de 2001/02 a 2025/26** (sólo temporadas completas: el código de datos filtra `temporada <= 2025`, así que la
temporada en curso, con 40 partidos, no aparece). Columnas: `temporada` (**entero: el año en que empieza**, 2001…2025),
`partidos`, `pct_local`, `pct_empate`, `pct_visita`, `goles_local`, `goles_visita`, `etiqueta` ("2020/21") y
`ventaja_local_pp`. La función usa `temporada`, `pct_local`, `pct_visita`, `pct_empate` y `etiqueta`.

**El código** (líneas 118–151), en cuatro bloques. Primero, **las bandas de los periodos del modelo**:

```python
def resultados_por_temporada(t: pd.DataFrame) -> go.Figure:
    fig = go.Figure()
    # Bandas de los periodos de modelación: conectan el contexto con el modelo.
    # Las bandas de una sola temporada son angostas: su etiqueta va en vertical.
    for x0, x1, texto, angulo in [(2018.5, 2023.5, "Entrenamiento", 0), (2023.5, 2024.5, "Validación", -90),
                                  (2024.5, 2025.5, "Prueba", -90)]:
        fig.add_vrect(x0=x0, x1=x1, fillcolor=BANDA if texto != "Validación" else "#ebeae4",
                      line_width=0, layer="below")
        fig.add_annotation(x=(x0 + x1) / 2, y=0.66 if angulo == 0 else 0.62, text=texto, showarrow=False,
                           yref="y", textangle=angulo, font=dict(size=11, color=TENUE))
```

- El eje x es el **año en que empieza** la temporada: la temporada 2019/20 ocupa de 2018.5 a 2019.5. Por eso los bordes de las
  bandas terminan en `.5`: **entrenamiento** de 2018.5 a 2023.5 = temporadas 2019/20 a 2023/24 (5 temporadas); **validación**
  de 2023.5 a 2024.5 = 2024/25; **prueba** de 2024.5 a 2025.5 = 2025/26.
- `add_vrect` dibuja un rectángulo vertical de todo el alto; `layer="below"` lo pone **debajo** de las líneas; `line_width=0`
  quita el borde. La banda de validación es un poco más oscura (`#ebeae4`, el único hex escrito a mano) para que las tres
  bandas se distingan.
- Cada banda lleva su nombre al centro y arriba (`y` = 0.66 o 0.62). Las de una sola temporada son angostas, así que su
  texto va **girado** (`textangle=-90`).
- **Límite:** la prueba real son 419 partidos: toda 2025/26 más 39 partidos de 2026/27 (hasta el 14-sep-2026). La gráfica sólo
  muestra temporadas completas, así que la banda "Prueba" cubre únicamente 2025/26.

Segundo, **las tres series y sus rótulos directos**:

```python
    series = [("pct_local", "Local", LOCAL, 2.5), ("pct_visita", "Visitante", VISITA, 2.5),
              ("pct_empate", "Empate", CONTEXTO, 1.5)]
    for col, nombre, color, grosor in series:
        fig.add_scatter(
            x=t["temporada"], y=t[col], mode="lines+markers", name=nombre,
            line=dict(color=color, width=grosor), marker=dict(size=6, color=color, line=dict(color="white", width=1.5)),
            customdata=t["etiqueta"], hovertemplate="%{customdata}<br>" + nombre + ": %{y:.1%}<extra></extra>",
        )
        ultimo = t.iloc[-1]
        fig.add_annotation(x=ultimo["temporada"], y=ultimo[col], text=f"<b>{nombre}</b> {_pct(ultimo[col])}",
                           xanchor="left", xshift=8, showarrow=False, font=dict(size=12, color=TINTA_2))
```

- `series` es una lista de tuplas `(columna, nombre, color, grosor)`. Local y visitante, 2.5 px; el **empate, 1.5 px y gris**:
  es la serie secundaria.
- `mode="lines+markers"`: línea con un punto por temporada (6 px, con **borde blanco** para separar los puntos que se
  traslapan).
- `customdata=t["etiqueta"]`: el tooltip dice "2020/21", no "2020". La plantilla es `"%{customdata}<br>Local: 37.9%"`
  (`%{y:.1%}` formatea la proporción como porcentaje).
- `ultimo = t.iloc[-1]` es la última fila (2025/26); la anotación `"<b>Local</b> 42.6%"` queda **a la derecha del último punto**
  (`xanchor="left"` y `xshift=8`: empieza 8 px a la derecha). Es la **etiqueta directa**: reemplaza a la leyenda.

Tercero, **la nota del COVID**:

```python
    covid = t[t["temporada"] == 2020].iloc[0]
    # La anotación va en la franja vacía inferior para no tapar ninguna línea.
    fig.add_annotation(x=2020, y=covid["pct_local"], ax=2014.2, ay=0.1, axref="x", ayref="y",
                       text="<b>2020/21, estadios vacíos (COVID-19)</b><br>única temporada en que los "
                            "visitantes<br>ganan más partidos que los locales",
                       showarrow=True, arrowhead=0, arrowwidth=1, arrowcolor=TENUE, align="left",
                       font=dict(size=12, color=TINTA_2), bgcolor="rgba(255,255,255,0.9)")
```

La flecha apunta al valor del local en 2020/21 (37.9 %). El texto está en `(ax, ay) = (2014.2, 0.10)`, en **coordenadas de
los datos** (`axref="x"`, `ayref="y"`): la franja de abajo, por debajo de todas las líneas (el mínimo de las tres series es
18.7 %, del empate), así que no tapa nada. La frase "única temporada en que los visitantes ganan más partidos que los
locales" está **escrita a mano**; hoy es cierta (en 2020/21 el local ganó 37.9 % y el visitante 40.3 %; es la única
temporada con ventaja local negativa, −2.4 puntos, según [13a.4.2](13a_codigo_datos_dashboard.md#13a42-resumen_temporadas)).

Cuarto, **el diseño**:

```python
    ticks = list(range(2001, 2026, 3))
    fig.update_layout(showlegend=False, hovermode="x unified", margin=dict(l=8, r=110, t=12, b=8))
    fig.update_xaxes(tickvals=ticks, ticktext=[f"{a}/{str(a + 1)[-2:]}" for a in ticks], showgrid=False,
                     range=[2000.5, 2025.8])
    fig.update_yaxes(range=[0, 0.68], tickformat=".0%", title_text="% de partidos de la temporada")
    return fig
```

- `ticks`: una marca cada tres temporadas (2001, 2004, …, 2025); `ticktext` las muestra como **"2001/02", "2004/05", …,
  "2025/26"** (`str(a + 1)[-2:]` toma las dos últimas cifras del año siguiente).
- `hovermode="x unified"`: **un solo tooltip** para la temporada bajo el puntero, con las tres series.
- Margen derecho de 110 px: ahí caben los rótulos de las series. Eje x de 2000.5 a 2025.8 (media temporada antes del primer
  punto y un poco después del último); sin rejilla vertical.
- Eje y de **0 a 68 %** con formato de porcentaje. Parte de cero: la serie del local se mueve entre 37.9 % y 50.8 %, y un
  eje recortado exageraría esas variaciones; además la franja de abajo es el sitio de la nota del COVID.

**Ejemplo con las cifras reales** ([13a.4.2](13a_codigo_datos_dashboard.md#13a42-resumen_temporadas)):

| Temporada | Local | Empate | Visitante | Ventaja local (pp) |
|---|---|---|---|---|
| 2001/02 | 43.4 % | 26.6 % | 30.0 % | +13.4 |
| 2009/10 | 50.8 % | 25.3 % | 23.9 % | **+26.8** (la mayor) |
| 2019/20 | 45.3 % | 24.2 % | 30.5 % | +14.7 |
| **2020/21** | **37.9 %** | 21.8 % | **40.3 %** | **−2.4** (la única negativa) |
| 2025/26 (los rótulos del margen) | 42.6 % | 27.4 % | 30.0 % | +12.6 |

Rangos de cada serie en las 25 temporadas (**cálculo propio**): local de 37.9 % a 50.8 %, visitante de 23.7 % a 40.3 %,
empate de 18.7 % a 29.2 %. La figura tiene 3 trazas, 3 bandas y 7 anotaciones.

**En R (ilustrativo, no ejecutado):**

```r
resultados_por_temporada <- function(t) {
  banda <- function(x0, x1, relleno) list(type = "rect", xref = "x", yref = "paper", x0 = x0, x1 = x1,
                                           y0 = 0, y1 = 1, fillcolor = relleno, line = list(width = 0), layer = "below")
  series <- list(list("pct_local", "Local", LOCAL, 2.5), list("pct_visita", "Visitante", VISITA, 2.5),
                 list("pct_empate", "Empate", CONTEXTO, 1.5))
  ultimo <- t[nrow(t), ]
  fig <- plot_ly(); rotulos <- list()
  for (s in series) {
    fig <- fig |> add_trace(
      x = t$temporada, y = t[[s[[1]]]], type = "scatter", mode = "lines+markers",
      line = list(color = s[[3]], width = s[[4]]),
      marker = list(size = 6, color = s[[3]], line = list(color = "white", width = 1.5)),
      customdata = t$etiqueta, hovertemplate = paste0("%{customdata}<br>", s[[2]], ": %{y:.1%}<extra></extra>"))
    rotulos <- c(rotulos, list(list(x = ultimo$temporada, y = ultimo[[s[[1]]]], showarrow = FALSE,
      text = paste0("<b>", s[[2]], "</b> ", scales::percent(ultimo[[s[[1]]]], accuracy = 0.1)),
      xanchor = "left", xshift = 8, font = list(size = 12, color = TINTA_2))))
  }
  ticks <- seq(2001, 2025, by = 3)
  fig |> layout(
    shapes = list(banda(2018.5, 2023.5, BANDA), banda(2023.5, 2024.5, "#ebeae4"), banda(2024.5, 2025.5, BANDA)),
    annotations = rotulos,               # + rótulos de las bandas y la nota del COVID, con el mismo formato
    hovermode = "x unified", margin = list(r = 110),
    xaxis = list(tickvals = ticks, ticktext = sprintf("%d/%02d", ticks, (ticks + 1) %% 100),
                 showgrid = FALSE, range = c(2000.5, 2025.8)),
    yaxis = list(range = c(0, 0.68), tickformat = ".0%", title = "% de partidos de la temporada"))
}
# ggplot2: pivot_longer(starts_with("pct_")) + annotate("rect", xmin = 2018.5, xmax = 2023.5, ymin = -Inf, ymax = Inf,
#   fill = BANDA) + geom_line() + geom_point() + scale_color_manual(values = c(...)) + scale_y_continuous(limits = c(0, .68),
#   labels = scales::percent) y luego ggplotly(). Las bandas con `annotate("rect")` quedan DEBAJO si se escriben antes.
```

> **Decisión:** líneas con marcadores, una por resultado, sobre un eje que parte de 0 %; el empate, más delgado y en gris. ·
> **Alternativas:** (a) barras apiladas al 100 % por temporada — a favor: muestran la composición (suman 100 %); en contra:
> sólo el segmento que parte de la base se compara bien entre temporadas y la pregunta es local contra visitante; (b) una
> sola línea con la ventaja local (local − visitante, en puntos) — a favor: la serie más directa, con un cero natural; en
> contra: pierde el empate y los niveles (en 2020/21 la ventaja es −2.4 puntos, pero no se ve que el local ganó 37.9 % y el
> visitante 40.3 %); (c) el eje recortado (p. ej. de 15 % a 55 %) — a favor: más detalle de las variaciones; en contra:
> exagera esas variaciones y deja sin sitio la nota; (d) tres paneles pequeños — a favor: sin cruces entre líneas; en
> contra: se pierde la comparación directa. Ninguna se probó. · **Por qué ésta:** las líneas son la forma natural de ver una
> serie en el tiempo; el cero honesto evita exagerar movimientos de unos cuantos puntos y deja una franja libre para
> anotar. · **Si preguntan:** "Son tres líneas porque queremos ver cómo se reparte cada temporada entre local, empate y
> visitante; el local casi siempre está arriba del visitante, salvo en 2020/21, cuando los estadios estaban vacíos."

> **Decisión:** etiquetar cada línea con su nombre y su último valor, a la derecha ("Local 42.6%"), en vez de usar leyenda, y
> poner la nota del COVID en la franja vacía de abajo, con una flecha. · **Alternativas:** (a) la leyenda de Plotly — a
> favor: automática; en contra: obliga a ir y volver con la vista y se enciman en pestañas ocultas (ver
> [`mostrar`](#13b21-mostrar)); (b) un rótulo en cada punto — a favor: todo a la vista; en contra: 75 rótulos, puro ruido;
> (c) sólo el tooltip — a favor: gráfica limpia; en contra: nada se lee sin pasar el puntero o tocar; (d) la nota encima
> del punto — a favor: más cerca de lo que explica; en contra: tapa líneas. Ninguna se probó. · **Por qué ésta:**
> "etiquetas directas selectivas" (docstring): una por serie, en el único sitio donde hace falta, y el texto largo donde no
> tapa datos. · **Si preguntan:** "Rotulamos las líneas directamente al final y pusimos la nota del COVID abajo, donde no
> tapa ninguna línea."

> **Decisión:** bandas de fondo para los periodos de entrenamiento, validación y prueba. · **Alternativas:** (a) no
> mostrarlas — a favor: gráfica más limpia; en contra: el contexto quedaría desconectado del modelo (el lector no vería con
> qué parte de la historia se entrenó); (b) líneas verticales en los cortes — a favor: menos tinta; en contra: no muestran el
> ancho de cada periodo; (c) explicarlo sólo en el subtítulo — a favor: ninguna marca en la gráfica; en contra: hay que
> imaginar dónde cae. Ninguna se probó. · **Por qué ésta:** "conectan el contexto con el modelo" (comentario del código):
> la pregunta "¿y esto qué tiene que ver con el modelo?" se contesta sin salir de la gráfica. Ojo con el límite: la banda
> de prueba sólo cubre 2025/26 y la prueba real incluye 39 partidos de 2026/27 que la gráfica no dibuja. · **Si
> preguntan:** "Las bandas grises muestran con qué temporadas se entrenó, se validó y se probó el modelo."

#### 13b.2.6 `resultado_favorito`

**Qué pregunta responde:** ¿qué tan seguro es el favorito de las cuotas?, ¿con qué frecuencia gana? Tarjeta *"Ni el favorito
es garantía"* (página *¿Qué ocurre?*, 36 % del ancho; subtítulo *"Resultado según el favorito de Bet365."*).

**Recibe:** `fav` = `d["favorito"]` = `resultado_del_favorito()` ([13a.4.3](13a_codigo_datos_dashboard.md#13a43-resultado_del_favorito)),
un **diccionario**, no una tabla: `partidos` (9,160), `gana_favorito` (54.2 %), `empate` (24.7 %), `gana_no_favorito`
(21.0 %), `local_es_favorito` (69.6 %) y `temporada_min` ("2002/03"). La función usa los cuatro primeros. El "favorito" es el
equipo con la cuota de Bet365 más baja.

**El código** (líneas 154–166):

```python
def resultado_favorito(f: dict) -> go.Figure:
    etiquetas = ["Gana el favorito", "Empate", "Gana el no favorito"]
    valores = [f["gana_favorito"], f["empate"], f["gana_no_favorito"]]
    fig = go.Figure(go.Bar(
        y=etiquetas, x=valores, orientation="h", marker=dict(color=CONTEXTO, cornerradius=4),
        text=[_pct(v) for v in valores], textposition="outside", cliponaxis=False, constraintext="none",
        textfont=dict(color=TINTA_2, size=13), width=0.55,
        hovertemplate="%{y}: %{x:.1%}<extra></extra>",
    ))
    fig.update_layout(margin=dict(l=8, r=48, t=8, b=8))
    fig.update_xaxes(range=[0, 0.7], tickformat=".0%", title_text=f"% de {f['partidos']:,} partidos con cuotas de Bet365")
    fig.update_yaxes(autorange="reversed", showgrid=False, tickfont=dict(color=TINTA, size=13))
    return fig
```

- Una sola traza de barras horizontales, **todas en `CONTEXTO` (gris)**. `go.Figure(go.Bar(...))` crea la figura con la traza
  ya adentro (equivale a `go.Figure()` + `add_bar`).
- El rótulo de cada barra es `_pct(v)`: "54.2%", "24.7%", "21.0%", al final de la barra (mismas opciones `outside`,
  `cliponaxis`, `constraintext` que en [`mejora_sobre_ingenua`](#13b24-mejora_sobre_ingenua)).
- `width=0.55`: grosor de la barra (fracción del espacio de su categoría).
- Eje x **fijo de 0 a 70 %** (el máximo real es 54.2 %): deja sitio al rótulo y mantiene la escala si cambian los datos. El
  título lo arma con el dato: `f"% de {f['partidos']:,} partidos con cuotas de Bet365"` → **"% de 9,160 partidos con cuotas
  de Bet365"** (`:,` escribe el separador de millares).
- Eje y invertido para leer de arriba abajo: favorito, empate, no favorito.

**Ejemplo:** barras de 54.2 %, 24.7 % y 21.0 %. Casi la mitad de las veces (≈ 46 %) el favorito **no** gana. Es el dato
que sostiene el texto "un buen modelo debe aspirar a acertar cerca de 50 %" y la decisión de evaluar probabilidades y no
sólo aciertos.

**En R (ilustrativo, no ejecutado):**

```r
resultado_favorito <- function(f) {
  etiquetas <- c("Gana el favorito", "Empate", "Gana el no favorito")
  valores   <- c(f$gana_favorito, f$empate, f$gana_no_favorito)
  plot_ly() |>
    add_bars(x = valores, y = factor(etiquetas, levels = etiquetas), orientation = "h", width = 0.55,
             marker = list(color = CONTEXTO), text = scales::percent(valores, accuracy = 0.1),
             textposition = "outside", cliponaxis = FALSE, hovertemplate = "%{y}: %{x:.1%}<extra></extra>") |>
    layout(margin = list(r = 48),
           xaxis = list(range = c(0, 0.7), tickformat = ".0%",
                        title = sprintf("%% de %s partidos con cuotas de Bet365", format(f$partidos, big.mark = ","))),
           yaxis = list(autorange = "reversed", showgrid = FALSE))
}
# ggplot2: ggplot(tibble(etiquetas, valores), aes(valores, fct_rev(fct_inorder(etiquetas)))) + geom_col(width = .55, fill = CONTEXTO) + ...
```

> **Decisión:** tres barras horizontales simples, las tres en gris, con el porcentaje al final de cada una y el eje fijo de
> 0 a 70 %. · **Alternativas:** (a) pastel o dona — a favor: sugiere "partes de un todo"; en contra: comparar ángulos y
> áreas es difícil y el módulo pide no usar pasteles; (b) una sola barra apilada al 100 % — a favor: compacta; en contra:
> los segmentos no parten de una base común, así que cuesta comparar el no favorito (21.0 %) con el empate (24.7 %); (c)
> resaltar la barra del favorito con color — a favor: guía la mirada; en contra: los colores con significado ya están
> asignados (azul = modelo, naranja = mercado…) y aquí no hay protagonistas que distinguir; (d) sólo la *value box* de la
> página (54 %) — a favor: ya está ahí; en contra: no muestra que el no favorito gana el 21 % de las veces. Ninguna se
> probó. · **Por qué ésta:** tres categorías excluyentes se comparan mejor por **longitud desde cero**; el gris dice "esto es
> contexto, no una comparación entre protagonistas". · **Si preguntan:** "El favorito de las cuotas sólo gana 54 % de las
> veces: el empate sale 25 % y el no favorito 21 %. Por eso evaluamos el modelo con probabilidades y no sólo con aciertos."

### Patrones

#### 13b.2.7 `resultado_por_diferencia_elo`

**Qué pregunta responde:** ¿cuánto pesa la diferencia de fuerza (Elo) previa en el resultado?, ¿y cuánto "vale" jugar en casa?
Es la gráfica que justifica que el Elo sea la variable principal del modelo. Tarjeta *"A más ventaja de Elo, más victorias
locales"* (página *Patrones*, 58 % del ancho; subtítulo "…en deciles (2019/20 a 2026/27, 2,696 partidos)").

**Recibe:** dos cosas.

- `t` = `d["elo"]` = `resultado_por_elo()` ([13a.4.4](13a_codigo_datos_dashboard.md#13a44-resultado_por_elo)): **10 filas**, una por
  decil de la diferencia de Elo previa (local − visitante), con `grupo`, `partidos` (≈ 270), `elo_min`, `elo_max`,
  `elo_mediana`, `pct_local`, `pct_empate`, `pct_visita`.
- `ventaja` = `d["ventaja_elo"]` = `ventaja_local_en_elo()` ([13a.4.5](13a_codigo_datos_dashboard.md#13a45-ventaja_local_en_elo)):
  un número, **50.03** puntos Elo (cuánto más débil puede ser el local para que local y visitante tengan la misma
  probabilidad de ganar).

**El código** (líneas 170–204), en tres bloques. Primero, **la referencia en cero**:

```python
def resultado_por_diferencia_elo(t: pd.DataFrame, ventaja: float) -> go.Figure:
    fig = go.Figure()
    fig.add_vline(x=0, line=dict(color=BASE, width=1))
    fig.add_annotation(x=0, y=0.01, text="Elo igual", showarrow=False, font=dict(size=11, color=TENUE), yref="y",
                       xanchor="left", yanchor="bottom", xshift=4)
```

Una línea vertical fina en diferencia = 0 ("Elo igual": los dos equipos tienen la misma fuerza) y su rótulo al pie, un poco a la
derecha de la línea.

Segundo, **las tres series con sus rótulos**:

```python
    for col, nombre, color, grosor in [("pct_local", "Local", LOCAL, 2.5),
                                       ("pct_visita", "Visitante", VISITA, 2.5),
                                       ("pct_empate", "Empate", CONTEXTO, 1.5)]:
        fig.add_scatter(
            x=t["elo_mediana"], y=t[col], mode="lines+markers", name=nombre,
            line=dict(color=color, width=grosor, shape="spline", smoothing=0.4),
            marker=dict(size=8, color=color, line=dict(color="white", width=2)),
            customdata=np.column_stack([t["elo_min"], t["elo_max"], t["partidos"]]),
            hovertemplate=("Gana " + nombre.lower() + ": %{y:.1%}" if nombre != "Empate" else "Empate: %{y:.1%}")
                          + "<br>Diferencia Elo entre %{customdata[0]:.0f} y %{customdata[1]:.0f}"
                            "<br>%{customdata[2]} partidos<extra></extra>",
        )
        ultimo = t.iloc[-1]
        fig.add_annotation(x=ultimo["elo_mediana"], y=ultimo[col], text=f"<b>{nombre}</b>", xanchor="left",
                           xshift=10, showarrow=False, font=dict(size=12, color=TINTA_2))
```

- **x** = la **mediana** de la diferencia de Elo de cada decil (de −252 a +251); **y** = el porcentaje de cada resultado en
  ese decil. Tres líneas con marcadores de 8 px (borde blanco de 2 px): local, visitante y empate (más delgado y gris).
- `shape="spline", smoothing=0.4`: la línea entre deciles es una **curva suavizada** (el 0.4 es un suavizado leve; el máximo
  es 1.3). Los marcadores marcan los deciles reales.
- `customdata`: el rango de Elo del decil y el número de partidos, que usa el tooltip. La plantilla del tooltip es una
  expresión condicional de Python: para "Local" dice "Gana local: 12.6%", para "Visitante" "Gana visitante: …" y para el
  empate "Empate: …"; después se agregan las dos líneas del rango y de los partidos.
- El rótulo directo (sólo el nombre) va a la derecha del último punto (`xshift=10`); no repite el porcentaje porque el eje y
  basta.

Tercero, **el punto donde se igualan y el diseño**:

```python
    y_cruce = float(np.interp(-ventaja, t["elo_mediana"], t["pct_local"]))
    fig.add_scatter(x=[-ventaja], y=[y_cruce], mode="markers", hoverinfo="skip", showlegend=False,
                    marker=dict(size=9, color="white", line=dict(color=TINTA_2, width=2)))
    # Texto en la esquina superior izquierda, la única zona sin líneas.
    fig.add_annotation(x=-ventaja, y=y_cruce, ax=float(t["elo_mediana"].min()) - 20, ay=0.84, axref="x",
                       ayref="y", align="left",
                       text=f"Local y visitante tienen la misma probabilidad<br>de ganar cuando el local es "
                            f"≈{round(ventaja, -1):.0f} puntos<br>más débil: eso <b>vale jugar en casa</b>",
                       showarrow=True, arrowhead=0, arrowwidth=1, arrowcolor=TENUE,
                       font=dict(size=12, color=TINTA_2), bgcolor="rgba(255,255,255,0.9)", xanchor="left")
    fig.update_layout(showlegend=False, margin=dict(l=8, r=90, t=12, b=8))
    x0, x1 = float(t["elo_mediana"].min()), float(t["elo_mediana"].max())
    fig.update_xaxes(range=[x0 - 30, x1 + 30], title_text="Diferencia de Elo previa (local − visitante), por decil")
    fig.update_yaxes(range=[0, 0.9], tickformat=".0%", title_text="% de partidos")
    return fig
```

- `np.interp(x, xp, fp)` es la **interpolación lineal**: el valor de `fp` (el % de victorias locales) en `x` = −`ventaja`,
  entre los dos deciles que lo rodean (los de mediana −56.5 y −20.3). Da **37.7 %** (**cálculo propio**: 0.3767). Es la altura
  del cruce: ahí local y visitante ganan lo mismo.
- Un **círculo hueco** (relleno blanco, borde oscuro) marca ese punto: `(−50.03, 37.7 %)`. `hoverinfo="skip"`: sin tooltip.
- La anotación explicativa sale de la **esquina superior izquierda** (`ax = −252 − 20`, `ay = 0.84`), "la única zona sin
  líneas" (a la izquierda las líneas más altas son el visitante, 66.7 %), y apunta al círculo. La cifra del texto se calcula:
  `round(ventaja, -1)` redondea a la decena (50.03 → 50.0) y `:.0f` la escribe sin decimales: "**≈50 puntos** más débil".
- El eje x se amplía 30 puntos a cada lado ([−282, 281]); el eje y va de 0 a 90 %; el margen derecho de 90 px aloja los
  rótulos.

**Ejemplo con las cifras reales** ([13a.4.4](13a_codigo_datos_dashboard.md#13a44-resultado_por_elo)):

| Decil | Diferencia de Elo | Mediana (eje x) | Partidos | Gana local | Empate | Gana visitante |
|---|---|---|---|---|---|---|
| 1 | −428 a −191 | −252 | 270 | **12.6 %** | 20.7 % | 66.7 % |
| 2 | −191 a −122 | −157 | 270 | 26.3 % | 24.8 % | 48.9 % |
| 3 | −122 a −76 | −99 | 269 | 28.3 % | 26.8 % | 45.0 % |
| 4 | −76 a −37 | −56 | 270 | 35.9 % | 24.4 % | 39.6 % |
| 5 | −37 a −3 | −20 | 269 | 45.7 % | 25.7 % | 28.6 % |
| 6 | −3 a +33 | +16 | 270 | 36.7 % | 31.1 % | 32.2 % |
| 7 | +33 a +77 | +53 | 269 | 52.8 % | 22.7 % | 24.5 % |
| 8 | +77 a +124 | +99 | 270 | 54.1 % | 27.0 % | 18.9 % |
| 9 | +124 a +189 | +154 | 269 | 63.2 % | 21.6 % | 15.2 % |
| 10 | +189 a +438 | +251 | 270 | **76.3 %** | 13.7 % | 10.0 % |

El cruce está entre los deciles 4 y 5: a **−50.03** puntos, con **37.7 %** para cada lado. La figura tiene 4 trazas (3 series +
el círculo), 1 línea y 5 anotaciones. **Nota:** la cifra "≈ 50" es aproximada (interpolación entre dos deciles ruidosos) y
depende de la escala del Elo, que depende de K ([capítulo 4](04_elo.md)): con el K anterior (30) salía ≈ 60.

**En R (ilustrativo, no ejecutado):**

```r
resultado_por_diferencia_elo <- function(t, ventaja) {
  series <- list(list("pct_local", "Local", LOCAL, 2.5), list("pct_visita", "Visitante", VISITA, 2.5),
                 list("pct_empate", "Empate", CONTEXTO, 1.5))
  ultimo <- t[nrow(t), ]; fig <- plot_ly(); rotulos <- list()
  for (s in series) {
    fig <- fig |> add_trace(
      x = t$elo_mediana, y = t[[s[[1]]]], type = "scatter", mode = "lines+markers",
      line = list(color = s[[3]], width = s[[4]], shape = "spline", smoothing = 0.4),
      marker = list(size = 8, color = s[[3]], line = list(color = "white", width = 2)),
      customdata = cbind(t$elo_min, t$elo_max, t$partidos),
      hovertemplate = paste0(if (s[[2]] == "Empate") "Empate" else paste("Gana", tolower(s[[2]])), ": %{y:.1%}",
        "<br>Diferencia Elo entre %{customdata[0]:.0f} y %{customdata[1]:.0f}<br>%{customdata[2]} partidos<extra></extra>"))
    rotulos <- c(rotulos, list(list(x = ultimo$elo_mediana, y = ultimo[[s[[1]]]], text = paste0("<b>", s[[2]], "</b>"),
                                    xanchor = "left", xshift = 10, showarrow = FALSE)))
  }
  y_cruce <- approx(t$elo_mediana, t$pct_local, xout = -ventaja)$y         # ≈ np.interp (los x están ordenados)
  fig |>
    add_markers(x = -ventaja, y = y_cruce, hoverinfo = "skip",
                marker = list(size = 9, color = "white", line = list(color = TINTA_2, width = 2))) |>
    layout(shapes = list(list(type = "line", x0 = 0, x1 = 0, y0 = 0, y1 = 1, yref = "paper",
                              line = list(color = BASE, width = 1))),
           annotations = c(rotulos, list(list(x = -ventaja, y = y_cruce, ax = min(t$elo_mediana) - 20, ay = 0.84,
             axref = "x", ayref = "y", showarrow = TRUE, arrowhead = 0, xanchor = "left", align = "left",
             bgcolor = "rgba(255,255,255,0.9)",
             text = sprintf("Local y visitante tienen la misma probabilidad<br>de ganar cuando el local es ≈%.0f puntos<br>más débil: eso <b>vale jugar en casa</b>", round(ventaja, -1))))),
           margin = list(r = 90),
           xaxis = list(range = c(min(t$elo_mediana) - 30, max(t$elo_mediana) + 30),
                        title = "Diferencia de Elo previa (local − visitante), por decil"),
           yaxis = list(range = c(0, 0.9), tickformat = ".0%", title = "% de partidos"))
}
```

> **Decisión:** agrupar los 2,696 partidos en **deciles** de la diferencia de Elo previa y dibujar el % de cada resultado por
> decil, con líneas suavizadas (`spline`) y un marcador por decil. · **Alternativas:** (a) un punto por partido (resultado
> contra Elo) — a favor: no pierde datos; en contra: el resultado sólo toma tres valores y no hay forma que se lea; (b) una
> curva de regresión (logística multinomial u ordinal) — a favor: curva suave que usa los partidos sin agrupar; en contra:
> hay que explicar otro modelo dentro de una gráfica de contexto; (c) cortes de ancho fijo (p. ej. cada 50 puntos) — a favor:
> el eje x conserva distancias reales; en contra: los extremos quedan con pocos partidos; (d) quintiles — a favor: menos ruido
> por punto; en contra: menos puntos para ver la forma; (e) líneas rectas en vez de `spline` — a favor: no sugieren valores
> entre deciles; en contra: se ven quebradas (el suavizado es leve y los marcadores muestran los deciles reales). Ninguna se
> probó. · **Por qué ésta:** cada decil tiene ≈ 270 partidos, así que todos los puntos tienen un error estándar parecido
> (≈ 3 puntos); la forma se lee de un vistazo y la tabla de deciles es su "vista de tabla". · **Si preguntan:** "Ordenamos
> los partidos por la diferencia de Elo, los partimos en diez grupos del mismo tamaño y vemos qué pasa en cada uno: con el
> local mucho más débil gana 13 % de las veces; con el local mucho más fuerte, 76 %."

> **Decisión:** marcar con un círculo hueco el punto donde local y visitante se igualan y explicarlo con una anotación
> ("≈ 50 puntos más débil: eso vale jugar en casa") cuya cifra **se calcula** con los datos. · **Alternativas:** (a) dejar la
> lectura al lector — a favor: gráfica más limpia; en contra: la conclusión (lo que vale la localía, en puntos Elo) no
> aparecería en ninguna parte; (b) ponerla sólo en el texto de la tarjeta "Por qué importan estos patrones" — a favor: no
> recarga la gráfica; en contra: separa la cifra de lo que la explica; (c) otra gráfica sólo para la localía — a favor: más
> espacio; en contra: una tarjeta entera para una cifra. Ninguna se probó. · **Por qué ésta:** la cifra sale de
> `datos_dashboard.py` y la anotación la usa tal cual (si cambia el modelo, cambia el texto sin tocarlo); el texto va en la
> esquina "sin líneas", con una flecha al punto. · **Si preguntan:** "Cuando el local es unos 50 puntos de Elo más débil,
> local y visitante tienen la misma probabilidad de ganar: eso es, en puntos de Elo, lo que vale jugar en casa; es una
> estimación aproximada, a partir de los deciles."

#### 13b.2.8 `calibracion_mercado`

**Qué pregunta responde:** ¿las probabilidades que implican las cuotas coinciden con lo que de verdad pasa? Si el mercado
está bien calibrado, "ganarle" exige saber algo que el mercado no sepa. Tarjeta *"Las cuotas están bien calibradas"*
(página *Patrones*, 42 % del ancho; subtítulo "Cuando las cuotas de Bet365 dicen 70 %, ocurre ≈70 % de las veces.").

**Recibe:** `t` = `d["calibracion_mercado"]` = `calibracion_historica_mercado()`
([13a.4.6](13a_codigo_datos_dashboard.md#13a46-calibracion_historica_mercado-y-_tabla_calibracion)): **18 filas** con `n` (casos),
`prob_predicha` (la probabilidad implícita **media** del intervalo) y `frecuencia` (la frecuencia **observada**). Cada partido
aporta tres pares (probabilidad de local, de empate y de visitante): 9,160 partidos de Bet365 (2002/03–2026/27) × 3 = 27,480
pares, agrupados en intervalos de 5 puntos; los 18 grupos con al menos 50 casos que se dibujan suman 27,478.

**El código** (líneas 207–231), en dos bloques:

```python
def calibracion_mercado(t: pd.DataFrame) -> go.Figure:
    fig = go.Figure()
    fig.add_scatter(x=[0, 1], y=[0, 1], mode="lines", line=dict(color=BASE, width=1), hoverinfo="skip",
                    name="Calibración perfecta")
    fig.add_scatter(
        x=t["prob_predicha"], y=t["frecuencia"], mode="markers", name="Bet365",
        marker=dict(size=10, color=MERCADO, line=dict(color="white", width=2)),
        customdata=t["n"],
        hovertemplate="Las cuotas decían %{x:.1%}<br>Ocurrió %{y:.1%}<br>%{customdata:,} casos<extra></extra>",
    )
    fig.add_annotation(x=0.97, y=0.06, text="diagonal = calibración perfecta", showarrow=False,
                       xanchor="right", font=dict(size=11, color=TENUE))
    alto = t.iloc[-1]
    fig.add_annotation(x=alto["prob_predicha"], y=alto["frecuencia"], ax=0.08, ay=0.82, axref="x", ayref="y",
                       text="Los grandes favoritos ganan<br>un poco más de lo que<br>dicen las cuotas",
                       xanchor="left", align="left", showarrow=True, arrowhead=0, arrowwidth=1,
                       arrowcolor=TENUE, font=dict(size=12, color=TINTA_2), bgcolor="rgba(255,255,255,0.9)")
```

```python
    fig.update_layout(showlegend=False, margin=dict(l=8, r=16, t=12, b=8))
    # Ejes cuadrados para que la diagonal quede a 45°; `constrain="domain"` encoge el área de
    # dibujo en lugar de extender los rangos (evita ejes de −20 % a 120 %).
    fig.update_xaxes(range=[0, 1], tickformat=".0%", title_text="Probabilidad implícita en la cuota",
                     constrain="domain")
    fig.update_yaxes(range=[0, 1], tickformat=".0%", title_text="Frecuencia observada", scaleanchor="x",
                     scaleratio=1, constrain="domain")
    return fig
```

**Cómo se lee un diagrama de calibración** (también llamado de confiabilidad): el eje x es **lo que decían las cuotas**; el eje
y, **lo que ocurrió**. La **diagonal** (traza gris fina, sin tooltip) es la calibración perfecta: si de todas las veces que
las cuotas dicen 30 % ocurre 30 %, el punto cae sobre ella. Un punto **sobre** la diagonal significa que ocurrió **más** de lo
que decían las cuotas; **bajo** ella, menos.

- Los puntos son naranja (`MERCADO`), de 10 px con borde blanco de 2 px, **sin línea que los una** (cada intervalo es una
  medición independiente). El tooltip dice, p. ej.: "Las cuotas decían 86.8% / Ocurrió 92.5% / 67 casos" (`:,` pone la coma de
  millares).
- Dos anotaciones: un rótulo discreto que dice qué es la diagonal (abajo a la derecha) y una explicación con flecha
  que sale de la esquina superior izquierda (`ax=0.08`, `ay=0.82`, en coordenadas de los datos) hacia el **último punto**
  (`t.iloc[-1]`, el intervalo más alto).
- **Ejes cuadrados.** `scaleanchor="x", scaleratio=1` en el eje y obliga a que una unidad de x mida lo mismo, en píxeles, que
  una de y: el área de dibujo se vuelve cuadrada y la diagonal queda a **45°**. Pero si la tarjeta no es cuadrada, Plotly
  tiene que ceder en algo: con `constrain="range"` (lo normal) **extendería** los rangos (ejes de −20 % a 120 %); con
  `constrain="domain"` **encoge el área de dibujo** y respeta [0, 1]. Se eligió lo segundo.

**Ejemplo con las cifras reales** ([13a.4.6](13a_codigo_datos_dashboard.md#13a46-calibracion_historica_mercado-y-_tabla_calibracion)):

| Probabilidad media (cuotas) | Frecuencia observada | Casos |
|---|---|---|
| 4.3 % | 3.4 % | 119 |
| 12.7 % | 11.7 % | 1,637 |
| 27.7 % | 28.0 % | 7,462 |
| 47.4 % | 46.9 % | 1,453 |
| 62.0 % | 65.7 % | 719 |
| 82.1 % | 87.7 % | 219 |
| 86.8 % | 92.5 % | 67 |

En el centro la calibración es casi perfecta; en los extremos aparece el sesgo favorito–no favorito. El punto anotado es el
último (86.8 % → 92.5 %, 67 casos). **Cálculo propio, aproximado** (errores estándar binomiales con los casos de la tabla):
un grupo de 67 casos con frecuencia ≈ 92 % tiene un error estándar de ≈ 3 puntos y su desviación (5.7 puntos) es de ≈ 1.8
errores estándar: **por sí solo no es concluyente**; lo que sostiene la frase es que son **tres grupos seguidos sobre la
diagonal** (62.0 → 65.7, 82.1 → 87.7 y 86.8 → 92.5).

**En R (ilustrativo, no ejecutado):**

```r
calibracion_mercado <- function(t) {
  alto <- t[nrow(t), ]
  plot_ly() |>
    add_lines(x = c(0, 1), y = c(0, 1), line = list(color = BASE, width = 1), hoverinfo = "skip") |>
    add_markers(x = t$prob_predicha, y = t$frecuencia, customdata = t$n,
                marker = list(size = 10, color = MERCADO, line = list(color = "white", width = 2)),
                hovertemplate = "Las cuotas decían %{x:.1%}<br>Ocurrió %{y:.1%}<br>%{customdata:,} casos<extra></extra>") |>
    layout(annotations = list(
             list(x = 0.97, y = 0.06, text = "diagonal = calibración perfecta", showarrow = FALSE, xanchor = "right"),
             list(x = alto$prob_predicha, y = alto$frecuencia, ax = 0.08, ay = 0.82, axref = "x", ayref = "y",
                  text = "Los grandes favoritos ganan<br>un poco más de lo que<br>dicen las cuotas",
                  xanchor = "left", align = "left", showarrow = TRUE, arrowhead = 0, bgcolor = "rgba(255,255,255,0.9)")),
           xaxis = list(range = c(0, 1), tickformat = ".0%", title = "Probabilidad implícita en la cuota", constrain = "domain"),
           yaxis = list(range = c(0, 1), tickformat = ".0%", title = "Frecuencia observada",
                        scaleanchor = "x", scaleratio = 1, constrain = "domain"))
}
# ggplot2: geom_abline(color = BASE) + geom_point(color = MERCADO, size = 3) + coord_equal(xlim = c(0, 1), ylim = c(0, 1))
#          (coord_equal() es el equivalente de scaleanchor/scaleratio)
```

> **Decisión:** un diagrama de calibración: un punto por intervalo de probabilidad (probabilidad implícita contra frecuencia
> observada), con la diagonal como referencia y los dos ejes cuadrados. · **Alternativas:** (a) barras de la diferencia
> (observada − implícita) por intervalo — a favor: muestran el error directamente; en contra: pierden la lectura "sobre o
> bajo la diagonal" y agrandan diferencias pequeñas; (b) sólo una tabla — a favor: exacta (existe como "Tabla: calibración de
> las cuotas"); en contra: el patrón no se ve; (c) un solo número (error de calibración esperado) — a favor: un resumen;
> en contra: esconde dónde falla (en los extremos); (d) puntos con intervalos de confianza — a favor: muestran el ruido de
> los grupos con pocos casos; en contra: más tinta (el mínimo de 50 casos ya filtra los grupos más ruidosos). Ninguna se
> probó. · **Por qué ésta:** es la forma estándar de ver calibración; con la diagonal a 45° la lectura es inmediata y el
> mismo diseño se reutiliza para comparar modelo y mercado en [`calibracion_modelos`](#13b213-calibracion_modelos). · **Si
> preguntan:** "Agrupamos las cuotas por la probabilidad que implican y comparamos con lo que ocurrió: casi todos los
> puntos caen sobre la diagonal; sólo los grandes favoritos ganan un poco más de lo que dicen las cuotas."

#### 13b.2.9 `ajuste_poisson`

**Qué pregunta responde:** ¿los goles por partido se parecen a una distribución de Poisson? Es el supuesto del modelo de goles
(la regresión de Poisson, [capítulo 6](06_poisson_y_regresion.md)). Tarjeta *"Los goles se comportan como un conteo de
Poisson"* (página *Patrones*, primera pestaña de la fila de abajo).

**Recibe:** `p` = `d["poisson"]` = `ajuste_poisson_goles()` ([13a.4.7](13a_codigo_datos_dashboard.md#13a47-ajuste_poisson_goles)):
**14 filas** (2 lados × 7 categorías de goles: 0, 1, 2, 3, 4, 5 y "6+") con `lado` ("Local"/"Visitante"), `goles`, `etiqueta`
(texto: "0", …, "5", "6+"), `observado` (la proporción real), `poisson` (la proporción que daría una Poisson con la misma
media), `media` y `varianza`. Se calcula con los 9,500 partidos de las temporadas completas.

**El código** (líneas 234–254), en dos bloques. Primero, **los dos paneles y sus títulos**:

```python
def ajuste_poisson(p: pd.DataFrame) -> go.Figure:
    lados = ["Local", "Visitante"]
    titulos = []
    for lado in lados:
        s = p[p["lado"] == lado].iloc[0]
        titulos.append(f"<b>Goles del {lado.lower()}</b> · media {s['media']:.2f}, varianza {s['varianza']:.2f}")
    fig = make_subplots(rows=1, cols=2, subplot_titles=titulos, horizontal_spacing=0.08, shared_yaxes=True)
```

- `make_subplots(rows=1, cols=2, …)`: **dos paneles lado a lado**. `shared_yaxes=True`: comparten el eje vertical (la misma escala,
  y el panel derecho no repite los números); `horizontal_spacing=0.08`: 8 % del ancho entre paneles.
- Los títulos se **calculan con los datos**: `p[p["lado"] == lado].iloc[0]` toma la primera fila del lado (la media y la
  varianza se repiten en todas sus filas) y las escribe con 2 decimales. Con los datos reales (**cálculo propio**; coincide con la
  página): **"Goles del local · media 1.53, varianza 1.70"** y **"Goles del visitante · media 1.19, varianza 1.34"** (sin
  redondear: 1.5349 / 1.6970 y 1.1891 / 1.3412).

Segundo, **las barras observadas, los rombos de Poisson y el diseño**:

```python
    for i, lado in enumerate(lados, start=1):
        s = p[p["lado"] == lado]
        fig.add_bar(x=s["etiqueta"], y=s["observado"], name="Observado", marker=dict(color=CONTEXTO, cornerradius=4),
                    showlegend=i == 1, hovertemplate="%{x} goles: %{y:.1%} observado<extra></extra>",
                    row=1, col=i, width=0.6)
        fig.add_scatter(x=s["etiqueta"], y=s["poisson"], name="Poisson con la misma media", mode="markers",
                        marker=dict(size=11, color=MODELO, symbol="diamond", line=dict(color="white", width=2)),
                        showlegend=i == 1, hovertemplate="%{x} goles: %{y:.1%} según Poisson<extra></extra>",
                        row=1, col=i)
    fig.update_layout(margin=dict(l=8, r=8, t=36, b=8), bargap=0.3)
    fig.update_annotations(font=dict(size=12, color=TINTA_2))
    fig.update_yaxes(tickformat=".0%", rangemode="tozero", gridcolor=REJILLA)
    fig.update_xaxes(showgrid=False, title_text="Goles en el partido")
    return fig
```

- `enumerate(lados, start=1)`: `i` vale 1 y 2; en Plotly los paneles se numeran desde 1 (`row=1, col=i`).
- **Barras grises** (`CONTEXTO`) = lo observado; **rombos azules** (`MODELO`, 11 px, borde blanco) = lo que daría una Poisson con
  la misma media. Azul porque la Poisson es **el supuesto del modelo** (interpretación razonada).
- `showlegend=i == 1`: sólo el primer panel declararía la leyenda (para no duplicarla); pero `mostrar` la apaga de todos modos y
  la clave va en el HTML de la tarjeta (`observado` / `Poisson con la misma media`).
- Los títulos de los paneles son **anotaciones** de Plotly, por eso se estilizan con `update_annotations`. Los ejes y van con
  `.0%` y desde cero; el eje x no tiene rejilla.
- Tooltip: "2 goles: 24.6% observado" y "2 goles: 25.4% según Poisson".

**Ejemplo con las cifras reales** ([13a.4.7](13a_codigo_datos_dashboard.md#13a47-ajuste_poisson_goles)):

| Goles | Local observado | Poisson (λ = 1.535) | Visitante observado | Poisson (λ = 1.189) |
|---|---|---|---|---|
| 0 | 23.3 % | 21.6 % | 32.8 % | 30.5 % |
| 1 | 31.8 % | 33.1 % | 34.2 % | 36.2 % |
| 2 | 24.6 % | 25.4 % | 20.0 % | 21.5 % |
| 3 | 12.6 % | 13.0 % | 8.8 % | 8.5 % |
| 4 | 5.2 % | 5.0 % | 3.0 % | 2.5 % |
| 5 | 1.8 % | 1.5 % | 0.9 % | 0.6 % |
| 6+ | 0.8 % | 0.5 % | 0.3 % | 0.1 % |

Los rombos quedan casi sobre la parte alta de las barras: la forma es muy parecida, con un poco **más de ceros y de goleadas**
que en una Poisson (por eso la varianza supera a la media). Lo que importa para la regresión es la dispersión **condicional**,
1.00 y 1.04 ([13a.5.11](13a_codigo_datos_dashboard.md#13a511-dispersion_pearson)).

> **Observado en el sitio publicado (3-oct-2026): la categoría "6+" no se dibuja.** Las barras llegan a **5** goles y el eje x
> muestra 0, 2 y 4. La causa más probable está en cómo Plotly decide el **tipo de eje**: `etiqueta` es **texto** ("0", "1", …,
> "5", "6+"), y al ver que casi todos los valores se pueden leer como números, trata el eje como **numérico** (`linear`);
> "6+" no se puede convertir y se descarta (lo que sí se comprobó en la página: `xaxis.type = "linear"` y los datos de la
> traza traen las siete etiquetas). El arreglo sería una línea (`fig.update_xaxes(type="category")`; en R,
> `layout(xaxis = list(type = "category"))`; no se probó) y **no se aplicó**: el código se entregó así. Efecto: se pierde
> la cola de goleadas (0.8 % de los partidos del local y 0.3 % del visitante); la conclusión no cambia y la categoría sí
> está en los datos. **Si preguntan** por qué no aparece "6+": "Es un
> defecto de dibujo conocido: la categoría existe en los datos (0.8 % y 0.3 %), pero el eje se interpretó como numérico y la
> barra no se muestra; no afecta a ninguna cifra del modelo."

**En R (ilustrativo, no ejecutado).** Aquí `ggplot2` + `ggplotly()` es lo más corto, y con un **factor** sí quedan las siete
categorías:

```r
ajuste_poisson <- function(p) {
  p <- p |> mutate(etiqueta = factor(etiqueta, levels = c(0:5, "6+")),
                   panel = sprintf("Goles del %s · media %.2f, varianza %.2f", tolower(lado), media, varianza))
  g <- ggplot(p, aes(etiqueta)) +
    geom_col(aes(y = observado), fill = CONTEXTO, width = 0.6) +
    geom_point(aes(y = poisson), shape = 18, size = 4, color = MODELO) +       # rombo
    facet_wrap(~panel) +                                                       # ≈ make_subplots(rows = 1, cols = 2)
    scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Goles en el partido", y = NULL) + theme_dashboard()
  ggplotly(g)
}
```

> **Decisión:** comparar las barras observadas (gris) con un punto por categoría de la Poisson de la misma media (rombos
> azules), en dos paneles (local y visitante) con el mismo eje vertical. · **Alternativas:** (a) dos barras por categoría
> (observado y teórico, una junto a otra) — a favor: ambas pesan lo mismo visualmente; en contra: 14 barras por panel y se
> pierde la jerarquía "dato frente a modelo"; (b) dos líneas superpuestas — a favor: menos tinta; en contra: unir valores
> discretos sugiere continuidad; (c) un rootograma colgante — a favor: es el diagnóstico clásico para conteos y resalta las
> desviaciones de las colas; en contra: poco conocido para la audiencia; (d) una prueba de bondad de ajuste (χ²) — a favor: un
> p-valor; en contra: con 9,500 partidos rechaza por desviaciones mínimas y no muestra cómo luce el ajuste; (e) un solo
> panel con los dos lados — a favor: más compacto; en contra: mezcla dos distribuciones de media distinta (1.53 y 1.19).
> Ninguna se probó. · **Por qué ésta:** barras desde cero para lo observado y un marcador para la referencia teórica es la
> lectura más directa de "¿se parecen?"; la media y la varianza en el título de cada panel dejan ver la sobredispersión leve
> (1.70 contra 1.53 y 1.34 contra 1.19). · **Si preguntan:** "Las barras grises son los goles reales y los rombos azules lo
> que daría una Poisson con la misma media: casi coinciden, con un poco más de ceros y de goleadas; por eso usamos una
> regresión de Poisson."

### El modelo

#### 13b.2.10 `delta_vs_m0`

**Qué pregunta responde:** cuando se evalúa con datos nuevos, ¿agregar variables (forma reciente, tiros) mejora al modelo base
M0?, y ¿cómo queda el mercado frente a M0 en los dos periodos? Tarjeta *"Agregar variables no generaliza"* (página *El modelo*,
52 % del ancho; subtítulo "Comparativa de LogLoss entre modelos." más una leyenda HTML con cuatro muestras: círculo hueco =
Validación, círculo oscuro = Prueba, naranja = Mercado, gris = Especificaciones del modelo).

**Recibe:** `d` = `d["delta_m0"]` = `delta_contra_m0()` ([13a.5.7](13a_codigo_datos_dashboard.md#13a57-delta_contra_m0)): **5 filas**
con `predictor`, `nombre`, `validacion` y `prueba`, donde cada valor es **el LogLoss del predictor menos el de M0** en ese
periodo (**negativo = mejor que M0**).

**El código** (líneas 258–283), en tres bloques. Primero, **la referencia**:

```python
def delta_vs_m0(d: pd.DataFrame) -> go.Figure:
    fig = go.Figure()
    fig.add_vline(x=0, line=dict(color=TINTA_2, width=1))
    fig.add_annotation(x=0, y=1.04, yref="paper", text="<b>M0 (base)</b>", showarrow=False,
                       font=dict(size=12, color=TINTA_2))
```

La línea vertical del cero **es M0**: todo lo demás se mide contra ella. Su rótulo va **arriba** del área de dibujo: `yref="paper"`
con `y=1.04` significa "4 % por encima del borde superior de la figura" (coordenadas de papel, no de los datos).

Segundo, **una mancuerna por predictor**:

```python
    for r in d.itertuples():
        color = MERCADO if r.predictor == "Mercado_apertura" else CONTEXTO
        fig.add_scatter(x=[r.validacion, r.prueba], y=[r.nombre, r.nombre], mode="lines",
                        line=dict(color=color, width=2), hoverinfo="skip", showlegend=False)
        fig.add_scatter(x=[r.validacion], y=[r.nombre], mode="markers", showlegend=False,
                        marker=dict(size=12, color="white", line=dict(color=color, width=2.5)),
                        hovertemplate=f"<b>{r.nombre}</b><br>Validación: %{{x:.4f}} vs M0<extra></extra>")
        fig.add_scatter(x=[r.prueba], y=[r.nombre], mode="markers", showlegend=False,
                        marker=dict(size=12, color=color, line=dict(color="white", width=2)),
                        hovertemplate=f"<b>{r.nombre}</b><br>Prueba: %{{x:.4f}} vs M0<extra></extra>")
```

- `d.itertuples()` recorre la tabla fila por fila como tuplas con nombre (`r.predictor`, `r.nombre`, `r.validacion`,
  `r.prueba`). En R: `for (i in seq_len(nrow(d)))`.
- `color`: **naranja** para el mercado y **gris** para las especificaciones M1–M4 (el color dice quién es).
- Cada predictor lleva **tres trazas**: (1) una **línea** de 2 px que une el valor de validación con el de prueba, sin tooltip;
  (2) un **punto hueco** (relleno blanco, borde del color de 2.5 px) en el valor de **validación**; (3) un **punto relleno**
  (borde blanco) en el valor de **prueba**. Son trazas separadas porque una línea de Plotly sólo admite un color y los
  puntos necesitan relleno y tooltip distintos. Son 5 × 3 = **15 trazas**.
- **Detalle de Python:** el tooltip es un *f-string* (`f"…"`) que inserta `{r.nombre}`; pero la plantilla de Plotly también
  usa llaves (`%{x:.4f}`), así que dentro del f-string se **duplican**: `%{{x:.4f}}` produce `%{x:.4f}`. En R no hay este
  problema si el texto se arma con `paste0()`.

Tercero, **la escala y las notas de dirección**:

```python
    # La codificación (hueco = validación, relleno = prueba) se explica en el subtítulo (HTML).
    valores = np.concatenate([d["validacion"], d["prueba"]])
    x0, x1 = float(valores.min()) - 0.003, float(valores.max()) + 0.003
    fig.add_annotation(x=x0, y=-0.16, yref="paper", xanchor="left", text="← mejor que M0", showarrow=False,
                       font=dict(size=11, color=TENUE))
    fig.add_annotation(x=x1, y=-0.16, yref="paper", xanchor="right", text="peor que M0 →", showarrow=False,
                       font=dict(size=11, color=TENUE))
    fig.update_layout(margin=dict(l=8, r=16, t=28, b=40))
    fig.update_xaxes(title_text="", tickformat=".3f", zeroline=False, range=[x0, x1])
    fig.update_yaxes(autorange="reversed", showgrid=False, tickfont=dict(color=TINTA, size=13))
    return fig
```

- `np.concatenate` junta las dos columnas para hallar el mínimo (−0.018995) y el máximo (+0.004255) globales; el rango
  del eje x es ese mínimo y ese máximo **±0.003**: de −0.0220 a +0.0073 (**cálculo propio**).
- Dos rótulos **bajo el eje** (`y=-0.16` en coordenadas de papel) dicen el sentido de lectura: "← mejor que M0" a la izquierda
  y "peor que M0 →" a la derecha. El eje no lleva título (`title_text=""`): los rótulos lo sustituyen. Los márgenes `t=28` y
  `b=40` les dejan sitio.
- Eje y invertido (la primera fila arriba), sin rejilla; tres decimales en el eje x.

**Ejemplo con las cifras reales** ([13a.5.7](13a_codigo_datos_dashboard.md#13a57-delta_contra_m0)):

| Predictor | Δ validación (hueco) | Δ prueba (relleno) |
|---|---|---|
| M1 · + Forma | −0.001944 | +0.001624 |
| M2 · + Tiros | −0.008829 | +0.004255 |
| M3 · + Tiros a puerta | −0.007228 | +0.000792 |
| M4 · Completo | −0.010935 | +0.003664 |
| Mercado · Apertura | −0.018995 | −0.013076 |

En validación los cuatro modelos ampliados quedan a la **izquierda** de M0 (mejores); en prueba, a la **derecha** (peores). El
mercado queda a la izquierda en los dos periodos. En el sitio, la mancuerna de cada modelo ampliado **cruza** la línea del cero
y la del mercado no. La figura tiene 15 trazas, 1 línea y 3 anotaciones.

**En R (ilustrativo, no ejecutado):**

```r
delta_vs_m0 <- function(d) {
  fig <- plot_ly()
  for (i in seq_len(nrow(d))) {
    r <- d[i, ]; color <- if (r$predictor == "Mercado_apertura") MERCADO else CONTEXTO
    fig <- fig |>
      add_trace(x = c(r$validacion, r$prueba), y = c(r$nombre, r$nombre), type = "scatter", mode = "lines",
                line = list(color = color, width = 2), hoverinfo = "skip", showlegend = FALSE) |>
      add_trace(x = r$validacion, y = r$nombre, type = "scatter", mode = "markers", showlegend = FALSE,
                marker = list(size = 12, color = "white", line = list(color = color, width = 2.5)),
                hovertemplate = paste0("<b>", r$nombre, "</b><br>Validación: %{x:.4f} vs M0<extra></extra>")) |>
      add_trace(x = r$prueba, y = r$nombre, type = "scatter", mode = "markers", showlegend = FALSE,
                marker = list(size = 12, color = color, line = list(color = "white", width = 2)),
                hovertemplate = paste0("<b>", r$nombre, "</b><br>Prueba: %{x:.4f} vs M0<extra></extra>"))
  }
  x0 <- min(d$validacion, d$prueba) - 0.003; x1 <- max(d$validacion, d$prueba) + 0.003
  fig |> layout(
    shapes = list(list(type = "line", x0 = 0, x1 = 0, y0 = 0, y1 = 1, yref = "paper", line = list(color = TINTA_2, width = 1))),
    annotations = list(list(x = 0, y = 1.04, yref = "paper", text = "<b>M0 (base)</b>", showarrow = FALSE),
                       list(x = x0, y = -0.16, yref = "paper", xanchor = "left", text = "← mejor que M0", showarrow = FALSE),
                       list(x = x1, y = -0.16, yref = "paper", xanchor = "right", text = "peor que M0 →", showarrow = FALSE)),
    margin = list(t = 28, b = 40),
    xaxis = list(title = "", tickformat = ".3f", zeroline = FALSE, range = c(x0, x1)),
    yaxis = list(autorange = "reversed", showgrid = FALSE,
                 categoryorder = "array", categoryarray = d$nombre))          # en R, fija el orden de las filas
}
# ggplot2: geom_segment(aes(x = validacion, xend = prueba, y = nombre, yend = nombre)) + geom_point(aes(x = validacion), shape = 21, fill = "white")
#          + geom_point(aes(x = prueba)) + geom_vline(xintercept = 0) → ggplotly()
```

> **Decisión:** un gráfico de **mancuernas**: una fila por predictor, un punto hueco (validación) y uno relleno (prueba)
> unidos por una línea, medidos como diferencia de LogLoss contra M0 (el cero es M0). · **Alternativas:** (a) barras agrupadas
> de la diferencia (como en el Resumen) — a favor: forma familiar y desde cero; en contra: dos barras con signo por fila, con
> valores de ±0.01, ocupan mucho espacio y se pierde el "cruza el cero"; (b) dos columnas de puntos unidos por líneas
> (*slope chart*) — a favor: muestra el cambio de pendiente; en contra: con cinco predictores las líneas se cruzan y hay que
> etiquetar cada una; (c) puntos con intervalos bootstrap por predictor — a favor: muestran la incertidumbre; en contra: más
> complejo, y esos intervalos ya están en la tabla "¿Son significativas las diferencias?"; (d) una tabla — a favor: precisa
> (está en "Métricas completas"); en contra: el cambio de signo no salta a la vista. Ninguna se probó. · **Por qué ésta:** la
> historia es el **cambio de lado**: en validación los puntos huecos están a la izquierda de M0 y en prueba los rellenos a la
> derecha; la línea que cruza el cero lo hace visible de un vistazo, y el mercado (naranja) es el único que se queda a la
> izquierda en los dos periodos. · **Si preguntan:** "Cada fila es un modelo: el punto hueco es cómo le fue en validación y el
> relleno cómo le fue en prueba, comparado con M0. Los modelos con más variables mejoran en validación pero empeoran en
> prueba; el mercado es mejor que M0 en los dos periodos."

> **Decisión:** el color dice **quién** es (naranja el mercado, gris M1–M4) y el relleno del punto dice **cuándo** (hueco =
> validación, relleno = prueba); el sentido de lectura se escribe bajo el eje ("← mejor que M0" / "peor que M0 →") y el eje no
> lleva título. · **Alternativas:** (a) un color distinto por periodo — a favor: se distingue sin leyenda; en contra: rompe el
> significado fijo de los colores; (b) un título de eje técnico ("Δ LogLoss respecto a M0") — a favor: preciso; en contra: "menos
> es mejor" no se entiende de un vistazo; (c) sólo una nota en el subtítulo — a favor: gráfica más limpia; en contra: la
> dirección queda lejos de donde se lee el dato. Ninguna se probó. · **Por qué ésta:** se separan los canales (color = quién,
> forma = cuándo) y el eje, cuyo sentido es contraintuitivo (menos LogLoss es mejor), se explica con palabras justo donde se
> mira. · **Si preguntan:** "Hueco es validación y relleno es prueba; a la izquierda de la línea es mejor que M0 y a la
> derecha, peor."

#### 13b.2.11 `brecha_por_resultado`

**Qué pregunta responde:** el mercado le gana a M0 por poco (0.016 de LogLoss), pero ¿**en qué partidos**? Tarjeta *"No es una
derrota..."* (página *El modelo*, 48 % del ancho; subtítulo "Diferencia de LogLoss entre M0 y el mercado, según el
resultado.").

**Recibe:** `t` = `d["brecha"]` = `brecha_por_resultado()` ([13a.5.8](13a_codigo_datos_dashboard.md#13a58-brecha_por_resultado)):
**3 filas** (Victoria local, Empate, Victoria visitante) con `resultado`, `partidos`, `aporte`, `p_modelo` y `p_mercado`. El
**aporte** es la parte de la brecha que sale de los partidos con ese resultado; los tres suman la brecha total (+0.0159 con
N = 799 partidos de validación y prueba). Positivo = el mercado le dio más probabilidad a lo que ocurrió.

**El código** (líneas 286–306):

```python
def brecha_por_resultado(t: pd.DataFrame) -> go.Figure:
    colores = [MERCADO if v > 0 else MODELO for v in t["aporte"]]
    fig = go.Figure(go.Bar(
        y=t["resultado"], x=t["aporte"], orientation="h", marker=dict(color=colores, cornerradius=4), width=0.55,
        text=[f"{v:+.3f}" for v in t["aporte"]], textposition="outside", cliponaxis=False, constraintext="none",
        textfont=dict(color=TINTA_2, size=13),
        customdata=np.column_stack([t["partidos"], t["p_modelo"], t["p_mercado"]]),
        hovertemplate=("<b>%{y}</b> (%{customdata[0]} partidos)<br>Aporte a la brecha: %{x:.4f}"
                       "<br>Probabilidad media que le dio el modelo: %{customdata[1]:.1%}"
                       "<br>… y el mercado: %{customdata[2]:.1%}<extra></extra>"),
    ))
    fig.add_vline(x=0, line=dict(color=TINTA_2, width=1))
    limite = float(np.abs(t["aporte"]).max()) * 1.6
    fig.add_annotation(x=limite, y=-0.13, yref="paper", xanchor="right", yanchor="top",
                       text="el mercado fue mejor →", showarrow=False, font=dict(size=11, color=TENUE))
    fig.add_annotation(x=-limite, y=-0.13, yref="paper", xanchor="left", yanchor="top",
                       text="← el modelo fue mejor", showarrow=False, font=dict(size=11, color=TENUE))
    fig.update_layout(margin=dict(l=8, r=40, t=8, b=56))
    fig.update_xaxes(range=[-limite, limite], tickformat=".3f", zeroline=False)
    fig.update_yaxes(autorange="reversed", showgrid=False, tickfont=dict(color=TINTA, size=13))
    return fig
```

- **Color por signo:** `[MERCADO if v > 0 else MODELO for v in t["aporte"]]` es una *comprensión de listas*: una lista con un
  color por barra. Aporte positivo → **naranja** (el mercado fue mejor en esos partidos); negativo → **azul** (el modelo
  fue mejor). R: `ifelse(t$aporte > 0, MERCADO, MODELO)`.
- **Rótulo con signo:** `f"{v:+.3f}"` escribe tres decimales **siempre con signo** ("+0.019", "+0.008", "−0.010"; los
  valores sin redondear son 0.018518, 0.007815 y −0.010442; **cálculo propio**).
- **Tooltip:** nombre del resultado y número de partidos, el aporte con 4 decimales y la probabilidad media que le dio cada
  uno al resultado que ocurrió.
- **Eje simétrico:** `limite = máximo(|aporte|) × 1.6` = 0.0296; el eje va de −0.0296 a +0.0296, con el cero (línea de 1 px) al
  **centro**. Los dos rótulos de dirección van **debajo del eje** (`y=-0.13` en coordenadas de papel, `yanchor="top"`), de ahí el
  margen inferior de 56 px.

**Ejemplo con las cifras reales** ([13a.5.8](13a_codigo_datos_dashboard.md#13a58-brecha_por_resultado)):

| Resultado real | Partidos | Aporte (rótulo) | P media del modelo al resultado | … del mercado |
|---|---|---|---|---|
| Victoria local | 329 | +0.0185 (**+0.019**, naranja) | 49.7 % | 52.0 % |
| Empate | 211 | +0.0078 (**+0.008**, naranja) | 23.5 % | 24.3 % |
| Victoria visitante | 259 | −0.0104 (**−0.010**, azul) | 41.0 % | 40.3 % |
| **Total** | 799 | **+0.0159** | | |

La mayor parte de la brecha está en las **victorias locales** y, después, en los **empates**; en las victorias visitantes el modelo
fue **mejor** que el mercado. Es lo que dice el título: *no es una derrota* (y la gráfica enseña dónde conviene mejorar: el
local y el empate). La figura tiene 1 traza, 1 línea y 2 anotaciones.

**En R (ilustrativo, no ejecutado):**

```r
brecha_por_resultado <- function(t) {
  limite <- max(abs(t$aporte)) * 1.6
  plot_ly() |>
    add_bars(y = factor(t$resultado, levels = t$resultado), x = t$aporte, orientation = "h", width = 0.55,
             marker = list(color = ifelse(t$aporte > 0, MERCADO, MODELO)),
             text = sprintf("%+.3f", t$aporte), textposition = "outside", cliponaxis = FALSE,
             customdata = cbind(t$partidos, t$p_modelo, t$p_mercado),
             hovertemplate = paste0("<b>%{y}</b> (%{customdata[0]} partidos)<br>Aporte a la brecha: %{x:.4f}",
                                    "<br>Probabilidad media que le dio el modelo: %{customdata[1]:.1%}",
                                    "<br>… y el mercado: %{customdata[2]:.1%}<extra></extra>")) |>
    layout(shapes = list(list(type = "line", x0 = 0, x1 = 0, y0 = 0, y1 = 1, yref = "paper",
                              line = list(color = TINTA_2, width = 1))),
           annotations = list(
             list(x = limite, y = -0.13, yref = "paper", xanchor = "right", yanchor = "top", text = "el mercado fue mejor →", showarrow = FALSE),
             list(x = -limite, y = -0.13, yref = "paper", xanchor = "left", yanchor = "top", text = "← el modelo fue mejor", showarrow = FALSE)),
           margin = list(r = 40, b = 56),
           xaxis = list(range = c(-limite, limite), tickformat = ".3f", zeroline = FALSE),
           yaxis = list(autorange = "reversed", showgrid = FALSE))
}
# ggplot2: geom_col(aes(fill = aporte > 0), width = .55) + scale_fill_manual(values = c(`TRUE` = MERCADO, `FALSE` = MODELO)) + geom_vline(xintercept = 0)
```

> **Decisión:** descomponer la brecha entre M0 y el mercado (0.016 de LogLoss) en **tres barras horizontales con signo**, una por
> resultado, coloreadas según **quién fue mejor** (naranja = mercado, azul = modelo). · **Alternativas:** (a) mostrar sólo el
> número de la brecha — a favor: simple; en contra: esconde que viene de las victorias locales y los empates y que en las
> visitantes el modelo ganó; (b) una cascada (*waterfall*) que sume hasta 0.016 — a favor: muestra el total; en contra: más
> compleja, y el total ya está en el texto; (c) barras de la probabilidad media por resultado (modelo contra mercado) — a
> favor: más intuitivas; en contra: las diferencias (49.7 % contra 52.0 %) se ven pequeñas y no muestran el efecto sobre el
> LogLoss (esos valores quedan en el tooltip); (d) una tabla — a favor: precisa; en contra: no se lee de un vistazo. Ninguna
> se probó. · **Por qué ésta:** responde "¿dónde gana el mercado?" con la misma medida de todo el tablero (LogLoss) y usa el
> color con propósito: el naranja y el azul vuelven a ser mercado y modelo, esta vez como "quién ganó en esos partidos". · **Si
> preguntan:** "La brecha total es 0.016 y casi toda viene de las victorias locales y los empates, donde el mercado le dio un
> poco más de probabilidad a lo que pasó; en las victorias visitantes el modelo fue mejor."

> **Decisión:** el eje es **simétrico** alrededor del cero (±1.6 veces la barra más grande) y el sentido se escribe debajo con
> palabras ("← el modelo fue mejor" / "el mercado fue mejor →"). · **Alternativas:** (a) el rango automático de Plotly — a
> favor: aprovecha mejor el espacio; en contra: el cero queda descentrado y el rótulo de la barra más larga puede no caber;
> (b) un título de eje técnico ("aporte a la brecha de LogLoss") — a favor: preciso; en contra: no dice quién ganó. Ninguna
> se probó. · **Por qué ésta:** con el cero al centro, izquierda y derecha pesan igual y "quién fue mejor" se lee de
> inmediato; el 1.6 deja sitio al rótulo exterior de la barra más larga. · **Si preguntan:** "A la derecha del cero es mejor
> el mercado y a la izquierda el modelo; el eje es simétrico para que ningún lado parezca favorecido por la escala."

#### 13b.2.12 `efectos`

**Qué pregunta responde:** ¿qué variables de M0 pesan más en los goles esperados, y con cuánta incertidumbre? Tarjeta *"Qué
variables pesan más"* (página *El modelo*, primera pestaña de la fila de abajo; el subtítulo cita los dos p-valores de los goles
recibidos del rival: 0.506 y 0.0498).

**Recibe:** `e` = `d["efectos"]` = `efectos_estandarizados()` ([13a.5.10](13a_codigo_datos_dashboard.md#13a510-efectos_estandarizados)):
**6 filas** (3 variables por ecuación) con `ecuacion` ("Goles del local" / "Goles del visitante"), `variable`, `etiqueta` (el nombre
en español), `coef`, `p_valor`, `efecto`, `ic_inf` e `ic_sup`. El **efecto** es cuánto cambian los goles esperados (en %) si la
variable sube **una desviación estándar**: exp(β·DE) − 1; `ic_inf` e `ic_sup` son los extremos del intervalo de 95 % en esa
misma escala.

**El código** (líneas 309–329):

```python
def efectos(e: pd.DataFrame) -> go.Figure:
    ecuaciones = list(dict.fromkeys(e["ecuacion"]))
    fig = make_subplots(rows=1, cols=2, subplot_titles=[f"<b>{x}</b>" for x in ecuaciones], horizontal_spacing=0.2)
    for i, ec in enumerate(ecuaciones, start=1):
        s = e[e["ecuacion"] == ec]
        fig.add_scatter(
            x=s["efecto"], y=s["etiqueta"], mode="markers", row=1, col=i, showlegend=False,
            marker=dict(size=11, color=MODELO, line=dict(color="white", width=2)),
            error_x=dict(type="data", symmetric=False, array=s["ic_sup"] - s["efecto"],
                         arrayminus=s["efecto"] - s["ic_inf"], color=MODELO, thickness=1.5, width=0),
            customdata=np.column_stack([s["ic_inf"], s["ic_sup"], s["p_valor"]]),
            hovertemplate=("%{y}<br>+1 desviación estándar → %{x:+.1%} goles esperados"
                           "<br>IC 95%: %{customdata[0]:+.1%} a %{customdata[1]:+.1%}"
                           "<br>p-valor: %{customdata[2]:.3f}<extra></extra>"),
        )
        fig.add_vline(x=0, line=dict(color=BASE, width=1), row=1, col=i)
    fig.update_layout(margin=dict(l=8, r=16, t=40, b=8))
    fig.update_annotations(font=dict(size=12, color=TINTA_2))
    fig.update_xaxes(tickformat="+.0%", title_text="Cambio en goles esperados (+1 desv. estándar)")
    fig.update_yaxes(autorange="reversed", showgrid=False, tickfont=dict(color=TINTA, size=12))
    return fig
```

- `list(dict.fromkeys(e["ecuacion"]))` saca los **valores distintos conservando el orden** de aparición (un `set` no garantiza
  el orden). En R: `unique(e$ecuacion)`. Da `["Goles del local", "Goles del visitante"]`; con ellos se arman los dos paneles.
- `make_subplots(rows=1, cols=2, …, horizontal_spacing=0.2)`: dos paneles, uno por ecuación, con **20 % de separación**. Los
  ejes verticales **no se comparten** (cada ecuación tiene sus propias variables: "Goles recibidos · visitante" en el panel del
  local y "Goles recibidos · local" en el del visitante), así que el hueco de en medio aloja los nombres del panel derecho.
- Cada panel es **una traza de puntos** (azul `MODELO`, 11 px, borde blanco) en la posición del efecto, con **barras de error
  horizontales**: `type="data"` (la longitud se da en unidades de los datos), `symmetric=False` (brazos distintos),
  `array` = distancia al extremo **derecho** (`ic_sup − efecto`) y `arrayminus` = distancia al **izquierdo** (`efecto −
  ic_inf`), `thickness=1.5` y `width=0` (sin remates en los extremos). Los brazos no son iguales porque el intervalo de
  exp(β·DE) − 1 **no es simétrico** respecto al efecto.
- Una línea vertical en 0 por panel (`add_vline(..., row=1, col=i)`): "sin efecto". **Si el intervalo no toca esa línea, el
  efecto es significativo al 95 %.**
- Eje x con formato `+.0%` ("+10%", "−20%"; el cero se rotula "+0%" por el signo obligatorio) y un solo título para ambos
  paneles. Cada panel tiene **su propia escala en x** (se comprobó en el sitio: las marcas del panel del local van de +0 % a
  +30 % y las del visitante, de −20 % a +10 %).
- Tooltip: "Diferencia Elo / +1 desviación estándar → +26.7% goles esperados / IC 95%: +21.0% a +32.8% / p-valor: 0.000".

**Ejemplo con las cifras reales** ([13a.5.10](13a_codigo_datos_dashboard.md#13a510-efectos_estandarizados)):

| Panel | Variable (`etiqueta`) | Efecto de +1 DE | IC 95 % | p |
|---|---|---|---|---|
| Goles del local | Diferencia Elo | **+26.7 %** | +21.0 a +32.8 % | < 0.001 |
| | Goles a favor · local | +10.7 % | +6.3 a +15.4 % | < 0.001 |
| | Goles recibidos · visitante | +4.0 % | **+0.004** a +8.1 % | 0.0498 |
| Goles del visitante | Diferencia Elo | **−22.8 %** | −26.6 a −18.7 % | < 0.001 |
| | Goles a favor · visitante | +6.9 % | +2.2 a +11.9 % | 0.0039 |
| | Goles recibidos · local | +1.5 % | −2.8 a +5.9 % | 0.506 |

La diferencia de Elo domina en las dos ecuaciones; los goles recibidos del rival pesan poco: en el límite en la del local (el
intervalo apenas excluye el cero) y sin significancia en la del visitante (cruza el cero). La figura tiene 2 trazas, 2 líneas
y 2 anotaciones (los títulos de los paneles).

**En R (ilustrativo, no ejecutado).** Con `ggplot2` es una línea por elemento y `facet_wrap` hace los dos paneles con escalas
propias:

```r
efectos <- function(e) {
  g <- ggplot(e, aes(x = efecto, y = fct_rev(fct_inorder(etiqueta)))) +
    geom_vline(xintercept = 0, color = BASE) +
    geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), color = MODELO, size = 0.6) +   # punto + intervalo (horizontal)
    facet_wrap(~ecuacion, scales = "free") +                                          # ≈ make_subplots(rows = 1, cols = 2)
    scale_x_continuous(labels = scales::label_percent(style_positive = "plus")) +
    labs(x = "Cambio en goles esperados (+1 desv. estándar)", y = NULL) + theme_dashboard()
  ggplotly(g)
}
# plot_ly directo: add_markers(..., error_x = list(type = "data", symmetric = FALSE, array = s$ic_sup - s$efecto,
#                                                  arrayminus = s$efecto - s$ic_inf, thickness = 1.5, width = 0)) + subplot(nrows = 1, margin = 0.2)
```

> **Decisión:** un gráfico de efectos (punto + intervalo de 95 %) con el efecto estandarizado (+1 desviación estándar, en %
> de goles esperados), un panel por ecuación y una línea en cero. · **Alternativas:** (a) una tabla de coeficientes (β, error
> estándar, p) — a favor: el formato estándar de la regresión; en contra: los β no se comparan entre variables (unas están en
> unidades de Elo ÷ 400 y otras en goles por partido); (b) barras del |β| estandarizado — a favor: un ranking simple; en
> contra: sin intervalo, no se ve la incertidumbre; (c) importancia por permutación (cuánto empeora el LogLoss al revolver
> una variable) — a favor: mide aporte predictivo; en contra: no es lo mismo que el tamaño del efecto y exige recalcular;
> (d) un solo panel con las seis variables — a favor: compacto; en contra: mezcla dos ecuaciones con variables distintas. Ninguna
> se probó. · **Por qué ésta:** sale del mismo modelo, se lee en porcentaje de goles y el intervalo dice de un vistazo qué es
> significativo ("¿toca el cero?"). · **Si preguntan:** "Cada punto es cuánto cambian los goles esperados si esa variable sube
> una desviación estándar y la línea es el intervalo de 95 %: la diferencia de Elo domina (+27 % en los goles del local); los
> goles recibidos del rival pesan poco y en la ecuación del visitante no son significativos."

> **Decisión:** dos paneles (local y visitante) con **escala propia** en x. · **Alternativas:** (a) un eje x compartido
> (`shared_xaxes=True`) — a favor: la longitud de un efecto se compara directamente entre ecuaciones (+26.7 % contra
> −22.8 %); en contra: queda espacio vacío en cada panel (los efectos del local son positivos y casi todos los del visitante,
> negativos o pequeños). Ninguna se probó; **no hay constancia de que se haya comparado**: la escala propia es el
> comportamiento por omisión de `make_subplots`. · **Por qué ésta:** cada ecuación se lee por separado (qué variables pesan
> en los goles de cada equipo); lo que se compara entre paneles es la **posición respecto al cero**, que se ve igual en los dos.
> · **Si preguntan:** "Los dos paneles tienen escala propia; para comparar tamaños entre ecuaciones, la diferencia de Elo es
> de ≈ +27 % para el local y ≈ −23 % para el visitante, y están rotulados."

#### 13b.2.13 `calibracion_modelos`

**Qué pregunta responde:** ¿el modelo M0 y el mercado están igualmente bien calibrados?, ¿M0 confía de más en los favoritos?
Tarjeta *"Calibración: modelo vs. mercado"* (página *El modelo*, segunda pestaña de la fila de abajo). Su subtítulo lleva una
leyenda HTML (línea azul "modelo M0", línea naranja "mercado (apertura)") y la lectura: "El modelo confía de más en los
favoritos claros: cuando les da 60–80 %, ganan menos de lo previsto. También subestima el empate…".

**Recibe:** `t` = `d["calibracion_modelos"]` = `calibracion_modelo_vs_mercado()`
([13a.5.9](13a_codigo_datos_dashboard.md#13a59-calibracion_modelo_vs_mercado)): **16 filas**, 8 por predictor (`M0_Base` y
`Mercado_apertura`), con `n`, `prob_predicha`, `frecuencia` y `predictor`; 2,397 pares (799 partidos × 3) de validación y
prueba, en intervalos de 10 puntos con al menos 30 casos.

**El código** (líneas 332–345):

```python
def calibracion_modelos(t: pd.DataFrame) -> go.Figure:
    fig = go.Figure()
    fig.add_scatter(x=[0, 1], y=[0, 1], mode="lines", line=dict(color=BASE, width=1), hoverinfo="skip",
                    showlegend=False)
    for pred, nombre, color in [("Mercado_apertura", "Mercado (apertura)", MERCADO), ("M0_Base", "Modelo M0", MODELO)]:
        s = t[t["predictor"] == pred]
        fig.add_scatter(x=s["prob_predicha"], y=s["frecuencia"], mode="lines+markers", name=nombre,
                        line=dict(color=color, width=2), marker=dict(size=9, color=color, line=dict(color="white", width=2)),
                        customdata=s["n"],
                        hovertemplate=nombre + "<br>Dijo %{x:.1%} → ocurrió %{y:.1%}<br>%{customdata} casos<extra></extra>")
    fig.update_layout(margin=dict(l=8, r=16, t=12, b=8))
    fig.update_xaxes(range=[0, 1], tickformat=".0%", title_text="Probabilidad asignada")
    fig.update_yaxes(range=[0, 1], tickformat=".0%", title_text="Frecuencia observada")
    return fig
```

Es el **mismo diagrama de calibración** de [`calibracion_mercado`](#13b28-calibracion_mercado), con tres diferencias:

1. **Dos series** (mercado y M0) con **línea y marcadores** (2 px y 9 px), azul y naranja. Se dibuja primero el mercado y
   después M0, así que **M0 queda encima** (el orden de las trazas es el orden de apilado).
2. **Sin anotaciones**: la clave de colores y la lectura van en el subtítulo HTML de la tarjeta.
3. **Sin ejes cuadrados**: aquí no hay `scaleanchor`, así que en una tarjeta ancha la diagonal **no** queda a 45° (se ve en el
   sitio). La referencia sigue siendo válida (es la recta y = x en coordenadas de los datos), pero visualmente es menos
   "limpia" que en la otra gráfica; es una **diferencia sin justificación documentada**.

El tooltip dice "Modelo M0 / Dijo 64.4% → ocurrió 57.0% / 135 casos" (`%{customdata}` sin separador de miles: ningún intervalo
pasa de 990 casos).

**Ejemplo con las cifras reales** ([13a.5.9](13a_codigo_datos_dashboard.md#13a59-calibracion_modelo_vs_mercado)) —
probabilidad media → frecuencia observada (casos):

| Intervalo | M0 | Mercado (apertura) |
|---|---|---|
| 0–10 % | 7.3 → 7.5 % (40) | 7.4 → 5.6 % (54) |
| 10–20 % | 16.3 → 16.8 % (321) | 15.8 → 15.7 % (376) |
| 20–30 % | 24.6 → 26.4 % (990) | 25.2 → 27.1 % (964) |
| 30–40 % | 35.1 → 36.3 % (353) | 35.1 → 36.1 % (330) |
| 40–50 % | 44.6 → 40.6 % (283) | 44.9 → 43.5 % (246) |
| 50–60 % | 54.5 → 54.2 % (214) | 55.0 → 48.3 % (209) |
| 60–70 % | **64.4 → 57.0 %** (135) | 65.0 → 63.7 % (135) |
| 70–80 % | **74.1 → 68.1 %** (47) | 74.2 → 70.3 % (64) |

M0 confía de más en los favoritos claros (cuando dice 64 %, ocurre 57 %); el mercado se desvía menos en esa zona. (El mercado, en
cambio, se queda corto en el intervalo de 50–60 %: 55.0 → 48.3 %, donde M0 está casi perfecto, 54.5 → 54.2 %: cada uno tiene su
zona de desvío.) **Cálculo propio, aproximado:** con 135 casos y frecuencia ≈ 57 % el error estándar es de ≈ 4 puntos (la desviación de 7.4 puntos es de ≈ 1.7
errores estándar); con 47 casos, de ≈ 7 puntos (la de 6.0 puntos, menos de uno). Los dos grupos van en el mismo sentido, pero **es
una tendencia, no una prueba**. La figura tiene 3 trazas (la diagonal y dos series) y ninguna anotación.

**En R (ilustrativo, no ejecutado):**

```r
calibracion_modelos <- function(t) {
  fig <- plot_ly() |> add_lines(x = c(0, 1), y = c(0, 1), line = list(color = BASE, width = 1),
                                hoverinfo = "skip", showlegend = FALSE)
  for (p in list(c("Mercado_apertura", "Mercado (apertura)", MERCADO), c("M0_Base", "Modelo M0", MODELO))) {
    s <- filter(t, predictor == p[1])
    fig <- fig |> add_trace(x = s$prob_predicha, y = s$frecuencia, type = "scatter", mode = "lines+markers", name = p[2],
      line = list(color = p[3], width = 2), marker = list(size = 9, color = p[3], line = list(color = "white", width = 2)),
      customdata = s$n, hovertemplate = paste0(p[2], "<br>Dijo %{x:.1%} → ocurrió %{y:.1%}<br>%{customdata} casos<extra></extra>"))
  }
  fig |> layout(xaxis = list(range = c(0, 1), tickformat = ".0%", title = "Probabilidad asignada"),
                yaxis = list(range = c(0, 1), tickformat = ".0%", title = "Frecuencia observada"))
}
# ggplot2: ggplot(t, aes(prob_predicha, frecuencia, color = predictor)) + geom_abline(color = BASE) + geom_line() + geom_point(size = 3)
#          + scale_color_manual(values = c(Mercado_apertura = MERCADO, M0_Base = MODELO)) + coord_cartesian(xlim = c(0, 1), ylim = c(0, 1))
```

> **Decisión:** modelo y mercado en el **mismo** diagrama de calibración, cada uno con línea y marcadores (azul y naranja)
> sobre la diagonal; la lectura (dónde se desvía cada uno) va en el subtítulo y no en anotaciones. · **Alternativas:** (a) dos
> diagramas lado a lado — a favor: cada serie queda limpia; en contra: no se comparan de un vistazo; (b) la diferencia de
> calibración (M0 − mercado) por intervalo — a favor: una sola serie; en contra: se pierde la referencia a la calibración
> perfecta; (c) intervalos de confianza en cada punto — a favor: muestran el ruido (los grupos de 47 a 64 casos son frágiles);
> en contra: más tinta, y con dos series superpuestas se vuelve ilegible; (d) resumir en un número (error de calibración) — a
> favor: un ranking directo; en contra: no dice dónde falla. Ninguna se probó. · **Por qué ésta:** la pregunta del tablero es
> comparar modelo y mercado, y dos curvas sobre la misma diagonal muestran de inmediato que M0 cae bajo la diagonal en la zona
> de 60–80 % mientras el mercado se queda más cerca. · **Si preguntan:** "Si el modelo dice 64 %, ocurre ≈ 57 %; si el mercado
> dice 65 %, ocurre ≈ 64 %: el modelo es más optimista con los favoritos. Son pocos casos en esa zona, así que es una tendencia
> más que una prueba."

#### 13b.2.14 `modelo_vs_mercado`

**Qué pregunta responde:** ¿qué tan parecidas son las probabilidades de M0 y las del mercado partido por partido? (¿el modelo
"ve" casi lo mismo que el mercado?). Tarjeta *"Modelo vs. mercado, partido a partido"* (página *El modelo*, tercera pestaña de
la fila de abajo): "Coinciden en lo esencial; las discrepancias grandes son pocas."

**Recibe:** `d` = `d["partido_a_partido"]` = `comparacion_partido_a_partido()`
([13a.5.13](13a_codigo_datos_dashboard.md#13a513-comparacion_partido_a_partido)): **419 filas** (los partidos de prueba) con `Date`,
`HomeTeam`, `AwayTeam`, `p_local_modelo`, `p_local_mercado` y `resultado` ("Local", "Empate" o "Visitante").

**El código** (líneas 348–363):

```python
def modelo_vs_mercado(d: pd.DataFrame) -> go.Figure:
    r = np.corrcoef(d["p_local_modelo"], d["p_local_mercado"])[0, 1]
    fig = go.Figure()
    fig.add_scatter(x=[0, 1], y=[0, 1], mode="lines", line=dict(color=BASE, width=1), hoverinfo="skip",
                    showlegend=False)
    texto = [f"{html.escape(h)} – {html.escape(a)}<br>{f:%d-%m-%Y} · resultado: {res}"
             for h, a, f, res in zip(d["HomeTeam"], d["AwayTeam"], d["Date"], d["resultado"])]
    fig.add_scatter(x=d["p_local_mercado"], y=d["p_local_modelo"], mode="markers", showlegend=False,
                    marker=dict(size=8, color=TINTA_2, opacity=0.55, line=dict(color="white", width=1)),
                    text=texto, hovertemplate="%{text}<br>Mercado: %{x:.1%} · Modelo: %{y:.1%}<extra></extra>")
    fig.add_annotation(x=0.05, y=0.95, xref="paper", yref="paper", showarrow=False, align="left",
                       text=f"r = {r:.2f}", font=dict(size=14, color=TINTA))
    fig.update_layout(margin=dict(l=8, r=16, t=12, b=8))
    fig.update_xaxes(range=[0, 1], tickformat=".0%", title_text="P(victoria local) según el mercado")
    fig.update_yaxes(range=[0, 1], tickformat=".0%", title_text="P(victoria local) según el modelo M0")
    return fig
```

- `np.corrcoef(x, y)` devuelve la **matriz de correlaciones** 2 × 2; `[0, 1]` toma la correlación de Pearson entre las dos
  columnas: **r = 0.9389 → "r = 0.94"** (**cálculo propio**; coincide con [13a.5.13](13a_codigo_datos_dashboard.md#13a513-comparacion_partido_a_partido)).
  R: `cor(d$p_local_modelo, d$p_local_mercado)`.
- `texto`: una lista con el **texto del tooltip de cada partido**, armada con una comprensión de listas. `zip` recorre cuatro
  columnas a la vez (equipo local, visitante, fecha, resultado). `{f:%d-%m-%Y}` da formato a la fecha dentro del f-string
  ("17-08-2025"); en R, `format(Date, "%d-%m-%Y")`. En R todo esto se hace **vectorizado** con `paste0()`, sin bucle.
- `html.escape(h)`: el texto de un tooltip admite un subconjunto de HTML (`<br>`, `<b>`…), así que los **nombres de equipos,
  que vienen de un CSV** (datos, no código), se *escapan*: `<`, `>` y `&` se convierten en entidades y se muestran como
  texto. Se comprobó en el sitio que **"Nott'm Forest" se ve bien**: el texto crudo es `Nott&#x27;m Forest – Brentford` y
  Plotly lo muestra como "Nott'm Forest – Brentford".
- Puntos de 8 px en **`TINTA_2`** (gris oscuro) con **opacidad 0.55** y borde blanco: donde hay muchos partidos juntos la
  mancha se oscurece y se ve la densidad. No llevan color por resultado: el resultado va **en el tooltip**.
- La anotación "r = 0.94" va en la esquina superior izquierda en **coordenadas de papel** (`xref="paper"`: 5 % desde la
  izquierda y 95 % desde abajo), así que no depende de los datos.
- Ejes de 0 a 100 % en ambos lados; **no** son cuadrados (como en `calibracion_modelos`).

**Ejemplo con las cifras reales:** el tooltip de un punto dice, por ejemplo, "Nott'm Forest – Brentford / 17-08-2025 · resultado:
Local / Mercado: 44.1% · Modelo: 42.5%" (leído del sitio). En los 419 partidos, r = 0.94; la diferencia absoluta media es de 4.5
puntos, la mayor de 19.6 y sólo 43 partidos difieren en más de 10 puntos ([13a.5.13](13a_codigo_datos_dashboard.md#13a513-comparacion_partido_a_partido)).
La figura tiene 2 trazas (la diagonal y los 419 puntos) y 1 anotación.

**En R (ilustrativo, no ejecutado).** Con `ggplot2` + `ggplotly()`; el texto del tooltip entra por la estética `text`:

```r
modelo_vs_mercado <- function(d) {
  r <- cor(d$p_local_modelo, d$p_local_mercado)
  g <- ggplot(d, aes(p_local_mercado, p_local_modelo,
                     text = paste0(htmltools::htmlEscape(HomeTeam), " – ", htmltools::htmlEscape(AwayTeam), "<br>",
                                   format(Date, "%d-%m-%Y"), " · resultado: ", resultado))) +
    geom_abline(color = BASE) +
    geom_point(color = TINTA_2, alpha = 0.55, size = 2) +
    annotate("text", x = 0.05, y = 0.95, label = sprintf("r = %.2f", r), size = 5) +
    scale_x_continuous(limits = c(0, 1), labels = scales::percent) +
    scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
    labs(x = "P(victoria local) según el mercado", y = "P(victoria local) según el modelo M0") + theme_dashboard()
  ggplotly(g, tooltip = "text")
}
```

> **Decisión:** una **dispersión** de los 419 partidos de prueba (probabilidad de victoria local del mercado en x, del modelo en
> y) con la diagonal de acuerdo perfecto y el coeficiente r en una esquina. · **Alternativas:** (a) un histograma de las
> diferencias (modelo − mercado) — a favor: muestra directamente cuánto discrepan; en contra: pierde el nivel de las
> probabilidades; (b) un gráfico de Bland–Altman (diferencia contra promedio) — a favor: es el estándar para medir
> concordancia; en contra: poco conocido para esta audiencia; (c) sólo el número r — a favor: un resumen; en contra: no dice
> dónde discrepan; además r mide asociación lineal, no coincidencia (dos predictores pueden tener r = 0.94 y diferir de forma
> sistemática); (d) las tres probabilidades (local, empate, visitante) — a favor: completo; en contra: tres gráficas y menos
> claridad. Ninguna se probó. · **Por qué ésta:** es la forma más directa de ver que las dos probabilidades "van juntas" (los
> puntos siguen la diagonal); el tooltip identifica el partido de cualquier punto raro; y la diagonal permite ver si hay sesgo
> sistemático (los puntos estarían todos de un lado). · **Si preguntan:** "Cada punto es un partido de prueba: a la derecha lo
> que dio el mercado, arriba lo que dio nuestro modelo; la mayoría cae sobre la diagonal (r = 0.94), o sea que el modelo y el
> mercado casi coinciden y las diferencias grandes son pocas."

### Tablas

#### 13b.2.15 `tabla_html`

**Qué hace:** convierte un `DataFrame` en el HTML de una tabla con el estilo del tablero. **No es una gráfica**; la usan las 7
tablas de `index.qmd`.

**El código** (líneas 367–374):

```python
def tabla_html(df: pd.DataFrame, clase: str = "tabla") -> str:
    """Tabla HTML sencilla; los textos se escapan porque vienen de archivos de datos."""
    cab = "".join(f"<th>{html.escape(str(c))}</th>" for c in df.columns)
    cuerpo = "".join(
        "<tr>" + "".join(f"<td>{html.escape(str(v))}</td>" for v in fila) + "</tr>"
        for fila in df.itertuples(index=False)
    )
    return f'<div class="tabla-contenedor"><table class="{clase}"><thead><tr>{cab}</tr></thead><tbody>{cuerpo}</tbody></table></div>'
```

- `cab`: arma el encabezado: una celda `<th>` por columna, con el nombre de la columna **escapado** (`html.escape(str(c))`).
- `cuerpo`: arma las filas. `df.itertuples(index=False)` recorre la tabla fila por fila **sin el índice**; por cada fila se
  arma un `<tr>` con una `<td>` por valor. **`str(v)`** convierte cada celda en texto: la tabla no formatea números, **el
  formato lo decide quien la llama** (en `index.qmd`: `t["pct_local"].map(pct)`, `mt["logloss"].map(lambda v: f"{v:.4f}")`).
- `html.escape`: cambia `&`, `<`, `>` y las comillas por entidades, para que un texto con esos símbolos no se interprete como
  HTML (los datos vienen de archivos).
- El resultado es **una sola cadena de HTML**: un `<div class="tabla-contenedor">` (caja con desplazamiento y borde
  redondeado) que envuelve la `<table class="tabla">`. Los estilos viven en `estilos.scss` ([13c](13c_codigo_index_quarto.md)):
  `table.tabla` ocupa el 100 % del ancho, usa cifras de ancho uniforme (`font-variant-numeric: tabular-nums`) para que las
  columnas alineen y deja el **encabezado fijo** (`position: sticky`) al desplazar.
- En `index.qmd` se muestra con `HTML(tabla_temporadas)` (`IPython.display.HTML` marca la cadena como HTML crudo).

**Ejemplo** (derivado del código, no ejecutado): `tabla_html(pd.DataFrame({"Predictor": ["M0 · Base"], "LogLoss": ["1.0331"]}))`
devuelve

```html
<div class="tabla-contenedor"><table class="tabla"><thead><tr><th>Predictor</th><th>LogLoss</th></tr></thead><tbody><tr><td>M0 · Base</td><td>1.0331</td></tr></tbody></table></div>
```

**Las 7 tablas del tablero** (todas se construyen en el chunk de preparación de `index.qmd`, con el comentario "vista tabular
de cada gráfica, para quien no puede o no quiere leer la gráfica"):

| Variable | Tarjeta · página | Gráfica a la que acompaña | Columnas |
|---|---|---|---|
| `tabla_temporadas` | "Tabla por temporada" · ¿Qué ocurre? (pestaña) | `resultados_por_temporada` | Temporada, Partidos, Local, Empate, Visitante, Ventaja local (pp), Goles local, Goles visitante |
| `tabla_elo` | "Tabla: resultado por diferencia de Elo" · Patrones (pestaña) | `resultado_por_diferencia_elo` | Decil, Diferencia de Elo, Partidos, Gana local, Empate, Gana visitante |
| `tabla_calibracion` | "Tabla: calibración de las cuotas" · Patrones (pestaña) | `calibracion_mercado` | Probabilidad implícita (promedio del grupo), Frecuencia observada, Casos |
| `tabla_metricas` | "Métricas completas" · El modelo (pestaña) | `mejora_sobre_ingenua` y `delta_vs_m0` (comparten los LogLoss) | Periodo, Predictor, Partidos, LogLoss, Prob. media al resultado real, Aciertos, P(empate) media, MAE goles |
| `tabla_bootstrap` | "¿Son significativas las diferencias?" · El modelo (pestaña) | complementa a `delta_vs_m0` y `brecha_por_resultado` (intervalos bootstrap) | Periodo, Comparación (A − B), Partidos, Diferencia de LogLoss, IC 95 %, ¿Distinta de cero? |
| `tabla_auditoria` | "Limpieza y calidad" · Datos y método | ninguna (revisión de calidad de `E0_consolidado.csv`) | las de `d["auditoria"]` |
| `tabla_verificacion` | "Reproducibilidad" · Datos y método | ninguna (la verificación 17 de 17) | las de `d["verificacion"]` + "Coincide" (✓/✗) |

**En R (ilustrativo, no ejecutado):**

```r
tabla_html <- function(df, clase = "tabla") {
  cab    <- paste0("<th>", htmltools::htmlEscape(names(df)), "</th>", collapse = "")
  cuerpo <- paste0(apply(df, 1, function(fila)
              paste0("<tr>", paste0("<td>", htmltools::htmlEscape(fila), "</td>", collapse = ""), "</tr>")),
            collapse = "")
  sprintf('<div class="tabla-contenedor"><table class="%s"><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>',
          clase, cab, cuerpo)
}
# en un chunk:  htmltools::HTML(tabla_html(df))
# lo habitual en R: knitr::kable(df, format = "html", escape = TRUE, table.attr = 'class="tabla"'), o gt::gt(df), o DT::datatable(df)
```

> **Decisión:** una función propia de 8 líneas que arma la tabla HTML a mano (con `html.escape`) y le pone las clases
> `tabla-contenedor` y `tabla` del CSS, en lugar de `DataFrame.to_html()`. · **Alternativas:** (a)
> `df.to_html(escape=True, index=False, classes="tabla")` — a favor: una línea y es lo estándar de pandas; en contra: agrega
> sus propios atributos (`border="1"`, la clase `dataframe`, el estilo `text-align: right` en el encabezado) y no incluye la
> caja con desplazamiento, así que habría que anularlos desde el CSS (no se probó); (b) una tabla interactiva (`itables` o
> DataTables: ordenar, buscar) — a favor: más cómoda con tablas largas; en contra: más JavaScript y otra dependencia (no se
> probó); (c) tablas con otra librería (`great_tables`) o Markdown — a favor: integradas con Quarto; en contra: el estilo
> depende de Pandoc o de la librería y se sale de la plantilla del tablero (no se probó). · **Por qué ésta:** control total del
> HTML que recibe el CSS de `estilos.scss`, cero dependencias nuevas y pocas líneas fáciles de leer; el formato de los números
> se decide en `index.qmd`, donde ya está el resto de las cifras con formato. · **Si preguntan:** "Armamos la tabla HTML con
> una función de pocas líneas para que tenga exactamente el estilo del tablero; los textos se escapan porque vienen de
> archivos de datos."

#### La vista de tabla: qué gráficas la tienen

El comentario de `index.qmd` dice "vista tabular de cada gráfica", pero **no todas las gráficas tienen tabla**. Estado real:

| Gráfica | ¿Vista de tabla? | Cuál |
|---|---|---|
| `mejora_sobre_ingenua` | **sí, compartida** | "Métricas completas" (LogLoss, aciertos… de los 9 predictores; la mejora es ingenua − predictor) |
| `resultados_por_temporada` | **sí** | "Tabla por temporada" |
| `resultado_favorito` | no | las tres cifras ya son el rótulo de cada barra |
| `resultado_por_diferencia_elo` | **sí** | "Tabla: resultado por diferencia de Elo" |
| `calibracion_mercado` | **sí** | "Tabla: calibración de las cuotas" |
| `ajuste_poisson` | no | (la tabla está en [13a.4.7](13a_codigo_datos_dashboard.md#13a47-ajuste_poisson_goles), no en el sitio) |
| `delta_vs_m0` | **sí, compartida** | "Métricas completas" (y los intervalos, en "¿Son significativas las diferencias?") |
| `brecha_por_resultado` | no | los tres aportes son el rótulo de cada barra; el resto, en el tooltip |
| `efectos` | no | cifras sólo en el tooltip (y dos p-valores en el subtítulo) |
| `calibracion_modelos` | no | cifras sólo en el tooltip |
| `modelo_vs_mercado` | no | 419 puntos: sólo en el tooltip |

**Son 5 de 11 gráficas** las que tienen tabla con sus datos (tres con tabla propia —temporadas, Elo, calibración de las
cuotas— y dos que comparten "Métricas completas") y **5 tablas de gráficas** en total (`tabla_temporadas`, `tabla_elo`,
`tabla_calibracion`, `tabla_metricas`, `tabla_bootstrap`); las otras dos, `tabla_auditoria` y `tabla_verificacion`, no
acompañan a ninguna gráfica. **No es cierto que "cada gráfica tenga su tabla".**

> **Decisión:** dar vista de tabla (en una pestaña junto a la gráfica) sólo a las gráficas con más cifras que leer; las demás
> llevan sus cifras como rótulo o en el tooltip. · **Alternativas:** (a) una tabla para **cada** gráfica — a favor: máxima
> accesibilidad (quien no puede o no quiere leer una gráfica tiene sus datos en texto); en contra: seis pestañas más, tablas de
> tres filas que repiten el rótulo y una de 419 filas que nadie leería; (b) ninguna tabla — a favor: tablero más limpio; en
> contra: quien necesite las cifras exactas (o no vea las gráficas) no las tendría; (c) un botón de descarga (CSV) — a favor:
> sirve a quien quiera analizar los datos; en contra: más código y un archivo por gráfica (no se hizo). Ninguna se probó. ·
> **Por qué ésta:** es un compromiso entre accesibilidad y claridad: la tabla va donde la gráfica esconde muchas cifras
> (25 temporadas, 10 deciles, 18 intervalos, 9 predictores) y se omite donde la cifra ya está escrita en la barra. · **Si
> preguntan:** "Las gráficas con más datos —temporadas, deciles, calibración, métricas— tienen su tabla en una pestaña; las que
> sólo tienen tres barras llevan las cifras escritas en la propia barra."

---

## 13b.3 Detalles raros y textos escritos a mano

Cosas que conviene saber **antes** de que alguien las encuentre. Ninguna cambia una conclusión; todas se dejaron como se
entregaron (no se corrigió el código). Lo marcado "observado" se comprobó en el sitio publicado el 3-oct-2026.

### Código sin uso

- **`_anotacion`** (líneas 79–82) **no se llama desde ninguna parte**: es código muerto ([13b.2.3](#13b23-_anotacion)).
- **`AZULES`** (línea 39) **no se usa en `graficas.py`**. Sus tonos sí se necesitan: `index.qmd` escribe **a mano** los extremos
  de la escala del mapa de calor del simulador (`["#eef5fd", "#184f95"]`, que son `AZULES[0]` y `AZULES[6]`) y el fondo
  `#eef5fd` de dos *value boxes*. La constante sirve entonces como documentación de la escala secuencial.
- **`showlegend=i == 1`** (en `ajuste_poisson`) y los `name=` de las trazas son **inertes** en el tablero: `mostrar` apaga la
  leyenda. Sirven si alguien muestra una figura sin pasar por `mostrar` (por ejemplo, para depurar).

### La paleta está repetida

La paleta vive en **tres** archivos ([13b.1.2](#13b12-la-paleta-un-color-un-significado)): `graficas.py`, `estilos.scss`
(variables `--modelo`, `--mercado`, `--local`, `--visita`, `--contexto`; los mismos cinco hex) e `index.qmd` (las leyendas
HTML y el simulador escriben hex a mano: `#898781`, `#2a78d6`, `#eb6834`, `#52514e`, `#eef5fd`, `#184f95`, `#0b0b0b`, `#f3f2ee`).
Los **grises de apoyo no coinciden** entre Plotly y el CSS (`TINTA` `#0b0b0b` contra `--tinta` `#171717`; `TINTA_2` `#52514e`
contra `#5f6368`; `REJILLA` `#e1e0d9` contra `#eceef1`). Cambiar un color exige tocar los tres sitios.

### Textos y números escritos a mano dentro de las gráficas

El tablero se cuida de que las cifras salgan del código, pero dentro de `graficas.py` hay textos fijos. Casi todos son
etiquetas, pero **conviene revisarlos si cambian los datos**:

| Dónde | Lo que está escrito a mano | ¿Se calcula? | Si cambian los datos |
|---|---|---|---|
| `mejora_sobre_ingenua` (líneas 88–90) | "Modelo base M0 · 3 variables", "Modelo completo M4 · 9 variables" | no (hoy son ciertos: M0 tiene 3 variables por ecuación y M4, 9) | habría que editarlos si cambia la especificación |
| `mejora_sobre_ingenua` (líneas 93–94) | "Validación 2024/25", "Prueba 2025/26 – sep 2026" | no | habría que editarlos si cambian las particiones o el corte |
| `resultados_por_temporada` (líneas 122–123, 146, 149) | bordes de las bandas (2018.5, 2023.5, 2024.5, 2025.5), `range(2001, 2026, 3)`, rango x hasta 2025.8 | no | al cerrar la temporada 2026/27 habría que mover bandas, marcas y rango |
| `resultados_por_temporada` (líneas 139–143) | la temporada 2020 y la frase "única temporada en que los visitantes ganan más partidos que los locales" | no (la altura de la flecha sí) | la frase seguiría diciendo lo mismo aunque dejara de ser cierta |
| `calibracion_mercado` (línea 221) | "Los grandes favoritos ganan un poco más de lo que dicen las cuotas" | no | hoy concuerda con los datos (86.8 % → 92.5 %) |
| `calibracion_modelos`, `modelo_vs_mercado`, `delta_vs_m0` | los nombres "Modelo M0", "Mercado (apertura)", "según el modelo M0", "← mejor que M0" | no | M0 está escrito en los rótulos |
| `resultado_favorito` (línea 164) | el eje x fijo de 0 a 70 % | no | recortaría una barra si el favorito ganara más de 70 % |
| varias | posiciones de anotaciones (`ay=0.84`, `ax=2014.2`, `(0.97, 0.06)`, `y=0.62`…) | no | con otros datos podrían tapar una línea |
| *Sí se calculan* | "≈50 puntos", "9,160 partidos", medias y varianzas del título de Poisson, "r = 0.94", límites de los ejes, rótulos de las barras | **sí** | se actualizan solas |

### Cosas que se ven raras en el sitio (observado)

- **No se dibuja la categoría "6+" de `ajuste_poisson`**; el eje x muestra 0, 2 y 4 ([13b.2.9](#13b29-ajuste_poisson)).
- **El tooltip de `resultados_por_temporada` repite la temporada.** Con `hovermode="x unified"`, el cuadro único tiene un
  encabezado con el **año de inicio** ("2020") y después tres filas que empiezan cada una con "2020/21" (porque la plantilla de cada
  traza arranca con `%{customdata}`).
- **Ejes no cuadrados en dos gráficas:** `calibracion_modelos` y `modelo_vs_mercado` no fuerzan ejes iguales (sí lo hace
  `calibracion_mercado`), así que su diagonal no queda a 45° y las marcas "0%" de los dos ejes se enciman en la esquina.
- **En `efectos`, el cero se rotula "+0%"** (por el formato con signo obligatorio, `+.0%`) y cada panel tiene su propia escala.
- **Con una ventana angosta (≈ 800 px de ancho, la del panel de vista previa) se recortan los títulos largos de eje** (el de `mejora_sobre_ingenua` y el de
  `resultado_favorito` pierden el último carácter) y las marcas del eje x de `resultados_por_temporada` quedan casi pegadas.

### Otros detalles de código

- **`f` significa dos cosas:** en `resultado_favorito(f)` es el diccionario del favorito y en `modelo_vs_mercado` es la fecha de
  la comprensión de listas (`for h, a, f, res in zip(...)`). Cada una vive en su función; no hay choque, pero confunde.
- **`cornerradius=4`** (esquinas redondeadas de las barras) es una propiedad reciente de Plotly; la versión está fija en
  `requirements.txt` (`plotly==5.24.1`), así que una versión muy vieja podría rechazarla.
- **Formato de los números:** las gráficas escriben "42.6%" (sin espacio) y algunos textos de `index.qmd` escriben "80 %" (con
  espacio). Es una diferencia tipográfica menor.
- **`go.Figure(go.Bar(...))` contra `go.Figure()` + `add_bar`:** el archivo usa las dos formas ([`resultado_favorito`](#13b26-resultado_favorito)
  y [`brecha_por_resultado`](#13b211-brecha_por_resultado) usan la primera). Equivalen.

---

## 13b.4 Preguntas rápidas

| Pregunta | Respuesta para decir en voz alta | Más detalle |
|---|---|---|
| ¿Por qué Plotly y no ggplot2? | "Plotly da tooltips en un HTML estático, sin servidor; en R sería `plotly` o `ggplotly()`." | [13b.1.1](#13b11-docstring-e-importaciones), D43 |
| ¿Qué significa cada color? | "Azul el modelo, naranja el mercado, verde el local, violeta el visitante y gris el contexto; siempre lo mismo." | [13b.1.2](#13b12-la-paleta-un-color-un-significado) |
| ¿Por qué quitaron el zoom? | "Un arrastre sin querer dejaba la gráfica ampliada y sin forma de regresar; el detalle sigue en los tooltips y las tablas." | [13b.1.4](#13b14-config) |
| ¿Por qué cada tarjeta tiene como título una frase? | "Porque el título dice el hallazgo; así la gráfica no repite el título y el lector sabe qué mirar." | D45, [13b.5](#13b5-principios-de-visualización-aplicados) |
| ¿Por qué no hay leyendas dentro de las gráficas? | "Plotly las mide mal cuando la página está oculta y se enciman; las pusimos en HTML y, donde se puede, etiquetamos directo." | [13b.2.1](#13b21-mostrar) |
| ¿Por qué las barras parten de cero? | "Para no exagerar diferencias; en la de mejora, el cero es la referencia ingenua." | [13b.2.4](#13b24-mejora_sobre_ingenua) |
| ¿Por qué todas las barras de "Ni el favorito es garantía" son grises? | "Porque no hay protagonistas que distinguir: son tres resultados posibles, y el color se reserva para modelo y mercado." | [13b.2.6](#13b26-resultado_favorito) |
| ¿De dónde sale "≈ 50 puntos" en la gráfica de Elo? | "Es cuánto más débil puede ser el local para que local y visitante tengan la misma probabilidad: se interpola entre los deciles." | [13b.2.7](#13b27-resultado_por_diferencia_elo), [13a.4.5](13a_codigo_datos_dashboard.md#13a45-ventaja_local_en_elo) |
| ¿Qué es la diagonal de las gráficas de calibración? | "La calibración perfecta: lo que decía la probabilidad es lo que ocurrió; bajo la diagonal ocurrió menos de lo dicho." | [13b.2.8](#13b28-calibracion_mercado) |
| ¿Por qué mancuernas en "Agregar variables no generaliza"? | "Porque lo importante es el cambio de lado: hueco (validación) a la izquierda de M0, relleno (prueba) a la derecha." | [13b.2.10](#13b210-delta_vs_m0) |
| ¿Por qué el eje de "No es una derrota..." es simétrico? | "Para que ningún lado parezca favorecido: a la derecha gana el mercado y a la izquierda el modelo." | [13b.2.11](#13b211-brecha_por_resultado) |
| ¿Cada gráfica tiene su tabla? | "No: las que concentran más datos —temporadas, deciles, calibración y métricas— sí; las de tres barras llevan las cifras escritas." | [13b.2.15](#13b215-tabla_html) |
| ¿Por qué no aparece la barra "6+" en la gráfica de Poisson? | "Es un defecto de dibujo conocido: el eje se interpretó como numérico y esa barra (0.8 % y 0.3 % de los partidos) no se muestra; los datos sí la tienen." | [13b.2.9](#13b29-ajuste_poisson) |
| ¿Es accesible para personas con daltonismo? | "La paleta se revisó para daltonismo (por eso el local pasó de aqua a verde), casi siempre el color va con etiqueta o con otra forma de distinguir, y las cifras principales tienen tabla. Límites: no hay texto alternativo y los números de los ejes tienen un contraste justo." | [13b.5](#13b5-principios-de-visualización-aplicados) |
| ¿Qué pasa si cambia un dato (por ejemplo, termina la temporada 2026/27)? | "Las cifras se recalculan solas; hay que revisar a mano las bandas de periodos, las etiquetas '3 variables'/'9 variables' y las frases fijas." | [13b.3](#13b3-detalles-raros-y-textos-escritos-a-mano) |
| ¿Qué es `redibujar.html`? | "Un script que vuelve a dibujar las gráficas cuando su pestaña se vuelve visible; Plotly mide mal lo que se dibuja oculto." | [13c, 3.3](13c_codigo_index_quarto.md), D46 |
| ¿Se verifican las gráficas? | "El tablero verifica 17 cifras contra el notebook; las gráficas se revisan a ojo, con el conteo de trazas de [13b.0](#cómo-comprobar-el-módulo)." | [13b.0](#cómo-comprobar-el-módulo) |

---

## 13b.5 Principios de visualización aplicados

Son los del material del módulo (la tabla de principios del [capítulo 13, 13.3](13_dashboard.md)); aquí se ve **dónde vive cada
uno en el código** y qué tan bien se cumplió. No se cita ninguna fuente externa: sólo el material del módulo y el propio código.

### Contar una historia (*storytelling*)

- **Cada gráfica responde una pregunta y el título dice la respuesta** (D45): la gráfica no define `title`; el título está en la
  tarjeta de `index.qmd` ("Jugar en casa siempre ayuda… salvo sin público"). Por eso las funciones no tienen texto de título.
- **La conclusión se anota en la propia gráfica**, con una flecha y en palabras: la nota del COVID, "eso vale jugar en casa",
  "los grandes favoritos ganan un poco más de lo que dicen las cuotas", "← el modelo fue mejor". El lector no tiene que inferirla.
- **Orden de la historia:** Resumen (la conclusión primero) → ¿Qué ocurre? → Patrones → El modelo; las 11 gráficas están repartidas
  así ([13b.0](#todas-las-piezas-del-archivo)).

> **Decisión:** el título de cada tarjeta dice el **hallazgo** ("Jugar en casa siempre ayuda… salvo sin público") y las figuras no
> llevan título propio (ninguna define `title`); el subtítulo de la tarjeta dice qué se muestra y trae la leyenda. ·
> **Alternativas:** (a) títulos descriptivos ("Resultados por temporada") — a favor: neutros y fáciles de ubicar; en contra:
> obligan al lector a sacar la conclusión (D45); (b) el título dentro de la figura de Plotly — a favor: la figura es
> autosuficiente si se exporta; en contra: duplica el título de la tarjeta y compite con él por el mismo sitio (no se probó);
> (c) título descriptivo y la conclusión en un texto aparte — a favor: separa descripción de mensaje; en contra: el mensaje queda
> lejos de la gráfica. Ninguna se probó. · **Por qué ésta:** el título es lo primero que se lee, así que la gráfica se mira
> *buscando* esa conclusión, y las anotaciones (la nota del COVID, "eso vale jugar en casa") la señalan dentro de la propia
> gráfica. · **Si preguntan:** "Cada título dice lo que hay que ver; la gráfica y su subtítulo muestran cómo se ve y de dónde
> sale."

| Gráfica | Lo que le dice al lector (en una frase) |
|---|---|
| `mejora_sobre_ingenua` | El modelo alcanza ≈ 80 % de la mejora del mercado sobre la referencia ingenua; más variables (M4) no ayudan en prueba. |
| `resultados_por_temporada` | El local gana más que el visitante en todas las temporadas menos 2020/21, la de los estadios vacíos. |
| `resultado_favorito` | El favorito de las cuotas sólo gana 54 % de las veces: predecir fútbol es difícil. |
| `resultado_por_diferencia_elo` | A más ventaja de Elo, más victorias locales; jugar en casa vale ≈ 50 puntos de Elo. |
| `calibracion_mercado` | Las cuotas están bien calibradas (salvo un pequeño sesgo en los extremos): ganarles exige información nueva. |
| `ajuste_poisson` | Los goles se parecen a una Poisson: la regresión de Poisson es un modelo razonable. |
| `delta_vs_m0` | Las variables extra mejoran en validación pero no en prueba; el mercado es mejor que M0 en los dos. |
| `brecha_por_resultado` | La ventaja del mercado viene sobre todo de las victorias locales y los empates; en las visitantes el modelo fue mejor. |
| `efectos` | La diferencia de Elo domina; los goles recibidos del rival pesan poco. |
| `calibracion_modelos` | M0 confía de más en los favoritos claros; el mercado se desvía menos. |
| `modelo_vs_mercado` | Modelo y mercado casi coinciden (r = 0.94); las discrepancias grandes son pocas. |

### Menos tinta

Todo lo que no transmite información se quitó o se suavizó, y está en la `PLANTILLA` y en `mostrar`:

- sin líneas de eje, sin marcas (*ticks*), sin línea del cero, sin recuadro ni fondo (fondos transparentes);
- rejilla de 1 px en un gris casi blanco (1.32:1 contra blanco: está ahí, pero no compite con los datos);
- sin barra de herramientas, sin título de gráfica, sin leyenda interna (las leyendas, si hacen falta, en una línea de HTML);
- **etiquetas directas** en vez de leyenda y ejes con sólo las marcas necesarias (cada tres temporadas, `.0%`);
- sin pasteles, sin 3D, sin sombras dentro de Plotly (las sombras y los bordes redondeados de las tarjetas son del CSS y son
  decoración, no tinta de datos);
- los decimales justos: 3 en el LogLoss (las diferencias están en la tercera cifra), 1 en los porcentajes, 4 en los tooltips.

### Color con propósito

- **El color es identidad, no decoración:** cinco colores con significado fijo (azul = modelo, naranja = mercado, verde =
  local, violeta = visitante, gris = contexto) y **gris para todo lo demás** ([13b.1.2](#13b12-la-paleta-un-color-un-significado)).
- **Un segundo canal para lo que no es entidad:** la **opacidad** para el periodo (`mejora_sobre_ingenua`), el **relleno** del
  punto (`delta_vs_m0`), el **signo** en `brecha_por_resultado` (donde el color dice quién ganó).
- **El color no se desperdicia:** `resultado_favorito` y `modelo_vs_mercado` son de un solo tono neutro porque no hay
  protagonistas que distinguir.

### Accesibilidad

**Lo que sí hay:**

- **Color nunca solo, casi siempre:** las series llevan etiqueta directa (temporadas, Elo), las barras llevan su cifra, los
  periodos se distinguen por **opacidad o relleno** (diferencias de claridad y de forma, no de matiz) y el sentido de lectura
  está escrito ("← mejor que M0").
- **Pares de colores usuales:** el par azul–naranja suele distinguirse bien en las formas comunes de daltonismo (es el par
  principal de las comparaciones modelo–mercado). El docstring afirma que la paleta se validó para daltonismo; el cambio del
  local de aqua a verde es la evidencia documentada ([13b.1.2](#13b12-la-paleta-un-color-un-significado)).
- **Contraste** (cálculo propio): los cinco colores de entidad superan 3:1 contra blanco; los textos principales
  (`TINTA` 19.7:1, `TINTA_2` 7.9:1) superan 4.5:1.
- **Tooltips** con las cifras exactas y **tablas** para 5 de las 11 gráficas ([13b.2.15](#13b215-tabla_html)).
- Texto en español declarado (`lang: es` en `index.qmd`), tamaños de letra de 11 a 14 px y gráficas que se adaptan al ancho
  (`responsive`, `redibujar.html`).

**Lo que no hay (límites honestos):**

- **No hay texto alternativo** para las gráficas (ningún chunk define `fig-alt`) ni navegación por teclado de los tooltips.
- **Los números de los ejes** (`TENUE`, 3.59:1) quedan por debajo de los 4.5:1 recomendados para texto pequeño.
- **Seis gráficas sin tabla** (las que se listan en [13b.2.15](#la-vista-de-tabla-qué-gráficas-la-tienen)).
- **No se repitió la prueba de daltonismo** en esta guía y en la carpeta del tablero no hay un script que la reproduzca.
- Las dos curvas de `calibracion_modelos` se distinguen sólo por color (la leyenda HTML también): dependen de que el par
  azul–naranja se distinga bien.

### Cómo revisar una gráfica nueva (lista corta)

1. ¿Qué pregunta responde y el **título de la tarjeta** dice la respuesta?
2. ¿Los **colores** significan lo mismo que en el resto del tablero (o es neutra)?
3. Si es de barras, ¿**parte de cero**? Si no, ¿se dice por qué?
4. ¿Hay **etiqueta directa** de lo importante y la **leyenda** (si hace falta) está en el subtítulo HTML?
5. ¿Pasa por `mostrar` (sin zoom ni leyenda interna) y **se ve bien en una pestaña oculta** (`redibujar.html`)?
6. ¿Tiene **tabla** o sus cifras están escritas en la propia gráfica?
7. ¿Hay texto o números **escritos a mano** que habría que actualizar si cambian los datos ([13b.3](#13b3-detalles-raros-y-textos-escritos-a-mano))?
