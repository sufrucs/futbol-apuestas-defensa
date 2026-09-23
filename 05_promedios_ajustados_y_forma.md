# 5. Promedios ajustados (*shrinkage*) y forma reciente

[← Elo](04_elo.md) · [Índice](README.md) · [Siguiente: Poisson →](06_poisson_y_regresion.md)

El Elo resume la fuerza **general** de un equipo. Pero para pronosticar **goles** conviene saber
también qué tanto anota y qué tanto recibe. Para eso el proyecto construye dos tipos de promedios,
siempre con partidos **anteriores** a la fecha del encuentro:

| Variable | Ventana | Qué captura | Parámetro |
|---|---|---|---|
| Goles a favor / en contra **ajustados** (`gf_*`, `ga_*`) | Temporada actual + anterior | Nivel de ataque y defensa de la temporada | k = 10 |
| **Forma reciente** (`form_*`, `shots_*`, `sot_*`) | Últimos 10 partidos | Racha: cómo viene jugando el equipo | decaimiento 0.85 |

## 5.1 Promedios ajustados: el problema que resuelven

Imagina la jornada 2: un equipo que anotó 6 goles en sus 2 primeros partidos tiene un promedio de
**3 goles por partido**. Nadie cree que vaya a mantener eso toda la temporada: con tan pocos
partidos, el promedio es muy **ruidoso**. Y en la jornada 1 ni siquiera existe promedio.

**Solución (shrinkage o "contracción"):** mezclar el promedio de la temporada actual con el de la
temporada anterior, dándole más peso al actual conforme se juegan más partidos:

$$
GF^{\text{ajustado}} = \frac{n}{n+k}\,\overline{GF}_{\text{actual}} + \frac{k}{n+k}\,\overline{GF}_{\text{anterior}}
$$

donde $n$ es el número de partidos jugados en la temporada actual antes de la fecha y $k = 10$.
Lo mismo para los goles en contra (GA).

**Interpretación de k:** es como si la temporada anterior "valiera" 10 partidos de información.

| Partidos jugados (n) | Peso de la temporada actual | Peso de la anterior |
|---|---|---|
| 0 | 0 % | 100 % |
| 2 | 17 % | 83 % |
| 5 | 33 % | 67 % |
| 10 | **50 %** | 50 % |
| 19 (media temporada) | 66 % | 34 % |
| 38 (temporada completa) | 79 % | 21 % |

**Ejemplo:** el equipo de los 6 goles en 2 partidos, con 1.2 goles por partido la temporada
anterior: $\frac{2}{12}(3) + \frac{10}{12}(1.2) = 0.5 + 1.0 = 1.5$. Un valor mucho más creíble
que 3.

**¿De dónde viene la idea?** Es un "promedio bayesiano" (o de credibilidad): cuando hay pocos
datos, se confía más en la información previa; cuando hay muchos, en los datos nuevos. El valor
k = 10 **no se optimizó** (limitación reconocida en el reporte técnico).

### Casos especiales (tal como están en el código)

- **Aún no se juega ningún partido de la temporada** (n = 0): se usa el promedio de la temporada
  anterior.
- **El equipo no jugó la temporada anterior en Premier** (recién ascendido): se usa el **promedio
  de goles de toda la liga** en la temporada anterior. Ejemplo real: Norwich en agosto de 2019
  recibe 1.4105, el promedio de 2018/19, tanto en goles a favor como en contra.
- **La temporada va del 1 de agosto al 31 de julio.** La temporada 2019/20, alargada hasta julio
  de 2020 por la pandemia, sigue quedando dentro.

**Ejemplo real verificado:** Liverpool en su primer partido de 2019/20 (9-ago-2019) todavía no
juega partidos de esa temporada, así que recibe su promedio de 2018/19: 89 goles a favor y 22 en
contra en 38 partidos, es decir 2.3421 y 0.5789. Son exactamente los valores de la caché
`premier_training_data.csv`.

> **Limitación:** darle a un recién ascendido el promedio de la liga lo **sobreestima**, porque
> los ascendidos suelen anotar menos y recibir más que el promedio.

## 5.2 Forma reciente: promedio ponderado de los últimos 10 partidos

Se toman los **últimos 10 partidos** del equipo (de local y de visitante, de cualquier temporada)
y se calcula un promedio donde **los partidos recientes pesan más**:

$$
\tilde w_i = d^{\,m-i}, \qquad w_i = \frac{\tilde w_i}{\sum_j \tilde w_j}, \qquad \overline{x} = \sum_{i=1}^{m} w_i\,x_i
$$

con $d = 0.85$, $m \le 10$ partidos ordenados del más antiguo ($i = 1$) al más reciente
($i = m$). El más reciente tiene $\tilde w = 0.85^0 = 1$, el anterior $0.85$, luego
$0.85^2 = 0.72$, etc. Al dividir entre la suma, los pesos suman 1.

| Posición (1 = el más reciente) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Peso | 18.7 % | 15.9 % | 13.5 % | 11.5 % | 9.8 % | 8.3 % | 7.0 % | 6.0 % | 5.1 % | 4.3 % |

Los **3 últimos partidos suman ≈ 48 %** del promedio.

Se aplica a seis variables: goles a favor y en contra, tiros realizados y concedidos, y tiros a
puerta realizados y concedidos.

**¿Por qué tiros?** Los goles son pocos y muy aleatorios. Los tiros son muchos más, así que
indican la calidad ofensiva con menos ruido: un equipo que tira mucho pero no anota tiende a anotar
más en el futuro. Es la idea detrás de las métricas de "goles esperados" (xG).

> **Limitación importante (ejemplo real):** la forma de Norwich para su primer partido de 2019/20
> se calculó con partidos de **marzo a mayo de 2016**, su última etapa en Premier. Para un equipo
> recién ascendido, "forma reciente" puede significar datos de hace años.

## 5.3 El código en Python (`wc_predictor.py`)

### `season_stats()`: promedios ajustados

```python
def season_stats(df, team, as_of_date, k=10):
    fecha = pd.to_datetime(as_of_date)
    df_pre = df[df["date"] < fecha].copy()                 # 1) sólo el pasado

    season_year = fecha.year if fecha.month >= 8 else fecha.year - 1
    season_start = pd.Timestamp(year=season_year, month=8, day=1)
    previous_start = pd.Timestamp(year=season_year - 1, month=8, day=1)

    current = df_pre[df_pre["date"] >= season_start]                    # 2) temporada actual
    current = current[(current["home_team"] == team) | (current["away_team"] == team)]
    previous_league = df_pre[(df_pre["date"] >= previous_start) & (df_pre["date"] < season_start)]
    previous = previous_league[(previous_league["home_team"] == team) |
                               (previous_league["away_team"] == team)]  # 3) temporada anterior

    def calculate_stats(matches):
        if matches.empty:
            return None
        gf = np.where(matches["home_team"] == team, matches["home_score"], matches["away_score"])
        ga = np.where(matches["home_team"] == team, matches["away_score"], matches["home_score"])
        return {"gf": float(np.mean(gf)), "ga": float(np.mean(ga))}
    # ... 4) si no hay temporada anterior: promedio de la liga; 5) n == 0: sólo el previo
    peso_actual = n / (n + k)
    peso_previo = k / (n + k)
    gf_ajustado = peso_actual * gf_actual + peso_previo * gf_previo
```

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `df[df["date"] < fecha]` | Filtra los partidos anteriores a la fecha | `filter(historico, Date < fecha)` |
| `fecha.month >= 8` | Decide a qué temporada pertenece la fecha | `as.integer(format(fecha, "%m")) >= 8` |
| `(a == team) \| (b == team)` | Partidos donde juega el equipo, de local o visitante | `HomeTeam == equipo \| AwayTeam == equipo` |
| `np.where(cond, x, y)` | Toma `x` si es local y `y` si es visitante | `ifelse(cond, x, y)` |
| `np.mean(gf)` | Promedio | `mean(gf)` |

### `recent_form()`: forma reciente

```python
def recent_form(df, team, n=10, decay=0.85):
    tmp = df[(df["home_team"] == team) | (df["away_team"] == team)].sort_values("date").tail(n)
    if tmp.empty:
        return {"gf": avg_team_goals, "ga": avg_team_goals, "shots_for": np.nan, ...}
    gf, ga, shots_for, shots_against, sot_for, sot_against = [], [], [], [], [], []
    for _, row in tmp.iterrows():
        if row["home_team"] == team:          # visto desde el equipo cuando juega de local
            gf.append(row["home_score"]); ga.append(row["away_score"])
            shots_for.append(row["HS"]);  shots_against.append(row["AS"])
            sot_for.append(row["HST"]);   sot_against.append(row["AST"])
        else:                                  # ... y cuando juega de visitante
            gf.append(row["away_score"]); ga.append(row["home_score"])
            shots_for.append(row["AS"]);  shots_against.append(row["HS"])
            sot_for.append(row["AST"]);   sot_against.append(row["HST"])
    w = np.array([decay ** (len(gf) - 1 - i) for i in range(len(gf))])   # pesos geométricos
    w = w / w.sum()                                                       # normalizados
    return {"gf": float(np.average(gf, weights=w)), ...}
```

- `.tail(n)` toma las últimas n filas ya ordenadas por fecha (en R, `tail(df, n)`).
- La comprensión `[decay ** (len(gf) - 1 - i) for i in range(len(gf))]` genera
  0.85⁹, 0.85⁸, …, 0.85⁰ (en R, `0.85^((m - 1):0)`).
- `np.average(x, weights=w)` es el promedio ponderado (en R, `sum(w * x)` con pesos normalizados,
  o `weighted.mean(x, w)`).
- **Importante:** la función no filtra por fecha. Quien la llama debe pasarle **solo partidos
  anteriores**, y así lo hace el notebook: `crear_variables_partido` exige `df_pre` con fechas
  menores a la del partido y lanza un error si no.
- Si el equipo no tiene partidos previos, los tiros quedan vacíos (`NaN`). Por eso se excluyeron
  4 partidos de la base.

## 5.4 El mismo código en R

Script completo y verificado contra la caché: [`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R).

```r
forma_reciente <- function(historico, equipo, fecha, n = 10, decaimiento = 0.85) {
  ultimos <- historico |>
    filter(Date < fecha, HomeTeam == equipo | AwayTeam == equipo) |>
    arrange(Date) |> tail(n)
  m <- nrow(ultimos)
  pesos <- decaimiento^((m - 1):0)       # el más reciente pesa 1
  pesos <- pesos / sum(pesos)            # suman 1
  gf <- ifelse(ultimos$HomeTeam == equipo, ultimos$FTHG, ultimos$FTAG)
  sum(pesos * gf)                        # ≈ np.average(gf, weights = pesos)
}
```

En R también existen herramientas para promedios móviles ponderados (`slider::slide_dbl()`,
`zoo::rollapply()`); aquí se escribió explícito para que sea idéntico a Python.

## 5.5 Preguntas rápidas

<details><summary>¿Por qué no usar simplemente el promedio de toda la historia del equipo?</summary>

Porque los equipos cambian mucho de un año a otro (fichajes, entrenadores). El promedio de la
temporada, contraído hacia la anterior, equilibra lo reciente con lo estable.
</details>

<details><summary>¿Por qué 10 partidos y 0.85?</summary>

Son valores operativos razonables: 10 partidos son un cuarto de temporada, y 0.85 hace que los
3 últimos pesen casi la mitad. No se optimizaron; hacerlo con validación temporal es una extensión.
</details>

<details><summary>¿La forma reciente mezcla temporadas?</summary>

Sí: son los últimos 10 partidos de Premier sin importar la temporada. Para los recién ascendidos
eso puede significar partidos de hace años (Norwich en 2019 usó datos de 2016).
</details>
