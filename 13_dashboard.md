# 13. El dashboard: diseño y código

[← Resultados](12_resultados.md) · [Índice](README.md) · [Siguiente: publicación en GitHub →](14_publicacion_en_github.md)

**URL:** https://pitirringo.github.io/futbol-apuestas/

## 13.1 Qué debía lograr

Las instrucciones piden "una visualización publicada y accesible mediante URL" que permita
entender, como mínimo: **¿qué ocurre?, ¿qué patrones o relaciones encontraron?, ¿qué aporta el
modelo? y ¿cuál es la conclusión principal?** Y aclaran que "no se evaluará la herramienta
utilizada, sino la capacidad de la visualización para comunicar los resultados".

**Decisión de estructura:** una página por pregunta, en el orden de una historia.

| Página | Papel en la historia (storytelling) | Pregunta que responde |
|---|---|---|
| **Resumen** | Conclusión primero: "lectura en 20 segundos" | ¿Cuál es la conclusión principal? |
| **¿Qué ocurre?** | Planteamiento: el fenómeno y por qué es difícil predecirlo | ¿Qué ocurre? |
| **Patrones** | Desarrollo: la evidencia que justifica el modelo | ¿Qué patrones o relaciones hay? |
| **El modelo** | Conflicto y resolución: el modelo contra el mercado | ¿Qué aporta el modelo? |
| **Explora un partido** | Exploración libre (simulador) | — |
| **Datos y método** | Respaldo: datos, limpieza, variables, evaluación, limitaciones, reproducibilidad | — |

## 13.2 La herramienta: Quarto (formato *dashboard*) + Python

| Opción | Por qué sí / por qué no |
|---|---|
| **Quarto + Python** ✅ | El análisis del equipo está en Python: el tablero **importa el mismo código** y recalcula todo, así que sus cifras coinciden con las del notebook por construcción. Usa los mismos conceptos que Flexdashboard. Quarto se vio en la clase 8 |
| Flexdashboard (R) | Es la herramienta del tema 2 del módulo, pero habría obligado a reescribir el modelo en R o a pasar resultados de un lenguaje a otro (riesgo de que las cifras no coincidan) |
| Shiny | Necesita un servidor encendido (shinyapps.io); la interactividad que queríamos funciona en el navegador |
| Blogdown / sitio web | Sirve para varias historias; aquí hay una sola historia con evidencia densa |

**Quarto dashboards es el sucesor de Flexdashboard** (lo hace el mismo grupo, Posit), con la misma
lógica: páginas, filas, columnas, tarjetas, *value boxes*, pestañas.

## 13.3 Principios de diseño aplicados (material del módulo)

| Principio del módulo | Cómo se aplicó |
|---|---|
| Entender el contexto y la audiencia | Profesores (conocen LogLoss) y compañeros: dos lenguajes a la vez, LogLoss para unos y "aciertos" o "84 %" para todos |
| Contar una historia (inicio, conflicto, resolución) | Orden de páginas: Resumen → ¿Qué ocurre? → Patrones → El modelo |
| "Lectura en 20 segundos" (ejemplo de vuelos) | Tarjeta con 4 conclusiones en la portada |
| Títulos que comunican hallazgos | "La ventaja de jugar en casa es persistente… salvo sin público", no "Resultados por temporada" |
| Pocos indicadores (máximo 3 por página) | 3 *value boxes* en Resumen y 3 en ¿Qué ocurre? |
| Jerarquía: gráfica principal ≈ 2/3 del ancho (650/350) | Columnas de 62 % / 38 % y 64 % / 36 % |
| Pestañas para información de segundo nivel | Tablas y gráficas secundarias en `.tabset` |
| El color se reserva para lo importante | Azul = modelo, naranja = mercado, verde = local, violeta = visitante, **gris = todo lo demás** |
| Barras desde cero; sin pasteles ni 3D; etiquetas directas | Todas las barras parten de 0; etiquetas al final de las barras y de las líneas |
| La precisión sigue a la decisión | LogLoss con 3 decimales (las diferencias están en la tercera cifra); porcentajes con 1 |
| Accesibilidad | Paleta validada para daltonismo (el gris del empate junto a un aqua falló con deuteranopía y se cambió el local a verde); cada gráfica tiene su tabla |

## 13.4 Los archivos del tablero

```text
Dashboard-o-pagina/
├── _quarto.yml          proyecto Quarto: qué renderizar y dónde (salida en _site/)
├── index.qmd            el tablero: páginas, textos, orden y dónde va cada gráfica
├── datos_dashboard.py   "backend": calcula todas las cifras con el código del equipo
├── graficas.py          "capa visual": paleta, tema y una función por gráfica
├── estilos.scss         tema visual (sobre el tema cosmo)
├── redibujar.html       JavaScript que redibuja las gráficas al mostrarse cada página
└── requirements.txt     paquetes de Python con versiones fijas
```

**Separación de responsabilidades:** números (`datos_dashboard.py`), gráficas (`graficas.py`) y
narrativa (`index.qmd`). Si cambia un dato, no hay que tocar las gráficas; si cambia un color, no
hay que tocar los datos.

## 13.5 `index.qmd`: la sintaxis, comparada con Flexdashboard

### Encabezado YAML

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
format:
  dashboard:
    orientation: rows          # el nivel 2 (##) son filas
    scrolling: true            # la página puede crecer hacia abajo
    theme: [cosmo, estilos.scss]
    include-after-body: redibujar.html
    nav-buttons:
      - icon: github
        href: https://github.com/pitirringo/futbol-apuestas
jupyter: python3               # ejecutar los chunks con Python
---
```

**Equivalente en Flexdashboard (R Markdown):**

```yaml
---
title: "Premier League: estadística vs. mercado de apuestas"
output:
  flexdashboard::flex_dashboard:
    orientation: rows
    vertical_layout: scroll    # ≈ scrolling: true
    theme: cosmo
    source_code: embed
---
```

### Estructura: páginas, filas, columnas y tarjetas

| Quarto dashboard | Flexdashboard | Qué es |
|---|---|---|
| `# Resumen {#resumen}` | `Resumen` + línea de `=====` | Página (pestaña de la barra superior) |
| `## Row {height=540px}` | `Row {data-height=540}` + `-----` | Fila |
| `### Column {width=62%}` | `Column {data-width=620}` | Columna dentro de la fila |
| `::: {.card title="Título"}` … `:::` | `### Título` | Tarjeta (caja) |
| `## Row {.tabset}` | `Row {.tabset}` | Pestañas: cada tarjeta es una pestaña |
| `## {.sidebar}` | `Sidebar {.sidebar}` | Barra lateral |

`{#resumen}` le da a la página un identificador sin acentos: así el enlace
`…/futbol-apuestas/#que-ocurre` abre directamente esa página.

### El chunk de preparación

```python
#| include: false
import datos_dashboard as dd
import graficas as gr
d = dd.preparar_todo()           # calcula TODO una sola vez
```

`#| include: false` ejecuta el código pero no muestra nada (en R Markdown:
```` ```{r setup, include=FALSE} ````).

### *Value boxes* (indicadores)

```markdown
::: {.valuebox icon="check2-circle" color="#eef5fd"}
Partidos acertados por el modelo

`{python} pct(acc('Prueba', 'M0_Base'))`

Mercado: `{python} pct(acc('Prueba', 'Mercado_apertura'))` · …
:::
```

- Primera línea: título; segunda: el valor grande; tercera: texto de apoyo.
- `` `{python} expresión` `` es **código en línea**: el número se calcula al generar el tablero, no
  se escribe a mano. Ninguna cifra del tablero está escrita a mano.
- `icon` usa los íconos de Bootstrap; `color` es el tinte de fondo (azul claro = indicadores del
  modelo, naranja claro = mercado, verde claro = localía, gris = contexto).

**En Flexdashboard:**

```r
### Partidos acertados por el modelo
valueBox(scales::percent(aciertos_m0, 0.1), caption = "Partidos acertados por el modelo",
         icon = "fa-check-circle")
```

y el código en línea sería `` `r scales::percent(aciertos_m0)` ``.

### Gráficas dentro de tarjetas

```markdown
::: {.card title="El modelo recupera la mayor parte de la ventaja del mercado, pero no lo supera"}
<p class="subtitulo">Cuánto reduce cada predictor el LogLoss…</p>

```{python}
gr.mostrar(gr.mejora_sobre_ingenua(met))
```
:::
```

En Flexdashboard sería un `### Título` seguido de un chunk que imprime un `ggplotly(...)`.

## 13.6 `datos_dashboard.py`: el backend

**Objetivo:** que todas las cifras del tablero salgan del **mismo código y los mismos datos** que el
notebook del equipo.

- Importa `wc_predictor.py` desde `../Codigo/proyecto_mod_8` (la ruta se puede cambiar con la
  variable de entorno `RUTA_CODIGO`). Lo importa desde su carpeta y en silencio, por el efecto
  secundario que tiene al importarse ([cap. 10](10_codigo_wc_predictor.md)).
- Copia **con la misma lógica y los mismos nombres** las funciones del notebook (`preparar_X`,
  `entrenar_modelo`, `probabilidades_1x2`, …), porque viven dentro del notebook y no se pueden
  importar.
- Agrega los análisis complementarios: exploratorio, aciertos, bootstrap, calibración,
  descomposición de la brecha, efectos estandarizados, sensibilidad sin público, simulador y
  auditoría de datos.
- `tabla_verificacion()` compara **15 cifras** del tablero contra las publicadas por el notebook y
  el reporte técnico. En la pestaña *Reproducibilidad*, todas salen ✓, **también cuando el tablero
  se construye en los servidores de GitHub**.
- `@lru_cache` es **memorización**: la primera llamada calcula y las siguientes devuelven el
  resultado guardado. En R existe `memoise::memoise()`, o simplemente se calcula una vez en el chunk
  de preparación.

| Función | Devuelve |
|---|---|
| `cargar_historico()` / `cargar_base_modelacion()` | Los dos CSV del equipo |
| `resumen_temporadas()`, `resultado_del_favorito()`, `resultado_por_elo()` | Análisis exploratorio |
| `modelos_entrenados()` | M0–M4 ajustados en entrenamiento |
| `probabilidades_por_conjunto()` | Probabilidades de todos los predictores en validación y prueba |
| `tabla_metricas()`, `tabla_bootstrap()`, `delta_contra_m0()` | Métricas e incertidumbre |
| `brecha_por_resultado()`, `calibracion_modelo_vs_mercado()`, `efectos_estandarizados()` | Diagnóstico |
| `sensibilidad_sin_publico()` | M0 reentrenado sin los partidos a puerta cerrada |
| `datos_simulador()` | Las 380 combinaciones de equipos de 2026/27 con M0 |
| `auditoria_datos()`, `tabla_verificacion()` | Calidad de datos y verificación |
| `preparar_todo()` | Todo lo anterior en un diccionario |

## 13.7 `graficas.py`: la capa visual con Plotly

**Anatomía de una gráfica en Plotly (Python):**

```python
import plotly.graph_objects as go

fig = go.Figure()                                           # lienzo vacío
fig.add_bar(y=nombres, x=valores, orientation="h",          # barras horizontales
            marker=dict(color=colores, cornerradius=4),
            text=[f"{v:.3f}" for v in valores], textposition="outside",   # etiqueta al final
            hovertemplate="<b>%{y}</b><br>Mejora: %{x:.3f}<extra></extra>")  # tooltip
fig.update_layout(barmode="group", margin=dict(l=8, r=48, t=8, b=8))
fig.update_xaxes(rangemode="tozero", tickformat=".2f")     # eje desde cero
fig.add_annotation(x=..., y=..., text="…", showarrow=True) # anotación con flecha
```

**Equivalente en R** (ver [`equivalencias_R/04_grafica_resumen.R`](equivalencias_R/04_grafica_resumen.R),
que construye la gráfica principal y la guarda como imagen):

```r
ggplot(datos, aes(x = mejora, y = predictor, fill = predictor, alpha = periodo, group = periodo)) +
  geom_col(position = position_dodge(0.75)) +                       # ≈ add_bar(barmode="group")
  geom_text(aes(label = sprintf("%.3f", mejora)), hjust = -0.15,
            position = position_dodge(0.75)) +                       # ≈ textposition="outside"
  scale_fill_manual(values = colores) +                              # colores por entidad
  theme_minimal()                                                    # ≈ la plantilla PLANTILLA
plotly::ggplotly(grafica)                                            # ≈ interactividad de Plotly
```

| Plotly (Python) | R |
|---|---|
| `go.Figure()` + `add_bar` / `add_scatter` | `ggplot() + geom_col()` / `geom_line()` / `geom_point()`, o `plot_ly() |> add_bars()` |
| `update_layout(...)` / `update_xaxes(...)` | `labs()`, `theme()`, `scale_x_continuous()` |
| `hovertemplate` | `ggplotly(tooltip = ...)` o `text = ~...` en `plot_ly` |
| `add_annotation()` | `annotate("text", ...)` |
| `make_subplots(rows=1, cols=2)` | `facet_wrap()` o `patchwork` |
| Plantilla `PLANTILLA` (fuente, rejilla, colores) | un `theme_*()` propio |

**`mostrar(fig)`**, la función que muestra cada gráfica, fija tres cosas:
1. **Sin barra de herramientas** (`displayModeBar: False`).
2. **Sin zoom ni arrastre** (`dragmode=False`, ejes con `fixedrange=True`). Antes, un arrastre
   accidental ampliaba la gráfica sin forma visible de regresar; es lo que pasó con la gráfica de
   "pesas". Los tooltips siguen funcionando.
3. **Sin leyendas de Plotly:** la leyenda va en HTML en el subtítulo de cada tarjeta, porque Plotly
   encimaba sus leyendas cuando la página estaba oculta al dibujarse.

## 13.8 El simulador "Explora un partido" (Observable JS)

**Cómo funciona:**
1. En Python (`datos_simulador()`) se calculan **las 380 combinaciones** local–visitante de los 20
   equipos de 2026/27 con M0: λ, P(1X2), marcador más probable y la matriz de marcadores de 0 a 5.
2. `ojs_define(sim=...)` pasa esos datos del lado de Python al del navegador (JavaScript).
3. En el navegador, **Observable JS** (OJS) arma los selectores y las gráficas:

```js
viewof local = Inputs.select(sim.equipos, {label: "Equipo local", value: "Arsenal"})
viewof visita = Inputs.select(sim.equipos.filter(e => e !== local), {label: "Equipo visitante"})
partido = sim.partidos.find(p => p.local === local && p.visita === visita) ?? sim.partidos[0]
Plot.plot({ marks: [Plot.cell(celdas, {x: "gv", y: "gl", fill: "p"}), Plot.text(...)] })
```

- `viewof` crea un control cuyo valor es "reactivo": al cambiarlo, **todo lo que depende de él se
  recalcula solo** (como en una hoja de cálculo).
- El visitante excluye al local (`filter`), así que no se puede elegir el mismo equipo dos veces.
- `?? sim.partidos[0]` es una protección: si por algo no encuentra la combinación, muestra la
  primera en vez de romperse.

**¿Por qué no Shiny?** Porque Shiny calcula en un servidor que debe estar encendido. Aquí todo se
precalcula y el navegador solo filtra y dibuja: por eso funciona en GitHub Pages, que solo sirve
archivos estáticos. El tutorial de Flexdashboard lo dice: "interactividad del navegador no es lo
mismo que reactividad de R".

**En R**, lo mismo con Shiny sería:

```r
selectInput("local", "Equipo local", choices = equipos, selected = "Arsenal")
output$probabilidades <- renderText({ ... })      # se recalcula en el servidor
```

(requiere `runtime: shiny` y un servidor). Sin servidor, en R se podría usar `crosstalk` con
widgets HTML.

## 13.9 `estilos.scss` y `redibujar.html`

**`estilos.scss`:** Sass (CSS con variables). La primera parte cambia **variables** del tema
Bootstrap (`$primary`, fuente, fondo); la segunda agrega **reglas**: tarjetas sin sombra, tintes
de los *value boxes*, estilos de tablas, del simulador, del diagrama de flujo y de las leyendas.
En Flexdashboard se haría con `theme:` y un archivo `css:`, o con `bslib::bs_theme()`.

**`redibujar.html`:** un pequeño JavaScript que resuelve un problema real:
- Plotly mide los textos (etiquetas, anotaciones) al dibujar. Las páginas del tablero que no están
  a la vista están **ocultas** y miden cero, así que al mostrarlas las etiquetas no aparecían o se
  encimaban.
- La solución es **volver a dibujar** cada gráfica cuando su contenedor pasa de oculto a visible
  (`ResizeObserver`), al cargar y al cambiar de pestaña.
- La primera versión no funcionaba porque, como la página incluye `require.js`, Plotly queda en
  `window._Plotly` y no en `window.Plotly`; la versión final busca ambos.

## 13.10 Problemas encontrados y cómo se resolvieron

| Síntoma | Causa | Solución |
|---|---|---|
| Quarto no ejecutaba Python (`No module named 'yaml'`) | Faltaba PyYAML en Python 3.10 | Se instaló (y está en `requirements.txt`) |
| Una gráfica aparecía dos veces | Quarto imprime cualquier expresión suelta que devuelva la figura (p. ej. `fig.update_layout(...)`) | Las figuras se construyen dentro de funciones |
| El simulador no cargaba datos | `ojs_define()` no funciona en chunks con `include: false` | Chunk con `echo: false` |
| Diagrama Mermaid vacío | Mermaid no dibuja en páginas ocultas | Diagrama hecho con HTML y CSS |
| Barra de desplazamiento dentro de las tarjetas | El subtítulo y la gráfica se repartían la altura | Regla CSS: el texto que acompaña a una gráfica no crece |
| Página en blanco al abrir `#qué-ocurre` | Identificadores con acento | Identificadores ASCII explícitos |
| Tras la barra lateral, filas convertidas en columnas | Quarto invierte la orientación después de un `.sidebar` | `## Column` con `### Row` adentro |
| Leyendas encimadas y etiquetas ausentes | Medición de textos en páginas ocultas y redibujado que no encontraba Plotly | Leyendas en HTML + redibujado con `ResizeObserver` y `window._Plotly` |
| Gráfica "vacía" con ejes en −0.001 | Zoom accidental sin botón para regresar | Zoom desactivado |
| Plotly ignoraba el formato `"+.3f"` | Plotly lo convierte internamente en `"~+.3f"`, que no es válido | Formatos sin `+` |
