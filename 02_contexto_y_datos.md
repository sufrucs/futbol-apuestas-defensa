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
periodo y alcance geográfico". Esta es la propuesta del proyecto:

| Elemento | Definición |
|---|---|
| **Pregunta principal** | ¿Qué tan bien anticipan el resultado de un partido de la Premier League (victoria local, empate o victoria visitante) las estadísticas disponibles **antes** del encuentro, comparadas con las probabilidades implícitas en las cuotas de apuestas? |
| **Preguntas secundarias** | ¿Qué variables pesan más? ¿Cómo cambia el desempeño local y visitante? ¿Qué tan calibradas están las cuotas? ¿Más variables mejoran el pronóstico? |
| **Hipótesis** | Las estadísticas contienen información útil (el modelo supera a una referencia ingenua), pero el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor (el modelo no supera a las cuotas). |
| **Variable objetivo** | Goles del local y goles del visitante (conteos: 0, 1, 2, …). De ahí se deriva el resultado 1X2. |
| **Variables explicativas** | Diferencia de Elo, goles a favor y en contra ajustados, forma reciente (goles), tiros y tiros a puerta; **todas calculadas con partidos anteriores** al que se pronostica. |
| **Población** | Partidos de la Premier League inglesa. |
| **Unidad de análisis** | El partido (una fila = un partido). |
| **Periodo** | 2001–2026 como histórico (para Elo y exploración); 2019/20–2026/27 para modelar. |
| **Alcance geográfico** | Inglaterra (una sola liga). |

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
- **Cómo se obtuvo:** descarga directa desde https://football-data.co.uk/englandm.php. **No se usó
  una API**: el sitio ofrece los CSV listos. (Las instrucciones piden documentar "el uso de APIs
  cuando corresponda"; aquí no correspondió.)
- **Datos complementarios:** ninguno externo. Las cuotas vienen en los mismos archivos.
- **Nota oficial sobre las cuotas** (archivo `notes.txt` del sitio): las cuotas "previas"
  (sin C) de los partidos de fin de semana se registran **el viernes por la tarde**, y las de
  entre semana **el martes por la tarde**; las columnas con **C** son las de **cierre** (justo
  antes del partido). El proyecto llama "de apertura" a las primeras.

## 2.4 Diccionario de las 33 variables de `E0_consolidado.csv`

### Identificación y resultado

| Variable | Significado | Ejemplo |
|---|---|---|
| `Date` | Fecha del partido (AAAA-MM-DD) | 2026-09-14 |
| `HomeTeam` / `AwayTeam` | Equipo local / visitante | Leeds / Newcastle |
| `FTHG` / `FTAG` | **F**ull **T**ime **H**ome/**A**way **G**oals: goles al final del partido | 4 / 1 |
| `FTR` | **F**ull **T**ime **R**esult: H (local), D (empate, *draw*), A (visitante, *away*) | H |
| `HTHG` / `HTAG` / `HTR` | Lo mismo al **medio tiempo** (*Half Time*) | 3 / 0 / H |

### Estadísticas del partido

| Variable | Significado |
|---|---|
| `HS` / `AS` | Tiros (*Shots*) del local / visitante |
| `HST` / `AST` | Tiros a puerta (*Shots on Target*) |
| `HC` / `AC` | Tiros de esquina (*Corners*) |
| `HF` / `AF` | Faltas cometidas (*Fouls*) |
| `HY` / `AY` | Tarjetas amarillas (*Yellow*) |
| `HR` / `AR` | Tarjetas rojas (*Red*) |
| `Referee` | Árbitro |

### Cuotas y goles esperados

| Variable | Significado | Disponible desde |
|---|---|---|
| `B365H` / `B365D` / `B365A` | Cuotas de **Bet365** para local / empate / visitante | 2002/03 |
| `AvgH` / `AvgD` / `AvgA` | Cuota **promedio del mercado** ("apertura" en el proyecto) | 2019/20 |
| `AvgCH` / `AvgCD` / `AvgCA` | Cuota promedio **de cierre** | 2019/20 |
| `HxG` / `AxG` | Goles esperados (*expected goals*) del partido | solo 2026/27 |

> **Cuidado conceptual:** las estadísticas del partido (tiros, goles, etc.) **ocurren durante** el
> partido. Nunca se usan para pronosticar ese mismo partido; solo sirven para construir promedios
> de partidos **anteriores**. Usarlas directamente sería "hacer trampa" (fuga de información).

## 2.5 Calidad de los datos (auditoría)

Las instrucciones piden revisar "tipos de variables, valores faltantes, registros duplicados,
valores atípicos, errores o inconsistencias, cambios metodológicos en la fuente". Esto se
encontró (el tablero lo recalcula en la pestaña *Datos y método → Limpieza y calidad*):

| Revisión | Resultado | Qué significa |
|---|---|---|
| Registros | 9,450 partidos, 33 columnas, 18-ago-2001 a 14-sep-2026 | Base completa |
| Duplicados (fecha, local, visitante) | 0 | Ningún partido repetido |
| `FTR` incongruente con los goles | 0 | El resultado siempre coincide con el marcador |
| Temporadas incompletas | 2003/04 y 2004/05 (335 de 380) | Faltan 45 partidos en cada una; solo afecta al Elo de hace 20 años |
| Tiros a puerta mayores que tiros | 1 (Newcastle–West Ham, 15-ago-2021: 8 tiros y 9 a puerta del visitante) | Error de la fuente; efecto despreciable; no se corrigió |
| Goles mayores que tiros a puerta | 48 casos | Plausible (autogoles), no es error |
| Cuotas Bet365 | faltan en 2001/02 | Por eso el análisis histórico del mercado empieza en 2002/03 |
| Cuotas promedio (Avg) | solo desde 2019/20 | **Cambio en la fuente**; por eso la modelación empieza en 2019 |
| xG | solo 2026/27 (40 partidos) | No se usa: cobertura insuficiente |
| Fechas | 0 inversiones día/mes | Se verificó que el formato mixto se leyó bien |
| Partidos sin historial de tiros | 4 excluidos de la modelación | Equipos debutantes en la base: Brentford (2021), Nott'm Forest (2022), Luton (2023), Coventry (2026) |

**Sobre los faltantes:** no se eliminaron partidos por no tener cuotas o xG. Esas columnas
quedan vacías donde no existen, y cada análisis usa solo los partidos donde la información está
disponible. Así el histórico completo sigue sirviendo para calcular el Elo.

### El equivalente de la auditoría en R

```r
library(readr); library(dplyr)
e0 <- read_csv("Codigo/proyecto_mod_8/E0_consolidado.csv")

nrow(e0); ncol(e0)                                   # 9450 33
sum(duplicated(e0[, c("Date", "HomeTeam", "AwayTeam")]))   # 0 duplicados
colSums(is.na(e0))                                   # faltantes por columna
e0 |> mutate(temporada = ifelse(format(Date, "%m") >= "08",
                                as.integer(format(Date, "%Y")),
                                as.integer(format(Date, "%Y")) - 1)) |>
  count(temporada)                                   # 335 en 2003 y 2004
e0 |> filter(AST > AS | HST > HS)                    # la fila con error
```

En Python (pandas) lo mismo es `df.duplicated([...]).sum()`, `df.isna().sum()` y
`df.groupby("temporada").size()`.
