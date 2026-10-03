# 9. Evaluación y validación

[← Cuotas y mercado](08_cuotas_y_mercado.md) · [Índice](README.md) · [Siguiente: código wc_predictor →](10_codigo_wc_predictor.md)

Este capítulo explica cómo se decidió qué tan bueno es un pronóstico: cómo se partieron los datos en el tiempo,
cómo se calibraron K y k sin tocar los datos de evaluación, qué métricas se usan y cómo saber si una diferencia
es real o suerte. Las cifras salen de las salidas guardadas de `Analisis.ipynb` y del tablero. Unas pocas las
calculamos **para esta guía** con el código del proyecto (Brier, RPS, error cuadrático, pruebas z); se indica
cuando es así. El código de cada paso está en el [capítulo 11](11_codigo_analisis_notebook.md).

## 9.1 Partición temporal: entrenamiento, validación y prueba

| Conjunto | Periodo | Partidos | Para qué se usa |
|---|---|---|---|
| Entrenamiento | 1-ago-2019 a 31-jul-2024 (5 temporadas; partidos del 9-ago-2019 al 19-may-2024) | 1,897 | Calibrar K y k (dentro de este periodo) y estimar los coeficientes de las regresiones |
| Validación | temporada 2024/25 | 380 | Comparar las 5 especificaciones (M0–M4) |
| Prueba | 15-ago-2025 a 14-sep-2026 | 419 (380 de 2025/26 + 39 de 2026/27) | Evaluación final, con partidos que el modelo nunca vio |

**Los coeficientes se estiman una sola vez** con entrenamiento y no se reestiman para validación ni prueba. Lo
que sí se actualiza partido a partido son las **variables** (Elo, promedios de la temporada, forma), siempre con
información anterior al partido.

```text
Temporada       19/20   20/21   21/22   22/23   23/24 | 24/25 | 25/26 + 26/27
Calibración: 3 pliegues dentro del entrenamiento (§5)  |       |
Pliegue 1      ======= ======= #######                |       |
Pliegue 2      ======= ======= ======= #######        |       |
Pliegue 3      ======= ======= ======= ======= #######|       |
M0–M4 (§6)     ======= ======= ======= ======= =======| VALID | PRUEBA
                                                      ^ 1-ago-2024: nada de la derecha se usa para elegir K y k
=  entrena (760, 1,140 y 1,520 partidos en los pliegues; 1,897 para M0–M4)      #  evalúa (380 cada pliegue)
```

**¿Por qué temporal y no aleatoria?** En datos ordenados en el tiempo, una partición aleatoria metería partidos de
2025 en el entrenamiento y evaluaría con partidos de 2020: el modelo "vería el futuro" (**fuga de información**)
y el desempeño se sobreestimaría. La partición temporal imita el uso real: ajustar con el pasado y pronosticar el
futuro.

**¿Por qué tres conjuntos?** Si se eligiera el mejor modelo mirando la prueba, la prueba dejaría de ser una
evaluación honesta: el ganador habría sido elegido por suerte en esos mismos datos. La validación sirve para
elegir; la prueba, para medir.

> **Decisión:** partición temporal en tres bloques consecutivos.
> **Alternativas:** (a) partición aleatoria (por ejemplo, 70/15/15) — usa los datos de forma pareja, pero mezcla
> futuro y pasado: fuga de información; (b) *k-fold* aleatorio (validación cruzada clásica) — cada partido se
> evalúa una vez, pero con modelos entrenados con partidos posteriores a él; además las variables (Elo, forma) ya
> resumen el pasado, así que los pliegues no serían independientes; (c) validación con origen móvil en todo el
> periodo (reentrenar y pronosticar temporada por temporada; Hyndman y Athanasopoulos, 2021) — más completa,
> pero un modelo distinto por temporada. Ninguna se probó para M0–M4; el origen móvil sí se usó, en pequeño, para
> calibrar K y k (9.3).
> **Por qué ésta:** respeta el orden del calendario, es la forma estándar de evaluar pronósticos y es fácil de
> explicar: "con lo que sabíamos hasta 2024, ¿qué tan bien pronosticamos 2024/25 y 2025/26?".
> **Si preguntan:** "No partimos al azar porque el modelo habría visto el futuro; entrenamos con el pasado,
> elegimos con 2024/25 y medimos con partidos posteriores."

> **Decisión:** tamaño de los periodos: 5 temporadas de entrenamiento, 1 de validación y 1 más 4 jornadas de
> prueba, con la base desde agosto de 2019.
> **Alternativas:** (a) entrenar desde 2001/02 — las variables existen desde entonces (el Elo ya se calcula desde
> 2001), serían unos 6,800 partidos más, pero de un fútbol más lejano; (b) validar con dos temporadas — más
> partidos para distinguir modelos, a costa de entrenamiento o de prueba; (c) probar sólo con 2025/26 completa
> (380) — el proyecto incluyó también los 39 partidos ya jugados de 2026/27, lo más reciente disponible.
> **Por qué ésta:** el notebook no lo justifica explícitamente. Razones razonables: 2019/20 es la primera temporada
> con cuotas promedio de apertura (la referencia de mercado), el fútbol reciente se parece más al que se quiere
> pronosticar, y cinco temporadas dan casi 1,900 partidos para estimar 4 coeficientes por ecuación en M0.
> **Evidencia en el proyecto:** con 380 partidos, el error estándar de la diferencia de LogLoss entre M4 y M0 es de
> ≈ 0.0055 (calculado para esta guía): diferencias de ≈ 0.01 están en el límite de lo detectable. Y la composición
> del entrenamiento importa poco: sin los 472 partidos a puerta cerrada, el LogLoss de prueba de M0 pasa de 1.0331 a
> 1.0328 (sensibilidad del tablero).
> **Si preguntan:** "Usamos el periodo con cuotas promedio, cinco temporadas para entrenar; con una temporada de
> validación, diferencias de una centésima apenas se distinguen del azar."

## 9.2 Fuga de información (*data leakage*): cómo se evitó

| Posible fuga | Cómo se evita en el proyecto |
|---|---|
| Usar estadísticas del mismo partido (tiros, goles) como predictores | Sólo se usan promedios de partidos **anteriores** |
| Promedios o Elo calculados con partidos futuros | `df_pre = historial[date < fecha]` en cada fecha; el Elo se actualiza **después** de construir las variables del día |
| Que un partido informe a otro del mismo día | Todos los partidos de una fecha usan el corte "antes de ese día" (la base no trae la hora de inicio) |
| Elegir K y k con los datos de evaluación | La calibración (§5) usa sólo 2021/22, 2022/23 y 2023/24, dentro del entrenamiento (9.3) |
| Partición aleatoria | Partición por fechas |
| Usar las cuotas como predictor | Las cuotas son sólo referencia |
| Elegir el modelo con la prueba | La elección formal se hizo en validación (ver 9.4, con su matiz) |
| Imputar los tiros de equipos sin historial | Los 4 partidos sin historial de tiros se excluyen, no se rellenan |

`crear_variables_partido` incluso **verifica** que no se cuele el futuro: si `df_pre` contiene alguna fecha igual o
posterior a la del partido, lanza un error. Un detalle menor: el respaldo de forma reciente para un equipo sin
ningún partido previo es el promedio de goles de **todo** el histórico; sólo afecta a esos 4 partidos, que se
eliminan antes de modelar.

## 9.3 La calibración de K y k: validación temporal de ventana creciente

K (qué tanto mueve el Elo cada partido) y k (cuánto pesa la temporada anterior en los promedios de goles) son
**hiperparámetros**: no los estima la regresión, porque definen las variables que la regresión recibe. La versión
anterior los fijaba a mano (K = 30, k = 10). La versión final los **elige con datos** (§5 del notebook,
[capítulo 11](11_codigo_analisis_notebook.md)):

1. Para cada combinación (K, k) de la rejilla, se reconstruye toda la base histórica.
2. En cada uno de **tres pliegues** se ajusta M0 con **todo** lo anterior a una temporada y se mide su LogLoss en
   esa temporada (ver el diagrama de 9.1): 2021/22 con 760 partidos de entrenamiento, 2022/23 con 1,140 y 2023/24
   con 1,520. Es una **ventana creciente** (*expanding window*): cada pliegue entrena con más historia que el
   anterior.
3. Se promedian los tres LogLoss, **ponderados por el número de partidos** de cada pliegue:

$$
\overline{LL}(K,k)=\frac{\sum_{f=1}^{3} N_f\,LL_f(K,k)}{\sum_{f=1}^{3} N_f},\qquad (K^*,k^*)=\arg\min_{K,k}\overline{LL}(K,k)
$$

Como los tres pliegues tienen 380 partidos (1,140 en total), el promedio ponderado coincide con el simple.

4. Se elige la combinación con el menor promedio y, con ella, se construye la base definitiva.

**Rejilla probada:** K ∈ {15, 20, 25, 30, 35, 40, 45} × k ∈ {0, 5, 10, 15, 20} = 35 combinaciones. En el notebook
guardado quedó activa sólo la ganadora; la rejilla completa está comentada y la reprodujimos (tabla completa en
el [capítulo 11](11_codigo_analisis_notebook.md#1155-la-rejilla-completa); en R,
[`06_calibracion.R`](equivalencias_R/06_calibracion.R) obtiene las mismas 35 cifras).

| Combinación | LogLoss promedio (3 pliegues) | Lugar | Diferencia con la elegida |
|---|---|---|---|
| **K = 15, k = 0 (elegida)** | **0.959558** (0.960230 · 0.989315 · 0.929130) | 1 de 35 | — |
| K = 20, k = 0 | 0.959589 | 2 | +0.000031 |
| K = 30, k = 10 (la configuración anterior) | 0.962178 | 15 | +0.002620 |
| K = 45, k = 20 (la peor) | 0.965084 | 35 | +0.005526 |

**Cómo leerla:**

- **K chico gana:** con K = 15–20 el Elo reacciona menos a cada partido y resume mejor la fuerza de largo plazo.
- **k = 0 gana para casi todo K** (la excepción es K = 45): con un Elo estable, mezclar la temporada actual con la
  anterior no ayudó. k = 0 no deja sin información el inicio de temporada: antes del primer partido se usa la
  referencia previa.
- **Las diferencias son pequeñas:** toda la rejilla cabe en 0.0055, la mitad de la ventaja de M4 sobre M0 en
  validación (0.0109). K y k afinan; no cambian las conclusiones.
- **Los pliegues no coinciden:** 2021/22 y 2023/24 prefieren K = 15, k = 0, pero 2022/23 prefiere K = 35, k = 0
  (0.981453 contra 0.989315). Con una sola temporada, la elección habría dependido de cuál se mirara; por eso se
  promedian tres.

**¿Por qué no se usa la validación 2024/25 ni la prueba para elegir K y k?**

1. La validación ya tiene un trabajo: elegir entre M0–M4. Si también eligiera K y k, los mismos 380 partidos
   tomarían dos decisiones y la comparación de modelos quedaría optimista.
2. La prueba no debe participar en **ninguna** decisión; si no, deja de medir el desempeño en partidos nuevos.
3. Calibrar dentro del entrenamiento y después reestimar los coeficientes con **todo** el entrenamiento es lo
   normal: la calibración sólo elige K y k; los coeficientes de M0–M4 se estiman después con los 1,897 partidos.

**Advertencia del borde.** El propio notebook lo dice: "si el mejor valor aparece en un extremo, conviene ampliar
el rango". **K = 15 es el valor más chico de la rejilla**, así que el óptimo podría estar por debajo; **K < 15 no
se probó** (es la extensión natural). k = 0 también está en el extremo, pero ahí el extremo es natural: k no puede
ser negativo (k = 0 ya es "sin mezcla"). Y como K = 20 queda a 0.000031, lo robusto no es "15 exactamente", sino
"un K chico y sin mezcla".

**Detalle fino.** La base de calibración sólo tiene las variables de M0 y no pasa por el `dropna` de tiros, así que
tres de los cuatro partidos que después se excluyen (Brentford 2021, Nott'm Forest 2022 y Luton 2023) sí entran en
los pliegues. Es 1 partido de 380 por pliegue: no cambia la conclusión.

> **Decisión:** calibrar con ventana creciente: cada temporada evaluada se pronostica con todo lo anterior desde
> 2019/20.
> **Alternativas:** (a) ventana móvil de tamaño fijo (por ejemplo, sólo las dos temporadas previas) — se adapta si
> el fútbol cambia, pero entrena con menos datos y desecha información; (b) un solo pliegue (sólo 2023/24) — tres
> veces más rápido, pero la elección dependería de una temporada; (c) *k-fold* aleatorio — fuga temporal; (d)
> calibrar con la validación 2024/25 — la gastaría en dos decisiones. Ninguna se probó.
> **Por qué ésta:** imita el uso real (al empezar cada temporada se sabe todo lo anterior), aprovecha todos los
> datos y promedia tres temporadas; es la evaluación con "origen móvil" que recomiendan Hyndman y Athanasopoulos
> (2021) para series de tiempo.
> **Evidencia en el proyecto:** la temporada 2022/23 sola habría elegido K = 35; el promedio de 1,140 partidos elige
> K = 15. El costo: el primer pliegue entrena con sólo 760 partidos.
> **Si preguntan:** "Cada temporada se pronosticó con todo lo que había antes, como en la vida real, y promediamos
> tres temporadas para no depender de una; ni la validación ni la prueba participaron."

## 9.4 La selección de modelo (un punto delicado)

| | M0 | M1 | M2 | M3 | M4 | Mercado |
|---|---|---|---|---|---|---|
| LogLoss en **validación** | 0.9895 | 0.9876 | 0.9807 | 0.9823 | **0.9786** | 0.9706 |
| LogLoss en **prueba** | **1.0331** | 1.0347 | 1.0373 | 1.0339 | 1.0367 | 1.0200 |

- En **validación**, el mejor fue **M4**, y el bootstrap dice que su ventaja sobre M0 es **significativa por un
  margen mínimo**: −0.0109, con IC 95 % de −0.0213 a **−0.00005** (el intervalo apenas excluye el cero; en 2.5 % de
  los remuestreos M4 no supera a M0).
- En **prueba** se evaluaron **las cinco** especificaciones y el mejor fue **M0** (1.0331), con M3 muy cerca
  (1.0339). M4 − M0 = +0.0037, IC 95 % de −0.0063 a +0.0139: **no concluyente**.

¿Cuál es "el modelo"? El equipo se queda con **M0**, por cuatro razones:

1. La ventaja de M4 en validación es **mínima** y no toma en cuenta que M4 fue **el mejor de cinco**: elegir al
   mejor de varios favorece al que tuvo suerte (la "maldición del ganador"). Con una corrección por las cuatro
   comparaciones contra M0 (Bonferroni, intervalo de 98.75 %), el intervalo de M4 − M0 va de −0.0244 a +0.0029 e
   incluye el cero (calculado para esta guía).
2. En prueba M4 no se sostuvo y M0 fue el mejor de los cinco.
3. **Parsimonia:** 3 variables por ecuación contra 9, sin colinealidad (VIF de M0 ≤ 1.67; en M4 llega a 5.56).
4. M0 tiene el menor MAE en validación.

La forma honesta de explicarlo:

> "En validación ganó M4, y su ventaja sobre M0 fue distinguible del azar por un margen mínimo. En prueba esa
> ventaja no se sostuvo: M0 fue el mejor de los cinco y la diferencia con M4 no es concluyente. Por parsimonia
> preferimos M0, sabiendo que esa preferencia usa información de prueba y que habría que confirmarla con la
> siguiente temporada."

**Dos formulaciones, una evidencia.** El reporte pregunta si las variables de fortaleza y desempeño reciente
**mejoran** la predicción, y concluye que su hipótesis se respalda **parcialmente** (en validación M4 tiene el menor
LogLoss y M0 el menor MAE; en prueba M0 el menor LogLoss y M3 el menor MAE). El tablero pregunta qué tan bien
anticipan las estadísticas **frente al mercado**. Son complementarias: ver el
[capítulo 20](20_el_reporte_entregado.md) y el [capítulo 12](12_resultados.md).

> **Decisión:** elegir con validación y usar la prueba sólo para medir; al final se presenta M0, el más simple, porque
> la ventaja de M4 fue mínima en validación y no se sostuvo en prueba.
> **Alternativas:** (a) seguir mecánicamente la validación y presentar M4 — es la regla pura, pero ignora que la
> ventaja apenas excluye el cero y que M4 tiene el triple de variables; (b) elegir con la prueba — la prueba dejaría
> de ser una medición honesta; (c) reentrenar con entrenamiento + validación antes de la prueba — más datos, pero ya
> no se probaría el modelo comparado; (d) promediar los cinco modelos (ensamble) — no se probó.
> **Por qué ésta:** separa elegir de medir y, cuando la validación casi no distingue, usa la parsimonia como
> desempate. Se reportan los cinco resultados de prueba, así que nadie tiene que creer en la elección a ciegas.
> **Evidencia en el proyecto:** M4 − M0: −0.0109 en validación (IC hasta −0.00005) y +0.0037 en prueba (no
> concluyente).
> **Si preguntan:** "La validación eligió M4 por un margen mínimo; en prueba no se sostuvo. Nos quedamos con el modelo
> más simple y lo decimos abiertamente: esa preferencia ya usa la prueba y habría que confirmarla con otra
> temporada."

## 9.5 LogLoss: la métrica principal

$$
\text{LogLoss} = -\frac{1}{N} \sum_{i=1}^{N} \log \hat p_{i,\,y_i}
$$

donde $\hat p_{i,y_i}$ es la probabilidad que el modelo le asignó **al resultado que ocurrió** en el partido $i$.
**Menor es mejor.**

**Ejemplos con un solo partido:**

| Pronóstico (local / empate / visita) | Qué pasó | Pérdida $-\log \hat p$ |
|---|---|---|
| 50 % / 25 % / 25 % | Ganó el local | $-\ln 0.50 = 0.693$ |
| 50 % / 25 % / 25 % | Ganó el visitante | $-\ln 0.25 = 1.386$ |
| 90 % / 5 % / 5 % (muy seguro) | Ganó el visitante | $-\ln 0.05 = 3.00$ ← castigo fuerte |
| 33.3 % / 33.3 % / 33.3 % (azar) | Cualquiera | $-\ln(1/3) = 1.099$ |

**¿Por qué LogLoss?**
1. Evalúa **probabilidades completas**, no sólo si se acertó el resultado más probable.
2. Castiga fuerte la **sobreconfianza**: equivocarse diciendo 90 % cuesta mucho.
3. Es una **regla de puntuación estrictamente propia** (Gneiting y Raftery, 2007): su valor esperado se minimiza
   sólo reportando las probabilidades que uno realmente cree, así que no se puede "hacer trampa" exagerando.
4. Es la misma idea que estima el modelo: el LogLoss es menos el promedio de la log-verosimilitud de los resultados
   observados.

**Traducción intuitiva:** $e^{-\text{LogLoss}}$ es la probabilidad **promedio (geométrica)** que se le dio al resultado
real. M0 en prueba: $e^{-1.033} = 35.6\,\%$; mercado: 36.1 %; azar: 33.3 %. Parecen cercanos, pero en fútbol cada
décima es difícil.

**Referencias útiles:** azar = ln 3 ≈ **1.099**; referencia ingenua ≈ 1.08–1.09; modelos ≈ 0.98–1.04; mercado ≈
0.97–1.02.

```python
from sklearn.metrics import log_loss
log_loss(y_observado, P, labels=[0, 1, 2])     # y: 0 = local, 1 = empate, 2 = visita
```

```r
logloss <- function(P, y) -mean(log(P[cbind(seq_along(y), y)]))   # y: 1, 2, 3 (columna)
# alternativa con paquetes: yardstick::mn_log_loss()
```

`P[cbind(filas, columnas)]` toma, de cada fila, la probabilidad de la columna que ocurrió (en Python se logra con
indexación avanzada `P[np.arange(n), y]`).

**Otras reglas que se podían usar.** Con $o_{ij} = 1$ si ocurrió el resultado $j$ y 0 si no:

$$
\text{Brier}=\frac{1}{N}\sum_{i}\sum_{j=1}^{3}(\hat p_{ij}-o_{ij})^2,
\qquad
\text{RPS}=\frac{1}{N}\sum_i \frac{1}{2}\Big[(\hat p_{i1}-o_{i1})^2+(\hat p_{i1}+\hat p_{i2}-o_{i1}-o_{i2})^2\Big]
$$

- **Brier** (Brier, 1950): error cuadrático de las probabilidades. Castiga menos la sobreconfianza que el LogLoss
  (equivocarse con 90 % cuesta como mucho 2, no infinito).
- **RPS** (*ranked probability score*): compara probabilidades **acumuladas**, así que toma en cuenta que el
  resultado es ordinal (local → empate → visita): si se dijo "local" y hubo empate, el error es menor que si ganó el
  visitante. Constantinou y Fenton (2012) lo recomiendan para el fútbol precisamente por eso.

Las tres son reglas propias. Para esta guía calculamos Brier y RPS con las mismas probabilidades del proyecto (no
están en el notebook ni en el tablero):

| Predictor | Validación: LogLoss · Brier · RPS | Prueba: LogLoss · Brier · RPS |
|---|---|---|
| M0 | 0.9895 · 0.5919 · 0.2034 | **1.0331 · 0.6217 · 0.2088** |
| M3 | 0.9823 · 0.5864 · 0.2010 | 1.0339 · 0.6219 · 0.2089 |
| M4 | **0.9786 · 0.5844 · 0.1999** | 1.0367 · 0.6237 · 0.2094 |
| Mercado de apertura | 0.9706 · 0.5789 · 0.1974 | 1.0200 · 0.6133 · 0.2049 |
| Referencia ingenua | 1.0794 · 0.6544 · 0.2348 | 1.0868 · 0.6582 · 0.2273 |
| Azar (1/3 cada uno) | 1.0986 · 0.6667 · 0.2370 | 1.0986 · 0.6667 · 0.2308 |

Con las tres reglas, el **orden de los cinco modelos y del mercado es el mismo** en cada periodo (en validación M4 <
M2 < M3 < M1 < M0; en prueba M0 < M3 < M1 < M4 < M2; el mercado, siempre primero). La conclusión no depende de la
métrica elegida.

> **Decisión:** LogLoss 1X2 como métrica principal.
> **Alternativas:** (a) Brier — más estable ante probabilidades extremas, pero castiga menos la sobreconfianza;
> (b) RPS — respeta el orden local → empate → visita y es la que recomiendan Constantinou y Fenton (2012) para el
> fútbol; (c) aciertos — fácil de comunicar, pero no es una regla propia: ignora la confianza y nunca premia
> pronosticar empates.
> **Por qué ésta:** es estrictamente propia (Gneiting y Raftery, 2007), castiga la sobreconfianza, es la
> log-verosimilitud de lo observado (el mismo principio que estima los GLM), viene en `sklearn` y es la que usan el
> notebook, el reporte y el tablero.
> **Evidencia en el proyecto:** con Brier y RPS el orden de modelos y mercado no cambia (calculado para esta guía).
> **Si preguntan:** "Usamos LogLoss porque evalúa la probabilidad completa y castiga la sobreconfianza; con Brier o
> RPS, que respeta el orden de los resultados, el orden de los modelos es el mismo."

## 9.6 MAE de goles, y por qué no coincide con el LogLoss

$$
\text{MAE}_{\text{promedio}} = \frac{1}{2N} \sum_{i=1}^{N} \left( \lvert g_{L,i} - \hat\lambda_{L,i} \rvert + \lvert g_{V,i} - \hat\lambda_{V,i} \rvert \right)
$$

Error absoluto medio entre los goles reales y los esperados, promediado entre local y visitante. Evalúa **λ**, no las
probabilidades 1X2.

| MAE promedio | M0 | M1 | M2 | M3 | M4 |
|---|---|---|---|---|---|
| Validación | **0.918332** | 0.921561 | 0.921414 | 0.920956 | 0.921895 |
| Prueba | 0.902306 | 0.903519 | 0.901631 | **0.894173** | 0.899439 |

**La tensión que enfatiza el reporte.** Las dos métricas eligen distinto en los dos periodos:

| Periodo | Mejor LogLoss | Mejor MAE |
|---|---|---|
| Validación | M4 (0.978612) | **M0** (0.918332), que tiene el **peor** LogLoss |
| Prueba | **M0** (1.033076) | M3 (0.894173), 0.008133 menos que M0 |

Por eso el reporte concluye que su hipótesis se respalda sólo **parcialmente**: aproximar mejor el número de goles
no garantiza mejores probabilidades de victoria, empate y derrota. ¿Por qué pasa?

1. **Miden cosas distintas.** El MAE juzga cada λ por separado; el 1X2 depende de las **dos** λ a la vez (sobre todo
   de su diferencia). Un modelo puede acercar cada λ a los goles reales y aun así repartir peor la probabilidad entre
   los tres resultados.
2. **El MAE premia la mediana, no la media.** El error absoluto esperado se minimiza pronosticando la **mediana** de
   la distribución, y la mediana de una Poisson con λ entre 0.69 y 1.68 es **1 gol**. Ejemplo: si los goles de un
   equipo son Poisson(1.5), pronosticar su media verdadera, 1.5, da un error absoluto esperado de 1.004; pronosticar
   "1 gol", 0.946. La predicción honesta pierde. En los datos (calculado para esta guía), **pronosticar siempre 1 gol
   para los dos equipos**, sin saber nada de ellos, tiene un MAE de 0.935526 en validación (mejor que la referencia
   ingenua, 0.991147) y de **0.894988 en prueba: mejor que M0, M1, M2 y M4, y sólo 0.0008 peor que M3**.
3. **El error cuadrático sí apunta a la media.** Con el MSE (que se minimiza con la media, que es lo que estima λ),
   "siempre 1 gol" queda muy atrás (1.7408 en validación y 1.4606 en prueba, contra 1.3827 y 1.2360 de M0), y el mejor
   es M3 en los dos periodos (1.3738 y 1.2247).
4. **Las diferencias son minúsculas:** entre el mejor y el peor modelo hay 0.0036 de MAE en validación y 0.0093 en
   prueba.

**Cómo decirlo:** para pronosticar el resultado y compararse con las cuotas, la métrica que importa es el LogLoss;
el MAE describe qué tan cerca quedan los goles esperados, pero premia acercarse a "1 gol" y casi no distingue entre
modelos.

> **Decisión:** reportar el MAE de goles como métrica secundaria, junto al LogLoss.
> **Alternativas:** (a) MSE o RMSE — se minimizan con la media, que es justo lo que estima λ (en el proyecto, M3 tiene el
> menor MSE en ambos periodos; calculado para esta guía); (b) devianza de Poisson (log-verosimilitud de los goles) —
> la pérdida natural de un modelo de Poisson; evalúa toda la distribución de goles; (c) no reportar métrica de goles.
> **Por qué ésta:** es fácil de explicar ("en promedio nos equivocamos por 0.9 goles por equipo"), viene en `sklearn`
> y el reporte la usa para mostrar que goles y probabilidades son problemas distintos.
> **Limitación:** el error absoluto premia la mediana; un pronóstico constante de 1 gol casi empata con el mejor modelo
> en prueba. Por eso no sirve para elegir entre modelos.
> **Si preguntan:** "El MAE mide qué tan cerca quedan los goles esperados; no evalúa las probabilidades. Además premia
> pronosticar un gol: hasta un pronóstico constante de un gol casi empata con el mejor modelo. Para el 1X2 la métrica
> correcta es el LogLoss."

## 9.7 Métricas complementarias que agrega el tablero

| Métrica | Qué es | Resultado en prueba (validación) | Por qué se agregó |
|---|---|---|---|
| Aciertos | % de partidos donde el resultado más probable ocurrió | M0 48.0 % · mercado 48.9 % · ingenua 41.5 % (53.2 · 54.2 · 40.8 %) | Fácil de comunicar; pero ignora la confianza y nadie pronostica empates |
| Referencia ingenua | Poisson con los goles promedio del entrenamiento (1.56 local, 1.31 visitante), igual para todos | LogLoss 1.0868 (1.0794) | "Cero información de los equipos": mide cuánto aportan las variables |
| Parte de la mejora del mercado | (ingenua − M0) / (ingenua − mercado) | **80 %** (83 %) | Resume "cerca, pero debajo" en un número |
| Probabilidad media al resultado real | $e^{-\text{LogLoss}}$ | 35.6 % vs 36.1 % del mercado | Traduce el LogLoss |

**¿Por qué la referencia ingenua acierta 41.5 %?** Porque siempre le da más probabilidad al local (43.24 % contra
32.07 % y 24.69 %), así que acierta exactamente cuando gana el local: 41.5 % de los partidos de prueba.

## 9.8 Calibración del modelo vs el mercado

Con validación + prueba (799 partidos × 3 = 2,397 pronósticos), en grupos de 10 puntos porcentuales (se muestran
grupos con al menos 30 pronósticos):

| El modelo M0 dijo | Ocurrió | El mercado dijo | Ocurrió |
|---|---|---|---|
| 24.6 % | 26.4 % | 25.2 % | 27.1 % |
| 44.6 % | 40.6 % | 44.9 % | 43.5 % |
| 64.4 % | **57.0 %** | 65.0 % | 63.7 % |
| 74.1 % | **68.1 %** | 74.2 % | 70.3 % |

**El modelo es algo sobreconfiado con los favoritos**: cuando asigna 60–80 %, el favorito gana menos de lo previsto.
El mercado está mejor calibrado en esa zona, aunque tampoco es perfecto (en el grupo de 50–60 % dice 55.0 % y ocurre
48.3 %). Es otra forma de ver por qué el mercado gana.

## 9.9 ¿Son significativas las diferencias? Bootstrap

**La idea:** con 380 o 419 partidos, parte de cualquier diferencia de LogLoss es suerte de la muestra. El
**bootstrap** (Efron y Tibshirani, 1993) mide esa incertidumbre:
1. Se calcula la diferencia de pérdida **partido por partido** (A − B).
2. Se remuestrean los partidos **con reemplazo** (algunos salen repetidos, otros no) y se promedia.
3. Se repite 10,000 veces; los percentiles 2.5 y 97.5 forman el **intervalo de 95 %**.
4. Si el intervalo **no incluye el cero**, la diferencia es distinguible del azar.

| Periodo | Comparación (A − B) | Diferencia | IC 95 % | ¿Distinta de cero? |
|---|---|---|---|---|
| Prueba | M0 − ingenua | −0.054 | −0.086 a −0.022 | **Sí**: el modelo es claramente mejor |
| Prueba | M0 − mercado | +0.013 | −0.0005 a +0.026 | No, por muy poco |
| Prueba | M4 − M0 | +0.004 | −0.006 a +0.014 | No |
| Prueba | M4 − mercado | +0.017 | +0.003 a +0.030 | Sí |
| Validación | M4 − M0 | −0.011 | −0.021 a −0.00005 | **Sí, por un margen mínimo** |
| Validación | M0 − mercado | +0.019 | +0.005 a +0.033 | Sí |
| Validación + prueba | M0 − mercado | +0.016 | **+0.006 a +0.025** | **Sí** |

**Lectura:** el modelo supera claramente a la ingenua. El mercado es mejor que M0 **de forma consistente**: en prueba
sola el intervalo toca el cero por muy poco, pero en validación y con los dos periodos juntos (799 partidos) la
diferencia es clara. Entre M4 y M0 la evidencia es débil y cambia de signo: M4 mejor en validación por un margen
mínimo, no concluyente en prueba (ver 9.4). Antes, con K = 30 y k = 10, ninguna diferencia M4 − M0 era concluyente;
con K = 15 y k = 0, la de validación apenas lo es.

```python
# datos_dashboard.py (_bootstrap)
rng = np.random.default_rng(2026)                    # semilla fija: resultados reproducibles
idx = rng.integers(0, len(dif), size=(10_000, len(dif)))
medias = dif[idx].mean(axis=1)
np.percentile(medias, [2.5, 97.5])
```

```r
set.seed(2026)
medias <- replicate(10000, mean(sample(dif, replace = TRUE)))
quantile(medias, c(0.025, 0.975))
```

R y Python generan números aleatorios distintos, así que los extremos varían en la cuarta cifra: para M0 − mercado
en prueba, [`03_mercado.R`](equivalencias_R/03_mercado.R) da +0.0131 con IC de −0.0007 a +0.0265, y Python, de
−0.0005 a +0.0264. La conclusión es la misma.

> **Decisión:** intervalos bootstrap por partidos (10,000 remuestreos, semilla 2026, percentiles 2.5 y 97.5).
> **Alternativas:** (a) prueba de Diebold y Mariano (1995) — una prueba t sobre la diferencia media de pérdidas, con
> corrección por autocorrelación; para pronósticos a un paso sin autocorrelación se reduce a una z: da z ≈ −1.98
> (p ≈ 0.048) para M4 − M0 en validación y z ≈ 1.89 (p ≈ 0.059) para M0 − mercado en prueba (calculado para esta
> guía), las mismas conclusiones; (b) bootstrap por bloques (remuestrear jornadas o semanas completas) — respeta la
> dependencia entre partidos cercanos en el tiempo; (c) prueba de permutación pareada (cambiar al azar el signo de
> las diferencias). Las dos últimas no se probaron.
> **Por qué ésta:** no supone normalidad, es fácil de explicar y de reproducir, y con partidos casi independientes
> entre sí remuestrear partidos es razonable.
> **Limitaciones:** supone partidos intercambiables (si hubiera dependencia, los intervalos serían algo estrechos;
> el bootstrap por bloques lo corregiría) y no corrige por haber elegido al mejor de varios modelos (9.4).
> **Si preguntan:** "Remuestreamos los partidos 10,000 veces para ver cuánto varía la diferencia; si el intervalo no
> incluye el cero, no es suerte. Una prueba de Diebold–Mariano da la misma conclusión."

## 9.10 Multicolinealidad y VIF

Cuando las variables explicativas están muy correlacionadas entre sí (por ejemplo, **tiros y tiros a puerta:
correlación de 0.86**), el modelo no puede separar bien el efecto de cada una: los coeficientes individuales se
vuelven inestables (errores estándar grandes, signos raros).

El **VIF** (factor de inflación de la varianza) lo mide: para cada variable $j$, se hace una regresión de esa variable
contra las demás y

$$
\text{VIF}_j = \frac{1}{1 - R_j^2}
$$

VIF = 1 es sin correlación; valores de 5 a 10 se consideran altos.

| Modelo | VIF | Fuente |
|---|---|---|
| M0, ecuación del local | `elo_diff` 1.632 · `gf_home` 1.407 · `ga_away` 1.219 | Notebook, §7 |
| M0, ecuación del visitante | `elo_diff` 1.665 · `gf_away` 1.438 · `ga_home` 1.255 | Notebook, §7 |
| M4, ecuación del local | Máximo **5.56** (`sot_for_home`, tiros a puerta del local) | Tablero |

**¿Hay que eliminar variables por eso?** No automáticamente: la multicolinealidad **no sesga las predicciones**,
sólo vuelve inestables los coeficientes. Por eso el proyecto compara modelos por su desempeño **fuera de muestra**,
no por la significancia de cada coeficiente. En M0, el modelo cuyos coeficientes se interpretan, todos los VIF son
menores que 2.

```python
from statsmodels.stats.outliers_influence import variance_inflation_factor
[variance_inflation_factor(X.to_numpy(), i) for i in range(1, X.shape[1])]
```

```r
# igual que Python (sin ponderar): regresión lineal de cada X contra las demás
vif_manual <- function(X) sapply(names(X), function(j)
  1 / (1 - summary(lm(reformulate(setdiff(names(X), j), j), data = X))$r.squared))
# car::vif(modelo_glm) da una versión ponderada por el GLM: valores parecidos, no idénticos
```

## 9.11 Resumen de las decisiones de este capítulo

| Decisión | Alternativa principal | Por qué ésta, en una línea | Dónde |
|---|---|---|---|
| Partición temporal | Aleatoria o *k-fold* | Sin fuga: se entrena con el pasado | 9.1 |
| 5 + 1 + 1 temporadas desde 2019/20 | Entrenar desde 2001/02 | Periodo con cuotas promedio; fútbol reciente | 9.1 |
| Calibrar K y k con 3 pliegues de ventana creciente | Ventana móvil; un solo pliegue | Usa todo lo anterior y no depende de una temporada | 9.3 |
| Elegir en validación, medir en prueba; presentar M0 | Presentar M4 | La ventaja de M4 fue mínima y no se sostuvo | 9.4 |
| LogLoss como métrica principal | Brier, RPS | Regla propia; mismo orden con las tres | 9.5 |
| MAE como métrica secundaria | MSE, devianza de Poisson | Fácil de explicar; premia la mediana | 9.6 |
| Bootstrap por partidos | Diebold–Mariano, bloques | Sin supuestos de normalidad; misma conclusión | 9.9 |

Las decisiones de todo el proyecto están reunidas en el [capítulo 19](19_decisiones_y_alternativas.md).

[← Cuotas y mercado](08_cuotas_y_mercado.md) · [Índice](README.md) · [Siguiente: código wc_predictor →](10_codigo_wc_predictor.md)
