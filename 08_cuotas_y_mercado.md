# 8. Cuotas, probabilidad implícita y el mercado como referencia

[← De goles a probabilidades](07_de_goles_a_probabilidades.md) · [Índice](README.md) · [Siguiente: evaluación →](09_evaluacion_y_validacion.md)

## 8.1 De la cuota a la probabilidad

Una **cuota decimal** dice cuánto se cobra por cada peso apostado si se acierta, incluyendo el peso
apostado. Si la apuesta fuera "justa" (sin ganancia para la casa), se cumpliría
$\text{cuota} = 1/p$, así que la **probabilidad implícita bruta** es:

$$
q_j = \frac{1}{\text{cuota}_j}, \qquad j \in \{1, X, 2\}
$$

**Ejemplo real:** Leeds vs Newcastle, 14 de septiembre de 2026, cuotas promedio de apertura:

| | Gana Leeds | Empate | Gana Newcastle | Suma |
|---|---|---|---|---|
| Cuota | 2.38 | 3.45 | 2.81 | |
| Probabilidad bruta (1/cuota) | 42.02 % | 28.99 % | 35.59 % | **106.59 %** |
| Probabilidad normalizada | **39.4 %** | **27.2 %** | **33.4 %** | 100 % |

(Leeds ganó 4–1.)

## 8.2 El margen de la casa (*overround*)

Las probabilidades brutas suman **más de 100 %**: en el ejemplo, 106.59 %. Ese exceso (6.59 %) es
el **margen**: la ganancia esperada de la casa de apuestas si recibe apuestas balanceadas. En los
datos:

| Cuotas | Margen promedio |
|---|---|
| Promedio de mercado (`Avg`), validación 2024/25 | 4.49 % |
| Promedio de mercado (`Avg`), prueba | 5.84 % |
| Bet365, 2002/03–2026/27 | 5.42 % |

## 8.3 Normalización

Para comparar contra el modelo, cuyas probabilidades suman exactamente 1, hay que **quitar el
margen**. El proyecto usa la **normalización proporcional**, la más simple:

$$
p_j^{\text{mercado}} = \frac{q_j}{q_1 + q_X + q_2}
$$

Es decir, se divide cada probabilidad bruta entre la suma de las tres. Así se reparte el margen en
proporción a cada probabilidad.

> **Limitación:** en la práctica, las casas suelen cargar **más margen a los resultados poco
> probables** (las sorpresas). Existen métodos más finos para quitar el margen (el de Shin, el
> método de potencias), que corrigen en parte ese sesgo. La normalización proporcional no lo hace;
> el reporte técnico lo reconoce: "no identifica necesariamente las probabilidades subyacentes
> exactas del mercado".

## 8.4 ¿Están bien calibradas las cuotas?

Una probabilidad está **calibrada** si los eventos a los que se les asigna 70 % ocurren el 70 % de
las veces. Para comprobarlo se agrupan todos los pronósticos por rango de probabilidad y se compara
con la frecuencia real (diagrama de calibración). Con Bet365, 2002/03–2026/27 (9,070 partidos ×
3 resultados = 27,210 pronósticos):

| Probabilidad implícita (promedio del grupo) | Frecuencia observada | Lectura |
|---|---|---|
| 7.8 % | 7.0 % | Las sorpresas pasan **un poco menos** de lo que dicen las cuotas |
| 12.7 % | 11.7 % | |
| 27.7 % | 28.0 % | (aquí están casi todos los empates) calibrado |
| 42.3 % | 42.3 % | calibrado |
| 72.6 % | 72.8 % | calibrado |
| 82.1 % | 87.7 % | Los grandes favoritos ganan **un poco más** de lo que dicen |
| 86.8 % | 92.5 % | |

**Conclusión:** las cuotas están muy bien calibradas en general, con un leve **sesgo
favorito–sorpresa** en los extremos, fenómeno documentado en la literatura de apuestas. Por eso
el mercado es una referencia **exigente**: para superarlo hay que tener información que las cuotas
no incorporen.

## 8.5 ¿Por qué el mercado es tan difícil de superar?

- **Agrega información:** alineaciones, lesiones, rotaciones, clima, motivación, noticias y la
  opinión de miles de apostadores con dinero en juego.
- **Se corrige solo:** si una cuota está "mal", los apostadores informados apuestan y la casa la
  ajusta.
- **Mejora conforme llega información:** las cuotas de **cierre** (justo antes del partido, con
  alineaciones confirmadas) son todavía mejores que las de apertura:

| LogLoss | Validación | Prueba |
|---|---|---|
| Mercado apertura | 0.9706 | 1.0200 |
| Mercado cierre | **0.9667** | **1.0170** |

## 8.6 "Apertura" vs "cierre" en Football-Data

Según las notas oficiales del sitio, las cuotas **sin** "C" se registran **el viernes por la
tarde** (partidos de fin de semana) o **el martes** (entre semana), y las que llevan **C** son las
de **cierre**. El proyecto llama "de apertura" a las primeras; es una simplificación que conviene
aclarar si preguntan.

## 8.7 Cómo se usa el mercado en el proyecto

- **Solo como vara de comparación, nunca como variable del modelo.** Si metiéramos las cuotas
  como predictor, el modelo solo copiaría al mercado; la pregunta es si **las estadísticas por sí
  solas** pueden acercarse.
- Se comparan en **los mismos partidos**: los 380 de validación y los 419 de prueba tienen las tres
  cuotas, así que no hubo que descartar ninguno.
- Se usa el **promedio de mercado** (`Avg`) y no una sola casa, porque resume a muchas casas.
- **No se evaluó rentabilidad** ni se simularon apuestas. Las instrucciones exigen que cualquier
  simulación use capital ficticio y fines académicos. Además, con un margen de ≈ 5 %, para ganar
  dinero habría que superar al mercado por más que ese margen, y nuestro modelo ni siquiera lo
  iguala.

## 8.8 El código: Python vs R

**Python (`Analisis.ipynb`, sección 7):**

```python
def cargar_cuotas(ruta):
    mercado = pd.read_csv(ruta, usecols=CLAVES + CUOTAS)       # sólo fecha, equipos y AvgH/AvgD/AvgA
    mercado["Date"] = pd.to_datetime(mercado["Date"], dayfirst=True, format="mixed")
    mercado[CUOTAS] = mercado[CUOTAS].apply(pd.to_numeric, errors="coerce")
    if mercado.duplicated(CLAVES).any():
        raise ValueError("Hay registros duplicados en el archivo de cuotas")
    return mercado

def comparar_con_mercado(predicciones_por_modelo, mercado):
    ...
    datos = base.merge(mercado, on=CLAVES, how="left", validate="one_to_one")
    cuotas = datos[CUOTAS].to_numpy(dtype=float)
    validas = np.isfinite(cuotas).all(axis=1) & (cuotas > 1).all(axis=1)   # cuotas existentes y > 1
    datos = datos.loc[validas]
    brutas = 1.0 / datos[CUOTAS].to_numpy(dtype=float)
    totales = brutas.sum(axis=1)
    prob_mercado = brutas / totales[:, None]                                 # normalización
    ...
    return tabla, len(base), len(datos), (totales.mean() - 1.0) * 100        # margen promedio
```

| Código | Qué hace | En R |
|---|---|---|
| `usecols=...` | Lee solo algunas columnas | `read_csv(..., col_select = c(...))` o `select()` |
| `merge(..., how="left", validate="one_to_one")` | Une las probabilidades del modelo con las cuotas por fecha y equipos, y **verifica** que cada partido aparezca una sola vez | `left_join(..., by = c(...), relationship = "one-to-one")` |
| `np.isfinite(...) & (cuotas > 1)` | Descarta cuotas vacías o imposibles | `complete.cases(...) & rowSums(cuotas > 1) == 3` |
| `brutas / totales[:, None]` | Divide cada fila entre su suma | `brutas / rowSums(brutas)` |

**R (verificado en `equivalencias_R/03_mercado.R`):**

```r
cuotas <- read_csv("E0_consolidado.csv") |> select(Date, HomeTeam, AwayTeam, AvgH, AvgD, AvgA)
prueba_cuotas <- prueba |> left_join(cuotas, by = c("Date", "HomeTeam", "AwayTeam"))
brutas <- 1 / as.matrix(prueba_cuotas[, c("AvgH", "AvgD", "AvgA")])
margen <- mean(rowSums(brutas) - 1)                  # 5.84 %
P_mercado <- brutas / rowSums(brutas)                # normalización proporcional
```

Da el mismo margen (5.84 %) y el mismo LogLoss del mercado (1.020000) que Python.
