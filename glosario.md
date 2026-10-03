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
| **Columnas comunes / complementarias** | Las 23 columnas presentes en los 26 archivos y las 11 que sólo existen en algunas temporadas (cuotas y xG); juntas, las 34 de la base | [3](03_limpieza_de_datos.md) |
| **Cuota decimal** | Pago por cada peso apostado si se acierta, incluido el peso; 2.50 paga 2.50 | [8](08_cuotas_y_mercado.md) |
| **Div** | Columna con el código de la división (siempre `E0`); es la columna 34, que la versión anterior de la base no tenía | [2](02_contexto_y_datos.md) |
| **E0** | Código de Football-Data para la Premier League (E = Inglaterra, 0 = primera división) | [2](02_contexto_y_datos.md) |
| **Favorito** | El resultado con la cuota más baja (la mayor probabilidad implícita) | [8](08_cuotas_y_mercado.md) |
| **Football-Data.co.uk** | Sitio con resultados, estadísticas y cuotas de ligas europeas, en CSV por temporada | [2](02_contexto_y_datos.md) |
| **FTHG / FTAG / FTR** | Goles del local / del visitante / resultado final (H, D, A) | [2](02_contexto_y_datos.md) |
| **HS / HST** | Tiros / tiros a puerta del local (AS y AST, del visitante) | [2](02_contexto_y_datos.md) |
| **Localía** | Ventaja de jugar en casa: el local gana 45.6 % de los partidos, contra 29.7 % del visitante; equivale a ≈ 50 puntos de Elo | [12](12_resultados.md) |
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
| **Escala (400)** | Divisor de la fórmula del Elo: con 400 puntos de diferencia, el resultado esperado es 10 a 1; también divide `elo_diff` al entrar al modelo | [4](04_elo.md) |
| **Forma reciente** | Promedio ponderado de los últimos 10 partidos, con más peso a los recientes | [5](05_promedios_ajustados_y_forma.md) |
| **Goles de la temporada (GF, GA)** | Goles a favor y en contra por partido en la temporada en curso; antes del primer partido, los de la temporada anterior (o el promedio de la liga para un ascendido). Antes se llamaban "goles ajustados" | [5](05_promedios_ajustados_y_forma.md) |
| **K (Elo) = 15** | Cuántos puntos se mueve el Elo por partido; calibrado por validación temporal (la versión anterior usaba 30) | [4](04_elo.md) |
| **k (shrinkage) = 0** | Peso de la temporada anterior, en "partidos equivalentes"; calibrado en 0: desde el primer partido de la temporada sólo cuenta la temporada en curso (la versión anterior usaba 10) | [5](05_promedios_ajustados_y_forma.md) |
| **Resultado esperado (Elo)** | $1/(1 + 10^{(R_B - R_A)/400})$: probabilidad "de ganar" según los ratings | [4](04_elo.md) |
| ***Shrinkage*** | Contraer un promedio ruidoso (pocos partidos) hacia un valor previo más estable | [5](05_promedios_ajustados_y_forma.md) |
| **Variable previa al partido** | Calculada solo con partidos de fechas anteriores; condición para no usar el futuro | [9](09_evaluacion_y_validacion.md) |

## Estadística y modelo

| Término | Qué es | Cap. |
|---|---|---|
| **Binomial negativa** | Alternativa a Poisson cuando la varianza es mayor que la media; aquí no hace falta (dispersión ≈ 1) | [19](19_decisiones_y_alternativas.md) |
| **Bootstrap** | Remuestrear los partidos con reemplazo (10,000 veces) para medir la incertidumbre de una diferencia; es pareado porque las dos predicciones se comparan en los mismos partidos | [9](09_evaluacion_y_validacion.md) |
| **Calibración de hiperparámetros** | Elegir K y k probando una rejilla de valores con validación temporal y quedándose con el menor LogLoss | [9](09_evaluacion_y_validacion.md), [11](11_codigo_analisis_notebook.md) |
| **Coeficiente (β)** | Efecto de una variable en log λ; $e^{\beta}$ es el factor multiplicativo sobre los goles esperados | [6](06_poisson_y_regresion.md) |
| **Dispersión de Pearson** | Suma de residuos de Pearson al cuadrado entre grados de libertad; ≈ 1 si se cumple Poisson (0.996 y 1.036) | [6](06_poisson_y_regresion.md) |
| **Dixon–Coles** | Corrección (1997) de las probabilidades de 0–0, 1–0, 0–1 y 1–1; extensión propuesta | [7](07_de_goles_a_probabilidades.md) |
| **Efecto estandarizado** | Cambio en los goles esperados al subir una variable una desviación estándar | [6](06_poisson_y_regresion.md) |
| **Enlace logarítmico** | log λ = Xβ: asegura λ > 0 y efectos multiplicativos | [6](06_poisson_y_regresion.md) |
| **Especificación** | Una versión del modelo con cierto conjunto de variables (M0 a M4) | [11](11_codigo_analisis_notebook.md) |
| **GLM** | Modelo lineal generalizado: distribución + predictor lineal + función de enlace | [6](06_poisson_y_regresion.md) |
| **Goles esperados (λ)** | Media de la Poisson de cada equipo en un partido; lo que predicen las regresiones | [6](06_poisson_y_regresion.md) |
| **Hiperparámetro** | Valor que el GLM no estima y se fija antes de ajustarlo: K, k, la ventana de 10 partidos y el decaimiento 0.85 | [9](09_evaluacion_y_validacion.md) |
| **IC 95 %** | Intervalo de confianza: rango plausible de un valor; si una diferencia no lo cruza en cero, es distinguible del azar | [9](09_evaluacion_y_validacion.md) |
| **Independencia condicional** | Supuesto de que, dadas las variables, los goles de un equipo no dependen de los del otro | [7](07_de_goles_a_probabilidades.md) |
| **Intercepto** | Término constante de cada ecuación; en este modelo absorbe la ventaja de local | [6](06_poisson_y_regresion.md) |
| **IRLS** | Algoritmo iterativo con el que `statsmodels` y `glm()` estiman un GLM | [6](06_poisson_y_regresion.md) |
| **M0 … M4** | M0 base (Elo y goles de la temporada), M1 + forma, M2 + tiros, M3 + tiros a puerta, M4 completo | [11](11_codigo_analisis_notebook.md) |
| **Marcador más probable** | La celda de mayor probabilidad de la matriz de marcadores (p. ej., 1–1); no es lo mismo que el resultado más probable | [7](07_de_goles_a_probabilidades.md) |
| **Matriz de marcadores** | Tabla con la probabilidad de cada marcador exacto (0–0, 1–0, …) | [7](07_de_goles_a_probabilidades.md) |
| **Máxima verosimilitud** | Estimar los coeficientes que hacen más probables los datos observados | [6](06_poisson_y_regresion.md) |
| **Multicolinealidad** | Variables explicativas muy correlacionadas; vuelve inestables los coeficientes, no las predicciones | [9](09_evaluacion_y_validacion.md) |
| **Parsimonia** | Preferir el modelo más simple cuando el desempeño es equivalente | [12](12_resultados.md) |
| **Poisson (distribución)** | Modelo de conteos con media = varianza = λ | [6](06_poisson_y_regresion.md) |
| **Poisson bivariada** | Modelo que permite correlación entre los goles de los dos equipos; alternativa a la independencia | [19](19_decisiones_y_alternativas.md) |
| **Regresión de Poisson** | GLM con distribución Poisson y enlace logarítmico | [6](06_poisson_y_regresion.md) |
| **Rejilla (*grid*)** | Conjunto de combinaciones que se prueban al calibrar: 7 valores de K × 5 de k = 35 | [9](09_evaluacion_y_validacion.md) |
| **Semilla (*seed*)** | Número que fija los aleatorios para que el resultado se repita (aquí, 2026) | [9](09_evaluacion_y_validacion.md) |
| **Skellam** | Distribución de la diferencia de dos Poisson independientes; da P(local), P(empate), P(visita) | [7](07_de_goles_a_probabilidades.md) |
| **Sobredispersión** | Varianza mayor que la media; se trataría con binomial negativa (aquí no hace falta) | [6](06_poisson_y_regresion.md) |
| **Sobreajuste** | Cuando un modelo aprende ruido del entrenamiento o la validación y no generaliza (M4) | [12](12_resultados.md) |
| **VIF** | Factor de inflación de la varianza, 1/(1 − R²); mide multicolinealidad (máximo 5.56 en M4; en M0, todos menores que 1.7) | [9](09_evaluacion_y_validacion.md) |

## Evaluación

| Término | Qué es | Cap. |
|---|---|---|
| **Aciertos** | % de partidos en los que el resultado más probable ocurrió | [9](09_evaluacion_y_validacion.md) |
| **Brier score** | Error cuadrático medio de las probabilidades; alternativa al LogLoss (ordena los predictores igual) | [9](09_evaluacion_y_validacion.md) |
| **Diebold–Mariano** | Prueba estadística para comparar dos pronósticos; alternativa al bootstrap | [9](09_evaluacion_y_validacion.md) |
| **Elegir mirando la prueba** | Escoger un modelo o un parámetro por su resultado en prueba; la prueba deja de ser una evaluación honesta (*data snooping*) | [9](09_evaluacion_y_validacion.md) |
| **Entrenamiento / validación / prueba** | 2019/20–2023/24 (1,897) / 2024/25 (380) / 15-ago-2025 a 14-sep-2026 (419) | [9](09_evaluacion_y_validacion.md) |
| **Fracción de la mejora** | (LogLoss ingenua − LogLoss modelo) / (LogLoss ingenua − LogLoss mercado): parte de la ventaja del mercado que logra el modelo (80 % en prueba) | [12](12_resultados.md) |
| **Fuga de información** | Usar información que no existía al momento de predecir; da resultados optimistas | [9](09_evaluacion_y_validacion.md) |
| **LogLoss** | −promedio de log(probabilidad asignada a lo que ocurrió); métrica principal, menor es mejor | [9](09_evaluacion_y_validacion.md) |
| **MAE** | Error absoluto medio entre goles reales y esperados | [9](09_evaluacion_y_validacion.md) |
| **Partición temporal** | Dividir por fechas: entrenar con el pasado, evaluar con el futuro | [9](09_evaluacion_y_validacion.md) |
| **Pliegue (*fold*)** | Cada una de las evaluaciones de la validación temporal: 2021/22, 2022/23 y 2023/24 | [9](09_evaluacion_y_validacion.md) |
| **Probabilidad media al resultado real** | $e^{-\text{LogLoss}}$: traducción intuitiva del LogLoss (M0 35.6 %, mercado 36.1 % en prueba) | [9](09_evaluacion_y_validacion.md) |
| **Referencia ingenua** | Poisson con los goles promedio del entrenamiento, igual para todos los partidos | [9](09_evaluacion_y_validacion.md) |
| **Regla de puntuación propia** | Métrica que se optimiza reportando las probabilidades verdaderas (el LogLoss lo es) | [9](09_evaluacion_y_validacion.md) |
| **RPS** | *Ranked probability score*: considera que local > empate > visita es un orden | [9](09_evaluacion_y_validacion.md) |
| **Shin (método de)** | Forma alternativa de quitar el margen de las cuotas; con ella el mercado da 0.970635 / 1.020971 de LogLoss, casi lo mismo | [8](08_cuotas_y_mercado.md) |
| **Validación temporal de ventana creciente** | *Expanding window*: entrenar con todo lo anterior a una temporada, evaluar en ella y repetir hacia adelante; así se calibraron K y k | [9](09_evaluacion_y_validacion.md) |

## Tablero

| Término | Qué es | Cap. |
|---|---|---|
| **Card (tarjeta)** | Caja del tablero con título y contenido | [13](13_dashboard.md) |
| **Dumbbell (pesas)** | Gráfica con dos puntos unidos por una línea para comparar dos periodos | [13](13_dashboard.md) |
| **Flexdashboard** | Paquete de R para tableros con R Markdown, visto en el módulo | [13](13_dashboard.md) |
| **Inline code (código en línea)** | `` `{python} expr` ``: un número calculado dentro del texto | [13c](13c_codigo_index_quarto.md) |
| **Observable JS (OJS)** | JavaScript reactivo que Quarto ejecuta en el navegador; se usa en el simulador | [13c](13c_codigo_index_quarto.md) |
| **`ojs_define`** | Función de Quarto que pasa datos de Python a Observable (los 380 cruces del simulador) | [13c](13c_codigo_index_quarto.md) |
| **Plotly** | Biblioteca de gráficas interactivas (Python, R y JavaScript) | [13](13_dashboard.md) |
| **Quarto** | Sistema de publicación de Posit, sucesor de R Markdown; genera documentos, sitios y tableros | [13](13_dashboard.md) |
| **SCSS / Sass** | CSS con variables; define el tema visual (`estilos.scss`) | [13](13_dashboard.md) |
| **Storytelling** | Contar los datos como historia: inicio, conflicto y resolución | [13](13_dashboard.md) |
| **Tabset** | Grupo de pestañas para información de segundo nivel | [13](13_dashboard.md) |
| **Value box** | Indicador destacado (número grande con título y contexto) | [13](13_dashboard.md) |
| **Verificación (tabla de)** | Tarjeta del tablero que compara 17 cifras con las salidas guardadas del notebook; si alguna no coincide avisa "HAY DIFERENCIAS" | [13a](13a_codigo_datos_dashboard.md) |

## Git y GitHub

| Término | Qué es | Cap. |
|---|---|---|
| **Artifact** | Archivos que un *job* entrega a otro (la carpeta `_site`) | [14](14_publicacion_en_github.md) |
| **Branch (rama)** | Línea de historial; la principal es `main` | [14](14_publicacion_en_github.md) |
| **Clone** | Descargar un repositorio con todo su historial | [14](14_publicacion_en_github.md) |
| **Collaborator** | Persona invitada con permiso de ver y editar un repositorio | [14](14_publicacion_en_github.md) |
| **Commit** | Versión guardada del proyecto con autor, fecha, mensaje y *hash* | [14](14_publicacion_en_github.md) |
| **`commit --amend`** | Rehacer el último commit (p. ej., para corregir su mensaje); cambia su *hash* | [14](14_publicacion_en_github.md) |
| **Concurrency (Actions)** | Grupo `pages` del flujo: evita dos publicaciones a la vez; si llegan varios push seguidos, sólo queda en cola el más reciente | [14](14_publicacion_en_github.md) |
| **Fast-forward (`merge --ff-only`)** | Traer commits del remoto sólo si la rama local no se separó; se niega a crear un *merge* | [14](14_publicacion_en_github.md) |
| **Force push** | Push que reemplaza el historial remoto; irreversible del lado de GitHub | [14](14_publicacion_en_github.md) |
| **`--force-with-lease`** | Push forzado que se niega si alguien subió algo que no tienes; la variante prudente del *force push* | [14](14_publicacion_en_github.md) |
| **`.gitignore`** | Lista de archivos que Git no debe incluir | [14](14_publicacion_en_github.md) |
| **Git Credential Manager** | Programa que hace el inicio de sesión en GitHub por el navegador y guarda el token | [14](14_publicacion_en_github.md) |
| **GitHub Actions** | Servicio que ejecuta flujos automáticos (aquí, construir y publicar el tablero) | [14](14_publicacion_en_github.md) |
| **GitHub Pages** | Servicio que publica sitios estáticos en `usuario.github.io/repositorio` | [14](14_publicacion_en_github.md) |
| **Hash** | Identificador de un commit (p. ej., `e3bd43f`, el del entregable final) | [14](14_publicacion_en_github.md) |
| **Huella SHA-256** | Código que cambia si cambia un solo carácter de un archivo; el README del proyecto la da para comprobar los CSV | [14](14_publicacion_en_github.md) |
| **Job** | Conjunto de pasos de un flujo (`build` y `deploy`) | [14](14_publicacion_en_github.md) |
| **Orphan branch** | Rama nueva sin historial previo; se usó para rehacer el historial público | [14](14_publicacion_en_github.md) |
| **origin** | Apodo convencional del repositorio remoto en GitHub | [14](14_publicacion_en_github.md) |
| **PAT** | *Personal access token*: token de GitHub que sustituye a la contraseña (visto en clase con `gitcreds`) | [14](14_publicacion_en_github.md) |
| **Pull / push** | Traer / subir commits del remoto | [14](14_publicacion_en_github.md) |
| **Repositorio** | Carpeta cuyo historial controla Git | [14](14_publicacion_en_github.md) |
| **Runner** | Máquina virtual (Ubuntu) donde GitHub ejecuta el flujo | [14](14_publicacion_en_github.md) |
| **Staging (área de preparación)** | Cambios elegidos con `git add` para el próximo commit | [14](14_publicacion_en_github.md) |
| **Stash** | Guardar aparte cambios sin commit (`git stash push`) para traer lo del remoto y luego reaplicarlos (`git stash pop`) | [14](14_publicacion_en_github.md) |
| **Upstream** | Rama remota ligada a la local (`-u`), para que baste `git push` | [14](14_publicacion_en_github.md) |
| **Workflow** | Archivo YAML en `.github/workflows/` con los pasos automáticos | [14](14_publicacion_en_github.md) |
