# 6. Distribución de Poisson y regresión de Poisson

[← Promedios y forma](05_promedios_ajustados_y_forma.md) · [Índice](README.md) · [Siguiente: de goles a probabilidades →](07_de_goles_a_probabilidades.md)

## 6.1 La distribución de Poisson

La distribución de Poisson describe **cuántas veces ocurre un evento** en un intervalo (goles en
90 minutos, llamadas en una hora) cuando los eventos son relativamente raros e independientes y
ocurren a un ritmo promedio constante $\lambda$ (lambda).

$$
P(G = g) = \frac{e^{-\lambda}\,\lambda^{g}}{g!}, \qquad g = 0, 1, 2, \dots
$$

Su propiedad clave: **la media y la varianza son iguales a λ**.

**Ejemplo con λ = 1.5 goles esperados:**

| Goles | 0 | 1 | 2 | 3 | 4 | 5 o más |
|---|---|---|---|---|---|---|
| Probabilidad | 22.3 % | 33.5 % | 25.1 % | 12.6 % | 4.7 % | 1.9 % |

```python
from scipy.stats import poisson
poisson.pmf([0, 1, 2, 3, 4], 1.5)      # probabilidades puntuales
```

```r
dpois(0:4, lambda = 1.5)               # R base: d = densidad, p = acumulada, r = simular
```

### ¿Los goles se comportan como Poisson? (evidencia de los datos)

En las 25 temporadas completas (9,410 partidos):

| | Media | Varianza | Varianza / media |
|---|---|---|---|
| Goles del local | 1.534 | 1.691 | 1.10 |
| Goles del visitante | 1.189 | 1.344 | 1.13 |

| Goles del local | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| Observado | 23.3 % | 31.7 % | 24.7 % | 12.6 % | 5.2 % | 1.7 % | 0.5 % |
| Poisson (λ = 1.534) | 21.6 % | 33.1 % | 25.4 % | 13.0 % | 5.0 % | 1.5 % | 0.4 % |

Se parecen mucho. La varianza es **un poco** mayor que la media (sobredispersión leve), pero eso
es esperable al mezclar equipos de distinta fuerza. **Ya dentro del modelo**, controlando por las
variables, la dispersión es 0.99 (local) y 1.04 (visitante): prácticamente 1, justo lo que supone
Poisson (ver 6.5). El tablero muestra esta comparación en *Patrones → Los goles se comportan como
un conteo de Poisson*.

## 6.2 De la distribución a la regresión

En el modelo, cada partido tiene su propia λ: un equipo fuerte contra uno débil espera más goles.
La **regresión de Poisson** hace que λ dependa de variables explicativas:

$$
G \mid X \sim \text{Poisson}(\lambda), \qquad \log \lambda = \beta_0 + \beta_1 x_1 + \dots + \beta_p x_p
\quad\Longleftrightarrow\quad \lambda = e^{\beta_0 + \beta_1 x_1 + \dots + \beta_p x_p}
$$

Es un **modelo lineal generalizado (GLM)**, con tres piezas:

| Pieza | En este modelo | En regresión lineal (para comparar) |
|---|---|---|
| Distribución de la respuesta | Poisson (conteos) | Normal |
| Predictor lineal | $\beta_0 + \beta_1 x_1 + \dots$ | Igual |
| Función de enlace | **Logaritmo**: $\log \lambda$ = predictor lineal | Identidad: $\mu$ = predictor lineal |

**¿Por qué el logaritmo?** Por dos razones:
1. λ (goles esperados) **no puede ser negativa**, y $e^{\text{algo}}$ siempre es positivo.
2. Los efectos se vuelven **multiplicativos**, lo cual es natural para goles: "un equipo con más
   Elo anota un 10 % más", no "anota 0.1 goles más" sin importar el rival.

## 6.3 Las dos ecuaciones del proyecto

Se estiman **dos regresiones separadas**: una para los goles del local y otra para los del visitante.

**M0, el modelo base (3 variables por ecuación):**

$$
\log \hat\lambda_{\text{local}} = -0.3864 + 0.4082\,D + 0.3338\,GF_{\text{local}} + 0.2158\,GA_{\text{visitante}}
$$

$$
\log \hat\lambda_{\text{visitante}} = -0.3009 - 0.4870\,D + 0.2101\,GF_{\text{visitante}} + 0.1589\,GA_{\text{local}}
$$

donde $D$ = (Elo local − Elo visitante)/400, $GF$ = goles a favor ajustados del equipo y $GA$ =
goles en contra ajustados del rival.

**¿Por qué dos ecuaciones y no una con una variable "es local"?** Porque así cada lado tiene sus
propios coeficientes. Por ejemplo, la diferencia de Elo pesa **más** para el visitante (−0.487)
que para el local (+0.408). La ventaja de local aparece en la diferencia entre los interceptos
(−0.386 vs −0.301) y en esos coeficientes.

**Ejemplo de cálculo:** dos equipos idénticos (D = 0) con 1.36 goles a favor y en contra
(el promedio de la liga):

- $\log \hat\lambda_L = -0.3864 + 0.3338(1.36) + 0.2158(1.36) = 0.361 \Rightarrow \hat\lambda_L = e^{0.361} \approx 1.43$
- $\log \hat\lambda_V = -0.3009 + 0.2101(1.36) + 0.1589(1.36) = 0.201 \Rightarrow \hat\lambda_V = e^{0.201} \approx 1.22$

Aun entre iguales, el local espera ≈ 0.2 goles más: **esa es la ventaja de jugar en casa** que
aprendió el modelo.

## 6.4 Cómo interpretar los coeficientes

Como $\lambda = e^{\dots}$, **aumentar una variable en 1 multiplica λ por $e^{\beta}$**:

| Coeficiente (M0) | $e^{\beta}$ | Lectura |
|---|---|---|
| $D$ en la ecuación del local: 0.4082 | 1.504 por cada 400 puntos | +100 puntos de Elo → × $e^{0.102}$ = **1.107**, es decir +10.7 % goles del local |
| $D$ en la del visitante: −0.4870 | 0.614 por cada 400 puntos | +100 puntos de Elo del local → × 0.885 (−11.5 %) goles del visitante |
| $GF_{\text{local}}$: 0.3338 | 1.396 | Cada gol más por partido en su promedio ajustado → +39.6 % goles esperados |
| $GA_{\text{visitante}}$: 0.2158 | 1.241 | Cada gol más que recibe el rival por partido → +24.1 % |

**Para comparar variables con escalas distintas** (Elo contra goles contra tiros), el tablero
muestra **efectos estandarizados**: el cambio en goles esperados al subir **una desviación
estándar** cada variable, $e^{\beta \cdot DE} - 1$:

| Variable (M0) | Goles del local | Goles del visitante |
|---|---|---|
| Diferencia de Elo | **+18.6 %** (IC 95 %: +11.1 a +26.6) | **−18.4 %** (−24.0 a −12.4) |
| Goles a favor del propio equipo | +16.0 % (+10.2 a +22.2) | +9.8 % (+3.8 a +16.2) |
| Goles en contra del rival | +6.9 % (+1.7 a +12.4) | +5.1 % (−0.5 a +11.0), **no significativo al 5 %** (p = 0.075) |

Conclusión: **la diferencia de Elo es la variable que más pesa**.

## 6.5 Cómo se estima: máxima verosimilitud

Se buscan los $\beta$ que hacen **más probables los goles que realmente ocurrieron**. Para
$n$ partidos, la log-verosimilitud es:

$$
\ell(\beta) = \sum_{i=1}^{n} \left[\, g_i \log \lambda_i - \lambda_i - \log(g_i!) \,\right], \qquad \lambda_i = e^{X_i \beta}
$$

No tiene solución con una fórmula cerrada, así que se resuelve numéricamente con **IRLS**
(*iteratively reweighted least squares*, mínimos cuadrados reponderados iterativamente). Es lo que
hacen tanto `statsmodels` en Python como `glm()` en R. Por eso dan **exactamente los mismos
coeficientes**: en este proyecto convergió en 5 iteraciones.

## 6.6 Leer la salida del modelo (Python vs R)

**Python (statsmodels), del notebook:**

```text
                 coef    std err          z      P>|z|      [0.025      0.975]
const         -0.3864      0.177     -2.187      0.029      -0.733      -0.040
elo_diff       0.4082      0.080      5.122      0.000       0.252       0.564
gf_home        0.3338      0.059      5.617      0.000       0.217       0.450
ga_away        0.2158      0.082      2.642      0.008       0.056       0.376
Log-Likelihood: -2888.2   Deviance: 2122.6   Pearson chi2: 1.88e+03   No. Iterations: 5
```

**R (`summary(glm(...))`), de `equivalencias_R/02_modelo_poisson.R`:**

```text
                  Estimate Std. Error   z value     Pr(>|z|)
(Intercept)     -0.3864181 0.17666728 -2.187265 2.872320e-02
I(elo_diff/400)  0.4081865 0.07968615  5.122427 3.016272e-07
gf_home          0.3338374 0.05943129  5.617198 1.940787e-08
ga_away          0.2157736 0.08166922  2.642043 8.240749e-03
```

| statsmodels | R | Qué es |
|---|---|---|
| `coef` | `Estimate` | El coeficiente β |
| `std err` | `Std. Error` | Su incertidumbre |
| `z` | `z value` | coef / error estándar |
| `P>\|z\|` | `Pr(>\|z\|)` | Valor p: si es menor a 0.05, el coeficiente es distinto de cero al 5 % |
| `[0.025 0.975]` | `confint.default(m)` | Intervalo de confianza de 95 % |
| `Deviance` | `Residual deviance` | Qué tan lejos está el modelo de un ajuste perfecto |
| `Pearson chi2` | `sum(residuals(m, "pearson")^2)` | Base de la dispersión |

**Dispersión de Pearson** = Pearson χ² / grados de libertad = 1,878 / 1,893 = **0.99** (local) y
1,971 / 1,893 = **1.04** (visitante). Si fuera mucho mayor que 1 (sobredispersión), convendría una
regresión binomial negativa (`MASS::glm.nb()` en R) o cuasi-Poisson (`family = quasipoisson`).

## 6.7 El código: Python vs R

**Python (`Analisis.ipynb`, sección 4):**

```python
import statsmodels.api as sm

def preparar_X(datos, columnas, modelo=None):
    X = datos.loc[:, columnas].copy().astype(float)
    X["elo_diff"] = X["elo_diff"] / ESCALA_ELO          # Elo en escala /400
    X = sm.add_constant(X, has_constant="add")           # agrega la columna del intercepto
    if modelo is not None:
        X = X.loc[:, modelo.model.exog_names]            # mismo orden de columnas que al entrenar
    return X

def entrenar_modelo(datos, columnas_home, columnas_away):
    home = sm.GLM(datos["home_goals"], preparar_X(datos, columnas_home),
                  family=sm.families.Poisson()).fit()
    away = sm.GLM(datos["away_goals"], preparar_X(datos, columnas_away),
                  family=sm.families.Poisson()).fit()
    return {"home": home, "away": away,
            "columnas_home": columnas_home, "columnas_away": columnas_away}
```

**R:**

```r
m0_local  <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away,
                 family = poisson(link = "log"), data = entrenamiento)
m0_visita <- glm(away_goals ~ I(elo_diff / 400) + gf_away + ga_home,
                 family = poisson(link = "log"), data = entrenamiento)
predict(m0_local, newdata = prueba, type = "response")   # λ de cada partido
```

| Python (statsmodels) | R | Nota |
|---|---|---|
| `sm.add_constant(X)` | automático en la fórmula | R agrega el intercepto solo |
| `X["elo_diff"] / 400` | `I(elo_diff / 400)` | `I()` hace la operación aritmética dentro de la fórmula |
| `sm.GLM(y, X, family=Poisson())` | `glm(y ~ x1 + x2, family = poisson)` | Enlace log por defecto en ambos |
| `.fit()` | (se ajusta al llamar `glm`) | |
| `modelo.predict(X)` | `predict(m, newdata, type = "response")` | `type = "response"` da λ; sin él da log λ |
| `modelo.summary()` | `summary(m)` | |

## 6.8 Las cinco especificaciones

Todas incluyen las 3 variables de M0 y agregan bloques:

| Modelo | Variables por ecuación | Qué agrega |
|---|---|---|
| **M0** base | 3 | Elo + goles ajustados |
| M1 forma | 5 | + goles recientes a favor del equipo y en contra del rival |
| M2 tiros | 5 | + tiros recientes realizados y concedidos por el rival |
| M3 tiros a puerta | 5 | + tiros a puerta recientes |
| M4 completo | 9 | todo lo anterior |

Comparar modelos **anidados** (cada uno contiene al anterior) permite ver si cada bloque de
variables aporta información **fuera de muestra**. Resultado: en validación todos mejoraron un poco
a M0; en prueba ninguno lo hizo (ver [capítulo 12](12_resultados.md)).

## 6.9 Preguntas rápidas

<details><summary>¿Por qué no una regresión lineal para los goles?</summary>

Porque los goles son conteos no negativos, con varianza que crece con la media; una regresión
lineal podría predecir goles negativos y supone varianza constante. Poisson respeta la naturaleza
del dato.
</details>

<details><summary>¿Qué significa que un coeficiente no sea significativo?</summary>

Que su intervalo de confianza incluye el cero: con estos datos no podemos distinguir su efecto de
nada. En M0 pasa con los goles en contra del local en la ecuación del visitante (p = 0.075). En M4
pasa con varias variables, en parte por la multicolinealidad.
</details>

<details><summary>¿Qué alternativas al modelo de Poisson existen?</summary>

Binomial negativa (si hay sobredispersión), Poisson bivariada o Dixon–Coles (para modelar la
dependencia entre goles y los empates), logística multinomial u ordinal (modelan el 1X2
directamente) y modelos de aprendizaje automático (árboles, *boosting*).
</details>
