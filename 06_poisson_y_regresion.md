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

En las 25 temporadas completas (9,500 partidos):

| | Media | Varianza | Varianza / media |
|---|---|---|---|
| Goles del local | 1.535 | 1.697 | 1.11 |
| Goles del visitante | 1.189 | 1.341 | 1.13 |

| Goles del local | 0 | 1 | 2 | 3 | 4 | 5 | 6 o más |
|---|---|---|---|---|---|---|---|
| Observado | 23.3 % | 31.8 % | 24.6 % | 12.5 % | 5.2 % | 1.8 % | 0.8 % |
| Poisson (λ = 1.535) | 21.5 % | 33.1 % | 25.4 % | 13.0 % | 5.0 % | 1.5 % | 0.5 % |

Se parecen mucho. La varianza es **un poco** mayor que la media (sobredispersión leve) y hay algo más
de ceros de los que da una Poisson (23.3 % contra 21.5 %), pero eso es esperable al mezclar equipos de
distinta fuerza: si λ cambia de un partido a otro, la varianza total es la media más la varianza de las
λ. En el periodo de entrenamiento (2019/20–2023/24) la varianza de los goles del local es 1.81 contra
una media de 1.56; las λ que da M0 tienen varianza 0.27, y 1.56 + 0.27 = 1.83, casi exactamente la
varianza observada (en el visitante: 1.31 + 0.17 = 1.48 contra 1.54 observado). **Ya dentro del
modelo**, controlando por las variables, la dispersión es 0.996 (local) y 1.036 (visitante):
prácticamente 1, justo lo que supone Poisson (ver 6.6). El tablero muestra esta comparación en
*Patrones → Los goles se comportan como un conteo de Poisson*.

*(La comparación entre la varianza de los goles y la varianza de las λ de M0 es un cálculo hecho para esta
guía con el código del proyecto; no está en el notebook, el tablero ni el reporte.)*

### La referencia simple: una sola λ para todos los partidos

Si ignoramos todas las variables y damos a **todos** los partidos la misma λ, las medias de goles del
entrenamiento, **λ = 1.561413** para el local y **λ = 1.311545** para el visitante, tenemos el modelo
más pobre que sigue siendo Poisson. Con esas λ todos los partidos reciben las mismas probabilidades
1X2: **43.24 %** local, **24.69 %** empate y **32.07 %** visitante (el [capítulo 7](07_de_goles_a_probabilidades.md)
explica cómo se calculan). Es la **referencia simple** del reporte y del notebook (§7), que el tablero
llama **referencia ingenua**: sirve para medir cuánto aportan las variables. Su LogLoss es 1.079361 en
validación y 1.086791 en prueba, contra 0.989547 y 1.033076 de M0
([capítulo 9](09_evaluacion_y_validacion.md) y
[11.8](11_codigo_analisis_notebook.md#118--7-referencia-simple-y-diagnóstico-celdas-1718)).

```python
lambda_base_home = float(train["home_goals"].mean())   # 1.561413
lambda_base_away = float(train["away_goals"].mean())   # 1.311545
```

```r
lh0 <- mean(entrenamiento$home_goals); la0 <- mean(entrenamiento$away_goals)   # 1.561413 · 1.311545
```

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

Las alternativas al logaritmo, y una comprobación con el enlace identidad, están en [6.9](#69-decisiones-y-alternativas).

## 6.3 Las dos ecuaciones del proyecto

Se estiman **dos regresiones separadas**: una para los goles del local y otra para los del visitante.

**M0, el modelo base (3 variables por ecuación):**

$$
\log \hat\lambda_{\text{local}} = 0.0433 + 0.6283\,D + 0.1678\,GF_{\text{local}} + 0.0778\,GA_{\text{visitante}}
$$

$$
\log \hat\lambda_{\text{visitante}} = 0.0264 - 0.6854\,D + 0.1079\,GF_{\text{visitante}} + 0.0281\,GA_{\text{local}}
$$

donde $D$ = (Elo local − Elo visitante)/400, $GF$ = goles a favor ajustados del equipo y $GA$ =
goles en contra ajustados del rival.

**¿Por qué dos ecuaciones y no una con una variable "es local"?** Porque así cada lado **puede** tener
sus propios coeficientes. Las estimaciones son parecidas, pero no idénticas: la diferencia de Elo pesa
un poco más para el visitante (−0.685) que para el local (+0.628), y los goles a favor pesan más para el
local (0.168 contra 0.108). La ventaja de local aparece en los interceptos (0.043 contra 0.026) y, sobre
todo, en esos coeficientes. Ojo: con estos datos las diferencias entre lados **no son estadísticamente
distinguibles** (ver el modelo apilado en [6.9](#69-decisiones-y-alternativas)); la razón para dos
ecuaciones es la flexibilidad y la lectura por lado, no una ventaja de pronóstico comprobada.

**Ejemplo de cálculo:** dos equipos idénticos (D = 0) cuyos goles a favor y en contra son el promedio de
los equipos en el entrenamiento, (1.5614 + 1.3115) / 2 = 1.4365:

- $\log \hat\lambda_L = 0.0433 + 0.1678(1.4365) + 0.0778(1.4365) = 0.396 \Rightarrow \hat\lambda_L = e^{0.396} \approx 1.486$
- $\log \hat\lambda_V = 0.0264 + 0.1079(1.4365) + 0.0281(1.4365) = 0.222 \Rightarrow \hat\lambda_V = e^{0.222} \approx 1.248$

Aun entre iguales, el local espera ≈ 0.24 goles más (1.486 contra 1.248, una razón de **1.19**): **esa
es la ventaja de jugar en casa** que aprendió el modelo. Con esas λ, el modelo da 42.7 % de victoria
local, 25.4 % de empate y 31.9 % de victoria visitante entre dos equipos iguales. La razón 1.19 es la
misma que hay en los datos de entrenamiento (1.5614 / 1.3115 = 1.19). En logaritmos se reparte así:
log(λ<sub>L</sub> / λ<sub>V</sub>) = 0.017 (interceptos) + 0.086 (goles a favor) + 0.071 (goles en contra)
= 0.174, y e<sup>0.174</sup> = 1.19.

*(El cálculo con el promedio de 1.4365 goles y el reparto del logaritmo son de esta guía, hechos con los
coeficientes del notebook. Con el promedio histórico de la liga, 1.36 goles, saldría λ<sub>L</sub> = 1.458
y λ<sub>V</sub> = 1.235, razón 1.18.)*

## 6.4 Cómo interpretar los coeficientes

Como $\lambda = e^{\dots}$, **aumentar una variable en 1 multiplica λ por $e^{\beta}$**:

| Coeficiente (M0) | $e^{\beta}$ | Lectura |
|---|---|---|
| $D$ en la ecuación del local: 0.6283 | 1.874 por cada 400 puntos | +400 puntos de Elo → × 1.87 los goles del local (el ejemplo del reporte: $e^{0.6283} \approx 1.87$); +100 puntos → × $e^{0.157}$ = **1.170**, es decir +17.0 % |
| $D$ en la del visitante: −0.6854 | 0.504 por cada 400 puntos | +100 puntos de Elo del local → × 0.843 (−15.7 %) goles del visitante |
| $GF_{\text{local}}$: 0.1678 | 1.183 | Cada gol más por partido en su promedio ajustado → +18.3 % goles esperados |
| $GA_{\text{visitante}}$: 0.0778 | 1.081 | Cada gol más que recibe el rival por partido → +8.1 % |
| $GF_{\text{visitante}}$: 0.1079 | 1.114 | Cada gol más por partido del visitante → +11.4 % goles del visitante |
| $GA_{\text{local}}$: 0.0281 | 1.028 | Cada gol más que recibe el local por partido → +2.8 % (no significativo, p = 0.506) |

Para dar una idea de las escalas: subir un gol por partido el promedio de goles a favor del local pesa lo
mismo que ≈ 107 puntos de Elo (0.1678 / 0.6283 × 400).

**Para comparar variables con escalas distintas** (Elo contra goles contra tiros), el tablero
muestra **efectos estandarizados**: el cambio en goles esperados al subir **una desviación
estándar** cada variable, $e^{\beta \cdot DE} - 1$:

| Variable (M0) | Goles del local | Goles del visitante |
|---|---|---|
| Diferencia de Elo | **+26.7 %** (IC 95 %: +21.0 a +32.8) | **−22.8 %** (−26.6 a −18.7) |
| Goles a favor del propio equipo | +10.7 % (+6.3 a +15.4) | +6.9 % (+2.2 a +11.9) |
| Goles en contra del rival | +4.0 % (+0.0 a +8.1), **en el límite del 5 %** (p = 0.0498) | +1.5 % (−2.8 a +5.9), **no significativo al 5 %** (p = 0.506) |

(Una desviación estándar de la diferencia de Elo en el entrenamiento son 150.8 puntos.)

Conclusión: **la diferencia de Elo es la variable que más pesa**.

**Lo que cambió al calibrar K y k.** Con la configuración inicial (K = 30 y k = 10) el coeficiente del Elo
en el local era 0.408 y el de los goles a favor 0.334; con la calibrada (K = 15 y k = 0) el Elo pesa 0.628
y los goles a favor 0.168, y los goles en contra del rival pasaron de significativos (p = 0.008) a apenas
significativos (p = 0.0498). Lectura: con K = 15 el Elo resume más de la fuerza del equipo y los promedios
de goles de la temporada aportan menos. Una explicación razonable (no comprobada): con k = 0 esos
promedios no se mezclan con la temporada anterior y son más ruidosos en las primeras jornadas, así que
reciben menos peso ([capítulo 5](05_promedios_ajustados_y_forma.md)).

**¿Se estorban las variables entre sí? Correlaciones y VIF de M0.** Si dos variables se parecen mucho, el
modelo no puede separar bien el efecto de cada una (multicolinealidad). El **VIF** de una variable es
$1/(1 - R^2)$, donde $R^2$ sale de regresar esa variable contra las demás: vale 1 si no se traslapa con
ellas, y se considera alto de 5 a 10. En M0 (reporte §7.2; notebook §7):

| Ecuación | Correlaciones | VIF |
|---|---|---|
| Local | Elo–$GF$ 0.503 · Elo–$GA$ del rival 0.372 · $GF$–$GA$ 0.011 | Elo 1.632 · $GF$ 1.407 · $GA$ 1.219 |
| Visitante | Elo–$GF$ −0.497 · Elo–$GA$ del rival −0.371 · $GF$–$GA$ −0.038 | Elo 1.665 · $GF$ 1.438 · $GA$ 1.255 |

Todos los VIF son menores que 2: **no hay redundancia problemática**, así que los coeficientes de M0 son
estables y se pueden interpretar. El Elo se correlaciona moderadamente con los goles a favor y en contra
(los equipos fuertes anotan más y reciben menos). En la ecuación del visitante los signos salen negativos
porque $D$ = (Elo local − Elo visitante)/400: un visitante fuerte tiene $D$ negativa y muchos goles a
favor. La colinealidad sí aparece en M4 (VIF máximo 5.56, en los tiros a puerta del local; ver
[9.10](09_evaluacion_y_validacion.md#910-multicolinealidad-y-vif)). El diagnóstico describe la relación
entre los predictores; no mide la calidad del pronóstico.

```python
from statsmodels.stats.outliers_influence import variance_inflation_factor
columnas = ["elo_diff", "gf_home", "ga_away"]
train[columnas].corr()                                                         # correlaciones
X = preparar_X(train, columnas)                                                # incluye la constante
[variance_inflation_factor(X.to_numpy(), i) for i in range(1, X.shape[1])]     # 1.632, 1.407, 1.219
```

```r
cor(entrenamiento[, c("elo_diff", "gf_home", "ga_away")])                      # correlaciones
vif_manual(entrenamiento, c("elo_diff", "gf_home", "ga_away"))                 # 1.632 1.407 1.219 (vif_manual: ver 9.10)
```

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

**Python (statsmodels), del notebook (§7), ecuación del local:**

```text
                 coef    std err          z      P>|z|      [0.025      0.975]
const          0.0433      0.088      0.494      0.621      -0.128       0.215
elo_diff       0.6283      0.063      9.994      0.000       0.505       0.751
gf_home        0.1678      0.035      4.848      0.000       0.100       0.236
ga_away        0.0778      0.040      1.962      0.050    7.24e-05       0.155
Log-Likelihood: -2895.0   Deviance: 2136.3   Pearson chi2: 1.89e+03   No. Iterations: 5
```

Y la del visitante:

```text
                 coef    std err          z      P>|z|      [0.025      0.975]
const          0.0264      0.095      0.277      0.781      -0.160       0.213
elo_diff      -0.6854      0.069     -9.893      0.000      -0.821      -0.550
gf_away        0.1079      0.037      2.887      0.004       0.035       0.181
ga_home        0.0281      0.042      0.664      0.506      -0.055       0.111
Log-Likelihood: -2743.8   Deviance: 2244.2   Pearson chi2: 1.96e+03   No. Iterations: 5
```

**R (`summary(glm(...))`), de `equivalencias_R/02_modelo_poisson.R` (ecuación del local):**

```text
                  Estimate Std. Error   z value     Pr(>|z|)
(Intercept)     0.04328841 0.08755085 0.4944374 6.209973e-01
I(elo_diff/400) 0.62825715 0.06286197 9.9942325 1.615337e-23
gf_home         0.16778915 0.03460947 4.8480703 1.246682e-06
ga_away         0.07777111 0.03964291 1.9617913 4.978679e-02
```

**Lectura:** el Elo domina (z ≈ 10 en las dos ecuaciones); los goles a favor propios son significativos; los
goles en contra del rival quedan **en el límite** en la ecuación del local (p = 0.0498; el intervalo de
95 % empieza en 7.24e-05, casi cero) y **no son significativos** en la del visitante (p = 0.506). Las
constantes tampoco son significativas (p = 0.621 y 0.781): son log λ cuando todas las variables valen cero,
un caso sin sentido práctico.

| statsmodels | R | Qué es |
|---|---|---|
| `coef` | `Estimate` | El coeficiente β |
| `std err` | `Std. Error` | Su incertidumbre |
| `z` | `z value` | coef / error estándar |
| `P>\|z\|` | `Pr(>\|z\|)` | Valor p: si es menor a 0.05, el coeficiente es distinto de cero al 5 % |
| `[0.025 0.975]` | `confint.default(m)` | Intervalo de confianza de 95 % |
| `Deviance` | `Residual deviance` | Qué tan lejos está el modelo de un ajuste perfecto |
| `Pearson chi2` | `sum(residuals(m, "pearson")^2)` | Base de la dispersión |

**Dispersión de Pearson** = Pearson χ² / grados de libertad = 1,886 / 1,893 = **0.996** (local) y
1,962 / 1,893 = **1.036** (visitante). Si fuera mucho mayor que 1 (sobredispersión), convendría una
regresión binomial negativa (`MASS::glm.nb()` en R) o cuasi-Poisson (`family = quasipoisson`); aquí no
hace falta (comprobación en [6.9](#69-decisiones-y-alternativas)).

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
| **M0** base | 3 | Elo + goles de la temporada |
| M1 forma | 5 | + goles recientes a favor del equipo y en contra del rival |
| M2 tiros | 5 | + tiros recientes realizados y concedidos por el rival |
| M3 tiros a puerta | 5 | + tiros a puerta recientes |
| M4 completo | 9 | todo lo anterior |

Comparar modelos **anidados** (M1, M2 y M3 contienen a M0, y M4 contiene a todos) permite ver si cada
bloque de variables aporta información **fuera de muestra**. Los cinco se entrenan con los mismos 1,897
partidos y se evalúan con el LogLoss 1X2 (menor es mejor):

| LogLoss | M0 | M1 | M2 | M3 | M4 |
|---|---|---|---|---|---|
| Validación (380 partidos) | 0.989547 | 0.987603 | 0.980718 | 0.982319 | **0.978612** |
| Prueba (419 partidos) | **1.033076** | 1.034699 | 1.037331 | 1.033868 | 1.036739 |

Resultado: en validación todos mejoraron un poco a M0 (de −0.0019 con M1 a −0.0109 con M4); en prueba
ninguno lo hizo (de +0.0008 con M3 a +0.0043 con M2); ver [capítulo 12](12_resultados.md). Con el MAE de
goles el orden cambia: el menor en validación es el de M0 (0.918332) y en prueba el de M3 (0.894173).

## 6.9 Decisiones y alternativas

Cada recuadro justifica una decisión de este capítulo: qué se hizo, qué otras opciones había y por qué ésta.
Lo que se **probó** de verdad en el proyecto es poco (las cinco especificaciones M0–M4, la referencia simple y
el mercado); lo demás es **razonado** y así hay que decirlo. Las comprobaciones marcadas como *de la guía*
se hicieron **después de la entrega**, con el código y los datos del proyecto, para saber si una conclusión
depende de la decisión: **no están en el notebook, el tablero ni el reporte**, y sólo se mencionan si
preguntan, aclarando que son posteriores. Todas las decisiones del proyecto están reunidas en el
[capítulo 19](19_decisiones_y_alternativas.md) (D1, D19, D22, D24, D25 y D27 son las de este capítulo).

> **Decisión:** modelar los goles de cada equipo con un GLM de Poisson (enlace logarítmico, máxima
> verosimilitud): `sm.GLM(goles, X, family=sm.families.Poisson()).fit()`; en R, `glm(goles ~ …, family = poisson)`,
> con los mismos coeficientes.
>
> **Alternativas:** (a) **binomial negativa** (`MASS::glm.nb()` en R) — a favor: admite varianza mayor que la
> media; en contra: no hace falta si la dispersión es ≈ 1 y agrega un parámetro; (b) **Poisson con ceros
> inflados** (`pscl::zeroinfl()`) — a favor: captura un exceso de 0–0 o de equipos que no anotan; en contra:
> la dispersión ≈ 1 no sugiere ese exceso y agrega una ecuación; (c) **Poisson bivariada** (Karlis y
> Ntzoufras, 2003) — a favor: modela la dependencia entre los goles de los dos equipos; en contra: sólo
> admite dependencia positiva y es más compleja de estimar; (d) **Dixon–Coles** (1997) — a favor: corrige las
> probabilidades de 0–0, 1–0, 0–1 y 1–1; en contra: su parámetro ρ se estima junto con las dos ecuaciones y
> no viene en `statsmodels` (más en el [capítulo 7](07_de_goles_a_probabilidades.md)); (e) **aprendizaje
> automático** (XGBoost, bosques aleatorios, redes) — a favor: captura relaciones no lineales e
> interacciones; en contra: con 1,897 partidos de entrenamiento el sobreajuste es alto y se pierde la lectura
> e<sup>β</sup>. Ninguna de las cinco se probó en el proyecto; de (a) a (d) hay comprobaciones posteriores
> (abajo).
>
> **Por qué ésta:** los goles son conteos no negativos; el enlace logarítmico garantiza λ > 0 y da efectos
> multiplicativos; es el estándar para goles de fútbol (Maher, 1982; Loukas et al., 2024); su supuesto central
> se puede revisar con los datos (la dispersión) y tiene equivalente directo en R. La propia evidencia del
> proyecto va contra más flexibilidad: M4, con 9 variables, no generalizó mejor que M0, con 3.
>
> **Evidencia en el proyecto:** dispersión de Pearson de M0: 0.996 (local) y 1.036 (visitante), es decir,
> ≈ 1 (tablero). Sin variables sí hay sobredispersión leve (6.1), pero es la que produce mezclar partidos con
> λ distintas. *Comprobaciones de la guía:* la binomial negativa colapsa a Poisson en el local (α ≈ 0) y en el
> visitante estima α = 0.028, una mejora de log-verosimilitud de 0.68 (p = 0.24) con peor AIC; los ceros
> inflados dan una probabilidad de cero extra ≈ 0 en el local y 0.024 en el visitante (p = 0.18); en
> entrenamiento M0 espera 23.5 % de ceros del local y 29.0 % del visitante, y ocurrieron 23.1 % y 29.9 %; la
> correlación entre los residuos de Pearson de las dos ecuaciones es −0.061 en entrenamiento y +0.004 en
> validación + prueba, y el ρ de Dixon–Coles sale ≈ −0.008 (capítulo 7).
>
> **Si preguntan:** "Porque los goles son conteos y la regresión de Poisson da coeficientes interpretables.
> Revisamos su supuesto clave: la dispersión de Pearson es 0.996 y 1.036, prácticamente 1, así que la
> binomial negativa no hacía falta; después comprobamos que sale igual. Aprendizaje automático no lo
> probamos: con 1,897 partidos, y viendo que 9 variables ya no generalizaban mejor que 3, no esperábamos
> ganancia."

> **Decisión:** estimar dos GLM separados, uno para los goles del local y otro para los del visitante
> (`entrenar_modelo()`), cada uno con su intercepto y sus coeficientes.
>
> **Alternativas:** (a) **un solo modelo "apilado"**: cada partido aporta dos filas (los goles de cada
> equipo, con la diferencia de Elo en signo contrario en la fila del visitante) y un indicador `local` marca
> la ventaja — a favor: 5 parámetros en vez de 8 y un coeficiente de localía que se lee directo
> (e<sup>γ</sup>); en contra: obliga a que el Elo, los goles a favor y los goles en contra pesen igual de
> local y de visitante; (b) **modelar la diferencia de goles** (una regresión lineal o una Skellam con
> covariables) — a favor: un solo modelo; en contra: se pierden los goles de cada equipo y los marcadores;
> (c) **apilado con interacciones `local × variable`** — a favor: deja que cada variable pese distinto por
> lado; en contra: es el mismo modelo de dos ecuaciones con otra escritura. Ninguna se probó en el proyecto;
> (a) se comprobó después.
>
> **Por qué ésta:** deja que los datos digan si ser local cambia el efecto de cada variable; la localía queda
> en los interceptos y en esos coeficientes (por eso el Elo no necesita una ventaja de localía en su fórmula,
> [capítulo 4](04_elo.md)); da una λ por lado con su propia lectura; y es lo que describe el reporte (§5.1).
>
> **Evidencia en el proyecto:** los coeficientes de M0 difieren entre lados: Elo/400 0.6283 contra −0.6854;
> goles a favor propios 0.1678 contra 0.1079; goles en contra del rival 0.0778 (p = 0.0498, en el límite)
> contra 0.0281 (p = 0.506). *Comprobación de la guía:* el modelo apilado (Elo 0.655, goles a favor 0.140,
> goles en contra 0.055, localía γ = 0.180, o sea e<sup>γ</sup> = 1.20) tiene una log-verosimilitud de
> −5639.69 contra −5638.78 de las dos ecuaciones (prueba de razón de verosimilitudes con los 3 parámetros de
> más: p = 0.61), mejor AIC (11289.4 contra 11293.6) y un LogLoss prácticamente igual: 0.989716 contra 0.989547
> en validación y 1.031688 contra 1.033076 en prueba. Con estos datos las dos formulaciones **no se
> distinguen**: la ventaja de dos ecuaciones es de flexibilidad y de lectura por lado, no de pronóstico.
>
> **Si preguntan:** "Con dos ecuaciones cada variable puede pesar distinto de local y de visitante, y la
> ventaja de local sale de los datos. Después comprobamos que un modelo con un solo indicador de localía
> predice casi igual (LogLoss 0.9897 contra 0.9895 en validación), así que no es una diferencia decisiva;
> dejamos dos ecuaciones por claridad y porque así viene en el reporte."

> **Decisión:** enlace logarítmico, log λ = Xβ (el de `family=sm.families.Poisson()` por defecto; en R,
> `poisson(link = "log")`).
>
> **Alternativas:** (a) **regresión lineal sobre los goles** (mínimos cuadrados) — a favor: simple y
> conocida; en contra: puede predecir goles negativos, supone varianza constante y trata los goles como
> continuos; (b) **Poisson con enlace identidad**, λ = Xβ — a favor: efectos aditivos ("+0.2 goles") fáciles
> de leer; en contra: no garantiza λ > 0, es más delicado de ajustar (en R hay que dar valores iniciales con
> `start`) y el efecto en goles sería el mismo sin importar el rival; (c) **otros enlaces** (raíz cuadrada) —
> a favor: ninguno claro aquí; en contra: sin una interpretación sencilla. Ninguna se probó en el proyecto;
> (b) se comprobó después.
>
> **Por qué ésta:** λ > 0 por construcción; los efectos son multiplicativos (+X % de goles, como se piensa
> en fútbol); es el enlace canónico de Poisson, con el que IRLS converge sin problemas (5 iteraciones); y es el
> que usa el reporte.
>
> **Evidencia en el proyecto:** ninguna directa (no se probó otro enlace). *Comprobación de la guía:* con
> enlace identidad el modelo converge (7 y 6 iteraciones) y no da λ negativas en validación ni en prueba
> (mínimo 0.23), pero ajusta peor en entrenamiento (log-verosimilitud −2896.84 contra −2894.99 en el local y
> −2747.68 contra −2743.79 en el visitante) y su LogLoss es casi el mismo: 0.990356 contra 0.989547 en
> validación y 1.032868 contra 1.033076 en prueba. Es decir, el logaritmo se justifica por λ > 0,
> interpretación y ajuste, no porque el otro enlace falle aquí.
>
> **Si preguntan:** "Usamos el logaritmo para que los goles esperados nunca sean negativos y para que los
> efectos sean multiplicativos: un equipo con más Elo anota un cierto porcentaje más, no una cantidad fija de
> goles. Después probamos el enlace identidad: no se rompe, pero ajusta peor y pronostica casi igual."

> **Decisión:** en cada ecuación entran la diferencia de Elo, los goles a favor del propio equipo y los goles
> en contra del rival (`gf_home` y `ga_away`; en la del visitante, `gf_away` y `ga_home`), calculados con
> partidos anteriores; no hay un parámetro propio por equipo.
>
> **Alternativas:** (a) **efectos fijos de ataque y defensa por equipo** (Maher, 1982), con una ventaja de
> local común — a favor: es el modelo clásico y ajusta por la fuerza de cada rival; en contra: con 26 equipos
> en el entrenamiento son 52 parámetros fijos, los equipos sin partidos en el entrenamiento no tienen
> parámetro (Ipswich en validación; Coventry, Hull, Ipswich y Sunderland en prueba) y un efecto fijo no sigue
> la evolución de un equipo durante cinco temporadas; (b) **efectos que cambian con el tiempo** (Dixon y
> Coles, 1997, con pesos que decaen) — a favor: sigue a los equipos; en contra: otro modelo, con más
> parámetros; (c) **promedios separados de local y de visitante por equipo** — a favor: capta equipos que
> rinden distinto en casa; en contra: la mitad de partidos por promedio, más ruido. Ninguna se probó en el
> proyecto; (a) se comprobó después.
>
> **Por qué ésta:** las variables se recalculan antes de cada partido (se actualizan solas, sin reestimar
> nada), sirven para cualquier equipo con historia, incluidos los ascendidos (el Elo existe desde 2001/02), y
> bastan 4 coeficientes por ecuación.
>
> **Evidencia en el proyecto:** las variables de M0 apenas se traslapan (VIF máximo 1.665) y los coeficientes
> son estables (z del Elo ≈ 10). *Comprobación de la guía:* un modelo de Maher con los mismos 1,897 partidos
> (52 parámetros; e<sup>γ</sup> = 1.19; mejores ataques: Man City, Liverpool y Arsenal) ajusta mejor el
> entrenamiento (log-verosimilitud −5598.1 contra −5638.8 de M0) pero tiene peor AIC (11300.3 contra
> 11293.6) y **pronostica mucho peor**: LogLoss 1.0547 contra 0.9895 en validación y 1.0566 contra 1.0331 en
> prueba. Tampoco gana si se quitan los partidos con equipos nuevos (1.0565 contra 0.9926 en validación;
> 1.0576 contra 1.0217 en prueba) ni si se reestima sólo con las últimas dos temporadas (1.0238 y 1.0444) o
> con la última (1.0475 y 1.0395).
>
> **Si preguntan:** "El modelo de Maher estima un ataque y una defensa por equipo: unos 50 parámetros fijos,
> y los ascendidos que no estaban en el entrenamiento, como Ipswich o Coventry, no tendrían parámetro.
> Nuestras variables se recalculan antes de cada partido, con 4 coeficientes por ecuación. Después lo
> comprobamos: el modelo de Maher ajusta mejor el pasado pero pronostica peor el futuro (LogLoss 1.055
> contra 0.990 en validación)."

> **Decisión:** cinco especificaciones anidadas: M0 (diferencia de Elo + goles de la temporada: 3 variables
> por ecuación) y cuatro ampliaciones: M1 (+ forma reciente: 5), M2 (+ tiros: 5), M3 (+ tiros a puerta: 5) y
> M4 (todo: 9).
>
> **Alternativas:** (a) sólo M4 — a favor: un solo modelo, el más completo; en contra: no dice qué bloque
> aporta; (b) selección automática de variables (*stepwise*, LASSO) — a favor: elige sola; en contra: menos
> interpretable por bloques y fácil de sobreajustar; (c) todas las combinaciones de bloques (2³ = 8) — a
> favor: exhaustivo; en contra: más modelos que comparar con sólo 380 partidos de validación. *Probada:* M0–M4
> (las cinco se entrenaron y se evaluaron); (a) sólo como parte de las cinco; (b) y (c) no.
>
> **Por qué ésta:** cada bloque responde una pregunta concreta ("¿la forma reciente agrega algo a lo que ya
> dicen el Elo y los promedios?"); es el diseño incremental de la hipótesis del reporte.
>
> **Evidencia en el proyecto:** la tabla de 6.8: en validación todos los bloques mejoran a M0 (M4 es el mejor,
> 0.978612); en prueba ninguno lo hace (M0 es el mejor, 1.033076).
>
> **Si preguntan:** "Agregamos un bloque a la vez para medir su aporte. En validación ayudaron un poco; en
> prueba ninguno superó al modelo base, así que nos quedamos con M0."

> **Decisión:** `preparar_X()` divide la diferencia de Elo entre 400 antes de ajustar el GLM (en R,
> `I(elo_diff / 400)`).
>
> **Alternativas:** (a) **puntos crudos** — a favor: sin transformar; en contra: el coeficiente queda
> diminuto (0.00157 por punto en el local) y difícil de leer, aunque el pronóstico sería idéntico; (b)
> **estandarizar** (restar la media y dividir entre la desviación estándar, 150.8 puntos) — a favor: los
> coeficientes son comparables entre variables; en contra: la unidad depende de la muestra de entrenamiento
> (para comparar variables, el tablero ya usa el efecto de una desviación estándar); (c) **usar la
> probabilidad Elo en lugar de la diferencia** — otra forma funcional; no se probó.
>
> **Por qué ésta:** multiplicar o dividir una variable por una constante no cambia el ajuste ni las
> predicciones del GLM, sólo la unidad del coeficiente; "por cada 400 puntos" es la unidad natural del Elo
> (la escala de su fórmula).
>
> **Evidencia en el proyecto:** el coeficiente es 0.6283 por cada 400 puntos (e<sup>0.6283</sup> ≈ 1.87, reporte
> §7.1) en lugar de 0.00157 por punto.
>
> **Si preguntan:** "Dividir entre 400 no cambia el modelo, sólo la unidad del coeficiente: 0.628 por cada 400
> puntos en lugar de 0.0016 por punto. Para comparar variables, el tablero usa el efecto de una desviación
> estándar."

**Las comprobaciones de la guía, en Python y en R.** Python es lo que se ejecutó; el código R es **ilustrativo**
(sus cifras se reprodujeron en R con los mismos resultados):

```python
# Binomial negativa y ceros inflados (ecuación del visitante); X = preparar_X(train, columnas_away)
nb   = sm.NegativeBinomial(y, X).fit()                      # α = nb.params["alpha"]
zip_ = sm.ZeroInflatedPoisson(y, X, exog_infl=np.ones((len(y), 1)), inflation="logit").fit()

# Modelo apilado: dos filas por partido; el Elo cambia de signo en la fila del visitante
apilado = sm.GLM(larga["y"], sm.add_constant(larga[["elo", "gf", "ga", "local"]]),
                 family=sm.families.Poisson()).fit()

# Maher: efectos fijos de ataque y de defensa (suma cero) y localía
maher = smf.glm("g ~ local + C(ataca, Sum) + C(defiende, Sum)", data=larga_equipos,
                family=sm.families.Poisson()).fit()
```

```r
# R (ilustrativo)
library(MASS); library(pscl)
nb  <- glm.nb(away_goals ~ I(elo_diff / 400) + gf_away + ga_home, data = entrenamiento)    # α = 1 / nb$theta
zip <- zeroinfl(away_goals ~ I(elo_diff / 400) + gf_away + ga_home | 1, data = entrenamiento)

apilar <- function(d) rbind(                                  # dos filas por partido
  data.frame(g = d$home_goals, elo =  d$elo_diff / 400, gf = d$gf_home, ga = d$ga_away, local = 1),
  data.frame(g = d$away_goals, elo = -d$elo_diff / 400, gf = d$gf_away, ga = d$ga_home, local = 0))
apilado <- glm(g ~ elo + gf + ga + local, family = poisson, data = apilar(entrenamiento))

id_local <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away,        # enlace identidad
                family = poisson(link = "identity"), data = entrenamiento,
                start = coef(lm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away, data = entrenamiento)))

larga_equipos <- function(d) data.frame(g = c(d$home_goals, d$away_goals),             # Maher
  ataca = factor(c(d$HomeTeam, d$AwayTeam)), defiende = factor(c(d$AwayTeam, d$HomeTeam)),
  local = rep(c(1, 0), each = nrow(d)))
maher <- glm(g ~ local + ataca + defiende, family = poisson, data = larga_equipos(entrenamiento),
             contrasts = list(ataca = "contr.sum", defiende = "contr.sum"))
```

## 6.10 Preguntas rápidas

<details><summary>¿Por qué no una regresión lineal para los goles?</summary>

Porque los goles son conteos no negativos, con varianza que crece con la media; una regresión
lineal podría predecir goles negativos y supone varianza constante. Poisson respeta la naturaleza
del dato.
</details>

<details><summary>¿Qué significa que un coeficiente no sea significativo?</summary>

Que su intervalo de confianza incluye el cero: con estos datos no podemos distinguir su efecto de
nada. En M0 pasa con los goles en contra del local en la ecuación del visitante (p = 0.506); los goles
en contra del visitante en la ecuación del local quedan en el límite (p = 0.0498). En M4 pasa con 11 de
los 18 coeficientes (sin contar las constantes), en parte por la multicolinealidad.
</details>

<details><summary>¿Qué alternativas al modelo de Poisson existen?</summary>

Binomial negativa (si hay sobredispersión; aquí la dispersión es 0.996 y 1.036), Poisson con ceros
inflados, Poisson bivariada o Dixon–Coles (para modelar la dependencia entre goles y los empates),
logística multinomial u ordinal (modelan el 1X2 directamente) y modelos de aprendizaje automático
(árboles, *boosting*). Ninguna se probó en el proyecto; en [6.9](#69-decisiones-y-alternativas) hay
comprobaciones posteriores de las primeras.
</details>

<details><summary>¿De dónde sale la ventaja de jugar en casa en el modelo?</summary>

No hay una variable "es local": sale de tener una ecuación para cada lado. Con dos equipos idénticos
(D = 0, 1.4365 goles a favor y en contra), M0 da 1.486 goles al local y 1.248 al visitante, una razón de
1.19, la misma que hay en los datos de entrenamiento (1.5614 / 1.3115). Se reparte entre los interceptos
(0.043 contra 0.026) y los coeficientes de goles, que son mayores para el local.
</details>

<details><summary>¿Se pueden interpretar los coeficientes de M0?</summary>

Sí: los VIF son menores que 2 (1.632, 1.407 y 1.219 en el local; 1.665, 1.438 y 1.255 en el visitante) y
la mayor correlación entre variables es 0.503 en valor absoluto. La lectura es descriptiva, no causal:
e<sup>0.6283</sup> ≈ 1.87 significa que, con lo demás igual, 400 puntos más de diferencia de Elo se asocian con
1.87 veces los goles esperados del local.
</details>

<details><summary>¿Qué es la "referencia simple" y para qué sirve?</summary>

Una Poisson con la misma λ para todos los partidos, las medias de goles del entrenamiento (1.561413 y
1.311545), que da 43.24 % / 24.69 % / 32.07 % a cualquier partido. Sirve para medir cuánto aportan las
variables: su LogLoss es 1.0794 en validación y 1.0868 en prueba, contra 0.9895 y 1.0331 de M0. El tablero
la llama "referencia ingenua".
</details>

<details><summary>¿Por qué el Elo se divide entre 400?</summary>

Es la unidad natural del Elo (la escala de su fórmula) y no cambia el modelo, sólo la unidad del
coeficiente: 0.628 por cada 400 puntos en lugar de 0.0016 por punto.
</details>
