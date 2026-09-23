# 11. Código: `Analisis.ipynb`, sección por sección

[← wc_predictor.py](10_codigo_wc_predictor.md) · [Índice](README.md) · [Siguiente: resultados →](12_resultados.md)

El notebook hace todo el modelado: construye las variables previas a cada partido, entrena las
cinco especificaciones, las compara en validación, las evalúa en prueba contra el mercado y hace
una predicción de ejemplo. Aquí se explica cada sección y cómo se haría en R. La versión
ejecutable en R está en [`equivalencias_R/02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R)
y [`03_mercado.R`](equivalencias_R/03_mercado.R), y **da exactamente las mismas cifras**.

## Sección 1: dependencias y configuración

```python
from pathlib import Path
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import poisson, skellam
from sklearn.metrics import log_loss, mean_absolute_error
from statsmodels.stats.outliers_influence import variance_inflation_factor
import wc_predictor

FECHA_INICIO = pd.Timestamp("2019-08-01")
FECHA_VALIDACION = pd.Timestamp("2024-08-01")
FECHA_PRUEBA = pd.Timestamp("2025-08-01")
K_SHRINKAGE, N_FORMA, DECAY_FORMA, ESCALA_ELO = 10, 10, 0.85, 400
RECONSTRUIR_VARIABLES = False       # True para recalcular la caché desde cero

GRUPOS = {
    "base_home": ["elo_diff", "gf_home", "ga_away"],
    "base_away": ["elo_diff", "gf_away", "ga_home"],
    "forma_home": ["form_gf_home", "form_ga_away"], ...
}
ESPECIFICACIONES = {
    "M0_Base": (GRUPOS["base_home"], GRUPOS["base_away"]),
    "M4_Completo": (GRUPOS["base_home"] + GRUPOS["forma_home"] + GRUPOS["tiros_home"] + GRUPOS["sot_home"], ...),
}
```

| Librería de Python | Para qué | Equivalente en R |
|---|---|---|
| `pandas` | Tablas de datos | `data.frame` / `tibble`, `dplyr` |
| `numpy` | Arreglos y matemáticas vectorizadas | vectores y matrices de R base |
| `statsmodels` | Modelos estadísticos (GLM) con salida tipo econometría | `glm()` de R base |
| `scipy.stats` | Distribuciones (Poisson, Skellam) | `dpois()`, `ppois()` de R base |
| `sklearn.metrics` | Métricas (LogLoss, MAE) | a mano o `yardstick` |

**Idea de diseño:** las fechas de corte y los parámetros están **en un solo lugar**, y las cinco
especificaciones se definen como **combinaciones de grupos** de variables. Cambiar un modelo es
cambiar una línea.

**En R**, las especificaciones serían listas de nombres y las fórmulas se armarían con
`reformulate()`:

```r
especificaciones <- list(
  M0 = list(local = c("elo_diff", "gf_home", "ga_away"), visita = c("elo_diff", "gf_away", "ga_home"))
)
formula_local <- reformulate(especificaciones$M0$local, response = "home_goals")
# home_goals ~ elo_diff + gf_home + ga_away   (con elo_diff ya dividido entre 400)
```

## Sección 2: construcción de variables previas a cada partido

```python
def crear_variables_partido(df_pre, fecha, home, away, elo_home, elo_away):
    fecha = pd.Timestamp(fecha)
    if not (df_pre["date"] < fecha).all():
        raise ValueError("df_pre contiene información de la fecha objetivo o posterior")
    stats_h = wc_predictor.season_stats(df_pre, home, fecha, k=K_SHRINKAGE)
    stats_a = wc_predictor.season_stats(df_pre, away, fecha, k=K_SHRINKAGE)
    form_h = wc_predictor.recent_form(df_pre, home, n=N_FORMA, decay=DECAY_FORMA)
    form_a = wc_predictor.recent_form(df_pre, away, n=N_FORMA, decay=DECAY_FORMA)
    return {"elo_home": elo_home, "elo_away": elo_away, "elo_diff": elo_home - elo_away,
            "gf_home": stats_h["gf_avg"], ..., "sot_against_away": form_a["sot_against"]}

def construir_base_historica(historial, desde=FECHA_INICIO):
    historial = historial.sort_values("date", kind="stable").reset_index(drop=True)
    ratings, registros = {}, []
    for fecha, partidos_dia in historial.groupby("date", sort=True):     # día por día
        df_pre = historial.loc[historial["date"] < fecha]                # sólo días anteriores
        elo_previo = ratings.copy()                                      # Elo antes de este día
        if fecha >= desde:
            for partido in partidos_dia.itertuples(index=False):
                variables = crear_variables_partido(df_pre, fecha, partido.home_team, partido.away_team,
                                                    elo_previo.get(partido.home_team, 1500),
                                                    elo_previo.get(partido.away_team, 1500))
                registros.append({"Date": fecha, "HomeTeam": ..., **variables,
                                  "home_goals": partido.home_score, "away_goals": partido.away_score})
        for partido in partidos_dia.itertuples(index=False):             # después: actualizar Elo
            ... ratings[home] = update_elo(rh, ra, sh); ratings[away] = update_elo(ra, rh, 1 - sh)
    return pd.DataFrame(registros)
```

**Lo importante:**
1. **Una sola función** (`crear_variables_partido`) construye las variables tanto para el
   entrenamiento como para pronosticar partidos nuevos. Así se garantiza que el modelo recibe las
   variables calculadas de la misma forma siempre.
2. **Guardia contra la fuga de información:** si `df_pre` trae alguna fecha igual o posterior al
   partido, lanza un error.
3. Se procesa **día por día**: todos los partidos del mismo día usan la misma información (la de los
   días anteriores) y el Elo se actualiza **después** de registrar las variables del día.
4. Aunque solo se guardan partidos desde 2019 (`fecha >= desde`), el Elo se calcula desde 2001.
5. `**variables` "desempaca" el diccionario dentro de otro (en R: `c(lista1, lista2)`).

**Tiempo:** recalcular todo tarda cerca de un minuto (miles de filtros de pandas). Por eso se
guarda en la **caché** `premier_training_data.csv`. Se verificó que reconstruirla desde cero da
exactamente los mismos 2,696 partidos (diferencias de $10^{-13}$, precisión de punto flotante).

**En R** sería el mismo doble ciclo: `split(historico, historico$Date)` para agrupar por día y
`bind_rows()` para juntar los registros; cada variable con las funciones de
[`05_variables_previas.R`](equivalencias_R/05_variables_previas.R).

## Sección 3: carga, control de calidad y partición cronológica

```python
historial = wc_predictor.load_history()
if RECONSTRUIR_VARIABLES or not ARCHIVO_VARIABLES.exists():
    training_data = construir_base_historica(historial)
    training_data = training_data.dropna(subset=COLUMNAS_TIROS).reset_index(drop=True)
    training_data.to_csv(ARCHIVO_VARIABLES, index=False)
else:
    training_data = pd.read_csv(ARCHIVO_VARIABLES)

faltantes = training_data[TODOS_LOS_PREDICTORES + OBJETIVOS].apply(pd.to_numeric, errors="coerce")
if not np.isfinite(faltantes.to_numpy(dtype=float)).all():
    raise ValueError("Existen variables no numéricas, faltantes o infinitas.")
if training_data.duplicated(CLAVES).any():
    raise ValueError("Hay partidos duplicados según fecha y equipos.")

train = training_data.loc[training_data["Date"] < FECHA_VALIDACION]
val = training_data.loc[(training_data["Date"] >= FECHA_VALIDACION) & (training_data["Date"] < FECHA_PRUEBA)]
test = training_data.loc[training_data["Date"] >= FECHA_PRUEBA]
```

- `dropna(subset=COLUMNAS_TIROS)`: quita los 4 partidos de equipos sin historial de tiros.
- Dos **controles de calidad**: todo numérico y finito, y sin partidos duplicados. Si falla alguno,
  el notebook se detiene en vez de seguir con datos malos.
- La partición es por fechas (ver [capítulo 9](09_evaluacion_y_validacion.md)).
- Salida: `Entrenamiento: 1897 partidos, 2019-08-09 a 2024-05-19` · `Validación: 380` · `Prueba: 419`.

```r
stopifnot(all(is.finite(as.matrix(variables[, predictores]))))    # ≈ np.isfinite(...).all()
stopifnot(!any(duplicated(variables[, c("Date", "HomeTeam", "AwayTeam")])))
entrenamiento <- filter(variables, Date < as.Date("2024-08-01"))
```

## Sección 4: funciones estadísticas compartidas

Son las piezas del modelo, explicadas en los capítulos de teoría:

| Función | Qué hace | Capítulo |
|---|---|---|
| `preparar_X()` | Selecciona columnas, divide el Elo entre 400 y agrega el intercepto | [6](06_poisson_y_regresion.md) |
| `entrenar_modelo()` | Ajusta las dos regresiones de Poisson (local y visitante) | [6](06_poisson_y_regresion.md) |
| `probabilidades_1x2()` | Convierte λ en P(local), P(empate), P(visita) con Skellam | [7](07_de_goles_a_probabilidades.md) |
| `resultados_observados()` | Codifica el resultado real: 0 = local, 1 = empate, 2 = visita | [9](09_evaluacion_y_validacion.md) |
| `predecir_con_modelo()` | Calcula λ y probabilidades para un conjunto de partidos | — |
| `evaluar_predicciones()` | MAE (local, visitante, promedio) y LogLoss | [9](09_evaluacion_y_validacion.md) |

```python
def resultados_observados(datos):
    gh, ga = datos["home_goals"].to_numpy(), datos["away_goals"].to_numpy()
    return np.where(gh > ga, 0, np.where(gh == ga, 1, 2))          # ifelse anidado

def evaluar_predicciones(pred):
    mae_h = mean_absolute_error(pred["home_goals"], pred["lambda_home"])
    mae_a = mean_absolute_error(pred["away_goals"], pred["lambda_away"])
    return {"MAE_local": mae_h, "MAE_visitante": mae_a, "MAE_promedio": (mae_h + mae_a) / 2,
            "LogLoss_1X2": log_loss(resultados_observados(pred), pred[PROBS].to_numpy(), labels=[0, 1, 2])}
```

```r
resultado <- function(d) ifelse(d$home_goals > d$away_goals, 1L, ifelse(d$home_goals == d$away_goals, 2L, 3L))
mae <- function(real, esperado) mean(abs(real - esperado))
```

> **Detalle a corregir:** justo después de esta sección hay una celda que imprime
> `modelos_entrenados["M0_Base"]...summary()`, pero `modelos_entrenados` se define en la
> sección 5. Si alguien ejecuta el notebook de principio a fin, falla con `NameError`. Hay que
> mover esa celda después de la sección 5 (ver [hallazgos](18_hallazgos_y_pendientes.md)).

## Sección 5: estimación de M0–M4 y validación

```python
modelos_entrenados = {nombre: entrenar_modelo(train, *columnas)
                      for nombre, columnas in ESPECIFICACIONES.items()}
predicciones_val = {nombre: predecir_con_modelo(modelo, val)
                    for nombre, modelo in modelos_entrenados.items()}
tabla_validacion = pd.DataFrame([{"Modelo": nombre, **evaluar_predicciones(pred)}
                                 for nombre, pred in predicciones_val.items()])
tabla_validacion["Delta_LogLoss_vs_M0"] = tabla_validacion["LogLoss_1X2"] - ll_m0
```

- `{nombre: ... for nombre, columnas in ...items()}` es una *dict comprehension*: entrena los cinco
  modelos en una línea. `*columnas` pasa la tupla (columnas del local, columnas del visitante)
  como dos argumentos.
- En R: `modelos <- lapply(especificaciones, function(e) entrenar(entrenamiento, e$local, e$visita))`.
- Resultado: M4 tiene el menor LogLoss en validación (0.9753); M0 el mayor (0.9837).

## Sección 6: referencia simple y diagnóstico de M4

```python
lambda_base_home = float(train["home_goals"].mean())     # 1.561
lambda_base_away = float(train["away_goals"].mean())     # 1.312
base_val[PROBS] = probabilidades_1x2(np.full(len(val), lambda_base_home), np.full(len(val), lambda_base_away))
# -> LogLoss 1.0794 en validación: la referencia ingenua

def tabla_vif(datos, columnas):
    X = preparar_X(datos, columnas)
    return [variance_inflation_factor(X.to_numpy(dtype=float), i) for i in range(1, X.shape[1])]
```

- La referencia ingenua usa la **misma λ para todos los partidos**: mide qué tan bien se pronostica
  sin saber nada de los equipos.
- Correlaciones (`train[columnas].corr()`) y VIF para M4: tiros vs tiros a puerta 0.85; VIF máximo
  5.5 (ver [capítulo 9](09_evaluacion_y_validacion.md)).
- En R: `cor(entrenamiento[, columnas])` y `vif_manual()` (en `02_modelo_poisson.R`).

## Sección 7: cuotas de apertura como referencia

`cargar_cuotas()` y `comparar_con_mercado()`, explicadas en el [capítulo 8](08_cuotas_y_mercado.md).
Salida: `Validación: 380/380 con cuotas válidas; margen bruto promedio 4.49%`, y el mercado queda
primero en validación (0.9706).

## Sección 8: evaluación final en prueba

```python
MODELOS_PRUEBA = ("M0_Base", "M2_Tiros", "M4_Completo")
predicciones_test = {nombre: predecir_con_modelo(modelos_entrenados[nombre], test) for nombre in MODELOS_PRUEBA}
```

- **No se reentrena nada**: se usan los modelos ya ajustados con entrenamiento.
- Se evaluaron tres modelos (el base, el mejor de un bloque y el completo). Resultado: M0 1.0306,
  M4 1.0344, M2 1.0352, mercado 1.0200; margen del mercado 5.84 %.

## Sección 9: predicción de un partido

```python
def predecir_partido(home, away, fecha, nombre_modelo="M4_Completo"):
    df_pre = historial.loc[historial["date"] < fecha]
    elo = wc_predictor.build_elo(df_pre)                         # Elo con información hasta la fecha
    fila = {"Date": fecha, "HomeTeam": home, "AwayTeam": away,
            **crear_variables_partido(df_pre, fecha, home, away, elo.get(home, 1500), elo.get(away, 1500))}
    pred = predecir_con_modelo(modelos_entrenados[nombre_modelo], pd.DataFrame([fila])).iloc[0]
    goles = np.arange(11)
    matriz = np.outer(poisson.pmf(goles, pred["lambda_home"]), poisson.pmf(goles, pred["lambda_away"]))
    gh, ga = np.unravel_index(matriz.argmax(), matriz.shape)
    ...
ejemplo = predecir_partido("Arsenal", "Man City", "2026-09-20", "M4_Completo")
```

Resultado con M4: λ 1.562 y 1.211; 45.46 % / 24.98 % / 29.56 %; marcador más probable 1–1
(11.82 %). Con M0 (el que usa el simulador del tablero): λ 1.566 y 1.202; **45.76 % / 24.97 % /
29.27 %**. Es un partido hipotético: ilustra el uso, pero no forma parte de la evaluación.

## Sección 10: notas de alcance

El propio notebook advierte: la independencia de goles es una hipótesis; LogLoss y MAE miden cosas
distintas; la caché debe regenerarse si cambian los datos o las funciones; y no se evaluó
rentabilidad. Todo eso aparece como limitación en el [capítulo 15](15_limitaciones_y_extensiones.md).
