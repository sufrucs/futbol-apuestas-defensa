# 17. Banco de preguntas

[← Guion](16_guion_exposicion.md) · [Índice](README.md) · [Siguiente: hallazgos y pendientes →](18_hallazgos_y_pendientes.md)

**Cómo usarlo:** lee la pregunta, contéstala **en voz alta** y solo después abre la respuesta (clic
en la flecha). Al final de cada respuesta está el capítulo donde se explica a fondo. Las
respuestas están pensadas para decirse en 30–45 segundos.

**Temas:** [A. Proyecto](#a-el-proyecto) · [B. Datos y limpieza](#b-datos-y-limpieza) ·
[C. Elo](#c-elo) · [D. Shrinkage y forma](#d-promedios-ajustados-y-forma-reciente) ·
[E. Poisson y regresión](#e-poisson-y-regresión) · [F. Probabilidades 1X2](#f-de-goles-a-probabilidades) ·
[G. Cuotas y mercado](#g-cuotas-y-mercado) · [H. Evaluación](#h-evaluación) ·
[I. Resultados](#i-resultados) · [J. Código](#j-código) · [K. Tablero](#k-el-tablero) ·
[L. Publicación](#l-publicación) · [M. Ética y alcance](#m-ética-y-alcance)

---

## A. El proyecto

<details><summary><b>1. ¿Cuál es la pregunta de investigación?</b></summary>

¿Qué tan bien anticipan el resultado de un partido de la Premier League (victoria local, empate o
victoria visitante) las estadísticas disponibles **antes** del encuentro, comparadas con las
probabilidades implícitas en las cuotas de apuestas? → [cap. 2](02_contexto_y_datos.md)
</details>

<details><summary><b>2. ¿Cuál era la hipótesis y se confirmó?</b></summary>

Que las estadísticas contienen información útil (el modelo supera a una referencia ingenua), pero
que el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor (el modelo
no supera a las cuotas). **Se confirmó en ambas partes.** → [cap. 2](02_contexto_y_datos.md), [cap. 12](12_resultados.md)
</details>

<details><summary><b>3. Explícanos el proyecto en un minuto.</b></summary>

Con 9,450 partidos de la Premier League construimos variables previas a cada partido (Elo y goles
ajustados), ajustamos dos regresiones de Poisson para los goles de cada equipo y de ahí obtuvimos
las probabilidades de victoria local, empate y visita. Las evaluamos con partidos futuros contra las
probabilidades de las cuotas. El modelo acierta 48 % (el mercado 49 %, "siempre local" 41.5 %) y
logra el 84 % de la mejora del mercado sobre una referencia ingenua, pero no lo supera. Conclusión:
las cuotas ya incorporan la información estadística pública. → [cap. 1](01_panorama.md)
</details>

<details><summary><b>4. ¿Cuál es la conclusión principal?</b></summary>

Las estadísticas previas sí anticipan resultados, pero el mercado sabe un poco más: tiene menor
LogLoss en validación y en prueba, y con ambos periodos juntos la diferencia (+0.012, IC 95 %
+0.002 a +0.022) es pequeña pero distinta de cero. Un modelo simple se acerca sin encontrar una
ventaja sistemática. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>5. ¿Qué preguntas secundarias respondieron?</b></summary>

¿Qué variables pesan más? La diferencia de Elo. ¿Cómo cambia el desempeño local y visitante? La
localía es estable (≈ 45 % de victorias locales), salvo sin público en 2020/21. ¿Qué tan calibradas
están las cuotas? Bien calibradas. ¿Más variables mejoran el pronóstico? No de forma que generalice.
→ [cap. 12](12_resultados.md)
</details>

<details><summary><b>6. ¿Por qué este tema es buen caso de ciencia de datos?</b></summary>

Hay datos públicos abundantes y de calidad, una pregunta clara y, sobre todo, una **vara de
comparación natural**: el mercado de apuestas, que resume la opinión de miles de participantes con
dinero en juego. Así no basta con decir "el modelo acierta 48 %": sabemos contra qué compararlo.
→ [cap. 2](02_contexto_y_datos.md)
</details>

## B. Datos y limpieza

<details><summary><b>7. ¿De dónde salen los datos y cómo se obtuvieron?</b></summary>

De Football-Data.co.uk: un CSV por temporada de la Premier League (archivos `E0`), de 2001/02 a
2026/27, descargados directamente del sitio, sin API. Se unieron en `E0_consolidado.csv` con
`Limpieza de datos.ipynb`. → [cap. 2](02_contexto_y_datos.md), [cap. 3](03_limpieza_de_datos.md)
</details>

<details><summary><b>8. ¿Qué significa "E0"?</b></summary>

Es el código de Football-Data: **E** = Inglaterra, **0** = primera división (Premier League). E1 es
la Championship, E2 la League One, etc. → [cap. 2](02_contexto_y_datos.md)
</details>

<details><summary><b>9. ¿Cuántos datos tienen?</b></summary>

9,450 partidos, 26 temporadas (18-ago-2001 a 14-sep-2026) y 33 variables. Para modelar se usan
2,696 partidos: 1,897 de entrenamiento, 380 de validación y 419 de prueba. → [cap. 2](02_contexto_y_datos.md)
</details>

<details><summary><b>10. ¿Qué significan FTHG, FTR, HS, HST y AvgH?</b></summary>

FTHG: goles del local al final del partido (*Full Time Home Goals*). FTR: resultado final (H, D o
A). HS: tiros del local (*Home Shots*). HST: tiros a puerta del local (*Home Shots on Target*).
AvgH: cuota promedio del mercado a la victoria local. → [cap. 2](02_contexto_y_datos.md) (diccionario de 33 variables)
</details>

<details><summary><b>11. ¿Por qué usar datos desde 2001 si el modelo empieza en 2019?</b></summary>

Porque el Elo necesita historia para estabilizarse. Con 18 años de partidos previos, en 2019 los
ratings ya reflejan la fuerza real de cada equipo. El análisis exploratorio también usa todo el
histórico. → [cap. 4](04_elo.md)
</details>

<details><summary><b>12. ¿Por qué el modelo empieza en 2019?</b></summary>

Porque desde 2019/20 existen las cuotas promedio del mercado (apertura y cierre), que son nuestra
vara de comparación. Además, así quedan cinco temporadas de entrenamiento. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>13. ¿Qué decisiones de limpieza tomaron?</b></summary>

(1) Conservar 22 columnas comunes a todas las temporadas y 11 complementarias (cuotas y xG).
(2) `reindex` para que una columna ausente quede vacía en vez de perder la temporada. (3) Eliminar
filas sin equipos (filas vacías al final de algunos archivos). (4) Homologar fechas (`dd/mm/aa` y
`dd/mm/aaaa`) y ordenar cronológicamente. (5) No eliminar partidos sin cuotas, porque alimentan el
Elo. → [cap. 3](03_limpieza_de_datos.md)
</details>

<details><summary><b>14. ¿Qué problemas de calidad encontraron?</b></summary>

No hay duplicados ni resultados incongruentes. Hay dos temporadas incompletas (2003/04 y 2004/05,
con 335 de 380 partidos), un partido con más tiros a puerta que tiros (error de la fuente), xG solo
en 2026/27 y cuotas promedio solo desde 2019/20. Ninguno afecta el periodo de modelación.
→ [cap. 2](02_contexto_y_datos.md)
</details>

<details><summary><b>15. ¿Por qué quedaron 2,696 partidos y no 2,700?</b></summary>

Se excluyeron 4 partidos: el primero de Brentford (2021), Nott'm Forest (2022), Luton (2023) y
Coventry (2026). Esos equipos no tenían partidos previos en la base, así que sus variables de tiros
quedaban vacías. → [cap. 11](11_codigo_analisis_notebook.md)
</details>

<details><summary><b>16. ¿Qué es la fuga de información y cómo la evitaron?</b></summary>

Es usar, sin querer, información que no existía en el momento de predecir, lo que da resultados
optimistas. Se evitó de tres formas: cada variable se calcula solo con partidos de fechas
**anteriores** (`date < fecha`); el Elo se actualiza después de procesar todos los partidos del
día; y la partición es temporal (entrenar con el pasado, evaluar con el futuro). → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>17. ¿Cómo manejaron las fechas?</b></summary>

Los archivos antiguos usan `dd/mm/aa` y los recientes `dd/mm/aaaa`. Se leyeron con
`dayfirst=True` y `format='mixed'` y se exportaron en formato ISO (aaaa-mm-dd). Se verificó que
ninguna fecha invirtió día y mes. → [cap. 3](03_limpieza_de_datos.md)
</details>

## C. Elo

<details><summary><b>18. ¿Qué es el Elo?</b></summary>

Un rating de fuerza. Cada equipo empieza con 1,500 puntos y, tras cada partido, gana o pierde
puntos según qué tan inesperado fue el resultado: rating nuevo = rating previo + K × (resultado real
− resultado esperado). La diferencia de Elo entre dos equipos resume quién es más fuerte.
→ [cap. 4](04_elo.md)
</details>

<details><summary><b>19. ¿Cuál es la fórmula del resultado esperado?</b></summary>

$E_A = 1 / (1 + 10^{(R_B - R_A)/400})$. Con ratings iguales da 0.5. Con 400 puntos de ventaja da
0.909, es decir, 10 a 1. Ejemplo: Arsenal (1833) contra Man City (1808) da 0.537. → [cap. 4](04_elo.md)
</details>

<details><summary><b>20. ¿Qué significa K = 30?</b></summary>

Cuántos puntos se mueve el rating por partido. Ganarle a un rival igual suma 30 × (1 − 0.5) = 15
puntos; ganarle a uno 200 puntos más fuerte suma ≈ 23, porque era menos esperado. K = 30 es un
valor habitual, no optimizado: más alto reacciona más rápido pero con más ruido. → [cap. 4](04_elo.md)
</details>

<details><summary><b>21. ¿Por qué la diferencia de Elo se divide entre 400?</b></summary>

Para usar la misma escala de la fórmula de Elo, donde 400 puntos es la unidad natural. El
coeficiente se lee "por cada 400 puntos de diferencia". Dividir entre una constante no cambia las
predicciones, solo la escala del coeficiente. → [cap. 4](04_elo.md), [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>22. ¿Cuánto vale jugar en casa, en puntos Elo?</b></summary>

≈ 60 puntos. En la gráfica de deciles, las curvas de victoria local y visitante se cruzan cuando el
local es ≈ 60 puntos más débil: jugar en casa compensa esa diferencia. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>23. ¿Qué limitaciones tiene su Elo?</b></summary>

No incluye la ventaja de local ni el margen de victoria (ganar 1–0 o 5–0 mueve lo mismo), y solo
usa partidos de Premier: un ascendido nuevo empieza en 1,500 y uno que regresa conserva su rating
de hace años, sin regresión a la media entre temporadas. → [cap. 15](15_limitaciones_y_extensiones.md)
</details>

## D. Promedios ajustados y forma reciente

<details><summary><b>24. ¿Qué es el shrinkage y por qué k = 10?</b></summary>

Al inicio de la temporada, con pocos partidos, el promedio de goles es muy ruidoso. El *shrinkage*
lo mezcla con el promedio de la temporada anterior: con n partidos, la temporada actual pesa
n / (n + 10). Con 10 partidos pesa la mitad; con 38, 79 %. k = 10 es un valor operativo, no
optimizado. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>25. Dame un ejemplo numérico de shrinkage.</b></summary>

Un equipo lleva 5 partidos con 2.0 goles por partido y la temporada pasada promedió 1.5. Peso de la
temporada actual: 5/15 = 1/3. Promedio ajustado: 1/3 × 2.0 + 2/3 × 1.5 = **1.67**. El arranque
bueno cuenta, pero sin exagerarlo. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>26. ¿Qué pasa con un equipo recién ascendido?</b></summary>

No tiene temporada anterior en Premier, así que su valor previo es el promedio de goles de la liga
(en 2019, 1.41 para Norwich). Es una limitación: los ascendidos suelen ser más débiles que el
promedio. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>27. ¿Qué es la forma reciente?</b></summary>

Un promedio ponderado de los últimos 10 partidos, con pesos 0.85^antigüedad normalizados: el más
reciente pesa 18.7 %, el más antiguo 4.3 % y los tres últimos suman ≈ 48 %. Se calcula para goles,
tiros y tiros a puerta, a favor y en contra. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>28. ¿Por qué la forma reciente no mejoró el modelo?</b></summary>

Porque se traslapa con lo que ya miden el Elo y los goles ajustados, y agrega ruido. En validación
M1 mejoró apenas (−0.0014 de LogLoss) y en prueba empeoró (+0.0009); ambas diferencias están dentro
del ruido. → [cap. 12](12_resultados.md)
</details>

## E. Poisson y regresión

<details><summary><b>29. ¿Qué es la distribución de Poisson?</b></summary>

Modela cuántas veces ocurre un evento en un intervalo cuando los eventos son relativamente raros e
independientes y ocurren a un ritmo promedio λ: $P(G = g) = e^{-\lambda}\lambda^g / g!$. Su
propiedad clave: **media = varianza = λ**. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>30. ¿Por qué regresión de Poisson para los goles?</b></summary>

Los goles son conteos pequeños (0, 1, 2…) de eventos poco frecuentes: el caso típico de Poisson y
el enfoque clásico de la literatura (Maher, 1982; Dixon y Coles, 1997). Los datos lo respaldan: la
media se parece a la varianza (1.53 contra 1.69 del local; 1.19 contra 1.34 del visitante) y, dentro
del modelo, la dispersión de Pearson es 0.99 y 1.04. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>31. ¿Por qué no una regresión lineal?</b></summary>

Porque podría predecir goles negativos, supone varianza constante y errores normales, y los goles
son conteos discretos cuya varianza crece con la media. La Poisson con enlace logarítmico respeta
todo eso. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>32. ¿Qué es un GLM?</b></summary>

Un modelo lineal generalizado. Tiene tres piezas: una distribución para la variable respuesta (aquí,
Poisson), un predictor lineal (Xβ) y una función de enlace que los une (aquí, log λ = Xβ). La
regresión lineal es el caso particular con distribución normal y enlace identidad. En R:
`glm(family = poisson)`. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>33. ¿Por qué enlace logarítmico?</b></summary>

Garantiza que λ (goles esperados) sea siempre positiva y hace que los efectos sean
**multiplicativos**: cada unidad de una variable multiplica los goles esperados por $e^{\beta}$.
→ [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>34. ¿Cómo se estiman los coeficientes?</b></summary>

Por **máxima verosimilitud**: se buscan los β que hacen más probables los goles observados.
`statsmodels` y `glm()` de R usan el mismo algoritmo iterativo (IRLS) y llegan a los mismos
coeficientes, lo que se verificó en `equivalencias_R/02_modelo_poisson.R`. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>35. ¿Cómo se interpreta el coeficiente de la diferencia de Elo en M0?</b></summary>

En la ecuación del local es 0.4082 por cada 400 puntos. +100 puntos (D = 0.25) multiplican los goles
esperados del local por $e^{0.4082 \times 0.25} ≈ 1.107$ (+10.7 %). En la del visitante (−0.4870)
los multiplican por ≈ 0.885 (−11.5 %). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>36. ¿Qué variable pesa más?</b></summary>

La diferencia de Elo. En escala comparable (+1 desviación estándar, ≈ 167 puntos) sube 18.6 % los
goles esperados del local y baja 18.4 % los del visitante. Le siguen los goles a favor del local
(+16.0 %). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>37. ¿Son significativos los coeficientes de M0?</b></summary>

Casi todos. En la ecuación del local, Elo (z = 5.1), goles a favor (z = 5.6) y goles en contra del
rival (z = 2.6, p = 0.008). En la del visitante, los goles en contra del local no alcanzan
significancia (p = 0.075). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>38. ¿Cómo se interpreta el intercepto?</b></summary>

Es log λ cuando todas las variables valen cero. Como "cero goles promedio" no es realista, no se
interpreta directamente ($e^{-0.3864} ≈ 0.68$). Lo que importa es que cada ecuación tiene su propio
intercepto, así que la ventaja de local se **estima** y no se impone. → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>39. ¿Por qué dos regresiones y no una?</b></summary>

Una para los goles del local y otra para los del visitante. Así cada una tiene su intercepto y sus
coeficientes, y la ventaja de local sale de los datos. Por ejemplo, la diferencia de Elo tiene un
coeficiente propio en cada ecuación: +0.408 en la del local y −0.487 en la del visitante.
→ [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>40. ¿Qué es la dispersión de Pearson y por qué importa?</b></summary>

Es la suma de residuos de Pearson al cuadrado entre los grados de libertad. Si vale ≈ 1, la
varianza es ≈ la media, como supone Poisson. Si fuera mucho mayor (sobredispersión), los errores
estándar saldrían demasiado pequeños y convendría una binomial negativa. Aquí es 0.99 y 1.04.
→ [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>41. ¿Qué es la multicolinealidad? ¿Es un problema en M4?</b></summary>

Es cuando las variables explicativas están muy correlacionadas (tiros y tiros a puerta: 0.85; VIF
máximo 5.5). No sesga las predicciones, pero vuelve inestables los coeficientes individuales. Por
eso los modelos se comparan por su desempeño fuera de muestra y no por la significancia de cada
coeficiente. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>42. ¿Qué especificaciones compararon?</b></summary>

M0 (base: Elo y goles ajustados, 3 variables por ecuación) → M1 (+ forma) → M2 (+ tiros) → M3
(+ tiros a puerta) → M4 (todo, 9 variables). Son modelos anidados: cada bloque se agrega para ver si
aporta. → [cap. 11](11_codigo_analisis_notebook.md)
</details>

## F. De goles a probabilidades

<details><summary><b>43. ¿Cómo pasan de goles esperados a P(local), P(empate) y P(visita)?</b></summary>

Se supone que, dadas las variables, los goles de ambos equipos son independientes. Entonces la
probabilidad de un marcador es el producto de dos Poisson. Sumando las celdas de la matriz de
marcadores: victoria local donde el local anota más, empate en la diagonal y victoria visitante
donde anota más el visitante. → [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>44. ¿Qué es la distribución de Skellam?</b></summary>

La distribución de la **diferencia** entre dos Poisson independientes. P(local) es la probabilidad
de que la diferencia sea positiva, P(empate) de que sea cero y P(visita) de que sea negativa. El
notebook la usa con `scipy.stats.skellam`; en R se obtiene lo mismo sumando la matriz de marcadores.
→ [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>45. Da el ejemplo del reporte.</b></summary>

Arsenal (local) contra Man City, con información al 14-sep-2026: λ = 1.57 y 1.20. Probabilidades:
45.8 % Arsenal, 25.0 % empate, 29.3 % City. El marcador más probable es 1–1, con 11.8 %.
→ [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>46. ¿Por qué el marcador más probable es 1–1 si el favorito es el local?</b></summary>

Porque la victoria local agrupa muchos marcadores (1–0, 2–0, 2–1…) y el empate pocos. El 1–1 es el
marcador **individual** más probable, pero la suma de todos los marcadores de victoria local es
mayor. Marcador más probable ≠ resultado más probable. → [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>47. ¿Qué problema causa el supuesto de independencia?</b></summary>

Subestima los empates, sobre todo 0–0 y 1–1. En prueba, M0 asignó en promedio 23.7 % al empate y
ocurrieron 28.2 %. La corrección clásica es la de Dixon y Coles (1997). → [cap. 7](07_de_goles_a_probabilidades.md), [cap. 15](15_limitaciones_y_extensiones.md)
</details>

## G. Cuotas y mercado

<details><summary><b>48. ¿Qué es una cuota decimal?</b></summary>

Cuánto te pagan por cada peso apostado si aciertas, incluido tu peso. Una cuota de 2.50 paga 2.50
por cada 1 apostado (1.50 de ganancia). → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>49. ¿Cómo convierten las cuotas en probabilidades?</b></summary>

La probabilidad bruta es 1/cuota. Las tres suman más de 100 %; ese exceso es el margen de la casa.
Se normalizan dividiendo cada una entre la suma. Ejemplo (Leeds–Newcastle): cuotas 2.38 / 3.45 /
2.81 → brutas 42.0 / 29.0 / 35.6 % (suma 106.6 %) → normalizadas 39.4 / 27.2 / 33.4 %.
→ [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>50. ¿Qué es el margen de la casa?</b></summary>

Lo que las probabilidades brutas suman por encima de 100 %: es la ganancia esperada de la casa.
Promedio: 4.49 % en validación y 5.84 % en prueba. → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>51. ¿Qué limitación tiene la normalización proporcional?</b></summary>

Reparte el margen en proporción a cada probabilidad, y no corrige el **sesgo favorito–sorpresa**: la
tendencia a que las sorpresas estén sobrevaloradas en las cuotas. Existen métodos más finos, como el
de Shin. → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>52. ¿Qué son las cuotas de apertura y de cierre?</b></summary>

Las de "apertura" (`Avg`) son las cuotas promedio que Football-Data registra el viernes por la tarde
para los partidos de fin de semana, o el martes para los de entre semana. Las de cierre (`AvgC`) son
las últimas antes del partido. Las de cierre son más precisas (LogLoss 1.0170 contra 1.0200 en
prueba) porque incorporan más información, como las alineaciones. → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>53. ¿Las cuotas entran al modelo?</b></summary>

**No.** Solo son la vara de comparación. El modelo usa exclusivamente estadísticas previas al
partido. → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>54. ¿Están calibradas las cuotas?</b></summary>

Sí: cuando las cuotas dicen 70 %, el resultado ocurre cerca de 70 %. Hay un leve sesgo en los
extremos. El favorito de Bet365 gana 54.3 % de las veces, empata 24.6 % y pierde 21.0 % (9,070
partidos). → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>55. ¿Por qué el mercado es mejor que el modelo?</b></summary>

Porque incorpora información que el modelo no tiene (alineaciones, lesiones, noticias, rotaciones)
y agrega las opiniones de muchos participantes con dinero en juego. Consistente con eso, las cuotas
de cierre, que tienen más información, son aún mejores que las de apertura. → [cap. 12](12_resultados.md)
</details>

## H. Evaluación

<details><summary><b>56. ¿Por qué partición temporal y no aleatoria?</b></summary>

Una partición aleatoria mezclaría partidos futuros en el entrenamiento (fuga de información) y daría
resultados optimistas. La temporal imita el uso real: ajustar con el pasado y pronosticar el futuro.
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>57. ¿Por qué tres conjuntos (entrenamiento, validación y prueba)?</b></summary>

Entrenamiento (2019/20–2023/24) para estimar los coeficientes; validación (2024/25) para elegir entre
especificaciones; prueba (15-ago-2025 a 14-sep-2026), intacta hasta el final, para una estimación
honesta del desempeño. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>58. ¿Qué es el LogLoss?</b></summary>

El promedio de −log(probabilidad asignada al resultado que ocurrió). Si el modelo le dio 45.8 % a la
victoria local y ganó el local, ese partido suma −ln(0.458) = 0.78. Si fue empate (25 %), suma 1.39.
Menor es mejor. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>59. ¿Por qué LogLoss y no porcentaje de aciertos?</b></summary>

El LogLoss evalúa las probabilidades completas: premia asignar mucha probabilidad a lo que ocurre y
castiga fuerte la sobreconfianza. Los aciertos ignoran la confianza (60 % y 90 % cuentan igual), y
como nadie pronostica empates, casi no distinguen modelos. Además, el LogLoss es una regla de
puntuación **propia**: se minimiza reportando las probabilidades verdaderas. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>60. ¿Qué significa un LogLoss de 1.031?</b></summary>

Que en promedio (geométrico) el modelo asignó $e^{-1.031}$ = 35.7 % de probabilidad al resultado que
ocurrió. Adivinar al azar da 33.3 % (LogLoss ln 3 = 1.099) y el mercado 36.1 % (1.020).
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>61. ¿Qué es la referencia ingenua y por qué acierta 41.5 %?</b></summary>

Un modelo de Poisson sin información de los equipos: usa los goles promedio del entrenamiento (1.56
del local y 1.31 del visitante) para todos los partidos. Como siempre favorece al local, acierta
exactamente cuando gana el local: 41.5 % en prueba. Mide cuánto aportan las variables.
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>62. ¿De dónde sale el 84 %?</b></summary>

(LogLoss ingenua − LogLoss M0) / (LogLoss ingenua − LogLoss mercado) en prueba = (1.0868 − 1.0306) /
(1.0868 − 1.0200) = 0.0562 / 0.0668 = 84 %. Es la fracción de la **mejora** del mercado que logra el
modelo, no "84 % tan bueno como el mercado". En validación es 88 %. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>63. ¿Qué es el MAE y por qué no coincide con el LogLoss?</b></summary>

El error absoluto medio entre goles reales y esperados. Evalúa λ, no las probabilidades 1X2. En
prueba, M4 tuvo el mejor MAE (0.898) pero peor LogLoss que M0: estimar mejor los goles no garantiza
mejores probabilidades de resultado. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>64. ¿Qué es el bootstrap?</b></summary>

Un método para medir la incertidumbre: se calcula la diferencia de pérdida partido por partido, se
remuestrean los partidos con reemplazo, se promedia y se repite 10,000 veces. Los percentiles 2.5 y
97.5 forman el intervalo de 95 %. Si no incluye el cero, la diferencia es distinguible del azar.
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>65. ¿Son significativas las diferencias?</b></summary>

Contra la referencia ingenua, sí, con claridad (−0.056, IC −0.086 a −0.026). Contra el mercado, en
prueba sola el intervalo incluye el cero (+0.011, IC −0.004 a +0.025), pero en validación y con
ambos periodos juntos no lo incluye (+0.012, IC +0.002 a +0.022): el mercado es mejor de forma
consistente. Entre M0 y M4, nada es concluyente. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>66. ¿Qué es la calibración y cómo sale su modelo?</b></summary>

Un modelo está calibrado si, cuando dice 70 %, el evento ocurre ≈ 70 % de las veces. M0 es algo
sobreconfiado con los favoritos: cuando dice 64.6 %, ocurre 58.5 %; cuando dice 74.7 %, ocurre
68.1 %. El mercado está mejor calibrado. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>67. ¿Por qué todos empeoran en prueba, incluido el mercado?</b></summary>

El periodo de prueba fue más difícil de predecir para todos: hubo más empates (28.2 % contra 24.5 %
en validación), y el empate es el resultado más difícil de anticipar. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>68. ¿Qué otras métricas pudieron usar?</b></summary>

El Brier score (error cuadrático de las probabilidades, castiga menos la sobreconfianza) y el RPS
(*ranked probability score*), que considera que el resultado es ordinal (local > empate > visita) y
es muy usado en fútbol. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

## I. Resultados

<details><summary><b>69. ¿Qué modelo eligieron y por qué?</b></summary>

La validación eligió M4 por poco. En prueba su ventaja no se sostuvo y M0 fue mejor. Como las
diferencias entre especificaciones son menores al ruido, por parsimonia preferimos M0: tres
variables, fácil de explicar y el mejor en prueba. Somos conscientes de que esa preferencia usa
información de prueba y habría que confirmarla con la siguiente temporada. → [cap. 18](18_hallazgos_y_pendientes.md) (C6)
</details>

<details><summary><b>70. Si el modelo no le gana al mercado, ¿qué aporta?</b></summary>

Tres cosas. Demuestra que las estadísticas públicas contienen información (mejora clara sobre la
referencia ingenua y 84 % de la ventaja del mercado). Es transparente: sabemos qué variables pesan y
cuánto. Y estima goles y marcadores, no solo el 1X2. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>71. ¿Dónde pierde el modelo contra el mercado?</b></summary>

En victorias locales (+0.011) y empates (+0.010); en victorias visitantes el modelo es ligeramente
mejor (−0.010). Total: +0.012 en 799 partidos. Asigna menos probabilidad a los empates y es algo
sobreconfiado con los favoritos claros. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>72. ¿Afectó la pandemia al modelo?</b></summary>

El entrenamiento incluye los 472 partidos a puerta cerrada, cuando la ventaja local desapareció. Al
reentrenar M0 sin ellos, la probabilidad media de victoria local en prueba sube de 42.9 % a 44.1 %,
pero el LogLoss no mejora (1.0306 → 1.0311). La pandemia no explica la brecha con el mercado.
→ [cap. 12](12_resultados.md)
</details>

<details><summary><b>73. ¿Qué tan parecidos son el modelo y el mercado?</b></summary>

Mucho: la correlación entre sus probabilidades de victoria local en prueba es r = 0.93. Coinciden en
lo esencial y difieren en los matices, que es donde el mercado gana. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>74. ¿Algún predictor pronostica empates?</b></summary>

No. Ni el modelo ni el mercado señalan nunca el empate como el resultado más probable, aunque
ocurre en uno de cada cuatro partidos. Por eso los aciertos distinguen poco entre predictores.
→ [cap. 12](12_resultados.md)
</details>

<details><summary><b>75. ¿Cuántos partidos acierta cada uno?</b></summary>

En prueba: M0 48.0 %, M4 48.2 %, mercado 48.9 % y "siempre local" 41.5 %. En validación: M0 53.4 %,
mercado 54.2 % y cierre 55.5 %. → [cap. 12](12_resultados.md)
</details>

## J. Código

<details><summary><b>76. ¿Qué hace <code>wc_predictor.py</code>?</b></summary>

Es un módulo de funciones que el notebook importa. Del análisis final usa `load_history()` (lee el
histórico), `build_elo()` (Elo), `season_stats()` (goles ajustados) y `recent_form()` (forma).
Conserva piezas de un predictor del Mundial que **no se usan**. → [cap. 10](10_codigo_wc_predictor.md)
</details>

<details><summary><b>77. ¿Qué es <code>get_lambda()</code> y por qué no se usa?</b></summary>

Una versión heurística que calcula los goles esperados como mezcla con pesos elegidos a mano (50 %,
35 %, 15 %). El modelo final la reemplazó por el GLM de Poisson, donde los pesos (coeficientes) **se
estiman con los datos** por máxima verosimilitud. → [cap. 10](10_codigo_wc_predictor.md)
</details>

<details><summary><b>78. ¿Y <code>simular_partido()</code>?</b></summary>

Simula 30,000 partidos con Poisson (Monte Carlo), con prórroga y penales para eliminatorias. No
forma parte del análisis final: el notebook calcula las probabilidades exactas con Skellam, que dan
casi lo mismo sin error de simulación. → [cap. 10](10_codigo_wc_predictor.md)
</details>

<details><summary><b>79. ¿Qué pasa al importar <code>wc_predictor</code>?</b></summary>

Se ejecuta el código que está fuera de funciones: lee el CSV con ruta relativa e imprime el ranking
Elo. Por eso el notebook muestra esa lista al principio. La buena práctica es proteger ese código con
`if __name__ == "__main__":`. → [cap. 10](10_codigo_wc_predictor.md)
</details>

<details><summary><b>80. ¿Qué es <code>premier_training_data.csv</code>?</b></summary>

Una caché con las variables previas de los 2,696 partidos, para no recalcularlas cada vez (tarda
varios minutos). `RECONSTRUIR_VARIABLES = True` la vuelve a generar. Se reconstruyó desde cero y
coincide con la del equipo. → [cap. 11](11_codigo_analisis_notebook.md)
</details>

<details><summary><b>81. ¿Qué librerías usaron y para qué?</b></summary>

`pandas` (tablas), `numpy` (cálculo), `statsmodels` (GLM con errores estándar y p-valores), `scipy`
(Poisson y Skellam), `scikit-learn` (LogLoss y MAE), `plotly` (gráficas del tablero) y Quarto
(tablero). → [cap. 11](11_codigo_analisis_notebook.md)
</details>

<details><summary><b>82. ¿Por qué <code>statsmodels</code> y no <code>scikit-learn</code> para el modelo?</b></summary>

`statsmodels` da la inferencia completa (errores estándar, z y p-valores, dispersión), como
`summary(glm(...))` en R. `scikit-learn` se enfoca en predicción y aquí solo se usa para las
métricas. → [cap. 11](11_codigo_analisis_notebook.md)
</details>

<details><summary><b>83. ¿Cómo se haría el modelo en R?</b></summary>

`glm(home_goals ~ I(elo_diff/400) + gf_home + ga_away, family = poisson, data = entrenamiento)`, y
lo mismo para el visitante; `predict(type = "response")` da λ; `dpois()` y `outer()` arman la matriz
de marcadores. Los scripts de `equivalencias_R/` lo hacen y dan **exactamente** los mismos
coeficientes y LogLoss. → [Equivalencias en R](equivalencias_R/README.md)
</details>

<details><summary><b>84. ¿Cómo verificaron que el análisis es reproducible?</b></summary>

Las métricas del notebook se reproducen a 6 decimales; la caché de variables se reconstruye
idéntica; el tablero recalcula todo desde los datos (también en los servidores de GitHub) y compara
15 cifras con el notebook y el reporte; y los scripts de R dan las mismas cifras en otro lenguaje.
→ [cap. 13](13_dashboard.md), [cap. 14](14_publicacion_en_github.md)
</details>

## K. El tablero

<details><summary><b>85. ¿Por qué Quarto y no Flexdashboard o Shiny?</b></summary>

El análisis está en Python, y con Quarto el tablero ejecuta el mismo código del equipo, así que las
cifras coinciden con el reporte por construcción. Usa la misma lógica que Flexdashboard (páginas,
filas, *value boxes*, pestañas). Shiny necesitaría un servidor encendido; la interactividad que
queríamos funciona en el navegador. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>86. ¿Cómo está organizado el tablero?</b></summary>

Seis páginas en orden de historia: Resumen (conclusión), ¿Qué ocurre?, Patrones, El modelo, Explora
un partido (simulador) y Datos y método (8 pestañas de respaldo). Cada una de las cuatro preguntas
mínimas de las instrucciones tiene su página. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>87. ¿Cómo garantizan que las cifras del tablero coinciden con el reporte?</b></summary>

Ninguna cifra está escrita a mano: todas se calculan al generar el tablero con código en línea
(`` `{python} ...` ``). La pestaña *Reproducibilidad* compara automáticamente 15 cifras con el
notebook y el reporte, y todas coinciden. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>88. ¿Cómo funciona el simulador sin servidor?</b></summary>

Las 380 combinaciones local–visitante de los 20 equipos se calculan en Python al generar el
tablero. El navegador solo filtra y dibuja con Observable JS. Es interactividad del navegador, no
reactividad de un servidor. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>89. ¿Por qué esos colores?</b></summary>

Colores fijos por entidad en todo el tablero: azul = modelo, naranja = mercado, verde = local,
violeta = visitante y gris = empate y contexto. El color se reserva para lo importante, y la paleta
se validó para daltonismo (una primera opción falló y se cambió). → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>90. ¿Por qué esos indicadores?</b></summary>

Máximo tres por página, cada uno responde una pregunta. Resumen: 84 % (la respuesta en un número),
48.0 % de aciertos (traducción intuitiva, con referencias) y "3 variables" (el modelo simple fue el
más robusto). ¿Qué ocurre?: 9,450 partidos, 45.6 % gana el local y 54.3 % gana el favorito.
→ [cap. 13](13_dashboard.md)
</details>

<details><summary><b>91. ¿Qué principios de storytelling aplicaron?</b></summary>

Conclusión primero ("Lectura en 20 segundos"), después el planteamiento (¿qué ocurre?), la evidencia
(patrones) y el conflicto y su resolución (el modelo contra el mercado). Títulos que comunican el
hallazgo, gráfica principal en ≈ 2/3 del ancho y pestañas para el segundo nivel. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>92. ¿Qué muestra la gráfica de "pesas"?</b></summary>

Para cada especificación, su LogLoss relativo a M0 en validación (círculo hueco) y en prueba
(círculo relleno). Muestra en una vista que las variables adicionales ayudaron en validación y
dejaron de ayudar en prueba, mientras que el mercado fue mejor en ambos periodos. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>93. ¿Por qué no hay gráficas de pastel ni gauges?</b></summary>

Porque comparar ángulos o áreas es menos preciso que comparar longitudes, y el material del módulo
pide preguntarse si un gauge "facilita una decisión o solamente ocupa espacio". Se usaron barras
desde cero, líneas y puntos. → [cap. 13](13_dashboard.md)
</details>

## L. Publicación

<details><summary><b>94. ¿Cómo se publicó el tablero?</b></summary>

El código y los datos están en un repositorio público de GitHub. En cada push, GitHub Actions
levanta una máquina Ubuntu, instala Python 3.10 y Quarto 1.8.25 con versiones fijas, recalcula todo,
genera el HTML y lo publica en GitHub Pages. Tarda unos 2 minutos. Es el esquema de la clase, con
Python en lugar de R. → [cap. 14](14_publicacion_en_github.md)
</details>

<details><summary><b>95. ¿Qué pasa si alguien sube un cambio que rompe el tablero?</b></summary>

El job `build` falla y, como `deploy` depende de él (`needs: build`), no se publica nada: el sitio
sigue mostrando la última versión buena. → [cap. 14](14_publicacion_en_github.md)
</details>

<details><summary><b>96. ¿Por qué no subieron el HTML generado?</b></summary>

Porque se genera en GitHub desde el código y los datos. Así se garantiza que lo publicado
corresponde al repositorio, y cada publicación prueba que el proyecto se puede reproducir en otra
computadora. → [cap. 14](14_publicacion_en_github.md)
</details>

## M. Ética y alcance

<details><summary><b>97. ¿Se podría ganar dinero con este modelo?</b></summary>

No lo evaluamos y no es el objetivo: el proyecto es académico. Como el modelo no supera al mercado y
las casas cobran un margen de ≈ 5 %, no hay evidencia de una ventaja explotable. → [cap. 15](15_limitaciones_y_extensiones.md)
</details>

<details><summary><b>98. ¿Hay consideraciones éticas?</b></summary>

Sí. Las apuestas pueden causar daño. Por eso el proyecto no da recomendaciones de apuesta, el
simulador lleva un aviso de uso académico y, como piden las instrucciones, cualquier simulación de
apuestas debería usar solo capital ficticio. → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>99. ¿Sus resultados son causales?</b></summary>

No. Es un modelo predictivo: los coeficientes indican asociación. Que la diferencia de Elo esté
asociada a más goles no significa que "subir el Elo" cause goles; ambos reflejan la calidad del
equipo. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>100. ¿Qué harían para mejorarlo?</b></summary>

Corrección de Dixon–Coles para los empates; optimizar K, k y el decaimiento con validación temporal;
probar si el modelo aporta información que el mercado no tiene combinándolos en una regresión; un
Elo que incluya la segunda división; xG cuando haya historial; y comparar contra cuotas de cierre.
→ [cap. 15](15_limitaciones_y_extensiones.md)
</details>
