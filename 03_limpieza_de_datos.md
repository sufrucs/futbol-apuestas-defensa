# 3. Limpieza de datos: `Limpieza de datos.ipynb`

[← Contexto y datos](02_contexto_y_datos.md) · [Índice](README.md) · [Siguiente: Elo →](04_elo.md)

**Qué hace este notebook:** toma los 26 CSV descargados de Football-Data (uno por temporada),
se queda con las mismas 33 columnas en todos, los une en una sola tabla, convierte las fechas a un
formato único y ordena los partidos. El resultado es `E0_consolidado.csv`.

## 3.1 El código, bloque por bloque

### Bloque 1: qué columnas se conservan

```python
import pandas as pd

columnas_obligatorias = [
    "Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR", "HTHG", "HTAG", "HTR",
    "HS", "AS", "HST", "AST", "HC", "AC", "HF", "AF", "HY", "AY", "HR", "AR", "Referee",
]
# Estas no están completas para todos los años pero sirven para análisis estadístico
columnas_complementarias = [
    "B365H", "B365D", "B365A", "AvgH", "AvgD", "AvgA", "AvgCH", "AvgCD", "AvgCA", "HxG", "AxG",
]
columnas_totales = columnas_obligatorias + columnas_complementarias
```

- **Qué hace:** define dos listas de nombres de columnas y las une con `+` (en Python, sumar
  listas las concatena).
- **Por qué:** los archivos de Football-Data traen **muchas más** columnas (decenas de casas de
  apuestas, mercados de "más/menos goles", hándicap asiático) y **no todos los años traen las
  mismas**. Se eligen las 22 que existen en todas las temporadas (resultado, estadísticas,
  árbitro) y 11 complementarias que sirven aunque falten en algunos años (cuotas y xG).
- **En R:** `columnas_totales <- c(columnas_obligatorias, columnas_complementarias)`.

### Bloque 2: la lista de archivos

```python
archivos = [r"C:\Users\Daniel\Downloads\E0.csv"] + [
    rf"C:\Users\Daniel\Downloads\E0 ({i}).csv" for i in range(1, 26)
]
```

- **Qué hace:** arma la lista de las 26 rutas. El navegador guardó el primer archivo como
  `E0.csv` y los siguientes como `E0 (1).csv`, `E0 (2).csv`, … `E0 (25).csv`.
- **Sintaxis:** `r"..."` es una cadena "cruda" (las `\` de Windows no se interpretan como escapes);
  `rf"..."` además permite insertar variables con `{i}`. `[... for i in range(1, 26)]` es una
  *list comprehension*: genera la lista para i = 1, …, 25.
- **En R:** `c("E0.csv", sprintf("E0 (%d).csv", 1:25))`.
- **Problema de reproducibilidad:** la ruta es absoluta y personal (`C:\Users\Daniel\...`); en
  otra computadora falla. Ver [hallazgos](18_hallazgos_y_pendientes.md).

### Bloque 3: leer cada archivo y homologar columnas

```python
lista_dfs = []
for idx, ruta in enumerate(archivos):
    nombre_archivo = ruta.split("\\")[-1]
    try:
        df_temp = pd.read_csv(ruta, encoding="latin1", on_bad_lines="skip", engine="python")
        df_temp.columns = df_temp.columns.str.strip()
        df_filtrado = df_temp.reindex(columns=columnas_totales)
        lista_dfs.append(df_filtrado)
    except FileNotFoundError:
        print(f"{nombre_archivo}: No se encontró el archivo (omitido).")
    except Exception as e:
        print(f"{nombre_archivo}: Error al procesar: {e}")
```

Línea por línea:

| Código | Qué hace | Por qué | Equivalente en R |
|---|---|---|---|
| `for idx, ruta in enumerate(archivos)` | Recorre los archivos | Mismo proceso para los 26 | `for (ruta in archivos)` o `lapply(archivos, leer)` |
| `encoding="latin1"` | Lee el texto como Latin-1 | Los CSV antiguos no están en UTF-8; con UTF-8 fallarían caracteres especiales | `read_csv(ruta, locale = locale(encoding = "latin1"))` |
| `on_bad_lines="skip"` | Salta las filas con un número de campos distinto al encabezado | Evita que un archivo con filas mal formadas detenga todo | `readr` no las salta: avisa con `problems()` |
| `engine="python"` | Usa el lector de pandas escrito en Python | Es el que admite `on_bad_lines` de forma flexible | — |
| `.columns.str.strip()` | Quita espacios al inicio y final de los nombres | Algunos archivos traen `"HomeTeam "` con espacio | `names(df) <- trimws(names(df))` |
| `.reindex(columns=columnas_totales)` | Deja **exactamente** esas 33 columnas, en ese orden; si falta alguna, la crea vacía (NaN) | Todos los archivos quedan con la misma estructura y se pueden apilar | ver abajo |
| `try / except` | Si un archivo no existe o falla, avisa y sigue | Un error no detiene la consolidación | `tryCatch(...)` |

> **Atención con `on_bad_lines="skip"`:** es la explicación más probable de que 2003/04 y
> 2004/05 tengan 335 partidos en vez de 380: las filas con campos de más o de menos se descartaron
> **en silencio**. Se puede comprobar releyendo esos dos archivos con `on_bad_lines="warn"`.
> El impacto es bajo (solo afecta el Elo inicial, que se estabiliza años antes de 2019).

**`reindex` en R.** `dplyr::bind_rows()` ya rellena con `NA` las columnas que faltan, así que en R
basta con seleccionar las que existan y apilar:

```r
leer <- function(ruta) {
  df <- read_csv(ruta, locale = locale(encoding = "latin1"), show_col_types = FALSE,
                 col_types = cols(.default = col_character()))
  names(df) <- trimws(names(df))
  df[, intersect(columnas_totales, names(df))]      # solo las columnas que nos interesan
}
```

### Bloque 4: unir, limpiar filas vacías, fechas y orden

```python
if lista_dfs:
    df_resultado = pd.concat(lista_dfs, ignore_index=True)
    df_resultado.dropna(subset=["HomeTeam", "AwayTeam"], how="all", inplace=True)
    df_resultado.sort_values(by="Date", inplace=True, ascending=False)

    df_resultado['Date'] = pd.to_datetime(
        df_resultado['Date'], dayfirst=True, format='mixed', errors='coerce'
    )
    df_resultado.sort_values(by='Date', inplace=True, ascending=False)
    df_resultado['Date'] = df_resultado['Date'].dt.strftime('%Y-%m-%d')

    ruta_salida = r"C:\Users\Daniel\Downloads\E0_filtrado_consolidado.csv"
#    df_resultado.to_csv(ruta_salida, index=False, encoding="utf-8-sig")
```

| Código | Qué hace | Por qué | Equivalente en R |
|---|---|---|---|
| `pd.concat(lista, ignore_index=True)` | Apila las 26 tablas una debajo de otra; reinicia el índice | Una sola tabla con todas las temporadas | `bind_rows(lista)` |
| `dropna(subset=[...], how="all")` | Borra filas donde **ambos** equipos están vacíos | Algunos CSV terminan con filas en blanco | `filter(!(is.na(HomeTeam) & is.na(AwayTeam)))` |
| Primer `sort_values("Date")` | Ordena… pero todavía como **texto** | No sirve de mucho (el texto `"01/02/03"` no ordena como fecha); es inofensivo porque se vuelve a ordenar | — |
| `pd.to_datetime(..., dayfirst=True, format='mixed')` | Convierte el texto a fecha, **día primero**, aceptando `dd/mm/aa` y `dd/mm/aaaa` | Los archivos viejos usan año de 2 dígitos y los nuevos de 4 | `lubridate::dmy(Date)` (acepta ambos) |
| `errors='coerce'` | Si una fecha no se puede leer, la deja vacía (NaT) en vez de fallar | Robustez | `dmy()` devuelve `NA` con aviso |
| Segundo `sort_values(ascending=False)` | Ordena del más reciente al más antiguo | Presentación; el análisis vuelve a ordenar de antiguo a reciente | `arrange(desc(Date))` |
| `.dt.strftime('%Y-%m-%d')` | Escribe la fecha en formato ISO (AAAA-MM-DD) | Formato sin ambigüedad para leerla después | `format(Date, "%Y-%m-%d")` |
| `to_csv(..., encoding="utf-8-sig")` | Guarda en UTF-8 **con BOM** | Para que Excel muestre bien los acentos; por eso el CSV empieza con un carácter invisible | `write_excel_csv()` |

> **Detalle:** la línea `to_csv` está **comentada** (`#`), así que el notebook tal como está no
> guarda nada, y además guardaría `E0_filtrado_consolidado.csv`, mientras que el análisis lee
> `E0_consolidado.csv`. El archivo que usamos se generó en una ejecución anterior. Conviene
> corregirlo (ver [hallazgos](18_hallazgos_y_pendientes.md)).

**Se verificó** que no hubo inversiones de día y mes: leyendo el CSV final como ISO o con
`dayfirst=True` se obtienen exactamente las mismas 9,450 fechas.

## 3.2 El notebook completo, en R

```r
library(readr); library(dplyr); library(lubridate)

carpeta <- "descargas"                          # carpeta con los 26 CSV
archivos <- file.path(carpeta, c("E0.csv", sprintf("E0 (%d).csv", 1:25)))

leer <- function(ruta) {
  df <- read_csv(ruta, locale = locale(encoding = "latin1"), show_col_types = FALSE,
                 col_types = cols(.default = col_character()))    # todo como texto al leer
  names(df) <- trimws(names(df))
  df[, intersect(columnas_totales, names(df))]
}

e0 <- lapply(archivos, leer) |>
  bind_rows() |>                                              # ≈ pd.concat + reindex
  filter(!(is.na(HomeTeam) & is.na(AwayTeam))) |>             # ≈ dropna(how = "all")
  mutate(Date = dmy(Date)) |>                                 # ≈ to_datetime(dayfirst = TRUE)
  mutate(across(c(FTHG:AR, B365H:AxG), as.numeric)) |>        # números como números
  arrange(desc(Date))

write_excel_csv(e0, "E0_consolidado.csv")                     # ≈ to_csv(encoding = "utf-8-sig")
```

## 3.3 Decisiones de limpieza y su justificación

| Decisión | Justificación |
|---|---|
| Conservar solo 33 columnas | Las necesarias para el análisis y las que existen de forma consistente; el resto (decenas de casas y mercados) no aporta a la pregunta |
| No borrar partidos por faltar cuotas o xG | El Elo necesita el histórico completo; cada análisis filtra lo que necesita |
| Homologar fechas y ordenar | Sin un orden cronológico correcto no se pueden calcular variables "previas al partido" |
| Modelar desde agosto de 2019 | Es cuando aparecen las cuotas promedio (la referencia de mercado) y deja 5 temporadas de entrenamiento |
| Excluir 4 partidos sin historial de tiros | Sin partidos previos, las variables de tiros quedan vacías y la regresión no se puede calcular (`dropna` en el notebook de análisis) |
| No corregir la fila con más tiros a puerta que tiros | Es un solo partido de 9,450; corregirlo exigiría inventar un dato |
