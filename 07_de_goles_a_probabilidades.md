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

Con información al 14-sep-2026, M0 da $\hat\lambda_L = 1.57$ y $\hat\lambda_V = 1.20$. La matriz
de marcadores, en %, con filas = goles de Arsenal y columnas = goles de Man City:

| Arsenal \ City | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| **0** | 6.3 | 7.5 | 4.5 | 1.8 | 0.5 | 0.1 |
| **1** | 9.8 | **11.8** | 7.1 | 2.9 | 0.9 | 0.2 |
| **2** | 7.7 | 9.3 | 5.6 | 2.2 | 0.7 | 0.2 |
| **3** | 4.0 | 4.8 | 2.9 | 1.2 | 0.4 | 0.1 |
| **4** | 1.6 | 1.9 | 1.1 | 0.5 | 0.1 | 0.0 |
| **5** | 0.5 | 0.6 | 0.4 | 0.1 | 0.0 | 0.0 |

- **Debajo de la diagonal** (Arsenal anota más): suma ≈ **45.8 %** → P(gana Arsenal).
- **Diagonal** (0–0, 1–1, 2–2, …): suma ≈ **25.0 %** → P(empate).
- **Arriba de la diagonal:** suma ≈ **29.3 %** → P(gana Man City).

Es exactamente lo que muestra el simulador del tablero y el ejemplo del reporte técnico. (Si sumas
a mano la tabla obtendrás un poco menos, por ejemplo 45.2 % en vez de 45.8 %, porque la tabla se
corta en 5 goles; con todos los marcadores posibles las sumas son 45.8 %, 25.0 % y 29.3 %.)

## 7.3 Marcador más probable ≠ resultado más probable

El marcador individual más probable es **1–1** (11.8 %), un empate. Pero el resultado más probable
es **victoria de Arsenal** (45.8 %), porque junta muchos marcadores distintos (1–0, 2–0, 2–1, 3–1…),
mientras que el empate tiene pocas celdas. Si preguntan "¿por qué el modelo dice 1–1 pero da
favorito al local?", esta es la respuesta.

## 7.4 La distribución de Skellam

La **diferencia** de dos Poisson independientes, $G_L - G_V$, sigue una distribución llamada
**Skellam**. En lugar de construir la matriz, se puede calcular directamente:

- P(local) = P(diferencia > 0), P(empate) = P(diferencia = 0), P(visitante) = P(diferencia < 0).

Su fórmula usa funciones de Bessel, pero lo importante es que **da exactamente lo mismo que sumar
la matriz**. El notebook usa la versión de `scipy`; en R, sin paquetes extra, se suma la matriz.

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

**Marcador más probable (sección 9, `predecir_partido`):**

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
- Cortar en 15 goles no cambia nada: la probabilidad de más de 15 goles es del orden de
  $10^{-12}$.

**Alternativa por simulación (no usada en el análisis final):** `wc_predictor.simular_partido()`
simula 30,000 partidos con `np.random.poisson` y cuenta cuántas veces gana cada uno. Da casi lo
mismo, pero con error de simulación. El notebook usa la fórmula exacta (Skellam).

## 7.6 La debilidad del supuesto: los empates

En la realidad, los goles de ambos equipos **no son del todo independientes** (un equipo que va
ganando se defiende, el que pierde arriesga), y los marcadores bajos como 0–0 y 1–1 ocurren algo
más de lo que predice la independencia. Consecuencia en nuestros datos:

| Periodo | P(empate) promedio del modelo M0 | … del mercado | Empates reales |
|---|---|---|---|
| Validación 2024/25 | 21.9 % | 23.0 % | 24.5 % |
| Prueba ago-2025 a sep-2026 | 23.7 % | 24.5 % | 28.2 % |

**El modelo subestima el empate**, y más que el mercado. Es una de las razones por las que pierde
contra las cuotas (ver [capítulo 12](12_resultados.md)). La corrección clásica es el modelo de
**Dixon y Coles (1997)**, que ajusta las probabilidades de 0–0, 1–0, 0–1 y 1–1: es una extensión
natural del proyecto.

> **Dato curioso:** ni el modelo ni el mercado pronostican **nunca** el empate como resultado más
> probable. La probabilidad de empate casi nunca supera a la de ambas victorias, aunque los empates
> ocurren en uno de cada cuatro partidos.

## 7.7 Preguntas rápidas

<details><summary>¿Por qué suponer independencia si no es del todo cierta?</summary>

Porque simplifica mucho el modelo (dos regresiones separadas) y funciona razonablemente bien; es
el punto de partida estándar en la literatura. Su costo principal es subestimar empates, y eso se
reconoce como limitación.
</details>

<details><summary>¿Las tres probabilidades siempre suman 1?</summary>

Sí; el código lo verifica en cada partido y se detiene si no ocurre.
</details>
