# 5. Promedios ajustados (*shrinkage*) y forma reciente

[← Elo](04_elo.md) · [Índice](README.md) · [Siguiente: Poisson →](06_poisson_y_regresion.md)

> **Versión vigente:** el parámetro del *shrinkage* es **k = 0**, calibrado por validación temporal (la primera
> versión usaba k = 10 fijo). La idea del *shrinkage* sigue en el código y se explica completa porque **se calibró**:
> k = 0 fue el valor que ganó. Todas las cifras se calcularon con el código entregado; el código línea por línea está en
> el [capítulo 10](10_codigo_wc_predictor.md#1011-season_stats).

El Elo resume la fuerza **general** de un equipo. Pero para pronosticar **goles** conviene saber también qué tanto
anota y qué tanto recibe. Para eso el proyecto construye dos tipos de promedios, siempre con partidos de **días
anteriores** a la fecha del encuentro:

| Variable | Ventana | Qué captura | Parámetro | Modelos |
|---|---|---|---|---|
| Goles a favor / en contra de la temporada (`gf_*`, `ga_*`) | Temporada en curso; la anterior sólo antes del primer partido | Nivel de ataque y defensa en la temporada | k = 0 (calibrado; antes 10) | M0–M4 |
| **Forma reciente** (`form_*`, `shots_*`, `sot_*`) | Últimos 10 partidos, de cualquier temporada | Racha: cómo viene jugando el equipo | decaimiento 0.85 (no calibrado) | M1–M4 |

## 5.1 Promedios de la temporada: el problema que resuelve el *shrinkage*

Imagina la jornada 2: un equipo que anotó 6 goles en sus 2 primeros partidos tiene un promedio de **3 goles por
partido**. Nadie cree que vaya a mantener eso toda la temporada: con tan pocos partidos, el promedio es muy
**ruidoso**. Y en la jornada 1 ni siquiera existe promedio.

**Solución (shrinkage o "contracción"):** mezclar el promedio de la temporada actual con una referencia previa (el
promedio del equipo en la temporada anterior), dándole más peso al actual conforme se juegan más partidos:

$$
GF^{\text{ajustado}} = \frac{n}{n+k}\,\overline{GF}_{\text{actual}} + \frac{k}{n+k}\,GF_{\text{previo}}
$$

donde $n$ es el número de partidos jugados en la temporada actual antes de la fecha y $k$ es el parámetro. Lo mismo
para los goles en contra (GA).

**Interpretación de k:** es como si la referencia previa "valiera" k partidos de información. Peso de la temporada
actual según k:

| Partidos jugados (n) | k = 10 (versión inicial) | k = 5 | **k = 0 (vigente)** |
|---|---|---|---|
| 0 | 0 % (sólo la referencia) | 0 % | 0 % (sólo la referencia) |
| 1 | 9 % | 17 % | **100 %** |
| 2 | 17 % | 29 % | **100 %** |
| 5 | 33 % | 50 % | **100 %** |
| 10 | 50 % | 67 % | **100 %** |
| 19 (media temporada) | 66 % | 79 % | **100 %** |
| 38 (temporada completa) | 79 % | 88 % | **100 %** |

**Ejemplo inventado:** el equipo de los 6 goles en 2 partidos, con 1.2 goles por partido la temporada anterior.

- Con k = 10: $\frac{2}{12}(3) + \frac{10}{12}(1.2) = 0.5 + 1.0 = 1.5$. Un valor mucho más creíble que 3.
- Con k = 0: $\frac{2}{2}(3) + 0 \cdot 1.2 = 3$. Se usa el promedio de la temporada tal cual.

**¿De dónde viene la idea?** Es un "promedio bayesiano" (o de credibilidad): cuando hay pocos datos, se confía más en
la información previa; cuando hay muchos, en los datos nuevos. De hecho, la fórmula es **exactamente** la media
posterior de un modelo gamma-Poisson: si los goles por partido son Poisson con tasa λ y antes de ver la temporada se
cree que λ sigue una distribución gamma con media $GF_{\text{previo}}$ y "peso" de k partidos (forma
$k \cdot GF_{\text{previo}}$, tasa $k$), después de ver n partidos la media de λ es la fórmula de arriba. **k = 0
equivale a no tener información previa**: la media posterior es el promedio observado.

### Qué significa k = 0 en el código

`season_stats()` (ver [capítulo 10](10_codigo_wc_predictor.md#1011-season_stats)) hace dos cosas, en este orden:

1. **Si n = 0** (antes del primer partido de la temporada), devuelve la **referencia previa** y termina. Por eso no
   llega a dividir 0 / (0 + 0).
2. **Si n ≥ 1**, aplica la fórmula. Con k = 0, el peso de la temporada actual es n / n = 1 y el de la referencia es
   0: **sólo el promedio de la temporada en curso, sin mezcla**.

Así, k = 0 **no** deja sin información al inicio de temporada: en el primer partido de cada equipo se usa la
referencia previa; desde el segundo, sólo la temporada en curso. La propia §5 del notebook lo aclara.

### Ejemplos reales con k = 0 y con k = 10

Calculados con `season_stats()`, en goles a favor / en contra por partido:

| Equipo y fecha | n | Referencia previa | **k = 0 (vigente)** | k = 10 (versión inicial) |
|---|---|---|---|---|
| Liverpool, 9-ago-2019 (primer partido) | 0 | 2.3421 / 0.5789 (su 2018/19) | 2.3421 / 0.5789 | 2.3421 / 0.5789 (igual) |
| Norwich, 9-ago-2019 (ascendido) | 0 | 1.4105 / 1.4105 (liga 2018/19) | 1.4105 / 1.4105 | igual |
| Liverpool, 17-ago-2019 (ya ganó 4–1 a Norwich) | 1 | 2.3421 / 0.5789 | **4.0000 / 1.0000** | 2.4928 / 0.6172 |
| Arsenal, 15-sep-2026 (8 GF y 1 GA en 4 partidos) | 4 | 1.8684 / 0.7105 (2025/26) | **2.0000 / 0.2500** | 1.9060 / 0.5789 |
| Man City, 15-sep-2026 (8 GF y 2 GA en 4 partidos) | 4 | 2.0263 / 0.9211 (2025/26) | **2.0000 / 0.5000** | 2.0188 / 0.8008 |

- **En el primer partido de cada temporada, k no influye** (n = 0): las variables de Liverpool–Norwich, el primer
  partido de la base de modelación, son idénticas con k = 0 y con k = 10.
- **Desde el segundo partido sí.** A mano, Liverpool con k = 10: $\frac{1}{11}(4) + \frac{10}{11}(2.3421) = 0.3636 + 2.1292 = 2.4928$.
  Con k = 0 queda el 4–1 tal cual: 4 y 1.
- **Consecuencia visible:** al inicio de la temporada los promedios varían mucho. Arsenal llega al partido contra
  Man City del simulador con 0.25 goles recibidos por partido (1 en 4 partidos); con k = 10 habría tenido 0.58. En
  toda la base de modelación, `gf_home` va de 0 a 5.
- **¿Qué tan seguido pasa?** De los 5,392 pares equipo–partido de la base (2,696 partidos × 2 equipos), **152
  (2.8 %)** tienen n = 0 y usan la referencia, y **480 (8.9 %)** tienen entre 1 y 3 partidos, donde k cambia más el
  resultado. En el resto de la temporada, con k = 10 la temporada anterior seguía pesando: 34 % a media temporada y
  21 % al final.

El ejemplo de Liverpool está verificado también en R: [`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R)
reproduce los valores de la caché `premier_training_data.csv` y muestra el cambio de k = 10 a k = 0.

### Casos especiales (tal como están en el código)

La referencia previa se busca en cascada:

1. **El equipo jugó la temporada anterior en Premier:** sus propios promedios de esa temporada. Liverpool en agosto
   de 2019: 89 goles a favor y 22 en contra en 38 partidos de 2018/19 → 2.3421 y 0.5789. Son exactamente los valores
   de la caché `premier_training_data.csv`.
2. **No la jugó (recién ascendido):** el **promedio de goles por equipo y partido de toda la liga** en la temporada
   anterior, igual para goles a favor y en contra. Norwich en agosto de 2019: 1,072 goles en los 380 partidos de
   2018/19 → 1,072 / 760 = **1.4105**.
3. **No hay ningún partido de la temporada anterior:** promedio de todo el histórico anterior (no ocurre: las
   temporadas son consecutivas).
4. **No hay nada antes:** error. Pasa con cualquier fecha de 2001/02, la primera temporada de la base; por eso las
   variables se construyen desde 2019 y no desde 2001.

Además:

- **La temporada va del 1 de agosto al 31 de julio.** La temporada 2019/20, alargada hasta el 26 de julio de 2020 por
  la pandemia, sigue quedando dentro; ninguna temporada empieza antes del 5 de agosto.
- **Sólo días anteriores:** el filtro es estricto (`date < fecha`), así que los partidos del mismo día no se
  informan entre sí.

> **Limitación:** darle a un recién ascendido el promedio de la liga lo **sobreestima**, porque los ascendidos suelen
> anotar menos y recibir más que el promedio. Con los datos: los 21 ascendidos de 2019/20 a 2025/26 anotaron
> **1.02** goles por partido y recibieron **1.84** en su temporada, pero recibieron como referencia el promedio de la
> liga, **1.44** en ambos. Con k = 0 esto sólo afecta su primer partido de la temporada; con k = 10 afectaba varias
> jornadas.

### Cómo se eligió k = 0

En la §5 del notebook se calibraron K (Elo) y k a la vez, con validación temporal de ventana creciente: para cada una
de las 35 combinaciones se reconstruyó la base, se entrenó M0 con todo lo anterior a cada temporada y se midió el
LogLoss 1X2 en 2021/22, 2022/23 y 2023/24 (1,140 partidos). Detalle del procedimiento y de K en el
[capítulo 4](04_elo.md#43-por-qué-400-y-por-qué-k--15).

LogLoss de la rejilla por k, con K = 15 (el K elegido):

| k | LogLoss promedio | 2021/22 | 2022/23 | 2023/24 |
|---|---|---|---|---|
| **0** | **0.959558** | **0.960230** | 0.989315 | **0.929130** |
| 5 | 0.960369 | 0.961828 | **0.988725** | 0.930553 |
| 10 | 0.961220 | 0.962173 | 0.989611 | 0.931877 |
| 15 | 0.962085 | 0.962653 | 0.990618 | 0.932985 |
| 20 | 0.962794 | 0.963103 | 0.991503 | 0.933776 |

Lo que dice la evidencia:

- **Con K = 15, el LogLoss empeora conforme crece k**: 0 < 5 < 10 < 15 < 20.
- **Pasa con casi cualquier K:** k = 0 es el mejor k para 6 de los 7 valores de K probados. La excepción es K = 45 (el
  Elo más reactivo), donde gana k = 5 (0.964021 contra 0.964290 de k = 0).
- **No gana en todas las temporadas:** en 2022/23, k = 5 fue un poco mejor que k = 0.
- **Las diferencias son pequeñas:** de k = 0 a k = 10 hay 0.0017 de LogLoss promedio.
- La rejilla completa se reprodujo en R con las mismas cifras: [`equivalencias_R/06_calibracion.R`](equivalencias_R/06_calibracion.R).

**¿Por qué pudo ganar k = 0?** Posibles razones (ninguna se comprobó por separado):

1. **El Elo ya trae la información de largo plazo.** El Elo acumula todas las temporadas anteriores; mezclar el
   promedio de la temporada con la anterior repite algo que el modelo ya sabe y diluye lo nuevo. Es **compatible** con
   la excepción de K = 45: con un Elo de memoria corta, un poco de mezcla volvió a ayudar.
2. **El balance entre ruido y actualidad.** k = 0 pierde precisión en las primeras jornadas (el 8.9 % de los pares
   tiene de 1 a 3 partidos), pero gana el resto de la temporada, cuando con k = 10 la temporada anterior todavía pesaba
   21 %–34 %. La rejilla dice que el saldo total favoreció a k = 0.
3. **Los equipos cambian de una temporada a otra** (fichajes, entrenadores), así que la temporada anterior puede ser
   una referencia más débil de lo que parece.

**Si preguntan:** "La función permite mezclar con la temporada anterior, pero la calibración dijo que no convenía: con
k = 0 se usa el promedio de la temporada en curso, y la anterior sólo antes del primer partido. Creemos que es porque
el Elo ya aporta la información de largo plazo, pero eso no lo probamos por separado."

## 5.2 Forma reciente: promedio ponderado de los últimos 10 partidos

Se toman los **últimos 10 partidos** del equipo (de local y de visitante, de cualquier temporada) y se calcula un
promedio donde **los partidos recientes pesan más**:

$$
\tilde w_i = d^{\,m-i}, \qquad w_i = \frac{\tilde w_i}{\sum_j \tilde w_j}, \qquad \overline{x} = \sum_{i=1}^{m} w_i\,x_i
$$

con $d = 0.85$, $m \le 10$ partidos ordenados del más antiguo ($i = 1$) al más reciente ($i = m$). El más reciente
tiene $\tilde w = 0.85^0 = 1$, el anterior $0.85$, luego $0.85^2 = 0.72$, etc. Al dividir entre la suma (normalizar),
los pesos suman 1 y el resultado queda en goles o tiros **por partido**. (El código numera desde 0 y escribe
$d^{\,m-1-i}$; es lo mismo.)

| Posición (1 = el más reciente) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Peso | 18.7 % | 15.9 % | 13.5 % | 11.5 % | 9.7 % | 8.3 % | 7.0 % | 6.0 % | 5.1 % | 4.3 % |

- Los **3 últimos partidos suman 48.0 %** del promedio y los 5 últimos, 69.3 %.
- El peso se reduce a la mitad cada **≈ 4.3 partidos** ($\ln 0.5 / \ln 0.85 = 4.27$).
- **Con menos de 10 partidos**, los pesos se renormalizan sobre los que haya: con 2 partidos, 54.1 % el último y 45.9 %
  el anterior; con 3, 38.9 %, 33.0 % y 28.1 %.

Se aplica a seis variables: goles a favor y en contra, tiros realizados y concedidos, y tiros a puerta realizados y
concedidos. Las de goles entran en M1 y M4; las de tiros, en M2 y M4; las de tiros a puerta, en M3 y M4. **M0, el
modelo final, no usa la forma reciente.**

**Ejemplo real:** Liverpool antes de su primer partido de la base (9-ago-2019). Sus últimos 10 partidos son de marzo a
mayo de 2019 (tabla completa, partido por partido, en el [capítulo 10](10_codigo_wc_predictor.md#1010-recent_form)).
Goles a favor ponderados **2.6617** (el promedio simple sería 2.50: pesa más el 5–0 a Huddersfield de abril), en
contra 0.6325 (simple: 0.70), tiros 15.38 y tiros a puerta 5.25. Son los valores de la caché
`premier_training_data.csv`.

**¿Por qué tiros?** Los goles son pocos y muy aleatorios. Los tiros son muchos más, así que indican la calidad
ofensiva con menos ruido: un equipo que tira mucho pero no anota tiende a anotar más en el futuro. Es la idea detrás
de las métricas de "goles esperados" (xG).

> **Limitación importante (ejemplo real):** la forma de Norwich para su primer partido de 2019/20 se calculó con
> partidos de **marzo a mayo de 2016**, su última etapa en Premier (goles a favor 0.91 y en contra 1.69). Para un
> equipo recién ascendido, "forma reciente" puede significar datos de hace años.

## 5.3 El código en Python (`wc_predictor.py`)

Versiones abreviadas; el código completo, bloque por bloque, está en el [capítulo 10](10_codigo_wc_predictor.md).

### `season_stats()`: promedios de la temporada con *shrinkage*

```python
SHRINKAGE_K = 0

def season_stats(df, team, as_of_date, k=SHRINKAGE_K):
    fecha = pd.to_datetime(as_of_date)
    df_pre = df[df["date"] < fecha].copy()                 # 1) sólo días anteriores

    season_year = fecha.year if fecha.month >= 8 else fecha.year - 1   # (en el archivo, con if/else)
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
    # ... 4) referencia previa: temporada anterior del equipo, si no la jugó el promedio de la liga
    n = len(current)
    if n == 0:                                             # 5) sin partidos: sólo la referencia
        return {"gf_avg": gf_previo, "ga_avg": ga_previo}
    peso_actual = n / (n + k)                              # con k = 0: 1
    peso_previo = k / (n + k)                              # con k = 0: 0
    gf_ajustado = peso_actual * gf_actual + peso_previo * gf_previo
```

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `df[df["date"] < fecha]` | Filtra los partidos de días anteriores a la fecha | `filter(historico, Date < fecha)` |
| `fecha.month >= 8` | Decide a qué temporada pertenece la fecha | `as.integer(format(fecha, "%m")) >= 8` |
| `(a == team) \| (b == team)` | Partidos donde juega el equipo, de local o visitante | `HomeTeam == equipo \| AwayTeam == equipo` |
| `np.where(cond, x, y)` | Toma `x` si es local y `y` si es visitante | `ifelse(cond, x, y)` |
| `np.mean(gf)` | Promedio | `mean(gf)` |
| `if n == 0: return ...` | Antes del primer partido de la temporada, sólo la referencia | `if (n == 0) return(...)` |

Quién la llama: `crear_variables_partido` (notebook §2), con `k=k_shrinkage`; en la base definitiva, k = 0.

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
- La comprensión `[decay ** (len(gf) - 1 - i) for i in range(len(gf))]` genera 0.85⁹, 0.85⁸, …, 0.85⁰ (en R,
  `0.85^((m - 1):0)`).
- `np.average(x, weights=w)` es el promedio ponderado (en R, `sum(w * x)` con pesos normalizados, o
  `weighted.mean(x, w)`).
- **Importante:** la función no filtra por fecha. Quien la llama debe pasarle **sólo partidos anteriores**, y así lo
  hace el notebook: `crear_variables_partido` exige `df_pre` con fechas menores a la del partido y lanza un error si
  no. El notebook le pasa la ventana y el decaimiento explícitos (`n=N_FORMA, decay=DECAY_FORMA`, 10 y 0.85).
- Si el equipo no tiene partidos previos, los tiros quedan vacíos (`NaN`). Por eso se excluyeron 4 partidos de la
  base (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026): 2,700 → 2,696.

## 5.4 El mismo código en R

Script completo y verificado contra la caché: [`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R).

```r
library(readr); library(dplyr)
historico <- read_csv("E0_consolidado.csv", show_col_types = FALSE) |> arrange(Date)

# season_stats(): referencia previa y peso n / (n + k)
promedios_ajustados <- function(historico, equipo, fecha, k = 0) {
  previo <- historico |> filter(Date < fecha)                       # sólo días anteriores
  anio <- as.integer(format(fecha, "%Y")) - (as.integer(format(fecha, "%m")) < 8)
  inicio <- as.Date(sprintf("%d-08-01", anio))                      # la temporada empieza el 1 de agosto
  juega <- function(d) d$HomeTeam == equipo | d$AwayTeam == equipo
  actual <- previo |> filter(Date >= inicio)
  actual <- actual[juega(actual), ]
  liga_anterior <- previo |> filter(Date >= as.Date(sprintf("%d-08-01", anio - 1)), Date < inicio)
  anterior <- liga_anterior[juega(liga_anterior), ]
  gf <- function(d) ifelse(d$HomeTeam == equipo, d$FTHG, d$FTAG)
  ga <- function(d) ifelse(d$HomeTeam == equipo, d$FTAG, d$FTHG)
  if (nrow(anterior) == 0) {                                        # ascendido: promedio de la liga
    media_liga <- (sum(liga_anterior$FTHG) + sum(liga_anterior$FTAG)) / (2 * nrow(liga_anterior))
    previa <- c(gf = media_liga, ga = media_liga)
  } else {
    previa <- c(gf = mean(gf(anterior)), ga = mean(ga(anterior)))
  }
  n <- nrow(actual)
  if (n == 0) return(previa)                                        # antes del primer partido
  peso <- n / (n + k)                                               # con k = 0: 1
  peso * c(gf = mean(gf(actual)), ga = mean(ga(actual))) + (1 - peso) * previa
}

# recent_form(): promedio ponderado de los últimos 10 partidos
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

promedios_ajustados(historico, "Liverpool", as.Date("2019-08-17"))          # 4 y 1 (k = 0)
promedios_ajustados(historico, "Liverpool", as.Date("2019-08-17"), k = 10)  # 2.4928 y 0.6172
forma_reciente(historico, "Liverpool", as.Date("2019-08-09"))               # 2.6617
```

En R también existen herramientas para promedios móviles ponderados (`slider::slide_dbl()`, `zoo::rollapply()`);
aquí se escribió explícito para que sea idéntico a Python.

## 5.5 Decisiones y alternativas

> **Decisión:** promedios de goles de la temporada con *shrinkage* de peso fijo n / (n + k), con k elegido por
> validación temporal (k = 0) y, como referencia, la temporada anterior del equipo (o el promedio de la liga si
> ascendió).
> **Alternativas:** (a) *shrinkage* bayesiano formal: un modelo gamma-Poisson cuyo k (la fuerza de la información
> previa) se estima con los datos, por ejemplo comparando cuánto varían los equipos entre sí contra el ruido de
> Poisson — es la versión "de libro" de la misma fórmula, pero más difícil de explicar; (b) promedio móvil de los
> últimos N partidos sin importar la temporada — eso ya lo hace la forma reciente; (c) estimar ataque y defensa de
> cada equipo dentro de un modelo de Poisson que también ajusta por la fuerza del rival (Maher, 1982; Dixon y Coles,
> 1997) — más completo (un equipo que enfrentó a los cuatro grandes no queda castigado), pero es otro modelo; (d) para
> los ascendidos, el promedio histórico de los ascendidos en vez del de toda la liga. Se probaron k = 0, 5, 10, 15 y
> 20 dentro de la rejilla; (a), (c) y (d) no se probaron.
> **Por qué ésta:** con un solo parámetro, la fórmula va de "sin mezcla" (k = 0) a "mucha mezcla", así que se puede
> calibrar con una rejilla pequeña, y es la misma idea bayesiana con peso fijo. La validación eligió el extremo sin
> mezcla.
> **Evidencia en el proyecto:** con K = 15, LogLoss de calibración 0.959558 (k = 0) contra 0.961220 (k = 10); k = 0 fue
> el mejor para 6 de 7 valores de K. Los ascendidos de 2019/20–2025/26 anotaron 1.02 y recibieron 1.84 goles por
> partido, contra la referencia de 1.44 que recibieron: con k = 0 ese error sólo afecta su primer partido.
> **Si preguntan:** "Probamos mezclar con la temporada anterior con pesos de 0 a 20 partidos y ganó no mezclar; el Elo
> ya aporta la historia del equipo."

> **Decisión:** forma reciente con los últimos 10 partidos y decaimiento 0.85, pesos normalizados.
> **Alternativas:** (a) ventana de 5 partidos — más reactiva, pero más ruidosa; (b) ventana de 20 — más estable, pero
> mezcla más partidos viejos; (c) promedio simple de los 10 — todos los partidos pesan igual; (d) pesos que decaen con
> los **días** transcurridos (exponencial en el tiempo, como en Dixon y Coles, 1997) — trata bien las pausas de verano o
> de Mundial; (e) elegir ventana y decaimiento con la misma rejilla de validación temporal que K y k. Ninguna se probó.
> **Por qué ésta:** 10 partidos son un cuarto de temporada; con 0.85 los 3 últimos pesan 48 % y el peso se reduce a la
> mitad cada ≈ 4.3 partidos, un punto medio entre reaccionar y no perseguir un solo resultado. No se calibraron porque
> la forma sólo entra en M1–M4, y la calibración se hizo con M0.
> **Evidencia en el proyecto:** ninguna directa sobre 10 y 0.85. Lo que sí se midió: agregar la forma de goles (M1) no
> mejoró a M0 en prueba (1.0347 contra 1.0331).
> **Si preguntan:** "10 y 0.85 son valores razonables, no optimizados; como el modelo final no usa la forma reciente,
> no se calibraron. Sería una extensión."

> **Decisión:** la forma reciente cruza temporadas (los últimos 10 partidos de Premier, sean de la temporada que sean).
> **Alternativas:** (a) sólo partidos de la temporada en curso — evita usar datos viejos, pero en la jornada 1 no habría
> forma y en las primeras jornadas sería muy ruidosa; (b) incluir partidos de otras ligas o divisiones (Championship) —
> resolvería el caso de los ascendidos, pero Football-Data `E0` sólo trae Premier; (c) cruzar temporadas con un
> decaimiento por días, para que los partidos de hace años casi no pesen. Ninguna se probó.
> **Por qué ésta:** así hay forma desde el primer partido de cada temporada, con datos que la base sí tiene.
> **Evidencia en el proyecto:** el costo está documentado: Norwich, al volver en 2019/20, usó partidos de 2016.
> **Si preguntan:** "Usamos los últimos 10 partidos de Premier aunque sean de la temporada anterior; para los
> ascendidos eso puede ser de hace años, y lo reconocemos como limitación."

## 5.6 Preguntas rápidas

<details><summary>¿Qué es el shrinkage y qué valor de k usaron?</summary>

Mezclar el promedio de goles de la temporada con una referencia previa (la temporada anterior), con peso n / (n + k)
para la temporada actual. Se calibró k entre 0 y 20 con validación temporal y ganó **k = 0**: en cuanto el equipo jugó
un partido, se usa sólo el promedio de la temporada en curso.
</details>

<details><summary>Si k = 0, ¿para qué está el shrinkage en el código?</summary>

Porque se calibró: la fórmula con k permite probar desde "sin mezcla" hasta "mucha mezcla", y la validación eligió el
extremo sin mezcla. Además, la referencia previa sí se usa con k = 0: es lo que recibe cada equipo antes de su primer
partido de la temporada.
</details>

<details><summary>¿k = 0 significa que no hay información al inicio de la temporada?</summary>

No. Antes del primer partido (n = 0), `season_stats()` devuelve la referencia previa: los promedios del equipo en la
temporada anterior o, si ascendió, el promedio de la liga. Desde el segundo partido se usa la temporada en curso.
</details>

<details><summary>¿Por qué no usar simplemente el promedio de toda la historia del equipo?</summary>

Porque los equipos cambian mucho de un año a otro (fichajes, entrenadores). La historia larga ya la resume el Elo;
el promedio de goles de la temporada aporta cómo está jugando el equipo este año.
</details>

<details><summary>¿Por qué 10 partidos y 0.85?</summary>

Son valores operativos razonables: 10 partidos son un cuarto de temporada, y 0.85 hace que los 3 últimos pesen casi
la mitad (48 %). No se optimizaron (sólo se calibraron K y k, con M0); hacerlo con validación temporal es una
extensión.
</details>

<details><summary>¿La forma reciente mezcla temporadas?</summary>

Sí: son los últimos 10 partidos de Premier sin importar la temporada. Para los recién ascendidos eso puede significar
partidos de hace años (Norwich en 2019 usó datos de 2016).
</details>
