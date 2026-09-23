# Equivalencias en R

[← Índice de la guía](../README.md)

El análisis del equipo está en Python. Estos cinco scripts reproducen sus partes centrales en R,
el lenguaje del diplomado. Hacen dos cosas:

1. **Estudiar:** cada línea tiene un comentario con su equivalente en Python.
2. **Verificar:** cada script termina con un `stopifnot()` que compara contra las cifras de Python.
   Si algo no coincide, el script se detiene con error. **Los cinco pasan.** La última ejecución fue
   el 22-sep-2026, con R 4.3.2, y tardó unos 19 segundos en total.

## Cómo correrlos

Desde la carpeta raíz de este repositorio, **en este orden**, porque el 03 usa un archivo que genera
el 02:

```r
source("equivalencias_R/01_elo.R")
source("equivalencias_R/02_modelo_poisson.R")
source("equivalencias_R/03_mercado.R")
source("equivalencias_R/04_grafica_resumen.R")
source("equivalencias_R/05_variables_previas.R")
```

O desde una terminal (en esta computadora, R no está en el PATH):

```bash
"C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" equivalencias_R/01_elo.R
```

- **Paquetes:** `readr`, `dplyr` y `ggplot2`, todos de `tidyverse`.
- **Datos:** si el repositorio público está clonado al lado de este (`../06_proyecto/`), se leen del
  disco. Si no, la función `ruta()` los descarga del repositorio público en GitHub, así que basta
  con tener internet.

## Qué hace cada script

| Script | Reproduce (Python) | Funciones de R clave | Qué debe imprimir |
|---|---|---|---|
| [`01_elo.R`](01_elo.R) | `wc_predictor.build_elo()` | `for`, vector con nombres (≈ diccionario) | Top 10 de Elo: Arsenal **1833**, Man City **1808**, Man United 1680… · "OK: los ratings coinciden" · P(Arsenal gana a City según Elo) = **0.537** |
| [`02_modelo_poisson.R`](02_modelo_poisson.R) | `Analisis.ipynb` §3–6: partición, GLM de Poisson, 1X2, métricas, VIF | `glm(family = poisson)`, `predict(type = "response")`, `dpois()`, `outer()`, `lm()` | 1,897 / 380 / 419 · coeficientes de M0 (−0.3864, 0.4082, 0.3338, 0.2158 / −0.3009, −0.4870, 0.2101, 0.1589) · dispersión **0.992 / 1.041** · VIF máximo **5.517** · LogLoss **0.983690, 0.975296, 1.030556, 1.034434** |
| [`03_mercado.R`](03_mercado.R) | `Analisis.ipynb` §7–8 y complementos del tablero | `left_join()`, `rowSums()`, `sample(replace = TRUE)`, `quantile()` | Margen **5.84 %** · LogLoss del mercado **1.020000** · ingenua 1.0868 · **84.2 %** de la mejora · aciertos 48.0 / 48.9 / 41.5 % · IC bootstrap [−0.0042, +0.0251] |
| [`04_grafica_resumen.R`](04_grafica_resumen.R) | `graficas.mejora_sobre_ingenua()` (la gráfica principal del tablero) | `ggplot()`, `geom_col(position = position_dodge())`, `geom_text()`, `ggsave()` | Guarda [`grafica_resumen.png`](grafica_resumen.png) |
| [`05_variables_previas.R`](05_variables_previas.R) | `wc_predictor.season_stats()` y `recent_form()` | `filter(Date < fecha)`, `ifelse()`, `tail()`, pesos `0.85^(m-1):0` | Liverpool: GF ajustado 2.3421, GA 0.5789 · Norwich (ascendido): 1.4105 / 1.4105 · "OK: mismas variables que la caché" |

Los avisos `Attaching package: 'dplyr'… masked from 'package:stats'` son normales: solo informan
que `dplyr` tiene funciones con el mismo nombre que otras de R base.

## Diccionario rápido Python → R

| Python | R | Nota |
|---|---|---|
| `pd.read_csv("x.csv")` | `readr::read_csv("x.csv")` | |
| `df.sort_values("Date")` | `arrange(df, Date)` | |
| `df[df["Date"] < fecha]` | `filter(df, Date < fecha)` | |
| `df.merge(otro, on=[...], how="left")` | `left_join(df, otro, by = c(...))` | |
| `np.where(cond, a, b)` | `ifelse(cond, a, b)` | |
| `np.average(x, weights=w)` | `sum(w * x) / sum(w)` o `weighted.mean(x, w)` | |
| `dict` `{equipo: rating}` | vector con nombres `elo["Arsenal"]` o `list` | |
| `sm.GLM(y, sm.add_constant(X), family=sm.families.Poisson()).fit()` | `glm(y ~ x1 + x2, family = poisson, data = d)` | R agrega el intercepto solo |
| `modelo.summary()` | `summary(modelo)` | Mismos coeficientes, errores estándar, z y p |
| `modelo.predict(X)` | `predict(modelo, newdata = d, type = "response")` | `type = "response"` devuelve λ, no log λ |
| `scipy.stats.poisson.pmf(k, lam)` | `dpois(k, lam)` | |
| `scipy.stats.skellam.sf(0, l1, l2)` | `sum(m[lower.tri(m)])` con `m <- outer(dpois(0:15, l1), dpois(0:15, l2))` | El paquete `skellam` de R no está instalado; sumar la matriz da lo mismo |
| `sklearn.metrics.log_loss(y, P)` | `-mean(log(P[cbind(1:n, y)]))` | |
| `sklearn.metrics.mean_absolute_error` | `mean(abs(y - yhat))` | |
| `variance_inflation_factor(X, j)` | `1 / (1 - summary(lm(xj ~ resto))$r.squared)` | `car::vif()` usa una versión ponderada por el GLM y da valores parecidos, no idénticos |
| `np.random.default_rng(2026)` | `set.seed(2026)` | Generadores distintos: los intervalos varían en la cuarta cifra |
| `plotly.graph_objects` | `ggplot2` + `plotly::ggplotly()` o `plot_ly()` | |

## Por qué los números coinciden exactamente (y cuándo no)

- **Elo, variables, coeficientes, LogLoss, MAE y aciertos coinciden al decimal** porque son cálculos
  deterministas. La máxima verosimilitud de un GLM de Poisson tiene una solución única, así que
  `statsmodels` y `glm()` llegan al mismo punto.
- **El bootstrap no coincide al decimal**, porque R y Python generan números aleatorios distintos
  aun con la misma semilla. Los extremos del intervalo cambian en la cuarta cifra
  ([−0.0042, +0.0251] en R contra [−0.0044, +0.0254] en Python), pero la conclusión es la misma.
