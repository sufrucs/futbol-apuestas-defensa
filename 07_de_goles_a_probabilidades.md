# 7. De goles esperados a probabilidades 1X2

[← Poisson](06_poisson_y_regresion.md) · [Índice](README.md) · [Siguiente: cuotas y mercado →](08_cuotas_y_mercado.md)

Las regresiones dan dos números por partido: $\hat\lambda_L$ (goles esperados del local) y
$\hat\lambda_V$ (del visitante). Para comparar contra las cuotas necesitamos **tres
probabilidades**: gana el local, empate y gana el visitante.

## 7.1 El supuesto: independencia condicional

Se supone que, **dados** los goles esperados de cada equipo, lo que anota uno no depende de lo que
anota el otro. Entonces la probabilidad de un marcador exacto es el producto de dos Poisson:

$$
P(G_L = h,\; G_V = a) = \frac{e^{-\lambda_L}\lambda_L^{h}}{h!} \cdot \frac{e^{-\lambda_V}\lambda_V^{a}}{a!}
$$

Y sumando celdas de la "matriz de marcadores":

$$
P(\text{local}) = \sum_{h > a} P(h, a), \qquad P(\text{empate}) = \sum_{h = a} P(h, a), \qquad P(\text{visitante}) = \sum_{h < a} P(h, a)
$$

## 7.2 Ejemplo completo: Arsenal (local) vs Man City

Con la información disponible a mediados de septiembre de 2026 (el último partido de la base es del 14;
el tablero usa el 15 como fecha de corte y el reporte el 20, con el mismo resultado porque no hubo partidos
entre medias), M0 da $\hat\lambda_L = 1.538$ y $\hat\lambda_V = 1.266$.

**De dónde salen esas λ.** Son los coeficientes de M0 ([capítulo 6](06_poisson_y_regresion.md)) aplicados a
las variables de cada equipo en esa fecha. Elo: Arsenal 1,787.12 y Man City 1,779.19, así que
$D$ = (1,787.12 − 1,779.19)/400 = 0.0198. Tras 4 partidos de 2026/27 (con k = 0 los promedios de goles son
sólo los de esos 4 partidos, [capítulo 5](05_promedios_ajustados_y_forma.md)), Arsenal anota 2.00 y recibe
0.25 por partido; Man City anota 2.00 y recibe 0.50.

- Arsenal (local): $\log\hat\lambda_L = 0.0433 + 0.6283(0.0198) + 0.1678(2.00) + 0.0778(0.50) = 0.430 \Rightarrow \hat\lambda_L = e^{0.430} \approx 1.538$
- Man City (visitante): $\log\hat\lambda_V = 0.0264 - 0.6854(0.0198) + 0.1079(2.00) + 0.0281(0.25) = 0.236 \Rightarrow \hat\lambda_V = e^{0.236} \approx 1.266$

(Con los coeficientes redondeados a 4 decimales sale 1.5376 y 1.2656; el reporte, con todos los decimales,
da 1.537597 y 1.265612.)

La matriz de marcadores, en %, con filas = goles de Arsenal y columnas = goles de Man City (los mismos
valores que muestra el simulador del tablero):

| Arsenal \ City | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| **0** | 6.06 | 7.67 | 4.85 | 2.05 | 0.65 | 0.16 |
| **1** | 9.32 | **11.80** | 7.46 | 3.15 | 1.00 | 0.25 |
| **2** | 7.17 | 9.07 | 5.74 | 2.42 | 0.77 | 0.19 |
| **3** | 3.67 | 4.65 | 2.94 | 1.24 | 0.39 | 0.10 |
| **4** | 1.41 | 1.79 | 1.13 | 0.48 | 0.15 | 0.04 |
| **5** | 0.43 | 0.55 | 0.35 | 0.15 | 0.05 | 0.01 |

- **Debajo de la diagonal** (Arsenal anota más): suma ≈ **43.65 %** → P(gana Arsenal).
- **Diagonal** (0–0, 1–1, 2–2, …): suma ≈ **25.00 %** → P(empate).
- **Arriba de la diagonal:** suma ≈ **31.35 %** → P(gana Man City).

Es exactamente lo que muestra el simulador del tablero (43.65 / 25.00 / 31.35 %; marcador más probable
1–1 con 11.80 %) y el ejemplo del reporte técnico, que da cuatro decimales: 43.6462 % / 25.0000 % /
31.3538 %, con 1–1 en 11.7957 %. (Si sumas a mano la tabla obtendrás un poco menos, por ejemplo 43.16 % en
vez de 43.65 %, porque la tabla se corta en 5 goles: faltan 0.70 % de probabilidad en marcadores con 6 o
más goles de algún equipo; con todos los marcadores posibles las sumas son 43.65 %, 25.00 % y 31.35 %.)

Con los papeles al revés (City de local y Arsenal de visitante) el simulador da 41.02 % de victoria de
City, 25.29 % de empate y 33.69 % de victoria de Arsenal: ser local vale unos 10 puntos porcentuales de
probabilidad de ganar (Arsenal pasa de 33.69 % de visitante a 43.65 % de local).

## 7.3 Marcador más probable ≠ resultado más probable

El marcador individual más probable es **1–1** (11.80 %), un empate. Pero el resultado más probable
es **victoria de Arsenal** (43.65 %), porque junta muchos marcadores distintos (1–0, 2–0, 2–1, 3–1…),
mientras que el empate tiene pocas celdas: hay 9 marcadores de victoria local con probabilidad de al menos
1 % y sólo 4 de empate (0–0, 1–1, 2–2 y 3–3), y los tres marcadores de victoria más probables (1–0, 2–1 y
2–0) suman 25.6 %, más que todos los empates juntos (25.0 %). Si preguntan "¿por qué el modelo dice 1–1 pero
da favorito al local?", esta es la respuesta.

## 7.4 La distribución de Skellam

La **diferencia** de dos Poisson independientes, $G_L - G_V$, sigue una distribución llamada
**Skellam**. En lugar de construir la matriz, se puede calcular directamente:

- P(local) = P(diferencia > 0), P(empate) = P(diferencia = 0), P(visitante) = P(diferencia < 0).

Su fórmula usa funciones de Bessel:

$$
P(G_L - G_V = z) = e^{-(\lambda_L + \lambda_V)} \left(\frac{\lambda_L}{\lambda_V}\right)^{z/2} I_{|z|}\!\left(2\sqrt{\lambda_L \lambda_V}\right)
$$

donde $I_k$ es la función de Bessel modificada de primera especie. Lo importante es que **da exactamente lo
mismo que sumar la matriz completa**, sin truncarla. En Arsenal–City el empate es
$e^{-2.8032} \cdot I_0(2.7900) = 0.0606 \times 4.1244 = 0.2500$, igual que la diagonal de la matriz. El
notebook usa la versión de `scipy`; en R, sin paquetes extra, se suma la matriz (con el paquete `VGAM`,
`dskellam()` da la fórmula directa).

## 7.5 El código: Python vs R

**Python (`Analisis.ipynb`, sección 4):**

```python
from scipy.stats import skellam

def probabilidades_1x2(lambda_home, lambda_away):
    lh, la = np.asarray(lambda_home), np.asarray(lambda_away)
    probs = np.column_stack((
        skellam.sf(0, lh, la),    # P(dif > 0): sf = "survival function" = 1 - acumulada
        skellam.pmf(0, lh, la),   # P(dif = 0)
        skellam.cdf(-1, lh, la),  # P(dif <= -1)
    ))
    if not np.isfinite(probs).all() or not np.allclose(probs.sum(axis=1), 1.0, atol=1e-8):
        raise ValueError("Las probabilidades 1X2 no son válidas")
    return probs
```

- `np.column_stack` arma una matriz con 3 columnas (una por resultado) y una fila por partido.
- El `if` es un **control de calidad**: si alguna probabilidad es infinita o las tres no suman 1,
  detiene el programa. Es buena práctica defensiva.

**Marcador más probable (sección 10, `predecir_partido`):**

```python
goles = np.arange(11)                                               # 0, 1, ..., 10
matriz = np.outer(poisson.pmf(goles, lambda_home), poisson.pmf(goles, lambda_away))
gh, ga = np.unravel_index(matriz.argmax(), matriz.shape)            # celda con la mayor probabilidad
```

`np.outer` multiplica cada elemento de un vector por cada elemento del otro (la matriz de
marcadores); `argmax` encuentra la celda más probable.

**R (verificado en `equivalencias_R/02_modelo_poisson.R`):**

```r
prob_1x2 <- function(lambda_local, lambda_visita, max_goles = 15) {
  t(mapply(function(ll, lv) {
    m <- outer(dpois(0:max_goles, ll), dpois(0:max_goles, lv))   # ≈ np.outer
    c(local  = sum(m[lower.tri(m)]),    # celdas con goles del local > goles del visitante
      empate = sum(diag(m)),            # diagonal
      visita = sum(m[upper.tri(m)]))
  }, lambda_local, lambda_visita))
}
which(m == max(m), arr.ind = TRUE) - 1   # marcador más probable (≈ unravel_index(argmax))
```

- `outer(a, b)` ≈ `np.outer(a, b)`; `lower.tri()` / `upper.tri()` seleccionan las celdas debajo y
  arriba de la diagonal; `mapply` aplica la función partido por partido.
- Cortar en 15 goles no cambia nada: en Arsenal–City la probabilidad de más de 15 goles de algún equipo
  es de 1.2 × 10⁻¹¹ y, en el peor partido de validación + prueba, de 1.8 × 10⁻⁶.

**Alternativa por simulación (no usada en el análisis final):** la versión inicial de `wc_predictor.py`
tenía `simular_partido()` (30,000 partidos con `np.random.poisson`, contando cuántas veces gana cada uno,
más prórroga y penales de un Mundial); se eliminó en la versión entregada
([capítulo 10](10_codigo_wc_predictor.md)). Daría casi lo mismo, pero con error de simulación. El notebook
usa la fórmula exacta (Skellam). Simular sería así, y cada semilla da valores un poco distintos (ver el
recuadro sobre Skellam en [7.7](#77-decisiones-y-alternativas)):

```python
rng = np.random.default_rng(2026)
gl, gv = rng.poisson(lh, 30_000), rng.poisson(la, 30_000)       # goles simulados de cada equipo
np.mean(gl > gv), np.mean(gl == gv), np.mean(gl < gv)           # P(local), P(empate), P(visitante)
```

```r
set.seed(2026); gl <- rpois(30000, lL); gv <- rpois(30000, lV)  # ilustrativo
c(mean(gl > gv), mean(gl == gv), mean(gl < gv))
```

## 7.6 La debilidad del supuesto: los empates

En la realidad, los goles de ambos equipos **pueden no ser del todo independientes** (un equipo que va
ganando se defiende, el que pierde arriesga), y en la literatura (Dixon y Coles, 1997) los marcadores
bajos como 0–0 y 1–1 ocurren algo más de lo que predice la independencia. Consecuencia en nuestros datos:

| Periodo | P(empate) promedio del modelo M0 | … del mercado | Empates reales |
|---|---|---|---|
| Validación 2024/25 | 22.8 % | 23.0 % | 24.5 % |
| Prueba ago-2025 a sep-2026 | 23.6 % | 24.5 % | 28.2 % |

**El modelo subestima el empate** en validación y en prueba, y algo más que el mercado. Es una de las
razones por las que pierde contra las cuotas: los empates aportan +0.0078 de los +0.0159 de brecha
M0 − mercado (el resto: +0.0185 en victorias locales y −0.0104 en victorias visitantes; ver
[capítulo 12](12_resultados.md)). La corrección clásica es el modelo de **Dixon y Coles (1997)**, que ajusta
las probabilidades de 0–0, 1–0, 0–1 y 1–1: es una extensión natural del proyecto.

**Un matiz (comprobación de la guía, posterior a la entrega).** En el entrenamiento el modelo **no**
subestima el empate: espera 22.7 % y ocurrió 22.8 %, y los marcadores bajos salen bien (0–0: 5.9 % esperado
contra 5.6 % observado; 1–1: 10.7 % contra 10.9 %). Lo que cambia entre periodos es la **tasa de empates**:
22.8 % en el entrenamiento (2019/20–2023/24), 24.5 % en 2024/25, 27.4 % en 2025/26 (y 14 de 39 partidos,
35.9 %, en lo que va de 2026/27), contra 24.7 % en las 25 temporadas completas. Con las λ de M0 fijas, el
parámetro ρ de Dixon–Coles estimado en el entrenamiento es −0.008, indistinguible de cero (recuadro de
[7.7](#77-decisiones-y-alternativas)). Lectura: lo que falló en validación y en prueba parece ser sobre todo
que hubo **más empates** que en el periodo con el que se entrenó, más que un defecto probado de la
independencia; pero tampoco se puede decir que la independencia quede confirmada para los empates altos.

> **Dato curioso:** ni el modelo ni el mercado pronostican **nunca** el empate como resultado más
> probable (en los 799 partidos de validación y prueba, ni M0 a M4 ni las cuotas de apertura o de cierre).
> La probabilidad de empate más alta que da M0 es 29.2 % y la del mercado de apertura 31.0 %, aunque los
> empates ocurren en uno de cada cuatro partidos.

## 7.7 Decisiones y alternativas

Las comprobaciones marcadas como *de la guía* se hicieron **después de la entrega**, con el código y los
datos del proyecto: **no están en el notebook, el tablero ni el reporte** y sólo se mencionan si preguntan,
aclarando que son posteriores. En el proyecto no se probó ninguna de las alternativas de este capítulo
(todas son razonadas). Las decisiones de todo el proyecto están en el
[capítulo 19](19_decisiones_y_alternativas.md) (D26 es la de este capítulo).

> **Decisión:** suponer que, dadas las variables, los goles del local y del visitante son independientes.
> Con eso la diferencia de goles sigue una Skellam y `probabilidades_1x2()` calcula P(local) = `skellam.sf(0)`,
> P(empate) = `skellam.pmf(0)` y P(visitante) = `skellam.cdf(-1)`, sin ningún parámetro de dependencia.
>
> **Alternativas:** (a) **Dixon–Coles** (1997) — a favor: un parámetro ρ ajusta 0–0, 1–0, 0–1 y 1–1 y ataca
> la debilidad conocida, los empates; en contra: ρ se estima junto con las dos ecuaciones por verosimilitud
> conjunta (ya no son dos GLM separados), no viene en `statsmodels` y las probabilidades 1X2 ya no salen de
> una Skellam simple; (b) **Poisson bivariada** (Karlis y Ntzoufras, 2003), con un componente común a los dos
> equipos — a favor: modela la covarianza directamente; en contra: sólo admite dependencia positiva y es más
> compleja de estimar; (c) **modelar el 1X2 directamente** (logit multinomial u ordinal) — a favor: no supone
> nada sobre los goles; en contra: tira el marcador ([capítulo 6](06_poisson_y_regresion.md)); (d)
> **independencia con Skellam** (lo elegido). Ninguna de las otras se probó en el proyecto; (a) se comprobó
> después en una versión simplificada.
>
> **Por qué ésta:** es la consecuencia directa de dos Poisson independientes y mantiene dos regresiones
> separadas, fáciles de explicar y de reproducir (en R, dos `glm()`); Skellam es exacta e instantánea; el
> reporte (§5.2) y el notebook (§4) lo explican así.
>
> **Evidencia en el proyecto:** el costo del supuesto está a la vista: M0 subestima los empates (23.6 %
> contra 28.2 % reales en prueba; 22.8 % contra 24.5 % en validación), y los empates aportan +0.0078 de la
> brecha con el mercado (+0.0159). *Comprobación de la guía:* con las λ de M0 fijas, el ρ de Dixon–Coles
> estimado en el entrenamiento es −0.008 (error estándar ≈ 0.030; razón de verosimilitudes: p = 0.79), o
> sea, no hay dependencia detectable. Aplicarlo cambia el LogLoss de 0.989547 a 0.989369 en validación y de
> 1.033076 a 1.032628 en prueba, y la P(empate) media de 22.77 % a 22.94 % y de 23.57 % a 23.75 %. Para
> igualar la tasa real de empates harían falta ρ = −0.08 (validación) y −0.21 (prueba), valores que el
> entrenamiento no respalda. La correlación entre los residuos de Pearson de las dos ecuaciones es −0.061 en
> entrenamiento y +0.004 en validación + prueba (y la Poisson bivariada sólo podría representar valores
> positivos).
>
> **Si preguntan:** "Suponer independencia nos permite usar la distribución de Skellam, que da las tres
> probabilidades de forma exacta. Su costo es conocido: subestima los empates (en prueba, 23.6 % contra
> 28.2 %). Después probamos Dixon y Coles en una versión simplificada: su parámetro sale prácticamente cero y
> casi no mejora el LogLoss, así que el problema parece ser que hubo más empates que en el entrenamiento,
> no la independencia. Es la primera extensión que haríamos."

> **Decisión:** las probabilidades 1X2 se calculan **exactas**, con Skellam; la matriz de marcadores (0 a 10
> goles por equipo) sólo se usa para localizar el marcador más probable.
>
> **Alternativas:** (a) **sumar la matriz truncada** (celdas con h > a, h = a y h < a; en R, `lower.tri()`,
> `diag()` y `upper.tri()`) — a favor: transparente y didáctica, sin funciones de Bessel; en contra: ignora
> la cola (hay que elegir un máximo de goles) y las tres sumas ya no dan exactamente 1; (b) **simular**
> partidos (`rng.poisson`) y contar — a favor: flexible, sirve si hay reglas complicadas (prórroga, torneos);
> en contra: ruido aleatorio, más lento y distinto con cada semilla; (c) **Skellam** (lo elegido) — a favor:
> exacta, instantánea, vectorizada para todos los partidos y sin truncar; en contra: sólo da la diferencia
> de goles, no los marcadores (sirve para el 1X2, no para el modal). La versión inicial del código tenía una
> simulación de 30,000 partidos (`simular_partido()`, ya eliminada); el análisis final usa Skellam. No se
> comparó formalmente en el proyecto; la comparación que sigue es de la guía.
>
> **Por qué ésta:** da las tres probabilidades con precisión de máquina, siempre suman 1 (el código lo
> verifica en cada partido) y no agrega ruido a la comparación entre modelos, donde las diferencias de
> LogLoss son de milésimas.
>
> **Evidencia en el proyecto:** el reporte (§5.2) dice que las probabilidades salen de Skellam, no de la matriz
> truncada ni de simulaciones. *Comprobación de la guía* (Arsenal–City): Skellam 43.6462 / 25.0000 /
> 31.3538 %; matriz 0–10: 43.6461 / 25.0000 / 31.3538 %, con 8 × 10⁻⁷ de probabilidad fuera de la matriz (en
> el peor partido de validación + prueba, 1.5 × 10⁻³). Simulación: el error estándar de P(local) es 0.0050
> con 10,000 partidos y 0.0029 con 30,000; con 30,000 y cuatro semillas distintas salió 43.67, 43.92, 43.48
> y 43.73 % (exacto: 43.65 %), y en 1,000 repeticiones de 10,000 partidos P(local) varió entre 42.6 % y
> 44.6 % (95 % de las veces).
>
> **Si preguntan:** "Usamos Skellam porque es la distribución exacta de la diferencia de dos Poisson: da las
> tres probabilidades sin truncar ni simular. Sumar la matriz da prácticamente lo mismo (la diferencia es del
> orden de 10⁻⁷) y simular agrega ruido: con 30,000 partidos, P(local) cambia unas tres décimas de punto de
> una semilla a otra."

> **Decisión:** el 1X2 se pronostica con probabilidades y se evalúa con el LogLoss; el **marcador más
> probable** (la celda máxima de la matriz 0–10, `argmax` en `predecir_partido()`) sólo se muestra como
> ejemplo (reporte §10 y simulador del tablero), advirtiendo que no es lo mismo que el resultado más
> probable.
>
> **Alternativas:** (a) **pronosticar el marcador modal** — a favor: concreto y fácil de comunicar; en
> contra: engañoso, casi siempre sale 1–1 aunque haya un favorito claro, y su probabilidad es baja (11.80 %
> en el ejemplo); (b) **pronosticar el resultado 1X2 más probable** (el "acierto") — a favor: es lo que más
> se entiende; en contra: ignora la confianza (43.65 % no es certeza) y el empate casi nunca es el más
> probable; se reporta como métrica secundaria (aciertos de M0: 53.2 % en validación y 48.0 % en prueba);
> (c) **dar las tres probabilidades completas** — lo que se hace y se evalúa con el LogLoss; (d) **redondear
> los goles esperados** (1.538 y 1.266 → "2–1") — a favor: simple; en contra: incoherente con las
> probabilidades. Ninguna se probó como pronóstico alternativo.
>
> **Por qué ésta:** las probabilidades son lo que se puede comparar con el mercado y evaluar con una regla
> propia; el marcador modal es un dato atractivo para el público (y una pregunta frecuente), pero engaña si
> se confunde con el resultado más probable.
>
> **Evidencia en el proyecto:** en Arsenal–City el marcador más probable es 1–1 (11.80 %), pero gana Arsenal con
> 43.65 %: hay 9 marcadores de victoria local con al menos 1 % y sólo 4 de empate, y 1–0 + 2–1 + 2–0 suman
> 25.6 %, más que todos los empates (25.0 %). *Comprobación de la guía:* en los 799 partidos de validación y
> prueba, el marcador modal de M0 es 1–1 en 537 (67.2 %), 2–0 en 115 y 1–0 en 54: un empate en dos de cada
> tres partidos, mientras que el empate jamás es el resultado más probable.
>
> **Si preguntan:** "El 1–1 es el marcador más probable porque ninguna victoria concreta lo supera, pero las
> victorias de Arsenal juntas suman 43.65 %, contra 25 % del empate. Por eso evaluamos con probabilidades 1X2
> y no con el marcador modal."

**La comprobación de Dixon–Coles, en Python y en R.** Python es lo que se ejecutó; el código R es
**ilustrativo** (se reprodujo en R con el mismo ρ):

```python
def tau(x, y, lam, mu, rho):            # factor de Dixon–Coles: sólo cambia 0–0, 0–1, 1–0 y 1–1
    t = np.ones_like(lam)
    t = np.where((x == 0) & (y == 0), 1 - lam * mu * rho, t)
    t = np.where((x == 0) & (y == 1), 1 + lam * rho, t)
    t = np.where((x == 1) & (y == 0), 1 + mu * rho, t)
    t = np.where((x == 1) & (y == 1), 1 - rho, t)
    return t

# etapa 1: las λ de M0 (lam, mu) ya están estimadas; etapa 2: ρ por máxima verosimilitud en el entrenamiento
res = minimize_scalar(lambda r: -np.log(tau(x, y, lam, mu, r)).sum(), bounds=(lo, hi), method="bounded")
rho = res.x                                              # -0.00802 (lo y hi: límites que mantienen τ > 0)

e = rho * lh * la * np.exp(-(lh + la))                   # masa que se mueve en un partido de validación o prueba
P_dc = P + np.column_stack([e, -2 * e, e])               # P: [local, empate, visitante] de M0; suma sigue siendo 1
```

```r
# R (ilustrativo)
tau <- function(x, y, lam, mu, rho) {
  t <- rep(1, length(x))
  t <- ifelse(x == 0 & y == 0, 1 - lam * mu * rho, t); t <- ifelse(x == 0 & y == 1, 1 + lam * rho, t)
  t <- ifelse(x == 1 & y == 0, 1 + mu * rho, t);       t <- ifelse(x == 1 & y == 1, 1 - rho, t); t
}
opt <- optimize(function(r) -sum(log(tau(x, y, lam, mu, r))), c(lo, hi))     # rho = opt$minimum
e <- opt$minimum * lh * la * exp(-(lh + la)); P_dc <- P + cbind(e, -2 * e, e)
```

## 7.8 Preguntas rápidas

<details><summary>¿Por qué suponer independencia si no es del todo cierta?</summary>

Porque simplifica mucho el modelo (dos regresiones separadas) y funciona razonablemente bien; es
el punto de partida estándar en la literatura. Su costo principal es subestimar empates en validación y
prueba (22.8 % contra 24.5 % y 23.6 % contra 28.2 %), y eso se reconoce como limitación. Una comprobación
posterior con Dixon–Coles dio un parámetro de dependencia casi cero (−0.008), así que parte del problema es
que hubo más empates que en el entrenamiento.
</details>

<details><summary>¿Las tres probabilidades siempre suman 1?</summary>

Sí; el código lo verifica en cada partido y se detiene si no ocurre.
</details>

<details><summary>¿Por qué la matriz llega hasta 10 goles y no hasta infinito?</summary>

La matriz de 0 a 10 sólo sirve para encontrar el marcador más probable. Las probabilidades 1X2 salen de
Skellam, que no trunca. Si se sumara la matriz de 0 a 10, se perdería una probabilidad de 8 × 10⁻⁷ en
Arsenal–City (1.5 × 10⁻³ en el peor partido de validación y prueba).
</details>

<details><summary>¿Qué es lo que Skellam calcula exactamente?</summary>

La distribución de la diferencia de goles (local − visitante) cuando cada equipo anota una Poisson
independiente. P(local) es P(diferencia > 0), P(empate) es P(diferencia = 0) y P(visitante) es
P(diferencia < 0). En Arsenal–City: 43.65 %, 25.00 % y 31.35 %.
</details>
