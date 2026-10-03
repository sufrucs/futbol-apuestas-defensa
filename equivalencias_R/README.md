# Equivalencias en R

[← Índice de la guía](../README.md)

El análisis del equipo está en Python. Estos seis scripts reproducen sus partes centrales en R,
el lenguaje del diplomado. Hacen dos cosas:

1. **Estudiar:** cada línea tiene un comentario con su equivalente en Python.
2. **Verificar:** cada script termina con un `stopifnot()` que compara contra las cifras de Python.
   Si algo no coincide, el script se detiene con error. **Los seis pasan** con la versión final del
   proyecto (K = 15 del Elo y k = 0 del *shrinkage*, calibrados en `Analisis.ipynb` §5; base de 9,540
   partidos). La última ejecución fue el 2-oct-2026, con R 4.3.2, y tardó unos 40 segundos en total
   (casi la mitad es el 04, que dibuja y guarda la gráfica). El 06 repite la calibración completa de
   K y k (35 combinaciones) en unos 7 segundos.

## Cómo correrlos

Desde la carpeta raíz de este repositorio, **en este orden**, porque el 03 usa un archivo que genera
el 02:

```r
source("equivalencias_R/01_elo.R")
source("equivalencias_R/02_modelo_poisson.R")
source("equivalencias_R/03_mercado.R")
source("equivalencias_R/04_grafica_resumen.R")
source("equivalencias_R/05_variables_previas.R")
source("equivalencias_R/06_calibracion.R")
```

O desde una terminal (en esta computadora, R no está en el PATH):

```bash
"C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" equivalencias_R/01_elo.R
```

- **Paquetes:** `readr`, `dplyr`, `tidyr` y `ggplot2`, todos de `tidyverse`.
- **Datos:** si el repositorio público está clonado al lado de este (`../06_proyecto/`), se leen del
  disco. Si no, la función `ruta()` los descarga del repositorio público en GitHub, así que basta
  con tener internet.

## Qué hace cada script

| Script | Reproduce (Python) | Funciones de R clave | Qué debe imprimir |
|---|---|---|---|
| [`01_elo.R`](01_elo.R) | `wc_predictor.build_elo()` con `ELO_K = 15` | `for`, vector con nombres (≈ diccionario) | Top 10 de Elo: Arsenal **1787**, Man City **1779**, Liverpool 1684, Man United 1638, Aston Villa 1625… · "OK: los ratings coinciden" · P(Arsenal gana a City según Elo) = **0.511** |
| [`02_modelo_poisson.R`](02_modelo_poisson.R) | `Analisis.ipynb` §4, §6, §7 y §9: GLM de Poisson, 1X2, métricas, VIF (la partición es la del final de §5) | `glm(family = poisson)`, `predict(type = "response")`, `dpois()`, `outer()`, `lm()` | 1,897 / 380 / 419 · coeficientes de M0 (0.0433, 0.6283, 0.1678, 0.0778 / 0.0264, −0.6854, 0.1079, 0.0281) · dispersión **0.996 / 1.036** · VIF máximo de M4 **5.560** · LogLoss **0.989547, 0.978612, 1.033076, 1.036739** |
| [`03_mercado.R`](03_mercado.R) | `Analisis.ipynb` §8–9 y complementos del tablero | `left_join()`, `rowSums()`, `sample(replace = TRUE)`, `quantile()` | Margen **5.84 %** · LogLoss del mercado **1.020000** · M0 1.033076 · ingenua 1.0868 · **80.4 %** de la mejora · aciertos 48.0 / 48.9 / 41.5 % · IC bootstrap [−0.0007, +0.0265] |
| [`04_grafica_resumen.R`](04_grafica_resumen.R) | `graficas.mejora_sobre_ingenua()` (la gráfica principal del tablero) | `ggplot()`, `geom_col(position = position_dodge())`, `geom_text()`, `ggsave()` | Guarda [`grafica_resumen.png`](grafica_resumen.png): mejora sobre la ingenua de 0.109 / 0.067 (mercado), 0.090 / 0.054 (M0) y 0.101 / 0.050 (M4), validación / prueba |
| [`05_variables_previas.R`](05_variables_previas.R) | `wc_predictor.season_stats()` (k = 0) y `recent_form()` | `filter(Date < fecha)`, `ifelse()`, `tail()`, pesos `0.85^(m-1):0` | Primer partido (n = 0, k no influye): Liverpool GF 2.3421, GA 0.5789 · Norwich (ascendido) 1.4105 / 1.4105 · segundo partido de Liverpool (n = 1): con k = 0, GF 4 y GA 1; con k = 10 habría sido 2.4928 / 0.6172 · "OK: mismas variables que la caché" |
| [`06_calibracion.R`](06_calibracion.R) | `Analisis.ipynb` §5: `construir_base_historica()` + `calibrar_hiperparametros()` con la rejilla completa | sumas acumuladas por grupo (`group_by()` + `cumsum()`), `pivot_wider()`, `glm()`, `weighted.mean()` | Tabla de las 35 combinaciones · gana **K = 15, k = 0** con **0.959558** (pliegues 0.960230 / 0.989315 / 0.929130; 1,140 partidos) · "OK: las 35 combinaciones coinciden con Python" · la configuración anterior (K = 30, k = 10) da 0.962178, **0.002620** peor |

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
  ([−0.0007, +0.0265] en R contra [−0.0005, +0.0264] en Python), pero la conclusión es la misma: en
  prueba sola el intervalo de M0 − mercado incluye el cero, aunque por muy poco.
