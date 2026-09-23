# 9. Evaluación y validación

[← Cuotas y mercado](08_cuotas_y_mercado.md) · [Índice](README.md) · [Siguiente: código wc_predictor →](10_codigo_wc_predictor.md)

## 9.1 Partición temporal: entrenamiento, validación y prueba

| Conjunto | Periodo | Partidos | Para qué se usa |
|---|---|---|---|
| Entrenamiento | 1-ago-2019 a 31-jul-2024 (5 temporadas) | 1,897 | Estimar los coeficientes de las regresiones |
| Validación | temporada 2024/25 | 380 | Comparar las 5 especificaciones (M0–M4) |
| Prueba | 15-ago-2025 a 14-sep-2026 | 419 (380 de 2025/26 + 39 de 2026/27) | Evaluación final, con partidos que el modelo nunca vio |

**Los coeficientes se estiman una sola vez** con entrenamiento y no se reestiman para validación
ni prueba.

**¿Por qué temporal y no aleatoria?** En datos ordenados en el tiempo, una partición aleatoria
metería partidos de 2025 en el entrenamiento y evaluaría con partidos de 2020: el modelo "vería el
futuro" (**fuga de información**) y el desempeño se sobreestimaría. La partición temporal imita
el uso real: ajustar con el pasado y pronosticar el futuro.

**¿Por qué tres conjuntos?** Si se eligiera el mejor modelo mirando la prueba, la prueba dejaría
de ser una evaluación honesta: el ganador habría sido elegido por suerte en esos mismos datos. La
validación sirve para elegir; la prueba, para medir.

## 9.2 Fuga de información (*data leakage*): cómo se evitó

| Posible fuga | Cómo se evita en el proyecto |
|---|---|
| Usar estadísticas del mismo partido (tiros, goles) como predictores | Solo se usan promedios de partidos **anteriores** |
| Promedios o Elo calculados con partidos futuros | `df_pre = historial[date < fecha]` en cada partido; el Elo se actualiza después de cada día |
| Partición aleatoria | Partición por fechas |
| Usar las cuotas como predictor | Las cuotas son solo referencia |
| Elegir el modelo con la prueba | La elección formal se hizo en validación (ver 9.3) |

`crear_variables_partido` incluso **verifica** que no se cuele el futuro: si `df_pre` contiene
alguna fecha igual o posterior a la del partido, lanza un error.

## 9.3 La selección de modelo (un punto delicado)

- En **validación**, el mejor fue **M4** (LogLoss 0.9753 contra 0.9837 de M0).
- En **prueba**, se evaluaron M0, M2 y M4, y el mejor fue **M0** (1.0306 contra 1.0344 de M4).

¿Cuál es "el modelo"? La forma honesta de explicarlo:

> "La validación eligió M4, pero en prueba su ventaja no se sostuvo: M0 fue mejor. Las diferencias
> entre especificaciones son menores al ruido (el intervalo bootstrap de M4 − M0 incluye el cero en
> ambos periodos). Por parsimonia (3 variables contra 9, menos multicolinealidad) preferimos M0,
> sabiendo que esa preferencia usa información de prueba y habría que confirmarla con la siguiente
> temporada."

## 9.4 LogLoss: la métrica principal

$$
\text{LogLoss} = -\frac{1}{N} \sum_{i=1}^{N} \log \hat p_{i,\,y_i}
$$

donde $\hat p_{i,y_i}$ es la probabilidad que el modelo le asignó **al resultado que ocurrió**
en el partido $i$. **Menor es mejor.**

**Ejemplos con un solo partido:**

| Pronóstico (local / empate / visita) | Qué pasó | Pérdida $-\log \hat p$ |
|---|---|---|
| 50 % / 25 % / 25 % | Ganó el local | $-\ln 0.50 = 0.693$ |
| 50 % / 25 % / 25 % | Ganó el visitante | $-\ln 0.25 = 1.386$ |
| 90 % / 5 % / 5 % (muy seguro) | Ganó el visitante | $-\ln 0.05 = 3.00$ ← castigo fuerte |
| 33.3 % / 33.3 % / 33.3 % (azar) | Cualquiera | $-\ln(1/3) = 1.099$ |

**¿Por qué LogLoss?**
1. Evalúa **probabilidades completas**, no solo si se acertó el resultado más probable.
2. Castiga fuerte la **sobreconfianza**: equivocarse diciendo 90 % cuesta mucho.
3. Es una **regla de puntuación propia**: se minimiza reportando las probabilidades verdaderas, así
   que no se puede "hacer trampa" exagerando.

**Traducción intuitiva:** $e^{-\text{LogLoss}}$ es la probabilidad **promedio (geométrica)** que
se le dio al resultado real. M0 en prueba: $e^{-1.031} = 35.7\,\%$; mercado: 36.1 %; azar: 33.3 %.
Parecen cercanos, pero en fútbol cada décima es difícil.

**Referencias útiles:** azar = ln 3 ≈ **1.099**; referencia ingenua ≈ 1.08–1.09; modelo ≈ 0.98–1.03;
mercado ≈ 0.97–1.02.

```python
from sklearn.metrics import log_loss
log_loss(y_observado, P, labels=[0, 1, 2])     # y: 0 = local, 1 = empate, 2 = visita
```

```r
logloss <- function(P, y) -mean(log(P[cbind(seq_along(y), y)]))   # y: 1, 2, 3 (columna)
# alternativa con paquetes: yardstick::mn_log_loss()
```

`P[cbind(filas, columnas)]` toma, de cada fila, la probabilidad de la columna que ocurrió (en
Python se logra con indexación avanzada `P[np.arange(n), y]`).

## 9.5 MAE de goles

$$
\text{MAE}_{\text{promedio}} = \frac{1}{2N} \sum_{i=1}^{N} \left( \lvert g_{L,i} - \hat\lambda_{L,i} \rvert + \lvert g_{V,i} - \hat\lambda_{V,i} \rvert \right)
$$

Error absoluto medio entre los goles reales y los esperados, promediado entre local y visitante.
Evalúa **λ**, no las probabilidades 1X2. Por eso puede discrepar del LogLoss: en prueba, **M4
tuvo el mejor MAE (0.898) pero peor LogLoss** que M0. El reporte lo resume así: "la menor pérdida
en goles esperados no garantizó una menor pérdida en probabilidades 1X2".

## 9.6 Métricas complementarias que agrega el tablero

| Métrica | Qué es | Resultado en prueba | Por qué se agregó |
|---|---|---|---|
| Aciertos | % de partidos donde el resultado más probable ocurrió | M0 48.0 % · mercado 48.9 % · ingenua 41.5 % | Fácil de comunicar; pero ignora la confianza y nadie pronostica empates |
| Referencia ingenua | Poisson con los goles promedio del entrenamiento (1.56 local, 1.31 visitante), igual para todos | LogLoss 1.0868 | "Cero información de los equipos": mide cuánto aportan las variables |
| Parte de la mejora del mercado | (ingenua − M0) / (ingenua − mercado) | **84 %** | Resume "cerca pero debajo" en un número |
| Probabilidad media al resultado real | $e^{-\text{LogLoss}}$ | 35.7 % vs 36.1 % | Traduce el LogLoss |

**¿Por qué la referencia ingenua acierta 41.5 %?** Porque siempre le da más probabilidad al local,
así que acierta exactamente cuando gana el local.

## 9.7 Calibración del modelo vs el mercado

Con validación + prueba (799 partidos × 3 = 2,397 pronósticos):

| El modelo M0 dijo | Ocurrió | El mercado dijo | Ocurrió |
|---|---|---|---|
| 24.4 % | 25.2 % | 25.2 % | 27.1 % |
| 44.8 % | 40.3 % | 44.9 % | 43.5 % |
| 64.6 % | **58.5 %** | 65.0 % | 63.7 % |
| 74.7 % | **68.1 %** | 74.2 % | 70.3 % |

**El modelo es algo sobreconfiado con los favoritos**: cuando asigna 60–80 %, el favorito gana
menos de lo previsto. El mercado está mejor calibrado. Es otra forma de ver por qué el mercado gana.

## 9.8 ¿Son significativas las diferencias? Bootstrap

**La idea:** con 419 partidos, parte de cualquier diferencia de LogLoss es suerte de la muestra.
El **bootstrap** mide esa incertidumbre:
1. Se calcula la diferencia de pérdida **partido por partido** (A − B).
2. Se remuestrean los partidos **con reemplazo** (algunos salen repetidos, otros no) y se promedia.
3. Se repite 10,000 veces; los percentiles 2.5 y 97.5 forman el **intervalo de 95 %**.
4. Si el intervalo **no incluye el cero**, la diferencia es distinguible del azar.

| Periodo | Comparación (A − B) | Diferencia | IC 95 % | ¿Distinta de cero? |
|---|---|---|---|---|
| Prueba | M0 − ingenua | −0.056 | −0.086 a −0.026 | **Sí**: el modelo es claramente mejor |
| Prueba | M0 − mercado | +0.011 | −0.004 a +0.025 | No |
| Prueba | M4 − M0 | +0.004 | −0.006 a +0.014 | No |
| Prueba | M4 − mercado | +0.014 | +0.0004 a +0.028 | Sí (por poco) |
| Validación | M4 − M0 | −0.008 | −0.019 a +0.002 | No |
| Validación | M0 − mercado | +0.013 | +0.0002 a +0.026 | Sí |
| Validación + prueba | M0 − mercado | +0.012 | **+0.002 a +0.022** | **Sí** |

**Lectura:** el modelo supera claramente a la ingenua; el mercado es mejor que M0 **de forma
consistente** (aunque en prueba sola no alcanza significancia, sí en validación y con ambos
periodos juntos); entre M0 y M4 no hay diferencia concluyente.

```python
# datos_dashboard.py
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

(R y Python generan números aleatorios distintos, así que los extremos varían en la cuarta cifra;
la conclusión es la misma.)

## 9.9 Multicolinealidad y VIF

Cuando las variables explicativas están muy correlacionadas entre sí (por ejemplo, **tiros y
tiros a puerta: correlación de 0.85**), el modelo no puede separar bien el efecto de cada una:
los coeficientes individuales se vuelven inestables (errores estándar grandes, signos raros).

El **VIF** (factor de inflación de la varianza) lo mide: para cada variable $j$, se hace una
regresión de esa variable contra las demás y

$$
\text{VIF}_j = \frac{1}{1 - R_j^2}
$$

VIF = 1 es sin correlación; valores de 5 a 10 se consideran altos. En M4 el máximo fue **5.5**
(tiros a puerta del local).

**¿Hay que eliminar variables por eso?** No automáticamente: la multicolinealidad **no sesga las
predicciones**, solo vuelve inestables los coeficientes. Por eso el proyecto compara modelos por su
desempeño **fuera de muestra**, no por la significancia de cada coeficiente.

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

## 9.10 Otras métricas que se podrían usar

- **Brier score:** promedio del error cuadrático de las probabilidades; castiga menos la
  sobreconfianza que el LogLoss.
- **RPS** (*ranked probability score*): tiene en cuenta que el resultado es ordinal (local >
  empate > visitante); muy usado en fútbol.
