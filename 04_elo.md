# 4. El sistema Elo

[← Limpieza](03_limpieza_de_datos.md) · [Índice](README.md) · [Siguiente: promedios ajustados y forma →](05_promedios_ajustados_y_forma.md)

> **Versión vigente:** K = **15**, calibrado por validación temporal (la primera versión usaba K = 30 fijo). Todas
> las cifras de este capítulo se calcularon con el código entregado (`wc_predictor.py`, `Analisis.ipynb`, tablero).
> El código, línea por línea, está en el [capítulo 10](10_codigo_wc_predictor.md).

## 4.1 La idea en palabras

El **Elo** es un número que resume **qué tan fuerte es un equipo** según sus resultados. Lo inventó el físico Arpad
Elo para el ajedrez (Elo, 1978) y hoy se usa en muchos deportes (hay ratings Elo públicos de selecciones y clubes de
fútbol).

Funciona con tres reglas:

1. Todos empiezan con el mismo rating (en el proyecto, **1,500**).
2. Antes de cada partido, la **diferencia** de ratings dice qué resultado se espera.
3. Después del partido, cada equipo **gana o pierde puntos según qué tan sorprendente fue el resultado**: vencer a
   un rival mucho más fuerte da muchos puntos; vencer a uno más débil, pocos.

## 4.2 Las fórmulas

**Resultado esperado del local** ($E_H$) frente al visitante, con ratings $R_H$ y $R_A$:

$$
E_H = \frac{1}{1 + 10^{(R_A - R_H)/400}}, \qquad E_A = 1 - E_H
$$

**Actualización** después del partido, donde $S_H$ es el resultado real del local (1 si gana, 0.5 si empata, 0 si
pierde) y $K = 15$:

$$
R_H^{\text{nuevo}} = R_H + K\,(S_H - E_H), \qquad R_A^{\text{nuevo}} = R_A + K\,(S_A - E_A), \qquad S_A = 1 - S_H
$$

Cómo leerlo: **(resultado real − resultado esperado)** es la sorpresa. Si fue mejor de lo esperado, sube; si fue
peor, baja. $K$ decide cuánto se mueve el rating por partido.

> **Ojo:** $E_H$ **no** es "la probabilidad de ganar": es el **resultado esperado** contando el empate como medio
> punto. Por ejemplo, $E_H = 0.6$ puede venir de 50 % de ganar, 20 % de empatar y 30 % de perder
> (0.5 + 0.5 · 0.2 = 0.6).

## 4.3 ¿Por qué 400 y por qué K = 15?

### El 400 es la escala

Con esa constante, una diferencia de 400 puntos significa que el más fuerte espera sacar 10 veces más puntos que el
débil:

| Diferencia de Elo (local − visitante) | Resultado esperado del local $E_H$ |
|---|---|
| 0 | 0.50 |
| +50 | 0.57 |
| +100 | 0.64 |
| +200 | 0.76 |
| +400 | 0.91 |
| −200 | 0.24 |

El valor 400 es convencional (heredado del ajedrez) y **no cambia el modelo**. Se comprobó con el código: con escala
800 y K = 30, todos los ratings medidos desde 1,500 salen exactamente al doble que con escala 400 y K = 15
(diferencias de $2 \times 10^{-12}$), y como la regresión usa la diferencia dividida entre la misma escala
($D = \text{elo\_diff}/400$), recibe la misma variable. Lo mismo pasa con el 1,500: sólo fija el promedio, y lo que
importa es la diferencia.

### K es la "velocidad de aprendizaje"

Con K grande el rating reacciona rápido (pero es más ruidoso, persigue rachas); con K chico es estable (pero tarda en
reconocer cambios reales, como un equipo que mejora mucho). **K es el parámetro que sí cambia el comportamiento del
Elo**, y por eso se calibró.

**Cómo se eligió** (notebook §5, ver [capítulo 9](09_evaluacion_y_validacion.md) y
[capítulo 11](11_codigo_analisis_notebook.md)): validación temporal con ventana creciente. Para cada combinación de
K ∈ {15, 20, 25, 30, 35, 40, 45} y k ∈ {0, 5, 10, 15, 20} (el *shrinkage*, [capítulo 5](05_promedios_ajustados_y_forma.md))
se reconstruyó toda la base, se entrenó M0 con todo lo anterior a cada temporada y se midió el LogLoss 1X2 en esa
temporada: 2021/22, 2022/23 y 2023/24 (380 partidos cada una, 1,140 en total). Se eligió el menor promedio
ponderado por partidos. Ni la validación (2024/25) ni la prueba se usaron para elegir.

LogLoss de la rejilla por K, con k = 0 (el k elegido), y la configuración inicial como referencia:

| K | LogLoss promedio | 2021/22 | 2022/23 | 2023/24 |
|---|---|---|---|---|
| **15** | **0.959558** | **0.960230** | 0.989315 | **0.929130** |
| 20 | 0.959589 | 0.962732 | 0.985396 | 0.930639 |
| 25 | 0.960162 | 0.964908 | 0.983092 | 0.932485 |
| 30 | 0.961021 | 0.966769 | 0.981898 | 0.934396 |
| 35 | 0.962039 | 0.968382 | **0.981453** | 0.936282 |
| 40 | 0.963143 | 0.969808 | 0.981509 | 0.938113 |
| 45 | 0.964290 | 0.971099 | 0.981894 | 0.939877 |
| *30, con k = 10 (configuración inicial)* | *0.962178* | *0.967483* | *0.983457* | *0.935594* |

Cómo leer la tabla:

- **Ganó K = 15** (con k = 0): 0.959558, **0.002620 menos** que la configuración inicial (K = 30, k = 10).
- **K = 20 queda prácticamente empatado** (0.000031 más): el "óptimo" es plano entre 15 y 20.
- **No ganó en las tres temporadas:** 2021/22 y 2023/24 prefieren K chicos; 2022/23 prefiere K grandes (su mejor
  valor es K = 35). K = 15 gana en el promedio.
- **K = 15 es el valor más bajo de la rejilla** (está en el borde). El propio notebook advierte que, si el mejor
  valor sale en un extremo, conviene ampliar el rango. **No se probaron K menores que 15**; es la extensión natural.

La rejilla completa (35 combinaciones) está comentada en el notebook entregado, que sólo deja activa la combinación
elegida para no repetir la búsqueda en cada ejecución. Se reprodujo completa en Python y en R:
[`equivalencias_R/06_calibracion.R`](equivalencias_R/06_calibracion.R) da las mismas 35 cifras a 6 decimales.

**Intuición de por qué ganó un K chico:** la Premier tiene muchos partidos por temporada entre los mismos rivales; un
rating que se mueve poco no persigue rachas y "recuerda" más temporadas. Es una interpretación, no algo que se haya
probado por separado.

### ¿La calibración mejoró los resultados finales?

Pregunta probable, sobre todo de quien vio la primera versión del tablero (que usaba K = 30 y k = 10). **Cálculo
hecho para esta guía** con el código del notebook entregado (una copia con la rejilla fija en K = 30, k = 10), con la
**misma** base de 9,540 partidos; no está en el notebook ni en el reporte:

| LogLoss de M0 | K = 15, k = 0 (calibrada, vigente) | K = 30, k = 10 (inicial) | Diferencia calibrada − inicial (IC 95 %, bootstrap pareado, 10,000 remuestreos) |
|---|---|---|---|
| Calibración (2021/22–2023/24, 1,140 partidos) | **0.959558** | 0.962178 | −0.0026 |
| Validación 2024/25 (380) | 0.989547 | **0.983636** | +0.0059 [−0.0018, +0.0135] |
| Prueba (419) | 1.033076 | **1.030640** | +0.0024 [−0.0049, +0.0099] |
| Validación + prueba (799) | | | +0.0041 [−0.0012, +0.0093] |

- La configuración calibrada ganó donde se eligió, pero en validación y prueba la inicial dio un LogLoss **un poco
  menor**. Las diferencias son pequeñas y **no concluyentes**: los tres intervalos incluyen el cero.
- Confirma lo que ya mostraba la rejilla: el mejor K y k **cambia de una temporada a otra** (2022/23 prefería K
  grandes).
- **¿Por qué no volver a K = 30?** Porque sería elegir mirando la prueba: la prueba dejaría de ser una evaluación
  honesta (fuga de información). El procedimiento correcto es fijar la regla de selección antes (validación temporal
  en 2021–2024) y reportar lo que salga.
- Con la base anterior (9,450 partidos) la configuración inicial daba 0.983690 y 1.030556, casi lo mismo: la
  diferencia viene de K y k, no de los 90 partidos recuperados en la limpieza.

**Si preguntan:** "Elegimos K y k con validación temporal en tres temporadas anteriores. En validación y prueba la
configuración anterior salía apenas mejor, pero la diferencia no es significativa, y cambiarla por eso sería usar la
prueba para elegir."

## 4.4 Ejemplos a mano

**Ejemplo 1: equipos iguales (1,500 contra 1,500).** $E_H = 1/(1+10^0) = 0.5$.

| Resultado | Cambio del local con K = 15 (vigente) | Con K = 30 (versión inicial) | Cambio del visitante (K = 15) |
|---|---|---|---|
| Gana el local | 15 · (1 − 0.5) = **+7.5** | +15 | −7.5 |
| Empate | 15 · (0.5 − 0.5) = **0** | 0 | 0 |
| Pierde el local | 15 · (0 − 0.5) = **−7.5** | −15 | +7.5 |

**Ejemplo 2: favorito local (1,700) contra 1,500.**
$E_H = 1/(1+10^{-200/400}) = 1/(1+0.316) = 0.760$.

| Resultado | Cambio del favorito con K = 15 | Con K = 30 | Cambio del rival (K = 15) |
|---|---|---|---|
| Gana el favorito | 15 · (1 − 0.760) = **+3.6** | +7.2 | −3.6 |
| Empate | 15 · (0.5 − 0.760) = **−3.9** | −7.8 | +3.9 |
| Pierde el favorito | 15 · (0 − 0.760) = **−11.4** | −22.8 | +11.4 |

El favorito gana poco si cumple y pierde mucho si falla. **Lo que gana uno lo pierde el otro** (el sistema es de
"suma cero"), así que el promedio de todos los ratings siempre es 1,500: con los 45 equipos que han jugado en la base,
el promedio es exactamente 1,500.000000. Con K = 15 todos los movimientos son la mitad que con K = 30.

**Ejemplo real:** el último Man City–Arsenal de la base (19-abr-2026, 2–1). Antes del partido: City 1,764.92 y
Arsenal 1,764.00, así que $E_H$ = 0.5013 (casi parejo). Gana City: 15 · (1 − 0.5013) = **+7.48** (queda en 1,772.40)
y Arsenal **−7.48** (1,756.52).

## 4.5 El ranking final

Ratings al 14-sep-2026, después del último partido de la base (`build_elo` con los 9,540 partidos):

| # | Equipo | Elo (K = 15) |
|---|---|---|
| 1 | Arsenal | 1,787.12 |
| 2 | Man City | 1,779.19 |
| 3 | Liverpool | 1,683.74 |
| 4 | Man United | 1,638.49 |
| 5 | Aston Villa | 1,625.20 |
| 6 | Chelsea | 1,614.82 |
| 7 | Bournemouth | 1,609.99 |
| 8 | Brighton | 1,605.36 |
| 9 | Newcastle | 1,592.32 |
| 10 | Brentford | 1,590.63 |

- **Arsenal contra Man City:** resultado esperado de Arsenal según Elo = **0.511** (casi parejo). Con la versión
  inicial (K = 30, base de 9,450 partidos) era Arsenal 1,833.29 contra Man City 1,807.88 y 0.537.
- **El orden cambia con K:** con K = 30 los cinco primeros eran Arsenal, Man City, Man United (1,679.95),
  Bournemouth (1,659.96) y Liverpool (1,656.03). Con K = 15 Liverpool sube al 3.er lugar: un K más chico le da más
  peso a las temporadas anteriores.
- Los ratings con K = 15 están más juntos: la diferencia entre el primero (Arsenal) y el último de los 45 (Derby,
  1,320.84, descendido hace años) es de 466 puntos.

## 4.6 Cómo entra al modelo

- Para cada partido se guarda el Elo de ambos equipos **inmediatamente antes** del partido (`elo_home`, `elo_away`) y
  su diferencia `elo_diff`.
- En la regresión entra como $D = \text{elo\_diff}/400$ (la misma escala de la fórmula).
- En el periodo de entrenamiento (2019/20–2023/24), `elo_diff` tiene **desviación estándar de 150.8** puntos y va de
  −427.6 a +432.8 (con K = 30 eran 167.0 y −533.7 a +498.0: un K más chico separa menos a los equipos).
- **Lectura de los coeficientes de M0** (local 0.6283, visitante −0.6854):

| Cambio en la diferencia de Elo | Goles esperados del local | Goles esperados del visitante |
|---|---|---|
| +100 puntos ($D$ = +0.25) | $e^{0.6283 \times 0.25}$ = 1.170 → **+17.0 %** | $e^{-0.6854 \times 0.25}$ = 0.842 → **−15.7 %** |
| +1 desviación estándar (150.8 puntos) | **+26.7 %** (IC 95 %: +21.0 a +32.8) | **−22.8 %** (IC 95 %: −26.6 a −18.7) |
| +400 puntos ($D$ = +1) | $e^{0.6283}$ ≈ **1.87** (casi el doble) | $e^{-0.6854}$ ≈ 0.50 (la mitad) |

- **Es la variable más importante del modelo:** +1 desviación estándar de Elo mueve los goles del local +26.7 %,
  contra +10.7 % de sus goles a favor de la temporada. Otra forma de verlo: en la ecuación del local, **1 gol más de
  promedio en la temporada equivale a ≈ 107 puntos de Elo** (0.1678 / 0.6283 × 400).
- Con la configuración inicial (K = 30, k = 10) el coeficiente era menor (0.4082 / −0.4870; +100 puntos = +10.7 % /
  −11.5 %) y el efecto de +1 desviación estándar era +18.6 % / −18.4 %. Con la configuración vigente el Elo resume
  más de la fuerza del equipo y los promedios de goles aportan menos (`gf_home`: 0.1678 en lugar de 0.3338).

## 4.7 ¿Y la ventaja de jugar en casa?

Muchos sistemas Elo de fútbol suman puntos al local antes de calcular $E_H$. **El Elo del proyecto no lo hace**: la
localía la capturan las regresiones de Poisson, porque hay una ecuación para el local y otra para el visitante, cada
una con su propio intercepto.

En el tablero (página *Patrones*) se estimó cuánto "vale" jugar en casa: se agrupan los 2,696 partidos de la base de
modelación (2019/20–2026/27) en deciles de diferencia de Elo y se busca, interpolando, la diferencia en la que el
local y el visitante ganan igual de seguido. Resultado: cuando el local es **≈ 50 puntos más débil** (50.0; con la
versión inicial eran ≈ 60, 62.6). Los deciles también muestran que el Elo separa bien: en el decil más bajo
(visitante mucho más fuerte) el local gana **12.6 %** de las veces; en el más alto, **76.3 %**.

¿Qué cuesta no tener localía dentro de la fórmula? Poco: en promedio el local saca 0.0805 puntos de resultado más de
lo que espera el Elo (0.5789 contra 0.4985), o sea **+1.2 puntos de Elo** por partido en casa con K = 15, que
devuelve cuando juega de visitante. Como cada equipo juega la mitad de sus partidos en casa, se compensa en la
temporada.

## 4.8 Detalles de implementación que conviene saber

- **Arranque en 2001:** todos empiezan en 1,500, así que los primeros años el Elo no es informativo. Por eso se usa
  el histórico desde 2001/02 aunque la base de modelación empiece en 2019: en 18 temporadas los ratings se
  estabilizan.
- **Sólo partidos de Premier League:** un equipo que desciende **congela** su rating hasta que regresa. Ejemplos:
  Norwich volvió en 2019/20 con su rating de mayo de 2016 (1,437.7, lugar 19 de 20); Ipswich volvió en 2024/25 con su
  rating de 2002 (1,447.9); Sunderland volvió en 2025/26 con el de 2017 (1,421.8, último) y terminó esa temporada en
  1,521.0.
- **Equipos nuevos con 1,500:** un equipo que nunca había estado en la base entra con 1,500, que suele ser **más** de
  lo que vale un recién ascendido. Brentford (2021), Nott'm Forest (2022), Luton (2023) y Coventry (2026) entraron
  entre los lugares 15 y 18 de 20; Luton entró por encima de tres equipos que ya estaban en Premier y terminó su
  temporada en 1,443.4. Es una limitación reconocida.
- **El promedio es 1,500, pero no el de la liga actual:** los 45 equipos de la base promedian 1,500 exactos, pero los
  20 de 2026/27 promedian 1,584.9, porque los descendidos se quedan con ratings bajos.
- **Sin regresión a la media** entre temporadas (algunos sistemas acercan los ratings al promedio cada verano, porque
  las plantillas cambian).
- **Sin margen de goles:** ganar 1–0 o 5–0 mueve el rating lo mismo.

## 4.9 El código en Python (`wc_predictor.py`)

Versión entregada, sin comentarios (explicación línea por línea en el [capítulo 10](10_codigo_wc_predictor.md#109-build_elo)):

```python
ELO_INIT     = 1500
ELO_SCALE    = 400
ELO_K        = 15

def expected_score(r_a, r_b, scale=ELO_SCALE):
    return 1 / (1 + 10 ** ((r_b - r_a) / scale))

def update_elo(r_a, r_b, score_a, k=ELO_K, scale=ELO_SCALE):
    exp_a = expected_score(r_a, r_b, scale=scale)
    return r_a + k * (score_a - exp_a)

def build_elo(df, elo_init=ELO_INIT, k=ELO_K, scale=ELO_SCALE):
    ratings = {}                                   # diccionario {equipo: rating}
    for _, row in df.sort_values("date").iterrows():
        h = row["home_team"]
        a = row["away_team"]
        hs = row["home_score"]
        as_ = row["away_score"]
        rh = ratings.get(h, elo_init)              # rating actual o 1500 si es nuevo
        ra = ratings.get(a, elo_init)
        if hs > as_:
            sh, sa = 1, 0
        elif hs < as_:
            sh, sa = 0, 1
        else:
            sh, sa = 0.5, 0.5
        ratings[h] = update_elo(rh, ra, sh, k=k, scale=scale)
        ratings[a] = update_elo(ra, rh, sa, k=k, scale=scale)
    return ratings
```

- `10 ** x` es "10 elevado a x" (en R, `10^x`).
- `ratings.get(h, elo_init)` busca al equipo en el diccionario y, si no está, devuelve 1,500.
- `df.sort_values("date").iterrows()` recorre las filas en orden de fecha.
- K y la escala son **argumentos**: así la calibración prueba varios K sin editar el archivo. Antes, `build_elo` no
  recibía K y siempre usaba 30.
- Nota: `update_elo(ra, rh, sa, ...)` usa `rh` **previo**: los dos equipos se actualizan con los ratings de antes del
  partido, como debe ser.
- `build_elo` devuelve los ratings **finales**; para la base de entrenamiento el notebook necesita el rating
  **previo a cada partido**, así que repite el ciclo día por día con `update_elo` (ver
  [capítulo 11](11_codigo_analisis_notebook.md)): todos los partidos de un mismo día usan los ratings de antes de ese
  día, y el Elo se actualiza después.

## 4.10 El mismo código en R

Script completo y verificado: [`equivalencias_R/01_elo.R`](equivalencias_R/01_elo.R).

```r
ELO_INICIAL <- 1500
K <- 15                                        # Python: ELO_K = 15 (la versión inicial usaba 30)
esperado <- function(r_a, r_b) 1 / (1 + 10^((r_b - r_a) / 400))

elo <- numeric(0)                              # vector con nombres ≈ diccionario de Python
for (i in seq_len(nrow(historico))) {          # historico ordenado por fecha
  local  <- historico$HomeTeam[i]
  visita <- historico$AwayTeam[i]
  r_local  <- if (local  %in% names(elo)) elo[[local]]  else ELO_INICIAL   # ≈ ratings.get(h, 1500)
  r_visita <- if (visita %in% names(elo)) elo[[visita]] else ELO_INICIAL
  s_local <- if (historico$FTHG[i] > historico$FTAG[i]) 1 else
             if (historico$FTHG[i] < historico$FTAG[i]) 0 else 0.5
  elo[local]  <- r_local  + K * (s_local       - esperado(r_local,  r_visita))
  elo[visita] <- r_visita + K * ((1 - s_local) - esperado(r_visita, r_local))
}
```

Resultado: exactamente los mismos ratings que Python (Arsenal 1,787.12; Man City 1,779.19; Liverpool 1,683.74; …) y
el mismo resultado esperado de Arsenal contra Man City, 0.511. La calibración de K en R está en
[`equivalencias_R/06_calibracion.R`](equivalencias_R/06_calibracion.R).

## 4.11 Decisiones y alternativas

> **Decisión:** medir la fuerza de cada equipo con un Elo calculado desde 2001/02.
> **Alternativas:** (a) puntos o posición en la tabla de la temporada — fácil de entender, pero no existe en la
> jornada 1, no distingue contra quién se ganó y se reinicia cada temporada; (b) diferencia de goles (de la temporada o
> acumulada) — usa el marcador, pero tampoco ajusta por la fuerza del rival; (c) ratings más elaborados, como el
> pi-rating (separa la fuerza de local y de visitante y usa la diferencia de goles) o el SPI de FiveThirtyEight (ataque
> y defensa estimados con goles esperados) — más precisos, pero con más parámetros y, en el SPI, datos que la base no
> tiene; (d) valor de mercado de la plantilla (por ejemplo, Transfermarkt) — muy informativo, pero es un dato externo
> que Football-Data no trae; (e) Elo (lo elegido). Ninguna de las otras se probó.
> **Por qué ésta:** resume en un número toda la historia de resultados, ajusta por la fuerza del rival y existe desde
> el primer partido de cada temporada; sólo necesita resultados, que la base tiene completos desde 2001/02. Además está
> respaldado por la literatura: Hvattum y Arntzen (2010) usaron diferencias de Elo como variables en un modelo logit
> ordenado para pronosticar partidos de fútbol, y pronosticaron mejor que otros métodos de referencia, aunque peor que
> los basados en cuotas de las casas: lo mismo que se ve en este proyecto.
> **Evidencia en el proyecto:** es la variable con mayor efecto en M0 (+1 desviación estándar: +26.7 % de goles del
> local, contra +10.7 % de sus goles a favor de la temporada), y separa bien los resultados (el local gana 12.6 % en el
> decil más bajo de diferencia de Elo y 76.3 % en el más alto).
> **Si preguntan:** "Usamos Elo porque resume la fuerza de cada equipo con toda su historia y ajustando por el rival;
> es la variable más importante del modelo."

> **Decisión:** K = 15, elegido por validación temporal entre 15, 20, …, 45 (junto con k).
> **Alternativas:** (a) un valor habitual elegido a mano (la versión inicial usaba 30) — simple, pero arbitrario;
> (b) rejilla con validación temporal (lo elegido); (c) rejilla más amplia o más fina (K < 15, o de 1 en 1) — no se
> probó; (d) K distinto según el equipo o el momento (más alto para equipos nuevos) — no se probó.
> **Por qué ésta:** de los parámetros del Elo, K es el que cambia su comportamiento (la escala y el 1,500 son
> convenciones), y elegirlo con temporadas anteriores a la validación evita usar la prueba para decidir.
> **Evidencia en el proyecto:** LogLoss de calibración 0.959558 con K = 15 contra 0.962178 de la configuración
> inicial. Matices honestos: K = 20 quedó prácticamente empatado, K = 15 está en el borde de la rejilla, 2022/23
> prefería K grandes, y en validación y prueba la configuración inicial salió apenas mejor sin diferencia significativa
> ([4.3](#43-por-qué-400-y-por-qué-k--15)).
> **Si preguntan:** "K = 15 fue el mejor de una rejilla de 15 a 45 con validación temporal; como quedó en el borde, el
> siguiente paso sería probar valores menores."

> **Decisión:** escala 400 y rating inicial 1,500, los valores convencionales del ajedrez.
> **Alternativas:** cualquier otra escala (800) o nivel inicial (1,000 o 0).
> **Por qué ésta:** no cambian el modelo: el 1,500 sólo fija el promedio (lo que entra a la regresión es la
> diferencia) y la escala sólo reexpresa los ratings (con escala 800 y K = 30 todo sale al doble, y la regresión,
> que divide entre la escala, recibe la misma variable). Con los valores habituales, los ratings se leen como
> cualquier Elo. Lo que sí es una decisión de fondo es dar a los equipos **nuevos** el mismo 1,500 que al resto
> ([4.8](#48-detalles-de-implementación-que-conviene-saber)).
> **Evidencia en el proyecto:** comprobado con `build_elo` (diferencias de $2 \times 10^{-12}$).
> **Si preguntan:** "400 y 1,500 son convenciones; cambiarlas sólo reexpresa los ratings. Lo que se calibró fue K."

> **Decisión:** sin ventaja de localía dentro de la fórmula del Elo.
> **Alternativas:** (a) sumar una ventaja fija al local antes de calcular $E_H$ (aquí valdría ≈ 50 puntos); (b)
> estimar esa ventaja junto con K; (c) sin ventaja (lo elegido). (a) y (b) no se probaron.
> **Por qué ésta:** la localía ya la estima la regresión (ecuaciones separadas para local y visitante, cada una con su
> intercepto); en el Elo el efecto de no incluirla se compensa en la temporada (+1.2 puntos por partido en casa, que se
> devuelven de visitante).
> **Evidencia en el proyecto:** para dos equipos iguales, M0 espera 1.19 veces más goles del local que del visitante,
> la misma razón observada en el entrenamiento ([cap. 10](10_codigo_wc_predictor.md#105-calcular_parametros_liga)).
> **Si preguntan:** "La localía no está en el Elo sino en la regresión: hay una ecuación para el local y otra para el
> visitante."

> **Decisión:** el Elo sólo usa el resultado (gana, empata, pierde), no el margen de goles.
> **Alternativas:** multiplicar K por un factor que crece con la diferencia de goles, como hacen algunos sistemas
> públicos — usa más información del partido, pero premia golear y agrega un parámetro. No se probó.
> **Por qué ésta:** es la versión más simple y la información de goles ya entra al modelo por separado (goles a favor y
> en contra de la temporada).
> **Evidencia en el proyecto:** ninguna directa; es una extensión posible.
> **Si preguntan:** "El Elo mide resultados; los goles entran al modelo por otra variable."

## 4.12 Preguntas rápidas

<details><summary>¿Por qué usar Elo y no simplemente la posición en la tabla?</summary>

La tabla sólo cuenta puntos de la temporada actual y no distingue contra quién se ganó. El Elo acumula historia y
pondera cada resultado por la fuerza del rival, así que es informativo desde la primera jornada.
</details>

<details><summary>¿El Elo usa información del futuro?</summary>

No. Para cada partido se usa el rating calculado con los partidos de días anteriores. El rating se actualiza después
de registrar todos los partidos de ese día.
</details>

<details><summary>¿Por qué K = 15 y no 30?</summary>

Porque en la validación temporal (2021/22–2023/24, 1,140 partidos) K = 15 dio el menor LogLoss promedio de la
rejilla de 15 a 45: 0.959558, contra 0.962178 de la configuración inicial (K = 30, k = 10). Con K más chico el
rating es más estable y no persigue rachas.
</details>

<details><summary>¿Por qué no probaron K menores que 15?</summary>

La rejilla del equipo empezaba en 15 y el mejor valor salió justo ahí, en el borde. El notebook lo advierte: si el
mejor valor está en un extremo, conviene ampliar el rango. Es la extensión más directa; no se hizo.
</details>

<details><summary>¿Qué harías para mejorar el Elo?</summary>

Ampliar la rejilla de K por debajo de 15, agregar la ventaja de local dentro de la fórmula, usar el margen de goles,
incluir la segunda división para no congelar a los descendidos y aplicar regresión a la media entre temporadas.
</details>
