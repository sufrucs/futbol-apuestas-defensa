# Guía de estudio · Proyecto: Fútbol y mercados de apuestas

- **Dashboard (público):** https://pitirringo.github.io/futbol-apuestas/
- **Repositorio del proyecto (público):** https://github.com/pitirringo/futbol-apuestas (entregable final: commit `e3bd43f`, 30-sep-2026, con `Reporte.pdf`)
- **Exposición:** 1 o 6 de octubre, 18:00–20:00. **5 minutos** + **2 preguntas** que pueden hacerle a **cualquier integrante**, sobre cualquier parte (datos, limpieza, modelo, código, tablero, publicación).

## Contenido

| # | Archivo | Qué cubre | Te prepara para preguntas como… |
|---|---|---|---|
| 1 | [Panorama del proyecto](01_panorama.md) | La historia completa en una página, las dos formas de plantear la pregunta (reporte y tablero), la cadena de archivos y las cifras clave | "Explícanos el proyecto en un minuto" |
| 2 | [Contexto, pregunta y datos](02_contexto_y_datos.md) | Apuestas 1X2, la pregunta y la hipótesis, Football-Data, diccionario de las 34 columnas y de las 24 de la base de modelación, calidad de los datos | "¿De dónde salen los datos? ¿Qué es FTHG?" |
| 3 | [Limpieza de datos](03_limpieza_de_datos.md) | `Limpieza de datos.ipynb` celda por celda (28), con su versión en R, cada decisión y los detalles conocidos | "¿Qué decisiones de limpieza tomaron y por qué?" |
| 4 | [Elo](04_elo.md) | Qué es, fórmula, ejemplos a mano, por qué K = 15 (calibrado) y 400, código en Python y R | "¿Qué es el Elo y cómo lo calcularon?" |
| 5 | [Promedios de la temporada y forma reciente](05_promedios_ajustados_y_forma.md) | *Shrinkage* (calibrado: k = 0) y promedio ponderado (0.85), con ejemplos | "¿Qué es el shrinkage? ¿k = 0 ignora la temporada anterior?" |
| 6 | [Poisson y regresión de Poisson](06_poisson_y_regresion.md) | Distribución de Poisson, GLM, enlace logarítmico, máxima verosimilitud, interpretación de coeficientes | "¿Por qué Poisson? ¿Cómo se interpreta un coeficiente?" |
| 7 | [De goles esperados a probabilidades](07_de_goles_a_probabilidades.md) | Independencia, matriz de marcadores, Skellam, marcador vs resultado más probable | "¿Cómo obtienen P(local), P(empate), P(visita)?" |
| 8 | [Cuotas y mercado](08_cuotas_y_mercado.md) | Cuotas decimales, probabilidad implícita, margen, normalización, calibración, apertura vs cierre | "¿Cómo convierten cuotas en probabilidades?" |
| 9 | [Evaluación y validación](09_evaluacion_y_validacion.md) | Partición temporal, calibración de K y k con ventana creciente, fuga de información, LogLoss, MAE, Brier y RPS, bootstrap, VIF | "¿Por qué LogLoss? ¿Cómo eligieron K y k? ¿Son significativas las diferencias?" |
| 10 | [Código: wc_predictor.py](10_codigo_wc_predictor.md) | Cada constante y función, quién la usa y qué cambió frente a la versión anterior, con su equivalente en R | "¿Qué hace season_stats?" |
| 11 | [Código: Analisis.ipynb](11_codigo_analisis_notebook.md) | Las 26 celdas del notebook explicadas, incluida la calibración (§5), con R | "¿Cómo entrenaron y evaluaron los modelos?" |
| 12 | [Resultados](12_resultados.md) | Todas las tablas y cómo leerlas; qué decir y qué no decir | "¿Cuál es la conclusión?" |
| 13 | [El dashboard: diseño y arquitectura](13_dashboard.md) | Qué debía lograr, principios de diseño, cómo se conectan las piezas | "¿Cómo construyeron la visualización?" |
| 13a | [Código: datos_dashboard.py](13a_codigo_datos_dashboard.md) | El backend función por función: de dónde sale cada cifra del tablero y cómo se verifica contra el notebook | "¿Las cifras del tablero son las del notebook?" |
| 13b | [Código: graficas.py](13b_codigo_graficas.md) | Cada gráfica de Plotly: qué muestra, por qué ese tipo de gráfica y esos colores | "¿Por qué eligieron esa gráfica?" |
| 13c | [Código: index.qmd y estilos](13c_codigo_index_quarto.md) | El documento Quarto chunk por chunk, el simulador en Observable, `_quarto.yml`, estilos y dependencias | "¿Cómo funciona el simulador?" |
| 14 | [Publicación en GitHub](14_publicacion_en_github.md) | Git, GitHub, GitHub Actions y Pages, paso a paso, con cada comando, hasta la versión final | "¿Cómo se publicó? ¿Cómo lo reproduzco?" |
| 15 | [Limitaciones y extensiones](15_limitaciones_y_extensiones.md) | Qué no hace el modelo y cómo se podría mejorar | "¿Cuáles son las limitaciones?" |
| 16 | [Guion de la exposición](16_guion_exposicion.md) | 5 minutos cronometrados, qué mostrar y transiciones | La exposición misma |
| 17 | [Banco de preguntas](17_banco_de_preguntas.md) | 114 preguntas probables con respuesta, para autoevaluarse (las 101–113 y la 64 bis son nuevas: calibración, alternativas, reporte, publicación y el bootstrap del tablero) | Las 2 preguntas del jurado |
| 18 | [Hallazgos y pendientes del equipo](18_hallazgos_y_pendientes.md) | Detalles del código y de los documentos que un evaluador podría notar | — |
| 19 | [Decisiones y alternativas](19_decisiones_y_alternativas.md) | Las 50 decisiones del proyecto: qué alternativas había, por qué se eligió cada una y cuáles se probaron de verdad | "¿Por qué Poisson y no otro modelo? ¿Por qué Quarto?" |
| 20 | [El reporte entregado](20_el_reporte_entregado.md) | `Reporte.pdf` sección por sección, de dónde sale cada cifra y las preguntas que puede provocar | "¿Por qué la hipótesis se cumple sólo en parte?" |
| — | [Glosario](glosario.md) | Todos los términos, en una línea cada uno | — |
| — | [Equivalencias en R](equivalencias_R/README.md) | Seis scripts de R que reproducen el análisis y dan **las mismas cifras** que Python, incluida la calibración completa de K y k | "¿Cómo se haría esto en R?" |
| — | [Archivo](archivo/README.md) | Primeras versiones (`DECISIONES_v1.md`, `GUIA_DEFENSA_v1.md`), ya reemplazadas por los capítulos | — |

## Ruta de estudio sugerida (aprox. 10 horas)

1. **Día 1 (1.5 horas):** capítulos 1, 2, 12 y 20. Con eso ya puedes explicar qué se hizo, qué se encontró y qué dice
   el reporte.
2. **Día 2 (2 horas):** capítulos 4 a 9, la teoría. Lee los ejemplos numéricos con lápiz.
3. **Día 3 (3 horas):** capítulos 3, 10 y 11, el código del modelo, y corre los scripts de `equivalencias_R/`.
4. **Día 4 (2 horas):** capítulos 13, 13a, 13b, 13c y 14, el tablero y la publicación.
5. **Antes de exponer (1.5 horas):** capítulos 19 (al menos su tabla índice), 15, 16 y 17. Tapa las respuestas del
   banco de preguntas y contéstalas en voz alta.

**Si sólo tienes una hora:** capítulo 1, la sección 12.5 ("qué decir y qué no decir"), la tabla índice del
capítulo 19 y la sección 20.6 (preguntas que provoca el reporte).

## Cifras que hay que saber de memoria

| Qué | Cifra |
|---|---|
| Base de datos | 9,540 partidos · 26 temporadas (2001/02 a sep-2026) · 34 columnas (23 comunes a todos los archivos + 11 complementarias) |
| Base de modelación | 2,696 partidos: 1,897 entrenamiento · 380 validación · 419 prueba (se excluyen 4 sin historial de tiros) |
| Parámetros del modelo | Elo con K = 15 y *shrinkage* con k = 0, calibrados por validación temporal (LogLoss promedio 0.959558); forma reciente de 10 partidos con decaimiento 0.85 |
| Resultados históricos | Local 45.6 % · empate 24.7 % · visitante 29.7 % |
| Favorito de las cuotas | Gana 54.2 % de las veces |
| Localía en Elo | ≈ 50 puntos |
| LogLoss en prueba | M0 **1.033** · mercado **1.020** · referencia ingenua 1.087 · azar 1.099 |
| LogLoss en validación | M4 0.979 (el mejor de los modelos) · M0 0.990 · mercado 0.971 |
| Aciertos en prueba | M0 **48.0 %** · mercado 48.9 % · "siempre local" 41.5 % |
| Parte de la ventaja del mercado que logra M0 | **80 %** (prueba) · 83 % (validación) |
| Brecha M0 − mercado | +0.016 con validación + prueba (IC 95 %: +0.006 a +0.025): pequeña pero real |
| Ejemplo | Arsenal–Man City: 43.7 % / 25.0 % / 31.4 %, marcador más probable 1–1 |
| Verificación del tablero | 17 de 17 cifras coinciden con las salidas guardadas del notebook |

```r
# desde la carpeta de este repositorio, en este orden (el 03 usa un archivo que genera el 02)
source("equivalencias_R/01_elo.R")
source("equivalencias_R/02_modelo_poisson.R")
source("equivalencias_R/03_mercado.R")
source("equivalencias_R/04_grafica_resumen.R")
source("equivalencias_R/05_variables_previas.R")
source("equivalencias_R/06_calibracion.R")
```
