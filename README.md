# Guía de estudio · Proyecto: Fútbol y mercados de apuestas

- **Dashboard (público):** https://pitirringo.github.io/futbol-apuestas/
- **Repositorio del proyecto (público):** https://github.com/pitirringo/futbol-apuestas
- **Exposición:** 1 o 6 de octubre, 18:00–20:00. **5 minutos** + **2 preguntas** que pueden hacerle a **cualquier integrante**, sobre cualquier parte (datos, limpieza, modelo, código, tablero, publicación).

## Contenido

| # | Archivo | Qué cubre | Te prepara para preguntas como… |
|---|---|---|---|
| 1 | [Panorama del proyecto](01_panorama.md) | La historia completa en una página, el flujo de trabajo y las cifras clave | "Explícanos el proyecto en un minuto" |
| 2 | [Contexto, pregunta y datos](02_contexto_y_datos.md) | Apuestas 1X2, la pregunta y la hipótesis, Football-Data, diccionario de variables, calidad de los datos | "¿De dónde salen los datos? ¿Qué es FTHG?" |
| 3 | [Limpieza de datos](03_limpieza_de_datos.md) | El notebook de limpieza línea por línea, con su versión en R | "¿Qué decisiones de limpieza tomaron y por qué?" |
| 4 | [Elo](04_elo.md) | Qué es, fórmula, ejemplo a mano, por qué K = 30 y 400, código en Python y R | "¿Qué es el Elo y cómo lo calcularon?" |
| 5 | [Promedios ajustados y forma reciente](05_promedios_ajustados_y_forma.md) | *Shrinkage* (k = 10) y promedio ponderado (0.85) explicados con ejemplos | "¿Qué es el shrinkage?" |
| 6 | [Poisson y regresión de Poisson](06_poisson_y_regresion.md) | Distribución de Poisson, GLM, enlace logarítmico, máxima verosimilitud, interpretación de coeficientes | "¿Por qué Poisson? ¿Cómo se interpreta un coeficiente?" |
| 7 | [De goles esperados a probabilidades](07_de_goles_a_probabilidades.md) | Independencia, matriz de marcadores, Skellam, marcador vs resultado más probable | "¿Cómo obtienen P(local), P(empate), P(visita)?" |
| 8 | [Cuotas y mercado](08_cuotas_y_mercado.md) | Cuotas decimales, probabilidad implícita, margen, normalización, calibración, apertura vs cierre | "¿Cómo convierten cuotas en probabilidades?" |
| 9 | [Evaluación y validación](09_evaluacion_y_validacion.md) | Partición temporal, fuga de información, LogLoss, MAE, aciertos, referencia ingenua, bootstrap, VIF | "¿Por qué LogLoss? ¿Son significativas las diferencias?" |
| 10 | [Código: wc_predictor.py](10_codigo_wc_predictor.md) | Cada función explicada, qué se usa y qué no, equivalente en R | "¿Qué hace season_stats?" |
| 11 | [Código: Analisis.ipynb](11_codigo_analisis_notebook.md) | Cada sección del notebook explicada, equivalente en R | "¿Cómo entrenaron y evaluaron los modelos?" |
| 12 | [Resultados](12_resultados.md) | Todas las tablas y cómo leerlas; qué decir y qué no decir | "¿Cuál es la conclusión?" |
| 13 | [El dashboard](13_dashboard.md) | Diseño (storytelling, indicadores, color) y código (Quarto, Plotly, OJS), con equivalentes en R/Flexdashboard | "¿Cómo construyeron la visualización?" |
| 14 | [Publicación en GitHub](14_publicacion_en_github.md) | Todo el proceso de Git, GitHub, GitHub Actions y Pages, paso a paso, con cada comando | "¿Cómo se publicó? ¿Cómo lo reproduzco?" |
| 15 | [Limitaciones y extensiones](15_limitaciones_y_extensiones.md) | Qué no hace el modelo y cómo se podría mejorar | "¿Cuáles son las limitaciones?" |
| 16 | [Guion de la exposición](16_guion_exposicion.md) | 5 minutos cronometrados, qué mostrar y transiciones | La exposición misma |
| 17 | [Banco de preguntas](17_banco_de_preguntas.md) | 100 preguntas probables con respuesta, para autoevaluarse | Las 2 preguntas del jurado |
| 18 | [Hallazgos y pendientes del equipo](18_hallazgos_y_pendientes.md) | Detalles del código y del reporte por corregir antes del 28 de septiembre | — |
| — | [Glosario](glosario.md) | Todos los términos, en una línea cada uno | — |
| — | [Equivalencias en R](equivalencias_R/README.md) | Scripts de R que reproducen el análisis y dan **las mismas cifras** que Python | "¿Cómo se haría esto en R?" |
| — | [Archivo](archivo/README.md) | Primeras versiones (`DECISIONES_v1.md`, `GUIA_DEFENSA_v1.md`), ya reemplazadas por los capítulos | — |

## Ruta de estudio sugerida (aprox. 6 horas)

1. **Día 1 (1 hora):** capítulos 1, 2 y 12. Con eso ya puedes explicar qué se hizo y qué se encontró.
2. **Día 2 (2 horas):** capítulos 4 a 9, la teoría. Lee los ejemplos numéricos con lápiz.
3. **Día 3 (2 horas):** capítulos 3, 10 y 11, el código, y corre los scripts de `equivalencias_R/`.
4. **Día 4 (1 hora):** capítulos 13 y 14, el tablero y la publicación.
5. **Antes de exponer:** capítulos 15, 16 y 17. Tapa las respuestas del banco de preguntas y contéstalas en voz alta.

## Cifras que hay que saber de memoria

| Qué | Cifra |
|---|---|
| Base de datos | 9,450 partidos · 26 temporadas (2001/02 a sep-2026) · 33 variables |
| Base de modelación | 2,696 partidos: 1,897 entrenamiento · 380 validación · 419 prueba |
| Resultados históricos | Local 45.6 % · empate 24.7 % · visitante 29.8 % |
| Favorito de las cuotas | Gana 54.3 % de las veces |
| Localía en Elo | ≈ 60 puntos |
| LogLoss en prueba | M0 **1.031** · mercado **1.020** · referencia ingenua 1.087 · azar 1.099 |
| Aciertos en prueba | M0 **48.0 %** · mercado 48.9 % · "siempre local" 41.5 % |
| Parte de la ventaja del mercado que logra M0 | **84 %** (prueba) · 88 % (validación) |
| Brecha M0 − mercado | +0.012 con validación + prueba (IC 95 %: +0.002 a +0.022): pequeña pero real |
| Ejemplo | Arsenal–Man City: 45.8 % / 25.0 % / 29.3 %, marcador más probable 1–1 |




```r
# desde la carpeta de este repositorio, en este orden (el 03 usa un archivo que genera el 02)
source("equivalencias_R/01_elo.R")
source("equivalencias_R/02_modelo_poisson.R")
source("equivalencias_R/03_mercado.R")
source("equivalencias_R/04_grafica_resumen.R")
source("equivalencias_R/05_variables_previas.R")
```


