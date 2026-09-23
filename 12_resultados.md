# 12. Resultados y cómo interpretarlos

[← Notebook de análisis](11_codigo_analisis_notebook.md) · [Índice](README.md) · [Siguiente: el dashboard →](13_dashboard.md)

## 12.1 Lo que muestran los datos (análisis exploratorio)

**Resultados históricos** (25 temporadas completas, 9,410 partidos): local **45.6 %**, empate
**24.7 %**, visitante **29.8 %**. Goles por partido: 2.72 (local 1.53, visitante 1.19).

**La localía es estable… salvo sin público:**

| Temporada | Gana local | Empate | Gana visitante | Comentario |
|---|---|---|---|---|
| Típica (promedio) | ≈ 45 % | ≈ 25 % | ≈ 30 % | |
| **2020/21** | **37.9 %** | 21.8 % | **40.3 %** | Estadios vacíos (COVID-19): **única** temporada en que ganan más los visitantes |
| 2024/25 (validación) | 40.8 % | 24.5 % | 34.7 % | Localía baja |
| 2025/26 (prueba) | 42.6 % | 27.4 % | 30.0 % | Muchos empates |

**El favorito de las cuotas** (Bet365, 9,070 partidos): gana **54.3 %**, empata 24.6 %, pierde 21.0 %.
El local es favorito en el 69.5 % de los partidos. **Implicación:** en fútbol, acertar ~50 % ya es
bueno; nadie acierta 80 %.

**La diferencia de Elo ordena los resultados** (2019–2026, deciles):

| Decil | Diferencia de Elo (mediana) | Gana local | Empate | Gana visitante |
|---|---|---|---|---|
| 1 | −272 | 14.1 % | 20.0 % | 65.9 % |
| 3 | −110 | 30.9 % | 25.3 % | 43.9 % |
| 5 | −25 | 39.8 % | 24.9 % | 35.3 % |
| 6 | +20 | 47.4 % | 21.5 % | 31.1 % |
| 8 | +108 | 57.0 % | 25.2 % | 17.8 % |
| 10 | +272 | **76.3 %** | 15.6 % | 8.1 % |

Las curvas de local y visitante se cruzan en ≈ −60: **jugar en casa vale ≈ 60 puntos Elo**.

**Las cuotas están calibradas** (ver [capítulo 8](08_cuotas_y_mercado.md)) y **los goles se
parecen a una Poisson** (ver [capítulo 6](06_poisson_y_regresion.md)).

## 12.2 Resultados del modelo

### Validación (temporada 2024/25, 380 partidos)

| Predictor | LogLoss | Prob. media al resultado real | Aciertos | P(empate) media | MAE goles |
|---|---|---|---|---|---|
| Azar (1/3 cada uno) | 1.0986 | 33.3 % | 40.8 % | 33.3 % | — |
| Referencia ingenua | 1.0794 | 34.0 % | 40.8 % | 24.7 % | — |
| M0 · base | 0.9837 | 37.4 % | 53.4 % | 21.9 % | 0.928 |
| M1 · + forma | 0.9823 | 37.4 % | 53.2 % | 22.0 % | 0.928 |
| M2 · + tiros | 0.9770 | 37.6 % | 53.9 % | 21.8 % | **0.924** |
| M3 · + tiros a puerta | 0.9772 | 37.6 % | 54.5 % | 22.0 % | 0.925 |
| **M4 · completo** | **0.9753** | 37.7 % | 53.9 % | 21.8 % | 0.925 |
| Mercado · apertura | 0.9706 | 37.9 % | 54.2 % | 23.0 % | — |
| Mercado · cierre | 0.9667 | 38.0 % | 55.5 % | 23.3 % | — |

### Prueba (15-ago-2025 a 14-sep-2026, 419 partidos)

| Predictor | LogLoss | Prob. media al resultado real | Aciertos | P(empate) media | MAE goles |
|---|---|---|---|---|---|
| Azar | 1.0986 | 33.3 % | 41.5 % | 33.3 % | — |
| Referencia ingenua | 1.0868 | 33.7 % | 41.5 % | 24.7 % | — |
| **M0 · base** | **1.0306** | 35.7 % | 48.0 % | 23.7 % | 0.901 |
| M1 · + forma | 1.0314 | 35.7 % | 47.7 % | 23.7 % | 0.901 |
| M2 · + tiros | 1.0352 | 35.5 % | 48.7 % | 23.8 % | 0.901 |
| M3 · + tiros a puerta | 1.0326 | 35.6 % | 46.5 % | 24.1 % | **0.895** |
| M4 · completo | 1.0344 | 35.5 % | 48.2 % | 23.9 % | 0.898 |
| Mercado · apertura | 1.0200 | 36.1 % | 48.9 % | 24.5 % | — |
| Mercado · cierre | 1.0170 | 36.2 % | 48.9 % | 24.8 % | — |

(El notebook evaluó en prueba M0, M2 y M4; M1 y M3 se agregan con el mismo código para completar.)

### Diferencia de LogLoss contra M0 (negativo = mejor que M0)

| | M1 | M2 | M3 | M4 | Mercado |
|---|---|---|---|---|---|
| Validación | −0.0014 | −0.0067 | −0.0065 | −0.0084 | −0.0131 |
| Prueba | +0.0009 | +0.0046 | +0.0020 | +0.0039 | −0.0106 |

**Las variables adicionales ayudaron en validación y dejaron de ayudar en prueba**, mientras que el
mercado fue mejor que M0 en ambos periodos. Es la gráfica de "pesas" del tablero.

## 12.3 Las cinco conclusiones

1. **Las estadísticas previas sí anticipan resultados.** Todos los modelos superan con claridad a la
   referencia ingenua (M0 − ingenua en prueba: −0.056, IC 95 % −0.086 a −0.026).
2. **El mercado sabe un poco más.** Tiene menor LogLoss en validación y en prueba. Con ambos
   periodos juntos (799 partidos), la brecha M0 − mercado es **+0.012 (IC +0.002 a +0.022)**:
   pequeña pero distinta de cero.
3. **El modelo logra el 84 % de la mejora del mercado** sobre la referencia ingenua en prueba
   (88 % en validación).
4. **Más variables no generalizan.** M4 ganó en validación, M0 en prueba; las diferencias entre
   especificaciones caen dentro del ruido. Por parsimonia, M0.
5. **El periodo de prueba fue más difícil para todos** (más empates: 28.2 % contra 24.5 %). Por eso
   todos los LogLoss suben, incluido el del mercado.

## 12.4 ¿Por qué pierde el modelo contra el mercado? (dónde está la brecha)

Aporte de cada tipo de resultado a la brecha M0 − mercado (validación + prueba, 799 partidos):

| Resultado real | Partidos | Aporte | P media que le dio el modelo | … el mercado |
|---|---|---|---|---|
| Victoria local | 329 | **+0.011** (el mercado mejor) | 50.4 % | 52.0 % |
| Empate | 211 | **+0.010** (el mercado mejor) | 23.2 % | 24.3 % |
| Victoria visitante | 259 | **−0.010** (el modelo mejor) | 40.9 % | 40.4 % |
| **Total** | 799 | **+0.012** | | |

Tres explicaciones, todas con evidencia:
1. **Empates:** el modelo los subestima por el supuesto de independencia ([cap. 7](07_de_goles_a_probabilidades.md)).
2. **Favoritos:** el modelo es sobreconfiado cuando asigna 60–80 % ([cap. 9](09_evaluacion_y_validacion.md)).
3. **Información:** el mercado conoce alineaciones, lesiones y noticias; el modelo no. Consistente con eso, el mercado de **cierre** es aún mejor que el de apertura.

**¿Y la pandemia?** Reentrenando M0 sin los 472 partidos a puerta cerrada, la probabilidad media de
victoria local en prueba sube de 42.9 % a 44.1 %, pero el LogLoss **no mejora** (1.0306 → 1.0311).
La pandemia no explica la brecha.

**Modelo y mercado coinciden en lo esencial:** la correlación entre sus probabilidades de victoria
local en prueba es **r = 0.93**.

## 12.5 Qué decir y qué NO decir

| ✅ Decir | ❌ No decir | Por qué |
|---|---|---|
| "El modelo logra el 84 % de la mejora del mercado sobre la referencia ingenua" | "El modelo es 84 % tan bueno como el mercado" | El 84 % es una fracción de la **mejora**, no del desempeño total |
| "El mercado fue mejor de forma consistente; con ambos periodos la diferencia es significativa" | "El modelo es significativamente peor en prueba" | En prueba sola el intervalo incluye el cero |
| "M4 ganó en validación pero no en prueba; las diferencias están dentro del ruido" | "M4 es mejor" o "M0 es mejor" como verdad absoluta | Ninguna diferencia M0–M4 es concluyente |
| "La diferencia de Elo está **asociada** a más goles" | "Subir el Elo **causa** más goles" | Es un modelo predictivo, no causal |
| "No evaluamos rentabilidad; es un proyecto académico" | "Con esto se puede ganar dinero" | No se probó, y el modelo ni siquiera iguala al mercado |
| "El marcador más probable es 1–1, pero el resultado más probable es la victoria local" | "El modelo predice que quedarán 1–1" | El marcador modal tiene solo ≈ 12 % de probabilidad |
