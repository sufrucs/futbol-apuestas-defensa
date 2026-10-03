# 10. Código: `wc_predictor.py`, pieza por pieza

[← Evaluación](09_evaluacion_y_validacion.md) · [Índice](README.md) · [Siguiente: el notebook de análisis →](11_codigo_analisis_notebook.md)

> **Versión que se explica:** la entregada (rama `main`, `e3bd43f`, 30-sep-2026). El archivo tiene **563 líneas**;
> cuando se dice "líneas 19–52" son de ese archivo. Todas las cifras de los ejemplos se calcularon **ejecutando el
> propio módulo** con Python 3.10, y **todos** los fragmentos de R de este capítulo se ejecutaron con R 4.3.2 y dan
> las mismas cifras.

## 10.1 Panorama

### Qué es

`wc_predictor.py` es un **módulo** de Python: un archivo con constantes y funciones que otros archivos importan
(`import wc_predictor`) para no repetir código. En R sería un script de funciones que se carga con
`source("wc_predictor.R")` (o, más formal, un paquete).

Su nombre viene de "World Cup predictor": el equipo partió de un predictor del Mundial y lo adaptó a la Premier
League. La versión entregada ya **no** tiene las piezas del Mundial (ver [10.2](#102-qué-cambió-frente-a-la-versión-anterior)).

### Qué hace (y qué no)

Hace tres trabajos:

1. **Cargar el histórico** `E0_consolidado.csv` con nombres de columna homogéneos → `load_history()`.
2. **Elo**: resultado esperado, actualización tras cada partido y ratings de todos los equipos →
   `expected_score()`, `update_elo()`, `build_elo()` (teoría en el [capítulo 4](04_elo.md)).
3. **Estadísticas de un equipo antes de un partido**: promedios de goles de la temporada con *shrinkage* →
   `season_stats()`, y forma reciente ponderada de los últimos 10 partidos → `recent_form()` (teoría en el
   [capítulo 5](05_promedios_ajustados_y_forma.md)).

Además fija los **parámetros** que comparten el notebook y el tablero (`ELO_INIT`, `ELO_SCALE`, `ELO_K`,
`SHRINKAGE_K`) y conserva un **resto de la versión heurística** que ya nadie usa: `calcular_parametros_liga()` y los
factores `HOME_FACTOR` / `AWAY_FACTOR`.

Lo que **no** hace: no estima modelos, no calcula probabilidades 1X2 y no lee cuotas. Todo eso está en
`Analisis.ipynb` (regresión de Poisson + Skellam, [capítulo 11](11_codigo_analisis_notebook.md)).

### Dónde encaja en la cadena

```
Limpieza de datos.ipynb ──► E0_consolidado.csv (9,540 partidos × 34 columnas)
                                      │  lo lee load_history()
                                      ▼
                           ┌──── wc_predictor.py ────┐
                   import  │                         │  import
                           ▼                         ▼
                 Analisis.ipynb              datos_dashboard.py ──► graficas.py ──► index.qmd ──► sitio
                           │                         ▲
                           ▼                         │ lee
             premier_training_data.csv ──────────────┘
             (2,696 × 24: variables previas a cada partido)
```

El notebook usa el módulo para **construir** las variables de cada partido; el tablero lo usa para **leer los
parámetros** (K, k, escala, rating inicial) y para el **simulador** de partidos de 2026/27. Para los modelos, el
tablero no reconstruye la base: lee `premier_training_data.csv`, que exportó el notebook.

### Quién llama a qué

Verificado en el notebook entregado (`Analisis.ipynb`, 26 celdas) y en `Dashboard-o-pagina/datos_dashboard.py`:

| Pieza del módulo | `Analisis.ipynb` | Tablero (`datos_dashboard.py`, `index.qmd`) |
|---|---|---|
| `ELO_K` | §1: `K_ELO = wc_predictor.ELO_K` | `K_ELO = wc_predictor.ELO_K` (línea 142) |
| `SHRINKAGE_K` | §1: `K_SHRINKAGE = wc_predictor.SHRINKAGE_K` | `K_SHRINKAGE = wc_predictor.SHRINKAGE_K` (143); `index.qmd` arma el texto "k = 0, es decir, sin mezcla" |
| `ELO_SCALE` | §1: `ESCALA_ELO = wc_predictor.ELO_SCALE` | `ESCALA_ELO = wc_predictor.ELO_SCALE` (147) |
| `ELO_INIT` | §2 (`construir_base_historica`) y §10 (`predecir_partido`): rating de un equipo sin historial | simulador (`datos_simulador`); `index.qmd` lo muestra en el texto |
| `load_history()` | §3: `historial = wc_predictor.load_history()` | simulador (`datos_simulador`, línea 704) |
| `update_elo()` | §2: `construir_base_historica` actualiza el Elo día por día | sólo indirectamente, dentro de `build_elo()` |
| `build_elo()` | §10: `predecir_partido` (ratings al corte) | simulador (línea 711) |
| `season_stats()` | §2: `crear_variables_partido` (local y visitante) | su copia de `crear_variables_partido` y el simulador (738) |
| `recent_form()` | §2: `crear_variables_partido` | su copia de `crear_variables_partido`; además lee sus valores por defecto (`n`, `decay`) con `inspect.signature` como respaldo (línea 85) |
| `expected_score()` | indirecto (dentro de `update_elo`) | indirecto |
| `avg_team_goals` | indirecto: respaldo de `recent_form` para equipos sin partidos | indirecto |
| `calcular_parametros_liga()`, `HOME_FACTOR`, `AWAY_FACTOR`, `df`, `parametros` | **no se usan** | **no se usan** |

> **Dato para la exposición:** el notebook **no** usa `build_elo()` para la base de entrenamiento. `build_elo()`
> sólo devuelve los ratings **finales**, y para entrenar hace falta el rating **previo a cada partido**. Por eso
> `construir_base_historica` (§2) repite el ciclo día por día y llama a `update_elo()` después de guardar las
> variables de ese día. `build_elo()` se usa cuando basta el rating "de hoy": la predicción individual (§10) y el
> simulador del tablero.

### Todas las piezas del archivo

| # | Pieza | Líneas | Tipo | Para qué sirve | ¿Quién la usa? | Sección |
|---|---|---|---|---|---|---|
| 1 | `import numpy as np`, `import pandas as pd` | 1–2 | importaciones | arreglos y tablas | todo el módulo | [10.3](#103-importaciones-y-constantes) |
| 2 | `ELO_INIT = 1500` | 7 | constante | rating de un equipo que aparece por primera vez | `build_elo`; notebook §2 y §10; tablero | [10.3](#103-importaciones-y-constantes) |
| 3 | `ELO_SCALE = 400` | 8 | constante | escala de la fórmula Elo | las tres funciones Elo; notebook y tablero (`ESCALA_ELO`) | [10.3](#103-importaciones-y-constantes) |
| 4 | `ELO_K = 15` | 11 | constante **calibrada** | cuánto se mueve el rating por partido | `update_elo`, `build_elo`; notebook y tablero (`K_ELO`) | [10.3](#103-importaciones-y-constantes) |
| 5 | `SHRINKAGE_K = 0` | 12 | constante **calibrada** | peso de la temporada anterior en los promedios | `season_stats`; notebook y tablero (`K_SHRINKAGE`) | [10.3](#103-importaciones-y-constantes) |
| 6 | `load_history()` | 19–52 | función | leer el CSV, renombrar, convertir fechas, ordenar | el propio módulo (línea 86); notebook §3; simulador | [10.4](#104-load_history) |
| 7 | `calcular_parametros_liga()` | 56–83 | función | goles promedio y factores de localía de todo el histórico | sólo el bloque de la línea 89 | [10.5](#105-calcular_parametros_liga) |
| 8 | `df`, `parametros`, `avg_team_goals`, `HOME_FACTOR`, `AWAY_FACTOR` | 85–98 | código suelto (se ejecuta al importar) | lee el CSV y calcula los parámetros de la liga | sólo `avg_team_goals` (respaldo de `recent_form`) | [10.6](#106-el-bloque-que-se-ejecuta-al-importar) |
| 9 | `expected_score()` | 103–106 | función | resultado esperado según la diferencia de ratings | `update_elo` | [10.7](#107-expected_score) |
| 10 | `update_elo()` | 110–118 | función | rating después de un partido | `build_elo`; notebook §2 | [10.8](#108-update_elo) |
| 11 | `build_elo()` | 120–180 | función | ratings finales de todos los equipos | notebook §10; simulador | [10.9](#109-build_elo) |
| 12 | `recent_form()` | 185–347 | función | forma de los últimos 10 partidos (goles, tiros, tiros a puerta) | notebook §2; tablero | [10.10](#1010-recent_form) |
| 13 | `season_stats()` | 349–563 | función | goles a favor y en contra de la temporada, con *shrinkage* | notebook §2; tablero | [10.11](#1011-season_stats) |
| 13a | `calculate_stats()` (dentro de `season_stats`) | 426–453 | función interna | GF y GA promedio de un conjunto de partidos | sólo `season_stats` | [10.11](#1011-season_stats) |

## 10.2 Qué cambió frente a la versión anterior

La guía se escribió primero (22-sep) con la versión inicial del archivo. Daniel la cambió el 29 y 30 de septiembre.
Historial del archivo en el repositorio:

| Fecha | Commit | Quién | Cambio en `wc_predictor.py` |
|---|---|---|---|
| 22-sep-2026 | `8b1fc83` | César (sube el código del equipo) | Versión inicial, 575 líneas: K = 30 fijo, k = 10 en la firma de `season_stats`, piezas del Mundial, imprime el ranking Elo al importarse |
| 29-sep | `1a9eb93` | Daniel | `ELO_K = 15` y `season_stats(..., k=0)` sobre esa misma versión |
| 30-sep | `4b156bb` | Daniel | Archivo reescrito y comentado línea por línea (563 líneas): nuevas constantes `ELO_SCALE` y `SHRINKAGE_K`, K y escala como parámetros, sin piezas del Mundial. Los valores por defecto quedaron otra vez en 30 y 10 |
| 30-sep | `9c181b6` | Daniel | Valores por defecto finales: `ELO_K = 15`, `SHRINKAGE_K = 0` (es la versión entregada) |

Diferencias entre la versión inicial y la entregada:

| Pieza | Versión inicial (`8b1fc83`) | Versión entregada |
|---|---|---|
| `ELO_K` | 30 | **15**, elegido por validación temporal (notebook §5) |
| `ELO_SCALE` | no existía: el 400 estaba escrito dentro de `expected_score` | **400**, como constante |
| `SHRINKAGE_K` | no existía: `k=10` en la firma de `season_stats` | **0**, elegido por validación temporal |
| `expected_score` | `expected_score(r_a, r_b)` | `expected_score(r_a, r_b, scale=ELO_SCALE)` |
| `update_elo` | `update_elo(r_a, r_b, score_a, k=ELO_K)` | `update_elo(r_a, r_b, score_a, k=ELO_K, scale=ELO_SCALE)` |
| `build_elo` | `build_elo(df, elo_init=ELO_INIT)`: no recibía K, siempre usaba el de la constante | `build_elo(df, elo_init=ELO_INIT, k=ELO_K, scale=ELO_SCALE)`, y se los pasa a `update_elo` |
| `season_stats` | `season_stats(df, team, as_of_date, k=10)` | `season_stats(df, team, as_of_date, k=SHRINKAGE_K)` |
| `N_SIMS`, `AVG_WC_GOALS`, `HIST_URL`, `NAME_MAP`, `INJURY_FACTOR` | restos del Mundial (simulaciones, URL de resultados de selecciones, nombres de países, lesiones) | **eliminados** |
| `get_lambda()` | goles esperados con pesos fijos 50 % / 35 % / 15 % | **eliminada** (ver [10.5](#105-calcular_parametros_liga)) |
| `simular_partido()` | Monte Carlo de 30,000 partidos, con prórroga y penales | **eliminada** |
| Bloque final (`from wc_predictor import ...` + `print`) | al importar, imprimía el ranking Elo | **eliminado**: importar ya no imprime nada |
| Comentarios | casi ninguno | cada línea comentada en español |
| `load_history`, `calcular_parametros_liga`, `recent_form` y la lógica de `season_stats` | — | **sin cambios** |

**Por qué importan las firmas nuevas:** la calibración (§5) prueba 7 valores de K y 5 de k sin editar el archivo, así
que K, k y la escala tienen que poder **pasarse como argumentos**; las constantes sólo dan el valor por defecto.
`update_elo` y `season_stats` ya recibían K y k; lo nuevo es que la escala también sea un argumento y que
`build_elo` reciba K (antes, la predicción individual habría usado siempre el K de la constante).

> **Ojo con un comentario desactualizado** (línea 117 del archivo): dice que K "por defecto es 30". El valor por
> defecto real es `ELO_K = 15`. Si preguntan: "el comentario quedó de la versión anterior; el valor que se usa es 15".

## 10.3 Importaciones y constantes

Líneas 1–12:

```python
import numpy as np
import pandas as pd

# ── Constantes del modelo ─────────────────────────────────────────────────────


ELO_INIT     = 1500
ELO_SCALE    = 400

# Valores de K por default, estas las tomamos despues de realizar prueba log loss
ELO_K        = 15
SHRINKAGE_K  = 0
```

**Qué hace, línea por línea:**

- `import numpy as np`: arreglos y matemáticas vectorizadas (`np.where`, `np.average`, `np.nan`). En R casi todo esto
  ya viene en R base (vectores, `ifelse()`, `weighted.mean()`, `NA`).
- `import pandas as pd`: tablas (`DataFrame`), lectura de CSV, fechas. En R: `data.frame`/`tibble` con `readr` y `dplyr`.
- Las cuatro constantes van en **MAYÚSCULAS**: es la convención de Python para "valor fijo que no se debe cambiar"
  (Python no lo impide; es un acuerdo). En R se usa la misma convención.

| Constante | Valor | Qué controla | ¿De dónde sale? | Quién la lee |
|---|---|---|---|---|
| `ELO_INIT` | 1500 | rating de un equipo que aparece por primera vez | convención del ajedrez; sólo fija el nivel promedio ([cap. 4](04_elo.md)) | `build_elo`; notebook (`elo_previo.get(home, wc_predictor.ELO_INIT)`); tablero |
| `ELO_SCALE` | 400 | cuántos puntos de diferencia equivalen a "10 a 1" en el resultado esperado | convención; no cambia el modelo (ver [10.9](#109-build_elo)) | las tres funciones Elo; notebook `ESCALA_ELO` (también divide `elo_diff` en la regresión) |
| `ELO_K` | 15 | cuánto se mueve el rating por partido | **calibrado**: rejilla de 15 a 45 con validación temporal (notebook §5) | `update_elo`, `build_elo`; notebook y tablero `K_ELO` |
| `SHRINKAGE_K` | 0 | peso de la temporada anterior en los promedios de goles | **calibrado**: rejilla de 0 a 20 (notebook §5) | `season_stats`; notebook y tablero `K_SHRINKAGE` |

Cómo las toma el notebook (§1, celda 2):

```python
#Variables definidas en wc_predictor.py
K_ELO = wc_predictor.ELO_K
K_SHRINKAGE = wc_predictor.SHRINKAGE_K
N_FORMA = 10
DECAY_FORMA = 0.85
ESCALA_ELO = wc_predictor.ELO_SCALE
```

Detalles que conviene saber:

- La ventana y el decaimiento de la forma reciente (10 y 0.85) **no** son constantes del módulo: están como valores
  por defecto de `recent_form()` y, otra vez, escritos en la §1 del notebook (`N_FORMA`, `DECAY_FORMA`). El tablero
  los lee del código del notebook y, si no los encontrara, usaría los valores por defecto de `recent_form()`.
- Después de la calibración (§5), el notebook reemplaza `K_ELO` y `K_SHRINKAGE` por los ganadores de la rejilla
  (`K_ELO = float(mejor["K_Elo"])`). Como la rejilla activa es sólo `[15]` × `[0]`, coinciden con el módulo. Si
  alguien activara la rejilla completa y ganara otra combinación, habría que **copiarla también en
  `wc_predictor.py`**, porque el tablero toma K y k del módulo, no del resultado de la §5.

**En R:**

```r
ELO_INIT    <- 1500
ELO_SCALE   <- 400
ELO_K       <- 15   # calibrado en Analisis.ipynb §5 (antes 30)
SHRINKAGE_K <- 0    # calibrado en Analisis.ipynb §5 (antes 10)
```

> **Decisión:** K, k, la escala y el rating inicial viven como constantes en `wc_predictor.py`, y el notebook y el
> tablero los leen de ahí.
> **Alternativas:** (a) escribir los valores a mano en cada archivo — simple, pero se desincronizan (el notebook
> anterior tenía `K_SHRINKAGE = 10` escrito a mano); (b) un archivo de configuración aparte (YAML o JSON) — más
> formal, pero es un archivo más que mantener y leer; (c) constantes en el módulo que todos importan (la elegida).
> **Por qué ésta:** el módulo ya es la pieza que comparten el notebook y el tablero; poner ahí los valores garantiza
> que ambos usen los mismos, y el tablero los muestra en sus textos sin escribirlos a mano.
> **Evidencia en el proyecto:** la tabla de verificación del tablero reproduce con esos valores las cifras guardadas
> del notebook (17 de 17 ✓).
> **Si preguntan:** "K y k están en un solo lugar, `wc_predictor.py`; el notebook y el tablero los importan, así no
> pueden quedar distintos."

## 10.4 `load_history()`

Lee `E0_consolidado.csv` y lo deja listo para todo lo demás. Líneas 19–52:

```python
def load_history(
    path="E0_consolidado.csv"
):

    # Lee el archivo CSV y lo almacena como un DataFrame de pandas.
    df = pd.read_csv(path)

    # Renombra las variables principales para utilizar nombres homogéneos dentro del predictor.
    df = df.rename(columns={
        "Date": "date",
        "HomeTeam": "home_team",
        "AwayTeam": "away_team",
        "FTHG": "home_score",
        "FTAG": "away_score"
    })

    # Convierte la columna de fecha a formato datetime, dayfirst=True indica que el día aparece antes que el mes, mientras que format="mixed" permite distintos formatos de fecha.
    df["date"] = pd.to_datetime(
        df["date"],
        dayfirst=True,
        format="mixed"
    )

    # Elimina los partidos que no tengan alguna de las variables indispensables: fecha, equipos o marcador final.
    df = df.dropna(subset=[
        "date",
        "home_team",
        "away_team",
        "home_score",
        "away_score"
    ])

    # Ordena los partidos cronológicamente, reinicia el índice y devuelve el DataFrame preparado.
    return df.sort_values("date").reset_index(drop=True)
```

| Líneas | Código | Qué hace | En R |
|---|---|---|---|
| 19–21 | `def load_history(path="E0_consolidado.csv")` | Define la función. Si no se le da ruta, busca `E0_consolidado.csv` **en la carpeta actual** (ruta relativa) | `load_history <- function(path = "E0_consolidado.csv")` |
| 24 | `pd.read_csv(path)` | Lee el CSV a un `DataFrame` de 9,540 × 34 | `readr::read_csv(path)` |
| 27–33 | `df.rename(columns={...})` | Cambia 5 nombres a nombres genéricos (`date`, `home_team`, `away_team`, `home_score`, `away_score`); las otras 29 columnas (`HS`, `HST`, `AvgH`, …) conservan su nombre | `rename(date = Date, home_team = HomeTeam, ...)` |
| 36–40 | `pd.to_datetime(..., dayfirst=True, format="mixed")` | Texto → fecha. `format="mixed"` deduce el formato renglón por renglón; `dayfirst=True` dice que en una fecha ambigua (05/08/19) el día va primero | `as.Date(date)` (el CSV ya viene en ISO); para formatos mezclados, `lubridate::parse_date_time(x, c("Ymd", "dmy"))` |
| 43–49 | `df.dropna(subset=[...])` | Quita los partidos sin fecha, sin equipos o sin marcador | `tidyr::drop_na(date, home_team, away_team, home_score, away_score)` |
| 52 | `df.sort_values("date").reset_index(drop=True)` | Ordena por fecha y renumera las filas 0…9,539 | `arrange(date)` (R no tiene un índice que renumerar) |

**Ejemplo real (entrada → salida):**

| | Antes (CSV tal cual) | Después de `load_history()` |
|---|---|---|
| Tamaño | 9,540 × 34 | 9,540 × 34 (`dropna` no quita **ninguna** fila) |
| Primera fila | 2026-08-21 Arsenal 3–0 Coventry | 2001-08-18 Tottenham 0–0 Aston Villa |
| Última fila | 2002-05-11 West Ham 2–1 Bolton | 2026-09-14 Leeds 4–1 Newcastle |
| Tipo de `date` | texto (`"2026-08-21"`) | fecha (`datetime64`) |
| Tipo de los goles | número decimal (`float64`, así lo exporta la limpieza) | igual |

- El CSV viene **de la temporada más reciente a la más antigua** (así lo arma la limpieza). Sin el
  `sort_values("date")`, el Elo se calcularía del futuro hacia el pasado.
- Leer con `dayfirst=True` las fechas ISO (`aaaa-mm-dd`) **no** invierte día y mes: se comparó contra una lectura
  estricta ISO y difieren **0 de 9,540** fechas.
- **Detalle fino del orden:** `sort_values` usa por defecto un ordenamiento **no estable** (*quicksort*): dentro de un
  mismo día, los partidos pueden quedar en otro orden que el del archivo. Por ejemplo, el 18-ago-2001 hay 8 partidos;
  pandas pone primero Tottenham–Aston Villa y un ordenamiento estable (`arrange()` de R) pone primero
  Charlton–Everton. **No cambia nada:** en los 9,540 partidos ningún equipo juega dos veces el mismo día (0 casos), así
  que el orden dentro del día no altera ni el Elo ni los promedios. El notebook, además, vuelve a ordenar con
  `kind="stable"`.

**En R** (ejecutado; da 9,540 filas y las mismas fechas):

```r
library(readr); library(dplyr); library(tidyr)

load_history <- function(path = "E0_consolidado.csv") {
  read_csv(path, show_col_types = FALSE) |>                       # pd.read_csv(path)
    rename(date = Date, home_team = HomeTeam, away_team = AwayTeam,
           home_score = FTHG, away_score = FTAG) |>                # df.rename(columns = {...})
    mutate(date = as.Date(date)) |>                                # pd.to_datetime(...)
    drop_na(date, home_team, away_team, home_score, away_score) |> # df.dropna(subset = [...])
    arrange(date)                                                  # sort_values("date")
}
```

> **Decisión:** la carga convierte las fechas con un lector tolerante y ordena cronológicamente dentro de la misma
> función.
> **Alternativas:** (a) lector estricto (`format="ISO8601"`) — avisa con un error si se cuela otro formato, pero
> fallaría con los CSV originales de Football-Data, que traen `dd/mm/aa` (antes de 2016/17) y `dd/mm/aaaa` (desde
> 2016/17); (b) confiar en el orden del archivo — el CSV viene de 2026/27 hacia atrás, así que el Elo saldría al
> revés; (c) lo elegido.
> **Por qué ésta:** con el CSV actual (todo ISO) el lector tolerante da exactamente lo mismo que el estricto, y
> sigue funcionando si se le pasa un archivo original; ordenar aquí garantiza que todo lo que viene después vea el
> pasado en orden.
> **Evidencia en el proyecto:** 0 fechas distintas entre la lectura tolerante y la estricta; 0 filas perdidas.
> **Si preguntan:** "`load_history` deja el histórico en orden cronológico; sin eso el Elo se calcularía del futuro
> al pasado."

## 10.5 `calcular_parametros_liga()`

**No la usa el análisis final.** Es un resto de la versión heurística. Líneas 56–83:

```python
def calcular_parametros_liga(df):
    """
    Calcula los promedios históricos de goles y los factores de localía a partir del DataFrame.
    """

    # Calcula el promedio de goles anotados por los equipos locales.
    avg_home_goals = df["home_score"].mean()

    # Calcula el promedio de goles anotados por los equipos visitantes.
    avg_away_goals = df["away_score"].mean()

    # Calcula el promedio general de goles anotados por equipo a partir de los promedios de local y visitante.
    avg_team_goals = (
        avg_home_goals + avg_away_goals
    ) / 2

    # Calcula el factor de localía como la proporción entre los goles promedio del local y el promedio general.
    home_factor = avg_home_goals / avg_team_goals

    # Calcula el factor de visitante como la proporción entre los goles promedio del visitante y el promedio general.
    away_factor = avg_away_goals / avg_team_goals

    # Devuelve los tres parámetros calculados en un diccionario.
    return {
        "avg_team_goals": avg_team_goals,
        "home_factor": home_factor,
        "away_factor": away_factor
    }
```

**Qué hace:** tres promedios y dos cocientes. Con los 9,540 partidos:

| Variable | Fórmula | Valor |
|---|---|---|
| `avg_home_goals` | goles promedio del local | 1.5347 |
| `avg_away_goals` | goles promedio del visitante | 1.1898 |
| `avg_team_goals` | (1.5347 + 1.1898) / 2 | **1.3623** goles por equipo y partido |
| `home_factor` | 1.5347 / 1.3623 | **1.1266**: el local anota ≈ 12.7 % más que un equipo promedio |
| `away_factor` | 1.1898 / 1.3623 | **0.8734**: el visitante, ≈ 12.7 % menos |

Los dos factores siempre suman 2 (porque `avg_team_goals` es el promedio de los otros dos). Devuelve un
**diccionario** (en R, una lista con nombres).

**En R** (ejecutado; da 1.3623, 1.1266 y 0.8734):

```r
calcular_parametros_liga <- function(df) {
  avg_home_goals <- mean(df$home_score)
  avg_away_goals <- mean(df$away_score)
  avg_team_goals <- (avg_home_goals + avg_away_goals) / 2
  list(avg_team_goals = avg_team_goals,
       home_factor = avg_home_goals / avg_team_goals,
       away_factor = avg_away_goals / avg_team_goals)
}
```

**Para qué servía.** En la versión inicial, estos factores alimentaban dos funciones que ya se borraron:

- `get_lambda()` calculaba los goles esperados como una **mezcla con pesos fijados a mano**:
  λ = 0.50 · (estadísticas de la temporada) + 0.35 · (forma reciente) + 0.15 · (Elo), y luego multiplicaba por
  `home_factor` (local) o `away_factor` (visitante).
- `simular_partido()` simulaba 30,000 marcadores con esas λ y contaba en qué fracción ganaba cada uno (más prórroga y
  penales, propios de un Mundial).

**Por qué el GLM las sustituye.** En la regresión de Poisson del notebook, los "pesos" de cada variable son
**coeficientes estimados con los datos** (máxima verosimilitud, con errores estándar y valores p), y la localía la
capta el hecho de tener **una ecuación para el local y otra para el visitante**, cada una con su intercepto. Además,
las probabilidades 1X2 salen exactas con la distribución de Skellam, sin error de simulación.

Un ejemplo de por qué conviene estimar la localía en vez de fijarla: en **todo** el histórico el local anota
1.29 veces lo del visitante (1.5347 / 1.1898), pero en el periodo de entrenamiento 2019/20–2023/24 (que incluye los
partidos sin público) la razón fue **1.19** (1.5614 / 1.3115). El GLM, estimado en ese periodo, reproduce 1.19:
para dos equipos iguales (diferencia de Elo 0) con goles a favor y en contra iguales al promedio del entrenamiento
(1.4365), M0 da λ = 1.4859 para el local y 1.2482 para el visitante, razón 1.19. Los factores fijos habrían
supuesto 1.29.

> **Decisión:** el modelo final es un GLM de Poisson con coeficientes estimados; la heurística de pesos fijos y sus
> factores de localía se abandonaron (las funciones se borraron; `calcular_parametros_liga()` quedó sin uso).
> **Alternativas:** (a) heurística con pesos fijos (50/35/15) y factores de localía — simple, pero los pesos son
> arbitrarios y nadie los validó; (b) GLM de Poisson con ecuaciones separadas (la elegida); (c) modelos más
> elaborados como Dixon y Coles (1997) o Poisson bivariado (Karlis y Ntzoufras, 2003) — corrigen la dependencia
> entre los goles de ambos equipos, pero son más difíciles de estimar y explicar; no se probaron.
> **Por qué ésta:** el GLM es el modelo de conteo que se ve en el diplomado, estima cuánto aporta cada variable y
> permite comparar especificaciones (M0–M4) con la misma métrica.
> **Evidencia en el proyecto:** no se comparó la heurística contra el GLM (se descartó por diseño, antes de
> evaluar). Lo que sí se midió: M0 le gana a la referencia ingenua en prueba (LogLoss 1.0331 contra 1.0868).
> **Si preguntan:** "`calcular_parametros_liga` es un resto de la versión heurística; en el modelo final la localía y
> los pesos los estima la regresión con los datos."

## 10.6 El bloque que se ejecuta al importar

Líneas 85–98 (fuera de cualquier función):

```python
# Cargar el histórico
df = load_history()

# Calcular parámetros de la liga: calcula los promedios históricos de goles y los factores de localía a partir del DataFrame.
parametros = calcular_parametros_liga(df)

# Extrae del diccionario el promedio general de goles por equipo.
avg_team_goals = parametros["avg_team_goals"]

# Extrae el factor de localía calculado a partir del histórico.
HOME_FACTOR = parametros["home_factor"]

# Extrae el factor correspondiente a los equipos visitantes.
AWAY_FACTOR = parametros["away_factor"]
```

**Qué pasa al hacer `import wc_predictor`:** Python ejecuta el archivo de arriba abajo. Las líneas `def` sólo
**definen** funciones, pero estas 5 líneas sueltas **se ejecutan**: leen el CSV y calculan los parámetros. Es un
**efecto secundario** de importar.

| Prueba (hecha con la versión entregada) | Resultado |
|---|---|
| Importar desde la carpeta del código | tarda ≈ 0.1 s y **no imprime nada** (la versión inicial imprimía el ranking Elo) |
| Importar desde otra carpeta | **falla**: `FileNotFoundError: [Errno 2] No such file or directory: 'E0_consolidado.csv'`, porque la ruta es relativa a la carpeta actual |
| Variables que deja creadas | `df` (9,540 × 34), `parametros`, `avg_team_goals` = 1.3623, `HOME_FACTOR` = 1.1266, `AWAY_FACTOR` = 0.8734 |

Consecuencias:

- El notebook funciona porque Jupyter corre en la carpeta del notebook, que es la misma del CSV.
- El tablero importa el módulo **cambiando temporalmente de carpeta** y con la salida silenciada
  (`datos_dashboard._importar_wc_predictor()`, líneas 55–68). Su comentario todavía dice que el módulo "imprime el
  ranking Elo": eso ya no pasa, pero silenciar no estorba.
- De estas variables, sólo `avg_team_goals` se usa: es el respaldo de `recent_form()` cuando un equipo no tiene
  partidos previos. El `df` del módulo nadie lo usa (el notebook y el tablero vuelven a llamar a `load_history()`).
- **¿Hay fuga de información?** `avg_team_goals` se calcula con los 9,540 partidos, incluidos los posteriores a
  cualquier fecha de predicción. **No afecta al modelo final**: sólo aparece en los 4 partidos de equipos sin
  historial previo (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026), y esas filas se excluyen porque
  sus tiros quedan vacíos (ver [10.10](#1010-recent_form)).

**En R** pasa lo mismo: `source("wc_predictor.R")` ejecuta todo el código suelto del script. La buena práctica en
ambos lenguajes es dejar en el módulo **sólo definiciones**. En Python, el código de ejemplo se protege con
`if __name__ == "__main__":`; en R, un equivalente para scripts es `if (sys.nframe() == 0L) { ... }`, que corre
con `Rscript archivo.R` pero no con `source()` (probado).

```r
df <- load_history()                         # se ejecuta al hacer source("wc_predictor.R")
parametros <- calcular_parametros_liga(df)
avg_team_goals <- parametros$avg_team_goals  # 1.3623
HOME_FACTOR <- parametros$home_factor        # 1.1266
AWAY_FACTOR <- parametros$away_factor        # 0.8734
```

> **Decisión:** se conservó el bloque que lee el CSV al importar (herencia de la versión inicial; no fue una
> decisión de diseño del análisis).
> **Alternativas:** (a) dejar sólo definiciones y pasar el promedio de respaldo como argumento de `recent_form()` —
> sin efectos secundarios, el módulo se podría importar desde cualquier carpeta; (b) calcularlo sólo cuando se
> necesite y con los partidos anteriores a la fecha (sin usar datos futuros); (c) dejarlo como está.
> **Por qué se puede conservar:** no cambia ningún resultado (las 4 filas donde actuaría se excluyen).
> **Evidencia en el proyecto:** 2,700 partidos construidos → 2,696 tras quitar las 4 filas sin tiros previos.
> **Si preguntan:** "Al importarse lee el CSV para calcular un promedio de respaldo; ese respaldo sólo aparece en 4
> partidos que se excluyen, así que no hay fuga. Lo ideal sería quitar ese código suelto."

## 10.7 `expected_score()`

Líneas 101–106:

```python
# Calcula la probabilidad esperada de que el equipo A obtenga un resultado favorable frente al equipo B a partir de la diferencia entre sus ratings Elo.
#Notese que ELO_SCALE la tomamos como 400 como base
def expected_score(r_a, r_b, scale=ELO_SCALE):

    # Transforma la diferencia de ratings en una probabilidad entre 0 y 1. ELO_SCALE controla la sensibilidad de la probabilidad a dicha diferencia.
    return 1 / (1 + 10 ** ((r_b - r_a) / scale))
```

**Qué hace:** calcula el **resultado esperado** del equipo A contra el B:

$$
E_A = \frac{1}{1 + 10^{(R_B - R_A)/\text{scale}}}, \qquad \text{scale} = 400
$$

- `10 ** x` es "10 elevado a x" (en R, `10^x`).
- Entradas: dos ratings (números) y, opcional, la escala. Salida: un número entre 0 y 1.
- Sólo importa la **diferencia** $R_A - R_B$, no el nivel: 1,700 contra 1,500 da lo mismo que 1,500 contra 1,300.
- Es simétrica: $E_A + E_B = 1$ (comprobado: 0.7597 + 0.2403 = 1).
- **No** es la probabilidad de ganar: cuenta el empate como medio punto (el comentario del código dice
  "probabilidad"; es más preciso decir "resultado esperado"). Ver [capítulo 4](04_elo.md).

**Ejemplos (calculados con la función):**

| Diferencia $R_A - R_B$ | 0 | +25 | +50 | +100 | +200 | +400 | −100 | −200 |
|---|---|---|---|---|---|---|---|---|
| $E_A$ | 0.5000 | 0.5359 | 0.5715 | 0.6401 | 0.7597 | 0.9091 | 0.3599 | 0.2403 |

- Real: Arsenal (1,787.12) contra Man City (1,779.19), diferencia 7.94 → $E$ = **0.5114**.
- Con `scale=800`, la misma diferencia de +200 da 0.6401 (lo mismo que +100 con escala 400): la escala sólo dice
  cuántos puntos "valen" una misma ventaja.

**En R** (ejecutado):

```r
expected_score <- function(r_a, r_b, scale = ELO_SCALE) 1 / (1 + 10^((r_b - r_a) / scale))
expected_score(1700, 1500)   # 0.7597
```

> **Decisión:** el resultado esperado compara los dos ratings tal cual, **sin sumar puntos al local**.
> **Alternativas:** (a) sumar una ventaja fija al local antes de calcular $E$ (en estos datos la localía vale
> ≈ 50 puntos) — el Elo sería algo más preciso partido a partido; (b) estimar esa ventaja junto con K en la
> calibración — un parámetro más; (c) sin ventaja (la elegida).
> **Por qué ésta:** la localía no se pierde: la estima la regresión, que tiene una ecuación para los goles del local
> y otra para los del visitante, cada una con su intercepto. El costo es pequeño: sin ventaja, el local saca en
> promedio 0.0805 puntos de resultado más de lo esperado por partido (0.5789 contra 0.4985), es decir **+1.2 puntos
> de Elo** con K = 15 cada vez que juega en casa, y los devuelve de visitante. Como cada equipo juega la mitad de sus
> partidos en casa, se compensa a lo largo de la temporada (sólo agrega un poco de ruido según el orden del
> calendario).
> **Evidencia en el proyecto:** localía ≈ 50 puntos de Elo (tablero, página *Patrones*); M0, para dos equipos
> iguales, espera 1.19 veces más goles del local que del visitante ([10.5](#105-calcular_parametros_liga)).
> **Si preguntan:** "El Elo no tiene ventaja de local a propósito: la localía la estima la regresión, con
> ecuaciones separadas para local y visitante."

## 10.8 `update_elo()`

Líneas 109–118:

```python
# Actualiza el rating Elo del equipo A después de observar el resultado del partido.
def update_elo(r_a, r_b, score_a, k=ELO_K, scale=ELO_SCALE):

    # Calcula el resultado esperado del equipo A antes del partido.
    exp_a = expected_score(r_a, r_b, scale=scale)

    # Actualiza el Elo según la diferencia entre el resultado observado
    # (1 = victoria, 0.5 = empate, 0 = derrota) y el resultado esperado.
    # k determina qué tan rápido responde el rating a nueva información, por defecto es 30.
    return r_a + k * (score_a - exp_a)
```

**Qué hace:** $R_A^{\text{nuevo}} = R_A + K\,(S_A - E_A)$.

- `score_a` es el resultado real de A: 1 (gana), 0.5 (empata) o 0 (pierde).
- Sólo actualiza **a un equipo**. Para un partido se llama dos veces, una por equipo, **con los ratings de antes del
  partido** (así lo hacen `build_elo` y el notebook).
- El comentario "por defecto es 30" está desactualizado: el valor por defecto es `ELO_K = 15`.
- **Detalle de Python:** el valor por defecto `k=ELO_K` se fija **cuando se define la función** (al importar). Si
  alguien cambiara después `wc_predictor.ELO_K = 20`, la función seguiría usando 15. Por eso el notebook pasa K
  siempre de forma explícita (`update_elo(rh, ra, sh, k=k_elo, scale=escala_elo)`). En R, los valores por defecto se
  evalúan al llamar la función, así que ahí sí se vería el cambio.

**Ejemplo:** un favorito de 1,700 contra un rival de 1,500 ($E$ = 0.7597):

| Resultado del favorito | `update_elo(1700, 1500, ...)` con K = 15 (vigente) | Con K = 30 (versión inicial) |
|---|---|---|
| Gana (`score_a = 1`) | 1,703.60 (**+3.60**); el rival queda en 1,496.40 (−3.60) | 1,707.21 (+7.21) |
| Empata (0.5) | 1,696.10 (**−3.90**) | 1,692.21 (−7.79) |
| Pierde (0) | 1,688.60 (**−11.40**) | 1,677.21 (−22.79) |

Lo que gana uno lo pierde el otro (suma cero). Con K = 15 todos los movimientos son la mitad que con K = 30.

**En R** (ejecutado):

```r
update_elo <- function(r_a, r_b, score_a, k = ELO_K, scale = ELO_SCALE) {
  exp_a <- expected_score(r_a, r_b, scale = scale)
  r_a + k * (score_a - exp_a)
}
update_elo(1700, 1500, 1)   # 1703.604
```

> **Decisión:** K = 15, elegido por validación temporal, y el resultado sólo cuenta victoria, empate o derrota (no
> el margen de goles).
> **Alternativas:** (a) K a mano (30 en la versión inicial) — habitual pero arbitrario; (b) K elegido en una
> rejilla con validación temporal (lo elegido); (c) K variable, más grande para equipos nuevos o al inicio de
> temporada — reacciona rápido cuando hay poca información, pero agrega parámetros; (d) multiplicar K por un factor
> que crece con la diferencia de goles, como hacen algunos sistemas públicos — usa más información, pero premia
> golear y agrega otro parámetro. (c) y (d) no se probaron.
> **Por qué ésta:** de los parámetros del Elo, K es el que cambia su comportamiento (la escala sólo reexpresa los
> ratings y el 1,500 sólo fija el nivel, ver [10.9](#109-build_elo)), así que es el que vale la pena calibrar; sin
> margen, el Elo mide sólo resultados, y la información de goles entra al modelo por separado (promedios de goles
> de la temporada).
> **Evidencia en el proyecto:** LogLoss promedio de calibración 0.959558 con K = 15 (y k = 0) contra 0.962178 de la
> configuración inicial (K = 30, k = 10). Tabla completa por K en el [capítulo 4](04_elo.md).
> **Si preguntan:** "K = 15 salió de una búsqueda en rejilla con validación temporal; no usamos el margen de goles
> para que el Elo mida resultados, y los goles entran aparte."

## 10.9 `build_elo()`

Recorre todo el histórico y devuelve el rating **final** de cada equipo. Líneas 120–180:

```python
def build_elo(df, elo_init=ELO_INIT, k=ELO_K, scale=ELO_SCALE):
    """
    Calcula el rating Elo de cada club de la Premier League
    utilizando los resultados históricos.

    Los partidos se procesan cronológicamente.
    Cada equipo comienza con un Elo inicial de 1500.
    """

    # Crea un diccionario vacío donde se almacenará el rating Elo
    # actualizado de cada equipo.
    ratings = {}

    # Ordena los partidos cronológicamente y recorre el histórico
    # partido por partido.
    for _, row in df.sort_values("date").iterrows():

        # Extrae el nombre del equipo local.
        h = row["home_team"]

        # Extrae el nombre del equipo visitante.
        a = row["away_team"]

        # Extrae los goles anotados por el equipo local.
        hs = row["home_score"]

        # Extrae los goles anotados por el equipo visitante.
        as_ = row["away_score"]

        # Elo anterior al partido

        # Obtiene el Elo actual del local, si el equipo todavía no aparece en el diccionario, se le asigna el Elo inicia.
        rh = ratings.get(h, elo_init)

        # Obtiene el Elo actual del visitante, si el equipo todavía no aparece en el diccionario, se le asigna el Elo inicial.
        ra = ratings.get(a, elo_init)

        # Resultado del partido

        # Si el local anota más goles, se asigna 1 al local y 0 al visitante.
        if hs > as_:
            sh, sa = 1, 0

        # Si el visitante anota más goles, se asigna 0 al local y 1 al visitante.
        elif hs < as_:
            sh, sa = 0, 1

        # Si el partido termina empatado, ambos equipos reciben un resultado de 0.5.
        else:
            sh, sa = 0.5, 0.5

        # Actualización de Elo

        # Actualiza el Elo del equipo local comparando su resultado observado con el resultado esperado frente al Elo del visitante.
        ratings[h] = update_elo(rh, ra, sh, k=k, scale=scale)

        # Actualiza el Elo del equipo visitante utilizando los ratings que ambos equipos tenían antes del partido.
        ratings[a] = update_elo(ra, rh, sa, k=k, scale=scale)

    # Devuelve un diccionario con el Elo final de cada equipo después de procesar todos los partidos del histórico.
    return ratings
```

**Qué hace, bloque por bloque:**

| Líneas | Código | Qué hace | En R |
|---|---|---|---|
| 131 | `ratings = {}` | Diccionario vacío `{equipo: rating}` | vector con nombres vacío, `numeric(0)` |
| 135 | `for _, row in df.sort_values("date").iterrows():` | Recorre los partidos en orden de fecha, uno por uno. `iterrows()` entrega pares (índice, fila); el `_` descarta el índice | `for (i in seq_len(nrow(df)))` sobre el histórico ordenado |
| 138–147 | `h`, `a`, `hs`, `as_` | Equipos y goles del partido. Se llama `as_` porque `as` es palabra reservada de Python | `df$home_team[i]`, … |
| 152–155 | `ratings.get(h, elo_init)` | Rating actual del equipo o 1,500 si todavía no aparece | `if (h %in% names(ratings)) ratings[[h]] else 1500` |
| 160–169 | `if / elif / else` | Resultado real: (1, 0), (0, 1) o (0.5, 0.5) | `if (...) ... else if (...) ... else ...` |
| 174–177 | dos llamadas a `update_elo` | Actualiza a los dos equipos. La segunda usa `rh`, el rating del local **antes** del partido, no el recién actualizado | igual |
| 180 | `return ratings` | Ratings **finales** después de todos los partidos | `ratings` |

**Ejemplo real** (`build_elo(df)` con los 9,540 partidos; K = 15 por defecto, idéntico a `build_elo(df, k=15)`):

- Tarda ≈ 0.7 s y devuelve **45 equipos** (todos los que han jugado Premier desde 2001/02).
- El promedio de los 45 ratings es **1,500.000000**: como lo que gana uno lo pierde el otro, el promedio no se
  mueve. Ojo: los 20 equipos de 2026/27 promedian 1,584.9, porque los que descendieron hace años se quedaron con
  ratings bajos (el último es Derby, 1,320.84).
- Los 10 primeros al 14-sep-2026: Arsenal 1,787.12 · Man City 1,779.19 · Liverpool 1,683.74 · Man United 1,638.49 ·
  Aston Villa 1,625.20 · Chelsea 1,614.82 · Bournemouth 1,609.99 · Brighton 1,605.36 · Newcastle 1,592.32 ·
  Brentford 1,590.63.
- Un partido concreto: el último Man City–Arsenal de la base (19-abr-2026, 2–1). Antes: City 1,764.92 y Arsenal
  1,764.00, $E$ del local = 0.5013. City gana: 15 · (1 − 0.5013) = **+7.48** → 1,772.40; Arsenal **−7.48** →
  1,756.52.

**La escala es sólo una convención (comprobado).** Si se duplica la escala (800) **y** se duplica K (30), todos los ratings
medidos desde 1,500 salen exactamente al doble: `build_elo(df, k=30, scale=800)` − 1,500 = 2 × (`build_elo(df)` −
1,500), con diferencias de $2 \times 10^{-12}$. Como la regresión usa `elo_diff / ESCALA_ELO`, el modelo recibe la
misma variable. Por eso 400 es una convención y **K es el parámetro que importa**.

**Quién la usa:** la predicción individual del notebook (§10, `predecir_partido`:
`elo = wc_predictor.build_elo(df_pre, k=K_ELO, scale=ESCALA_ELO)`, con `df_pre` = partidos anteriores al corte) y
el simulador del tablero. La base de entrenamiento **no** la usa (ver [10.1](#101-panorama)).

**En R** (ejecutado; Arsenal 1,787.12, Man City 1,779.19, 45 equipos, promedio 1,500). Versión completa y comentada
en [`equivalencias_R/01_elo.R`](equivalencias_R/01_elo.R):

```r
build_elo <- function(df, elo_init = ELO_INIT, k = ELO_K, scale = ELO_SCALE) {
  ratings <- numeric(0)                                   # ≈ diccionario {} de Python
  df <- arrange(df, date)
  for (i in seq_len(nrow(df))) {
    h <- df$home_team[i]; a <- df$away_team[i]
    hs <- df$home_score[i]; as_ <- df$away_score[i]
    rh <- if (h %in% names(ratings)) ratings[[h]] else elo_init   # ratings.get(h, elo_init)
    ra <- if (a %in% names(ratings)) ratings[[a]] else elo_init
    if (hs > as_) { sh <- 1; sa <- 0 } else if (hs < as_) { sh <- 0; sa <- 1 } else { sh <- 0.5; sa <- 0.5 }
    ratings[h] <- update_elo(rh, ra, sh, k = k, scale = scale)
    ratings[a] <- update_elo(ra, rh, sa, k = k, scale = scale)   # usa rh PREVIO
  }
  ratings
}
```

> **Decisión:** todo equipo que aparece por primera vez empieza en 1,500; los ratings no se acercan a la media entre
> temporadas; sólo cuentan partidos de Premier League (un equipo que desciende conserva su rating hasta que vuelve).
> **Alternativas:** (a) dar a los recién llegados el rating típico de un ascendido en vez de 1,500; (b) regresión a la
> media cada verano (acercar cada rating una fracción hacia el promedio, porque las plantillas cambian); (c) incluir
> la segunda división (Championship) para que los descendidos sigan acumulando historia; (d) lo elegido. Ninguna de
> las tres primeras se probó.
> **Por qué ésta:** es el Elo estándar y el más fácil de explicar; los datos del proyecto son sólo de Premier
> (Football-Data `E0`); arrancar en 2001/02 da 18 temporadas para que los ratings se estabilicen antes de 2019, cuando
> empieza la base de modelación.
> **Evidencia en el proyecto:** los cuatro equipos sin historial (Brentford 2021, Nott'm Forest 2022, Luton 2023,
> Coventry 2026) entraron con 1,500, entre los lugares 15 y 18 de 20. Luton entró 15.º, por encima de tres equipos
> que ya estaban en Premier (Nott'm Forest 1,496.3, Fulham 1,492.0, Bournemouth 1,469.6), y terminó su temporada en
> 1,443.4. En sentido contrario, Sunderland volvió en 2025/26 con el rating congelado desde 2017 (1,421.8, último
> lugar) y terminó esa temporada en 1,521.0.
> **Si preguntan:** "Es el Elo estándar: 1,500 para los nuevos y sin ajustes entre temporadas. Sabemos que puede
> sobrevalorar a un recién llegado y que congela a los descendidos; corregirlo es una extensión."

## 10.10 `recent_form()`

Promedio **ponderado** de los últimos `n` partidos de un equipo (de local y de visitante, de cualquier temporada),
con más peso para los recientes. Devuelve seis variables: goles a favor y en contra, tiros realizados y concedidos,
y tiros a puerta realizados y concedidos. Teoría y ejemplos en el [capítulo 5](05_promedios_ajustados_y_forma.md).
Líneas 185–347; abajo, el código de cada bloque tal como está en el archivo, sin las líneas que sólo son comentario
(el archivo comenta cada línea).

**Bloque 1 — firma y elección de partidos** (líneas 185–208; la *docstring* va abreviada: en el archivo también
lista las seis variables):

```python
def recent_form(df, team, n=10, decay=0.85):
    """
    Calcula la forma reciente de un equipo utilizando
    sus últimos n partidos.
    ...
    Los partidos más recientes reciben mayor peso.
    """
    tmp = df[
        (df["home_team"] == team) |  #| O
        (df["away_team"] == team)
    ].sort_values("date").tail(n)  # Ordena los partidos cronológicamente y conserva únicamente los n encuentros más recientes.
```

- `(df["home_team"] == team) | (df["away_team"] == team)`: partidos donde el equipo jugó de local **o** de
  visitante (`|` es "o", igual que en R).
- `.sort_values("date").tail(n)`: ordena y se queda con los `n` más recientes (o menos, si no hay tantos).
- **No filtra por fecha.** Usa todo lo que reciba en `df`. Quien la llama debe pasarle **sólo partidos anteriores**
  al encuentro. El notebook lo garantiza: `crear_variables_partido` recibe `df_pre` y lanza un error si trae alguna
  fecha igual o posterior al partido.

**Bloque 2 — equipo sin partidos** (líneas 213–223):

```python
    if tmp.empty:
        return {
            "gf": avg_team_goals,
            "ga": avg_team_goals,
            "shots_for": np.nan,
            "shots_against": np.nan,
            "sot_for": np.nan,
            "sot_against": np.nan
        }
```

Si el equipo nunca ha jugado en la base, devuelve el promedio de la liga en goles (`avg_team_goals` = 1.3623, del
bloque que se ejecuta al importar) y **vacíos** (`NaN`, en R `NA`) en los tiros. Esos vacíos son los que después
hacen que el notebook excluya 4 partidos (`dropna` sobre las columnas de tiros).

**Bloque 3 — orientar cada partido desde el punto de vista del equipo** (líneas 228–297):

```python
    gf = []
    ga = []
    shots_for = []
    shots_against = []
    sot_for = []
    sot_against = []

    for _, row in tmp.iterrows():
        if row["home_team"] == team:
            gf.append(row["home_score"])
            ga.append(row["away_score"])
            shots_for.append(row["HS"])
            shots_against.append(row["AS"])
            sot_for.append(row["HST"])
            sot_against.append(row["AST"])
        else:
            gf.append(row["away_score"])
            ga.append(row["home_score"])
            shots_for.append(row["AS"])
            shots_against.append(row["HS"])
            sot_for.append(row["AST"])
            sot_against.append(row["HST"])
```

Si el equipo fue local, sus goles son `home_score` y sus tiros `HS`/`HST`; si fue visitante, al revés. Así, "goles a
favor" siempre son los del equipo. `lista.append(x)` agrega `x` al final de la lista (en R, `c(lista, x)`, aunque en
R se hace todo de una vez con `ifelse()`).

**Bloque 4 — pesos geométricos normalizados** (líneas 303–315):

```python
    w = np.array([
        decay ** (len(gf) - 1 - i)
        for i in range(len(gf))
    ])
    w = w / w.sum()
```

- Es una *list comprehension*: genera un peso por partido. Con `m = len(gf)` partidos, ordenados del más antiguo
  (`i = 0`) al más reciente (`i = m − 1`), el peso es $0.85^{m-1-i}$: el más reciente recibe $0.85^0 = 1$, el
  anterior 0.85, luego 0.7225, etc. En R: `decay^((m - 1):0)`.
- `w / w.sum()` los **normaliza** para que sumen 1. Así el resultado sigue en las unidades originales (goles o tiros
  por partido), aunque haya menos de 10 partidos.

**Bloque 5 — promedios ponderados** (líneas 320–347, abreviado):

```python
    return {
        "gf": float(np.average(gf, weights=w)),
        "ga": float(np.average(ga, weights=w)),
        "shots_for": float(
            np.average(shots_for, weights=w)
        ),
        ...   # shots_against, sot_for y sot_against, igual
    }
```

`np.average(x, weights=w)` es $\sum_i w_i x_i$ (en R, `weighted.mean(x, w)`); `float(...)` convierte el número de
NumPy en un número normal de Python.

**Ejemplo real:** Liverpool antes de su primer partido de la base de modelación (9-ago-2019). Sus últimos 10
partidos son de marzo a mayo de 2019:

| Fecha | Partido | Peso | GF | GA | Tiros |
|---|---|---|---|---|---|
| 2019-03-03 | Everton 0–0 Liverpool | 0.0433 | 0 | 0 | 10 |
| 2019-03-10 | Liverpool 4–2 Burnley | 0.0509 | 4 | 2 | 23 |
| 2019-03-17 | Fulham 1–2 Liverpool | 0.0599 | 2 | 1 | 16 |
| 2019-03-31 | Liverpool 2–1 Tottenham | 0.0704 | 2 | 1 | 14 |
| 2019-04-05 | Southampton 1–3 Liverpool | 0.0829 | 3 | 1 | 17 |
| 2019-04-14 | Liverpool 2–0 Chelsea | 0.0975 | 2 | 0 | 15 |
| 2019-04-21 | Cardiff 0–2 Liverpool | 0.1147 | 2 | 0 | 17 |
| 2019-04-26 | Liverpool 5–0 Huddersfield | 0.1349 | 5 | 0 | 21 |
| 2019-05-04 | Newcastle 2–3 Liverpool | 0.1588 | 3 | 2 | 11 |
| 2019-05-12 | Liverpool 2–0 Wolves | 0.1868 | 2 | 0 | 13 |

Resultado de `recent_form(df_pre, "Liverpool")`: goles a favor **2.6617** (el promedio simple sería 2.50: pesa más
el 5–0 reciente), goles en contra 0.6325 (simple: 0.70), tiros 15.3765, tiros concedidos 8.1536, tiros a puerta
5.2533 y concedidos 2.7167. Son exactamente los valores de la primera fila de `premier_training_data.csv`.

Otros dos casos reales:

- **Norwich** (recién ascendido) para ese mismo partido: sus últimos 10 partidos de Premier son de **marzo a mayo de
  2016**; goles a favor 0.9062 y en contra 1.6870.
- **Brentford** antes de su primer partido (13-ago-2021): no tiene partidos en la base → goles 1.3623 (el respaldo) y
  tiros vacíos. Es una de las 4 filas excluidas.
- **Llamada incorrecta, para ver por qué importa filtrar:** `recent_form(df, "Liverpool")` con el histórico completo
  da 1.5094 goles a favor: son los últimos 10 partidos hasta septiembre de 2026, información del futuro para un
  partido de 2019.

**En R** (ejecutado; mismos seis valores para Liverpool y el mismo respaldo para Brentford):

```r
recent_form <- function(df, team, n = 10, decay = 0.85) {
  tmp <- df |> filter(home_team == team | away_team == team) |> arrange(date) |> tail(n)
  if (nrow(tmp) == 0) {
    return(c(gf = avg_team_goals, ga = avg_team_goals, shots_for = NA, shots_against = NA,
             sot_for = NA, sot_against = NA))
  }
  local <- tmp$home_team == team                      # ¿jugó de local?
  x <- tibble(gf            = ifelse(local, tmp$home_score, tmp$away_score),
              ga            = ifelse(local, tmp$away_score, tmp$home_score),
              shots_for     = ifelse(local, tmp$HS,  tmp$AS),
              shots_against = ifelse(local, tmp$AS,  tmp$HS),
              sot_for       = ifelse(local, tmp$HST, tmp$AST),
              sot_against   = ifelse(local, tmp$AST, tmp$HST))
  w <- decay^((nrow(tmp) - 1):0)                       # el más reciente pesa decay^0 = 1
  w <- w / sum(w)                                      # normalizar: suman 1
  sapply(x, weighted.mean, w = w)                      # np.average(..., weights = w)
}
recent_form(df |> filter(date < as.Date("2019-08-09")), "Liverpool")
```

> **Decisión:** forma reciente = promedio de los últimos 10 partidos con pesos geométricos (0.85) normalizados, sin
> importar la temporada, y la función no filtra fechas (lo hace quien la llama).
> **Alternativas:** (a) promedio simple de los últimos N partidos — más fácil, pero un partido de hace dos meses pesa
> igual que el de ayer; (b) pesos que decaen con los **días** transcurridos, como en Dixon y Coles (1997), que
> ponderan los partidos pasados con un decaimiento exponencial en el tiempo — trata bien las pausas (verano,
> Mundial), pero agrega un parámetro de tiempo; (c) otras ventanas (5 o 20 partidos) u otros decaimientos (0.7, 0.95);
> (d) sólo partidos de la temporada en curso — evita usar partidos de hace años, pero deja sin datos al inicio de la
> temporada; (e) goles esperados (xG) en vez de tiros — en este archivo sólo existen para los 40 partidos de 2026/27.
> Ninguna se probó.
> **Por qué ésta:** con 10 partidos hay datos desde la primera jornada (vienen de la temporada anterior), y 0.85 hace
> que los 3 últimos partidos pesen 48 %; normalizar deja el resultado en goles o tiros por partido. Dejar el filtro
> de fechas a quien llama permite usar la misma función para entrenar y para predecir.
> **Evidencia en el proyecto:** los valores no se optimizaron. Las variables de forma sólo entran en M1–M4, y M0
> (sin ellas) fue el mejor en prueba (1.0331 contra 1.0347 de M1, que agrega la forma de goles).
> **Si preguntan:** "Son los últimos 10 partidos con más peso a los recientes; los valores son razonables pero no se
> optimizaron, y el modelo final (M0) no los usa."

## 10.11 `season_stats()`

Goles a favor y en contra por partido de un equipo **en la temporada en curso**, antes de una fecha, mezclados con
una referencia previa según k (*shrinkage*). Teoría, ejemplos y calibración de k en el
[capítulo 5](05_promedios_ajustados_y_forma.md). Líneas 349–563; abajo, cada bloque tal como está en el archivo, sin
las líneas que sólo son comentario.

**Bloque 1 — firma y filtro estricto de fecha** (líneas 349–370):

```python
def season_stats(df, team, as_of_date, k=SHRINKAGE_K):
    """
    Calcula los goles promedio a favor y en contra
    de un equipo utilizando shrinkage.
    ...
    k controla el peso de la información anterior.

    Utiliza exclusivamente partidos anteriores
    a la fecha de predicción.
    """
    fecha = pd.to_datetime(as_of_date)
    df_pre = df[df["date"] < fecha].copy()
```

- `as_of_date` puede ser texto (`"2019-08-17"`) o fecha; `pd.to_datetime` lo convierte (en R, `as.Date()`).
- `df["date"] < fecha` es **estricto**: quedan fuera el propio partido y todos los del mismo día.
- `.copy()` hace una copia independiente (evita advertencias de pandas al modificar un subconjunto). En R no hace
  falta: `filter()` siempre devuelve una tabla nueva.
- A diferencia de `recent_form()`, esta función **sí** filtra por fecha ella misma.

**Bloque 2 — ¿en qué temporada cae la fecha?** (líneas 375–394):

```python
    if fecha.month >= 8:
        season_year = fecha.year
    else:
        season_year = fecha.year - 1

    season_start = pd.Timestamp(
        year=season_year,
        month=8,
        day=1
    )

    previous_start = pd.Timestamp(
        year=season_year - 1,
        month=8,
        day=1
    )
```

De agosto a diciembre, la temporada empezó ese año; de enero a julio, el año anterior. Ejemplos: 17-ago-2019 →
temporada que empieza el 1-ago-2019 (la anterior, el 1-ago-2018); 26-jul-2020 (último partido de 2019/20, alargada
por la pandemia) → sigue en la temporada del 1-ago-2019; 15-sep-2026 → 1-ago-2026.

**Bloque 3 — partidos de la temporada actual y de la anterior** (líneas 399–421):

```python
    current = df_pre[
        df_pre["date"] >= season_start
    ]
    current = current[
        (current["home_team"] == team) |
        (current["away_team"] == team)
    ]
    previous_league = df_pre[
        (df_pre["date"] >= previous_start) &
        (df_pre["date"] < season_start)
    ]
    previous = previous_league[
        (previous_league["home_team"] == team) |
        (previous_league["away_team"] == team)
    ]
```

- `current`: partidos del equipo en la temporada actual, antes de la fecha. Su número es **n**.
- `previous_league`: **todos** los partidos de la liga en la temporada anterior (sirven para el promedio de la liga).
- `previous`: los del equipo en la temporada anterior (vacío si no jugó en Premier).
- `&` es "y", `|` es "o" (igual en R).

**Bloque 4 — función interna `calculate_stats()`** (líneas 426–461):

```python
    def calculate_stats(matches):
        if matches.empty:
            return None
        gf = np.where(
            matches["home_team"] == team,
            matches["home_score"],
            matches["away_score"]
        )
        ga = np.where(
            matches["home_team"] == team,
            matches["away_score"],
            matches["home_score"]
        )
        return {
            "gf": float(np.mean(gf)),
            "ga": float(np.mean(ga))
        }

    stats_current = calculate_stats(current)
    stats_previous = calculate_stats(previous)
```

- Es una función **dentro** de otra: sólo existe mientras corre `season_stats` y "ve" la variable `team` de la
  función de afuera (en R pasa igual con funciones definidas dentro de funciones).
- `np.where(condición, x, y)` toma `x` donde la condición es cierta y `y` donde no (en R, `ifelse()`): los goles a
  favor son `home_score` si el equipo fue local y `away_score` si fue visitante.
- Si no hay partidos devuelve `None` (en R, `NULL`).

**Bloque 5 — la referencia previa, en cascada** (líneas 467–517):

```python
    if stats_previous is None:
        if not previous_league.empty:
            league_avg = (
                previous_league["home_score"].sum()
                + previous_league["away_score"].sum()
            ) / (2 * len(previous_league))
        else:
            historical = df_pre[
                df_pre["date"] < season_start
            ]
            if historical.empty:
                raise ValueError(
                    "No existe histórico anterior suficiente "
                    "para calcular el promedio previo."
                )
            league_avg = (
                historical["home_score"].sum()
                + historical["away_score"].sum()
            ) / (2 * len(historical))
        gf_previo = league_avg
        ga_previo = league_avg
    else:
        gf_previo = stats_previous["gf"]
        ga_previo = stats_previous["ga"]
```

La referencia se busca en este orden:

| Paso | Si… | Referencia (GF y GA previos) | Ejemplo real |
|---|---|---|---|
| 1 | el equipo jugó la temporada anterior en Premier | sus propios promedios de esa temporada | Liverpool, ago-2019: 89 GF y 22 GA en 38 partidos de 2018/19 → 2.3421 / 0.5789 |
| 2 | no la jugó (recién ascendido) pero hay datos de esa temporada | promedio de goles **por equipo y partido** de toda la liga en esa temporada, igual para GF y GA | Norwich, ago-2019: 1,072 goles en 380 partidos de 2018/19 → 1,072 / 760 = 1.4105 / 1.4105 |
| 3 | no hay ningún partido de la temporada anterior | promedio de todo el histórico antes del inicio de la temporada | no ocurre: las 26 temporadas son consecutivas |
| 4 | no hay nada antes | error `ValueError` | `season_stats(df, "Arsenal", "2001-09-01")` → `ValueError`: no hay temporada anterior a 2001/02 |

- `raise ValueError(...)` detiene el programa con un mensaje (en R, `stop("...")`). Las dos cadenas de texto
  seguidas se pegan solas en una (`"No existe … " "para calcular …"`).
- El paso 4 explica por qué no se pueden construir variables para 2001/02. El notebook sólo las construye desde
  agosto de 2019 (`FECHA_INICIO`), así que nunca ocurre.

**Bloque 6 — *shrinkage*** (líneas 524–563):

```python
    n = len(current)
    if n == 0:
        return {
            "gf_avg": gf_previo,
            "ga_avg": ga_previo
        }
    gf_actual = stats_current["gf"]
    ga_actual = stats_current["ga"]
    peso_actual = n / (n + k)
    peso_previo = k / (n + k)
    gf_ajustado = (
        peso_actual * gf_actual
        + peso_previo * gf_previo
    )
    ga_ajustado = (
        peso_actual * ga_actual
        + peso_previo * ga_previo
    )
    return {
        "gf_avg": float(gf_ajustado),
        "ga_avg": float(ga_ajustado)
    }
```

- **n = 0** (antes del primer partido de la temporada): devuelve la referencia previa. Este `return` temprano también
  evita dividir 0 / (0 + 0) cuando k = 0, que en Python daría `ZeroDivisionError`.
- **n ≥ 1:** $GF = \frac{n}{n+k}\,\overline{GF}_{\text{actual}} + \frac{k}{n+k}\,GF_{\text{previo}}$, y lo mismo
  para GA.
- **Con k = 0 (el valor vigente):** `peso_actual` = n / n = 1 y `peso_previo` = 0 → sólo el promedio de la temporada
  en curso, **sin mezcla**.

**Ejemplos reales** (calculados con la función; "8 GF" = goles a favor en esos partidos):

| Equipo y fecha | n | Referencia previa | k = 0 (vigente) | k = 5 | k = 10 (versión inicial) |
|---|---|---|---|---|---|
| Liverpool, 9-ago-2019 | 0 | 2.3421 / 0.5789 (su 2018/19) | 2.3421 / 0.5789 | igual | igual |
| Norwich, 9-ago-2019 (ascendido) | 0 | 1.4105 / 1.4105 (liga 2018/19) | 1.4105 / 1.4105 | igual | igual |
| Liverpool, 17-ago-2019 | 1 (ganó 4–1 a Norwich) | 2.3421 / 0.5789 | **4.0000 / 1.0000** | 2.6184 / 0.6491 | 2.4928 / 0.6172 |
| Arsenal, 15-sep-2026 | 4 (8 GF, 1 GA) | 1.8684 / 0.7105 (2025/26: 71 GF, 27 GA) | **2.0000 / 0.2500** | 1.9269 / 0.5058 | 1.9060 / 0.5789 |
| Man City, 15-sep-2026 | 4 (8 GF, 2 GA) | 2.0263 / 0.9211 (2025/26: 77 GF, 35 GA) | **2.0000 / 0.5000** | 2.0146 / 0.7339 | 2.0188 / 0.8008 |

A mano, Liverpool con k = 10: $\frac{1}{11}(4) + \frac{10}{11}(2.3421) = 0.3636 + 2.1292 = 2.4928$.

¿Qué tan seguido actúa la referencia? En la base de modelación (2,696 partidos = 5,392 pares equipo–partido), **152
pares (2.8 %)** tienen n = 0 y usan la referencia; **480 (8.9 %)** tienen entre 1 y 3 partidos, donde k cambia más
el resultado.

**En R** (ejecutado; da todos los valores de la tabla y el mismo error para 2001/02). Versión comentada en
[`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R):

```r
season_stats <- function(df, team, as_of_date, k = SHRINKAGE_K) {
  fecha <- as.Date(as_of_date)
  df_pre <- df |> filter(date < fecha)                          # sólo días anteriores (estricto)
  mes <- as.integer(format(fecha, "%m")); anio <- as.integer(format(fecha, "%Y"))
  season_year <- if (mes >= 8) anio else anio - 1               # la temporada empieza el 1 de agosto
  season_start <- as.Date(sprintf("%d-08-01", season_year))
  previous_start <- as.Date(sprintf("%d-08-01", season_year - 1))
  juega <- function(d) d$home_team == team | d$away_team == team
  current <- df_pre |> filter(date >= season_start); current <- current[juega(current), ]
  previous_league <- df_pre |> filter(date >= previous_start, date < season_start)
  previous <- previous_league[juega(previous_league), ]
  calculate_stats <- function(m) {                              # función interna
    if (nrow(m) == 0) return(NULL)
    local <- m$home_team == team
    c(gf = mean(ifelse(local, m$home_score, m$away_score)),
      ga = mean(ifelse(local, m$away_score, m$home_score)))
  }
  stats_current <- calculate_stats(current)
  stats_previous <- calculate_stats(previous)
  if (is.null(stats_previous)) {                                # referencia en cascada
    if (nrow(previous_league) > 0) {
      league_avg <- (sum(previous_league$home_score) + sum(previous_league$away_score)) / (2 * nrow(previous_league))
    } else {
      historical <- df_pre |> filter(date < season_start)
      if (nrow(historical) == 0) stop("No existe histórico anterior suficiente para calcular el promedio previo.")
      league_avg <- (sum(historical$home_score) + sum(historical$away_score)) / (2 * nrow(historical))
    }
    gf_previo <- league_avg; ga_previo <- league_avg
  } else {
    gf_previo <- stats_previous[["gf"]]; ga_previo <- stats_previous[["ga"]]
  }
  n <- nrow(current)
  if (n == 0) return(c(gf_avg = gf_previo, ga_avg = ga_previo))
  peso_actual <- n / (n + k); peso_previo <- k / (n + k)        # con k = 0: 1 y 0
  c(gf_avg = peso_actual * stats_current[["gf"]] + peso_previo * gf_previo,
    ga_avg = peso_actual * stats_current[["ga"]] + peso_previo * ga_previo)
}
season_stats(df, "Liverpool", "2019-08-17")           # 4 y 1
season_stats(df, "Liverpool", "2019-08-17", k = 10)   # 2.4928 y 0.6172
```

> **Decisión:** la temporada va del 1 de agosto al 31 de julio y se deduce de la fecha.
> **Alternativas:** (a) usar el archivo de origen de cada partido (cada CSV de Football-Data es una temporada) —
> exacto, pero la base consolidada no guarda una columna de temporada; (b) cortar en el primer partido de cada
> temporada — exacto, pero hay que calcularlo; (c) fecha fija (la elegida).
> **Por qué ésta:** es simple y en estos datos no se equivoca nunca.
> **Evidencia en el proyecto:** en las 26 temporadas, el primer partido es el 5 de agosto o después (el más temprano,
> 2022/23) y el último de una temporada completa es a más tardar el 26 de julio (2019/20, por la pandemia).
> **Si preguntan:** "La temporada empieza el 1 de agosto; revisamos que ninguna empiece antes ni termine después."

> **Decisión:** las variables de un partido sólo usan partidos de **días anteriores** (`date < fecha`, estricto).
> **Alternativas:** (a) `<=` — incluiría el propio partido: fuga de información, porque se usaría el resultado que se
> quiere predecir; (b) incluir los partidos anteriores del mismo día, por hora — el archivo consolidado no trae la
> hora; (c) estricto por día (lo elegido).
> **Por qué ésta:** es la forma más simple de garantizar que no se use nada del futuro; los partidos del mismo día no
> se informan entre sí.
> **Evidencia en el proyecto:** 1,840 de las 2,662 fechas del histórico tienen más de un partido, y ninguno usa a
> los otros del mismo día. El notebook además verifica en `crear_variables_partido` que `df_pre` no traiga la fecha
> del partido (lanza un error si la trae).
> **Si preguntan:** "Cada variable usa sólo partidos de días anteriores; ni siquiera los del mismo día."

> **Decisión:** promedio de la temporada mezclado con una referencia previa con peso n / (n + k); k se eligió por
> validación temporal (k = 0: sin mezcla en cuanto hay un partido), y la referencia sólo se usa antes del primer
> partido de la temporada.
> **Alternativas:** (a) promedio simple de la temporada (es lo que resulta con k = 0); (b) k fijo a mano (k = 10 en
> la versión inicial); (c) *shrinkage* bayesiano formal (modelo gamma-Poisson con k estimado de los datos); (d)
> promedio de los últimos partidos sin importar la temporada (eso ya lo hace `recent_form`); (e) para los ascendidos,
> el promedio histórico de los ascendidos en vez del de toda la liga. Se probaron (a) y (b) dentro de la rejilla
> (k = 0, 5, 10, 15 y 20); (c), (d) como sustituto y (e) no.
> **Por qué ésta:** con un solo parámetro la fórmula cubre desde "sin mezcla" hasta "mucha mezcla", y eso permitió
> calibrarla.
> **Evidencia en el proyecto:** con K = 15, LogLoss promedio de calibración 0.959558 (k = 0), 0.960369 (k = 5),
> 0.961220 (k = 10), 0.962085 (k = 15) y 0.962794 (k = 20). Detalle y posibles razones en el
> [capítulo 5](05_promedios_ajustados_y_forma.md).
> **Si preguntan:** "La función permite mezclar la temporada con la anterior, pero la calibración dijo que no
> convenía: con k = 0 se usa el promedio de la temporada en curso, y la anterior sólo antes del primer partido."

## 10.12 Resumen en R y verificación

Todo el módulo tiene equivalente en R, y se comprobó que da las mismas cifras:

| Python (`wc_predictor.py`) | R | Verificación |
|---|---|---|
| Constantes, `load_history()`, `calcular_parametros_liga()`, bloque al importar | fragmentos de este capítulo (10.3–10.6) | 9,540 partidos; 1.3623 / 1.1266 / 0.8734 |
| `expected_score()`, `update_elo()`, `build_elo()` | este capítulo y [`equivalencias_R/01_elo.R`](equivalencias_R/01_elo.R) | mismos ratings finales a 2 decimales (Arsenal 1,787.12; Man City 1,779.19) |
| `season_stats()`, `recent_form()` | este capítulo y [`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R) | mismas variables que `premier_training_data.csv` |
| Uso de K y k en la calibración (notebook §5) | [`equivalencias_R/06_calibracion.R`](equivalencias_R/06_calibracion.R) | las 35 combinaciones de la rejilla coinciden con Python a 6 decimales |

| Idea de Python | Equivalente en R |
|---|---|
| módulo + `import wc_predictor` | script de funciones + `source("wc_predictor.R")` (o un paquete) |
| diccionario `{equipo: rating}` y `ratings.get(h, 1500)` | vector con nombres y `if (h %in% names(ratings)) ratings[[h]] else 1500` |
| `df[(df["home_team"] == team) \| (df["away_team"] == team)]` | `filter(df, home_team == team \| away_team == team)` |
| `np.where(cond, x, y)` | `ifelse(cond, x, y)` |
| `np.average(x, weights=w)` | `weighted.mean(x, w)` |
| `None` / `np.nan` | `NULL` / `NA` |
| `raise ValueError("...")` | `stop("...")` |
| valores por defecto que se fijan al definir la función | valores por defecto que se evalúan al llamarla |

## 10.13 Preguntas rápidas

<details><summary>¿Qué partes del archivo no usa el análisis?</summary>

`calcular_parametros_liga()` y lo que calcula (`HOME_FACTOR`, `AWAY_FACTOR`, `parametros`), y el `df` que se lee al
importar. De ese bloque sólo se usa `avg_team_goals`, como respaldo de `recent_form()`. Las funciones heurísticas de
la versión inicial (`get_lambda()`, `simular_partido()`) y los restos del Mundial ya no están en el archivo
entregado.
</details>

<details><summary>¿Dónde se eligió K = 15? ¿En este archivo?</summary>

No: se eligió en la §5 del notebook (validación temporal con 35 combinaciones de K y k). Este archivo sólo guarda el
resultado como valor por defecto (`ELO_K = 15`, `SHRINKAGE_K = 0`), para que el notebook y el tablero usen lo
mismo. Detalle en los capítulos [4](04_elo.md) y [5](05_promedios_ajustados_y_forma.md).
</details>

<details><summary>¿Por qué el notebook no usa build_elo() para construir la base?</summary>

Porque `build_elo()` devuelve sólo los ratings finales, y para entrenar se necesita el rating de cada equipo
**justo antes de cada partido**. El notebook recorre los partidos día por día: guarda las variables del día con los
ratings de antes y luego actualiza con `update_elo()`. `build_elo()` se usa para la predicción individual (§10) y
para el simulador del tablero.
</details>

<details><summary>¿Qué pasa si importo el módulo desde otra carpeta?</summary>

Falla con `FileNotFoundError`, porque al importarse lee `E0_consolidado.csv` con ruta relativa. Por eso el tablero
lo importa cambiando temporalmente de carpeta. La versión entregada ya no imprime nada al importarse.
</details>

<details><summary>¿Estas funciones pueden usar información del futuro?</summary>

`season_stats()` no: filtra ella misma con `date < fecha`. `recent_form()` usa todo lo que recibe, así que depende de
quien la llama; el notebook le pasa sólo partidos de días anteriores y lo verifica (lanza un error si no). El único
dato calculado con todo el histórico es `avg_team_goals`, y sólo aparece en 4 partidos que se excluyen.
</details>

<details><summary>¿Por qué se excluyen 4 partidos de la base?</summary>

Son el primer partido de equipos que no tenían ningún partido previo en la base (Brentford 2021, Nott'm Forest 2022,
Luton 2023 y Coventry 2026). `recent_form()` les devuelve tiros vacíos, y el notebook quita esas filas para que las
cinco especificaciones (M0–M4) usen exactamente los mismos partidos: 2,700 → 2,696.
</details>

<details><summary>¿Cambiar la escala de 400 cambiaría los resultados?</summary>

No, si K se cambia en la misma proporción: con escala 800 y K = 30 todos los ratings (medidos desde 1,500) salen al
doble, y como la regresión divide la diferencia entre la misma escala, el modelo recibe la misma variable. Por eso el
parámetro que importa es K.
</details>
