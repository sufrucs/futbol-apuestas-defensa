# Glosario

[← Índice](README.md)

Cada término en una línea, con el capítulo donde se explica a fondo.

## Fútbol, apuestas y datos

| Término | Qué es | Cap. |
|---|---|---|
| **1X2** | Las tres opciones de resultado: 1 = gana el local, X = empate, 2 = gana el visitante | [2](02_contexto_y_datos.md) |
| **Apertura (cuotas de)** | Cuotas promedio (`Avg`) que Football-Data registra el viernes por la tarde (partidos de fin de semana) o el martes (entre semana) | [8](08_cuotas_y_mercado.md) |
| **Ascendido** | Equipo que sube de la segunda división (Championship); no tiene temporada anterior en Premier | [5](05_promedios_ajustados_y_forma.md) |
| **Calibración** | Que, cuando se dice 70 %, el evento ocurra ≈ 70 % de las veces | [8](08_cuotas_y_mercado.md), [9](09_evaluacion_y_validacion.md) |
| **Cierre (cuotas de)** | Últimas cuotas antes del partido (`AvgC`); incorporan más información que las de apertura | [8](08_cuotas_y_mercado.md) |
| **Cuota decimal** | Pago por cada peso apostado si se acierta, incluido el peso; 2.50 paga 2.50 | [8](08_cuotas_y_mercado.md) |
| **E0** | Código de Football-Data para la Premier League (E = Inglaterra, 0 = primera división) | [2](02_contexto_y_datos.md) |
| **Favorito** | El resultado con la cuota más baja (la mayor probabilidad implícita) | [8](08_cuotas_y_mercado.md) |
| **Football-Data.co.uk** | Sitio con resultados, estadísticas y cuotas de ligas europeas, en CSV por temporada | [2](02_contexto_y_datos.md) |
| **FTHG / FTAG / FTR** | Goles del local / del visitante / resultado final (H, D, A) | [2](02_contexto_y_datos.md) |
| **HS / HST** | Tiros / tiros a puerta del local (AS y AST, del visitante) | [2](02_contexto_y_datos.md) |
| **Localía** | Ventaja de jugar en casa: el local gana 45.6 % de los partidos, contra 29.8 % del visitante | [12](12_resultados.md) |
| **Margen (*overround*)** | Lo que las probabilidades brutas (1/cuota) suman por encima de 100 %; la ganancia esperada de la casa (≈ 5 %) | [8](08_cuotas_y_mercado.md) |
| **Mercado** | En este proyecto, las probabilidades implícitas en las cuotas promedio, normalizadas | [8](08_cuotas_y_mercado.md) |
| **Normalización proporcional** | Dividir cada probabilidad bruta entre la suma de las tres para que sumen 100 % | [8](08_cuotas_y_mercado.md) |
| **Probabilidad implícita** | 1 / cuota: la probabilidad que la cuota asigna a un resultado | [8](08_cuotas_y_mercado.md) |
| **Puerta cerrada** | Partidos sin público (pandemia, 2020–2021); 472 en la base | [12](12_resultados.md) |
| **Sesgo favorito–sorpresa** | Tendencia a que las sorpresas estén sobrevaloradas en las cuotas | [8](08_cuotas_y_mercado.md) |
| **xG (goles esperados)** | Estadística que mide la calidad de las ocasiones; en la base solo existe para 2026/27 | [2](02_contexto_y_datos.md) |

## Variables del modelo

| Término | Qué es | Cap. |
|---|---|---|
| **Decaimiento (0.85)** | Factor con el que pierde peso cada partido hacia atrás en la forma reciente | [5](05_promedios_ajustados_y_forma.md) |
| **Diferencia de Elo (D)** | (Elo local − Elo visitante) / 400; la variable más importante del modelo | [4](04_elo.md) |
| **Elo** | Rating de fuerza: empieza en 1,500 y se ajusta tras cada partido según lo inesperado del resultado | [4](04_elo.md) |
| **Forma reciente** | Promedio ponderado de los últimos 10 partidos, con más peso a los recientes | [5](05_promedios_ajustados_y_forma.md) |
| **Goles ajustados (GF, GA)** | Goles a favor y en contra por partido, con *shrinkage* hacia la temporada anterior | [5](05_promedios_ajustados_y_forma.md) |
| **K (Elo) = 30** | Cuántos puntos se mueve el Elo por partido | [4](04_elo.md) |
| **k (shrinkage) = 10** | Cuántos "partidos de la temporada anterior" se mezclan con los actuales | [5](05_promedios_ajustados_y_forma.md) |
| **Resultado esperado (Elo)** | $1/(1 + 10^{(R_B - R_A)/400})$: probabilidad "de ganar" según los ratings | [4](04_elo.md) |
| ***Shrinkage*** | Contraer un promedio ruidoso (pocos partidos) hacia un valor previo más estable | [5](05_promedios_ajustados_y_forma.md) |
| **Variable previa al partido** | Calculada solo con partidos de fechas anteriores; condición para no usar el futuro | [9](09_evaluacion_y_validacion.md) |

## Estadística y modelo

| Término | Qué es | Cap. |
|---|---|---|
| **Bootstrap** | Remuestrear los partidos con reemplazo (10,000 veces) para medir la incertidumbre de una diferencia | [9](09_evaluacion_y_validacion.md) |
| **Coeficiente (β)** | Efecto de una variable en log λ; $e^{\beta}$ es el factor multiplicativo sobre los goles esperados | [6](06_poisson_y_regresion.md) |
| **Dispersión de Pearson** | Suma de residuos de Pearson al cuadrado entre grados de libertad; ≈ 1 si se cumple Poisson (0.99 y 1.04) | [6](06_poisson_y_regresion.md) |
| **Dixon–Coles** | Corrección (1997) de las probabilidades de 0–0, 1–0, 0–1 y 1–1; extensión propuesta | [7](07_de_goles_a_probabilidades.md) |
| **Efecto estandarizado** | Cambio en los goles esperados al subir una variable una desviación estándar | [6](06_poisson_y_regresion.md) |
| **Enlace logarítmico** | log λ = Xβ: asegura λ > 0 y efectos multiplicativos | [6](06_poisson_y_regresion.md) |
| **Especificación** | Una versión del modelo con cierto conjunto de variables (M0 a M4) | [11](11_codigo_analisis_notebook.md) |
| **GLM** | Modelo lineal generalizado: distribución + predictor lineal + función de enlace | [6](06_poisson_y_regresion.md) |
| **Goles esperados (λ)** | Media de la Poisson de cada equipo en un partido; lo que predicen las regresiones | [6](06_poisson_y_regresion.md) |
| **IC 95 %** | Intervalo de confianza: rango plausible de un valor; si una diferencia no lo cruza en cero, es distinguible del azar | [9](09_evaluacion_y_validacion.md) |
| **Independencia condicional** | Supuesto de que, dadas las variables, los goles de un equipo no dependen de los del otro | [7](07_de_goles_a_probabilidades.md) |
| **Intercepto** | Término constante de cada ecuación; en este modelo absorbe la ventaja de local | [6](06_poisson_y_regresion.md) |
| **IRLS** | Algoritmo iterativo con el que `statsmodels` y `glm()` estiman un GLM | [6](06_poisson_y_regresion.md) |
| **M0 … M4** | M0 base (Elo y goles ajustados), M1 + forma, M2 + tiros, M3 + tiros a puerta, M4 completo | [11](11_codigo_analisis_notebook.md) |
| **Marcador más probable** | La celda de mayor probabilidad de la matriz de marcadores (p. ej., 1–1); no es lo mismo que el resultado más probable | [7](07_de_goles_a_probabilidades.md) |
| **Matriz de marcadores** | Tabla con la probabilidad de cada marcador exacto (0–0, 1–0, …) | [7](07_de_goles_a_probabilidades.md) |
| **Máxima verosimilitud** | Estimar los coeficientes que hacen más probables los datos observados | [6](06_poisson_y_regresion.md) |
| **Multicolinealidad** | Variables explicativas muy correlacionadas; vuelve inestables los coeficientes, no las predicciones | [9](09_evaluacion_y_validacion.md) |
| **Parsimonia** | Preferir el modelo más simple cuando el desempeño es equivalente | [12](12_resultados.md) |
| **Poisson (distribución)** | Modelo de conteos con media = varianza = λ | [6](06_poisson_y_regresion.md) |
| **Regresión de Poisson** | GLM con distribución Poisson y enlace logarítmico | [6](06_poisson_y_regresion.md) |
| **Semilla (*seed*)** | Número que fija los aleatorios para que el resultado se repita (aquí, 2026) | [9](09_evaluacion_y_validacion.md) |
| **Skellam** | Distribución de la diferencia de dos Poisson independientes; da P(local), P(empate), P(visita) | [7](07_de_goles_a_probabilidades.md) |
| **Sobredispersión** | Varianza mayor que la media; se trataría con binomial negativa (aquí no hace falta) | [6](06_poisson_y_regresion.md) |
| **Sobreajuste** | Cuando un modelo aprende ruido del entrenamiento o la validación y no generaliza (M4) | [12](12_resultados.md) |
| **VIF** | Factor de inflación de la varianza, 1/(1 − R²); mide multicolinealidad (máximo 5.5 en M4) | [9](09_evaluacion_y_validacion.md) |

## Evaluación

| Término | Qué es | Cap. |
|---|---|---|
| **Aciertos** | % de partidos en los que el resultado más probable ocurrió | [9](09_evaluacion_y_validacion.md) |
| **Brier score** | Error cuadrático medio de las probabilidades; alternativa al LogLoss | [9](09_evaluacion_y_validacion.md) |
| **Entrenamiento / validación / prueba** | 2019/20–2023/24 (1,897) / 2024/25 (380) / 15-ago-2025 a 14-sep-2026 (419) | [9](09_evaluacion_y_validacion.md) |
| **Fuga de información** | Usar información que no existía al momento de predecir; da resultados optimistas | [9](09_evaluacion_y_validacion.md) |
| **LogLoss** | −promedio de log(probabilidad asignada a lo que ocurrió); métrica principal, menor es mejor | [9](09_evaluacion_y_validacion.md) |
| **MAE** | Error absoluto medio entre goles reales y esperados | [9](09_evaluacion_y_validacion.md) |
| **Partición temporal** | Dividir por fechas: entrenar con el pasado, evaluar con el futuro | [9](09_evaluacion_y_validacion.md) |
| **Probabilidad media al resultado real** | $e^{-\text{LogLoss}}$: traducción intuitiva del LogLoss (M0 35.7 %, mercado 36.1 %) | [9](09_evaluacion_y_validacion.md) |
| **Referencia ingenua** | Poisson con los goles promedio del entrenamiento, igual para todos los partidos | [9](09_evaluacion_y_validacion.md) |
| **Regla de puntuación propia** | Métrica que se optimiza reportando las probabilidades verdaderas (el LogLoss lo es) | [9](09_evaluacion_y_validacion.md) |
| **RPS** | *Ranked probability score*: considera que local > empate > visita es un orden | [9](09_evaluacion_y_validacion.md) |

## Tablero

| Término | Qué es | Cap. |
|---|---|---|
| **Card (tarjeta)** | Caja del tablero con título y contenido | [13](13_dashboard.md) |
| **Dumbbell (pesas)** | Gráfica con dos puntos unidos por una línea para comparar dos periodos | [13](13_dashboard.md) |
| **Flexdashboard** | Paquete de R para tableros con R Markdown, visto en el módulo | [13](13_dashboard.md) |
| **Inline code (código en línea)** | `` `{python} expr` ``: un número calculado dentro del texto | [13](13_dashboard.md) |
| **Observable JS (OJS)** | JavaScript reactivo que Quarto ejecuta en el navegador; se usa en el simulador | [13](13_dashboard.md) |
| **Plotly** | Biblioteca de gráficas interactivas (Python, R y JavaScript) | [13](13_dashboard.md) |
| **Quarto** | Sistema de publicación de Posit, sucesor de R Markdown; genera documentos, sitios y tableros | [13](13_dashboard.md) |
| **SCSS / Sass** | CSS con variables; define el tema visual (`estilos.scss`) | [13](13_dashboard.md) |
| **Storytelling** | Contar los datos como historia: inicio, conflicto y resolución | [13](13_dashboard.md) |
| **Tabset** | Grupo de pestañas para información de segundo nivel | [13](13_dashboard.md) |
| **Value box** | Indicador destacado (número grande con título y contexto) | [13](13_dashboard.md) |

## Git y GitHub

| Término | Qué es | Cap. |
|---|---|---|
| **Artifact** | Archivos que un *job* entrega a otro (la carpeta `_site`) | [14](14_publicacion_en_github.md) |
| **Branch (rama)** | Línea de historial; la principal es `main` | [14](14_publicacion_en_github.md) |
| **Clone** | Descargar un repositorio con todo su historial | [14](14_publicacion_en_github.md) |
| **Collaborator** | Persona invitada con permiso de ver y editar un repositorio | [14](14_publicacion_en_github.md) |
| **Commit** | Versión guardada del proyecto con autor, fecha, mensaje y *hash* | [14](14_publicacion_en_github.md) |
| **Force push** | Push que reemplaza el historial remoto; irreversible del lado de GitHub | [14](14_publicacion_en_github.md) |
| **`.gitignore`** | Lista de archivos que Git no debe incluir | [14](14_publicacion_en_github.md) |
| **Git Credential Manager** | Programa que hace el inicio de sesión en GitHub por el navegador y guarda el token | [14](14_publicacion_en_github.md) |
| **GitHub Actions** | Servicio que ejecuta flujos automáticos (aquí, construir y publicar el tablero) | [14](14_publicacion_en_github.md) |
| **GitHub Pages** | Servicio que publica sitios estáticos en `usuario.github.io/repositorio` | [14](14_publicacion_en_github.md) |
| **Hash** | Identificador de un commit (p. ej., `8b1fc83`) | [14](14_publicacion_en_github.md) |
| **Job** | Conjunto de pasos de un flujo (`build` y `deploy`) | [14](14_publicacion_en_github.md) |
| **Orphan branch** | Rama nueva sin historial previo; se usó para rehacer el historial público | [14](14_publicacion_en_github.md) |
| **origin** | Apodo convencional del repositorio remoto en GitHub | [14](14_publicacion_en_github.md) |
| **PAT** | *Personal access token*: token de GitHub que sustituye a la contraseña (visto en clase con `gitcreds`) | [14](14_publicacion_en_github.md) |
| **Pull / push** | Traer / subir commits del remoto | [14](14_publicacion_en_github.md) |
| **Repositorio** | Carpeta cuyo historial controla Git | [14](14_publicacion_en_github.md) |
| **Runner** | Máquina virtual (Ubuntu) donde GitHub ejecuta el flujo | [14](14_publicacion_en_github.md) |
| **Staging (área de preparación)** | Cambios elegidos con `git add` para el próximo commit | [14](14_publicacion_en_github.md) |
| **Upstream** | Rama remota ligada a la local (`-u`), para que baste `git push` | [14](14_publicacion_en_github.md) |
| **Workflow** | Archivo YAML en `.github/workflows/` con los pasos automáticos | [14](14_publicacion_en_github.md) |
