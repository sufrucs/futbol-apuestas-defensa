# 2. Contexto, pregunta y datos

[← Panorama](01_panorama.md) · [Índice](README.md) · [Siguiente: limpieza →](03_limpieza_de_datos.md)

## 2.1 El contexto: fútbol y apuestas en 5 ideas

1. **La Premier League** es la primera división de Inglaterra: 20 equipos, cada uno juega contra
   todos dos veces (local y visitante), así que hay **380 partidos por temporada**. Los 3 últimos
   descienden y suben 3 de la segunda división (Championship).
2. **Resultado 1X2.** Todo partido termina en una de tres opciones: **1** = gana el local,
   **X** = empate, **2** = gana el visitante. Es la apuesta más común y la que modelamos.
3. **Cuota decimal.** Es cuánto te pagan por cada peso apostado si aciertas (incluye tu peso).
   Una cuota de 2.50 paga 2.50 por cada 1 apostado.
4. **Probabilidad implícita.** Si la apuesta fuera "justa", la cuota sería 1/probabilidad; por
   eso 1/cuota es la probabilidad que el mercado le asigna al resultado: 1/2.50 = 40 %.
5. **Margen de la casa.** Las tres probabilidades brutas (1/cuota) suman **más de 100 %**; el
   exceso (≈ 5 %) es la ganancia esperada de la casa de apuestas. Para comparar con nuestro
   modelo se "normalizan" para que sumen 100 % (ver [capítulo 8](08_cuotas_y_mercado.md)).

## 2.2 La pregunta de investigación

Las instrucciones piden "formular una pregunta de investigación y las preguntas secundarias… una
hipótesis, variable objetivo, variables explicativas, población de interés, unidad de análisis,
periodo y alcance geográfico". Esta es la formulación del tablero y del README del repositorio:

| Elemento | Definición |
|---|---|
| **Pregunta principal** | ¿Qué tan bien anticipan el resultado de un partido de la Premier League (victoria local, empate o victoria visitante) las estadísticas disponibles **antes** del encuentro, comparadas con las probabilidades implícitas en las cuotas de apuestas? (Así en el README del repositorio; el tablero dice lo mismo con "gana el local, empate o gana el visitante" y "frente a". El reporte la formula de otra manera: ver [cap. 20](20_el_reporte_entregado.md).) |
| **Preguntas secundarias** | ¿Qué variables pesan más? ¿Cómo cambia el desempeño local y visitante? ¿Qué tan calibradas están las cuotas? ¿Más variables mejoran el pronóstico? |
| **Hipótesis** | Las estadísticas contienen información útil (el modelo supera a una referencia ingenua), pero el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor (el modelo no supera a las cuotas). En el tablero: "el mercado, que además tiene información ventajosa, la aprovecha mejor". |
| **Variable objetivo** | Goles del local y goles del visitante (conteos: 0, 1, 2, …). De ahí se deriva el resultado 1X2. |
| **Variables explicativas** | Diferencia de Elo, promedios de goles a favor y en contra de la temporada, forma reciente (goles), tiros y tiros a puerta; **todas calculadas con partidos anteriores** al que se pronostica. |
| **Población** | Partidos de la Premier League inglesa. |
| **Unidad de análisis** | El partido (una fila = un partido). |
| **Periodo** | 2001/02–2026/27 como histórico (para Elo y exploración); 2019/20–2026/27 para modelar. |
| **Alcance geográfico** | Inglaterra (una sola liga). |

**La misma investigación, vista desde el reporte.** El reporte entregado (`Reporte.pdf`, §2.1 y
§2.2) pone en primer plano otra de las preguntas secundarias: *¿en qué medida agregar variables de
fortaleza y desempeño reciente mejora la capacidad predictiva, y cómo se compara con las cuotas de
apertura?* Su hipótesis es que los modelos ampliados (M1–M4) tendrán menor error de goles y mejores
probabilidades que M0, y su conclusión es que eso se respalda **sólo parcialmente**. La del tablero
pone en primer plano la comparación con el mercado. No se contradicen: cómo se concilian, y qué
responder si preguntan por qué difieren, está en el
[capítulo 1](01_panorama.md#dos-formas-de-plantear-la-pregunta); el reporte, en el
[capítulo 20](20_el_reporte_entregado.md).

**¿Por qué modelar goles y no directamente el resultado?** Porque los goles contienen más
información (no es lo mismo ganar 1–0 que 4–0), permiten calcular la probabilidad de cada
marcador y dan probabilidades 1X2 coherentes. Es el enfoque clásico en la literatura (Maher, 1982;
Dixon y Coles, 1997).

**¿Por qué comparar contra las cuotas?** Porque el mercado de apuestas es la mejor referencia
pública de "cuánto se puede saber" de un partido antes de jugarse: muchos participantes con dinero
en juego lo ajustan continuamente. Superar a una referencia ingenua es fácil; acercarse al mercado
no lo es.

## 2.3 La fuente: Football-Data.co.uk

- **Qué es:** un sitio gratuito que publica, desde los años noventa, un archivo CSV por liga y
  temporada con resultados, estadísticas del partido y cuotas de varias casas de apuestas.
- **Qué usamos:** los archivos de la Premier League (código `E0`), de 2001/02 a 2026/27 (26
  archivos; el último con partidos hasta el 14 de septiembre de 2026).
- **Cómo se obtuvo:** descarga directa desde https://football-data.co.uk/englandm.php. Cada
  temporada está en `https://www.football-data.co.uk/mmz4281/AABB/E0.csv`, donde `AABB` son los dos
  últimos dígitos de los dos años (`2425` = 2024/25). **No se usó una API**: el sitio ofrece los CSV
  listos. (Las instrucciones piden documentar "el uso de APIs cuando corresponda"; aquí no
  correspondió.) Cómo repetir la descarga, el orden de los archivos y por qué una descarga nueva no
  garantiza la misma base: [capítulo 3, §3.7](03_limpieza_de_datos.md#37-reconstruir-la-base-desde-cero).
- **Datos complementarios:** ninguno externo. Las cuotas vienen en los mismos archivos.
- **Nota oficial sobre las cuotas** (archivo `notes.txt` del sitio): las cuotas "previas"
  (sin C) de los partidos de fin de semana se registran **el viernes por la tarde**, y las de
  entre semana **el martes por la tarde**; las columnas con **C** son las de **cierre** (justo
  antes del partido). El proyecto llama "de apertura" a las primeras.
- **Cita en el reporte:** Football-Data (2026), *Football Results, Statistics and Soccer Betting
  Odds Data*, consultado en septiembre de 2026.

## 2.4 Diccionario de las 34 variables de `E0_consolidado.csv`

La base consolidada tiene **9,540 partidos** (del 18-ago-2001 al 14-sep-2026) y **34 columnas**: las
**23** que existen en los 26 archivos de la fuente más **11** complementarias (cuotas y xG). Las
columnas van en este orden en el archivo; el reporte trae el mismo diccionario en su apéndice A.1
(Cuadro 9). Cómo se construyó: [capítulo 3](03_limpieza_de_datos.md).

### Identificación y resultado

| Variable | Significado | Ejemplo (último partido de la base) |
|---|---|---|
| `Div` | División. En la Premier League siempre es `E0` (la versión anterior de la base no la tenía) | E0 |
| `Date` | Fecha del partido (en el CSV, AAAA-MM-DD) | 2026-09-14 |
| `HomeTeam` / `AwayTeam` | Equipo local / visitante (45 equipos distintos en la base) | Leeds / Newcastle |
| `FTHG` / `FTAG` | **F**ull **T**ime **H**ome/**A**way **G**oals: goles al final del partido | 4 / 1 |
| `FTR` | **F**ull **T**ime **R**esult: H (local), D (empate, *draw*), A (visitante, *away*) | H |
| `HTHG` / `HTAG` / `HTR` | Lo mismo al **medio tiempo** (*Half Time*) | 3 / 0 / H |
| `Referee` | Árbitro (153 distintos). En el archivo va justo después de `HTR` | — |

### Estadísticas del partido

| Variable | Significado | Máximo de un equipo en la base |
|---|---|---|
| `HS` / `AS` | Tiros (*Shots*) del local / visitante | 43 / 37 |
| `HST` / `AST` | Tiros a puerta (*Shots on Target*) | 24 / 20 |
| `HF` / `AF` | Faltas cometidas (*Fouls*) | 33 / 29 |
| `HC` / `AC` | Tiros de esquina (*Corners*) | 20 / 19 |
| `HY` / `AY` | Tarjetas amarillas (*Yellow*) | 7 / 9 |
| `HR` / `AR` | Tarjetas rojas (*Red*) | 3 / 2 |

El máximo de goles de un equipo es 9 (cuatro partidos, todos reales: por ejemplo, Liverpool 9–0
Bournemouth en 2022 y Southampton 0–9 Leicester en 2019).

### Cuotas y goles esperados

| Variable | Significado | Disponible desde | Partidos con dato |
|---|---|---|---|
| `B365H` / `B365D` / `B365A` | Cuotas de **Bet365** para local / empate / visitante | 2002/03 | 9,160 |
| `AvgH` / `AvgD` / `AvgA` | Cuota **promedio del mercado** registrada antes del partido ("apertura" en el proyecto) | 2019/20 | 2,700 |
| `AvgCH` / `AvgCD` / `AvgCA` | Cuota promedio **de cierre** | 2019/20 | 2,700 |
| `HxG` / `AxG` | Goles esperados (*expected goals*) del local / visitante | 2026/27 | 40 |

> **Cuidado conceptual:** las estadísticas del partido (tiros, goles, etc.) **ocurren durante** el
> partido. Nunca se usan para pronosticar ese mismo partido; solo sirven para construir promedios
> de partidos **anteriores**. Usarlas directamente sería "hacer trampa" (fuga de información).

**En el código.** `wc_predictor.load_history()` lee este archivo y renombra cinco columnas
(`Date` → `date`, `HomeTeam` → `home_team`, `AwayTeam` → `away_team`, `FTHG` → `home_score`,
`FTAG` → `away_score`); el tablero lo lee con `datos_dashboard.cargar_historico()`. Ninguno de los
modelos usa cuotas ni xG como variables explicativas: las cuotas sólo sirven de referencia.

## 2.5 Diccionario de las 24 variables de `premier_training_data.csv`

Es la **base de modelación**: una fila por partido desde el 9-ago-2019, con las variables
**previas** al partido que construye `Analisis.ipynb` (§2 y §5, con las funciones de
`wc_predictor.py`) y los goles reales. Tiene **2,696 filas × 24 columnas** y ningún nulo: de los
2,700 partidos desde agosto de 2019 se excluyen los 4 primeros partidos de equipos sin historial
previo de tiros (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026). Se reparte en
entrenamiento (1,897), validación (380) y prueba (419). El archivo está en el repositorio como
"caché": el tablero lo lee para no reconstruir todo, y su huella SHA-256 (`37de4c4c…`) está en el
README. El reporte trae este diccionario en su apéndice A.2 (Cuadro 10).

Las 24 columnas se agrupan así: 3 claves + 3 de Elo + 4 promedios de temporada + 4 de forma en
goles + 8 de tiros + 2 objetivos = 24. El ejemplo es la primera fila: **Liverpool–Norwich,
9-ago-2019** (terminó 4–1).

| Variable | Significado | Cómo se calcula | Ejemplo |
|---|---|---|---|
| `Date`, `HomeTeam`, `AwayTeam` | Claves del partido | — | 2019-08-09 · Liverpool · Norwich |
| `elo_home` / `elo_away` | Elo de cada equipo **antes** del partido | Todos los partidos previos desde 2001/02, K = 15 ([cap. 4](04_elo.md)) | 1780.87 / 1437.66 |
| `elo_diff` | `elo_home − elo_away`, en puntos | El modelo la divide entre 400 al estimar (`X["elo_diff"] / ESCALA_ELO`) | 343.21 (÷ 400 = 0.858) |
| `gf_home` / `ga_home` | Promedio de goles a favor / en contra del local en la temporada, con partidos anteriores | Con k = 0, sólo la temporada en curso; antes de su primer partido, la temporada anterior ([cap. 5](05_promedios_ajustados_y_forma.md)) | 2.3421 / 0.5789 (los de Liverpool en 2018/19) |
| `gf_away` / `ga_away` | Lo mismo para el visitante | Un ascendido sin temporada previa en Premier toma el promedio de la liga | 1.4105 / 1.4105 (promedio de la liga en 2018/19) |
| `form_gf_home` / `form_ga_home` | Goles a favor / en contra en los **últimos 10 partidos** del local | Promedio ponderado con decaimiento 0.85 (el más reciente pesa más); no se reinicia cada temporada | 2.6617 / 0.6325 |
| `form_gf_away` / `form_ga_away` | Lo mismo para el visitante | Para Norwich salen de sus últimos partidos en Premier (2015/16) | 0.9062 / 1.6870 |
| `shots_for_home` / `shots_against_home` | Tiros hechos / recibidos por el local, últimos 10 partidos | Misma ponderación | 15.38 / 8.15 |
| `shots_for_away` / `shots_against_away` | Lo mismo para el visitante | Misma ponderación | 12.05 / 12.90 |
| `sot_for_home` / `sot_against_home` | Tiros a puerta hechos / recibidos por el local | Misma ponderación | 5.25 / 2.72 |
| `sot_for_away` / `sot_against_away` | Lo mismo para el visitante | Misma ponderación | 3.47 / 4.64 |
| `home_goals` / `away_goals` | Goles reales: las **variables objetivo** | `FTHG` y `FTAG` del partido | 4 / 1 |

Qué usa cada modelo (ecuación del local; la del visitante es la espejo):

| Modelo | Variables | Cuántas |
|---|---|---|
| M0 | `elo_diff`, `gf_home`, `ga_away` | 3 |
| M1 | M0 + `form_gf_home`, `form_ga_away` | 5 |
| M2 | M0 + `shots_for_home`, `shots_against_away` | 5 |
| M3 | M0 + `sot_for_home`, `sot_against_away` | 5 |
| M4 | M0 + las seis anteriores | 9 |

`elo_home` y `elo_away` no entran por separado: la diferencia resume la fuerza relativa sin meter
dos variables casi redundantes en la misma ecuación.

## 2.6 Decisiones sobre los datos

> **Decisión:** usar los CSV gratuitos de **Football-Data.co.uk** (el archivo `E0` de cada
> temporada).
>
> **Alternativas:** (a) **Una API de datos de fútbol**, como football-data.org — datos en JSON por
> consulta, cómoda para resultados y calendarios; en contra: pide registrarse para obtener una
> clave, limita las consultas en su nivel gratuito y habría que programar la descarga de 25
> temporadas y revisar qué campos incluye (no se probó). (b) **Proveedores de pago** (Opta / Stats
> Perform, StatsBomb) — datos de eventos muy detallados (cada tiro con su xG); en contra: cuestan y
> su licencia no permite publicarlos en un repositorio público. (c) **FBref o Understat** — tienen xG
> por partido de las temporadas recientes; en contra: no traen cuotas, no ofrecen descarga oficial
> (habría que hacer *web scraping*, con restricciones de uso) y escriben los nombres de los equipos
> de otra forma, así que habría que emparejarlos con Football-Data. (d) **Conjuntos de Kaggle** —
> cómodos, pero muchos son copias de Football-Data sin procedencia ni fecha de actualización claras.
> (e) **Football-Data** (la elegida).
>
> **Por qué ésta:** da, en un solo lugar, gratis y sin registro, las tres cosas que la pregunta
> necesita: resultados, estadísticas para construir variables previas (tiros) y cuotas para
> comparar (de varias casas, con su promedio y el cierre). Además, cualquiera puede descargar los
> mismos archivos: ayuda a la reproducibilidad.
>
> **Evidencia en el proyecto:** con 26 archivos se construyó toda la base, y las cuotas promedio de
> apertura y cierre cubren los 2,700 partidos de la modelación. Ninguna alternativa se probó.
>
> **Si preguntan:** "Football-Data trae en un mismo CSV resultados, estadísticas y cuotas, gratis y
> sin registro. Las API piden clave y límites de consultas, y las fuentes de xG no traen cuotas, que
> son justo nuestra referencia."

> **Decisión:** usar como histórico las **26 temporadas de 2001/02 a 2026/27**, aunque la
> modelación empiece en 2019/20.
>
> **Alternativas:** (a) **Sólo desde 2019/20** — base más chica; en contra: el Elo de todos los
> equipos empezaría en 1,500 justo al inicio de la modelación. (b) **Una ventana intermedia** (por
> ejemplo, desde 2010/11 o 2015/16). (c) **Más temporadas** (el sitio publica archivos desde los años
> noventa) — más historia con rendimientos decrecientes; además, con el método de intersección del
> [capítulo 3](03_limpieza_de_datos.md), un archivo antiguo al que le faltara una columna la
> eliminaría de toda la base. No se probó. (d) **2001/02** (la elegida).
>
> **Por qué ésta:** el Elo necesita "calentar": cada equipo empieza en 1,500 y tarda temporadas en
> llegar a su nivel. Con 18 temporadas previas, en agosto de 2019 el Elo ya refleja la jerarquía
> real (en el primer partido de la base, Liverpool tiene 1780.87 y Norwich, recién ascendido,
> 1437.66).
>
> **Evidencia** (cálculo nuestro para la guía, con `build_elo()` del proyecto y K = 15): el Elo al
> 1-ago-2019 de los 20 equipos de 2019/20, según el año en que empieza el histórico:
>
> | Histórico desde | Partidos previos | Desviación estándar del Elo de los 20 | Diferencia media con 2001/02 | Diferencia máxima |
> |---|---|---|---|---|
> | 2001/02 (el usado) | 6,840 | 112.7 | — | — |
> | 2010/11 | 3,420 | 111.6 | 12.3 | 32.7 |
> | 2015/16 | 1,520 | 99.5 | 34.2 | 54.5 |
> | 2018/19 | 380 | 53.9 | 71.7 | 180.7 |
>
> Empezar en 2010/11 casi no cambia nada (la historia más antigua ya pesa poco); empezar en 2018/19
> deja el Elo "aplastado" cerca de 1,500 (la mitad de dispersión) y lo cambia hasta 181 puntos.
>
> **Si preguntan:** "El histórico empieza en 2001 para que el Elo llegue estabilizado a 2019. Lo
> comprobamos: empezar en 2010 casi no cambia el Elo de 2019; empezar en 2018 lo deja aplastado
> cerca de 1,500."

> **Decisión:** **modelar desde el 1-ago-2019**: 2,700 partidos (2,696 tras excluir 4), con
> entrenamiento en 2019/20–2023/24, validación en 2024/25 y prueba desde 2025/26.
>
> **Alternativas:** (a) **Empezar antes y comparar contra Bet365** (cuotas desde 2002/03) — muchos
> más partidos para entrenar; en contra: sería una sola casa (con su propio margen) en vez del
> promedio del mercado, y sin cuotas de cierre. (b) **Entrenar con más historia y comparar contra el
> mercado sólo desde 2019/20** — posible: el modelo tendría más datos; en contra: el fútbol cambia
> (por ejemplo, el VAR llegó a la Premier en 2019/20) y lo antiguo puede representar peor el
> presente; no se probó. (c) **Quitar la etapa sin público** (2020/21) — sí se probó, en el tablero,
> como análisis de sensibilidad. (d) **2019/20** (la elegida).
>
> **Por qué ésta:** 2019/20 es la primera temporada con cuotas **promedio de apertura y de cierre**
> (`Avg`, `AvgC`), que son la referencia con la que se compara el modelo; y deja 5 temporadas de
> entrenamiento, 1 de validación y más de 1 de prueba.
>
> **Evidencia en el proyecto:** las cuotas promedio cubren exactamente los 2,700 partidos desde
> agosto de 2019. La sensibilidad del tablero (M0 reentrenado sin los 472 partidos a puerta cerrada,
> del 17-jun-2020 al 23-may-2021) cambia el LogLoss de prueba de 1.0331 a 1.0328: incluir esa
> etapa no distorsiona el resultado.
>
> **Si preguntan:** "Modelamos desde 2019 porque ahí empiezan las cuotas promedio de apertura y
> cierre, que son nuestra referencia; la historia anterior sirve para el Elo."

## 2.7 Calidad de los datos (auditoría)

Las instrucciones piden revisar "tipos de variables, valores faltantes, registros duplicados,
valores atípicos, errores o inconsistencias, cambios metodológicos en la fuente". El notebook de
limpieza hace 9 revisiones ([capítulo 3, §3.3](03_limpieza_de_datos.md#33-revisiones-de-consistencia-celdas-7-a-16))
y el tablero recalcula varias en la pestaña *Datos y método → Limpieza y calidad*. Esto se encontró:

| Revisión | Resultado | Qué significa |
|---|---|---|
| Registros | 9,540 partidos, 34 columnas, 18-ago-2001 a 14-sep-2026 | Base completa |
| Temporadas | 25 completas con **380 partidos cada una** (9,500) + 40 de 2026/27; en cada temporada completa, 20 equipos con 19 partidos de local y 19 de visitante | No falta ningún partido. La versión anterior de la limpieza perdía 90 partidos de 2003/04 y 2004/05 (quedaban con 335); la nueva los recupera |
| Duplicados (fecha, local, visitante) | 0 | Ningún partido repetido |
| Equipo contra sí mismo | 0 | — |
| Valores negativos en goles, tiros, faltas, córners o tarjetas | 0 | — |
| Goles al descanso mayores que los finales | 0 | — |
| `FTR` incongruente con los goles | 0 | El resultado siempre coincide con el marcador |
| Tiros a puerta mayores que tiros | 1 (Newcastle–West Ham, 15-ago-2021: West Ham con 8 tiros y 9 a puerta) | Error de la fuente; efecto despreciable; se conservó |
| Goles mayores que tiros a puerta | 50 casos (24 de locales y 26 de visitantes) | Plausible: un autogol cuenta como gol, pero no como tiro a puerta del equipo beneficiado |
| Cuotas ≤ 1 · xG negativos | 0 · 0 | — |
| Cuotas Bet365 | faltan en 2001/02 (380 partidos) | Por eso el análisis histórico del favorito empieza en 2002/03 |
| Cuotas promedio (`Avg`, `AvgC`) | sólo desde 2019/20 (faltan 6,840) | **Cambio en la fuente**; por eso la modelación empieza en 2019 |
| xG | sólo 2026/27 (40 partidos) | No se usa: cobertura insuficiente |
| Fechas | dos formatos (año de 2 y de 4 dígitos); 0 inválidas con `format="mixed"`; ninguna fuera de su temporada | El formato mixto se leyó bien |
| Caracteres | ninguno fuera de ASCII | La lectura que ignora bytes inválidos no borró nada |
| Partidos sin historial de tiros | 4 excluidos de la modelación | Primeros partidos en la base de Brentford (2021), Nott'm Forest (2022), Luton (2023) y Coventry (2026) |

**Sobre los faltantes:** no se eliminaron partidos por no tener cuotas o xG. Esas columnas
quedan vacías donde no existen, y cada análisis usa solo los partidos donde la información está
disponible. Así el histórico completo sigue sirviendo para calcular el Elo.

### Cifras de la base

| Qué | Cifra | Sobre qué partidos |
|---|---|---|
| Resultados | local **45.6 %** · empate **24.7 %** · visitante **29.7 %** | 9,500 de las 25 temporadas completas |
| Goles por partido | **2.724** (local 1.535, visitante 1.189) | los mismos 9,500 |
| Favorito de Bet365 (la cuota más baja entre local y visitante; si empatan, el local) | gana **54.2 %** · empate 24.7 % · gana el no favorito 21.0 % | 9,160 partidos con cuotas Bet365 (desde 2002/03) |
| El local es el favorito | 69.6 % | los mismos 9,160 |
| 2003/04 y 2004/05 | 380 partidos cada una; el local ganó 43.9 % y 45.5 % | antes, con 335 partidos: 44.8 % y 44.8 % |
| Temporada sin público (2020/21) | ganaron más los visitantes que los locales: ventaja local de −2.4 puntos porcentuales | 380 |

### El equivalente de la auditoría en R

Ejecutado sobre los archivos del repositorio; las cifras coinciden con las de arriba:

```r
library(readr); library(dplyr); library(lubridate)
e0 <- read_csv("Codigo/proyecto_mod_8/E0_consolidado.csv", show_col_types = FALSE)

dim(e0)                                                   # 9540 34
sum(duplicated(e0[, c("Date", "HomeTeam", "AwayTeam")]))  # 0 duplicados
colSums(is.na(e0))[colSums(is.na(e0)) > 0]                # sólo cuotas y xG
e0 <- e0 |> mutate(temporada = if_else(month(Date) >= 8, year(Date), year(Date) - 1L))
count(e0, temporada) |> filter(n != 380)                  # sólo 2026/27, con 40
e0 |> filter(HST > HS | AST > AS) |> select(Date, HomeTeam, AwayTeam, HST, HS, AST, AS)

completas <- filter(e0, temporada <= 2025)                # 25 temporadas completas: 9,500
round(prop.table(table(completas$FTR)), 4)                # A 0.2971 · D 0.2474 · H 0.4556
mean(completas$FTHG + completas$FTAG)                     # 2.724 goles por partido

b <- filter(e0, !is.na(B365H), !is.na(B365D), !is.na(B365A))
fav_local <- b$B365H <= b$B365A                           # favorito = cuota más baja (empate de cuotas: local)
c(partidos = nrow(b),
  gana_favorito = mean(ifelse(fav_local, b$FTR == "H", b$FTR == "A")),   # 0.5425
  empate = mean(b$FTR == "D"),                                           # 0.2471
  local_favorito = mean(fav_local))                                      # 0.6957

td <- read_csv("Codigo/proyecto_mod_8/premier_training_data.csv", show_col_types = FALSE)
dim(td); range(td$Date); sum(is.na(td))                   # 2696 24 · 2019-08-09 a 2026-09-14 · 0
```

La temporada se define de agosto a julio, igual que en `wc_predictor.season_stats()` y en el
tablero. En Python (pandas) lo mismo es `df.duplicated([...]).sum()`, `df.isna().sum()`,
`df.groupby("temporada").size()` y `df["FTR"].value_counts(normalize=True)`.

