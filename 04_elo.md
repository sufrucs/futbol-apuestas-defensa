# 4. El sistema Elo

[← Limpieza](03_limpieza_de_datos.md) · [Índice](README.md) · [Siguiente: promedios ajustados y forma →](05_promedios_ajustados_y_forma.md)

## 4.1 La idea en palabras

El **Elo** es un número que resume **qué tan fuerte es un equipo** según sus resultados. Lo
inventó el físico Arpad Elo en los años sesenta para el ajedrez y hoy se usa en muchos deportes
(hay ratings Elo públicos de selecciones y clubes de fútbol).

Funciona con tres reglas:

1. Todos empiezan con el mismo rating (en el proyecto, **1,500**).
2. Antes de cada partido, la **diferencia** de ratings dice qué resultado se espera.
3. Después del partido, cada equipo **gana o pierde puntos según qué tan sorprendente fue el
   resultado**: vencer a un rival mucho más fuerte da muchos puntos; vencer a uno más débil, pocos.

## 4.2 Las fórmulas

**Resultado esperado del local** ($E_H$) frente al visitante, con ratings $R_H$ y $R_A$:

$$
E_H = \frac{1}{1 + 10^{(R_A - R_H)/400}}, \qquad E_A = 1 - E_H
$$

**Actualización** después del partido, donde $S_H$ es el resultado real del local
(1 si gana, 0.5 si empata, 0 si pierde) y $K = 30$:

$$
R_H^{\text{nuevo}} = R_H + K\,(S_H - E_H), \qquad R_A^{\text{nuevo}} = R_A + K\,(S_A - E_A), \qquad S_A = 1 - S_H
$$

Cómo leerlo: **(resultado real − resultado esperado)** es la sorpresa. Si fue mejor de lo
esperado, sube; si fue peor, baja. $K$ decide cuánto se mueve el rating por partido.

> **Ojo:** $E_H$ **no** es "la probabilidad de ganar": es el **resultado esperado** contando el
> empate como medio punto. Por ejemplo, $E_H = 0.6$ puede venir de 50 % de ganar, 20 % de empatar
> y 30 % de perder (0.5 + 0.5 · 0.2 = 0.6).

## 4.3 ¿Por qué 400 y por qué K = 30?

**El 400 es la escala.** Con esa constante, una diferencia de 400 puntos significa que el más
fuerte espera sacar 10 veces más puntos que el débil:

| Diferencia de Elo (local − visitante) | Resultado esperado del local $E_H$ |
|---|---|
| 0 | 0.50 |
| +100 | 0.64 |
| +200 | 0.76 |
| +400 | 0.91 |
| −200 | 0.24 |

El valor 400 es convencional (heredado del ajedrez); cambiarlo solo reescala los ratings.

**K = 30 es la "velocidad de aprendizaje".** Con K grande el rating reacciona rápido (pero es
más ruidoso); con K chico es estable (pero tarda en reconocer cambios reales, como un equipo que
mejora mucho). Los sistemas de fútbol suelen usar valores entre 20 y 40. **El equipo eligió 30 sin
optimizarlo**: es un parámetro operativo y una de las limitaciones reconocidas.

## 4.4 Ejemplos a mano

**Ejemplo 1: equipos iguales (1,500 vs 1,500).** $E_H = 1/(1+10^0) = 0.5$.

| Resultado | Cambio del local | Cambio del visitante |
|---|---|---|
| Gana el local | 30 · (1 − 0.5) = **+15** | −15 |
| Empate | 30 · (0.5 − 0.5) = **0** | 0 |
| Pierde el local | 30 · (0 − 0.5) = **−15** | +15 |

**Ejemplo 2: favorito local (1,700) contra 1,500.**
$E_H = 1/(1+10^{-200/400}) = 1/(1+0.316) = 0.760$.

| Resultado | Cambio del favorito | Cambio del rival |
|---|---|---|
| Gana el favorito | 30 · (1 − 0.76) = **+7.2** | −7.2 |
| Empate | 30 · (0.5 − 0.76) = **−7.8** | +7.8 |
| Pierde el favorito | 30 · (0 − 0.76) = **−22.8** | +22.8 |

El favorito gana poco si cumple y pierde mucho si falla. **Lo que gana uno lo pierde el otro**
(el sistema es de "suma cero"), así que el promedio de todos los ratings siempre es 1,500.

**Ejemplo real:** al 14 de septiembre de 2026, Arsenal tiene 1,833 y Man City 1,808. Su resultado
esperado según Elo es 0.537 (casi parejo, con ligera ventaja para Arsenal).

## 4.5 Cómo entra al modelo

- Para cada partido se guarda el Elo de ambos equipos **inmediatamente antes** del partido
  (`elo_home`, `elo_away`) y su diferencia `elo_diff`.
- En la regresión entra como $D = \text{elo\_diff}/400$ (la misma escala de la fórmula).
- **Lectura del coeficiente en M0:** +100 puntos de Elo del local ($D$ = +0.25) multiplican sus
  goles esperados por $e^{0.4082 \times 0.25} \approx 1.107$ (**+10.7 %**) y los del visitante por
  $e^{-0.4870 \times 0.25} \approx 0.885$ (**−11.5 %**). Es la variable más importante del modelo.

## 4.6 ¿Y la ventaja de jugar en casa?

Muchos sistemas Elo de fútbol suman unos 60–100 puntos al local antes de calcular $E_H$. **El Elo
del proyecto no lo hace**: la localía la capturan las regresiones de Poisson, porque hay una
ecuación para el local y otra para el visitante, cada una con su propio intercepto.

En el tablero (página *Patrones*) se estimó cuánto "vale" jugar en casa: el local y el visitante
tienen la misma probabilidad de ganar cuando el local es **≈ 60 puntos más débil**. Coincide con
lo que usan los sistemas de fútbol.

## 4.7 Detalles de implementación que conviene saber

- **Arranque en 2001:** todos empiezan en 1,500, así que los primeros años el Elo no es
  informativo. Por eso se usa el histórico desde 2001 aunque el modelo empiece en 2019: en 18
  temporadas los ratings se estabilizan.
- **Solo partidos de Premier League:** un equipo que desciende **congela** su rating hasta que
  regresa (quizá años después), y un equipo que nunca había estado en la base entra con 1,500,
  que suele ser **más** que lo que vale un recién ascendido. Es una limitación reconocida.
- **Sin regresión a la media** entre temporadas (algunos sistemas acercan los ratings a 1,500 cada
  verano porque las plantillas cambian).

## 4.8 El código en Python (`wc_predictor.py`)

```python
ELO_INIT = 1500
ELO_K = 30

def expected_score(r_a, r_b):
    return 1 / (1 + 10 ** ((r_b - r_a) / 400))

def update_elo(r_a, r_b, score_a, k=ELO_K):
    exp_a = expected_score(r_a, r_b)
    return r_a + k * (score_a - exp_a)

def build_elo(df, elo_init=ELO_INIT):
    ratings = {}                                   # diccionario {equipo: rating}
    for _, row in df.sort_values("date").iterrows():
        h, a = row["home_team"], row["away_team"]
        hs, as_ = row["home_score"], row["away_score"]
        rh = ratings.get(h, elo_init)              # rating actual o 1500 si es nuevo
        ra = ratings.get(a, elo_init)
        if hs > as_:   sh, sa = 1, 0
        elif hs < as_: sh, sa = 0, 1
        else:          sh, sa = 0.5, 0.5
        ratings[h] = update_elo(rh, ra, sh)
        ratings[a] = update_elo(ra, rh, sa)
    return ratings
```

- `10 ** x` es "10 elevado a x" (en R, `10^x`).
- `ratings.get(h, elo_init)` busca al equipo en el diccionario y, si no está, devuelve 1,500.
- `df.sort_values("date").iterrows()` recorre las filas en orden de fecha.
- `build_elo` devuelve los ratings **finales**; el notebook usa además una versión que guarda el
  rating **previo a cada partido** (ver [capítulo 11](11_codigo_analisis_notebook.md)).
- Nota: `update_elo(ra, rh, sa)` usa `rh` **previo**: los dos equipos se actualizan con los
  ratings de antes del partido, como debe ser.

## 4.9 El mismo código en R

Script completo y verificado: [`equivalencias_R/01_elo.R`](equivalencias_R/01_elo.R).

```r
esperado <- function(r_a, r_b) 1 / (1 + 10^((r_b - r_a) / 400))

elo <- numeric(0)                              # vector con nombres ≈ diccionario de Python
for (i in seq_len(nrow(historico))) {          # historico ordenado por fecha
  local  <- historico$HomeTeam[i]
  visita <- historico$AwayTeam[i]
  r_local  <- if (local  %in% names(elo)) elo[[local]]  else 1500   # ≈ ratings.get(h, 1500)
  r_visita <- if (visita %in% names(elo)) elo[[visita]] else 1500
  s_local <- if (historico$FTHG[i] > historico$FTAG[i]) 1 else
             if (historico$FTHG[i] < historico$FTAG[i]) 0 else 0.5
  elo[local]  <- r_local  + 30 * (s_local       - esperado(r_local,  r_visita))
  elo[visita] <- r_visita + 30 * ((1 - s_local) - esperado(r_visita, r_local))
}
```

Resultado: exactamente los mismos ratings que Python (Arsenal 1,833.29; Man City 1,807.88; …).

## 4.10 Preguntas rápidas

<details><summary>¿Por qué usar Elo y no simplemente la posición en la tabla?</summary>

La tabla solo cuenta puntos de la temporada actual y no distingue contra quién se ganó. El Elo
acumula historia y pondera cada resultado por la fuerza del rival, así que es informativo desde la
primera jornada.
</details>

<details><summary>¿El Elo usa información del futuro?</summary>

No. Para cada partido se usa el rating calculado con los partidos anteriores a su fecha. El rating
se actualiza después de procesar todos los partidos de ese día.
</details>

<details><summary>¿Qué harías para mejorar el Elo?</summary>

Optimizar K con validación temporal, agregar ventaja de local dentro de la fórmula, incluir la
segunda división para no congelar a los descendidos y aplicar regresión a la media entre temporadas.
</details>
