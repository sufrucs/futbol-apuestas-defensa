# 11. Código: `Analisis.ipynb`, celda por celda

[← wc_predictor.py](10_codigo_wc_predictor.md) · [Índice](README.md) · [Siguiente: resultados →](12_resultados.md)

Este capítulo explica el notebook **vigente** (versión final entregada, commit `e3bd43f` del 30-sep-2026):
**26 celdas, índices 0 a 25**, organizadas en las secciones §1 a §10 más una sección final sin número
("Alcance, supuestos y reproducibilidad"). Se recorre en el mismo orden del archivo. De cada celda de código
se muestra el código real (el esencial, sin los comentarios línea por línea que trae el original), qué hace
bloque por bloque, su salida guardada y su equivalente en R. Las decisiones llevan un recuadro
**"Decisión y alternativas"**.

Las cifras salen de las salidas guardadas del notebook. Las que el notebook no imprime (tiempos, tamaños de
los pliegues, ejemplos intermedios) las calculamos ejecutando **el mismo código del notebook** el 2-oct-2026;
se indica cuando es así.

---

## 11.0 Panorama

### Qué hace y dónde encaja

El notebook es donde vive el modelo. Hace seis cosas, en este orden:

1. Construye, para cada partido desde agosto de 2019, las variables que **existían antes** de jugarse
   (Elo, goles de la temporada, forma reciente, tiros).
2. **Calibra** K del Elo y k del *shrinkage* con validación temporal (§5).
3. Estima **cinco especificaciones** (M0–M4), cada una con dos regresiones de Poisson.
4. Las compara en **validación** (temporada 2024/25).
5. Las evalúa en **prueba** (15-ago-2025 a 14-sep-2026) contra el **mercado de apertura**.
6. Hace una **predicción de ejemplo** (Arsenal–Man City).

La cadena completa del proyecto:

```text
Limpieza de datos.ipynb ──► E0_consolidado.csv (9,540 partidos × 34 columnas)
                                   │
          wc_predictor.py ─────────┤  load_history, update_elo, build_elo, season_stats, recent_form
                                   ▼
                     ┌──────────────────────────┐
                     │  Analisis.ipynb          │ ◄── este capítulo
                     └──────────────────────────┘
                                   │  la celda 14 (hoy comentada) exportó la base:
                                   ▼
                    premier_training_data.csv (2,696 × 24)
                                   │
         datos_dashboard.py + graficas.py ──► index.qmd ──► sitio (GitHub Pages)
                     ▲
                     └── además lee el CÓDIGO de la celda 2 y las SALIDAS GUARDADAS de las celdas 20, 22 y 24
```

### Flujo de datos dentro del notebook

```text
historial  (9,540 partidos, 2001-08-18 a 2026-09-14) ............................. §3, celda 7
   │
   ├─► construir_base_historica(K, k, incluir_forma=False)   1 vez (35 con la rejilla completa) §5
   │      └─► 3 pliegues de ventana creciente ─► LogLoss de M0 ─► tabla_hiperparametros
   │              └─► mejor combinación: K = 15, k = 0  (LogLoss promedio 0.959558)
   │
   └─► construir_base_historica(15, 0, incluir_forma=True)  ─► 2,700 × 24 ........ §5, celda 11
          └─► dropna(tiros) ─► training_data 2,696 × 24 ─► controles (finitos, sin duplicados)
                 │
                 ├─► train  1,897 (2019/20–2023/24) ─► modelos_entrenados: 5 modelos × 2 GLM ... §6
                 ├─► val      380 (2024/25) ─► tabla_validacion (MAE, LogLoss) ............. §6
                 │                         ├─► referencia simple, resúmenes, correlaciones, VIF  §7
                 │                         └─► comparar_con_mercado ─► tabla de LogLoss ....... §8 ◄ tablero
                 └─► test     419 (15-ago-2025 a 14-sep-2026) ─► tabla_test y mercado ....... §9 ◄ tablero

predecir_partido("Arsenal", "Man City", "2026-09-20") ─► λ, 1X2, marcador más probable ...... §10 ◄ tablero
```

### Mapa de las 26 celdas

| Celda | Tipo | Sección | Qué hace | Salida guardada | Aquí |
|---|---|---|---|---|---|
| 0 | Texto | — | Título y flujo: histórico → Elo y estadísticas → Poisson → Skellam → 1X2 | — | [11.1](#111--1-dependencias-y-configuración-celdas-02) |
| 1 | Texto | §1 | Parámetros, especificaciones y supuestos | — | [11.1](#111--1-dependencias-y-configuración-celdas-02) |
| 2 | Código | §1 | Importaciones y **toda** la configuración | — | [11.1](#111--1-dependencias-y-configuración-celdas-02) |
| 3 | Texto | §2 | Fórmulas de Elo, *shrinkage* y forma; supuestos | — | [11.2](#112--2-construcción-uniforme-de-variables-celdas-35) |
| 4 | Código | §2 | `crear_variables_partido`, `construir_base_historica` | — | [11.2](#112--2-construcción-uniforme-de-variables-celdas-35) |
| 5 | Código | §2 | Exportación a CSV, **comentada** (duplicado de la 14) | — | [11.2.5](#1125-celda-5-la-exportación-comentada) |
| 6 | Texto | §3 | Objetivo y controles de la carga | — | [11.3](#113--3-carga-y-control-inicial-del-histórico-celdas-67) |
| 7 | Código | §3 | Carga el `historial` | `Histórico: 9540 partidos, 2001-08-18 a 2026-09-14` | [11.3](#113--3-carga-y-control-inicial-del-histórico-celdas-67) |
| 8 | Texto | §4 | Poisson, Skellam, LogLoss y MAE; supuestos | — | [11.4](#114--4-funciones-estadísticas-compartidas-celdas-89) |
| 9 | Código | §4 | Las seis funciones del modelo | — | [11.4](#114--4-funciones-estadísticas-compartidas-celdas-89) |
| 10 | Texto | §5 | Validación temporal y criterio ponderado | — | [11.5](#115--5-calibración-de-k-y-k-celdas-1011) |
| 11 | Código | §5 | Calibración, base definitiva, controles y partición | Tabla de 1 fila, K y k elegidos, 2,700 → 2,696, periodos | [11.5](#115--5-calibración-de-k-y-k-celdas-1011) |
| 12 | Texto | Nota | Por qué se excluyen 4 partidos | — | [11.6](#116-nota-los-4-partidos-sin-historial-celdas-1214) |
| 13 | Código | Nota | Muestra los 4 partidos | Tabla de 4 filas | [11.6](#116-nota-los-4-partidos-sin-historial-celdas-1214) |
| 14 | Código | Nota | Exportación a CSV, **comentada** | — | [11.6.3](#1163-celda-14-la-exportación-de-la-caché) |
| 15 | Texto | §6 | Estructura de M0–M4 y ΔLogLoss | — | [11.7](#117--6-estimación-m0m4-y-validación-202425-celdas-1516) |
| 16 | Código | §6 | Estima M0–M4 y los compara en validación | Tabla de 5 filas | [11.7](#117--6-estimación-m0m4-y-validación-202425-celdas-1516) |
| 17 | Texto | §7 | Referencia constante y VIF | — | [11.8](#118--7-referencia-simple-y-diagnóstico-celdas-1718) |
| 18 | Código | §7 | Referencia simple, resúmenes de M0, correlaciones y VIF | Diccionario, 2 resúmenes, 4 tablas | [11.8](#118--7-referencia-simple-y-diagnóstico-celdas-1718) |
| 19 | Texto | §8 | Probabilidad implícita, normalización, margen | — | [11.9](#119--8-cuotas-de-apertura-como-referencia-externa-celdas-1920) |
| 20 | Código | §8 | `cargar_cuotas`, `comparar_con_mercado`; mercado en validación | Margen 4.49 %, tabla de 6 | [11.9](#119--8-cuotas-de-apertura-como-referencia-externa-celdas-1920) ◄ tablero |
| 21 | Texto | §9 | Evaluación en prueba | — | [11.10](#1110--9-evaluación-en-prueba-y-comparación-con-el-mercado-celdas-2122) |
| 22 | Código | §9 | Las cinco especificaciones en prueba; mercado | Tabla de 5, margen 5.84 %, tabla de 6 | [11.10](#1110--9-evaluación-en-prueba-y-comparación-con-el-mercado-celdas-2122) ◄ tablero |
| 23 | Texto | §10 | Marcador exacto y marcador modal | — | [11.11](#1111--10-predicción-individual-celdas-2324) |
| 24 | Código | §10 | `predecir_partido` y el ejemplo | 10 líneas | [11.11](#1111--10-predicción-individual-celdas-2324) ◄ tablero |
| 25 | Texto | Final | Supuestos centrales y reproducibilidad | — | [11.12](#1112-sección-final-alcance-supuestos-y-reproducibilidad-celda-25) |

### Todas las piezas

**Funciones definidas en el notebook (13):**

| Función | Celda | Para qué sirve | Quién la usa | Aquí |
|---|---|---|---|---|
| `crear_variables_partido` | 4 | Variables de **un** partido con información previa | `construir_base_historica`, `predecir_partido`; `datos_dashboard.py` tiene una copia con la misma lógica | [11.2.1](#1121-crear_variables_partido) |
| `construir_base_historica` | 4 | Recorre el histórico **día por día** y arma la base | `calibrar_hiperparametros` (1 o 35 veces) y la base definitiva (celda 11) | [11.2.2](#1122-construir_base_historica) |
| `preparar_X` | 9 | Matriz de regresores: Elo ÷ 400 y constante | `entrenar_modelo`, `predecir_con_modelo`, `tabla_vif`; copia en el tablero | [11.4.1](#1141-preparar_x) |
| `entrenar_modelo` | 9 | Ajusta las **dos** regresiones de Poisson | Calibración (§5), estimación (§6); copia en el tablero | [11.4.2](#1142-entrenar_modelo) |
| `probabilidades_1x2` | 9 | De (λ local, λ visitante) a P(1), P(X), P(2) con Skellam | `predecir_con_modelo`, referencia simple (§7); copia en el tablero | [11.4.3](#1143-probabilidades_1x2) |
| `resultados_observados` | 9 | Codifica el resultado real: 0 = local, 1 = empate, 2 = visita | `evaluar_predicciones`, `comparar_con_mercado`; copia en el tablero | [11.4.4](#1144-resultados_observados) |
| `predecir_con_modelo` | 9 | λ y probabilidades para una tabla de partidos | §5, §6, §9, §10; copia en el tablero | [11.4.5](#1145-predecir_con_modelo) |
| `evaluar_predicciones` | 9 | MAE (local, visitante, promedio) y LogLoss 1X2 | §5, §6, §7, §9; copia en el tablero | [11.4.6](#1146-evaluar_predicciones) |
| `calibrar_hiperparametros` | 11 | Prueba cada (K, k) en 3 pliegues temporales | Celda 11 | [11.5.1](#1151-calibrar_hiperparametros) |
| `tabla_vif` | 18 | Factor de inflación de la varianza de cada regresor | Celda 18 (M0); el tablero calcula el de M4 por su cuenta | [11.8.3](#1183-correlaciones-y-vif-de-m0) |
| `cargar_cuotas` | 20 | Lee las cuotas promedio de apertura | §8 y §9 | [11.9.1](#1191-cargar_cuotas) |
| `comparar_con_mercado` | 20 | LogLoss del mercado y de los modelos en **los mismos** partidos | §8 y §9; el tablero usa su propia `probabilidades_mercado` | [11.9.2](#1192-comparar_con_mercado) |
| `predecir_partido` | 24 | Pronóstico completo de un partido nuevo | El ejemplo; `datos_simulador()` del tablero aplica la misma lógica a todos los pares | [11.11](#1111--10-predicción-individual-celdas-2324) |

**Constantes y listas (celda 2, salvo `MODELOS_PRUEBA`):**

| Pieza | Valor | Quién la usa | Aquí |
|---|---|---|---|
| `FECHA_INICIO`, `FECHA_VALIDACION`, `FECHA_PRUEBA` | 2019-08-01, 2024-08-01, 2025-08-01 | `construir_base_historica` (`desde`), partición (celda 11) | [11.1.2](#1112-fechas-de-corte) |
| `K_ELO`, `K_SHRINKAGE` | Se leen de `wc_predictor.py` (15 y 0); la celda 11 las sobrescribe con el resultado de la calibración | Valores por defecto de §2, base definitiva, `predecir_partido` | [11.1.3](#1113-parámetros-del-modelo) |
| `N_FORMA`, `DECAY_FORMA`, `ESCALA_ELO` | 10, 0.85, 400 | `crear_variables_partido`, `preparar_X`; el tablero lee `N_FORMA` y `DECAY_FORMA` del código | [11.1.3](#1113-parámetros-del-modelo) |
| `K_ELO_CANDIDATOS`, `K_SHRINKAGE_CANDIDATOS` | Activas `[15]` y `[0]`; la rejilla completa, comentada | `calibrar_hiperparametros`; el tablero toma la lista más larga (la comentada) | [11.1.4](#1114-rejillas-y-pliegues-y-por-qué-la-rejilla-quedó-comentada) |
| `FOLDS_HIPERPARAMETROS` | 2021/22, 2022/23, 2023/24 | `calibrar_hiperparametros`; el tablero lee los años | [11.1.4](#1114-rejillas-y-pliegues-y-por-qué-la-rejilla-quedó-comentada) |
| `ARCHIVO_CUOTAS`, `CLAVES`, `OBJETIVOS`, `CUOTAS`, `PROBS` | Nombres de archivo y columnas | Todas las secciones | [11.1.5](#1115-nombres-de-archivo-y-de-columnas) |
| `GRUPOS`, `ESPECIFICACIONES` | Bloques de variables y los 5 modelos | §5 (sólo M0), §6, §9, §10 | [11.1.6](#1116-grupos-y-especificaciones-los-cinco-modelos) |
| `TODOS_LOS_PREDICTORES`, `COLUMNAS_TIROS` | 17 y 8 nombres | Controles y `dropna` (celda 11), celda 13 | [11.1.7](#1117-todos_los_predictores-y-columnas_tiros) |
| `MODELOS_PRUEBA` (celda 22) | Las cinco especificaciones | §9 | [11.10](#1110--9-evaluación-en-prueba-y-comparación-con-el-mercado-celdas-2122) |

**De `wc_predictor.py`** (explicadas en el [capítulo 10](10_codigo_wc_predictor.md)): `load_history` (§3),
`update_elo` (§2), `build_elo` (§10), `season_stats` y `recent_form` (§2), y las constantes `ELO_INIT`, `ELO_K`,
`ELO_SCALE` y `SHRINKAGE_K`. Al importarse, el módulo también carga el histórico y calcula `avg_team_goals`,
el respaldo que usa `recent_form` cuando un equipo no tiene partidos previos (ver [11.6](#116-nota-los-4-partidos-sin-historial-celdas-1214)).
`HOME_FACTOR` y `AWAY_FACTOR` existen en el módulo, pero el notebook no los usa.

### Qué salidas lee el tablero para su verificación

La tabla de verificación del tablero (**17 de 17 ✓**) no compara contra cifras copiadas a mano: la función
`cifras_publicadas_notebook()` de `datos_dashboard.py` abre `Analisis.ipynb` como JSON y recorre las
**salidas guardadas** de todas las celdas:

| Qué busca | Dónde está | Cifras |
|---|---|---|
| La línea `Validación: 380/380 con cuotas válidas…` y la tabla `LogLoss_1X2` que le sigue | Celda 20 (§8) | 6: mercado de apertura y M0–M4 en validación |
| La línea `Cuotas válidas en prueba…` y la tabla que le sigue | Celda 22 (§9) | 6: mercado y M0–M4 en prueba |
| Las líneas `lambda_home :`, `lambda_away :`, `P_home :`, `P_draw :`, `P_away :` | Celda 24 (§10) | 5: el ejemplo Arsenal–Man City con M0 |

Después recalcula esas 17 cifras con su propia copia de las funciones y las compara (tolerancia de 5 × 10⁻⁷
para los LogLoss; λ a 3 decimales y probabilidades a 4). Si el notebook se guarda **sin salidas**, no las
encuentra y marca ✗ ("HAY DIFERENCIAS"). Por eso, cuando Daniel agregó M3 a la prueba, la verificación pasó
sola de 16 a 17 cifras, sin tocar el tablero. El tablero también lee **código** de la celda 2 (no salidas):
`N_FORMA`, `DECAY_FORMA`, las rejillas y los años de los pliegues
(detalle en [13a](13a_codigo_datos_dashboard.md)).

> Consecuencia práctica: si alguien edita el notebook, debe guardarlo **con salidas**; y si cambia el texto de
> esos `print` (por ejemplo, "Cuotas válidas en prueba"), la verificación deja de encontrar las tablas.

### Cómo se corre y cuánto tarda

- Se ejecuta con el directorio de trabajo en `Codigo/proyecto_mod_8`: `load_history()` y `ARCHIVO_CUOTAS`
  usan la ruta relativa `E0_consolidado.csv`.
- Tiempos medidos en esta computadora (2-oct-2026, Python 3.10) con el código del notebook: la base de
  calibración (sin forma) tarda **≈ 38 s**; la base completa, **≈ 60 s**; `predecir_partido`, **≈ 0.6 s**.
- Con la rejilla completa activa, la calibración reconstruiría la base 35 veces: **≈ 22 minutos** más
  (estimado: 35 × 38 s).

### Equivalentes en R

| Parte del notebook | Script verificado de la guía |
|---|---|
| Elo (`build_elo`, `update_elo`) | [`equivalencias_R/01_elo.R`](equivalencias_R/01_elo.R) |
| §4, §6, §7 y §9: GLM, 1X2, LogLoss, MAE, dispersión, VIF de M4 | [`equivalencias_R/02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R) |
| §8 y §9: cuotas, margen, mercado contra M0 | [`equivalencias_R/03_mercado.R`](equivalencias_R/03_mercado.R) |
| §2: `season_stats` y `recent_form` en dos partidos | [`equivalencias_R/05_variables_previas.R`](equivalencias_R/05_variables_previas.R) |
| §5 completa: las 35 combinaciones de K y k | [`equivalencias_R/06_calibracion.R`](equivalencias_R/06_calibracion.R) |

Los bloques de R de este capítulo que no están en esos scripts (por ejemplo, la traducción literal de
`construir_base_historica` o de `predecir_partido`) los ejecutamos con R 4.3.2 contra los datos del proyecto
y dan las mismas cifras que Python; se marca **(verificado)**. Lo que no se ejecutó se marca **(ilustrativo)**.

---

## 11.1 · §1 Dependencias y configuración (celdas 0–2)

**Celda 0 (texto)** presenta el análisis: cinco especificaciones de regresión de Poisson y la regla central,
*"para construir las variables de un partido fechado en t, sólo se utiliza información disponible antes de
t"*. Resume el flujo como histórico → Elo y estadísticas previas → Poisson → (λ_H, λ_A) → Skellam → P(1), P(X),
P(2). **Celda 1 (texto)** lista los parámetros (Elo inicial 1500, escala 400, K y k "se calibran
posteriormente", ventana 10 y decaimiento 0.85), describe M0–M4 y aclara dos supuestos: los cortes son
cronológicos y el "óptimo" de la rejilla es *el mejor entre los valores probados*, no un óptimo global.

**Celda 2 (código)** concentra toda la configuración. Se explica por bloques.

### 11.1.1 Importaciones

```python
from pathlib import Path
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import poisson, skellam
from sklearn.metrics import log_loss, mean_absolute_error
from statsmodels.stats.outliers_influence import variance_inflation_factor
import itertools
import wc_predictor          # el módulo del equipo (capítulo 10)
```

| Librería de Python | Para qué se usa aquí | Equivalente en R |
|---|---|---|
| `pathlib.Path` | Ruta del archivo de cuotas | `file.path()` |
| `pandas` | Tablas de datos (`DataFrame`) | `data.frame` / `tibble`, `dplyr` |
| `numpy` | Arreglos y operaciones vectorizadas | Vectores y matrices de R base |
| `statsmodels` | GLM de Poisson con salida tipo econometría; VIF | `glm()`; `lm()` para el VIF |
| `scipy.stats` | Distribuciones de Poisson y Skellam | `dpois()`; Skellam sumando la matriz `outer(dpois(), dpois())` |
| `sklearn.metrics` | `log_loss` y `mean_absolute_error` | A mano (`-mean(log(...))`, `mean(abs(...))`) o `yardstick` |
| `itertools` | `product()`: todas las combinaciones de la rejilla | `expand.grid()` o `tidyr::crossing()` |
| `wc_predictor` | Elo, promedios de temporada, forma | `source("wc_predictor.R")` (no existe; ver los scripts de la guía) |

### 11.1.2 Fechas de corte

```python
# Fechas inclusivas por la izquierda: [inicio, fin)
FECHA_INICIO = pd.Timestamp("2019-08-01")
FECHA_VALIDACION = pd.Timestamp("2024-08-01")
FECHA_PRUEBA = pd.Timestamp("2025-08-01")
```

- **[inicio, fin)** quiere decir que el inicio entra y el fin no. Entrenamiento: `Date < 2024-08-01`;
  validación: `2024-08-01 ≤ Date < 2025-08-01`; prueba: `Date ≥ 2025-08-01`. Ningún partido cae en dos
  conjuntos.
- El **1 de agosto** es el corte de temporada de todo el proyecto (también lo usa `season_stats`). Funciona
  incluso con 2019/20, que por la pandemia terminó en julio de 2020.
- `FECHA_INICIO` marca desde cuándo se guardan partidos en la base de modelación. El Elo, en cambio, se
  calcula desde 2001 (ver [11.2.2](#1122-construir_base_historica)). Coincide con el inicio de las cuotas
  promedio `AvgH/AvgD/AvgA`: el primer partido con esas cuotas es del 9-ago-2019, el primero de la base. El
  notebook no da otra razón para esa fecha. Los tamaños de los periodos se discuten en el
  [capítulo 9](09_evaluacion_y_validacion.md).

### 11.1.3 Parámetros del modelo

```python
#Variables definidas en wc_predictor.py
K_ELO = wc_predictor.ELO_K              # 15
K_SHRINKAGE = wc_predictor.SHRINKAGE_K  # 0
N_FORMA = 10
DECAY_FORMA = 0.85
ESCALA_ELO = wc_predictor.ELO_SCALE     # 400
```

- K y k **no se escriben aquí**: se leen de `wc_predictor.py`, que es la única fuente. Así el notebook, el
  módulo y el tablero (que también los lee de ahí) no pueden quedar desfasados.
- La celda 11 los **sobrescribe** con el resultado de la calibración (`K_ELO = float(mejor["K_Elo"])`), así
  que desde ahí valen 15.0 y 0.0. Como la calibración elige justo lo que dice el módulo, el valor no cambia.
- `N_FORMA = 10` y `DECAY_FORMA = 0.85` son la ventana y el decaimiento de la forma reciente
  ([capítulo 5](05_promedios_ajustados_y_forma.md)); `ESCALA_ELO = 400` es la escala del Elo
  ([capítulo 4](04_elo.md)). No se calibraron.

### 11.1.4 Rejillas y pliegues (y por qué la rejilla quedó comentada)

```python
#Estos fueron los valores inicialmente utilizados, pero nos quedamos con K_SHRINKAGE = 0, y K_ELO = 15,
#ya que nos dieron los mejores resultados en la validación cruzada
#K_ELO_CANDIDATOS = [15, 20, 25, 30, 35, 40, 45]
#K_SHRINKAGE_CANDIDATOS = [0, 5, 10, 15, 20]

K_ELO_CANDIDATOS = [15]
K_SHRINKAGE_CANDIDATOS = [0]

FOLDS_HIPERPARAMETROS = [
    (pd.Timestamp("2021-08-01"), pd.Timestamp("2022-08-01")),   # primer pliegue: 2021/22
    (pd.Timestamp("2022-08-01"), pd.Timestamp("2023-08-01")),   # segundo: 2022/23
    (pd.Timestamp("2023-08-01"), pd.Timestamp("2024-08-01")),   # tercero: 2023/24
]
```

- La **rejilla completa** que se probó es K ∈ {15, 20, …, 45} (7 valores) × k ∈ {0, 5, …, 20} (5 valores) =
  **35 combinaciones**. Quedó **comentada** (con `#`) y activa sólo la ganadora, `[15]` × `[0]`. Por eso la
  tabla que imprime la celda 11 tiene **una sola fila**.
- **Por qué comentada:** cada combinación obliga a reconstruir toda la base histórica (≈ 38 s aquí), así que
  la rejilla completa añadiría ≈ 22 minutos a cada ejecución. Ya elegidos K y k, repetir la búsqueda en cada
  corrida no aporta nada.
- **Cómo repetirla:** quitar el `#` de las dos listas completas y borrar (o comentar) las de un solo valor. Lo
  hicimos sobre una copia del notebook: el resultado está en la [tabla de la rejilla](#1155-la-rejilla-completa)
  y lo reproduce en R [`06_calibracion.R`](equivalencias_R/06_calibracion.R).
- **Pliegues** (*folds*): cada tupla es (inicio, fin) de una temporada evaluada. Las tres están **dentro del
  entrenamiento** (antes del 1-ago-2024).
- El comentario dice "validación cruzada": es validación cruzada **temporal**, no aleatoria ni *k-fold*
  (ver [capítulo 9](09_evaluacion_y_validacion.md)).
- El tablero lee estas listas del código y se queda con **la más larga** (la comentada) para describir en su
  texto qué se probó.

> **Decisión:** dejar escrita, pero comentada, la rejilla completa, y activa sólo la combinación elegida.
> **Alternativas:** (a) dejar activa la rejilla completa — a favor: la búsqueda se repite sola; en contra:
> ≈ 22 minutos extra en cada ejecución; (b) borrar la rejilla — a favor: código más limpio; en contra: se pierde
> el registro de qué se probó; (c) guardar el resultado de la rejilla en un CSV y leerlo — a favor: rápido y
> auditable; en contra: otro archivo que mantener (no se hizo).
> **Por qué ésta:** conserva el registro de la búsqueda en el propio código, mantiene corta la ejecución y se
> reproduce quitando dos `#`.
> **Evidencia en el proyecto:** al reactivar la rejilla completa gana K = 15, k = 0 con 0.959558, la misma
> cifra que imprime el notebook; `06_calibracion.R` obtiene las 35 cifras a 6 decimales.
> **Si preguntan:** "La búsqueda completa tarda unos veinte minutos; dejamos activa sólo la combinación ganadora
> y la rejilla completa comentada, que se repite quitando dos símbolos de comentario."

### 11.1.5 Nombres de archivo y de columnas

```python
ARCHIVO_CUOTAS = Path("E0_consolidado.csv")      # las cuotas están en el mismo histórico
CLAVES = ["Date", "HomeTeam", "AwayTeam"]        # identifican un partido
OBJETIVOS = ["home_goals", "away_goals"]         # lo que se predice
CUOTAS = ["AvgH", "AvgD", "AvgA"]                # cuotas promedio de APERTURA: local, empate, visita
PROBS = ["P_home", "P_draw", "P_away"]           # nombres de las probabilidades 1X2
```

Definir los nombres una vez evita errores de dedo: si se quisiera usar el mercado de **cierre**, bastaría con
`CUOTAS = ["AvgCH", "AvgCD", "AvgCA"]` (el tablero lo hace como referencia adicional).

### 11.1.6 `GRUPOS` y `ESPECIFICACIONES`: los cinco modelos

```python
GRUPOS = {
    "base_home": ["elo_diff", "gf_home", "ga_away"],
    "base_away": ["elo_diff", "gf_away", "ga_home"],
    "forma_home": ["form_gf_home", "form_ga_away"],
    "forma_away": ["form_gf_away", "form_ga_home"],
    "tiros_home": ["shots_for_home", "shots_against_away"],
    "tiros_away": ["shots_for_away", "shots_against_home"],
    "sot_home": ["sot_for_home", "sot_against_away"],
    "sot_away": ["sot_for_away", "sot_against_home"],
}
ESPECIFICACIONES = {
    "M0_Base": (GRUPOS["base_home"], GRUPOS["base_away"]),
    "M1_Forma": (GRUPOS["base_home"] + GRUPOS["forma_home"], GRUPOS["base_away"] + GRUPOS["forma_away"]),
    "M2_Tiros": (GRUPOS["base_home"] + GRUPOS["tiros_home"], GRUPOS["base_away"] + GRUPOS["tiros_away"]),
    "M3_SOT":   (GRUPOS["base_home"] + GRUPOS["sot_home"],   GRUPOS["base_away"] + GRUPOS["sot_away"]),
    "M4_Completo": (GRUPOS["base_home"] + GRUPOS["forma_home"] + GRUPOS["tiros_home"] + GRUPOS["sot_home"],
                    GRUPOS["base_away"] + GRUPOS["forma_away"] + GRUPOS["tiros_away"] + GRUPOS["sot_away"]),
}
```

- Un **grupo** es un bloque de variables para una de las dos ecuaciones. La lógica de cada ecuación es "lo que
  genera el equipo que ataca + lo que concede su rival": para los goles del local entran los goles a favor del
  local (`gf_home`) y los goles en contra del visitante (`ga_away`).
- `elo_diff` (Elo local − Elo visitante) está en **las dos** ecuaciones: se espera coeficiente positivo para los
  goles del local y negativo para los del visitante (salieron 0.6283 y −0.6854).
- Cada especificación es una tupla **(columnas del local, columnas del visitante)**. Sumar listas
  (`+`) las concatena.

| Modelo | Agrega a M0 | Variables por ecuación |
|---|---|---|
| `M0_Base` | — (Elo y goles de la temporada) | 3 |
| `M1_Forma` | Goles recientes a favor y en contra | 5 |
| `M2_Tiros` | Tiros recientes a favor y en contra | 5 |
| `M3_SOT` | Tiros a puerta recientes | 5 |
| `M4_Completo` | Los tres bloques | 9 |

> **Decisión:** cinco modelos anidados: una base (M0), cada bloque por separado (M1–M3) y todos juntos (M4).
> **Alternativas:** (a) todas las combinaciones de los tres bloques (2³ = 8 modelos; faltaron forma + tiros,
> forma + tiros a puerta y tiros + tiros a puerta) — más completo, pero más comparaciones y más riesgo de elegir
> por suerte en validación; (b) selección automática de variables (paso a paso por AIC, LASSO) — elige
> variables sueltas, pero es menos interpretable y exige otra capa de validación; (c) un solo modelo grande —
> no permite saber qué bloque aporta. Ninguna se probó.
> **Por qué ésta:** responde directo a la pregunta del reporte (¿aportan las variables de desempeño reciente?):
> cada bloque se mide contra la misma base; cinco comparaciones son pocas e interpretables.
> **Evidencia en el proyecto:** en validación los cuatro modelos ampliados mejoran el LogLoss de M0 (M4 por
> −0.010935); en prueba ninguno lo hace (el más cercano, M3, queda +0.000792 arriba).
> **Si preguntan:** "Agregamos los bloques uno por uno para saber cuál aporta; en validación todos ayudaron un
> poco y en prueba ninguno superó a la base."

### 11.1.7 `TODOS_LOS_PREDICTORES` y `COLUMNAS_TIROS`

```python
TODOS_LOS_PREDICTORES = sorted({
    columna
    for par in ESPECIFICACIONES.values()      # cada (local, visitante)
    for columnas in par                       # cada una de las dos listas
    for columna in columnas                   # cada nombre
})
COLUMNAS_TIROS = [c for c in TODOS_LOS_PREDICTORES if c.startswith(("shots_", "sot_"))]
```

- Las llaves `{ … }` con `for` forman un **conjunto por comprensión** (*set comprehension*): recorre los tres
  niveles (modelo → ecuación → columna) y, como es un conjunto, cada nombre aparece una sola vez. `sorted()` lo
  ordena alfabéticamente.
- Resultado: **17 predictores** distintos (`elo_diff`, 4 de goles de la temporada, 4 de forma, 4 de tiros y 4 de
  tiros a puerta). `elo_home` y `elo_away` están en la base pero no son predictores: entra su diferencia.
- `COLUMNAS_TIROS`: las **8** que empiezan con `shots_` o `sot_` (`startswith` acepta una tupla de prefijos).
  Se usan para quitar los 4 partidos sin historial de tiros ([11.6](#116-nota-los-4-partidos-sin-historial-celdas-1214)).

**En R (verificado):** mismos 17 nombres y en el mismo orden.

```r
grupos <- list(
  base_home  = c("elo_diff", "gf_home", "ga_away"),        base_away  = c("elo_diff", "gf_away", "ga_home"),
  forma_home = c("form_gf_home", "form_ga_away"),          forma_away = c("form_gf_away", "form_ga_home"),
  tiros_home = c("shots_for_home", "shots_against_away"),  tiros_away = c("shots_for_away", "shots_against_home"),
  sot_home   = c("sot_for_home", "sot_against_away"),      sot_away   = c("sot_for_away", "sot_against_home"))
especificaciones <- with(grupos, list(
  M0_Base     = list(base_home, base_away),
  M1_Forma    = list(c(base_home, forma_home), c(base_away, forma_away)),
  M2_Tiros    = list(c(base_home, tiros_home), c(base_away, tiros_away)),
  M3_SOT      = list(c(base_home, sot_home),   c(base_away, sot_away)),
  M4_Completo = list(c(base_home, forma_home, tiros_home, sot_home),
                     c(base_away, forma_away, tiros_away, sot_away))))
todos_los_predictores <- sort(unique(unlist(especificaciones)), method = "radix")  # radix: mismo orden que Python
columnas_tiros <- todos_los_predictores[grepl("^(shots_|sot_)", todos_los_predictores)]
folds <- list(c("2021-08-01", "2022-08-01"), c("2022-08-01", "2023-08-01"), c("2023-08-01", "2024-08-01"))
rejilla <- expand.grid(K_Elo = c(15, 20, 25, 30, 35, 40, 45), k_shrinkage = c(0, 5, 10, 15, 20))  # ≈ itertools.product
```

`unlist()` aplana la lista anidada (como los tres `for`), `unique()` hace el papel del conjunto y
`method = "radix"` ordena como Python (por código de carácter, sin reglas del idioma). Con `with(grupos, …)`
se escriben los nombres de los grupos sin repetir `grupos$`.

---

## 11.2 · §2 Construcción uniforme de variables (celdas 3–5)

**Celda 3 (texto)** escribe las tres fórmulas que el código aplica (explicadas a fondo en los capítulos
[4](04_elo.md) y [5](05_promedios_ajustados_y_forma.md)):

$$
E_H=\frac{1}{1+10^{(R_A-R_H)/400}},\qquad R_H^{\text{nuevo}}=R_H+K\,(S_H-E_H),\qquad D=\frac{R_H-R_A}{400}
$$

$$
x^*=\frac{n}{n+k}\,x_{\text{actual}}+\frac{k}{n+k}\,x_{\text{previo}}
\qquad(\text{si } n=0:\ x^*=x_{\text{previo}};\ \text{si } k=0 \text{ y } n\ge 1:\ x^*=x_{\text{actual}})
$$

$$
\tilde w_i=d^{\,m-1-i},\qquad w_i=\frac{\tilde w_i}{\sum_j \tilde w_j},\qquad d=0.85,\ m\le 10
$$

Y lista siete supuestos:

| Supuesto (celda 3) | Cómo se ve en el código | Dónde se discute |
|---|---|---|
| No hay *look-ahead*: `df_pre` sólo tiene partidos anteriores | La guardia de `crear_variables_partido` y el corte por día | [11.2.1](#1121-crear_variables_partido), [cap. 9](09_evaluacion_y_validacion.md) |
| Un equipo sin rating empieza en 1500 | `elo_previo.get(equipo, ELO_INIT)` | [cap. 4](04_elo.md) |
| Mismo K para todos los equipos y fechas | Un solo `k_elo` | [cap. 4](04_elo.md), [cap. 15](15_limitaciones_y_extensiones.md) |
| El Elo no incluye localía | `update_elo` no da puntos extra al local; la localía la captan las dos ecuaciones de Poisson | [cap. 4](04_elo.md) |
| La temporada empieza el 1 de agosto | `season_stats` | [cap. 5](05_promedios_ajustados_y_forma.md) |
| GF y GA juntan partidos de local y de visitante | `season_stats` no separa por condición | [cap. 5](05_promedios_ajustados_y_forma.md) |
| Los partidos de una misma fecha usan el mismo corte | `groupby("date")` | [11.2.2](#1122-construir_base_historica) |

**Celda 4 (código)** define las dos funciones de la sección.

### 11.2.1 `crear_variables_partido`

```python
def crear_variables_partido(df_pre, fecha, home, away, elo_home, elo_away,
                            k_shrinkage=K_SHRINKAGE, incluir_forma=True):
    fecha = pd.Timestamp(fecha)
    if not (df_pre["date"] < fecha).all():
        raise ValueError("df_pre contiene información de la fecha objetivo o posterior")

    stats_h = wc_predictor.season_stats(df_pre, home, fecha, k=k_shrinkage)
    stats_a = wc_predictor.season_stats(df_pre, away, fecha, k=k_shrinkage)
    variables = {
        "elo_home": elo_home, "elo_away": elo_away,
        "elo_diff": elo_home - elo_away,
        "gf_home": stats_h["gf_avg"], "ga_home": stats_h["ga_avg"],
        "gf_away": stats_a["gf_avg"], "ga_away": stats_a["ga_avg"],
    }
    if not incluir_forma:
        return variables                       # sólo las 7 de M0 (más rápido)

    form_h = wc_predictor.recent_form(df_pre, home, n=N_FORMA, decay=DECAY_FORMA)
    form_a = wc_predictor.recent_form(df_pre, away, n=N_FORMA, decay=DECAY_FORMA)
    variables.update({
        "form_gf_home": form_h["gf"], "form_ga_home": form_h["ga"],
        "form_gf_away": form_a["gf"], "form_ga_away": form_a["ga"],
        "shots_for_home": form_h["shots_for"], "shots_against_home": form_h["shots_against"],
        "shots_for_away": form_a["shots_for"], "shots_against_away": form_a["shots_against"],
        "sot_for_home": form_h["sot_for"], "sot_against_home": form_h["sot_against"],
        "sot_for_away": form_a["sot_for"], "sot_against_away": form_a["sot_against"],
    })
    return variables
```

**Qué hace, bloque por bloque:**

1. **Entradas.** `df_pre` es el histórico anterior al partido; `fecha`, `home` y `away` identifican el partido;
   `elo_home` y `elo_away` llegan **ya calculados** (los calcula quien llama: `construir_base_historica` o
   `predecir_partido`). `k_shrinkage` y `incluir_forma` permiten que la calibración use otro k y omita la forma.
2. **Guardia contra la fuga de información.** `(df_pre["date"] < fecha).all()` revisa que **todas** las filas
   sean de antes del partido. Si una sola es del mismo día o posterior, la función se detiene con error. Es la
   regla central del notebook escrita como código.
3. **Goles de la temporada** de los dos equipos con `season_stats` (k = 0: el promedio de la temporada en curso
   si ya jugó; si no, la referencia previa).
4. **Diccionario con las 7 variables base:** los dos Elo, su diferencia y los cuatro promedios de goles.
5. **Salida temprana:** con `incluir_forma=False` devuelve sólo esas 7. Lo usa la calibración (M0 no necesita
   forma) y por eso esa base tarda ≈ 38 s en lugar de ≈ 60 s.
6. **Forma reciente** de los dos equipos con `recent_form` (últimos 10 partidos, decaimiento 0.85): 6 cifras por
   equipo (goles, tiros y tiros a puerta, a favor y en contra), 12 en total. `update` las agrega al
   diccionario, que queda con **19 variables**.

> Detalle de Python: los valores por defecto (`k_shrinkage=K_SHRINKAGE`) se fijan **cuando se define** la
> función (celda 4, con k = 0), no cuando se llama. Si después cambia `K_SHRINKAGE`, el valor por defecto no
> cambia. No afecta al proyecto porque la calibración y la base definitiva pasan k explícitamente. En R, los
> valores por defecto se evalúan al llamar la función.

**Ejemplo real: el primer partido de la base** (Liverpool 4–1 Norwich, 9-ago-2019):

| Variable | Valor | De dónde sale |
|---|---|---|
| `elo_home`, `elo_away` | 1780.868317 · 1437.657673 | Elo de antes del partido, acumulado desde 2001 (el Elo no se reinicia entre temporadas) |
| `elo_diff` | 343.210644 | La resta |
| `gf_home`, `ga_home` | 2.342105 · 0.578947 | Primer partido de la temporada (n = 0): promedio de Liverpool en 2018/19, 89 y 22 goles en 38 partidos |
| `gf_away`, `ga_away` | 1.410526 · 1.410526 | Norwich no jugó 2018/19 en Premier: promedio de goles por equipo y partido de la liga en 2018/19 (1,072 goles ÷ 760) |
| `form_gf_home`, `form_ga_home` | 2.661718 · 0.632481 | Últimos 10 partidos de Liverpool, ponderados con 0.85 |
| `form_gf_away`, `form_ga_away` | 0.906214 · 1.686959 | Últimos 10 de Norwich (de su última temporada en Premier) |
| `shots_for_home`, `shots_against_home` | 15.376515 · 8.153578 | Tiros de Liverpool en esos 10 partidos |
| `sot_for_home` … `sot_against_away` | 5.253294 … 4.643800 | Tiros a puerta, igual |
| `home_goals`, `away_goals` | 4 · 1 | El resultado: es el **objetivo**, no un predictor |

**En R (verificado):** con las funciones de abajo, R reconstruye la base completa de 2,700 × 24 y coincide con
la de Python (diferencia máxima 2.3 × 10⁻¹³).

```r
juega <- function(d, equipo) d$HomeTeam == equipo | d$AwayTeam == equipo
gf_ga <- function(d, equipo) {                       # goles desde el punto de vista del equipo
  local <- d$HomeTeam == equipo
  list(gf = mean(ifelse(local, d$FTHG, d$FTAG)), ga = mean(ifelse(local, d$FTAG, d$FTHG)))
}
season_stats <- function(previo, equipo, fecha, k = 0) {           # wc_predictor.season_stats
  anio <- as.integer(format(fecha, "%Y")) - (as.integer(format(fecha, "%m")) < 8)
  inicio <- as.Date(sprintf("%d-08-01", anio)); inicio_ant <- as.Date(sprintf("%d-08-01", anio - 1))
  actual <- previo[previo$Date >= inicio & juega(previo, equipo), ]
  liga_ant <- previo[previo$Date >= inicio_ant & previo$Date < inicio, ]
  anterior <- liga_ant[juega(liga_ant, equipo), ]
  if (nrow(anterior) > 0) pr <- gf_ga(anterior, equipo) else {     # no jugó: promedio de la liga
    ref <- if (nrow(liga_ant) > 0) liga_ant else previo[previo$Date < inicio, ]
    m <- (sum(ref$FTHG) + sum(ref$FTAG)) / (2 * nrow(ref)); pr <- list(gf = m, ga = m)
  }
  n <- nrow(actual)
  if (n == 0) return(c(gf_avg = pr$gf, ga_avg = pr$ga))
  ac <- gf_ga(actual, equipo); w <- n / (n + k)
  c(gf_avg = w * ac$gf + (1 - w) * pr$gf, ga_avg = w * ac$ga + (1 - w) * pr$ga)
}
recent_form <- function(previo, equipo, n = 10, decay = 0.85) {    # wc_predictor.recent_form
  u <- tail(previo[juega(previo, equipo), ], n); m <- nrow(u)
  if (m == 0) return(c(gf = media_goles_equipo, ga = media_goles_equipo,  # sin historial: tiros = NA
                       shots_for = NA, shots_against = NA, sot_for = NA, sot_against = NA))
  w <- decay^((m - 1):0); w <- w / sum(w); l <- u$HomeTeam == equipo
  c(gf = sum(w * ifelse(l, u$FTHG, u$FTAG)), ga = sum(w * ifelse(l, u$FTAG, u$FTHG)),
    shots_for = sum(w * ifelse(l, u$HS, u$AS)), shots_against = sum(w * ifelse(l, u$AS, u$HS)),
    sot_for = sum(w * ifelse(l, u$HST, u$AST)), sot_against = sum(w * ifelse(l, u$AST, u$HST)))
}
crear_variables_partido <- function(previo, fecha, local, visita, elo_local, elo_visita,
                                    k_shrinkage = 0, incluir_forma = TRUE) {
  if (!all(previo$Date < fecha)) stop("previo contiene información de la fecha objetivo o posterior")
  sh <- season_stats(previo, local, fecha, k_shrinkage); sa <- season_stats(previo, visita, fecha, k_shrinkage)
  v <- list(elo_home = elo_local, elo_away = elo_visita, elo_diff = elo_local - elo_visita,
            gf_home = sh[["gf_avg"]], ga_home = sh[["ga_avg"]], gf_away = sa[["gf_avg"]], ga_away = sa[["ga_avg"]])
  if (!incluir_forma) return(v)
  fh <- recent_form(previo, local); fa <- recent_form(previo, visita)
  c(v, list(form_gf_home = fh[["gf"]], form_ga_home = fh[["ga"]], form_gf_away = fa[["gf"]], form_ga_away = fa[["ga"]],
            shots_for_home = fh[["shots_for"]], shots_against_home = fh[["shots_against"]],
            shots_for_away = fa[["shots_for"]], shots_against_away = fa[["shots_against"]],
            sot_for_home = fh[["sot_for"]], sot_against_home = fh[["sot_against"]],
            sot_for_away = fa[["sot_for"]], sot_against_away = fa[["sot_against"]]))
}
```

En R se usan los nombres originales de Football-Data (`FTHG`, `HS`…), sin renombrar. `media_goles_equipo` es
`(mean(FTHG) + mean(FTAG)) / 2` sobre todo el histórico, el mismo respaldo que `avg_team_goals` en Python. El
diccionario de Python se vuelve una `list` con nombres, y `variables.update({...})` se vuelve `c(v, list(...))`.
La versión comentada línea por línea de `season_stats` y `recent_form` está en
[`05_variables_previas.R`](equivalencias_R/05_variables_previas.R).

> **Decisión:** una sola función calcula las variables, tanto para construir la base de entrenamiento como para
> pronosticar un partido nuevo (§10).
> **Alternativas:** (a) calcular la base de entrenamiento vectorizada (sumas acumuladas por equipo, como
> `06_calibracion.R`) y escribir aparte el cálculo para pronosticar — mucho más rápido, pero son dos
> implementaciones que pueden divergir sin que nadie lo note; (b) calcular las variables en el tablero por su
> cuenta — mismo riesgo.
> **Por qué ésta:** garantiza por construcción que el modelo recibe al predecir exactamente las mismas variables
> con que se entrenó. El costo (≈ 1 minuto por base) es aceptable.
> **Evidencia en el proyecto:** reconstruir la base con esta función reproduce la caché
> `premier_training_data.csv` (diferencia máxima 4.5 × 10⁻¹³) y `predecir_partido`, que usa la misma función, da
> lo mismo que el simulador del tablero (λ 1.538 y 1.266 para Arsenal–Man City).
> **Si preguntan:** "La misma función arma las variables para entrenar y para predecir; así es imposible que el
> modelo reciba variables calculadas de otra manera."

### 11.2.2 `construir_base_historica`

```python
def construir_base_historica(historial, desde=FECHA_INICIO, k_elo=K_ELO,
                              k_shrinkage=K_SHRINKAGE, escala_elo=ESCALA_ELO,
                              incluir_forma=True):
    historial = historial.sort_values("date", kind="stable").reset_index(drop=True)
    ratings = {}                                            # equipo -> Elo actual
    registros = []                                          # una fila (diccionario) por partido

    for fecha, partidos_dia in historial.groupby("date", sort=True):
        df_pre = historial.loc[historial["date"] < fecha]   # sólo días ANTERIORES
        elo_previo = ratings.copy()                         # Elo antes de este día

        if fecha >= desde:                                  # se guardan partidos desde 2019-08-01
            for partido in partidos_dia.itertuples(index=False):
                home, away = partido.home_team, partido.away_team
                variables = crear_variables_partido(
                    df_pre, fecha, home, away,
                    elo_previo.get(home, wc_predictor.ELO_INIT),
                    elo_previo.get(away, wc_predictor.ELO_INIT),
                    k_shrinkage=k_shrinkage, incluir_forma=incluir_forma)
                registros.append({"Date": fecha, "HomeTeam": home, "AwayTeam": away,
                                  **variables,
                                  "home_goals": partido.home_score,
                                  "away_goals": partido.away_score})

        for partido in partidos_dia.itertuples(index=False):   # DESPUÉS: actualizar el Elo
            home, away = partido.home_team, partido.away_team
            rh = ratings.get(home, wc_predictor.ELO_INIT)
            ra = ratings.get(away, wc_predictor.ELO_INIT)
            sh = 1.0 if partido.home_score > partido.away_score else (
                0.0 if partido.home_score < partido.away_score else 0.5)
            ratings[home] = wc_predictor.update_elo(rh, ra, sh, k=k_elo, scale=escala_elo)
            ratings[away] = wc_predictor.update_elo(ra, rh, 1.0 - sh, k=k_elo, scale=escala_elo)

    return pd.DataFrame(registros)
```

**Qué hace, bloque por bloque:**

1. **Parámetros.** `desde` (2019-08-01), `k_elo`, `k_shrinkage`, `escala_elo` e `incluir_forma`. La calibración
   llama a esta función con cada (K, k) de la rejilla; la base definitiva, con los elegidos.
2. **Orden estable.** `kind="stable"` respeta, entre partidos del mismo día, el orden que ya traían. Como se
   verá, ese orden no influye en ningún resultado.
3. **Dos acumuladores.** `ratings` es un diccionario equipo → Elo actual (en R, un vector con nombres);
   `registros`, una lista donde cada partido se agrega como diccionario.
4. **Recorrido por fechas.** `groupby("date", sort=True)` entrega, en orden, cada fecha con todos sus partidos
   (`partidos_dia`). Son **2,662 fechas** en total; **847** desde 2019-08-01 (2,700 partidos), de las cuales 574
   tienen más de un partido. El día más cargado tiene 10.
5. **El corte del día.** `df_pre` toma sólo lo jugado **antes** de esa fecha: los partidos del mismo día quedan
   fuera. Así ningún partido "se entera" de otro del mismo día.
6. **Foto del Elo.** `elo_previo = ratings.copy()` guarda los ratings de antes del día. Como las variables del día
   se construyen antes de actualizar, la copia es una protección extra: aunque alguien moviera la actualización,
   las variables seguirían usando el Elo de antes.
7. **Sólo se guardan partidos desde 2019.** Antes de `desde` el ciclo sólo actualiza el Elo. Así, en agosto de
   2019 cada rating ya acumula 18 temporadas de historial (2001/02 a 2018/19).
8. **Un registro por partido.** Las claves, las variables (`**variables` "desempaca" el diccionario dentro del
   nuevo; en R, `c(lista1, lista2)`) y los goles reales. Un equipo sin rating recibe 1500 (`ELO_INIT`).
9. **Actualización del Elo al final del día.** Con los ratings de antes del partido (`rh`, `ra`), el resultado
   del local (`sh`: 1, 0.5 o 0) y el complementario para el visitante (`1 - sh`). `update_elo` aplica
   R' = R + K·(S − E).
10. **Salida:** un `DataFrame` de **2,700 × 24** (3 claves + 19 variables + 2 objetivos), o de 2,700 × 12 sin forma.

**Un hallazgo que conviene saber.** Recalculamos la base **partido por partido** (cada partido ve todos los
anteriores y el Elo se actualiza tras cada uno) y sale **idéntica** (diferencia 0). La razón: ningún equipo juega
dos veces el mismo día (0 casos en 9,540 partidos) y todas las variables de un equipo dependen sólo de sus propios
partidos (y del promedio de la liga de la temporada anterior). El agrupamiento por día es, entonces, una
**garantía de diseño**: no cambia las cifras de este proyecto, pero las protegería si se agregara una variable
de toda la liga en la temporada en curso o si hubiera un partido duplicado. Además, encaja con la guardia
`date < fecha` de `crear_variables_partido`, que rechazaría cualquier partido del mismo día.

> **Decisión:** recorrer el histórico por fecha: las variables de un día usan el corte "antes de ese día" y el
> Elo se actualiza al terminar el día.
> **Alternativas:** (a) partido por partido — con hora de inicio sería un corte más fino, pero la base
> consolidada no conserva la hora, así que el orden dentro del día es arbitrario; (b) vectorizado con sumas
> acumuladas por equipo y temporada, como `06_calibracion.R` — calcula las 35 combinaciones en 7 s en lugar de
> ≈ 22 minutos, pero es una implementación distinta de la que se usa para predecir; (c) por jornada o semana —
> perdería partidos ya jugados.
> **Por qué ésta:** sin hora de inicio, "antes del día" es el corte más fino que no depende de un orden
> arbitrario, y es el mismo que exige la guardia.
> **Evidencia en el proyecto:** partido por partido sale la misma base (diferencia 0), y la base reproduce la
> caché a 4.5 × 10⁻¹³.
> **Si preguntan:** "Los partidos del mismo día no se informan entre sí: todos usan sólo lo ocurrido hasta el día
> anterior, y el Elo se actualiza al final del día."

> **Decisión:** calcular el Elo desde 2001 aunque la base de modelación empiece en 2019.
> **Alternativas:** (a) arrancar el Elo en 2019 con todos en 1500 — las primeras temporadas tendrían ratings sin
> información (Liverpool y Norwich empezarían iguales); (b) arrancar con un rating previo externo — no hay una
> fuente uniforme en los datos.
> **Por qué ésta:** 18 temporadas de "calentamiento" hacen que en 2019 el Elo ya distinga a los equipos (343 puntos
> entre Liverpool y Norwich en el primer partido), sin usar ninguna información posterior al partido.
> **Si preguntan:** "El Elo se calienta con 18 temporadas; desde 2019 sólo guardamos los partidos que modelamos."

**En R (verificado):** traducción literal; reconstruye la misma base (2,700 × 24, diferencia máxima con Python
2.3 × 10⁻¹³; tarda ≈ 21 s, y ≈ 15 s sin forma).

```r
construir_base_historica <- function(historico, desde = as.Date("2019-08-01"), k_elo = 15,
                                     k_shrinkage = 0, incluir_forma = TRUE) {
  historico <- arrange(historico, Date)
  ratings <- c()                                   # vector con nombres: ratings["Arsenal"]
  registros <- list()
  for (dia in split(historico, historico$Date)) {  # un bloque por fecha, en orden (≈ groupby)
    fecha <- dia$Date[1]
    previo <- historico[historico$Date < fecha, ] # sólo días anteriores
    elo_previo <- ratings
    if (fecha >= desde) {
      for (i in seq_len(nrow(dia))) {
        h <- dia$HomeTeam[i]; a <- dia$AwayTeam[i]
        v <- crear_variables_partido(previo, fecha, h, a,
                                     if (h %in% names(elo_previo)) elo_previo[[h]] else 1500,
                                     if (a %in% names(elo_previo)) elo_previo[[a]] else 1500,
                                     k_shrinkage, incluir_forma)
        registros[[length(registros) + 1]] <- c(list(Date = fecha, HomeTeam = h, AwayTeam = a), v,
                                                list(home_goals = dia$FTHG[i], away_goals = dia$FTAG[i]))
      }
    }
    for (i in seq_len(nrow(dia))) {                # después: Elo con los resultados del día
      h <- dia$HomeTeam[i]; a <- dia$AwayTeam[i]
      rh <- if (h %in% names(ratings)) ratings[[h]] else 1500
      ra <- if (a %in% names(ratings)) ratings[[a]] else 1500
      s <- if (dia$FTHG[i] > dia$FTAG[i]) 1 else if (dia$FTHG[i] < dia$FTAG[i]) 0 else 0.5
      e <- 1 / (1 + 10^((ra - rh) / 400))          # expected_score del local
      ratings[h] <- rh + k_elo * (s - e)
      ratings[a] <- ra + k_elo * ((1 - s) - (1 - e))
    }
  }
  bind_rows(registros)                             # ≈ pd.DataFrame(registros)
}
```

`split()` parte la tabla por fecha (como `groupby`), `bind_rows()` junta la lista de registros en una tabla y
`ratings[[h]]` lee el rating de un equipo. El orden de las filas dentro de un día puede diferir del de Python
(en Python lo fija el ordenamiento de `load_history`); por eso la comparación se hace alineando por fecha y
equipos. La versión rápida y vectorizada de las variables de M0 (Elo previo con índices enteros y promedios
con `cumsum` por equipo y temporada) está en [`06_calibracion.R`](equivalencias_R/06_calibracion.R).

### 11.2.3 Qué pasa con un equipo que nunca había jugado

Si un equipo no aparece en ningún partido anterior desde 2001, `recent_form` no tiene de dónde promediar
tiros: devuelve `NaN` en los 6 de tiros y, para los goles de forma, el respaldo `avg_team_goals` (1.362264,
goles por equipo y partido de **todo** el histórico). Ocurre en 4 partidos. Ese respaldo usa partidos
posteriores, pero no importa: esas 4 filas se eliminan antes de modelar ([11.6](#116-nota-los-4-partidos-sin-historial-celdas-1214)).

### 11.2.4 Las dos bases que produce

| Llamada | Dónde | Columnas | Filas | Tiempo |
|---|---|---|---|---|
| `construir_base_historica(…, incluir_forma=False)` | Calibración (celda 11), una vez por combinación | 12: claves, 7 variables de M0, 2 objetivos | 2,700 (incluye los 4 sin historial) | ≈ 38 s |
| `construir_base_historica(…, incluir_forma=True)` | Base definitiva (celda 11) | 24 | 2,700 → 2,696 tras quitar los 4 | ≈ 60 s |

### 11.2.5 Celda 5: la exportación comentada

```python
#NOTA: con este código se exportó la base de entrenamiento a csv para no recrearla cada vez que se corra el notebook en github
# training_data.to_csv(
#     "premier_training_data.csv",
#     index=False
# )
```

Está comentada y es un **duplicado** de la celda 14. En esta posición no funcionaría: `training_data` todavía no
existe (se crea en la celda 11), así que al descomentarla aquí y ejecutar de arriba abajo daría `NameError`. La
que sirve es la 14 ([11.6.3](#1163-celda-14-la-exportación-de-la-caché)).

---

## 11.3 · §3 Carga y control inicial del histórico (celdas 6–7)

**Celda 6 (texto)**: la sección carga `E0_consolidado.csv`, convierte fechas, ordena y verifica que haya datos;
no estima nada. Supuestos: fechas, equipos y goles bien registrados; el orden cronológico es esencial; el
archivo es la fuente de verdad de los resultados.

**Celda 7 (código):**

```python
historial = wc_predictor.load_history()
historial["date"] = pd.to_datetime(historial["date"])
historial = historial.sort_values("date", kind="stable").reset_index(drop=True)
if historial.empty:
    raise ValueError("El histórico está vacío")
print(f"Histórico: {len(historial)} partidos, "
      f"{historial['date'].min().date()} a {historial['date'].max().date()}")
```

**Salida guardada:** `Histórico: 9540 partidos, 2001-08-18 a 2026-09-14`

- `load_history()` ([capítulo 10](10_codigo_wc_predictor.md)) lee el CSV, **renombra** cinco columnas
  (`Date → date`, `HomeTeam → home_team`, `AwayTeam → away_team`, `FTHG → home_score`, `FTAG → away_score`),
  convierte la fecha (`dayfirst=True, format="mixed"`), quita filas sin fecha, equipos o marcador y ordena. Las
  otras 29 columnas se conservan (`recent_form` usa `HS`, `AS`, `HST`, `AST`).
- La segunda conversión de fecha es **redundante** (ya viene como fecha) e inofensiva: protege por si alguien
  cambiara `load_history`.
- El orden estable conserva el orden que dejó `load_history`, que ordena con el método por defecto de pandas
  (no estable). Por eso el orden **dentro** de un día no es el del CSV. No afecta nada: las variables se
  construyen por día.
- `if historial.empty` detiene el notebook si el archivo viniera vacío.
- Ojo con las **dos convenciones de nombres**: el histórico usa minúsculas (`date`, `home_team`) y la base de
  modelación y las cuotas usan los nombres de Football-Data (`Date`, `HomeTeam`), que son las `CLAVES` para
  unir con el mercado.

**En R (verificado):**

```r
historico <- read_csv("E0_consolidado.csv", show_col_types = FALSE) |>
  filter(!is.na(Date), !is.na(HomeTeam), !is.na(AwayTeam), !is.na(FTHG), !is.na(FTAG)) |>  # ≈ dropna
  arrange(Date)                                                 # arrange es estable
stopifnot(nrow(historico) > 0)                                  # ≈ if historial.empty: raise
cat(sprintf("Histórico: %d partidos, %s a %s\n", nrow(historico), min(historico$Date), max(historico$Date)))
# Histórico: 9540 partidos, 2001-08-18 a 2026-09-14
media_goles_equipo <- (mean(historico$FTHG) + mean(historico$FTAG)) / 2   # wc_predictor.avg_team_goals: 1.362264
```

`read_csv` reconoce la fecha en formato año-mes-día sin opciones extra, y en R no hace falta renombrar. La
última línea calcula el respaldo que en Python se calcula al importar `wc_predictor`.

---

## 11.4 · §4 Funciones estadísticas compartidas (celdas 8–9)

**Celda 8 (texto)** plantea el modelo ([capítulos 6](06_poisson_y_regresion.md) y
[7](07_de_goles_a_probabilidades.md)): dos GLM independientes,

$$
G_H\mid X_H\sim\text{Poisson}(\lambda_H),\ \log\lambda_H=X_H\beta_H;\qquad
G_A\mid X_A\sim\text{Poisson}(\lambda_A),\ \log\lambda_A=X_A\beta_A,
$$

con $\lambda=\exp(X\beta)>0$; en M0, $\log\lambda_H=\beta_{0H}+\beta_{1H}D+\beta_{2H}GF_H+\beta_{3H}GA_A$. De ahí,
$Z=G_H-G_A\sim\text{Skellam}(\lambda_H,\lambda_A)$ y $P(1)=P(Z>0)$, $P(X)=P(Z=0)$, $P(2)=P(Z<0)$. Las métricas son
$LL=-\frac{1}{N}\sum\log p_{i,y_i}$ y $MAE=\frac{1}{N}\sum|y_i-\hat\lambda_i|$. Y declara cinco supuestos:

| Supuesto estadístico (celda 8) | ¿Se revisó? |
|---|---|
| Conteos con media = varianza (equidispersión) | Sí, en el tablero: dispersión de Pearson de M0 0.996 (local) y 1.036 (visitante), ≈ 1 |
| Relación lineal en $\log\lambda$, sin interacciones | No se probó |
| Independencia de los goles de local y visitante (para Skellam) | No se probó; es la extensión de Dixon y Coles (1997), [capítulo 15](15_limitaciones_y_extensiones.md) |
| Observaciones independientes (no se modela la dependencia entre partidos de un club) | No se modela |
| Coeficientes estables en el periodo de entrenamiento | No se probó; se usan sin cambio en validación y prueba |

**Celda 9 (código)** define las seis funciones.

### 11.4.1 `preparar_X`

```python
def preparar_X(datos, columnas, modelo=None):
    X = datos.loc[:, columnas].copy().astype(float)
    X["elo_diff"] = X["elo_diff"] / ESCALA_ELO
    X = sm.add_constant(X, has_constant="add")
    if modelo is not None:
        X = X.loc[:, modelo.model.exog_names]
    return X
```

1. Toma sólo las columnas de la especificación, en una **copia** (para no modificar la base) y como números
   decimales.
2. Divide `elo_diff` entre 400. Las cinco especificaciones incluyen `elo_diff`; si alguna no la tuviera, esta
   línea fallaría.
3. Agrega la columna `const` (puros 1) para el intercepto. **`has_constant="add"` es indispensable:** al
   pronosticar **un solo partido** (§10), con una fila todas las columnas son "constantes" y, con la opción por
   defecto, `statsmodels` creería que ya hay intercepto y no lo agregaría.
4. Al predecir (`modelo` no es `None`), reordena las columnas exactamente como se entrenó el modelo
   (`exog_names`: `const` primero).

**Ejemplo real** (primer partido de validación, Man United 1–0 Fulham, 16-ago-2024; diferencia de Elo
124.826347):

| `const` | `elo_diff` | `gf_home` | `ga_away` |
|---|---|---|---|
| 1.0 | 0.312066 | 1.5 | 1.605263 |

`gf_home` = 1.5 es el promedio de Man United en 2023/24 (primer partido de 2024/25, n = 0) y `ga_away` = 1.605263
el de goles recibidos de Fulham en 2023/24.

> **Decisión:** la diferencia de Elo entra dividida entre 400.
> **Alternativas:** (a) en puntos, sin dividir — mismas predicciones, pero el coeficiente sería 400 veces más chico
> (≈ 0.0016 por punto) y difícil de leer; (b) estandarizada (restar la media y dividir entre la desviación
> estándar) — sirve para comparar variables, pero el coeficiente depende de la muestra (el tablero hace esa
> comparación aparte, con exp(β·DE) − 1); (c) usar la probabilidad esperada del Elo en lugar de la diferencia —
> no lineal; no se probó.
> **Por qué ésta:** 400 es la escala propia del Elo (400 puntos de diferencia equivalen a momios esperados de 10
> a 1) y el coeficiente se lee directo; reescalar no cambia el ajuste ni las predicciones.
> **Evidencia en el proyecto:** el reporte lo lee así: 400 puntos multiplican los goles esperados del local por
> e^0.6283 ≈ 1.87 (y los del visitante por e^−0.6854 ≈ 0.50).
> **Si preguntan:** "Dividir entre 400 sólo cambia la unidad del coeficiente: por cada 400 puntos de Elo a favor,
> el local espera 1.87 veces más goles."

### 11.4.2 `entrenar_modelo`

```python
def entrenar_modelo(datos, columnas_home, columnas_away):
    home = sm.GLM(datos["home_goals"], preparar_X(datos, columnas_home),
                  family=sm.families.Poisson()).fit()
    away = sm.GLM(datos["away_goals"], preparar_X(datos, columnas_away),
                  family=sm.families.Poisson()).fit()
    return {"home": home, "away": away,
            "columnas_home": columnas_home, "columnas_away": columnas_away}
```

- `sm.GLM(y, X, family=sm.families.Poisson())` define un modelo lineal generalizado de Poisson; su enlace por
  defecto es el logaritmo. `.fit()` lo estima por **máxima verosimilitud** con IRLS (mínimos cuadrados
  reponderados iterativos); M0 converge en 5 iteraciones.
- Son **dos modelos separados**: uno para los goles del local y otro para los del visitante, cada uno con sus
  columnas. A diferencia de `glm()` de R, `statsmodels` no usa fórmulas aquí: recibe la matriz X ya armada (con
  la constante que agregó `preparar_X`).
- Devuelve un diccionario con los dos modelos ajustados y sus listas de columnas, que se necesitan para
  predecir y para contar variables.

> **Decisión:** dos regresiones de Poisson independientes (una por equipo) con enlace logarítmico.
> **Alternativas:** (a) Poisson bivariada (Karlis y Ntzoufras, 2003) — modela la correlación entre los goles de
> ambos; (b) Dixon y Coles (1997) — corrige la frecuencia de 0–0, 1–0, 0–1 y 1–1 y pondera partidos recientes;
> (c) binomial negativa — para sobredispersión; (d) fuerzas de ataque y defensa por equipo (Maher, 1982) — un
> parámetro por club en lugar de variables previas; (e) logit multinomial u ordinal sobre el 1X2 — predice el
> resultado directo, pero sin goles esperados, sin MAE y sin marcadores. Ninguna se probó.
> **Por qué ésta:** los goles son conteos; es el modelo de referencia de la literatura (desde Maher, 1982), es
> interpretable, da goles esperados, marcadores y 1X2 a la vez, y es el GLM que se ve en el diplomado.
> **Evidencia en el proyecto:** la dispersión de Pearson de M0 es 0.996 y 1.036 (≈ 1): no hay sobredispersión
> que justifique la binomial negativa.
> **Si preguntan:** "Usamos Poisson porque los goles son conteos, y la dispersión salió cercana a 1; modelar la
> dependencia entre los goles de los dos equipos, como Dixon y Coles, queda como extensión."

### 11.4.3 `probabilidades_1x2`

```python
def probabilidades_1x2(lambda_home, lambda_away):
    lh, la = np.asarray(lambda_home), np.asarray(lambda_away)
    probs = np.column_stack((
        skellam.sf(0, lh, la),     # P(Z > 0): gana el local
        skellam.pmf(0, lh, la),    # P(Z = 0): empate
        skellam.cdf(-1, lh, la),   # P(Z <= -1): gana el visitante
    ))
    if not np.isfinite(probs).all() or not np.allclose(probs.sum(axis=1), 1.0, atol=1e-8):
        raise ValueError("Las probabilidades 1X2 no son válidas")
    return probs
```

- Si los goles de local y visitante son Poisson independientes, su diferencia Z sigue una **Skellam**. `sf(0)` es
  la función de supervivencia, P(Z > 0) = 1 − P(Z ≤ 0); `pmf(0)` es P(Z = 0); `cdf(-1)` es P(Z ≤ −1).
- `np.column_stack` arma una matriz de n × 3 (una fila por partido). Funciona igual con un partido o con 419.
- El control final exige que todo sea finito y que cada fila sume 1 (tolerancia 10⁻⁸); si no, se detiene.

**Ejemplo real:** con los goles promedio del entrenamiento (λ = 1.561413 y 1.311545, la referencia simple de §7)
da **43.24 % / 24.69 % / 32.07 %**.

> **Decisión:** pasar de λ a 1X2 con la fórmula cerrada de Skellam.
> **Alternativas:** (a) sumar la matriz de marcadores (la misma cuenta, truncada en algún número de goles);
> (b) simular miles de partidos — introduce ruido de simulación. Bajo independencia, las tres dan lo mismo.
> **Por qué ésta:** es exacta (no trunca) y vectorizada. La matriz se usa sólo donde hace falta, para el marcador
> exacto (§10).
> **Evidencia en el proyecto:** en el ejemplo de §10, la matriz de 0 a 10 goles da P(local) = 0.436461 y Skellam
> 0.436462; la diferencia es la masa que queda fuera de la matriz (8 × 10⁻⁷).
> **Si preguntan:** "Skellam es la distribución de la resta de dos Poisson independientes: P(local) es la
> probabilidad de que la resta sea positiva."

### 11.4.4 `resultados_observados`

```python
def resultados_observados(datos):
    gh = datos["home_goals"].to_numpy()
    ga = datos["away_goals"].to_numpy()
    return np.where(gh > ga, 0, np.where(gh == ga, 1, 2))      # 0 = local, 1 = empate, 2 = visita
```

Un `np.where` anidado (en R, `ifelse` anidado). El código coincide con la columna de `PROBS` que corresponde
(columna 0 = local). Ejemplo: Man United 1–0 Fulham, Ipswich 0–2 Liverpool y Arsenal 2–0 Wolves dan
`[0, 2, 0]`. En R se codifica 1, 2, 3 porque R indexa desde 1 y el código se usa como número de columna.

### 11.4.5 `predecir_con_modelo`

```python
def predecir_con_modelo(modelo, datos):
    lh = np.asarray(modelo["home"].predict(preparar_X(datos, modelo["columnas_home"], modelo["home"])), dtype=float)
    la = np.asarray(modelo["away"].predict(preparar_X(datos, modelo["columnas_away"], modelo["away"])), dtype=float)
    if not np.isfinite(lh).all() or not np.isfinite(la).all():
        raise ValueError("Se obtuvieron goles esperados no finitos")
    probs = probabilidades_1x2(lh, la)
    resultado = datos[CLAVES + OBJETIVOS].reset_index(drop=True).copy() if all(
        c in datos for c in OBJETIVOS
    ) else datos[CLAVES].reset_index(drop=True).copy()
    resultado["lambda_home"] = lh
    resultado["lambda_away"] = la
    resultado[PROBS] = probs
    return resultado
```

1. `predict` devuelve λ (ya en escala de goles: aplica exp al predictor lineal) con las columnas en el orden del
   entrenamiento.
2. Revisa que todas las λ sean finitas.
3. Calcula las probabilidades 1X2.
4. Arma la tabla de salida: claves y goles reales **si existen** (`c in datos` revisa si la columna está). Para un
   partido futuro no hay goles, y la tabla lleva sólo las claves.
5. Agrega λ y las tres probabilidades.

**Ejemplo real** (M0, primeros tres partidos de validación):

| Partido | Resultado | λ local | λ visita | P(local) | P(empate) | P(visita) |
|---|---|---|---|---|---|---|
| Man United – Fulham | 1–0 | 1.851272 | 1.011545 | 0.570397 | 0.225849 | 0.203754 |
| Ipswich – Liverpool | 0–2 | 0.927487 | 2.310806 | 0.135635 | 0.180660 | 0.683705 |
| Arsenal – Wolves | 2–0 | 2.606555 | 0.798737 | 0.760913 | 0.147785 | 0.091301 |

### 11.4.6 `evaluar_predicciones`

```python
def evaluar_predicciones(pred):
    mae_h = mean_absolute_error(pred["home_goals"], pred["lambda_home"])
    mae_a = mean_absolute_error(pred["away_goals"], pred["lambda_away"])
    return {
        "Partidos": len(pred),
        "MAE_local": mae_h,
        "MAE_visitante": mae_a,
        "MAE_promedio": (mae_h + mae_a) / 2,
        "LogLoss_1X2": log_loss(resultados_observados(pred), pred[PROBS].to_numpy(), labels=[0, 1, 2]),
    }
```

- **MAE** de cada lado: promedio de |goles reales − λ|. El promedio es la media simple de los dos.
- **LogLoss** con `sklearn`: menos el promedio del logaritmo de la probabilidad que se dio al resultado que
  ocurrió. `labels=[0, 1, 2]` fija las tres clases aunque en un subconjunto faltara alguna.
- Por qué estas dos métricas y cómo se leen: [capítulo 9](09_evaluacion_y_validacion.md).

**En R (verificado; mismas cifras que el notebook en todas las tablas de §5 a §10):**

```r
terminos <- function(columnas) sub("^elo_diff$", "I(elo_diff / 400)", columnas)   # ≈ preparar_X
entrenar_modelo <- function(datos, col_local, col_visita) list(
  home = glm(reformulate(terminos(col_local),  "home_goals"), family = poisson, data = datos),
  away = glm(reformulate(terminos(col_visita), "away_goals"), family = poisson, data = datos),
  columnas_home = col_local, columnas_away = col_visita)
probabilidades_1x2 <- function(lh, la, max_goles = 15) t(mapply(function(l1, l2) {
  m <- outer(dpois(0:max_goles, l1), dpois(0:max_goles, l2))   # fila = goles local, columna = visita
  c(P_home = sum(m[lower.tri(m)]), P_draw = sum(diag(m)), P_away = sum(m[upper.tri(m)]))
}, lh, la))
resultados_observados <- function(d) ifelse(d$home_goals > d$away_goals, 1L,
                                            ifelse(d$home_goals == d$away_goals, 2L, 3L))
predecir_con_modelo <- function(modelo, datos) {
  lh <- predict(modelo$home, newdata = datos, type = "response")   # type = "response": λ, no log λ
  la <- predict(modelo$away, newdata = datos, type = "response")
  stopifnot(all(is.finite(lh)), all(is.finite(la)))
  bind_cols(select(datos, any_of(c("Date", "HomeTeam", "AwayTeam", "home_goals", "away_goals"))),
            tibble(lambda_home = lh, lambda_away = la), as_tibble(probabilidades_1x2(lh, la)))
}
logloss <- function(P, y) -mean(log(P[cbind(seq_along(y), y)]))   # P[cbind(fila, columna)]
evaluar_predicciones <- function(pred) {
  mae_h <- mean(abs(pred$home_goals - pred$lambda_home)); mae_a <- mean(abs(pred$away_goals - pred$lambda_away))
  c(Partidos = nrow(pred), MAE_local = mae_h, MAE_visitante = mae_a, MAE_promedio = (mae_h + mae_a) / 2,
    LogLoss_1X2 = logloss(as.matrix(pred[, c("P_home", "P_draw", "P_away")]), resultados_observados(pred)))
}
```

- `reformulate()` arma la fórmula a partir de los nombres (`home_goals ~ I(elo_diff / 400) + gf_home + ga_away`) e
  `I()` hace la división dentro de la fórmula: así `predict()` la repite sola con datos nuevos. Es el papel de
  `preparar_X`; la constante la agrega `glm()` sin pedirla.
- R base no trae Skellam: se suma la matriz de marcadores hasta 15 goles (lo que queda fuera es despreciable).
  El empate también sale exacto con Bessel: `exp(-(l1 + l2)) * besselI(2 * sqrt(l1 * l2), 0)`.
- `any_of()` hace lo de `if all(c in datos …)`: toma las columnas que existan.
- `P[cbind(seq_along(y), y)]` toma de cada fila la probabilidad de la columna que ocurrió; en Python,
  `P[np.arange(n), y]`.

---

## 11.5 · §5 Calibración de K y k (celdas 10–11)

**Celda 10 (texto)** explica el método: validación temporal de **ventana creciente** (*expanding window*) sobre
2021/22, 2022/23 y 2023/24, con el LogLoss 1X2 de M0 como criterio. Para cada combinación (K, k) se reconstruye
la base, se estima M0 con el pasado de cada pliegue y se mide el LogLoss en la temporada siguiente. El criterio
agregado y la regla de elección son:

$$
\overline{LL}(K,k)=\frac{\sum_f N_f\,LL_f(K,k)}{\sum_f N_f},\qquad (K^*,k^*)=\arg\min_{K,k}\overline{LL}(K,k)
$$

donde $LL_f$ es el LogLoss del pliegue $f$ y $N_f$ su número de partidos. Sus supuestos: se optimiza M0 porque
K y k afectan directo a sus variables; cada partido pesa igual dentro de un pliegue y los pliegues se ponderan
por su tamaño; la rejilla es discreta ("si el mejor valor aparece en un extremo, conviene ampliar el rango");
la prueba no se usa para escoger; y k = 0 no deja sin información el inicio de temporada (con n = 0,
`season_stats` usa la referencia previa). La teoría de la validación temporal está en el
[capítulo 9](09_evaluacion_y_validacion.md).

**Celda 11 (código)** hace cinco cosas: define y corre la calibración, elige K y k, construye la base definitiva,
la revisa y la parte en entrenamiento, validación y prueba.

### 11.5.1 `calibrar_hiperparametros`

```python
def calibrar_hiperparametros(historial):
    resultados = []
    for k_elo, k_shrinkage in itertools.product(K_ELO_CANDIDATOS, K_SHRINKAGE_CANDIDATOS):
        datos = construir_base_historica(historial, k_elo=k_elo, k_shrinkage=k_shrinkage,
                                         escala_elo=ESCALA_ELO, incluir_forma=False)
        datos["Date"] = pd.to_datetime(datos["Date"])
        logloss_folds, pesos_folds = [], []                   # (en el original, en dos líneas)
        for inicio_val, fin_val in FOLDS_HIPERPARAMETROS:
            train_fold = datos.loc[datos["Date"] < inicio_val].copy()
            val_fold = datos.loc[(datos["Date"] >= inicio_val) & (datos["Date"] < fin_val)].copy()
            if train_fold.empty or val_fold.empty:
                raise ValueError(f"Fold vacío para K_Elo={k_elo}, k_shrinkage={k_shrinkage}")
            modelo = entrenar_modelo(train_fold, *ESPECIFICACIONES["M0_Base"])
            pred = predecir_con_modelo(modelo, val_fold)
            ll = evaluar_predicciones(pred)["LogLoss_1X2"]
            logloss_folds.append(ll)
            pesos_folds.append(len(val_fold))
        resultados.append({
            "K_Elo": k_elo, "k_shrinkage": k_shrinkage,
            # NOTA (del original): cambiar estos si se cambia el número de folds o el periodo de validación.
            "LogLoss_promedio": np.average(logloss_folds, weights=pesos_folds),
            "LogLoss_2021_22": logloss_folds[0],
            "LogLoss_2022_23": logloss_folds[1],
            "LogLoss_2023_24": logloss_folds[2],
            "Partidos": int(np.sum(pesos_folds)),
        })
    return pd.DataFrame(resultados).sort_values("LogLoss_promedio").reset_index(drop=True)
```

**Qué hace, bloque por bloque:**

1. **Todas las combinaciones.** `itertools.product(A, B)` da cada par (K, k), como `expand.grid()` en R. Con
   las listas activas hay un solo par; con las completas, 35.
2. **Una base por combinación.** K cambia el Elo y k los promedios de goles, así que hay que reconstruir la base
   completa cada vez. Con `incluir_forma=False` sólo se calculan las 7 variables de M0.
3. **Los pliegues.** Para cada temporada evaluada, `train_fold` es **todo lo anterior** a su inicio (desde
   agosto de 2019, porque ahí empieza la base) y `val_fold` es esa temporada. Si alguno saliera vacío, se detiene.
4. **M0 en cada pliegue.** `*ESPECIFICACIONES["M0_Base"]` desempaca la tupla (columnas del local, columnas del
   visitante) en dos argumentos. Se ajusta, se predice la temporada siguiente y se mide el LogLoss.
5. **Promedio ponderado.** `np.average(…, weights=…)` es el $\overline{LL}$ de la fórmula. Las tres columnas por
   temporada tienen el nombre escrito a mano: si se cambiaran los pliegues habría que cambiarlas (lo advierte el
   comentario).
6. **Orden.** La tabla se ordena de menor a mayor LogLoss: la fila 0 es la mejor.

### 11.5.2 Los tres pliegues

Tamaños calculados con el código del notebook (K = 15, k = 0):

| Pliegue | Entrena con (desde 9-ago-2019) | Partidos para entrenar | Evalúa | Partidos evaluados | LogLoss de M0 |
|---|---|---|---|---|---|
| 1 | 2019/20 y 2020/21 (hasta 23-may-2021) | 760 | 2021/22 | 380 | 0.960230 |
| 2 | 2019/20 a 2021/22 (hasta 22-may-2022) | 1,140 | 2022/23 | 380 | 0.989315 |
| 3 | 2019/20 a 2022/23 (hasta 28-may-2023) | 1,520 | 2023/24 | 380 | 0.929130 |
| **Criterio** | | | | **1,140** | **0.959558** |

- Como los tres pliegues tienen 380 partidos, el promedio ponderado **coincide con el simple** (pasa en las 35
  combinaciones). La ponderación sólo importaría con temporadas de distinto tamaño.
- **Detalle fino:** la base de calibración no tiene columnas de tiros, así que no se le aplica el `dropna`: tres
  de los cuatro partidos que después se excluyen (Brentford 2021, Nott'm Forest 2022 y Luton 2023) **sí entran**
  en los pliegues. Por eso cada pliegue tiene 380 y no 379. Es una inconsistencia menor (1 de 380 partidos por
  pliegue) que no cambia la conclusión.
- Ni la validación (2024/25) ni la prueba participan: todo ocurre antes del 1-ago-2024.

### 11.5.3 Ejecución y selección

```python
tabla_hiperparametros = calibrar_hiperparametros(historial)
display(tabla_hiperparametros.head(10).round(6))

mejor = tabla_hiperparametros.iloc[0]
K_ELO = float(mejor["K_Elo"])
K_SHRINKAGE = float(mejor["k_shrinkage"])
print(f"K Elo seleccionado: {K_ELO:g}")
print(f"k shrinkage seleccionado: {K_SHRINKAGE:g}")
print(f"Log-Loss temporal promedio: {mejor['LogLoss_promedio']:.6f}")
```

**Salida guardada** (la tabla, que el notebook parte en dos renglones, va aquí en uno):

```text
   K_Elo  k_shrinkage  LogLoss_promedio  LogLoss_2021_22  LogLoss_2022_23  LogLoss_2023_24  Partidos
0     15            0          0.959558          0.96023         0.989315          0.92913      1140
K Elo seleccionado: 15
k shrinkage seleccionado: 0
Log-Loss temporal promedio: 0.959558
```

- `head(10)` mostraría las 10 mejores; con una sola combinación activa sale una fila.
- `iloc[0]` toma la mejor. `float()` convierte a número decimal y `:g` imprime 15 sin decimales.
- Desde aquí `K_ELO` y `K_SHRINKAGE` valen 15.0 y 0.0; `predecir_partido` (§10) los usa.
- **k = 0** significa: con al menos un partido jugado en la temporada, sólo cuenta la temporada en curso (sin
  mezcla); antes del primer partido se usa la referencia previa. No es "sin información".

### 11.5.4 Por qué K = 15 y k = 0

> **Decisión:** elegir K y k por validación temporal en lugar de fijarlos a mano (la versión anterior usaba
> K = 30 y k = 10 fijos).
> **Alternativas:** (a) fijarlos por convención — sin costo de cómputo, pero arbitrario; (b) estimarlos dentro del
> GLM por máxima verosimilitud — no aplica directo: K y k construyen las variables, no son coeficientes del
> modelo; (c) calibrarlos por separado para cada modelo M0–M4 — más fino, pero cinco veces más cómputo y más
> riesgo de sobreajuste (no se hizo).
> **Por qué ésta:** K y k definen las variables de las que dependen todos los modelos; elegirlos con datos, sin
> tocar validación ni prueba, es más defendible que un número fijo.
> **Evidencia en el proyecto:** la configuración anterior (K = 30, k = 10) queda en el lugar 15 de 35, con 0.962178:
> 0.002620 peor que la elegida.
> **Si preguntan:** "No los fijamos a mano: probamos 35 combinaciones en tres temporadas anteriores a la
> validación y nos quedamos con la de menor LogLoss."

> **Decisión:** calibrar sólo con M0 y con el LogLoss 1X2.
> **Alternativas:** (a) calibrar con M4 o con cada modelo; (b) usar MAE, Brier o RPS como criterio
> ([capítulo 9](09_evaluacion_y_validacion.md)).
> **Por qué ésta:** K y k afectan directamente las variables de M0 (Elo y goles de la temporada); M0 es el más
> rápido (su base, sin forma, tarda ≈ 38 s en vez de ≈ 60 s) y el más estable; el LogLoss es la métrica principal
> del proyecto.
> **Riesgo que hay que reconocer:** al ajustar K y k para M0, la comparación posterior podría favorecer un poco a
> M0. Aun así, en validación ganó M4.
> **Si preguntan:** "K y k definen las variables base, así que los calibramos con el modelo base y con la misma
> métrica con que evaluamos todo."

**Por qué el resultado tiene sentido.** Con **K más chico** el Elo reacciona menos a cada partido y resume la
fuerza de largo plazo con menos ruido de rachas. Con el Elo haciendo ese trabajo, **mezclar** la temporada
actual con la anterior (k > 0) ya no ayudó: la parte "de largo plazo" la pone el Elo y la de corto plazo, el
promedio de la temporada en curso. Dos advertencias honestas: **K = 15 está en el borde inferior** de la
rejilla (el propio notebook dice que, en ese caso, conviene ampliar el rango; K < 15 no se probó), y K = 20,
k = 0 queda prácticamente empatado. Más en el [capítulo 9](09_evaluacion_y_validacion.md).

### 11.5.5 La rejilla completa

Resultado de reactivar las listas completas (lo corrimos sobre una copia del notebook;
[`06_calibracion.R`](equivalencias_R/06_calibracion.R) obtiene las mismas 35 cifras en R). LogLoss promedio de
M0 en los tres pliegues (menor es mejor):

| K \ k | 0 | 5 | 10 | 15 | 20 |
|---|---|---|---|---|---|
| **15** | **0.959558** | 0.960369 | 0.961220 | 0.962085 | 0.962794 |
| 20 | 0.959589 | 0.960464 | 0.961203 | 0.961961 | 0.962578 |
| 25 | 0.960162 | 0.960956 | 0.961593 | 0.962279 | 0.962845 |
| 30 | 0.961021 | 0.961648 | 0.962178 | 0.962804 | 0.963336 |
| 35 | 0.962039 | 0.962428 | 0.962840 | 0.963408 | 0.963912 |
| 40 | 0.963143 | 0.963232 | 0.963514 | 0.964024 | 0.964506 |
| 45 | 0.964290 | 0.964021 | 0.964165 | 0.964620 | 0.965084 |

Cómo leerla:

- **Gana K = 15, k = 0** (0.959558). La segunda es K = 20, k = 0, sólo **0.000031** peor: prácticamente empatadas.
- Para casi todo K, el mejor k es **0**: salvo en K = 45 (donde gana k = 5), cada aumento de k empeora el
  LogLoss. Mezclar con la temporada anterior no ayudó.
- De la mejor a la peor (K = 45, k = 20) hay **0.005526**. Toda la rejilla varía menos que la ventaja de M4 sobre
  M0 en validación (0.010935): K y k afinan, pero no cambian el panorama.
- **Los pliegues no coinciden:** 2021/22 y 2023/24 prefieren K = 15, k = 0, pero 2022/23 prefiere **K = 35**,
  k = 0 (0.981453, contra 0.989315 con K = 15). El promedio de tres temporadas decide; con una sola, la elección
  dependería de qué temporada se mirara.

### 11.5.6 Base definitiva, controles y partición

```python
training_data = construir_base_historica(historial, k_elo=K_ELO, k_shrinkage=K_SHRINKAGE,
                                         escala_elo=ESCALA_ELO, incluir_forma=True)
training_data_copia = training_data.copy()                       # nueva: la usa la celda 13
n_antes = len(training_data)
training_data = training_data.dropna(subset=COLUMNAS_TIROS).reset_index(drop=True)
print(f"Base construida: {n_antes} partidos, {len(training_data)} tras limpieza")
training_data["Date"] = pd.to_datetime(training_data["Date"])
training_data = training_data.sort_values("Date", kind="stable").reset_index(drop=True)

faltantes = training_data[TODOS_LOS_PREDICTORES + OBJETIVOS].apply(pd.to_numeric, errors="coerce")
if not np.isfinite(faltantes.to_numpy(dtype=float)).all():
    raise ValueError("Existen variables no numéricas, faltantes o infinitas. Revise la base histórica.")
if training_data.duplicated(CLAVES).any():
    raise ValueError("Hay partidos duplicados según fecha y equipos.")

train = training_data.loc[training_data["Date"] < FECHA_VALIDACION].copy()
val = training_data.loc[(training_data["Date"] >= FECHA_VALIDACION)
                        & (training_data["Date"] < FECHA_PRUEBA)].copy()
test = training_data.loc[training_data["Date"] >= FECHA_PRUEBA].copy()
for nombre, datos in [("Entrenamiento", train), ("Validación", val), ("Prueba", test)]:
    if datos.empty:
        raise ValueError(f"El conjunto {nombre} está vacío")
    print(f"{nombre}: {len(datos)} partidos, {datos['Date'].min().date()} a {datos['Date'].max().date()}")
```

**Salida guardada:**

```text
Base construida: 2700 partidos, 2696 tras limpieza
Entrenamiento: 1897 partidos, 2019-08-09 a 2024-05-19
Validación: 380 partidos, 2024-08-16 a 2025-05-25
Prueba: 419 partidos, 2025-08-15 a 2026-09-14
```

1. **Base definitiva** con K = 15 y k = 0 y **todas** las variables (≈ 60 s): 2,700 × 24.
2. **Copia antes de limpiar** (`training_data_copia`): la agregó Daniel para mostrar en la celda 13 qué se quitó.
3. **`dropna(subset=COLUMNAS_TIROS)`** quita las filas con algún tiro faltante: 2,700 → 2,696. Sólo mira las 8
   columnas de tiros; las de forma de goles nunca faltan (tienen respaldo).
4. **Fecha y orden.** La conversión es redundante (ya son fechas); el orden estable deja la base en orden
   cronológico.
5. **Control 1, todo numérico y finito.** `pd.to_numeric(errors="coerce")` convierte cualquier texto en `NaN` y
   `np.isfinite` detecta `NaN` e infinitos, en los 17 predictores y los 2 objetivos.
6. **Control 2, sin duplicados** por fecha y equipos. Los dos pasan en silencio; si alguno fallara, el notebook
   se detendría en vez de seguir con datos malos.
7. **Partición** por fechas con `[inicio, fin)`; `.copy()` hace tablas independientes. El ciclo final revisa que
   ninguna esté vacía e imprime sus periodos.

Las cuentas cuadran: de los 4 partidos quitados, 3 eran de entrenamiento (1,900 → **1,897**) y 1 de prueba
(420 → **419**: 380 de 2025/26 y 39 de 2026/27). Validación conserva sus 380.

### 11.5.7 En R

**La calibración completa (verificado):** [`06_calibracion.R`](equivalencias_R/06_calibracion.R) recorre las 35
combinaciones en ≈ 7 s y comprueba las 35 cifras contra Python a 6 decimales. En lugar de recorrer el histórico día
por día, calcula las variables de M0 **vectorizadas**: primero el Elo previo a cada partido para un K dado, luego
los promedios de la temporada con sumas acumuladas por equipo y temporada, y al final aplica cada k. Fragmentos:

```r
# FRAGMENTOS de equivalencias_R/06_calibracion.R (para correrlo, usar el script completo)
# Elo previo a cada partido (equipos numerados para que el bucle sea rápido)
elo_previo <- function(K, inicial = 1500, escala = 400) {
  rating <- rep(inicial, length(equipos))
  pre_l <- pre_v <- numeric(nrow(historico))
  for (i in seq_len(nrow(historico))) {
    rl <- rating[idx_local[i]]; rv <- rating[idx_visita[i]]
    pre_l[i] <- rl; pre_v[i] <- rv                       # se guarda ANTES de actualizar
    e <- 1 / (1 + 10^((rv - rl) / escala))
    rating[idx_local[i]]  <- rl + K * (s_local[i] - e)
    rating[idx_visita[i]] <- rv + K * ((1 - s_local[i]) - (1 - e))
  }
  tibble(id = historico$id, elo_home = pre_l, elo_away = pre_v)
}
# Goles de la temporada ANTES de cada partido: tabla larga (una fila por equipo y partido);
# n = partidos ya jugados en esa temporada y promedios con sumas acumuladas
largo <- bind_rows(
  historico |> transmute(id, Date, temporada, lado = "home", equipo = HomeTeam, gf = FTHG, ga = FTAG),
  historico |> transmute(id, Date, temporada, lado = "away", equipo = AwayTeam, gf = FTAG, ga = FTHG)) |>
  arrange(equipo, Date) |>
  group_by(equipo, temporada) |>
  mutate(n = row_number() - 1,
         gf_actual = (cumsum(gf) - gf) / n,     # NaN cuando n = 0; ese caso usa la referencia previa
         ga_actual = (cumsum(ga) - ga) / n) |>
  ungroup()
# … (referencia previa del equipo o de la liga; variables_m0(elo, k) aplica el peso n / (n + k)) …
# La rejilla: para cada K, el Elo; para cada k, las variables y los tres pliegues
for (K in K_CANDIDATOS) {
  elo <- elo_previo(K)
  for (k in k_CANDIDATOS) {
    datos <- variables_m0(elo, k)
    r <- sapply(FOLDS, function(f) logloss_pliegue(datos, f[1], f[2]))
    filas[[length(filas) + 1]] <- tibble(
      K_Elo = K, k_shrinkage = k,
      LogLoss_promedio = weighted.mean(r["logloss", ], r["partidos", ]),  # Python: np.average(weights=)
      … )
  }
}
```

Guardar el rating **antes** de actualizarlo equivale al corte por día de Python porque ningún equipo juega dos
veces el mismo día (ver [11.2.2](#1122-construir_base_historica)).

**La traducción literal de la celda 11 (verificado para K = 15, k = 0)**, con las funciones de R de §2 y §4:

```r
calibrar_un_par <- function(datos) {                   # datos = base SIN forma para un (K, k)
  r <- t(sapply(folds, function(f) {
    tr <- filter(datos, Date < as.Date(f[1]))
    va <- filter(datos, Date >= as.Date(f[1]), Date < as.Date(f[2]))
    m <- entrenar_modelo(tr, especificaciones$M0_Base[[1]], especificaciones$M0_Base[[2]])
    c(logloss = evaluar_predicciones(predecir_con_modelo(m, va))[["LogLoss_1X2"]], partidos = nrow(va))
  }))
  list(folds = r, promedio = weighted.mean(r[, "logloss"], r[, "partidos"]))
}
cal <- calibrar_un_par(construir_base_historica(historico, k_elo = 15, k_shrinkage = 0, incluir_forma = FALSE))
cal$folds[, "logloss"]   # 0.960230 0.989315 0.929130
cal$promedio             # 0.959558

base <- construir_base_historica(historico, k_elo = 15, k_shrinkage = 0)   # 2,700 × 24
training_data_copia <- base
training_data <- base |> filter(if_all(all_of(columnas_tiros), ~ !is.na(.x))) |> arrange(Date)  # ≈ dropna
cat(sprintf("Base construida: %d partidos, %d tras limpieza\n", nrow(base), nrow(training_data)))
stopifnot(all(is.finite(as.matrix(training_data[, c(todos_los_predictores, "home_goals", "away_goals")]))),
          !any(duplicated(training_data[, c("Date", "HomeTeam", "AwayTeam")])))
train <- filter(training_data, Date < as.Date("2024-08-01"))
val   <- filter(training_data, Date >= as.Date("2024-08-01"), Date < as.Date("2025-08-01"))
test  <- filter(training_data, Date >= as.Date("2025-08-01"))
c(nrow(train), nrow(val), nrow(test))                  # 1897 380 419
```

`if_all(all_of(cols), ~ !is.na(.x))` se queda con las filas donde **todas** esas columnas tienen dato (lo mismo
que `dropna(subset=…)`); `weighted.mean()` es `np.average(weights=…)`. Para las 35 combinaciones con esta versión
literal bastaría un `mapply()` sobre `rejilla`, pero tardaría varios minutos **(ilustrativo)**; la versión rápida y
verificada es `06_calibracion.R`.

---

## 11.6 Nota: los 4 partidos sin historial (celdas 12–14)

**Celda 12 (texto, nueva en la versión final):** las variables de forma usan sólo información previa. En cuatro
partidos, uno de los equipos no tenía partidos previos de Premier en el histórico, así que no hay forma de
calcular sus promedios recientes de tiros y tiros a puerta sin usar información futura o inventar valores. Esas
filas tienen faltantes en `shots_*` y `sot_*` y se eliminan: de 2,700 a 2,696. *"A pesar de que M0 podría
utilizarse sin la necesidad de calcular forma reciente"*, se quitan de todos los modelos para que todas las
especificaciones usen la misma muestra.

### 11.6.1 Celda 13: cuáles son

```python
sin_historial = training_data_copia[training_data_copia[COLUMNAS_TIROS].isna().any(axis=1)].copy()
sin_historial["Equipo"] = np.where(sin_historial["shots_for_home"].isna(),
                                   sin_historial["HomeTeam"], sin_historial["AwayTeam"])
sin_historial["Rival"] = np.where(sin_historial["shots_for_home"].isna(),
                                  sin_historial["AwayTeam"], sin_historial["HomeTeam"])
display(sin_historial[["Equipo", "Date", "Rival"]])
```

**Salida guardada:**

```text
             Equipo       Date      Rival
760       Brentford 2021-08-13    Arsenal
1144  Nott'm Forest 2022-08-06  Newcastle
1523          Luton 2023-08-12   Brighton
2660       Coventry 2026-08-21    Arsenal
```

- `isna().any(axis=1)` marca las filas con **algún** faltante en las 8 columnas de tiros (`axis=1` = por fila).
- Si faltan los tiros del **local**, el equipo sin historial es el local; si no, es el visitante. Brentford jugaba
  de local; los otros tres, de visitantes. Por eso faltan 1 valor en cada columna de tiros del local y 3 en cada
  columna del visitante.
- Los números de la izquierda (760, 1144, 1523, 2660) son la posición de la fila en la base antes de limpiar.
- Los cuatro son el **primer partido** de equipos que no habían jugado en Premier desde 2001: tres caen en
  entrenamiento (2021/22, 2022/23 y 2023/24) y uno en prueba (2026/27).

### 11.6.2 Por qué faltan sólo los tiros

Para esos equipos, `recent_form` devuelve `NaN` en tiros, pero en goles de forma usa el respaldo
`avg_team_goals` (1.362264), y `season_stats` usa el promedio de la liga de la temporada anterior (por ejemplo,
Brentford recibe `gf_home` = 1.347368, el promedio de 2020/21). Por eso el `dropna` mira sólo las columnas de
tiros: las demás nunca faltan.

> **Decisión:** eliminar los 4 partidos de **todos** los modelos, incluido M0.
> **Alternativas:** (a) dejarlos en M0 y quitarlos sólo de M1–M4 — M0 tendría 4 partidos más, pero los modelos ya
> no se compararían en la misma muestra; (b) imputar los tiros (promedio de la liga o de los ascendidos) —
> conserva los partidos, pero inventa un dato que el equipo no tenía; (c) traer datos de la segunda división
> (Championship) — no están en la base. Ninguna se probó.
> **Por qué ésta:** son 4 de 2,700 (0.15 %) y ninguno es de validación; con la misma muestra, las diferencias
> entre modelos se deben a las variables y no a los partidos.
> **Evidencia en el proyecto:** las tablas de §6 y §9 comparan los cinco modelos en exactamente los mismos 380 y
> 419 partidos.
> **Si preguntan:** "Son cuatro debuts de equipos sin historial de tiros; los quitamos de todos los modelos para
> comparar a todos con los mismos partidos."

**En R (verificado):**

```r
sin_historial <- training_data_copia |>
  filter(if_any(all_of(columnas_tiros), is.na)) |>               # ≈ isna().any(axis=1)
  mutate(Equipo = if_else(is.na(shots_for_home), HomeTeam, AwayTeam),
         Rival  = if_else(is.na(shots_for_home), AwayTeam, HomeTeam)) |>
  select(Equipo, Date, Rival)
#   Brentford 2021-08-13 Arsenal · Nott'm Forest 2022-08-06 Newcastle · Luton 2023-08-12 Brighton · Coventry 2026-08-21 Arsenal
```

### 11.6.3 Celda 14: la exportación de la caché

```python
#NOTA: con este código se exportó la base de entrenamiento a csv para no recrearla cada vez que se corra el notebook en github
# training_data.to_csv(
#     "premier_training_data.csv",
#     index=False
# )
```

- Ésta es la posición en la que la exportación **sí funciona** (después de la celda 11). Se ejecutó una vez y se
  comentó. El archivo `premier_training_data.csv` del repositorio (2,696 × 24) es esa base; el README del
  repositorio publica su huella SHA-256 para comprobarlo.
- **Quién lo lee:** el notebook **no**: siempre reconstruye la base en la celda 11. Lo leen `datos_dashboard.py`
  (así el tablero se construye en GitHub Actions sin ejecutar el notebook; a eso se refiere "en github") y los
  scripts de R de la guía.
- Reconstruir la base con el código vigente da los mismos valores que el CSV (diferencia máxima 4.5 × 10⁻¹³).

> **Decisión:** exportar una vez la base a CSV y dejar comentada la exportación.
> **Alternativas:** (a) que el tablero ejecute el notebook en cada publicación — siempre al día, pero varios
> minutos más y todas las dependencias del notebook en GitHub Actions; (b) que el tablero reconstruya la base con
> `wc_predictor` — duplicaría la lógica de §2; (c) guardar en formato binario (parquet, pickle) — más rápido de leer,
> pero menos transparente y R lo lee con paquetes extra.
> **Por qué ésta:** un CSV se puede abrir, auditar y leer desde Python y desde R; el tablero se construye rápido.
> **Riesgo:** si cambian los datos, `wc_predictor.py` o K y k, hay que volver a exportar (lo advierte el reporte).
> La verificación 17/17 del tablero detectaría un desfase entre la caché y las salidas del notebook.
> **Si preguntan:** "La base de variables se exportó una vez a CSV; el tablero la lee para no recalcularla en cada
> publicación, y comprobamos que reconstruirla da exactamente lo mismo."

---

## 11.7 · §6 Estimación M0–M4 y validación 2024/25 (celdas 15–16)

**Celda 15 (texto):** con K y k ya fijos, cada especificación se estima **sólo con `train`** y se evalúa en
`val`. Define $\Delta LL_m = LL_m - LL_{M0}$ (negativo = mejor que M0) y advierte: comparar especificaciones no
demuestra causalidad; más variables pueden mejorar dentro de muestra y empeorar fuera; se elige por desempeño
temporal y parsimonia.

**Celda 16 (código):**

```python
modelos_entrenados = {
    nombre: entrenar_modelo(train, *columnas)
    for nombre, columnas in ESPECIFICACIONES.items()
}
predicciones_val = {
    nombre: predecir_con_modelo(modelo, val)
    for nombre, modelo in modelos_entrenados.items()
}
tabla_validacion = pd.DataFrame([
    {"Modelo": nombre, "Variables": len(modelos_entrenados[nombre]["columnas_home"]),
     **evaluar_predicciones(pred)}
    for nombre, pred in predicciones_val.items()
])
ll_m0 = tabla_validacion.loc[tabla_validacion["Modelo"] == "M0_Base", "LogLoss_1X2"].iloc[0]
tabla_validacion["Delta_LogLoss_vs_M0"] = tabla_validacion["LogLoss_1X2"] - ll_m0
display(tabla_validacion.sort_values("LogLoss_1X2").round(6))
```

1. **Diccionario por comprensión** (*dict comprehension*): en una instrucción entrena los cinco modelos (10 GLM)
   con los 1,897 partidos de entrenamiento. `*columnas` reparte la tupla (local, visitante) en dos argumentos,
   como explica el comentario del original.
2. **Predicciones** de cada modelo para los 380 partidos de validación.
3. **Tabla de métricas:** una fila por modelo, con el número de variables por ecuación y lo que devuelve
   `evaluar_predicciones` (desempacado con `**`).
4. **ΔLogLoss contra M0:** `loc[máscara, columna]` toma el LogLoss de M0 e `iloc[0]` lo vuelve un número.
5. Muestra la tabla ordenada por LogLoss.

**Salida guardada:**

| Modelo | Variables | Partidos | MAE local | MAE visitante | MAE promedio | LogLoss 1X2 | Δ vs M0 |
|---|---|---|---|---|---|---|---|
| M4_Completo | 9 | 380 | 0.966128 | 0.877662 | 0.921895 | **0.978612** | −0.010935 |
| M2_Tiros | 5 | 380 | 0.967058 | 0.875771 | 0.921414 | 0.980718 | −0.008829 |
| M3_SOT | 5 | 380 | 0.962969 | 0.878943 | 0.920956 | 0.982319 | −0.007228 |
| M1_Forma | 5 | 380 | 0.964160 | 0.878962 | 0.921561 | 0.987603 | −0.001944 |
| M0_Base | 3 | 380 | 0.959641 | 0.877023 | **0.918332** | 0.989547 | 0.000000 |

**Cómo se lee:** por LogLoss, M4 es el mejor y M0 el peor; por MAE, **M0 es el mejor**. Las dos métricas no
ordenan igual (la tensión se explica en el [capítulo 9](09_evaluacion_y_validacion.md)). El bootstrap del tablero
dice que la ventaja de M4 sobre M0 en validación es significativa **por un margen mínimo**; en prueba se
invierte. Por eso se mantiene M0 ([capítulo 12](12_resultados.md)).

> **Decisión:** estimar los coeficientes una sola vez, con entrenamiento, y usarlos sin cambio en validación y
> prueba.
> **Alternativas:** (a) reestimar al inicio de cada temporada (origen móvil; Hyndman y Athanasopoulos, 2021) — más
> realista para un uso continuo, pero cada periodo tendría su propio modelo; (b) reestimar tras cada jornada — aún
> más realista y mucho más cómputo; (c) reentrenar con entrenamiento + validación antes de la prueba — más datos,
> pero ya no se probaría exactamente el modelo comparado. Ninguna se probó.
> **Por qué ésta:** es el esquema clásico entrenamiento / validación / prueba: un modelo por especificación, fácil
> de comparar y de explicar. Lo que sí se actualiza partido a partido son las **variables** (Elo, temporada, forma).
> **Si preguntan:** "Los coeficientes se fijan con 2019/20–2023/24; lo que cambia de partido a partido son las
> variables de cada equipo."

**En R (verificado):**

```r
modelos <- lapply(especificaciones, function(e) entrenar_modelo(train, e[[1]], e[[2]]))   # ≈ dict comprehension
pred_val <- lapply(modelos, predecir_con_modelo, datos = val)
tabla_validacion <- bind_rows(lapply(names(pred_val), function(n)
  c(Modelo = n, Variables = length(especificaciones[[n]][[1]]), evaluar_predicciones(pred_val[[n]])))) |>
  mutate(across(-Modelo, as.numeric)) |>
  mutate(Delta_LogLoss_vs_M0 = LogLoss_1X2 - LogLoss_1X2[Modelo == "M0_Base"]) |>
  arrange(LogLoss_1X2)
```

`lapply` recorre la lista de especificaciones como el `for` de la comprensión y conserva los nombres
(`modelos$M0_Base`). `c()` junta texto y números (todo queda como texto), y `across(-Modelo, as.numeric)` los
regresa a números.

---

## 11.8 · §7 Referencia simple y diagnóstico (celdas 17–18)

**Celda 17 (texto):** dos diagnósticos auxiliares. La **referencia de Poisson constante** usa las medias de goles
del entrenamiento para todos los partidos ("sirve como referencia mínima para comprobar si las covariables aportan
información"). El **VIF** es $VIF_j = 1/(1-R_j^2)$, con $R_j^2$ de regresar el predictor $j$ contra los demás.
Advierte que correlación y VIF diagnostican redundancia, no calidad predictiva, y que la sección no cambia las
variables.

> El título dice "diagnóstico del modelo **ampliado**", pero el código vigente diagnostica **M0**. El VIF de M4
> (máximo 5.56) lo calcula el tablero ([capítulo 9](09_evaluacion_y_validacion.md)).

### 11.8.1 La referencia simple

```python
lambda_base_home = float(train["home_goals"].mean())     # 1.561413
lambda_base_away = float(train["away_goals"].mean())     # 1.311545
base_val = val[CLAVES + OBJETIVOS].reset_index(drop=True).copy()
base_val["lambda_home"] = lambda_base_home
base_val["lambda_away"] = lambda_base_away
base_val[PROBS] = probabilidades_1x2(np.full(len(val), lambda_base_home),
                                     np.full(len(val), lambda_base_away))
print("Modelo de referencia simple:", evaluar_predicciones(base_val))
```

**Salida guardada:**

```text
Modelo de referencia simple: {'Partidos': 380, 'MAE_local': 1.054156146824626, 'MAE_visitante': 0.9281386122131897,
'MAE_promedio': 0.9911473795189079, 'LogLoss_1X2': 1.0793610651054353}
```

- Todos los partidos reciben la misma λ y, por tanto, las mismas probabilidades: **43.24 % / 24.69 % / 32.07 %**.
  `np.full(n, valor)` crea un vector de n valores iguales (en R, `rep(valor, n)`).
- Mide cuánto vale "pronosticar sin saber nada de los equipos". M0 la supera en las dos métricas: LogLoss 0.989547
  contra 1.079361 y MAE 0.918332 contra 0.991147.
- En el tablero se llama **referencia ingenua** y también se evalúa en prueba (1.086791), junto con el azar
  uniforme (1/3 para cada resultado: ln 3 = 1.098612).

> **Decisión:** comparar contra una referencia que no sabe nada de los equipos: Poisson con las medias del
> entrenamiento.
> **Alternativas:** (a) azar uniforme (1/3 cada resultado) — más débil: ni siquiera sabe que el local gana más; el
> tablero también la muestra; (b) frecuencias históricas del 1X2 — casi igual a la ingenua; (c) el Elo solo (su
> probabilidad esperada) — una referencia más exigente; no se calculó.
> **Por qué ésta:** usa la misma maquinaria (Poisson + Skellam) que los modelos, así que la diferencia mide justo lo
> que aportan las variables.
> **Evidencia en el proyecto:** M0 la supera en validación (0.989547 contra 1.079361) y en prueba (1.033076 contra
> 1.086791; bootstrap −0.0537, IC 95 % de −0.0861 a −0.0217: diferencia clara).
> **Si preguntan:** "La referencia ingenua le da a todos los partidos las mismas probabilidades; el modelo la supera
> claramente, así que las variables sí informan."

### 11.8.2 Los resúmenes de `statsmodels`

```python
m0 = modelos_entrenados["M0_Base"]
print("Modelo local M0");     print(m0["home"].summary())
print("Modelo visitante M0"); print(m0["away"].summary())
```

**Salida guardada** (ecuación del local completa; de la visitante, lo que cambia):

```text
                 Generalized Linear Model Regression Results
==============================================================================
Dep. Variable:             home_goals   No. Observations:                 1897
Model:                            GLM   Df Residuals:                     1893
Model Family:                 Poisson   Df Model:                            3
Link Function:                    Log   Scale:                          1.0000
Method:                          IRLS   Log-Likelihood:                -2895.0
Date:                Wed, 30 Sep 2026   Deviance:                       2136.3
Time:                        19:29:46   Pearson chi2:                 1.89e+03
No. Iterations:                     5   Pseudo R-squ. (CS):             0.1496
Covariance Type:            nonrobust
==============================================================================
                 coef    std err          z      P>|z|      [0.025      0.975]
------------------------------------------------------------------------------
const          0.0433      0.088      0.494      0.621      -0.128       0.215
elo_diff       0.6283      0.063      9.994      0.000       0.505       0.751
gf_home        0.1678      0.035      4.848      0.000       0.100       0.236
ga_away        0.0778      0.040      1.962      0.050    7.24e-05       0.155
==============================================================================
Modelo visitante M0:  Log-Likelihood -2743.8 · Deviance 2244.2 · Pearson chi2 1.96e+03 · Pseudo R-squ. (CS) 0.1158
const          0.0264      0.095      0.277      0.781      -0.160       0.213
elo_diff      -0.6854      0.069     -9.893      0.000      -0.821      -0.550
gf_away        0.1079      0.037      2.887      0.004       0.035       0.181
ga_home        0.0281      0.042      0.664      0.506      -0.055       0.111
```

| Elemento | Qué significa |
|---|---|
| `No. Observations` 1897 · `Df Residuals` 1893 · `Df Model` 3 | Partidos; partidos menos parámetros (4); predictores sin contar la constante |
| `Link Function: Log` · `Method: IRLS` · `No. Iterations: 5` | Enlace logarítmico; algoritmo de máxima verosimilitud; iteraciones hasta converger |
| `Scale: 1.0000` | Poisson fija la dispersión en 1 (no la estima) |
| `Log-Likelihood` −2895.0 | Log-verosimilitud maximizada (más alta = mejor ajuste, sólo comparable con los mismos datos) |
| `Deviance` 2136.3 | Distancia al modelo "perfecto"; sirve para comparar modelos anidados |
| `Pearson chi2` 1.89e+03 | Suma de residuos de Pearson al cuadrado: 1,886.2 ÷ 1,893 = **0.996**, la dispersión (≈ 1, Poisson adecuado). Visitante: 1,961.9 ÷ 1,893 = 1.036 |
| `Pseudo R-squ. (CS)` 0.1496 | R² de Cox y Snell: cuánto mejora la verosimilitud frente a un modelo sólo con constante. Es bajo, como cabe esperar en un deporte con mucho azar; no se usa para elegir modelos |
| `Covariance Type: nonrobust` | Errores estándar clásicos (no robustos) |
| `coef` · `std err` · `z` · `P>|z|` | Coeficiente; su error estándar; z = coef ÷ error; p-valor de la prueba de que el coeficiente sea 0 |
| `[0.025 0.975]` | Intervalo de 95 % de Wald: coef ± 1.96 × error estándar |

**Lectura:** el Elo domina (z ≈ 10 en las dos ecuaciones); los goles a favor propios son significativos; los
goles en contra del rival quedan **en el límite** en la ecuación del local (p = 0.0498) y **no son significativos**
en la del visitante (p = 0.506). La constante no es significativa (es log λ cuando todas las variables valen 0,
un caso sin sentido práctico). La interpretación de los coeficientes está en el
[capítulo 6](06_poisson_y_regresion.md).

> **Corregido en la versión final:** la guía anterior señalaba que estos resúmenes estaban **antes** de definir
> `modelos_entrenados` y que "ejecutar todo" fallaba con `NameError`. Ahora están en §7, después de §6, y el
> notebook corre de principio a fin.

### 11.8.3 Correlaciones y VIF de M0

```python
def tabla_vif(datos, columnas):
    X = preparar_X(datos, columnas)
    matriz = X.to_numpy(dtype=float)
    return pd.DataFrame({
        "Variable": X.columns[1:],
        "VIF": [variance_inflation_factor(matriz, i) for i in range(1, X.shape[1])],
    }).sort_values("VIF", ascending=False).reset_index(drop=True)

for lado in ("home", "away"):
    columnas = m0[f"columnas_{lado}"]
    print(f"Correlaciones M0: {lado}")
    display(train[columnas].corr().round(3))
    print(f"VIF M0: {lado}")
    display(tabla_vif(train, columnas).round(3))
```

- `variance_inflation_factor(matriz, i)` hace una regresión lineal de la columna i contra **todas** las demás de la
  matriz y devuelve 1/(1 − R²). La matriz incluye la constante (por eso `preparar_X`), que hace de intercepto, y el
  ciclo empieza en 1 para no reportar la constante.
- `train[columnas].corr()` es la correlación de Pearson. Dividir el Elo entre 400 no la cambia.
- `f"columnas_{lado}"` arma el nombre de la llave (`columnas_home` o `columnas_away`).

**Salidas guardadas:**

| Ecuación | Correlaciones | VIF |
|---|---|---|
| Local | `elo_diff`–`gf_home` 0.503 · `elo_diff`–`ga_away` 0.372 · `gf_home`–`ga_away` 0.011 | `elo_diff` 1.632 · `gf_home` 1.407 · `ga_away` 1.219 |
| Visitante | `elo_diff`–`gf_away` −0.497 · `elo_diff`–`ga_home` −0.371 · `gf_away`–`ga_home` −0.038 | `elo_diff` 1.665 · `gf_away` 1.438 · `ga_home` 1.255 |

Todos los VIF de M0 están **por debajo de 2**: no hay redundancia problemática. El Elo se correlaciona
moderadamente con los promedios de goles (los equipos fuertes anotan más y reciben menos); por eso, con K = 15,
el Elo "absorbe" parte de lo que antes explicaban los promedios.

> **Decisión:** en el notebook se diagnostica la colinealidad de M0, el modelo que se conserva.
> **Alternativas:** (a) diagnosticar los cinco modelos; (b) usar el número de condición de la matriz; (c) usar el VIF
> generalizado ponderado por el GLM (`car::vif` en R) — da valores parecidos, no idénticos.
> **Por qué ésta:** los coeficientes que se interpretan (por ejemplo, e^0.6283 ≈ 1.87) son los de M0, así que su
> estabilidad es la que importa. La colinealidad de M4 no sesga sus predicciones; el tablero la reporta aparte.
> **Evidencia en el proyecto:** VIF de M0 ≤ 1.665; VIF máximo de M4 5.56 (tiros a puerta del local), con
> correlación tiros–tiros a puerta de 0.86.
> **Si preguntan:** "En el modelo base los VIF son menores que 2; la colinealidad aparece en M4, entre tiros y tiros a
> puerta, y no afecta las predicciones, sólo la lectura de cada coeficiente."

**En R (verificado):**

```r
lh0 <- mean(train$home_goals); la0 <- mean(train$away_goals)               # 1.561413 · 1.311545
base_val <- val |> select(Date, HomeTeam, AwayTeam, home_goals, away_goals) |>
  mutate(lambda_home = lh0, lambda_away = la0) |>
  bind_cols(as_tibble(probabilidades_1x2(rep(lh0, nrow(val)), rep(la0, nrow(val)))))
evaluar_predicciones(base_val)       # MAE 1.054156 · 0.928139 · 0.991147; LogLoss 1.079361

m0 <- modelos$M0_Base
summary(m0$home)$coefficients        # coef, error estándar, z y p: la misma tabla que statsmodels
c(logLik(m0$home), deviance(m0$home))                                          # -2895.0 · 2136.3
sum(residuals(m0$home, type = "pearson")^2) / df.residual(m0$home)             # dispersión 0.996
1 - exp((deviance(m0$home) - m0$home$null.deviance) / nobs(m0$home))           # pseudo R² de Cox y Snell 0.1496
confint.default(m0$home)             # intervalos de Wald, como [0.025 0.975] de statsmodels

vif_manual <- function(datos, columnas) {                                       # ≈ tabla_vif
  X <- as.data.frame(datos[, columnas]); X$elo_diff <- X$elo_diff / 400
  sort(sapply(columnas, function(j)
    1 / (1 - summary(lm(reformulate(setdiff(columnas, j), j), data = X))$r.squared)), decreasing = TRUE)
}
for (lado in 1:2) {
  cols <- especificaciones$M0_Base[[lado]]
  print(round(cor(train[, cols]), 3)); print(round(vif_manual(train, cols), 3))
}
```

- En R, `confint()` de un `glm` usa intervalos de **perfil de verosimilitud**, que difieren un poco de los de
  `statsmodels`; `confint.default()` da los de Wald, que son los que imprime Python.
- `vif_manual` hace la regresión lineal de cada variable contra las demás con `lm()` (que agrega su propio
  intercepto), igual que `variance_inflation_factor` con la constante en la matriz. `car::vif()` daría la versión
  ponderada por el GLM.

---

## 11.9 · §8 Cuotas de apertura como referencia externa (celdas 19–20)

**Celda 19 (texto):** las cuotas **no entran en ninguna regresión**; sólo se convierten en probabilidades para
tener una referencia externa. Con cuota decimal $o_j$: $q_j = 1/o_j$; como el margen hace que $\sum_j q_j > 1$, se
normaliza $p_j = q_j / \sum_k q_k$; el margen bruto (*overround*) es $\sum_j q_j - 1$. Supuestos: `AvgH/AvgD/AvgA` son
cuotas decimales de apertura; la normalización es proporcional ("existen otros métodos de *de-vigging*"); se
compara sólo en partidos con cuotas válidas y en los mismos partidos para mercado y modelos; no se evalúa
rentabilidad. La teoría está en el [capítulo 8](08_cuotas_y_mercado.md).

### 11.9.1 `cargar_cuotas`

```python
def cargar_cuotas(ruta):
    mercado = pd.read_csv(ruta, usecols=CLAVES + CUOTAS)
    mercado["Date"] = pd.to_datetime(mercado["Date"], dayfirst=True, format="mixed")
    mercado[CUOTAS] = mercado[CUOTAS].apply(pd.to_numeric, errors="coerce")
    if mercado.duplicated(CLAVES).any():
        raise ValueError("Hay registros duplicados en el archivo de cuotas")
    return mercado
```

- `usecols` lee sólo 6 columnas (fecha, equipos y las tres cuotas promedio de apertura).
- Convierte la fecha y fuerza las cuotas a número (texto raro → `NaN`).
- Si un partido apareciera dos veces, se detiene: el cruce posterior sería ambiguo.
- Resultado: 9,540 filas. `AvgH` falta en 6,840 partidos (2001/02 a 2018/19): las cuotas promedio empiezan el
  9-ago-2019, justo con la base de modelación.

### 11.9.2 `comparar_con_mercado`

```python
def comparar_con_mercado(predicciones_por_modelo, mercado):
    modelo_referencia = next(iter(predicciones_por_modelo))
    base = predicciones_por_modelo[modelo_referencia][CLAVES + OBJETIVOS]
    datos = base.merge(mercado, on=CLAVES, how="left", validate="one_to_one")
    cuotas = datos[CUOTAS].to_numpy(dtype=float)
    validas = np.isfinite(cuotas).all(axis=1) & (cuotas > 1).all(axis=1)
    datos = datos.loc[validas].reset_index(drop=True)
    if datos.empty:
        raise ValueError("No hay encuentros con cuotas válidas")

    brutas = 1.0 / datos[CUOTAS].to_numpy(dtype=float)
    totales = brutas.sum(axis=1)
    prob_mercado = brutas / totales[:, None]
    y = resultados_observados(datos)
    tabla = [{"Modelo": "Mercado_apertura", "Partidos": len(datos),
              "LogLoss_1X2": log_loss(y, prob_mercado, labels=[0, 1, 2])}]

    for nombre, pred in predicciones_por_modelo.items():
        alineado = datos[CLAVES].merge(pred[CLAVES + PROBS], on=CLAVES, how="left", validate="one_to_one")
        prob = alineado[PROBS].to_numpy(dtype=float)
        if not np.isfinite(prob).all() or not np.allclose(prob.sum(axis=1), 1.0, atol=1e-8):
            raise ValueError(f"Probabilidades inválidas para {nombre}")
        tabla.append({"Modelo": nombre, "Partidos": len(datos),
                      "LogLoss_1X2": log_loss(y, prob, labels=[0, 1, 2])})

    return (pd.DataFrame(tabla).sort_values("LogLoss_1X2").reset_index(drop=True),
            len(base), len(datos), (totales.mean() - 1.0) * 100)
```

**Qué hace, bloque por bloque:**

1. **Los partidos a comparar** salen del primer modelo del diccionario (`next(iter(…))` da la primera llave, M0).
2. **Cruce con el mercado** por fecha y equipos. `validate="one_to_one"` hace que pandas se detenga si algún
   partido aparece más de una vez en cualquiera de las dos tablas.
3. **Cuotas válidas:** las tres finitas y mayores que 1 (con una cuota decimal de 1 o menos, ganar devolvería lo
   apostado o menos, y 1/cuota sería una "probabilidad" de 1 o más). Si no queda ninguna, error.
4. **Probabilidades del mercado:** `1 / cuota`; la suma de cada fila es mayor que 1 por el margen; `totales[:, None]`
   convierte el vector en columna para que **cada fila se divida entre su propio total** (en R,
   `brutas / rowSums(brutas)`).
5. **LogLoss del mercado** en esos partidos.
6. **Cada modelo** se alinea a **los mismos partidos** con otro cruce, se revisan sus probabilidades y se calcula
   su LogLoss.
7. **Devuelve cuatro cosas:** la tabla ordenada, cuántos partidos había, cuántos tenían cuotas válidas y el margen
   promedio en porcentaje.

**Ejemplo real** (Man United 1–0 Fulham, 16-ago-2024):

| | Local | Empate | Visita | Suma |
|---|---|---|---|---|
| Cuota promedio de apertura | 1.62 | 4.36 | 5.15 | |
| 1 / cuota | 0.617284 | 0.229358 | 0.194175 | 1.040817 → margen 4.08 % |
| Mercado normalizado | **59.31 %** | 22.04 % | 18.66 % | 100 % |
| M0 | 57.04 % | 22.58 % | 20.38 % | 100 % |

**Ejecución en validación** (final de la celda 20):

```python
mercado = cargar_cuotas(ARCHIVO_CUOTAS)
tabla_mercado_val, n_val, n_val_cuotas, margen_val = comparar_con_mercado(predicciones_val, mercado)
print(f"Validación: {n_val_cuotas}/{n_val} con cuotas válidas; margen bruto promedio {margen_val:.2f}%")
display(tabla_mercado_val.round(6))
```

**Salida guardada** (◄ el tablero lee esta tabla):

```text
Validación: 380/380 con cuotas válidas; margen bruto promedio 4.49%
             Modelo  Partidos  LogLoss_1X2
0  Mercado_apertura       380     0.970552
1       M4_Completo       380     0.978612
2          M2_Tiros       380     0.980718
3            M3_SOT       380     0.982319
4          M1_Forma       380     0.987603
5           M0_Base       380     0.989547
```

La función devuelve una tupla de cuatro elementos y se desempaca en cuatro variables (en R, una `list` con
nombres). El mercado gana a los cinco modelos; los LogLoss de los modelos son los mismos de §6 porque los 380
partidos tienen cuotas.

> **Decisión:** quitar el margen con normalización proporcional (cada 1/cuota entre la suma de las tres).
> **Alternativas:** (a) método de Shin (1993) — supone que parte del margen protege a la casa de apostadores con
> información privilegiada y lo reparte de forma no proporcional; (b) métodos de potencia o de razón de momios
> (comparados por Štrumbelj, 2014) — corrigen el sesgo favorito–no favorito; (c) no quitar el margen — las
> probabilidades sumarían más de 1. Ninguna se probó.
> **Por qué ésta:** es la más simple, transparente y común; el propio notebook reconoce que otros métodos darían
> probabilidades "ligeramente distintas".
> **Si preguntan:** "Dividimos cada probabilidad implícita entre la suma de las tres para que sumen 1; hay métodos
> más finos, como el de Shin, que quedaron como extensión."

> **Decisión:** usar las cuotas **promedio de apertura** como referencia, y no como predictor.
> **Alternativas:** (a) el cierre (`AvgCH/AvgCD/AvgCA`) — incorpora más información (alineaciones, lesiones) y es más
> difícil de vencer; (b) una sola casa (Bet365, presente en la base desde 2002/03) — más ruido que un promedio;
> (c) meter las cuotas como variable del modelo — mejoraría el pronóstico, pero ya no respondería si la información
> estadística pública alcanza al mercado.
> **Por qué ésta:** la apertura es la referencia más justa para un modelo con información previa; el promedio de
> casas reduce el ruido; existe para todo el periodo de modelación.
> **Evidencia en el proyecto:** el tablero agrega el cierre como referencia adicional y es aún mejor: 0.966733 en
> validación y 1.017024 en prueba (apertura: 0.970552 y 1.020000).
> **Si preguntan:** "Comparamos contra la apertura porque es lo más cercano a lo que se sabe días antes; el cierre
> es todavía más difícil de superar."

**En R (verificado):**

```r
mercado <- read_csv("E0_consolidado.csv", show_col_types = FALSE) |>
  select(Date, HomeTeam, AwayTeam, AvgH, AvgD, AvgA)
stopifnot(!any(duplicated(mercado[, c("Date", "HomeTeam", "AwayTeam")])))     # ≈ cargar_cuotas
comparar_con_mercado <- function(predicciones, mercado) {
  datos <- predicciones[[1]] |> select(Date, HomeTeam, AwayTeam, home_goals, away_goals) |>
    left_join(mercado, by = c("Date", "HomeTeam", "AwayTeam"), relationship = "one-to-one")
  cuotas <- as.matrix(datos[, c("AvgH", "AvgD", "AvgA")])
  validas <- rowSums(is.finite(cuotas) & cuotas > 1) == 3
  datos <- datos[validas, ]
  brutas <- 1 / as.matrix(datos[, c("AvgH", "AvgD", "AvgA")])
  p_mercado <- brutas / rowSums(brutas)                       # cada fila entre su total
  y <- resultados_observados(datos)
  tabla <- c(Mercado_apertura = logloss(p_mercado, y), sapply(predicciones, function(p) {
    al <- left_join(datos[, c("Date", "HomeTeam", "AwayTeam")], p, by = c("Date", "HomeTeam", "AwayTeam"))
    logloss(as.matrix(al[, c("P_home", "P_draw", "P_away")]), y)
  }))
  list(tabla = sort(tabla), n = nrow(predicciones[[1]]), n_cuotas = nrow(datos),
       margen = 100 * (mean(rowSums(brutas)) - 1))
}
mv <- comparar_con_mercado(pred_val, mercado)
mv$margen; mv$tabla        # 4.49 · mercado 0.970552, M4 0.978612, …, M0 0.989547
```

`relationship = "one-to-one"` (dplyr 1.1 o posterior) es el `validate="one_to_one"` de pandas. La versión
comentada de la comparación en prueba está en [`03_mercado.R`](equivalencias_R/03_mercado.R).

---

## 11.10 · §9 Evaluación en prueba y comparación con el mercado (celdas 21–22)

**Celda 21 (texto):** se aplican los modelos **ya estimados** al periodo de prueba; *"no se vuelven a escoger
variables ni hiperparámetros usando estos resultados"*. Advierte que una diferencia pequeña de LogLoss no es
automáticamente significativa y que el desempeño futuro puede cambiar si cambian la liga o los equipos.

**Celda 22 (código):**

```python
MODELOS_PRUEBA = ("M0_Base", "M1_Forma", "M2_Tiros","M3_SOT", "M4_Completo")
predicciones_test = {
    nombre: predecir_con_modelo(modelos_entrenados[nombre], test)
    for nombre in MODELOS_PRUEBA
}
tabla_test = pd.DataFrame([{"Modelo": nombre, **evaluar_predicciones(pred)}
                           for nombre, pred in predicciones_test.items()])
print(f"Prueba: {len(test)} partidos; {test['Date'].min().date()} a {test['Date'].max().date()}")
display(tabla_test.round(6))

tabla_mercado_test, n_test, n_test_cuotas, margen_test = comparar_con_mercado(predicciones_test, mercado)
print(f"Cuotas válidas en prueba: {n_test_cuotas}/{n_test}; margen bruto promedio: {margen_test:.2f}%")
display(tabla_mercado_test.round(6))
```

- **No se reentrena nada:** se usan los modelos de §6 tal cual.
- `MODELOS_PRUEBA` cambió con el tiempo: la primera versión de la guía evaluaba tres (M0, M2, M4); la del commit
  `9f84684`, cuatro (M0, M1, M2, M4); en la versión final **Daniel agregó M3** y se evalúan **las cinco**.
- `tabla_test` sale en el orden de `MODELOS_PRUEBA` (no se ordena); la tabla contra el mercado, por LogLoss.

**Salidas guardadas:**

```text
Prueba: 419 partidos; 2025-08-15 a 2026-09-14
        Modelo  Partidos  MAE_local  MAE_visitante  MAE_promedio  LogLoss_1X2
0      M0_Base       419   0.954870       0.849741      0.902306     1.033076
1     M1_Forma       419   0.956394       0.850644      0.903519     1.034699
2     M2_Tiros       419   0.945434       0.857829      0.901631     1.037331
3       M3_SOT       419   0.937986       0.850360      0.894173     1.033868
4  M4_Completo       419   0.942293       0.856585      0.899439     1.036739
Cuotas válidas en prueba: 419/419; margen bruto promedio: 5.84%
             Modelo  Partidos  LogLoss_1X2
0  Mercado_apertura       419     1.020000
1           M0_Base       419     1.033076
2            M3_SOT       419     1.033868
3          M1_Forma       419     1.034699
4       M4_Completo       419     1.036739
5          M2_Tiros       419     1.037331
```

(◄ el tablero lee la segunda tabla.) **Cómo se lee:**

- Por **LogLoss**, M0 es el mejor modelo (1.033076) y M3 queda muy cerca (1.033868, +0.000792). El orden de
  validación no se repite: M4, el mejor en validación, queda cuarto.
- Por **MAE**, **M3 es el mejor** (0.894173, 0.008133 menos que M0) y M0 queda en cuarto lugar (0.902306). Otra vez
  las métricas no ordenan igual ([capítulo 9](09_evaluacion_y_validacion.md)).
- El mercado de apertura (1.020000) supera a los cinco. El margen de las casas en prueba (5.84 %) es mayor que en
  validación (4.49 %).

> **Decisión:** evaluar en prueba las cinco especificaciones, no sólo la elegida.
> **Alternativas:** (a) evaluar sólo el modelo ganador de validación (M4) — la prueba respondería una sola pregunta y
> no se sabría si la elección fue buena; (b) evaluar sólo M0 y M4.
> **Por qué ésta:** transparencia: se reporta todo y se ve que el orden de validación no se sostuvo. El costo es la
> tentación de elegir el modelo final mirando la prueba; por eso hay que decir que la preferencia por M0 usa
> información de prueba ([capítulo 9](09_evaluacion_y_validacion.md)).
> **Evidencia en el proyecto:** en prueba el orden fue M0 < M3 < M1 < M4 < M2 por LogLoss.
> **Si preguntan:** "Evaluamos los cinco en prueba, sin reentrenar, para ser transparentes; el orden de validación no
> se repitió."

**En R (verificado):**

```r
pred_test <- lapply(modelos, predecir_con_modelo, datos = test)      # las cinco, sin reentrenar
tabla_test <- bind_rows(lapply(names(pred_test), function(n) c(Modelo = n, evaluar_predicciones(pred_test[[n]])))) |>
  mutate(across(-Modelo, as.numeric))
mt <- comparar_con_mercado(pred_test, mercado)
mt$margen; mt$tabla       # 5.84 · mercado 1.020000, M0 1.033076, M3 1.033868, M1, M4, M2
```

---

## 11.11 · §10 Predicción individual (celdas 23–24)

**Celda 23 (texto):** la función reproduce para un partido nuevo *exactamente* la ingeniería de variables del
entrenamiento: corta el histórico antes de la fecha, reconstruye el Elo, calcula las estadísticas y aplica el GLM.
Con $(\lambda_H,\lambda_A)$, la probabilidad de un marcador exacto es

$$
P(G_H=h,G_A=a)=\frac{e^{-\lambda_H}\lambda_H^{\,h}}{h!}\cdot\frac{e^{-\lambda_A}\lambda_A^{\,a}}{a!},
\qquad (h^*,a^*)=\arg\max_{h,a}P(G_H=h,G_A=a),\quad h,a\in\{0,\dots,10\}.
$$

Supuestos: otra vez independencia; el rango 0–10 sólo sirve para encontrar el marcador modal (las probabilidades
1X2 salen de Skellam, sin truncar); los nombres de equipo deben escribirse exactamente como en el histórico; la
fecha es un **corte de información**, no necesariamente el día real del partido.

**Celda 24 (código):**

```python
def predecir_partido(home, away, fecha, nombre_modelo="M0_Base"):
    fecha = pd.Timestamp(fecha)
    df_pre = historial.loc[historial["date"] < fecha].copy()
    if df_pre.empty:
        raise ValueError("No hay histórico anterior a la fecha indicada")
    equipos = set(df_pre["home_team"]) | set(df_pre["away_team"])
    if home not in equipos or away not in equipos:
        raise ValueError("Uno o ambos equipos no aparecen en el histórico anterior a la fecha")

    elo = wc_predictor.build_elo(df_pre, k=K_ELO, scale=ESCALA_ELO)
    fila = {"Date": fecha, "HomeTeam": home, "AwayTeam": away,
            **crear_variables_partido(df_pre, fecha, home, away,
                                      elo.get(home, wc_predictor.ELO_INIT),
                                      elo.get(away, wc_predictor.ELO_INIT),
                                      k_shrinkage=K_SHRINKAGE)}
    datos = pd.DataFrame([fila])
    modelo = modelos_entrenados[nombre_modelo]
    pred = predecir_con_modelo(modelo, datos).iloc[0]

    goles = np.arange(11)
    matriz = np.outer(poisson.pmf(goles, pred["lambda_home"]), poisson.pmf(goles, pred["lambda_away"]))
    gh, ga = np.unravel_index(matriz.argmax(), matriz.shape)
    return {"fecha_corte": fecha.date().isoformat(), "partido": f"{home} vs {away}", "modelo": nombre_modelo,
            "lambda_home": float(pred["lambda_home"]), "lambda_away": float(pred["lambda_away"]),
            "P_home": float(pred["P_home"]), "P_draw": float(pred["P_draw"]), "P_away": float(pred["P_away"]),
            "marcador_mas_probable": f"{gh}-{ga}", "P_marcador": float(matriz[gh, ga])}

ejemplo = predecir_partido("Arsenal", "Man City", "2026-09-20", "M0_Base")
for nombre, valor in ejemplo.items():
    print(f"{nombre}",":", f"{valor}")
```

**Qué hace, bloque por bloque:**

1. **Corte de información:** `df_pre` = todo lo jugado **antes** de la fecha.
2. **Dos controles:** que haya histórico y que los dos equipos aparezcan en él. `set(…) | set(…)` es la unión de
   conjuntos (en R, `union()`). Si un nombre está mal escrito, se detiene: por ejemplo, con `"Wrexham"` responde
   *"Uno o ambos equipos no aparecen en el histórico anterior a la fecha"*.
3. **Elo al corte:** `build_elo` recorre `df_pre` partido por partido con `K_ELO` (15.0 tras la celda 11). Da lo
   mismo que la versión por día de §2 porque ningún equipo juega dos veces el mismo día.
4. **Variables:** la **misma** `crear_variables_partido` del entrenamiento (con forma incluida, así que sirve
   también para M1–M4).
5. **Predicción:** una tabla de una fila; aquí es donde importa `has_constant="add"` de `preparar_X`. `.iloc[0]`
   toma esa fila.
6. **Marcador modal:** `np.outer` multiplica cada P(local = h) por cada P(visita = a) y forma la matriz de 11 × 11
   (h = fila, a = columna); `argmax()` da la posición del máximo en la matriz "aplanada" y `np.unravel_index` la
   convierte en (fila, columna).
7. **Salida:** un diccionario con 10 datos, que el ciclo final imprime como `nombre : valor`.

**Salida guardada** (◄ el tablero lee las cinco líneas de λ y P):

```text
fecha_corte : 2026-09-20
partido : Arsenal vs Man City
modelo : M0_Base
lambda_home : 1.5375969468793136
lambda_away : 1.2656117048285258
P_home : 0.4364619580907665
P_draw : 0.2500002700356388
P_away : 0.31353777187359494
marcador_mas_probable : 1-1
P_marcador : 0.11795733217007393
```

Es decir: **λ 1.538 y 1.266; 43.65 % / 25.00 % / 31.35 %; marcador más probable 1–1 con 11.80 %** (el reporte da
43.6462 / 25.0000 / 31.3538 % y 11.7957 %).

**El cálculo, a mano.** Al corte, Arsenal tiene Elo 1787.12 y Man City 1779.19 (diferencia 7.94; ÷ 400 = 0.019846).
En 2026/27 ambos llevan 4 partidos: Arsenal 2.00 goles a favor y 0.25 en contra por partido; City, 2.00 y 0.50. Con
los coeficientes de M0:

$$
\log\lambda_H = 0.0433 + 0.6283(0.019846) + 0.1678(2.00) + 0.0778(0.50) = 0.0433 + 0.0125 + 0.3356 + 0.0389 = 0.4303
\ \Rightarrow\ \lambda_H = e^{0.4303} \approx 1.538
$$

$$
\log\lambda_A = 0.0264 - 0.6854(0.019846) + 0.1079(2.00) + 0.0281(0.25) = 0.0264 - 0.0136 + 0.2158 + 0.0070 = 0.2356
\ \Rightarrow\ \lambda_A = e^{0.2356} \approx 1.266
$$

En la ecuación del local entran los goles a favor de Arsenal (2.00) y los goles **en contra** de City (0.50); en la
del visitante, los goles a favor de City (2.00) y los en contra de Arsenal (0.25). Con los coeficientes completos,
el código da 1.537597 y 1.265612.

**Otros datos del ejemplo** (calculados con el código del notebook):

- Los cinco marcadores más probables: 1–1 (11.80 %), 1–0 (9.32 %), 2–1 (9.07 %), 0–1 (7.67 %) y 1–2 (7.46 %).
- La matriz de 0 a 10 goles suma 0.9999992: lo que queda fuera (8 × 10⁻⁷) es la razón de que, sumando la matriz,
  P(local) dé 0.436461 en lugar de 0.436462 (Skellam).
- Con corte 15-sep-2026 (el que usa el simulador del tablero, un día después del último partido) sale exactamente
  lo mismo: no hubo partidos entre el 15 y el 20 de septiembre.
- Con `nombre_modelo="M4_Completo"`: λ 1.497 y 1.248; 43.02 % / 25.34 % / 31.64 %; también 1–1 (12.00 %). La versión
  anterior del notebook usaba M4 como modelo por defecto; la final usa M0.

> **Decisión:** reportar λ, el 1X2 y el marcador **más probable** (modal) buscado en una matriz de 0 a 10 goles, con
> M0 por defecto.
> **Alternativas:** (a) redondear λ para dar un marcador (1.54 → 2 y 1.27 → 1: 2–1) — no es el marcador más
> probable; (b) una matriz más chica (0–5, la que muestra el tablero) — suficiente para mostrar, pero pierde un
> poco más de masa; (c) M4 por defecto, como en la versión anterior.
> **Por qué ésta:** el modal responde exactamente "¿qué marcador es más probable?"; con 0–10 lo que queda fuera es
> despreciable; M0 fue el mejor en prueba y es el que usa el simulador del tablero.
> **Evidencia en el proyecto:** el 1–1 (11.80 %) es el marcador más probable aunque la victoria local (43.65 %) sea el
> resultado más probable: el empate 1–1 es un solo marcador y "gana el local" suma muchos (1–0, 2–1, 2–0…).
> **Si preguntan:** "El marcador más probable puede ser un empate aunque el resultado más probable sea que gane el
> local, porque la victoria local se reparte entre muchos marcadores."

**En R (verificado: mismas λ, probabilidades, marcador 1–1 y 11.7957 %):**

```r
construir_elo <- function(d, k = 15) {                # wc_predictor.build_elo
  r <- c()
  for (i in seq_len(nrow(d))) {
    h <- d$HomeTeam[i]; a <- d$AwayTeam[i]
    rh <- if (h %in% names(r)) r[[h]] else 1500; ra <- if (a %in% names(r)) r[[a]] else 1500
    s <- if (d$FTHG[i] > d$FTAG[i]) 1 else if (d$FTHG[i] < d$FTAG[i]) 0 else 0.5
    e <- 1 / (1 + 10^((ra - rh) / 400))
    r[h] <- rh + k * (s - e); r[a] <- ra + k * ((1 - s) - (1 - e))
  }
  r
}
predecir_partido <- function(local, visita, fecha, nombre_modelo = "M0_Base") {
  fecha <- as.Date(fecha)
  previo <- filter(historico, Date < fecha)
  if (nrow(previo) == 0) stop("No hay histórico anterior a la fecha indicada")
  if (!all(c(local, visita) %in% union(previo$HomeTeam, previo$AwayTeam)))
    stop("Uno o ambos equipos no aparecen en el histórico anterior a la fecha")
  elo <- construir_elo(previo)
  fila <- as_tibble(c(list(Date = fecha, HomeTeam = local, AwayTeam = visita),
                      crear_variables_partido(previo, fecha, local, visita, elo[[local]], elo[[visita]])))
  pred <- predecir_con_modelo(modelos[[nombre_modelo]], fila)
  m <- outer(dpois(0:10, pred$lambda_home), dpois(0:10, pred$lambda_away))   # ≈ np.outer
  modal <- which(m == max(m), arr.ind = TRUE) - 1      # fila y columna del máximo; -1 porque empiezan en 1
  list(lambda_home = pred$lambda_home, lambda_away = pred$lambda_away, P_home = pred$P_home,
       P_draw = pred$P_draw, P_away = pred$P_away,
       marcador_mas_probable = paste(modal[1], modal[2], sep = "-"), P_marcador = max(m))
}
str(predecir_partido("Arsenal", "Man City", "2026-09-20"))
```

`which(m == max(m), arr.ind = TRUE)` hace lo de `np.unravel_index(matriz.argmax(), …)`: devuelve fila y columna del
máximo. Se resta 1 porque la fila 1 corresponde a 0 goles.

---

## 11.12 Sección final: alcance, supuestos y reproducibilidad (celda 25)

La última celda (texto, sin número de sección) resume los supuestos centrales. Qué significa cada uno, dónde está
en el código y si se revisó:

| # | Supuesto (celda 25) | Dónde está en el código | ¿Se revisó? | Capítulo |
|---|---|---|---|---|
| 1 | **Información prepartido:** ninguna variable usa el resultado que se predice | Guardia de `crear_variables_partido`, corte por día, `df_pre` de `predecir_partido` | Sí: la guardia nunca se dispara y la base es reproducible | [9](09_evaluacion_y_validacion.md) |
| 2 | **Poisson marginal** | `sm.families.Poisson()` | Se compara la distribución de goles contra Poisson en el tablero | [6](06_poisson_y_regresion.md) |
| 3 | **Equidispersión** (sin corrección de sobredispersión) | `Scale: 1.0000` | Sí: dispersión 0.996 y 1.036 | [6](06_poisson_y_regresion.md) |
| 4 | **Independencia local–visitante** | Skellam y `np.outer` | No | [7](07_de_goles_a_probabilidades.md), [15](15_limitaciones_y_extensiones.md) |
| 5 | **Efectos log-lineales** | Enlace logarítmico, sin interacciones | No | [6](06_poisson_y_regresion.md) |
| 6 | **Parámetros estables:** los coeficientes de entrenamiento se aplican sin cambio | §6 y §9 | No; el orden de los modelos cambió entre validación y prueba | [9](09_evaluacion_y_validacion.md), [15](15_limitaciones_y_extensiones.md) |
| 7 | **Elo simplificado:** mismo K, escala 400, inicio 1500, sin regresión entre temporadas ni localía | `update_elo` | K se calibró; lo demás no | [4](04_elo.md) |
| 8 | ***Shrinkage* de temporada:** empieza el 1 de agosto; referencia previa = temporada anterior o la liga | `season_stats` | k se calibró (k = 0) | [5](05_promedios_ajustados_y_forma.md) |
| 9 | **Forma reciente:** máximo 10 partidos, decaimiento 0.85 | `recent_form` | No se calibró | [5](05_promedios_ajustados_y_forma.md) |
| 10 | **Mercado como referencia:** las cuotas no son predictores | §8 y §9 | — | [8](08_cuotas_y_mercado.md) |

**Reproducibilidad.** El notebook recomienda reiniciar el *kernel* y correr todo desde el inicio si se modifica
`wc_predictor.py`. La razón: Python importa un módulo **una sola vez** por sesión, así que los cambios al `.py` no se
ven hasta reiniciar (o usar `importlib.reload`). En R, lo equivalente sería volver a hacer `source()` del script.
Además, el orden importa: la celda 11 sobrescribe `K_ELO` y `K_SHRINKAGE`, y §7–§10 usan objetos creados en §5 y §6.

---

## 11.13 Cómo se verificó este capítulo

| Qué | Cómo | Resultado |
|---|---|---|
| Código y salidas | Se copiaron del notebook vigente (26 celdas) | — |
| Tiempos, tamaños de pliegues, ejemplos intermedios | Ejecutando las celdas 2, 4, 7, 9, 11 (definiciones), 20 y 24 del notebook real, sin modificarlo (2-oct-2026) | Pliegues de 760 / 1,140 / 1,520 → 380; base idéntica a la caché (4.5 × 10⁻¹³); por día = partido por partido |
| Rejilla completa | Copia del notebook con las listas completas activas | Las 35 cifras de [11.5.5](#1155-la-rejilla-completa) |
| Bloques de R marcados **(verificado)** | Ejecutados en orden con R 4.3.2 contra los datos del proyecto | Mismas cifras que el notebook en §3 a §10 |
| Calibración en R | [`06_calibracion.R`](equivalencias_R/06_calibracion.R) | 35 de 35 a 6 decimales, en ≈ 7 s |

Lo que **no** se probó en el proyecto y aparece aquí como alternativa razonada: K < 15, las otras tres
combinaciones de bloques, calibrar K y k por modelo, otros métodos para quitar el margen, Poisson bivariada,
Dixon–Coles, binomial negativa y reestimar los coeficientes cada temporada.

[← wc_predictor.py](10_codigo_wc_predictor.md) · [Índice](README.md) · [Siguiente: resultados →](12_resultados.md)
