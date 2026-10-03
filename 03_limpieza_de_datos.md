# 3. Limpieza de datos: `Limpieza de datos.ipynb`

[← Contexto y datos](02_contexto_y_datos.md) · [Índice](README.md) · [Siguiente: Elo →](04_elo.md)

> **En una frase:** el notebook toma los 26 CSV de Football-Data (uno por temporada), se queda con
> las **23 columnas que existen en todos** más **11 de cuotas y goles esperados**, los une **sin
> perder ningún partido**, revisa la calidad con 9 pruebas y exporta la base de **9,540 partidos ×
> 34 columnas** que usan el análisis y el tablero.

Las celdas se numeran **desde 0**, como en el archivo (`cells[0]` … `cells[27]`); en Jupyter son la
1.ª a la 28.ª. El código de cada celda está copiado del notebook entregado (commit `e3bd43f`), y
las salidas son las que quedaron guardadas en él.

## 3.0 Panorama

### Qué produce y dónde encaja

```text
Limpieza de datos.ipynb ──► E0_consolidado.csv ──► Analisis.ipynb + wc_predictor.py ──► premier_training_data.csv
   (este capítulo)            9,540 × 34            (capítulos 4 a 11)                    2,696 × 24
                                  │                                                         │
                                  └─────────► datos_dashboard.py + graficas.py ◄────────────┘
                                                        │
                                                        ▼
                                              index.qmd ──► sitio en GitHub Pages
```

| | |
|---|---|
| **Entrada** | 26 archivos `E0.csv` de Football-Data (2001/02 a 2026/27), guardados por el navegador como `E0.csv`, `E0 (1).csv`, …, `E0 (25).csv` |
| **Salida** | `E0_consolidado_final.csv`, 9,540 filas × 34 columnas. En el repositorio la base se llama **`E0_consolidado.csv`** (ver [Detalles conocidos](#36-detalles-conocidos)) |
| **Quién la usa** | `wc_predictor.load_history()`, que llama `Analisis.ipynb` en su §3, y `datos_dashboard.cargar_historico()` en el tablero. Los dos vuelven a ordenar por fecha |
| **Bibliotecas** | `pandas` (lectura, unión, revisiones), `numpy` (`np.where`), `matplotlib` (una gráfica), `pathlib` (rutas) |

El archivo del repositorio coincide con lo que muestran las salidas del notebook: mismas 9,540 filas
en el mismo orden (por ejemplo, la fila 1568 es Newcastle–West Ham del 15-ago-2021 y la 3460 es
Burnley–Swansea del 13-ago-2016), 61,180 nulos y las 34 columnas en el mismo orden.

### El flujo en un diagrama

```text
26 archivos E0.csv (Football-Data, 2001/02 … 2026/27)
  │ celda 1 ── lee sólo la cabecera de cada archivo (nrows=0) y las intersecta
  │            → 23 columnas comunes (columnas_obligatorias)
  │ celda 2 ── + 11 complementarias (B365 ×3, Avg ×3, AvgC ×3, HxG, AxG) = 34 columnas
  │            lee cada archivo con usecols, utf-8-sig y encoding_errors="ignore"; los apila con pd.concat
  ▼
9,541 filas × 34 columnas
  │ celda 2 ── dropna(how="all"): quita la única fila completamente vacía
  ▼
9,540 filas × 34 columnas  (df_consolidado)
  │ celdas 3–6 ─── diagnóstico: columnas comunes, nulos (61,180, todos en cuotas y xG), tipos, gráfica
  │ celdas 7–16 ── 9 revisiones de consistencia → sólo 2 hallazgos: las fechas y un partido
  │ celdas 17–21 ─ soluciones: fechas con format="mixed" (0 inválidas); el partido se conserva
  │ celdas 22–25 ─ tipos: Date → datetime64; 16 conteos → float64
  │ celda 26 ───── tabla de cobertura por grupo de variables
  ▼ celda 27 ── to_csv(index=False, encoding="utf-8-sig")
E0_consolidado_final.csv · 9,540 × 34      (en el repositorio: E0_consolidado.csv)
```

**Orden de las filas.** El notebook no reordena: las filas quedan en el orden de los archivos, de
2026/27 hacia atrás hasta 2001/02, y dentro de cada temporada en orden cronológico (así vienen en
Football-Data). Lo comprobamos sobre `E0_consolidado.csv`: 26 bloques de temporada, del más
reciente al más antiguo, y fechas no decrecientes dentro de cada bloque. Quien usa la base la ordena
por fecha antes de calcular nada.

### Qué cambió respecto de la versión anterior (la del 22 de septiembre)

| Aspecto | Antes | Ahora (versión entregada) |
|---|---|---|
| Estructura | 2 celdas: un texto y un solo bloque de código | 28 celdas: lectura, diagnóstico, revisiones, soluciones, tipos, cobertura y exportación |
| Columnas | lista escrita a mano: 22 + 11 = **33** (sin `Div`) | intersección calculada: **23** (con `Div`) + 11 = **34** |
| Lectura | `encoding="latin1"`, `on_bad_lines="skip"`, `engine="python"`, todas las columnas y luego `reindex` | `encoding="utf-8-sig"`, `encoding_errors="ignore"`, `usecols`, motor C (el de siempre) |
| Partidos | **9,450**: 2003/04 y 2004/05 con 335 de 380 | **9,540**: las 25 temporadas completas con 380 y 2026/27 con 40 |
| Filas vacías | `dropna(subset=["HomeTeam", "AwayTeam"], how="all")` | `dropna(how="all")` |
| Orden | por fecha, del más reciente al más antiguo | el de los archivos (sin reordenar) |
| Revisiones de calidad | ninguna dentro del notebook | nulos, tipos, 9 revisiones de consistencia y tabla de cobertura |
| Exportación | `to_csv` comentado (no guardaba nada); nombre `E0_filtrado_consolidado.csv` | activa; nombre `E0_consolidado_final.csv` |
| Ruta de los archivos | `C:\Users\Daniel\Downloads\...` | `Path("C:/Users/roski/Downloads")` (sigue siendo una carpeta local) |

Comparamos la base nueva con la anterior partido por partido (llave: fecha, local y visitante): los
9,450 partidos comunes son **idénticos** en las 33 columnas que compartían, y los 90 nuevos son
exactamente los que faltaban: 45 de 2003/04 (entre el 3-abr y el 15-may-2004) y 45 de 2004/05 (del
23-abr al 15-may-2005; en la base anterior esa temporada terminaba el 20-abr). La explicación está
en la [celda 2](#celda-2-lectura-unión-y-fila-vacía).

### Las 28 celdas

| Celda | Tipo | Qué hace | Salida clave | Quién usa el resultado |
|---|---|---|---|---|
| [0](#celda-0-presentación) | Texto | Presenta el notebook y la fuente | — | — |
| [1](#celda-1-rutas-cabeceras-y-columnas-comunes) | Código | Arma las 26 rutas, lee sólo las cabeceras e intersecta | 23 columnas comunes | Celdas 2 y 26 (`columnas_obligatorias`) |
| [2](#celda-2-lectura-unión-y-fila-vacía) | Código | Agrega 11 complementarias, lee y une los 26 archivos, quita la fila vacía | 9,540 × 34; diferencia de 1 fila | Todas las siguientes (`df_consolidado`) |
| [3](#celda-3-texto-revisión-del-consolidado) | Texto | Anuncia la revisión del consolidado | — | — |
| [4](#celda-4-columnas-comunes-nulos-y-tipos) | Código | Columnas comunes, nulos por columna, tipos, filas con nulos fuera de cuotas/xG | 61,180 nulos; 0 filas | Nadie (diagnóstico) |
| [5](#celda-5-segunda-eliminación-de-filas-vacías) | Código | Repite `dropna(how="all")` | Sin cambios | — |
| [6](#celda-6-gráfica-de-nulos) | Código | Gráfica de barras de nulos | Figura | Nadie (diagnóstico) |
| [7](#celda-7-texto-análisis-de-consistencia) | Texto | Título de las revisiones | — | — |
| [8](#celda-8-fechas-con-un-solo-formato) | Código | Intenta leer las fechas sólo con `dayfirst=True` | **5,320 inválidas** | Nadie (lo resuelve la 19) |
| [9](#celda-9-partidos-duplicados) | Código | Busca partidos repetidos | 0 | Nadie |
| [10](#celda-10-un-equipo-contra-sí-mismo) | Código | Local igual a visitante | 0 | Nadie |
| [11](#celda-11-valores-negativos) | Código | Conteos negativos | 0 | Nadie |
| [12](#celda-12-goles-al-medio-tiempo-contra-goles-finales) | Código | Goles al descanso mayores que los finales | 0 | Nadie |
| [13](#celda-13-tiros-a-puerta-contra-tiros-totales) | Código | Tiros a puerta mayores que tiros | **1** | Celda 21 (`tiros_inconsistentes`) |
| [14](#celda-14-ftr-contra-el-marcador) | Código | `FTR` contra el marcador | 0 | Nadie |
| [15](#celda-15-cuotas-inválidas) | Código | Cuotas ≤ 1 | 0 | Nadie |
| [16](#celda-16-xg-negativos) | Código | xG negativos | 0 | Nadie |
| [17 y 18](#celdas-17-y-18-texto-solución-de-las-fechas) | Texto | Título "Solución…" y explicación de las fechas | — | — |
| [19](#celda-19-fechas-con-formato-mixto) | Código | Repite la lectura con `format="mixed"` | 0 inválidas | Nadie (confirma que la 23 no fallará) |
| [20](#celda-20-texto-el-caso-de-west-ham) | Texto | Por qué se conserva el partido Newcastle–West Ham | — | — |
| [21](#celda-21-la-fila-inconsistente) | Código | Imprime ese partido | 1 fila | Nadie |
| [22](#celda-22-texto-tipos-de-datos) | Texto | Título "Tipos de datos" | — | — |
| [23](#celda-23-conversión-de-tipos) | Código | `Date` → fecha; 16 conteos → `float64` | Sin salida | Celdas 25 a 27 |
| [24](#celda-24-texto-tabla-de-tipos) | Texto | Tabla que describe los tipos | — | — |
| [25](#celda-25-tipos-finales) | Código | Muestra el tipo de cada columna | 27 `float64`, 6 texto, 1 fecha | Nadie |
| [26](#celda-26-tabla-de-cobertura) | Código | Cobertura por grupo de variables | Tabla de 4 renglones | Nadie en el código; el reporte la reproduce (Cuadro 2) |
| [27](#celda-27-exportación) | Código | Exporta el CSV | 9,540 filas y 34 columnas | `Analisis.ipynb` y el tablero (con el nombre `E0_consolidado.csv`) |

Al final del capítulo: [detalles conocidos](#36-detalles-conocidos), [cómo reconstruir la base
desde cero](#37-reconstruir-la-base-desde-cero), [el notebook completo en R](#38-el-notebook-completo-en-r)
y el [resumen de decisiones](#39-resumen-de-decisiones).

## 3.1 Lectura y unión (celdas 0 a 2)

### Celda 0. Presentación

Texto (Markdown) de la celda:

> Se descargaron los archivos de los resultados desde 2001 hasta la temporada actual desde
> football-data: https://football-data.co.uk/englandm.php. Despues se seleccionaron aquellas
> variables dentro de todos los dataframes (columnas obligatorias), y columnas complementarias
> relacionadas a apuestas, que nos servirán para hacer comparaciones con probabilidades implicitas
> de estas y los resultados de nuestro predictor. […]

- **Qué dice:** de dónde salen los datos y la idea central: **columnas obligatorias** (las que están
  en todos los archivos) y **complementarias** (cuotas y xG, para comparar con el modelo).
- La versión anterior decía "desde 2021"; ahora dice correctamente "desde 2001".

### Celda 1. Rutas, cabeceras y columnas comunes

```python
import pandas as pd
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

# Rutas a donde tienes tus CSVs, nosotros los dejamos en descargas
# Descargamos 26 archivos que comprenden desde 2001 hasta la actual, todos se llaman E0 tal que están guardados como E0.csv, E0 (1).csv, E0 (2).csv, ..., E0 (25).csv 
carpeta = Path("C:/Users/roski/Downloads")                          
archivos = [carpeta / "E0.csv"] + [carpeta / f"E0 ({i}).csv" for i in range(1, 26)]


# Primero vamos a encontrar las columnas en común entre todos los archivos
conjuntos_columnas = []
primeras_cols = []

for ruta in archivos:
    if not ruta.exists():
        continue
    # Lectura ultra rápida (solo cabecera)
    cols = pd.read_csv(ruta, encoding="utf-8-sig", encoding_errors="ignore", nrows=0).columns.str.strip()
    
    if not primeras_cols:
        primeras_cols = list(cols)
        
    conjuntos_columnas.append(set(cols))

if conjuntos_columnas:
    # Intersección para encontrar las comunes a todos los archivos
    comunes = set.intersection(*conjuntos_columnas)
    columnas_obligatorias = [col for col in primeras_cols if col in comunes]

    print(f"Total de columnas presentes en todos los archivos: {len(columnas_obligatorias)}")
    print(columnas_obligatorias)
else:
    print("No se encontraron archivos válidos.")
    exit()
```

**Qué hace, bloque por bloque:**

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `import pandas as pd` … `import matplotlib.pyplot as plt` | Carga las bibliotecas: tablas (`pandas`), cálculo (`numpy`), gráficas (`matplotlib`) y rutas (`pathlib`) | `library(readr); library(dplyr); library(lubridate); library(ggplot2)` |
| `carpeta = Path("C:/Users/roski/Downloads")` | Un objeto *ruta*. Con `/` normal funciona también en Windows | `carpeta <- "C:/Users/roski/Downloads"` |
| `[carpeta / "E0.csv"] + [carpeta / f"E0 ({i}).csv" for i in range(1, 26)]` | El operador `/` une carpeta y nombre; la *list comprehension* genera `E0 (1).csv` … `E0 (25).csv` (`range(1, 26)` va de 1 a 25); `+` concatena las dos listas: 26 rutas | `file.path(carpeta, c("E0.csv", sprintf("E0 (%d).csv", 1:25)))` |
| `if not ruta.exists(): continue` | Si un archivo no existe, **lo salta sin avisar** | `archivos <- archivos[file.exists(archivos)]` |
| `pd.read_csv(..., nrows=0)` | Lee **cero filas**: sólo la cabecera. Es instantáneo aunque el archivo sea grande | `read_csv(ruta, n_max = 0)` |
| `encoding="utf-8-sig", encoding_errors="ignore"` | Lee el texto como UTF-8, quita la marca BOM si existe e ignora bytes inválidos (detalle en la [celda 2](#celda-2-lectura-unión-y-fila-vacía)) | `readr` lee UTF-8 y quita el BOM por defecto |
| `.columns.str.strip()` | Quita espacios al inicio y al final de cada nombre (`"HomeTeam "` → `"HomeTeam"`) | `trimws(names(...))` |
| `if not primeras_cols: primeras_cols = list(cols)` | Guarda el orden de columnas del **primer** archivo encontrado (2026/27) | el primer elemento de la lista |
| `conjuntos_columnas.append(set(cols))` | Guarda las columnas de cada archivo como **conjunto** (sin orden ni repetidos) | `cabeceras <- lapply(archivos, cabecera)` |
| `set.intersection(*conjuntos_columnas)` | Intersección de los 26 conjuntos; el `*` "desempaca" la lista en 26 argumentos | `Reduce(intersect, cabeceras)` |
| `[col for col in primeras_cols if col in comunes]` | Los conjuntos no tienen orden; esto devuelve las comunes **en el orden del primer archivo** | `Reduce(intersect, ...)` ya conserva el orden del primero |
| `else: … exit()` | Si no encontró ningún archivo, avisa y detiene | `stop("No se encontraron archivos válidos.")` |

**Salida guardada:**

```text
Total de columnas presentes en todos los archivos: 23
['Div', 'Date', 'HomeTeam', 'AwayTeam', 'FTHG', 'FTAG', 'FTR', 'HTHG', 'HTAG', 'HTR', 'Referee', 'HS', 'AS', 'HST', 'AST', 'HF', 'AF', 'HC', 'AC', 'HY', 'AY', 'HR', 'AR']
```

Son las 22 de la versión anterior **más `Div`** (la división; siempre `E0`). El orden es el del
archivo de 2026/27; por eso `Referee` aparece después de `HTR` y no al final. Las columnas que sólo
traen algunos archivos (por ejemplo, las cuotas de casas que aparecen sólo en ciertos años) quedan
fuera de la intersección.

**En R** (probado con tres archivos de prueba que imitan los problemas reales: BOM, un nombre con
espacio y columnas que no están en todos):

```r
library(readr); library(dplyr)

carpeta  <- "datos_crudos"                                      # la carpeta con los 26 CSV
archivos <- file.path(carpeta, c("E0.csv", sprintf("E0 (%d).csv", 1:25)))
archivos <- archivos[file.exists(archivos)]                     # ≈ if not ruta.exists(): continue

cabecera  <- function(ruta) trimws(names(read_csv(ruta, n_max = 0, show_col_types = FALSE)))
cabeceras <- lapply(archivos, cabecera)                         # ≈ nrows=0: sólo la cabecera
columnas_obligatorias <- Reduce(intersect, cabeceras)           # ≈ set.intersection(*conjuntos)
length(columnas_obligatorias)                                   # 23 con los 26 archivos reales
```

Con los archivos de prueba, el resultado fue `Div Date HomeTeam AwayTeam FTHG FTAG FTR Referee HS
HST`: `Div` se reconoció aunque el primer archivo traía BOM, `"HomeTeam "` se limpió, y `Time` (que
sólo tenía un archivo) quedó fuera.

> **Decisión:** las "columnas obligatorias" son la **intersección** de las cabeceras de los 26
> archivos (23), calculada por el código y no escrita a mano.
>
> **Alternativas:** (a) **unión** de todas las columnas — a favor: no se pierde ninguna variable;
> en contra: juntaría todo lo que Football-Data publicó alguna vez (cuotas de decenas de casas,
> mercados de goles, hándicap asiático), casi todo vacío en la mayoría de las temporadas, y una base
> difícil de revisar. (b) **Lista escrita a mano** (la versión anterior: 22) — a favor: control total;
> en contra: hay que mantenerla, dejaba fuera `Div` y, con `reindex`, una columna que faltara en un
> archivo se creaba vacía sin aviso. (c) **Intersección** (la elegida) — a favor: garantiza que las
> 23 existen en las 26 temporadas y se recalcula sola si se agrega un archivo; en contra: si un
> archivo nuevo no trajera, por ejemplo, `Referee`, esa columna desaparecería de la base sin aviso.
>
> **Por qué ésta:** el Elo y los promedios necesitan variables completas en todo el histórico
> (goles, tiros, resultado); lo que sirve aunque falte en algunos años (cuotas, xG) se agrega aparte
> en la celda 2.
>
> **Evidencia en el proyecto:** la [celda 4](#celda-4-columnas-comunes-nulos-y-tipos) confirma 0
> nulos en las 23 comunes; todos los nulos están en cuotas y xG.
>
> **Si preguntan:** "Tomamos las columnas que están en los 26 archivos, calculadas por código, y
> aparte agregamos 11 de cuotas y xG que nos sirven aunque falten en algunos años."

### Celda 2. Lectura, unión y fila vacía

```python
# Concatenamos con las variables de cuotas promedio de apuestas y las concatenamos.
# Cabe resaltar que estas columnas no están presentes en todos los archivos, por lo que se rellenarán con NaN donde no existan.

# Variables complementarias que se conservan únicamente cuando están disponibles en el archivo original.
columnas_complementarias = [
    "B365H", "B365D", "B365A",
    "AvgH", "AvgD", "AvgA",
    "AvgCH", "AvgCD", "AvgCA",
    "HxG", "AxG"
]

# Define las columnas que se conservarán en el consolidado.
columnas_conservar = list(dict.fromkeys(columnas_obligatorias + columnas_complementarias))

# Almacena temporalmente cada base filtrada.
lista_dfs = []

# Recorre todos los archivos históricos.
for ruta in archivos:
    if not ruta.exists():
        continue

    # Lee únicamente las columnas obligatorias y complementarias disponibles en cada archivo.
    df = pd.read_csv(
        ruta,
        encoding="utf-8-sig",
        encoding_errors="ignore",
        usecols=lambda col: col.strip() in columnas_conservar
    )

    # Elimina espacios accidentales de los nombres de las columnas.
    df.columns = df.columns.str.strip()

    # Guarda la base filtrada para posteriormente consolidarla.
    lista_dfs.append(df)

# Concatena todas las bases filtradas en una sola base histórica.
df_consolidado = pd.concat(
    lista_dfs,
    ignore_index=True,
    sort=False
    
)

# Elimina las filas completamente vacías.
df_consolidado = df_consolidado.dropna(how="all").reset_index(drop=True)
# Ordena las columnas de acuerdo con el orden definido originalmente.
columnas_presentes = [col for col in columnas_conservar if col in df_consolidado.columns]
df_consolidado = df_consolidado[columnas_presentes]

# Muestra las dimensiones y las primeras observaciones de la base consolidada.
print(f"Filas: {len(df_consolidado):,}")
print(f"Columnas: {len(df_consolidado.columns)}")
display(df_consolidado.head())

# Cuenta el total de filas antes de realizar la concatenación.
filas_antes = sum(len(df) for df in lista_dfs)

# Cuenta el total de filas de la base consolidada.
filas_despues = len(df_consolidado)

# Compara ambos totales para verificar que ninguna fila se haya perdido.
print(f"Filas antes de concatenar: {filas_antes}")
print(f"Filas después de concatenar: {filas_despues}")
print(f"Diferencia: {filas_antes - filas_despues}")
```

**Qué hace, bloque por bloque:**

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `columnas_complementarias = [...]` | Las 11 columnas extra: cuotas de Bet365 (`B365H/D/A`), promedio de mercado previo (`AvgH/D/A`), promedio de cierre (`AvgCH/CD/CA`) y goles esperados (`HxG/AxG`) | `columnas_complementarias <- c("B365H", …, "AxG")` |
| `list(dict.fromkeys(a + b))` | Une las dos listas y quita repetidos **conservando el orden** (un diccionario no admite llaves repetidas). Aquí no había repetidos: 23 + 11 = 34 | `unique(c(a, b))` |
| `usecols=lambda col: col.strip() in columnas_conservar` | `usecols` puede ser una **función**: pandas la llama con el nombre de cada columna y conserva las que devuelven `True`. El `strip()` hace que `"HomeTeam "` también cuente. Sólo se leen las 34 columnas, no las decenas que trae cada archivo | `read_csv(ruta, col_select = any_of(columnas_conservar), name_repair = trimws)` |
| `encoding="utf-8-sig"`, `encoding_errors="ignore"` | Ver el recuadro de abajo | `readr` lee UTF-8 y quita el BOM; los bytes inválidos se limpian con `iconv(x, "UTF-8", "UTF-8", sub = "")` |
| `df.columns = df.columns.str.strip()` | Deja los nombres sin espacios | `name_repair = trimws` |
| `pd.concat(lista_dfs, ignore_index=True, sort=False)` | Apila las 26 tablas. Alinea por **nombre** de columna: si un archivo no trae `AvgH`, sus filas quedan con `NaN` ahí. `ignore_index=True` renumera las filas de 0 a n − 1; `sort=False` deja las columnas en el orden en que aparecen (no alfabético) | `bind_rows(lista_dfs)` (también rellena con `NA`) |
| `dropna(how="all").reset_index(drop=True)` | Borra las filas en las que **las 34** columnas están vacías y vuelve a numerar | `filter(if_any(everything(), ~ !is.na(.x)))` |
| `columnas_presentes = [...]`; `df_consolidado[columnas_presentes]` | Reordena: primero las 23 comunes, luego las 11 complementarias | `select(any_of(columnas_conservar))` |
| `print(f"Filas: {len(df_consolidado):,}")` | `:,` pone separador de miles | `format(nrow(e0), big.mark = ",")` |
| `display(df_consolidado.head())` | Muestra las 5 primeras filas (`display` existe en Jupyter, no en un script normal) | `head(e0)` o `print(head(e0))` |
| `filas_antes = sum(len(df) for df in lista_dfs)` | Suma las filas leídas de los 26 archivos | `sum(sapply(lista_dfs, nrow))` |

**Salida guardada** (abreviada: se omiten las columnas intermedias de la tabla):

```text
Filas: 9,540
Columnas: 34
  Div        Date       HomeTeam        AwayTeam  FTHG  FTAG FTR  HTHG  HTAG  ...  AvgCA   HxG   AxG
0  E0  21/08/2026        Arsenal        Coventry   3.0   0.0   H   2.0   0.0  ...  14.00  1.88  0.20
1  E0  22/08/2026           Hull      Man United   2.0   0.0   H   2.0   0.0  ...   1.34  1.01  1.83
2  E0  22/08/2026        Everton  Crystal Palace   2.0   0.0   H   1.0   0.0  ...   3.05  1.12  1.96
3  E0  22/08/2026        Ipswich      Sunderland   2.0   1.0   H   1.0   1.0  ...   2.52  1.80  0.66
4  E0  22/08/2026  Nott'm Forest           Leeds   0.0   1.0   A   0.0   0.0  ...   2.94  0.66  0.47
[5 rows x 34 columns]
Filas antes de concatenar: 9541
Filas después de concatenar: 9540
Diferencia: 1
```

Cómo leerla:

- La primera fila es el primer partido de 2026/27 (Arsenal–Coventry, 21-ago-2026): el orden es el
  de los archivos. Las fechas todavía son **texto** (`21/08/2026`); se convierten en la celda 23.
- Los goles ya salen como decimales (`3.0`). Lo más probable es que se deba a la fila vacía: basta
  un `NaN` en un archivo para que pandas guarde esa columna como `float64`, y al unir las tablas
  toda la columna queda `float64` aunque después se borre la fila (lo reprodujimos con un archivo de
  prueba).
- "Antes / después de concatenar" en realidad compara **filas leídas** (9,541) contra **filas
  finales** (9,540). `concat` nunca pierde filas; la diferencia de 1 es la fila vacía que quitó
  `dropna(how="all")`.

**En R** (probado con los archivos de prueba: 7 filas leídas, 6 finales, 13 columnas):

```r
columnas_complementarias <- c("B365H", "B365D", "B365A", "AvgH", "AvgD", "AvgA",
                              "AvgCH", "AvgCD", "AvgCA", "HxG", "AxG")
columnas_conservar <- unique(c(columnas_obligatorias, columnas_complementarias))   # ≈ dict.fromkeys

leer <- function(ruta) {
  read_csv(ruta,
           col_select = any_of(columnas_conservar),             # ≈ usecols
           name_repair = trimws,                                # ≈ columns.str.strip()
           col_types = cols(.default = col_character()),        # todo como texto; se convierte después
           show_col_types = FALSE)
}
lista_dfs <- lapply(archivos, leer)

df_consolidado <- bind_rows(lista_dfs) |>                       # ≈ pd.concat(ignore_index=True, sort=False)
  filter(if_any(everything(), ~ !is.na(.x))) |>                 # ≈ dropna(how="all")
  select(any_of(columnas_conservar)) |>                         # ≈ reordenar columnas
  mutate(across(where(is.character),                            # ≈ encoding_errors="ignore"
                ~ iconv(.x, "UTF-8", "UTF-8", sub = "")))

filas_antes <- sum(sapply(lista_dfs, nrow))
cat("Filas:", nrow(df_consolidado), "| Columnas:", ncol(df_consolidado),
    "| Diferencia:", filas_antes - nrow(df_consolidado), "\n")
```

Dos diferencias con pandas que conviene saber:

1. Se lee todo como texto (`col_types = cols(.default = col_character())`) porque `bind_rows()` se
   niega a unir una columna numérica de un archivo con una de texto de otro; los números se
   convierten después.
2. Ante una fila con **un campo de más**, `readr` conserva la fila y avisa (`One or more parsing
   issues, call problems()`), pero **pega el campo sobrante a la última columna del archivo**: con
   archivos de prueba, una cuota `4.2` quedó como `"4.2,"`, que al convertir a número se vuelve `NA`.
   Si esa última columna no es de las 34, no pasa nada; si lo es, se pierde ese valor. `problems(x)`
   dice en qué fila ocurrió. La forma de replicar exactamente a pandas es `data.table::fread()` con
   `fill = TRUE`, que pone lo sobrante en una columna nueva (`V27`, …) que después no se selecciona
   (probado: misma intersección, BOM reconocido, fila vacía eliminada, cuotas intactas):

```r
leer <- function(ruta) {                                         # alternativa con data.table
  d <- data.table::fread(ruta, colClasses = "character", fill = TRUE, na.strings = c("", "NA"))
  names(d) <- trimws(names(d))
  select(tibble::as_tibble(d), any_of(columnas_conservar))       # ≈ usecols
}
```

`na.strings = c("", "NA")` hace falta porque `fread` lee los campos vacíos de texto como `""`, no
como `NA`, y entonces la fila vacía no se reconocería.

> **Decisión:** además de las 23 comunes, conservar **11 complementarias**: Bet365 (3), promedio
> de mercado previo (3), promedio de cierre (3) y xG (2).
>
> **Alternativas:** (a) **sólo las 23 comunes** — base sin un solo nulo, pero sin cuotas: no habría
> con qué comparar el modelo, que es la pregunta del proyecto. (b) **Las cuotas de todas las casas**
> (Football-Data publica varias, por ejemplo Pinnacle o William Hill) — más información, pero con
> coberturas distintas y redundante con el promedio. (c) **Las 11 elegidas** — `Avg`/`AvgC` son la
> referencia de mercado de apertura y de cierre; Bet365 tiene cuotas desde 2002/03, lo que permite
> el análisis histórico del favorito en el tablero; xG se guarda por si sirve.
>
> **Por qué ésta:** son justo las que responden la pregunta. El promedio resume a muchas casas (es
> mejor referencia que una sola) y Bet365 da 24 temporadas de historia.
>
> **Evidencia en el proyecto:** `Avg`/`AvgC` cubren 2,700 partidos (2019/20–2026/27), que es la base
> de modelación antes de excluir 4; Bet365 cubre 9,160; xG sólo 40 (por eso no se usa).
>
> **Si preguntan:** "Guardamos las cuotas promedio de apertura y cierre, que son nuestra referencia
> de mercado, Bet365 por su historia larga y el xG; las demás casas no agregaban nada al promedio."

> **Decisión:** leer cada archivo con `usecols` (sólo las 34 columnas), `encoding="utf-8-sig"`
> (UTF-8 que tolera la marca BOM) y `encoding_errors="ignore"` (descarta bytes que no son UTF-8).
>
> **Alternativas:** (a) **`encoding="latin1"`** (la versión anterior) — nunca falla y conserva
> acentos de archivos Latin-1; pero si un archivo empieza con BOM, la primera columna se llama
> `ï»¿Div` en vez de `Div` y la intersección perdería esa columna (lo comprobamos con un archivo de
> prueba). (b) **UTF-8 estricto** — un solo byte inválido detiene todo con `UnicodeDecodeError`.
> (c) **`encoding_errors="replace"`** — pone `�` en lugar del byte: no se pierde en silencio, se ve.
> (d) **Leer todas las columnas y luego `reindex`** (la versión anterior) — más lento y, sin
> `usecols`, el lector de pandas se detiene ante filas con campos de más (siguiente recuadro).
> (e) **Detectar la codificación de cada archivo** (por ejemplo con el paquete `chardet`) — lo más
> robusto, pero más código. Ninguna de estas se probó con los archivos reales.
>
> **Por qué ésta:** es la combinación más simple que lee los 26 archivos sin errores y sin perder
> filas.
>
> **Evidencia en el proyecto:** la base no tiene **ningún** carácter fuera de ASCII (tampoco la
> anterior, leída con Latin-1), y los 9,450 partidos que comparten son idénticos: en la práctica,
> `ignore` no borró nada. Un nombre con acento escrito en Latin-1, como `Hervé`, sí quedaría como
> `Herv` (prueba sintética); no es el caso de estos archivos.
>
> **Si preguntan:** "Leímos como UTF-8 tolerando la marca BOM; así la columna `Div` se reconoce en
> todos los archivos. Revisamos que no hubiera acentos que se pudieran perder: no hay ninguno."

> **Decisión:** **no** usar `on_bad_lines="skip"`. Con `usecols`, pandas lee completas las filas
> que traen más campos que la cabecera (descarta sólo los campos sobrantes).
>
> **Alternativas:** (a) **`on_bad_lines="skip"`** (la versión anterior) — nunca falla, pero tira la
> fila entera **sin avisar**. (b) **`"warn"`** — también tira la fila, sólo que avisa (`Skipping line
> 3: expected 7 fields, saw 8`). (c) **`"error"`** (el valor por defecto, sin `usecols`) — se detiene
> con `ParserError: Expected 7 fields in line 3, saw 8`: obliga a revisar a mano. (d) **Una función**
> (`on_bad_lines=lambda campos: campos[:n]`, con `engine="python"`) — conserva la fila recortando los
> campos de más; mismo resultado que lo elegido, con más código. Las cuatro se probaron con un
> archivo sintético (pandas 2.2.3), no con los crudos.
>
> **Por qué ésta:** recupera los 90 partidos sin código especial y sin perder nada.
>
> **Evidencia en el proyecto:** 9,450 → 9,540 partidos; 2003/04 y 2004/05 pasan de 335 a 380;
> los demás partidos no cambian en ninguna columna.
>
> **Si preguntan:** "La versión anterior saltaba en silencio las filas con un campo de más y perdía
> 90 partidos del final de 2003/04 y 2004/05. La nueva lee sólo las columnas que necesita y esas
> filas entran completas."

**Cómo sabemos lo de los 90 partidos.** Comprobado: (1) los 90 que faltaban son 45 de abril y mayo
de 2004 y 45 de abril y mayo de 2005; (2) todo lo demás es idéntico entre las dos bases; (3) en la
versión anterior, la única instrucción capaz de quitar filas completas era `on_bad_lines="skip"`
(el `dropna` sólo quitaba filas sin equipos); (4) con un archivo de prueba, `skip` descarta la fila
con un campo de más y `usecols` la conserva. Lo que no pudimos ver es la línea exacta de los
archivos crudos, porque no los tenemos; pero es la única explicación compatible con lo anterior.

> **Decisión:** `dropna(how="all")`: borrar sólo las filas **completamente** vacías.
>
> **Alternativas:** (a) **`dropna()`** (por defecto `how="any"`) — borra toda fila con algún nulo;
> como el xG sólo existe en 2026/27, quedarían **40 partidos de 9,540** (lo calculamos sobre la base).
> (b) **`dropna(subset=["HomeTeam", "AwayTeam"], how="all")`** (la versión anterior) — aquí da lo
> mismo; exige sólo que haya equipos. (c) **No borrar nada** — quedaría una fila sin equipos ni
> goles que rompería el Elo y las revisiones.
>
> **Por qué ésta:** quita la basura (1 fila) sin tocar ningún partido; los nulos de cuotas y xG son
> esperados y se manejan después.
>
> **Evidencia en el proyecto:** 9,541 → 9,540; la celda 4 confirma que ninguna fila tiene nulos
> fuera de cuotas y xG.
>
> **Si preguntan:** "Sólo quitamos una fila totalmente vacía. Un `dropna` normal habría dejado 40
> partidos, porque el xG sólo existe en la temporada actual."

## 3.2 Diagnóstico (celdas 3 a 6)

### Celda 3. Texto: revisión del consolidado

Texto de la celda (resumen): se revisan las columnas presentes en todos los archivos, los nulos y
el tipo de cada columna; los nulos "se concentran principalmente en algunas variables de momios y
xG, debido a que estas columnas no estaban disponibles en todas las temporadas", mientras que
equipos, goles, resultado, tiros, córners, faltas y tarjetas "cuentan con información completa".
La celda 4 lo confirma con números.

### Celda 4. Columnas comunes, nulos y tipos

```python
# Columnas que aparecen en todos los archivos

columnas_comunes = set(lista_dfs[0].columns)

for df_temp in lista_dfs[1:]:
    columnas_comunes = columnas_comunes.intersection(df_temp.columns)

columnas_comunes = sorted(columnas_comunes)

print("Columnas presentes en todos los archivos:")
print(columnas_comunes)
print(f"\nTotal de columnas comunes: {len(columnas_comunes)}")


# Valores nulos del dataframe consolidado

print("\nValores nulos por columna:")
print(df_consolidado.isnull().sum())

print(f"\nTotal de valores nulos: {df_consolidado.isnull().sum().sum()}")


# Tipo de dato de cada columna

print("\nTipo de dato de cada columna:")
print(df_consolidado.dtypes)


# Resumen de tipos de datos

print("\nResumen de tipos de datos:")
print(df_consolidado.dtypes.value_counts())

# Muestra las filas que contienen al menos un valor nulo excluyendo las columnas de apuestas.
display(df_consolidado[
    df_consolidado.drop(columns=columnas_complementarias, errors="ignore").isnull().any(axis=1)
])
```

**Qué hace, bloque por bloque:**

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `set(lista_dfs[0].columns)` y el `for` con `.intersection(...)` | Vuelve a calcular las columnas comunes, ahora sobre las tablas ya leídas (con sus 34 columnas como máximo). Es una comprobación de la celda 1: como las 11 complementarias no están en todos los archivos, quedan las 23 | `Reduce(intersect, lapply(lista_dfs, names))` |
| `sorted(...)` | Ordena alfabéticamente. Python pone mayúsculas antes que minúsculas, por eso `'AY'` sale antes que `'AwayTeam'` | `sort(...)` (R ordena según el idioma del sistema; el orden puede variar) |
| `df_consolidado.isnull().sum()` | `isnull()` da `True`/`False` por celda; `sum()` cuenta los `True` de cada columna | `colSums(is.na(e0))` |
| `.isnull().sum().sum()` | La segunda suma junta todas las columnas: total de nulos | `sum(is.na(e0))` |
| `df_consolidado.dtypes` / `.value_counts()` | Tipo de cada columna y cuántas hay de cada tipo | `sapply(e0, class)` / `table(...)` |
| `drop(columns=columnas_complementarias, errors="ignore")` | Quita las 11 complementarias (`errors="ignore"`: no falla si alguna no existe) | `select(-any_of(columnas_complementarias))` |
| `.isnull().any(axis=1)` | `axis=1` recorre **filas**: `True` si la fila tiene al menos un nulo | `if_any(everything(), is.na)` |

**Salida guardada** (la lista de nulos resumida en una tabla):

```text
Columnas presentes en todos los archivos:
['AC', 'AF', 'AR', 'AS', 'AST', 'AY', 'AwayTeam', 'Date', 'Div', 'FTAG', 'FTHG', 'FTR', 'HC', 'HF', 'HR', 'HS', 'HST', 'HTAG', 'HTHG', 'HTR', 'HY', 'HomeTeam', 'Referee']

Total de columnas comunes: 23
Total de valores nulos: 61180
Resumen de tipos de datos:
float64    27
object      7
Empty DataFrame          ← ninguna fila tiene nulos fuera de cuotas y xG
[0 rows x 34 columns]
```

| Columnas | Nulos en cada una | Qué partidos son |
|---|---|---|
| Las 23 comunes | 0 | — |
| `B365H`, `B365D`, `B365A` | 380 | toda la temporada 2001/02 |
| `AvgH`, `AvgD`, `AvgA`, `AvgCH`, `AvgCD`, `AvgCA` | 6,840 | 2001/02 a 2018/19 (18 temporadas × 380) |
| `HxG`, `AxG` | 9,500 | todo salvo los 40 partidos de 2026/27 |
| **Total** | **61,180** | = 3 × 380 + 6 × 6,840 + 2 × 9,500 |

Los 7 `object` (texto) son `Div`, `Date`, `HomeTeam`, `AwayTeam`, `FTR`, `HTR` y `Referee`; `Date`
sigue siendo texto hasta la celda 23. Los 27 `float64` son los 16 conteos y las 11 columnas de
cuotas y xG.

**En R** (ejecutado sobre `E0_consolidado.csv`; da los mismos 61,180 nulos y 0 filas):

```r
e0 <- read_csv("Codigo/proyecto_mod_8/E0_consolidado.csv", show_col_types = FALSE)

nulos <- colSums(is.na(e0))
nulos[nulos > 0]                    # B365: 380 · Avg y AvgC: 6840 · xG: 9500
sum(nulos)                          # 61180
table(vapply(e0, function(x) class(x)[1], ""))     # character 6 · Date 1 · numeric 27
e0 |> filter(if_any(-any_of(columnas_complementarias), is.na))   # 0 filas
```

En R `Date` sale como fecha (6 de texto, 1 fecha y 27 numéricas) porque el CSV exportado ya tiene
fechas AAAA-MM-DD, que `read_csv()` reconoce solo; en el notebook, en este punto, todavía son texto.

> **Decisión:** medir los nulos y **dejarlos**: no borrar partidos ni rellenar valores.
>
> **Alternativas:** (a) **Borrar partidos con nulos** — con `dropna()` quedarían 40; borrando sólo
> los que no tienen cuotas promedio quedarían 2,700, y se perderían 18 temporadas que el Elo
> necesita. (b) **Imputar** (por ejemplo, rellenar la cuota promedio faltante con la de Bet365 o con
> una media) — inventaría datos de mercado justo en la variable con la que se compara el modelo.
> (c) **Quitar las columnas con muchos nulos** (xG) — posible, porque no se usan; conservarlas no
> cuesta nada. (d) **Dejar los nulos y que cada análisis use los partidos que tienen lo que
> necesita** (la elegida).
>
> **Por qué ésta:** estos nulos no son errores sino **cobertura**: la fuente empezó a publicar esas
> columnas en cierto año. El Elo usa las 26 temporadas; la comparación con el mercado usa sólo
> partidos con las tres cuotas (todos los de validación y prueba las tienen).
>
> **Evidencia en el proyecto:** 0 nulos en las 23 comunes, y los nulos forman bloques de temporadas
> completas (380, 6,840 y 9,500 son múltiplos de 380 que corresponden a temporadas enteras): es un
> patrón de cobertura, no de errores sueltos.
>
> **Si preguntan:** "Los nulos no son errores: son años en que la fuente no publicaba cuotas promedio
> o xG. No borramos partidos porque el Elo necesita toda la historia; cada análisis usa sólo los
> partidos que tienen la información que necesita."

### Celda 5. Segunda eliminación de filas vacías

```python
# Eliminamos la fila completamente vacía.
df_consolidado = df_consolidado.dropna(how="all").reset_index(drop=True)
```

- **Qué hace:** repite exactamente lo que ya hizo la celda 2. Como la fila vacía ya se había
  borrado, **no cambia nada**: siguen 9,540 filas. Es redundante pero inofensiva (aplicar `dropna`
  dos veces da lo mismo que una).
- **En R:** `e0 <- filter(e0, if_any(everything(), ~ !is.na(.x)))`.

### Celda 6. Gráfica de nulos

```python
# Cuenta los valores nulos de todas las columnas.
nulos = df_consolidado.isnull().sum()
#Quitamos las que son completamente cero
nulos = nulos[nulos > 0]
# Gráfica de valores nulos por columna.
plt.figure(figsize=(14, 6))

nulos.plot(kind="bar")

plt.title("Valores nulos por columna")
plt.xlabel("Columnas")
plt.ylabel("Número de valores nulos")
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
plt.show()
```

| Código | Qué hace | Equivalente en R (`ggplot2`) |
|---|---|---|
| `nulos[nulos > 0]` | Filtra la serie: sólo las columnas con algún nulo (11) | `nulos[nulos > 0]` |
| `plt.figure(figsize=(14, 6))` | Lienzo de 14 × 6 pulgadas | `ggsave(..., width = 14, height = 6)` |
| `nulos.plot(kind="bar")` | Una barra por columna; altura = número de nulos | `ggplot(aes(columna, nulos)) + geom_col()` |
| `plt.title`, `xlabel`, `ylabel` | Título y nombres de los ejes | `labs(title = …, x = …, y = …)` |
| `plt.xticks(rotation=45, ha="right")` | Gira 45° los nombres del eje x y los alinea a la derecha | `theme(axis.text.x = element_text(angle = 45, hjust = 1))` |
| `plt.tight_layout()`; `plt.show()` | Ajusta márgenes y muestra la figura | (automático al imprimir) |

**Salida:** una gráfica de 11 barras: tres bajas (Bet365, 380), seis medianas (`Avg` y `AvgC`,
6,840) y dos altas (`HxG`/`AxG`, 9,500). Hace visible de un vistazo el patrón por bloques de la
tabla anterior.

**En R** (ejecutado; produce la misma gráfica):

```r
library(ggplot2)
nulos <- colSums(is.na(e0)); nulos <- nulos[nulos > 0]
tibble(columna = factor(names(nulos), levels = names(nulos)), nulos = nulos) |>
  ggplot(aes(columna, nulos)) +
  geom_col() +
  labs(title = "Valores nulos por columna", x = "Columnas", y = "Número de valores nulos") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
# o, en R base: barplot(nulos, las = 2, main = "Valores nulos por columna")
```

El `factor(..., levels = names(nulos))` mantiene las barras en el orden de las columnas; sin él,
`ggplot2` las ordenaría alfabéticamente.

## 3.3 Revisiones de consistencia (celdas 7 a 16)

### Celda 7. Texto: análisis de consistencia

Sólo el título `### Analisis de consistencia de datos`. Debajo vienen 9 revisiones (celdas 8 a 16)
con la misma estructura: (1) una condición que marca con `True` las filas sospechosas, (2)
`display()` de esas filas y (3) `print()` del conteo. Que la tabla salga vacía (`Empty DataFrame`)
quiere decir que no hubo problemas.

| Celda | Regla que un dato correcto siempre cumple | Resultado |
|---|---|---|
| 8 | La fecha se puede leer | **5,320** no se leen con un solo formato → se resuelve en la 19 |
| 9 | Ningún partido está repetido | 0 |
| 10 | Un equipo no juega contra sí mismo | 0 |
| 11 | Goles, tiros, faltas, córners y tarjetas no son negativos | 0 |
| 12 | Los goles al descanso no superan a los finales | 0 |
| 13 | Los tiros a puerta no superan a los tiros totales | **1** → se conserva (celdas 20–21) |
| 14 | `FTR` coincide con el marcador | 0 |
| 15 | Toda cuota decimal es mayor que 1 | 0 |
| 16 | El xG no es negativo | 0 |

### Celda 8. Fechas con un solo formato

```python
# Convierte temporalmente las fechas para identificar aquellas que no puedan interpretarse.
fechas_convertidas = pd.to_datetime(df_consolidado["Date"], dayfirst=True, errors="coerce")

# Muestra las observaciones cuya fecha no pudo convertirse.
display(df_consolidado[fechas_convertidas.isna()])

print(f"Fechas inválidas: {fechas_convertidas.isna().sum()}")
```

- **`pd.to_datetime(..., dayfirst=True)`**: convierte texto en fecha leyendo primero el **día**
  (`05/08/2026` = 5 de agosto, no 8 de mayo).
- **`errors="coerce"`**: si un texto no se puede convertir, pone `NaT` (*Not a Time*, la fecha
  faltante) en vez de detener todo. Así se pueden contar los que fallan.
- **`fechas_convertidas.isna()`**: `True` donde quedó `NaT`; se usa para filtrar y contar.
- La variable se llama "temporal" porque **no modifica** `df_consolidado`: sólo diagnostica.

**Salida guardada** (abreviada):

```text
     Div      Date        HomeTeam    AwayTeam  ...
3460  E0  13/08/16         Burnley     Swansea  ...
3461  E0  13/08/16  Crystal Palace   West Brom  ...
...
9538  E0  11/05/02      Sunderland       Derby  ...
9539  E0  11/05/02        West Ham      Bolton  ...
[5320 rows x 34 columns]
Fechas inválidas: 5320
```

**Por qué fallan 5,320.** Sin `format`, pandas (desde la versión 2.0) **deduce un solo formato a
partir del primer valor** (`21/08/2026` → día/mes/año de 4 dígitos) y lo aplica a toda la columna.
Las fechas con año de 2 dígitos (`13/08/16`) no encajan y quedan como `NaT`. Lo que dice la salida:

- Las filas 0 a 3,459 (temporadas 2017/18 a 2026/27) se leyeron bien: traen año de 4 dígitos.
- La primera que falla es la 3460, **Burnley–Swansea del 13/08/16, primer partido de 2016/17**; la
  última, la 9539, del último día de 2001/02. 5,320 = 14 temporadas × 380.
- De 2001/02 a 2016/17 hay 16 temporadas (6,080 filas) y fallan 5,320: las otras 760 ya traían año
  de 4 dígitos. Cuáles son no se puede saber sin los archivos crudos.

**En R** (ilustrativo; probado con fechas de ejemplo, porque el CSV exportado ya tiene fechas AAAA-MM-DD):

```r
fechas <- readr::parse_date(df_consolidado$Date, "%d/%m/%Y")   # un solo formato: NA en "13/08/16"
sum(is.na(fechas))

as.Date("13/08/16", format = "%d/%m/%Y")    # ¡trampa!: devuelve "0016-08-13" (año 16), no NA
```

Ojo con la segunda línea: `as.Date()` con `%Y` acepta "16" como el año 16 después de Cristo y **no
avisa**. `readr::parse_date()` sí devuelve `NA`, igual que pandas.

### Celda 9. Partidos duplicados

```python
# Revisar partidos duplicados
# Identifica partidos repetidos según fecha, equipo local y equipo visitante.
duplicados = df_consolidado.duplicated(
    subset=["Date", "HomeTeam", "AwayTeam"],
    keep=False
)

# Muestra todos los partidos identificados como duplicados.
display(df_consolidado[duplicados])

print(f"Filas duplicadas: {duplicados.sum()}")
```

- **`duplicated(subset=[...])`**: `True` en las filas cuya combinación fecha–local–visitante ya
  apareció. Con **`keep=False`** marca **todas** las copias (no sólo de la segunda en adelante), para
  poder verlas juntas.
- **Salida:** `Filas duplicadas: 0`.
- **En R** (ejecutado: 0): `e0 |> add_count(Date, HomeTeam, AwayTeam) |> filter(n > 1)` marca todas
  las copias, como `keep=False`; `duplicated(e0[, c("Date", "HomeTeam", "AwayTeam")])` equivale a
  `keep="first"`.
- **Matiz:** en este punto `Date` todavía es texto. Un mismo partido escrito `13/08/16` y
  `13/08/2016` no se detectaría como repetido; no pasa aquí porque cada temporada viene de un solo
  archivo con un solo formato. Una comprobación más fuerte para esta liga, que hicimos para la guía:
  en cada una de las 25 temporadas completas hay **20 equipos, cada uno con 19 partidos de local y
  19 de visitante**, y ningún par local–visitante se repite dentro de una temporada.

### Celda 10. Un equipo contra sí mismo

```python
# Revisar que un equipo no juegue contra sí mismo
# Identifica partidos donde el equipo local y visitante sean el mismo.
mismo_equipo = df_consolidado["HomeTeam"] == df_consolidado["AwayTeam"]

# Muestra las observaciones inconsistentes.
display(df_consolidado[mismo_equipo])

print(f"Partidos con el mismo equipo: {mismo_equipo.sum()}")
```

- **Qué hace:** compara las dos columnas renglón por renglón (`==` entre columnas da una serie de
  `True`/`False`); `sum()` cuenta los `True`.
- **Salida:** `Partidos con el mismo equipo: 0`.
- **En R** (ejecutado: 0): `filter(e0, HomeTeam == AwayTeam)`.

### Celda 11. Valores negativos

```python
#Revisar valores negativos
# Define las variables que no pueden contener valores negativos.
columnas_no_negativas = [
    "FTHG", "FTAG", "HTHG", "HTAG",
    "HS", "AS", "HST", "AST",
    "HF", "AF", "HC", "AC",
    "HY", "AY", "HR", "AR"
]

# Identifica observaciones que contienen al menos un valor negativo.
negativos = (df_consolidado[columnas_no_negativas] < 0).any(axis=1)

# Muestra las observaciones inconsistentes.
display(df_consolidado[negativos])

print(f"Filas con valores negativos: {negativos.sum()}")
```

- **Qué hace:** `df[columnas] < 0` compara las 16 columnas de conteo a la vez y da una tabla de
  `True`/`False`; `.any(axis=1)` resume cada fila: `True` si **alguna** de sus 16 celdas es negativa.
- **Salida:** `Filas con valores negativos: 0`.
- **En R** (ejecutado: 0): `filter(e0, if_any(all_of(columnas_no_negativas), ~ .x < 0))`.

### Celda 12. Goles al medio tiempo contra goles finales

```python
#Revisar goles del medio tiempo contra goles finales
# Identifica partidos donde los goles al descanso superan los goles finales.
goles_inconsistentes = (
    (df_consolidado["HTHG"] > df_consolidado["FTHG"]) |
    (df_consolidado["HTAG"] > df_consolidado["FTAG"])
)

# Muestra las observaciones inconsistentes.
display(df_consolidado[goles_inconsistentes])

print(f"Filas con goles inconsistentes: {goles_inconsistentes.sum()}")
```

- **Qué hace:** un equipo no puede tener más goles al descanso que al final. `|` es el "o" elemento
  por elemento; en pandas cada comparación va **entre paréntesis** porque `|` se evalúa antes que `>`.
- **Salida:** `Filas con goles inconsistentes: 0`.
- **En R** (ejecutado: 0): `filter(e0, HTHG > FTHG | HTAG > FTAG)`. En R no hacen falta los
  paréntesis.

### Celda 13. Tiros a puerta contra tiros totales

```python
# Revisar tiros a puerta contra tiros totales
# Identifica partidos donde los tiros a puerta superan los tiros totales.
tiros_inconsistentes = (
    (df_consolidado["HST"] > df_consolidado["HS"]) |
    (df_consolidado["AST"] > df_consolidado["AS"])
)

# Muestra las observaciones inconsistentes.
display(df_consolidado[tiros_inconsistentes])
print(f"Filas con tiros inconsistentes: {tiros_inconsistentes.sum()}")
```

- **Qué hace:** un tiro a puerta también es un tiro, así que `HST ≤ HS` y `AST ≤ AS` siempre.
- **Salida guardada:** 1 fila, la **1568**: Newcastle 2–4 West Ham, 15/08/2021. El detalle está en
  la [celda 21](#celda-21-la-fila-inconsistente). La serie `tiros_inconsistentes` se reutiliza allí.
- **En R** (ejecutado: la misma fila):
  `e0 |> filter(HST > HS | AST > AS) |> select(Date, HomeTeam, AwayTeam, HST, HS, AST, AS)`.

### Celda 14. FTR contra el marcador

```python
#Revisar que FTR coincida con el marcador
# Calcula el resultado que debería corresponder al marcador final.
ftr_calculado = np.where(
    df_consolidado["FTHG"] > df_consolidado["FTAG"], "H",
    np.where(df_consolidado["FTHG"] < df_consolidado["FTAG"], "A", "D")
)

# Identifica partidos donde el resultado registrado no coincide con el marcador.
ftr_inconsistente = df_consolidado["FTR"] != ftr_calculado

# Muestra las observaciones inconsistentes.
display(df_consolidado[ftr_inconsistente])

print(f"Filas con FTR inconsistente: {ftr_inconsistente.sum()}")
```

- **Qué hace:** recalcula el resultado con los goles y lo compara con el `FTR` registrado.
  `np.where(condición, sí, no)` es un "si… entonces… si no" vectorizado; anidado da tres casos: local
  gana (`H`), visitante gana (`A`), si no, empate (`D`).
- **Salida:** `Filas con FTR inconsistente: 0`.
- **En R** (ejecutado: 0):

```r
e0 |>
  mutate(ftr_calculado = case_when(FTHG > FTAG ~ "H", FTHG < FTAG ~ "A", .default = "D")) |>
  filter(FTR != ftr_calculado)
# con R base: ifelse(FTHG > FTAG, "H", ifelse(FTHG < FTAG, "A", "D"))   ≈ np.where anidado
```

### Celda 15. Cuotas inválidas

```python
#Revisar cuotas menores o iguales a cero
# Selecciona las columnas de cuotas disponibles en la base.
columnas_cuotas = [
    col for col in [
        "B365H", "B365D", "B365A",
        "AvgH", "AvgD", "AvgA",
        "AvgCH", "AvgCD", "AvgCA"
    ]
    if col in df_consolidado.columns
]

# Identifica cuotas no nulas menores o iguales a uno.
cuotas_invalidas = (df_consolidado[columnas_cuotas] <= 1).any(axis=1)

# Muestra las observaciones con cuotas inválidas.
display(df_consolidado[cuotas_invalidas])

print(f"Filas con cuotas inválidas: {cuotas_invalidas.sum()}")
```

- **Qué hace:** una cuota decimal paga lo apostado **más** la ganancia, así que siempre es mayor que
  1 (una cuota de 1 devolvería sólo lo apostado). Se revisan las 9 columnas de cuotas; la *list
  comprehension* con `if col in df_consolidado.columns` evita un error si faltara alguna.
- El comentario dice "menores o iguales a cero", pero el código revisa **≤ 1**, que es la regla
  correcta.
- Los `NaN` no se marcan: en pandas, `NaN <= 1` da `False`.
- **Salida:** `Filas con cuotas inválidas: 0`.
- **En R** (ejecutado: 0): `filter(e0, if_any(any_of(columnas_cuotas), ~ .x <= 1))`. En R,
  `NA <= 1` da `NA` y `filter()` descarta esas filas: el mismo resultado.

### Celda 16. xG negativos

```python
#Revisar xG negativos
# Selecciona las columnas de xG disponibles en la base.
columnas_xg = [col for col in ["HxG", "AxG"] if col in df_consolidado.columns]

# Identifica valores de xG negativos.
xg_invalidos = (df_consolidado[columnas_xg] < 0).any(axis=1)

# Muestra las observaciones con xG inválido.
display(df_consolidado[xg_invalidos])

print(f"Filas con xG negativo: {xg_invalidos.sum()}")
```

- **Qué hace:** los goles esperados son una suma de probabilidades, nunca negativa.
- **Salida:** `Filas con xG negativo: 0` (sólo hay 40 partidos con xG).
- **En R** (ejecutado: 0): `filter(e0, if_any(any_of(c("HxG", "AxG")), ~ .x < 0))`.

> **Decisión:** revisar 9 reglas lógicas que un dato correcto **siempre** cumple, mostrando las
> filas que fallan y su número.
>
> **Alternativas:** (a) **No revisar** (la versión anterior) — rápido, pero a ciegas. (b) **Reglas de
> rango o detección de atípicos** (por ejemplo, marcar goleadas o valores a más de 3 desviaciones
> estándar) — detectan valores extremos, pero extremo no es lo mismo que erróneo: la base tiene
> cuatro partidos con 9 goles de un equipo, todos reales (por ejemplo, Liverpool 9–0 Bournemouth
> en 2022). (c) **Bibliotecas de validación** (`pandera` o `great_expectations` en Python;
> `validate` o `pointblank` en R) — reglas declaradas y reportes automáticos; demasiada
> infraestructura para un notebook. (d) **Revisiones estructurales de la liga** (20 equipos, 380
> partidos, 19 de local y 19 de visitante por equipo) — muy informativas aquí; el notebook no las
> hace, pero las comprobamos para la guía y todas se cumplen. Sólo (d) se probó, por nuestra cuenta.
>
> **Por qué ésta:** son reglas sin excepciones legítimas, fáciles de explicar y de leer en la
> salida.
>
> **Evidencia en el proyecto:** 7 de las 9 dan 0; la de fechas se resuelve en la celda 19 y la de
> tiros encuentra 1 partido de 9,540.
>
> **Si preguntan:** "Revisamos nueve reglas que un dato correcto siempre cumple. Sólo aparecieron
> dos cosas: fechas en dos formatos, que se resolvieron, y un partido con un tiro a puerta de más,
> que conservamos."

## 3.4 Soluciones (celdas 17 a 21)

### Celdas 17 y 18. Texto: solución de las fechas

La celda 17 es el título `## Solución a problemas observados`. La 18 explica:

> Para las fechas, observamos que desde la temporada 2016-2017, las fechas están en formato
> dd/mm/yyyy, mientras que antes de esa temporada, las fechas están en formato dd/mm/yy. Por lo
> tanto, basta con introducir format="mixed" en pd.to_datetime() para que interprete correctamente
> ambos formatos.

La idea es correcta. Un matiz, visible en la salida de la celda 8: el primer partido de **2016/17**
(fila 3460, `13/08/16`) todavía tiene año de 2 dígitos; el año de 4 dígitos empieza en **2017/18**.
Además, 760 filas anteriores a 2016/17 ya traían 4 dígitos. Nada de esto cambia la solución:
`format="mixed"` lee las dos variantes, estén donde estén.

### Celda 19. Fechas con formato mixto

```python

# Convierte temporalmente las fechas para identificar aquellas que no puedan interpretarse.
fechas_convertidas = pd.to_datetime(df_consolidado["Date"], format="mixed", dayfirst=True, errors="coerce")

# Muestra las observaciones cuya fecha no pudo convertirse.
display(df_consolidado[fechas_convertidas.isna()])

print(f"Fechas inválidas: {fechas_convertidas.isna().sum()}")

```

- **`format="mixed"`** (pandas 2.0 o posterior): en vez de deducir un formato para toda la columna,
  interpreta **cada valor por separado**. Así `21/08/2026` y `13/08/16` se leen bien en la misma
  columna.
- **`dayfirst=True`** sigue siendo indispensable: sin él, `05/08/2026` se leería como 8 de mayo (lo
  probamos). Con él, 5 de agosto.
- Los años de 2 dígitos (`01` a `16`) se interpretan como 2001 a 2016. Con años del siglo pasado
  habría que tener cuidado: lo probamos y `01/01/69` da 1969 con `format="%d/%m/%y"`, pero 2069 con
  `format="mixed"`.
- Sigue siendo una prueba "temporal": no modifica la base; la conversión real se hace en la
  celda 23.

**Salida guardada:** `Empty DataFrame` y `Fechas inválidas: 0`.

**En R** (probado con fechas de ejemplo):

```r
library(lubridate)
fechas <- dmy(df_consolidado$Date)      # día-mes-año; acepta "13/08/16" y "21/08/2026"
sum(is.na(fechas))                      # 0
dmy("05/08/2026")                       # "2026-08-05": el orden lo da el nombre de la función
# más explícito: parse_date_time(df_consolidado$Date, orders = c("dmY", "dmy"))
```

En `lubridate` el orden día/mes/año va en el **nombre** de la función (`dmy`, `mdy`, `ymd`), así que
no existe el error de `dayfirst`: `mdy("05/08/2026")` daría el 8 de mayo.

> **Decisión:** convertir las fechas con `format="mixed"` y `dayfirst=True`.
>
> **Alternativas:** (a) **Un solo formato** (`dayfirst=True` sin `format`, o `format="%d/%m/%Y"`) —
> falla en 5,320 fechas (celda 8). (b) **Formato explícito por archivo o por longitud del texto**
> (`%d/%m/%y` si tiene 8 caracteres, `%d/%m/%Y` si tiene 10) — lo más estricto: un texto con un
> formato inesperado fallaría en vez de interpretarse "como se pueda"; requiere más código. Lo
> probamos con fechas de ejemplo y da el mismo resultado. (c) **`format="mixed"`** (la elegida) — una
> línea; su riesgo es aceptar sin avisar un formato inesperado (por ejemplo, con el mes primero), y
> por eso importa `dayfirst=True`. (d) **`format="ISO8601"`** — sólo sirve para AAAA-MM-DD; no aplica
> a los archivos crudos.
>
> **Por qué ésta:** los archivos sólo traen dos variantes del mismo orden (día/mes/año) y `"mixed"`
> las resuelve en una línea; las comprobaciones posteriores descartan malas interpretaciones.
>
> **Evidencia en el proyecto:** 5,320 → 0 fechas inválidas. Además comprobamos sobre la base final
> que **ninguna** de las 9,540 fechas cae fuera de su temporada (agosto a julio) y que dentro de cada
> temporada van en orden; y que leer el CSV como ISO o con `dayfirst=True, format="mixed"` (como hacen
> `load_history()` y el tablero) da exactamente las mismas fechas.
>
> **Si preguntan:** "Las fechas venían con año de dos y de cuatro dígitos. Con `format="mixed"` y día
> primero se leen las dos; verificamos que ninguna quedara fuera de su temporada."

### Celda 20. Texto: el caso de West Ham

> ### Caso: identifica que West Ham realizo 8 tiros totales y 9 tiros a puerta en el partido contra Newcastle en 15/08/2021
> Este caso se ignora debido a que la inconsistencia es despreciable debido a que
> - La diferencia es solamente de 1 tiro
> - Excluir la demás informacion por una discrepancia pequeña es más perjudicial que dejar pasar este error

### Celda 21. La fila inconsistente

```python
# Se muestra la fila inconsistente
print(df_consolidado[tiros_inconsistentes][["Date", "HomeTeam", "AwayTeam", "HST", "HS", "AST", "AS"]])
```

- **Qué hace:** reutiliza la serie `tiros_inconsistentes` de la celda 13 para filtrar y, con la
  doble lista `[[...]]`, muestra sólo siete columnas.
- **Salida guardada:**

```text
            Date   HomeTeam  AwayTeam  HST    HS  AST   AS
1568  15/08/2021  Newcastle  West Ham  3.0  17.0  9.0  8.0
```

Newcastle (local): 17 tiros, 3 a puerta, sin problema. West Ham (visitante): **8 tiros y 9 a
puerta**, imposible. El partido terminó 2–4 (celda 13).

- **En R** (ejecutado: la misma fila):
  `e0 |> filter(HST > HS | AST > AS) |> select(Date, HomeTeam, AwayTeam, HST, HS, AST, AS)`.

> **Decisión:** **conservar** el partido tal como viene, sin corregirlo ni borrarlo.
>
> **Alternativas:** (a) **Borrar el partido** — se perdería un resultado real (2–4) que el Elo y los
> promedios de goles necesitan, por un error en una sola estadística. (b) **Corregirlo** (por
> ejemplo, `AS = 9`) — habría que adivinar cuál de los dos números está mal; sin otra fuente, es
> inventar un dato. (c) **Marcar como faltante sólo `AS` y `AST` de ese partido** — honesto, pero deja
> un hueco en la forma reciente de tiros de West Ham y Newcastle. (d) **Contrastar con otra fuente**
> (por ejemplo, la página oficial de la liga) — lo ideal si el dato importara; no se hizo.
>
> **Por qué ésta:** la diferencia es de un tiro en un partido de 9,540, y el efecto en las variables
> del modelo es mínimo.
>
> **Evidencia en el proyecto:** con ventana de 10 partidos y decaimiento 0.85, el partido más
> reciente pesa 1 / (1 + 0.85 + … + 0.85⁹) ≈ 0.187 en la forma reciente (cálculo nuestro). Si el
> dato correcto fuera 9 tiros en vez de 8, el promedio de tiros de West Ham para su siguiente partido
> cambiaría en ≈ 0.19 tiros, y menos en los siguientes. Los tiros y tiros a puerta sólo entran en
> M2, M3 y M4; M0, el modelo que se presenta, no los usa.
>
> **Si preguntan:** "Es un error de un tiro en un solo partido de 9,540. Borrarlo quitaba un
> resultado real que el Elo necesita y corregirlo era inventar un dato; lo dejamos y lo
> documentamos."

## 3.5 Tipos, cobertura y exportación (celdas 22 a 27)

### Celda 22. Texto: tipos de datos

Título `## Tipos de datos` y una frase que quedó incompleta ("Cambiamos los tipos de dato co"). La
explicación completa está en la celda 24.

### Celda 23. Conversión de tipos

```python
# Convierte la fecha al tipo datetime.
df_consolidado["Date"] = pd.to_datetime(
    df_consolidado["Date"],
    format="mixed",
    dayfirst=True
)

# Convierte las variables de conteo a floats.
columnas_enteras = [
    "FTHG", "FTAG", "HTHG", "HTAG",
    "HS", "AS", "HST", "AST",
    "HF", "AF", "HC", "AC",
    "HY", "AY", "HR", "AR"
]

df_consolidado[columnas_enteras] = df_consolidado[columnas_enteras].astype("float64")
```

- **La fecha:** ahora sí se **reemplaza** la columna `Date` por fechas reales (`datetime64`), con la
  misma receta probada en la celda 19. Aquí **no** se usa `errors="coerce"`: si alguna fecha no se
  pudiera leer, la celda se detendría con un error en vez de dejar un `NaT` escondido. Es seguro
  porque la celda 19 mostró 0 inválidas.
- **Los conteos:** `astype("float64")` convierte las 16 columnas a decimales. Ya lo eran desde la
  lectura (celda 4), así que en la práctica no cambia nada; garantiza el tipo aunque cambie la
  entrada. El nombre `columnas_enteras` describe el contenido (son conteos enteros), no el tipo final.
- **Sin salida.**

**En R** (ejecutado):

```r
e0 <- e0 |>
  mutate(Date = dmy(Date),                                  # en el CSV exportado: as.Date(Date)
         across(all_of(columnas_no_negativas), as.numeric)) # double ≈ float64
# como enteros: across(all_of(columnas_no_negativas), as.integer)   (en R los enteros admiten NA)
```

> **Decisión:** guardar los 16 conteos como `float64` (decimales) y no como enteros.
>
> **Alternativas:** (a) **`int64`** (entero de numpy) — el tipo "natural", pero **no admite nulos**:
> con un solo `NaN` la conversión falla. (b) **`Int64`** (entero de pandas que sí admite nulos) —
> exacto, y en el CSV se escribiría `3` en vez de `3.0`; en contra: es menos conocido, no todas las
> bibliotecas lo aceptan directamente (`statsmodels`, que estima los modelos, trabaja con arreglos de
> números decimales) y ocupa algo más de memoria (lo medimos: 1.37 MB contra 1.22 MB para las 16
> columnas). (c) **`float64`** (la elegida) — admite `NaN`, es lo que pandas produce al leer y lo que
> usan los modelos; en contra: el CSV muestra `3.0`.
>
> **Por qué ésta:** no cambia ningún cálculo. Todos los conteos son enteros exactos (lo comprobamos)
> y un `float64` representa sin error cualquier entero de este tamaño. El análisis los usa para
> promedios y regresiones, que son operaciones con decimales.
>
> **Evidencia en el proyecto:** `E0_consolidado.csv` tiene sólo valores enteros en goles y tiros
> (escritos como `3.0`), y la huella SHA-256 del README corresponde a ese formato.
>
> **Si preguntan:** "Los dejamos como decimales porque así los lee pandas y así los usa el modelo;
> siguen siendo enteros exactos. En R ni siquiera habría dilema: los enteros admiten `NA`."

### Celda 24. Texto: tabla de tipos

La celda explica los tipos con esta tabla (copiada del notebook):

| Tipo de dato | Descripción | Ejemplos |
|---|---|---|
| `object` | Variables de texto o categóricas | `Div`, `HomeTeam`, `AwayTeam`, `FTR`, `HTR`, `Referee` |
| `datetime64` | Variable temporal utilizada para identificar y ordenar cronológicamente los partidos | `Date` |
| `float64` | Resultados y goles del partido | `FTHG`, `FTAG`, `HTHG`, `HTAG` |
| `float64` | Estadísticas de tiros y tiros a puerta | `HS`, `AS`, `HST`, `AST` |
| `float64` | Faltas, córners y tarjetas | `HF`, `AF`, `HC`, `AC`, `HY`, `AY`, `HR`, `AR` |
| `float64` | Cuotas de apuestas prepartido | `B365H` … `AvgCA` |
| `float64` | Métricas de goles esperados | `HxG`, `AxG` |

En pandas, `object` es el tipo genérico que se usa para texto; en R sería `character`.

### Celda 25. Tipos finales

```python
display(df_consolidado.dtypes.to_frame("Tipo"))
```

- **Qué hace:** `dtypes` es una serie (columna → tipo); `to_frame("Tipo")` la vuelve tabla con una
  columna llamada "Tipo", que Jupyter muestra con mejor formato.
- **Salida guardada (resumida):** `Date` → `datetime64[ns]`; `Div`, `HomeTeam`, `AwayTeam`, `FTR`,
  `HTR`, `Referee` → `object`; las otras 27 → `float64`. (`[ns]` significa que pandas guarda la
  fecha con precisión de nanosegundos, aunque aquí sólo hay días.)
- **En R** (ejecutado): `sapply(e0, class)` o `dplyr::glimpse(e0)`; da 6 `character`, 1 `Date` y
  27 `numeric`.

### Celda 26. Tabla de cobertura

```python
# Realizamos un diccionario  que agrupa por tipo de varaible para luego hacer un resumen de cobertura histórica de c/u.
grupos_cobertura = {
    "Variables principales": columnas_obligatorias,
    "B365H, B365D, B365A": ["B365H", "B365D", "B365A"],
    "AvgH, AvgD, AvgA, AvgCH, AvgCD, AvgCA": ["AvgH", "AvgD", "AvgA", "AvgCH", "AvgCD", "AvgCA"],
    "HxG, AxG": ["HxG", "AxG"]
}

# Obtiene el año de inicio de la temporada correspondiente a cada partido, asumiendo que la temporada comienza en julio y termina en junio del año siguiente.
anio_inicio = np.where(
    df_consolidado["Date"].dt.month >= 7,
    df_consolidado["Date"].dt.year,
    df_consolidado["Date"].dt.year - 1
)

# Construye la temporada de cada partido en formato 2001/02.
temporadas = (
    pd.Series(anio_inicio, index=df_consolidado.index).astype(str)
    + "/"
    + pd.Series(anio_inicio + 1, index=df_consolidado.index).astype(str).str[-2:]
)

# Almacena los resultados de cobertura de cada grupo.
resumen_cobertura = []

# Calcula la cobertura histórica de cada grupo de variables.
for nombre, columnas in grupos_cobertura.items():

    # Identifica los partidos que cuentan con información completa para el grupo.
    disponibles = df_consolidado[columnas].notna().all(axis=1)

    # Obtiene las temporadas correspondientes a los partidos con información disponible.
    temporadas_disponibles = temporadas[disponibles]

    # Agrega los resultados del grupo a la tabla de cobertura.
    resumen_cobertura.append({
        "Variables": nombre,
        "Valores ausentes": len(df_consolidado) - disponibles.sum(),
        "Observaciones disponibles": disponibles.sum(),
        "Temporadas con información": f"{temporadas_disponibles.iloc[0]}--{temporadas_disponibles.iloc[-1]}"
    })

# Convierte los resultados en una tabla.
tabla_cobertura = pd.DataFrame(resumen_cobertura)

# Muestra la tabla de cobertura histórica.
display(tabla_cobertura)
```

**Qué hace, bloque por bloque:**

| Código | Qué hace | Equivalente en R |
|---|---|---|
| `grupos_cobertura = {...}` | Diccionario nombre del grupo → lista de columnas. Las 23 principales usan `columnas_obligatorias` de la celda 1 | `grupos <- list("Variables principales" = ..., ...)` |
| `np.where(month >= 7, year, year - 1)` | Año en que empieza la temporada de cada partido. Con este corte, un partido de julio cuenta para la temporada **siguiente** | `if_else(month(Date) >= 7, year(Date), year(Date) - 1L)` |
| `.astype(str) + "/" + ....str[-2:]` | Etiqueta tipo `2001/02`: el año, una diagonal y los dos últimos dígitos del año siguiente | `sprintf("%d/%02d", a, (a + 1) %% 100)` |
| `df[columnas].notna().all(axis=1)` | `True` si el partido tiene **todas** las columnas del grupo | `complete.cases(e0[columnas])` |
| `len(df) - disponibles.sum()` | Partidos sin el grupo completo | `sum(!disponibles)` |
| `temporadas_disponibles.iloc[0]` / `.iloc[-1]` | La temporada de la **primera** y de la **última fila** con información, en el orden del archivo (no la mínima y la máxima) | `first(t)` / `last(t)` |
| `pd.DataFrame(resumen_cobertura)` | Una lista de diccionarios se vuelve tabla: cada diccionario es un renglón | `bind_rows(..., .id = "Variables")` |

**Salida guardada:**

```text
                               Variables  Valores ausentes  Observaciones disponibles Temporadas con información
0                  Variables principales                 0                       9540           2026/27--2001/02
1                    B365H, B365D, B365A               380                       9160           2026/27--2002/03
2  AvgH, AvgD, AvgA, AvgCH, AvgCD, AvgCA              6840                       2700           2026/27--2020/21
3                               HxG, AxG              9500                         40           2026/27--2026/27
```

Los conteos son correctos. La última columna tiene dos detalles: los rangos salen **al revés** y el
de las cuotas promedio dice **2020/21** cuando debería decir **2019/20**. Por qué pasa y cómo se
corrige está en [Detalles conocidos](#36-detalles-conocidos). Con la corrección, la tabla queda así
(calculada por nosotros en Python y en R, con el mismo resultado):

| Variables | Valores ausentes | Observaciones disponibles | Temporadas con información |
|---|---|---|---|
| Variables principales | 0 | 9,540 | 2001/02–2026/27 |
| B365H, B365D, B365A | 380 | 9,160 | 2002/03–2026/27 |
| AvgH, AvgD, AvgA, AvgCH, AvgCD, AvgCA | 6,840 | 2,700 | 2019/20–2026/27 |
| HxG, AxG | 9,500 | 40 | 2026/27 |

Es la que presenta el reporte entregado (Cuadro 2).

**En R** (ejecutado; con `mes_corte = 7, orden = "iloc"` reproduce exactamente la salida del
notebook, y con los valores por defecto da la tabla corregida):

```r
etiqueta <- function(a) sprintf("%d/%02d", a, (a + 1) %% 100)
grupos <- list(
  "Variables principales" = columnas_obligatorias,
  "B365H, B365D, B365A" = c("B365H", "B365D", "B365A"),
  "AvgH, AvgD, AvgA, AvgCH, AvgCD, AvgCA" = c("AvgH", "AvgD", "AvgA", "AvgCH", "AvgCD", "AvgCA"),
  "HxG, AxG" = c("HxG", "AxG"))

cobertura <- function(columnas, mes_corte = 8, orden = "min_max") {
  temporada   <- if_else(month(e0$Date) >= mes_corte, year(e0$Date), year(e0$Date) - 1L)
  disponibles <- complete.cases(e0[columnas])                   # ≈ notna().all(axis=1)
  t <- temporada[disponibles]
  rango <- if (orden == "min_max") c(min(t), max(t)) else c(first(t), last(t))
  tibble(`Valores ausentes` = sum(!disponibles),
         `Observaciones disponibles` = sum(disponibles),
         `Temporadas con información` = paste(etiqueta(rango[1]), etiqueta(rango[2]), sep = "–"))
}
bind_rows(lapply(grupos, cobertura), .id = "Variables")                                # corregida
bind_rows(lapply(grupos, cobertura, mes_corte = 7, orden = "iloc"), .id = "Variables")  # = notebook
```

> **Decisión:** resumir la cobertura en **4 grupos** (principales, Bet365, promedios de mercado, xG)
> con conteos y rango de temporadas.
>
> **Alternativas:** (a) **una fila por columna** (34) — redundante: las columnas de un mismo grupo
> tienen exactamente la misma cobertura (las tres cuotas de un partido vienen juntas); (b) **un mapa
> de calor temporada × columna** — más visual, más código; (c) **los 4 grupos** (la elegida) — cabe
> en una tabla del reporte.
>
> **Por qué ésta:** cada grupo entra completo o no entra, así que 4 renglones dicen todo lo
> necesario.
>
> **Evidencia en el proyecto:** el reporte la usa como Cuadro 2, con los rangos bien escritos.
>
> **Si preguntan:** "Las variables principales están completas en las 26 temporadas; Bet365 desde
> 2002/03, las cuotas promedio desde 2019/20 y el xG sólo en la temporada actual."

### Celda 27. Exportación

```python
# Exporta la base consolidada a CSV.
df_consolidado.to_csv("E0_consolidado_final.csv",index=False,encoding="utf-8-sig")

print("Se exportaron ",len(df_consolidado), "filas y", len(df_consolidado.columns), "columnas a E0_consolidado_final.csv")
print("Fin")
```

- **`to_csv("E0_consolidado_final.csv", ...)`**: ruta relativa, así que el archivo queda en la
  carpeta desde donde corre el notebook.
- **`index=False`**: no escribe la numeración de filas como una columna extra.
- **`encoding="utf-8-sig"`**: UTF-8 **con BOM** (los 3 bytes `EF BB BF` al inicio), la marca que
  usa Excel para reconocer UTF-8.
- **Cómo queda el texto:** las fechas (`datetime64` sin hora) se escriben `AAAA-MM-DD`; los conteos,
  `3.0`; los nulos, vacío. Lo comprobamos en `E0_consolidado.csv`: empieza con BOM, las 9,540 fechas
  son ISO y la segunda línea es `E0,2026-08-21,Arsenal,Coventry,3.0,0.0,H,2.0,0.0,H,T Bramall,…`.
- **Salida guardada:** `Se exportaron  9540 filas y 34 columnas a E0_consolidado_final.csv` y `Fin`.

**En R** (ejecutado):

```r
write_excel_csv(e0, "E0_consolidado_final.csv", na = "")   # ≈ to_csv(encoding="utf-8-sig")
```

`write_excel_csv()` escribe UTF-8 con BOM, como pandas; `na = ""` deja los nulos vacíos (por
defecto escribiría `NA`). El contenido es el mismo, pero el archivo **no es idéntico byte por
byte**: R pone comillas al texto (`"E0","2026-08-21",…`) y escribe `3` en vez de `3.0`. Por eso su
huella SHA-256 no coincide con la del README (lo comprobamos). Para verificar la huella hay que usar
el archivo que genera pandas.

> **Decisión:** exportar a **CSV** con `encoding="utf-8-sig"` y sin índice.
>
> **Alternativas:** (a) **UTF-8 sin BOM** — el estándar en programación; Excel en Windows puede
> mostrar mal los acentos al abrirlo con doble clic (aquí no hay acentos, así que no cambiaría nada
> visible). (b) **Latin-1** — compatible con Excel antiguo, pero no representa todos los caracteres.
> (c) **Formatos binarios** (`parquet`, `feather`) — guardan los tipos (fecha, enteros) y pesan menos;
> en contra: no se abren en Excel ni se ven en GitHub y requieren otra biblioteca (`pyarrow`).
> (d) **CSV con BOM** (la elegida).
>
> **Por qué ésta:** un CSV lo lee cualquiera (Excel, R, Python, el navegador de GitHub); el BOM
> ayuda a Excel y pandas y `readr` lo leen sin problema.
>
> **Evidencia en el proyecto:** el CSV del repositorio empieza con el BOM y su huella SHA-256 está
> publicada en el README (`7cea84b1…`; la comprobamos con Python y con R).
>
> **Si preguntan:** "CSV porque lo abre cualquiera, y con BOM para que Excel lo reconozca como
> UTF-8. Si alguien lo abre y lo guarda desde Excel, cambian las fechas y los decimales y la huella
> deja de coincidir."

## 3.6 Detalles conocidos

> **Detalles conocidos del notebook entregado.** Ninguno cambia la base que usan el análisis y el
> tablero; conviene conocerlos por si preguntan.
>
> 1. **La tabla de cobertura (celda 26) muestra los rangos al revés y dice "2020/21" para las cuotas
>    promedio, cuando es 2019/20.** Son dos efectos que se suman:
>    - *Al revés:* el archivo va de 2026/27 hacia 2001/02, y `iloc[0]` / `iloc[-1]` toman la primera
>      y la última **fila**, no la temporada menor y la mayor.
>    - *2020/21:* el corte de temporada está en **julio** (`month >= 7`). La última fila con cuotas
>      promedio es el último partido de 2019/20, jugado el **26-jul-2020** (la temporada se alargó por
>      la pandemia), y con ese corte se etiqueta 2020/21. Los 66 partidos de julio de 2020 pasan a
>      la temporada siguiente: con esa regla, 2019/20 tendría 314 partidos y 2020/21, 446.
>    - *Corrección:* cortar en **agosto** (`month >= 8`, igual que `wc_predictor.season_stats()` y el
>      tablero) y usar `min()` / `max()`:
>
>      ```python
>      anio_inicio = np.where(df_consolidado["Date"].dt.month >= 8,
>                             df_consolidado["Date"].dt.year, df_consolidado["Date"].dt.year - 1)
>      ...
>      "Temporadas con información": f"{temporadas_disponibles.min()}–{temporadas_disponibles.max()}"
>      ```
>
>      `min()` y `max()` funcionan con el texto `2001/02` porque todas las etiquetas tienen el mismo
>      formato (año de 4 dígitos al inicio). Los conteos de la tabla ya eran correctos; sólo cambia la
>      columna de temporadas. Nada del código usa esta tabla, y el reporte la presenta corregida.
> 2. **Ruta local.** `carpeta = Path("C:/Users/roski/Downloads")` es la carpeta de descargas de una
>    computadora del equipo. En otra máquina hay que cambiarla antes de correr (el README propone
>    `Path("../../datos_crudos")`).
> 3. **Si falta un archivo, el notebook lo salta sin avisar** (`if not ruta.exists(): continue`, en las
>    celdas 1 y 2): la base quedaría incompleta e incluso podría cambiar la intersección de columnas.
>    Por eso el README pide revisar que el resultado tenga 9,540 filas y 34 columnas. Una línea como
>    `assert len(lista_dfs) == 26` lo detectaría.
> 4. **Nombre del archivo.** El notebook exporta `E0_consolidado_final.csv`, pero el análisis
>    (`load_history(path="E0_consolidado.csv")`) y el tablero leen `E0_consolidado.csv`. El README
>    explica que hay que renombrarlo: `mv E0_consolidado_final.csv E0_consolidado.csv`.
> 5. **Menores:** la celda 5 repite el `dropna` de la 2 (sin efecto); el texto de la celda 22 quedó
>    incompleto; el comentario de la celda 15 dice "menores o iguales a cero" pero el código revisa
>    ≤ 1 (lo correcto); la celda 18 ubica el cambio de formato en 2016/17, cuando es en 2017/18; y si
>    no hubiera ningún archivo, el `exit()` de la celda 1 cerraría el kernel de Jupyter en vez de
>    mostrar un error (`raise FileNotFoundError(...)` sería más claro).

## 3.7 Reconstruir la base desde cero

El repositorio ya trae `E0_consolidado.csv`, así que **para reproducir los resultados no hace falta
reconstruirla** (pasos 2 a 4 del README). El paso 5 del README, opcional, explica cómo rehacerla
desde los datos crudos. Resumen:

**1. Descargar los 26 archivos.** Cada temporada está en una dirección de esta forma:

```text
https://www.football-data.co.uk/mmz4281/AABB/E0.csv
```

`AABB` son los dos últimos dígitos de los dos años de la temporada (`2425` = 2024/25). Todos se
llaman `E0.csv`, así que el navegador los renombra al descargarlos, y el notebook espera esos
nombres **de la temporada más reciente a la más antigua**: `E0 (i).csv` es la temporada que empieza
en 2026 − i.

| Archivo | Temporada (`AABB`) | Archivo | Temporada (`AABB`) |
|---|---|---|---|
| `E0.csv` | 2026/27 (`2627`) | `E0 (13).csv` | 2013/14 (`1314`) |
| `E0 (1).csv` | 2025/26 (`2526`) | `E0 (14).csv` | 2012/13 (`1213`) |
| `E0 (2).csv` | 2024/25 (`2425`) | `E0 (15).csv` | 2011/12 (`1112`) |
| `E0 (3).csv` | 2023/24 (`2324`) | `E0 (16).csv` | 2010/11 (`1011`) |
| `E0 (4).csv` | 2022/23 (`2223`) | `E0 (17).csv` | 2009/10 (`0910`) |
| `E0 (5).csv` | 2021/22 (`2122`) | `E0 (18).csv` | 2008/09 (`0809`) |
| `E0 (6).csv` | 2020/21 (`2021`) | `E0 (19).csv` | 2007/08 (`0708`) |
| `E0 (7).csv` | 2019/20 (`1920`) | `E0 (20).csv` | 2006/07 (`0607`) |
| `E0 (8).csv` | 2018/19 (`1819`) | `E0 (21).csv` | 2005/06 (`0506`) |
| `E0 (9).csv` | 2017/18 (`1718`) | `E0 (22).csv` | 2004/05 (`0405`) |
| `E0 (10).csv` | 2016/17 (`1617`) | `E0 (23).csv` | 2003/04 (`0304`) |
| `E0 (11).csv` | 2015/16 (`1516`) | `E0 (24).csv` | 2002/03 (`0203`) |
| `E0 (12).csv` | 2014/15 (`1415`) | `E0 (25).csv` | 2001/02 (`0102`) |

El README confirma este orden con la propia base: sus filas van de 2026/27 hacia atrás.

En código (ilustrativo: **no lo ejecutamos**, no descargamos los archivos):

```python
from pathlib import Path
import urllib.request

destino = Path("datos_crudos"); destino.mkdir(exist_ok=True)
for i in range(26):                                  # i = 0 → 2026/27, …, i = 25 → 2001/02
    a = 26 - i                                       # dos últimos dígitos del año de inicio
    codigo = f"{a:02d}{a + 1:02d}"                   # "2627", "2526", …, "0102"
    nombre = "E0.csv" if i == 0 else f"E0 ({i}).csv"
    urllib.request.urlretrieve(f"https://www.football-data.co.uk/mmz4281/{codigo}/E0.csv", destino / nombre)
```

```r
codigos <- sprintf("%02d%02d", 26:1, 27:2)                       # "2627", "2526", …, "0102"
nombres <- c("E0.csv", sprintf("E0 (%d).csv", 1:25))
dir.create("datos_crudos", showWarnings = FALSE)
for (i in seq_along(codigos)) {
  download.file(sprintf("https://www.football-data.co.uk/mmz4281/%s/E0.csv", codigos[i]),
                file.path("datos_crudos", nombres[i]), mode = "wb")   # "wb": binario, no altera el archivo
}
```

**2. Ajustar la ruta y ejecutar.** Cambiar `carpeta = Path("C:/Users/roski/Downloads")` por la
carpeta de los archivos (por ejemplo `Path("../../datos_crudos")`) y correr el notebook completo
desde `Codigo/proyecto_mod_8`:

```bash
jupyter nbconvert --to notebook --execute "Limpieza de datos.ipynb" --output Limpieza_ejecutado.ipynb
mv E0_consolidado_final.csv E0_consolidado.csv      # el resto del proyecto busca este nombre
```

Después, revisar que tenga 9,540 filas y 34 columnas.

**3. Comprobar la huella.** Una huella SHA-256 es un código de 64 caracteres que se calcula con el
contenido del archivo: cambia por completo si cambia **un solo carácter**. El README publica las dos:

| Archivo | SHA-256 |
|---|---|
| `E0_consolidado.csv` | `7cea84b123c6924f453463fe3e6936631a87ecc469e2eed649f0c1874bb48e33` |
| `premier_training_data.csv` | `37de4c4cab439e7448f567eb722476885a7770ab53ffcc561b6a70ffbb5c3aa8` |

Las comprobamos sobre los archivos del repositorio y coinciden. Cómo calcularlas:

| Dónde | Comando |
|---|---|
| Windows (PowerShell) | `Get-FileHash Codigo\proyecto_mod_8\E0_consolidado.csv -Algorithm SHA256` |
| Linux / macOS | `sha256sum …` / `shasum -a 256 …` |
| Python | `hashlib.sha256(open("E0_consolidado.csv", "rb").read()).hexdigest()` |
| R | `digest::digest(file = "E0_consolidado.csv", algo = "sha256")` |

Si no coinciden, lo más común es que el archivo se haya abierto y guardado en Excel, que cambia el
formato de fechas y decimales.

**4. Por qué este paso no garantiza exactamente la misma base** (README, 5.3):

- **2026/27 sigue en curso** y Football-Data actualiza su archivo cada semana. La base llega al
  14-sep-2026 (40 partidos de esa temporada). Para obtener la misma, hay que quedarse con los
  partidos hasta esa fecha, por ejemplo:

  ```python
  df_consolidado = df_consolidado[
      pd.to_datetime(df_consolidado["Date"], format="mixed", dayfirst=True) <= "2026-09-14"]
  ```

- **Football-Data corrige a veces datos de temporadas pasadas** (cuotas, árbitros, xG): una descarga
  futura podría diferir en algún valor.
- **El periodo de prueba no tiene fecha de cierre** (empieza el 1-ago-2025): si se agregan partidos,
  cambian las cifras de prueba, la comparación con el mercado y el tablero.
- Un cuarto punto, razonado por nosotros: si los archivos se descargan **en otro orden**, la
  intersección es la misma, pero cambian el orden de las filas (y el de las columnas si el primer
  archivo es otro), así que la huella no coincidiría. Los resultados del análisis no deberían
  cambiar, porque ordena por fecha y en un mismo día cada equipo juega a lo más un partido.

Por eso **la referencia es el `E0_consolidado.csv` del repositorio**, cuya huella se puede comprobar;
el paso 5 sirve para revisar cómo se construyó, no para reemplazarlo.

## 3.8 El notebook completo, en R

Todo junto, en el orden del notebook. Este script completo se ejecutó de principio a fin, sin
avisos, sobre 26 archivos sintéticos que imitan los problemas reales (BOM, fechas `aa` y `aaaa`, una
fila vacía, una fila con un campo de más y columnas que sólo están en algunos años). Cada parte
(revisiones, cobertura, exportación) se ejecutó además sobre `E0_consolidado.csv` y da las mismas
cifras que Python (61,180 nulos, 0 duplicados, 1 partido con tiros inconsistentes, misma tabla de
cobertura). La lectura usa `data.table::fread()` por la razón explicada en la
[celda 2](#celda-2-lectura-unión-y-fila-vacía). La descarga no se ejecutó.

```r
library(readr); library(dplyr); library(lubridate); library(ggplot2)

# Celda 1: rutas y columnas comunes
carpeta  <- "datos_crudos"
archivos <- file.path(carpeta, c("E0.csv", sprintf("E0 (%d).csv", 1:25)))
archivos <- archivos[file.exists(archivos)]
stopifnot(length(archivos) == 26)                    # (mejora: avisa si falta un archivo)
cabecera <- function(ruta) trimws(names(data.table::fread(ruta, nrows = 0)))   # sólo la cabecera
columnas_obligatorias <- Reduce(intersect, lapply(archivos, cabecera))          # 23

# Celda 2: lectura, unión y fila vacía
columnas_complementarias <- c("B365H", "B365D", "B365A", "AvgH", "AvgD", "AvgA",
                              "AvgCH", "AvgCD", "AvgCA", "HxG", "AxG")
columnas_conservar <- unique(c(columnas_obligatorias, columnas_complementarias))  # 34
leer <- function(ruta) {               # fread + fill: el campo sobrante va a una columna nueva (≈ usecols)
  d <- data.table::fread(ruta, colClasses = "character", fill = TRUE, na.strings = c("", "NA"))
  names(d) <- trimws(names(d))
  select(tibble::as_tibble(d), any_of(columnas_conservar))
}
lista_dfs <- lapply(archivos, leer)
e0 <- bind_rows(lista_dfs) |>
  filter(if_any(everything(), ~ !is.na(.x))) |>                 # dropna(how = "all")
  select(any_of(columnas_conservar)) |>
  mutate(across(where(is.character), ~ iconv(.x, "UTF-8", "UTF-8", sub = "")))
cat("Filas:", nrow(e0), "| Diferencia:", sum(sapply(lista_dfs, nrow)) - nrow(e0), "\n")

# Celdas 19 y 23: tipos (en R se convierten antes de revisar: se leyó todo como texto)
columnas_no_negativas <- c("FTHG", "FTAG", "HTHG", "HTAG", "HS", "AS", "HST", "AST",
                           "HF", "AF", "HC", "AC", "HY", "AY", "HR", "AR")
columnas_cuotas <- c("B365H", "B365D", "B365A", "AvgH", "AvgD", "AvgA", "AvgCH", "AvgCD", "AvgCA")
e0 <- e0 |> mutate(Date = dmy(Date),
                   across(all_of(c(columnas_no_negativas, columnas_complementarias)), as.numeric))
stopifnot(!anyNA(e0$Date))                                       # celda 19: 0 fechas inválidas

# Celdas 4 y 6: nulos, tipos y gráfica
nulos <- colSums(is.na(e0)); print(nulos[nulos > 0]); sum(nulos)
table(vapply(e0, function(x) class(x)[1], ""))
barplot(nulos[nulos > 0], las = 2, main = "Valores nulos por columna")

# Celdas 9 a 16: revisiones de consistencia (todas deberían dar 0 filas, salvo la de tiros: 1)
e0 |> add_count(Date, HomeTeam, AwayTeam) |> filter(n > 1)
e0 |> filter(HomeTeam == AwayTeam)
e0 |> filter(if_any(all_of(columnas_no_negativas), ~ .x < 0))
e0 |> filter(HTHG > FTHG | HTAG > FTAG)
e0 |> filter(HST > HS | AST > AS) |> select(Date, HomeTeam, AwayTeam, HST, HS, AST, AS)   # celda 21
e0 |> mutate(ftr = case_when(FTHG > FTAG ~ "H", FTHG < FTAG ~ "A", .default = "D")) |> filter(FTR != ftr)
e0 |> filter(if_any(all_of(columnas_cuotas), ~ .x <= 1))
e0 |> filter(if_any(c(HxG, AxG), ~ .x < 0))

# Celda 26: cobertura (con el corte en agosto y min/max)
etiqueta <- function(a) sprintf("%d/%02d", a, (a + 1) %% 100)
grupos <- list("Variables principales" = columnas_obligatorias,
               "B365H, B365D, B365A" = c("B365H", "B365D", "B365A"),
               "AvgH, AvgD, AvgA, AvgCH, AvgCD, AvgCA" = c("AvgH", "AvgD", "AvgA", "AvgCH", "AvgCD", "AvgCA"),
               "HxG, AxG" = c("HxG", "AxG"))
temporada <- if_else(month(e0$Date) >= 8, year(e0$Date), year(e0$Date) - 1L)
bind_rows(lapply(grupos, function(cols) {
  d <- complete.cases(e0[cols]); t <- temporada[d]
  tibble(ausentes = sum(!d), disponibles = sum(d),
         temporadas = paste(etiqueta(min(t)), etiqueta(max(t)), sep = "–"))
}), .id = "Variables")

# Celda 27: exportación (UTF-8 con BOM)
write_excel_csv(e0, "E0_consolidado_final.csv", na = "")
```

Una diferencia de diseño: en R conviene convertir los tipos **antes** de las revisiones (se leyó todo
como texto para que `bind_rows()` no falle), mientras que pandas ya deduce números al leer y deja
sólo la fecha para el final.

## 3.9 Resumen de decisiones

| Decisión | En una línea | Detalle |
|---|---|---|
| Intersección de columnas (23), no unión | Garantiza variables completas en las 26 temporadas; se calcula sola | [Celda 1](#celda-1-rutas-cabeceras-y-columnas-comunes) |
| Conservar 11 complementarias | Son la referencia de mercado (Avg/AvgC), la historia de Bet365 y el xG | [Celda 2](#celda-2-lectura-unión-y-fila-vacía) |
| `usecols` + `utf-8-sig` + `encoding_errors="ignore"` | Lee los 26 archivos sin error, reconoce `Div` aunque haya BOM; no se perdió ningún carácter | [Celda 2](#celda-2-lectura-unión-y-fila-vacía) |
| No usar `on_bad_lines="skip"` | La versión anterior perdía 90 partidos de 2003/04 y 2004/05 | [Celda 2](#celda-2-lectura-unión-y-fila-vacía) |
| `dropna(how="all")` | Quita 1 fila vacía; un `dropna()` normal dejaría 40 partidos | [Celda 2](#celda-2-lectura-unión-y-fila-vacía) |
| Diagnosticar los nulos sin borrar partidos | Son cobertura de la fuente, no errores; el Elo necesita toda la historia | [Celda 4](#celda-4-columnas-comunes-nulos-y-tipos) |
| 9 revisiones lógicas | Reglas sin excepciones; sólo 2 hallazgos | [Celda 16](#celda-16-xg-negativos) |
| Fechas con `format="mixed"` y `dayfirst=True` | Dos variantes del mismo orden; 5,320 → 0 inválidas; ninguna fuera de su temporada | [Celda 19](#celda-19-fechas-con-formato-mixto) |
| Conservar Newcastle–West Ham (9 a puerta, 8 tiros) | Un tiro de diferencia en 1 de 9,540; corregir sería inventar | [Celda 21](#celda-21-la-fila-inconsistente) |
| Conteos en `float64` | Admite nulos y es lo que usa el modelo; los valores siguen siendo enteros | [Celda 23](#celda-23-conversión-de-tipos) |
| Cobertura en 4 grupos | Cada grupo entra completo o no entra | [Celda 26](#celda-26-tabla-de-cobertura) |
| CSV con `utf-8-sig` | Lo abre cualquiera; el BOM ayuda a Excel | [Celda 27](#celda-27-exportación) |

Dos decisiones de datos que se toman **fuera** de este notebook: modelar desde agosto de 2019 y usar
el histórico desde 2001/02 ([capítulo 2](02_contexto_y_datos.md#26-decisiones-sobre-los-datos)), y
excluir de la modelación los 4 partidos de equipos sin historial previo de tiros
([capítulo 11](11_codigo_analisis_notebook.md)). Todas las decisiones del proyecto están reunidas en
el [capítulo 19](19_decisiones_y_alternativas.md).

