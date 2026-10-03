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
| Bet365, 2002/03–2026/27 (9,160 partidos) | 5.44 % |

El margen no es una constante: el de Bet365 fue de 11.6 % en 2002/03, de 2.6 % a 3.1 % entre 2013/14 y
2018/19 y de 5.3 % a 5.6 % desde 2019/20. Los promedios de cierre (`AvgC`) tienen algo menos de margen que
los de apertura: 4.19 % en validación y 5.70 % en prueba. *(Los márgenes por temporada de Bet365 y los de
cierre son un cálculo de la guía con el código del proyecto; no están en el notebook ni en el tablero.)*

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
> el notebook (§8) lo reconoce como supuesto: hay otros métodos de *de-vigging* que podrían dar
> probabilidades ligeramente distintas.

**Los métodos finos en el ejemplo de 8.1** (comprobación de la guía, posterior a la entrega; el
[recuadro de 8.9](#89-decisiones-y-alternativas) da el resultado con todos los partidos):

| Método | Gana Leeds | Empate | Gana Newcastle |
|---|---|---|---|
| Proporcional (el del proyecto) | 39.42 % | 27.19 % | 33.39 % |
| Shin (z = 0.033) | 39.72 % | 26.90 % | 33.39 % |
| Potencia (k = 1.0624) | 39.80 % | 26.83 % | 33.37 % |

Los dos métodos finos le quitan probabilidad al resultado menos probable (aquí, el empate) y se la dan al
favorito. Con todos los partidos de validación y prueba, y márgenes de 4 a 6 %, la probabilidad media del
favorito sube entre 0.7 y 1.2 puntos porcentuales y la del empate baja entre 0.4 y 0.6; la mayor
diferencia en un solo partido con Shin es de 1.9 puntos (validación) y 2.8 (prueba).

## 8.4 ¿Están bien calibradas las cuotas?

Primero, un dato de contexto: con las cuotas de Bet365 (9,160 partidos desde 2002/03), el **favorito** (la
cuota más baja entre local y visitante) gana **54.2 %** de las veces; el empate ocurre 24.7 % y el no
favorito gana 21.0 %. El local es el favorito en 69.6 % de los partidos.

Una probabilidad está **calibrada** si los eventos a los que se les asigna 70 % ocurren el 70 % de
las veces. Para comprobarlo se agrupan todos los pronósticos por rango de probabilidad y se compara
con la frecuencia real (diagrama de calibración). Con Bet365, 2002/03–2026/27 (9,160 partidos ×
3 resultados = 27,480 pronósticos), en grupos de 5 puntos porcentuales:

| Probabilidad implícita (promedio del grupo) | Frecuencia observada | Pronósticos | Lectura |
|---|---|---|---|
| 7.8 % | 6.9 % | 1,024 | Las sorpresas pasan **un poco menos** de lo que dicen las cuotas |
| 12.7 % | 11.7 % | 1,637 | |
| 27.7 % | 28.0 % | 7,462 | (aquí caen la mayoría de los pronósticos de empate: 62 %, cálculo de la guía) calibrado |
| 42.3 % | 42.1 % | 1,450 | calibrado |
| 72.6 % | 72.7 % | 491 | calibrado |
| 82.1 % | 87.7 % | 219 | Los grandes favoritos ganan **un poco más** de lo que dicen |
| 86.8 % | 92.5 % | 67 | |

**Conclusión:** las cuotas están muy bien calibradas en general, con un leve **sesgo
favorito–sorpresa** en los extremos (los grupos de los extremos tienen pocos pronósticos, 219 y 67, y se leen
con cautela), fenómeno documentado en la literatura de apuestas. Por eso el mercado es una referencia
**exigente**: para superarlo hay que tener información que las cuotas no incorporen.

**¿Y el modelo?** La misma comprobación para M0 y para el mercado de apertura, con los partidos de
validación y prueba juntos (799 partidos × 3 resultados), en grupos de 10 puntos porcentuales (sólo grupos con
al menos 30 pronósticos). Cada celda dice "lo que dice → lo que ocurre":

| Grupo | M0 (n) | Mercado de apertura (n) |
|---|---|---|
| 0–10 % | 7.3 % → 7.5 % (40) | 7.4 % → 5.6 % (54) |
| 10–20 % | 16.3 % → 16.8 % (321) | 15.8 % → 15.7 % (376) |
| 20–30 % | 24.6 % → 26.4 % (990) | 25.2 % → 27.1 % (964) |
| 30–40 % | 35.1 % → 36.3 % (353) | 35.1 % → 36.1 % (330) |
| 40–50 % | 44.6 % → 40.6 % (283) | 44.9 % → 43.5 % (246) |
| 50–60 % | 54.5 % → 54.2 % (214) | 55.0 % → 48.3 % (209) |
| 60–70 % | 64.4 % → 57.0 % (135) | 65.0 % → 63.7 % (135) |
| 70–80 % | 74.1 % → 68.1 % (47) | 74.2 % → 70.3 % (64) |

M0 es más optimista que lo que ocurre en los favoritos fuertes (60–80 %): cuando dice ≈ 64.4 % ocurre 57.0 %,
y cuando dice ≈ 74.1 %, 68.1 %. El mercado se equivoca menos en el grupo de 60–70 % (65.0 % → 63.7 %), aunque
también sobrestima en el de 70–80 %; en el de 50–60 % ocurre al revés: M0 acierta (54.5 % → 54.2 %) y el
mercado sobrestima (55.0 % → 48.3 %). Con 47 a 135 pronósticos por grupo en los extremos, diferencias de
pocos puntos pueden ser ruido.

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
- Se usa el **promedio de mercado** (`Avg`) y no una sola casa, porque resume a muchas casas. (Con
  Bet365 sola el LogLoss sería casi igual: 0.970758 en validación y 1.022808 en prueba; comprobación de la
  guía en [8.9](#89-decisiones-y-alternativas).)
- **No se evaluó rentabilidad** ni se simularon apuestas. Las instrucciones exigen que cualquier
  simulación use capital ficticio y fines académicos. Además, con un margen de ≈ 5 %, para ganar
  dinero habría que superar al mercado por más que ese margen, y nuestro modelo ni siquiera lo
  iguala.

## 8.8 El código: Python vs R

**Python (`Analisis.ipynb`, sección 8):**

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
    datos = datos.loc[validas].reset_index(drop=True)
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

## 8.9 Decisiones y alternativas

Las comprobaciones marcadas como *de la guía* se hicieron **después de la entrega**, con el código y los
datos del proyecto: **no están en el notebook, el tablero ni el reporte** y sólo se mencionan si preguntan,
aclarando que son posteriores. Lo que el proyecto **probó** de verdad en este tema es el mercado de apertura
y el de cierre (en el tablero); lo demás es razonado. Las decisiones de todo el proyecto están en el
[capítulo 19](19_decisiones_y_alternativas.md) (D2 y D35 son las de este capítulo).

> **Decisión:** quitar el margen con la **normalización proporcional**, p<sub>j</sub> = q<sub>j</sub> / Σq, con
> q<sub>j</sub> = 1/cuota<sub>j</sub> (en R, `q / rowSums(q)`).
>
> **Alternativas:** (a) **Shin** (1993; Štrumbelj, 2014) — a favor: modela explícitamente a los apostadores
> informados (una fracción z) y mueve probabilidad de las sorpresas al favorito, corrigiendo el sesgo
> favorito–sorpresa; en contra: hay que resolver una ecuación para z partido por partido y es menos
> transparente; (b) **potencia**, p<sub>j</sub> = q<sub>j</sub><sup>k</sup> con k > 1 elegido para que sumen 1 — a
> favor: una sola constante y también corrige el sesgo; en contra: sin justificación económica clara; (c)
> **proporcional** (lo elegido) — a favor: la más simple y fácil de explicar; en contra: reparte el margen en
> proporción y no corrige el sesgo. Ni (a) ni (b) se probaron en el proyecto; se comprobaron después.
>
> **Por qué ésta:** es la conversión más simple y transparente, y con márgenes de 4 a 6 % los métodos difieren
> poco. La pregunta del proyecto no es cuál es la mejor forma de quitar el margen, sino cuánto se acerca el
> modelo al mercado.
>
> **Evidencia en el proyecto:** mercado de apertura 0.970552 (validación) y 1.020000 (prueba) con la
> proporcional; el reporte la usa (§6.2). *Comprobación de la guía:* con Shin, 0.970635 y 1.020971 (z medio
> 0.023 y 0.029); con potencia, 0.971026 y 1.021782 (k medio 1.050 y 1.062): un poco **peor**, porque ambos
> le quitan probabilidad al empate (en prueba, la P(empate) media baja de 24.54 % a 24.15 % con Shin) y los
> empates ocurrieron 28.2 %. La brecha de M0 contra el mercado pasa, con Shin, de +0.0190 a +0.0189 en
> validación y de +0.0131 a +0.0121 en prueba, y la parte de la ventaja del mercado que logra M0 es 82.6 % y
> 81.6 % (contra 82.5 % y 80.4 %): la conclusión no cambia.
>
> **Si preguntan:** "Usamos la normalización proporcional por ser la más simple. Hay métodos más finos, como el
> de Shin; después comprobamos que con él el LogLoss del mercado cambia en la tercera o cuarta cifra
> (0.970635 contra 0.970552; 1.020971 contra 1.020000) y la conclusión es la misma."

> **Decisión:** el mercado de referencia es el de **apertura** (cuotas promedio `AvgH`, `AvgD`, `AvgA`); el de
> **cierre** (`AvgCH`, `AvgCD`, `AvgCA`) se calcula y se muestra en el tablero como referencia adicional.
>
> **Alternativas:** (a) **cierre como referencia principal** — a favor: es el pronóstico público más
> informado (alineaciones confirmadas y noticias de último momento); en contra: incluye información que un
> pronóstico hecho con anticipación no tiene, así que compara al modelo contra algo más difícil de lo que
> tiene sentido para esta pregunta; (b) **apertura** (lo elegido) — a favor: se registra antes del partido
> (viernes por la tarde o martes), más comparable con un modelo que sólo usa información previa; en contra: no
> es la apertura estricta (la primera cuota publicada) sino la captura de Football-Data (8.6), y el reporte
> advierte que la disponibilidad exacta al momento de cada pronóstico requiere comprobación independiente;
> (c) **ambas**, la apertura como vara y el cierre como referencia adicional (lo que se hace). ***Probadas:***
> el tablero calcula y muestra las dos.
>
> **Por qué ésta:** la pregunta es qué tan bien se anticipa con estadística previa al partido; la apertura es el
> competidor justo en el tiempo, y el cierre muestra cuánto mejora el mercado al incorporar información.
>
> **Evidencia en el proyecto:** LogLoss de apertura 0.970552 y 1.020000; de cierre 0.966733 y 1.017024 (0.0038 y
> 0.0030 menos); aciertos 54.2 % y 55.5 % en validación, y 48.9 % en las dos en prueba. M0, con 0.989547 y
> 1.033076, queda 0.0228 y 0.0161 por detrás del cierre. *Comprobación de la guía:* el margen del cierre es
> 4.19 % y 5.70 %, contra 4.49 % y 5.84 % de la apertura; contra el cierre, M0 recupera 79.7 % y 77.0 % de la
> ventaja del mercado sobre la referencia ingenua (contra 82.5 % y 80.4 % con la apertura).
>
> **Si preguntan:** "Nuestra vara es la cuota promedio que registra Football-Data antes del partido, que
> llamamos de apertura. También mostramos el cierre, que es más informado: es un poco mejor (0.9667 contra
> 0.9706 en validación), pero la conclusión es la misma."

> **Decisión:** la vara de comparación es el **promedio** de varias casas (`Avg`); Bet365 sólo se usa para el
> análisis histórico del favorito y la calibración de 8.4 (9,160 partidos desde 2002/03).
>
> **Alternativas:** (a) **Bet365 sola** — a favor: cuotas desde 2002/03 (9,160 partidos) y una casa muy grande;
> en contra: es una casa, no el consenso, con su propio margen y política de precios; (b) **una casa "afilada"
> como Pinnacle** — a favor: se le reconocen márgenes bajos y precios que incorporan información rápido, así
> que sería la vara más exigente; en contra: sus columnas no están entre las 23 comunes ni entre las 11
> complementarias que se conservaron en la limpieza, y habría que revisar su cobertura por temporada; (c) **el
> promedio** (lo elegido) — a favor: resume a muchas casas y existe para exactamente los 380 + 419 partidos de
> validación y prueba; en contra: sólo existe desde 2019/20 y, al ser un promedio, no es la casa más afilada.
> Bet365 se usa en el análisis histórico y se comprobó después como vara; Pinnacle no se probó.
>
> **Por qué ésta:** el promedio es un consenso, menos idiosincrásico que una sola casa, y cubre toda la base de
> modelación sin descartar partidos; Bet365, con su historia larga, permite estudiar el favorito y la
> calibración en 24 temporadas.
>
> **Evidencia en el proyecto:** `Avg` y `AvgC` cubren 2,700 partidos (2019/20–2026/27, la base de modelación
> antes de excluir 4); Bet365, 9,160. *Comprobación de la guía:* con Bet365 sola, el LogLoss es 0.970758 en
> validación y 1.022808 en prueba, contra 0.970552 y 1.020000 del promedio; los márgenes son 5.53 % y 5.52 %,
> contra 4.49 % y 5.84 %; M0 recuperaría 82.7 % y 84.0 % de la ventaja del mercado (contra 82.5 % y 80.4 %).
> La conclusión no cambia con una sola casa.
>
> **Si preguntan:** "Usamos el promedio de varias casas porque es un consenso y existe para todos los partidos
> de validación y prueba. Bet365 sola da casi lo mismo (0.9708 y 1.0228 contra 0.9706 y 1.0200). Una casa
> afilada como Pinnacle sería una vara más exigente; no la probamos."

> **Decisión:** las cuotas **nunca** entran a las regresiones: se convierten en probabilidades (1/cuota,
> normalizadas) y se comparan con el modelo **sobre los mismos partidos** (`comparar_con_mercado`, notebook
> §8–§9).
>
> **Alternativas:** (a) **usar las cuotas como predictor** (la probabilidad implícita como variable) — a favor:
> el pronóstico quedaría casi tan bueno como el mercado; en contra: el ejercicio se vuelve circular y la
> pregunta "¿cuánto anticipa la estadística frente al mercado?" ya no se puede contestar; (b) **comparar sólo
> contra referencias sin información** (azar y referencia ingenua) — a favor: más simple; en contra: ganarle
> al azar es fácil y no dice qué tan cerca se está del mejor pronóstico público; (c) **combinar modelo y
> mercado** (regresión del resultado contra ambas probabilidades) — a favor: es la prueba más directa de si el
> modelo aporta algo que el mercado no tiene; en contra: es otro estudio; queda como extensión
> ([capítulo 15](15_limitaciones_y_extensiones.md)). Se probaron las referencias de (b), además del mercado; (a)
> y (c) no.
>
> **Por qué ésta:** la pregunta del tablero es estadística **contra** mercado; el mercado es el pronóstico
> público más exigente (incorpora alineaciones, lesiones y noticias que no están en los datos) y viene en los
> mismos archivos; usarlo como vara, y no como insumo, mantiene al modelo "sólo con estadística previa al
> partido".
>
> **Evidencia en el proyecto:** LogLoss del mercado 0.970552 y 1.020000, contra 0.989547 y 1.033076 de M0 (y
> 1.079361 y 1.086791 de la referencia ingenua): M0 recupera 82.5 % y 80.4 % de la ventaja del mercado. La
> brecha M0 − mercado con validación y prueba juntas (799 partidos) es +0.0159 (IC 95 %: +0.0064 a +0.0255),
> de la que +0.0185 viene de las victorias locales, +0.0078 de los empates y −0.0104 de las victorias
> visitantes. El mercado da más probabilidad que M0 al resultado real en 57.8 % de los partidos, y la P(local)
> de los dos se correlaciona r = 0.939 en prueba: piensan parecido, pero el mercado es algo mejor.
>
> **Si preguntan:** "Si metiéramos las cuotas al modelo sólo estaríamos copiando al mercado y ya no podríamos
> responder la pregunta. Las usamos como la vara más exigente: con tres variables públicas, el modelo recupera
> cerca de 80 % de la ventaja del mercado sobre una referencia ingenua, pero no lo supera."

**La comprobación de Shin y potencia, en Python y en R.** Python es lo que se ejecutó; el código R es
**ilustrativo** (se reprodujo en R con los mismos resultados):

```python
from scipy.optimize import brentq

def shin(q):                                   # q = 1 / cuota, tres valores
    S = q.sum()
    p_de_z = lambda z: (np.sqrt(z**2 + 4 * (1 - z) * q**2 / S) - z) / (2 * (1 - z))
    z = brentq(lambda z: p_de_z(z).sum() - 1, 0.0, 0.4)      # z: fracción de apostadores informados
    return p_de_z(z), z

def potencia(q):
    k = brentq(lambda k: (q**k).sum() - 1, 1.0, 3.0)         # k > 1 hace que las tres sumen 1
    return q**k, k

q = 1 / np.array([2.38, 3.45, 2.81])           # Leeds–Newcastle
q / q.sum()                                    # proporcional: 0.3942 0.2719 0.3339
shin(q)                                        # 0.3972 0.2690 0.3339 (z = 0.0330)
potencia(q)                                    # 0.3980 0.2683 0.3337 (k = 1.0624)
```

```r
# R (ilustrativo)
shin <- function(q) {
  p_de_z <- function(z) (sqrt(z^2 + 4 * (1 - z) * q^2 / sum(q)) - z) / (2 * (1 - z))
  z <- uniroot(function(z) sum(p_de_z(z)) - 1, c(0, 0.4), tol = 1e-12)$root
  list(p = p_de_z(z), z = z)
}
potencia <- function(q) { k <- uniroot(function(k) sum(q^k) - 1, c(1, 3), tol = 1e-12)$root; list(p = q^k, k = k) }
q <- 1 / c(2.38, 3.45, 2.81)
q / sum(q); shin(q)$p; potencia(q)$p
```
