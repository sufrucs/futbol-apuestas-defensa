# 13c. El código del tablero (II): `index.qmd` y los archivos de configuración y estilo

[← `graficas.py`](13b_codigo_graficas.md) · [Índice](README.md) · [Siguiente: publicación en GitHub →](14_publicacion_en_github.md)

> **Versión que se explica:** la entregada (rama `main`, commit `e3bd43f`, 30-sep-2026). `index.qmd` tiene **670 líneas**
> (514 con contenido); `estilos.scss`, 970; `redibujar.html`, 46; `_quarto.yml`, 12; `requirements.txt`, 10; `.gitignore`, 10;
> el `README.md` de la carpeta, 48. "Líneas 25–150" son siempre líneas de `index.qmd`, salvo que se nombre otro archivo.
>
> **De dónde salen las cifras de ejemplo:** para escribir este capítulo **no se ejecutó nada** (ni Python, ni R, ni Quarto).
> Los valores (80 %, 48.0 %, 1,897 partidos…) se leyeron del **sitio ya generado** (`_site/index.html`, creado el
> 30-sep-2026 a las 23:29, dos minutos después de la última edición de `index.qmd`); coinciden con los que citan los
> capítulos [13a](13a_codigo_datos_dashboard.md) y [19](19_decisiones_y_alternativas.md) y con la verificación 17 de 17.
> Los bloques de R son **ilustrativos**: no se ejecutaron.
>
> **Capítulos relacionados:** las cifras se calculan en [13a](13a_codigo_datos_dashboard.md) (`datos_dashboard.py`); las
> gráficas se dibujan en [13b](13b_codigo_graficas.md) (`graficas.py`); el diseño y la historia del tablero están en
> [13](13_dashboard.md); las decisiones D39–D46, en [19](19_decisiones_y_alternativas.md); la publicación, en
> [14](14_publicacion_en_github.md).

---

## 1. Panorama

### 1.1 Cómo Quarto convierte `index.qmd` en el sitio

`index.qmd` es un documento de **Quarto** (el sucesor de R Markdown, hecho por el mismo grupo, Posit). Es un archivo de
texto que mezcla cuatro clases de contenido:

| Contenido | Cómo se reconoce | Cuántos hay | Quién lo procesa |
|---|---|---|---|
| Encabezado YAML | Entre dos líneas `---` (líneas 1–23) | 1 | Quarto: opciones del formato |
| Texto en Markdown | Todo lo demás: títulos, listas, tablas, bloques `:::` | — | Pandoc (lo convierte a HTML) |
| Código ejecutable | Bloques ```` ```{python} ```` y ```` ```{ojs} ```` | **20** de Python y **6** de Observable JS | Python (al generar) y el navegador (OJS) |
| Código en línea | `` `{python} expresión` `` dentro del texto | **83** | Python (al generar) |

**Qué pasa cuando se ejecuta `quarto render Dashboard-o-pagina`** (es lo que hace César en su computadora y lo que hace
GitHub Actions en cada `push`, con Quarto 1.8.25 y Python 3.10 en ambos casos):

1. **Lee `_quarto.yml`** ([3.1](#31-_quartoyml)): qué archivos renderizar (sólo `index.qmd`), dónde dejar la salida
   (`_site/`), el idioma y que no se muestre el código.
2. **Lee el YAML de `index.qmd`** ([2.1](#21-el-encabezado-yaml)): el formato es `dashboard`, el motor es Jupyter con
   el kernel `python3`, el tema es `cosmo` + `estilos.scss` y hay que pegar `redibujar.html` al final de la página.
3. **Ejecuta los 20 chunks de Python en orden, en un solo kernel** (un solo proceso de Python). El primero
   ([2.2](#22-el-chunk-de-preparación)) importa `datos_dashboard` y `graficas`, llama a `preparar_todo()` (todas las
   cifras; unos 12 segundos según el [capítulo 13a](13a_codigo_datos_dashboard.md)) y define los formateadores. Los demás
   sólo **muestran** algo: una figura de Plotly (`gr.mostrar(...)`) o una tabla (`HTML(...)`). Las **83 expresiones
   en línea** se evalúan en ese mismo kernel, en el orden del documento, y Quarto escribe su valor en el texto.
4. **Pandoc convierte el Markdown a HTML.** Las clases (`.card`, `.valuebox`, `.tabset`, `.sidebar`…) y los encabezados
   le dicen a Quarto cómo armar el tablero.
5. **El formato `dashboard` traduce los encabezados a una cuadrícula:** cada `#` es una página (una pestaña de la barra
   superior), cada `##` una fila, cada `###` una columna; las alturas y anchos de `{height=…}` y `{width=…}` se vuelven
   `grid-template-rows` y `grid-template-columns` de CSS (en el HTML generado se ven `180px 185px 590px` y
   `62fr 38fr`). Cada `::: {.card}` es una tarjeta de Bootstrap/bslib, con su botón de pantalla completa.
6. **Compila el estilo:** Sass junta el tema `cosmo` de Bootswatch con `estilos.scss` en un solo CSS (≈ 457 KB).
7. **Compila las 6 celdas `{ojs}`** (el simulador) a código que **ejecuta el navegador** con el *runtime* de Observable
   (`quarto-ojs-runtime.js`). `ojs_define(...)` deja los datos que calculó Python como JSON dentro de la página.
8. **Pega `redibujar.html`** al final del `<body>` (`include-after-body`).
9. **Escribe la salida** en `_site/`: `index.html` (≈ 5 MB, porque lleva incrustado Plotly.js y ≈ 192 KB de datos del
   simulador) y `index_files/` (el CSS, JavaScript de Bootstrap y el *runtime* de Observable).

**Quién ejecuta qué (importante para la defensa):**

| Qué | Dónde corre | Cuándo |
|---|---|---|
| Los 20 chunks de Python y las 83 expresiones en línea | La máquina que construye el sitio (la de César o el servidor de GitHub Actions) | Una vez, al generar |
| El JavaScript de Plotly que dibuja las 11 gráficas | El navegador de quien visita | Al abrir la página |
| `redibujar.html` | El navegador | Al cargar, al cambiar de pestaña y al cambiar el tamaño |
| Las 6 celdas de Observable JS | El navegador | Al abrir y cada vez que se cambia un selector |

El sitio publicado es **100 % estático**: cuando alguien lo visita, **no corre nada de Python**. Por eso se puede alojar en
GitHub Pages, que sólo sirve archivos ([decisión 5.1](#51-herramienta-quarto-dashboard-con-python) y
[5.9](#59-observable-en-el-navegador-con-datos-precalculados)).

**Equivalencias con lo que se vio en el módulo (R):**

| Este tablero (Quarto + Python) | R Markdown / flexdashboard |
|---|---|
| `quarto render` | `rmarkdown::render()` o el botón *Knit* |
| Motor Jupyter (`jupyter: python3`) | Motor knitr (el de todo `.Rmd`) |
| ```` ```{python} ```` con `#\| include: false` | ```` ```{r setup, include=FALSE} ```` |
| `` `{python} expr` `` | `` `r expr` `` |
| `format: dashboard` | `output: flexdashboard::flex_dashboard` |
| `# Página`, `## Row`, `### Column`, `::: {.card}` | `Página` + `=====`, `Row` + `-----`, `Column`, `### Título` |
| `::: {.valuebox}` | `valueBox()` |
| Observable JS (```` ```{ojs} ````) | Shiny, `crosstalk` o `htmlwidgets` (sección [4](#4-equivalentes-en-r-ilustrativos)) |
| `theme: [cosmo, estilos.scss]` | `theme: cosmo` + `css:` o `bslib::bs_theme()` |
| `_quarto.yml` | `_site.yml` (sitios de R Markdown) |

### 1.2 Mapa del documento

**Seis páginas**, en el orden de una historia (la estructura está justificada en el [capítulo 13](13_dashboard.md) y en
la [decisión 5.4](#54-páginas-narrativas-con-títulos-que-dicen-la-conclusión)):

| # | Página | `id` | Líneas | Filas (alto declarado) | Qué contiene |
|---|---|---|---|---|---|
| 1 | Resumen | `#resumen` | 152–213 | 3 (180 · 185 · 590 px) | Pregunta e hipótesis, 3 *value boxes*, 1 gráfica y 4 conclusiones |
| 2 | ¿Qué ocurre? | `#que-ocurre` | 215–283 | 3 (185 · 500 px · pestañas) | 3 *value boxes*, 2 gráficas, y en pestañas un texto y una tabla |
| 3 | Patrones | `#patrones` | 285–345 | 2 (540 px · pestañas) | 2 gráficas, y en pestañas 1 gráfica, 1 texto y 2 tablas |
| 4 | El modelo | `#modelo` | 347–442 | 3 (300 · 490 px · pestañas) | Diagrama de flujo, un texto, 2 gráficas, y en pestañas 3 gráficas y 2 tablas |
| 5 | Explora un partido | `#simulador` | 444–550 | Barra lateral + 1 columna con 2 filas (150 · 520 px) | El simulador (Observable JS) |
| 6 | Datos y método | `#datos` | 552–669 | 1 fila de pestañas | 8 tarjetas de texto y 2 tablas |

(Las filas con pestañas, `.tabset`, declaran un `height`, pero **el HTML generado no lo aplica**: esa fila queda en `1fr`
y su altura la marca el contenido. Se explica en [2.4](#24-página-2-qué-ocurre) y en la sección
[6](#6-dudas-y-detalles-que-conviene-saber).)

**Los ladrillos del documento**, contados en el archivo:

| Pieza | Cuántas | Dónde |
|---|---|---|
| Páginas (`#`) | 6 | una por sección de la tabla anterior |
| Filas (`##` o `### Row`) | 14 | 3 + 3 + 2 + 3 + 2 + 1 |
| Columnas (`### Column` y `## Column`) | 11 | 2 + 2 + 2 + 4 + 1 |
| Barra lateral (`## {.sidebar}`) | 1 | página 5 |
| Tarjetas escritas con `::: {.card}` | 30 | 3 + 4 + 6 + 9 + 0 + 8 por página |
| Tarjetas que Quarto crea a partir de una celda OJS con `//\| title:` | 2 | página 5 |
| *Value boxes* (`::: {.valuebox}`) | 6 | 3 en la página 1 y 3 en la 2 |
| Chunks de Python | 20 | 1 de preparación + 11 gráficas + 7 tablas + 1 `ojs_define` |
| Chunks de Observable JS | 6 | todos en la página 5 |
| Expresiones en línea `` `{python} …` `` | 83 | 9 + 17 + 5 + 9 + 2 + 41 por página |
| Gráficas de Plotly | 11 | 1 + 2 + 3 + 5 + 0 + 0 por página (más el mapa de calor, que es de Observable Plot) |
| Tablas HTML hechas con `gr.tabla_html` | 7 | temporadas, Elo, calibración de cuotas, métricas, bootstrap, auditoría, verificación |
| Diagramas hechos con HTML y CSS | 1 | "Cómo funciona", página 4 |

**Qué tarjetas tienen gráfica y cuáles tabla** (la guía no debe decir "cada gráfica tiene su tabla": no es cierto):

| Gráfica (función de [13b](13b_codigo_graficas.md)) | Página | ¿Tiene tabla al lado? |
|---|---|---|
| `mejora_sobre_ingenua` | 1 | No directamente; los números están en "Métricas completas" (página 4) |
| `resultados_por_temporada` | 2 | **Sí:** "Tabla por temporada" |
| `resultado_favorito` | 2 | No |
| `resultado_por_diferencia_elo` | 3 | **Sí:** "Tabla: resultado por diferencia de Elo" |
| `calibracion_mercado` | 3 | **Sí:** "Tabla: calibración de las cuotas" |
| `ajuste_poisson` | 3 | No |
| `delta_vs_m0` | 4 | No directamente; los números están en "Métricas completas" |
| `brecha_por_resultado` | 4 | No |
| `efectos` | 4 | No |
| `calibracion_modelos` | 4 | No |
| `modelo_vs_mercado` | 4 | No |

Hay, pues, **5 tablas que acompañan resultados** (temporadas, Elo, calibración de cuotas, "Métricas completas" y
bootstrap) y **2 de documentación** (auditoría y verificación). Sólo 3 de las 11 gráficas tienen su propia vista de tabla.

### 1.3 Diagrama de texto

**A. Dónde encaja `index.qmd` en la cadena del proyecto**

```text
Limpieza de datos.ipynb ─► E0_consolidado.csv ─► wc_predictor.py ┐
                                  │                               ├─► Analisis.ipynb ─► premier_training_data.csv
                                  └───────────────────────────────┘                              │
                                                                                                 ▼
                                    datos_dashboard.py  ◄── lee los dos CSV, importa wc_predictor y lee el notebook
                                       │  preparar_todo() ─► diccionario d (28 entradas)             [capítulo 13a]
                                       ▼
 graficas.py (una función por gráfica + tabla_html) ─────────────┐                                   [capítulo 13b]
                                                                 ▼
 _quarto.yml · estilos.scss · redibujar.html ───────────►  index.qmd  ──► quarto render ──► _site/ ──► GitHub Pages
 requirements.txt (los paquetes que necesita el render)     (este capítulo)
```

**B. Por dentro de `index.qmd`** (las líneas son las del archivo)

```text
index.qmd
 ├─ YAML (1–23) ..................... formato dashboard, tema, include-after-body, botón de GitHub, motor jupyter
 ├─ Chunk de preparación (25–150)
 │    ├─ import datos_dashboard as dd · import graficas as gr
 │    ├─ d = dd.preparar_todo() ───► alias g, fav, met, sim, sens · índices m y bt
 │    ├─ formateadores ............. fecha_es · pct · num · ll · acc · ic · lista · rango
 │    ├─ textos condicionales ...... texto_k · texto_borde · texto_extension_K
 │    └─ 7 tablas HTML ............. temporadas · elo · calibración · métricas · bootstrap · auditoría · verificación
 ├─ # Resumen (152–213) ............ pregunta · 3 value boxes · gráfica · 4 conclusiones
 ├─ # ¿Qué ocurre? (215–283) ....... 3 value boxes · 2 gráficas · [pestañas: texto, tabla]
 ├─ # Patrones (285–345) ........... 2 gráficas · [pestañas: Poisson, "Por qué importan", 2 tablas]
 ├─ # El modelo (347–442) .......... diagrama · resumen · 2 gráficas · [pestañas: 3 gráficas, 2 tablas]
 ├─ # Explora un partido (444–550) . ojs_define(sim=…) ─► selectores ─► partido ─► KPIs · mapa de calor · tabla
 └─ # Datos y método (552–669) ..... [pestañas: 8 tarjetas, con las tablas de auditoría y verificación]
```

**C. Lo que ocurre en el navegador al abrir el sitio**

```text
Se abre _site/index.html
 1. El HTML trae las 6 páginas; sólo la 1 está visible. Las otras 5 son "tab-pane" ocultos (display: none).
 2. Plotly dibuja las 11 figuras. Las que están en páginas o pestañas ocultas "miden" 0 px.
 3. redibujar.html las vuelve a dibujar con Plotly.newPlot cuando se vuelven visibles:
      · al cargar la página (a los 250 ms y otra vez a los 1,500 ms)
      · al cambiar de pestaña (evento shown.bs.tab de Bootstrap, con 80 ms de espera)
      · cuando una gráfica pasa de 0 px a ocupar espacio o cambia más de 40 px de tamaño (ResizeObserver, 120 ms)
 4. El runtime de Observable lee <script type="ojs-define"> (los 380 cruces, ≈ 192 KB) y ejecuta las celdas:
      viewof local ─► viewof visita ─► partido ─► tarjetas de probabilidad · mapa de calor · tabla
    Cada cambio de un selector vuelve a ejecutar sólo lo que depende de él.
```

### 1.4 Tabla de todas las piezas

**A. Archivos de la carpeta `Dashboard-o-pagina/` que explica este capítulo**

| Archivo | Líneas | Para qué sirve | Quién lo usa | Aquí |
|---|---|---|---|---|
| `_quarto.yml` | 12 | Configuración del proyecto: qué renderizar, dónde dejar la salida, idioma y opciones de ejecución | Quarto, antes de leer `index.qmd` | [3.1](#31-_quartoyml) |
| `index.qmd` | 670 | El tablero: estructura, textos y orden de la historia | Quarto | [2](#2-indexqmd-pieza-por-pieza) |
| `estilos.scss` | 970 | Tema visual sobre `cosmo` (Sass) | Quarto lo compila (clave `theme`) | [3.2](#32-estilosscss) |
| `redibujar.html` | 46 | JavaScript que vuelve a dibujar las gráficas de Plotly cuando se hacen visibles | Quarto lo pega al final del `<body>` (`include-after-body`) | [3.3](#33-redibujarhtml) |
| `requirements.txt` | 10 | Paquetes de Python con versiones fijas | `pip install -r`, en la computadora y en GitHub Actions | [3.4](#34-requirementstxt) |
| `.gitignore` | 10 | Qué archivos generados no se guardan en git | git | [3.5](#35-gitignore) |
| `README.md` | 48 | Presentación de la carpeta | Quien lea el repositorio (Quarto no lo procesa: `render:` sólo lista `index.qmd`) | [3.6](#36-readmemd-de-la-carpeta) |
| `datos_dashboard.py` y `graficas.py` | 906 y 374 | Las cifras y las gráficas que usa `index.qmd` | El chunk de preparación | [13a](13a_codigo_datos_dashboard.md), [13b](13b_codigo_graficas.md) |

**B. Piezas de `index.qmd`, en el orden del archivo** ("Se muestra en" nombra la tarjeta tal como aparece en el sitio)

| Pieza | Líneas | Para qué sirve | Quién la usa o de qué depende | Aquí |
|---|---|---|---|---|
| Encabezado YAML | 1–23 | Formato `dashboard`, tema, `redibujar.html`, botón de GitHub, motor Jupyter | Quarto | [2.1](#21-el-encabezado-yaml) |
| **Chunk de preparación** | 25–150 | Importa los módulos, calcula `d` y define formateadores, frases condicionales y 7 tablas HTML | Los otros 19 chunks de Python y las 83 expresiones en línea | [2.2](#22-el-chunk-de-preparación) |
| ↳ `fecha_es`, `pct`, `num`, `ll`, `acc` | 40–56 | Formatean fechas, porcentajes, decimales y buscan métricas | Casi todas las expresiones en línea | 2.2.3 |
| ↳ `ic` | 58–62 | Escribe "diferencia (IC 95 %: a)" con 3 o 4 decimales | **No se usa** (ningún texto la llama desde que se simplificó la lectura del bootstrap) | 2.2.3 |
| ↳ `lista`, `rango` | 81–85 | Escriben "a, b y c" y "mín a máx" | "Evaluación" y "Limitaciones y extensiones" | 2.2.6 |
| ↳ `partidos_temporada` | 87–88 | Texto "380 partidos cada una" | **No se usa** | 2.2.7 |
| ↳ `texto_k`, `texto_borde`, `texto_extension_K` | 89–102 | Frases que cambian según el valor de k y la posición de K en la rejilla | "Variables del modelo" y "Limitaciones y extensiones" | 2.2.7 |
| ↳ 7 tablas HTML | 104–144 | `tabla_temporadas`, `tabla_elo`, `tabla_calibracion`, `tabla_metricas`, `tabla_bootstrap`, `tabla_auditoria`, `tabla_verificacion` | Los 7 chunks `HTML(tabla_…)` | 2.2.8 |
| ↳ `ventaja_elo` (variable) | 67 | Ventaja de jugar en casa en puntos de Elo, redondeada a decenas | **No se usa** (la gráfica recibe `d["ventaja_elo"]` sin redondear) | 2.2.4 |
| **Página 1 · Resumen** | 152–213 | Conclusión primero | | [2.3](#23-página-1-resumen) |
| ↳ Fila 1: tarjeta `.pregunta` | 154–162 | Pregunta, hipótesis y resultado | Texto fijo | 2.3 |
| ↳ Fila 2: 3 *value boxes* | 164–190 | 80 %, 48.0 % y 3 | `d['fraccion_mejora']`, `acc()`; el "3" es texto fijo | 2.3 |
| ↳ Chunk `gr.mejora_sobre_ingenua(met)` | 199–201 | Gráfica de barras de mejora sobre la referencia ingenua | `met` | 2.3 |
| ↳ Tarjeta `.lectura` "Resumen" | 206–213 | Cuatro conclusiones | `n_var_m0`, `acc()`, `brecha_total` | 2.3 |
| **Página 2 · ¿Qué ocurre?** | 215–283 | El fenómeno y por qué es difícil predecirlo | | [2.4](#24-página-2-qué-ocurre) |
| ↳ Fila 1: 3 *value boxes* | 217–247 | 9,540 partidos; 45.6 % gana el local; 54.2 % gana el favorito | `g`, `tc`, `fav`, `ultima_fecha` | 2.4 |
| ↳ Chunk `resultados_por_temporada` | 256–258 | Resultados por temporada | `d["temporadas"]` | 2.4 |
| ↳ Chunk `resultado_favorito` | 266–268 | Resultado según el favorito de Bet365 | `fav` | 2.4 |
| ↳ Tarjeta "Qué significa para el modelo" | 273–277 | Dos conclusiones (difícil de predecir; el COVID no cambia el modelo) | `fav`, `sens`, `ll()` | 2.4 |
| ↳ Chunk `HTML(tabla_temporadas)` | 280–282 | Vista de tabla de la gráfica de temporadas | `tabla_temporadas` | 2.4 |
| **Página 3 · Patrones** | 285–345 | La evidencia que justifica el modelo | | [2.5](#25-página-3-patrones) |
| ↳ Chunk `resultado_por_diferencia_elo` | 294–296 | Resultado según la diferencia de Elo (deciles) | `d["elo"]`, `d["ventaja_elo"]` | 2.5 |
| ↳ Chunk `calibracion_mercado` | 304–306 | Cuotas de Bet365 contra frecuencias | `d["calibracion_mercado"]` | 2.5 |
| ↳ Chunk `ajuste_poisson` | 314–316 | Goles observados contra Poisson | `d["poisson"]` | 2.5 |
| ↳ Tarjeta "Por qué importan estos patrones" | 319–333 | De cada patrón a una decisión del modelo | `e`, `disp` | 2.5 |
| ↳ Chunks `HTML(tabla_elo)` y `HTML(tabla_calibracion)` | 336–338 y 342–344 | Vistas de tabla de las dos gráficas | `tabla_elo`, `tabla_calibracion` | 2.5 |
| **Página 4 · El modelo** | 347–442 | Qué aporta el modelo | | [2.6](#26-página-4-el-modelo) |
| ↳ Tarjeta "Cómo funciona" | 353–367 | Diagrama de flujo en HTML y CSS | `g` | 2.6 |
| ↳ Tarjeta "En pocas palabras" | 371–376 | Cuatro viñetas de resumen | `n_train`, `n_val`, `n_test` | 2.6 |
| ↳ Chunks `delta_vs_m0` y `brecha_por_resultado` | 385–387 y 395–397 | Comparación de especificaciones y descomposición de la brecha | `d["delta_m0"]`, `brecha` | 2.6 |
| ↳ Chunks `efectos`, `calibracion_modelos`, `modelo_vs_mercado` | 405–407, 413–415, 421–423 | Efectos estandarizados, calibración del modelo y del mercado, partido a partido | `d[...]`, `p_ga_*`, `p_empate_*` | 2.6 |
| ↳ Chunks `HTML(tabla_metricas)` y `HTML(tabla_bootstrap)` | 429–431 y 437–439 | Métricas completas y significancia | `tabla_metricas`, `tabla_bootstrap` | 2.6 |
| **Página 5 · Explora un partido** | 444–550 | Simulador interactivo con M0 | | [2.7](#27-página-5-explora-un-partido-el-simulador) |
| ↳ Chunk `ojs_define(sim=…)` | 448–453 | Pasa los 380 cruces de Python al navegador | `sim`, `ultima_fecha`, `dd.K_ELO`, `dd.K_SHRINKAGE` | 2.7 |
| ↳ Celda `viewof local` | 455–458 | Selector del equipo local | `sim.equipos` | 2.7 |
| ↳ Celda `viewof visita` | 460–464 | Selector del visitante (excluye al local) | `sim.equipos`, `local` | 2.7 |
| ↳ Celda `partido` y `fmtp` | 466–472 | Busca el cruce elegido; formatea porcentajes | `sim.partidos`, `local`, `visita` | 2.7 |
| ↳ Bloque `.sim-aviso` | 474–480 | Aviso de uso académico | `ultima_fecha`, `sim['temporada']` | 2.7 |
| ↳ Celda de las tarjetas de probabilidad | 486–496 | Tres tarjetas: gana local, empate, gana visitante | `partido`, `fmtp` | 2.7 |
| ↳ Celda del mapa de calor | 500–521 | Probabilidad de cada marcador (`Plot.cell`) | `partido`, `local`, `visita` | 2.7 |
| ↳ Celda "¿De dónde sale el pronóstico?" | 523–550 | Variables de M0 de cada equipo y notas | `sim.stats`, `sim.k_shrinkage` | 2.7 |
| **Página 6 · Datos y método** | 552–669 | Respaldo: datos, limpieza, variables, evaluación, límites, reproducibilidad | | [2.8](#28-página-6-datos-y-método) |
| ↳ "Datos y procedencia" | 556–570 | Fuente, consolidación y tabla de definiciones | `g`, `est`, `ultima_fecha` | 2.8 |
| ↳ "Limpieza y calidad" (+ chunk `HTML(tabla_auditoria)` en 585–587) | 572–588 | Siete decisiones de limpieza y la auditoría | `d['excluidos']`, `tabla_auditoria` | 2.8 |
| ↳ "Variables del modelo" | 590–601 | Cómo se construye cada variable | `dd.*`, `texto_k`, `diag` | 2.8 |
| ↳ "Evaluación" | 603–610 | Partición, LogLoss, calibración de K y k, mercado | `cfg`, `lista`, `rango`, `d['margen']` | 2.8 |
| ↳ "Limitaciones y extensiones" | 612–629 | Límites y trabajo futuro | `texto_borde`, `texto_extension_K` | 2.8 |
| ↳ "Reproducibilidad" (+ chunk `HTML(tabla_verificacion)` en 634–636) | 631–639 | Verificación 17 de 17 y cómo reproducir | `verificacion_ok`, `tabla_verificacion` | 2.8 |
| ↳ "Glosario" y "Equipo" | 641–656 y 658–669 | 12 términos; integrantes y créditos | Texto fijo | 2.8 |

**C. Lo que está definido pero no se usa** (se detalla en la sección [6](#6-dudas-y-detalles-que-conviene-saber)): la función
`ic()`, las variables `partidos_temporada` y `ventaja_elo`, los campos `fecha` y `k_elo` que `ojs_define` manda al
navegador, la clase `.lectura .ruta` del SCSS y 12 de las 29 variables CSS de `:root`.

## 2. `index.qmd`, pieza por pieza

### 2.1 El encabezado YAML

Líneas 1–23. YAML es un formato de configuración por sangrías (lo que está entre dos líneas `---`). Quarto lo lee antes
que nada.

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
lang: es

format:
  dashboard:
    orientation: rows
    scrolling: true

    theme:
      - cosmo
      - estilos.scss

    include-after-body:
      - redibujar.html

    nav-buttons:
      - icon: github
        href: https://github.com/pitirringo/futbol-apuestas
        aria-label: Repositorio del proyecto en GitHub

jupyter: python3
---
```

**Cada opción:**

| Opción | Qué hace | Evidencia en el HTML generado | Qué pasaría sin ella |
|---|---|---|---|
| `title` | Texto de la barra superior y de la pestaña del navegador | Aparece como título de la barra | La barra quedaría sin nombre |
| `lang: es` | Idioma del documento (atributo `lang` de la página y textos propios de Quarto). También está en `_quarto.yml`: aquí se repite | — (en el HTML el botón de pantalla completa de las tarjetas sigue diciendo "Expand": ese texto viene de bslib y no se traduce) | El navegador y los lectores de pantalla tratarían el texto como inglés |
| `format: dashboard` | Usa el formato **dashboard** de Quarto (existe desde Quarto 1.4; aquí, 1.8.25): páginas, filas, columnas, tarjetas, *value boxes*, barra lateral | El contenedor lleva las clases `quarto-dashboard` y `quarto-dashboard-pages` | Sería una página HTML normal |
| `orientation: rows` | Los encabezados `##` son **filas** y los `###` son **columnas** dentro de cada fila. Es el valor por defecto; se escribe para que se lea | Cada página lleva `data-orientation="rows"` | Igual (es el valor por defecto) |
| `scrolling: true` | La página puede **crecer hacia abajo** y se respetan las alturas en píxeles de las filas. Sin esto (modo por defecto) el tablero se ajusta a la ventana y las filas se reparten el alto | El contenedor lleva la clase `dashboard-scrolling` | Los 150–590 px de cada fila se volverían proporciones y todo se apretaría en una pantalla |
| `theme: [cosmo, estilos.scss]` | Una **lista**: primero el tema Bootswatch `cosmo` (un Bootstrap plano y limpio) y encima `estilos.scss`, que cambia variables y agrega reglas. El orden importa: lo último gana | Un solo CSS compilado de ≈ 457 KB (`bootstrap-<huella>.min.css`) | Se vería el `cosmo` de fábrica, sin tarjetas de vidrio ni colores del proyecto |
| `include-after-body: [redibujar.html]` | Pega el **contenido** del archivo (un `<script>`) justo antes de cerrar `<body>` | El script aparece al final del HTML (busca `window._Plotly`) | Las gráficas de páginas ocultas saldrían mal ([3.3](#33-redibujarhtml)) |
| `nav-buttons` | Agrega botones a la barra superior; aquí uno con el ícono de GitHub que lleva al repositorio. `aria-label` es el texto que leen los lectores de pantalla (el ícono no tiene texto) | — | No habría enlace al repositorio desde la barra |
| `jupyter: python3` | Nombre del **kernel** de Jupyter con el que se ejecutan los chunks de Python. Es el valor por defecto para un documento con chunks de Python; se deja explícito | — | Igual |

**Lo que no está aquí pero también aplica:** las opciones de `_quarto.yml` ([3.1](#31-_quartoyml)): `echo: false`, `warning: false`
y `message: false` (no mostrar el código ni los avisos), y `lang: es`.

**Detalles de sintaxis que conviene saber**

- Una **lista** en YAML se escribe con guiones (`- cosmo`). `theme` e `include-after-body` aceptan una lista aunque
  tengan un solo elemento (`include-after-body` sólo trae uno).
- `format:` contiene al formato y éste a sus opciones (`dashboard:`), por eso `jupyter:` va **fuera** y a la izquierda:
  es una opción del documento, no del formato.
- Las líneas en blanco entre opciones no significan nada; sólo dan aire.

**En R (ilustrativo):** el mismo encabezado con flexdashboard (R Markdown). Las opciones se llaman distinto y el SCSS
hay que compilarlo antes a CSS.

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
lang: es
output:
  flexdashboard::flex_dashboard:
    orientation: rows              # igual que en Quarto
    vertical_layout: scroll        # ≈ scrolling: true (la alternativa es "fill")
    theme:
      version: 4                   # flexdashboard usa Bootstrap 4 con bslib
      bootswatch: cosmo            # ≈ cosmo
    css: estilos.css               # ≈ estilos.scss, ya compilado (sass::sass(sass::sass_file("estilos.scss")))
    includes:
      after_body: redibujar.html   # ≈ include-after-body
    navbar:
      - { icon: fa-github, href: "https://github.com/pitirringo/futbol-apuestas", align: right }
---
```

Decisiones relacionadas: la herramienta ([5.1](#51-herramienta-quarto-dashboard-con-python)), el *layout* y las alturas
([5.2](#52-estructura-y-layout-del-documento)), el tema ([5.6](#56-tema-cosmo-y-estilosscss)) y `redibujar.html`
([5.10](#510-redibujarhtml)).

### 2.2 El chunk de preparación

Líneas 25–150: es el único chunk que **calcula** (importa, llama a `preparar_todo()` y define funciones y variables);
los otros 19 chunks de Python sólo dibujan o muestran lo que éste dejó listo, y las 83 expresiones en línea usan sus
variables. Se explica en diez bloques, en el orden del archivo. Decisiones relacionadas: cifras en línea
([5.3](#53-cifras-en-línea-y-frases-condicionales)), tablas ([5.8](#58-tablas-html-propias-y-vista-de-tabla)) y código oculto
([5.12](#512-código-oculto-y-avisos-apagados)).

#### 2.2.1 La opción del chunk y las importaciones (líneas 25–33)

````markdown
```{python}
#| include: false
# Todas las cifras salen de datos_dashboard.py, que reutiliza el código del equipo
# (wc_predictor.py y las funciones de Analisis.ipynb). Aquí sólo se da formato.
import pandas as pd
from IPython.display import HTML

import datos_dashboard as dd
import graficas as gr
````

- ```` ```{python} ```` abre un chunk de Python; `#| include: false` es una **opción de chunk** (las opciones van en
  líneas que empiezan con `#|`). `include: false` significa: **ejecuta el código, pero no pongas nada en la página**
  (ni el código, ni los resultados, ni los avisos). Es lo mismo que ```` ```{r setup, include=FALSE} ```` en R Markdown.
- `import pandas as pd`: pandas se usa para armar los `DataFrame` de las tablas (`pd.DataFrame`) y para preguntar si un
  valor falta (`pd.isna`). Equivale a `library(dplyr)` / `tibble`.
- `from IPython.display import HTML`: `HTML` es una envoltura que le dice a Jupyter "este texto es HTML": en lugar de
  imprimirlo como texto, lo inserta tal cual en la página. Es lo que hacen los chunks `HTML(tabla_…)`. En R, es el
  `htmltools::HTML()` o el `results = 'asis'` de knitr.
- `import datos_dashboard as dd` y `import graficas as gr` cargan los dos módulos propios que están en la **misma
  carpeta** del `.qmd` (Quarto ejecuta el código con esa carpeta como directorio de trabajo, por eso los encuentra).
  Al importar `datos_dashboard` se ejecuta su código de arriba (rutas, importación silenciosa de `wc_predictor`, lectura
  de parámetros del notebook; ver [13a.1](13a_codigo_datos_dashboard.md#13a1-sección-1-configuración-líneas-1202)); todavía no se
  calcula nada pesado.
- El comentario dice que "aquí sólo se da formato". Es casi cierto: el chunk también hace unas pocas cuentas propias
  (`p_empate_real`, la ordenación de `mt`, la extracción de los p-valores); se señalan abajo.

**En R (ilustrativo):**

```r
library(dplyr); library(knitr)
source("datos_dashboard.R")   # ≈ import datos_dashboard as dd  (habría que escribirlo en R)
source("graficas.R")          # ≈ import graficas as gr
```

#### 2.2.2 `preparar_todo()` y los alias (líneas 35–38)

```python
d = dd.preparar_todo()
g, fav, met, sim, sens = d["general"], d["favorito"], d["metricas"], d["simulador"], d["sensibilidad"]
m = met.set_index(["conjunto", "predictor"])
bt = d["bootstrap"].set_index(["conjunto", "a", "b"])
```

- `d = dd.preparar_todo()` es **la línea que hace casi todo el trabajo**: calcula, en una sola pasada, los 28 elementos
  del diccionario `d` (el [capítulo 13a.8](13a_codigo_datos_dashboard.md#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906)
  los lista). Dura unos 12 segundos; con `@lru_cache` nunca se repite.
- La segunda línea **desempaqueta** cinco entradas con nombres cortos para escribir menos en el texto: `g` (resumen
  general: 9,540 partidos, 26 temporadas), `fav` (el favorito de Bet365), `met` (tabla de métricas: 9 predictores × 2
  periodos = 18 filas), `sim` (los datos del simulador) y `sens` (la sensibilidad sin público).
- `m` y `bt` son las mismas tablas con un **índice compuesto** (`conjunto`, `predictor`; y `conjunto`, `a`, `b`), para poder
  buscar con `m.loc[("Prueba", "M0_Base"), "logloss"]`.

**En R (ilustrativo):** no hace falta el índice compuesto; se filtra.

```r
d <- preparar_todo()                                   # una lista con 28 elementos (≈ dict de Python)
g <- d$general; fav <- d$favorito; met <- d$metricas; sim <- d$simulador; sens <- d$sensibilidad
# m.loc[("Prueba", "M0_Base"), "logloss"]   ≈
met |> filter(conjunto == "Prueba", predictor == "M0_Base") |> pull(logloss)     # 1.033076
```

#### 2.2.3 Los formateadores: `fecha_es`, `pct`, `num`, `ll`, `acc`, `ic` (líneas 40–62)

```python
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
         "septiembre", "octubre", "noviembre", "diciembre"]

def fecha_es(ts):
    return f"{ts.day} de {MESES[ts.month - 1]} de {ts.year}"

def pct(x, dec=1):
    return f"{x * 100:.{dec}f}%"

def num(x, dec=3):
    return f"{x:.{dec}f}"

def ll(conjunto, predictor):
    return m.loc[(conjunto, predictor), "logloss"]

def acc(conjunto, predictor):
    return m.loc[(conjunto, predictor), "aciertos"]

def ic(conjunto, a, b):
    r = bt.loc[(conjunto, a, b)]
    # Con un extremo muy cercano a cero, 3 decimales mostrarían "−0.000"; se usan 4.
    dec = 4 if min(abs(r['ic_inf']), abs(r['ic_sup'])) < 0.0005 else 3
    return f"{r['diferencia']:+.{dec}f} (IC 95 %: {r['ic_inf']:+.{dec}f} a {r['ic_sup']:+.{dec}f})"
```

| Función | Qué hace | Ejemplo real del sitio |
|---|---|---|
| `fecha_es(ts)` | Escribe una fecha en español: día **sin cero inicial**, mes en minúsculas y año. Usa la lista `MESES` y no `strftime("%B")` porque ésta depende del idioma de la computadora (un servidor de GitHub escribiría "September") | `fecha_es(g["fecha_max"])` → "14 de septiembre de 2026" |
| `pct(x, dec=1)` | Porcentaje: multiplica por 100 y pone `dec` decimales y el signo `%` **pegado** al número. `{x * 100:.{dec}f}` es un formato anidado: primero se sustituye `{dec}` (queda `.1f`) y luego se aplica | `pct(acc('Prueba', 'M0_Base'))` → "48.0%" |
| `num(x, dec=3)` | Número con `dec` decimales | `num(1.033076, 4)` → "1.0331" |
| `ll(conjunto, predictor)` | Busca el LogLoss de un predictor en `m` (índice compuesto) | `ll('Prueba', 'M0_Base')` → 1.033076 |
| `acc(conjunto, predictor)` | Busca la tasa de aciertos | `acc('Prueba', 'Ingenua')` → 0.415 |
| `ic(conjunto, a, b)` | Arma el texto "diferencia (IC 95 %: inferior a superior)" con signo (`:+`). Usa 4 decimales si algún extremo del intervalo está a menos de 0.0005 de cero, para no escribir "−0.000". **Ningún texto la llama ya** | — (el caso que la motivó es probablemente M0 − mercado en prueba, con extremo inferior −0.0005) |

Dos observaciones: **(1)** `pct` escribe "48.0%" sin espacio, mientras que los textos escritos a mano usan "95 %" y
"4.49 %" con espacio (ver [6](#6-dudas-y-detalles-que-conviene-saber)); **(2)** `ic` quedó **sin uso** cuando se simplificó
la lectura del bootstrap (el texto ya no repite los intervalos); sigue en el archivo, sin daño.

**En R (ilustrativo):**

```r
meses <- c("enero","febrero","marzo","abril","mayo","junio","julio","agosto",
           "septiembre","octubre","noviembre","diciembre")
fecha_es <- function(ts) {
  ts <- as.Date(ts)
  paste(as.integer(format(ts, "%d")), "de", meses[as.integer(format(ts, "%m"))], "de", format(ts, "%Y"))
}
pct <- function(x, dec = 1) sprintf("%.*f%%", dec, x * 100)      # o scales::percent(x, accuracy = 10^-dec)
num <- function(x, dec = 3) sprintf("%.*f", dec, x)
ll  <- function(conjunto, predictor) met$logloss[met$conjunto == conjunto & met$predictor == predictor]
acc <- function(conjunto, predictor) met$aciertos[met$conjunto == conjunto & met$predictor == predictor]
ic  <- function(conjunto, a, b) {
  r <- bt[bt$conjunto == conjunto & bt$a == a & bt$b == b, ]
  dec <- if (min(abs(r$ic_inf), abs(r$ic_sup)) < 0.0005) 4 else 3
  sprintf("%+.*f (IC 95 %%: %+.*f a %+.*f)", dec, r$diferencia, dec, r$ic_inf, dec, r$ic_sup)
}
```

(`%.*f` toma el número de decimales de un argumento; `%%` escribe un `%` literal; `%+` fuerza el signo.)

#### 2.2.4 Cifras sueltas (líneas 64–69)

```python
brecha_total = bt.loc[("Validación + prueba", "M0_Base", "Mercado_apertura"), "diferencia"]
ultima_fecha = fecha_es(g["fecha_max"])
disp = d["dispersion"]
ventaja_elo = round(d["ventaja_elo"], -1)
n_train, n_val, n_test = d["particiones"]["train"], d["particiones"]["val"], d["particiones"]["test"]
brecha = d["brecha"]
```

| Variable | Qué es | Valor en el sitio | De qué función de [13a](13a_codigo_datos_dashboard.md) viene |
|---|---|---|---|
| `brecha_total` | Diferencia media de LogLoss entre M0 y el mercado de apertura, con validación y prueba juntas (799 partidos); positiva = el mercado es mejor | +0.0159, que el texto muestra como "0.016" | `tabla_bootstrap` ([13a.5.6](13a_codigo_datos_dashboard.md#13a56-_bootstrap-y-tabla_bootstrap)), fila "Validación + prueba" |
| `ultima_fecha` | Fecha del último partido del histórico, escrita en español | "14 de septiembre de 2026" | `resumen_general` ([13a.4.1](13a_codigo_datos_dashboard.md#13a41-resumen_general)) |
| `disp` | Dispersión de Pearson de M0 (χ² / gl): cerca de 1 si los goles se comportan como Poisson | local 1.00; visitante 1.04 | `dispersion_pearson` ([13a.5.11](13a_codigo_datos_dashboard.md#13a511-dispersion_pearson)) |
| `ventaja_elo` | Cuántos puntos de Elo "vale" jugar en casa, redondeado a decenas (`round(x, -1)`) | −50.0 | `ventaja_local_en_elo` ([13a.4.5](13a_codigo_datos_dashboard.md#13a45-ventaja_local_en_elo)). **No se usa en el texto**: la gráfica recibe `d["ventaja_elo"]` sin redondear |
| `n_train`, `n_val`, `n_test` | Partidos de entrenamiento, validación y prueba | 1,897 · 380 · 419 | `particiones` ([13a.3.4](13a_codigo_datos_dashboard.md#13a34-particiones)) |
| `brecha` | Tabla de 3 filas (victoria local, empate, victoria visitante) con el aporte de cada resultado a la brecha M0 − mercado | — | `brecha_por_resultado` ([13a.5.8](13a_codigo_datos_dashboard.md#13a58-brecha_por_resultado)); la usa la gráfica de la página 4 |

**En R (ilustrativo):** `brecha_total <- bt$diferencia[bt$conjunto == "Validación + prueba" & bt$a == "M0_Base" & bt$b == "Mercado_apertura"]`;
`ultima_fecha <- fecha_es(g$fecha_max)`; `disp <- d$dispersion`; `n_train <- d$particiones$train` (y análogos).

#### 2.2.5 Parámetros y diagnósticos que el texto cita (líneas 71–79)

```python
# Parámetros y diagnósticos que el texto cita: se leen del código del equipo, no se escriben a mano.
cfg, tc, est, diag = d["config_notebook"], d["temporadas_completas"], d["estructura"], d["diagnostico_m4"]
ef = d["efectos"].set_index(["ecuacion", "variable"])
p_ga_local = ef.loc[("Goles del local", "ga_away"), "p_valor"]       # goles recibidos por el rival
p_ga_visita = ef.loc[("Goles del visitante", "ga_home"), "p_valor"]
n_var_m0 = len(dd.ESPECIFICACIONES["M0_Base"][0])
n_var_m4 = len(dd.ESPECIFICACIONES["M4_Completo"][0])
elo_inicial = f"{dd.wc_predictor.ELO_INIT:,.0f}"
decaimiento = f"{dd.DECAY_FORMA:g}"
```

| Variable | Qué es | Valor en el sitio | Origen ([13a](13a_codigo_datos_dashboard.md)) |
|---|---|---|---|
| `cfg` | Parámetros que el equipo fija **en el código** de `Analisis.ipynb`: ventana y decaimiento de la forma, rejillas de K y k, temporadas de los pliegues | folds 2021/22, 2022/23, 2023/24 | `configuracion_notebook` ([13a.1.6](13a_codigo_datos_dashboard.md#13a16-configuracion_notebook)) |
| `tc` | Temporadas completas y sus partidos | 25 temporadas de 380 partidos | `temporadas_completas` ([13a.7.2](13a_codigo_datos_dashboard.md#13a72-temporadas_completas)) |
| `est` | Estructura de `E0_consolidado.csv`: columnas totales, comunes y complementarias | 34 · 23 · 11 | `estructura_base` ([13a.7.1](13a_codigo_datos_dashboard.md#13a71-estructura_base)) |
| `diag` | Correlación tiros–tiros a puerta y VIF máximo de M4 | 0.86 · 5.6 | `diagnostico_m4` ([13a.7.3](13a_codigo_datos_dashboard.md#13a73-diagnostico_m4)) |
| `ef` | Efectos estandarizados, indexados por (ecuación, variable) | — | `efectos_estandarizados` ([13a.5.10](13a_codigo_datos_dashboard.md#13a510-efectos_estandarizados)) |
| `p_ga_local` | p-valor del coeficiente `ga_away` (goles que concede el rival) en la ecuación de los goles del **local** | 0.0498 | idem |
| `p_ga_visita` | p-valor de `ga_home` en la ecuación de los goles del **visitante** | 0.506 | idem |
| `n_var_m0`, `n_var_m4` | Número de variables **por ecuación** de M0 y de M4: `ESPECIFICACIONES[...][0]` es la lista de columnas de la ecuación del local | 3 · 9 | `ESPECIFICACIONES` ([13a.1.11](13a_codigo_datos_dashboard.md#13a111-grupos-y-especificaciones)) |
| `elo_inicial` | Elo inicial de un equipo nuevo, con coma de miles: `:,.0f` | "1,500" | `wc_predictor.ELO_INIT` |
| `decaimiento` | Decaimiento de la forma reciente; `:g` quita ceros sobrantes | "0.85" | `DECAY_FORMA` |

La idea del comentario ("se leen del código del equipo, no se escriben a mano") es que si Daniel cambia un parámetro del
notebook o de `wc_predictor.py`, el texto del tablero cambie solo.

**En R (ilustrativo):**

```r
cfg <- d$config_notebook; tc <- d$temporadas_completas; est <- d$estructura; diag <- d$diagnostico_m4
ef <- d$efectos
p_ga_local  <- ef$p_valor[ef$ecuacion == "Goles del local"     & ef$variable == "ga_away"]
p_ga_visita <- ef$p_valor[ef$ecuacion == "Goles del visitante" & ef$variable == "ga_home"]
n_var_m0 <- length(ESPECIFICACIONES$M0_Base[[1]])         # 3 variables en la ecuación del local
elo_inicial <- format(ELO_INIT, big.mark = ",")           # "1,500"
decaimiento <- format(DECAY_FORMA)                        # "0.85"  (≈ :g)
```

#### 2.2.6 `lista` y `rango` (líneas 81–85)

```python
def lista(xs):
    return xs[0] if len(xs) == 1 else ", ".join(xs[:-1]) + " y " + xs[-1]

def rango(xs):
    return f"{min(xs):g} a {max(xs):g}"
```

- `lista` escribe una enumeración en español: con un solo elemento lo devuelve tal cual; con varios, une todos menos el
  último con comas y agrega " y " antes del último. `lista(['2021/22', '2022/23', '2023/24'])` → "2021/22, 2022/23 y
  2023/24" (así aparece en "Evaluación"). Con una lista **vacía** fallaría (`xs[-1]`); no ocurre porque el notebook trae
  tres pliegues.
- `rango` escribe "mínimo a máximo". `:g` elimina el ".0" de los flotantes: `rango([15.0, ..., 45.0])` → "15 a 45".
  Se usa para las rejillas de K ("15 a 45") y de k ("0 a 20").

**En R (ilustrativo):**

```r
lista <- function(xs) knitr::combine_words(xs, and = " y ", oxford_comma = FALSE)   # "2021/22, 2022/23 y 2023/24"
rango <- function(xs) sprintf("%g a %g", min(xs), max(xs))                           # "15 a 45"
```

#### 2.2.7 Las frases condicionales (líneas 87–102)

```python
partidos_temporada = (f"{tc['partidos_max']} partidos cada una" if tc["partidos_min"] == tc["partidos_max"]
                      else f"entre {tc['partidos_min']} y {tc['partidos_max']} partidos")
texto_k = f"k = {dd.K_SHRINKAGE:g}" + (", es decir, sin mezcla" if dd.K_SHRINKAGE == 0 else "")
rejilla_K, rejilla_k = cfg["rejilla_k_elo"], cfg["rejilla_k_shrinkage"]
# Si el K elegido quedó en un extremo de la rejilla, el óptimo podría estar fuera de ella.
borde_K = "inferior" if dd.K_ELO == min(rejilla_K) else "superior" if dd.K_ELO == max(rejilla_K) else None
texto_borde = {
    "inferior": "El K elegido quedó en el borde inferior de la rejilla, así que un valor menor podría ser aún mejor.",
    "superior": "El K elegido quedó en el borde superior de la rejilla, así que un valor mayor podría ser aún mejor.",
    None: "",
}[borde_K]
texto_extension_K = {
    "inferior": f"Ampliar la búsqueda de K por debajo de {min(rejilla_K):g} y optimizar",
    "superior": f"Ampliar la búsqueda de K por encima de {max(rejilla_K):g} y optimizar",
    None: "Optimizar",
}[borde_K]
```

Estas son las **frases que cambian solas según los datos**. Son las únicas cuatro con esa propiedad en el chunk (más la
nota del simulador en [2.7](#27-página-5-explora-un-partido-el-simulador) y la frase de verificación en
[2.8](#28-página-6-datos-y-método)).

| Variable | Lógica | Valor hoy | Dónde aparece |
|---|---|---|---|
| `partidos_temporada` | Si todas las temporadas completas tienen los mismos partidos: "N partidos cada una"; si no: "entre A y B partidos" | "380 partidos cada una" | **Nunca** (definida, sin uso) |
| `texto_k` | "k = valor" y, **sólo si k vale 0**, agrega ", es decir, sin mezcla" | "k = 0, es decir, sin mezcla" | Tarjeta "Variables del modelo" |
| `rejilla_K`, `rejilla_k` | Las listas de valores probados para K (Elo) y para k (*shrinkage*). **Ojo:** los nombres sólo difieren en mayúscula | K de 15 a 45; k de 0 a 20 (35 combinaciones) | "Evaluación" y "Limitaciones" |
| `borde_K` | "inferior" si el K elegido es el menor de la rejilla; "superior" si es el mayor; `None` si queda adentro (cadena de dos `if … else`) | "inferior" (K = 15 = mínimo de la rejilla) | Interno |
| `texto_borde` | Un **diccionario** de tres entradas (`"inferior"`, `"superior"`, `None`) y se busca con `[borde_K]` | "El K elegido quedó en el borde inferior de la rejilla, así que un valor menor podría ser aún mejor." | "Limitaciones" |
| `texto_extension_K` | Igual: cambia el verbo y el lado según el borde; si K quedó adentro, sólo "Optimizar" | "Ampliar la búsqueda de K por debajo de 15 y optimizar" | "Posibles extensiones" |

**Por qué existen:** protegen al texto de decir algo falso si cambia la calibración. Si alguien repitiera la rejilla y K
quedara en el centro, el tablero dejaría de decir "un valor menor podría ser aún mejor". Es una **advertencia honesta**:
con K = 15 en el borde inferior no se puede afirmar que sea el óptimo (el capítulo 19 y el [capítulo 9](09_evaluacion_y_validacion.md)
detallan la calibración; una comparación hecha por la guía con la configuración anterior K = 30, k = 10 dio diferencias no
significativas, así que la conclusión no depende de ese valor).

**En R (ilustrativo):**

```r
partidos_temporada <- if (tc$partidos_min == tc$partidos_max) paste(tc$partidos_max, "partidos cada una") else
                      paste("entre", tc$partidos_min, "y", tc$partidos_max, "partidos")
texto_k <- paste0("k = ", format(K_SHRINKAGE), if (K_SHRINKAGE == 0) ", es decir, sin mezcla" else "")
borde_K <- if (K_ELO == min(rejilla_K)) "inferior" else if (K_ELO == max(rejilla_K)) "superior" else "ninguno"
texto_borde <- switch(borde_K,        # switch() elige por nombre; el último argumento sin nombre es el "por defecto"
  inferior = "El K elegido quedó en el borde inferior de la rejilla, así que un valor menor podría ser aún mejor.",
  superior = "El K elegido quedó en el borde superior de la rejilla, así que un valor mayor podría ser aún mejor.",
  "")
texto_extension_K <- switch(borde_K,
  inferior = paste0("Ampliar la búsqueda de K por debajo de ", min(rejilla_K), " y optimizar"),
  superior = paste0("Ampliar la búsqueda de K por encima de ", max(rejilla_K), " y optimizar"),
  "Optimizar")
```

#### 2.2.8 Las siete tablas HTML (líneas 104–144)

Cada tabla se **arma una vez aquí** (como texto HTML) y se muestra más adelante con `HTML(tabla_…)`. El comentario de la
línea 104 dice para qué: "vista tabular de cada gráfica, para quien no puede o no quiere leer la gráfica". Todas pasan
por `gr.tabla_html(df)` ([capítulo 13b](13b_codigo_graficas.md)): convierte un `DataFrame` en
`<div class="tabla-contenedor"><table class="tabla">…</table></div>` **escapando** cada celda con `html.escape` (porque
los textos vienen de archivos de datos). Las clases `tabla-contenedor` y `tabla` tienen estilo en `estilos.scss`
([3.2](#32-estilosscss)).

**Primeras tres: vistas de tabla de gráficas** (líneas 104–123)

```python
# Tablas (vista tabular de cada gráfica, para quien no puede o no quiere leer la gráfica)
t = d["temporadas"]
tabla_temporadas = gr.tabla_html(pd.DataFrame({
    "Temporada": t["etiqueta"], "Partidos": t["partidos"],
    "Local": t["pct_local"].map(pct), "Empate": t["pct_empate"].map(pct), "Visitante": t["pct_visita"].map(pct),
    "Ventaja local (pp)": t["ventaja_local_pp"].map(lambda v: f"{v:+.1f}"),
    "Goles local": t["goles_local"].map(lambda v: f"{v:.2f}"), "Goles visitante": t["goles_visita"].map(lambda v: f"{v:.2f}"),
}))
e = d["elo"]
tabla_elo = gr.tabla_html(pd.DataFrame({
    "Decil": e["grupo"] + 1,
    "Diferencia de Elo": [f"{a:+.0f} a {b:+.0f}" for a, b in zip(e["elo_min"], e["elo_max"])],
    "Partidos": e["partidos"], "Gana local": e["pct_local"].map(pct),
    "Empate": e["pct_empate"].map(pct), "Gana visitante": e["pct_visita"].map(pct),
}))
c = d["calibracion_mercado"]
tabla_calibracion = gr.tabla_html(pd.DataFrame({
    "Probabilidad implícita (promedio del grupo)": c["prob_predicha"].map(pct),
    "Frecuencia observada": c["frecuencia"].map(pct), "Casos": c["n"].map(lambda v: f"{v:,}"),
}))
```

- Se construye un `pd.DataFrame` a partir de un **diccionario**: cada llave es el nombre de una columna y cada valor, su
  contenido (una serie). `serie.map(pct)` aplica `pct` a cada elemento (≈ `purrr::map_chr()` o `sapply()` en R).
- `tabla_temporadas`: una fila por temporada completa (25), con `Local/Empate/Visitante` en porcentaje, la "ventaja
  local" en **puntos porcentuales con signo** (`{v:+.1f}`: % de victorias locales menos % de visitantes; positivo = ganó
  más el local) y los goles medios con dos decimales. Es la vista de tabla de "Jugar en casa siempre ayuda… salvo sin
  público".
- `tabla_elo`: una fila por **decil** de diferencia de Elo (`grupo + 1` para contar de 1 a 10; `grupo` viene de 0), con
  el rango del decil escrito como "mínimo a máximo" y signo (`:+.0f` = entero con signo; los deciles de desventaja
  quedan con negativos) y los tres resultados en porcentaje.
- `tabla_calibracion`: por grupo de probabilidad implícita de Bet365, la probabilidad promedio, la frecuencia observada y
  el número de casos con **coma de miles** (`{v:,}`).

**Las otras cuatro** (líneas 124–144)

```python
orden = ["Uniforme", "Ingenua", "M0_Base", "M1_Forma", "M2_Tiros", "M3_SOT", "M4_Completo",
         "Mercado_apertura", "Mercado_cierre"]
mt = met.assign(o=met["predictor"].map(orden.index)).sort_values(["conjunto", "o"], ascending=[False, True])
tabla_metricas = gr.tabla_html(pd.DataFrame({
    "Periodo": mt["conjunto"], "Predictor": mt["nombre"], "Partidos": mt["partidos"],
    "LogLoss": mt["logloss"].map(lambda v: f"{v:.4f}"),
    "Prob. media al resultado real": mt["prob_resultado_real"].map(pct),
    "Aciertos": mt["aciertos"].map(pct), "P(empate) media": mt["p_empate_media"].map(pct),
    "MAE goles": mt["mae_promedio"].map(lambda v: "—" if pd.isna(v) else f"{v:.3f}"),
}))
b = d["bootstrap"]
tabla_bootstrap = gr.tabla_html(pd.DataFrame({
    "Periodo": b["conjunto"],
    "Comparación (A − B)": [f"{dd.NOMBRES[x]} − {dd.NOMBRES[y]}" for x, y in zip(b["a"], b["b"])],
    "Partidos": b["partidos"], "Diferencia de LogLoss": b["diferencia"].map(lambda v: f"{v:+.4f}"),
    "IC 95 %": [f"{lo:+.4f} a {hi:+.4f}" for lo, hi in zip(b["ic_inf"], b["ic_sup"])],
    "¿Distinta de cero?": b["significativa"].map({True: "Sí", False: "No"}),
}))
tabla_auditoria = gr.tabla_html(d["auditoria"])
v = d["verificacion"]
tabla_verificacion = gr.tabla_html(v.assign(Coincide=v["Coincide"].map({True: "✓", False: "✗"})))
verificacion_ok = bool(v["Coincide"].all())
```

- **Orden de `tabla_metricas`.** `orden` fija el orden de los 9 predictores (de los más simples a los más informados).
  `met["predictor"].map(orden.index)` convierte cada nombre en su posición, `assign(o=…)` la guarda en una columna `o`
  y `sort_values(["conjunto", "o"], ascending=[False, True])` ordena por periodo en **orden descendente** (como "Validación" va
  después de "Prueba" en el alfabeto, **Validación sale primero**) y, dentro de cada periodo, por posición. Resultado: 18
  filas, 9 de validación y 9 de prueba.
- `tabla_metricas` muestra el LogLoss con **4 decimales** (las diferencias están en la tercera cifra) y deja "—" donde
  no hay MAE de goles: sólo lo tienen los cinco modelos, no el azar, la referencia ingenua ni el mercado
  (`pd.isna(v)` pregunta si el valor falta).
- `tabla_bootstrap`: nombres legibles con `dd.NOMBRES` ("M0 · Base − Mercado · Apertura"), diferencia con signo y 4
  decimales, intervalo "−0.0005 a +0.0264" y "Sí/No" según `significativa` (el intervalo no incluye el cero). Son 7 filas
  (la tabla real se muestra en [2.6](#26-página-4-el-modelo)).
- `tabla_auditoria`: el `DataFrame` de `auditoria_datos()` tal cual (10 filas; [13a.7.5](13a_codigo_datos_dashboard.md#13a75-auditoria_datos)).
- `tabla_verificacion`: el `DataFrame` de `tabla_verificacion()` (17 filas) cambiando el booleano `Coincide` por **✓ o ✗**;
  `verificacion_ok` guarda si **todas** coinciden (`.all()`), y es lo que decide la frase "todas coinciden" o "HAY
  DIFERENCIAS" de la página 6.

**En R (ilustrativo):** el equivalente de `tabla_html` es `knitr::kable()`, que ya **escapa** el HTML por defecto.

```r
library(dplyr); library(knitr)
tabla_html <- function(df, clase = "tabla")             # ≈ gr.tabla_html
  paste0('<div class="tabla-contenedor">',
         kable(df, format = "html", escape = TRUE, table.attr = paste0('class="', clase, '"')),
         '</div>')

tabla_temporadas <- d$temporadas |>
  transmute(Temporada = etiqueta, Partidos = partidos,
            Local = pct(pct_local), Empate = pct(pct_empate), Visitante = pct(pct_visita),
            `Ventaja local (pp)` = sprintf("%+.1f", ventaja_local_pp),
            `Goles local` = sprintf("%.2f", goles_local), `Goles visitante` = sprintf("%.2f", goles_visita)) |>
  tabla_html()

orden <- c("Uniforme","Ingenua","M0_Base","M1_Forma","M2_Tiros","M3_SOT","M4_Completo","Mercado_apertura","Mercado_cierre")
tabla_metricas <- met |>
  mutate(o = match(predictor, orden)) |>
  arrange(desc(conjunto), o) |>                                   # ≈ sort_values(..., ascending=[False, True])
  transmute(Periodo = conjunto, Predictor = nombre, Partidos = partidos,
            LogLoss = sprintf("%.4f", logloss), `Prob. media al resultado real` = pct(prob_resultado_real),
            Aciertos = pct(aciertos), `P(empate) media` = pct(p_empate_media),
            `MAE goles` = ifelse(is.na(mae_promedio), "—", sprintf("%.3f", mae_promedio))) |>
  tabla_html()

tabla_verificacion <- d$verificacion |> mutate(Coincide = ifelse(Coincide, "✓", "✗")) |> tabla_html()
verificacion_ok <- all(d$verificacion$Coincide)                   # ≈ bool(v["Coincide"].all())
```

#### 2.2.9 Lo que falta para las frases de la calibración (líneas 145–149)

El chunk termina con las variables que necesita la frase de calibración de la página 4 (`verificacion_ok`, la
última línea del bloque anterior, ya se explicó):

```python
p_empate_modelo = m.loc[("Prueba", "M0_Base"), "p_empate_media"]
p_empate_mercado = m.loc[("Prueba", "Mercado_apertura"), "p_empate_media"]
y_test = dd.probabilidades_por_conjunto()["Prueba"]["y"]
p_empate_real = float((y_test == 1).mean())
```

- `p_empate_modelo` y `p_empate_mercado`: la probabilidad **promedio** de empate que cada predictor asignó en los 419
  partidos de prueba: **23.6 %** y **24.5 %**.
- `y_test`: el resultado observado de cada partido de prueba, codificado 0 = gana el local, 1 = empate, 2 = gana el
  visitante. `dd.probabilidades_por_conjunto()` ya se calculó dentro de `preparar_todo()`, y `@lru_cache` la devuelve sin
  repetir el cálculo.
- `p_empate_real`: la **frecuencia real** de empates en la prueba: `(y_test == 1).mean()` es la proporción de unos (en R,
  `mean(y_test == 1)`): **28.2 %**. Las tres cifras sostienen la frase de la tarjeta "Calibración: modelo vs. mercado".

#### 2.2.10 Todas las variables del chunk, de un vistazo

| Variable | Valor en el sitio | Se usa en |
|---|---|---|
| `d` | diccionario de 28 entradas | gráficas y tablas |
| `g` | 9,540 partidos · 26 temporadas · última fecha 14 de septiembre de 2026 | páginas 2, 4, 6 |
| `fav` | el favorito de Bet365 gana 54.2 % | página 2 |
| `met`, `m` | métricas de 9 predictores × 2 periodos | páginas 1 y 4 |
| `sim` | 20 equipos · 380 cruces · temporada 2026/27 | página 5 |
| `sens` | 472 partidos sin público | página 2 |
| `bt`, `brecha_total` | tabla del bootstrap; +0.0159 | página 1 |
| `ultima_fecha` | "14 de septiembre de 2026" | páginas 2, 5, 6 |
| `disp` | 1.00 y 1.04 | página 3 |
| `n_train`, `n_val`, `n_test` | 1,897 · 380 · 419 | páginas 4 y 6 |
| `brecha` | tabla de 3 filas | página 4 (gráfica) |
| `cfg`, `tc`, `est`, `diag` | parámetros del notebook; 25 temporadas; 34/23/11 columnas; 0.86 y 5.6 | páginas 2 y 6 |
| `p_ga_local`, `p_ga_visita` | 0.0498 y 0.506 | página 4 |
| `n_var_m0`, `n_var_m4` | 3 y 9 | páginas 1 y 6 |
| `elo_inicial`, `decaimiento` | "1,500" y "0.85" | página 6 |
| `texto_k`, `texto_borde`, `texto_extension_K` | frases condicionales | página 6 |
| `rejilla_K`, `rejilla_k` | 15 a 45 y 0 a 20 | página 6 |
| `tabla_*` (7) | HTML de las tablas | páginas 2, 3, 4 y 6 |
| `verificacion_ok` | `True` | página 6 |
| `p_empate_modelo`, `p_empate_mercado`, `p_empate_real` | 23.6 %, 24.5 %, 28.2 % | página 4 |
| `ic`, `partidos_temporada`, `ventaja_elo` (la variable) | — | **no se usan** |
| `t`, `e`, `c`, `b`, `v`, `mt`, `orden`, `borde_K`, `y_test`, `ef` | auxiliares | sólo dentro del chunk, salvo `e` (que reutiliza la página 3) |

Una advertencia de estilo: nombres de una letra como `e`, `t`, `c`, `b`, `v` y `m` son cómodos pero fáciles de pisar;
`e` se reutiliza en la página 3 (`e['pct_local']`) y por eso **no debe renombrarse** en el chunk sin buscar sus usos.

### 2.3 Página 1: Resumen

Líneas 152–213. Es la página de la **conclusión primero** (la "lectura en 20 segundos" del [capítulo 13](13_dashboard.md)):
quien sólo mire esta página ya sabe la pregunta, la respuesta y las tres cifras que la sostienen.

```text
┌──────────────────────────────────────── # Resumen {#resumen} ────────────────────────────────────────┐
│ ## Row {height=180px}   [ tarjeta .pregunta: Pregunta · Hipótesis · Resultado ]                      │
│ ## Row {height=185px}   [ value box 80 % ]  [ value box 48.0 % ]  [ value box 3 ]                    │
│ ## Row {height=590px}   ┌ ### Column {width=62%} ────────────────┐ ┌ ### Column {width=38%} ───────┐ │
│                         │ tarjeta: gráfica mejora_sobre_ingenua  │ │ tarjeta .lectura (4 puntos)   │ │
│                         └────────────────────────────────────────┘ └───────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**El encabezado de página.** `# Resumen {#resumen}`: un `#` (nivel 1) crea una **página** (una pestaña de la barra
superior; el texto es el nombre de la pestaña). `{#resumen}` fija el **identificador** de la página. Sin él, Quarto lo
inventaría desde el texto; con "¿Qué ocurre?" saldría con acentos y la página se abría en blanco cuando se entraba por
`#qué-ocurre` (problema real, tabla de [13.10](13_dashboard.md)); por eso las seis páginas llevan un `id` explícito y sin
acentos: `#resumen`, `#que-ocurre`, `#patrones`, `#modelo`, `#simulador`, `#datos`. En el HTML cada página es un
`<div id="resumen" class="dashboard-page tab-pane …">` con su pestaña `tab-resumen`.

**Filas y columnas.** `## Row {height=180px}` abre una fila de 180 píxeles. `### Column {width=62%}` abre una columna
que ocupa el 62 % del ancho de su fila. En el HTML generado la página es una **cuadrícula de CSS** con
`grid-template-rows: 180px 185px 590px` y, en la tercera fila, `grid-template-columns: 62fr 38fr`.

#### 2.3.1 Fila 1: la tarjeta de la pregunta (líneas 154–162)

```markdown
## Row {height=180px}

::: {.card .pregunta}
**Pregunta.** ¿Qué tan bien anticipan el resultado de un partido de la Premier League (gana el local, empate o gana el visitante) las estadísticas disponibles antes del encuentro, frente a las probabilidades implícitas en las cuotas de apuestas?

**Hipótesis.** Las estadísticas sí contienen información útil, pero el mercado, que además tiene información ventajosa, la aprovecha mejor.

**Resultado: ** El modelo se acerca mucho al mercado, pero no lo supera.
:::
```

- `::: {.card .pregunta}` … `:::` es un **bloque con clases** (*fenced div* de Pandoc). `.card` lo vuelve una tarjeta del
  tablero; `.pregunta` es una clase propia que `estilos.scss` pinta con un **borde izquierdo azul** (`--modelo`) y fondo
  de vidrio ([3.2](#32-estilosscss)). No lleva `title`, así que no tiene encabezado.
- Todo el texto es **fijo** (ninguna expresión en línea): es el planteamiento, no una cifra.
- `**Resultado: **` tiene un espacio dentro de los asteriscos; en Markdown eso se tolera aquí y se ve en negritas.
- **Pregunta del tablero frente a la del reporte.** El tablero pregunta cuánto anticipan las estadísticas frente a las
  cuotas; el reporte PDF pregunta en qué medida las variables históricas de fortaleza y desempeño reciente mejoran la
  capacidad predictiva y cómo se compara con las cuotas de apertura. Son formulaciones **complementarias**, no
  contradictorias (cómo contestar si preguntan por la diferencia: [capítulo 20](20_el_reporte_entregado.md)).

#### 2.3.2 Fila 2: los tres *value boxes* (líneas 164–190)

```markdown
## Row {height=185px}

::: {.valuebox icon="bullseye" color="#eef5fd"}
Ventaja del mercado que alcanza el modelo

`{python} pct(d['fraccion_mejora'], 0)`

De cada 100 puntos que el mercado mejora sobre una referencia ingenua, el modelo logra `{python} f"{d['fraccion_mejora'] * 100:.0f}"`
:::

::: {.valuebox icon="check2-circle" color="#eef5fd"}
Partidos acertados por el modelo

`{python} pct(acc('Prueba', 'M0_Base'))`

Mercado: `{python} pct(acc('Prueba', 'Mercado_apertura'))`

Referencia ingenua: `{python} pct(acc('Prueba', 'Ingenua'))`
:::

::: {.valuebox icon="sliders" color="#f3f2ee"}
Variables en el mejor modelo

3

Elo y goles a favor y en contra de la temporada.
:::
```

**Cómo se lee un *value box* de Quarto.** Es un bloque `::: {.valuebox}` con **tres partes**, separadas por líneas en
blanco: el **primer párrafo** es el título (el SCSS lo pone en mayúsculas y letra pequeña), el **segundo** es el valor grande y los
**demás** son texto de apoyo. `icon` es el nombre de un ícono de **Bootstrap Icons** (`bullseye` es una diana,
`check2-circle` una palomita en un círculo, `sliders` unos controles; en el HTML son `<i class="bi bi-bullseye">`).
`color` pone el fondo.

| Caja | Expresiones | Valor en el sitio | Qué cifra es y de dónde sale |
|---|---|---|---|
| **Ventaja del mercado que alcanza el modelo** | `pct(d['fraccion_mejora'], 0)` y `f"{d['fraccion_mejora'] * 100:.0f}"` | **80%** y **80** | `fraccion_de_mejora` ([13a.5.5](13a_codigo_datos_dashboard.md#13a55-fraccion_de_mejora)): (LogLoss ingenua − LogLoss M0) / (LogLoss ingenua − LogLoss mercado), en la prueba. Con las cifras de la tabla del bootstrap: la mejora de M0 sobre la ingenua es 0.0537 y la del mercado ≈ 0.0668 (1.0868 − 1.0200), así que 0.0537 / 0.0668 ≈ 0.80. Es "qué parte del camino entre la ingenua y el mercado recorre el modelo" |
| **Partidos acertados por el modelo** | `pct(acc('Prueba', 'M0_Base'))`, `pct(acc('Prueba', 'Mercado_apertura'))`, `pct(acc('Prueba', 'Ingenua'))` | **48.0%**, 48.9% y 41.5% | Columna `aciertos` de `tabla_metricas` ([13a.5.4](13a_codigo_datos_dashboard.md#13a54-tabla_metricas)): la proporción de los 419 partidos de prueba en los que el resultado con **mayor probabilidad** fue el que ocurrió |
| **Variables en el mejor modelo** | ninguna: el **"3" está escrito a mano** | 3 | Es el número de variables por ecuación de M0, el mismo valor que `n_var_m0` (que sí se calcula y se usa en la tarjeta "Resumen"). Si M0 cambiara, esta caja no lo notaría |

**Dos observaciones honestas sobre las cajas:**

1. **El "3" no sale del código** (el [capítulo 13a.9](13a_codigo_datos_dashboard.md#13a9-detalles-raros-y-comentarios-desactualizados)
   lo lista entre los datos escritos a mano). Es correcto hoy; si se quisiera, bastaría poner `` `{python} n_var_m0` ``.
2. **El atributo `color` no se ve.** Quarto lo convierte en un fondo en línea (`style="background: #eef5fd;"`), pero
   `estilos.scss` declara `.bslib-value-box { background: linear-gradient(…) !important; }`, y una regla con `!important`
   de una hoja de estilo **gana a un estilo en línea sin `!important`** (comprobado en el CSS compilado). Lo que se ve es
   el vidrio translúcido, no los tintes pastel; el capítulo 13 describe los tintes ("azul claro = modelo…") como si se
   vieran. No afecta ninguna cifra; sólo es una descripción que ya no aplica ([6](#6-dudas-y-detalles-que-conviene-saber)).

Pie de cifra: la caja de "aciertos" también ilustra por qué el tablero evalúa **probabilidades y no sólo aciertos**: el
modelo (48.0 %) y el mercado (48.9 %) casi empatan en aciertos, y en la tarjeta de la página 2 se explica que incluso el
favorito de las cuotas sólo gana 54 % de las veces.

**En R (ilustrativo):** en flexdashboard cada caja es un `###` con un `valueBox()`; sólo admite un `value` y un `caption`,
así que las líneas de apoyo van dentro del `caption` como HTML.

```r
### Ventaja del mercado que alcanza el modelo
valueBox(pct(d$fraccion_mejora, 0),
         caption = htmltools::HTML(paste0("De cada 100 puntos que el mercado mejora sobre una referencia ingenua, ",
                                          "el modelo logra ", round(d$fraccion_mejora * 100))),
         icon = "fa-bullseye", color = "info")          # color: "primary", "info", "success", "warning", "danger" o un CSS
```

#### 2.3.3 Fila 3, columna izquierda: la gráfica principal (líneas 192–202)

````markdown
## Row {height=590px}

### Column {width=62%}

::: {.card title="El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo"}
<p class="subtitulo">Cuánto mejora cada predictor frente a una referencia ingenua. <br><span class="leyenda"><i class="muestra" style="background:#898781;opacity:.4"></i>Validación</span><span class="leyenda"><i class="muestra" style="background:#898781"></i>Prueba</span></p>

```{python}
gr.mostrar(gr.mejora_sobre_ingenua(met))
```
:::
````

- `title="…"` es el **título de la tarjeta** y dice la **conclusión**, no el tipo de gráfica ([decisión
  5.4](#54-páginas-narrativas-con-títulos-que-dicen-la-conclusión)).
- `<p class="subtitulo">…</p>` es HTML directo dentro del Markdown: un subtítulo con la **leyenda hecha a mano**. Los
  `<span class="leyenda">` con un `<i class="muestra">` son cuadritos de color con su etiqueta ("Validación" en gris al
  40 % de opacidad y "Prueba" en gris pleno). La leyenda va aquí y no dentro de Plotly porque `gr.mostrar()` la
  desactiva (`showlegend=False`): en páginas ocultas Plotly dibujaba las leyendas encimadas
  ([13b](13b_codigo_graficas.md)).
- El chunk `gr.mostrar(gr.mejora_sobre_ingenua(met))` construye la figura con `met` (barras agrupadas: la mejora de
  LogLoss de cada predictor respecto a la referencia ingenua, en validación y en prueba) y `mostrar` la imprime sin
  barra de herramientas, zoom ni leyenda. Los detalles de la gráfica están en el [capítulo 13b](13b_codigo_graficas.md).
- Los números exactos de esta gráfica están en la tarjeta "Métricas completas" de la página 4 (no tiene tabla propia).

**En R (ilustrativo):** una tarjeta con subtítulo y gráfica sería un `###` con un chunk que devuelve las dos cosas.

```r
### El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo {data-width=620}
htmltools::tagList(
  htmltools::p(class = "subtitulo", "Cuánto mejora cada predictor frente a una referencia ingenua."),
  plotly::ggplotly(mejora_sobre_ingenua(met))      # ≈ gr.mostrar(gr.mejora_sobre_ingenua(met))
)
```

#### 2.3.4 Fila 3, columna derecha: la tarjeta de lectura (líneas 204–213)

```markdown
### Column {width=38%}

::: {.card .lectura title="Resumen"}
1. **Las estadísticas sí anticipan resultados.** Con sólo `{python} n_var_m0` variables, el modelo acierta `{python} pct(acc('Prueba', 'M0_Base'))` de los partidos de prueba, contra `{python} pct(acc('Prueba', 'Ingenua'))` de un pronóstico básico. La mejora es estadísticamente significativa.
2. **El mercado sabe un poco más.** Sus cuotas pronostican mejor en validación y en prueba. La diferencia es pequeña (`{python} f"{brecha_total:.3f}"` de LogLoss con validación y prueba juntas), pero real.
3. **Más variables no es mejor.** Otros modelos con más variables como Forma reciente y tiros ayudaron en validación, pero no en prueba. El modelo base M0 fue el más robusto.
4. **Conclusión.** Las cuotas del mercado ya incorporan la estadística pública, y algo más. Nuestro modelo simple y transparente se acerca, pero no le gana al mercado de forma sistemática.
:::
```

`.lectura` le da a la lista numerada márgenes y espaciado propios (`estilos.scss`). Las **cuatro conclusiones**, con sus
expresiones (`n_var_m0` → 3; `pct(acc('Prueba','M0_Base'))` → 48.0%; `pct(acc('Prueba','Ingenua'))` → 41.5%;
`brecha_total` → 0.0159, que se escribe "0.016") y la **evidencia** que respalda cada frase (las frases son texto fijo;
las cifras de la derecha salen de las tablas del propio tablero, [2.6](#26-página-4-el-modelo) y [2.8](#28-página-6-datos-y-método)):

| Frase | Evidencia en el tablero |
|---|---|
| 1. "La mejora es estadísticamente significativa" | Bootstrap, prueba, M0 − referencia ingenua: **−0.0537** (IC −0.0861 a −0.0217, no incluye el cero) |
| 2. "Sus cuotas pronostican mejor en validación y en prueba" | LogLoss del mercado de apertura 0.970552 (validación) y 1.020000 (prueba), contra 0.989547 y 1.033076 de M0; menor es mejor |
| 2. "pequeña (0.016)… pero real" | Bootstrap, validación + prueba, M0 − mercado: **+0.0159** (IC +0.0064 a +0.0255, no incluye el cero) |
| 3. "ayudaron en validación, pero no en prueba" | Validación: M1 0.987603, M2 0.980718, M3 0.982319 y M4 0.978612, todos menores que el 0.989547 de M0. Prueba: M1 1.034699, M2 1.037331, M3 1.033868 y M4 1.036739, todos mayores que el 1.033076 de M0 |
| 3. "El modelo base M0 fue el más robusto" | Es el de menor LogLoss en prueba entre los cinco modelos. Matiz: M4 − M0 en validación es −0.0109 (IC −0.0213 a −0.0001), un margen mínimo |
| 4. "se acerca, pero no le gana al mercado de forma sistemática" | Prueba sola: M0 − mercado +0.0131 (IC −0.0005 a +0.0264, **incluye el cero**); con validación y prueba juntas el mercado es mejor |

(La frase 4 es la lectura prudente: con la prueba sola la diferencia no es concluyente; la guía, con otros métodos de
bootstrap y con Diebold–Mariano, encontró que esas comparaciones al límite son **frágiles**: ver capítulo 19.)

**Aviso:** ninguna de las cuatro frases se reescribe sola. Las **cifras** sí cambian si cambian los datos; las **palabras**
("pequeña", "mejor", "ayudaron") no. Es el compromiso explicado en la
[decisión 5.3](#53-cifras-en-línea-y-frases-condicionales).

**En R (ilustrativo):** el código en línea es `` `r pct(acc("Prueba", "M0_Base"))` ``; el resto del texto es igual.

```markdown
1. **Las estadísticas sí anticipan resultados.** Con sólo `r n_var_m0` variables, el modelo acierta
   `r pct(acc("Prueba", "M0_Base"))` de los partidos de prueba, contra `r pct(acc("Prueba", "Ingenua"))` de un pronóstico básico.
```

### 2.4 Página 2: ¿Qué ocurre?

Líneas 215–283. Es el **planteamiento** de la historia: el fenómeno (cuánto gana el local, cuánto el favorito) y por qué
es difícil predecirlo.

```text
┌──────────────────────── # ¿Qué ocurre? {#que-ocurre} ──────────────────────────────┐
│ ## Row {height=185px}     [ 9,540 partidos ]  [ 45.6 % gana el local ]  [ 54.2 % favorito ] │
│ ## Row {height=500px}     ┌ Column 64 % ───────────────────┐ ┌ Column 36 % ─────────────┐ │
│                           │ "Jugar en casa siempre ayuda…" │ │ "Ni el favorito es       │ │
│                           │ (resultados por temporada)     │ │  garantía"               │ │
│                           └────────────────────────────────┘ └──────────────────────────┘ │
│ ## Row {.tabset height=440px}   [ Qué significa para el modelo | Tabla por temporada ]    │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.4.1 Fila 1: tres *value boxes* (líneas 217–247)

```markdown
## Row {height=185px}

::: {.valuebox icon="calendar3" color="#f3f2ee"}
Partidos analizados

`{python} f"{g['partidos']:,}"`

`{python} g['temporadas']` temporadas.

Del 18 de agosto de 2001 al `{python} ultima_fecha`
:::

::: {.valuebox icon="house-door" color="#eef7ee"}
Gana el equipo local

`{python} pct(g['pct_local'])`

Empate `{python} pct(g['pct_empate'])`

Visitante `{python} pct(g['pct_visita'])`

(`{python} tc['n']` temporadas completas)
:::

::: {.valuebox icon="trophy" color="#fdf0ea"}
Gana el favorito de las cuotas

`{python} pct(fav['gana_favorito'])`

Casi la mitad de las veces, el favorito no gana (Bet365)
:::
```

(La sintaxis de un *value box* —título, valor, apoyo; `icon`; `color`— se explicó en [2.3.2](#232-fila-2-los-tres-value-boxes-líneas-164190);
aquí también el `color` queda tapado por el SCSS.)

| Caja | Expresión | Valor en el sitio | Qué cifra es y de qué función sale |
|---|---|---|---|
| **Partidos analizados** | `f"{g['partidos']:,}"` | **9,540** | `resumen_general` ([13a.4.1](13a_codigo_datos_dashboard.md#13a41-resumen_general)): `len(df)`, **todas** las filas del histórico, incluida la temporada 2026/27 en curso; `:,` agrega la coma de miles |
| | `g['temporadas']` | **26** | Temporadas distintas del histórico: 2001/02 a 2026/27 |
| | `ultima_fecha` | 14 de septiembre de 2026 | Fecha del último partido, en español ([2.2.4](#224-cifras-sueltas-líneas-6469)) |
| | "18 de agosto de 2001" | (texto fijo) | **Escrito a mano.** `g["fecha_min"]` existe en `resumen_general`, pero no se usa; `fecha_es(g["fecha_min"])` daría lo mismo |
| **Gana el equipo local** | `pct(g['pct_local'])`, `pct(g['pct_empate'])`, `pct(g['pct_visita'])` | **45.6%**, 24.7% y 29.7% | `resumen_general`: porcentajes de cada resultado **sólo en las temporadas completas** (2001/02 a 2025/26: `temporada <= 2025`); por eso no coinciden con los 9,540 de la caja anterior |
| | `tc['n']` | **25** | `temporadas_completas` ([13a.7.2](13a_codigo_datos_dashboard.md#13a72-temporadas_completas)): temporadas del archivo menos la última, que está en curso |
| **Gana el favorito de las cuotas** | `pct(fav['gana_favorito'])` | **54.2%** | `resultado_del_favorito` ([13a.4.3](13a_codigo_datos_dashboard.md#13a43-resultado_del_favorito)): proporción de partidos con cuotas de Bet365 en los que ocurrió el resultado del favorito (la cuota más baja entre local y visitante); incluye el empate como "no gana" |
| | "Casi la mitad de las veces, el favorito no gana (Bet365)" | (texto fijo) | 100 − 54.2 = 45.8 %: "casi la mitad" es una frase fija que hoy es correcta |

Ojo con las **bases distintas**: la primera caja cuenta todos los partidos (9,540); la segunda, sólo los de 25 temporadas
completas (por eso aclara "(25 temporadas completas)"); la tercera, los partidos con cuotas de Bet365 (desde 2002/03: 24
temporadas completas más la parcial 2026/27). Las tres son correctas, pero no se pueden sumar ni comparar entre sí.

#### 2.4.2 Fila 2: dos gráficas (líneas 249–269)

````markdown
## Row {height=500px}

### Column {width=64%}

::: {.card title="Jugar en casa siempre ayuda… salvo sin público"}
<p class="subtitulo">Las bandas grises marcan los periodos que usa el modelo.</p>

```{python}
gr.mostrar(gr.resultados_por_temporada(d["temporadas"]))
```
:::

### Column {width=36%}

::: {.card title="Ni el favorito es garantía"}
<p class="subtitulo">Resultado según el favorito de Bet365.</p>

```{python}
gr.mostrar(gr.resultado_favorito(fav))
```
:::
````

- **Izquierda (64 %):** `resultados_por_temporada(d["temporadas"])` dibuja, por temporada completa, qué porcentaje de
  partidos ganó el local, empató o ganó el visitante, con bandas grises sobre los periodos que usa el modelo (la tabla de
  la pestaña "Tabla por temporada" tiene los mismos datos). El título anuncia el hallazgo: la ventaja de local se
  mantiene en todas las temporadas **salvo** la de partidos sin público (2020/21).
- **Derecha (36 %):** `resultado_favorito(fav)` resume, con el diccionario `fav`, qué ocurre cuando juega el favorito de
  Bet365: gana, empata o pierde.
- Los detalles de cómo se dibuja cada una están en el [capítulo 13b](13b_codigo_graficas.md).
- 64 % y 36 % (y los 62/38, 58/42, 66/34 y 52/48 de otras filas) siguen la regla "la gráfica principal ocupa unos dos
  tercios del ancho".

#### 2.4.3 Fila 3: pestañas (líneas 271–283)

````markdown
## Row {.tabset height=440px}

::: {.card title="Qué significa para el modelo"}
- **Predecir fútbol es difícil por naturaleza.** Si el favorito de las casas de apuestas gana sólo `{python} pct(fav['gana_favorito'], 0)` de las veces, un buen modelo debe aspirar a acertar cerca de 50 %. Por eso el tablero evalúa probabilidades y no sólo aciertos.
- **El COVID-19 no tiene un impacto drástico en el modelo.** Al reentrenar M0 sin los `{python} sens['partidos_excluidos']` partidos jugados sin público (del `{python} fecha_es(sens['inicio'])` al `{python} fecha_es(sens['fin'])`), la probabilidad media de victoria local sube de `{python} pct(sens['original_test_p_local'])` a `{python} pct(sens['sin_publico_test_p_local'])`, pero el LogLoss de prueba casi no cambia (`{python} num(sens['original_test_logloss'], 4)` → `{python} num(sens['sin_publico_test_logloss'], 4)`), mientras que la brecha con el mercado es de `{python} num(ll('Prueba', 'M0_Base') - ll('Prueba', 'Mercado_apertura'), 3)`.

:::

::: {.card title="Tabla por temporada"}
```{python}
HTML(tabla_temporadas)
```
:::
````

**Qué es `.tabset`.** Con `{.tabset}` en la fila, las **tarjetas que contiene dejan de ser cajas separadas y se vuelven
pestañas de una sola tarjeta**; el `title` de cada una es el nombre de su pestaña y la primera queda activa. Es el recurso
del tablero para la **información de segundo nivel** (tablas y gráficas secundarias) sin llenar la página. En el HTML
la fila es una tarjeta `.tabset` con una lista de pestañas (`nav nav-tabs`) y un `tab-pane` por tarjeta; el SCSS las
convierte en "píldoras" ([3.2](#32-estilosscss)).

**Observación sobre la altura.** La fila declara `height=440px`, pero en el HTML generado esa fila **no lleva altura**:
`grid-template-rows: 185px 500px minmax(3em, 1fr)` (las dos filas anteriores sí tienen su altura en píxeles; la de
pestañas queda en `1fr`). Lo mismo ocurre con las filas de pestañas de las páginas 3, 4 y 6 (480, 530 y 660 px). Es
decir, esos valores **no tienen efecto**; la altura la define el contenido. No se comprobó visualmente cómo queda
([6](#6-dudas-y-detalles-que-conviene-saber)).

**Las expresiones de la primera pestaña:**

| Expresión | Valor | Qué es y de dónde sale |
|---|---|---|
| `pct(fav['gana_favorito'], 0)` | **54%** | La misma cifra de la caja anterior, sin decimales |
| `sens['partidos_excluidos']` | **472** | `sensibilidad_sin_publico` ([13a.5.12](13a_codigo_datos_dashboard.md#13a512-sensibilidad_sin_publico)): partidos de **entrenamiento** jugados sin público |
| `fecha_es(sens['inicio'])` y `fecha_es(sens['fin'])` | 17 de junio de 2020 y 23 de mayo de 2021 | Las fechas del periodo sin público (están escritas en la función de Python; el tablero las muestra) |
| `pct(sens['original_test_p_local'])` → `pct(sens['sin_publico_test_p_local'])` | **42.6%** → **44.0%** | Probabilidad **media** de victoria local que M0 asigna a los partidos de **prueba**, con el modelo original y con el reentrenado sin esos 472 partidos |
| `num(sens['original_test_logloss'], 4)` → `num(sens['sin_publico_test_logloss'], 4)` | **1.0331** → **1.0328** | LogLoss de prueba de M0 en cada versión |
| `num(ll('Prueba', 'M0_Base') - ll('Prueba', 'Mercado_apertura'), 3)` | **0.013** | 1.033076 − 1.020000: la brecha entre M0 y el mercado en prueba, que **no cambia** con el reentrenamiento |

**Qué dice y qué no.** Las dos viñetas son **conclusiones fijas** (la frase "no tiene un impacto drástico" no se reescribe
sola) con **cifras vivas** que las respaldan. Primera viñeta: si el favorito sólo gana 54 % de las veces, un buen modelo
debe aspirar a acertar cerca de 50 %; por eso el tablero evalúa probabilidades (LogLoss) y no sólo aciertos. Segunda: el
COVID no explica la brecha con el mercado, porque quitar los partidos sin público apenas mueve el LogLoss (de 1.0331 a
1.0328) mientras la brecha es 0.013.

**Segunda pestaña:** `HTML(tabla_temporadas)` pega la tabla de 25 filas armada en
[2.2.8](#228-las-siete-tablas-html-líneas-104144); el contenedor `.tabla-contenedor` le pone barra de desplazamiento y el
encabezado queda fijo al desplazarse (`position: sticky`).

**Un detalle de todas las tarjetas:** Quarto agrega a cada tarjeta, también a las de pestañas, un botón de pantalla
completa ("Expand", esquina inferior derecha); no se desactivó.

**En R (ilustrativo):**

````markdown
Row {.tabset .tabset-fade}
-------------------------------------------------------------------------

### Qué significa para el modelo

- **El COVID-19 no tiene un impacto drástico en el modelo.** Al reentrenar M0 sin los `r sens$partidos_excluidos`
  partidos jugados sin público (del `r fecha_es(sens$inicio)` al `r fecha_es(sens$fin)`), la probabilidad media de
  victoria local sube de `r pct(sens$original_test_p_local)` a `r pct(sens$sin_publico_test_p_local)`...

### Tabla por temporada

```{r}
htmltools::HTML(tabla_temporadas)
```
````

### 2.5 Página 3: Patrones

Líneas 285–345. Es el **desarrollo** de la historia: la evidencia que justifica cada decisión del modelo (Elo como
variable principal, el mercado como rival difícil, Poisson para los goles).

```text
┌──────────────────────────────── # Patrones {#patrones} ────────────────────────────────┐
│ ## Row {height=540px}   ┌ Column 58 % ───────────────────┐ ┌ Column 42 % ──────────────────┐ │
│                         │ "A más ventaja de Elo, más     │ │ "Las cuotas están bien        │ │
│                         │  victorias locales"            │ │  calibradas"                  │ │
│                         └────────────────────────────────┘ └───────────────────────────────┘ │
│ ## Row {.tabset height=480px}                                                                │
│   [ Los goles se comportan como un conteo de Poisson | Por qué importan estos patrones |     │
│     Tabla: resultado por diferencia de Elo | Tabla: calibración de las cuotas ]              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.5.1 Fila 1: dos gráficas (líneas 287–307)

````markdown
## Row {height=540px}

### Column {width=58%}

::: {.card title="A más ventaja de Elo, más victorias locales"}
<p class="subtitulo">Resultados según la diferencia de Elo antes del partido, en deciles (2019/20 a 2026/27, `{python} f"{int(e['partidos'].sum()):,}"` partidos).</p>

```{python}
gr.mostrar(gr.resultado_por_diferencia_elo(d["elo"], d["ventaja_elo"]))
```
:::

### Column {width=42%}

::: {.card title="Las cuotas están bien calibradas"}
<p class="subtitulo">Cuando las cuotas de Bet365 dicen 70 %, ocurre ≈70 % de las veces.</p>

```{python}
gr.mostrar(gr.calibracion_mercado(d["calibracion_mercado"]))
```
:::
````

- **Izquierda:** `resultado_por_diferencia_elo(d["elo"], d["ventaja_elo"])`. `d["elo"]` es la tabla de **diez deciles**
  de la diferencia de Elo previa al partido (grupos de ≈ 270 partidos con el mismo tamaño, `pd.qcut`), con el porcentaje
  de victoria local, empate y victoria visitante en cada uno ([13a.4.4](13a_codigo_datos_dashboard.md#13a44-resultado_por_elo));
  `d["ventaja_elo"]` (≈ −50 puntos) es la diferencia de Elo en la que local y visitante ganan igual: "jugar en casa vale
  ≈ 50 puntos" ([13a.4.5](13a_codigo_datos_dashboard.md#13a45-ventaja_local_en_elo)); la gráfica lo recibe como segundo
  argumento para señalar esa ventaja (cómo, en el [13b](13b_codigo_graficas.md)). El
  subtítulo cuenta los partidos con `f"{int(e['partidos'].sum()):,}"` → **2,696** (la suma de los diez deciles; es el tamaño
  de `premier_training_data.csv`). "2019/20 a 2026/27" está escrito a mano.
- **Derecha:** `calibracion_mercado(d["calibracion_mercado"])` compara la probabilidad implícita de las cuotas de Bet365
  con la frecuencia con que ocurrió, agrupando de 5 en 5 puntos y descartando grupos de menos de 50 casos
  ([13a.4.6](13a_codigo_datos_dashboard.md#13a46-calibracion_historica_mercado-y-_tabla_calibracion)). El subtítulo es un ejemplo fijo ("70 % → ≈70 %"); la tabla
  de la pestaña "Tabla: calibración de las cuotas" tiene los valores.
- Cómo se dibujan: [capítulo 13b](13b_codigo_graficas.md).

#### 2.5.2 Fila 2: pestañas (líneas 309–345)

````markdown
## Row {.tabset height=480px}

::: {.card title="Los goles se comportan como un conteo de Poisson"}
<p class="subtitulo">Goles por partido observados contra una distribución de Poisson con la misma media.<br><span class="leyenda"><i class="muestra" style="background:#898781"></i>observado</span><span class="leyenda"><i class="muestra rombo" style="background:#2a78d6"></i>Poisson con la misma media</span></p>

```{python}
gr.mostrar(gr.ajuste_poisson(d["poisson"]))
```
:::

::: {.card title="Por qué importan estos patrones"}
Cada patrón se traduce a una decisión del modelo:

- **Elo como variable principal.** 

Mientras más fuerte es el local según el Elo, más gana, `{python} pct(e['pct_local'].iloc[0], 0)` de las veces cuando está en clara desventaja y `{python} pct(e['pct_local'].iloc[-1], 0)` cuando tiene clara ventaja. Incluso con fuerzas iguales, el local gana más, por eso el modelo toma en cuenta quién juega en casa.

- **Mercado calibrado como rival difícil.** 

Las probabilidades de las cuotas coinciden con lo que de verdad pasa, así que para ganarles hace falta saber algo que el mercado no sepa. Sólo en los extremos se equivoca un poco, da algo de más a los equipos muy poco probables y algo de menos a los grandes favoritos.

- **Goles tipo Poisson - regresión de Poisson.** 

Los goles se reparten como predice una distribución de Poisson, y la variación que queda dentro del modelo es la esperada, `{python} num(disp['home'], 2)` en el local y `{python} num(disp['away'], 2)` en el visitante.
:::

::: {.card title="Tabla: resultado por diferencia de Elo"}
```{python}
HTML(tabla_elo)
```
:::

::: {.card title="Tabla: calibración de las cuotas"}
```{python}
HTML(tabla_calibracion)
```
:::
````

**Pestaña 1, Poisson.** El subtítulo trae su leyenda en HTML: un cuadrito gris para "observado" y un **rombo** azul
(`.muestra.rombo`, un cuadrito girado 45°) para "Poisson con la misma media", porque en la gráfica los valores esperados
se dibujan como rombos. `ajuste_poisson(d["poisson"])` compara la frecuencia observada de 0, 1, 2… goles con la
que daría una Poisson con la misma media ([13a.4.7](13a_codigo_datos_dashboard.md#13a47-ajuste_poisson_goles)).
Es el argumento visual de por qué se usa **regresión de Poisson**.

**Pestaña 2, "Por qué importan estos patrones".** Traduce cada patrón a una decisión del modelo. Las expresiones:

| Expresión | Valor | Qué es y de dónde sale |
|---|---|---|
| `pct(e['pct_local'].iloc[0], 0)` | **13%** | Porcentaje de victorias locales en el **primer** decil de diferencia de Elo (el local en clara desventaja). `iloc[0]` es la primera fila de `e` (R: `e$pct_local[1]`) |
| `pct(e['pct_local'].iloc[-1], 0)` | **76%** | Lo mismo en el **último** decil (clara ventaja); `iloc[-1]` es la última fila (R: `tail(e$pct_local, 1)`) |
| `num(disp['home'], 2)` y `num(disp['away'], 2)` | **1.00** y **1.04** | Dispersión de Pearson de M0 (χ² / grados de libertad) en cada ecuación: cerca de 1 significa que la variación de los goles es la que predice Poisson ([13a.5.11](13a_codigo_datos_dashboard.md#13a511-dispersion_pearson)) |

Las tres afirmaciones centrales son **texto fijo** respaldado por las gráficas: "incluso con fuerzas iguales, el local
gana más" (la ventaja de ≈ 50 puntos de Elo de arriba); "las cuotas coinciden con lo que de verdad pasa… sólo en los
extremos se equivoca un poco" (la gráfica de calibración); "la variación… es la esperada" (dispersión ≈ 1).

Un detalle de Markdown: los párrafos que siguen a cada viñeta **no están sangrados**, así que en Markdown no pertenecen
a la viñeta: cada viñeta funciona como un subtítulo y su párrafo queda debajo. Se ve bien; es una forma de armar la
tarjeta, no un error.

**Pestañas 3 y 4:** `HTML(tabla_elo)` (10 filas, una por decil) y `HTML(tabla_calibracion)` (una fila por grupo de
probabilidad), armadas en [2.2.8](#228-las-siete-tablas-html-líneas-104144). Son las dos vistas de tabla de esta página.

**En R (ilustrativo):** la estructura es la misma que en la página 2. Lo nuevo son las gráficas y el código en línea.

```r
### A más ventaja de Elo, más victorias locales {data-width=580}
plotly::ggplotly(resultado_por_diferencia_elo(e, ventaja_elo))      # ≈ gr.mostrar(gr.resultado_por_diferencia_elo(...))
# En el texto:  `r pct(e$pct_local[1], 0)`  y  `r pct(tail(e$pct_local, 1), 0)`
```

### 2.6 Página 4: El modelo

Líneas 347–442. Es el **conflicto y la resolución** de la historia: qué hace el modelo, qué pasa cuando se le agregan
variables y cómo queda frente al mercado. Es la página con más contenido (9 tarjetas).

```text
┌──────────────────────────────── # El modelo {#modelo} ─────────────────────────────────┐
│ ## Row {height=300px}   ┌ Column 66 % ─────────────────────┐ ┌ Column 34 % ───────────┐ │
│                         │ "Cómo funciona" (diagrama HTML)  │ │ "En pocas palabras"    │ │
│ ## Row {height=490px}   ┌ Column 52 % ─────────────────────┐ ┌ Column 48 % ───────────┐ │
│                         │ "Agregar variables no generaliza"│ │ "No es una derrota..." │ │
│ ## Row {.tabset height=530px}                                                           │
│   [ Qué variables pesan más | Calibración: modelo vs. mercado | Modelo vs. mercado,     │
│     partido a partido | Métricas completas | ¿Son significativas las diferencias? ]     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.6.1 Fila 1: el diagrama de flujo y el resumen (líneas 349–376)

````markdown
## Row {height=300px}

### Column {width=66%}

::: {.card title="Cómo funciona"}
<div class="flujo">
  <div class="paso"><b>Histórico</b><span>`{python} f"{g['partidos']:,}"` partidos, 2001–2026</span></div>
  <div class="flecha">→</div>
  <div class="paso"><b>Variables previas al partido</b><span>Elo · goles de la temporada · forma reciente · tiros</span></div>
  <div class="flecha">→</div>
  <div class="paso modelo"><div class="sub"><b>Poisson: goles del local</b><span>λ local</span></div><div class="sub"><b>Poisson: goles del visitante</b><span>λ visita</span></div></div>
  <div class="flecha">→</div>
  <div class="paso modelo"><b>Marcadores posibles (Skellam)</b><span>P(local) · P(empate) · P(visitante)</span></div>
  <div class="flecha">→</div>
  <div class="paso compara"><b>Comparación con LogLoss</b><span>contra la referencia ingenua y el mercado</span></div>
  <div class="flecha">←</div>
  <div class="paso mercado"><b>Mercado</b><span>1/cuota de apertura, normalizada</span></div>
</div>
:::

### Column {width=34%}

::: {.card title="En pocas palabras"}
- Dos regresiones de Poisson estiman los goles esperados de cada equipo, con información anterior al partido.
- De esos goles salen las probabilidades de cada marcador y de cada resultado.
- Entrenamiento 2019/20–2023/24 (`{python} f"{n_train:,}"` partidos) · validación 2024/25 (`{python} n_val`) · prueba ago-2025 a sep-2026 (`{python} n_test`).
- Las cuotas nunca entran al modelo, sólo sirven para comparar.
:::
````

**El diagrama "Cómo funciona" no es una imagen ni un diagrama de Mermaid: es HTML con CSS.** Cada recuadro es un
`<div class="paso">` con un título en negritas (`<b>`) y una línea de apoyo (`<span>`); las flechas son `<div
class="flecha">`. Las variantes de color usan clases: `.modelo` (borde azul), `.compara` (borde oscuro) y `.mercado`
(borde naranja); el paso de las dos regresiones agrupa dos `<div class="sub">` separados por una línea punteada. El CSS
está en `estilos.scss` ([3.2](#32-estilosscss)). Se hizo así porque **Mermaid no dibuja en páginas ocultas** (el diagrama
salía vacío; tabla de [13.10](13_dashboard.md)) y una imagen no podría llevar la cifra de partidos calculada
([decisión 5.7](#57-diagrama-de-flujo-en-html-y-css)).

- Lectura de izquierda a derecha: **Histórico** (9,540 partidos, 2001–2026; el número es la única expresión en línea
  del diagrama: `f"{g['partidos']:,}"`, y "2001–2026" es texto fijo) → **Variables previas al partido** (Elo, goles de la
  temporada, forma reciente y tiros) → **dos regresiones de Poisson**, una por equipo, que dan los goles esperados λ →
  **marcadores posibles** → **comparación con LogLoss**.
- La **flecha final apunta hacia atrás** (`←`) y el recuadro naranja "Mercado" queda al otro lado: el mercado **no entra al
  modelo**; sólo llega a la comparación. Es el mensaje de la última viñeta de "En pocas palabras".
- Precisión de lenguaje: el recuadro dice "Marcadores posibles (Skellam)". La distribución de **Skellam** es la de la
  *diferencia* de dos Poisson, y de ella salen directamente P(local), P(empate) y P(visitante); la **matriz de marcadores**
  (el 1–1, el 2–0…) sale del producto de dos Poisson, como en el simulador ([2.7](#27-página-5-explora-un-partido-el-simulador)).
  El diagrama resume las dos cosas en un solo paso.
- En R no se haría igual: un diagrama así se dibujaría con `DiagrammeR` (Mermaid o Graphviz) o con `htmltools::div()`;
  aquí se prefirió HTML puro por el problema de las páginas ocultas.

**"En pocas palabras"** (cuatro viñetas). Las expresiones: `f"{n_train:,}"` → **1,897**, `n_val` → **380**, `n_test` →
**419** (el tamaño de cada partición, de [`particiones`](13a_codigo_datos_dashboard.md#13a34-particiones)); los **periodos**
("2019/20–2023/24", "2024/25", "ago-2025 a sep-2026") están escritos a mano y corresponden a las fechas de corte
`FECHA_VALIDACION = 2024-08-01` y `FECHA_PRUEBA = 2025-08-01` de `datos_dashboard.py`. Las demás viñetas son texto fijo.

#### 2.6.2 Fila 2: dos gráficas (líneas 378–398)

````markdown
## Row {height=490px}

### Column {width=52%}

::: {.card title="Agregar variables no generaliza"}
<p class="subtitulo">Comparativa de LogLoss entre modelos.<br><span class="leyenda"><i class="muestra circulo hueco"></i>Validación</span><span class="leyenda"><i class="muestra circulo" style="background:#52514e"></i>Prueba</span><span class="leyenda"><i class="muestra" style="background:#eb6834"></i>Mercado</span><span class="leyenda"><i class="muestra" style="background:#898781"></i>Especificaciones del modelo</span></p>

```{python}
gr.mostrar(gr.delta_vs_m0(d["delta_m0"]))
```
:::

### Column {width=48%}

::: {.card title="No es una derrota..."}
<p class="subtitulo">Diferencia de LogLoss entre M0 y el mercado, según el resultado.</p>

```{python}
gr.mostrar(gr.brecha_por_resultado(brecha))
```
:::
````

- **Izquierda, "Agregar variables no generaliza".** `delta_vs_m0(d["delta_m0"])` dibuja, para M1, M2, M3, M4 y el mercado,
  la **diferencia de LogLoss respecto a M0** (negativa = mejor que M0), en validación (círculo hueco) y en prueba
  (círculo lleno oscuro). La leyenda HTML tiene cuatro entradas: dos formas de círculo (`.circulo`, `.hueco`), un cuadrito
  naranja (el mercado) y uno gris (las especificaciones). Con las cifras de la tabla de verificación (LogLoss de cada
  modelo menos el de M0, calculado por la guía):

  | Predictor | Validación | Prueba |
  |---|---|---|
  | M1 · + Forma | −0.0019 | +0.0016 |
  | M2 · + Tiros | −0.0088 | +0.0043 |
  | M3 · + Tiros a puerta | −0.0072 | +0.0008 |
  | M4 · Completo | −0.0109 | +0.0037 |
  | Mercado · Apertura | −0.0190 | −0.0131 |

  La lectura del título: **en validación todas las ampliaciones mejoran a M0; en prueba todas empeoran**. Sólo el mercado
  mejora a M0 en ambos periodos ([13a.5.7](13a_codigo_datos_dashboard.md#13a57-delta_contra_m0)).
- **Derecha, "No es una derrota...".** `brecha_por_resultado(brecha)` reparte la brecha de LogLoss entre M0 y el mercado
  (799 partidos de validación y prueba) según **el resultado que ocurrió**: el mercado le ganó a M0 sobre todo en las
  **victorias locales** (+0.0185) y en los **empates** (+0.0078), pero **M0 fue mejor que el mercado en las victorias
  visitantes** (−0.0104); suman la brecha total, +0.0159 ([13a.5.8](13a_codigo_datos_dashboard.md#13a58-brecha_por_resultado)).
  El título quedó con puntos suspensivos (es una frase inconclusa a propósito: "No es una derrota…"; el subtítulo
  completa la idea).

#### 2.6.3 Fila 3: cinco pestañas (líneas 400–442)

La fila `{.tabset height=530px}` agrupa cinco tarjetas; como en las otras páginas, el `height` no se aplica en el HTML
generado.

**Pestaña 1: "Qué variables pesan más"** (líneas 402–408)

````markdown
::: {.card title="Qué variables pesan más"}
<p class="subtitulo">Efecto sobre los goles esperados de subir una desviación estándar cada variable de M0, con intervalo de 95 %. La diferencia de Elo domina en ambas ecuaciones. Los goles en contra del rival pesan poco, no son significativos en la ecuación del visitante (p = `{python} f"{p_ga_visita:.3g}"`) y quedan en el límite en la del local (p = `{python} f"{p_ga_local:.3g}"`).</p>

```{python}
gr.mostrar(gr.efectos(d["efectos"]))
```
:::
````

`efectos(d["efectos"])` dibuja, para las **seis** variables de M0 (tres por ecuación), el cambio porcentual esperado en
goles al subir una desviación estándar (exp(β·DE) − 1) con su IC de 95 %
([13a.5.10](13a_codigo_datos_dashboard.md#13a510-efectos_estandarizados)). Las dos expresiones: `f"{p_ga_visita:.3g}"` →
**0.506** y `f"{p_ga_local:.3g}"` → **0.0498** (`:.3g` = tres cifras significativas). La frase "quedan en el límite" es
**texto fijo**: 0.0498 queda apenas debajo de 0.05; si cambiara el valor, la frase no se ajustaría sola.

**Pestaña 2: "Calibración: modelo vs. mercado"** (líneas 410–416)

````markdown
::: {.card title="Calibración: modelo vs. mercado"}
<p class="subtitulo"><span class="leyenda"><i class="muestra linea" style="background:#2a78d6"></i>modelo M0</span><span class="leyenda"><i class="muestra linea" style="background:#eb6834"></i>mercado (apertura)</span><br>Probabilidad asignada contra frecuencia observada (validación + prueba). El modelo confía de más en los favoritos claros: cuando les da 60–80 %, ganan menos de lo previsto. También subestima el empate: en prueba le asigna `{python} pct(p_empate_modelo)` en promedio, el mercado `{python} pct(p_empate_mercado)`, y ocurrió en `{python} pct(p_empate_real)` de los partidos.</p>

```{python}
gr.mostrar(gr.calibracion_modelos(d["calibracion_modelos"]))
```
:::
````

La leyenda usa `.muestra.linea` (una barrita horizontal) porque la gráfica son **líneas** (azul = M0, naranja =
mercado). `calibracion_modelos(d["calibracion_modelos"])` dibuja la tabla que calcula `calibracion_modelo_vs_mercado`
([13a.5.9](13a_codigo_datos_dashboard.md#13a59-calibracion_modelo_vs_mercado)): intervalos de 10 puntos con al menos 30 casos. **Evidencia de la frase fija:** cuando M0 dice
64 % ocurre 57 % y cuando dice 74 % ocurre 68 % (el mercado se desvía menos en esa zona). Las tres cifras en línea:
**23.6%** (probabilidad media de empate de M0 en prueba), **24.5%** (del mercado) y **28.2%** (frecuencia real de
empates). Es decir: los dos subestiman el empate y M0 más (el límite de Poisson con goles independientes, que el tablero
reconoce en "Limitaciones").

**Pestaña 3: "Modelo vs. mercado, partido a partido"** (líneas 418–424)

````markdown
::: {.card title="Modelo vs. mercado, partido a partido"}
<p class="subtitulo">Probabilidad de victoria local según el mercado y según M0 en cada partido de prueba. Coinciden en lo esencial; las discrepancias grandes son pocas.</p>

```{python}
gr.mostrar(gr.modelo_vs_mercado(d["partido_a_partido"]))
```
:::
````

`d["partido_a_partido"]` es la tabla de [13a.5.13](13a_codigo_datos_dashboard.md#13a513-comparacion_partido_a_partido)
(una fila por partido de prueba, 419, con la P(local) de M0 y del mercado). La gráfica es un diagrama de dispersión:
eje horizontal, P(victoria local) según el mercado; eje vertical, según M0; ambos de 0 a 100 %. Si los dos coincidieran,
los puntos caerían sobre la diagonal. La frase del subtítulo es fija.

**Pestaña 4: "Métricas completas"** (líneas 426–432)

````markdown
::: {.card title="Métricas completas"}
<p class="subtitulo">LogLoss, probabilidad media asignada al resultado real, aciertos y error absoluto medio de goles.</p>

```{python}
HTML(tabla_metricas)
```
:::
````

La tabla de 18 filas de [2.2.8](#228-las-siete-tablas-html-líneas-104144): primero los nueve predictores de **validación**
y luego los nueve de **prueba**, del azar al mercado de cierre, con ocho columnas (periodo, predictor, partidos, LogLoss con
4 decimales, probabilidad media al resultado real, aciertos, P(empate) media y MAE de goles). Es **la tabla que respalda**
las barras de las páginas 1 y 4 (que no tienen vista de tabla propia). Cifras de LogLoss de seis de los nueve predictores,
las mismas que verifica la página 6:

| Predictor | Validación | Prueba |
|---|---|---|
| M0 · Base | 0.989547 | 1.033076 |
| M1 · + Forma | 0.987603 | 1.034699 |
| M2 · + Tiros | 0.980718 | 1.037331 |
| M3 · + Tiros a puerta | 0.982319 | 1.033868 |
| M4 · Completo | 0.978612 | 1.036739 |
| Mercado · Apertura | 0.970552 | 1.020000 |

**Pestaña 5: "¿Son significativas las diferencias?"** (líneas 434–442)

````markdown
::: {.card title="¿Son significativas las diferencias?"}
<p class="subtitulo">Intervalos bootstrap con 10,000 remuestreos de partidos. Si el intervalo no incluye el cero, la diferencia no se explica por azar.</p>

```{python}
HTML(tabla_bootstrap)
```

<p class="nota"><b>Lectura.</b> El modelo supera con claridad a la referencia ingenua. Frente al mercado, la prueba sola no es concluyente; con validación y prueba juntas, sí. Entre M4 y M0, en validación M4 fue mejor por un margen mínimo; en prueba la diferencia no es concluyente.</p>
:::
````

La tabla real (la que muestra el sitio):

| Periodo | Comparación (A − B) | Partidos | Diferencia de LogLoss | IC 95 % | ¿Distinta de cero? |
|---|---|---|---|---|---|
| Prueba | M0 · Base − Referencia ingenua | 419 | −0.0537 | −0.0861 a −0.0217 | Sí |
| Prueba | M0 · Base − Mercado · Apertura | 419 | +0.0131 | −0.0005 a +0.0264 | **No** |
| Prueba | M4 · Completo − M0 · Base | 419 | +0.0037 | −0.0063 a +0.0139 | No |
| Prueba | M4 · Completo − Mercado · Apertura | 419 | +0.0167 | +0.0034 a +0.0301 | Sí |
| Validación | M4 · Completo − M0 · Base | 380 | −0.0109 | −0.0213 a −0.0001 | Sí |
| Validación | M0 · Base − Mercado · Apertura | 380 | +0.0190 | +0.0053 a +0.0328 | Sí |
| Validación + prueba | M0 · Base − Mercado · Apertura | 799 | +0.0159 | +0.0064 a +0.0255 | Sí |

(Diferencia = A − B; **negativa = A mejor**. El IC sale de 10,000 remuestreos de partidos con semilla fija 2026;
[13a.5.6](13a_codigo_datos_dashboard.md#13a56-_bootstrap-y-tabla_bootstrap).)

**Cómo se lee la "Lectura" contra la tabla:** "supera con claridad a la referencia ingenua" = fila 1; "frente al
mercado, la prueba sola no es concluyente" = fila 2 (el intervalo incluye el cero); "con validación y prueba juntas, sí" =
fila 7; "en validación M4 fue mejor por un margen mínimo" = fila 5 (el límite superior es −0.0001); "en prueba la
diferencia no es concluyente" = fila 3. **Dos filas que el texto no comenta**, y que conviene conocer: en la fila 4, **M4
queda significativamente por detrás del mercado incluso en la prueba** (+0.0167), mientras que M0, en la prueba sola, no; y
la fila 6 confirma que en validación el mercado es mejor que M0 (+0.0190). Además, las dos comparaciones "al límite"
(filas 2 y 5) son **frágiles**: cambian de lado con otros métodos de bootstrap o con Diebold–Mariano (cálculo propio de
la guía, capítulo 19).

**Dos simplificaciones del subtítulo y de la "Lectura":** "Si el intervalo no incluye el cero, la diferencia no se
explica por azar" es una paráfrasis laxa de "el intervalo de 95 % no incluye el cero"; y "10,000 remuestreos" está
**escrito a mano** (coincide con `N_BOOTSTRAP = 10_000`). Las frases de la "Lectura" son **texto fijo**; se escribió
sin repetir los intervalos justamente para que no se desactualice si cambian las cifras.

**Una clase y una regla de estilo:** `<p class="nota">` es el texto pequeño y gris de las notas; está **después** del
chunk, y la regla de CSS que hace que el texto de una tarjeta no estire a la gráfica cubre ese caso ([3.2](#32-estilosscss)).

**En R (ilustrativo):** la tabla del bootstrap y las notas serían un chunk con `knitr::kable()` seguido de HTML.

```r
### ¿Son significativas las diferencias? {.tabset}
htmltools::tagList(
  htmltools::p(class = "subtitulo", "Intervalos bootstrap con 10,000 remuestreos de partidos. ..."),
  htmltools::HTML(tabla_bootstrap),
  htmltools::p(class = "nota", htmltools::HTML("<b>Lectura.</b> El modelo supera con claridad a la referencia ingenua. ..."))
)
```

### 2.7 Página 5: Explora un partido (el simulador)

Líneas 444–550. Es la **exploración libre** de la historia: el lector elige dos equipos y ve el pronóstico de M0. Es la
única página que no es estática del todo: **corre código en el navegador** (Observable JS). Decisión relacionada:
[5.9](#59-observable-en-el-navegador-con-datos-precalculados).

```text
┌─────────────────── # Explora un partido {#simulador} ────────────────────┐
│ ┌─ ## {.sidebar} ───────────┐  ┌─ ## Column ───────────────────────────┐ │
│ │ chunk ojs_define (oculto) │  │ ### Row {height=150px}                │ │
│ │ [ Equipo local     ▼ ]    │  │   [ Local ] [ Empate ] [ Visitante ]  │ │
│ │ [ Equipo visitante ▼ ]    │  │ ### Row {height=520px}                │ │
│ │ partido · fmtp (ocultos)  │  │   ┌ Mapa de calor ┐ ┌ Tabla de M0 ┐   │ │
│ │ aviso de uso académico    │  │   └───────────────┘ └─────────────┘   │ │
│ └───────────────────────────┘  └───────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.7.1 Qué es Observable JS y cómo piensa

**Observable JS (OJS)** es JavaScript con una regla distinta: es **reactivo**, como una hoja de cálculo. Cada bloque
```` ```{ojs} ```` es una o varias **celdas** con nombre; si una celda menciona el nombre de otra, **se vuelve a calcular
sola cuando la otra cambia**. Por eso no hay "eventos" ni `onchange`: basta con escribir `partido = … local … visita`.

| Elemento de OJS | Qué es | Dónde se usa aquí |
|---|---|---|
| `viewof x = Inputs.select(opciones, {label, value})` | Crea un menú desplegable. `viewof x` es el control en pantalla y `x` es su valor actual, que se actualiza solo | `viewof local`, `viewof visita` |
| `nombre = expresión` | Una celda con nombre: se recalcula cuando cambia algo de lo que menciona | `partido`, `fmtp` |
| `` html`…` `` | Plantilla que construye HTML y sustituye `${expresión}` por su valor | tarjetas, tabla y notas |
| `Plot.plot({…})`, `Plot.cell`, `Plot.text` | Biblioteca **Observable Plot** para dibujar | el mapa de calor |
| `d3.range(6)` | Utilidad de D3: la lista `[0, 1, 2, 3, 4, 5]` | los ejes del mapa |
| `//\| echo: false`, `//\| title: "…"` | Opciones de celda (con `//\|`, como `#\|` en Python) | todas las celdas |

**Quién hace qué.** Python **precalcula** (en la generación) las probabilidades de los 380 cruces local–visitante; el
navegador **sólo filtra y dibuja**. No hay ningún modelo corriendo en la página.

**Dependencias externas (a tener en cuenta).** El *runtime* de Observable viene en el sitio
(`index_files/libs/quarto-ojs/quarto-ojs-runtime.js`), pero las bibliotecas que usa (Plot, Inputs, D3) se descargan de
**jsDelivr** (`cdn.jsdelivr.net/npm/…`, la dirección que aparece en el *runtime*) cuando se abre la página. Sin conexión
a internet, o con ese servidor bloqueado, el simulador no se dibujaría (no se probó: es una consecuencia de cómo
carga las bibliotecas). Y **no es sólo el simulador**: el HTML generado también carga **jQuery 3.5.1 y RequireJS 2.3.6
desde jsDelivr** (`<script src="https://cdn.jsdelivr.net/npm/…">`), y las gráficas de Plotly se dibujan con
`require(["plotly"], …)`, es decir, con RequireJS. Todo el tablero necesita acceso a ese servidor para verse completo.

#### 2.7.2 La estructura de la página: barra lateral y columna

```markdown
# Explora un partido {#simulador}

## {.sidebar}
   … (chunk ojs_define, selectores, celdas ocultas y aviso) …

## Column

### Row {height=150px}
   … (tarjetas de probabilidad) …

### Row {height=520px}
   … (mapa de calor y tabla) …
```

- `## {.sidebar}` (un encabezado de nivel 2 **sin texto**, sólo con la clase) crea la **barra lateral** izquierda. En el
  HTML es un `bslib-sidebar-layout` abierto en escritorio y plegable en pantallas chicas.
- `## Column` y `### Row`: Quarto **invierte la orientación después de una barra lateral** (problema real, tabla de
  [13.10](13_dashboard.md): "tras la barra lateral, filas convertidas en columnas"). La solución fue declarar
  explícitamente una `## Column` y meter adentro dos `### Row`. El resultado en el HTML es una columna cuyas filas miden
  `150px 520px` (`grid-template-rows: 150px 520px`).
- Las dos celdas OJS con `//| title:` se vuelven **tarjetas** (`<div class="card cell … data-title="…">`); las
  tarjetas de probabilidad no llevan `title` y quedan sin marco de tarjeta, porque cada una es su propia caja (`.sim-kpi`).

#### 2.7.3 El chunk `ojs_define` (líneas 448–453)

````markdown
```{python}
#| echo: false
ojs_define(sim={"equipos": sim["equipos"], "partidos": sim["partidos"], "stats": sim["stats"],
                "temporada": sim["temporada"], "fecha": ultima_fecha,
                "k_elo": dd.K_ELO, "k_shrinkage": dd.K_SHRINKAGE})
```
````

Es **el puente entre Python y el navegador**.

- `ojs_define(nombre=valor, …)` es una función que Quarto pone a disposición en los chunks de Python. Convierte los
  valores a **JSON** y los deja en la página dentro de un `<script type="ojs-define">`; en el navegador, cada
  nombre se vuelve una **variable de OJS** (aquí, `sim`). En el sitio ese bloque pesa ≈ **192 KB** de los ≈ 5 MB.
- Lo que pasa:

  | Campo | Contenido | Se usa en OJS |
  |---|---|---|
  | `equipos` | Los 20 nombres, en orden alfabético | Sí: las opciones de los selectores |
  | `partidos` | 380 diccionarios (uno por cruce): `local`, `visita`, `lambda_local`, `lambda_visita`, `p_local`, `p_empate`, `p_visita`, `marcador`, `p_marcador` y `matriz` (6 × 6) | Sí |
  | `stats` | 20 diccionarios: `equipo`, `elo`, `gf`, `ga`, `partidos_temporada` | Sí: la tabla "¿De dónde sale el pronóstico?" |
  | `temporada` | "2026/27" | Sí: una fila de la tabla |
  | `fecha` | La última fecha, en español | **No** (el aviso la toma de Python) |
  | `k_elo` | 15 | **No** |
  | `k_shrinkage` | 0 | Sí: elige qué nota se escribe |

- Se pasan **piezas** y no `sim` completo porque `sim` contiene `fecha_corte`, un `Timestamp` de pandas que no es JSON
  (explicación razonable; no consta en el código). `fecha` y `k_elo` **no los lee ninguna celda**: son sobrantes.
- `sim` aparece dos veces con sentidos distintos: es la variable de **Python** (`sim = d["simulador"]`, línea 36) y la
  variable de **OJS** creada por `sim=` dentro de `ojs_define`.
- **Por qué `#| echo: false` y no `include: false`:** con `include: false` Quarto descarta la salida del chunk y los
  datos nunca llegan a la página ("el simulador no cargaba datos", tabla de [13.10](13_dashboard.md)). Como `echo: false`
  ya es global, la opción es redundante; lo importante es **no** poner `include: false`.

**En R (ilustrativo):** con el motor knitr, el mismo puente existe: `ojs_define()` en un chunk de R. Las celdas OJS
no cambian.

````markdown
```{r}
#| echo: false
ojs_define(sim = list(equipos = sim$equipos, partidos = sim$partidos, stats = sim$stats,
                      temporada = sim$temporada, k_shrinkage = K_SHRINKAGE))
```
````

(Un `data.frame` llega a OJS **por columnas** y se pasa a filas con `transpose()`; para listas anidadas como `partidos`,
conviene construirlas con `purrr::pmap()` o `jsonlite`. No se verificó.)

#### 2.7.4 Los dos selectores (líneas 455–464)

````markdown
```{ojs}
//| echo: false
viewof local = Inputs.select(sim.equipos, {label: "Equipo local", value: "Arsenal"})
```

```{ojs}
//| echo: false
viewof visita = Inputs.select(sim.equipos.filter(e => e !== local),
  {label: "Equipo visitante", value: local === "Man City" ? "Arsenal" : "Man City"})
```
````

- `Inputs.select(opciones, {label, value})` dibuja un menú: `label` es el rótulo y `value` la opción preseleccionada.
  El primero lista los 20 equipos y arranca en **Arsenal**.
- El segundo depende de `local` (lo menciona dos veces). `sim.equipos.filter(e => e !== local)` es una **función flecha**:
  se queda con los equipos distintos del local (19 opciones), así que **no se puede elegir el mismo equipo dos veces**.
  (`e` es la variable de la función en JavaScript; no tiene relación con la `e` de Python.)
- `value: local === "Man City" ? "Arsenal" : "Man City"` es un **condicional** (`condición ? si_cierto : si_falso`): el
  visitante arranca en Man City, salvo que el local sea Man City, y entonces en Arsenal.
- **Consecuencia de la reactividad:** cuando se cambia `local`, la celda de `visita` se vuelve a ejecutar y su menú se
  **vuelve a crear** con su valor inicial; es decir, **al cambiar el equipo local, el visitante regresa a Man City (o
  Arsenal)**. La página abre con **Arsenal – Man City**, el mismo cruce que verifica la página 6.
- `echo: false` es redundante (ya es global); las celdas con `viewof` se muestran como el control mismo.

**En R (ilustrativo, con Shiny):** son dos `selectInput`, y el segundo depende del primero.

```r
selectInput("local", "Equipo local", choices = equipos, selected = "Arsenal")
renderUI(selectInput("visita", "Equipo visitante",
                     choices  = setdiff(equipos, input$local),                       # ≈ filter(e => e !== local)
                     selected = if (input$local == "Man City") "Arsenal" else "Man City"))
```

#### 2.7.5 Las celdas `partido` y `fmtp` (líneas 466–472)

````markdown
```{ojs}
//| echo: false
//| output: false
// Si por algún motivo la combinación no existe, se usa la primera para no dejar la página en error.
partido = sim.partidos.find(p => p.local === local && p.visita === visita) ?? sim.partidos[0]
fmtp = p => (p * 100).toFixed(1) + "%"
```
````

- `//| output: false`: las celdas **se calculan pero no se muestran** (si no, la página imprimiría el objeto `partido`).
- `sim.partidos.find(p => …)` recorre los 380 cruces y devuelve **el primero** cuyo local y visitante coinciden con
  los menús (en R, `dplyr::filter(...) |> slice(1)`). Es el cruce elegido; es una búsqueda lineal de 380 elementos,
  instantánea.
- `?? sim.partidos[0]` es el operador de **coalescencia nula**: si `find` no encuentra nada (`undefined`), usa el primer
  cruce, "para no dejar la página en error". Con los selectores actuales **nunca debería ocurrir** (los 380 pares existen);
  es una red de seguridad.
- `fmtp` es una función que convierte una proporción en texto con **un decimal y el signo %**: `fmtp(0.25)` → "25.0%",
  `fmtp(0.118)` → "11.8%". (Equivale al `pct` de Python.)

#### 2.7.6 El aviso de uso (líneas 474–480)

```html
<div class="sim-aviso">

Pronóstico del **modelo M0** con la información disponible hasta el `{python} ultima_fecha`, para los 20 equipos de la temporada `{python} sim['temporada']`.

**Uso académico.** No es una recomendación de apuesta. Cualquier simulación de apuestas debe usar capital ficticio.

</div>
```

- Es HTML (`<div class="sim-aviso">`) con **líneas en blanco** dentro: así Pandoc interpreta el interior como Markdown
  (negritas y expresiones en línea funcionan). `.sim-aviso` le da letra chica, gris y una línea superior.
- Expresiones: `ultima_fecha` → "14 de septiembre de 2026" y `sim['temporada']` → "2026/27". "20 equipos" está
  **escrito a mano** (es `len(sim['equipos'])`).
- El aviso deja claro el **uso académico**: no es una recomendación de apuesta, y cualquier simulación debe usar capital
  ficticio.

#### 2.7.7 Las tres tarjetas de probabilidad (líneas 482–496)

````markdown
## Column

### Row {height=150px}

```{ojs}
//| echo: false
html`<div class="sim-kpis">
  <div class="sim-kpi local"><div class="etq">Gana ${local}</div><div class="val">${fmtp(partido.p_local)}</div>
    <div class="det">${partido.lambda_local.toFixed(2)} goles esperados</div></div>
  <div class="sim-kpi"><div class="etq">Empate</div><div class="val">${fmtp(partido.p_empate)}</div>
    <div class="det">Marcador más probable: ${partido.marcador} (${fmtp(partido.p_marcador)})</div></div>
  <div class="sim-kpi visita"><div class="etq">Gana ${visita}</div><div class="val">${fmtp(partido.p_visita)}</div>
    <div class="det">${partido.lambda_visita.toFixed(2)} goles esperados</div></div>
</div>`
```
````

- `` html`…` `` construye el HTML de **tres tarjetas** dentro de un contenedor `.sim-kpis`; cada `${…}` se sustituye por su
  valor y la celda **se vuelve a dibujar** cuando cambian `local`, `visita` o `partido`.
- Cada `.sim-kpi` tiene tres líneas: la **etiqueta** (`.etq`: "Gana Arsenal"), el **valor grande** (`.val`: el porcentaje con
  `fmtp`) y el **detalle** (`.det`). La del local muestra sus **goles esperados** λ con dos decimales
  (`lambda_local.toFixed(2)`); la del visitante, los suyos; la del empate, el **marcador más probable** y su
  probabilidad.
- Los colores no los pone esta celda sino el CSS: `.sim-kpi.local` lleva una línea superior **verde** (el color del local
  en todo el tablero), `.sim-kpi.visita` **violeta** y la del empate **gris** ([3.2](#32-estilosscss)).
- Ejemplo (Arsenal local contra Man City, verificado en la página 6): λ **1.538** y **1.266** (se ven como 1.54 y 1.27),
  empate **25.00 %**, victoria de Man City **31.35 %**, y marcador más probable **1-1 (11.8%)**.
- Las tres probabilidades **suman 100 %** (Skellam reparte toda la probabilidad entre las tres opciones), pero con el
  redondeo a un decimal la suma mostrada puede diferir una décima.

#### 2.7.8 El mapa de calor de marcadores (líneas 498–521)

````markdown
### Row {height=520px}

```{ojs}
//| echo: false
//| title: "Probabilidad de cada marcador (%)"
{
  const celdas = partido.matriz.flatMap((fila, i) => fila.map((p, j) => ({gl: i, gv: j, p})));
  const [mh, mv] = partido.marcador.split("-").map(Number);
  return Plot.plot({
    width: 540, height: 420, marginLeft: 64, marginBottom: 48, marginTop: 8,
    style: {fontFamily: 'system-ui, -apple-system, "Segoe UI", sans-serif', fontSize: "12px", color: "#52514e"},
    x: {label: `Goles de ${visita} →`, domain: d3.range(6), labelAnchor: "center", labelOffset: 38, tickSize: 0},
    y: {label: `↓ Goles de ${local}`, domain: d3.range(6), labelAnchor: "center", labelOffset: 50, tickSize: 0},
    color: {type: "linear", range: ["#eef5fd", "#184f95"]},
    marks: [
      Plot.cell(celdas, {x: "gv", y: "gl", fill: "p", inset: 1.5, rx: 4, tip: true,
        title: d => `${local} ${d.gl} – ${d.gv} ${visita}: ${(d.p * 100).toFixed(1)}%`}),
      Plot.text(celdas, {x: "gv", y: "gl", text: d => (d.p * 100).toFixed(1),
        fill: d => d.p > 0.075 ? "white" : "#0b0b0b"}),
      Plot.cell([{gl: mh, gv: mv}], {x: "gv", y: "gl", fill: "none", stroke: "#0b0b0b", strokeWidth: 2, inset: 1, rx: 4})
    ]
  });
}
```
````

**Línea por línea:**

1. `//| title: "…"` convierte la salida de la celda en una **tarjeta** con ese título.
2. `{ … return …; }`: las llaves hacen que la celda sea un **bloque** (se pueden declarar variables con `const` y devolver
   el resultado con `return`). Lo que devuelve es el dibujo.
3. `celdas`: `partido.matriz` es una lista de **6 filas × 6 columnas** (goles del local de 0 a 5 × goles del visitante de
   0 a 5). `flatMap` + `map` la convierte en una lista **larga** de 36 objetos `{gl, gv, p}` (goles local, goles
   visitante, probabilidad). En R es `expand.grid(gv = 0:5, gl = 0:5)` con `p = as.vector(t(matriz))`, o un
   `pivot_longer`.
4. `[mh, mv] = partido.marcador.split("-").map(Number)`: separa el texto "1-1" en `["1","1"]` y lo pasa a números
   (`[1, 1]`) para saber qué celda resaltar. (Es una *desestructuración*: asigna los dos elementos a la vez.)
5. `Plot.plot({…})` dibuja con **Observable Plot**. `width: 540, height: 420` son **tamaños fijos** (el mapa no se
   adapta al ancho de la tarjeta) y los `margin*` dejan lugar a las etiquetas; `style` fija fuente, tamaño y color.
6. `x:` y `y:`: ejes **ordinales** con `domain: d3.range(6)` = `[0,1,2,3,4,5]` (así siempre salen las seis filas y
   columnas, aunque haya probabilidades casi cero). Las etiquetas llevan una flecha que indica hacia dónde crecen los goles:
   "Goles de {visita} →" y "↓ Goles de {local}" (en el eje vertical el 0 queda **arriba**). `tickSize: 0` quita las
   marquitas.
7. `color: {type: "linear", range: ["#eef5fd", "#184f95"]}`: escala de color **lineal** del azul muy claro (poca
   probabilidad) al azul oscuro (mucha). No se fija el dominio, así que Plot usa de **mínimo a máximo de cada cruce**:
   el mismo tono significa probabilidades distintas en cruces distintos; para eso cada celda lleva su número.
8. Las tres **capas** (`marks`), una encima de otra:
   - `Plot.cell(celdas, {x: "gv", y: "gl", fill: "p", …})`: un rectángulo por celda, relleno según `p`; `inset: 1.5` deja
     un espacio entre celdas, `rx: 4` redondea las esquinas y `tip: true` activa el **mensaje al pasar el cursor**, cuyo
     texto es `title` ("Arsenal 1 – 1 Man City: 11.8%").
   - `Plot.text(celdas, …)`: escribe en cada celda el porcentaje con un decimal; el texto es **blanco si p > 7.5 %** (las
     celdas oscuras) y casi negro si no, para que siempre se lea.
   - `Plot.cell([{gl: mh, gv: mv}], {fill: "none", stroke: "#0b0b0b", strokeWidth: 2, …})`: un **recuadro negro** sin
     relleno sobre el **marcador más probable**.
9. El mapa cubre de 0 a 5 goles: contiene entre **90.1 % y 99.8 %** de la probabilidad de cada cruce (99.3 % en
   Arsenal–City, [13a.6](13a_codigo_datos_dashboard.md#13a6-sección-6-simulador-líneas-697744)); lo que falta son marcadores de
   6 o más goles.
10. En el cruce de ejemplo, el recuadro cae en **1–1 (11.8 %)**; ese marcador es el más probable en 239 de los 380 cruces.

**En R (ilustrativo, estático; con `plotly::ggplotly()` se obtiene el mensaje al pasar el cursor):**

```r
celdas <- expand.grid(gv = 0:5, gl = 0:5)
celdas$p <- as.vector(t(matriz))                       # matriz: 6 x 6, filas = goles del local
mh <- 1; mv <- 1                                       # marcador más probable (de "1-1")
ggplot(celdas, aes(gv, gl, fill = p)) +
  geom_tile(color = "white", linewidth = 1.5) +                                          # ≈ Plot.cell
  geom_text(aes(label = sprintf("%.1f", p * 100), color = p > 0.075), size = 3.5, show.legend = FALSE) +   # ≈ Plot.text
  scale_color_manual(values = c("TRUE" = "white", "FALSE" = "#0b0b0b")) +
  geom_tile(data = data.frame(gl = mh, gv = mv), fill = NA, color = "#0b0b0b", linewidth = 1) +           # el recuadro
  scale_fill_gradient(low = "#eef5fd", high = "#184f95", guide = "none") +
  scale_x_continuous(breaks = 0:5) + scale_y_reverse(breaks = 0:5) +                     # el 0 arriba, como en Plot
  labs(x = paste("Goles de", visita, "→"), y = paste("↓ Goles de", local)) + coord_fixed()
```

#### 2.7.9 La tabla "¿De dónde sale el pronóstico?" (líneas 523–550)

````markdown
```{ojs}
//| echo: false
//| title: "¿De dónde sale el pronóstico?"
{
  const L = sim.stats.find(s => s.equipo === local);
  const V = sim.stats.find(s => s.equipo === visita);
  return html`<table class="tabla">
    <thead><tr><th>Variable de M0</th><th>${local}</th><th>${visita}</th></tr></thead>
    <tbody>
      <tr><td>Elo antes del partido</td><td>${L.elo.toFixed(0)}</td><td>${V.elo.toFixed(0)}</td></tr>
      <tr><td>Goles a favor por partido (temporada)</td><td>${L.gf.toFixed(2)}</td><td>${V.gf.toFixed(2)}</td></tr>
      <tr><td>Goles en contra por partido (temporada)</td><td>${L.ga.toFixed(2)}</td><td>${V.ga.toFixed(2)}</td></tr>
      <tr><td>Partidos jugados en ${sim.temporada}</td><td>${L.partidos_temporada}</td><td>${V.partidos_temporada}</td></tr>
    </tbody>
  </table>
  <p class="nota" style="margin-top:.8rem">Diferencia de Elo: <b>${Math.abs(L.elo - V.elo).toFixed(0)} puntos</b> a favor de
  ${L.elo >= V.elo ? local : visita}. ${sim.k_shrinkage === 0
    ? html`Los goles a favor y en contra son promedios de la temporada en curso
      (<i>shrinkage</i> k = ${sim.k_shrinkage}: la calibración del equipo mostró que mezclarlos con la temporada anterior no
      mejora el pronóstico). Antes del primer partido de la temporada se usa la anterior, y un equipo recién ascendido
      recibe el promedio de la liga. Con pocos partidos jugados, estos promedios todavía varían mucho.`
    : html`Los goles a favor y en contra mezclan la temporada en curso con la anterior
      (<i>shrinkage</i> k = ${sim.k_shrinkage}, peso n/(n+k) a la actual): con pocos partidos jugados pesa más la
      temporada pasada, y un equipo recién ascendido recibe el promedio de la liga.`}</p>
  <p class="nota">El marcador más probable (recuadro negro) suele ser corto. Un equipo puede ser favorito aunque
  el marcador individual más probable sea un empate, porque su victoria suma muchos marcadores distintos.</p>`;
}
```
````

- `L` y `V` son las **estadísticas** de cada equipo (`sim.stats.find(...)`, igual que `partido`). La tabla muestra las
  **variables que usa M0** para este cruce: el **Elo** de cada uno (0 decimales), los **goles a favor** y **en contra**
  por partido de la temporada (2 decimales) y los **partidos jugados** en 2026/27. Usa la clase `tabla`, la misma de las
  tablas de Python, así que se ve igual.
- La primera nota calcula la **diferencia de Elo** (`Math.abs(L.elo − V.elo)`) y dice a favor de quién (`L.elo >= V.elo ?
  local : visita`, un condicional). Ejemplo: Arsenal 1,787.1 contra Man City 1,779.2 → **8 puntos a favor de Arsenal**.
- **La nota condicional a k.** `${sim.k_shrinkage === 0 ? html`…` : html`…`}` elige entre **dos explicaciones** según el
  valor de k que Python mandó (`sim.k_shrinkage`; `===` es la igualdad estricta de JavaScript):
  - **k = 0 (el caso actual):** "los goles a favor y en contra son promedios de la temporada en curso (*shrinkage* k = 0: la
    calibración del equipo mostró que mezclarlos con la temporada anterior no mejora el pronóstico)"; antes del primer
    partido se usa la temporada anterior y un equipo recién ascendido recibe el promedio de la liga; y "con pocos partidos
    jugados, estos promedios todavía varían mucho".
  - **k ≠ 0:** explicaría la mezcla con peso n/(n+k) a la temporada actual.
  Es la versión en el navegador de la frase condicional `texto_k` ([2.2.7](#227-las-frases-condicionales-líneas-87102)):
  si se volviera a calibrar y k cambiara, el texto se ajustaría solo.
- **Un punto a tener presente:** al corte del simulador **los 20 equipos llevan sólo 4 partidos** de 2026/27 y, con k = 0,
  sus goles a favor y en contra son promedios de **cuatro partidos** (por ejemplo, Arsenal 2.00 a favor y 0.25 en
  contra). Por eso M0 es poco estable ahora, y la nota lo dice ("todavía varían mucho").
- La segunda nota recuerda que el marcador más probable suele ser corto (1–1 en 239 de los 380 cruces) y que un equipo
  puede ser favorito aunque su marcador individual más probable sea un empate, "porque su victoria suma muchos marcadores
  distintos".

#### 2.7.10 Cómo se encadena todo

```text
ojs_define(sim=…) ──► sim ──► viewof local ──► viewof visita ──► partido ──┬─► tarjetas de probabilidad (usa fmtp)
   (Python, al generar)                │               ▲                    ├─► mapa de calor (usa local, visita)
                                       └───────────────┘                    └─► tabla (usa sim.stats, local, visita, sim.k_shrinkage)
```

Al elegir otro equipo local: (1) cambia `local`; (2) `viewof visita` se recrea (nuevas opciones y valor inicial); (3)
`partido` se recalcula con el nuevo par; (4) se redibujan las tarjetas, el mapa y la tabla. Todo en el navegador, sin
volver a ejecutar nada de Python.

**Limitaciones del simulador** (para quien pregunte): sólo hay los **380 cruces** de la fecha de corte; no admite
ajustes (lesiones, alineaciones); el mapa tiene un **ancho fijo** de 540 px; depende de jsDelivr para cargar Plot e
Inputs; y las probabilidades son de M0, no del mercado (no se compara en vivo).

**Alternativa en R (ilustrativo, sección [4](#4-equivalentes-en-r-ilustrativos)):** con Shiny, `crosstalk` o,
la más parecida, Quarto con un chunk de R y `ojs_define()` (las celdas OJS no cambian).

### 2.8 Página 6: Datos y método

Líneas 552–669. Es el **respaldo** de la historia: de dónde salen los datos, cómo se limpiaron, qué variables usa el modelo,
cómo se evaluó, qué límites tiene y cómo reproducirlo. Es una sola fila de **8 pestañas**; es la página con más
expresiones en línea (**41** de las 83).

```text
┌──────────────────────────── # Datos y método {#datos} ────────────────────────────┐
│ ## Row {.tabset height=660px}                                                       │
│   [ Datos y procedencia | Limpieza y calidad | Variables del modelo | Evaluación |  │
│     Limitaciones y extensiones | Reproducibilidad | Glosario | Equipo ]             │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

Aquí hay **dos tipos de tablas** con aspecto distinto: las que se arman en Python con `gr.tabla_html` (auditoría y
verificación) llevan la clase `tabla` y el estilo del proyecto; las que se escriben en Markdown con barras `|`
(definiciones, variables, glosario) las convierte Pandoc y sólo reciben las clases de Bootstrap (`caption-top table`), sin
las reglas `table.tabla` de `estilos.scss`.

#### 2.8.1 "Datos y procedencia" (líneas 556–570)

Dos párrafos y una tabla de definiciones. El texto, con las cifras ya sustituidas:

> **Fuente.** Football-Data.co.uk: un archivo CSV por temporada de la Premier League (código `E0`), de 2001/02 a
> 2026/27. Son **26** archivos; el último llega hasta el **14 de septiembre de 2026**. Se descargan directamente del
> sitio, sin API.
>
> **Consolidación** (`Limpieza de datos.ipynb`). Se unieron los **26** archivos con las **23** columnas presentes en
> todas las temporadas (división, fecha, equipos, resultado final y al medio tiempo, árbitro, tiros, tiros a puerta,
> faltas, córners y tarjetas) y **11** complementarias (cuotas de Bet365, cuotas promedio de apertura y de cierre, y
> goles esperados). Resultado: `E0_consolidado.csv`, con **9,540 partidos × 34 variables**.

| Expresión | Valor | Qué es y de dónde sale |
|---|---|---|
| `g['temporadas']` (dos veces) | **26** | Temporadas distintas del histórico ([13a.4.1](13a_codigo_datos_dashboard.md#13a41-resumen_general)): un archivo por temporada |
| `ultima_fecha` | 14 de septiembre de 2026 | Último partido del histórico |
| `est['comunes']` | **23** | Columnas **sin ningún vacío**, que son las "presentes en todas las temporadas" ([13a.7.1](13a_codigo_datos_dashboard.md#13a71-estructura_base)) |
| `est['complementarias']` | **11** | Columnas con vacíos (34 − 23). Según el propio texto son las cuotas de Bet365, las cuotas promedio de apertura y de cierre y los goles esperados: 3 + 3 + 3 + 2 = 11 |
| `f"{g['partidos']:,}"` y `est['columnas']` | **9,540** y **34** | Filas y columnas de `E0_consolidado.csv` (23 + 11 = 34) |

La lista entre paréntesis (división, fecha, equipos…) es texto fijo; suma 23 columnas, así que coincide con el cálculo.
La **tabla de definiciones** (unidad de análisis, población, periodo, variable objetivo, variables explicativas,
referencia externa y datos complementarios) es Markdown fijo; su fila "Periodo" (2001–2026 para el histórico y 2019/20–2026/27
para modelar) está escrita a mano. Cómo se hicieron la limpieza y la consolidación: [capítulo 3](03_limpieza_de_datos.md).

#### 2.8.2 "Limpieza y calidad" (líneas 572–588)

Siete decisiones de limpieza (lista numerada) y, debajo, la tabla de auditoría. La estructura con el chunk:

````markdown
::: {.card title="Limpieza y calidad"}
**Decisiones de limpieza**

1. **Lectura completa de los archivos.** No se descartan renglones con formato irregular. Una primera versión lo hacía y perdía 90 partidos de 2003/04 y 2004/05.
   … (siete puntos) …
6. **Se excluyeron `{python} len(d['excluidos'])` partidos** de equipos debutantes sin partidos previos en la base para calcular tiros.
7. **Revisiones de consistencia** en el notebook: duplicados, un equipo contra sí mismo, … cuotas ≤ 1 y xG negativos.

**Revisión de calidad de `E0_consolidado.csv`**

```{python}
HTML(tabla_auditoria)
```
:::
````

| # | Decisión | Qué significa |
|---|---|---|
| 1 | Lectura completa | Ningún renglón descartado; la primera versión perdía 90 partidos de 2003/04 y 2004/05 (recuperados) |
| 2 | Sin eliminar por cuotas o xG faltantes | Esas columnas quedan vacías; el histórico completo sirve para el Elo |
| 3 | Fechas homologadas | Los archivos viejos usan `dd/mm/aa` y los recientes `dd/mm/aaaa`; se leyeron con el **día primero**, se exportaron en ISO y se verificó que ninguna fecha invirtiera día y mes |
| 4 | Orden cronológico estricto | Para calcular cada variable **sin usar información del futuro** |
| 5 | La modelación empieza en agosto de 2019 | Es cuando aparecen las cuotas promedio de apertura y de cierre: se puede comparar con el mercado y quedan cinco temporadas de entrenamiento |
| 6 | Se excluyeron **4** partidos (`len(d['excluidos'])`) | Equipos debutantes sin partidos previos para calcular tiros |
| 7 | Revisiones de consistencia | Duplicados, un equipo contra sí mismo, negativos, goles al medio tiempo mayores que los finales, tiros a puerta mayores que tiros, resultado contra marcador, cuotas ≤ 1 y xG negativos |

La **única expresión en línea** de la tarjeta es `len(d['excluidos'])` → **4**: el número de filas de
`partidos_excluidos()` ([13a.7.4](13a_codigo_datos_dashboard.md#13a74-partidos_excluidos)). "Cinco temporadas de entrenamiento" y
"90 partidos" son texto fijo. La tabla de auditoría (`tabla_auditoria`) tiene **10 filas** de
[`auditoria_datos`](13a_codigo_datos_dashboard.md#13a75-auditoria_datos); la que muestra el sitio:

| Revisión | Resultado | Comentario |
|---|---|---|
| Registros | 9,540 partidos, 34 columnas | Base completa del equipo, 18-08-2001 a 14-09-2026 |
| Duplicados (fecha, local, visitante) | 0 | Sin duplicados |
| Resultado (FTR) incongruente con los goles | 0 | Sin incongruencias |
| Temporadas incompletas | Ninguna | Las 25 temporadas completas tienen 380 partidos (una primera lectura descartaba 90 de 2003/04 y 2004/05) |
| Tiros a puerta mayores que tiros | 1 | Error de la fuente: Newcastle–West Ham 2021-08-15; no se corrigió |
| Goles mayores que tiros a puerta | 50 | Plausible (autogoles); no es error |
| Cuotas Bet365 | faltan en 2001/02 | Se usan desde 2002/03 para el análisis histórico del mercado |
| Cuotas promedio de apertura y cierre | sólo desde 2019/20 | Por eso la comparación modelo–mercado es 2024/25–2026/27 |
| Goles esperados (xG) | sólo 2026/27 | No se usan: cobertura insuficiente |
| Partidos excluidos de la base de modelación | 4 | Equipos sin historial previo de tiros en la base (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026) |

Siete de las diez filas se calculan; **tres son texto fijo** (Bet365, cuotas promedio y xG) y también la nota de los 90
partidos; se comprobaron y son ciertas ([13a.9](13a_codigo_datos_dashboard.md#13a9-detalles-raros-y-comentarios-desactualizados)).
La fila de los 4 partidos excluidos concuerda con la celda que Daniel agregó al notebook (Brentford, Nott'm Forest, Luton y
Coventry; [capítulo 11](11_codigo_analisis_notebook.md)).

#### 2.8.3 "Variables del modelo" (líneas 590–601)

Una tabla en Markdown (variable, cómo se construye, parámetro) y un párrafo de especificaciones; **todo lo que es número
es expresión en línea**, incluso dentro de las celdas de la tabla. Lo que muestra el sitio:

> Todas se calculan sólo con partidos **anteriores** al encuentro (`wc_predictor.py`):

| Variable | Cómo se construye | Parámetro |
|---|---|---|
| Diferencia de Elo | Rating que sube al ganar y baja al perder, más cuanto más inesperado el resultado; entra como (Elo local − Elo visitante) / **400** | Inicial **1,500**, K = **15** (calibrado) |
| Goles a favor y en contra de la temporada | Promedio de la temporada en curso; antes de su primer partido, el de la temporada anterior (o el de la liga, si el equipo no jugó en Premier). La mezcla con la temporada anterior (*shrinkage*, peso n/(n+k) a la actual) se calibró y el mejor valor fue **k = 0, es decir, sin mezcla** | k = **0** (calibrado) |
| Forma reciente | Promedio ponderado de goles de los últimos **10** partidos, con más peso a los recientes | Decaimiento **0.85** |
| Tiros y tiros a puerta | Mismo promedio ponderado, a favor y concedidos | **10** partidos, **0.85** |

> **Especificaciones comparadas.** M0 = Elo + goles de la temporada (**3** variables por ecuación) · M1 = M0 + forma · M2
> = M0 + tiros · M3 = M0 + tiros a puerta · M4 = todo (**9** variables). En M4 las variables se traslapan (correlación de
> **0.86** entre tiros y tiros a puerta; VIF máximo **5.6**), lo que vuelve inestables sus coeficientes.

| Expresión | Valor | Qué es |
|---|---|---|
| `f"{dd.ESCALA_ELO:g}"` | 400 | Escala del Elo (`wc_predictor.ELO_SCALE`) |
| `elo_inicial` | 1,500 | `wc_predictor.ELO_INIT` con coma de miles |
| `f"{dd.K_ELO:g}"` | 15 | K del Elo, calibrado (`wc_predictor.ELO_K`) |
| `texto_k` y `f"{dd.K_SHRINKAGE:g}"` | "k = 0, es decir, sin mezcla" y 0 | k del *shrinkage*, calibrado (`wc_predictor.SHRINKAGE_K`); `texto_k` es la frase condicional de [2.2.7](#227-las-frases-condicionales-líneas-87102) |
| `dd.N_FORMA` (dos veces) | 10 | Ventana de la forma reciente, **leída del código del notebook** |
| `decaimiento` (dos veces) | 0.85 | Decaimiento de la forma, también leído del notebook |
| `n_var_m0`, `n_var_m4` | 3 y 9 | Variables por ecuación |
| `num(diag['corr_tiros_puerta'], 2)`, `num(diag['vif_max'], 1)` | 0.86 y 5.6 | Diagnóstico de M4 ([13a.7.3](13a_codigo_datos_dashboard.md#13a73-diagnostico_m4)): correlación y VIF máximo |

Qué es cada variable y por qué: Elo ([capítulo 4](04_elo.md)), promedios de temporada y forma reciente
([capítulo 5](05_promedios_ajustados_y_forma.md)). Dos observaciones: el "Inicial 1,500" y el "/ 400" salen del código,
pero el texto "entra como (Elo local − Elo visitante) / 400" es fijo; y las definiciones de M1 a M3 ("M1 = M0 + forma"…)
son texto fijo que coincide con `ESPECIFICACIONES` ([13a.1.11](13a_codigo_datos_dashboard.md#13a111-grupos-y-especificaciones)).

**En R (ilustrativo):** una tabla de Markdown con código en línea se escribe igual en R Markdown; sólo cambia la sintaxis
de la expresión.

```markdown
| Diferencia de Elo | Rating que sube al ganar… (Elo local − Elo visitante) / `r ESCALA_ELO` | Inicial `r format(ELO_INIT, big.mark = ",")`, K = `r K_ELO` (calibrado) |
```

#### 2.8.4 "Evaluación" (líneas 603–610)

Seis viñetas en Markdown; las cifras son expresiones en línea. El texto, con los valores ya sustituidos:

> - **Partición temporal, no aleatoria.** El modelo aprende del pasado y se evalúa con el futuro, como se usaría en la
>   práctica. Entrenamiento 2019/20–2023/24 (**1,897**), validación 2024/25 (**380**) y prueba del 15 de agosto de 2025
>   al **14 de septiembre de 2026** (**419**). Los coeficientes no se reestiman después del entrenamiento.
> - **LogLoss (métrica principal).** Menos el promedio del logaritmo de la probabilidad asignada al resultado que ocurrió.
>   Premia dar mucha probabilidad a lo que pasa y castiga la sobreconfianza. Como referencia, el azar puro da ln 3 ≈ 1.099,
>   y exp(−LogLoss) es la probabilidad media (geométrica) asignada al resultado real.
> - **Calibración de K y k.** El K del Elo y el k del *shrinkage* se eligieron con validación temporal de ventana
>   creciente: se entrena con todo lo anterior y se evalúa en **2021/22, 2022/23 y 2023/24**, todas dentro del periodo de
>   entrenamiento. Se probaron K de **15 a 45** y k de **0 a 20** con M0, y ganó la combinación de menor LogLoss: K = **15**
>   y k = **0**. Ni la validación 2024/25 ni la prueba se usaron para elegirlos.
> - **MAE de goles.** Error absoluto medio entre goles observados y esperados; evalúa λ, no las probabilidades 1X2.
> - **Complementos.** Tasa de aciertos (fácil de comunicar, pero ignora la confianza), intervalos bootstrap, calibración y
>   descomposición de la brecha con el mercado.
> - **Mercado.** Probabilidad implícita = 1/cuota, normalizada para que las tres sumen 1. Esto retira el margen de la casa
>   de apuestas: **4.49 %** en validación y **5.84 %** en prueba, en promedio.

| Expresión | Valor | Qué es y de dónde sale |
|---|---|---|
| `f"{n_train:,}"`, `n_val`, `n_test` | 1,897 · 380 · 419 | Tamaño de las particiones ([13a.3.4](13a_codigo_datos_dashboard.md#13a34-particiones)) |
| `ultima_fecha` | 14 de septiembre de 2026 | Fin de la prueba = último partido del histórico |
| `lista(cfg['folds'])` | "2021/22, 2022/23 y 2023/24" | Temporadas que evalúan los pliegues de la calibración, **leídas del código del notebook** ([13a.1.6](13a_codigo_datos_dashboard.md#13a16-configuracion_notebook)); `lista` las une en español ([2.2.6](#226-lista-y-rango-líneas-8185)) |
| `rango(rejilla_K)` y `rango(rejilla_k)` | "15 a 45" y "0 a 20" | Valores probados (la rejilla de 35 combinaciones), también leídos del notebook |
| `f"{dd.K_ELO:g}"` y `f"{dd.K_SHRINKAGE:g}"` | 15 y 0 | Los valores elegidos (`wc_predictor.ELO_K` y `SHRINKAGE_K`) |
| `num(d['margen']['Validación'], 2)` y `num(d['margen']['Prueba'], 2)` | 4.49 y 5.84 (el texto agrega " %") | Margen promedio de la casa de apuestas, en puntos porcentuales, que calcula `probabilidades_mercado` ([13a.2.8](13a_codigo_datos_dashboard.md#13a28-probabilidades_mercado)) |

Notas: "prueba del 15 de agosto de 2025" y los periodos de entrenamiento y validación están escritos a mano (las fechas de
corte de `datos_dashboard.py` son 2024-08-01 y 2025-08-01; el primer partido de la prueba es del 15 de agosto). La frase
"ni la validación 2024/25 ni la prueba se usaron para elegirlos" es cierta **para K y k**; la **preferencia por M0** como
modelo del simulador sí tomó en cuenta la prueba ([capítulo 9](09_evaluacion_y_validacion.md)).

#### 2.8.5 "Limitaciones y extensiones" (líneas 612–629)

Dos listas: seis limitaciones y cinco extensiones. Las que llevan expresiones, tal como las muestra el sitio:

> - **Independencia entre goles.** Poisson + Skellam supone que los goles de un equipo no dependen de los del otro; por eso
>   subestima los empates (ver "Calibración" en *El modelo*).
> - **Parámetros optimizados sólo en parte.** K y k se calibraron en una rejilla (K de **15 a 45**, k de **0 a 20**) y sólo
>   con M0. **El K elegido quedó en el borde inferior de la rejilla, así que un valor menor podría ser aún mejor.** El
>   decaimiento **0.85** y la ventana de **10** partidos no se optimizaron.
> - **Equipos ascendidos.** El Elo sólo usa partidos de Premier: un equipo que regresa conserva el Elo de su última
>   temporada en primera, a veces de hace años, y uno nuevo empieza con **1,500**. Su forma reciente también puede venir de
>   temporadas lejanas.
> - **Información ausente.** Alineaciones, lesiones, calendario, descanso y fichajes, que el mercado sí considera.
> - **Muestra de prueba pequeña** (**419** partidos): las diferencias entre especificaciones caen dentro del ruido.
> - **Mercado aproximado.** Cuotas promedio con normalización proporcional; no se evaluó rentabilidad.
>
> **Posibles extensiones:** corrección de Dixon–Coles o regresión binomial negativa · **Ampliar la búsqueda de K por debajo
> de 15 y optimizar también el decaimiento y la ventana de forma reciente** · Elo con segunda división · goles esperados (xG)
> y cuotas de cierre · detectar equipos que el mercado sobrevalora o infravalora.

| Expresión | Valor | Qué es |
|---|---|---|
| `rango(rejilla_K)`, `rango(rejilla_k)` (dos veces cada una en el archivo: aquí y en "Evaluación") | "15 a 45" y "0 a 20" | Rejillas de la calibración |
| `texto_borde` | "El K elegido quedó en el borde inferior…" | Frase condicional ([2.2.7](#227-las-frases-condicionales-líneas-87102)) |
| `decaimiento` y `dd.N_FORMA` | 0.85 y 10 | Parámetros de la forma reciente (del notebook) |
| `elo_inicial` | 1,500 | Elo con el que empieza un equipo nuevo |
| `n_test` | 419 | Partidos de la prueba |
| `texto_extension_K` | "Ampliar la búsqueda de K por debajo de 15 y optimizar" | Frase condicional; la oración sigue con "también el decaimiento y la ventana de forma reciente." |

**Por qué importa la frase del borde (para la defensa).** K = 15 es el valor **más bajo** de la rejilla, así que no se puede
afirmar que sea el óptimo: sólo que fue el mejor entre los probados. Una comparación hecha por la guía **después de la
entrega** (cálculo propio) con la configuración anterior (K = 30, k = 10) dio LogLoss de M0 de 0.983636 en validación y
1.030640 en prueba, contra 0.989547 y 1.033076 de la vigente, con diferencias **no significativas** (+0.0059 y +0.0024):
calibrar fue el procedimiento correcto, pero el efecto de K y k es pequeño e inestable, y la conclusión (cerca del
mercado, sin superarlo) no cambia. Elegir K mirando la prueba habría sido sobreajustar a la evaluación.

#### 2.8.6 "Reproducibilidad" (líneas 631–639)

````markdown
::: {.card title="Reproducibilidad"}
**Verificación.** El tablero recalcula todo desde los archivos del equipo cada vez que se genera. Esta tabla compara sus cifras con las que publica el notebook del equipo (`Analisis.ipynb`): `{python} "todas coinciden" if verificacion_ok else "HAY DIFERENCIAS: revisar antes de publicar"`.

```{python}
HTML(tabla_verificacion)
```

**Cómo reproducirlo.** Código, datos e instrucciones están en [github.com/pitirringo/futbol-apuestas](https://github.com/pitirringo/futbol-apuestas). Basta con instalar las dependencias de `Dashboard-o-pagina/requirements.txt` y ejecutar `quarto render Dashboard-o-pagina`. GitHub Actions hace exactamente eso en una máquina limpia con cada `git push` y publica el resultado en GitHub Pages; esta tabla confirma que las cifras se reproducen ahí.
:::
````

- **La frase condicional.** `` `{python} "todas coinciden" if verificacion_ok else "HAY DIFERENCIAS: revisar antes de publicar"` `` es
  una **expresión condicional de Python** (`a if condición else b`): escribe "todas coinciden" si `verificacion_ok` es
  `True` y, si no, la advertencia. En R sería `` `r if (verificacion_ok) "todas coinciden" else "HAY DIFERENCIAS: revisar antes de publicar"` ``.
- **La tabla** (`tabla_verificacion`, [13a.7.6](13a_codigo_datos_dashboard.md#13a76-tabla_verificacion)) compara 17 cifras: 12 LogLoss
  (M0 a M4 y mercado de apertura, en validación y en prueba; coinciden si difieren menos de 5 × 10⁻⁷) y 5 del ejemplo
  Arsenal–Man City (λ con 3 decimales; probabilidades con 4). La columna "Notebook" es lo que `Analisis.ipynb` **imprimió** en su
  última ejecución (se lee de sus salidas guardadas); "Dashboard" es lo que el tablero calculó; "Coincide" es ✓ o ✗:

| Cifra | Notebook | Dashboard | Coincide |
|---|---|---|---|
| LogLoss M0 · Base (validación) | 0.989547 | 0.989547 | ✓ |
| LogLoss M1 · + Forma (validación) | 0.987603 | 0.987603 | ✓ |
| LogLoss M2 · + Tiros (validación) | 0.980718 | 0.980718 | ✓ |
| LogLoss M3 · + Tiros a puerta (validación) | 0.982319 | 0.982319 | ✓ |
| LogLoss M4 · Completo (validación) | 0.978612 | 0.978612 | ✓ |
| LogLoss Mercado · Apertura (validación) | 0.970552 | 0.970552 | ✓ |
| LogLoss M0 · Base (prueba) | 1.033076 | 1.033076 | ✓ |
| LogLoss M1 · + Forma (prueba) | 1.034699 | 1.034699 | ✓ |
| LogLoss M2 · + Tiros (prueba) | 1.037331 | 1.037331 | ✓ |
| LogLoss M3 · + Tiros a puerta (prueba) | 1.033868 | 1.033868 | ✓ |
| LogLoss M4 · Completo (prueba) | 1.036739 | 1.036739 | ✓ |
| LogLoss Mercado · Apertura (prueba) | 1.020000 | 1.020000 | ✓ |
| Ejemplo Arsenal–Man City: λ Arsenal (M0) | 1.538 | 1.538 | ✓ |
| Ejemplo Arsenal–Man City: λ Man City (M0) | 1.266 | 1.266 | ✓ |
| Ejemplo Arsenal–Man City: P(victoria Arsenal) M0 | 0.4365 | 0.4365 | ✓ |
| Ejemplo Arsenal–Man City: P(empate) M0 | 0.2500 | 0.2500 | ✓ |
| Ejemplo Arsenal–Man City: P(victoria Man City) M0 | 0.3135 | 0.3135 | ✓ |

**17 de 17 ✓.** Cuando Daniel agregó M3 a la evaluación de prueba, la tabla pasó de 16 a 17 filas **sin tocar el tablero**: lee
las salidas del notebook. Qué demuestra y qué no: demuestra que las funciones del tablero (copiadas del notebook) dan **lo
mismo** que el notebook; **no** verifica el bootstrap, la calibración, el simulador (salvo Arsenal–Man City) ni las cifras
del reporte. Si el notebook se guardara sin salidas, la tabla marcaría ✗ y la frase diría "HAY DIFERENCIAS", pero **la
publicación no se detendría** ([13a.9](13a_codigo_datos_dashboard.md#13a9-detalles-raros-y-comentarios-desactualizados), punto 14;
cómo se publica, en el [capítulo 14](14_publicacion_en_github.md)).

- **"Cómo reproducirlo"** es la versión corta; el `README.md` de la raíz del repositorio trae los pasos completos (versiones,
  huellas SHA-256, repetición de la rejilla).
- Una precisión: "esta tabla confirma que las cifras se reproducen ahí [en GitHub]" es cierta porque el sitio publicado
  muestra también 17 de 17.

#### 2.8.7 "Glosario" (líneas 641–656)

Una tabla de dos columnas en Markdown, **texto fijo**, con 12 términos: **1X2**, **cuota decimal**, **cuotas de apertura y de
cierre**, **probabilidad implícita**, **margen**, **Elo**, **regresión de Poisson**, **Skellam**, ***shrinkage***,
**LogLoss**, **calibración** y **bootstrap**. Dos definiciones merecen cuidado en la exposición:

- **Cuotas de apertura y de cierre.** "Apertura" es **el nombre que usa el proyecto** para las cuotas promedio (`AvgH`,
  `AvgD`, `AvgA`) que Football-Data registra el viernes por la tarde (fin de semana) o el martes (entre semana); las de
  cierre (`AvgCH`…) son las últimas antes del partido. No son cuotas "de apertura del mercado" en el sentido estricto.
- **Skellam.** "Distribución de la diferencia entre dos conteos de Poisson independientes; da P(local), P(empate) y
  P(visitante)": la misma que usa el diagrama de la página 4.

#### 2.8.8 "Equipo" (líneas 658–669)

Texto fijo: "Proyecto final del Módulo 8, *Comunicación de resultados*. Diplomado de Introducción Analítica a la Ciencia de
Datos", la lista de los seis integrantes (Castillo Rodríguez Daniel Arturo, Castillo Santiago Erika Isabel, Garduño
Gutiérrez César Emiliano, Gómez Mendoza Maximiliano, Martínez Vega Eduardo y Zacateco Tello María Fernanda) y una línea
de créditos: "Datos: Football-Data.co.uk · Código: Python (pandas, statsmodels, scipy, scikit-learn) · Tablero: Quarto +
Plotly + Observable JS, publicado con GitHub Actions en GitHub Pages". Esta página **no menciona el uso de herramientas de
IA**; ese apartado está en el `README.md` de la raíz del repositorio ([capítulo 14](14_publicacion_en_github.md)).

**En R (ilustrativo):** las pestañas de texto con tablas son `### Título` dentro de `Row {.tabset}`; las tablas en Markdown
funcionan igual en R Markdown y la verificación sería un `kable()`.

```r
### Reproducibilidad
`r if (verificacion_ok) "todas coinciden" else "HAY DIFERENCIAS: revisar antes de publicar"`
knitr::kable(tabla_verif, format = "html")
```

## 3. Archivos de configuración y estilo

### 3.1 `_quarto.yml`

Doce líneas. Es la **configuración del proyecto**: Quarto la lee **antes** que `index.qmd`, y sus opciones valen para todos
los documentos del proyecto.

```yaml
project:
  type: default
  output-dir: _site
  render:
    - index.qmd

lang: es

execute:
  echo: false
  warning: false
  message: false
```

| Opción | Qué hace | Por qué está |
|---|---|---|
| `project:` | Declara que la carpeta es un **proyecto** de Quarto. Por eso se puede ejecutar `quarto render Dashboard-o-pagina` (con la carpeta, no con el archivo) | Es lo que hace GitHub Actions y lo que pide el README |
| `type: default` | Proyecto **sencillo**: ni sitio web (`website`) ni libro (`book`). Cada documento se renderiza por separado; la navegación entre páginas ya la da el formato `dashboard` | Hay un solo documento |
| `output-dir: _site` | Carpeta donde se escribe el resultado (`_site/index.html` y `_site/index_files/`) | Es el nombre habitual; el workflow sube `Dashboard-o-pagina/_site` a GitHub Pages ([capítulo 14](14_publicacion_en_github.md)) |
| `render: [index.qmd]` | **Lista explícita** de lo que se renderiza | Sin ella Quarto consideraría los archivos de la carpeta; así sólo se procesa el tablero. No se probó qué pasaría sin la línea |
| `lang: es` | Idioma por defecto del proyecto (en `index.qmd` se repite) | Textos de Quarto en español y atributo `lang` |
| `execute:` | Opciones de **ejecución** para todos los chunks | Ver abajo |
| `echo: false` | **No mostrar el código** de los chunks (el tablero es para leerlo, no para ver Python) | El código está en GitHub |
| `warning: false`, `message: false` | No mostrar avisos ni mensajes de los paquetes | Que no salgan advertencias de pandas, statsmodels o Plotly en la página |

Observaciones: **(1)** con `echo: false` global, las opciones `#| echo: false` que aparecen en `index.qmd` (en el chunk
`ojs_define` y en las celdas OJS) son **redundantes**; **(2)** apagar `warning` y `message` también oculta advertencias
útiles (por ejemplo, de convergencia); aquí la protección es la **tabla de verificación** (17 de 17); **(3)** `lang: es`
aparece dos veces (aquí y en el YAML de `index.qmd`) sin conflicto. Decisión relacionada:
[5.12](#512-código-oculto-y-avisos-apagados).

**En R (ilustrativo):** un sitio de R Markdown usa `_site.yml` y las opciones de chunk globales van en un chunk de
preparación; con Quarto y R el mismo `_quarto.yml` sirve sin cambios.

```yaml
# _site.yml (rmarkdown::render_site)
name: "futbol-apuestas"
output_dir: "_site"
```

```r
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)   # ≈ execute: echo/warning/message: false
```

### 3.2 `estilos.scss`

970 líneas. Es el **tema visual** del tablero: sobre el tema `cosmo` de Bootswatch, cambia colores y tipografía y agrega
reglas para tarjetas, *value boxes*, tablas, el diagrama de flujo y el simulador. El estilo general es de **vidrio**
(*glassmorphism*): fondos blancos translúcidos, bordes suaves, sombras y desenfoque de lo que queda detrás. Decisión
relacionada: [5.6](#56-tema-cosmo-y-estilosscss). Como son muchas reglas, aquí se explican **por secciones**: las que
cambian cómo funciona o se ve algo importante, una por una; las repetitivas (transiciones, sombras, esquinas), agrupadas.

#### 3.2.1 Cómo se aplica: Sass, dos capas y la lista del tema

- **SCSS** es una forma de escribir CSS con extras: **variables** (`$primary`), **anidamiento** (una regla dentro de otra,
  que se compila a un selector largo: `.navbar { .nav-link { … } }` → `.navbar .nav-link { … }`) y el **`&`** (el selector
  de afuera: `&:hover`, `&::before`, `&.modelo`). Quarto lo compila con Sass.
- Los comentarios `/*-- scss:defaults --*/` y `/*-- scss:rules --*/` **separan dos capas**. Lo que va en *defaults*
  se compila **antes** que el código de Bootstrap, así que **cambia sus variables** (colores, fuentes, radios). Lo que va
  en *rules* se compila **después**, así que **sus reglas ganan** a las de Bootstrap.
- En el YAML, `theme: [cosmo, estilos.scss]` es una lista: `cosmo` primero y este archivo después. El resultado es **un solo
  CSS** (`bootstrap-<huella>.min.css`, ≈ 457 KB) que ya trae Bootstrap, los componentes de tarjetas y *value boxes* de
  Quarto y las reglas de este archivo.
- **27 declaraciones usan `!important`.** Es necesario donde Quarto pone estilos con más fuerza (el fondo en línea de los
  *value boxes*, los colores de la barra en tema oscuro); el costo es que cualquier cambio posterior debe volver a usarlo.

#### 3.2.2 Mapa de secciones

| Sección (comentario del archivo) | Líneas | Qué hace | Peso |
|---|---|---|---|
| Variables de Sass (`scss:defaults`) | 1–17 | Cambia el color primario, la tipografía, el fondo y el radio de Bootstrap | Media |
| `:root` (variables CSS) | 22–61 | Paleta de la interfaz y de las gráficas, sombras y radios | Clave (12 de 29 sin uso) |
| `html`, `body` | 63–78 | Fondo con degradados y suavizado de letra | Estética |
| Layout | 81–86 | Separación entre filas y márgenes de cada página | Menor |
| Navbar y su "píldora" | 89–173 | Barra superior flotante de vidrio, enlaces redondeados, página activa oscura | Estética |
| Tabs | 176–225 | Las pestañas de las tarjetas con pestañas, como "píldoras" | Estética |
| Cards | 228–311 | Tarjetas de vidrio, brillo superior, elevación al pasar el cursor y **la regla de la altura** | **Clave** (la regla `:has`) |
| Subtítulos | 314–320 | Texto gris y pequeño bajo el título | Menor |
| Value boxes | 323–415 | Cajas de indicadores | **Clave** (`!important` y tipografía) |
| Pregunta, lectura, notas | 418–469 | Tarjeta de la pregunta, lista de conclusiones y notas | Media |
| Tablas | 472–533 | Tablas HTML: contenedor con desplazamiento, encabezado fijo | **Clave** |
| Diagrama de flujo | 536–645 | "Cómo funciona" (flex, pasos, flechas) | **Clave** |
| Simulador | 648–734 | Tarjetas de probabilidad y aviso | **Clave** |
| Controles y botones | 737–831 | Menús, campos y botones de vidrio | Menor |
| Leyendas | 834–873 | Cuadritos de color de las leyendas HTML | **Clave** |
| Plotly, títulos, barras de desplazamiento | 876–916 | Esquinas de las gráficas, tipografía de títulos, scrollbars finas | Menor |
| Responsive | 919–970 | Ajustes para pantallas de hasta 768 px | Media |

#### 3.2.3 La capa `defaults`: variables de Sass (líneas 1–17)

```scss
/*-- scss:defaults --*/
$primary: #2a78d6;
$font-family-sans-serif: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
$body-bg: #f4f5f7;
$body-color: #172033;
$navbar-bg: #3D195B;
$navbar-fg: #ffffff;
$navbar-hl: #2a78d6;
$link-color: #256abf;
$border-radius: .8rem;
```

| Variable | Qué cambia | Efecto real |
|---|---|---|
| `$primary` | El color "primario" de Bootstrap: `#2a78d6`, **el mismo azul del modelo** en las gráficas | Enlaces, botones primarios y componentes que usen `primary` |
| `$font-family-sans-serif` | La tipografía: la **pila de fuentes del sistema** (la del sistema operativo de quien visita) | No se descarga ninguna fuente web; es la misma que usa Plotly (`FUENTE` en `graficas.py`) |
| `$body-bg`, `$body-color` | Fondo (`#f4f5f7`) y color de texto (`#172033`) | El fondo lo tapa la regla de `body` (degradados); el color de texto sí aplica y coincide con `--ui-ink` |
| `$navbar-bg`, `$navbar-fg`, `$navbar-hl` | Colores de la barra superior: morado oscuro `#3D195B`, blanco y azul | **Sin efecto visible:** las reglas de la barra los anulan con `!important`. Parecen **un vestigio** de una versión anterior. En el HTML la barra sigue marcada `data-bs-theme="dark"` (probablemente por ese fondo oscuro), y por eso las reglas fuerzan el color de texto |
| `$link-color` | Color de los enlaces (`#256abf`) | Aplica |
| `$border-radius` | Redondeo base de Bootstrap (`.8rem`) | Aplica a los componentes que no definen el suyo; las tarjetas usan `--ui-radius-xl` |

**En R (ilustrativo):** estas variables se cambian con `bslib` (en flexdashboard, `theme:` apunta a un tema de `bslib`).

```r
tema <- bslib::bs_theme(version = 5, bootswatch = "cosmo", primary = "#2a78d6",
                        "font-family-sans-serif" = "system-ui, -apple-system, 'Segoe UI', Roboto, Arial, sans-serif",
                        "body-bg" = "#f4f5f7", "body-color" = "#172033", "link-color" = "#256abf",
                        "border-radius" = ".8rem")                                   # ≈ la capa defaults
tema <- bslib::bs_add_rules(tema, sass::sass_file("estilos.scss"))                   # ≈ la capa rules
# En Quarto con R (formato dashboard) no cambia nada: el mismo theme: [cosmo, estilos.scss].
```

#### 3.2.4 Variables CSS en `:root` (líneas 22–61)

`:root` es la raíz del documento: ahí se declaran **variables de CSS** (`--nombre: valor`) que el resto de las reglas leen con
`var(--nombre)`. Cambiar un color en un solo lugar cambia todo lo que lo usa.

| Grupo | Variables | Para qué |
|---|---|---|
| Interfaz (texto) | `--ui-ink` (`#172033`), `--ui-ink-2` (`#626d80`), `--ui-ink-3` (`#8a94a6`) | Texto principal, secundario y terciario |
| Interfaz (fondo y acentos) | `--ui-bg`, `--ui-bg-soft`, `--ui-accent`, `--ui-accent-2`, `--ui-accent-hover` | Fondo de la página y el azul pizarra oscuro de pestañas activas |
| "Vidrio" | `--ui-glass`, `--ui-glass-soft`, `--ui-glass-strong`, `--ui-border`, `--ui-border-strong` | Blancos translúcidos y bordes claros |
| Sombras y radios | `--ui-shadow-sm`, `--ui-shadow`, `--ui-shadow-lg`; `--ui-radius-xl` (1.55rem), `-lg` (1.25rem), `-md` (.95rem) | Elevación y esquinas |
| **Colores de las gráficas** | `--modelo` `#2a78d6` (azul), `--mercado` `#eb6834` (naranja), `--local` `#008300` (verde), `--visita` `#4a3aa7` (violeta), `--contexto` `#898781` (gris) | **La misma paleta que `graficas.py`**, para que las partes en HTML (diagrama, tarjetas del simulador) usen el mismo color que las gráficas con el mismo significado |
| Auxiliares | `--tinta`, `--tinta-2`, `--rejilla`, `--borde`, `--fondo-suave` | Tinta y rejilla de las gráficas |

**Qué no se usa.** Se declaran **29** variables y **12 no se leen en ningún `var(…)`**: `--ui-bg-soft`, `--ui-ink-3`,
`--ui-accent-2`, `--ui-accent-hover`, `--ui-glass`, `--ui-glass-soft`, `--ui-glass-strong`, `--ui-radius-md`, `--tinta-2`,
`--rejilla`, `--borde` y `--fondo-suave`. Son restos de versiones anteriores; no dañan nada. Una precisión: las leyendas
HTML de `index.qmd` escriben el color **a mano** (`style="background:#898781"`), no con `var(--contexto)`; si se cambiara la
paleta habría que editar el SCSS, `graficas.py` **y** `index.qmd`.

#### 3.2.5 Fondo de la página y espaciado (líneas 63–86)

```scss
body {
  background:
    radial-gradient(circle at 7% 0%, rgba(117, 157, 225, .20), transparent 28rem),
    radial-gradient(circle at 96% 2%, rgba(174, 190, 221, .18), transparent 26rem),
    radial-gradient(circle at 50% 100%, rgba(255, 255, 255, .72), transparent 34rem),
    linear-gradient(180deg, #edf2f8 0%, #f8fafc 48%, #f2f5f9 100%);
  color: var(--ui-ink);
  -webkit-font-smoothing: antialiased;  -moz-osx-font-smoothing: grayscale;  text-rendering: optimizeLegibility;
}
.quarto-dashboard .dashboard-page, .quarto-dashboard #quarto-dashboard { gap: 1.2rem; padding: 1rem 1.15rem 1.5rem; }
```

- El `body` apila **cuatro fondos**: tres degradados radiales (resplandores azulados arriba a la izquierda y a la
  derecha, y uno blanco abajo) sobre un degradado lineal vertical muy claro. Sirven de **telón** para el efecto vidrio:
  `backdrop-filter` desenfoca lo que hay detrás de cada tarjeta, y sobre un fondo liso no se notaría.
- Las tres líneas de `-webkit-font-smoothing`, `-moz-osx-font-smoothing` y `text-rendering` sólo mejoran el suavizado de la
  letra.
- La regla de `.dashboard-page` fija el **espacio entre filas y tarjetas** (`gap: 1.2rem`) y el margen de cada página.

#### 3.2.6 Barra superior y pestañas (líneas 89–225)

```scss
.navbar {
  margin: .65rem .85rem 0;  border-radius: 1.35rem;
  background: linear-gradient(135deg, rgba(255,255,255,.68), rgba(255,255,255,.36)) !important;
  border: 1px solid rgba(255, 255, 255, .62) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.86), 0 14px 34px rgba(28,40,63,.065) !important;
  backdrop-filter: blur(24px) saturate(165%);
  .navbar-brand, .navbar-title { color: var(--ui-ink) !important; font-weight: 720; letter-spacing: -.025em; }
  .nav-link { color: #394457 !important; border-radius: 999px; padding: .55rem .95rem !important; … }
}
```

- La barra deja de ser una franja pegada arriba: es una **tarjeta flotante** (`margin`, `border-radius`) de vidrio
  (fondo blanco translúcido, borde claro, sombra interior y exterior, y `backdrop-filter: blur(24px) saturate(165%)` que
  desenfoca y satura lo que queda detrás). Los `!important` vencen al fondo morado que Quarto pondría.
- Anidadas están el título (`.navbar-brand`, `.navbar-title`: color tinta, negrita) y los enlaces (`.nav-link`: color
  gris azulado, forma de **píldora** con `border-radius: 999px`, transición suave y, al pasar el cursor, un fondo claro y
  un pequeño levantamiento `translateY(-1px)`).
- `.navbar-nav` (líneas 138–153) agrupa los enlaces en una **cápsula** translúcida; `.navbar-nav .nav-link.active`
  (155–173) pinta la **página activa** con un degradado azul pizarra oscuro (`#26354d → #344966`), texto blanco y sombra:
  así se sabe en cuál de las seis páginas se está.
- **Tabs** (176–225): las reglas de `.nav-tabs, .nav-pills` quitan la línea inferior y aplican **la misma forma de píldora**
  y **el mismo azul oscuro para la pestaña activa**. Son las pestañas de las tarjetas con `.tabset` (páginas 2, 3, 4 y 6).

#### 3.2.7 Tarjetas (líneas 228–320)

```scss
.card {
  position: relative; overflow: hidden;
  background: linear-gradient(145deg, rgba(255,255,255,.66), rgba(255,255,255,.34));
  border: 1px solid var(--ui-border);  border-radius: var(--ui-radius-xl);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.88), var(--ui-shadow);
  backdrop-filter: blur(24px) saturate(160%);
  transition: transform .22s cubic-bezier(.2,.8,.2,1), box-shadow .22s cubic-bezier(.2,.8,.2,1), border-color .22s ease;
}
.card::before { content: ""; position: absolute; inset: 0 0 auto 0; height: 42%; pointer-events: none;
  background: linear-gradient(180deg, rgba(255,255,255,.22), transparent); opacity: .75; }
.card:hover { transform: translateY(-3px); … var(--ui-shadow-lg) }
```

- **`.card`:** el vidrio: degradado blanco translúcido (de .66 a .34 de opacidad), borde claro, esquinas muy redondas
  (1.55rem), sombra (con un reflejo interior de 1 px arriba) y desenfoque del fondo. `overflow: hidden` recorta el
  contenido a las esquinas.
- **`.card::before`:** un **brillo** (un degradado de blanco a transparente en el 42 % superior de la tarjeta).
  `pointer-events: none` hace que no estorbe a los clics ni a los mensajes de las gráficas.
- **`.card:hover`:** al pasar el cursor, la tarjeta **se levanta** 3 px y su sombra crece (`transition` lo hace suave). Es una
  decisión estética; no cambia ninguna cifra.
- **`.card-header`** (título: sin fondo ni borde, 1.06rem, negrita) y **`.card-body`** (`position: relative; z-index: 1`
  para quedar **encima del brillo**) y `.card-body p, .card-body li { line-height: 1.52 }` (interlineado cómodo).

**La regla que evita la barra de desplazamiento (líneas 307–311):**

```scss
.card > .card-body:not(.cell):has(+ .cell),
.card > .cell + .card-body:not(.cell) {
  flex: 0 0 auto !important;
  padding-bottom: .25rem;
}
```

Es la más "inteligente" del archivo y resuelve un problema real ([13.10](13_dashboard.md): "barra de desplazamiento dentro
de las tarjetas"). En una tarjeta con un subtítulo en Markdown (un `.card-body`) y una gráfica (una `.cell`), el sistema de
tarjetas **reparte la altura** entre los dos, y la gráfica se quedaba corta y con barra de desplazamiento. La regla dice:
"un bloque de texto que está **justo antes de una celda** (`:has(+ .cell)`: *tiene como siguiente hermano una celda*), o
**justo después de una** (`.cell + .card-body`), **no crece ni se encoge** (`flex: 0 0 auto`): ocupa **sólo su altura natural**".
Así la gráfica recibe el resto. El segundo selector cubre la nota que va **debajo** del bootstrap (página 4). `:has()` es un
selector moderno (Chrome 105, Safari 15.4, Firefox 121 o posteriores); en navegadores más viejos la regla se ignora y reaparece
el problema.

- **`.subtitulo`** (314–320): texto gris de .83rem con poco margen, el subtítulo de las gráficas.

#### 3.2.8 *Value boxes* (líneas 323–415)

```scss
.bslib-value-box {
  position: relative; overflow: hidden;
  background: linear-gradient(145deg, rgba(255,255,255,.69), rgba(255,255,255,.37)) !important;
  border: 1px solid var(--ui-border) !important;  border-radius: var(--ui-radius-xl) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.88), var(--ui-shadow) !important;
  backdrop-filter: blur(22px) saturate(155%);
  .value-box-title { color: var(--ui-ink-2); font-size: .74rem; font-weight: 700; letter-spacing: .065em; text-transform: uppercase; … }
  .value-box-value { color: var(--ui-ink); font-size: 2.22rem !important; font-weight: 730; letter-spacing: -.05em; line-height: 1.02; }
  p:not(.value-box-title):not(.value-box-value) { color: var(--ui-ink-2); font-size: .82rem; … }
  .value-box-showcase { color: var(--ui-ink-2); opacity: .72; }
}
.bslib-value-box::before { …  inset: 0 auto 0 0; width: 3px; … }   /* barra de acento a la izquierda */
.bslib-value-box::after  { …  pointer-events: none; … }           /* brillo superior */
```

- Es el mismo vidrio que las tarjetas, pero con `!important` en fondo, borde, radio y sombra: **vence al fondo en línea**
  que Quarto genera con el atributo `color="#eef5fd"` de `index.qmd`. Por eso los tintes pastel de las cajas **no se ven**
  ([2.3.2](#232-fila-2-los-tres-value-boxes-líneas-164190)).
- Tipografía por parte: el **título** (`.value-box-title`) en mayúsculas pequeñas y espaciadas; el **valor** (`.value-box-value`)
  grande (2.22rem, `!important` para vencer el tamaño de Quarto) y con las letras apretadas; las **líneas de apoyo** (los
  párrafos que no son título ni valor) en gris de .82rem; el **ícono** (`.value-box-showcase`) gris, con 72 % de opacidad.
- `::before` dibuja una **barra vertical de 3 px** a la izquierda (azul grisáceo) como acento; `::after` agrega el brillo
  superior; `:hover` levanta la caja como a las tarjetas.

#### 3.2.9 Pregunta, lectura y notas (líneas 418–469)

- **`.pregunta`** (418–440): tarjeta con **borde izquierdo azul** de 4 px (`var(--modelo)`) y esquinas algo menores; sus
  párrafos (`p`) con 1rem. Es la tarjeta del planteamiento de la página 1.
- **`.lectura`** (443–461): `ol` con sangría de 1.2rem y `li` con separación de .55rem (la lista de conclusiones). Incluye una
  regla `.ruta` (texto pequeño con una línea arriba) que **ya no se usa**: era del "recorrido sugerido" que se quitó del
  tablero.
- **`.nota`** (464–469): texto pequeño (.82rem) y gris para las notas bajo las tablas y el simulador.

#### 3.2.10 Tablas (líneas 472–533)

```scss
.tabla-contenedor { overflow: auto; max-height: 100%; background: …vidrio…; border: 1px solid var(--ui-border); border-radius: var(--ui-radius-lg); … }
table.tabla {
  width: 100%; border-collapse: collapse; font-size: .85rem; font-variant-numeric: tabular-nums;
  th { text-align: left; color: var(--ui-ink-2); font-size: .72rem; text-transform: uppercase; … position: sticky; top: 0; background: rgba(247,249,252,.84); backdrop-filter: blur(14px); z-index: 1; }
  td { border-bottom: 1px solid rgba(80,94,116,.07); padding: .58rem .78rem; vertical-align: top; line-height: 1.42; … }
  tr:hover td { background: rgba(255,255,255,.40); }
  tr:last-child td { border-bottom: none; }
}
```

- **`.tabla-contenedor`** es el `<div>` que `gr.tabla_html` pone alrededor de cada tabla: `overflow: auto` le da su **propia
  barra de desplazamiento** y `max-height: 100%` lo limita a la tarjeta; por eso las tablas largas (25 filas) se desplazan
  **dentro** de la tarjeta.
- **`table.tabla`:** ancho completo, líneas colapsadas, letra de .85rem y **`font-variant-numeric: tabular-nums`**, que hace
  que todos los dígitos midan lo mismo y las **columnas de números se alineen**.
- **`th`** (encabezados): a la izquierda, en mayúsculas pequeñas y grises, y **`position: sticky; top: 0`**: al desplazarse la
  tabla, el encabezado **se queda fijo arriba**, con fondo translúcido y desenfoque para que se lea sobre las filas que
  pasan por debajo (`z-index: 1`).
- `td` y `tr:hover` (separadores finos y un resaltado al pasar el cursor) son estética.
- Estas reglas valen para las tablas de **Python** (`class="tabla"`) y la del simulador (que también usa `<table class="tabla">`),
  no para las tablas de Markdown de la página 6.

#### 3.2.11 Diagrama de flujo "Cómo funciona" (líneas 536–645)

```scss
.flujo.html-fill-container,
.flujo {
  display: flex;  flex-direction: row !important;  align-items: stretch;  gap: .7rem;  flex-wrap: nowrap;  height: 100%;  font-size: .84rem;
  > .flecha { flex: 0 0 auto !important; }
  .paso { flex: 1 1 0 !important; min-width: 0; display: flex; flex-direction: column; justify-content: center; gap: .4rem;
          border-left: 4px solid var(--contexto); … &.modelo { border-left-color: var(--modelo); … } &.mercado { … var(--mercado) … } &.compara { … var(--tinta) … } }
  .sub { flex: 0 0 auto !important; border-top: 1px dashed rgba(80,94,116,.12); padding-top: .35rem; }
  .sub:first-of-type { border-top: none; padding-top: 0; }
  .flecha { align-self: center; color: #8b95a6; font-size: 1.15rem; }
}
```

- **El problema de fondo:** Quarto marca los `<div>` dentro de una tarjeta con la clase `html-fill-container`, que **apila los hijos en
  columna**. El diagrama necesita **una fila**. Por eso el selector se repite con esa clase (`.flujo.html-fill-container`,
  para ganar en especificidad) y se fuerza `flex-direction: row !important`.
- **`display: flex`** pone los pasos en **línea** (`gap: .7rem` entre ellos; `flex-wrap: nowrap` para que no salten de línea;
  `align-items: stretch` para que todos tengan la misma altura).
- **`.paso`:** cada recuadro (`flex: 1 1 0`: **todos del mismo ancho**; `min-width: 0` evita que un texto largo los
  ensanche) es una caja de vidrio con **borde izquierdo de 4 px** del color de su tipo: gris (`--contexto`) por defecto,
  azul (`.modelo`), naranja (`.mercado`) y oscuro (`.compara`), con un tinte de fondo a juego. El título (`b`) en negritas y
  la línea de apoyo (`span`, `display: block`) en gris.
- **`.flecha`:** `flex: 0 0 auto` (no se estira) y centrada verticalmente (`align-self: center`): las flechas `→` y `←`.
- **`.sub`:** las dos regresiones de Poisson dentro de un mismo paso, separadas por una **línea punteada**
  (`border-top: 1px dashed`), salvo la primera (`.sub:first-of-type`).

#### 3.2.12 Simulador (líneas 648–734)

```scss
.sim-kpis { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
.sim-kpi { position: relative; overflow: hidden; … vidrio … padding: .95rem 1rem;
  &::before { content: ""; position: absolute; inset: 0 0 auto 0; height: 3px; background: var(--contexto); }
  &.local::before { background: var(--local); }   &.visita::before { background: var(--visita); }
  .etq { … text-transform: uppercase; … }   .val { font-size: 2.08rem; font-weight: 730; … }   .det { color: var(--ui-ink-2); font-size: .82rem; … } }
.sim-aviso { font-size: .8rem; line-height: 1.4; color: var(--ui-ink-2); border-top: 1px solid rgba(80,94,116,.10); padding-top: .6rem; margin-top: .6rem; }
```

- **`.sim-kpis`:** una **cuadrícula** (`display: grid`) de **tres columnas iguales** (`repeat(3, 1fr)`) para las tarjetas
  de probabilidad.
- **`.sim-kpi`:** una caja de vidrio como las demás; su `::before` dibuja una **línea de 3 px en el borde superior** cuyo color
  dice quién es: gris (empate, `--contexto`), **verde** (`.local`, `--local`), **violeta** (`.visita`, `--visita`), los mismos
  colores que en las gráficas.
- `.etq` (etiqueta en mayúsculas), `.val` (el porcentaje grande) y `.det` (el detalle) son las tres líneas de cada caja.
- **`.sim-aviso`:** el aviso de uso, pequeño, gris, con una línea arriba.

#### 3.2.13 Lo menor, agrupado (líneas 737–916)

| Grupo | Líneas | Qué hace |
|---|---|---|
| **Controles** | 737–774 | `.form-control`, `.form-select`, `select`, `input[type=text/number/search]`: fondo de vidrio, borde claro, esquinas de .95rem. Los menús de Observable son `<select>`, así que esta regla es la que los viste. En `:focus` el contorno se reemplaza por un halo suave (`box-shadow`) |
| **Botones** | 777–831 | `.btn`: píldora de 42 px de alto, sombra suave y levantamiento al pasar el cursor; `.btn-primary` con el degradado azul pizarra; `.btn-secondary` claro. El tablero casi no tiene botones; no se comprobó a cuáles afecta (por ejemplo, al botón de GitHub de la barra) |
| **Leyendas** | 834–873 | **`.leyenda`**: `inline-flex`, `gap`, sin saltos de línea (`white-space: nowrap`), .8rem gris. **`.muestra`**: el cuadrito de color (.8rem, esquinas de 3 px) con cuatro modificadores: `.circulo` (redondo), `.hueco` (sin relleno y con borde de 2 px), `.linea` (barra de 1.3rem × 3 px) y `.rombo` (cuadrito girado 45°). Son las leyendas de los subtítulos de `index.qmd` |
| **Plotly y títulos** | 876–897 | `.plotly, .html-widget, .js-plotly-plot { border-radius: 1rem }`; `h1`, `h2`, `h3` con color tinta y letras apretadas (`letter-spacing: -.035em`), negrita 720 y 680 |
| **Barras de desplazamiento** | 900–916 | `* { scrollbar-width: thin; scrollbar-color: … }` (Firefox) y `*::-webkit-scrollbar` (Chrome y Safari): barras de 9 px, gris azulado, con el extremo redondeado |

Estas reglas no cambian ninguna cifra ni la estructura; son acabado visual. Las **leyendas** son las únicas de este grupo
que importan: sustituyen a la leyenda de Plotly, desactivada ([2.3.3](#233-fila-3-columna-izquierda-la-gráfica-principal-líneas-192202)).

#### 3.2.14 Pantallas pequeñas (líneas 919–970)

Un solo bloque `@media (max-width: 768px)` (un celular o una tableta vertical):

- menos relleno en las páginas (`.75rem`) y márgenes menores en la barra;
- esquinas ligeramente menores en `.card`, `.bslib-value-box` y `.sim-kpi` (`!important`), y encabezados y cuerpos de tarjeta
  con menos relleno;
- **`.sim-kpis` pasa a una sola columna** (`grid-template-columns: 1fr`) y el número grande se achica (1.95rem);
- **`.flujo` se envuelve** (`flex-wrap: wrap`): los pasos ocupan el 40 % del ancho (`flex: 1 1 40%`) y las flechas se
  **ocultan** (`display: none`), porque en varias líneas dejarían de tener sentido;
- las tablas bajan a .82rem.

Lo que **no** cambia: el mapa de calor mide 540 px fijos y las gráficas de Plotly tienen sus propios márgenes; en un celular
estrecho el mapa puede salirse de su tarjeta (no se probó).

### 3.3 `redibujar.html`

46 líneas de JavaScript que Quarto pega **al final del `<body>`** (`include-after-body`). Resuelven un problema concreto:
**las gráficas de Plotly que se dibujan estando ocultas salen mal.** Decisión relacionada:
[5.10](#510-redibujarhtml); en [19](19_decisiones_y_alternativas.md) es la D46.

#### 3.3.1 El problema

- En el tablero, **sólo la página 1 está visible al abrirlo**; las otras cinco, y las pestañas que no son la primera de cada
  `.tabset`, existen en el HTML pero **ocultas** (`display: none`). De las 11 gráficas de Plotly, **10 se dibujan estando
  ocultas** (sólo la de la página 1 está a la vista).
- Plotly **mide** el contenedor y los textos (etiquetas de ejes, anotaciones, leyendas) **en el momento de dibujar**. Un
  elemento oculto mide **0 px**, así que Plotly calcula todo con medidas absurdas: las etiquetas salían **encimadas o
  ausentes**.
- Cuando el lector entra a esa página o pestaña, **la gráfica no se vuelve a calcular**: Plotly sólo reacciona cuando cambia
  el tamaño de la **ventana** (opción `responsive: True` de `mostrar()`), y mostrar una pestaña no cambia la ventana.
- El arreglo: **volver a dibujar** cada gráfica cuando se hace visible.

#### 3.3.2 El código, bloque por bloque

```html
<script>

(function () {
  function plotly() { return window.Plotly || window._Plotly || null; }

  function redibujar(el) {
    var P = plotly();
    if (!P || !el.data || el.offsetParent === null || el.clientWidth === 0) return;
    P.newPlot(el, el.data, el.layout, el._context);
  }

  function redibujarVisibles() {
    document.querySelectorAll(".js-plotly-plot").forEach(redibujar);
  }

  var tamanos = new WeakMap();
  var observador = ("ResizeObserver" in window) ? new ResizeObserver(function (entradas) {
    entradas.forEach(function (entrada) {
      var el = entrada.target;
      var w = Math.round(entrada.contentRect.width), h = Math.round(entrada.contentRect.height);
      var previo = tamanos.get(el) || [0, 0];
      tamanos.set(el, [w, h]);
      // Redibuja al pasar de oculto (0 px) a visible, o ante un cambio grande de tamaño.
      var cambio = previo[0] === 0 || Math.abs(previo[0] - w) > 40 || Math.abs(previo[1] - h) > 40;
      if (w > 0 && h > 0 && cambio) {
        clearTimeout(el.__temporizador);
        el.__temporizador = setTimeout(function () { redibujar(el); }, 120);
      }
    });
  }) : null;

  function vigilar() {
    if (!observador) return;
    document.querySelectorAll(".js-plotly-plot").forEach(function (el) {
      if (!el.__vigilada) { el.__vigilada = true; observador.observe(el); }
    });
  }

  window.addEventListener("load", function () {
    vigilar();
    setTimeout(redibujarVisibles, 250);
    setTimeout(function () { vigilar(); redibujarVisibles(); }, 1500);  // equipos lentos
  });
  document.addEventListener("shown.bs.tab", function () { setTimeout(redibujarVisibles, 80); });
})();
</script>
```

| Líneas | Qué hace |
|---|---|
| 1 y 46 | `<script> … </script>`: el archivo es **HTML**, no JavaScript suelto; Quarto lo copia tal cual al final de la página |
| 3 y 45 | `(function () { … })();` es una **función que se ejecuta de inmediato** (IIFE): mantiene las variables adentro y no ensucia el espacio global de la página |
| 4 | `plotly()` busca el objeto de Plotly en `window.Plotly` **o** en `window._Plotly`. La página carga Plotly con **RequireJS**, y el cargador de Quarto lo deja en `window._Plotly` (en el HTML generado: `require(['plotly'], function(Plotly) { window._Plotly = Plotly; })`). La **primera versión** sólo buscaba `window.Plotly` y no encontraba nada ([13.9](13_dashboard.md)). `\|\| null` devuelve `null` si no existe (`\|\|` es el "o" de JavaScript) |
| 6–10 | `redibujar(el)` vuelve a dibujar **una** gráfica. Primero **se sale sin hacer nada** si: no hay Plotly (`!P`), el elemento **no tiene datos** (`!el.data`: todavía no se dibujó), está **oculto** (`el.offsetParent === null`: un elemento con un ancestro `display: none` tiene `offsetParent` nulo) o mide **0 px de ancho** (`el.clientWidth === 0`). Si no, `P.newPlot(el, el.data, el.layout, el._context)` **dibuja de nuevo desde cero** con los mismos datos, diseño y configuración que Plotly dejó guardados en el propio elemento (`data`, `layout`, `_context`), pero ahora con el tamaño real |
| 12–14 | `redibujarVisibles()`: recorre todos los contenedores con la clase **`js-plotly-plot`** (la que Plotly agrega a cada gráfica ya dibujada) y llama a `redibujar` en cada uno; las ocultas se saltan solas |
| 16 | `tamanos = new WeakMap()`: guarda el **último tamaño conocido** `[ancho, alto]` de cada gráfica. Un `WeakMap` no impide que el navegador libere el elemento si desaparece |
| 17 y 30 | `observador`: un **`ResizeObserver`**, la función del navegador que **avisa cuando cambia el tamaño de un elemento**. Si el navegador no la tiene (`"ResizeObserver" in window` es falso) queda `null` y el resto del script sigue con los otros disparadores |
| 18–29 | La función que recibe los avisos: por cada gráfica obtiene `w` y `h` redondeados (`contentRect`), recupera el tamaño **previo** (`[0, 0]` si no había) y lo actualiza. `cambio` es verdadero si **antes medía 0 de ancho** (estaba oculta y se acaba de mostrar) **o** si el ancho o el alto cambiaron **más de 40 px**. Sólo si ahora **tiene tamaño** (`w > 0 && h > 0`) **y** hubo `cambio`, programa el redibujado: `clearTimeout(el.__temporizador)` cancela uno pendiente y `setTimeout(…, 120)` espera **120 ms** (*antirrebote*: si llegan muchos avisos seguidos, sólo se redibuja al final) |
| 32–37 | `vigilar()`: pone al observador a **mirar cada gráfica una sola vez** (la marca `el.__vigilada` evita registrarla dos veces) |
| 39–43 | Al terminar de cargar la página (`load`): `vigilar()` registra las gráficas; a los **250 ms** `redibujarVisibles()` redibuja las que ya están a la vista; y a los **1,500 ms** se repite todo (`// equipos lentos`: en computadoras o celulares lentos Plotly tarda en dibujar y las gráficas pueden no existir todavía a los 250 ms) |
| 44 | `shown.bs.tab` es el **evento de Bootstrap** que se dispara **después de mostrar una pestaña** (sea una página de la barra superior o una pestaña dentro de una tarjeta); a los **80 ms** (para que el diseño se asiente) se redibujan las visibles |

**Por qué hay tres disparadores.** Cada uno cubre un caso distinto: `load` (los retrasos al abrir), `shown.bs.tab` (el cambio de
pestaña o de página) y `ResizeObserver` (cualquier cambio de tamaño, incluida la rotación de un celular o el cambio de la
ventana). Los **40 px** de tolerancia (el código no dice por qué) evitan, con toda probabilidad, que el propio redibujado,
que cambia el tamaño unos píxeles, dispare un ciclo infinito de redibujados.

**Qué no hace.** No cambia las gráficas ni los datos: sólo vuelve a ejecutar `Plotly.newPlot`. Alternativas como
`Plotly.Plots.resize` o `Plotly.relayout` **no se probaron** ([5.10](#510-redibujarhtml)). Y como todo el tablero, depende de
que RequireJS (de jsDelivr) cargue Plotly.

**En R (ilustrativo):** en flexdashboard, los *htmlwidgets* de `plotly` suelen redibujarse al cambiar de pestaña porque
flexdashboard dispara un evento de cambio de tamaño; no se verificó. Si hiciera falta, se puede ejecutar JavaScript sobre
cada gráfica con `htmlwidgets::onRender()`:

```r
plotly::plot_ly(...) |>
  htmlwidgets::onRender("function(el) { new ResizeObserver(function () { Plotly.Plots.resize(el); }).observe(el); }")
```

### 3.4 `requirements.txt`

Diez líneas (la primera está en blanco). Son los paquetes de Python que necesita **generar el tablero**, con sus versiones.

```text

pandas==2.2.3
numpy==2.2.3
scipy==1.15.2
statsmodels==0.14.4
scikit-learn==1.6.1
plotly==5.24.1
# Motor de Quarto para ejecutar Python (incluye ipykernel, nbclient y PyYAML)
jupyter
pyyaml
```

| Paquete | Versión | Para qué lo usa el tablero |
|---|---|---|
| `pandas` | 2.2.3 | Tablas (`DataFrame`) en `datos_dashboard.py` y en `index.qmd` |
| `numpy` | 2.2.3 | Cálculo numérico: matrices de probabilidades, bootstrap |
| `scipy` | 1.15.2 | Distribuciones `poisson` y `skellam` (`scipy.stats`) |
| `statsmodels` | 0.14.4 | Las regresiones de Poisson (`sm.GLM`), el VIF y los p-valores |
| `scikit-learn` | 1.6.1 | `log_loss` y `mean_absolute_error` |
| `plotly` | 5.24.1 | Las 11 gráficas (`graficas.py`) |
| `jupyter` | **sin versión** | El **motor de Quarto** para Python: instala `ipykernel`, `nbclient`, `nbformat` y otras piezas (más de las necesarias) |
| `pyyaml` | **sin versión** | Quarto lo necesita para leer las opciones de los chunks; sin él falló con `No module named 'yaml'` ([13.10](13_dashboard.md)) |

- **Las líneas con `==`** fijan la **versión exacta**: quien instale hoy o dentro de un año obtiene el mismo código. Son las
  versiones con las que se desarrolló y verificó el tablero (el README del repositorio las lista igual). Importa porque pandas,
  numpy o Plotly cambian de comportamiento entre versiones mayores.
- **`jupyter` y `pyyaml` no tienen versión.** No afectan las cifras (sólo hacen funcionar Quarto), pero `pip` instalará lo
  más reciente, y las dependencias de **todos** los paquetes (por ejemplo, `patsy`, `python-dateutil`, `joblib`) tampoco están
  fijadas: **no es un archivo de bloqueo completo**, sino las versiones directas más importantes.
- **Qué falta a propósito:** `matplotlib` y `nbconvert`, que sólo necesita el notebook (el README raíz los instala aparte con
  `pip install nbconvert matplotlib`).
- **Cómo se usa:** en la computadora, `pip install -r Dashboard-o-pagina/requirements.txt`; en GitHub Actions, el mismo
  comando, con la caché de `pip` **atada a este archivo** (`cache-dependency-path`: si cambia, se invalida) y Python 3.10.
  Decisión relacionada: [5.11](#511-versiones-fijas).

**En R (ilustrativo):** el equivalente es **`renv`**, que guarda las versiones en `renv.lock`:

```r
renv::init()        # crea el entorno del proyecto
renv::snapshot()    # escribe renv.lock con las versiones instaladas   (≈ pip freeze > requirements.txt)
renv::restore()     # en otra computadora, instala exactamente esas versiones   (≈ pip install -r requirements.txt)
```

### 3.5 `.gitignore`

Diez líneas (una en blanco) que le dicen a git **qué no guardar**. Está dentro de `Dashboard-o-pagina/`, así que las rutas
son relativas a esa carpeta.

```text
# Salida generada: GitHub Actions la vuelve a construir en cada push
_site/
.quarto/
index_files/
index.html
__pycache__/
*.pyc

/.quarto/
**/*.quarto_ipynb
```

| Línea | Qué ignora | Por qué |
|---|---|---|
| `# Salida generada: …` | (comentario) | Resume la idea: lo que se genera no se guarda, porque el servidor lo reconstruye |
| `_site/` | El sitio generado (`index.html` de ≈ 5 MB y `index_files/`) | Es la salida de `quarto render`; GitHub Actions la vuelve a crear en cada `push` |
| `.quarto/` | La carpeta interna de Quarto (cachés y registros de la ejecución) | Es de trabajo, no del proyecto |
| `index_files/`, `index.html` | Lo que genera Quarto **junto al `.qmd`** si alguien renderiza el archivo suelto (`quarto render index.qmd`) en lugar del proyecto | Que esa salida alternativa tampoco se suba por accidente (razón probable; no consta) |
| `__pycache__/`, `*.pyc` | El *bytecode* que Python compila al importar `datos_dashboard.py` y `graficas.py` | Archivos temporales |
| (línea en blanco) | — | Sólo separa |
| `/.quarto/` | Lo mismo que `.quarto/`, anclado a esta carpeta | **Repite** la línea 3; no hace daño |
| `**/*.quarto_ipynb` | Los cuadernos intermedios (`index.quarto_ipynb`) que Quarto crea para ejecutar el código | Normalmente se borran, pero quedan si el *render* falla |

En la carpeta de la computadora de César existen `_site/`, `.quarto/` y `__pycache__/` (de los *renders* locales), pero
**nada de eso está en el repositorio**. Decisión relacionada: [5.13](#513-la-salida-generada-no-se-guarda-en-git).

**En R (ilustrativo):** un `.gitignore` de un proyecto de R Markdown/Quarto lleva, por la misma razón,
`.Rproj.user/`, `.Rhistory`, `*_files/`, `*_cache/` y `_site/`.

### 3.6 `README.md` de la carpeta

48 líneas. Es la **presentación corta de `Dashboard-o-pagina/`**; la guía de reproducción completa (≈ 400 líneas, con versiones,
huellas SHA-256 y la repetición de la rejilla) es el `README.md` de la raíz del repositorio ([capítulo 14](14_publicacion_en_github.md)).

| Parte | Líneas | Contenido |
|---|---|---|
| Título y descripción | 1–5 | "Dashboard · Premier League: estadística vs. mercado de apuestas"; es la visualización final del Proyecto 1 (Fútbol y mercados de apuestas) del Módulo 8 |
| Cuatro datos clave | 7–9 | La URL publicada (`pitirringo.github.io/futbol-apuestas`), el repositorio, la herramienta (**Quarto formato `dashboard` + Python (pandas, statsmodels, Plotly) + Observable JS**) y la publicación (**GitHub Actions → GitHub Pages**, en cada `push` a `main`) |
| Tabla de las seis páginas | 11–20 | Una línea por página: Resumen, ¿Qué ocurre?, Patrones, El modelo, Explora un partido, Datos y método |
| Estructura | 22–42 | Árbol de la raíz del repositorio (`.github/workflows/publicar-dashboard.yml`, `Codigo/proyecto_mod_8/` "no se modifica", y los archivos de `Dashboard-o-pagina/` con una línea cada uno) |
| Nota de rutas | 44–46 | `datos_dashboard.py` importa `wc_predictor.py` desde `../Codigo/proyecto_mod_8` y reproduce las funciones de `Analisis.ipynb`; si el código está en otra carpeta, basta la variable de entorno `RUTA_CODIGO` |

Coincide con lo que explica este capítulo (seis páginas, archivos y su función). Quarto **no lo procesa** (la lista `render:`
de `_quarto.yml` sólo incluye `index.qmd`). Si preguntan por la estructura de archivos, el árbol del README es la respuesta
más rápida.

## 4. Equivalentes en R (ilustrativos)

Todo lo de esta sección es **ilustrativo**: no se ejecutó (ni R ni Quarto). Sirve para contestar "¿cómo se haría esto en
lo que vimos en el módulo?". Los fragmentos por pieza están en las secciones 2 y 3; aquí se junta lo de **todo el
documento**.

### 4.1 Tabla de correspondencias

| Pieza del tablero (Quarto + Python) | Equivalente en R | Comentario |
|---|---|---|
| `format: dashboard`, `orientation: rows`, `scrolling: true` | `flexdashboard::flex_dashboard`, `orientation: rows`, `vertical_layout: scroll` | Quarto dashboards es el **sucesor** de flexdashboard (mismo grupo, Posit) |
| `# Página {#id}` | `Página` + línea de `=====` | Las páginas son pestañas de la barra superior |
| `## Row {height=…px}` | `Row {data-height=…}` + línea de `-----` | Con `vertical_layout: scroll`, `data-height` son píxeles |
| `### Column {width=62%}` | un `###` con `{data-width=620}` | El ancho es relativo (suma 1000) |
| `::: {.card title="…"}` | `### Título` | Cada `###` es una tarjeta |
| `::: {.valuebox icon color}` | `valueBox(valor, caption, icon, color)` en un chunk | Admite un valor y un `caption` (con HTML para más líneas) |
| `## Row {.tabset}` | `Row {.tabset}` | Cada `###` pasa a ser una pestaña |
| `## {.sidebar}` | `Column {.sidebar}` | Las entradas reactivas de Shiny van ahí |
| Chunk ```` ```{python} ```` con `#\| include: false` | ```` ```{r setup, include=FALSE} ```` | Preparación |
| `` `{python} expr` `` | `` `r expr` `` | Código en línea |
| `gr.mostrar(figura)` (Plotly) | `plotly::ggplotly(grafica)` o `plot_ly()` | Mismo motor (Plotly.js) |
| `HTML(tabla)` (`gr.tabla_html`) | `knitr::kable(df, format = "html")` o `DT::datatable()` | `kable` escapa el HTML por defecto |
| `include-after-body: redibujar.html` | `includes: after_body: redibujar.html` | Igual |
| `theme: [cosmo, estilos.scss]` | `theme:` con `bslib`, más `css:` | [4.4](#44-tema-y-estilos-con-bslib) |
| Observable JS (simulador) | Shiny, `crosstalk` o Quarto + R + `ojs_define` | [4.3](#43-el-simulador-en-r) |
| `requirements.txt` | `renv.lock` | [4.5](#45-reproducibilidad-y-publicación) |
| `_quarto.yml` | `_site.yml` | Sitios de R Markdown |

### 4.2 Un `index.Rmd` mínimo con flexdashboard

Las dos primeras páginas del tablero, con la misma estructura. Los nombres de las funciones y de los objetos (`preparar_todo`,
`mejora_sobre_ingenua`, `met`, `d`…) serían los del equivalente en R de `datos_dashboard.py` y `graficas.py` (hay que escribirlos;
las funciones del modelo en R están en las [equivalencias de R](equivalencias_R/README.md) y en los capítulos [10](10_codigo_wc_predictor.md)
y [11](11_codigo_analisis_notebook.md)).

````markdown
---
title: "Premier League: estadística vs. mercado de apuestas"
lang: es
output:
  flexdashboard::flex_dashboard:
    orientation: rows
    vertical_layout: scroll
    theme: { version: 4, bootswatch: cosmo }
    css: estilos.css                      # compilado antes desde estilos.scss
    includes: { after_body: redibujar.html }
    navbar:
      - { icon: fa-github, href: "https://github.com/pitirringo/futbol-apuestas", align: right }
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)       # ≈ execute: de _quarto.yml
library(dplyr); library(ggplot2); library(plotly); library(flexdashboard); library(knitr)
source("datos_dashboard.R"); source("graficas.R")
d <- preparar_todo()                                                         # ≈ dd.preparar_todo()
met <- d$metricas
pct <- function(x, dec = 1) sprintf("%.*f%%", dec, x * 100)
acc <- function(conjunto, predictor) met$aciertos[met$conjunto == conjunto & met$predictor == predictor]
n_var_m0 <- length(ESPECIFICACIONES$M0_Base[[1]])
```

Resumen {#resumen}
=====================================================================

Row {data-height=185}
---------------------------------------------------------------------

### Ventaja del mercado que alcanza el modelo

```{r}
valueBox(pct(d$fraccion_mejora, 0), caption = "Ventaja del mercado que alcanza el modelo",
         icon = "fa-bullseye", color = "info")
```

### Partidos acertados por el modelo

```{r}
valueBox(pct(acc("Prueba", "M0_Base")),
         caption = htmltools::HTML(paste0("Partidos acertados por el modelo<br>Mercado: ",
                                          pct(acc("Prueba", "Mercado_apertura")))),
         icon = "fa-check-circle", color = "info")
```

Row {data-height=590}
---------------------------------------------------------------------

### El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo {data-width=620}

```{r}
ggplotly(mejora_sobre_ingenua(met))                      # ≈ gr.mostrar(gr.mejora_sobre_ingenua(met))
```

### Resumen {data-width=380}

1. **Las estadísticas sí anticipan resultados.** Con sólo `r n_var_m0` variables, el modelo acierta
   `r pct(acc("Prueba", "M0_Base"))` de los partidos de prueba, contra `r pct(acc("Prueba", "Ingenua"))` de un pronóstico básico.

¿Qué ocurre? {#que-ocurre}
=====================================================================

Row {.tabset}
---------------------------------------------------------------------

### Qué significa para el modelo
…

### Tabla por temporada

```{r}
htmltools::HTML(tabla_temporadas)
```
````

Diferencias que conviene saber: flexdashboard no tiene `title=` en el chunk ni tarjetas con subtítulo propio (se usa
`htmltools::tagList()`); un `valueBox` sólo tiene valor y `caption`; y **no existe** un equivalente a `.tabset height=…`.
Quarto, además, ejecuta Python y R **en el mismo documento**; flexdashboard, sólo R (con `reticulate` se podría llamar a Python desde R,
fijando antes `RETICULATE_PYTHON`; no se probó).

### 4.3 El simulador en R

El simulador de Python + Observable **no calcula nada en el navegador** (sólo filtra 380 cruces precalculados). Hay tres formas
de hacer lo mismo desde R, con ventajas distintas:

| Opción | ¿Necesita servidor? | ¿Funciona en GitHub Pages? | Qué permite | Qué le falta |
|---|---|---|---|---|
| **A. Shiny** (`runtime: shiny`) | **Sí** (shinyapps.io o Posit Connect) | **No** | Cualquier cálculo reactivo en vivo, incluso recalcular el modelo | El servidor encendido |
| **B. `crosstalk`** | No | **Sí** (HTML estático) | Filtros enlazados entre *widgets* | Selectores dependientes y tarjetas calculadas con facilidad; el mapa de calor se simularía con puntos |
| **C. Quarto + chunk de R + `ojs_define()`** | No | **Sí** | **Las mismas celdas de Observable de este tablero**, sin cambios | Hay que pasar de flexdashboard a Quarto |

**A. Shiny (ilustrativo).** La reactividad de OJS se vuelve `reactive()`; los menús, `selectInput`; y el cálculo se hace en
el servidor cada vez.

````markdown
Column {.sidebar}
---------------------------------------------------------------------

```{r}
selectInput("local", "Equipo local", choices = equipos, selected = "Arsenal")            # ≈ viewof local
uiOutput("ui_visita")
output$ui_visita <- renderUI(selectInput("visita", "Equipo visitante",                  # ≈ viewof visita
  choices  = setdiff(equipos, input$local),                                              # ≈ filter(e => e !== local)
  selected = if (input$local == "Man City") "Arsenal" else "Man City"))
partido <- reactive({ req(input$visita)                                                  # ≈ partido = sim.partidos.find(…)
  cruces |> filter(local == input$local, visita == input$visita) |> slice(1) })
```

Column
---------------------------------------------------------------------

### Gana el local

```{r}
renderValueBox(valueBox(pct(partido()$p_local), caption = paste("Gana", input$local), color = "success"))
```

### Probabilidad de cada marcador (%)

```{r}
renderPlot({                                                                              # ≈ Plot.plot con Plot.cell y Plot.text
  m <- partido()$matriz[[1]]                                                              # matriz 6 x 6
  celdas <- expand.grid(gv = 0:5, gl = 0:5); celdas$p <- as.vector(t(m))
  ggplot(celdas, aes(gv, gl, fill = p)) + geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.1f", p * 100))) + scale_y_reverse() +
    scale_fill_gradient(low = "#eef5fd", high = "#184f95", guide = "none")
})
```
````

**B. `crosstalk` (ilustrativo, sin servidor).** Los filtros se enlazan con una tabla **larga** (una fila por celda del mapa).

```r
library(crosstalk); library(plotly)
sd <- SharedData$new(celdas_largas)       # columnas: local, visita, gl, gv, p  (380 cruces x 36 celdas)
bscols(widths = c(3, 3, 6),
  filter_select("local",  "Equipo local",     sd, ~local,  multiple = FALSE),
  filter_select("visita", "Equipo visitante", sd, ~visita, multiple = FALSE),
  plot_ly(sd, x = ~gv, y = ~gl, color = ~p, colors = c("#eef5fd", "#184f95"),
          type = "scatter", mode = "markers", marker = list(symbol = "square", size = 40)))
```

Limitaciones: los dos menús son **independientes** (el visitante no excluye al local), no hay tarjetas de probabilidad
calculadas ni nota condicional, y el mapa de calor se aproxima con cuadros de color. Es la opción menos parecida.

**C. Quarto con R y `ojs_define()` (ilustrativo, la más parecida).** Se conserva el documento de Quarto y las seis celdas de
OJS; sólo cambia el motor del chunk (`knitr` en vez de Jupyter) y la preparación de los datos, que se hace en R:

````markdown
```{r}
#| echo: false
ojs_define(sim = list(equipos = equipos, partidos = purrr::transpose(cruces),
                      stats = purrr::transpose(estadisticas), temporada = "2026/27", k_shrinkage = K_SHRINKAGE))
```
````

Las celdas `viewof local`, `viewof visita`, `partido`, el mapa de calor y la tabla ([2.7](#27-página-5-explora-un-partido-el-simulador))
**no cambian**. (`purrr::transpose()` convierte la tabla en una lista de filas, que es lo que espera OJS; los
*data frames* llegan a OJS por columnas. No se verificó.)

### 4.4 Tema y estilos con bslib

```r
tema <- bslib::bs_theme(version = 5, bootswatch = "cosmo", primary = "#2a78d6",
                        "body-bg" = "#f4f5f7", "body-color" = "#172033", "link-color" = "#256abf")
tema <- bslib::bs_add_rules(tema, sass::sass_file("estilos.scss"))     # las reglas de las secciones 3.2.4 a 3.2.14
# En flexdashboard: theme: bslib::bs_theme(...)  (flexdashboard >= 0.6)   o   css: estilos.css, con
# sass::sass(sass::sass_file("estilos.scss"), output = "estilos.css")   # compila el SCSS a CSS
```

El SCSS **no cambia**: es el mismo archivo. Lo único que cambia es quién lo compila (Quarto aquí; `sass`/`bslib` en R). Las
variables CSS de `:root` y las reglas de `.card`, `.bslib-value-box` o `.flujo` dependen de las clases que genere cada
herramienta (flexdashboard usa Bootstrap 3 o 4 y otras clases), así que habría que revisarlas.

### 4.5 Reproducibilidad y publicación

| Python (este proyecto) | R |
|---|---|
| `requirements.txt` con versiones fijas + `pip install -r` | `renv.lock` (`renv::snapshot()` y `renv::restore()`) |
| `quarto render Dashboard-o-pagina` en GitHub Actions | `rmarkdown::render_site()` o `quarto render`, con `r-lib/actions/setup-r` y `r-lib/actions/setup-renv` |
| `actions/setup-python` + `cache: pip` | `actions/cache` sobre la biblioteca de `renv` |
| Publicar `_site/` en GitHub Pages | Igual: se sube la carpeta de salida |

### 4.6 Lo que no tiene equivalente directo

- **`redibujar.html`:** es JavaScript sobre el *widget* de Plotly; en R se haría igual con `htmlwidgets::onRender()` o con un
  archivo `includes: after_body`.
- **Las celdas de Observable Plot** (`Plot.cell`, `Plot.text`, `tip`): en R el equivalente estático es `ggplot2` (+ `ggplotly`).
- **La regla CSS `:has()` de las tarjetas:** depende de las clases que genere la herramienta de tableros.

## 5. Decisiones y alternativas

Cada recuadro sigue el formato **Decisión · Alternativas · Por qué ésta · Si preguntan**. Reglas de honestidad: sólo se dice
"se probó" de lo que **de verdad se probó** en el proyecto (y falló); todo lo demás son **alternativas razonadas**, marcadas
"No se probó". Lo que sí se probó (y salió mal) en el tablero: Mermaid para el diagrama (salía vacío), identificadores de
página con acento (página en blanco), `ojs_define` en un chunk `include: false` (no llegaban los datos), `redibujar.html`
buscando sólo `window.Plotly` (no encontraba Plotly), Plotly con sus opciones por defecto (leyendas encimadas y zoom
accidental) y Quarto sin PyYAML (no ejecutaba Python) — todo en la tabla de problemas del [capítulo 13](13_dashboard.md).
Las decisiones también están resumidas en el [capítulo 19](19_decisiones_y_alternativas.md) (D39 a D48).

| Decisión | Dónde se ve | En el capítulo 19 |
|---|---|---|
| [5.1](#51-herramienta-quarto-dashboard-con-python) Quarto dashboard con Python | YAML ([2.1](#21-el-encabezado-yaml)) | D39 |
| [5.2](#52-estructura-y-layout-del-documento) Estructura y layout | Encabezados `#`, `##`, `###` y `.tabset` | D45 (en parte) |
| [5.3](#53-cifras-en-línea-y-frases-condicionales) Cifras en línea y frases condicionales | Chunk de preparación ([2.2](#22-el-chunk-de-preparación)) y las 83 expresiones | D42 |
| [5.4](#54-páginas-narrativas-con-títulos-que-dicen-la-conclusión) Páginas narrativas con títulos-conclusión | Las seis páginas | D45 |
| [5.5](#55-value-boxes) *Value boxes* | Páginas 1 y 2 | D45 (en parte) |
| [5.6](#56-tema-cosmo-y-estilosscss) Tema `cosmo` + SCSS | `estilos.scss` ([3.2](#32-estilosscss)) | D39 (menciona el tema) |
| [5.7](#57-diagrama-de-flujo-en-html-y-css) Diagrama en HTML y CSS | "Cómo funciona" ([2.6.1](#261-fila-1-el-diagrama-de-flujo-y-el-resumen-líneas-349376)) | — |
| [5.8](#58-tablas-html-propias-y-vista-de-tabla) Tablas propias y vista de tabla | [2.2.8](#228-las-siete-tablas-html-líneas-104144) | D43 (en parte) |
| [5.9](#59-observable-en-el-navegador-con-datos-precalculados) Observable con datos precalculados | Página 5 ([2.7](#27-página-5-explora-un-partido-el-simulador)) | D44 |
| [5.10](#510-redibujarhtml) `redibujar.html` | [3.3](#33-redibujarhtml) | D46 |
| [5.11](#511-versiones-fijas) Versiones fijas | [3.4](#34-requirementstxt) | D48 |
| [5.12](#512-código-oculto-y-avisos-apagados) Código oculto y avisos apagados | [3.1](#31-_quartoyml) | — |
| [5.13](#513-la-salida-generada-no-se-guarda-en-git) La salida no se guarda en git | [3.5](#35-gitignore) | D47 (publicación) |

### 5.1 Herramienta: Quarto dashboard con Python

> **Decisión:** construir el tablero con **Quarto (formato `dashboard`) y Python** (`jupyter: python3`) y publicarlo como HTML
> estático ·
> **Alternativas:** (a) **flexdashboard (R Markdown)** — a favor: es la herramienta que se vio en el módulo y tiene la misma
> lógica de páginas, filas y tarjetas; en contra: el modelo y los datos están en Python, así que habría que reescribirlos en R
> o pasar resultados de un lenguaje a otro, con el riesgo de que las cifras no coincidan; (b) **Shiny** (R o Python) — a favor:
> reactividad total y cálculo en vivo; en contra: necesita un servidor encendido y GitHub Pages sólo sirve archivos;
> (c) **Streamlit o Dash** — a favor: Python puro y *widgets* rápidos; en contra: también necesitan servidor; (d) **Power BI o
> Tableau** — a favor: arrastrar y soltar, conocidos en las empresas; en contra: licencias, no se reconstruyen desde el código
> y no ejecutan el modelo; (e) **un sitio normal de Quarto** (no *dashboard*) — a favor: mejor para texto largo; en contra:
> sin tarjetas, filas ni *value boxes*. No se probó ninguna ·
> **Por qué ésta:** el análisis está en Python y el tablero **importa el mismo código**, así que sus cifras coinciden con las del
> notebook por construcción (la tabla de verificación da 17 de 17); produce un sitio **estático** que GitHub Pages publica gratis
> con GitHub Actions; los *dashboards* de Quarto los hace Posit, el mismo grupo de flexdashboard, con los mismos conceptos (páginas,
> filas, tarjetas, *value boxes*, pestañas); y Quarto se vio en la clase 8 (el workflow cita sus plantillas) ·
> **Si preguntan:** "Porque el modelo está en Python y Quarto nos deja importar ese mismo código; así las cifras del tablero
> coinciden por construcción con las del notebook, y además produce un sitio estático que GitHub Pages publica gratis. Shiny,
> Streamlit o Dash necesitarían un servidor encendido."

### 5.2 Estructura y layout del documento

> **Decisión:** **un solo `index.qmd`** con seis páginas (`#`), filas (`##`) y columnas (`###`) de **alturas y anchos fijos**
> (`{height=…px}`, `{width=…%}`) y `scrolling: true`; **identificadores sin acentos** (`{#que-ocurre}`); pestañas (`.tabset`)
> para lo de segundo nivel; y una `## Column` explícita después de la barra lateral ·
> **Alternativas:** (a) **un archivo por página** (sitio web de Quarto) — a favor: archivos más cortos y una dirección por página;
> en contra: se pierde la navegación de pestañas del *dashboard* y habría que compartir el chunk de preparación entre archivos;
> (b) **el modo por defecto, que se ajusta a la ventana** (sin `scrolling`) — a favor: todo cabe sin desplazarse; en contra: con
> hasta 9 tarjetas en una página las gráficas quedarían muy apretadas; (c) **dejar que Quarto genere los identificadores** — a
> favor: menos escritura; en contra: **se probó**: con acentos (`#qué-ocurre`) la página se abría en blanco; (d) **todo visible, sin
> pestañas** — a favor: nada queda oculto (y no existiría el problema de Plotly); en contra: páginas muy largas. (a), (b) y (d) no se
> probaron ·
> **Por qué ésta:** un solo `render`, un solo chunk de preparación y un diseño predecible; los identificadores ASCII corrigieron un
> error real; las pestañas guardan la información de segundo nivel (tablas y gráficas secundarias) sin llenar la página; y la
> `## Column` explícita corrige que Quarto invierte la orientación después de una barra lateral. Una salvedad: las alturas de las filas
> con pestañas **no se aplican** en el HTML generado ·
> **Si preguntan:** "Es un solo documento con seis páginas; cada fila tiene altura fija para que el diseño sea predecible, y lo
> secundario va en pestañas dentro de la misma tarjeta."

### 5.3 Cifras en línea y frases condicionales

> **Decisión:** escribir los **números del texto como código en línea** (`` `{python} expr` ``, 83 en total) y hacer que **algunas
> frases cambien solas según el dato** (`texto_k`, `texto_borde`, `texto_extension_K`, la nota del simulador según k, y "todas
> coinciden / HAY DIFERENCIAS"); los títulos, las conclusiones y unos pocos datos quedan como texto fijo ·
> **Alternativas:** (a) **escribir todos los números a mano** — a favor: texto más simple de editar; en contra: se desactualiza con cada
> cambio de datos o de parámetros (en el proyecto cambiaron K de 30 a 15 y k de 10 a 0, y se agregó M3 a la prueba) y el texto podría contradecir a las
> gráficas; (b) **generar todo el texto con plantillas** (f-strings o Jinja; `glue` en R) — a favor: coherencia total; en contra:
> texto ilegible para quien lo edita, y las conclusiones no se pueden automatizar sin juicio humano; (c) **un archivo de cifras**
> (JSON) que el texto lea — a favor: separa datos y texto; en contra: otro archivo que mantener. No se probó ninguna ·
> **Por qué ésta:** es un término medio: lo que cambia con los datos (cifras, parámetros del notebook) sale del código y lo que es
> juicio (títulos, conclusiones) lo escribe una persona. **Lo que quedó a mano, con honestidad:** el "3" de la caja "Variables en el
> mejor modelo", "18 de agosto de 2001", "20 equipos", "10,000 remuestreos", los periodos de las particiones ("2019/20–2023/24", "2024/25",
> "ago-2025 a sep-2026"), la lista de columnas y, sobre todo, **todas las frases de interpretación** ("subestima el empate", "el modelo base M0
> fue el más robusto", "quedan en el límite"): las cifras que las respaldan son vivas, las palabras no, y hay que releerlas si cambian los
> datos. Además, `ic()`, `partidos_temporada` y la variable `ventaja_elo` quedaron definidas sin usarse ·
> **Si preguntan:** "Los números del texto se calculan al generar el tablero; no están escritos a mano. Incluso hay frases que cambian
> según el valor: si k no fuera 0, el tablero explicaría la mezcla de temporadas en lugar de decir 'sin mezcla'. Lo que escribimos
> nosotros son los títulos y las conclusiones, que hay que releer si cambian los datos."

### 5.4 Páginas narrativas con títulos que dicen la conclusión

> **Decisión:** seis páginas en el orden de una historia (**Resumen** con la conclusión primero → **¿Qué ocurre?** → **Patrones** →
> **El modelo** → **Explora un partido** → **Datos y método**) y **títulos de tarjeta que dicen el hallazgo** ("Jugar en casa siempre ayuda…
> salvo sin público", "Agregar variables no generaliza", "El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo") ·
> **Alternativas:** (a) **una sola página larga** — a favor: todo a la vista, sin pestañas ocultas; en contra: difícil de recorrer y sin
> jerarquía; (b) **organizar por tipo de gráfica o por archivo** — a favor: fácil de construir; en contra: no cuenta una historia;
> (c) **títulos descriptivos** ("Resultados por temporada") — a favor: neutros y claros; en contra: obligan al lector a sacar la conclusión;
> (d) **el orden de un artículo** (método primero y conclusión al final) — a favor: sigue el orden del análisis; en contra: quien sólo mire
> la primera página no ve la conclusión. No se probó ninguna ·
> **Por qué ésta:** las instrucciones del proyecto piden que la visualización responda qué ocurre, qué patrones hay, qué aporta el modelo y
> cuál es la conclusión principal, y aclaran que se evalúa la comunicación, no la herramienta; el orden sigue esas preguntas y el
> *storytelling* del módulo (conclusión primero, "lectura en 20 segundos"). Los títulos con la conclusión dejan que alguien que sólo
> hojee las tarjetas se lleve el mensaje ·
> **Si preguntan:** "El tablero sigue el orden de las preguntas de la actividad: primero la conclusión, luego qué ocurre, los patrones y lo
> que aporta el modelo; después el simulador y el método. Cada título dice el hallazgo, no el tipo de gráfica."

### 5.5 *Value boxes*

> **Decisión:** **tres *value boxes* por página** en las páginas 1 y 2 (seis en total): un título corto, un número grande y una línea de
> apoyo ·
> **Alternativas:** (a) **una tabla de indicadores** — a favor: compacta y exacta; en contra: no se lee de un vistazo; (b) **el número dentro
> del texto** — a favor: sin componentes nuevos; en contra: se pierde entre las palabras; (c) **más de tres por página** — a favor: más
> información; en contra: contradice la regla de pocos indicadores (máximo 3 por página) y diluye el mensaje; (d) **gráficas pequeñas**
> (*sparklines*) — a favor: muestran tendencia; en contra: los indicadores no son series y añaden ruido. No se probó ninguna ·
> **Por qué ésta:** es el recurso estándar del formato y responde la regla del módulo de "pocos indicadores": en la página 1, cuánto del camino
> al mercado recorre el modelo (80 %), cuántos partidos acierta (48.0 %) y con cuántas variables (3); en la 2, cuántos partidos hay, cuánto gana
> el local y cuánto el favorito. Dos detalles honestos: el "3" está escrito a mano, y el atributo `color` de las cajas no se ve porque el SCSS
> lo cubre con `!important` ·
> **Si preguntan:** "Son los números que queremos que el lector recuerde; no pusimos más de tres por página para que se lean en segundos."

### 5.6 Tema `cosmo` y `estilos.scss`

> **Decisión:** partir del tema **`cosmo`** de Bootswatch y agregar **`estilos.scss`** (variables y reglas) con un estilo de **vidrio** (tarjetas
> translúcidas con desenfoque, bordes suaves, píldoras), una paleta **con significado** (azul = modelo, naranja = mercado, verde = local,
> violeta = visitante, gris = contexto), la misma que las gráficas, y la fuente del sistema ·
> **Alternativas:** (a) **el tema por defecto de Quarto, sin SCSS** — a favor: cero mantenimiento; en contra: aspecto genérico y colores sin
> significado; (b) **otro tema de Bootswatch** (flatly, litera…) — a favor: también trae un estilo completo; en contra: habría que
> sobrescribirlo igual para la paleta; (c) **un CSS plano con `css:`** — a favor: más sencillo; en contra: sin variables de Bootstrap (cambiar
> `$primary` o la fuente) ni anidamiento; (d) **estilos en línea en cada tarjeta** — a favor: nada que compilar; en contra: repetición y difícil
> de mantener. No se probó ninguna ·
> **Por qué ésta:** SCSS permite cambiar el tema en un solo archivo (variables antes de compilar, reglas después) y reutilizar la paleta en las
> partes en HTML (diagrama, simulador), de modo que el mismo color signifique lo mismo en todo el tablero; `cosmo` es un punto de partida plano y
> limpio (el motivo exacto de elegirlo no está documentado). Costos honestos: 27 `!important`, restos sin uso (`$navbar-*`, 12 variables CSS,
> `.lectura .ruta`), `backdrop-filter` en 20 declaraciones (más pesado en equipos lentos; no se midió) y `:has()`, que exige navegadores recientes ·
> **Si preguntan:** "Usamos el tema cosmo de Bootswatch y un archivo SCSS encima; así la paleta es la misma en las gráficas y en el resto de la
> página, y el azul siempre es el modelo y el naranja el mercado."

### 5.7 Diagrama de flujo en HTML y CSS

> **Decisión:** dibujar el diagrama "Cómo funciona" con **HTML y CSS** (`.flujo`, `.paso`, `.flecha`) dentro de una tarjeta ·
> **Alternativas:** (a) **Mermaid** — a favor: se escribe como texto y Quarto lo dibuja; en contra: **se probó** y el diagrama salía
> **vacío**, porque Mermaid no dibuja en páginas ocultas; (b) **una imagen** (PNG o SVG) — a favor: control total del dibujo; en contra:
> no puede llevar la cifra calculada (los 9,540 partidos), no se edita como texto y no se adapta a pantallas chicas (razonada; no se probó);
> (c) **Graphviz o `DiagrammeR`** — a favor: diagramas automáticos; en contra: otra dependencia y, probablemente, el mismo problema de las
> páginas ocultas (no se probó) ·
> **Por qué ésta:** funciona esté la página oculta o no, usa la misma paleta (azul = modelo, naranja = mercado), lleva la cifra viva del número de
> partidos y se adapta a pantallas chicas (los pasos se envuelven y se ocultan las flechas) ·
> **Si preguntan:** "Lo hicimos con HTML y CSS porque Mermaid salía vacío en las páginas ocultas del tablero."

### 5.8 Tablas HTML propias y vista de tabla

> **Decisión:** armar las **siete tablas** con una función propia (`gr.tabla_html`, que escapa el HTML) y mostrarlas con `HTML(tabla)`, y
> ofrecer **vista de tabla** (en una pestaña) para tres gráficas (temporadas, Elo, calibración de cuotas) más las tablas de métricas y de
> bootstrap, para quien no pueda o no quiera leer la gráfica ·
> **Alternativas:** (a) **dejar que Quarto muestre el `DataFrame`** — a favor: una línea de código; en contra: formato y aspecto no
> controlados, sin las clases de `estilos.scss`; (b) **`itables` o `great_tables`** — a favor: filtros, ordenación y formato avanzado; en
> contra: más dependencias y JavaScript, y menos control del estilo; (c) **tablas escritas a mano en Markdown** — a favor: simples; en contra:
> las cifras no se actualizarían; (d) **una tabla para cada gráfica** — a favor: accesibilidad total; en contra: más tablas que mantener. No se
> probó ninguna ·
> **Por qué ésta:** control total del HTML y del estilo (`.tabla`), **escape** de los datos (vienen de archivos), formato uniforme de cifras (`pct`,
> `num`) y ninguna dependencia nueva; las vistas de tabla dan una alternativa a lo que se ve en la gráfica. Limitaciones honestas: no tienen filtros ni
> ordenación, y **sólo 5 de las 11 gráficas tienen vista de tabla** (3 con tabla propia y 2 que comparten la de métricas) ·
> **Si preguntan:** "Las tablas se generan con el mismo formato que el resto de las cifras y están en pestañas; las usamos para las gráficas
> principales, por si alguien prefiere los números."

### 5.9 Observable en el navegador con datos precalculados

> **Decisión:** el simulador usa **Observable JS en el navegador** con los **380 cruces precalculados en Python** (`ojs_define`, ≈ 192 KB): el
> navegador sólo filtra y dibuja (selectores `Inputs.select`, mapa de calor con `Plot.cell`) ·
> **Alternativas:** (a) **Shiny o un servidor de Python** — a favor: calcula cualquier escenario en vivo; en contra: necesita un servidor
> encendido y GitHub Pages no lo ofrece; (b) **Python en el navegador** (Pyodide o Shinylive) — a favor: sin servidor y con el mismo código; en
> contra: el navegador debe descargar Python y los paquetes (arranque lento); (c) **programar el modelo en JavaScript** — a favor: datos mucho
> más pequeños (sólo coeficientes); en contra: una segunda implementación del modelo que la verificación no cubriría; (d) **una tabla estática de
> 380 filas** — a favor: sin JavaScript; en contra: sin interacción; (e) **Plotly para el mapa de calor** — a favor: el mismo motor que el resto;
> en contra: habría que pasar a la página una figura por cruce o armarla en JavaScript, y Observable Plot lo resuelve en pocas líneas. No se
> probó ninguna ·
> **Por qué ésta:** 20 × 19 = 380 cruces son pocos: precalcularlos es barato (≈ 8 s al generar), usa el mismo modelo M0 y la misma verificación (el
> ejemplo Arsenal–Man City coincide en las 5 cifras) y el sitio sigue siendo estático. Costos honestos: sólo existe la fecha de corte (15-sep-2026) y no
> admite ajustes (lesiones, alineaciones); el mapa mide 540 px fijos; las bibliotecas se descargan de jsDelivr; y con k = 0 y sólo 4 partidos por equipo
> las estadísticas son muy ruidosas ·
> **Si preguntan:** "Como sólo hay 380 cruces posibles, los calculamos todos en Python con M0 y el navegador sólo los filtra. Así el simulador
> funciona en un sitio estático; con Shiny habríamos necesitado un servidor encendido."

### 5.10 `redibujar.html`

> **Decisión:** un script de 46 líneas (`include-after-body`) que **vuelve a dibujar** cada gráfica de Plotly con `Plotly.newPlot` cuando pasa de
> oculta a visible: al cargar (a los 250 ms y otra vez a los 1,500 ms), al cambiar de pestaña (`shown.bs.tab`, con 80 ms de espera) y con un
> `ResizeObserver` (cambios de más de 40 px, con 120 ms de espera); busca Plotly en `window.Plotly` o en `window._Plotly` ·
> **Alternativas:** (a) **no hacer nada** — a favor: nada que mantener; en contra: **se probó** y, como 10 de las 11 gráficas se dibujan ocultas, las
> etiquetas salían ausentes o encimadas; (b) **una sola página sin pestañas** — a favor: no habría gráficas ocultas; en contra: se pierde la estructura
> de la historia; (c) **`Plotly.Plots.resize` o `Plotly.relayout` en lugar de `newPlot`** — a favor: más ligero; en contra: no se sabe si vuelve a medir
> los textos (no se probó); (d) **imágenes estáticas** — a favor: sin problema de medición; en contra: sin mensajes al pasar el cursor; (e) **quitar las
> leyendas de Plotly** — se hizo además (`showlegend=False`), pero no basta para las etiquetas de los ejes ·
> **Por qué ésta:** es un arreglo pequeño que no toca las gráficas y sólo actúa cuando una gráfica se vuelve visible; los tres disparadores cubren los
> casos reales (carga lenta, cambio de pestaña, cambio de tamaño). La primera versión no funcionaba porque buscaba sólo `window.Plotly`, y la página carga
> Plotly con RequireJS, que lo deja en `window._Plotly` ·
> **Si preguntan:** "Plotly mide los textos al dibujar, y en una pestaña oculta todo mide cero, así que las etiquetas salían mal. El script vuelve a dibujar
> cada gráfica cuando se vuelve visible."

### 5.11 Versiones fijas

> **Decisión:** fijar con `==` las versiones de los seis paquetes de cálculo y gráficas en `requirements.txt` (pandas 2.2.3, numpy 2.2.3, scipy 1.15.2,
> statsmodels 0.14.4, scikit-learn 1.6.1, plotly 5.24.1), dejar sin versión `jupyter` y `pyyaml`, y fijar Quarto (1.8.25) y Python (3.10) en el workflow ·
> **Alternativas:** (a) **sin versiones** — a favor: siempre lo más nuevo; en contra: una actualización (por ejemplo, un cambio mayor de Plotly o de pandas) puede
> cambiar las cifras o romper el *render* sin que nadie toque el código; (b) **rangos** (`>=2.2,<3`) — a favor: permite parches; en contra: menos
> reproducible; (c) **un archivo de bloqueo completo** (`pip freeze`, `pip-tools`, `conda env export`) — a favor: fija también las dependencias indirectas; en
> contra: más largo y difícil de leer; (d) **Docker** — a favor: fija todo el sistema; en contra: más infraestructura. En R sería `renv`. No se probó ninguna ·
> **Por qué ésta:** es el mínimo que garantiza que el mismo código dé las mismas cifras sin complicar el repositorio (la verificación 17 de 17 lo comprueba también
> en el servidor); `jupyter` y `pyyaml` no afectan las cifras. Debilidad honesta: las dependencias indirectas (`patsy`, `joblib`, `python-dateutil`…) no están
> fijadas ·
> **Si preguntan:** "Fijamos las versiones de los paquetes que calculan y dibujan, y también las de Python y Quarto, para que el tablero dé lo mismo hoy que dentro
> de un año; en GitHub se construye en una máquina limpia con esas versiones."

### 5.12 Código oculto y avisos apagados

> **Decisión:** `execute: echo: false, warning: false, message: false` para **todo** el proyecto: el tablero no muestra código ni avisos (el código está en
> GitHub) ·
> **Alternativas:** (a) **mostrar el código** (`echo: true` o `code-fold`) — a favor: transparencia dentro del propio tablero; en contra: ruido para un lector que
> busca conclusiones; (b) **mostrarlo sólo en algunos chunks** — a favor: equilibrio; en contra: hay que decidirlo chunk por chunk; (c) **dejar visibles los avisos** — a
> favor: se verían problemas; en contra: los avisos de pandas o statsmodels ensuciarían la página. No se probó ninguna ·
> **Por qué ésta:** el público del tablero lee resultados; el código y los datos están en el repositorio y la tabla de verificación muestra que las cifras se
> reproducen. Costo honesto: apagar `warning` también oculta advertencias útiles; la verificación es la red de seguridad ·
> **Si preguntan:** "El tablero es para leer conclusiones; el código completo y los datos están en el repositorio, y la pestaña de reproducibilidad muestra que las
> cifras coinciden con las del notebook."

### 5.13 La salida generada no se guarda en git

> **Decisión:** `.gitignore` excluye `_site/`, `.quarto/`, `index_files/`, `index.html`, `__pycache__/` y los `*.quarto_ipynb`: el sitio se **reconstruye en GitHub
> Actions en cada `push`** ·
> **Alternativas:** (a) **guardar `_site/` en git** — a favor: se ve exactamente lo publicado y no hay que construir; en contra: un HTML de ≈ 5 MB que cambia casi
> por completo en cada *render* y llena el historial, y podría publicarse algo que no corresponde al código; (b) **publicar desde una carpeta `docs/` o una rama
> `gh-pages`** (`quarto publish gh-pages`) — a favor: GitHub Pages sirve directamente la carpeta; en contra: también guarda la salida, en otra rama o carpeta, y se
> puede desincronizar del código. No se probó ninguna ·
> **Por qué ésta:** la fuente es el código; la salida se regenera en una máquina limpia, lo que además prueba que el tablero se reproduce (17 de 17 ✓ en el sitio
> publicado) ·
> **Si preguntan:** "No guardamos el sitio generado: GitHub lo construye desde el código en cada cambio, así lo publicado siempre corresponde al código del
> repositorio."

## 6. Dudas y detalles que conviene saber

### 6.1 Detalles raros, restos y cosas escritas a mano

Ninguno cambia una cifra del tablero, pero conviene conocerlos por si alguien lee el código durante la exposición. El
detalle de lo que **no es calculado** (los datos escritos a mano) es lo que más importa: en la exposición no conviene decir
que "ninguna cifra del tablero está escrita a mano" ni que "cada gráfica tiene su tabla"; **ninguna de las dos cosas es del
todo cierta**.

| # | Dónde | Qué pasa | Si preguntan |
|---|---|---|---|
| 1 | `index.qmd` (varios) | **Texto fijo con datos**: el "3" de la caja "Variables en el mejor modelo" (línea 187), "18 de agosto de 2001" (226), "20 equipos" (476), "10,000 remuestreos" (435), "2019/20 a 2026/27" (292), los periodos de entrenamiento, validación y prueba (374, 604), "2001–2026" (355), "ln 3 ≈ 1.099" (constante) y la lista de las 23 columnas comunes (559). **Todos son correctos hoy** | "Las cifras que cambian con los datos se calculan; unos pocos datos fijos están escritos a mano y los revisamos" |
| 2 | `index.qmd`, todas las frases de interpretación | "Subestima el empate", "el modelo base M0 fue el más robusto", "quedan en el límite", "no tiene un impacto drástico", "el mercado sabe un poco más": son **juicios escritos por una persona** sobre cifras vivas. Si cambian los datos, las palabras no se reescriben solas | "Las cifras son vivas; las conclusiones las escribimos nosotros y están respaldadas por las cifras que aparecen al lado" |
| 3 | Chunk de preparación | `ic()`, `partidos_temporada` y la variable `ventaja_elo` están **definidas y no se usan**; el comentario "aquí sólo se da formato" no es del todo cierto (también hay cálculos: `p_empate_real`, `mt`, los p-valores) | "Quedaron de versiones anteriores; no afectan ninguna cifra" |
| 4 | `ojs_define` (líneas 450–452) | Manda `fecha` y `k_elo`, que **ninguna celda OJS lee**; sólo se usa `k_shrinkage` | Cosmético |
| 5 | Chunk de preparación | `rejilla_K` (Elo) y `rejilla_k` (*shrinkage*) sólo se distinguen por la mayúscula; `lista([])` y `rango([])` fallarían con una lista vacía | Cosmético |
| 6 | Cajas de las páginas 1 y 2 | El atributo `color="#eef5fd"` etc. **no se ve**: el SCSS lo cubre con `!important`. Una versión anterior de la guía describía los tintes ("azul claro = modelo…") como si se vieran | "El color de las cajas lo da el estilo de vidrio, no el atributo" |
| 7 | Filas `{.tabset height=…}` (páginas 2, 3, 4 y 6) | El `height` **no aparece en el HTML generado** (la fila queda en `1fr`): esos 440, 480, 530 y 660 px no tienen efecto. No se verificó visualmente la altura resultante | "La altura de esas filas la define el contenido" |
| 8 | Página 2, tres cajas | Cada una usa una **base distinta**: 9,540 partidos (todo el histórico), 25 temporadas completas (45.6 %…) y partidos con cuotas de Bet365 (54.2 %); no se pueden sumar ni comparar | "Cada caja dice su base: 'temporadas completas', 'Bet365'" |
| 9 | Texto de `pct()` | Escribe "48.0%" **sin espacio**; los textos a mano usan "95 %" y "4.49 %" **con espacio** | Cosmético |
| 10 | Diagrama "Cómo funciona" | El paso dice "Marcadores posibles (Skellam)"; Skellam es la distribución de la **diferencia** de goles (de ahí P(local), P(empate), P(visitante)); la matriz de marcadores sale del producto de dos Poisson | "Skellam da el 1X2; los marcadores individuales, el producto de dos Poisson" |
| 11 | Tarjeta "No es una derrota..." | El título termina en puntos suspensivos a propósito; el subtítulo completa la idea. Lo que muestra: el mercado le gana a M0 en las victorias locales y los empates, pero **M0 es mejor en las victorias visitantes** | "No es una derrota: la brecha es de 0.016 y viene de dos de los tres resultados" |
| 12 | Mapa de calor | Mide **540 px fijos** y su escala de color va **del mínimo al máximo de cada cruce** (el mismo tono vale probabilidades distintas en cruces distintos; para eso cada celda lleva su número) | "Las celdas llevan el número; el color es sólo una ayuda" |
| 13 | Simulador, tabla y notas | Al corte los 20 equipos llevan sólo **4 partidos** y, con k = 0, sus promedios son de cuatro partidos: poco estables (la nota lo dice). Y al cambiar el local, el visitante **vuelve a Man City (o Arsenal)** | "Con tan pocos partidos el pronóstico es muy ruidoso; el simulador es un ejemplo, no una recomendación" |
| 14 | HTML generado | **Todo el tablero** carga jQuery y RequireJS (y el simulador, Plot e Inputs) de **jsDelivr**; sin ese servidor, las gráficas y el simulador no se dibujarían. No se probó sin conexión | "Necesita internet para cargar esas bibliotecas" |
| 15 | `_quarto.yml` | `warning: false` y `message: false` apagan también advertencias útiles; la red de seguridad es la verificación 17 de 17 | — |
| 16 | `estilos.scss` | 27 `!important`, 12 de 29 variables CSS sin uso, `$navbar-*` anulados, `.lectura .ruta` sin uso; `:has()` y `backdrop-filter` piden navegadores recientes (y pesan más en equipos lentos; no se midió) | Cosmético |
| 17 | `requirements.txt` | `jupyter` y `pyyaml` **sin versión**, y no hay archivo de bloqueo: las dependencias indirectas se instalan en su última versión | "Fijamos lo que afecta a las cifras" |
| 18 | `.gitignore` | `.quarto/` aparece dos veces (`.quarto/` y `/.quarto/`) | Cosmético |
| 19 | Tarjeta "Evaluación" | "Ni la validación 2024/25 ni la prueba se usaron para elegirlos" es cierto para **K y k**; la **preferencia por M0** (el modelo del simulador) sí miró la prueba ([capítulo 9](09_evaluacion_y_validacion.md)) | "K y k se eligieron sólo con el entrenamiento; M0 se prefirió por simple y además fue el mejor en prueba" |
| 20 | Caja "80 %" | Es una **razón** de dos mejoras pequeñas; un intervalo bootstrap hecho por la guía (después de la entrega) va de **54 % a 101 %**, y con M4 sería 75 %. No se dice en el tablero | "Es una cifra de orden de magnitud: M0 recorre alrededor de cuatro quintos del camino" |
| 21 | Tarjeta del bootstrap | "Si el intervalo no incluye el cero, la diferencia no se explica por azar" es una paráfrasis laxa; las dos comparaciones al límite (M0 − mercado en prueba y M4 − M0 en validación) cambian de lado con otros métodos | "Dos de las siete comparaciones están al límite; no las presentamos como definitivas" |

**Afirmaciones de la versión anterior de la guía que ya se corrigieron** (por si alguien las recuerda): "ninguna cifra del
tablero está escrita a mano" (hay unas pocas, fila 1); "cada gráfica tiene su tabla" (sólo 5 de 11: 3 con tabla propia y 2
que comparten la de métricas); "`tabla_verificacion()` compara 15 cifras" (son 17); los tintes de los *value boxes* (fila 6);
y "tarjetas sin sombra" (el SCSS entregado es de vidrio, con sombras). El [capítulo 13](13_dashboard.md) actual ya lo dice así.

### 6.2 Preguntas rápidas

**¿Cómo se convierte `index.qmd` en el sitio?** Con `quarto render`: Python ejecuta los 20 chunks y las 83 expresiones,
Pandoc convierte el Markdown, el formato *dashboard* arma la cuadrícula de páginas, filas y tarjetas, Sass compila el tema,
las 6 celdas de Observable se compilan para el navegador y todo se escribe en `_site/`.

**¿Corre Python cuando alguien visita el sitio?** No. Python sólo corre al **generar**; en el navegador corre JavaScript
(Plotly, Observable y `redibujar.html`). Por eso el sitio es estático y se aloja en GitHub Pages.

**¿Por qué el chunk de preparación tiene `include: false` y el de `ojs_define` tiene `echo: false`?** Porque el
primero no debe mostrar nada, y el segundo **sí necesita que su salida llegue a la página** (con `include: false` los datos
del simulador no llegaban).

**¿De dónde sale el 80 % de la primera caja?** De `fraccion_de_mejora`: (LogLoss ingenua − LogLoss M0) / (LogLoss ingenua −
LogLoss mercado) en la prueba, con las cifras de la tabla del bootstrap 0.0537 / 0.0668 ≈ 0.80.

**¿Por qué las gráficas salían mal y qué hace `redibujar.html`?** Plotly mide los textos al dibujar y en una pestaña oculta todo mide
cero; el script las vuelve a dibujar al hacerse visibles (al cargar, al cambiar de pestaña y cuando cambia el tamaño).

**¿Cómo se actualiza el simulador si cambian los datos?** Al generar, Python recalcula los 380 cruces y los entrega con
`ojs_define`; las celdas de Observable no cambian.

**¿Qué pasa si el equipo cambia K en `wc_predictor.py`?** El texto lo lee solo (`texto_borde` y `texto_extension_K` se ajustan;
las cifras de "Variables del modelo" cambian) y el simulador usa el nuevo K; los modelos, en cambio, usan la base de
`premier_training_data.csv`, que no cambia hasta que el notebook se vuelva a ejecutar ([13a.10](13a_codigo_datos_dashboard.md#13a10-preguntas-rápidas)).

**¿Por qué no Shiny?** Porque Shiny necesita un servidor encendido y GitHub Pages sólo sirve archivos; el simulador sólo filtra 380
cruces precalculados, que cabe en el navegador.

**¿Qué hace el SCSS?** Cambia las variables del tema `cosmo` y agrega reglas para el estilo de vidrio, las tablas, el diagrama de
flujo, el simulador y las leyendas; la regla `:has()` de las tarjetas evita la barra de desplazamiento entre el subtítulo y la gráfica.

**¿Cómo se reproduce el tablero?** `pip install -r Dashboard-o-pagina/requirements.txt` y `quarto render Dashboard-o-pagina` (Python
3.10, Quarto 1.8.25); GitHub Actions hace lo mismo en cada `push` y publica `_site/` ([capítulo 14](14_publicacion_en_github.md)).

**¿Qué está escrito a mano en el tablero?** Los títulos, las frases de conclusión y unos pocos datos (el "3", "18 de agosto de 2001",
"20 equipos", "10,000 remuestreos", los periodos); todas las demás cifras se calculan.

**¿Por qué el simulador arranca en Arsenal contra Man City?** Porque es el cruce que verifica la página 6 contra el notebook
(5 cifras ✓) y los valores iniciales de los menús.

### 6.3 Cómo se escribió este capítulo (qué se verificó y qué no)

| Qué | Cómo | Resultado |
|---|---|---|
| Código de `index.qmd`, `_quarto.yml`, `redibujar.html`, `requirements.txt`, `.gitignore`, `README.md` y `estilos.scss` | Copiado de los archivos entregados, leídos completos | Los fragmentos de código son literales |
| Cifras de ejemplo | Leídas del **sitio ya generado** (`_site/index.html`, 30-sep-2026 23:29) y de la tabla de verificación; ninguna recalculada | 1,897 / 380 / 419, 0.016, 80 %, 17 de 17, etc. |
| Estructura del HTML | Búsquedas de texto en el HTML generado (cuadrículas de CSS, clases, scripts externos, `ojs-define` ≈ 192 KB, `data-orientation`, `dashboard-scrolling`) y en el CSS compilado (regla `.bslib-value-box … !important`) | Los hechos de [2.1](#21-el-encabezado-yaml), [2.3.2](#232-fila-2-los-tres-value-boxes-líneas-164190) y [2.4.3](#243-fila-3-pestañas-líneas-271283) |
| Conteos (chunks, expresiones, tarjetas, filas…) | Contados con `grep` sobre `index.qmd` | 20 + 6 chunks, 83 expresiones, 30 + 2 tarjetas, 6 *value boxes* |
| Bloques de R | **Ilustrativos**: no se ejecutaron | — |
| Comportamientos de navegador (jsDelivr sin conexión, `:has()` en navegadores viejos, aspecto en celulares, altura real de las filas con pestañas, aspecto de los *value boxes*) | **No se probaron** | Se describen como consecuencia del código, con la salvedad correspondiente |
| Razones de diseño que no constan en el proyecto (por qué `cosmo`; por qué se pasan "piezas" a `ojs_define`; por qué la tolerancia de 40 px) | Marcadas como "razón probable" o "no consta" | — |

Lo que **no** se probó en el proyecto y aparece aquí como alternativa razonada: flexdashboard, Shiny, Streamlit, Power BI, un
sitio con varios archivos, otros temas, `itables`, Pyodide o Shinylive, `Plotly.Plots.resize` en lugar de `newPlot`, un archivo de
bloqueo o Docker, y publicar desde `docs/` o `gh-pages`.
