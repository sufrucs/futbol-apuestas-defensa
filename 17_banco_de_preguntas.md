# 17. Banco de preguntas

[← Guion](16_guion_exposicion.md) · [Índice](README.md) · [Siguiente: hallazgos y pendientes →](18_hallazgos_y_pendientes.md)



**Temas:** [A. Proyecto](#a-el-proyecto) · [B. Datos y limpieza](#b-datos-y-limpieza) ·
[C. Elo](#c-elo) · [D. Shrinkage y forma](#d-promedios-de-la-temporada-shrinkage-y-forma-reciente) ·
[E. Poisson y regresión](#e-poisson-y-regresión) · [F. Probabilidades 1X2](#f-de-goles-a-probabilidades) ·
[G. Cuotas y mercado](#g-cuotas-y-mercado) · [H. Evaluación](#h-evaluación) ·
[I. Resultados](#i-resultados) · [J. Código](#j-código) · [K. Tablero](#k-el-tablero) ·
[L. Publicación](#l-publicación) · [M. Ética y alcance](#m-ética-y-alcance) ·
[N. Calibración y comprobaciones posteriores](#n-calibración-y-comprobaciones-posteriores)

> **Versión de las cifras:** son las de la versión entregada (commit `e3bd43f`, 30-sep-2026: K = 15,
> k = 0 y una base de 9,540 partidos), tomadas de [cap. 12](12_resultados.md),
> [cap. 19](19_decisiones_y_alternativas.md) y [cap. 20](20_el_reporte_entregado.md). Las marcadas como
> *cálculo propio* o *comprobación de la guía* se hicieron **después de la entrega**: no están en el
> notebook, el reporte ni el tablero, y se dicen sólo si preguntan, aclarando que son posteriores. Las
> preguntas 101 a 113 (sección N) y la 64 bis (sección H) son nuevas.

---

## A. El proyecto

<details><summary><b>1. ¿Cuál es la pregunta de investigación?</b></summary>

¿Qué tan bien anticipan el resultado de un partido de la Premier League (victoria local, empate o
victoria visitante) las estadísticas disponibles **antes** del encuentro, comparadas con las
probabilidades implícitas en las cuotas de apuestas? → [cap. 2](02_contexto_y_datos.md)

Así la formulan el README y, casi igual, el tablero. El reporte la plantea de otra forma: cuánto **aportan** las
variables de fortaleza y forma reciente (ver la pregunta 111 y el [cap. 20](20_el_reporte_entregado.md)).
</details>

<details><summary><b>2. ¿Cuál era la hipótesis y se confirmó?</b></summary>

Que las estadísticas contienen información útil (el modelo supera a una referencia ingenua), pero
que el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor (el modelo
no supera a las cuotas). **Se confirmó en ambas partes**, la segunda con un matiz: con validación y
prueba juntas el mercado es mejor, y en prueba sola la diferencia queda al límite (el intervalo
llega a −0.0005). Ésta es la hipótesis del **tablero**; la del **reporte** es otra (¿mejoran los
modelos ampliados?) y se respalda sólo parcialmente (pregunta 111). → [cap. 2](02_contexto_y_datos.md),
[cap. 12](12_resultados.md), [cap. 20](20_el_reporte_entregado.md)
</details>

<details><summary><b>3. Explícanos el proyecto en un minuto.</b></summary>

Con 9,540 partidos de la Premier League construimos variables previas a cada partido (Elo y
promedios de goles de la temporada), ajustamos dos regresiones de Poisson para los goles de cada
equipo y de ahí obtuvimos las probabilidades de victoria local, empate y visita. Las evaluamos con
partidos futuros contra las probabilidades de las cuotas. El modelo acierta 48 % (el mercado 49 %,
"siempre local" 41.5 %) y logra cerca del 80 % de la mejora del mercado sobre una referencia
ingenua, pero no lo supera. Conclusión: las cuotas ya incorporan la información estadística
pública. → [cap. 1](01_panorama.md)
</details>

<details><summary><b>4. ¿Cuál es la conclusión principal?</b></summary>

Las estadísticas previas sí anticipan resultados, pero el mercado sabe un poco más: tiene menor
LogLoss en validación y en prueba, y con ambos periodos juntos la diferencia (+0.016, IC 95 %
+0.006 a +0.025) es pequeña pero distinta de cero (en prueba sola el intervalo incluye el cero, por
muy poco). Un modelo simple se acerca sin encontrar una ventaja sistemática. → [cap. 12](12_resultados.md)
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

9,540 partidos (9,500 en las 25 temporadas completas y 40 de 2026/27), 26 temporadas (18-ago-2001 a
14-sep-2026) y 34 variables. Para modelar se usan 2,696 partidos desde agosto de 2019: 1,897 de
entrenamiento, 380 de validación y 419 de prueba. → [cap. 2](02_contexto_y_datos.md)
</details>

<details><summary><b>10. ¿Qué significan FTHG, FTR, HS, HST y AvgH?</b></summary>

FTHG: goles del local al final del partido (*Full Time Home Goals*). FTR: resultado final (H, D o
A). HS: tiros del local (*Home Shots*). HST: tiros a puerta del local (*Home Shots on Target*).
AvgH: cuota promedio del mercado a la victoria local. → [cap. 2](02_contexto_y_datos.md) (diccionario de 34 variables)
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

(1) Leer primero sólo las cabeceras de los 26 archivos y quedarse con la intersección: 23 columnas
comunes (con `Div`), más 11 complementarias (cuotas y xG): 34 columnas. (2) Leer **todos** los
renglones de cada archivo, sin `on_bad_lines="skip"`: esa opción, en la primera versión, descartaba
en silencio 90 partidos de 2003/04 y 2004/05. (3) Eliminar 1 fila completamente vacía (9,541 →
9,540). (4) Homologar las fechas (`dd/mm/aa` y `dd/mm/aaaa`) con `format="mixed"`. (5) No eliminar
partidos sin cuotas, porque alimentan el Elo. → [cap. 3](03_limpieza_de_datos.md),
[D10 a D12](19_decisiones_y_alternativas.md#d10-23-columnas-comunes--11-complementarias--razonada)
</details>

<details><summary><b>14. ¿Qué problemas de calidad encontraron?</b></summary>

Pocos, y todos documentados. Los controles dan 0 duplicados, 0 equipos contra sí mismos, 0 valores
negativos y 0 resultados que no cuadren con el marcador, y las 25 temporadas completas tienen 380
partidos (2026/27 lleva 40). Lo que sí apareció: 1 fila completamente vacía (se eliminó); 5,320
fechas que no se leían sólo con `dayfirst` (se resolvió con `format="mixed"`); un partido con más
tiros a puerta que tiros (Newcastle–West Ham, 15-ago-2021: 9 contra 8; error de 1 tiro de la fuente,
se conserva); y huecos esperados: cuotas Bet365 ausentes en 2001/02, cuotas promedio solo desde
2019/20 y xG solo en 2026/27 (40 partidos). Ninguno obliga a quitar partidos del periodo de
modelación. Antes había además dos temporadas "incompletas" (2003/04 y 2004/05, con 335 de 380): era
un error de nuestra lectura, que descartaba renglones, y ya está corregido (pregunta 113).
→ [cap. 2](02_contexto_y_datos.md), [cap. 3](03_limpieza_de_datos.md),
[D11](19_decisiones_y_alternativas.md#d11-leer-todos-los-renglones-de-cada-archivo--probada)
</details>

<details><summary><b>15. ¿Por qué quedaron 2,696 partidos y no 2,700?</b></summary>

Se excluyeron 4 partidos: el primero de Brentford (2021), Nott'm Forest (2022), Luton (2023) y
Coventry (2026). Esos equipos no tenían partidos previos en la base, así que sus variables de tiros
quedaban vacías. Se quitan en los cinco modelos, aunque M0 no use tiros, para que M0–M4 se evalúen
con la misma muestra y las comparaciones sean pareadas (Daniel lo documentó en una nota del
notebook). Son 4 de 2,700: 3 en entrenamiento y 1 (Arsenal–Coventry) en prueba, que por eso tiene
419 partidos y no 420. → [cap. 11](11_codigo_analisis_notebook.md),
[D14](19_decisiones_y_alternativas.md#d14-excluir-los-4-partidos-sin-historial-de-tiros-en-m0m4--razonada)
</details>

<details><summary><b>16. ¿Qué es la fuga de información y cómo la evitaron?</b></summary>

Es usar, sin querer, información que no existía en el momento de predecir, lo que da resultados
optimistas. Se evitó de cuatro formas: cada variable se calcula solo con partidos de fechas
**anteriores** (`date < fecha`); el Elo se actualiza después de procesar todos los partidos del
día; la partición es temporal (entrenar con el pasado, evaluar con el futuro); y K y k se eligieron
sólo con temporadas del entrenamiento, sin usar la validación ni la prueba. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>17. ¿Cómo manejaron las fechas?</b></summary>

Los archivos anteriores a 2016/17 usan `dd/mm/aa` y los recientes `dd/mm/aaaa`. Con sólo
`dayfirst=True`, 5,320 fechas no se interpretaban; con `dayfirst=True` y `format='mixed'` quedaron 0
inválidas, y se exportaron en formato ISO (aaaa-mm-dd). Se verificó que ninguna fecha invirtió día y
mes. → [cap. 3](03_limpieza_de_datos.md),
[D12](19_decisiones_y_alternativas.md#d12-fechas-con-formatmixed-y-dayfirsttrue--probada)
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
0.909, es decir, 10 a 1. Ejemplo: Arsenal (1787) contra Man City (1779), con los ratings al
14-sep-2026, da 0.511 (con la configuración anterior, K = 30, daba 0.537). → [cap. 4](04_elo.md)
</details>

<details><summary><b>20. ¿Qué significa K = 15 y cómo se eligió?</b></summary>

Cuántos puntos se mueve el rating por partido. Con K = 15, ganarle a un rival igual suma
15 × (1 − 0.5) = 7.5 puntos; ganarle a uno 200 puntos más fuerte suma ≈ 11.4, porque era menos
esperado (con K = 30, el valor inicial, serían 15 y 22.8). K no se fijó a mano: se **calibró** con
validación temporal (35 combinaciones de K y k) y K = 15 dio el menor LogLoss. Un K chico vuelve al
Elo más estable: reacciona menos al ruido de las rachas. Quedó en el borde de la rejilla y K importa
poco (preguntas 101 a 105). → [cap. 4](04_elo.md),
[D16](19_decisiones_y_alternativas.md#d16-k--15-en-el-elo--probada)
</details>

<details><summary><b>21. ¿Por qué la diferencia de Elo se divide entre 400?</b></summary>

Para usar la misma escala de la fórmula de Elo, donde 400 puntos es la unidad natural. El
coeficiente se lee "por cada 400 puntos de diferencia". Dividir entre una constante no cambia las
predicciones, solo la escala del coeficiente. → [cap. 4](04_elo.md), [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>22. ¿Cuánto vale jugar en casa, en puntos Elo?</b></summary>

≈ 50 puntos. En la gráfica de deciles, las curvas de victoria local y visitante se cruzan cuando el
local es ≈ 50 puntos más débil (50.0 con la interpolación del tablero): jugar en casa compensa esa
diferencia. Con la configuración anterior (K = 30) eran ≈ 60 (62.6): al bajar K el Elo se mueve menos
y los "puntos" son más chicos, así que la cifra sólo se compara con la misma K.
→ [cap. 12](12_resultados.md), [cap. 4](04_elo.md)
</details>

<details><summary><b>23. ¿Qué limitaciones tiene su Elo?</b></summary>

No incluye la ventaja de local ni el margen de victoria (ganar 1–0 o 5–0 mueve lo mismo), y solo
usa partidos de Premier: un ascendido nuevo empieza en 1,500 y uno que regresa conserva su rating
de hace años, sin regresión a la media entre temporadas. K sí se calibró; el rating inicial (1,500) y
la escala (400) no. → [cap. 15](15_limitaciones_y_extensiones.md),
[D18](19_decisiones_y_alternativas.md#d18-elo-sin-localía-sin-margen-de-victoria-y-sin-regresión-a-la-media--razonada)
</details>

## D. Promedios de la temporada (shrinkage) y forma reciente

<details><summary><b>24. ¿Qué es el shrinkage y qué significa k = 0?</b></summary>

Al inicio de la temporada, con pocos partidos, el promedio de goles es muy ruidoso. El *shrinkage*
lo mezcla con una referencia previa (la temporada anterior del equipo): con n partidos, la
temporada actual pesa n / (n + k). El valor de k se **calibró** con validación temporal y ganó
**k = 0**: el peso es 1 desde el primer partido de la temporada, es decir, **sin mezcla**; antes del
primer partido (n = 0) sí se usa la referencia previa. Con el valor inicial (k = 10) la temporada
pesaba la mitad con 10 partidos y 79 % con 38. La idea es razonable, pero en la validación no mejoró
el pronóstico: el Elo ya aporta la historia de largo plazo. La fórmula sigue en el código porque k se
puede recalibrar (preguntas 101 y 103). → [cap. 5](05_promedios_ajustados_y_forma.md),
[D20](19_decisiones_y_alternativas.md#d20-goles-de-la-temporada-con-shrinkage-y-k--0--probada)
</details>

<details><summary><b>25. Dame un ejemplo numérico de shrinkage.</b></summary>

Un equipo lleva 5 partidos con 2.0 goles por partido y la temporada pasada promedió 1.5. Con k = 10
(el valor inicial), el peso de la temporada actual es 5/15 = 1/3 y el promedio ajustado es
1/3 × 2.0 + 2/3 × 1.5 = **1.67**: el arranque bueno cuenta, pero sin exagerarlo. Con k = 0 (el
calibrado), el peso es 5/5 = 1 y el promedio es simplemente **2.00**. Caso real: tras 4 partidos de
2026/27, Arsenal lleva 2.00 goles a favor y 0.25 en contra (con k = 10 habrían sido 1.91 y 0.58). Por
eso, al inicio de temporada, los promedios varían mucho. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>26. ¿Qué pasa con un equipo recién ascendido?</b></summary>

No tiene temporada anterior en Premier, así que su valor previo es el promedio de goles de la liga
(en 2019, 1.41 para Norwich). Con k = 0 ese valor sólo se usa **antes de su primer partido**; desde
el primero, cuenta su propio promedio de la temporada. Sigue siendo una limitación: los ascendidos
suelen ser más débiles que el promedio. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>27. ¿Qué es la forma reciente?</b></summary>

Un promedio ponderado de los últimos 10 partidos, con pesos 0.85^antigüedad normalizados: el más
reciente pesa 18.7 %, el más antiguo 4.3 % y los tres últimos suman ≈ 48 %. Se calcula para goles,
tiros y tiros a puerta, a favor y en contra. → [cap. 5](05_promedios_ajustados_y_forma.md)
</details>

<details><summary><b>28. ¿Por qué la forma reciente no mejoró el modelo?</b></summary>

Porque se traslapa con lo que ya miden el Elo y los promedios de goles de la temporada, y agrega
ruido. En validación M1 mejoró apenas (−0.0019 de LogLoss) y en prueba empeoró (+0.0016); ambas
diferencias son pequeñas, del tamaño del ruido. → [cap. 12](12_resultados.md)
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
media se parece a la varianza (1.53 contra 1.70 del local; 1.19 contra 1.34 del visitante) y, dentro
del modelo, la dispersión de Pearson es 0.996 y 1.036. → [cap. 6](06_poisson_y_regresion.md)
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

En la ecuación del local es 0.6283 por cada 400 puntos. +100 puntos (D = 0.25) multiplican los goles
esperados del local por $e^{0.6283 \times 0.25} ≈ 1.170$ (+17.0 %). En la del visitante (−0.6854)
los multiplican por ≈ 0.84 (−15.7 %). Con +400 puntos (D = 1), los goles del local se multiplican
por $e^{0.6283} ≈ 1.87$ (el ejemplo del reporte). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>36. ¿Qué variable pesa más?</b></summary>

La diferencia de Elo. En escala comparable (+1 desviación estándar, ≈ 151 puntos) sube 26.7 % los
goles esperados del local y baja 22.8 % los del visitante. Le siguen los goles a favor del local
(+10.7 %). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>37. ¿Son significativos los coeficientes de M0?</b></summary>

Los dos principales sí. En la ecuación del local, el Elo (z = 10.0) y los goles a favor (z = 4.8); en
la del visitante, el Elo (z = −9.9) y sus goles a favor (z = 2.9, p = 0.004). Los **goles en contra
del rival** son más débiles: en el local quedan en el límite del 5 % (p = 0.0498) y en el visitante
no son significativos (p = 0.506), así que no hay que presentarlos como un hallazgo firme (con
K = 30 y k = 10 eran significativos en el local, p = 0.008: con K = 15 el Elo resume más de la fuerza
del equipo). Las constantes tampoco se distinguen de cero (p = 0.621 y 0.781).
→ [cap. 6](06_poisson_y_regresion.md), [cap. 12](12_resultados.md)
</details>

<details><summary><b>38. ¿Cómo se interpreta el intercepto?</b></summary>

Es log λ cuando todas las variables valen cero. Como "cero goles promedio" no es realista, no se
interpreta directamente ($e^{0.0433} ≈ 1.04$ en el local). Lo que importa es que cada ecuación tiene
su propio intercepto, así que la ventaja de local se **estima** y no se impone. En M0 las constantes
no se distinguen de cero (p = 0.621 y 0.781): la ventaja de jugar en casa no está en la constante,
sino en la suma de los términos (con dos equipos idénticos, M0 da λ = 1.486 al local y 1.248 al
visitante). → [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>39. ¿Por qué dos regresiones y no una?</b></summary>

Una para los goles del local y otra para los del visitante. Así cada una tiene su intercepto y sus
coeficientes, y la ventaja de local sale de los datos. Por ejemplo, la diferencia de Elo tiene un
coeficiente propio en cada ecuación: +0.628 en la del local y −0.685 en la del visitante.
→ [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>40. ¿Qué es la dispersión de Pearson y por qué importa?</b></summary>

Es la suma de residuos de Pearson al cuadrado entre los grados de libertad. Si vale ≈ 1, la
varianza es ≈ la media, como supone Poisson. Si fuera mucho mayor (sobredispersión), los errores
estándar saldrían demasiado pequeños y convendría una binomial negativa. Aquí es 0.996 y 1.036.
→ [cap. 6](06_poisson_y_regresion.md)
</details>

<details><summary><b>41. ¿Qué es la multicolinealidad? ¿Es un problema en M4?</b></summary>

Es cuando las variables explicativas están muy correlacionadas (tiros y tiros a puerta: 0.86; VIF
máximo 5.56). No sesga las predicciones, pero vuelve inestables los coeficientes individuales. Por
eso los modelos se comparan por su desempeño fuera de muestra y no por la significancia de cada
coeficiente. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>42. ¿Qué especificaciones compararon?</b></summary>

M0 (base: Elo y goles de la temporada, 3 variables por ecuación) → M1 (+ forma) → M2 (+ tiros) → M3
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

Arsenal (local) contra Man City, con información hasta el 14-sep-2026: λ = 1.54 y 1.27.
Probabilidades: 43.65 % Arsenal, 25.00 % empate, 31.35 % City. El marcador más probable es 1–1, con
11.80 %. (El reporte usa como corte el 20-sep y el tablero el 15-sep; da lo mismo, porque no hubo
partidos entre el 15 y el 19.) → [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>46. ¿Por qué el marcador más probable es 1–1 si el favorito es el local?</b></summary>

Porque la victoria local agrupa muchos marcadores (1–0, 2–0, 2–1…) y el empate pocos. El 1–1 es el
marcador **individual** más probable, pero la suma de todos los marcadores de victoria local es
mayor. Marcador más probable ≠ resultado más probable. → [cap. 7](07_de_goles_a_probabilidades.md)
</details>

<details><summary><b>47. ¿Qué problema causa el supuesto de independencia?</b></summary>

En teoría, subestima los empates, sobre todo 0–0 y 1–1: es la crítica clásica de Dixon y Coles
(1997). En prueba, M0 asignó en promedio 23.6 % al empate y ocurrieron 28.2 %, pero **eso no prueba
que la independencia sea el problema**: en entrenamiento M0 sí reproduce los empates (22.7 %
esperado contra 22.8 % real) y el parámetro de Dixon–Coles estimado sale ≈ −0.008, indistinguible de
cero (comprobación de la guía). Lo que cambió fue la tasa de empates: 22.8 % en el entrenamiento,
24.5 % en 2024/25 y 27.4 % en 2025/26 (pregunta 109). → [cap. 7](07_de_goles_a_probabilidades.md),
[cap. 15](15_limitaciones_y_extensiones.md)
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
de Shin; al comprobarlo después, el LogLoss del mercado cambia en la cuarta cifra y la conclusión es
la misma (pregunta 110). → [cap. 8](08_cuotas_y_mercado.md),
[D35](19_decisiones_y_alternativas.md#d35-mercado-cuotas-promedio-de-apertura-con-normalización-proporcional--probada)
</details>

<details><summary><b>52. ¿Qué son las cuotas de apertura y de cierre?</b></summary>

Las de "apertura" (`Avg`) son las cuotas promedio que Football-Data registra el viernes por la tarde
para los partidos de fin de semana, o el martes para los de entre semana. Las de cierre (`AvgC`) son
las últimas antes del partido. Las de cierre son más precisas (LogLoss 1.0170 contra 1.0200 en
prueba) porque incorporan más información, como las alineaciones. El reporte advierte que la
disponibilidad exacta de las de apertura al momento del pronóstico requeriría una comprobación
independiente. → [cap. 8](08_cuotas_y_mercado.md),
[cap. 20](20_el_reporte_entregado.md#206-preguntas-que-el-reporte-puede-provocar)
</details>

<details><summary><b>53. ¿Las cuotas entran al modelo?</b></summary>

**No.** Solo son la vara de comparación. El modelo usa exclusivamente estadísticas previas al
partido. → [cap. 8](08_cuotas_y_mercado.md)
</details>

<details><summary><b>54. ¿Están calibradas las cuotas?</b></summary>

En general sí: cuando las cuotas dicen 70 %, el resultado ocurre cerca de 70 %. Hay un leve sesgo en
los extremos, y no son perfectas (en el grupo de 50–60 % dicen 55.0 % y ocurre 48.3 %, con
validación y prueba juntas). El favorito de Bet365 gana 54.2 % de las veces, empata 24.7 % y pierde
21.0 % (9,160 partidos con cuotas). → [cap. 8](08_cuotas_y_mercado.md), [cap. 12](12_resultados.md)
</details>

<details><summary><b>55. ¿Por qué el mercado es mejor que el modelo?</b></summary>

La explicación más plausible es que incorpora información que el modelo no tiene (alineaciones,
lesiones, noticias, rotaciones) y agrega las opiniones de muchos participantes con dinero en juego.
Es consistente con que las cuotas de cierre, que tienen más información, sean aún mejores que las de
apertura (0.9667 contra 0.9706 en validación; 1.0170 contra 1.0200 en prueba), pero no está
probado. La brecha con ambos periodos juntos es +0.016 (IC +0.006 a +0.025).
→ [cap. 12](12_resultados.md)
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
honesta del desempeño. K y k no se eligen con la validación ni con la prueba: se calibraron dentro
del entrenamiento (pregunta 102). → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>58. ¿Qué es el LogLoss?</b></summary>

El promedio de −log(probabilidad asignada al resultado que ocurrió). Si el modelo le dio 43.65 % a la
victoria local (Arsenal–Man City) y ganó el local, ese partido suma −ln(0.4365) = 0.83. Si fue
empate (25.00 %), suma 1.39. Menor es mejor. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>59. ¿Por qué LogLoss y no porcentaje de aciertos?</b></summary>

El LogLoss evalúa las probabilidades completas: premia asignar mucha probabilidad a lo que ocurre y
castiga fuerte la sobreconfianza. Los aciertos ignoran la confianza (60 % y 90 % cuentan igual), y
como nadie pronostica empates, casi no distinguen modelos. Además, el LogLoss es una regla de
puntuación **propia**: se minimiza reportando las probabilidades verdaderas. → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>60. ¿Qué significa un LogLoss de 1.033?</b></summary>

Que en promedio (geométrico) el modelo asignó $e^{-1.033}$ = 35.6 % de probabilidad al resultado que
ocurrió (es el de M0 en prueba). Adivinar al azar da 33.3 % (LogLoss ln 3 = 1.099) y el mercado
36.1 % (1.020). → [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>61. ¿Qué es la referencia ingenua y por qué acierta 41.5 %?</b></summary>

Un modelo de Poisson sin información de los equipos: usa los goles promedio del entrenamiento (1.56
del local y 1.31 del visitante) para todos los partidos. Como siempre favorece al local, acierta
exactamente cuando gana el local: 41.5 % en prueba. Mide cuánto aportan las variables.
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>62. ¿De dónde sale el 80 %?</b></summary>

(LogLoss ingenua − LogLoss M0) / (LogLoss ingenua − LogLoss mercado) en prueba = (1.0868 − 1.0331) /
(1.0868 − 1.0200) = 0.0537 / 0.0668 ≈ 80 %. Es la fracción de la **mejora** del mercado que logra el
modelo, no "80 % tan bueno como el mercado". En validación es 83 %. Es una cifra incierta: su IC 95 %
bootstrap va de 54 % a 101 % en prueba (cálculo propio de la guía, posterior a la entrega).
→ [cap. 12](12_resultados.md),
[D37](19_decisiones_y_alternativas.md#d37-parte-de-la-ventaja-del-mercado-80--para-comunicar--razonada)
</details>

<details><summary><b>63. ¿Qué es el MAE y por qué no coincide con el LogLoss?</b></summary>

El error absoluto medio entre goles reales y esperados. Evalúa λ, no las probabilidades 1X2, y premia
la **mediana**, no la media. Por eso elige otro modelo que el LogLoss: en validación el menor MAE es
de M0 (0.918), que tiene el peor LogLoss de los cinco; en prueba, el menor MAE es de M3 (0.894) y el
menor LogLoss, de M0. De hecho, pronosticar siempre "1 gol" para los dos equipos da un MAE de
0.894988 en prueba, mejor que el de M0 (0.902306) (cálculo propio de la guía). Estimar mejor los
goles no garantiza mejores probabilidades de resultado (pregunta 107).
→ [cap. 9](09_evaluacion_y_validacion.md#96-mae-de-goles-y-por-qué-no-coincide-con-el-logloss)
</details>

<details><summary><b>64. ¿Qué es el bootstrap?</b></summary>

Un método para medir la incertidumbre: se calcula la diferencia de pérdida partido por partido (es
*pareado*: los dos pronósticos se evalúan en los mismos partidos), se remuestrean los partidos con
reemplazo, se promedia y se repite 10,000 veces (semilla 2026). Los percentiles 2.5 y 97.5 forman el
intervalo de 95 %. Si no incluye el cero, la diferencia es distinguible del azar.
→ [cap. 9](09_evaluacion_y_validacion.md)
</details>

<details><summary><b>64 bis. ¿Por qué el tablero usa bootstrap si el modelo no lo usa?</b></summary>

El modelo no necesita bootstrap para entrenarse ni para predecir; lo necesitan las conclusiones. El
notebook da diferencias de LogLoss pequeñas, como 0.013 entre el modelo y el mercado en 419 partidos,
y la pregunta es si son reales o suerte de la muestra. Remuestreamos los partidos 10,000 veces con
reemplazo, recalculamos la diferencia en cada remuestreo y tomamos el 95 % central. Si ese intervalo
no incluye el cero, la diferencia es real. Así sabemos que el modelo sí supera a la referencia
ingenua, que con validación y prueba juntas el mercado sí supera al modelo, y que entre M0 y M4 las
diferencias están dentro del ruido. No cambia ninguna cifra del modelo: sólo les pone barras de error.
→ En el tablero: página **El modelo**, tarjeta "¿Son significativas las diferencias?" ·
[cap. 9](09_evaluacion_y_validacion.md#99-son-significativas-las-diferencias-bootstrap),
[13a.5.6](13a_codigo_datos_dashboard.md#13a56-_bootstrap-y-tabla_bootstrap),
[D36](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)
</details>

<details><summary><b>65. ¿Son significativas las diferencias?</b></summary>

Contra la referencia ingenua, sí, con claridad (−0.054, IC −0.086 a −0.022). Contra el mercado, en
prueba sola el intervalo incluye el cero, por muy poco (+0.013, IC −0.0005 a +0.026); en validación
(+0.019, IC +0.005 a +0.033) y con ambos periodos juntos (+0.016, IC +0.006 a +0.025) no lo incluye:
el mercado es mejor. Entre M0 y M4, en validación M4 gana por un margen mínimo (−0.011, IC hasta
−0.00005) y en prueba no es concluyente (+0.004, IC −0.006 a +0.014). Las dos comparaciones al
límite son **frágiles**: con Diebold–Mariano o con bootstrap por fechas o semanas pueden cambiar de
lado (comprobación de la guía). Lo robusto: M0 supera a la ingenua y, con ambos periodos, el mercado
supera a M0. → [cap. 9](09_evaluacion_y_validacion.md),
[D36](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)
</details>

<details><summary><b>66. ¿Qué es la calibración y cómo sale su modelo?</b></summary>

Un modelo está calibrado si, cuando dice 70 %, el evento ocurre ≈ 70 % de las veces. M0 es algo
sobreconfiado con los favoritos: cuando dice 64.4 %, ocurre 57.0 %; cuando dice 74.1 %, ocurre
68.1 % (con 135 y 47 pronósticos: sirve para explicar, no para afirmar con certeza). El mercado está
mejor calibrado en esa zona, aunque no es perfecto (en el grupo de 50–60 % dice 55.0 % y ocurre
48.3 %). → [cap. 9](09_evaluacion_y_validacion.md), [cap. 12](12_resultados.md)
</details>

<details><summary><b>67. ¿Por qué todos empeoran en prueba, incluido el mercado?</b></summary>

El periodo de prueba fue más difícil de predecir para todos: hubo más empates (28.2 % contra 24.5 %
en validación), y el empate es el resultado más difícil de anticipar. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>68. ¿Qué otras métricas pudieron usar?</b></summary>

El Brier score (error cuadrático de las probabilidades, castiga menos la sobreconfianza) y el RPS
(*ranked probability score*), que considera que el resultado es ordinal (local > empate > visita) y
es muy usado en fútbol. No se reportan en el proyecto, pero después se comprobó que con ambos el
orden de los nueve predictores es exactamente el mismo que con el LogLoss (comprobación de la guía).
→ [cap. 9](09_evaluacion_y_validacion.md),
[D33](19_decisiones_y_alternativas.md#d33-logloss-como-métrica-principal-y-mae-como-complemento--razonada)
</details>

## I. Resultados

<details><summary><b>69. ¿Qué modelo eligieron y por qué?</b></summary>

La validación eligió M4 por un margen mínimo (−0.0109 de LogLoss; el IC llega a −0.00005 y es frágil:
con bootstrap por fechas o semanas ya incluye el cero). En prueba su ventaja no se sostuvo: M0 fue el
mejor de los cinco (1.0331; M4 quedó cuarto, con 1.0367) y M4 − M0 = +0.0037, no concluyente. Como
las diferencias entre especificaciones son del tamaño del ruido, por parsimonia preferimos M0: tres
variables, fácil de explicar y el mejor en prueba. Somos conscientes de que esa preferencia usa
información de prueba y habría que confirmarla con la siguiente temporada; y la conclusión frente al
mercado no depende de ella (M4 tampoco lo supera). → [cap. 9, 9.4](09_evaluacion_y_validacion.md#94-la-selección-de-modelo-un-punto-delicado),
[D28](19_decisiones_y_alternativas.md#d28-m0-como-modelo-principal--probada),
[cap. 18](18_hallazgos_y_pendientes.md) (C6)
</details>

<details><summary><b>70. Si el modelo no le gana al mercado, ¿qué aporta?</b></summary>

Tres cosas. Demuestra que las estadísticas públicas contienen información (mejora clara sobre la
referencia ingenua y cerca de 80 % de la mejora del mercado, aunque esa cifra es incierta). Es
transparente: sabemos qué variables pesan y cuánto. Y estima goles y marcadores, no solo el 1X2.
→ [cap. 12](12_resultados.md)
</details>

<details><summary><b>71. ¿Dónde pierde el modelo contra el mercado?</b></summary>

Sobre todo en las victorias locales (+0.0185); en los empates aporta +0.0078; en las victorias
visitantes el modelo es mejor (−0.0104). Total: +0.0159 en 799 partidos (validación y prueba).
Partido a partido, el mercado le da más probabilidad que M0 al resultado real en el 57.8 % de los
partidos. M0 asigna menos probabilidad a los empates (23.5 % contra 24.3 %) y es algo sobreconfiado
con los favoritos claros. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>72. ¿Afectó la pandemia al modelo?</b></summary>

El entrenamiento incluye los 472 partidos a puerta cerrada (17-jun-2020 a 23-may-2021), cuando la
ventaja local desapareció. Al reentrenar M0 sin ellos, la probabilidad media de victoria local en
prueba sube de 42.6 % a 44.0 %, pero el LogLoss casi no cambia (1.0331 → 1.0328), mientras que la
brecha con el mercado en prueba es de 0.013. La pandemia no explica la brecha con el mercado.
→ [cap. 12](12_resultados.md),
[D38](19_decisiones_y_alternativas.md#d38-sensibilidad-sin-público--probada)
</details>

<details><summary><b>73. ¿Qué tan parecidos son el modelo y el mercado?</b></summary>

Mucho: la correlación entre sus probabilidades de victoria local en prueba es r = 0.94 (0.939). Coinciden en
lo esencial y difieren en los matices, que es donde el mercado gana. → [cap. 12](12_resultados.md)
</details>

<details><summary><b>74. ¿Algún predictor pronostica empates?</b></summary>

No. Ni el modelo ni el mercado señalan nunca el empate como el resultado más probable, aunque
ocurre en uno de cada cuatro partidos. Por eso los aciertos distinguen poco entre predictores.
→ [cap. 12](12_resultados.md)
</details>

<details><summary><b>75. ¿Cuántos partidos acierta cada uno?</b></summary>

En prueba: M0 48.0 %, M4 47.5 %, mercado 48.9 % y "siempre local" 41.5 %. En validación: M0 53.2 %,
mercado 54.2 % y cierre 55.5 %. Los aciertos distinguen poco entre predictores.
→ [cap. 12](12_resultados.md)
</details>

## J. Código

<details><summary><b>76. ¿Qué hace <code>wc_predictor.py</code>?</b></summary>

Es un módulo de funciones que el notebook importa. Del análisis final usa `load_history()` (lee el
histórico), `build_elo()` (Elo, con K = `ELO_K` = 15), `season_stats()` (promedios de la temporada
con *shrinkage*, k = `SHRINKAGE_K` = 0) y `recent_form()` (forma). Conserva piezas de un predictor del
Mundial que **no se usan**. Un comentario de la línea 117 todavía dice que K "por defecto es 30": el
valor real es `ELO_K = 15`. → [cap. 10](10_codigo_wc_predictor.md)
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

Se ejecuta el código que está fuera de funciones: lee `E0_consolidado.csv` con ruta relativa y calcula
los parámetros de la liga (`HOME_FACTOR` y `AWAY_FACTOR`, que el análisis no usa; sólo
`avg_team_goals` sirve, como respaldo de `recent_form`). La versión entregada **ya no imprime nada**
(la inicial imprimía el ranking Elo). Como lee el CSV con ruta relativa, el tablero la importa desde
su carpeta; desde otra falla con `FileNotFoundError`. La buena práctica es proteger ese código con
`if __name__ == "__main__":`.
→ [cap. 10](10_codigo_wc_predictor.md#106-el-bloque-que-se-ejecuta-al-importar)
</details>

<details><summary><b>80. ¿Qué es <code>premier_training_data.csv</code>?</b></summary>

La tabla de variables previas de los 2,696 partidos (2,696 × 24), exportada desde el notebook. El
tablero la lee (`cargar_base_modelacion()`) en lugar de reconstruirla, que tarda alrededor de un
minuto. El notebook **no** la lee: reconstruye la base en cada ejecución (la celda que la exporta
quedó comentada). Con K = 15 y k = 0, la base reconstruida coincide con la guardada hasta el decimal
12; si cambian los datos, K o k, hay que regenerarla. → [cap. 11](11_codigo_analisis_notebook.md),
[D49](19_decisiones_y_alternativas.md#d49-premier_training_datacsv-como-caché--razonada)
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
coeficientes y LogLoss; `06_calibracion.R` repite la rejilla de K y k (unos 8 segundos) con los
mismos resultados. → [Equivalencias en R](equivalencias_R/README.md)
</details>

<details><summary><b>84. ¿Cómo verificaron que el análisis es reproducible?</b></summary>

Las métricas del notebook se reproducen a 6 decimales; la base de variables se reconstruye idéntica
a la guardada; el equipo repitió todo desde cero el 30-sep-2026 en Linux (Python 3.10.20, Quarto
1.8.25) y obtuvo las cifras guardadas; el README publica la huella SHA-256 de los dos CSV; el tablero
recalcula todo desde los datos (también en los servidores de GitHub) y compara 17 cifras con las
salidas guardadas del notebook (coinciden las 17); y los scripts de R dan las mismas cifras en otro
lenguaje. → [cap. 13](13_dashboard.md), [cap. 14](14_publicacion_en_github.md),
[D41](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada),
[D48](19_decisiones_y_alternativas.md#d48-versiones-fijas-y-huellas-sha-256--razonada)
</details>

## K. El tablero

<details><summary><b>85. ¿Por qué Quarto y no Flexdashboard, Shiny o Power BI?</b></summary>

Porque el modelo está en Python y Quarto deja importar ese mismo código (`datos_dashboard.py`
reutiliza `wc_predictor.py` y las funciones del notebook), así que las cifras del tablero coinciden
con las del notebook por construcción. Además produce un sitio estático que GitHub Pages publica
gratis, y usa la misma lógica que Flexdashboard (páginas, filas, *value boxes*, pestañas), que habría
obligado a reescribir el modelo en R. Shiny (y Streamlit o Dash) necesitan un servidor encendido; la
interactividad que queríamos cabe en el navegador. Power BI o Tableau requieren licencia y el tablero
no se reconstruiría desde el código. Ninguna alternativa se probó: se descartaron por razonamiento.
→ [cap. 13](13_dashboard.md),
[D39](19_decisiones_y_alternativas.md#d39-quarto-formato-dashboard--python--razonada)
</details>

<details><summary><b>86. ¿Cómo está organizado el tablero?</b></summary>

Seis páginas en orden de historia: Resumen (conclusión), ¿Qué ocurre?, Patrones, El modelo, Explora
un partido (simulador) y Datos y método (8 pestañas de respaldo: datos y procedencia, limpieza y
calidad, variables, evaluación, limitaciones, reproducibilidad, glosario y equipo). Cada una de las
cuatro preguntas mínimas de las instrucciones tiene su página. → [cap. 13](13_dashboard.md),
[D45](19_decisiones_y_alternativas.md#d45-una-historia-en-seis-páginas-con-títulos-que-dicen-la-conclusión--razonada)
</details>

<details><summary><b>87. ¿Cómo saben que las cifras del tablero son las del notebook y del reporte?</b></summary>

Con dos mecanismos. (1) El tablero no copia cifras: `datos_dashboard.py` importa `wc_predictor.py`,
lee los dos CSV del equipo y repite con el mismo código las funciones del notebook; casi todas las
cifras del texto se calculan al generar el tablero con código en línea (`` `{python} ...` ``), y
quedan unos pocos datos escritos a mano (el "3" de "Variables en el mejor modelo", "18 de agosto de
2001" y "20 equipos"). (2) La pestaña *Reproducibilidad* lee las salidas guardadas del notebook y
compara **17 cifras** (12 LogLoss de M0–M4 y del mercado, en validación y en prueba, más 5 del
ejemplo Arsenal–Man City): coinciden **17 de 17**, también en el servidor de GitHub. Cuando se agregó
M3 a la prueba, la tabla pasó de 16 a 17 cifras sin tocar el tablero. Si el notebook se guardara sin
salidas, el propio tablero diría "HAY DIFERENCIAS". Las cifras del reporte salen del mismo notebook.
→ [cap. 13](13_dashboard.md), [cap. 13a](13a_codigo_datos_dashboard.md),
[D41](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)
</details>

<details><summary><b>88. ¿Cómo funciona el simulador sin servidor?</b></summary>

Las 380 combinaciones local–visitante de los 20 equipos de 2026/27 se calculan en Python al generar
el tablero (`datos_simulador()`, con M0 y corte el 15-sep-2026): λ, P(1X2), marcador más probable y
matriz de marcadores de 0 a 5. `ojs_define(sim=…)` pasa esos datos al navegador y Observable JS arma
los selectores (`Inputs.select`) y el mapa de calor (`Plot.cell`): el navegador solo filtra y dibuja.
Es interactividad del navegador, no reactividad de un servidor, así que funciona en GitHub Pages, que
sólo sirve archivos estáticos (el equivalente en R sería Shiny, que sí necesita un servidor); y no se
reprogramó el modelo en JavaScript, para no tener dos implementaciones. Ejemplo: Arsenal–Man City da
λ = 1.538 / 1.266, 43.65 % / 25.00 % / 31.35 % y 1–1 con 11.80 %. Limitación: no admite ajustes
(lesiones, alineaciones) y el corte es fijo. → [cap. 13](13_dashboard.md),
[cap. 13c](13c_codigo_index_quarto.md),
[D44](19_decisiones_y_alternativas.md#d44-simulador-en-observable-js-con-los-380-cruces-precalculados--razonada)
</details>

<details><summary><b>89. ¿Por qué esos colores?</b></summary>

Colores fijos por entidad en todo el tablero: azul = modelo, naranja = mercado, verde = local,
violeta = visitante y gris = empate y contexto. El color se reserva para lo importante, y la paleta
se validó para daltonismo (una primera opción falló y se cambió). → [cap. 13](13_dashboard.md)
</details>

<details><summary><b>90. ¿Por qué esos indicadores?</b></summary>

Máximo tres por página, cada uno responde una pregunta. Resumen: 80 % (la ventaja del mercado que
alcanza el modelo, en un número), 48.0 % de aciertos (traducción intuitiva, con referencias) y "3
variables" (el modelo simple fue el más robusto). ¿Qué ocurre?: 9,540 partidos, 45.6 % gana el local
y 54.2 % gana el favorito.
→ [cap. 13](13_dashboard.md)
</details>

<details><summary><b>91. ¿Qué principios de storytelling aplicaron?</b></summary>

Conclusión primero (página Resumen: pregunta, hipótesis, resultado y una lectura en cuatro puntos),
después el planteamiento (¿qué ocurre?), la evidencia
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

Si el cambio rompe la construcción, el job `build` falla y, como `deploy` depende de él
(`needs: build`), no se publica nada: el sitio sigue mostrando la última versión buena. Si el cambio
sólo altera cifras, la construcción no falla y sí se publica, pero la pestaña *Reproducibilidad* lo
avisa con ✗ y "HAY DIFERENCIAS" (que la publicación falle en ese caso no se hizo).
→ [cap. 14](14_publicacion_en_github.md),
[D41](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada)
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

Ampliar la rejilla por debajo de K = 15 (guardando la tabla de las 35 combinaciones) y calibrar
también la ventana y el decaimiento de la forma; corregir los empates con Dixon–Coles o una Poisson
bivariada (aunque la comprobación sugiere un efecto pequeño); fijar de antemano que el modelo se
elige en validación; usar intervalos que respeten la dependencia entre partidos (bootstrap por
jornada); reportar la normalización de Shin como sensibilidad; probar si el modelo aporta
información que el mercado no tiene combinándolos en una regresión (o un logit multinomial como
alternativa); xG cuando haya historial; y un Elo que incluya la segunda división.
→ [cap. 19, §19.10](19_decisiones_y_alternativas.md#1910-decisiones-que-hoy-tomaríamos-distinto),
[cap. 15](15_limitaciones_y_extensiones.md)
</details>

## N. Calibración y comprobaciones posteriores

Preguntas nuevas de la versión final: cómo se calibraron K y k, las comprobaciones que se hicieron
después de la entrega (sólo se dicen si preguntan, aclarando que son posteriores) y lo que cambió
respecto de la primera versión.

<details><summary><b>101. ¿Cómo se calibraron K y k?</b></summary>

Con una rejilla de 35 combinaciones (K ∈ {15, 20, …, 45} × k ∈ {0, 5, …, 20}) y validación temporal
de ventana creciente, sólo con M0 y con el LogLoss 1X2. Son tres pliegues dentro del entrenamiento:
para cada temporada (2021/22, 2022/23 y 2023/24) se ajusta M0 con todo lo anterior y se mide su
LogLoss en esa temporada. Se promedia ponderando por partidos (1,140 en total) y gana el menor:
**K = 15, k = 0**, con 0.959558 (pliegues 0.960230 / 0.989315 / 0.929130). Después se reconstruye la
base con esos valores y se crean entrenamiento, validación y prueba.
→ [cap. 9, 9.3](09_evaluacion_y_validacion.md#93-la-calibración-de-k-y-k-validación-temporal-de-ventana-creciente),
[D29](19_decisiones_y_alternativas.md#d29-validación-temporal-con-ventana-creciente--razonada),
[D30](19_decisiones_y_alternativas.md#d30-rejilla-de-35-combinaciones-sólo-con-m0-y-logloss-ponderado--razonada)
</details>

<details><summary><b>102. ¿Por qué no se calibraron con la validación o con la prueba?</b></summary>

Porque cada conjunto ya tiene su trabajo. La validación (2024/25) sirve para elegir entre M0 y M4:
si también eligiera K y k, los mismos 380 partidos tomarían dos decisiones y la comparación saldría
optimista. La prueba no debe participar en **ninguna** decisión; si no, deja de medir el desempeño en
partidos nuevos. Por eso se calibra dentro del entrenamiento y después los coeficientes se estiman
con los 1,897 partidos. → [cap. 9, 9.3](09_evaluacion_y_validacion.md#93-la-calibración-de-k-y-k-validación-temporal-de-ventana-creciente),
[D29](19_decisiones_y_alternativas.md#d29-validación-temporal-con-ventana-creciente--razonada)
</details>

<details><summary><b>103. Si k = 0, ¿se ignora la temporada anterior?</b></summary>

No del todo. Con k = 0 el peso de la temporada en curso es n / (n + 0) = 1 desde el primer partido
jugado, así que de ahí en adelante se usa sólo el promedio de la temporada (sin mezcla). Pero antes
del primer partido (n = 0) sí se usa la referencia previa: la temporada anterior del equipo, o el
promedio de la liga si es ascendido. Por eso, en el primer partido de cada temporada, las variables
son iguales con k = 0 y con k = 10 (Liverpool–Norwich 2019: Liverpool 2.3421 / 0.5789; Norwich,
ascendido, 1.4105 / 1.4105). La historia de largo plazo entra por el Elo.
→ [cap. 5](05_promedios_ajustados_y_forma.md),
[D20](19_decisiones_y_alternativas.md#d20-goles-de-la-temporada-con-shrinkage-y-k--0--probada)
</details>

<details><summary><b>104. ¿K = 15 es el óptimo? Quedó en el borde de la rejilla.</b></summary>

No lo decimos: es el mejor de los valores **probados**. Es el más chico de la rejilla (K < 15 no se
probó), así que el óptimo podría estar por debajo; probarlo es la extensión natural, y el propio
notebook advierte que, si el mejor valor queda en un extremo, conviene ampliar el rango. Además,
K = 20 queda a sólo +0.000031, las 35 combinaciones caben en 0.0055 de LogLoss y el ganador cambia
con la temporada (2022/23 prefería K = 35). Lo robusto es "un K chico y sin mezcla". k = 0 también
está en el extremo, pero es un extremo natural: k no puede ser negativa.
→ [cap. 9, 9.3](09_evaluacion_y_validacion.md#93-la-calibración-de-k-y-k-validación-temporal-de-ventana-creciente),
[D16](19_decisiones_y_alternativas.md#d16-k--15-en-el-elo--probada)
</details>

<details><summary><b>105. ¿Y la configuración anterior (K = 30, k = 10)? ¿No salía un poco mejor?</b></summary>

Fuera de muestra, sí, un poco: M0 con K = 30 y k = 10 da 0.983636 en validación y 1.030640 en
prueba, contra 0.989547 y 1.033076 de la vigente (cálculo propio de la guía, posterior a la entrega).
Pero las diferencias no son concluyentes (+0.0059 [−0.0018, +0.0135] y +0.0024 [−0.0049, +0.0099]),
y la vigente ganó donde se eligió (calibración: 0.959558 contra 0.962178). Volver a K = 30 mirando la
prueba sería elegir con la evaluación, es decir, sobreajustar a la prueba. Y la conclusión no cambia:
con cualquiera de las dos, M0 queda detrás del mercado (0.9706 y 1.0200). Por eso no decimos
"K = 15 es el óptimo", sino "el mejor de los que probamos, en un rango donde K importa poco".
→ [cap. 12](12_resultados.md#la-configuración-anterior-de-k-y-k-fuera-de-muestra),
[D16](19_decisiones_y_alternativas.md#d16-k--15-en-el-elo--probada)
</details>

<details><summary><b>106. ¿Por qué el notebook entregado sólo muestra K = 15 y k = 0? ¿Dónde está la rejilla?</b></summary>

Para que el notebook corra en minutos: con la rejilla activa reconstruiría la base 35 veces (del
orden de 20 a 25 minutos). Quedó activa sólo la ganadora (`K_ELO_CANDIDATOS = [15]` y
`K_SHRINKAGE_CANDIDATOS = [0]`) y la rejilla completa está comentada justo arriba; el README (§3.3)
explica cómo repetirla. La tabla de las 35 combinaciones no está en el entregable: la guía la
reprodujo en Python y en R (`06_calibracion.R`) con los mismos resultados, y vuelve a ganar K = 15,
k = 0. → [cap. 11](11_codigo_analisis_notebook.md#1155-la-rejilla-completa),
[D31](19_decisiones_y_alternativas.md#d31-rejilla-comentada-en-el-notebook-entregado--razonada)
</details>

<details><summary><b>107. M3 tiene el menor MAE en prueba. ¿Por qué no es el modelo?</b></summary>

Porque la meta son las probabilidades 1X2, y eso lo mide el LogLoss, donde M0 es mejor en prueba
(1.0331 contra 1.0339 de M3). El MAE sólo mide qué tan cerca quedan los goles esperados y casi no
distingue modelos: como el error absoluto premia la mediana (1 gol, en una Poisson con λ entre 0.7 y
1.7), pronosticar siempre "1 gol" para los dos equipos da un MAE de 0.894988 en prueba (cálculo propio
de la guía), mejor que el de M0 (0.902306) y sólo 0.0008 peor que el de M3 (0.894173). Por eso el
reporte concluye que su hipótesis se respalda sólo parcialmente (pregunta 111).
→ [cap. 9, 9.6](09_evaluacion_y_validacion.md#96-mae-de-goles-y-por-qué-no-coincide-con-el-logloss),
[cap. 12](12_resultados.md),
[cap. 20](20_el_reporte_entregado.md#206-preguntas-que-el-reporte-puede-provocar)
</details>

<details><summary><b>108. ¿Por qué no un modelo con un ataque y una defensa por equipo (Maher, Dixon–Coles)?</b></summary>

Porque serían unos 52 parámetros fijos (26 equipos en entrenamiento), los equipos que no estaban en el
entrenamiento (Ipswich en validación; Coventry, Hull, Ipswich y Sunderland en prueba) no tendrían
parámetro, y un parámetro fijo no sigue la evolución de un equipo en cinco temporadas. Nuestras
variables se recalculan antes de cada partido para cualquier equipo, con 4 coeficientes por ecuación.
No se probó en el proyecto, pero lo comprobamos después: ese modelo se ajusta mejor al pasado (LogLoss
0.966 contra 0.973 de M0) y pronostica peor, 1.0547 contra 0.9895 en validación y 1.0566 contra 1.0331
en prueba: es sobreajuste. → [cap. 6](06_poisson_y_regresion.md),
[D22](19_decisiones_y_alternativas.md#d22-ataque-propio--defensa-del-rival-sin-parámetros-por-equipo--razonada)
</details>

<details><summary><b>109. ¿Por qué no corregir los empates con Dixon–Coles?</b></summary>

La corrección completa no se probó en el proyecto, y una comprobación posterior sugiere que ayudaría
poco. En prueba, M0 da a los empates 23.6 % y ocurrieron 28.2 %, pero en entrenamiento el modelo los
reproduce bien (22.7 % esperado contra 22.8 % real) y el parámetro ρ de Dixon–Coles, estimado con las
λ de M0, sale ≈ −0.008 (error estándar ≈ 0.03, p = 0.79); aplicarlo apenas mueve el LogLoss de prueba
(1.0331 → 1.0326). Lo que pasó es que la prueba tuvo más empates de lo normal, algo que un modelo
entrenado con el pasado no anticipaba (el mercado tampoco: 24.5 %). Además, ρ se estima junto con las
dos ecuaciones (ya no serían dos GLM separados) y no viene en `statsmodels`. Sigue siendo la extensión
natural. → [cap. 7](07_de_goles_a_probabilidades.md#76-la-debilidad-del-supuesto-los-empates),
[D26](19_decisiones_y_alternativas.md#d26-independencia-condicional-y-skellam-exacta--razonada)
</details>

<details><summary><b>110. ¿Y si se quita el margen con el método de Shin?</b></summary>

Es una comprobación posterior (no está en el entregable). Con Shin (1993) en lugar de la
normalización proporcional, el LogLoss del mercado sería 0.970635 en validación y 1.020971 en prueba
(proporcional: 0.970552 y 1.020000): cambia en la cuarta cifra, un poco para peor, porque ese método
quita probabilidad al empate y los empates ocurrieron 28.2 % en prueba. El mercado sigue muy por
delante de M0 (0.989547 y 1.033076), así que la conclusión es la misma.
→ [cap. 8](08_cuotas_y_mercado.md),
[D35](19_decisiones_y_alternativas.md#d35-mercado-cuotas-promedio-de-apertura-con-normalización-proporcional--probada)
</details>

<details><summary><b>111. ¿Por qué difieren la pregunta del reporte y la del tablero? ¿Se cumplió la hipótesis?</b></summary>

Son dos preguntas complementarias sobre el mismo experimento, con las mismas cifras (salen del mismo
notebook). El **reporte** pregunta en qué medida agregar variables de fortaleza y desempeño reciente
mejora la predicción y cómo se compara con las cuotas de apertura; su hipótesis (los modelos
ampliados mejoran) se respalda **parcialmente**: en validación M4 tiene el menor LogLoss y M0 el
menor MAE; en prueba, M0 el menor LogLoss y M3 el menor MAE. El **tablero** pregunta qué tan bien
anticipan las estadísticas frente a las cuotas; su hipótesis (informan, pero el mercado las aprovecha
mejor) se confirma: el modelo logra cerca de 80 % de la mejora del mercado sin superarlo. Un respaldo
parcial no es un mal resultado, es un hallazgo: más variables no garantizan mejores probabilidades
fuera de muestra.
→ [cap. 20, 20.2](20_el_reporte_entregado.md#202-la-pregunta-y-la-hipótesis-dos-formulaciones-que-conviene-saber-conciliar),
[D4](19_decisiones_y_alternativas.md#d4-dos-formulaciones-de-la-pregunta-reporte-y-tablero--razonada)
</details>

<details><summary><b>112. ¿Qué hace GitHub Actions y por qué hay ejecuciones canceladas?</b></summary>

El flujo `publicar-dashboard.yml` se ejecuta en cada push a `main`: el trabajo `build` (Ubuntu)
instala Quarto 1.8.25 y Python 3.10, instala `requirements.txt`, renderiza el tablero y sube
`_site/`; el trabajo `deploy` (`needs: build`) lo publica en GitHub Pages. Las ejecuciones canceladas
**no son errores**: el flujo usa `concurrency: group: "pages"` con `cancel-in-progress: false`, así
que no interrumpe la ejecución en curso, pero si llegan varios push seguidos sólo queda en cola el más
reciente y los intermedios se cancelan. De las 81 ejecuciones del repositorio, entre las 40 más
recientes hay 37 con éxito y 3 canceladas (todas del 30-sep, entre 21:46 y 22:08, durante ediciones
seguidas de Max); la de `e3bd43f`, la última, terminó con éxito y el sitio publicado muestra la
verificación 17 de 17. → [cap. 14](14_publicacion_en_github.md),
[D47](19_decisiones_y_alternativas.md#d47-github-pages--github-actions--razonada)
</details>

<details><summary><b>113. Vimos una versión anterior (K = 30, k = 10, 9,450 partidos). ¿Qué cambió?</b></summary>

Tres cosas, y la conclusión no cambió. (1) **Limpieza:** ya no se pierden renglones, así que la base
pasó de 9,450 × 33 a 9,540 × 34 (las 25 temporadas completas tienen 380 partidos; se recuperaron 90
de 2003/04 y 2004/05); eso casi no movió el modelo (la diferencia está en la quinta cifra decimal).
(2) **K y k se calibraron:** K de 30 a 15 y k de 10 a 0. (3) **Cifras:** el LogLoss de M0 pasó de
0.9837 / 1.0306 a 0.9895 / 1.0331 (validación / prueba; el cambio viene de K y k, no de los 90
partidos); la "ventaja del mercado que logra el modelo", de 84 % a 80 %; la brecha con el mercado
(validación + prueba), de +0.012 a +0.016, ahora sobre todo en victorias locales; M4 − M0 en
validación, de no significativa (IC hasta +0.0022) a significativa por un margen mínimo (IC hasta
−0.00005); y jugar en casa vale ≈ 50 puntos Elo en vez de ≈ 60. Siguen igual: M0 es el mejor en
prueba, el mercado queda por delante y la partición es 1,897 / 380 / 419.
→ [cap. 12](12_resultados.md), [cap. 19](19_decisiones_y_alternativas.md)
</details>
