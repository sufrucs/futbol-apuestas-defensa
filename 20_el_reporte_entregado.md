# 20. El reporte entregado (`Reporte.pdf`)

[← Índice](README.md)

El reporte técnico es lo que la profesora leyó antes de la exposición, así que es probable que pregunte por
él. Este capítulo lo resume sección por sección, dice de dónde sale cada cifra (celda del notebook, tablero o
cálculo propio del reporte) y prepara las preguntas incómodas que puede provocar.

## 20.1 Ficha

| Campo | Valor |
|---|---|
| Archivo | `Reporte.pdf`, en la raíz del repositorio público ([enlace](https://github.com/pitirringo/futbol-apuestas/blob/main/Reporte.pdf)) |
| Título | *Proyecto final: análisis de resultados de la Premier League. Fútbol y mercados de apuestas: modelado Poisson para la predicción de resultados de la Premier League* |
| Institución | UNAM, Facultad de Ciencias · Diplomado Introducción Analítica a la Ciencia de Datos · Módulo 8 |
| Equipo | Equipo número 1: Castillo Rodríguez Daniel Arturo, Castillo Santiago Erika Isabel, Garduño Gutiérrez César Emiliano, Gómez Mendoza Maximiliano, Martínez Vega Eduardo, Zacateco Tello María Fernanda |
| Profesora | Claudia Juárez |
| Fecha | 30 de septiembre de 2026 |
| Extensión | 21 páginas: 12 secciones, un apéndice (diccionario de variables) y 4 referencias |

## 20.2 La pregunta y la hipótesis: dos formulaciones que conviene saber conciliar

El reporte y el tablero formulan la pregunta de manera distinta. No se contradicen: miran el mismo resultado desde
dos ángulos.

| | Reporte (§2.1–2.2) | Tablero (página *Resumen*) |
|---|---|---|
| Pregunta | ¿En qué medida la incorporación de variables históricas de fortaleza y desempeño reciente **mejora** la capacidad predictiva de un modelo probabilístico, y cómo se compara con las cuotas de apertura? | ¿Qué tan bien anticipan el resultado las estadísticas disponibles antes del partido, **frente a** las probabilidades implícitas en las cuotas? |
| Hipótesis | Los modelos ampliados (M1–M4) tendrán menor error de goles y mejores probabilidades 1X2 que el modelo base | Las estadísticas sí contienen información útil, pero el mercado, que tiene información ventajosa, la aprovecha mejor |
| Respuesta | Se respalda **parcialmente**: las variables extra mejoran algunas métricas en algunos periodos, no todas (§9.2 y §12) | Se confirma: el modelo recupera la mayor parte de la ventaja del mercado (80 % en prueba) sin superarlo |
| Énfasis | Comparación **entre especificaciones** (M0 contra M1–M4) y entre métricas (MAE contra LogLoss) | Comparación **contra el mercado** y contra una referencia ingenua |

> **Si preguntan por qué difieren:** "Son dos preguntas complementarias sobre el mismo experimento. El reporte
> pregunta si agregar variables ayuda, y la respuesta es que sólo en parte: M4 gana en LogLoss en validación, pero en
> prueba el mejor LogLoss es el de M0. El tablero pregunta cuánto se acerca la estadística pública al mercado, y la
> respuesta es que recupera cerca de 80 % de la ventaja del mercado sobre una referencia ingenua, sin superarlo. Las
> cifras son las mismas en los dos documentos porque salen del mismo notebook."

## 20.3 Sección por sección

### 1. Resumen (pág. 1)
Describe el sistema completo: dos regresiones de Poisson (goles del local y del visitante), probabilidades 1X2 con
Skellam, cinco especificaciones (M0–M4) y el mercado de apertura como referencia. Cifras: 9,540 partidos y 34
columnas (18-ago-2001 a 14-sep-2026); matriz de modelación de 2,696 partidos (9-ago-2019 a 14-sep-2026);
1,897 / 380 / 419. Resultado central: en validación M0 tiene el menor MAE medio (0.918332) y M4 el menor LogLoss
(0.978612 contra 0.989547 de M0); en prueba M3 tiene el menor MAE medio (0.894173) y M0 el menor LogLoss
(1.033076; M3 1.033868). El mercado: 0.970552 y 1.020000.
→ Origen: `Analisis.ipynb` §6 y §9 (tablas de validación y prueba). Ver [cap. 12](12_resultados.md).

### 2. Planteamiento del problema y objetivos (pág. 2)
Objetivo general, población (partidos de la Premier League), unidad de análisis (el partido), variables objetivo
(goles del local y del visitante), alcance predictivo y comparativo. Pregunta e hipótesis (§20.2).
→ Ver [cap. 2](02_contexto_y_datos.md).

### 3. Limpieza y preparación de datos (págs. 3–5)
- **Cuadro 1:** histórico 9,540 × 34; matriz 2,696 × 24.
- **Cuadro 2 (cobertura):** variables principales sin ausentes (9,540, 2001/02–2026/27); Bet365 380 ausentes
  (9,160, desde 2002/03); cuotas promedio de apertura y cierre 6,840 ausentes (2,700, **2019/20–2026/27**); xG 9,500
  ausentes (40, sólo 2026/27).
  Ojo: el reporte presenta esta tabla **correcta**. La celda del notebook de limpieza que la genera muestra los
  rangos al revés y "2020/21" para las cuotas promedio (ver [cap. 3](03_limpieza_de_datos.md), "Detalles conocidos").
  Si alguien compara los dos documentos, la cifra correcta es la del reporte.
- **§3.1 Limpieza e integración:** 26 archivos; intersección de columnas + complementarias; 1 fila vacía eliminada;
  fechas homologadas; revisiones de consistencia (duplicados, mismo equipo, negativos, medio tiempo, marcador contra
  resultado, cuotas inválidas, xG negativos, tiros a puerta contra tiros) y la única inconsistencia conservada
  (un partido con más tiros a puerta que tiros). De 2,700 partidos construidos se excluyen 4 sin historial previo de
  tiros, para que M0–M4 usen la misma muestra.
- **§3.2 Separación temporal (Cuadro 3):** entrenamiento 09-08-2019 a 19-05-2024; validación 16-08-2024 a
  25-05-2025; prueba 15-08-2025 a 14-09-2026 (una temporada completa de 380 partidos más 39 de la siguiente). Filtro
  estricto de fecha anterior: los partidos del mismo día no se informan entre sí.
→ Origen: `Limpieza de datos.ipynb` y `Analisis.ipynb` §5. Ver [cap. 3](03_limpieza_de_datos.md) y
[cap. 9](09_evaluacion_y_validacion.md).

### 4. Ingeniería de variables (págs. 5–6)
- **§4.1 Elo:** inicial 1,500, **K = 15**, escala 400; variable del modelo ΔR/400; sin ajuste de localía dentro del
  Elo (la localía la captan las dos ecuaciones separadas). Cita a Hvattum y Arntzen (2010).
- **§4.2 Promedios de goles por temporada:** fórmula general con shrinkage n/(n + k); en la configuración elegida
  **k = 0**, así que con partidos de la temporada actual se usa sólo su promedio; antes del primer partido, la
  temporada anterior (o el promedio de la liga para los ascendidos). K y k se evaluaron por validación temporal con
  el LogLoss de M0: **0.959558**.
- **§4.3 Forma reciente:** últimos 10 partidos, pesos geométricos con d = 0.85, cruza temporadas; orientación de cada
  partido desde el punto de vista del equipo. Explica las 24 columnas de la matriz: 3 claves + 3 de Elo + 4 de goles
  de temporada + 4 de forma + 8 de tiros + 2 objetivos.
- **Figura 1:** el flujo histórico → variables → M0–M4 → Skellam → evaluación → predicción.
→ Origen: `wc_predictor.py` y `Analisis.ipynb` §1, §2 y §5. Ver [cap. 4](04_elo.md), [cap. 5](05_promedios_ajustados_y_forma.md)
y [cap. 10](10_codigo_wc_predictor.md).

### 5. Fundamento estadístico (págs. 7–8)
- **§5.1 Regresión de Poisson:** distribución de Poisson, enlace logarítmico, máxima verosimilitud con
  `statsmodels.api.GLM`, log-verosimilitud; e^β como cambio multiplicativo; aclara que no es un efecto causal.
  Cita a Loukas et al. (2024).
- **§5.2 Skellam:** P(local) = 1 − F(0), P(empate) = P(D = 0), P(visitante) = F(−1); el marcador modal sale de una
  matriz de 0 a 10 goles por equipo; las probabilidades 1X2 se calculan con Skellam, no con la matriz truncada ni con
  simulación.
→ Ver [cap. 6](06_poisson_y_regresion.md) y [cap. 7](07_de_goles_a_probabilidades.md).

### 6. Diseño experimental y especificaciones (págs. 8–10)
- **Cuadro 4:** las cinco especificaciones con sus variables por ecuación (3, 5, 5, 5 y 9 sin contar el intercepto).
- Ecuaciones de M0. Los coeficientes se ajustan sólo con los 1,897 partidos de entrenamiento y no se reestiman.
- **§6.1 Métricas:** MAE local, visitante y medio; LogLoss 1X2 (cita a Foulley, 2021). "Ambas métricas se
  reportan porque optimizan criterios distintos."
- **§6.2 Referencias:** referencia simple con intensidades constantes **λ = 1.561413 y 1.311545** (medias de
  entrenamiento); mercado: 1/cuota normalizado; margen bruto Σ 1/o − 1.
→ Ver [cap. 9](09_evaluacion_y_validacion.md) y [cap. 8](08_cuotas_y_mercado.md).

### 7. Resultados de la estimación y diagnósticos (pág. 11)
- **Cuadro 5 (coeficientes de M0):** intercepto 0.0433 / 0.0264; Elo/400 0.6283 / −0.6854; goles a favor propios
  0.1678 / 0.1079; goles en contra del rival 0.0778 / 0.0281. Ejemplo: +400 puntos de Elo multiplican los goles
  esperados del local por e^0.6283 ≈ 1.87.
- **§7.2 Colinealidad de M0:** correlaciones en la ecuación local 0.503 (Elo–GF), 0.372 (Elo–GA rival) y 0.011
  (GF–GA); VIF 1.632, 1.407 y 1.219. Visitante: −0.497, −0.371, −0.038; VIF 1.665, 1.438, 1.255. Conclusión: sin
  redundancia elevada en M0.
→ Origen: `Analisis.ipynb` §7. Ver [cap. 6](06_poisson_y_regresion.md) y [cap. 11](11_codigo_analisis_notebook.md).

### 8. Validación y selección de especificaciones (pág. 12)
- **Cuadro 6 (validación, 380 partidos):** MAE local / visitante / medio y LogLoss de M0–M4, con la diferencia contra
  M0 (M1 −0.001944, M2 −0.008829, M3 −0.007228, M4 −0.010935).
- La referencia simple obtiene MAE 1.054156 / 0.928139 / 0.991147 y LogLoss 1.079361: los cinco modelos la superan.
- **§8.1 Mercado en validación:** margen 4.49 %; LogLoss 0.970552, mejor que los cinco modelos.
→ Origen: `Analisis.ipynb` §6–§8.

### 9. Evaluación final en el conjunto de prueba (págs. 13–14)
- **Cuadro 7 (prueba, 419 partidos):** las cinco especificaciones (M3 incluido) con MAE y LogLoss.
- M3 tiene el menor MAE medio (0.894173, 0.008133 menos que M0); M0 el menor LogLoss (1.033076) y M3 queda a 0.000792.
- Aclara que el notebook no incluye intervalos bootstrap, calibración ni dispersión, y remite al **tablero**, que sí
  los tiene.
- **§9.1 Mercado en prueba:** 419 de 419 partidos con cuotas; margen 5.84 %; LogLoss 1.020000.
- **§9.2 Análisis:** respalda parcialmente la hipótesis (§20.2).
→ Origen: `Analisis.ipynb` §9; complementos en el tablero. Ver [cap. 12](12_resultados.md).

### 10. Ejemplo de pronóstico individual (pág. 14)
**Cuadro 8:** Arsenal–Man City con corte el 20-sep-2026 y M0: λ 1.537597 / 1.265612; 43.6462 % / 25.0000 % /
31.3538 %; marcador modal 1–1 con 11.7957 %. Explica por qué el marcador modal es un empate aunque gane el local en
probabilidad agregada.
→ Origen: `Analisis.ipynb` §10 (`predecir_partido`). El tablero muestra el mismo partido redondeado (1.538 / 1.266;
43.65 / 25.00 / 31.35 %; 1–1 con 11.80 %). Ver [cap. 7](07_de_goles_a_probabilidades.md).

### 11. Reproducibilidad, supuestos y limitaciones (pág. 15)
`premier_training_data.csv` como caché; regenerarla si cambia la base, `wc_predictor.py` o los hiperparámetros;
controles de finitud y duplicados; independencia condicional de los goles; MAE contra LogLoss; alcance sólo Premier
League; el mercado no es evaluación de rentabilidad. Extensiones: otros esquemas de validación, más calibración de
hiperparámetros y modelos con dependencia entre goles.
→ Ver [cap. 15](15_limitaciones_y_extensiones.md) y el README del repositorio (reproducibilidad paso a paso).

### 12. Conclusiones (pág. 16)
Repite el resultado central y el aprendizaje: más complejidad no garantiza una mejora uniforme fuera de muestra; hay
que mirar a la vez la precisión de los goles, la calidad de las probabilidades y su estabilidad temporal.

### Apéndice A. Diccionario de variables (págs. 17–19)
Las 34 columnas de `E0_consolidado.csv` (incluida `Div`) y las 24 de `premier_training_data.csv`.
→ Ver [cap. 2](02_contexto_y_datos.md).

## 20.4 Las cuatro referencias del reporte

| Ref. | Qué es | Por qué se cita |
|---|---|---|
| [1] Hvattum & Arntzen (2010), *International Journal of Forecasting* 26(3) | Estudio que usa la diferencia de Elo como variable para predecir resultados de fútbol y la compara con otros métodos y con las casas de apuestas | Respalda usar el Elo como medida de fuerza relativa (§4.1). Su hallazgo general coincide con el nuestro: el Elo es informativo, pero las cuotas pronostican mejor |
| [2] Loukas et al. (2024), *Applied Sciences* 14(16), 7230 | Aplicación de regresión de Poisson para predecir resultados de partidos | Respalda modelar goles con Poisson (§5.1) |
| [3] Foulley (2021), arXiv:2106.14345 | Verificación de pronósticos probabilísticos de fútbol: descomposición de puntajes, confiabilidad (calibración) y discriminación | Respalda evaluar con una regla de puntaje probabilística como el LogLoss (§6.1) |
| [4] Football-Data (2026) | La fuente de los datos | Origen de los 26 archivos (§3) |

Otras referencias útiles si preguntan por alternativas (Maher 1982, Dixon y Coles 1997, Constantinou y Fenton 2012,
Štrumbelj 2014): ver el [cap. 19](19_decisiones_y_alternativas.md).

## 20.5 Cifras del reporte que no aparecen en el tablero

| Cifra | Valor | Dónde se calcula |
|---|---|---|
| Medias de la referencia simple | λ = 1.561413 (local) y 1.311545 (visitante) | `Analisis.ipynb` §7 (medias de goles en entrenamiento) |
| MAE de la referencia simple en validación | 1.054156 / 0.928139 / 0.991147 | `Analisis.ipynb` §7 |
| VIF de M0 | local 1.632, 1.407, 1.219 · visitante 1.665, 1.438, 1.255 | `Analisis.ipynb` §7 |
| Correlaciones de M0 | 0.503, 0.372, 0.011 · −0.497, −0.371, −0.038 | `Analisis.ipynb` §7 |
| Efecto de +400 puntos de Elo | e^0.6283 ≈ 1.87 | Cálculo del reporte a partir del coeficiente |
| Columnas de la matriz | 3 + 3 + 4 + 4 + 8 + 2 = 24 | Conteo del reporte |
| MAE local y visitante por modelo | Cuadros 6 y 7 | `Analisis.ipynb` §6 y §9 |

Y al revés, el tablero tiene lo que el reporte no: intervalos bootstrap, calibración de modelo y mercado, brecha por
resultado, efectos estandarizados, dispersión de Pearson, sensibilidad sin público y el simulador (ver
[cap. 13](13_dashboard.md)). El propio reporte lo dice en su §9.

## 20.6 Preguntas que el reporte puede provocar

**"Su hipótesis no se cumplió. ¿Es un mal resultado?"**
No. Una hipótesis se pone a prueba y se respalda o no; aquí se respalda en parte, y eso es un hallazgo: más variables
no garantizan mejores probabilidades fuera de muestra. Es la razón por la que el tablero usa M0 en el simulador.

**"En validación gana M4 y en prueba gana M0. ¿Cuál es su modelo?"**
M0. La validación sirve para comparar y la prueba para confirmar. M4 fue mejor en validación por un margen mínimo (el
tablero muestra que el intervalo bootstrap apenas excluye el cero) y la ventaja no se sostuvo en prueba; M0 es el más
simple (3 variables por ecuación) y el mejor en prueba. Ver [cap. 9](09_evaluacion_y_validacion.md).

**"M3 tiene el menor MAE en prueba. ¿Por qué no lo eligen?"**
Porque el objetivo es pronosticar el resultado 1X2 con probabilidades, y eso lo mide el LogLoss, donde M0 es mejor.
El MAE sólo mide qué tan cerca quedó el número esperado de goles. Un modelo puede acertar mejor el promedio de goles y
repartir peor las probabilidades entre ganar, empatar y perder; el reporte lo muestra con cifras.

**"¿Cómo eligieron K = 15 y k = 0?"**
Con validación temporal de ventana creciente dentro del entrenamiento (2021/22, 2022/23 y 2023/24), probando 35
combinaciones y quedándose con la de menor LogLoss promedio (0.959558). Ver [cap. 4](04_elo.md),
[cap. 5](05_promedios_ajustados_y_forma.md) y [cap. 11](11_codigo_analisis_notebook.md).

**"¿Por qué el ejemplo usa el 20 de septiembre si los datos llegan al 14?"**
La fecha es un corte de información: el modelo sólo usa partidos anteriores a ella. Como no hubo partidos entre el 15
y el 19 de septiembre en la base, el pronóstico es el mismo que con corte el 15 (el que muestra el tablero).

**"¿Las cuotas de apertura estaban disponibles antes de cada partido?"**
Son las cuotas que Football-Data registra antes del partido (no las de cierre, que también vienen en los archivos y
el tablero usa como comparación adicional). El reporte advierte que la disponibilidad exacta al momento del
pronóstico requeriría comprobación independiente. Ver [cap. 8](08_cuotas_y_mercado.md), donde se explica qué son
"apertura" y "cierre" en esa fuente.

**"¿El reporte evalúa si se puede ganar dinero?"**
No, y lo dice explícitamente: el mercado se usa como referencia de calidad probabilística, no como estrategia de
apuestas (no hay comisiones, límites ni simulación de apuestas).

## 20.7 Mapa: reporte ↔ notebook ↔ tablero ↔ guía

| Reporte | Notebook (`Analisis.ipynb`) | Tablero | Guía |
|---|---|---|---|
| §3 Limpieza | (`Limpieza de datos.ipynb`) | Datos y método → Limpieza y calidad | [cap. 3](03_limpieza_de_datos.md) |
| §3.2 Partición | §5 (final) | El modelo → En pocas palabras | [cap. 9](09_evaluacion_y_validacion.md) |
| §4.1 Elo | §1–§2, §5 | Patrones → Elo | [cap. 4](04_elo.md) |
| §4.2 Promedios y calibración | §2, §5 | Datos y método → Variables / Evaluación | [cap. 5](05_promedios_ajustados_y_forma.md) |
| §4.3 Forma reciente | §2 | Datos y método → Variables | [cap. 5](05_promedios_ajustados_y_forma.md) |
| §5 Poisson y Skellam | §4 | El modelo → Cómo funciona | [caps. 6](06_poisson_y_regresion.md) y [7](07_de_goles_a_probabilidades.md) |
| §6 Diseño y métricas | §1, §4, §7, §8 | Datos y método → Evaluación | [caps. 9](09_evaluacion_y_validacion.md) y [8](08_cuotas_y_mercado.md) |
| §7 Coeficientes y colinealidad | §7 | El modelo → Qué variables pesan más | [cap. 6](06_poisson_y_regresion.md) |
| §8 Validación | §6, §8 | El modelo → Métricas completas | [cap. 12](12_resultados.md) |
| §9 Prueba | §9 | Resumen; El modelo | [cap. 12](12_resultados.md) |
| §10 Ejemplo | §10 | Explora un partido | [cap. 7](07_de_goles_a_probabilidades.md) |
| §11 Reproducibilidad | sección final | Datos y método → Reproducibilidad | [caps. 14](14_publicacion_en_github.md) y [15](15_limitaciones_y_extensiones.md) |
