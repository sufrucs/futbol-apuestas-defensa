# 12. Resultados y cómo interpretarlos

[← Notebook de análisis](11_codigo_analisis_notebook.md) · [Índice](README.md) · [Siguiente: el dashboard →](13_dashboard.md)

Las cifras de este capítulo salen de las salidas guardadas de `Analisis.ipynb` (§6 a §10), del tablero
(`datos_dashboard.py`) y del reporte. Las marcadas como **cálculo propio de la guía** se hicieron *después de la entrega*, con el código y los datos del
proyecto: no están en el notebook, el reporte ni el tablero, y se mencionan sólo si preguntan, aclarando que son
posteriores. El código de cada paso está en el [capítulo 11](11_codigo_analisis_notebook.md); las decisiones de
fondo, en el [capítulo 19](19_decisiones_y_alternativas.md); y el reporte entregado, en el
[capítulo 20](20_el_reporte_entregado.md).

## 12.1 Lo que muestran los datos (análisis exploratorio)

**Resultados históricos** (25 temporadas completas, 9,500 partidos; la base completa tiene 9,540, con los 40 que
lleva 2026/27): local **45.6 %**, empate **24.7 %**, visitante **29.7 %**. Goles por partido: 2.72 (local 1.53,
visitante 1.19).

**La localía es estable… salvo sin público:**

| Temporada | Gana local | Empate | Gana visitante | Comentario |
|---|---|---|---|---|
| Típica (promedio) | ≈ 45 % | ≈ 25 % | ≈ 30 % | |
| **2020/21** | **37.9 %** | 21.8 % | **40.3 %** | Estadios vacíos (COVID-19): **única** temporada en que ganan más los visitantes |
| 2024/25 (validación) | 40.8 % | 24.5 % | 34.7 % | Localía baja |
| 2025/26 (casi toda la prueba) | 42.6 % | 27.4 % | 30.0 % | Muchos empates (la prueba suma 39 partidos de 2026/27) |

**El favorito de las cuotas** (Bet365, 9,160 partidos con cuotas): gana **54.2 %**, empata 24.7 %, pierde 21.0 %.
El local es favorito en el 69.6 % de los partidos. **Implicación:** en fútbol, acertar ~50 % ya es
bueno; nadie acierta 80 %.

**La diferencia de Elo ordena los resultados** (2019–2026, 2,696 partidos en diez deciles de unos 270 cada
uno; Elo con K = 15):

| Decil | Diferencia de Elo (mediana) | Gana local | Empate | Gana visitante |
|---|---|---|---|---|
| 1 | −252 | **12.6 %** | 20.7 % | 66.7 % |
| 3 | −99 | 28.3 % | 26.8 % | 45.0 % |
| 5 | −20 | 45.7 % | 25.7 % | 28.6 % |
| 6 | +16 | 36.7 % | 31.1 % | 32.2 % |
| 8 | +99 | 54.1 % | 27.0 % | 18.9 % |
| 10 | +251 | **76.3 %** | 13.7 % | 10.0 % |

El local gana de **12.6 % a 76.3 %** del decil más bajo al más alto. Los deciles 5 y 6 (diferencias de Elo
cercanas a cero) no suben de forma pareja: 45.7 % y luego 36.7 %. No es un error: con unos 270 partidos por decil,
cada porcentaje tiene un error estándar de ≈ 3 puntos (cálculo propio), así que los saltos de pocos puntos entre
deciles vecinos son ruido; lo que importa es la tendencia.

Las curvas de local y visitante se cruzan en ≈ −50: **jugar en casa vale ≈ 50 puntos Elo** (50.0 con la
interpolación entre deciles que hace el tablero). Con la configuración anterior (K = 30) eran ≈ 60 (62.6): al
bajar K el Elo se mueve menos y los "puntos" son más chicos, así que esta cifra **sólo se compara con la misma K**
([capítulo 4](04_elo.md)).

**Las cuotas están calibradas** (ver [capítulo 8](08_cuotas_y_mercado.md)) y **los goles se
parecen a una Poisson** (ver [capítulo 6](06_poisson_y_regresion.md)).

## 12.2 Resultados del modelo

Se comparan **nueve predictores**: el azar, la referencia ingenua, las cinco especificaciones M0–M4 y el mercado
(apertura y cierre). Modelo y mercado se evalúan en los mismos partidos, con coeficientes estimados una sola vez
con el entrenamiento (1,897 partidos; K = 15 y k = 0).

### Validación (temporada 2024/25, 380 partidos)

| Predictor | LogLoss | Prob. media al resultado real | Aciertos | P(empate) media | MAE goles |
|---|---|---|---|---|---|
| Azar (1/3 cada uno) | 1.0986 | 33.3 % | 40.8 % | 33.3 % | — |
| Referencia ingenua | 1.0794 | 34.0 % | 40.8 % | 24.7 % | — |
| M0 · base | 0.9895 | 37.2 % | 53.2 % | 22.8 % | **0.918** |
| M1 · + forma | 0.9876 | 37.2 % | 52.4 % | 22.6 % | 0.922 |
| M2 · + tiros | 0.9807 | 37.5 % | 53.4 % | 22.2 % | 0.921 |
| M3 · + tiros a puerta | 0.9823 | 37.4 % | 52.4 % | 22.4 % | 0.921 |
| **M4 · completo** | **0.9786** | 37.6 % | 53.7 % | 22.2 % | 0.922 |
| Mercado · apertura | 0.9706 | 37.9 % | 54.2 % | 23.0 % | — |
| Mercado · cierre | 0.9667 | 38.0 % | 55.5 % | 23.3 % | — |

### Prueba (15-ago-2025 a 14-sep-2026, 419 partidos)

| Predictor | LogLoss | Prob. media al resultado real | Aciertos | P(empate) media | MAE goles |
|---|---|---|---|---|---|
| Azar | 1.0986 | 33.3 % | 41.5 % | 33.3 % | — |
| Referencia ingenua | 1.0868 | 33.7 % | 41.5 % | 24.7 % | — |
| **M0 · base** | **1.0331** | 35.6 % | 48.0 % | 23.6 % | 0.902 |
| M1 · + forma | 1.0347 | 35.5 % | 46.3 % | 23.6 % | 0.904 |
| M2 · + tiros | 1.0373 | 35.4 % | 47.5 % | 23.7 % | 0.902 |
| M3 · + tiros a puerta | 1.0339 | 35.6 % | 46.3 % | 24.1 % | **0.894** |
| M4 · completo | 1.0367 | 35.5 % | 47.5 % | 23.8 % | 0.899 |
| Mercado · apertura | 1.0200 | 36.1 % | 48.9 % | 24.5 % | — |
| Mercado · cierre | 1.0170 | 36.2 % | 48.9 % | 24.8 % | — |

(En la versión final el notebook evalúa en prueba **las cinco** especificaciones, M3 incluido; antes sólo M0, M2
y M4. El MAE de M3, con todos los decimales, es 0.894173; el de M0, 0.902306.)

### Diferencia de LogLoss contra M0 (negativo = mejor que M0)

| | M1 | M2 | M3 | M4 | Mercado |
|---|---|---|---|---|---|
| Validación | −0.0019 | −0.0088 | −0.0072 | −0.0109 | −0.0190 |
| Prueba | +0.0016 | +0.0043 | +0.0008 | +0.0037 | −0.0131 |

**Las variables adicionales ayudaron en validación y dejaron de ayudar en prueba**, mientras que el
mercado fue mejor que M0 en ambos periodos. Es la gráfica de "pesas" del tablero.

### El orden de los nueve predictores

| Periodo | De mejor a peor LogLoss |
|---|---|
| Validación | Mercado cierre (0.9667) · Mercado apertura (0.9706) · **M4 (0.9786)** · M2 (0.9807) · M3 (0.9823) · M1 (0.9876) · M0 (0.9895) · ingenua (1.0794) · azar (1.0986) |
| Prueba | Mercado cierre (1.0170) · Mercado apertura (1.0200) · **M0 (1.0331)** · M3 (1.0339) · M1 (1.0347) · M4 (1.0367) · M2 (1.0373) · ingenua (1.0868) · azar (1.0986) |

- **El orden de los cinco modelos casi se invierte entre periodos:** M0 es el último en validación y el primero
  en prueba; M2 es el segundo en validación y el último en prueba. En prueba el orden es **M0, M3, M1, M4, M2**.
- **Lo que no cambia:** el mercado queda por delante de todos los modelos en los dos periodos, y los cinco modelos
  quedan muy por encima de la referencia ingenua.
- **Las diferencias entre modelos son pequeñas** junto a las que los separan de la ingenua: entre el mejor y el
  peor de los cinco hay 0.0109 en validación y 0.0043 en prueba, mientras que los cinco quedan entre 0.09 y 0.10
  (validación) y ≈ 0.05 (prueba) por debajo de la ingenua.
- Con Brier y con RPS el orden de los predictores es el mismo que con el LogLoss (cálculo propio de la guía;
  [capítulo 9](09_evaluacion_y_validacion.md#95-logloss-la-métrica-principal)).

### Goles contra probabilidades: la tensión entre el MAE y el LogLoss

Las dos métricas **no eligen lo mismo**, y es lo que hace que el reporte concluya que su hipótesis se respalda
sólo parcialmente ([capítulo 20](20_el_reporte_entregado.md)):

| Periodo | Mejor LogLoss | Mejor MAE medio |
|---|---|---|
| Validación | M4 (0.978612) | **M0** (0.918332), que tiene el **peor** LogLoss de los cinco |
| Prueba | **M0** (1.033076) | **M3** (0.894173), 0.008133 menos que M0 |

Por qué no coinciden: el MAE juzga cada λ por separado, mientras que el 1X2 depende de las **dos** λ a la vez, y
además el error absoluto **premia la mediana, no la media**. La mediana de una Poisson con λ entre 0.7 y 1.7 es
**1 gol**, así que pronosticar siempre "1 gol" para los dos equipos, sin saber nada de ellos, da un MAE de
**0.894988 en prueba** (cálculo propio de la guía): **mejor que el de M0** (0.902306), M1, M2 y M4, y sólo 0.0008
peor que el de M3. Conclusión: **el MAE no sirve como métrica principal**; describe qué tan cerca quedan los goles
esperados, casi no distingue entre modelos y para el 1X2 manda el LogLoss
([9.6](09_evaluacion_y_validacion.md#96-mae-de-goles-y-por-qué-no-coincide-con-el-logloss)).

### Cuánto de la ventaja del mercado logra el modelo

$$
\text{fracción de la mejora}=\frac{\text{LogLoss ingenua}-\text{LogLoss M0}}{\text{LogLoss ingenua}-\text{LogLoss mercado}}
$$

| Periodo | Cálculo | Fracción |
|---|---|---|
| Prueba | (1.086791 − 1.033076) / (1.086791 − 1.020000) = 0.053715 / 0.066791 | **80 %** (80.4) |
| Validación | (1.079361 − 0.989547) / (1.079361 − 0.970552) = 0.089814 / 0.108809 | **83 %** (82.5) |

La cifra es **incierta** (cálculo propio de la guía, bootstrap por partidos): su IC 95 % va de **54 % a 101 %**
en prueba y de 68 % a 94 % en validación. Es un cociente de diferencias pequeñas: con 419 partidos, "cerca de
80 %" no distingue entre "poco más de la mitad" y "todo". Con M4 en lugar de M0 sería 75 % en prueba. Más en
[D37 del capítulo 19](19_decisiones_y_alternativas.md#d37-parte-de-la-ventaja-del-mercado-80--para-comunicar--razonada).

### ¿Son reales las diferencias? Bootstrap

Diferencia de LogLoss A − B (negativo = A mejor), bootstrap pareado por partidos: 10,000 remuestreos, semilla
2026 ([9.9](09_evaluacion_y_validacion.md#99-son-significativas-las-diferencias-bootstrap)).

| Periodo | Comparación (A − B) | Diferencia | IC 95 % | ¿Distinta de cero? |
|---|---|---|---|---|
| Prueba | M0 − ingenua | −0.054 | −0.086 a −0.022 | **Sí**: el modelo es claramente mejor |
| Prueba | M0 − mercado | +0.013 | −0.0005 a +0.026 | No, por muy poco |
| Prueba | M4 − M0 | +0.004 | −0.006 a +0.014 | No |
| Prueba | M4 − mercado | +0.017 | +0.003 a +0.030 | Sí |
| Validación | M4 − M0 | −0.011 | −0.021 a −0.00005 | **Sí, por un margen mínimo** |
| Validación | M0 − mercado | +0.019 | +0.005 a +0.033 | Sí |
| Validación + prueba (799 partidos) | M0 − mercado | +0.016 | **+0.006 a +0.025** | **Sí** |

**Lo robusto:** M0 supera a la referencia ingenua, y con validación y prueba juntas el mercado supera a M0.

**Lo frágil** (comprobaciones de la guía, [D36](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)):
las dos comparaciones **al límite** cambian según el método.

| Comparación | Bootstrap por partidos (tablero) | Otros métodos |
|---|---|---|
| M4 − M0 en validación (hoy "Sí") | Excluye el cero por 0.00005; con 100 semillas distintas lo excluye en **83 de 100** | Diebold–Mariano: p = 0.048 (al límite); bootstrap por fechas o por semanas: el intervalo llega a +0.0002 y +0.0003, **ya incluye el cero** |
| M0 − mercado en prueba (hoy "No") | Incluye el cero por 0.0005; con 100 semillas, **ninguna** lo excluye | Diebold–Mariano: p = 0.059 (al límite); bootstrap por semanas: el intervalo empieza en **+0.0002** |

Por eso la lectura de M4 − M0 en validación es "significativa por un margen mínimo y frágil", **no robusta**: en la
versión anterior (K = 30, k = 10) ni siquiera lo era (−0.0084, IC −0.0193 a +0.0022), y con K = 15 y k = 0 apenas
cruza el umbral.

**Otras comprobaciones de la guía (todas posteriores a la entrega):**

| Comprobación | Resultado | ¿Cambia la conclusión? |
|---|---|---|
| Brier o RPS en lugar de LogLoss | Mismo orden de los predictores | No |
| Normalización de Shin en lugar de la proporcional ([cap. 8](08_cuotas_y_mercado.md)) | LogLoss del mercado 0.970635 y 1.020971 (en lugar de 0.970552 y 1.020000) | No |
| Recuperar los 90 partidos de 2003/04 y 2004/05 en la limpieza | El modelo cambia en la quinta cifra decimal | No |
| K = 30 y k = 10 en lugar de K = 15 y k = 0 | Ver [la subsección sobre la configuración anterior](#la-configuración-anterior-de-k-y-k-fuera-de-muestra) | No |

### Qué pesa en M0: coeficientes y efectos

Coeficientes de M0 estimados con el entrenamiento (1,897 partidos), con su valor p, y efecto de subir **una
desviación estándar** cada variable sobre los goles esperados, $e^{\beta\cdot DE}-1$, con su IC 95 %
(explicación completa en [6.4](06_poisson_y_regresion.md#64-cómo-interpretar-los-coeficientes)):

| Variable | Local: β (p) | Efecto de +1 DE en los goles del local | Visitante: β (p) | Efecto de +1 DE en los goles del visitante |
|---|---|---|---|---|
| Constante | 0.0433 (0.621) | — | 0.0264 (0.781) | — |
| Diferencia de Elo (÷ 400) | 0.6283 (< 0.001) | **+26.7 %** [+21.0, +32.8] | −0.6854 (< 0.001) | **−22.8 %** [−26.6, −18.7] |
| Goles a favor del propio equipo | 0.1678 (< 0.001) | +10.7 % [+6.3, +15.4] | 0.1079 (0.004) | +6.9 % [+2.2, +11.9] |
| Goles en contra del rival | 0.0778 (**0.0498**) | +4.0 % [0.0, +8.1] | 0.0281 (0.506) | +1.5 % [−2.8, +5.9] |

- **La diferencia de Elo es la variable que más pesa.** Una desviación estándar son 150.8 puntos de Elo en el
  entrenamiento (con K = 30 eran 167.0); +400 puntos multiplican por e^0.6283 ≈ **1.87** los goles esperados del
  local (el ejemplo del reporte).
- **Los goles de la temporada aportan menos que antes.** Con K = 30 y k = 10 los coeficientes del local eran 0.408
  (Elo) y 0.334 (goles a favor); con K = 15 y k = 0, 0.628 y 0.168. Lectura: con K = 15 el Elo resume más de la
  fuerza del equipo. Los goles en contra del rival pasaron de significativos (p = 0.008) a estar **en el límite**
  del 5 % (local, p = 0.0498) o a no serlo (visitante, p = 0.506): no hay que presentarlos como un hallazgo firme.
- **Las constantes no se distinguen de cero** (p = 0.621 y 0.781): la ventaja de jugar en casa no está en la
  constante, sino en la suma de los términos. Con dos equipos idénticos, M0 da λ = 1.486 al local y 1.248 al
  visitante ([6.3](06_poisson_y_regresion.md#63-las-dos-ecuaciones-del-proyecto)).
- **La dispersión de Pearson es ≈ 1** (0.996 en la ecuación del local y 1.036 en la del visitante): la varianza de
  los goles es la que supone la Poisson, sin sobredispersión que corregir.
- **Son asociaciones, no causas:** el modelo es predictivo ("la diferencia de Elo está asociada a más goles").

### La configuración anterior de K y k fuera de muestra

Pregunta previsible, sobre todo de quien vio la primera versión del tablero (K = 30 y k = 10): *¿y qué habría
pasado con la configuración anterior?* Es un **cálculo propio de la guía, posterior a la entrega** (no está en el
notebook, el reporte ni el tablero): M0 con K = 30 y k = 10 sobre la **misma base** de 9,540 partidos, evaluado
con el mismo código ([capítulo 4](04_elo.md), "¿La calibración mejoró los resultados finales?").

| LogLoss de M0 | K = 15, k = 0 (vigente) | K = 30, k = 10 (anterior) | Vigente − anterior (IC 95 %) |
|---|---|---|---|
| Calibración (2021/22–2023/24, 1,140 partidos) | **0.959558** | 0.962178 | −0.0026 |
| Validación 2024/25 (380) | 0.989547 | **0.983636** | +0.0059 [−0.0018, +0.0135] |
| Prueba (419) | 1.033076 | **1.030640** | +0.0024 [−0.0049, +0.0099] |
| Validación + prueba (799) | | | +0.0041 [−0.0012, +0.0093] |

- La configuración vigente ganó **donde se eligió** (la calibración), pero en validación y prueba la anterior dio
  un LogLoss **un poco menor**. Las diferencias son pequeñas y **no concluyentes**: los tres intervalos incluyen
  el cero.
- **El efecto de K y k es pequeño e inestable entre temporadas:** las 35 combinaciones de la rejilla caben en
  0.0055 de LogLoss, K = 20 queda a 0.000031 de K = 15, y los pliegues no coinciden (2022/23 prefería K = 35).
- **La conclusión frente al mercado no cambia.** Con la configuración anterior, M0 habría logrado ≈ 84 % (prueba)
  y ≈ 88 % (validación) de la mejora del mercado, contra 80 % y 83 % con la vigente, y habría quedado también por
  detrás de él (0.970552 en validación y 1.020000 en prueba).
- **Volver a K = 30 sería elegir mirando la prueba:** la prueba dejaría de ser una evaluación honesta. El
  procedimiento correcto es fijar la regla de selección antes y reportar lo que salga.
- **Matiz que hay que decir:** K = 15 quedó en el **borde inferior** de la rejilla (K < 15 no se probó) y k = 0 está
  en el extremo natural (no hay k negativa). Por eso **no se debe decir "K = 15 es el óptimo"**, sino "el mejor de
  los valores probados, en un rango donde K importa poco".

> **Decisión:** mantener K = 15 y k = 0, elegidos por validación temporal en las tres temporadas anteriores a la
> validación, aunque fuera de muestra la configuración anterior (K = 30, k = 10) habría dado un LogLoss de M0 un poco
> menor (0.983636 / 1.030640 contra 0.989547 / 1.033076). · **Alternativas:** (a) volver a K = 30 y k = 10 — a favor:
> LogLoss menor en validación y en prueba; en contra: sería elegir mirando la prueba, que dejaría de ser una medición
> honesta, y las diferencias no son concluyentes (los intervalos incluyen el cero); (b) quedarse con el K que gane en
> validación (K = 35 habría sido mejor ahí, 0.980894, y peor en prueba, 1.035075) — a favor: usa un periodo posterior a
> la calibración; en contra: ningún valor gana en los dos periodos y la validación ya sirve para elegir entre M0 y M4;
> (c) ampliar la rejilla (K < 15) y recalibrar con los mismos tres pliegues — a favor: K = 15 quedó en el borde; en
> contra: no se hizo, y K parece importar poco. · **Por qué ésta:** la regla de selección se fijó antes de mirar la
> validación y la prueba, y es la única que no usa la evaluación para decidir; el efecto de K y k es del tamaño del
> ruido entre temporadas (la rejilla entera cabe en 0.0055 y los pliegues no coinciden); y la conclusión no depende de
> ella: con cualquiera de las dos configuraciones M0 queda detrás del mercado. · **Si preguntan:** "Elegimos K y k con
> validación temporal en tres temporadas anteriores. Después comprobamos que la configuración anterior habría salido
> apenas mejor en validación y prueba, pero la diferencia no es significativa, y cambiar por eso sería elegir mirando la
> prueba. K importa poco y la conclusión frente al mercado es la misma; no decimos que K = 15 sea el óptimo, sino el
> mejor de los que probamos."

## 12.3 Las cinco conclusiones

1. **Las estadísticas previas sí anticipan resultados.** Todos los modelos superan con claridad a la
   referencia ingenua en los dos periodos (M0 − ingenua en prueba: −0.054, IC 95 % −0.086 a −0.022).
2. **El mercado sabe un poco más.** Tiene menor LogLoss en validación y en prueba. Con ambos
   periodos juntos (799 partidos), la brecha M0 − mercado es **+0.016 (IC +0.006 a +0.025)**:
   pequeña pero distinta de cero. En prueba sola es +0.013 (IC −0.0005 a +0.026): no concluyente, por muy poco.
   En una frase: el modelo **se acerca al mercado sin superarlo**.
3. **El modelo logra el 80 % de la mejora del mercado** sobre la referencia ingenua en prueba
   (83 % en validación). Es una cifra incierta (IC bootstrap de 54 % a 101 % en prueba) y no quiere decir
   "80 % tan bueno como el mercado".
4. **Más variables no generalizan, y la ventaja de M4 es frágil.** M4 ganó en validación por un margen mínimo
   (−0.0109; el IC llega a −0.00005) que sale "significativo" en 83 de 100 semillas y cambia con otros métodos; en
   prueba el orden es M0, M3, M1, M4, M2 y M4 − M0 no es concluyente (+0.0037). Las diferencias entre
   especificaciones son del tamaño del ruido. Por parsimonia, M0.
5. **El periodo de prueba fue más difícil para todos** (más empates: 28.2 % contra 24.5 %). Eso explica en parte
   que todos los LogLoss suban, incluido el del mercado.

**Dos matices que acompañan a las cinco** (para decirlos antes de que los pregunten):

- **K y k.** Se calibraron con una rejilla de 35 combinaciones, sólo con M0, y K = 15 quedó en el borde inferior; el
  efecto de K y k es pequeño e inestable entre temporadas
  ([subsección de 12.2](#la-configuración-anterior-de-k-y-k-fuera-de-muestra)). No es "el óptimo".
- **Goles contra probabilidades.** En el MAE gana otro modelo que en el LogLoss (M0 en validación, M3 en prueba), y
  pronosticar siempre 1 gol bate a M0 en MAE. Por eso el reporte concluye que su hipótesis se respalda **parcialmente**
  y el tablero, que el modelo queda **cerca del mercado sin superarlo**: son dos lecturas de la misma evidencia
  ([capítulo 20](20_el_reporte_entregado.md)).

## 12.4 ¿Por qué pierde el modelo contra el mercado? (dónde está la brecha)

Aporte de cada tipo de resultado a la brecha M0 − mercado (validación + prueba, 799 partidos):

| Resultado real | Partidos | Aporte | P media que le dio el modelo | … el mercado |
|---|---|---|---|---|
| Victoria local | 329 | **+0.0185** (el mercado mejor) | 49.7 % | 52.0 % |
| Empate | 211 | **+0.0078** (el mercado mejor) | 23.5 % | 24.3 % |
| Victoria visitante | 259 | **−0.0104** (el modelo mejor) | 41.0 % | 40.3 % |
| **Total** | 799 | **+0.0159** | | |

**Lectura:** la brecha está ahora sobre todo en las **victorias locales**: aportan +0.0185, más que el total,
porque el modelo compensa con −0.0104 en las visitantes. Con la configuración anterior (K = 30, k = 10) las
victorias locales y los empates pesaban casi igual (+0.0111 y +0.0103). Partido a partido, el mercado le da más
probabilidad que M0 al resultado real en el **57.8 %** de los partidos: en 64.7 % de las victorias locales, en
69.7 % de los empates y sólo en 39.4 % de las victorias visitantes.

Tres explicaciones posibles, con lo que muestran los datos de cada una:
1. **Empates (la parte más chica):** aportan +0.0078 de los +0.0159. El modelo los subestima en validación
   (P(empate) media de 22.8 % contra 24.5 % reales) y en prueba (23.6 % contra 28.2 %), y el mercado también,
   aunque menos (24.5 % en prueba). Pero **no está probado que la causa sea el supuesto de independencia**
   ([cap. 7](07_de_goles_a_probabilidades.md#76-la-debilidad-del-supuesto-los-empates)): en el entrenamiento el
   modelo no los subestima (22.7 % esperado contra 22.8 % real) y el parámetro ρ de Dixon–Coles sale ≈ −0.008,
   indistinguible de cero (comprobación de la guía). Lo que cambió es la tasa de empates: 22.8 % en el
   entrenamiento contra 24.5 % en 2024/25 y 27.4 % en 2025/26.
2. **Favoritos:** M0 es algo sobreconfiado cuando asigna 60–80 % (tabla de abajo). Con pocos pronósticos en esos
   grupos es una señal consistente, no una prueba.
3. **Información:** el mercado conoce alineaciones, lesiones y noticias; el modelo no. Consistente con eso, el
   mercado de **cierre** es aún mejor que el de apertura (0.9667 contra 0.9706 en validación; 1.0170 contra 1.0200
   en prueba).

### Calibración: lo que dice cada uno contra lo que ocurre

Con validación + prueba (799 partidos × 3 = 2,397 pronósticos), en grupos de 10 puntos porcentuales (se muestran
los grupos con al menos 30 pronósticos; [9.8](09_evaluacion_y_validacion.md#98-calibración-del-modelo-vs-el-mercado)):

| Grupo | M0 dijo (media) | Ocurrió | Pronósticos | Mercado dijo (media) | Ocurrió | Pronósticos |
|---|---|---|---|---|---|---|
| 0–10 % | 7.3 % | 7.5 % | 40 | 7.4 % | 5.6 % | 54 |
| 10–20 % | 16.3 % | 16.8 % | 321 | 15.8 % | 15.7 % | 376 |
| 20–30 % | 24.6 % | 26.4 % | 990 | 25.2 % | 27.1 % | 964 |
| 30–40 % | 35.1 % | 36.3 % | 353 | 35.1 % | 36.1 % | 330 |
| 40–50 % | 44.6 % | 40.6 % | 283 | 44.9 % | 43.5 % | 246 |
| 50–60 % | 54.5 % | 54.2 % | 214 | 55.0 % | 48.3 % | 209 |
| 60–70 % | 64.4 % | **57.0 %** | 135 | 65.0 % | 63.7 % | 135 |
| 70–80 % | 74.1 % | **68.1 %** | 47 | 74.2 % | 70.3 % | 64 |

**Lectura:** M0 queda cerca de lo que ocurre hasta el 40 % y en el grupo de 50–60 %, y es algo **sobreconfiado
con los favoritos**: cuando dice 64.4 % ocurre 57.0 %, y cuando dice 74.1 %, 68.1 % (también se pasa un poco en el
grupo de 40–50 %: dice 44.6 % y ocurre 40.6 %). El mercado está mejor calibrado en esa zona, aunque tampoco es
perfecto (en el grupo de 50–60 % dice 55.0 % y ocurre 48.3 %). Con 135 y 47 pronósticos, el error estándar de las
dos frecuencias altas es de ≈ 4 y ≈ 7 puntos (cálculo propio): sirve para explicar por qué el mercado gana, no
para afirmarlo con certeza.

**¿Y la pandemia?** Reentrenando M0 sin los 472 partidos a puerta cerrada (17-jun-2020 a 23-may-2021), la
probabilidad media de victoria local en prueba sube de 42.6 % a 44.0 %, pero el LogLoss **casi no cambia**
(1.0331 → 1.0328 en prueba; 0.9895 → 0.9900 en validación: décimas de milésima, sin dirección clara), mientras que
la brecha con el mercado en prueba es de 0.013. La pandemia no explica la brecha
([D38](19_decisiones_y_alternativas.md#d38-sensibilidad-sin-público--probada)).

**Modelo y mercado coinciden en lo esencial:** la correlación entre sus probabilidades de victoria
local en prueba es **r = 0.939** (≈ 0.94). Difieren en los matices, que es donde el mercado gana.

## 12.5 Qué decir y qué NO decir

| ✅ Decir | ❌ No decir | Por qué |
|---|---|---|
| "El modelo logra el 80 % de la mejora del mercado sobre la referencia ingenua" | "El modelo es 80 % tan bueno como el mercado" | El 80 % es una fracción de la **mejora**, no del desempeño total, y es incierta (IC bootstrap de 54 % a 101 % en prueba) |
| "El modelo se acerca al mercado sin superarlo" | "El modelo **casi empata** con el mercado" | Con validación y prueba juntas el mercado es mejor (+0.016, IC +0.006 a +0.025) y el modelo no lo supera en ningún periodo; "casi empata" le quita fuerza a una brecha que sí es distinta de cero |
| "El mercado fue mejor de forma consistente; con ambos periodos la diferencia es significativa" | "El modelo es significativamente peor en prueba" | En prueba sola el intervalo incluye el cero por muy poco (−0.0005), aunque esa lectura cambia con el método |
| "M4 ganó en validación por un margen mínimo; en prueba no se sostuvo y M0 fue el mejor de los cinco; las diferencias están dentro del ruido" | "M4 − M0 es una diferencia **robusta**", ni "M4 es mejor" o "M0 es mejor" como verdad absoluta | El intervalo de validación apenas excluye el cero (−0.00005): sale significativo en 83 de 100 semillas y deja de serlo con bootstrap por fechas o semanas; en prueba no es concluyente. Y elegir a M0 usa la prueba: hay que confirmarlo con otra temporada |
| "K = 15 y k = 0 salieron de una calibración con tres temporadas; K = 15 fue el mejor de los valores probados, pero quedó en el borde y K importa poco" | "**K = 15 es el óptimo**" | Está en el borde de la rejilla (K < 15 no se probó), K = 20 casi empata (+0.000031) y fuera de muestra la configuración anterior salió algo mejor (diferencia no significativa) |
| "El MAE mide qué tan cerca quedan los goles esperados; para el 1X2 manda el LogLoss" | "M3 es el mejor modelo porque tiene el menor MAE" | El MAE premia la mediana: pronosticar siempre 1 gol da 0.894988 en prueba, mejor que M0 (0.902306) |
| "Nuestra hipótesis se respalda parcialmente (reporte); frente al mercado, el modelo queda cerca sin superarlo (tablero)" | "La hipótesis se cumplió" o "fracasó" | Reporte y tablero hacen preguntas distintas sobre el mismo experimento ([capítulo 20](20_el_reporte_entregado.md)) |
| "M0 es algo sobreconfiado con los favoritos; el mercado está mejor calibrado en esa zona" | "El mercado está perfectamente calibrado" o "M0 está mal calibrado" | En el grupo de 50–60 % el mercado dice 55.0 % y ocurre 48.3 %; M0 queda cerca hasta el 40 %. Los grupos altos tienen pocos pronósticos (135 y 47) |
| "La diferencia de Elo está **asociada** a más goles" | "Subir el Elo **causa** más goles" | Es un modelo predictivo, no causal |
| "No evaluamos rentabilidad; es un proyecto académico" | "Con esto se puede ganar dinero" | No se probó, y el modelo ni siquiera iguala al mercado |
| "El marcador más probable es 1–1, pero el resultado más probable es la victoria local" | "El modelo predice que quedarán 1–1" | El marcador modal tiene solo ≈ 12 % de probabilidad (11.8 % en Arsenal–Man City) |

[← Notebook de análisis](11_codigo_analisis_notebook.md) · [Índice](README.md) · [Siguiente: el dashboard →](13_dashboard.md)
