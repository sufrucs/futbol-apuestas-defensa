# 19. Decisiones y alternativas

[← Hallazgos y pendientes](18_hallazgos_y_pendientes.md) · [Índice](README.md) · [Siguiente: el reporte entregado →](20_el_reporte_entregado.md)

Este capítulo es el **registro central de las decisiones del proyecto**: datos, limpieza, variables,
modelo, calibración, evaluación, tablero y publicación. Para cada una dice qué se hizo, qué otras
opciones había, por qué la elegida fue razonable **para este proyecto** y qué cifra la respalda. Los
demás capítulos explican cada tema a fondo; aquí está la justificación lista para defenderla.

Las cifras corresponden a la versión entregada (commit `e3bd43f`, 30-sep-2026) y se revisaron el
2-oct-2026 contra las salidas guardadas de `Analisis.ipynb`, el tablero, el reporte y el código.

## Cómo usar este capítulo

- **Para estudiar:** lee el índice y después el bloque de tu tema. Cada decisión enlaza al capítulo
  donde se explica en detalle.
- **Para la exposición:** la pregunta típica es "¿por qué X y no Y?". Busca X en el índice. La línea
  **Si preguntan** de cada ficha es una respuesta de 15 a 20 segundos para decir en voz alta.
- **Regla de honestidad:** distingue siempre lo que **probamos** de lo que **razonamos**. Nunca digas
  "lo comparamos" de algo que no se comparó. Es mejor "no lo probamos; lo descartamos porque…".

### Leyenda

| Marca | Qué significa | Cómo decirlo |
|---|---|---|
| **Probada** | En el proyecto se ejecutaron la opción elegida y al menos una alternativa, y se compararon sus resultados (en el notebook de limpieza, en `Analisis.ipynb` o en el tablero). Dentro de la ficha se dice cuáles alternativas se probaron y cuáles no | "Lo comparamos y…" |
| **Razonada** | Ninguna alternativa se ejecutó: se descartaron con argumentos (datos disponibles, tamaño de muestra, interpretabilidad, objetivo del curso, literatura) | "No lo probamos; lo descartamos porque…" |
| *Comprobación de la guía* | Un cálculo hecho **después de la entrega**, para esta guía, con el código y los datos del proyecto. **No está en el notebook, el tablero ni el reporte.** Sirve para saber si una conclusión depende de una decisión | "Después verificamos que…" (sólo si lo preguntan, y aclarando que es posterior) |

Las alternativas **probadas de verdad** son pocas y conviene saberlas de memoria:

1. Las **35 combinaciones de K y k** de la calibración (`Analisis.ipynb` §5).
2. Las **cinco especificaciones M0–M4** (§6 y §9).
3. Las referencias **ingenua** (Poisson sin variables) y **uniforme** (azar, 1/3 por resultado).
4. El **mercado de apertura** y, en el tablero, el **de cierre**.
5. La **sensibilidad sin público** (tablero: M0 reentrenado sin los partidos a puerta cerrada).
6. Dos comprobaciones de la limpieza: leer todos los renglones (la primera versión perdía 90 partidos)
   y el formato de las fechas.

Todo lo demás es **razonado**.

### Formato de cada ficha

> **Decisión:** qué se hizo.
>
> **Alternativas:** cada una con lo que tenía a favor y en contra, y si se probó.
>
> **Por qué ésta:** razones concretas para este proyecto.
>
> **Evidencia en el proyecto:** la cifra o el resultado que la respalda (y, si existe, la comprobación de la guía).
>
> **Si preguntan:** una frase lista para decir en voz alta.

## Índice de decisiones

| # | Bloque | Decisión (en una línea) | Tipo | Detalle en |
|---|---|---|---|---|
| [D1](#d1-modelar-los-goles-de-cada-equipo-y-derivar-el-1x2--razonada) | Planteamiento | Modelar los goles de cada equipo y derivar el 1X2 | Razonada | [cap. 6](06_poisson_y_regresion.md), [cap. 7](07_de_goles_a_probabilidades.md) |
| [D2](#d2-el-mercado-es-la-vara-de-comparación-no-una-variable--razonada) | Planteamiento | El mercado es la vara de comparación, no una variable | Razonada | [cap. 8](08_cuotas_y_mercado.md) |
| [D3](#d3-sólo-la-premier-league--razonada) | Planteamiento | Sólo la Premier League | Razonada | [cap. 2](02_contexto_y_datos.md) |
| [D4](#d4-dos-formulaciones-de-la-pregunta-reporte-y-tablero--razonada) | Planteamiento | Dos formulaciones de la pregunta (reporte y tablero) | Razonada | [cap. 20](20_el_reporte_entregado.md) |
| [D5](#d5-football-datacouk-como-única-fuente--razonada) | Datos | Football-Data.co.uk como única fuente | Razonada | [cap. 2](02_contexto_y_datos.md) |
| [D6](#d6-elo-con-todo-el-histórico-desde-200102--razonada) | Datos | Elo con todo el histórico desde 2001/02 | Razonada | [cap. 4](04_elo.md) |
| [D7](#d7-modelar-desde-agosto-de-2019--razonada) | Datos | Modelar desde agosto de 2019 | Razonada | [cap. 2](02_contexto_y_datos.md), [cap. 9](09_evaluacion_y_validacion.md) |
| [D8](#d8-no-borrar-partidos-por-faltar-cuotas-o-xg--razonada) | Datos | No borrar partidos por faltar cuotas o xG | Razonada | [cap. 3](03_limpieza_de_datos.md) |
| [D9](#d9-no-usar-goles-esperados-xg--razonada) | Datos | No usar goles esperados (xG) | Razonada | [cap. 2](02_contexto_y_datos.md), [cap. 15](15_limitaciones_y_extensiones.md) |
| [D10](#d10-23-columnas-comunes--11-complementarias--razonada) | Limpieza | 23 columnas comunes + 11 complementarias | Razonada | [cap. 3](03_limpieza_de_datos.md) |
| [D11](#d11-leer-todos-los-renglones-de-cada-archivo--probada) | Limpieza | Leer todos los renglones (sin `on_bad_lines="skip"`) | **Probada** | [cap. 3](03_limpieza_de_datos.md) |
| [D12](#d12-fechas-con-formatmixed-y-dayfirsttrue--probada) | Limpieza | Fechas con `format="mixed"` y `dayfirst=True` | **Probada** | [cap. 3](03_limpieza_de_datos.md) |
| [D13](#d13-conservar-el-partido-con-más-tiros-a-puerta-que-tiros--razonada) | Limpieza | Conservar el partido con más tiros a puerta que tiros | Razonada | [cap. 3](03_limpieza_de_datos.md) |
| [D14](#d14-excluir-los-4-partidos-sin-historial-de-tiros-en-m0m4--razonada) | Limpieza | Excluir los 4 partidos sin historial de tiros, en M0–M4 | Razonada | [cap. 3](03_limpieza_de_datos.md), [cap. 11](11_codigo_analisis_notebook.md) |
| [D15](#d15-elo-como-medida-de-fuerza-relativa--razonada) | Variables | Elo como medida de fuerza relativa | Razonada | [cap. 4](04_elo.md) |
| [D16](#d16-k--15-en-el-elo--probada) | Variables | K = 15 en el Elo | **Probada** | [cap. 4](04_elo.md), [cap. 11](11_codigo_analisis_notebook.md) |
| [D17](#d17-escala-400-y-rating-inicial-1500-sin-calibrar--razonada) | Variables | Escala 400 y rating inicial 1500, sin calibrar | Razonada | [cap. 4](04_elo.md) |
| [D18](#d18-elo-sin-localía-sin-margen-de-victoria-y-sin-regresión-a-la-media--razonada) | Variables | Elo sin localía, sin margen de victoria y sin regresión a la media | Razonada | [cap. 4](04_elo.md) |
| [D19](#d19-la-diferencia-de-elo-entra-dividida-entre-400--razonada) | Variables | La diferencia de Elo entra dividida entre 400 | Razonada | [cap. 6](06_poisson_y_regresion.md), [cap. 11](11_codigo_analisis_notebook.md) |
| [D20](#d20-goles-de-la-temporada-con-shrinkage-y-k--0--probada) | Variables | Goles de la temporada con *shrinkage* y k = 0 | **Probada** | [cap. 5](05_promedios_ajustados_y_forma.md) |
| [D21](#d21-forma-reciente-10-partidos-decaimiento-085-y-cruza-temporadas--razonada) | Variables | Forma reciente: 10 partidos, decaimiento 0.85, cruza temporadas | Razonada | [cap. 5](05_promedios_ajustados_y_forma.md) |
| [D22](#d22-ataque-propio--defensa-del-rival-sin-parámetros-por-equipo--razonada) | Variables | Ataque propio + defensa del rival, sin parámetros por equipo | Razonada | [cap. 6](06_poisson_y_regresion.md) |
| [D23](#d23-variables-estrictamente-previas-construidas-por-día--razonada) | Variables | Variables estrictamente previas, construidas por día | Razonada | [cap. 9](09_evaluacion_y_validacion.md), [cap. 11](11_codigo_analisis_notebook.md) |
| [D24](#d24-glm-de-poisson--razonada) | Modelo | GLM de Poisson | Razonada | [cap. 6](06_poisson_y_regresion.md) |
| [D25](#d25-dos-ecuaciones-separadas-local-y-visitante--razonada) | Modelo | Dos ecuaciones separadas (local y visitante) | Razonada | [cap. 6](06_poisson_y_regresion.md) |
| [D26](#d26-independencia-condicional-y-skellam-exacta--razonada) | Modelo | Independencia condicional y Skellam exacta | Razonada | [cap. 7](07_de_goles_a_probabilidades.md) |
| [D27](#d27-cinco-especificaciones-anidadas-m0m4--probada) | Modelo | Cinco especificaciones anidadas M0–M4 | **Probada** | [cap. 6](06_poisson_y_regresion.md), [cap. 12](12_resultados.md) |
| [D28](#d28-m0-como-modelo-principal--probada) | Modelo | M0 como modelo principal | **Probada** | [cap. 12](12_resultados.md) |
| [D29](#d29-validación-temporal-con-ventana-creciente--razonada) | Calibración | Validación temporal con ventana creciente (3 pliegues) | Razonada | [cap. 9](09_evaluacion_y_validacion.md), [cap. 11](11_codigo_analisis_notebook.md) |
| [D30](#d30-rejilla-de-35-combinaciones-sólo-con-m0-y-logloss-ponderado--razonada) | Calibración | Rejilla de 35 combinaciones, sólo con M0, LogLoss ponderado | Razonada | [cap. 11](11_codigo_analisis_notebook.md) |
| [D31](#d31-rejilla-comentada-en-el-notebook-entregado--razonada) | Calibración | Rejilla comentada en el notebook entregado | Razonada | [cap. 11](11_codigo_analisis_notebook.md), [cap. 14](14_publicacion_en_github.md) |
| [D32](#d32-partición-temporal-1897--380--419--razonada) | Evaluación | Partición temporal 1,897 / 380 / 419 | Razonada | [cap. 9](09_evaluacion_y_validacion.md) |
| [D33](#d33-logloss-como-métrica-principal-y-mae-como-complemento--razonada) | Evaluación | LogLoss como métrica principal y MAE como complemento | Razonada | [cap. 9](09_evaluacion_y_validacion.md) |
| [D34](#d34-referencias-sin-información-azar-y-referencia-ingenua--probada) | Evaluación | Referencias sin información: azar y referencia ingenua | **Probada** | [cap. 9](09_evaluacion_y_validacion.md) |
| [D35](#d35-mercado-cuotas-promedio-de-apertura-con-normalización-proporcional--probada) | Evaluación | Mercado: cuotas promedio de apertura, normalización proporcional | **Probada** | [cap. 8](08_cuotas_y_mercado.md) |
| [D36](#d36-bootstrap-pareado-por-partidos--razonada) | Evaluación | Bootstrap pareado por partidos | Razonada | [cap. 9](09_evaluacion_y_validacion.md) |
| [D37](#d37-parte-de-la-ventaja-del-mercado-80--para-comunicar--razonada) | Evaluación | "Parte de la ventaja del mercado" (80 %) para comunicar | Razonada | [cap. 12](12_resultados.md), [cap. 13](13_dashboard.md) |
| [D38](#d38-sensibilidad-sin-público--probada) | Evaluación | Sensibilidad sin público | **Probada** | [cap. 12](12_resultados.md), [cap. 13](13_dashboard.md) |
| [D39](#d39-quarto-formato-dashboard--python--razonada) | Tablero | Quarto (formato *dashboard*) + Python | Razonada | [cap. 13](13_dashboard.md) |
| [D40](#d40-recalcular-todo-desde-los-archivos-del-equipo--razonada) | Tablero | Recalcular todo desde los archivos del equipo | Razonada | [cap. 13a](13a_codigo_datos_dashboard.md) |
| [D41](#d41-verificación-automática-contra-las-salidas-del-notebook--razonada) | Tablero | Verificación automática contra las salidas del notebook | Razonada | [cap. 13a](13a_codigo_datos_dashboard.md) |
| [D42](#d42-cifras-del-texto-con-python-y-frases-condicionales--razonada) | Tablero | Cifras del texto con `{python}` y frases condicionales | Razonada | [cap. 13c](13c_codigo_index_quarto.md) |
| [D43](#d43-plotly-con-plantilla-única-y-paleta-con-significado--razonada) | Tablero | Plotly con plantilla única y paleta con significado | Razonada | [cap. 13b](13b_codigo_graficas.md) |
| [D44](#d44-simulador-en-observable-js-con-los-380-cruces-precalculados--razonada) | Tablero | Simulador en Observable JS con los 380 cruces precalculados | Razonada | [cap. 13c](13c_codigo_index_quarto.md) |
| [D45](#d45-una-historia-en-seis-páginas-con-títulos-que-dicen-la-conclusión--razonada) | Tablero | Una historia en seis páginas, con títulos que dicen la conclusión | Razonada | [cap. 13](13_dashboard.md) |
| [D46](#d46-redibujarhtml-para-las-gráficas-en-pestañas-ocultas--razonada) | Tablero | `redibujar.html` para las gráficas en pestañas ocultas | Razonada | [cap. 13b](13b_codigo_graficas.md), [cap. 13c](13c_codigo_index_quarto.md) |
| [D47](#d47-github-pages--github-actions--razonada) | Publicación | GitHub Pages + GitHub Actions | Razonada | [cap. 14](14_publicacion_en_github.md) |
| [D48](#d48-versiones-fijas-y-huellas-sha-256--razonada) | Publicación | Versiones fijas y huellas SHA-256 | Razonada | [cap. 14](14_publicacion_en_github.md) |
| [D49](#d49-premier_training_datacsv-como-caché--razonada) | Publicación | `premier_training_data.csv` como caché | Razonada | [cap. 11](11_codigo_analisis_notebook.md), [cap. 14](14_publicacion_en_github.md) |
| [D50](#d50-repositorios-separados-e-historial-limpio--razonada) | Publicación | Repositorios separados e historial limpio | Razonada | [cap. 14](14_publicacion_en_github.md) |

**Resumen:** 9 decisiones probadas (D11, D12, D16, D20, D27, D28, D34, D35, D38) y 41 razonadas.

---

## 19.1 Planteamiento

### D1. Modelar los goles de cada equipo y derivar el 1X2 · Razonada

Detalle: [cap. 6](06_poisson_y_regresion.md) y [cap. 7](07_de_goles_a_probabilidades.md).

> **Decisión:** dos regresiones de Poisson estiman los goles esperados del local (λ<sub>H</sub>) y del
> visitante (λ<sub>A</sub>); de esos dos conteos salen P(local), P(empate) y P(visitante) con la
> distribución de Skellam, y también el marcador más probable.
>
> **Alternativas:**
> - **(a) Logit multinomial** sobre el resultado 1X2 (en R, `nnet::multinom()`). A favor: modela
>   directamente lo que se evalúa. En contra: tira la información del marcador (un 4–0 y un 1–0 cuentan
>   igual) y no da goles esperados ni marcadores. *No se probó.*
> - **(b) Logit o probit ordinal** (local > empate > visitante; en R, `MASS::polr()`). A favor: respeta el
>   orden de los resultados y es parsimonioso. En contra: también tira el marcador y supone que una sola
>   variable latente mueve los tres resultados. *No se probó.*
> - **(c) Un clasificador de aprendizaje automático** sobre el 1X2. Ver [D24](#d24-glm-de-poisson--razonada).
>
> **Por qué ésta:** (1) usa más información: cada partido aporta dos conteos, no sólo una etiqueta;
> (2) da todo lo que el proyecto necesitaba con un solo modelo: goles esperados (MAE), probabilidades 1X2
> (LogLoss) y marcadores (simulador y ejemplo Arsenal–City); (3) es interpretable: e<sup>β</sup> es un
> cambio multiplicativo en los goles esperados; (4) es el enfoque clásico para fútbol (Maher, 1982;
> Dixon y Coles, 1997), y el reporte lo respalda con Loukas et al. (2024). Su costo son dos supuestos:
> Poisson e independencia condicional ([D24](#d24-glm-de-poisson--razonada) y
> [D26](#d26-independencia-condicional-y-skellam-exacta--razonada)).
>
> **Evidencia en el proyecto:** los supuestos se sostienen razonablemente (dispersión de Pearson de M0:
> 0.996 local y 1.036 visitante) y el modelo supera con claridad a la referencia sin variables: M0 −
> ingenua en prueba = −0.0537 de LogLoss (IC 95 %: −0.0861 a −0.0217).
>
> **Si preguntan:** "Porque el marcador tiene más información que el resultado. Con dos conteos de goles
> obtenemos a la vez goles esperados, marcadores y probabilidades 1X2, con coeficientes interpretables;
> es el enfoque clásico desde Maher y Dixon–Coles. No lo comparamos contra un logit multinomial: sería
> una extensión natural."

### D2. El mercado es la vara de comparación, no una variable · Razonada

Detalle: [cap. 8](08_cuotas_y_mercado.md).

> **Decisión:** las cuotas promedio de apertura (`AvgH`, `AvgD`, `AvgA`) nunca entran a las regresiones.
> Se convierten en probabilidades (1/cuota, normalizadas) y se comparan con el modelo **sobre los mismos
> partidos** (`comparar_con_mercado`, notebook §8–§9).
>
> **Alternativas:**
> - **(a) Usar las cuotas como predictor** (la probabilidad implícita como variable). A favor: el
>   pronóstico quedaría casi tan bueno como el mercado. En contra: el ejercicio se vuelve circular; la
>   pregunta "¿cuánto anticipa la estadística frente al mercado?" ya no se podría contestar. *No se probó.*
> - **(b) Comparar sólo contra referencias sin información** (azar, ingenua). A favor: más simple. En
>   contra: ganarle al azar es fácil; no dice qué tan cerca se está del mejor pronóstico público.
> - **(c) Combinar modelo y mercado** (regresión del resultado contra ambas probabilidades) para ver si el
>   modelo aporta algo que el mercado no tiene. A favor: es la prueba más directa de esa pregunta. En
>   contra: es otro estudio; quedó como extensión ([cap. 15](15_limitaciones_y_extensiones.md)). *No se probó.*
>
> **Por qué ésta:** la pregunta del tablero es justamente estadística **contra** mercado; el mercado es
> el pronóstico público más exigente (incorpora alineaciones, lesiones y noticias que no están en los
> datos); y viene en los mismos archivos, sin unir fuentes. Usarlo como vara, y no como insumo, mantiene
> al modelo "sólo con estadística previa al partido".
>
> **Evidencia en el proyecto:** LogLoss del mercado 0.970552 (validación) y 1.020000 (prueba), contra
> 0.989547 y 1.033076 de M0. M0 recupera 82.5 % (validación) y 80.4 % (prueba) de la ventaja del mercado
> sobre la referencia ingenua. Brecha M0 − mercado con validación y prueba juntas (799 partidos):
> +0.0159 (IC 95 %: +0.0064 a +0.0255). La P(local) de M0 y la del mercado se correlacionan r = 0.94 en
> prueba.
>
> **Si preguntan:** "Si metiéramos las cuotas al modelo sólo estaríamos copiando al mercado y ya no
> podríamos responder la pregunta. Las usamos como la vara más exigente: con tres variables públicas, el
> modelo recupera cerca de 80 % de la ventaja del mercado sobre una referencia ingenua, pero no lo supera."

### D3. Sólo la Premier League · Razonada

Detalle: [cap. 2](02_contexto_y_datos.md).

> **Decisión:** una sola liga, la Premier League inglesa (código `E0` en Football-Data), de 2001/02 a
> septiembre de 2026.
>
> **Alternativas:**
> - **(a) Varias ligas** (Football-Data publica otras con el mismo formato). A favor: más partidos y
>   conclusiones más generales. En contra: los equipos de ligas distintas casi no se enfrentan, así que
>   habría un Elo por liga; más limpieza (nombres de equipos y columnas por liga); y más tiempo de
>   análisis en un módulo cuyo objetivo es **comunicar** resultados. *No se probó.*
> - **(b) Selecciones nacionales.** El módulo `wc_predictor.py` nació de un predictor del Mundial (de
>   ahí "wc"; la versión entregada ya no conserva esas funciones). En contra: pocos partidos por
>   selección, sin tiros ni cuotas históricas en una sola fuente. *No se probó.*
>
> **Por qué ésta:** datos homogéneos y completos (25 temporadas completas de 380 partidos), todos los
> equipos se enfrentan entre sí (el Elo es comparable) y una liga basta para responder la pregunta con
> rigor y dejar tiempo para el tablero.
>
> **Evidencia en el proyecto:** 9,540 partidos; 25 temporadas completas con 380 partidos cada una y 40
> de 2026/27. El reporte (§11.3) limita explícitamente sus conclusiones a la Premier League.
>
> **Si preguntan:** "Una liga con 25 temporadas completas y el mismo formato nos dio datos homogéneos y
> un Elo comparable, porque todos juegan contra todos. No afirmamos nada de otras ligas; extenderlo sería
> otro proyecto."

### D4. Dos formulaciones de la pregunta (reporte y tablero) · Razonada

Detalle: [cap. 20](20_el_reporte_entregado.md) (§20.2).

> **Decisión:** el reporte pregunta **en qué medida agregar variables mejora** el modelo (hipótesis:
> M1–M4 serán mejores que M0; respuesta: se respalda **parcialmente**). El tablero pregunta **qué tan bien
> anticipa la estadística frente al mercado** (hipótesis: informa, pero el mercado lo aprovecha mejor;
> respuesta: se confirma).
>
> **Alternativas:**
> - **(a) Una sola redacción en los dos documentos**, como recomendaba el [cap. 18](18_hallazgos_y_pendientes.md)
>   (C9). A favor: más fácil de defender. En contra: el reporte se centra en el diseño experimental M0–M4 y
>   el tablero en comunicar el resultado frente al mercado; forzar una sola formulación habría
>   empobrecido uno de los dos.
> - **(b) Una pregunta de rentabilidad** ("¿se puede ganar dinero apostando?"). En contra: fuera del
>   alcance (comisiones, límites, gestión de capital) y tema sensible. Ambos documentos aclaran que no
>   evalúan rentabilidad.
>
> **Por qué ésta:** no fue un diseño previo; el reporte y el tablero se escribieron en paralelo y al final
> quedaron dos formulaciones. Se mantuvieron porque **no se contradicen**: es el mismo experimento visto
> desde dos ángulos, con las mismas cifras, que salen del mismo notebook.
>
> **Evidencia en el proyecto:** las cifras coinciden en los dos documentos (por ejemplo, LogLoss de M0 en
> prueba 1.033076 y del mercado 1.020000); la tabla de verificación del tablero lo comprueba
> ([D41](#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)).
>
> **Si preguntan:** "Son dos preguntas complementarias sobre el mismo experimento. El reporte pregunta si
> agregar variables ayuda, y la respuesta es que sólo en parte. El tablero pregunta cuánto se acerca la
> estadística al mercado, y la respuesta es que recupera cerca de 80 % de su ventaja sin superarlo."

---

## 19.2 Datos

### D5. Football-Data.co.uk como única fuente · Razonada

Detalle: [cap. 2](02_contexto_y_datos.md).

> **Decisión:** los 26 archivos `E0.csv` de Football-Data.co.uk (uno por temporada, 2001/02 a 2026/27),
> descargados a mano del sitio, sin API.
>
> **Alternativas:**
> - **(a) Un servicio de resultados por API** (por ejemplo football-data.org, que es otro sitio).
>   A favor: descarga automatizable. En contra: está pensado para resultados y calendario; las cuotas
>   históricas habría que buscarlas en otra fuente y unirlas por nombre de equipo y fecha.
> - **(b) Proveedores de pago** (Opta, StatsBomb). A favor: datos de cada jugada y xG de calidad. En
>   contra: costo y licencias que impiden publicar los datos en un repositorio público.
> - **(c) FBref o Understat por *scraping*.** A favor: xG de varias temporadas. En contra: términos de
>   uso, código frágil (si cambia la página, se rompe) y, otra vez, unir dos fuentes.
> - **(d) Un conjunto de Kaggle.** A favor: listo para usar. En contra: lo arma un tercero, sin control
>   de versiones ni garantía de que se actualice (2026/27 está en curso).
>
> Ninguna se probó.
>
> **Por qué ésta:** es gratuita; tiene el mismo formato en todas las temporadas; trae **en el mismo
> archivo** resultados, estadísticas del partido (tiros, tiros a puerta) y cuotas de varias casas (Bet365
> y promedios de apertura y de cierre); cubre 25 temporadas completas; y es citable (referencia [4] del
> reporte). Una sola fuente evita el paso donde más errores aparecen: unir bases por nombre de equipo.
>
> **Evidencia en el proyecto:** 26 archivos → 9,540 partidos × 34 columnas. El tablero lo resume así:
> "Datos complementarios: ninguno externo; las cuotas vienen en los mismos archivos".
>
> **Si preguntan:** "Porque en un archivo por temporada trae resultados, tiros y cuotas de apertura y de
> cierre, gratis y con el mismo formato desde 2001. Con una sola fuente no tuvimos que unir bases por
> nombre de equipo, que es donde más errores aparecen."

### D6. Elo con todo el histórico desde 2001/02 · Razonada

Detalle: [cap. 4](04_elo.md).

> **Decisión:** el Elo se calcula desde el primer partido de 2001/02 (18-ago-2001), aunque la modelación
> empieza en agosto de 2019. Los 6,840 partidos anteriores sólo sirven para que el Elo llegue "maduro".
>
> **Alternativas:**
> - **(a) Empezar el Elo en 2019 con todos los equipos en 1500.** A favor: más simple. En contra: la
>   variable más importante del modelo valdría cero al principio y tardaría muchas jornadas en separar a
>   los equipos, porque con K = 15 un rating se mueve a lo más 15 puntos por partido. *No se probó en el
>   proyecto* (ver la comprobación abajo).
> - **(b) Tomar el Elo inicial de otra fuente** (un sitio de ratings). En contra: otra fuente y otra
>   metodología. *No se probó.*
> - **(c) Arrancar con un rating según la tabla de 2018/19.** En contra: una regla arbitraria más.
>   *No se probó.*
>
> **Por qué ésta:** los datos ya estaban en la base; 18 temporadas de calentamiento hacen que en 2019 el
> Elo ya distinga a los equipos fuertes de los débiles.
>
> **Evidencia en el proyecto:** el primer partido modelado (Liverpool–Norwich, 9-ago-2019) llega con
> Elo 1780.9 contra 1437.7: **343 puntos** de diferencia. *Comprobación de la guía:* si el Elo empezara
> en agosto de 2019, ese partido tendría diferencia 0, y la desviación estándar de la diferencia de Elo en
> 2019/20 sería 56.8 puntos en lugar de 161.7 (en todo el entrenamiento, 107.0 en lugar de 150.8).
>
> **Si preguntan:** "Porque el Elo necesita historia: con K = 15 se mueve a lo más 15 puntos por partido.
> Con 18 temporadas previas, el primer partido modelado ya tenía 343 puntos de diferencia entre Liverpool
> y Norwich; si hubiéramos empezado en 2019, todos tendrían 1500 y la variable más importante valdría cero."

### D7. Modelar desde agosto de 2019 · Razonada

Detalle: [cap. 2](02_contexto_y_datos.md) y [cap. 9](09_evaluacion_y_validacion.md).

> **Decisión:** la base de modelación empieza el 1-ago-2019 (`FECHA_INICIO`; primer partido el
> 9-ago-2019), porque desde 2019/20 la fuente trae las cuotas promedio de apertura y de cierre (`Avg*`,
> `AvgC*`). Quedan 2,700 partidos (2,696 tras la exclusión de [D14](#d14-excluir-los-4-partidos-sin-historial-de-tiros-en-m0m4--razonada)).
>
> **Alternativas:**
> - **(a) Modelar desde 2002/03 con Bet365 como mercado.** A favor: 9,160 partidos con cuotas, 3.4 veces
>   más que los 2,700 con cuotas promedio. En contra: una sola casa en lugar del promedio del mercado, y
>   sin cuotas de cierre en la base. *No se probó.*
> - **(b) Entrenar desde 2001 y comparar con el mercado sólo desde 2019.** A favor: más partidos para los
>   coeficientes. En contra: el modelo supone coeficientes estables (supuesto 6 del notebook) y estaría
>   aprendiendo de un fútbol de hace 20 años. *No se probó.*
>
> **Por qué ésta:** permite comparar modelo y mercado en exactamente los mismos partidos y con el
> consenso de las casas; deja cinco temporadas completas de entrenamiento (1,897 partidos) para estimar
> 4 coeficientes por ecuación; y la historia anterior no se pierde: alimenta el Elo ([D6](#d6-elo-con-todo-el-histórico-desde-200102--razonada)).
>
> **Evidencia en el proyecto:** cuotas `Avg` presentes en 2,700 partidos, desde el 9-ago-2019; Bet365 en
> 9,160, desde 2002/03. El tablero ("Limpieza y calidad", punto 5) da la misma razón.
>
> **Si preguntan:** "Porque en agosto de 2019 aparecen las cuotas promedio de apertura y de cierre, que
> son nuestra vara. Así comparamos modelo y mercado en los mismos partidos y aun quedan cinco temporadas
> para entrenar. La historia anterior no se tira: alimenta el Elo."

### D8. No borrar partidos por faltar cuotas o xG · Razonada

Detalle: [cap. 3](03_limpieza_de_datos.md).

> **Decisión:** las columnas complementarias quedan vacías (`NaN`) donde la fuente no las tiene; ningún
> partido se elimina por eso.
>
> **Alternativas:**
> - **(a) Eliminación por lista** (quitar toda fila con algún vacío; en R, `na.omit()`). En contra: sólo
>   quedarían los partidos con xG, y el Elo perdería toda su historia.
> - **(b) Quitar sólo los partidos sin cuotas promedio.** En contra: quedarían 2,700 y el Elo empezaría
>   en 2019 ([D6](#d6-elo-con-todo-el-histórico-desde-200102--razonada)).
> - **(c) Imputar cuotas o xG.** En contra: sería inventar información de mercado.
>
> Ninguna se probó.
>
> **Por qué ésta:** los vacíos no son errores; son columnas que la fuente fue agregando con los años.
> Cada etapa usa sólo lo que necesita: el Elo, los resultados (completos desde 2001); la comparación con
> el mercado, las cuotas `Avg` (desde 2019/20); el análisis histórico del favorito, Bet365 (desde 2002/03).
>
> **Evidencia en el proyecto:** vacíos por columna: Bet365 380 (toda 2001/02), `Avg` y `AvgC` 6,840,
> xG 9,500; las 23 columnas principales, 0. *Comprobación de la guía:* con eliminación por lista quedarían
> **40 partidos** (los de 2026/27, únicos con xG).
>
> **Si preguntan:** "Porque los vacíos son columnas que la fuente agregó con los años, no errores. Si
> borráramos toda fila con un vacío nos quedarían 40 partidos; dejándolos, el Elo usa los 9,540
> resultados y cada análisis usa sólo las columnas que necesita."

### D9. No usar goles esperados (xG) · Razonada

Detalle: [cap. 2](02_contexto_y_datos.md) y [cap. 15](15_limitaciones_y_extensiones.md).

> **Decisión:** `HxG` y `AxG` se conservan en la base, pero no entran a ningún modelo.
>
> **Alternativas:**
> - **(a) Usar los partidos que sí tienen xG.** En contra: son 40, todos de 2026/27; ningún partido de
>   entrenamiento lo tiene.
> - **(b) Traer xG de otra fuente** (Understat, FBref). En contra: *scraping*, términos de uso, unir fuentes
>   por nombre de equipo y otra metodología de xG. *No se probó.*
> - **(c) Usar lo más parecido que sí hay: tiros y tiros a puerta.** Esto **sí se hizo**: son M2 y M3
>   ([D27](#d27-cinco-especificaciones-anidadas-m0m4--probada)).
>
> **Por qué ésta:** cobertura insuficiente (40 de 9,540 partidos). Los tiros y tiros a puerta cubren la
> idea de "calidad de las ocasiones" con datos completos.
>
> **Evidencia en el proyecto:** auditoría del tablero: "Goles esperados (xG): sólo 2026/27. No se usan:
> cobertura insuficiente". Además, el sustituto disponible no ayudó: M3 (tiros a puerta) tuvo en prueba un
> LogLoss de 1.033868, apenas peor que M0 (1.033076).
>
> **Si preguntan:** "Sólo 40 partidos, todos de 2026/27, tienen xG en la fuente; ninguno de
> entrenamiento. Probamos lo más parecido que sí había, tiros y tiros a puerta, y no mejoraron a M0 en
> prueba. Con historia de xG sería la primera extensión."

---

## 19.3 Limpieza

### D10. 23 columnas comunes + 11 complementarias · Razonada

Detalle: [cap. 3](03_limpieza_de_datos.md).

> **Decisión:** primero se leen **sólo las cabeceras** de los 26 archivos (`nrows=0`) y se toma su
> intersección: 23 columnas presentes en todas las temporadas (`Div`, fecha, equipos, resultado final y al
> medio tiempo, árbitro, tiros, tiros a puerta, faltas, córners y tarjetas). Se agregan 11 complementarias
> de interés (`B365H/D/A`, `AvgH/D/A`, `AvgCH/CD/CA`, `HxG`, `AxG`): 34 columnas.
>
> **Alternativas:**
> - **(a) La unión de todas las columnas.** A favor: no se pierde nada. En contra: los archivos recientes
>   traen muchas columnas de otras casas y de otros mercados (más/menos goles, hándicap asiático) que
>   cambian de una temporada a otra; la base quedaría llena de vacíos y de columnas que nadie usa. No se
>   contó cuántas serían: los CSV crudos no están en el repositorio.
> - **(b) Sólo la intersección (23).** En contra: se perderían las cuotas, que son la vara de comparación.
> - **(c) Una lista de columnas escrita a mano.** En contra: frágil si un archivo cambia; la intersección
>   se calcula sola.
>
> Ninguna se probó.
>
> **Por qué ésta:** la intersección garantiza que las 23 variables principales estén completas en todo el
> histórico, y las 11 complementarias son exactamente las que el análisis usa (cuotas) o evaluó (xG).
>
> **Evidencia en el proyecto:** las 23 columnas comunes no tienen ningún vacío; las complementarias tienen
> 380, 6,840 y 9,500 vacíos según el grupo. `estructura_base()` del tablero lo recalcula: 34 columnas, 23
> comunes y 11 complementarias.
>
> **Si preguntan:** "Tomamos las 23 columnas que están en los 26 archivos, así que no tienen vacíos, y
> agregamos sólo las 11 de cuotas y xG que íbamos a usar o a evaluar. La unión habría traído muchas
> columnas de otras casas y mercados que cambian cada temporada y que no necesitábamos."

### D11. Leer todos los renglones de cada archivo · **Probada**

Detalle: [cap. 3](03_limpieza_de_datos.md).

> **Decisión:** cada archivo se lee con `pd.read_csv(ruta, encoding="utf-8-sig", encoding_errors="ignore",
> usecols=…)` **sin** `on_bad_lines="skip"` (en R, `readr::read_csv()` con `col_select`). Después sólo
> se elimina 1 fila completamente vacía (9,541 → 9,540).
>
> **Alternativas:**
> - **(a) `on_bad_lines="skip"`, la primera versión.** A favor: la lectura no se detiene ante renglones
>   con formato irregular. En contra: los descarta **en silencio**; perdía 90 partidos de 2003/04 y
>   2004/05, que quedaban con 335 de 380. ***Probada:*** fue la versión anterior y se comparó el conteo.
> - **(b) `on_bad_lines="warn"`.** Avisaría, pero igual descartaría los renglones. *No se probó.*
> - **(c) Reparar a mano los renglones irregulares.** *No hizo falta.*
>
> **Por qué ésta:** perder datos sin aviso es el peor tipo de error de limpieza; la versión final no
> pierde ningún partido.
>
> **Evidencia en el proyecto:** las 25 temporadas completas tienen 380 partidos cada una y 2026/27 lleva
> 40; la auditoría del tablero lo documenta ("una primera lectura descartaba 90 de 2003/04 y 2004/05").
> *Comprobación de la guía:* recuperar esos 90 partidos casi no movió el modelo. Con K = 30 y k = 10 (los
> valores de entonces), el LogLoss de M0 era 0.983690 / 1.030556 (validación / prueba) con la base vieja
> y es 0.983636 / 1.030640 con la base corregida: cambia en la quinta cifra, porque esos partidos sólo
> afectan al Elo de hace 20 años.
>
> **Si preguntan:** "La primera versión usaba `on_bad_lines="skip"`, que borra en silencio los renglones
> con formato irregular, y perdía 90 partidos de 2003/04 y 2004/05. La versión final lee todo: las 25
> temporadas completas tienen 380 partidos cada una."

### D12. Fechas con `format="mixed"` y `dayfirst=True` · **Probada**

Detalle: [cap. 3](03_limpieza_de_datos.md).

> **Decisión:** `pd.to_datetime(df["Date"], format="mixed", dayfirst=True)`, porque los archivos antiguos
> traen el año con dos dígitos (`dd/mm/aa`) y los recientes con cuatro (`dd/mm/aaaa`). Lo mismo hacen
> `load_history()` y `cargar_cuotas()`. En R, `lubridate::dmy()` lee ambos formatos con el día primero.
>
> **Alternativas:**
> - **(a) Sólo `dayfirst=True`.** ***Probada*** en el notebook de limpieza: **5,320 fechas** no se
>   interpretan.
> - **(b) Un formato explícito por archivo** (`%d/%m/%y` o `%d/%m/%Y`). A favor: más estricto. En contra:
>   hay que saber qué formato usa cada archivo y falla si uno cambia. *No se probó.*
> - **(c) Dejar que pandas adivine sin `dayfirst`.** En contra: riesgo de invertir día y mes (05/08 podría
>   leerse como 8 de mayo). *No se probó.*
>
> **Por qué ésta:** una sola llamada resuelve los dos formatos y fija el día primero en ambos.
>
> **Evidencia en el proyecto:** 5,320 fechas inválidas sin `format="mixed"` y 0 con él (celdas 8 y 19 de
> `Limpieza de datos.ipynb`). El tablero añade que se verificó que ninguna fecha invirtiera día y mes.
>
> **Si preguntan:** "Los archivos viejos traen el año con dos dígitos y los nuevos con cuatro. Con sólo
> `dayfirst` no se leían 5,320 fechas; con `format="mixed"` y `dayfirst=True` se leen todas, con el día
> primero."

### D13. Conservar el partido con más tiros a puerta que tiros · Razonada

Detalle: [cap. 3](03_limpieza_de_datos.md).

> **Decisión:** Newcastle–West Ham (15-ago-2021) registra para West Ham 9 tiros a puerta y 8 tiros. Se
> conserva sin corregir y se documenta (celdas 20 y 21 del notebook de limpieza).
>
> **Alternativas:**
> - **(a) Borrar el partido.** En contra: se pierde un resultado válido (2–4) que alimenta el Elo y los
>   promedios de goles de dos equipos.
> - **(b) Corregirlo** (por ejemplo, tiros = 9). En contra: es inventar un dato; no sabemos cuál de los dos
>   números está mal.
> - **(c) Dejar vacíos los tiros de ese partido.** En contra: crea un vacío en la forma reciente de dos
>   equipos durante sus diez partidos siguientes.
>
> Ninguna se probó.
>
> **Por qué ésta:** es una diferencia de 1 tiro en 1 de 9,540 partidos; borrar o inventar hace más daño
> que el error.
>
> **Evidencia en el proyecto:** es la única inconsistencia de contenido que encontraron las revisiones
> del notebook (0 duplicados, 0 equipos contra sí mismos, 0 negativos, 0 goles al medio tiempo mayores que
> los finales, 0 resultados contra marcador, 0 cuotas ≤ 1, 0 xG negativos). *Comprobación de la guía:* con 10 partidos y
> decaimiento 0.85, el partido más reciente pesa 18.7 %, así que en el peor caso el error mueve el promedio
> de tiros de West Ham **0.19 tiros** en un solo partido.
>
> **Si preguntan:** "Es un error de la fuente de un tiro en un solo partido. Borrarlo nos quitaba un
> resultado válido para el Elo, y corregirlo era inventar un dato. En el peor caso mueve el promedio de
> tiros de West Ham 0.19 tiros en un partido."

### D14. Excluir los 4 partidos sin historial de tiros, en M0–M4 · Razonada

Detalle: [cap. 3](03_limpieza_de_datos.md) y [cap. 11](11_codigo_analisis_notebook.md).

> **Decisión:** de los 2,700 partidos construidos desde agosto de 2019 se quitan 4: el debut de un equipo
> sin partidos previos en la base, con el que no se pueden calcular tiros recientes (Brentford vs
> Arsenal, 13-ago-2021; Nott'm Forest vs Newcastle, 6-ago-2022; Luton vs Brighton, 12-ago-2023; Coventry
> vs Arsenal, 21-ago-2026). Quedan 2,696, **la misma muestra para M0–M4** (`dropna(subset=COLUMNAS_TIROS)`;
> en R, `tidyr::drop_na()`).
>
> **Alternativas:**
> - **(a) Imputar los tiros** (promedio de la liga o de los ascendidos). A favor: conserva los 4. En
>   contra: inventa forma reciente; `recent_form()` ya rellena los goles con el promedio histórico de
>   goles por equipo (1.3623), pero deja los tiros vacíos. *No se probó.*
> - **(b) Quitarlos sólo de M1–M4**, porque M0 no usa tiros. A favor: M0 conserva 4 partidos. En contra:
>   M0 y M1–M4 se evaluarían en muestras distintas y las comparaciones dejarían de ser pareadas (mismos
>   partidos), que es lo que exigen las diferencias de LogLoss y el bootstrap. *No se probó en el proyecto.*
> - **(c) Usar partidos de segunda división** para su historial. En contra: no están en la base.
>
> **Por qué ésta:** son 4 de 2,700 (0.15 %), y una muestra común hace homogénea la comparación de los cinco
> modelos; es la razón que Daniel documentó en la nota de la celda 12.
>
> **Evidencia en el proyecto:** la celda 13 lista los 4 partidos. Tres están en entrenamiento y uno
> (Arsenal–Coventry) en prueba; por eso la prueba tiene 419 partidos y no 420. Detalle: en la calibración
> (§5) **no** se excluyen, porque su base no calcula tiros; por eso cada pliegue tiene 380 partidos.
> *Comprobación de la guía:* con los 2,700, los coeficientes de M0 casi no cambian (Elo/400: 0.6280 contra
> 0.6283 en el local) y el LogLoss de validación pasa de 0.989547 a 0.989645.
>
> **Si preguntan:** "Son 4 de 2,700 partidos: el debut de equipos sin partidos previos en la base, así que
> sus tiros recientes no existen. Imputarlos era inventar datos, y quitarlos sólo de M1–M4 rompía la
> comparación pareada. Preferimos la misma muestra para los cinco modelos."

---

## 19.4 Variables

### D15. Elo como medida de fuerza relativa · Razonada

Detalle: [cap. 4](04_elo.md) y [cap. 10](10_codigo_wc_predictor.md) (`expected_score`, `update_elo`,
`build_elo`).

> **Decisión:** cada equipo tiene un rating Elo (inicial 1500, K = 15, escala 400) que se actualiza con
> cada resultado: R' = R + K·(S − E), con E = 1/(1 + 10<sup>(R<sub>rival</sub> − R)/400</sup>). La
> regresión usa la **diferencia** de Elo previa al partido (local − visitante).
>
> **Alternativas:**
> - **(a) Puntos o posición en la tabla.** A favor: lo entiende cualquiera. En contra: no ajusta por la
>   fuerza de los rivales y se reinicia cada agosto (en la jornada 1 todos tienen 0 puntos).
> - **(b) Diferencia de goles acumulada.** En contra: los mismos dos problemas.
> - **(c) Valor de mercado de la plantilla.** En contra: otra fuente (y *scraping*); no viene en
>   Football-Data.
> - **(d) Otros ratings** (pi-ratings, índices de sitios especializados). En contra: más parámetros u otra
>   fuente y otra metodología.
>
> Ninguna se probó.
>
> **Por qué ésta:** se calcula sólo con los resultados que ya teníamos; se actualiza partido a partido;
> pondera por la fuerza del rival (ganarle al líder sube más que ganarle al último); no se reinicia entre
> temporadas; y es interpretable. Es el método de Elo (1978), y su uso para pronosticar fútbol está
> estudiado (Hvattum y Arntzen, 2010; referencia [1] del reporte).
>
> **Evidencia en el proyecto:** es la variable que más pesa: en M0, z = 9.99 (local) y −9.89 (visitante).
> Subir una desviación estándar la diferencia de Elo cambia los goles esperados del local +26.7 % (IC 95 %:
> +21.0 a +32.8) y los del visitante −22.8 % (−26.6 a −18.7). Por deciles de diferencia de Elo, la
> victoria local va de 12.6 % a 76.3 %.
>
> **Si preguntan:** "Porque resume la fuerza de cada equipo sólo con resultados, ajusta por la calidad
> del rival y no se reinicia cada temporada como la tabla. Es la variable que más pesa: subir una
> desviación estándar la diferencia de Elo aumenta 27 % los goles esperados del local."

### D16. K = 15 en el Elo · **Probada**

Detalle: [cap. 4](04_elo.md) y [cap. 11](11_codigo_analisis_notebook.md) (§5 del notebook).

> **Decisión:** `ELO_K = 15` en `wc_predictor.py`, elegido junto con k por validación temporal
> ([D29](#d29-validación-temporal-con-ventana-creciente--razonada)) entre K ∈ {15, 20, 25, 30, 35, 40, 45}.
>
> **Alternativas (probadas en la rejilla; LogLoss promedio de los tres pliegues):**
> - **K = 15, k = 0 (elegida):** 0.959558 (pliegues 0.960230 / 0.989315 / 0.929130).
> - **K = 20, k = 0:** 0.959589, prácticamente empatada (+0.000031).
> - **K = 30**, el valor que usaba el proyecto antes de calibrar: 0.961021 con k = 0, y 0.962178 con
>   k = 10 (la configuración anterior completa, +0.002620).
> - **K = 45, k = 0:** 0.964290, la peor con k = 0.
> - **K < 15:** *no se probó.*
>
> **Por qué ésta:** tiene el menor LogLoss promedio, y el patrón es claro: con k = 0, el LogLoss sube con K
> sin excepción (15 < 20 < 25 < … < 45). Un K chico hace al Elo más estable: reacciona menos a cada
> resultado y filtra el ruido de las rachas.
>
> **Evidencia en el proyecto y matices (para decirlos antes de que los pregunten):**
> 1. **Está en el borde de la rejilla.** El propio notebook advierte que, si el mejor valor queda en un
>    extremo, conviene ampliar el rango, y el tablero lo dice. Probar K < 15 es la extensión natural.
> 2. **Las diferencias son pequeñas.** Las 35 combinaciones caben en 0.0055 de LogLoss (0.959558 a 0.965084).
> 3. **No gana en las tres temporadas.** K = 15 es el mejor en 2021/22 y 2023/24, pero en 2022/23 ganó
>    K = 35 (0.981453 contra 0.989315).
> 4. *Comprobación de la guía (información posterior, no se usó para decidir):* con M0 en validación y
>    prueba, la configuración anterior (K = 30, k = 10) habría dado 0.983636 y 1.030640, **algo mejor**
>    que la elegida (0.989547 y 1.033076); K = 35 habría sido mejor en validación (0.980894) y peor en
>    prueba (1.035075). Ninguna configuración gana en los dos periodos, las diferencias son del tamaño del
>    ruido entre temporadas y **todas quedan lejos del mercado** (0.970552 y 1.020000). Elegir K mirando la
>    prueba sería hacer trampa; lo correcto es lo que se hizo, y reconocer que K importa poco.
>
> **Si preguntan:** "Probamos siete valores de K, de 15 a 45, con validación temporal en tres temporadas
> anteriores a la validación, y K = 15 dio el menor LogLoss. Quedó en el borde, así que probar valores
> menores es la extensión natural. Las diferencias entre valores de K son pequeñas y cambian según la
> temporada; la conclusión frente al mercado no depende de K."

### D17. Escala 400 y rating inicial 1500, sin calibrar · Razonada

Detalle: [cap. 4](04_elo.md).

> **Decisión:** `ELO_SCALE = 400` y `ELO_INIT = 1500` fijos: la convención del Elo del ajedrez (Elo, 1978).
>
> **Alternativas:**
> - **(a) Calibrar también la escala.** En contra: es redundante con K. Si se multiplican la escala y K
>   por el mismo número, todos los ratings (medidos desde 1500) se multiplican por ese número y las
>   probabilidades esperadas no cambian; como la regresión divide la diferencia entre la escala, recibe
>   exactamente el mismo valor. Calibrar K con la escala fija ya recorre todas las opciones.
> - **(b) Otro rating inicial.** En contra: el nivel absoluto no importa, porque al modelo sólo entra la
>   diferencia y cada actualización suma cero (lo que gana un equipo lo pierde el otro). Lo que sí
>   importa es con cuánto **entra un equipo nuevo** frente a los demás: eso es una limitación real de los
>   ascendidos ([cap. 15](15_limitaciones_y_extensiones.md)).
>
> Ninguna se probó.
>
> **Por qué ésta:** la escala y el valor inicial sólo fijan unidades; la convención hace comparables los
> números con la literatura (con 400 puntos de ventaja, la probabilidad esperada del favorito es
> 1/(1 + 10<sup>−1</sup>) = 0.909).
>
> **Evidencia en el proyecto:** *comprobación de la guía:* el promedio de los ratings finales de los 45
> equipos del histórico es exactamente 1500.0, como corresponde a un sistema de suma cero.
>
> **Si preguntan:** "La escala y el 1500 sólo fijan las unidades: si duplicáramos la escala y K a la vez,
> todos los ratings se duplicarían y los pronósticos serían idénticos. Por eso calibramos K y dejamos la
> convención de 400 y 1500."

### D18. Elo sin localía, sin margen de victoria y sin regresión a la media · Razonada

Detalle: [cap. 4](04_elo.md).

> **Decisión:** un Elo "simple": la expectativa E no suma ventaja al local, S vale 1, 0.5 o 0 sin
> importar el marcador, y los ratings no se acercan a 1500 al empezar cada temporada.
>
> **Alternativas:**
> - **(a) Ventaja de local dentro del Elo** (sumar H puntos al local al calcular E). A favor: el Elo
>   pronosticaría mejor por sí solo. En contra: un parámetro más que calibrar; en nuestro modelo la
>   localía ya la capturan las dos ecuaciones de Poisson ([D25](#d25-dos-ecuaciones-separadas-local-y-visitante--razonada)).
> - **(b) Margen de victoria** (que un 5–0 mueva más que un 1–0). A favor: usa más información. En contra:
>   otro parámetro; y la regresión ya recibe los goles a favor y en contra de la temporada.
> - **(c) Regresión parcial a la media entre temporadas.** A favor: reflejaría fichajes y cambios de
>   plantilla. En contra: otro parámetro; con K = 15 el rating ya es estable.
>
> Ninguna se probó.
>
> **Por qué ésta:** parsimonia: K es el único parámetro del Elo y sí se calibró. Lo que al Elo le falta lo
> cubre el modelo de goles: la localía, con dos ecuaciones; el margen, con los promedios de goles.
>
> **Evidencia en el proyecto:** la localía existe en los datos y equivale a unos 50 puntos de Elo (tablero:
> local y visitante tienen la misma probabilidad de ganar cuando el local es ≈ 50 puntos más débil).
> *Comprobación de la guía:* con dos equipos idénticos (Elo igual y 1.4365 goles a favor y en contra, el
> promedio de entrenamiento), M0 da λ = 1.486 al local y 1.248 al visitante, es decir, 42.7 % / 25.4 % /
> 31.9 %: la regresión ya absorbió la ventaja de jugar en casa.
>
> **Si preguntan:** "El Elo sólo mide fuerza relativa; la ventaja de jugar en casa la estima la regresión,
> porque hay una ecuación para el local y otra para el visitante. Con dos equipos idénticos el modelo ya da
> 43 % al local y 32 % al visitante. Meter la localía al Elo habría sido un parámetro más sin calibrar."

### D19. La diferencia de Elo entra dividida entre 400 · Razonada

Detalle: [cap. 6](06_poisson_y_regresion.md) y [cap. 11](11_codigo_analisis_notebook.md) (`preparar_X`).

> **Decisión:** `preparar_X()` hace `X["elo_diff"] = X["elo_diff"] / ESCALA_ELO` antes del GLM (en R,
> `glm(home_goals ~ I(elo_diff / 400) + …)`).
>
> **Alternativas:**
> - **(a) Puntos crudos.** El pronóstico sería idéntico; el coeficiente quedaría en 0.00157 por punto
>   (local) y −0.00171 (visitante), difícil de leer.
> - **(b) Estandarizar** (restar la media y dividir entre la desviación estándar, 150.8 puntos). El
>   coeficiente sería "por desviación estándar", pero dependería de la muestra de entrenamiento.
> - **(c) Usar la probabilidad Elo E en lugar de la diferencia.** Otra forma funcional; *no se probó.*
>
> **Por qué ésta:** multiplicar o dividir una variable por una constante no cambia el ajuste ni las
> predicciones del GLM, sólo la unidad del coeficiente; "por cada 400 puntos" es la unidad natural del
> Elo. Para comparar variables entre sí, el tablero sí usa el efecto de una desviación estándar.
>
> **Evidencia en el proyecto:** coeficiente 0.6283 por cada 400 puntos en la ecuación del local:
> e<sup>0.6283</sup> ≈ 1.87, es decir, 400 puntos más de diferencia multiplican por 1.87 los goles esperados
> del local (reporte, §7.1). Por una desviación estándar: +26.7 % (tablero).
>
> **Si preguntan:** "Dividir entre 400 no cambia el modelo, sólo la unidad del coeficiente: 0.628 por cada
> 400 puntos en lugar de 0.0016 por punto. Para comparar variables, el tablero usa el efecto de una
> desviación estándar."

### D20. Goles de la temporada con *shrinkage* y k = 0 · **Probada**

Detalle: [cap. 5](05_promedios_ajustados_y_forma.md) y [cap. 10](10_codigo_wc_predictor.md) (`season_stats`).

> **Decisión:** `season_stats()` combina el promedio de la temporada en curso con una referencia previa:
> x* = n/(n + k)·x<sub>actual</sub> + k/(n + k)·x<sub>previo</sub>, donde n son los partidos jugados en la
> temporada y la referencia es la temporada anterior del equipo (o el promedio de la liga, si no estuvo
> en Premier). Con el valor calibrado **k = 0** (`SHRINKAGE_K`): si n ≥ 1 se usa sólo la temporada en
> curso; si n = 0 (antes de su primer partido), la referencia previa.
>
> **Alternativas (probadas en la rejilla, con K = 15):** k = 5 (0.960369), k = 10 (0.961220; era el
> valor inicial), k = 15 (0.962085) y k = 20 (0.962794): el LogLoss sube con k. Para cada K de la rejilla
> gana k = 0, salvo con K = 45, donde k = 5 es apenas mejor (0.964021 contra 0.964290).
> **No se probaron:** promedios de varias temporadas, una ventana móvil de N partidos (es lo que hace la
> forma reciente, [D21](#d21-forma-reciente-10-partidos-decaimiento-085-y-cruza-temporadas--razonada)) ni
> un modelo bayesiano completo.
>
> **Por qué ésta:** la idea de no fiarse de pocos partidos es razonable (la fórmula es la media posterior
> de un modelo gamma-Poisson cuya "previa" vale k partidos), pero la validación dijo que, una vez que hay
> partidos de la temporada, mezclar no mejora: el Elo ya aporta la información de largo plazo. Se
> conservó la fórmula en el código porque k es un parámetro que se puede volver a calibrar.
>
> **Evidencia en el proyecto:** la rejilla. Consecuencia visible: al empezar la temporada los promedios
> varían mucho (tras 4 partidos de 2026/27, Arsenal 2.00 a favor y 0.25 en contra; Coventry y Tottenham,
> 0.00 a favor); el simulador lo advierte. En el primer partido de cada temporada (n = 0) da lo mismo k = 0
> que k = 10 (Liverpool–Norwich 2019: Liverpool 2.3421 / 0.5789; Norwich, ascendido, 1.4105 / 1.4105).
> *Comprobación de la guía:* en prueba, K = 15 con k = 10 habría dado 1.029922 (mejor que 1.033076), pero
> en validación 0.991201 (peor que 0.989547): otra vez, el efecto es pequeño y cambia con el periodo.
>
> **Si preguntan:** "La fórmula mezcla la temporada actual con la anterior con peso n/(n + k). Probamos k
> de 0 a 20 y el mejor fue k = 0: con partidos de la temporada, mezclar no mejoró, porque el Elo ya trae la
> historia del equipo. Antes del primer partido sí se usa la temporada anterior."

### D21. Forma reciente: 10 partidos, decaimiento 0.85 y cruza temporadas · Razonada

Detalle: [cap. 5](05_promedios_ajustados_y_forma.md) y [cap. 10](10_codigo_wc_predictor.md) (`recent_form`).

> **Decisión:** `recent_form(n=10, decay=0.85)`: promedio ponderado de los últimos 10 partidos del equipo
> en la base (de goles, tiros y tiros a puerta, a favor y en contra), con pesos 0.85<sup>m−1−i</sup>
> normalizados. Toma los 10 más recientes aunque sean de la temporada anterior. Lo usan M1–M4.
>
> **Alternativas:**
> - **(a) Otra ventana** (5 o 20 partidos) **u otro decaimiento** (0.7 o 0.95). *No se probaron.*
> - **(b) Media simple de los últimos N** (decaimiento 1). *No se probó.*
> - **(c) Sólo partidos de la temporada actual.** En contra: en agosto no habría datos.
>
> **Por qué ésta:** son valores razonables, **no optimizados**. Con 0.85 el partido más reciente pesa
> 18.7 % y el décimo 4.3 % (4.3 veces menos); la "vida media" es de 4.3 partidos. Cruzar temporadas evita
> el vacío de agosto. Se priorizó calibrar K y k porque afectan a las variables de M0, que está en los
> cinco modelos; la forma sólo entra en M1–M4.
>
> **Evidencia en el proyecto:** la forma aportó poco: M1 mejoró a M0 en validación por 0.0019 y empeoró en
> prueba por 0.0016; dentro de M4, sus cuatro coeficientes de forma no son significativos (p de 0.50 a
> 0.86). Limitación conocida: para un ascendido, los 10 partidos pueden ser de hace años (Norwich en 2019
> usaba partidos de 2016).
>
> **Si preguntan:** "Diez partidos con decaimiento 0.85 quiere decir que el más reciente pesa 4.3 veces
> más que el décimo. Son valores razonables que no optimizamos; como la forma reciente no mejoró a M0 en
> prueba, la prioridad fue calibrar K y k."

### D22. Ataque propio + defensa del rival, sin parámetros por equipo · Razonada

Detalle: [cap. 6](06_poisson_y_regresion.md).

> **Decisión:** en la ecuación del local entran los goles a favor del local y los goles en contra del
> visitante (`gf_home`, `ga_away`); en la del visitante, al revés (`gf_away`, `ga_home`). No hay un
> parámetro propio por equipo.
>
> **Alternativas:**
> - **(a) Modelo de Maher (1982) o de Dixon y Coles (1997):** un parámetro de ataque y uno de defensa por
>   equipo, más la localía. A favor: es el clásico de la literatura. En contra: con 26 equipos en
>   entrenamiento son unos 52 parámetros fijos, y los equipos que no estaban en entrenamiento no tendrían
>   parámetro (Ipswich en validación; Coventry, Hull, Ipswich y Sunderland en prueba); además, un
>   parámetro fijo no sigue la evolución de un equipo en cinco temporadas. *No se probó en el proyecto;
>   comprobación de la guía abajo.*
> - **(b) Promedios separados de local y de visitante por equipo.** En contra: la mitad de partidos por
>   promedio, más ruido (el notebook lo deja como supuesto: "no se estiman ataques/defensas separados por
>   condición de localía"). *No se probó.*
>
> **Por qué ésta:** las variables se recalculan antes de cada partido (se actualizan solas), sirven para
> cualquier equipo con historia, incluidos los ascendidos, y bastan 4 coeficientes por ecuación.
>
> **Evidencia en el proyecto:** las variables de M0 apenas se traslapan (VIF máximo 1.665) y los
> coeficientes son estables (z del Elo ≈ 10). *Comprobación de la guía* ([cap. 6](06_poisson_y_regresion.md)):
> un modelo con un ataque y una defensa por equipo, ajustado en el mismo entrenamiento, se ajusta mejor
> dentro de la muestra (LogLoss 0.966 contra 0.973 de M0) pero generaliza peor: 1.0547 contra 0.9895 en
> validación y 1.0566 contra 1.0331 en prueba. Es sobreajuste: muchos parámetros fijos que no siguen la
> evolución de los equipos.
>
> **Si preguntan:** "El modelo de Maher o de Dixon–Coles estima un ataque y una defensa por equipo: unos 50
> parámetros fijos, y los ascendidos que no estaban en entrenamiento, como Ipswich o Coventry, no tendrían
> parámetro. Nuestras variables se recalculan antes de cada partido para cualquier equipo, con 4
> coeficientes por ecuación. Lo comprobamos después: ese modelo se ajusta mejor al pasado, pero pronostica
> peor en validación y en prueba."

### D23. Variables estrictamente previas, construidas por día · Razonada

Detalle: [cap. 9](09_evaluacion_y_validacion.md) y [cap. 11](11_codigo_analisis_notebook.md) (§2).

> **Decisión:** las variables de un partido del día t se calculan sólo con partidos de fechas
> **anteriores** (`df_pre = historial[date < t]`); `crear_variables_partido()` se detiene con
> `ValueError` si recibe algo del mismo día o posterior. `construir_base_historica()` recorre el histórico
> por fechas: primero arma las variables de todos los partidos del día y al final actualiza el Elo. La
> misma función sirve para entrenar y para pronosticar un partido nuevo (`predecir_partido`).
>
> **Alternativas:**
> - **(a) Promedios de la temporada completa.** En contra: fuga de información; el modelo vería el futuro
>   y la validación saldría optimista.
> - **(b) Actualizar el Elo partido a partido dentro del día.** Da lo mismo en estos datos (ver abajo).
> - **(c) Filtrar con `<=`.** En contra: incluiría el propio partido.
>
> Ninguna se probó en el proyecto.
>
> **Por qué ésta:** es como se usaría el modelo en la realidad, y el control explícito impide errores.
>
> **Evidencia en el proyecto:** el control nunca se dispara en la construcción de la base. *Comprobación de
> la guía:* ningún equipo juega dos veces el mismo día, así que actualizar el Elo por día o partido a
> partido da exactamente las mismas variables (diferencia máxima 0.0). La regla "por día" es la forma
> segura de garantizarlo para cualquier dato futuro.
>
> **Si preguntan:** "Cada variable usa sólo partidos de días anteriores, y la función se detiene con error
> si recibe información del mismo día o posterior. Así el modelo nunca ve el resultado que intenta
> predecir, y la misma función sirve para entrenar y para pronosticar."

---

## 19.5 Modelo

### D24. GLM de Poisson · Razonada

Detalle: [cap. 6](06_poisson_y_regresion.md).

> **Decisión:** `sm.GLM(goles, X, family=sm.families.Poisson()).fit()`: enlace logarítmico,
> log λ = Xβ, estimado por máxima verosimilitud (en R, `glm(goles ~ …, family = poisson)`, que da los
> mismos coeficientes; ver `02_modelo_poisson.R` en [equivalencias en R](equivalencias_R/README.md)).
>
> **Alternativas:**
> - **(a) Binomial negativa** (en R, `MASS::glm.nb()`). A favor: admite varianza mayor que la media. En
>   contra: no hacía falta; la dispersión de Pearson de M0 es 0.996 y 1.036. *No se probó.*
> - **(b) Poisson con ceros inflados.** En contra: la dispersión ≈ 1 no lo sugiere (un exceso de ceros
>   dentro del modelo inflaría la varianza). *No se probó.*
> - **(c) Poisson bivariada** (Karlis y Ntzoufras, 2003) **o Dixon–Coles.** Atacan la dependencia entre los
>   goles; ver [D26](#d26-independencia-condicional-y-skellam-exacta--razonada). *No se probaron.*
> - **(d) Aprendizaje automático** (XGBoost, bosques aleatorios, redes neuronales). A favor: capturan
>   relaciones no lineales. En contra: con 1,897 partidos de entrenamiento el riesgo de sobreajuste es alto
>   y se pierde la interpretación (no hay e<sup>β</sup>). XGBoost está instalado en el Python del equipo,
>   pero *no se probó*.
>
> **Por qué ésta:** los goles son conteos; el enlace logarítmico garantiza λ > 0; los coeficientes se
> interpretan como cambios multiplicativos; es el estándar para goles de fútbol (Maher, 1982; Loukas et al.,
> 2024); y tiene equivalente directo en R. La propia evidencia del proyecto va contra más flexibilidad: M4,
> con 9 variables, no generalizó mejor que M0, con 3.
>
> **Evidencia en el proyecto:** dispersión de Pearson 0.996 / 1.036 (tablero). Un matiz que conviene
> entender: los goles **sin variables** sí tienen varianza mayor que la media (en entrenamiento, 1.81 contra
> 1.56 en el local y 1.54 contra 1.31 en el visitante) y algo más de ceros que una Poisson (23.3 % contra
> 21.5 % en el local, en las 25 temporadas completas). Eso es lo esperable al mezclar partidos de equipos muy
> distintos; una vez que el modelo distingue a los equipos, la dispersión que queda es ≈ 1.
>
> **Si preguntan:** "Porque los goles son conteos y la regresión de Poisson da coeficientes
> interpretables. Revisamos su supuesto clave: la dispersión de Pearson es 0.996 y 1.036, prácticamente 1,
> así que la binomial negativa no hacía falta. Aprendizaje automático no lo probamos: con 1,897 partidos, y
> viendo que 9 variables ya no generalizaban mejor que 3, no esperábamos ganancia."

### D25. Dos ecuaciones separadas (local y visitante) · Razonada

Detalle: [cap. 6](06_poisson_y_regresion.md).

> **Decisión:** `entrenar_modelo()` ajusta un GLM para los goles del local y otro, independiente, para los
> del visitante, cada uno con sus propios coeficientes.
>
> **Alternativas:**
> - **(a) Un solo modelo "apilado"**: cada partido aporta dos filas (los goles de cada equipo) y una
>   variable indica quién es local. A favor: la mitad de coeficientes. En contra: obliga a que cada variable
>   pese lo mismo de local y de visitante; sólo el indicador marca la diferencia. *No se probó.*
> - **(b) Modelar directamente la diferencia de goles.** En contra: se pierden los marcadores.
>   *No se probó.*
>
> **Por qué ésta:** deja que los datos digan si ser local cambia el efecto de cada variable, y la
> localía queda en los interceptos y en esas diferencias (por eso el Elo no la necesita,
> [D18](#d18-elo-sin-localía-sin-margen-de-victoria-y-sin-regresión-a-la-media--razonada)).
>
> **Evidencia en el proyecto:** los coeficientes de M0 difieren en magnitud: diferencia de Elo/400 0.6283
> (local) contra −0.6854 (visitante); goles a favor propios 0.1678 contra 0.1079; goles en contra del rival
> 0.0778 (p = 0.0498, en el límite) contra 0.0281 (p = 0.506, no significativo). *Comprobación de la guía*
> ([cap. 6](06_poisson_y_regresion.md)): esas diferencias **no son estadísticamente significativas**; frente
> a un modelo apilado con un indicador de localía, la prueba de razón de verosimilitudes da LR = 1.81 con 3
> grados de libertad, p = 0.61. Las dos versiones describen los datos igual de bien.
>
> **Si preguntan:** "Con dos ecuaciones, cada variable puede pesar distinto de local y de visitante. Lo
> comprobamos después: frente a un modelo con un solo indicador de localía, la diferencia no es
> significativa (p = 0.61), así que las dos versiones son equivalentes. Mantener dos ecuaciones es más
> flexible y se lee más fácil: una para los goles de cada equipo."

### D26. Independencia condicional y Skellam exacta · Razonada

Detalle: [cap. 7](07_de_goles_a_probabilidades.md).

> **Decisión:** dadas las variables, los goles del local y del visitante se suponen independientes. Así
> la diferencia de goles sigue una distribución de Skellam y `probabilidades_1x2()` calcula exactamente
> P(local) = `skellam.sf(0)`, P(empate) = `skellam.pmf(0)` y P(visitante) = `skellam.cdf(−1)`. El marcador
> más probable se busca en una matriz de 0 a 10 goles por equipo (`np.outer` de dos `poisson.pmf`; en R,
> `outer(dpois(0:10, lh), dpois(0:10, la))`).
>
> **Alternativas:**
> - **(a) Corrección de Dixon y Coles (1997):** un parámetro ρ que ajusta 0–0, 1–0, 0–1 y 1–1. A favor:
>   ataca la debilidad observada, los empates. En contra: ρ se estima junto con las dos ecuaciones por
>   máxima verosimilitud conjunta (ya no son dos GLM separados) y no viene en `statsmodels`. *No se probó.*
> - **(b) Poisson bivariada** (Karlis y Ntzoufras, 2003), con una covarianza entre los goles. En contra:
>   más compleja de estimar. *No se probó.*
> - **(c) Sumar la matriz truncada** en lugar de usar Skellam. Da prácticamente lo mismo (ver abajo).
> - **(d) Simular partidos (Monte Carlo).** En contra: agrega ruido aleatorio y es más lento.
>
> **Por qué ésta:** es la consecuencia directa de dos Poisson independientes; Skellam es exacta,
> instantánea y no trunca; el reporte (§5.2) y el notebook (§4) lo explican así.
>
> **Evidencia en el proyecto:** en prueba, M0 asigna a los empates 23.6 % en promedio, el mercado 24.5 %,
> y ocurrieron en 28.2 % de los partidos; los empates explican +0.0078 de la brecha M0 − mercado (+0.0159 en
> total). *Comprobación de la guía* ([cap. 7](07_de_goles_a_probabilidades.md)): eso no prueba que la
> independencia sea el problema. En entrenamiento M0 reproduce bien los empates (22.7 % contra 22.8 % reales)
> y el parámetro de Dixon–Coles estimado con las λ de M0 sale casi cero (ρ = −0.008, error estándar ≈ 0.03,
> p = 0.79); aplicarlo apenas mueve el LogLoss (1.0331 → 1.0326 en prueba). La prueba simplemente tuvo más
> empates de lo normal (28.2 %), algo que ningún modelo entrenado con el pasado anticipaba; el mercado
> tampoco (24.5 %).
> *Comprobación de la guía:* en Arsenal–City, la matriz 0–10 deja fuera una probabilidad de 8 × 10⁻⁷; en
> el peor partido de validación + prueba, 1.5 × 10⁻³. Con 10,000 simulaciones, P(local) tendría un error
> estándar de 0.005 (medio punto porcentual).
>
> **Si preguntan:** "Suponer independencia nos permite usar la distribución de Skellam, que da las tres
> probabilidades de forma exacta, sin truncar ni simular. En prueba hubo más empates (28.2 %) de los que dio
> el modelo (23.6 %) y también el mercado (24.5 %), pero en entrenamiento el modelo acierta la proporción de
> empates y la corrección de Dixon–Coles sale casi cero. Probarla de forma completa sigue siendo la
> extensión natural."

### D27. Cinco especificaciones anidadas M0–M4 · **Probada**

Detalle: [cap. 6](06_poisson_y_regresion.md) y [cap. 12](12_resultados.md).

> **Decisión:** `ESPECIFICACIONES` define M0 (diferencia de Elo + goles de la temporada: 3 variables por
> ecuación), M1 (+ forma reciente de goles: 5), M2 (+ tiros: 5), M3 (+ tiros a puerta: 5) y M4 (todo: 9).
> Todas se entrenan con los mismos 1,897 partidos y se evalúan en validación y en prueba.
>
> **Alternativas:**
> - **(a) Un solo modelo con todas las variables** (sólo M4). En contra: no permitiría saber qué bloque
>   aporta. *M4 sí se evaluó, como una de las cinco.*
> - **(b) Selección automática de variables** (*stepwise*, LASSO). En contra: menos interpretable por
>   bloques y fácil de sobreajustar. *No se probó.*
> - **(c) Todas las combinaciones de bloques** (2³ = 8). En contra: más modelos que comparar con sólo 380
>   partidos de validación. *No se probó.*
>
> **Por qué ésta:** cada bloque responde una pregunta concreta ("¿la forma reciente agrega algo a lo que ya
> dicen el Elo y los promedios?"). Es el diseño incremental de la hipótesis del reporte.
>
> **Evidencia en el proyecto (probada):**
>
> | LogLoss | M0 | M1 | M2 | M3 | M4 |
> |---|---|---|---|---|---|
> | Validación (380) | 0.989547 | 0.987603 | 0.980718 | 0.982319 | **0.978612** |
> | Prueba (419) | **1.033076** | 1.034699 | 1.037331 | 1.033868 | 1.036739 |
>
> En validación todos los bloques ayudan un poco (M4 es el mejor); en prueba ninguno supera a M0. Con el
> MAE de goles el orden cambia: en validación el menor es el de M0 (0.918332) y en prueba el de M3
> (0.894173).
>
> **Si preguntan:** "Para medir el aporte de cada tipo de información: partimos de M0 y agregamos un
> bloque a la vez —forma, tiros, tiros a puerta— y al final todos juntos. En validación los bloques
> ayudaron un poco; en prueba ninguno superó a M0 en LogLoss."

### D28. M0 como modelo principal · **Probada**

Detalle: [cap. 12](12_resultados.md) y [cap. 18](18_hallazgos_y_pendientes.md) (C6).

> **Decisión:** el tablero presenta a M0 como el modelo (portada y simulador: `MODELO_SIMULADOR =
> "M0_Base"`, "el mejor en prueba y el más parsimonioso"). El reporte muestra las cinco especificaciones y
> concluye que su hipótesis se respalda parcialmente.
>
> **Alternativas (probadas):**
> - **(a) M4, el mejor en validación** (0.978612). Es lo que diría el protocolo estricto "elegir en
>   validación, confirmar en prueba". En prueba quedó cuarto de cinco: 1.036739, 0.0037 peor que M0 (IC 95 %:
>   −0.0063 a +0.0139, no significativo).
> - **(b) M3, el menor MAE en prueba** (0.894173). Pero su LogLoss en prueba (1.033868) es 0.0008 peor que
>   el de M0, y la meta son probabilidades 1X2, no goles esperados.
> - **(c) Un promedio de los cinco modelos** (ensamble). *No se probó.*
>
> **Por qué ésta:** parsimonia (3 variables por ecuación y VIF ≤ 1.67, contra VIF de hasta 5.56 en M4, cuyas
> variables de tiros y tiros a puerta se correlacionan 0.86); el mejor LogLoss en prueba; coeficientes
> estables e interpretables; y la ventaja de M4 en validación no se sostuvo.
>
> **Honestidad:** presentar a M0 como "el mejor en prueba" **usa la prueba para elegir**; hay que decirlo
> así ([cap. 18](18_hallazgos_y_pendientes.md), C6). Dos hechos lo atenúan:
> 1. *Comprobación de la guía:* la ventaja de M4 en validación era frágil. Su IC bootstrap por partidos
>    apenas excluye el cero (−0.0213 a −0.00005); si se remuestrean fechas o semanas completas, lo incluye
>    (−0.0222 a +0.0002 y −0.0221 a +0.0003).
> 2. **La conclusión principal no depende de la elección:** M4 tampoco supera al mercado (M4 − mercado en
>    prueba: +0.0167, IC 95 %: +0.0034 a +0.0301), y su "parte de la ventaja del mercado" sería 75 % en
>    prueba (la de M0 es 80 %).
>
> **Si preguntan:** "Con el protocolo estricto habríamos elegido M4, el mejor en validación, pero en prueba
> quedó cuarto y su diferencia con M0 no es significativa. Preferimos M0 por ser el más simple y el mejor
> en prueba, sabiendo que esa preferencia usa la prueba y debe confirmarse con la siguiente temporada. La
> conclusión frente al mercado es la misma con cualquiera de los dos."

---

## 19.6 Calibración de K y k

### D29. Validación temporal con ventana creciente · Razonada

Detalle: [cap. 9](09_evaluacion_y_validacion.md) y [cap. 11](11_codigo_analisis_notebook.md) (§5).

> **Decisión:** `FOLDS_HIPERPARAMETROS` define tres pliegues de ventana creciente (*expanding window*),
> todos **dentro del periodo de entrenamiento**: el pliegue 1 entrena con 2019/20–2020/21 (760 partidos) y
> evalúa 2021/22; el 2 entrena con 1,140 y evalúa 2022/23; el 3 entrena con 1,520 y evalúa 2023/24. Ni la
> validación 2024/25 ni la prueba se usan para elegir K y k.
>
> **Alternativas:**
> - **(a) Validación cruzada aleatoria (*k-fold*).** En contra: fuga temporal; partidos futuros
>   entrenarían al modelo que predice el pasado, y el resultado saldría optimista.
> - **(b) Ventana móvil de tamaño fijo.** A favor: se adapta a cambios en el juego. En contra: con cinco
>   temporadas, cada entrenamiento sería más chico. *No se probó.*
> - **(c) Elegir K y k con la validación 2024/25.** En contra: la "gastaría"; ya no serviría para comparar
>   M0–M4 sin sesgo.
> - **(d) Más pliegues** (empezar evaluando 2020/21). En contra: el primer pliegue entrenaría con una sola
>   temporada (380 partidos) y, además, la del COVID. *No se probó.*
>
> **Por qué ésta:** respeta el orden del tiempo, como se usaría el modelo; cada pliegue entrena con todo lo
> anterior, que es la validación con origen móvil que recomiendan Hyndman y Athanasopoulos (2021); y deja
> intactos los dos periodos con que se comparan los modelos.
>
> **Evidencia en el proyecto:** LogLoss de K = 15, k = 0 por pliegue: 0.960230 / 0.989315 / 0.929130; promedio
> ponderado por partidos 0.959558 (1,140 partidos). Como cada pliegue tiene 380 partidos, el promedio
> ponderado coincide con el simple.
>
> **Si preguntan:** "Porque con datos en el tiempo no se puede mezclar: el pasado no debe aprender del
> futuro. Cada pliegue entrena con todo lo anterior a una temporada y evalúa esa temporada, y las tres están
> dentro del entrenamiento; la validación y la prueba quedaron intactas para comparar modelos."

### D30. Rejilla de 35 combinaciones, sólo con M0 y LogLoss ponderado · Razonada

Detalle: [cap. 11](11_codigo_analisis_notebook.md) (§5, `calibrar_hiperparametros`).

> **Decisión:** `itertools.product` de K ∈ {15, 20, …, 45} y k ∈ {0, 5, …, 20} (7 × 5 = 35; en R,
> `expand.grid()`). Para cada combinación se reconstruye la base (`construir_base_historica` con
> `incluir_forma=False`), se ajusta M0 en cada pliegue y se promedia el LogLoss ponderado por partidos; gana
> el mínimo.
>
> **Alternativas:**
> - **(a) Búsqueda aleatoria o bayesiana.** A favor: más eficientes cuando hay muchos parámetros. En
>   contra: con dos parámetros, una rejilla se revisa completa, se ve toda la superficie y no depende de una
>   semilla. *No se probó.*
> - **(b) Calibrar con M4 o con cada modelo.** En contra: K y k sólo afectan a las variables base (diferencia
>   de Elo, goles a favor y en contra), que están en los cinco modelos; con M0 no se mezcla el efecto de los
>   demás bloques y la base se construye más rápido (sin forma ni tiros). *No se probó.*
> - **(c) Calibrar también la ventana y el decaimiento de la forma.** *No se hizo*
>   ([D21](#d21-forma-reciente-10-partidos-decaimiento-085-y-cruza-temporadas--razonada)).
> - **(d) Otro criterio** (MAE, Brier). En contra: el LogLoss es la métrica principal de todo el proyecto
>   ([D33](#d33-logloss-como-métrica-principal-y-mae-como-complemento--razonada)); elegir con la misma
>   métrica con que se evalúa es lo coherente.
>
> **Por qué ésta:** transparente, determinista y con el mismo criterio que la evaluación.
>
> **Evidencia en el proyecto:** la superficie es suave y casi monótona: el LogLoss sube con K (con k = 0 y
> k = 5 sin excepción; con k ≥ 10, K = 20 queda apenas por debajo de K = 15) y sube con k (salvo con
> K = 45). Toda la rejilla cabe en 0.0055 de LogLoss. *Comprobación de la guía:* construir la
> base de M0 tarda unos 40 segundos por combinación, así que las 35 llevan del orden de 20 a 25 minutos.
>
> **Si preguntan:** "Con sólo dos parámetros, una rejilla de 35 combinaciones se revisa completa y no
> depende del azar. Usamos M0 porque K y k sólo afectan a sus variables, y elegimos con el mismo LogLoss con
> el que evaluamos."

### D31. Rejilla comentada en el notebook entregado · Razonada

Detalle: [cap. 11](11_codigo_analisis_notebook.md) y [cap. 14](14_publicacion_en_github.md); README del
repositorio, §3.3; la versión en R está en [equivalencias en R](equivalencias_R/README.md) (`06_calibracion.R`).

> **Decisión:** en la versión entregada, `K_ELO_CANDIDATOS = [15]` y `K_SHRINKAGE_CANDIDATOS = [0]`; la
> rejilla completa queda **comentada** justo arriba, y el README (§3.3) explica cómo repetirla.
>
> **Alternativas:**
> - **(a) Dejar la rejilla activa.** En contra: el notebook tardaría "varias decenas de minutos" cada vez
>   (README).
> - **(b) Borrar la rejilla.** En contra: se perdería la evidencia de cómo se eligió.
> - **(c) Guardar la tabla de las 35 combinaciones en un archivo del repositorio.** A favor: la evidencia
>   quedaría a la vista sin volver a correr nada. *No se hizo.*
>
> **Por qué ésta:** el notebook corre rápido y sigue siendo reproducible; además, el tablero lee la
> rejilla comentada (`configuracion_notebook()` toma la lista más larga) para describirla en su texto.
>
> **Evidencia en el proyecto:** el notebook entregado muestra **sólo la fila elegida** (K = 15, k = 0,
> 0.959558); la tabla completa no está en el entregable. *Comprobación de la guía:* la rejilla se repitió en
> Python (las 35 combinaciones) y en R (`equivalencias_R/06_calibracion.R`, unos 8 segundos), con los mismos
> resultados a 6 decimales; vuelve a ganar K = 15, k = 0.
>
> **Si preguntan:** "Para que el notebook corriera en minutos dejamos activa sólo la combinación elegida; la
> rejilla completa está comentada y el README explica cómo repetirla quitando el comentario de dos líneas.
> Al repetirla vuelve a ganar K = 15 y k = 0."

---

## 19.7 Evaluación

### D32. Partición temporal 1,897 / 380 / 419 · Razonada

Detalle: [cap. 9](09_evaluacion_y_validacion.md).

> **Decisión:** cortes por fecha (`FECHA_VALIDACION = 2024-08-01`, `FECHA_PRUEBA = 2025-08-01`):
> entrenamiento 2019/20–2023/24 (1,897 partidos, 9-ago-2019 a 19-may-2024), validación 2024/25 (380) y
> prueba desde agosto de 2025 (419: 380 de 2025/26 y 39 de 2026/27, hasta el 14-sep-2026). Los coeficientes
> se estiman una sola vez, con entrenamiento, y no se vuelven a estimar.
>
> **Alternativas:**
> - **(a) Partición aleatoria** (por ejemplo 70/15/15). En contra: fuga temporal y resultados optimistas.
> - **(b) Sólo entrenamiento y prueba.** En contra: no habría un periodo para comparar M0–M4 sin tocar la
>   prueba.
> - **(c) Reentrenar con entrenamiento + validación antes de la prueba.** A favor: 380 partidos más, y más
>   recientes. En contra: el modelo que se prueba ya no sería el que se comparó en validación.
>   *No se probó.*
> - **(d) Cerrar la prueba en una fecha fija** (por ejemplo, 31-jul-2026: exactamente 380 partidos).
>   A favor: los resultados no cambiarían si la fuente se actualiza. En contra: deja fuera los 39 partidos
>   más recientes. *No se hizo* (ver 19.10).
>
> **Por qué ésta:** es como se usaría el modelo: aprende del pasado y se evalúa con el futuro; usa
> temporadas completas para entrenar y validar, y lo más reciente para confirmar.
>
> **Evidencia en el proyecto:** Cuadro 3 del reporte; salida de la §5 del notebook. El README (§5.3) advierte
> que la prueba no tiene fecha de cierre: si se agregan partidos nuevos a `E0_consolidado.csv`, cambian las
> cifras de prueba.
>
> **Si preguntan:** "Como se usaría en la realidad: aprende de 2019 a 2024, compara modelos en 2024/25 y se
> confirma con lo más reciente, de agosto de 2025 a septiembre de 2026. Mezclar al azar dejaría que partidos
> futuros entrenen al modelo que predice el pasado."

### D33. LogLoss como métrica principal y MAE como complemento · Razonada

Detalle: [cap. 9](09_evaluacion_y_validacion.md).

> **Decisión:** la métrica principal es el LogLoss 1X2, −(1/N)·Σ log p<sub>i,y<sub>i</sub></sub>
> (`sklearn.metrics.log_loss`; en R, `-mean(log(P[cbind(1:n, y)]))`). El MAE de goles evalúa λ; la tasa de
> aciertos sólo se usa para comunicar.
>
> **Alternativas:**
> - **(a) Brier** (Brier, 1950): también es una regla de puntaje propia, menos severa con los errores muy
>   confiados.
> - **(b) RPS** (*ranked probability score*; Constantinou y Fenton, 2012): toma en cuenta el orden
>   local–empate–visitante.
> - **(c) Aciertos:** fáciles de explicar, pero ignoran la confianza (decir 40 % o 90 % al favorito cuenta
>   igual) y no son una regla de puntaje propia.
> - **(d) Sólo el MAE:** evalúa los goles esperados, no las probabilidades 1X2.
>
> Brier y RPS no se reportan en el proyecto.
>
> **Por qué ésta:** el LogLoss es una regla de puntaje **estrictamente propia** (Gneiting y Raftery, 2007):
> la única forma de minimizarla es dar las probabilidades verdaderas; castiga la sobreconfianza; tiene una
> referencia natural (el azar da ln 3 = 1.0986); y e<sup>−LogLoss</sup> se lee como la probabilidad media
> (geométrica) que se dio al resultado real: 35.6 % para M0 en prueba y 36.1 % para el mercado. El reporte
> lo respalda con Foulley (2021).
>
> **Evidencia en el proyecto:** el MAE y el LogLoss no siempre coinciden: en prueba, M3 tiene el menor MAE
> (0.894173) y M0 el menor LogLoss (1.033076); por eso se reportan los dos. *Comprobación de la guía:* con
> Brier y con RPS, el orden de los nueve predictores (azar, ingenua, M0–M4, apertura y cierre) es
> **exactamente el mismo** que con el LogLoss, en validación y en prueba. En prueba: Brier 0.6217 (M0),
> 0.6133 (mercado), 0.6582 (ingenua); RPS 0.2088, 0.2049 y 0.2273.
>
> **Si preguntan:** "Porque es una regla de puntaje propia: la única forma de minimizarla es dar las
> probabilidades correctas, y castiga la sobreconfianza. No reportamos Brier ni RPS, pero después
> verificamos que con ellos el orden de los modelos y del mercado es exactamente el mismo."

### D34. Referencias sin información: azar y referencia ingenua · **Probada**

Detalle: [cap. 9](09_evaluacion_y_validacion.md).

> **Decisión:** dos referencias. **Azar**: 1/3 a cada resultado (LogLoss = ln 3 = 1.098612). **Referencia
> ingenua**: la misma Poisson + Skellam sin variables, con las medias de goles de entrenamiento
> (λ = 1.561413 y 1.311545), que da a todos los partidos 43.24 % / 24.69 % / 32.07 %.
>
> **Alternativas:**
> - **(a) Frecuencias históricas del 1X2** (45.6 / 24.7 / 29.7 %). Es casi la misma idea, sin pasar por
>   Poisson. *No se probó.*
> - **(b) "Siempre gana el local"** para los aciertos. Da lo mismo que la ingenua, que siempre favorece al
>   local: 40.8 % en validación y 41.5 % en prueba.
> - **(c) Comparar sólo contra el mercado.** En contra: no diría cuánto aporta la estadística frente a no
>   saber nada.
>
> **Por qué ésta:** la ingenua usa el mismo aparato que el modelo, así que aísla el aporte de las
> variables; y es el "cero" de la parte de la ventaja del mercado ([D37](#d37-parte-de-la-ventaja-del-mercado-80--para-comunicar--razonada)).
>
> **Evidencia en el proyecto (probada):** LogLoss de la ingenua 1.079361 (validación) y 1.086791 (prueba);
> azar 1.098612. M0 − ingenua en prueba: −0.0537 (IC 95 %: −0.0861 a −0.0217). Aciertos en prueba: M0
> 48.0 %, ingenua 41.5 %.
>
> **Si preguntan:** "Para saber cuánto aportan las variables necesitamos un 'cero': el mismo modelo de
> Poisson sin variables, que da a todos los partidos 43 / 25 / 32 %. M0 lo supera con claridad: −0.054 de
> LogLoss en prueba, con un intervalo que no toca el cero."

### D35. Mercado: cuotas promedio de apertura con normalización proporcional · **Probada**

Detalle: [cap. 8](08_cuotas_y_mercado.md).

> **Decisión:** con las cuotas promedio `AvgH`, `AvgD`, `AvgA`: q<sub>j</sub> = 1/cuota<sub>j</sub> y
> p<sub>j</sub> = q<sub>j</sub>/Σq (en R, `q / rowSums(q)`), sobre exactamente los mismos partidos que el
> modelo (380 de 380 en validación y 419 de 419 en prueba). El margen promedio que se retira es 4.49 % y
> 5.84 %. "Apertura" es el nombre que usa el proyecto: Football-Data registra estas cuotas el viernes por
> la tarde (partidos de fin de semana) o el martes (entre semana).
>
> **Alternativas:**
> - **(a) Cuotas de cierre** (`AvgCH`, `AvgCD`, `AvgCA`). A favor: más informadas: 0.966733 y 1.017024,
>   mejores que la apertura. En contra: incluyen información de último momento que no tendría un pronóstico
>   hecho con anticipación. ***Probada:*** el tablero las muestra como referencia adicional.
> - **(b) Bet365 sola.** En contra: una casa en lugar del consenso. *No se probó como vara del modelo* (se usa
>   para el análisis histórico del favorito).
> - **(c) Una casa "afilada"** como Pinnacle. En contra: sus columnas no se conservaron en la limpieza.
> - **(d) Normalización de Shin** (Shin, 1993; Štrumbelj, 2014) **o de potencia**, que corrigen el sesgo
>   favorito–sorpresa. *No se probaron en el proyecto.*
>
> **Por qué ésta:** es la conversión más simple y transparente, y con márgenes de 4 a 6 % los métodos
> difieren poco.
>
> **Evidencia en el proyecto:** mercado de apertura 0.970552 / 1.020000; de cierre 0.966733 / 1.017024;
> M0 0.989547 / 1.033076. *Comprobación de la guía:* con Shin, el LogLoss del mercado sería 0.970635 /
> 1.020971, y con el método de potencia 0.971026 / 1.021782: un poco **peor** que la normalización
> proporcional, porque ambos quitan probabilidad al empate (en prueba, la P(empate) media baja de 24.54 % a
> 24.15 % con Shin) y los empates ocurrieron 28.2 %. La conclusión no cambia: el mercado sigue muy por delante de M0.
>
> **Si preguntan:** "Usamos la cuota promedio de varias casas, registrada antes del partido, y quitamos el
> margen repartiéndolo en proporción. Hay métodos más finos, como el de Shin; después comprobamos que con
> ellos el LogLoss del mercado cambia en la cuarta cifra y la conclusión es la misma. Las cuotas de cierre
> son aún mejores y las mostramos como referencia adicional."

### D36. Bootstrap pareado por partidos · Razonada

Detalle: [cap. 9](09_evaluacion_y_validacion.md).

> **Decisión:** `tabla_bootstrap()` (tablero) toma, para cada comparación A − B, la diferencia de LogLoss
> partido por partido, la remuestrea con reemplazo 10,000 veces (`np.random.default_rng(2026)`; en R,
> `set.seed(2026)` y `sample(replace = TRUE)`) y reporta el IC 95 % con los percentiles 2.5 y 97.5. Si el
> intervalo no incluye el cero, la diferencia se marca como distinta de cero.
>
> **Alternativas:**
> - **(a) Prueba de Diebold y Mariano (1995)**, la clásica para comparar pronósticos; con horizonte de un
>   paso equivale a una prueba t sobre las diferencias. *No se probó en el proyecto.*
> - **(b) Bootstrap por bloques** (remuestrear fechas o jornadas completas), que respeta la posible
>   dependencia entre partidos cercanos. *No se probó en el proyecto.*
> - **(c) No reportar incertidumbre.** Es lo que hace el notebook; el reporte (§9) lo reconoce y remite al
>   tablero.
>
> **Por qué ésta:** no supone normalidad; es **pareado** (los dos pronósticos se evalúan en los mismos
> partidos, lo que elimina la variación que comparten); y es fácil de explicar (Efron y Tibshirani, 1993).
>
> **Evidencia en el proyecto:** las siete comparaciones del tablero. *Comprobación de la guía:* con
> Diebold–Mariano y con bootstrap por fecha y por semana calendario (una aproximación a la jornada), la
> lectura se mantiene en cinco de siete; las dos que están **al límite** cambian según el método:
>
> | Comparación (A − B) | Por partidos (tablero) | Diebold–Mariano | Por fecha | Por semana |
> |---|---|---|---|---|
> | M0 − ingenua (prueba) | −0.0861 a −0.0217 | p = 0.001 | −0.0880 a −0.0207 | −0.0840 a −0.0209 |
> | M0 − mercado (prueba) | −0.0005 a +0.0264 | p = 0.059 | −0.0010 a +0.0273 | **+0.0002** a +0.0269 |
> | M4 − M0 (prueba) | −0.0063 a +0.0139 | p = 0.48 | −0.0058 a +0.0129 | −0.0060 a +0.0132 |
> | M4 − mercado (prueba) | +0.0034 a +0.0301 | p = 0.015 | +0.0031 a +0.0308 | +0.0017 a +0.0320 |
> | M4 − M0 (validación) | −0.0213 a −0.00005 | p = 0.048 | −0.0222 a **+0.0002** | −0.0221 a **+0.0003** |
> | M0 − mercado (validación) | +0.0053 a +0.0328 | p = 0.008 | +0.0056 a +0.0326 | +0.0070 a +0.0318 |
> | M0 − mercado (validación + prueba) | +0.0064 a +0.0255 | p = 0.001 | +0.0060 a +0.0259 | +0.0068 a +0.0253 |
>
> Hay 127 fechas y 41 semanas en prueba, y 109 y 36 en validación.
>
> **Si preguntan:** "Remuestreamos los partidos 10,000 veces y vimos si el intervalo de la diferencia
> incluye el cero; es pareado, porque los dos pronósticos se evalúan en los mismos partidos. Los casos al
> límite, como M4 contra M0 en validación o M0 contra el mercado sólo en prueba, hay que leerlos así, al
> límite: con otros métodos pueden quedar de un lado o del otro. Lo robusto es que M0 supera a la ingenua y
> que, con validación y prueba juntas, el mercado supera a M0."

### D37. "Parte de la ventaja del mercado" (80 %) para comunicar · Razonada

Detalle: [cap. 12](12_resultados.md) y [cap. 13](13_dashboard.md).

> **Decisión:** `fraccion_de_mejora()` = (LogLoss ingenua − LogLoss M0) / (LogLoss ingenua − LogLoss
> mercado): 80.4 % en prueba y 82.5 % en validación. La portada lo muestra como "80 %": "de cada 100 puntos
> que el mercado mejora sobre una referencia ingenua, el modelo logra 80".
>
> **Alternativas:**
> - **(a) Sólo las diferencias de LogLoss** (+0.013 en prueba). Exactas, pero ilegibles para quien no
>   conoce la métrica. *También se muestran.*
> - **(b) Aciertos** (48.0 % contra 48.9 %). Fáciles, pero ignoran la confianza. *También se muestran.*
> - **(c) Mejora relativa al azar** (1 − LogLoss / ln 3): 6.0 % para M0 y 7.2 % para el mercado en prueba.
>   Correcta, pero poco intuitiva. *No se usó.*
>
> **Por qué ésta:** traduce el LogLoss a una escala de 0 (la ingenua) a 100 (el mercado) que entiende
> cualquiera, y es justo la historia del tablero.
>
> **Evidencia en el proyecto:** 80.4 % y 82.5 %. Limitaciones que hay que conocer: depende de qué se tome
> como cero, y es un cociente de diferencias pequeñas, así que es **incierto**. *Comprobación de la guía:* su
> IC 95 % bootstrap (por partidos) va de 54 % a 101 % en prueba y de 68 % a 94 % en validación. Con M4 sería
> 75 % en prueba y 93 % en validación.
>
> **Si preguntan:** "Es una forma de leer el LogLoss: si la referencia ingenua vale 0 y el mercado 100, el
> modelo llega a 80. No sustituye a la cifra exacta, que también mostramos, y es incierta: con 419 partidos
> podría estar entre la mitad y casi el total."

### D38. Sensibilidad sin público · **Probada**

Detalle: [cap. 12](12_resultados.md) y [cap. 13](13_dashboard.md).

> **Decisión:** el tablero (`sensibilidad_sin_publico()`) reentrena M0 sin los 472 partidos de
> entrenamiento jugados a puerta cerrada (17-jun-2020 a 23-may-2021) y compara validación y prueba. Es un
> complemento: no sustituye al modelo del equipo.
>
> **Alternativas:**
> - **(a) No revisarlo.** En contra: 2020/21 es la única temporada en que los visitantes ganaron más que
>   los locales (40.3 % contra 37.9 %) y está dentro del entrenamiento; la pregunta es inevitable.
> - **(b) Una variable indicadora "sin público"** en el entrenamiento (valdría 0 al pronosticar). A favor:
>   conserva los partidos. *No se probó.*
> - **(c) Excluir toda la temporada 2020/21.** Parecido a lo que se hizo. *No se probó.*
>
> **Por qué ésta:** responde de forma directa si la temporada sin público explica la brecha con el mercado,
> sin cambiar el modelo principal.
>
> **Evidencia en el proyecto (probada):** LogLoss de prueba 1.0331 → 1.0328; validación 0.9895 → 0.9900;
> P(local) media en prueba 42.6 % → 44.0 %. La brecha con el mercado en prueba es de 0.013, mucho mayor que
> esos cambios.
>
> **Si preguntan:** "Sí lo revisamos: reentrenamos M0 sin los 472 partidos a puerta cerrada. Sube un poco la
> probabilidad del local, de 42.6 % a 44.0 %, pero el LogLoss de prueba casi no cambia (1.0331 a 1.0328),
> mientras que la brecha con el mercado es de 0.013. El COVID no explica la diferencia."

---

## 19.8 Tablero

### D39. Quarto (formato *dashboard*) + Python · Razonada

Detalle: [cap. 13](13_dashboard.md) y [cap. 13c](13c_codigo_index_quarto.md).

> **Decisión:** `index.qmd` con `format: dashboard` (orientación por filas, `scrolling: true`, tema
> `cosmo` + `estilos.scss`) y `jupyter: python3`: los chunks se ejecutan con el mismo Python del equipo.
> Se construye con Quarto 1.8.25 y sale como HTML estático en `_site/` (`_quarto.yml`).
>
> **Alternativas:**
> - **(a) Flexdashboard (R Markdown).** A favor: es la herramienta del tema 2 del módulo, con la misma
>   lógica de páginas, filas y tarjetas. En contra: habría obligado a reescribir el modelo en R o a pasar
>   resultados de un lenguaje a otro, con riesgo de que las cifras no coincidan.
> - **(b) Shiny.** En contra: necesita un servidor encendido (shinyapps.io); la interactividad que se quería
>   cabe en el navegador.
> - **(c) Streamlit o Dash** (Python). En contra: también necesitan servidor.
> - **(d) Power BI o Tableau.** En contra: licencias, y el tablero no se reconstruye desde el código.
>
> Ninguna se probó.
>
> **Por qué ésta:** el análisis está en Python y el tablero **importa el mismo código**, así que sus cifras
> coinciden con las del notebook por construcción; Quarto produce un sitio estático que GitHub Pages
> publica gratis; los dashboards de Quarto los hace Posit, el mismo grupo que Flexdashboard, con los mismos
> conceptos; y Quarto se vio en clase (el workflow cita las plantillas de Quarto de la clase 8).
>
> **Evidencia en el proyecto:** el sitio se construye solo en GitHub Actions y la verificación da 17 de 17
> ([D41](#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)).
>
> **Si preguntan:** "Porque el modelo está en Python y Quarto nos deja importar ese mismo código, así las
> cifras del tablero coinciden por construcción con las del notebook. Además produce un sitio estático que
> GitHub Pages publica gratis; Shiny, Streamlit o Dash necesitarían un servidor encendido."

### D40. Recalcular todo desde los archivos del equipo · Razonada

Detalle: [cap. 13a](13a_codigo_datos_dashboard.md).

> **Decisión:** `datos_dashboard.py` importa `wc_predictor.py` desde `../Codigo/proyecto_mod_8` (o desde
> la ruta de la variable de entorno `RUTA_CODIGO`), lee `E0_consolidado.csv` y `premier_training_data.csv`,
> y reproduce **con la misma lógica y los mismos nombres** las funciones del notebook (§2, §4 y §8:
> `preparar_X`, `entrenar_modelo`, `probabilidades_1x2`…), porque viven dentro del notebook y no se pueden
> importar. Lee K, k y la escala de `wc_predictor.py`, y la ventana, el decaimiento, las rejillas y los
> pliegues del código del notebook (`configuracion_notebook()`).
>
> **Alternativas:**
> - **(a) Copiar las cifras a mano.** En contra: se desactualizan con cada cambio, y hubo varios (K de 30 a
>   15, k de 10 a 0, M3 en la prueba).
> - **(b) Ejecutar el notebook desde el tablero** (por ejemplo con `nbclient`). En contra: tarda varios
>   minutos y el tablero dependería de que el notebook corra completo.
> - **(c) Que el notebook exporte sus resultados a un archivo** (JSON o CSV) que el tablero lea. En contra:
>   el tablero calcula muchas cosas que el notebook no (bootstrap, calibración, simulador).
> - **(d) Pasar las funciones del notebook a un módulo importable.** A favor: una sola implementación. En
>   contra: reorganizar el notebook del equipo de Código al final del proyecto.
>
> Ninguna se probó.
>
> **Por qué ésta:** una sola fuente de verdad, los archivos del equipo. El riesgo de duplicar funciones
> (que dejen de coincidir) se controla con la verificación automática ([D41](#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)).
>
> **Evidencia en el proyecto:** cuando Daniel agregó M3 a la evaluación de prueba, el tablero lo incorporó
> sin tocar su código. Detalle técnico: `wc_predictor.py` se importa desde su propia carpeta porque, al
> importarse, lee `E0_consolidado.csv` con ruta relativa.
>
> **Si preguntan:** "El tablero no tiene cifras copiadas: importa `wc_predictor.py`, lee los dos CSV del
> equipo y repite las funciones del notebook con el mismo código. Lo que el notebook no calcula, como el
> bootstrap o el simulador, se agrega en el mismo archivo."

### D41. Verificación automática contra las salidas del notebook · Razonada

Detalle: [cap. 13a](13a_codigo_datos_dashboard.md).

> **Decisión:** `tabla_verificacion()` lee las **salidas guardadas** de `Analisis.ipynb`
> (`cifras_publicadas_notebook()`: las tablas de comparación con el mercado y el ejemplo Arsenal–City) y
> las compara con las del tablero: 12 LogLoss (M0–M4 y mercado, en validación y en prueba; tolerancia
> 5 × 10⁻⁷) y 5 cifras del ejemplo. Si el notebook se guardó sin salidas, agrega una fila con ✗ y el texto
> de la pestaña *Reproducibilidad* dice "HAY DIFERENCIAS: revisar antes de publicar".
>
> **Alternativas:**
> - **(a) Comparar contra cifras copiadas a mano**, como hacía una versión anterior. En contra: la lista
>   también se desactualiza.
> - **(b) No verificar** y confiar en que las funciones duplicadas coinciden.
> - **(c) Que la publicación falle** si alguna cifra no coincide (una prueba automática en el workflow).
>   A favor: no se publicaría nada inconsistente. En contra: más infraestructura. *No se hizo*: hoy el
>   tablero avisa, pero se publica.
>
> **Por qué ésta:** demuestra que duplicar las funciones no introdujo diferencias, y se adapta sola a lo
> que el notebook imprima.
>
> **Evidencia en el proyecto:** **17 de 17 ✓**, también en el sitio publicado, que se construye en los
> servidores de GitHub. Cuando se agregó M3 a la prueba, la tabla pasó de 16 a 17 cifras sin tocar el
> tablero. *Comprobación de la guía:* se volvió a calcular el 2-oct-2026 y coinciden las 17.
>
> **Si preguntan:** "El tablero lee las salidas guardadas del notebook y compara 17 cifras contra las suyas;
> coinciden las 17, también en el servidor de GitHub. Si no coincidieran, el propio tablero diría 'HAY
> DIFERENCIAS'."

### D42. Cifras del texto con `{python}` y frases condicionales · Razonada

Detalle: [cap. 13c](13c_codigo_index_quarto.md).

> **Decisión:** los números del texto de `index.qmd` son código en línea, por ejemplo
> `` `{python} pct(acc('Prueba', 'M0_Base'))` `` (en R Markdown, `` `r scales::percent(x)` ``), y algunas
> frases cambian según el valor: `texto_k` dice "es decir, sin mezcla" sólo si k = 0; `texto_borde` avisa si
> K quedó en un extremo de la rejilla; el simulador explica los promedios de una forma u otra según k; la
> frase de la verificación dice "todas coinciden" o "HAY DIFERENCIAS"; y `ic()` usa 4 decimales cuando un
> extremo del intervalo está muy cerca de cero, para no mostrar "−0.000".
>
> **Alternativas:**
> - **(a) Escribir los números a mano.** En contra: el texto podría contradecir a las gráficas en cuanto
>   cambie algo.
> - **(b) Generar todo el texto con plantillas.** En contra: ilegible para quien edita el tablero.
>
> **Por qué ésta:** si cambian los datos o los parámetros, el texto se reescribe solo, incluido el sentido
> de algunas frases.
>
> **Evidencia en el proyecto:** los valores de K, k, la ventana, el decaimiento, las rejillas y los pliegues
> que cita el texto se leen del código del equipo, no del texto. Quedan escritos a mano algunos datos fijos
> que convendría calcular: el "3" de
> la tarjeta "Variables en el mejor modelo", la fecha inicial (18 de agosto de 2001), los "20 equipos" del
> simulador y los nombres de los periodos.
>
> **Si preguntan:** "Las cifras del texto se calculan al generar el tablero; no están escritas a mano.
> Incluso hay frases condicionales: si k no fuera 0, el tablero explicaría la mezcla de temporadas en lugar
> de decir 'sin mezcla'."

### D43. Plotly con plantilla única y paleta con significado · Razonada

Detalle: [cap. 13b](13b_codigo_graficas.md).

> **Decisión:** `graficas.py` usa Plotly (`plotly.graph_objects`) con una sola plantilla (`PLANTILLA`:
> fuente del sistema, rejilla clara, fondo transparente) y colores fijos: **azul** `#2a78d6` = modelo,
> **naranja** `#eb6834` = mercado, **verde** `#008300` = local, **violeta** `#4a3aa7` = visitante y **gris**
> `#898781` = contexto (empate, referencias, especificaciones secundarias). `mostrar()` quita la barra de
> herramientas, el zoom y el arrastre (`displayModeBar: False`, `dragmode=False`, ejes `fixedrange`) y la
> leyenda interna (las leyendas van en HTML, en el subtítulo de cada tarjeta). Las barras parten de cero, y
> las gráficas principales tienen una vista de tabla en una pestaña (`tabla_html`).
>
> **Alternativas:**
> - **(a) ggplot2 o matplotlib estáticos.** En contra: imágenes sin tooltips. En R, lo equivalente
>   interactivo sería `plotly::ggplotly()` o `plot_ly()`. *No se probó.*
> - **(b) Plotly con sus opciones por defecto.** Así estaba al principio y se corrigió: las leyendas se
>   encimaban en páginas ocultas y un arrastre accidental dejaba la gráfica ampliada sin forma visible de
>   regresar.
> - **(c) La paleta por defecto.** En contra: el color no significaría nada. *No se probó.*
>
> **Por qué ésta:** interactividad (tooltips) en un HTML estático, sin servidor; el color se reserva para lo
> importante y significa lo mismo en todo el tablero; y la paleta se revisó para daltonismo (un gris de
> empate junto a un tono aqua no se distinguía con deuteranopía, y el local pasó a verde).
>
> **Evidencia en el proyecto:** el código de `graficas.py` y su docstring con las reglas de diseño.
>
> **Si preguntan:** "Plotly da tooltips sin necesitar servidor. Cada color significa siempre lo mismo
> —azul el modelo, naranja el mercado, verde el local, violeta el visitante, gris el contexto— y
> desactivamos el zoom porque un arrastre accidental dejaba la gráfica ampliada sin forma de regresar."

### D44. Simulador en Observable JS con los 380 cruces precalculados · Razonada

Detalle: [cap. 13c](13c_codigo_index_quarto.md) y [cap. 13a](13a_codigo_datos_dashboard.md) (`datos_simulador`).

> **Decisión:** `datos_simulador()` calcula en Python, con M0 y corte el 15-sep-2026 (un día después del
> último partido), los 380 cruces local–visitante de los 20 equipos de 2026/27: λ, P(1X2), marcador más
> probable y la matriz de marcadores de 0 a 5. `ojs_define(sim=…)` pasa esos datos al navegador (en un
> chunk con `echo: false`, porque con `include: false` no funciona) y Observable JS arma los selectores
> (`Inputs.select`) y el mapa de calor (`Plot.cell`).
>
> **Alternativas:**
> - **(a) Shiny o un servidor de Python.** A favor: podría calcular cualquier escenario. En contra: necesita
>   un servidor encendido.
> - **(b) Python en el navegador** (Pyodide o Shinylive). A favor: sin servidor. En contra: el navegador
>   tendría que descargar Python y los paquetes; arranque lento.
> - **(c) Programar el modelo en JavaScript.** En contra: una segunda implementación del modelo, con riesgo
>   de que no coincida.
> - **(d) Una tabla estática de 380 filas.** En contra: sin interacción.
>
> Ninguna se probó.
>
> **Por qué ésta:** 20 × 19 = 380 combinaciones son pocas: precalcularlas es barato y el navegador sólo
> filtra y dibuja, así que funciona en GitHub Pages, que sólo sirve archivos estáticos.
>
> **Evidencia en el proyecto:** Arsenal–Man City da λ = 1.538 / 1.266, 43.65 % / 25.00 % / 31.35 % y 1–1
> como marcador más probable (11.80 %), las mismas cifras del notebook redondeadas. Limitación: no admite
> ajustes (lesiones, alineaciones) y la fecha de corte es fija.
>
> **Si preguntan:** "Como sólo hay 380 cruces posibles, los calculamos todos en Python con M0 y el navegador
> sólo los filtra. Así el simulador funciona en un sitio estático; con Shiny habríamos necesitado un
> servidor encendido."

### D45. Una historia en seis páginas, con títulos que dicen la conclusión · Razonada

Detalle: [cap. 13](13_dashboard.md).

> **Decisión:** seis páginas en el orden de una historia: **Resumen** (pregunta, hipótesis, resultado y la
> conclusión primero) → **¿Qué ocurre?** → **Patrones** → **El modelo** → **Explora un partido** (simulador)
> → **Datos y método**. Cada tarjeta lleva un título que dice el hallazgo ("Jugar en casa siempre ayuda…
> salvo sin público", "Agregar variables no generaliza"), con tres indicadores (*value boxes*) en las dos
> primeras páginas e identificadores sin acentos (`#que-ocurre`).
>
> **Alternativas:**
> - **(a) Una sola página larga.** En contra: difícil de recorrer.
> - **(b) Organizar por tipo de gráfica o por archivo.** En contra: no cuenta una historia.
> - **(c) Títulos descriptivos** ("Resultados por temporada"). En contra: obligan al lector a sacar la
>   conclusión.
>
> Ninguna se probó.
>
> **Por qué ésta:** las instrucciones piden que la visualización responda qué ocurre, qué patrones hay, qué
> aporta el modelo y cuál es la conclusión principal, y aclaran que se evalúa la comunicación, no la
> herramienta; el orden sigue esas preguntas y el *storytelling* del módulo.
>
> **Evidencia en el proyecto:** la estructura de `index.qmd` (encabezados `#` de cada página).
>
> **Si preguntan:** "El tablero sigue el orden de las preguntas que pide la actividad: primero la
> conclusión, luego qué ocurre, los patrones y lo que aporta el modelo; después el simulador y el método.
> Cada título dice el hallazgo, no el tipo de gráfica."

### D46. `redibujar.html` para las gráficas en pestañas ocultas · Razonada

Detalle: [cap. 13b](13b_codigo_graficas.md) y [cap. 13c](13c_codigo_index_quarto.md).

> **Decisión:** un script de unas 45 líneas, incluido con `include-after-body`, que vuelve a dibujar cada
> gráfica de Plotly (`Plotly.newPlot`) cuando su contenedor pasa de oculto (0 px) a visible o cambia más de
> 40 px de tamaño (`ResizeObserver`, con 120 ms de espera), al cargar la página (a los 250 ms y otra vez a
> los 1,500 ms, para equipos lentos) y al cambiar de pestaña (`shown.bs.tab`). Busca Plotly en
> `window.Plotly` o en `window._Plotly`, porque la página incluye `require.js`.
>
> **Alternativas:**
> - **(a) No hacer nada.** En contra: en las páginas ocultas al dibujarse, las etiquetas no aparecían o se
>   encimaban (problema observado).
> - **(b) Poner todas las gráficas en una sola página visible.** En contra: se pierde la estructura de la
>   historia.
> - **(c) Imágenes estáticas.** En contra: sin tooltips.
>
> **Por qué ésta:** es un arreglo pequeño que no toca las gráficas; sólo actúa cuando una gráfica se vuelve
> visible.
>
> **Evidencia en el proyecto:** el problema y su causa están en la tabla de problemas resueltos del
> [cap. 13](13_dashboard.md) (la primera versión no encontraba Plotly porque estaba en `window._Plotly`).
>
> **Si preguntan:** "Plotly mide los textos al dibujar, y en una pestaña oculta todo mide cero, así que las
> etiquetas salían mal. El script vuelve a dibujar cada gráfica cuando se vuelve visible."

---

## 19.9 Publicación y reproducibilidad

### D47. GitHub Pages + GitHub Actions · Razonada

Detalle: [cap. 14](14_publicacion_en_github.md).

> **Decisión:** `.github/workflows/publicar-dashboard.yml` se ejecuta en cada `push` a `main` (o a mano,
> con `workflow_dispatch`). El trabajo `build`, en Ubuntu, clona el repositorio, instala Quarto 1.8.25 y
> Python 3.10, instala `requirements.txt`, ejecuta `quarto render Dashboard-o-pagina` y sube `_site/`; el
> trabajo `deploy` (`needs: build`) lo publica en GitHub Pages. Permisos mínimos (`contents: read`,
> `pages: write`, `id-token: write`) y `concurrency: pages` para que dos publicaciones no se pisen.
>
> **Alternativas:**
> - **(a) Generar el sitio en una computadora y subir `_site/` al repositorio** (o usar `quarto publish
>   gh-pages`). A favor: no hay que escribir un workflow. En contra: el sitio depende de la máquina de alguien,
>   los archivos generados ensucian el historial y nadie comprueba que se reproduce. *No se usó*: `_site/`
>   está en `.gitignore`.
> - **(b) Netlify o Quarto Pub.** En contra: otro servicio y otra cuenta. *No se probó.*
> - **(c) shinyapps.io.** En contra: sólo sirve para Shiny, que necesita servidor ([D39](#d39-quarto-formato-dashboard--python--razonada)).
>
> **Por qué ésta:** gratis, y **cada publicación es una prueba de reproducibilidad**: el tablero se construye
> desde cero en una máquina limpia, y si algo falla no se publica. El sitio siempre corresponde al último
> commit.
>
> **Evidencia en el proyecto:** verificado con la API pública de GitHub: de las 40 ejecuciones más
> recientes, 37 terminaron con éxito y 3 se cancelaron. Las canceladas eran publicaciones en espera que
> reemplazó un push más nuevo (`concurrency`, ver [cap. 14](14_publicacion_en_github.md)); ninguna falló, y
> la del último commit (`e3bd43f`) publicó el sitio con la tabla de verificación en 17 de 17, calculada en
> ese servidor. El README (§4.1) lo describe y explica cómo activarlo en un *fork*.
>
> **Si preguntan:** "En cada push, GitHub construye el tablero desde cero en una máquina limpia, con las
> mismas versiones de Quarto y de Python, y sólo si termina bien lo publica. Así la publicación es también
> una prueba de que el proyecto se reproduce."

### D48. Versiones fijas y huellas SHA-256 · Razonada

Detalle: [cap. 14](14_publicacion_en_github.md); README del repositorio, §1–§2.

> **Decisión:** `requirements.txt` fija las librerías que calculan las cifras (pandas 2.2.3, numpy 2.2.3,
> scipy 1.15.2, statsmodels 0.14.4, scikit-learn 1.6.1, plotly 5.24.1; `jupyter` y `pyyaml` sin versión);
> el workflow fija Quarto 1.8.25 y Python 3.10; y el README publica la huella SHA-256 de los dos CSV.
>
> **Alternativas:**
> - **(a) Sin versiones** (`pip install pandas`). En contra: una versión nueva podría cambiar una cifra o
>   romper el código el día de la exposición.
> - **(b) Congelar el entorno completo** (`pip freeze`, un entorno de conda o Docker). A favor:
>   reproducibilidad total. En contra: más pesado, y una lista congelada en Windows puede no instalarse en
>   Ubuntu. *No se probó.*
> - **(c) Sin huellas.** En contra: no habría forma rápida de saber si un CSV cambió; abrirlo y guardarlo en
>   Excel cambia fechas y decimales.
>
> **Por qué ésta:** es un punto medio: fija lo que produce las cifras y permite detectar cualquier cambio en
> los datos.
>
> **Evidencia en el proyecto:** el equipo repitió todo desde cero el 30-sep-2026, en Linux, con Python 3.10.20
> y Quarto 1.8.25 (commit `16c9e4b`): el notebook volvió a dar las cifras guardadas y la caché salió idéntica
> (README). *Comprobación de la guía:* las huellas actuales coinciden con las del README
> (`7cea84b1…` para `E0_consolidado.csv` y `37de4c4c…` para `premier_training_data.csv`).
>
> **Si preguntan:** "Fijamos las versiones de las librerías que calculan las cifras, y el README da la huella
> SHA-256 de cada CSV: si alguien abre el archivo en Excel y lo guarda, la huella cambia y se nota. Con eso
> repetimos todo desde cero en Linux y obtuvimos las mismas cifras."

### D49. `premier_training_data.csv` como caché · Razonada

Detalle: [cap. 11](11_codigo_analisis_notebook.md) y [cap. 14](14_publicacion_en_github.md); README, §3.2.

> **Decisión:** la base de modelación (2,696 × 24) se exportó desde el notebook (la celda `to_csv` quedó
> comentada) y el tablero la lee (`cargar_base_modelacion()`) en lugar de reconstruirla. El notebook no la
> lee: la reconstruye en cada ejecución.
>
> **Alternativas:**
> - **(a) Que el tablero reconstruya la base en cada publicación.** En contra: `construir_base_historica`
>   vive en el notebook (habría que duplicarla también) y tarda alrededor de un minuto (60 segundos en la
>   comprobación de la guía). *No se probó.*
> - **(b) No guardar la tabla.** En contra: el tablero no tendría de dónde leer las variables.
>
> **Por qué ésta:** el tablero se construye rápido y usa exactamente la misma tabla que el notebook. El
> riesgo es que la caché quede vieja si cambian la base, `wc_predictor.py`, K o k; entonces hay que
> regenerarla (reporte, §11.1). Si eso pasara, la verificación lo delataría, porque los LogLoss del tablero
> dejarían de coincidir con los del notebook.
>
> **Evidencia en el proyecto:** README §3.2: una celda compara la tabla reconstruida con la caché y debe
> imprimir `OK (2696, 24)`. *Comprobación de la guía:* la base reconstruida con K = 15 y k = 0 coincide con la
> caché, con las mismas claves en el mismo orden y una diferencia numérica máxima de 4.5 × 10⁻¹³.
>
> **Si preguntan:** "Es la misma tabla que construye el notebook, guardada para que el tablero no tenga que
> rehacerla. Si cambian los datos o K y k hay que regenerarla; comprobamos que la tabla reconstruida coincide
> con la guardada hasta el decimal 12."

### D50. Repositorios separados e historial limpio · Razonada

Detalle: [cap. 14](14_publicacion_en_github.md).

> **Decisión:** el entregable está en un repositorio público (`pitirringo/futbol-apuestas`: código, datos,
> tablero, reporte) y esta guía en otro, privado. Los mensajes de commit son de una línea. El último commit
> se rehízo con `git commit --amend` y `git push --force-with-lease` para dejar su mensaje en una línea:
> `e3bd43f Correcciones finales` (30-sep-2026).
>
> **Alternativas:**
> - **(a) Guardar la guía en el repositorio público.** En contra: expondría el material de estudio y las
>   respuestas preparadas, y mezclaría el entregable con material interno.
> - **(b) `git push --force`.** En contra: sobrescribe la rama remota sin revisar; si alguien hubiera subido
>   algo en ese momento, se perdería. `--force-with-lease` sólo sobrescribe si la rama remota sigue como la
>   última vez que se descargó.
> - **(c) No reescribir el historial** y dejar el mensaje largo. A favor: lo más seguro. En contra: un
>   historial menos legible.
>
> **Por qué ésta:** quien revisa ve sólo el entregable; reescribir historial publicado es delicado, así que
> se hizo una vez, sobre el último commit y con la opción segura.
>
> **Evidencia en el proyecto:** `git log` del entregable termina en `e3bd43f Correcciones finales`, y la
> publicación posterior funcionó.
>
> **Si preguntan:** "El repositorio público tiene sólo el entregable: código, datos, tablero y reporte; la
> guía de estudio vive aparte. Cuando corregimos el último mensaje de commit usamos `--force-with-lease`, que
> se niega a sobrescribir si alguien más subió cambios."

---

## 19.10 Decisiones que hoy tomaríamos distinto

Reconocer lo que cambiaríamos no debilita el proyecto: muestra que se entiende. La regla para decirlo es
**qué cambiaríamos → por qué (con la cifra) → qué esperamos**.

| # | Qué haríamos distinto | Por qué | Ficha |
|---|---|---|---|
| 1 | **Ampliar la rejilla por debajo de K = 15 y presentar K y k como un ajuste fino**, guardando la tabla de las 35 combinaciones en el repositorio | K quedó en el borde de la rejilla; las 35 combinaciones caben en 0.0055 de LogLoss; el ganador cambia según la temporada; y la comprobación posterior mostró que la configuración anterior (K = 30, k = 10) daba un LogLoss algo menor en validación y en prueba. Decir "K importa poco" es más honesto que presentar K = 15 como "el óptimo" | [D16](#d16-k--15-en-el-elo--probada), [D20](#d20-goles-de-la-temporada-con-shrinkage-y-k--0--probada), [D31](#d31-rejilla-comentada-en-el-notebook-entregado--razonada) |
| 2 | **Calibrar también la ventana y el decaimiento de la forma** | 10 partidos y 0.85 no se optimizaron. Prioridad baja: M1 no mejoró a M0 en prueba | [D21](#d21-forma-reciente-10-partidos-decaimiento-085-y-cruza-temporadas--razonada) |
| 3 | **Corregir los empates con Dixon–Coles o con una Poisson bivariada** | El modelo da 23.6 % a los empates y ocurren 28.2 %; los empates explican +0.0078 de la brecha de +0.0159 con el mercado. Ojo: la binomial negativa, que el tablero también menciona como extensión, no ataca los empates, y con dispersión ≈ 1 casi no cambiaría nada | [D24](#d24-glm-de-poisson--razonada), [D26](#d26-independencia-condicional-y-skellam-exacta--razonada) |
| 4 | **Fijar el protocolo de selección antes de ver la prueba** ("se elige en validación") | Presentar a M0 como "el mejor en prueba" usa la prueba para elegir; con un protocolo previo no habría nada que explicar | [D28](#d28-m0-como-modelo-principal--probada) |
| 5 | **Intervalos que respeten la dependencia entre partidos** (bootstrap por jornada) en los casos al límite | M4 − M0 en validación y M0 − mercado en prueba cambian de lado según el método | [D36](#d36-bootstrap-pareado-por-partidos--razonada) |
| 6 | **Reportar la normalización de Shin como sensibilidad** | No cambia la conclusión (cambia el LogLoss del mercado en la cuarta cifra), pero responde una pregunta previsible | [D35](#d35-mercado-cuotas-promedio-de-apertura-con-normalización-proporcional--probada) |
| 7 | **Usar xG cuando haya cobertura histórica** | Hoy sólo 40 partidos lo tienen | [D9](#d9-no-usar-goles-esperados-xg--razonada) |
| 8 | **Cerrar la fecha final de la prueba** | La prueba no tiene fin: si se actualiza `E0_consolidado.csv`, cambian sus cifras (README §5.3) | [D32](#d32-partición-temporal-1897--380--419--razonada) |
| 9 | **Corregir la tabla de cobertura del notebook de limpieza** | Dice "2026/27--2020/21" para las cuotas promedio; lo correcto es 2019/20–2026/27 (el reporte la trae bien). La causa: la celda toma la **última fila** con cuotas, y como el archivo va de 2026/27 hacia atrás, es el último partido de 2019/20, jugado el 26-jul-2020 por la pausa del COVID; además define la temporada con corte en **julio** (no en agosto, como `wc_predictor.py`), así que ese partido queda etiquetado como 2020/21. Por eso también los rangos salen al revés | [D10](#d10-23-columnas-comunes--11-complementarias--razonada) |
| 10 | **Pulir la ingeniería** | Que la publicación falle si la verificación no da 17 de 17; calcular los datos que quedaron escritos a mano en `index.qmd`; fijar las versiones de `jupyter` y `pyyaml`; en el notebook de limpieza, usar una ruta relativa (hoy `C:/Users/roski/Downloads`), exportar con el nombre que lee el análisis (`E0_consolidado.csv`, no `E0_consolidado_final.csv`) y avisar si falta alguno de los 26 archivos (hoy lo salta sin avisar); y quitar de `wc_predictor.py` el cálculo al importarse de `HOME_FACTOR` y `AWAY_FACTOR`, que el análisis no usa | [D41](#d41-verificación-automática-contra-las-salidas-del-notebook--razonada), [D42](#d42-cifras-del-texto-con-python-y-frases-condicionales--razonada), [D48](#d48-versiones-fijas-y-huellas-sha-256--razonada), [D11](#d11-leer-todos-los-renglones-de-cada-archivo--probada), [D40](#d40-recalcular-todo-desde-los-archivos-del-equipo--razonada) |
| 11 | **Dos comparaciones que faltaron** | Un logit multinomial u ordinal como alternativa al enfoque de goles, y una regresión del resultado contra las probabilidades del modelo **y** del mercado, para ver si el modelo sabe algo que el mercado no | [D1](#d1-modelar-los-goles-de-cada-equipo-y-derivar-el-1x2--razonada), [D2](#d2-el-mercado-es-la-vara-de-comparación-no-una-variable--razonada) |

### Lo que las comprobaciones confirmaron (no lo cambiaríamos)

- **Recuperar los 90 partidos de 2003/04 y 2004/05** casi no movió el modelo: el LogLoss cambia en la quinta
  cifra ([D11](#d11-leer-todos-los-renglones-de-cada-archivo--probada)).
- **El LogLoss como métrica:** Brier y RPS ordenan a los nueve predictores exactamente igual
  ([D33](#d33-logloss-como-métrica-principal-y-mae-como-complemento--razonada)).
- **Skellam exacta:** sumar la matriz o simular daría lo mismo o algo peor
  ([D26](#d26-independencia-condicional-y-skellam-exacta--razonada)).
- **La conclusión frente al mercado no depende de K y k:** con las seis configuraciones revisadas, M0 queda
  entre 0.9809 y 0.9912 en validación (mercado 0.9706) y entre 1.0299 y 1.0351 en prueba (mercado 1.0200)
  ([D16](#d16-k--15-en-el-elo--probada)).
- **Ni de M0 contra M4:** M4 tampoco supera al mercado ([D28](#d28-m0-como-modelo-principal--probada)).
- **Ni del COVID:** sin los partidos a puerta cerrada, el LogLoss de prueba casi no cambia
  ([D38](#d38-sensibilidad-sin-público--probada)).

### Cómo responder "¿qué harían diferente?" en 20 segundos

> "Tres cosas. Primero, corregir los empates con Dixon y Coles, porque el modelo los subestima: les da
> 23.6 % y ocurren 28.2 %. Segundo, fijar desde el principio que el modelo se elige en validación, para no
> usar la prueba al elegir. Y tercero, presentar K y k como lo que resultaron ser, un ajuste fino de efecto
> pequeño, ampliando la búsqueda por debajo de K = 15. Ninguna de las tres cambiaría la conclusión: con lo
> que revisamos, el mercado sigue por delante."

---

## 19.11 Referencias citadas en este capítulo

- Brier, G. W. (1950). Verification of forecasts expressed in terms of probability. *Monthly Weather
  Review*, 78(1), 1–3.
- Constantinou, A. C., & Fenton, N. E. (2012). Solving the problem of inadequate scoring rules for assessing
  probabilistic football forecast models. *Journal of Quantitative Analysis in Sports*, 8(1).
- Diebold, F. X., & Mariano, R. S. (1995). Comparing predictive accuracy. *Journal of Business & Economic
  Statistics*, 13(3), 253–263.
- Dixon, M. J., & Coles, S. G. (1997). Modelling association football scores and inefficiencies in the
  football betting market. *Journal of the Royal Statistical Society: Series C*, 46(2), 265–280.
- Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*. Chapman & Hall.
- Elo, A. E. (1978). *The Rating of Chessplayers, Past and Present*. Arco.
- Football-Data (2026). *Football Results, Statistics and Soccer Betting Odds Data*.
  https://www.football-data.co.uk/data.php (referencia [4] del reporte).
- Foulley, J.-L. (2021). More on verification of probability forecasts for football outcomes: Score
  decompositions, reliability, and discrimination analyses. arXiv:2106.14345 (referencia [3] del reporte).
- Gneiting, T., & Raftery, A. E. (2007). Strictly proper scoring rules, prediction, and estimation.
  *Journal of the American Statistical Association*, 102(477), 359–378.
- Hvattum, L. M., & Arntzen, H. (2010). Using ELO ratings for match result prediction in association
  football. *International Journal of Forecasting*, 26(3), 460–470 (referencia [1] del reporte).
- Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice* (3.ª ed.). OTexts.
- Karlis, D., & Ntzoufras, I. (2003). Analysis of sports data by using bivariate Poisson models. *Journal of
  the Royal Statistical Society: Series D*, 52(3), 381–393.
- Loukas, K., Karapiperis, D., Feretzakis, G., & Verykios, V. S. (2024). Predicting football match results
  using a Poisson regression model. *Applied Sciences*, 14(16), 7230 (referencia [2] del reporte).
- Maher, M. J. (1982). Modelling association football scores. *Statistica Neerlandica*, 36(3), 109–118.
- Shin, H. S. (1993). Measuring the incidence of insider trading in a market for state-contingent claims.
  *The Economic Journal*, 103(420), 1141–1153.
- Štrumbelj, E. (2014). On determining probability forecasts from betting odds. *International Journal of
  Forecasting*, 30(4), 934–943.

[← Hallazgos y pendientes](18_hallazgos_y_pendientes.md) · [Índice](README.md) · [Siguiente: el reporte entregado →](20_el_reporte_entregado.md)
