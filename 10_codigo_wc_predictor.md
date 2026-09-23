# 10. Código: `wc_predictor.py`, función por función

[← Evaluación](09_evaluacion_y_validacion.md) · [Índice](README.md) · [Siguiente: el notebook de análisis →](11_codigo_analisis_notebook.md)

`wc_predictor.py` es un **módulo** de Python: un archivo con funciones que el notebook importa
(`import wc_predictor`) para no repetir código. Su nombre viene de "World Cup predictor": se
adaptó de un predictor del Mundial, y por eso conserva piezas que el análisis final **no usa**.

## 10.1 Mapa del archivo: qué se usa y qué no

| Parte | ¿La usa el análisis final? | Para qué |
|---|---|---|
| `ELO_INIT`, `ELO_K` | **Sí** | 1,500 y 30 |
| `load_history()` | **Sí** | Lee `E0_consolidado.csv` y prepara las columnas |
| `expected_score()`, `update_elo()`, `build_elo()` | **Sí** | Elo ([cap. 4](04_elo.md)) |
| `recent_form()` | **Sí** | Forma reciente ([cap. 5](05_promedios_ajustados_y_forma.md)) |
| `season_stats()` | **Sí** | Promedios ajustados ([cap. 5](05_promedios_ajustados_y_forma.md)) |
| `N_SIMS`, `AVG_WC_GOALS`, `HIST_URL`, `NAME_MAP`, `INJURY_FACTOR` | No | Restos del predictor del Mundial (resultados de selecciones, nombres de países) |
| `calcular_parametros_liga()`, `HOME_FACTOR`, `AWAY_FACTOR` | No en el modelo final | Factores de localía para la versión heurística |
| `get_lambda()` | **No** | Versión heurística: goles esperados como mezcla 50 % / 35 % / 15 % |
| `simular_partido()` | **No** | Simulación de 30,000 partidos con penales (eliminatorias) |
| Bloque final (`from wc_predictor import ...` y `print`) | Se ejecuta al importar | Imprime el ranking Elo |

> **Para la exposición:** el modelo final es el **GLM de Poisson del notebook**
> (`statsmodels`), **no** `get_lambda()`. Si alguien pregunta por `simular_partido()`, la respuesta
> es: "es una versión anterior que no forma parte del análisis final".

## 10.2 Constantes y carga del histórico

```python
import numpy as np
import pandas as pd

N_SIMS       = 30_000
AVG_WC_GOALS = 1.3619        # promedio histórico de goles por equipo en Mundiales (no se usa)
ELO_INIT     = 1500
ELO_K        = 30

def load_history(path="E0_consolidado.csv"):
    df = pd.read_csv(path)
    df = df.rename(columns={"Date": "date", "HomeTeam": "home_team", "AwayTeam": "away_team",
                            "FTHG": "home_score", "FTAG": "away_score"})
    df["date"] = pd.to_datetime(df["date"], dayfirst=True, format="mixed")
    df = df.dropna(subset=["date", "home_team", "away_team", "home_score", "away_score"])
    return df.sort_values("date").reset_index(drop=True)
```

| Código | Qué hace | En R |
|---|---|---|
| `30_000` | El guion bajo solo separa miles (es 30000) | `30000` |
| `pd.read_csv(path)` | Lee el CSV | `read_csv(path)` |
| `.rename(columns={...})` | Cambia nombres de columnas (a los nombres "genéricos" del predictor del Mundial) | `rename(date = Date, home_team = HomeTeam, ...)` |
| `pd.to_datetime(..., dayfirst=True, format="mixed")` | Convierte a fecha | `as.Date()` (el CSV ya viene en ISO) |
| `.dropna(subset=[...])` | Quita filas sin fecha, equipos o goles | `drop_na(date, home_team, ...)` |
| `.sort_values("date").reset_index(drop=True)` | Ordena por fecha y renumera las filas | `arrange(date)` |

Se verificó que leer con `dayfirst=True` las fechas ISO no invierte día y mes (0 de 9,450).

## 10.3 El efecto secundario al importar (importante)

```python
df = load_history()                       # se ejecuta al importar el módulo
parametros = calcular_parametros_liga(df)
avg_team_goals = parametros["avg_team_goals"]
HOME_FACTOR = parametros["home_factor"]
AWAY_FACTOR = parametros["away_factor"]
...
from wc_predictor import load_history, build_elo      # (al final del archivo)
df = load_history()
elo = build_elo(df)
for equipo, rating in sorted(elo.items(), key=lambda x: x[1], reverse=True):
    print(f"{equipo:25s} {rating:.2f}")
```

- Todo lo que está **fuera de una función** se ejecuta en cuanto alguien hace `import wc_predictor`.
  Por eso el notebook, al importar, **imprime el ranking Elo** (la lista que aparece bajo la primera
  celda) y exige que `E0_consolidado.csv` esté en la carpeta actual (ruta relativa).
- `avg_team_goals` se calcula con **todo** el histórico, incluidos partidos futuros respecto a
  cualquier fecha. **No provoca fuga de información en el modelo final**: solo se usa como valor de
  respaldo en `recent_form()` para equipos sin partidos previos, y esas filas se excluyen porque
  sus tiros quedan vacíos.
- En R, lo equivalente sería un script que al hacer `source()` también ejecuta código suelto. La
  buena práctica en ambos lenguajes es dejar solo definiciones en el módulo. En Python se protege
  el código de ejemplo con `if __name__ == "__main__":`.
- El tablero lo importa **silenciando** esa impresión y cambiando temporalmente de carpeta
  (`datos_dashboard._importar_wc_predictor()`).

## 10.4 `calcular_parametros_liga()` (solo para la versión heurística)

```python
def calcular_parametros_liga(df):
    avg_home_goals = df["home_score"].mean()                 # ≈ 1.53
    avg_away_goals = df["away_score"].mean()                 # ≈ 1.19
    avg_team_goals = (avg_home_goals + avg_away_goals) / 2   # ≈ 1.36
    home_factor = avg_home_goals / avg_team_goals            # ≈ 1.13: el local anota 13 % más que el promedio
    away_factor = avg_away_goals / avg_team_goals            # ≈ 0.87
    return {"avg_team_goals": avg_team_goals, "home_factor": home_factor, "away_factor": away_factor}
```

Resume la localía en dos factores multiplicativos. En el modelo final, la localía la estiman las
regresiones, así que estos factores no se usan.

## 10.5 Elo: `expected_score()`, `update_elo()`, `build_elo()`

Explicadas a detalle en el [capítulo 4](04_elo.md). En resumen:
`expected_score` = $1/(1+10^{(R_B-R_A)/400})$; `update_elo` = rating + K × (resultado − esperado);
`build_elo` recorre los partidos en orden y actualiza a ambos equipos con los ratings previos.

## 10.6 `recent_form()` y `season_stats()`

Explicadas línea por línea en el [capítulo 5](05_promedios_ajustados_y_forma.md), con su versión
en R verificada contra la caché.

## 10.7 `get_lambda()`: la versión heurística que NO se usa

```python
def get_lambda(attacker_stats, defender_stats, attacker_form, defender_form,
               elo_att, elo_def, home_factor=1.0, injury_factor=1.0, avg_goals=avg_team_goals):
    gf_api = attacker_stats.get('gf_avg', avg_goals)
    ga_api = defender_stats.get('ga_avg', avg_goals)
    lam_api = (gf_api / avg_goals) * (ga_api / avg_goals) * avg_goals     # ataque × defensa rival
    lam_hist = (attacker_form['gf'] / avg_goals) * (defender_form['ga'] / avg_goals) * avg_goals
    elo_ratio = 10 ** ((elo_att - elo_def) / 800)
    lam_elo = avg_goals * elo_ratio
    lam = 0.50 * lam_api + 0.35 * lam_hist + 0.15 * lam_elo               # pesos fijados a mano
    lam *= home_factor
    lam *= injury_factor
    return round(max(lam, 0.2), 3)
```

Combina tres estimaciones de goles con **pesos elegidos a mano** (50 %, 35 %, 15 %). Es la
diferencia clave con el modelo final: **en la regresión de Poisson los pesos (coeficientes) se
estiman con los datos** por máxima verosimilitud, no se eligen a ojo. Por eso el análisis final
reemplazó esta función por el GLM.

## 10.8 `simular_partido()`: simulación Monte Carlo que NO se usa

```python
gh = np.random.poisson(lam_h, n_sims)      # 30,000 marcadores simulados del local
ga = np.random.poisson(lam_a, n_sims)      # ... y del visitante
p_h = np.mean(gh > ga); p_d = np.mean(gh == ga); p_a = np.mean(gh < ga)
over25 = np.mean(gh + ga > 2.5)            # más de 2.5 goles
btts = np.mean((gh > 0) & (ga > 0))        # ambos anotan
# ... prórroga y penales para eliminatorias (propio del Mundial)
```

- Estima probabilidades **contando** en qué fracción de 30,000 partidos simulados gana cada uno.
  Da casi lo mismo que la fórmula exacta de Skellam que usa el notebook, pero con un error de
  simulación de ±0.3 puntos porcentuales.
- La parte de penales no aplica a una liga.
- En R: `rpois(30000, lambda)` ≈ `np.random.poisson(lambda, 30000)`; `mean(gh > ga)` igual.

## 10.9 Resumen del módulo en R

Todas las piezas que sí se usan están reproducidas en R y verificadas:

| Python (`wc_predictor.py`) | R (`equivalencias_R/`) | Verificación |
|---|---|---|
| `build_elo()` | `01_elo.R` | Mismos ratings finales |
| `season_stats()` | `05_variables_previas.R` → `promedios_ajustados()` | Mismos valores que la caché |
| `recent_form()` | `05_variables_previas.R` → `forma_reciente()` | Mismos valores que la caché |
