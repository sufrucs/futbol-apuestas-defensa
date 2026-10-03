# 13. El dashboard: diseño y arquitectura

[← Resultados](12_resultados.md) · [Índice](README.md) · [Siguiente: `datos_dashboard.py` →](13a_codigo_datos_dashboard.md)

**URL:** https://pitirringo.github.io/futbol-apuestas/

> **Versión que se describe:** la entregada (rama `main`, commit `e3bd43f`, 30-sep-2026). Este capítulo explica el
> **diseño** del tablero y cómo se conectan sus piezas. El **código**, pieza por pieza, está en tres capítulos:
> [13a](13a_codigo_datos_dashboard.md) (`datos_dashboard.py`), [13b](13b_codigo_graficas.md) (`graficas.py`) y
> [13c](13c_codigo_index_quarto.md) (`index.qmd`, `estilos.scss` y los archivos de configuración). Las decisiones, con
> sus alternativas, están en el [capítulo 19](19_decisiones_y_alternativas.md) (**D39 a D50**). Para este capítulo no
> se ejecutó R ni Quarto: los bloques de R están marcados **ilustrativo** (código razonado, no probado).

## 13.1 Qué debía lograr

Las instrucciones piden "una visualización publicada y accesible mediante URL" que permita
entender, como mínimo: **¿qué ocurre?, ¿qué patrones o relaciones encontraron?, ¿qué aporta el
modelo? y ¿cuál es la conclusión principal?** Y aclaran que "no se evaluará la herramienta
utilizada, sino la capacidad de la visualización para comunicar los resultados".

**Decisión de estructura:** una página por pregunta, en el orden de una historia (el recorrido
completo está en [13.5](#135-indexqmd-la-estructura-y-el-recorrido-por-las-seis-páginas)).

| Lo que piden las instrucciones | Página del tablero | Papel en la historia (*storytelling*) |
|---|---|---|
| ¿Cuál es la conclusión principal? | **Resumen** | Conclusión primero: pregunta, hipótesis, resultado y "lectura en 20 segundos" |
| ¿Qué ocurre? | **¿Qué ocurre?** | Planteamiento: el fenómeno y por qué es difícil predecirlo |
| ¿Qué patrones o relaciones hay? | **Patrones** | Desarrollo: la evidencia que justifica el modelo |
| ¿Qué aporta el modelo? | **El modelo** | Conflicto y resolución: el modelo contra el mercado |
| — | **Explora un partido** | Exploración libre: un simulador con el modelo M0 |
| — | **Datos y método** | Respaldo: datos, limpieza, variables, evaluación, limitaciones y reproducibilidad |

**La pregunta del propio tablero** (tarjeta superior de *Resumen*): ¿qué tan bien anticipan el resultado de un
partido las estadísticas disponibles antes del encuentro, frente a las probabilidades implícitas en las cuotas de
apuestas? **Hipótesis:** las estadísticas contienen información útil, pero el mercado, que además tiene información
ventajosa, la aprovecha mejor. **Resultado:** el modelo se acerca mucho al mercado, pero no lo supera. El reporte
técnico formula la pregunta de otra manera (cuánto mejoran la predicción las variables históricas de fortaleza y de
desempeño reciente, y cómo se compara con las cuotas de apertura). Son formulaciones complementarias, no
contradictorias; véase el [capítulo 20](20_el_reporte_entregado.md).

## 13.2 La herramienta: Quarto (formato *dashboard*) + Python

| Opción | Por qué sí / por qué no |
|---|---|
| **Quarto + Python** ✅ | El análisis del equipo está en Python: el tablero **importa el mismo código** y recalcula todo, así que sus cifras coinciden con las del notebook por construcción. Usa los mismos conceptos que Flexdashboard. Quarto se vio en la clase 8 |
| Flexdashboard (R) | Es la herramienta del tema 2 del módulo, pero habría obligado a reescribir el modelo en R o a pasar resultados de un lenguaje a otro (riesgo de que las cifras no coincidan) |
| Shiny | Necesita un servidor encendido (shinyapps.io); la interactividad que queríamos funciona en el navegador |
| Streamlit o Dash (Python) | También necesitan un servidor encendido |
| Power BI o Tableau | Licencias, y el tablero no se reconstruiría desde el código |
| Blogdown / sitio web | Sirve para varias historias; aquí hay una sola historia con evidencia densa |

**Quarto dashboards es el sucesor de Flexdashboard** (lo hace el mismo grupo, Posit), con la misma
lógica: páginas, filas, columnas, tarjetas, *value boxes*, pestañas.

**Qué se usa en cada capa:** Python 3.10 con pandas 2.2.3, statsmodels 0.14.4, scipy 1.15.2 y scikit-learn 1.6.1
(las cifras); Plotly 5.24.1 (las gráficas); Observable JS (el simulador); el tema `cosmo` de Bootstrap con Sass
(`estilos.scss`); Quarto 1.8.25 (arma el sitio); GitHub Actions y GitHub Pages (lo publican,
[capítulo 14](14_publicacion_en_github.md)).

> **Decisión:** `index.qmd` con `format: dashboard` y `jupyter: python3`: los chunks se ejecutan con el mismo Python del
> equipo; se construye con Quarto 1.8.25 y sale como HTML estático en `_site/`.
> **Alternativas:** las de la tabla anterior. **Ninguna se probó**; se descartaron por las razones que ahí se dan.
> **Por qué ésta:** el análisis está en Python y el tablero importa el mismo código; Quarto produce un sitio estático que
> GitHub Pages publica gratis; es del mismo grupo y usa los mismos conceptos que Flexdashboard; y se vio en clase.
> **Evidencia en el proyecto:** el sitio se construye solo en GitHub Actions y su tabla de verificación da 17 de 17
> ([13.6](#136-datos_dashboardpy-el-backend-y-las-cifras-que-vienen-del-código)).
> **Si preguntan:** "Porque el modelo está en Python y Quarto nos deja importar ese mismo código, así las cifras del
> tablero coinciden por construcción con las del notebook. Además produce un sitio estático que GitHub Pages publica
> gratis; Shiny, Streamlit o Dash necesitarían un servidor encendido."

(Es la decisión [D39](19_decisiones_y_alternativas.md#d39-quarto-formato-dashboard--python--razonada) del capítulo 19.)

## 13.3 Principios de diseño aplicados (material del módulo)

| Principio del módulo | Cómo se aplicó |
|---|---|
| Entender el contexto y la audiencia | Profesores (conocen LogLoss) y compañeros: dos lenguajes a la vez, LogLoss para unos y "aciertos" o "80 %" (la parte de la ventaja del mercado que alcanza el modelo) para todos |
| Contar una historia (inicio, conflicto, resolución) | Orden de páginas: Resumen → ¿Qué ocurre? → Patrones → El modelo; después, el simulador y el método |
| "Lectura en 20 segundos" (ejemplo de vuelos) | Portada: una tarjeta con pregunta, hipótesis y resultado; tres indicadores; y la tarjeta "Resumen" con 4 conclusiones numeradas |
| Títulos que comunican hallazgos | "Jugar en casa siempre ayuda… salvo sin público" y "Agregar variables no generaliza", no "Resultados por temporada" |
| Pocos indicadores (máximo 3 por página) | 3 *value boxes* en *Resumen* y 3 en *¿Qué ocurre?* |
| Jerarquía: gráfica principal ≈ 2/3 del ancho | Columnas de 62 % / 38 % (Resumen), 64 % / 36 % (¿Qué ocurre?) y 66 % / 34 % (El modelo, "Cómo funciona"); 58 / 42 y 52 / 48 donde dos gráficas pesan casi igual |
| Pestañas para información de segundo nivel | Tablas y gráficas secundarias en `.tabset` (cuatro de las seis páginas) |
| El color se reserva para lo importante | Azul = modelo, naranja = mercado, verde = local, violeta = visitante, **gris = todo lo demás** |
| Barras desde cero; sin pasteles ni 3D; etiquetas directas | Todas las barras parten de 0; etiquetas al final de las barras y de las líneas; la leyenda, cuando hace falta, va en HTML en el subtítulo de la tarjeta |
| La precisión sigue a la decisión | LogLoss con 3 decimales en el texto (4 en las tablas), porque las diferencias están en la tercera cifra; porcentajes con 1 decimal (0 en el indicador principal) |
| Accesibilidad | Paleta revisada para daltonismo (el gris del empate junto a un aqua falló con deuteranopía y se cambió el local a verde); el color casi nunca va solo (etiquetas directas, cifras en las barras); tooltips con las cifras exactas; **5 de las 11 gráficas** tienen vista de tabla (tres con tabla propia —temporadas, Elo y calibración de las cuotas— y dos que comparten "Métricas completas"); las otras llevan sus cifras en la etiqueta o en el tooltip |

**Accesibilidad, con sus límites** (detalle y cálculos de contraste en [13b.5](13b_codigo_graficas.md)):

- **Lo que hay:** el docstring de `graficas.py` afirma que la paleta se validó para daltonismo (la evidencia
  documentada es el cambio del local de aqua a verde); los cinco colores de entidad superan 3:1 contra blanco y los
  textos principales superan 4.5:1 (cálculo propio de la guía); `lang: es`; `aria-label` en el botón de GitHub.
- **Lo que no hay:** texto alternativo (`fig-alt`) para las gráficas; navegación por teclado de los tooltips; los
  números de los ejes tienen un contraste de 3.59:1, por debajo de los 4.5:1 recomendados; y **seis gráficas no tienen
  tabla**. **No es cierto que "cada gráfica tenga su tabla".**

## 13.4 La arquitectura: de los archivos del equipo al sitio publicado

```text
Archivos del equipo (Codigo/proyecto_mod_8/)
  E0_consolidado.csv · premier_training_data.csv · wc_predictor.py · Analisis.ipynb
        │  se leen: datos, código del equipo y salidas guardadas del notebook
        ▼
datos_dashboard.py ....... backend: calcula TODAS las cifras → preparar_todo() → diccionario d (28 entradas)
        │  tablas y diccionarios
        ▼
graficas.py .............. capa visual: paleta + plantilla + una función por gráfica → figuras de Plotly
        │  figuras y tablas HTML
        ▼
index.qmd ................ narrativa: seis páginas, textos con {python} en línea, simulador en Observable JS
        │  quarto render (Quarto 1.8.25, Python 3.10)         ← estilos.scss · redibujar.html
        ▼
_site/index.html ......... sitio estático (HTML + JavaScript)
        │  push a main
        ▼
GitHub Actions ........... repite todo lo anterior en una máquina limpia y sube _site/
        │
        ▼
GitHub Pages ............. https://pitirringo.github.io/futbol-apuestas/
```

**Lo que el tablero toma del equipo de Código:**

| Archivo del equipo | Qué le da al tablero | Capítulo |
|---|---|---|
| `E0_consolidado.csv` (9,540 × 34) | El histórico: exploración, cuotas, auditoría y simulador | [3](03_limpieza_de_datos.md) |
| `premier_training_data.csv` (2,696 × 24) | La base de modelación (caché de las variables previas al partido): modelos M0–M4 | [11](11_codigo_analisis_notebook.md) (D49) |
| `wc_predictor.py` | Elo, promedios de temporada y forma reciente; K = 15, k = 0 y la escala 400 | [10](10_codigo_wc_predictor.md) |
| `Analisis.ipynb` | Su **código** (ventana de 10 partidos, decaimiento 0.85, rejillas y pliegues de la calibración) y sus **salidas guardadas** (para verificar) | [11](11_codigo_analisis_notebook.md) |

**Los archivos de `Dashboard-o-pagina/`:**

| Archivo | Qué es | Líneas | Se explica en |
|---|---|---|---|
| `_quarto.yml` | Proyecto Quarto: salida en `_site/`, renderiza sólo `index.qmd`, `lang: es`, y por omisión no muestra código, advertencias ni mensajes | 12 | [13c](13c_codigo_index_quarto.md) |
| `index.qmd` | El tablero: encabezado YAML, un chunk de preparación y seis páginas con sus textos, tarjetas, gráficas y simulador | 670 | [13c](13c_codigo_index_quarto.md) |
| `datos_dashboard.py` | **Backend**: calcula todas las cifras (importa `wc_predictor.py`, reproduce las funciones del notebook, agrega los complementos y verifica) | 906 | [13a](13a_codigo_datos_dashboard.md) |
| `graficas.py` | **Capa visual**: paleta, plantilla y una función por gráfica (11), más las tablas HTML | 374 | [13b](13b_codigo_graficas.md) |
| `estilos.scss` | Tema visual sobre `cosmo` (variables y reglas) | 970 | [13c](13c_codigo_index_quarto.md) |
| `redibujar.html` | JavaScript que vuelve a dibujar las gráficas de Plotly cuando pasan de ocultas a visibles | 46 | [13c](13c_codigo_index_quarto.md) |
| `requirements.txt` | Versiones fijas: pandas 2.2.3, numpy 2.2.3, scipy 1.15.2, statsmodels 0.14.4, scikit-learn 1.6.1, plotly 5.24.1; `jupyter` y `pyyaml` sin versión | 10 | [13c](13c_codigo_index_quarto.md) |
| `README.md` | Descripción de la carpeta: las seis páginas, la estructura del repositorio y la variable `RUTA_CODIGO` | 48 | [13c](13c_codigo_index_quarto.md) |
| `.gitignore` | Ignora lo generado: `_site/`, `.quarto/`, `index_files/`, `index.html`, `__pycache__/`, `*.pyc` | 10 | [13c](13c_codigo_index_quarto.md) |
| *(generados, no se suben)* | `_site/` (el sitio), `.quarto/` y `__pycache__/` | — | [14](14_publicacion_en_github.md) |

Fuera de esa carpeta, `.github/workflows/publicar-dashboard.yml` es el archivo que construye y publica el sitio en
cada `push` ([capítulo 14](14_publicacion_en_github.md)).

**Separación de responsabilidades:** números (`datos_dashboard.py`), gráficas (`graficas.py`) y
narrativa (`index.qmd`). Si cambia un dato, no hay que tocar las gráficas; si cambia un color, no
hay que tocar los datos. Para que se cumpla, `graficas.py` ni siquiera importa `datos_dashboard`: recibe tablas ya
calculadas, y `index.qmd` sólo les da formato.

**Qué pasa al renderizar** (`quarto render Dashboard-o-pagina`):

1. Quarto lee `_quarto.yml` (renderiza `index.qmd`) y ejecuta sus chunks de Python con el kernel `python3` de Jupyter.
2. El primer chunk importa los dos módulos y calcula **una sola vez** `d = dd.preparar_todo()` (≈ 10 s en esta
   computadora, casi todo el simulador; [13a](13a_codigo_datos_dashboard.md)). Las llamadas siguientes devuelven lo guardado (`@lru_cache`).
3. Cada tarjeta llama `gr.mostrar(gr.función(...))` (11 gráficas) o inserta una tabla HTML (7 tablas).
4. Los chunks `{ojs}` del simulador se compilan a JavaScript, que corre en el navegador.
5. Pandoc arma el HTML con el tema `cosmo` + `estilos.scss` y Quarto lo escribe en `_site/`.

## 13.5 `index.qmd`: la estructura y el recorrido por las seis páginas

`index.qmd` (670 líneas) es el tablero. Tiene **seis páginas** (los encabezados `#`), y cada una lleva un identificador
sin acentos (`{#resumen}`, `{#que-ocurre}`, `{#patrones}`, `{#modelo}`, `{#simulador}`, `{#datos}`), así que el enlace
`…/futbol-apuestas/#que-ocurre` abre directamente esa página. En total hay **11 gráficas de Plotly**, el **mapa de
marcadores** del simulador (Observable Plot) y **7 tablas**. Cada tarjeta lleva un título que dice el hallazgo.

### 13.5.1 Resumen: ¿cuál es la conclusión principal?

- **Qué hay:** una tarjeta con la **pregunta, la hipótesis y el resultado**; tres indicadores (*value boxes*):
  *Ventaja del mercado que alcanza el modelo* (**80 %**), *Partidos acertados por el modelo* (**48.0 %** en prueba, contra
  48.9 % del mercado y 41.5 % de la referencia ingenua) y *Variables en el mejor modelo* (**3**); la gráfica "El modelo
  recupera la mayor parte de la ventaja del mercado, sin superarlo" (62 % del ancho) y la tarjeta "Resumen", con cuatro
  conclusiones numeradas (38 %).
- **Cómo se lee el 80 %:** en prueba, la referencia ingenua tiene LogLoss 1.0868, el modelo M0 1.0331 y el mercado de
  apertura 1.0200. La parte de la ventaja del mercado que logra el modelo es
  (1.0868 − 1.0331) / (1.0868 − 1.0200) = 0.0537 / 0.0668 ≈ 0.80: "de cada 100 puntos que el mercado mejora sobre la
  referencia ingenua, el modelo logra 80". Es una **razón de dos mejoras pequeñas**, así que es una cifra de orden de
  magnitud: un intervalo *bootstrap* que calculó esta guía después de la entrega (no aparece en el tablero) va de 54 % a
  101 %.
- **Mensaje:** las estadísticas sí anticipan resultados; el mercado sabe un poco más; más variables no es mejor; el
  modelo simple se acerca al mercado pero no le gana.

### 13.5.2 ¿Qué ocurre?: el fenómeno

- **Qué hay:** tres indicadores: *Partidos analizados* (9,540, en 26 temporadas), *Gana el equipo local* (45.6 %; empate
  24.7 %, visitante 29.7 %, en las 25 temporadas completas) y *Gana el favorito de las cuotas* (54.2 %, con Bet365); las
  gráficas "Jugar en casa siempre ayuda… salvo sin público" (64 % del ancho) y "Ni el favorito es garantía" (36 %); y, en
  pestañas, "Qué significa para el modelo" (con la sensibilidad sin público) y "Tabla por temporada".
- **Mensaje:** predecir fútbol es difícil por naturaleza (el favorito de las casas sólo gana ≈ 54 %); la ventaja de jugar
  en casa es real, pero desaparece en 2020/21, la temporada de los estadios vacíos. Por eso el tablero evalúa
  **probabilidades** y no sólo aciertos.

### 13.5.3 Patrones: qué relaciones hay

- **Qué hay:** "A más ventaja de Elo, más victorias locales" (58 %): el local gana **12.6 %** de las veces en el decil
  con más desventaja y **76.3 %** en el de más ventaja; "Las cuotas están bien calibradas" (42 %); y, en pestañas, "Los goles
  se comportan como un conteo de Poisson", "Por qué importan estos patrones" y dos tablas (Elo y calibración).
- **Mensaje:** cada patrón se traduce en una decisión del modelo: **Elo** como variable principal, el **mercado
  calibrado** como rival difícil y los goles tipo Poisson como razón para usar **regresión de Poisson**.

### 13.5.4 El modelo: qué aporta

- **Qué hay:** el diagrama "Cómo funciona" (hecho con HTML y CSS: histórico → variables previas al partido → dos
  regresiones de Poisson → el paso "Marcadores posibles (Skellam)", que da P(local), P(empate) y P(visitante) →
  comparación con LogLoss, contra el mercado) y "En pocas palabras"; "Agregar variables no generaliza" (52 %) y "No es
  una derrota..." (48 %); y cinco pestañas: qué variables pesan más, calibración modelo vs. mercado, modelo vs. mercado
  partido a partido, métricas completas y la tabla del *bootstrap* ("¿Son significativas las diferencias?"). (Precisión:
  Skellam es la distribución de la **diferencia** de goles, de ahí salen las tres probabilidades; la matriz de marcadores
  sale del producto de dos Poisson.)
- **Mensaje:** M0 es el más robusto (3 variables por ecuación); las variables extra ayudan en validación pero no en
  prueba; el mercado es un poco mejor, y la brecha (+0.0159 de LogLoss en validación y prueba juntas) viene sobre todo de
  las victorias locales y los empates: en las victorias visitantes el modelo fue mejor. Por eso el título dice "No es una
  derrota...".

### 13.5.5 Explora un partido: el simulador

- **Qué hay:** una barra lateral con dos selectores (equipo local y visitante, entre los 20 de la temporada 2026/27);
  tres indicadores (probabilidad de cada resultado, goles esperados y marcador más probable); un mapa de calor con la
  probabilidad de cada marcador de 0 a 5 goles; y la tabla "¿De dónde sale el pronóstico?" (Elo, goles a favor y en
  contra, partidos jugados). Un aviso aclara que es de uso académico y no una recomendación de apuesta.
- **Mensaje:** el modelo se puede explorar y explicar: cada pronóstico sale de la diferencia de Elo y de los goles a
  favor y en contra de la temporada de cada equipo. Cómo funciona por dentro: [13.8](#138-el-simulador-explora-un-partido-observable-js).

### 13.5.6 Datos y método: el respaldo

- **Qué hay:** ocho pestañas: *Datos y procedencia*, *Limpieza y calidad* (con la revisión de calidad de
  `E0_consolidado.csv`), *Variables del modelo*, *Evaluación* (incluye la calibración de K y k), *Limitaciones y
  extensiones*, *Reproducibilidad* (la verificación de 17 cifras y cómo reproducir el tablero), *Glosario* y *Equipo*.
- **Mensaje:** todo lo que respalda la historia está a un clic, sin saturar las otras páginas.

**El código de `index.qmd`, en breve:**

- El encabezado YAML activa `format: dashboard` (orientación por filas, `scrolling: true`, tema `cosmo` + `estilos.scss`,
  `redibujar.html` al final del cuerpo y un botón de GitHub en la barra) y `jupyter: python3`.
- Un primer chunk (`include: false`) importa `datos_dashboard` y `graficas`, calcula `d = dd.preparar_todo()` y define
  los ayudantes de formato (`pct`, `num`, `ll`, `acc`, `ic`, `fecha_es`…) y las 7 tablas. En total el archivo tiene 20
  chunks de Python, 83 expresiones `{python}` en línea y 6 celdas de Observable (conteo del [13c](13c_codigo_index_quarto.md)).
- Después la estructura es siempre la misma: `#` página → `##` fila → `###` columna → `::: {.card title="…"}` tarjeta; las
  cifras van en `` `{python} …` `` y cada gráfica es un chunk de una línea: `gr.mostrar(gr.función(d["…"]))`.
- Cada tarjeta, la sintaxis comparada con Flexdashboard y los equivalentes en R: [capítulo 13c](13c_codigo_index_quarto.md).

> **Decisión:** seis páginas en el orden de una historia (Resumen → ¿Qué ocurre? → Patrones → El modelo → Explora un
> partido → Datos y método); cada tarjeta lleva un título que dice el hallazgo; tres indicadores en las dos primeras
> páginas; identificadores sin acentos.
> **Alternativas:** (a) una sola página larga; (b) organizar por tipo de gráfica o por archivo; (c) títulos descriptivos
> ("Resultados por temporada"). **Ninguna se probó.** (a) es difícil de recorrer, (b) no cuenta una historia y (c) obliga
> al lector a sacar la conclusión.
> **Por qué ésta:** las instrucciones piden responder qué ocurre, qué patrones hay, qué aporta el modelo y cuál es la
> conclusión principal, y aclaran que se evalúa la comunicación, no la herramienta; el orden sigue esas preguntas y el
> *storytelling* del módulo.
> **Evidencia en el proyecto:** la estructura de `index.qmd` (los seis encabezados `#`) y el recorrido de arriba.
> **Si preguntan:** "El tablero sigue el orden de las preguntas que pide la actividad: primero la conclusión, luego qué
> ocurre, los patrones y lo que aporta el modelo; después el simulador y el método. Cada título dice el hallazgo, no el
> tipo de gráfica."

(Es la decisión [D45](19_decisiones_y_alternativas.md#d45-una-historia-en-seis-páginas-con-títulos-que-dicen-la-conclusión--razonada)
del capítulo 19.)

## 13.6 `datos_dashboard.py`: el backend y las cifras que vienen del código

**Objetivo:** que todas las cifras del tablero salgan del **mismo código y los mismos datos** que el notebook del
equipo.

**El código, en breve** (función por función: [capítulo 13a](13a_codigo_datos_dashboard.md)):

- `datos_dashboard.py` (906 líneas, siete secciones) es el **backend**. Hace cuatro trabajos: **traer el código del
  equipo** (importa `wc_predictor.py` y lee del código de `Analisis.ipynb` la ventana, el decaimiento, las rejillas y los
  pliegues de la calibración), **reproducir el modelo** (copia, con los mismos nombres, las funciones del notebook que
  no se pueden importar, y reentrena M0–M4), **agregar lo que el notebook no calcula** (exploración, aciertos,
  *bootstrap*, calibración, brecha con el mercado, efectos, sensibilidad sin público, simulador y auditoría de datos) y
  **verificar** (17 cifras).
- Importa `wc_predictor.py` **desde su carpeta** (`../Codigo/proyecto_mod_8`, o la que diga la variable de entorno
  `RUTA_CODIGO`) porque ese módulo lee `E0_consolidado.csv` con una ruta relativa. Lo hace en silencio: la versión
  inicial imprimía el ranking de Elo al importarse; la entregada ya no imprime nada, y el docstring de
  `_importar_wc_predictor` quedó desactualizado ([13a.9](13a_codigo_datos_dashboard.md)).
- `preparar_todo()` junta todo en un diccionario de 28 entradas, y `@lru_cache` es **memorización**: la primera llamada
  calcula y las siguientes devuelven el resultado guardado (en R, `memoise::memoise()`, o simplemente se calcula una vez
  en el chunk de preparación).

### 13.6.1 Qué sale del código y qué sigue escrito a mano

| Sale del código (se actualiza solo) | Cómo llega al texto |
|---|---|
| Resultados: LogLoss, aciertos, probabilidades, intervalos *bootstrap*, calibración, brecha con el mercado, efectos | `d = dd.preparar_todo()` y expresiones `` `{python} …` `` en línea (y los *value boxes*) |
| Parámetros del modelo: K del Elo, k del *shrinkage*, escala 400, ventana, decaimiento, rejillas y pliegues de la calibración | `dd.K_ELO`, `dd.K_SHRINKAGE`, `dd.ESCALA_ELO`, `dd.N_FORMA`, `dd.DECAY_FORMA` y `d["config_notebook"]`: se leen de `wc_predictor.py` y del código del notebook. La tarjeta "Variables del modelo" muestra hoy "K = 15 (calibrado)" y "k = 0 (calibrado)" sin que esos valores estén escritos en el texto |
| Frases que dependen de un valor | Son **condicionales**: "es decir, sin mezcla" sólo si k = 0; "el K elegido quedó en el borde inferior de la rejilla" sólo si lo es; el texto del simulador cambia con k; la frase de la verificación dice "todas coinciden" o "HAY DIFERENCIAS: revisar antes de publicar" |

| Sigue escrito a mano | Dónde |
|---|---|
| El **"3"** de la tarjeta "Variables en el mejor modelo", "**Del 18 de agosto de 2001**", "**20 equipos**" y "**10,000 remuestreos**" | `index.qmd` (hoy son correctos) |
| Los **periodos** de entrenamiento, validación y prueba (2019/20–2023/24, 2024/25, ago-2025 en adelante) y las etiquetas "3 variables" y "9 variables" | `index.qmd` y `graficas.py` ([13b.3](13b_codigo_graficas.md)) |
| Las **fechas de corte** de las particiones y las fechas del periodo sin público (17-jun-2020 a 23-may-2021) | constantes de `datos_dashboard.py` |
| Las **lecturas en palabras** ("el mercado sabe un poco más", "la prueba sola no es concluyente") | `index.qmd`: las escribió una persona al ver los resultados; si cambiaran los datos habría que releerlas |

**Si preguntan "¿hay cifras escritas a mano?":** los **resultados** (LogLoss, aciertos, probabilidades, intervalos…) no;
sí quedan unos pocos datos de contexto y frases fijas, que son correctos hoy (tabla de arriba). El detalle está en
[13a.9](13a_codigo_datos_dashboard.md), [13b.3](13b_codigo_graficas.md) y [13c](13c_codigo_index_quarto.md).

### 13.6.2 La verificación de 17 cifras

La pestaña *Datos y método → Reproducibilidad* trae una tabla que compara cifras del tablero contra las que el
**notebook dejó guardadas** en sus salidas (`tabla_verificacion()`, [13a.7.6](13a_codigo_datos_dashboard.md#13a76-tabla_verificacion)).
Compara **17**:

| Grupo | Cifras | Cuántas |
|---|---|---|
| LogLoss en validación | M0, M1, M2, M3, M4 y el mercado de apertura | 6 |
| LogLoss en prueba | M0, M1, M2, M3, M4 y el mercado de apertura | 6 |
| Ejemplo Arsenal–Man City (M0, corte del 15-sep-2026) | λ de Arsenal (1.538) y de Man City (1.266); P(gana Arsenal) 0.4365, P(empate) 0.2500, P(gana Man City) 0.3135 | 5 |
| **Total** | | **17** |

- **Tolerancia:** 5 × 10⁻⁷ (media unidad de la sexta cifra decimal, porque el notebook imprime 6 decimales). La diferencia
  más grande es 4.27 × 10⁻⁷ (M3 en prueba).
- **Resultado:** **17 de 17 ✓**, también en el sitio que construye GitHub Actions. Si alguna fila fallara, la tabla marcaría
  ✗ y el texto diría "HAY DIFERENCIAS", pero **la publicación no se detiene**: el tablero avisa, no bloquea.

**La evidencia de que no es una lista copiada:** la verificación pasó de **15 a 16 y a 17 cifras** sin que nadie
cambiara su lista.

| Fecha | Cómo se verificaba | Cifras | Qué pasó |
|---|---|---|---|
| 22-sep | Contra cifras **copiadas a mano** en `datos_dashboard.py` (con K = 30 y k = 10) | 15 (10 LogLoss + 5 del ejemplo) | Primera versión; al calibrar K = 15 y k = 0, esas cifras quedaron viejas |
| 30-sep (`9f84684`) | Contra las **salidas guardadas** de `Analisis.ipynb`, leídas en cada render | 16 (11 LogLoss + 5) | En ese momento la prueba del notebook evaluaba M0, M1, M2 y M4 |
| 30-sep (Daniel sube el notebook con M3 en la prueba) | La misma, sin tocar el tablero | **17** (12 LogLoss + 5) | El notebook ya imprime M3 en prueba (LogLoss 1.033868) y la tabla lo incorporó **sola** |

| Demuestra | No demuestra |
|---|---|
| Que las funciones copiadas del notebook reproducen las suyas (12 LogLoss de cinco modelos y el mercado) | Nada sobre los complementos (*bootstrap*, calibración…), que el notebook no calcula |
| Que `premier_training_data.csv`, K y k del módulo coinciden con los del notebook | Que el notebook sea correcto: compara contra él, no contra una verdad externa |
| Que con las versiones de `requirements.txt` salen las mismas cifras en GitHub | Que estén **todas** las cifras: si se pierde la salida de una celda, compara menos y no avisa |

> **Decisión:** el tablero **recalcula** todo con los archivos del equipo (importa `wc_predictor.py`, lee los dos CSV y
> reproduce las funciones del notebook); los textos toman las cifras con `{python}` en línea; y una tabla compara 17 cifras
> con las salidas guardadas del notebook.
> **Alternativas:** (a) **copiar las cifras a mano**: así era la primera versión de la tabla de verificación, y se
> desactualizó; (b) ejecutar el notebook desde el tablero; (c) importar el notebook como si fuera un módulo; (d) que el
> notebook exporte sus resultados a un archivo que el tablero lea; (e) pasar las funciones del notebook a un módulo
> importable; (f) pruebas automáticas que **detengan** la publicación si algo no coincide. **Ninguna de (b) a (f) se
> probó**; el detalle de por qué no está en [13a](13a_codigo_datos_dashboard.md) y en D40 a D42.
> **Por qué ésta:** una sola fuente de verdad (los archivos del equipo), render rápido (≈ 12 s) y el riesgo de duplicar
> funciones lo controla la verificación, que compara contra lo que el notebook realmente reportó.
> **Evidencia en el proyecto:** 17 de 17 ✓ en el sitio publicado; y los cambios del equipo de Código (K, k, limpieza nueva,
> M3 en la prueba) llegaron al tablero sin copiar ningún número.
> **Si preguntan:** "El tablero no tiene resultados copiados: importa `wc_predictor.py`, lee los dos CSV del equipo y repite
> las funciones del notebook; y para comprobar que la copia es fiel, compara 17 cifras contra las que el notebook dejó
> guardadas. Coinciden las 17, también en el servidor de GitHub; cuando Daniel agregó M3, la tabla lo incorporó sola."

(Son las decisiones [D40](19_decisiones_y_alternativas.md#d40-recalcular-todo-desde-los-archivos-del-equipo--razonada),
[D41](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada) y
[D42](19_decisiones_y_alternativas.md#d42-cifras-del-texto-con-python-y-frases-condicionales--razonada) del capítulo 19.)

## 13.7 `graficas.py`: la capa visual con Plotly

**El código, en breve** (función por función: [capítulo 13b](13b_codigo_graficas.md)):

- `graficas.py` (374 líneas) convierte las tablas de `datos_dashboard.py` en **figuras de Plotly con un mismo estilo**.
  Tiene tres partes: las constantes (paleta de cinco colores con significado, fuente, configuración de plotly.js y una
  plantilla), **una función por gráfica** (11) y `tabla_html`, que arma las tablas HTML.
- `mostrar(fig)` es la función que dibuja cada gráfica y fija tres cosas: **sin barra de herramientas**; **sin zoom ni
  arrastre** (antes, un arrastre accidental ampliaba la gráfica sin forma visible de regresar; los tooltips siguen
  funcionando); y **sin leyendas de Plotly**: la leyenda va en HTML en el subtítulo de la tarjeta, porque Plotly encimaba
  las suyas cuando la página estaba oculta al dibujarse.
- Ninguna figura define su título: el título que dice el hallazgo vive en la tarjeta de `index.qmd`.
- **En R** sería `ggplot2` con un `theme_*()` propio y `scale_*_manual()` con la paleta, más `plotly::ggplotly()` para
  los tooltips ([`equivalencias_R/04_grafica_resumen.R`](equivalencias_R/04_grafica_resumen.R) construye la gráfica
  principal; más en [13.11](#1311-el-mismo-diseño-en-r-flexdashboard-y-shiny)).

## 13.8 El simulador "Explora un partido" (Observable JS)

**El código, en breve** (los datos: [13a.6](13a_codigo_datos_dashboard.md); el JavaScript: [capítulo 13c](13c_codigo_index_quarto.md)):

- En Python, `datos_simulador()` calcula con M0 **las 380 combinaciones** local–visitante de los 20 equipos de 2026/27:
  λ de cada equipo, P(1X2), marcador más probable y la matriz de marcadores de 0 a 5.
- `ojs_define(sim=...)` pasa esos datos al navegador y **Observable JS** arma los selectores y las gráficas. Un `viewof`
  crea un control **reactivo**: al cambiarlo, todo lo que depende de él se recalcula solo, como en una hoja de cálculo. El
  visitante excluye al local, así que no se puede elegir el mismo equipo dos veces.
- **¿Por qué no Shiny?** Porque Shiny calcula en un servidor que debe estar encendido. Aquí todo se precalcula y el
  navegador sólo filtra y dibuja, así que funciona en GitHub Pages, que sólo sirve archivos estáticos.
- El texto bajo la tabla del simulador **cambia con k**: si k = 0 explica que los promedios son de la temporada en curso;
  si no, que mezclan la temporada anterior con peso n/(n+k).
- **En R**, lo mismo con Shiny requiere servidor; sin servidor se podría usar `crosstalk` con widgets HTML
  ([13.11](#1311-el-mismo-diseño-en-r-flexdashboard-y-shiny)).

## 13.9 `estilos.scss` y `redibujar.html`

**El código, en breve** ([capítulo 13c](13c_codigo_index_quarto.md)):

- `estilos.scss` (970 líneas) es **Sass** (CSS con variables). La primera parte (`scss:defaults`) cambia **variables** del
  tema Bootstrap `cosmo`: color primario, fuente, fondo, enlaces y radio de los bordes (las de la barra de navegación no se
  ven, porque las reglas las anulan). La segunda (`scss:rules`) agrega las **reglas**, por secciones: diseño, barra de
  navegación, pestañas, tarjetas, *value boxes*, tablas, diagrama de flujo, simulador, leyendas HTML y diseño adaptable.
  El estilo general es de **vidrio**: tarjetas translúcidas, con desenfoque del fondo y sombra. En Flexdashboard se haría
  con `theme:` y un archivo `css:`, o con `bslib::bs_theme()`.
- `redibujar.html` (46 líneas) es un JavaScript que resuelve un problema real: Plotly mide los textos al dibujar, y las
  páginas que no están a la vista están **ocultas** y miden cero, así que al mostrarlas las etiquetas no aparecían o se
  encimaban. El script **vuelve a dibujar** cada gráfica cuando su contenedor pasa de oculto a visible
  (`ResizeObserver`), al cargar y al cambiar de pestaña (`shown.bs.tab`).
- Busca Plotly en `window.Plotly` **y** en `window._Plotly`: como la página incluye `require.js`, Plotly queda en
  `window._Plotly`; la primera versión sólo miraba `window.Plotly` y no funcionaba. Es la decisión
  [D46](19_decisiones_y_alternativas.md#d46-redibujarhtml-para-las-gráficas-en-pestañas-ocultas--razonada).

## 13.10 Problemas encontrados y cómo se resolvieron

| Síntoma | Causa | Solución |
|---|---|---|
| Quarto no ejecutaba Python (`No module named 'yaml'`) | Faltaba PyYAML en Python 3.10 | Se instaló (y `jupyter` y `pyyaml` están en `requirements.txt`) |
| Una gráfica aparecía dos veces | Quarto imprime cualquier expresión suelta que devuelva la figura (p. ej. `fig.update_layout(...)`) | Las figuras se construyen dentro de funciones, y `mostrar` no devuelve nada |
| El simulador no cargaba datos | `ojs_define()` no funciona en chunks con `include: false` | Chunk con `echo: false` |
| Diagrama Mermaid vacío | Mermaid no dibuja en páginas ocultas | Diagrama hecho con HTML y CSS |
| Barra de desplazamiento dentro de las tarjetas | El subtítulo y la gráfica se repartían la altura | Regla CSS: el texto que acompaña a una gráfica no crece |
| Página en blanco al abrir `#qué-ocurre` | Identificadores con acento | Identificadores ASCII explícitos (`{#que-ocurre}`) |
| Tras la barra lateral, filas convertidas en columnas | Quarto invierte la orientación después de un `.sidebar` | `## Column` con `### Row` adentro |
| Leyendas encimadas y etiquetas ausentes | Medición de textos en páginas ocultas y redibujado que no encontraba Plotly | Leyendas en HTML + redibujado con `ResizeObserver` y `window._Plotly` |
| Gráfica "vacía" con ejes en −0.001 | Zoom accidental sin botón para regresar | Zoom desactivado |
| Plotly ignoraba el formato `"+.3f"` | Plotly lo convierte internamente en `"~+.3f"`, que no es válido (según se observó al construir el tablero) | Formatos sin `+` en Plotly: las etiquetas con signo se escriben con Python (`f"{v:+.3f}"`) |
| La tabla de verificación quedó vieja al cambiar K y k | Sus 15 cifras de referencia estaban copiadas a mano (con K = 30) | Se leen las **salidas guardadas** del notebook en cada render ([D41](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)): 16 cifras el 30-sep y 17 cuando el notebook agregó M3 a la prueba |
| La verificación no encuentra contra qué comparar | El notebook se guardó sin salidas | Marca ✗ y el texto dice "HAY DIFERENCIAS: revisar antes de publicar" (se publica de todos modos); se corrige volviendo a guardar el notebook con sus salidas |
| La copia local de `index.qmd` quedó atrasada | Los compañeros editaron en GitHub (editor web) mientras se trabajaba en la computadora | `git fetch`, `git stash`, `git merge --ff-only` y `git stash pop` antes de subir ([14.12](14_publicacion_en_github.md#1412-la-versión-final-30-sep-2026)) |
| Ejecuciones "canceladas" en la pestaña Actions | `concurrency` sólo conserva en espera el *push* más reciente | No es un error: la última ejecución publica ([14.9](14_publicacion_en_github.md#149-paso-7-github-actions-construye-y-publica-el-tablero) y [14.12](14_publicacion_en_github.md#1412-la-versión-final-30-sep-2026)) |

**Cosas que se ven raras y no se corrigieron** (por ejemplo, la barra "6+" de la gráfica de Poisson no se dibuja, dos
gráficas no tienen ejes cuadrados y el tooltip de las temporadas repite el año): [13b.3](13b_codigo_graficas.md). Los
datos escritos a mano que habría que revisar si cambian los datos: [13.6.1](#1361-qué-sale-del-código-y-qué-sigue-escrito-a-mano).

## 13.11 El mismo diseño en R: flexdashboard y Shiny

El diplomado trabaja en R, así que conviene saber cómo sería **el mismo tablero** con las herramientas de R. Todo lo
de esta sección es **ilustrativo**: código razonado, no ejecutado. Cada pieza, línea por línea, con su equivalente, está en
[13a](13a_codigo_datos_dashboard.md), [13b](13b_codigo_graficas.md) y [13c](13c_codigo_index_quarto.md).

| Pieza del proyecto (Python) | Equivalente en R |
|---|---|
| `datos_dashboard.py`: funciones que devuelven tablas, `preparar_todo()` y `@lru_cache` | `datos_dashboard.R`: funciones que devuelven *tibbles*; `preparar_todo()` devuelve una `list`; `memoise::memoise()` como caché (o calcular una vez en el chunk `setup`) |
| `wc_predictor.py` (Elo, promedios de temporada, forma reciente) | `source("wc_predictor.R")`; ya hay versiones en R en `equivalencias_R/` ([`01_elo.R`](equivalencias_R/01_elo.R), [`05_variables_previas.R`](equivalencias_R/05_variables_previas.R)) |
| Regresión de Poisson con `statsmodels` (GLM) | `glm(goles ~ ..., family = poisson)` ([`02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R)) |
| `graficas.py`: `go.Figure`, plantilla y paleta | `graficas.R`: `ggplot2` + un `theme_*()` propio + `scale_*_manual()`; `plotly::ggplotly()` o `plot_ly()` para los tooltips |
| `index.qmd` con `format: dashboard` y `jupyter: python3` | `dashboard.Rmd` con `flexdashboard::flex_dashboard` (o el mismo `.qmd` con chunks `{r}`) |
| Chunks `{python}` y código en línea `` `{python} expr` `` | Chunks `{r}` y `` `r expr` `` |
| `ojs_define()` + chunks `{ojs}` (el simulador) | Shiny (con servidor) o `crosstalk` con widgets HTML |
| `estilos.scss` | `theme:` y un archivo `css:`, o `bslib::bs_theme()` |
| `requirements.txt` (versiones fijas) | `renv.lock` (paquete `renv`) |
| Workflow con `setup-python` y `quarto render` | `r-lib/actions/setup-r`, `setup-pandoc`, `install.packages(...)` y `rmarkdown::render()` ([14.9](14_publicacion_en_github.md#149-paso-7-github-actions-construye-y-publica-el-tablero)) |

### La sintaxis: Quarto dashboard frente a Flexdashboard

| Quarto dashboard | Flexdashboard | Qué es |
|---|---|---|
| `# Resumen {#resumen}` | `Resumen` + línea de `=====` | Página (pestaña de la barra superior) |
| `## Row {height=185px}` | `Row {data-height=185}` + `-----` | Fila |
| `### Column {width=62%}` | `Column {data-width=620}` | Columna dentro de la fila |
| `::: {.card title="Título"}` … `:::` | `### Título` | Tarjeta (caja) |
| `## Row {.tabset}` | `Row {.tabset}` | Pestañas: cada tarjeta es una pestaña |
| `## {.sidebar}` | `Sidebar {.sidebar}` | Barra lateral |
| `::: {.valuebox icon="…" color="…"}` | `valueBox(valor, caption, icon)` | Indicador (*value box*) |

El encabezado del tablero y su equivalente en Flexdashboard (R Markdown):

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
lang: es
format:
  dashboard:
    orientation: rows          # el nivel 2 (##) son filas
    scrolling: true            # la página puede crecer hacia abajo
    theme: [cosmo, estilos.scss]
    include-after-body: redibujar.html
jupyter: python3               # ejecutar los chunks con Python
---
```

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
output:
  flexdashboard::flex_dashboard:
    orientation: rows
    vertical_layout: scroll    # ≈ scrolling: true
    theme: cosmo               # (ilustrativo; el SCSS propio pasaría a css: o a bslib)
---
```

Un indicador y una gráfica en Flexdashboard (el equivalente de un *value box* y de una tarjeta con `gr.mostrar(...)`):

````markdown
```{r setup, include=FALSE}
source("datos_dashboard.R"); source("graficas.R")
d <- preparar_todo()            # calcula TODO una sola vez (≈ preparar_todo() en Python)
```

### Partidos acertados por el modelo

```{r}
valueBox(scales::percent(acc("Prueba", "M0_Base"), 0.1),
         caption = "Partidos acertados por el modelo", icon = "fa-check-circle")
```

### El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo

```{r}
mostrar(mejora_sobre_ingenua(d$metricas))     # ggplot2 + ggplotly()
```
````

El código en línea sería `` `r scales::percent(acc("Prueba", "M0_Base"), 0.1)` ``, y la frase condicional
"es decir, sin mezcla" se escribiría con `` `r if (k_shrinkage == 0) ", es decir, sin mezcla"` ``.

### Shiny, y por qué no se usó

El simulador, hecho con Shiny, sería algo así:

```r
selectInput("local", "Equipo local", choices = equipos, selected = "Arsenal")
selectInput("visita", "Equipo visitante", choices = equipos, selected = "Man City")
partido <- reactive(subset(sim, local == input$local & visita == input$visita))
output$probabilidades <- renderText({ ... })      # se recalcula en el servidor
```

Requiere `runtime: shiny` (o una app de Shiny) y **un servidor encendido** (shinyapps.io o Posit Connect). El tablero se
publica en GitHub Pages, que sólo sirve archivos estáticos; por eso el simulador se precalculó y se resolvió en el
navegador con Observable JS ([13.8](#138-el-simulador-explora-un-partido-observable-js)). El tutorial de Flexdashboard lo dice:
"interactividad del navegador no es lo mismo que reactividad de R". Sin servidor, en R se podría usar `crosstalk`
(filtros y selección entre widgets HTML, pero sin recalcular el modelo) o, de forma experimental, `shinylive` (Shiny que
corre en el navegador con WebAssembly). **Ninguna se probó.**

