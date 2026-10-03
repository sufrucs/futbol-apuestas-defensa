# 13a. Código: `datos_dashboard.py`, función por función

[← El dashboard](13_dashboard.md) · [Índice](README.md) · [Siguiente: `graficas.py` →](13b_codigo_graficas.md)

> **Versión que se explica:** la entregada (rama `main`, commit `e3bd43f`, 30-sep-2026). El archivo tiene
> **906 líneas**; cuando se dice "líneas 316–325" son de ese archivo. Todas las salidas de ejemplo se obtuvieron
> **ejecutando el propio módulo** con Python 3.10 el 2-oct-2026 (`python -c "import datos_dashboard as dd; …"` desde
> la carpeta `Dashboard-o-pagina`). Los bloques de R marcados **(verificado)** se ejecutaron con R 4.3.2 contra los
> datos del proyecto y dan las mismas cifras; los marcados **(ilustrativo)** no se ejecutaron.
> `index.qmd`, que usa estas cifras, se explica en el [capítulo 13c](13c_codigo_index_quarto.md); las gráficas, en el
> [13b](13b_codigo_graficas.md).

---

## 13a.0 Panorama

### Para qué existe

`datos_dashboard.py` es el **backend** del tablero: **todas las cifras que muestra el sitio se calculan aquí**, a
partir de los mismos archivos y del mismo código que usa el equipo de Código. Ningún **resultado** está copiado a
mano del notebook o del reporte: `index.qmd` sólo les da formato. Lo que sí está escrito a mano son algunas
constantes de configuración (fechas de corte, especificaciones, las fechas del periodo sin público) y unos pocos
textos fijos; se señalan en [13a.9](#13a9-detalles-raros-y-comentarios-desactualizados).

Hace cuatro trabajos:

1. **Traer el código del equipo:** importa `wc_predictor.py` (Elo, promedios de temporada, forma reciente) y lee
   del **código** de `Analisis.ipynb` los parámetros que viven ahí (ventana y decaimiento de la forma, rejillas y
   pliegues de la calibración).
2. **Reproducir el modelo:** repite, con la misma lógica y los mismos nombres, las funciones del notebook (§2, §4 y
   §8) que no se pueden importar porque viven dentro del notebook; con ellas reentrena M0–M4 y calcula sus
   probabilidades en validación y prueba.
3. **Agregar lo que el notebook no calcula** ("complemento del dashboard"): análisis exploratorio, tasa de aciertos,
   intervalos bootstrap, calibración, descomposición de la brecha con el mercado, efectos estandarizados,
   sensibilidad sin público, el simulador y la auditoría de datos.
4. **Comprobar que todo coincide:** lee las **salidas guardadas** del notebook y compara 17 cifras contra las suyas
   (`tabla_verificacion()`: 17 de 17 ✓).

### Dónde encaja en la cadena

```text
Limpieza de datos.ipynb ──► E0_consolidado.csv (9,540 partidos × 34 columnas) ───────────────┐ lee
                                   │ load_history()                                         │
                                   ▼                                                        │
                          wc_predictor.py ─── import (desde su carpeta, en silencio) ──────┐ │
                                   │ import                                               │ │
                                   ▼                                                      ▼ ▼
                            Analisis.ipynb ── CÓDIGO de la celda 2 (N_FORMA, rejillas…) ─► ┌─────────────────────┐
                                   │       ── SALIDAS de las celdas 20, 22 y 24 ─────────► │ datos_dashboard.py  │ ◄ este capítulo
                                   ▼                                                      │ (906 líneas)        │
                 premier_training_data.csv (2,696 × 24) ─────────────────── lee ────────► └──────────┬──────────┘
                                                                                                     │ preparar_todo()
                                                                                                     ▼  diccionario de 28 entradas
                                                     index.qmd + graficas.py ──► quarto render ──► _site/ ──► GitHub Pages
```

- Del **histórico** `E0_consolidado.csv` salen el análisis exploratorio, las cuotas del mercado, la auditoría y el
  simulador.
- De la **base de modelación** `premier_training_data.csv` (exportada por el notebook) salen los modelos: el tablero
  **no** reconstruye las variables partido por partido (eso tarda ≈ 1 minuto en el notebook); lee la caché.
- Del **notebook** lee dos cosas distintas: su **código** (parámetros) y sus **salidas guardadas** (para verificar).

### Cómo trae el código del equipo (resumen)

```python
RUTA_CODIGO = Path(os.environ.get("RUTA_CODIGO", AQUI.parent / "Codigo" / "proyecto_mod_8")).resolve()
...
with _en_directorio(RUTA_CODIGO), contextlib.redirect_stdout(io.StringIO()):
    import wc_predictor
```

- `RUTA_CODIGO` es la carpeta del código del equipo: por defecto `../Codigo/proyecto_mod_8` (relativa al propio
  archivo), o la que diga la variable de entorno del mismo nombre.
- `wc_predictor.py` lee `E0_consolidado.csv` **con ruta relativa al importarse** ([cap. 10, 10.6](10_codigo_wc_predictor.md#106-el-bloque-que-se-ejecuta-al-importar)):
  si se importara desde `Dashboard-o-pagina`, fallaría con `FileNotFoundError` (lo comprobamos). Por eso
  `_en_directorio` cambia de carpeta mientras dura el `import` y luego regresa.
- `redirect_stdout` **silencia** lo que el módulo imprima. La versión inicial imprimía el ranking Elo al importarse;
  la entregada **ya no imprime nada** (lo comprobamos: salida vacía), así que hoy ese silencio es sólo precaución. El
  docstring de `_importar_wc_predictor` quedó desactualizado: todavía dice que el módulo "imprime el ranking Elo".
- Detalle en [13a.1.4](#13a14-_importar_wc_predictor-y-wc_predictor).

### Las siete secciones del archivo

El archivo está dividido con comentarios `# ── n. … ──`. Los encabezados de las secciones 0 ("Ubicación del código
del equipo") y 1 ("Configuración idéntica a Analisis.ipynb") se borraron en una edición web del 22-sep (commit
`0b8bcfd`), por eso **la numeración visible empieza en 2**. Aquí se mantiene la organización original:

| # | Sección (comentario del archivo) | Líneas | Qué contiene | Aquí |
|---|---|---|---|---|
| 1 | Configuración (sin encabezado) | 1–202 | Docstring, importaciones, rutas, importación de `wc_predictor`, lectura del notebook, constantes | [13a.1](#13a1-sección-1-configuración-líneas-1202) |
| 2 | "Funciones de Analisis.ipynb (secciones 2 y 4), misma lógica" | 205–308 | Las 8 funciones copiadas del notebook | [13a.2](#13a2-sección-2-funciones-reproducidas-del-notebook-líneas-205308) |
| 3 | "Carga de datos" | 311–341 | Los dos CSV del equipo y la partición | [13a.3](#13a3-sección-3-carga-de-datos-líneas-311341) |
| 4 | "Análisis exploratorio (complemento del dashboard)" | 344–465 | Temporadas, favorito, Elo, calibración de cuotas, Poisson | [13a.4](#13a4-sección-4-análisis-exploratorio-líneas-344465) |
| 5 | "Modelación y evaluación" | 468–694 | Modelos, métricas y los complementos de evaluación (bootstrap, brecha, calibración, efectos…) | [13a.5](#13a5-sección-5-modelación-y-evaluación-líneas-468694) |
| 6 | "Simulador (complemento del dashboard)" | 697–744 | Los 380 cruces de 2026/27 | [13a.6](#13a6-sección-6-simulador-líneas-697744) |
| 7 | "Calidad de datos y verificación" | 747–857 | Auditoría de datos y tabla de verificación | [13a.7](#13a7-sección-7-calidad-de-datos-y-verificación-líneas-747857) |
| — | Cierre | 860–906 | `preparar_todo()` y el bloque `if __name__ == "__main__"` | [13a.8](#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906) |

### Flujo interno

```text
import datos_dashboard
 ├─ _importar_wc_predictor() ........ wc_predictor (ELO_K = 15, SHRINKAGE_K = 0, ELO_SCALE = 400)
 └─ configuracion_notebook() ........ N_FORMA = 10, DECAY_FORMA = 0.85 (del código del notebook)

preparar_todo()                                         (una sola vez; todo queda en caché)
 ├─ cargar_historico() ............... E0_consolidado.csv + columnas "temporada" y "resultado"
 │    ├─ resumen_general · resumen_temporadas · resultado_del_favorito
 │    ├─ calibracion_historica_mercado · ajuste_poisson_goles
 │    └─ estructura_base · temporadas_completas · partidos_excluidos · auditoria_datos
 ├─ cargar_base_modelacion() ......... premier_training_data.csv
 │    ├─ resultado_por_elo ──► ventaja_local_en_elo
 │    └─ particiones() ──► entrenamiento 1,897 · validación 380 · prueba 419
 │         └─ modelos_entrenados() ... M0–M4, dos GLM de Poisson cada uno
 │              ├─ probabilidades_por_conjunto() ... 9 predictores × 2 periodos
 │              │    ├─ tabla_metricas ──► fraccion_de_mejora · delta_contra_m0
 │              │    ├─ tabla_bootstrap · brecha_por_resultado
 │              │    └─ calibracion_modelo_vs_mercado · comparacion_partido_a_partido
 │              ├─ efectos_estandarizados · dispersion_pearson · diagnostico_m4
 │              ├─ sensibilidad_sin_publico (reentrena M0 sin los partidos a puerta cerrada)
 │              └─ datos_simulador (load_history + build_elo + M0 para los 380 cruces)
 └─ tabla_verificacion(metricas, simulador) ◄── cifras_publicadas_notebook() (salidas guardadas)
```

### Todas las piezas del archivo

"Origen" dice si la pieza **reproduce** algo del notebook (con su sección) o es **complemento del dashboard** (algo
que el notebook no calcula). "Quién la usa" nombra la tarjeta del tablero con su título tal como aparece en
`index.qmd`; si una pieza sólo la usan otras funciones, se dice cuáles.

**Sección 1: configuración**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Origen | Aquí |
|---|---|---|---|---|---|---|
| 1 | Docstring del módulo | 1–16 | Explica qué hace el archivo | — (documentación) | — | [13a.1.1](#13a11-docstring-e-importaciones) |
| 2 | `from __future__ import annotations` e importaciones | 18–35 | Librerías estándar, pandas, statsmodels, scipy, sklearn | Todo el archivo | — | [13a.1.1](#13a11-docstring-e-importaciones) |
| 3 | `AQUI` | 38 | Carpeta del propio archivo | `RUTA_CODIGO` | Complemento | [13a.1.2](#13a12-rutas-aqui-ruta_codigo-y-la-variable-de-entorno) |
| 4 | `RUTA_CODIGO` | 39 | Carpeta del código del equipo (o la de la variable de entorno) | Las tres rutas, la importación | Complemento | [13a.1.2](#13a12-rutas-aqui-ruta_codigo-y-la-variable-de-entorno) |
| 5 | `ARCHIVO_HISTORICO`, `ARCHIVO_VARIABLES`, `ARCHIVO_NOTEBOOK` | 40–42 | Rutas de los dos CSV y del notebook | Carga, simulador, lectura del notebook | Complemento | [13a.1.2](#13a12-rutas-aqui-ruta_codigo-y-la-variable-de-entorno) |
| 6 | `_en_directorio()` | 45–52 | Cambiar de carpeta temporalmente y regresar | `_importar_wc_predictor` | Complemento | [13a.1.3](#13a13-_en_directorio) |
| 7 | `_importar_wc_predictor()` | 55–65 | Importar `wc_predictor.py` desde su carpeta y en silencio | Línea 68 | Complemento | [13a.1.4](#13a14-_importar_wc_predictor-y-wc_predictor) |
| 8 | `wc_predictor` (variable global) | 68 | El módulo del equipo ya importado | Todo el archivo; `index.qmd` lee `dd.wc_predictor.ELO_INIT` ("Variables del modelo", "Limitaciones y extensiones") | Código del equipo | [13a.1.4](#13a14-_importar_wc_predictor-y-wc_predictor) |
| 9 | `_notebook()` | 71–73 | Leer `Analisis.ipynb` como JSON una sola vez | `configuracion_notebook`, `cifras_publicadas_notebook` | Complemento | [13a.1.5](#13a15-_notebook-y-lru_cache) |
| 10 | `configuracion_notebook()` | 76–107 | Ventana y decaimiento de la forma, rejillas de K y k, años de los pliegues, leídos del **código** | `N_FORMA`, `DECAY_FORMA`; tarjetas "Evaluación" y "Limitaciones y extensiones" | Lee el notebook (§1) | [13a.1.6](#13a16-configuracion_notebook) |
| 11 | `cifras_publicadas_notebook()` | 110–133 | 12 LogLoss y 5 cifras del ejemplo, leídos de las **salidas guardadas** | `tabla_verificacion` ("Reproducibilidad") | Lee el notebook (§8, §9, §10) | [13a.1.7](#13a17-cifras_publicadas_notebook) |
| 12 | `FECHA_INICIO`, `FECHA_VALIDACION`, `FECHA_PRUEBA` | 136–138 | Cortes 2019-08-01, 2024-08-01 y 2025-08-01 | `particiones`, `partidos_excluidos` | Copia del notebook (§1) | [13a.1.8](#13a18-fechas-de-corte) |
| 13 | `K_ELO`, `K_SHRINKAGE`, `N_FORMA`, `DECAY_FORMA`, `ESCALA_ELO` | 140–147 | 15, 0, 10, 0.85 y 400 | Variables, simulador, `preparar_X`; textos de "Variables del modelo", "Evaluación", "Limitaciones y extensiones" y del simulador | Leídos de `wc_predictor.py` y del notebook | [13a.1.9](#13a19-parámetros-k_elo-k_shrinkage-n_forma-decay_forma-y-escala_elo) |
| 14 | `CLAVES`, `OBJETIVOS`, `CUOTAS`, `CUOTAS_CIERRE`, `PROBS` | 149–153 | Nombres de columnas | Casi todas las funciones | Copia del notebook (§1), salvo `CUOTAS_CIERRE` (complemento) | [13a.1.10](#13a110-nombres-de-columnas) |
| 15 | `GRUPOS`, `ESPECIFICACIONES` | 155–184 | Bloques de variables y los cinco modelos | `modelos_entrenados`, `sensibilidad_sin_publico`, `diagnostico_m4`; `index.qmd` cuenta sus variables ("Resumen", "Variables del modelo") | Copia del notebook (§1) | [13a.1.11](#13a111-grupos-y-especificaciones) |
| 16 | `MODELO_SIMULADOR` | 186–187 | `"M0_Base"` | `datos_simulador` | Complemento | [13a.1.12](#13a112-modelo_simulador-nombres-semilla-y-n_bootstrap) |
| 17 | `NOMBRES` | 189–199 | Etiquetas en español de los 9 predictores | `tabla_metricas`, `delta_contra_m0`, `tabla_verificacion`; `index.qmd` ("¿Son significativas las diferencias?") | Complemento | [13a.1.12](#13a112-modelo_simulador-nombres-semilla-y-n_bootstrap) |
| 18 | `SEMILLA`, `N_BOOTSTRAP` | 201–202 | 2026 y 10,000 | `_bootstrap` | Complemento | [13a.1.12](#13a112-modelo_simulador-nombres-semilla-y-n_bootstrap) |

**Sección 2: funciones reproducidas del notebook**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Origen | Aquí |
|---|---|---|---|---|---|---|
| 19 | `crear_variables_partido()` | 206–232 | Las 19 variables de un partido con información previa | `datos_simulador` | Reproduce §2 | [13a.2.1](#13a21-crear_variables_partido) |
| 20 | `preparar_X()` | 235–242 | Regresores: Elo ÷ 400 y constante | `entrenar_modelo`, `predecir_con_modelo`, `efectos_estandarizados`, `diagnostico_m4` | Reproduce §4 | [13a.2.2](#13a22-preparar_x) |
| 21 | `entrenar_modelo()` | 245–252 | Dos GLM de Poisson | `modelos_entrenados`, `sensibilidad_sin_publico` | Reproduce §4 | [13a.2.3](#13a23-entrenar_modelo) |
| 22 | `probabilidades_1x2()` | 255–265 | De (λ local, λ visitante) a 1X2 con Skellam | `predecir_con_modelo`, referencia ingenua | Reproduce §4 | [13a.2.4](#13a24-probabilidades_1x2) |
| 23 | `resultados_observados()` | 268–272 | 0 = local, 1 = empate, 2 = visita | `evaluar_predicciones`, `probabilidades_por_conjunto`, `resultado_por_elo` | Reproduce §4 | [13a.2.5](#13a25-resultados_observados) |
| 24 | `predecir_con_modelo()` | 275–285 | λ y 1X2 para una tabla de partidos | `probabilidades_por_conjunto`, `sensibilidad_sin_publico`, `datos_simulador` | Reproduce §4 | [13a.2.6](#13a26-predecir_con_modelo) |
| 25 | `evaluar_predicciones()` | 288–297 | MAE y LogLoss | `tabla_metricas` (MAE), `sensibilidad_sin_publico` | Reproduce §4 | [13a.2.7](#13a27-evaluar_predicciones) |
| 26 | `probabilidades_mercado()` | 300–308 | Cuotas → probabilidad implícita normalizada y margen | `probabilidades_por_conjunto` | Reproduce §8 (otra forma) | [13a.2.8](#13a28-probabilidades_mercado) |

**Sección 3: carga de datos**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Origen | Aquí |
|---|---|---|---|---|---|---|
| 27 | `_etiqueta_temporada()` | 312–313 | 2019 → "2019/20" | `resumen_temporadas`, `resultado_del_favorito`, `auditoria_datos`, `datos_simulador` | Complemento | [13a.3.1](#13a31-_etiqueta_temporada) |
| 28 | `cargar_historico()` | 316–325 | `E0_consolidado.csv` + `temporada` + `resultado` | Exploratorio, mercado, auditoría | Complemento (lee el archivo del equipo) | [13a.3.2](#13a32-cargar_historico) |
| 29 | `cargar_base_modelacion()` | 328–333 | `premier_training_data.csv` | `particiones`, `resultado_por_elo`, `partidos_excluidos` | Lee la base que exportó el notebook (§5) | [13a.3.3](#13a33-cargar_base_modelacion) |
| 30 | `particiones()` | 336–341 | Entrenamiento, validación y prueba | Modelos y complementos de evaluación; `index.qmd` ("En pocas palabras", "Evaluación", "Limitaciones y extensiones") | Reproduce el final de §5 | [13a.3.4](#13a34-particiones) |

**Sección 4: análisis exploratorio (todo es complemento del dashboard)**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Aquí |
|---|---|---|---|---|---|
| 31 | `resumen_general()` | 345–360 | Partidos, temporadas, fechas, % de resultados, goles | *Value boxes* "Partidos analizados" y "Gana el equipo local"; "Cómo funciona"; "Datos y procedencia"; la fecha final en varios textos | [13a.4.1](#13a41-resumen_general) |
| 32 | `resumen_temporadas()` | 363–377 | Resultados y goles por temporada completa | "Jugar en casa siempre ayuda… salvo sin público"; "Tabla por temporada" | [13a.4.2](#13a42-resumen_temporadas) |
| 33 | `resultado_del_favorito()` | 380–397 | Qué pasa con el favorito de Bet365 | *Value box* "Gana el favorito de las cuotas"; "Ni el favorito es garantía"; "Qué significa para el modelo" | [13a.4.3](#13a43-resultado_del_favorito) |
| 34 | `resultado_por_elo()` | 400–414 | Resultados por decil de diferencia de Elo | "A más ventaja de Elo, más victorias locales"; "Tabla: resultado por diferencia de Elo"; "Por qué importan estos patrones" | [13a.4.4](#13a44-resultado_por_elo) |
| 35 | `ventaja_local_en_elo()` | 417–428 | Cuántos puntos Elo "vale" jugar en casa | Anotación de "A más ventaja de Elo, más victorias locales" | [13a.4.5](#13a45-ventaja_local_en_elo) |
| 36 | `calibracion_historica_mercado()` | 431–437 | Probabilidad de Bet365 contra frecuencia observada | "Las cuotas están bien calibradas"; "Tabla: calibración de las cuotas" | [13a.4.6](#13a46-calibracion_historica_mercado-y-_tabla_calibracion) |
| 37 | `_tabla_calibracion()` | 440–447 | Agrupa probabilidades en intervalos y cuenta | `calibracion_historica_mercado`, `calibracion_modelo_vs_mercado` | [13a.4.6](#13a46-calibracion_historica_mercado-y-_tabla_calibracion) |
| 38 | `ajuste_poisson_goles()` | 450–465 | Goles observados contra Poisson con la misma media | "Los goles se comportan como un conteo de Poisson" | [13a.4.7](#13a47-ajuste_poisson_goles) |

**Sección 5: modelación y evaluación**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Origen | Aquí |
|---|---|---|---|---|---|---|
| 39 | `modelos_entrenados()` | 469–473 | M0–M4 ajustados en entrenamiento | Toda la evaluación y el simulador | Reproduce §6 | [13a.5.1](#13a51-modelos_entrenados) |
| 40 | `probabilidades_por_conjunto()` | 476–507 | Probabilidades 1X2 de 9 predictores en validación y prueba | Toda la evaluación; `index.qmd` (resultado real de prueba en "Calibración: modelo vs. mercado") | Reproduce §6–§9; azar y cierre son complemento | [13a.5.2](#13a52-probabilidades_por_conjunto) |
| 41 | `_logloss_por_partido()` | 510–511 | −log de la probabilidad del resultado real, partido por partido | `tabla_bootstrap`, `brecha_por_resultado` | Complemento | [13a.5.3](#13a53-_logloss_por_partido) |
| 42 | `tabla_metricas()` | 514–533 | LogLoss, probabilidad media, aciertos, P(empate), MAE | *Value box* "Partidos acertados por el modelo"; gráfica principal del Resumen; "Resumen"; "Métricas completas"; "Calibración: modelo vs. mercado"; "Qué significa para el modelo" | LogLoss y MAE reproducen §6–§9; lo demás, complemento | [13a.5.4](#13a54-tabla_metricas) |
| 43 | `fraccion_de_mejora()` | 536–539 | Parte de la ventaja del mercado que logra M0 | *Value box* "Ventaja del mercado que alcanza el modelo" (la de validación no se muestra) | Complemento | [13a.5.5](#13a55-fraccion_de_mejora) |
| 44 | `_bootstrap()` | 542–546 | IC 95 % de una media por remuestreo | `tabla_bootstrap` | Complemento | [13a.5.6](#13a56-_bootstrap-y-tabla_bootstrap) |
| 45 | `tabla_bootstrap()` | 549–577 | Siete comparaciones A − B con IC | "¿Son significativas las diferencias?"; "Resumen" (la brecha total) | Complemento | [13a.5.6](#13a56-_bootstrap-y-tabla_bootstrap) |
| 46 | `delta_contra_m0()` | 580–590 | ΔLogLoss de cada predictor contra M0 | "Agregar variables no generaliza" | Validación reproduce §6; prueba, complemento | [13a.5.7](#13a57-delta_contra_m0) |
| 47 | `brecha_por_resultado()` | 593–614 | Aporte de cada resultado a la brecha M0 − mercado | "No es una derrota..." | Complemento | [13a.5.8](#13a58-brecha_por_resultado) |
| 48 | `calibracion_modelo_vs_mercado()` | 617–628 | Calibración de M0 y del mercado | "Calibración: modelo vs. mercado" | Complemento | [13a.5.9](#13a59-calibracion_modelo_vs_mercado) |
| 49 | `efectos_estandarizados()` | 631–660 | exp(β·DE) − 1 con IC | "Qué variables pesan más" | Complemento | [13a.5.10](#13a510-efectos_estandarizados) |
| 50 | `dispersion_pearson()` | 663–666 | χ² de Pearson / grados de libertad | "Por qué importan estos patrones" | Complemento | [13a.5.11](#13a511-dispersion_pearson) |
| 51 | `sensibilidad_sin_publico()` | 669–685 | M0 reentrenado sin los 472 partidos a puerta cerrada | "Qué significa para el modelo" | Complemento | [13a.5.12](#13a512-sensibilidad_sin_publico) |
| 52 | `comparacion_partido_a_partido()` | 688–694 | P(local) de M0 y del mercado en cada partido de prueba | "Modelo vs. mercado, partido a partido" | Complemento | [13a.5.13](#13a513-comparacion_partido_a_partido) |

**Secciones 6 y 7, y cierre**

| # | Pieza | Líneas | Para qué sirve | Quién la usa | Origen | Aquí |
|---|---|---|---|---|---|---|
| 53 | `datos_simulador()` | 698–744 | Pronóstico de M0 para los 380 cruces de 2026/27 | Página "Explora un partido"; `tabla_verificacion` (Arsenal–Man City) | Complemento (aplica la lógica de §10 a todos los pares) | [13a.6](#13a6-sección-6-simulador-líneas-697744) |
| 54 | `estructura_base()` | 748–756 | Columnas totales, comunes y complementarias | "Datos y procedencia"; `auditoria_datos` | Complemento | [13a.7.1](#13a71-estructura_base) |
| 55 | `temporadas_completas()` | 759–763 | Cuántas temporadas completas y cuántos partidos | *Value box* "Gana el equipo local"; `auditoria_datos` | Complemento | [13a.7.2](#13a72-temporadas_completas) |
| 56 | `diagnostico_m4()` | 766–775 | Correlación tiros – tiros a puerta y VIF máximo de M4 | "Variables del modelo" | Complemento (el notebook da el VIF de M0) | [13a.7.3](#13a73-diagnostico_m4) |
| 57 | `partidos_excluidos()` | 778–791 | Los 4 partidos sin historial y su equipo debutante | "Limpieza y calidad"; `auditoria_datos` | Complemento (mismo resultado que la celda 13 del notebook) | [13a.7.4](#13a74-partidos_excluidos) |
| 58 | `auditoria_datos()` | 794–825 | Tabla de 10 revisiones de calidad | "Limpieza y calidad" | Complemento | [13a.7.5](#13a75-auditoria_datos) |
| 59 | `tabla_verificacion()` | 828–857 | 17 cifras del tablero contra las del notebook | "Reproducibilidad" | Verificación | [13a.7.6](#13a76-tabla_verificacion) |
| 60 | `preparar_todo()` | 860–895 | Todo lo anterior en un diccionario de 28 entradas | El chunk de preparación de `index.qmd` | — | [13a.8](#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906) |
| 61 | `if __name__ == "__main__":` | 898–906 | Imprime un resumen al correr el archivo directamente | Sólo quien lo ejecute a mano | — | [13a.8](#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906) |

### Cómo se corre y cuánto tarda

- **Dentro del tablero:** `index.qmd` hace `import datos_dashboard as dd` y `d = dd.preparar_todo()` en su chunk
  de preparación; Quarto lo ejecuta con Python 3.10 al renderizar ([cap. 13c](13c_codigo_index_quarto.md)).
- **Solo:** desde la carpeta `Dashboard-o-pagina`, `python datos_dashboard.py` imprime métricas, bootstrap y la
  verificación ([13a.8](#13a8-cierre-preparar_todo-y-el-bloque-__main__-líneas-860906)).
- **Tiempos medidos** en esta computadora (2-oct-2026): importar el módulo ≈ 2.1–2.4 s (incluye que
  `wc_predictor` lea el CSV); `preparar_todo()` ≈ 8 s más, casi todo el simulador (≈ 7 s); el archivo completo
  desde la terminal, ≈ 12 s. Una segunda llamada a `preparar_todo()` tarda menos de un microsegundo (caché).

### Historial del archivo

| Fecha | Commit | Quién | Cambio en `datos_dashboard.py` |
|---|---|---|---|
| 22-sep-2026 | `8b1fc83` | César | Versión inicial (780 líneas): K = 30 de la constante del módulo, `K_SHRINKAGE = 10`, `N_FORMA = 10`, `DECAY_FORMA = 0.85` y `ESCALA_ELO = 400` escritos a mano; la verificación comparaba contra **15 cifras copiadas a mano** (`REPORTADO_NOTEBOOK`, `REPORTADO_EJEMPLO_M0`) |
| 22-sep | `0b8bcfd` | César (edición web) | Borra los encabezados de las secciones 0 y 1 |
| 24-sep | `1e966be` | Max (edición web) | Etiquetas más cortas en `NOMBRES` y en `efectos_estandarizados` |
| 30-sep | `9f84684` | César | K, k y escala desde `wc_predictor.py`; ventana, decaimiento, rejillas y pliegues desde el código del notebook (`_notebook`, `configuracion_notebook`); verificación contra las salidas guardadas (`cifras_publicadas_notebook`, 16 cifras); nuevas `estructura_base`, `temporadas_completas`, `diagnostico_m4` y `partidos_excluidos` |
| 30-sep | `e3bd43f` | César | `sensibilidad_sin_publico` devuelve también las fechas `inicio` y `fin` (versión entregada) |

Después de `9f84684` el archivo no volvió a cambiar salvo por `e3bd43f`; aun así, cuando Daniel agregó M3 a la
evaluación de prueba del notebook, la verificación pasó **sola** de 16 a 17 cifras
([13a.7.6](#13a76-tabla_verificacion)).

> **Decisión:** recalcular todas las cifras del tablero desde los archivos del equipo, importando `wc_predictor.py` y
> reproduciendo las funciones del notebook.
> **Alternativas:** (a) **copiar las cifras a mano** en el tablero — a favor: no hay código que mantener; en contra:
> se desactualizan con cada cambio, y hubo varios (K de 30 a 15, k de 10 a 0, 90 partidos recuperados en la limpieza,
> M3 en la prueba); (b) **ejecutar el notebook desde el tablero** (por ejemplo con `nbclient` o `papermill`) — a favor:
> sería literalmente el mismo código; en contra: tarda minutos en cada render, el tablero dependería de que el
> notebook corra completo y de principio a fin, y aun así faltarían los complementos; (c) **importar el notebook**
> como si fuera un módulo (con herramientas como `importnb`) — en contra: ejecutaría también las celdas pesadas (la
> base y la calibración) y depende de una librería más; (d) **que el notebook exporte sus resultados** a un JSON o CSV
> que el tablero lea — a favor: rápido; en contra: el tablero necesita mucho que el notebook no calcula (bootstrap,
> calibración, simulador), y sería otro archivo que se puede quedar viejo; (e) **pasar las funciones del notebook a
> un módulo** importable — a favor: una sola implementación; en contra: reorganizar el notebook del equipo de Código
> al final del proyecto. Ninguna se probó.
> **Por qué ésta:** una sola fuente de verdad (los archivos del equipo), render de ≈ 12 s, y el riesgo de duplicar
> funciones se controla con la verificación automática, que compara contra lo que el notebook imprimió.
> **Evidencia en el proyecto:** la tabla de verificación da 17 de 17 ✓, también en los servidores de GitHub; y los
> cambios del equipo de Código (K, k, limpieza, M3) llegaron al tablero sin copiar ningún número.
> **Si preguntan:** "El tablero no tiene cifras copiadas: importa `wc_predictor.py`, lee los dos CSV del equipo y
> repite las funciones del notebook; y para comprobar que la copia es fiel, compara 17 cifras contra las que el
> notebook dejó guardadas."

(Es la decisión D40 del [capítulo 19](19_decisiones_y_alternativas.md#d40-recalcular-todo-desde-los-archivos-del-equipo--razonada).)

---

## 13a.1 Sección 1: configuración (líneas 1–202)

Todo lo que se define al importar el módulo: rutas, el código del equipo, la lectura del notebook y las constantes.
Python ejecuta estas líneas **una vez**, al hacer `import datos_dashboard`.

### 13a.1.1 Docstring e importaciones

Líneas 1–35 (docstring resumido):

```python
"""Backend de datos del dashboard.

Todas las cifras que muestra el tablero se calculan aquí, a partir de los mismos
archivos y del mismo código que usa el equipo de Código:
- ``wc_predictor.py`` (...) se importa directamente desde la carpeta del código.
- Las funciones de modelación de ``Analisis.ipynb`` (secciones 2, 4 y 8) viven dentro
  del notebook, no en un módulo importable, por eso se reproducen aquí con la misma
  lógica y los mismos nombres. ``tabla_verificacion()`` comprueba que el tablero
  obtiene exactamente las métricas reportadas por el notebook.
Lo que el notebook no calcula (...) está marcado como "complemento del dashboard" en cada función.
"""
from __future__ import annotations

import contextlib, inspect, io, json, os, re, sys      # (en el archivo, una por línea)
from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import poisson, skellam
from sklearn.metrics import log_loss, mean_absolute_error
from statsmodels.stats.outliers_influence import variance_inflation_factor
```

- El **docstring** (texto entre triples comillas al inicio) es la documentación del módulo; en R sería un bloque de
  comentarios al inicio del script. Resume la estrategia del archivo: importar lo importable, reproducir lo que vive
  en el notebook y verificar.
- `from __future__ import annotations` hace que las anotaciones de tipo (`-> pd.DataFrame`, `-> dict`) no se
  evalúen al definir cada función. No cambia ningún resultado; es una costumbre de estilo.

| Librería | Para qué se usa aquí | Equivalente en R |
|---|---|---|
| `contextlib` | `@contextmanager` (para `_en_directorio`) y `redirect_stdout` (silenciar) | `on.exit()`, `withr::with_dir()`; `capture.output()` |
| `inspect` | Leer los valores por defecto de `recent_form()` | `formals(recent_form)$n` |
| `io` | `StringIO`: un "archivo" en memoria donde se tira lo que se imprime | `capture.output()` |
| `json` | Leer `Analisis.ipynb`, que es un JSON | `jsonlite::fromJSON()` |
| `os`, `sys` | Variable de entorno, cambiar de carpeta, ruta de búsqueda de módulos | `Sys.getenv()`, `setwd()` |
| `re` | Expresiones regulares para leer el notebook | `stringr::str_match()` / `regmatches()` |
| `functools.lru_cache` | Memorización (caché) de funciones | `memoise::memoise()` |
| `pathlib.Path` | Rutas de archivos | `file.path()`, `normalizePath()` |
| `numpy`, `pandas` | Arreglos y tablas | vectores y matrices; `tibble` + `dplyr` |
| `statsmodels` | GLM de Poisson y VIF | `glm()`; VIF con `lm()` |
| `scipy.stats` | Poisson y Skellam | `dpois()`, `ppois()`; Skellam sumando `outer(dpois(), dpois())` |
| `sklearn.metrics` | `log_loss`, `mean_absolute_error` | a mano o con `yardstick` |

### 13a.1.2 Rutas: `AQUI`, `RUTA_CODIGO` y la variable de entorno

Líneas 38–42:

```python
AQUI = Path(__file__).resolve().parent
RUTA_CODIGO = Path(os.environ.get("RUTA_CODIGO", AQUI.parent / "Codigo" / "proyecto_mod_8")).resolve()
ARCHIVO_HISTORICO = RUTA_CODIGO / "E0_consolidado.csv"
ARCHIVO_VARIABLES = RUTA_CODIGO / "premier_training_data.csv"
ARCHIVO_NOTEBOOK = RUTA_CODIGO / "Analisis.ipynb"
```

1. `__file__` es la ruta del propio `datos_dashboard.py`; `.resolve()` la vuelve absoluta y `.parent` toma su
   carpeta. Así las rutas no dependen de **desde dónde** se ejecute Python (Quarto, la terminal o GitHub Actions).
2. `os.environ.get("RUTA_CODIGO", valor_por_defecto)` lee la variable de entorno; si no existe, usa
   `../Codigo/proyecto_mod_8` relativo al archivo. El operador `/` de `Path` une carpetas.
3. Las tres rutas que usa el resto del archivo cuelgan de `RUTA_CODIGO`.

**Salida real:** `RUTA_CODIGO = …\06_proyecto\Codigo\proyecto_mod_8`. Nadie define la variable en el proyecto (el
workflow de GitHub Actions no la usa); es una salida de emergencia que documentan los dos README
(`export RUTA_CODIGO=/ruta/a/proyecto_mod_8`) por si alguien mueve la carpeta del código.

**En R (ilustrativo):**

```r
ruta_codigo <- normalizePath(Sys.getenv("RUTA_CODIGO", unset = file.path("..", "Codigo", "proyecto_mod_8")))
archivo_historico <- file.path(ruta_codigo, "E0_consolidado.csv")
```

R no tiene un `__file__` confiable: en un proyecto se usa `here::here()` o se ejecuta desde la carpeta del script.

> **Decisión:** ubicar el código del equipo con una ruta relativa al propio archivo, que se puede cambiar con una
> variable de entorno.
> **Alternativas:** (a) ruta absoluta (`C:\Users\…`) — sólo funciona en una computadora; (b) ruta relativa al
> directorio de trabajo (`"../Codigo/…"`) — se rompe si Python se lanza desde otra carpeta; (c) copiar los archivos
> del equipo dentro de `Dashboard-o-pagina` — habría dos copias que pueden divergir.
> **Por qué ésta:** funciona igual en las computadoras del equipo y en el servidor de GitHub sin configurar nada, y
> permite mover la carpeta sin tocar el código.
> **Evidencia en el proyecto:** el sitio se construye en GitHub Actions con la ruta por defecto (17 de 17 ✓).
> **Si preguntan:** "Las rutas se calculan desde la ubicación del propio archivo, así funciona en cualquier
> computadora; si alguien mueve el código, basta con la variable `RUTA_CODIGO`."

### 13a.1.3 `_en_directorio`

Líneas 45–52:

```python
@contextlib.contextmanager
def _en_directorio(ruta: Path):
    anterior = Path.cwd()
    os.chdir(ruta)
    try:
        yield
    finally:
        os.chdir(anterior)
```

- Es un **administrador de contexto** (lo que se usa con `with`): guarda la carpeta actual, cambia a `ruta`, entrega
  el control al bloque `with` (`yield`) y, al terminar, **regresa** a la carpeta anterior.
- `try/finally` garantiza el regreso **aunque el bloque falle**: si el `import` lanzara un error, la carpeta de
  trabajo no quedaría cambiada para el resto del tablero.
- El guion bajo inicial es la convención de Python para "función interna, no la uses desde fuera".

**En R (ilustrativo):**

```r
en_directorio <- function(ruta, codigo) {
  anterior <- setwd(ruta)          # setwd() cambia de carpeta y devuelve la anterior
  on.exit(setwd(anterior))         # ≈ finally: se ejecuta al salir, aunque haya error
  codigo                           # el argumento se evalúa aquí (evaluación perezosa), ya dentro de `ruta`
}
# o, con el paquete withr: withr::with_dir(ruta, codigo)
```

### 13a.1.4 `_importar_wc_predictor` y `wc_predictor`

Líneas 55–68:

```python
def _importar_wc_predictor():
    """Importa wc_predictor tal cual lo dejó el equipo.

    Al importarse, el módulo lee "E0_consolidado.csv" con ruta relativa e imprime el
    ranking Elo, por eso se importa desde su carpeta y con la salida silenciada.
    """
    if str(RUTA_CODIGO) not in sys.path:
        sys.path.insert(0, str(RUTA_CODIGO))
    with _en_directorio(RUTA_CODIGO), contextlib.redirect_stdout(io.StringIO()):
        import wc_predictor
    return wc_predictor


wc_predictor = _importar_wc_predictor()
```

1. `sys.path` es la lista de carpetas donde Python busca módulos. Se agrega `RUTA_CODIGO` al principio para que
   `import wc_predictor` encuentre el archivo; el `if` evita agregarla dos veces.
2. `with A, B:` abre **dos** contextos a la vez: el cambio de carpeta y `redirect_stdout(io.StringIO())`, que manda
   todo lo que se imprima a un texto en memoria que nadie lee.
3. `import wc_predictor` ejecuta el módulo completo: define sus funciones y corre su código suelto, que lee
   `E0_consolidado.csv` con ruta relativa ([cap. 10, 10.6](10_codigo_wc_predictor.md#106-el-bloque-que-se-ejecuta-al-importar)).
4. La función devuelve el módulo y la línea 68 lo guarda en la variable global `wc_predictor`. Desde `index.qmd` se
   alcanza como `dd.wc_predictor` (así lee `ELO_INIT`).
5. Python guarda los módulos importados en `sys.modules`: un segundo `import` no vuelve a ejecutar el archivo.

**Comprobaciones (2-oct-2026):**

| Prueba | Resultado |
|---|---|
| Importar `wc_predictor` desde su carpeta | No imprime nada (salida vacía) |
| Importarlo desde `Dashboard-o-pagina` sin cambiar de carpeta | Falla: `FileNotFoundError: [Errno 2] No such file or directory: 'E0_consolidado.csv'` |
| Importar `datos_dashboard` | ≈ 2.1–2.4 s; al terminar, la carpeta de trabajo es otra vez `Dashboard-o-pagina` |

> **Comentario desactualizado.** El docstring dice que el módulo "imprime el ranking Elo". Eso era cierto en la
> versión inicial de `wc_predictor.py` (22-sep); Daniel quitó ese bloque el 30-sep. Hoy `redirect_stdout` no
> silencia nada: es sólo precaución. Lo que sigue siendo **indispensable** es el cambio de carpeta.
> **Si preguntan:** "El comentario quedó de la versión anterior del módulo; el silencio ya no hace falta, pero el
> cambio de carpeta sí, porque el módulo lee el CSV con ruta relativa."

**En R (ilustrativo):** si el módulo fuera un script de R, `source()` ya trae las dos cosas:

```r
invisible(capture.output(source(file.path(ruta_codigo, "wc_predictor.R"), chdir = TRUE)))
# chdir = TRUE: cambia a la carpeta del script mientras se ejecuta (≈ _en_directorio)
# capture.output(): se queda con lo que se imprima (≈ redirect_stdout)
# Con reticulate se puede importar el propio módulo de Python desde R:
# wc <- withr::with_dir(ruta_codigo, reticulate::import_from_path("wc_predictor", path = ruta_codigo)); wc$ELO_K
```

> **Decisión:** importar `wc_predictor.py` sin modificarlo, desde su carpeta y con la salida silenciada.
> **Alternativas:** (a) **corregir el módulo** para que no lea el CSV al importarse — lo ideal, pero era código del
> equipo de Código y el tablero no debía cambiarlo; (b) **copiar el módulo** a la carpeta del tablero — dos versiones
> que pueden divergir (justo lo que pasó con K y k durante el proyecto); (c) **reescribir** Elo y promedios en el
> tablero — una tercera implementación del mismo cálculo.
> **Por qué ésta:** usa exactamente el archivo que usa el notebook; si Daniel lo cambia (como pasó con K = 15 y
> k = 0), el tablero lo hereda sin tocar nada.
> **Evidencia en el proyecto:** el cambio de K = 30 a K = 15 llegó al tablero leyendo `wc_predictor.ELO_K`.
> **Si preguntan:** "Importamos el módulo del equipo tal cual; como al importarse lee el CSV con ruta relativa, lo
> importamos parados en su carpeta y luego regresamos."

### 13a.1.5 `_notebook()` y `lru_cache`

Líneas 71–73:

```python
@lru_cache(maxsize=None)
def _notebook() -> dict:
    return json.loads(ARCHIVO_NOTEBOOK.read_text(encoding="utf-8"))
```

- Un `.ipynb` es un archivo **JSON**: `read_text` lo lee como texto y `json.loads` lo convierte en un diccionario
  con una lista `cells`. Cada celda tiene `cell_type` (`"code"` o `"markdown"`), `source` (su código, como lista
  de líneas) y, si es de código, `outputs` (lo que imprimió la última vez que se ejecutó). El notebook tiene 26
  celdas.
- `@lru_cache(maxsize=None)` es **memorización**: la primera llamada ejecuta la función y guarda el resultado; las
  siguientes devuelven lo guardado sin volver a calcular. `maxsize=None` quiere decir "sin límite de entradas" (aquí
  sólo hay una, porque la función no recibe argumentos). Desde Python 3.9, `functools.cache` es lo mismo.

**Dónde se usa `lru_cache` en el archivo:** en `_notebook`, `configuracion_notebook`, `cifras_publicadas_notebook`,
`cargar_historico`, `cargar_base_modelacion`, `modelos_entrenados`, `probabilidades_por_conjunto`,
`tabla_bootstrap` y `preparar_todo`. Contadores reales tras un `preparar_todo()` (`funcion.cache_info()`):

| Función | Cálculos | Llamadas servidas desde la caché |
|---|---|---|
| `cargar_historico` | 1 | 10 |
| `cargar_base_modelacion` | 1 | 8 |
| `probabilidades_por_conjunto` | 1 | 7 (la primera llamada tarda 0.26 s; las siguientes ≈ 1 µs) |
| `modelos_entrenados` | 1 | 3 |
| `configuracion_notebook` | 1 | 2 (las líneas 145 y 146 la llaman al importar) |

Dos cuidados que el código respeta:

1. La caché devuelve **el mismo objeto** cada vez. Si una función modificara la tabla que recibe de
   `cargar_historico()`, modificaría la copia guardada para todas las demás. Por eso las funciones que agregan
   columnas trabajan sobre copias: `particiones()` usa `.copy()`, `resultado_por_elo()` hace
   `cargar_base_modelacion().copy()`, y las demás filtran (lo que crea una tabla nueva).
2. La caché vive mientras vive el proceso de Python. Cada `quarto render` arranca un proceso nuevo, así que nunca se
   muestran datos viejos de una ejecución anterior.

**En R (ilustrativo):**

```r
leer_notebook <- memoise::memoise(function() jsonlite::fromJSON(archivo_notebook, simplifyVector = FALSE))
nb <- leer_notebook()   # la primera vez lee el archivo; las siguientes devuelven lo guardado
```

> **Decisión:** memorizar con `@lru_cache` las funciones caras o que se llaman varias veces.
> **Alternativas:** (a) calcular todo una vez en el chunk de preparación y pasar los resultados como argumentos — sin
> caché, pero cada función tendría que recibir varias tablas; (b) guardar resultados en disco (`pickle`, `.rds`) —
> rápido entre ejecuciones, pero se pueden quedar viejos; (c) no memorizar — `probabilidades_por_conjunto` y los
> CSV se recalcularían en cada uso.
> **Por qué ésta:** cada función se puede llamar sola (por ejemplo desde una terminal, para revisar una cifra) y aun
> así el tablero completo calcula cada cosa una sola vez.
> **Evidencia en el proyecto:** 10 lecturas del histórico servidas desde la caché; una segunda llamada a
> `preparar_todo()` tarda menos de un microsegundo.
> **Si preguntan:** "`lru_cache` guarda el resultado de la primera llamada; en R sería `memoise`. Así cada CSV se lee
> una vez y los modelos se ajustan una vez, aunque varias tarjetas los usen."

### 13a.1.6 `configuracion_notebook()`

Líneas 76–107 (completa, sin el docstring):

```python
@lru_cache(maxsize=None)
def configuracion_notebook() -> dict:
    codigo = "\n".join("".join(c["source"]) for c in _notebook()["cells"] if c["cell_type"] == "code")
    defectos = inspect.signature(wc_predictor.recent_form).parameters

    def numero(nombre, defecto):
        m = re.search(rf"^{nombre}\s*=\s*([\d.]+)", codigo, flags=re.M)
        return float(m.group(1)) if m else defecto

    def rejilla(nombre):
        # El notebook conserva comentada la rejilla completa que se probó y deja activa sólo
        # la combinación elegida; se toma la lista más larga.
        listas = [[float(x) for x in m.split(",") if x.strip()]
                  for m in re.findall(rf"{nombre}\s*=\s*\[([^\]]*)\]", codigo)]
        return max(listas, key=len) if listas else []

    bloque = re.search(r"FOLDS_HIPERPARAMETROS\s*=\s*\[(.*?)\n\]", codigo, flags=re.S)
    anios = [int(a) for a in re.findall(r'Timestamp\("(\d{4})-\d{2}-\d{2}"\)', bloque.group(1))] if bloque else []
    return {
        "n_forma": int(numero("N_FORMA", defectos["n"].default)),
        "decay_forma": numero("DECAY_FORMA", defectos["decay"].default),
        "rejilla_k_elo": rejilla("K_ELO_CANDIDATOS"),
        "rejilla_k_shrinkage": rejilla("K_SHRINKAGE_CANDIDATOS"),
        # Cada pliegue es (inicio, fin); la temporada evaluada es la del inicio.
        "folds": [f"{a}/{str(a + 1)[-2:]}" for a in anios[0::2]],
    }
```

**Qué hace, bloque por bloque:**

1. **Junta el código** de todas las celdas de código en un solo texto (`"".join` une las líneas de una celda;
   `"\n".join` une las celdas). No ejecuta nada: sólo **lee** el código como texto.
2. **Valores de respaldo:** `inspect.signature(wc_predictor.recent_form).parameters` describe los argumentos de
   `recent_form(df, team, n=10, decay=0.85)`; `defectos["n"].default` es 10 y `defectos["decay"].default` es 0.85.
   Se usan sólo si el notebook no tuviera la línea buscada.
3. **`numero(nombre, defecto)`** busca una línea que **empiece** con el nombre: `^N_FORMA\s*=\s*([\d.]+)`.
   - `^` con `re.M` (multilínea) significa "inicio de línea": una línea comentada (`#N_FORMA = 12`) o sangrada no
     cuenta.
   - `\s*` acepta espacios (o ninguno) alrededor del `=`.
   - `([\d.]+)` captura dígitos y puntos (`10`, `0.85`); `m.group(1)` es lo capturado.
4. **`rejilla(nombre)`** busca **todas** las asignaciones `K_ELO_CANDIDATOS = [ … ]`, sin `^`, así que también
   encuentra las **comentadas**. `[^\]]*` captura todo hasta el corchete de cierre; `split(",")` separa los
   números. De las listas encontradas se queda con la **más larga** (`max(listas, key=len)`): la rejilla completa
   que se probó, no la combinación que quedó activa.
5. **Pliegues:** `FOLDS_HIPERPARAMETROS\s*=\s*\[(.*?)\n\]` con `re.S` (el punto también acepta saltos de línea)
   captura todo el bloque hasta la línea que empieza con `]`; `.*?` es "lo menos posible". Dentro, cada
   `Timestamp("2021-08-01")` aporta un año.
6. **Resultado:** la ventana como entero, el decaimiento, las dos rejillas y las etiquetas de las temporadas
   evaluadas. Cada pliegue es (inicio, fin), así que los años salen de dos en dos y `anios[0::2]` toma uno sí y uno
   no (los inicios).

**Lo que encuentra en el notebook entregado (celda 2):**

| Busca | Líneas que coinciden | Resultado |
|---|---|---|
| `N_FORMA` | `N_FORMA = 10` | 10 |
| `DECAY_FORMA` | `DECAY_FORMA = 0.85` | 0.85 |
| `K_ELO_CANDIDATOS` | `#K_ELO_CANDIDATOS = [15, 20, 25, 30, 35, 40, 45]` y `K_ELO_CANDIDATOS = [15]` | la primera (7 valores) |
| `K_SHRINKAGE_CANDIDATOS` | `#K_SHRINKAGE_CANDIDATOS = [0, 5, 10, 15, 20]` y `K_SHRINKAGE_CANDIDATOS = [0]` | la primera (5 valores) |
| `FOLDS_HIPERPARAMETROS` | 3 tuplas con 6 fechas | años 2021, 2022, 2022, 2023, 2023, 2024 → inicios 2021, 2022, 2023 |

**Salida real:**

```text
{'n_forma': 10, 'decay_forma': 0.85, 'rejilla_k_elo': [15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0],
 'rejilla_k_shrinkage': [0.0, 5.0, 10.0, 15.0, 20.0], 'folds': ['2021/22', '2022/23', '2023/24']}
```

**Quién lo usa:** las líneas 145–146 (`N_FORMA`, `DECAY_FORMA`) y, en `index.qmd`, las tarjetas "Evaluación"
("se evalúa en 2021/22, 2022/23 y 2023/24… Se probaron K de 15 a 45 y k de 0 a 20") y "Limitaciones y
extensiones" (el aviso de que K quedó en el **borde inferior** de la rejilla sale de comparar `K_ELO` con el mínimo
de la rejilla).

**Casos límite (probados con copias modificadas del notebook):**

| Cambio en el notebook | Lo que devuelve | Consecuencia |
|---|---|---|
| `N_FORMA = 12` | 12 | El texto del tablero diría 12 (aunque la base de modelación no cambia hasta que el notebook la vuelva a exportar) |
| Se borra la línea `N_FORMA = …` | 10 (respaldo de `recent_form`) | Sigue funcionando |
| Se borra la rejilla **comentada** | `[15.0]` | El texto diría "K de 15 a 15" y que K quedó "en el borde": engañoso |
| Comillas simples en los pliegues (`Timestamp('2021-08-01')`) | `[]` | `index.qmd` fallaría al armar la lista de temporadas (el render se detiene) |

**En R (verificado: mismo resultado que Python):**

```r
configuracion_notebook <- function(nb, n_defecto = 10, decay_defecto = 0.85) {   # ≈ formals(recent_form)
  codigo <- nb$cells |> keep(~ .x$cell_type == "code") |>
    map_chr(~ paste(unlist(.x$source), collapse = "")) |> paste(collapse = "\n")
  numero <- function(nombre, defecto) {
    m <- str_match(codigo, regex(paste0("^", nombre, "\\s*=\\s*([\\d.]+)"), multiline = TRUE))[1, 2]
    if (is.na(m)) defecto else as.numeric(m)
  }
  rejilla <- function(nombre) {                  # todas las asignaciones, también las comentadas
    textos <- str_match_all(codigo, paste0(nombre, "\\s*=\\s*\\[([^\\]]*)\\]"))[[1]][, 2]
    listas <- map(str_split(textos, ","), ~ as.numeric(str_trim(.x[str_trim(.x) != ""])))
    if (length(listas) == 0) numeric(0) else listas[[which.max(lengths(listas))]]   # la más larga
  }
  bloque <- str_match(codigo, regex("FOLDS_HIPERPARAMETROS\\s*=\\s*\\[(.*?)\\n\\]", dotall = TRUE))[1, 2]
  anios <- as.integer(str_match_all(bloque, 'Timestamp\\("(\\d{4})-\\d{2}-\\d{2}"\\)')[[1]][, 2])
  inicio <- anios[c(TRUE, FALSE)]                # ≈ anios[0::2]
  list(n_forma = numero("N_FORMA", n_defecto), decay_forma = numero("DECAY_FORMA", decay_defecto),
       rejilla_k_elo = rejilla("K_ELO_CANDIDATOS"), rejilla_k_shrinkage = rejilla("K_SHRINKAGE_CANDIDATOS"),
       folds = sprintf("%d/%s", inicio, substr(inicio + 1, 3, 4)))
}
nb <- jsonlite::fromJSON(file.path(ruta_codigo, "Analisis.ipynb"), simplifyVector = FALSE)
str(configuracion_notebook(nb))   # 10 · 0.85 · 15…45 · 0…20 · "2021/22" "2022/23" "2023/24"
```

(Usa `stringr` y `purrr`.) `regex(..., multiline = TRUE)` es `re.M`; `dotall = TRUE` es `re.S`;
`which.max(lengths(listas))` es `max(listas, key=len)` (las dos devuelven la primera si hay empate);
`anios[c(TRUE, FALSE)]` recicla el vector lógico y toma uno sí y uno no.

> **Decisión:** leer del **código** del notebook la ventana, el decaimiento, las rejillas y los pliegues, con
> expresiones regulares.
> **Alternativas:** (a) **duplicarlos a mano** en el tablero — simple, pero es como estaba antes del 30-sep
> (`K_SHRINKAGE = 10` escrito a mano) y se desincroniza; (b) **ejecutar la celda 2** del notebook — también
> importaría librerías y correría código ajeno; (c) **moverlos a `wc_predictor.py`** o a un archivo de
> configuración (YAML/JSON) que lean los dos — lo más limpio, pero obligaba a reorganizar el notebook del equipo;
> (d) leerlos de las **salidas** — el notebook no los imprime.
> **Por qué ésta:** el notebook sigue siendo la única fuente; el tablero describe siempre la configuración vigente
> (si cambia la rejilla, cambia el texto) y no hay que tocar el código del equipo.
> **Evidencia en el proyecto:** devuelve exactamente lo que dice la celda 2 (tabla de arriba), y el texto del
> tablero sobre la calibración no tiene ningún valor escrito a mano.
> **Riesgos:** depende de la forma del texto: si alguien borra la rejilla comentada o cambia las comillas, el texto
> sería engañoso o el render fallaría (tabla de casos límite).
> **Si preguntan:** "El tablero lee los parámetros directamente del código del notebook, con expresiones
> regulares; así, si el equipo cambia la rejilla o la ventana, el texto del tablero cambia solo."

### 13a.1.7 `cifras_publicadas_notebook()`

Líneas 110–133 (sin el docstring):

```python
@lru_cache(maxsize=None)
def cifras_publicadas_notebook() -> dict:
    logloss, ejemplo, conjunto = {}, {}, None
    for celda in _notebook()["cells"]:
        for salida in celda.get("outputs", []):
            texto = "".join(salida.get("text", "")) or "".join(salida.get("data", {}).get("text/plain", ""))
            if re.search(r"^Validación: \d+/\d+ con cuotas", texto, flags=re.M):
                conjunto = "Validación"
            elif re.search(r"^Cuotas válidas en prueba", texto, flags=re.M):
                conjunto = "Prueba"
            elif conjunto and "LogLoss_1X2" in texto:
                for nombre, valor in re.findall(r"^\s*\d+\s+(\S+)\s+\d+\s+([\d.]+)\s*$", texto, flags=re.M):
                    logloss[(conjunto, nombre)] = float(valor)
                conjunto = None
            for clave, valor in re.findall(r"^(lambda_home|lambda_away|P_home|P_draw|P_away)\s*:\s*([\d.]+)",
                                           texto, flags=re.M):
                ejemplo[clave] = float(valor)
    return {"logloss": logloss, "ejemplo": ejemplo}
```

**Qué hace:** recorre las **salidas guardadas** de todas las celdas (lo que el notebook imprimió la última vez que
se ejecutó y se guardó) y extrae dos cosas.

1. **El texto de cada salida.** Un `print()` se guarda como salida de tipo *stream* con campo `text`; un
   `display(tabla)` se guarda como *display_data* con la tabla en texto en `data["text/plain"]`. La expresión
   `a or b` usa la segunda si la primera está vacía.
2. **Una pequeña máquina de estados** con la variable `conjunto`:
   - si una salida contiene la línea `Validación: 380/380 con cuotas…` (celda 20), anota "Validación";
   - si contiene `Cuotas válidas en prueba…` (celda 22), anota "Prueba";
   - la **siguiente** salida que traiga una tabla con `LogLoss_1X2` es la comparación con el mercado: de cada renglón
     `0  Mercado_apertura   380   0.970552` saca el nombre y el LogLoss (`(\S+)` = una palabra sin espacios;
     `\d+` = la columna de partidos; `([\d.]+)` = el LogLoss; `\s*$` = fin de renglón), y vuelve a `None`.
3. **El ejemplo Arsenal–Man City** (celda 24): en cualquier salida, los renglones `lambda_home : 1.5375…`,
   `P_home : 0.4364…`, etc.

**Por qué funciona con este notebook (detalles finos):**

- La celda 11 también imprime un renglón que empieza con "Validación:" (`Validación: 380 partidos, 2024-08-16 a
  2025-05-25`). No se confunde porque la expresión exige la forma `380/380 con cuotas`.
- La celda 22 muestra **dos** tablas con `LogLoss_1X2`: la de las cinco especificaciones (con MAE) y, después del
  renglón "Cuotas válidas en prueba", la del mercado. La primera se ignora porque cuando aparece `conjunto` todavía
  es `None`; además, sus renglones tienen más columnas y no coincidirían con la expresión. La celda 16 (validación,
  con MAE) se ignora por lo mismo.

**Salida real** (12 + 5 cifras):

```text
logloss: (Validación, Mercado_apertura) 0.970552 · M4_Completo 0.978612 · M2_Tiros 0.980718 · M3_SOT 0.982319
         · M1_Forma 0.987603 · M0_Base 0.989547
         (Prueba, Mercado_apertura) 1.02 · M0_Base 1.033076 · M3_SOT 1.033868 · M1_Forma 1.034699
         · M4_Completo 1.036739 · M2_Tiros 1.037331
ejemplo: lambda_home 1.5375969468793136 · lambda_away 1.2656117048285258 · P_home 0.4364619580907665
         · P_draw 0.2500002700356388 · P_away 0.31353777187359494
```

Los LogLoss vienen con 6 decimales (así los imprimió el notebook, `round(6)`); el ejemplo, con todos los decimales.

**¿Qué pasa si el notebook se guarda sin salidas?** (probado vaciando las salidas en una copia) Los dos
diccionarios quedan vacíos, la tabla de verificación muestra una sola fila, "Cifras publicadas en Analisis.ipynb ·
no encontradas · ✗", y el texto de la pestaña *Reproducibilidad* cambia a "HAY DIFERENCIAS: revisar antes de
publicar". El tablero **se publica de todos modos**: avisa, no detiene.

**Limitación que conviene conocer** (probada): si sólo se pierde la salida de **una** celda —por ejemplo la 22—, la
verificación compara las 11 cifras que sí encuentra, todas salen ✓ y **no avisa** que faltan 6. La comparación es
contra lo que encuentra, no contra una lista fija de 17.

**En R (verificado: las mismas 12 + 5 cifras):**

```r
cifras_publicadas_notebook <- function(nb) {
  logloss <- c(); ejemplo <- c(); conjunto <- NA_character_
  for (celda in nb$cells) for (s in celda$outputs) {
    texto <- paste(unlist(s$text), collapse = "")                                    # print()
    if (texto == "") texto <- paste(unlist(s$data[["text/plain"]]), collapse = "")   # display()
    if (str_detect(texto, regex("^Validación: \\d+/\\d+ con cuotas", multiline = TRUE))) {
      conjunto <- "Validación"
    } else if (str_detect(texto, regex("^Cuotas válidas en prueba", multiline = TRUE))) {
      conjunto <- "Prueba"
    } else if (!is.na(conjunto) && str_detect(texto, fixed("LogLoss_1X2"))) {
      filas <- str_match_all(texto, regex("^\\s*\\d+\\s+(\\S+)\\s+\\d+\\s+([\\d.]+)\\s*$", multiline = TRUE))[[1]]
      logloss[paste(conjunto, filas[, 2], sep = "|")] <- as.numeric(filas[, 3])
      conjunto <- NA_character_
    }
    ej <- str_match_all(texto, regex("^(lambda_home|lambda_away|P_home|P_draw|P_away)\\s*:\\s*([\\d.]+)",
                                     multiline = TRUE))[[1]]
    ejemplo[ej[, 2]] <- as.numeric(ej[, 3])
  }
  list(logloss = logloss, ejemplo = ejemplo)
}
```

La decisión de verificar contra las salidas guardadas se discute en [13a.7.6](#13a76-tabla_verificacion).

### 13a.1.8 Fechas de corte

Líneas 136–138:

```python
FECHA_INICIO = pd.Timestamp("2019-08-01")
FECHA_VALIDACION = pd.Timestamp("2024-08-01")
FECHA_PRUEBA = pd.Timestamp("2025-08-01")
```

Son las mismas de la §1 del notebook ([11.1.2](11_codigo_analisis_notebook.md#1112-fechas-de-corte)): entrenamiento
`Date < 2024-08-01`, validación `[2024-08-01, 2025-08-01)`, prueba `≥ 2025-08-01`. Aquí **sí** están copiadas a
mano (no se leen del notebook). `FECHA_VALIDACION` y `FECHA_PRUEBA` las usa `particiones()`; `FECHA_INICIO`, sólo
`partidos_excluidos()` (la base de modelación ya viene filtrada desde agosto de 2019). Si el equipo cambiara un
corte, los LogLoss del tablero dejarían de coincidir con los del notebook y la verificación lo marcaría con ✗.
En R (ilustrativo): `FECHA_PRUEBA <- as.Date("2025-08-01")`.

### 13a.1.9 Parámetros: `K_ELO`, `K_SHRINKAGE`, `N_FORMA`, `DECAY_FORMA` y `ESCALA_ELO`

Líneas 140–147:

```python
# K del Elo y k del shrinkage: los calibró el equipo (Analisis.ipynb, sección 5) y viven en
# wc_predictor.py. Se leen de ahí para que el tablero use siempre los mismos valores que el notebook.
K_ELO = wc_predictor.ELO_K
K_SHRINKAGE = wc_predictor.SHRINKAGE_K
# Ventana y decaimiento de la forma reciente: los fija el notebook (sección 1).
N_FORMA = configuracion_notebook()["n_forma"]
DECAY_FORMA = configuracion_notebook()["decay_forma"]
ESCALA_ELO = wc_predictor.ELO_SCALE
```

| Constante | Valor | De dónde sale | Dónde se usa en el backend | Dónde aparece en el tablero |
|---|---|---|---|---|
| `K_ELO` | 15 | `wc_predictor.ELO_K` (calibrado, notebook §5) | `datos_simulador` (`build_elo`) | "Variables del modelo", "Evaluación", aviso de borde en "Limitaciones y extensiones" |
| `K_SHRINKAGE` | 0 | `wc_predictor.SHRINKAGE_K` (calibrado) | `crear_variables_partido`, estadísticas del simulador | "Variables del modelo" ("k = 0, es decir, sin mezcla"), "Evaluación", texto del simulador |
| `N_FORMA` | 10 | código del notebook (§1) | `crear_variables_partido` | "Variables del modelo", "Limitaciones y extensiones" |
| `DECAY_FORMA` | 0.85 | código del notebook (§1) | `crear_variables_partido` | "Variables del modelo", "Limitaciones y extensiones" |
| `ESCALA_ELO` | 400 | `wc_predictor.ELO_SCALE` | `preparar_X` (divide `elo_diff`), simulador | "Variables del modelo" |

Dos detalles:

- **Los modelos no usan K ni k directamente:** la base de modelación ya viene construida (por el notebook) con K = 15
  y k = 0. En el backend, K sólo interviene en el simulador, que sí calcula el Elo al corte.
- **Coherencia entre módulo y notebook.** El notebook sobrescribe `K_ELO` con el ganador de su calibración; el
  tablero lo toma del módulo. Hoy coinciden (15 y 0). Si alguien activara la rejilla completa, ganara otra
  combinación y no actualizara `wc_predictor.py`, el ejemplo Arsenal–City del simulador dejaría de coincidir con el
  del notebook y la verificación lo marcaría ([cap. 10, 10.3](10_codigo_wc_predictor.md#103-importaciones-y-constantes)).

En R (ilustrativo): `K_ELO <- 15; K_SHRINKAGE <- 0; N_FORMA <- cfg$n_forma; DECAY_FORMA <- cfg$decay_forma;
ESCALA_ELO <- 400`, o con `reticulate`, `K_ELO <- wc$ELO_K`.

### 13a.1.10 Nombres de columnas

Líneas 149–153:

```python
CLAVES = ["Date", "HomeTeam", "AwayTeam"]      # identifican un partido
OBJETIVOS = ["home_goals", "away_goals"]       # lo que se predice
CUOTAS = ["AvgH", "AvgD", "AvgA"]              # cuotas promedio de apertura
CUOTAS_CIERRE = ["AvgCH", "AvgCD", "AvgCA"]    # cuotas promedio de cierre (sólo el tablero)
PROBS = ["P_home", "P_draw", "P_away"]         # probabilidades 1X2
```

Iguales a las del notebook ([11.1.5](11_codigo_analisis_notebook.md#1115-nombres-de-archivo-y-de-columnas)), más
`CUOTAS_CIERRE`, que sólo usa el tablero para agregar el mercado de cierre como referencia adicional (los
comentarios de la derecha son de esta guía). Escribir los nombres una vez evita errores de dedo. En R:
`CLAVES <- c("Date", "HomeTeam", "AwayTeam")`, etc.

### 13a.1.11 `GRUPOS` y `ESPECIFICACIONES`

Líneas 155–184: **idénticas** a las de la §1 del notebook (se explican con su equivalente en R, verificado, en
[11.1.6](11_codigo_analisis_notebook.md#1116-grupos-y-especificaciones-los-cinco-modelos)). Ocho bloques de variables
(`base_home`, `forma_home`, `tiros_home`, `sot_home` y sus pares `_away`) y cinco especificaciones como tuplas
(columnas del local, columnas del visitante): M0 con 3 variables por ecuación, M1–M3 con 5 y M4 con 9.

- No se leen del notebook: están copiadas. Si el equipo cambiara una especificación, los LogLoss dejarían de
  coincidir y la verificación lo marcaría.
- `index.qmd` cuenta sus variables: `len(dd.ESPECIFICACIONES["M0_Base"][0])` = 3 (tarjetas "Resumen" y "Variables
  del modelo") y la de M4 = 9 ("Variables del modelo").

### 13a.1.12 `MODELO_SIMULADOR`, `NOMBRES`, `SEMILLA` y `N_BOOTSTRAP`

Líneas 186–202:

```python
# Modelo que usa el simulador: el mejor en prueba y el más parsimonioso (3 variables por ecuación).
MODELO_SIMULADOR = "M0_Base"

NOMBRES = {
    "Uniforme": "Azar · 1/3 por resultado",
    "Ingenua": "Referencia ingenua",
    "M0_Base": "M0 · Base",
    ...                                         # M1–M4 y mercado de apertura
    "Mercado_cierre": "Mercado · Cierre",
}

SEMILLA = 2026
N_BOOTSTRAP = 10_000
```

- `MODELO_SIMULADOR`: el simulador usa M0. El comentario da la razón ("el mejor en prueba y el más parsimonioso");
  ojo: "el mejor en prueba" usa información de prueba para elegir, como se reconoce en el
  [capítulo 9](09_evaluacion_y_validacion.md). La parsimonia (3 variables contra 9) es razón suficiente por sí
  sola.
- `NOMBRES`: las etiquetas en español de los 9 predictores (Max las acortó el 24-sep). El **orden** del
  diccionario importa: `tabla_verificacion()` lo usa para ordenar sus filas.
- `SEMILLA = 2026`: el año del proyecto; cualquier número fijo sirve. Lo importante es que sea fijo: con la misma
  semilla, el bootstrap da exactamente los mismos intervalos en cada render.
- `N_BOOTSTRAP = 10_000`: el guion bajo es sólo un separador de miles permitido en los números de Python
  (`10_000 == 10000`). El número de remuestreos se discute en [13a.5.6](#13a56-_bootstrap-y-tabla_bootstrap).

En R (ilustrativo): `NOMBRES <- c(Uniforme = "Azar · 1/3 por resultado", …)` (vector con nombres);
`SEMILLA <- 2026; N_BOOTSTRAP <- 10000`.

---

## 13a.2 Sección 2: funciones reproducidas del notebook (líneas 205–308)

El encabezado del archivo dice "Funciones de Analisis.ipynb (secciones 2 y 4), misma lógica"; la última,
`probabilidades_mercado`, corresponde a la §8. Estas ocho funciones **viven dentro del notebook** y Python no puede
importar funciones de un `.ipynb` como de un módulo, así que el tablero las **copia**. La lógica estadística de cada
una ya está explicada a fondo, con su equivalente en R **verificado**, en el [capítulo 11](11_codigo_analisis_notebook.md);
aquí se explica cada copia, con un ejemplo real del tablero, y **en qué difiere** del original.

**Diferencias entre la copia y el original** (revisadas línea por línea):

| Función | En el notebook | En el tablero | ¿Cambia algún resultado? |
|---|---|---|---|
| `crear_variables_partido` | Recibe además `k_shrinkage` e `incluir_forma` (la calibración los usa para probar otros k y omitir la forma) | Sin esos dos parámetros: siempre `K_SHRINKAGE` y siempre con forma | No: el tablero no calibra |
| `preparar_X`, `entrenar_modelo`, `probabilidades_1x2`, `resultados_observados` | — | Idénticas | — |
| `predecir_con_modelo` | Revisa que las λ sean finitas; agrega los goles reales sólo si están **las dos** columnas | No hace esa revisión (pero `probabilidades_1x2` sí exige probabilidades finitas, así que un λ inválido también detiene todo); agrega las columnas de goles **que existan** | No |
| `evaluar_predicciones` | Devuelve también `Partidos` | Sin `Partidos` | No |
| `probabilidades_mercado` | Son dos funciones, `cargar_cuotas` y `comparar_con_mercado`: leen las cuotas aparte, revisan duplicados, **filtran** cuotas no finitas o ≤ 1 y devuelven una tabla de LogLoss | Una función que cruza con el histórico ya cargado (con `validate="one_to_one"`), **no filtra** y devuelve la matriz de probabilidades y el margen | No en este proyecto: los 380 + 419 partidos tienen cuotas válidas. Si faltara una cuota, el tablero no excluiría el partido: `log_loss` se detendría con `ValueError: Input contains NaN` (comprobado) |

La prueba de que las copias son fieles es la verificación: 12 LogLoss calculados con estas funciones coinciden con los
del notebook hasta la sexta cifra decimal ([13a.7.6](#13a76-tabla_verificacion)).

### 13a.2.1 `crear_variables_partido`

Líneas 206–232 (resumidas):

```python
def crear_variables_partido(df_pre, fecha, home, away, elo_home, elo_away):
    """Predictores construidos sólo con partidos anteriores a `fecha` (notebook §2)."""
    fecha = pd.Timestamp(fecha)
    if not (df_pre["date"] < fecha).all():
        raise ValueError("df_pre contiene información de la fecha objetivo o posterior")
    stats_h = wc_predictor.season_stats(df_pre, home, fecha, k=K_SHRINKAGE)
    stats_a = wc_predictor.season_stats(df_pre, away, fecha, k=K_SHRINKAGE)
    form_h = wc_predictor.recent_form(df_pre, home, n=N_FORMA, decay=DECAY_FORMA)
    form_a = wc_predictor.recent_form(df_pre, away, n=N_FORMA, decay=DECAY_FORMA)
    return {"elo_home": elo_home, "elo_away": elo_away, "elo_diff": elo_home - elo_away,
            "gf_home": stats_h["gf_avg"], "ga_home": stats_h["ga_avg"], ...    # 19 variables en total
            "sot_against_away": form_a["sot_against"]}
```

- **Guardia contra la fuga de información:** si `df_pre` trae un solo partido del mismo día o posterior, se detiene.
  Comprobado: con el histórico completo y una fecha un mes antes del corte responde *"df_pre contiene información de
  la fecha objetivo o posterior"*.
- Usa las funciones de `wc_predictor` con los parámetros leídos en la sección 1 (k = 0, ventana 10, decaimiento 0.85).
- Devuelve un diccionario con las **19 variables**: dos Elo y su diferencia, cuatro promedios de goles de la temporada
  y doce de forma reciente (goles, tiros y tiros a puerta, a favor y en contra, de cada equipo).
- **En el tablero sólo la usa el simulador** ([13a.6](#13a6-sección-6-simulador-líneas-697744)); los modelos se
  entrenan con la base que ya construyó el notebook.

**Ejemplo real** (Arsenal–Man City con corte 15-sep-2026, el del simulador): `elo_home` 1787.124685, `elo_away`
1779.186208, `elo_diff` 7.938477; `gf_home` 2.00, `ga_home` 0.25 (Arsenal en 4 partidos de 2026/27), `gf_away` 2.00,
`ga_away` 0.50 (City); `form_gf_home` 1.792169, `shots_for_home` 13.651387, `sot_for_home` 5.405789, …

**En R:** el de [11.2.1](11_codigo_analisis_notebook.md#1121-crear_variables_partido) (verificado allá), sin los
argumentos `k_shrinkage` e `incluir_forma`.

### 13a.2.2 `preparar_X`

Líneas 235–242, idéntica al notebook ([11.4.1](11_codigo_analisis_notebook.md#1141-preparar_x)):

```python
def preparar_X(datos, columnas, modelo=None):
    X = datos.loc[:, columnas].copy().astype(float)
    X["elo_diff"] = X["elo_diff"] / ESCALA_ELO
    X = sm.add_constant(X, has_constant="add")
    if modelo is not None:
        X = X.loc[:, modelo.model.exog_names]
    return X
```

Toma las columnas de la especificación, divide la diferencia de Elo entre 400, agrega la constante (siempre, gracias
a `has_constant="add"`, indispensable cuando se predice **una sola fila**) y, al predecir, ordena las columnas como en
el entrenamiento.

**Ejemplo real** (Arsenal–Man City): ecuación del local `const 1.0 · elo_diff 0.019846 · gf_home 2.0 · ga_away 0.5`;
ecuación del visitante `const 1.0 · elo_diff 0.019846 · gf_away 2.0 · ga_home 0.25`.

En el tablero la usan `entrenar_modelo`, `predecir_con_modelo`, `efectos_estandarizados` (para medir la desviación
estándar de cada regresor) y `diagnostico_m4` (para el VIF). **En R:** `I(elo_diff / 400)` dentro de la fórmula de
`glm()` ([11.4.6](11_codigo_analisis_notebook.md#1146-evaluar_predicciones), verificado).

### 13a.2.3 `entrenar_modelo`

Líneas 245–252, idéntica al notebook ([11.4.2](11_codigo_analisis_notebook.md#1142-entrenar_modelo)): dos
`sm.GLM(..., family=sm.families.Poisson()).fit()`, una para los goles del local y otra para los del visitante, y un
diccionario con los dos ajustes y sus listas de columnas.

**Ejemplo real** (M0 en entrenamiento, 1,897 partidos): local `const 0.0433 · elo_diff 0.6283 · gf_home 0.1678 ·
ga_away 0.0778`; visitante `const 0.0264 · elo_diff −0.6854 · gf_away 0.1079 · ga_home 0.0281`. Son los mismos
coeficientes del notebook y del reporte.

La usan `modelos_entrenados()` (los cinco modelos) y `sensibilidad_sin_publico()` (M0 reentrenado). La decisión de
usar dos Poisson independientes se discute en [11.4.2](11_codigo_analisis_notebook.md#1142-entrenar_modelo).
**En R:** `glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away, family = poisson, data = train)` (verificado en
[`02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R)).

### 13a.2.4 `probabilidades_1x2`

Líneas 255–265, idéntica al notebook ([11.4.3](11_codigo_analisis_notebook.md#1143-probabilidades_1x2)):
`skellam.sf(0, λl, λv)` = P(gana local), `skellam.pmf(0, …)` = P(empate), `skellam.cdf(-1, …)` = P(gana visita), con
el control de que todo sea finito y cada fila sume 1.

**Ejemplos reales:** λ = (1.5, 1.2) → 0.441465 / 0.254817 / 0.303718. Con vectores, una fila por partido:
λ = (1.5375969, 1.2656117) → 0.436462 / 0.250000 / 0.313538 (Arsenal–City) y λ = (2.0, 0.8) → 0.654430 / 0.204682 /
0.140888.

En el tablero la usan `predecir_con_modelo` y la **referencia ingenua** (λ constantes = goles promedio del
entrenamiento, 1.561413 y 1.311545 → 43.24 % / 24.69 % / 32.07 %). **En R:** suma de la matriz
`outer(dpois(0:15, λl), dpois(0:15, λv))` por debajo, en y por encima de la diagonal (verificado en
[11.4.6](11_codigo_analisis_notebook.md#1146-evaluar_predicciones)).

### 13a.2.5 `resultados_observados`

Líneas 268–272, idéntica al notebook ([11.4.4](11_codigo_analisis_notebook.md#1144-resultados_observados)):

```python
def resultados_observados(datos):
    gh = datos["home_goals"].to_numpy()
    ga = datos["away_goals"].to_numpy()
    return np.where(gh > ga, 0, np.where(gh == ga, 1, 2))
```

Codifica el resultado real como 0 (local), 1 (empate) o 2 (visita): el número coincide con la **columna** de la matriz
de probabilidades. La usan `evaluar_predicciones`, `probabilidades_por_conjunto` (el vector `y` de cada periodo) y
`resultado_por_elo`. **En R:** `ifelse` anidado con 1, 2, 3, porque R cuenta desde 1.

### 13a.2.6 `predecir_con_modelo`

Líneas 275–285:

```python
def predecir_con_modelo(modelo, datos):
    lh = np.asarray(modelo["home"].predict(
        preparar_X(datos, modelo["columnas_home"], modelo["home"])), dtype=float)
    la = np.asarray(modelo["away"].predict(
        preparar_X(datos, modelo["columnas_away"], modelo["away"])), dtype=float)
    resultado = datos[CLAVES + [c for c in OBJETIVOS if c in datos]].reset_index(drop=True).copy()
    resultado["lambda_home"] = lh
    resultado["lambda_away"] = la
    resultado[PROBS] = probabilidades_1x2(lh, la)
    return resultado
```

1. `predict` devuelve λ ya en escala de goles (aplica `exp` al predictor lineal).
2. La tabla de salida lleva las claves del partido y los goles reales **si existen**: `[c for c in OBJETIVOS if c in
   datos]` es una lista por comprensión que conserva sólo las columnas presentes (para un partido futuro, ninguna).
3. Agrega λ y las tres probabilidades.

**Ejemplo real** (Arsenal–Man City, corte 15-sep-2026, M0): `lambda_home` 1.537597, `lambda_away` 1.265612,
`P_home` 0.436462, `P_draw` 0.250000, `P_away` 0.313538. Son las cifras del notebook (§10) y del simulador.

La usan `probabilidades_por_conjunto` (5 modelos × 2 periodos), `sensibilidad_sin_publico` y `datos_simulador`.
**En R:** `predict(modelo$home, newdata = datos, type = "response")` ([11.4.6](11_codigo_analisis_notebook.md#1146-evaluar_predicciones), verificado).

### 13a.2.7 `evaluar_predicciones`

Líneas 288–297: MAE de goles del local y del visitante, su promedio, y LogLoss 1X2 con
`log_loss(y, P, labels=[0, 1, 2])` ([11.4.6](11_codigo_analisis_notebook.md#1146-evaluar_predicciones)). La única
diferencia con el notebook es que no devuelve el número de partidos.

**Ejemplo real** (M0 en prueba): MAE 0.954870 (local), 0.849741 (visitante), 0.902306 (promedio); LogLoss 1.033076.

En el tablero se usa para el **MAE** de `tabla_metricas` y para el LogLoss de `sensibilidad_sin_publico`; los demás
LogLoss del tablero se calculan directamente sobre las matrices de probabilidades.

### 13a.2.8 `probabilidades_mercado`

Líneas 300–308:

```python
def probabilidades_mercado(datos, historico, columnas=CUOTAS):
    """Cuotas decimales -> probabilidad implícita normalizada (notebook §8).

    q_j = 1/cuota_j ; p_j = q_j / (q_1 + q_X + q_2). La normalización reparte el
    margen de la casa de apuestas de forma proporcional.
    """
    x = datos[CLAVES].merge(historico[CLAVES + columnas], on=CLAVES, how="left", validate="one_to_one")
    brutas = 1.0 / x[columnas].to_numpy(dtype=float)
    return brutas / brutas.sum(axis=1, keepdims=True), (brutas.sum(axis=1).mean() - 1.0) * 100
```

1. **Cruce:** a cada partido del periodo le pega sus cuotas del histórico, por fecha y equipos. `how="left"` conserva
   todos los partidos del periodo; `validate="one_to_one"` detiene el programa si algún partido apareciera dos veces
   en cualquiera de las tablas.
2. **Probabilidades brutas:** `1 / cuota`. Suman más de 1 por el margen de la casa.
3. **Normalización proporcional:** cada fila entre su suma (`keepdims=True` deja la suma como columna para que la
   división sea fila por fila; en R, `brutas / rowSums(brutas)`).
4. **Devuelve dos cosas:** la matriz n × 3 de probabilidades y el **margen promedio** en porcentaje, `(Σq − 1) × 100`.
   Con `columnas=CUOTAS_CIERRE` hace lo mismo con el mercado de cierre.

**Ejemplo real** (Man United 1–0 Fulham, 16-ago-2024):

| | Local | Empate | Visita | Margen |
|---|---|---|---|---|
| Cuotas de apertura | 1.62 | 4.36 | 5.15 | |
| Probabilidad normalizada | 59.31 % | 22.04 % | 18.66 % | 4.08 % |
| Cuotas de cierre | 1.66 | 4.20 | 5.02 | |
| Probabilidad normalizada | 57.94 % | 22.90 % | 19.16 % | 3.97 % |

**Margen promedio:** apertura 4.49 % en validación y 5.84 % en prueba (los del notebook); cierre 4.19 % y 5.70 %
(calculados con esta función; el tablero no los muestra porque descarta el segundo valor, `_`).

**En R (ilustrativo):**

```r
probabilidades_mercado <- function(datos, historico, columnas = c("AvgH", "AvgD", "AvgA")) {
  x <- datos |> select(Date, HomeTeam, AwayTeam) |>
    left_join(select(historico, Date, HomeTeam, AwayTeam, all_of(columnas)),
              by = c("Date", "HomeTeam", "AwayTeam"), relationship = "one-to-one")   # ≈ validate="one_to_one"
  brutas <- 1 / as.matrix(x[, columnas])                      # q_j = 1 / cuota_j
  list(P = brutas / rowSums(brutas),                          # p_j = q_j / (q_1 + q_X + q_2)
       margen = 100 * (mean(rowSums(brutas)) - 1))
}
```

La normalización proporcional y el uso de la apertura (y no del cierre) como referencia se discuten en
[11.9.2](11_codigo_analisis_notebook.md#1192-comparar_con_mercado) y en el [capítulo 8](08_cuotas_y_mercado.md).

> **Ojo con una diferencia (no documentada como decisión):** a diferencia de `comparar_con_mercado` del notebook,
> esta función **no filtra** partidos sin cuotas válidas. En este proyecto da igual (todos las tienen). Si algún día
> faltara una cuota, el tablero **fallaría** en lugar de evaluar en silencio sobre menos partidos que el notebook,
> lo cual es el comportamiento más seguro para una comparación que debe ser "en los mismos partidos".
> **Si preguntan:** "El tablero no filtra porque los 799 partidos de validación y prueba tienen cuotas; si faltara
> alguna, el cálculo se detendría con error en vez de comparar sobre partidos distintos."

---

## 13a.3 Sección 3: carga de datos (líneas 311–341)

### 13a.3.1 `_etiqueta_temporada`

```python
def _etiqueta_temporada(anio: int) -> str:
    return f"{anio}/{str(anio + 1)[-2:]}"
```

Convierte el año de inicio en la etiqueta de la temporada: 2019 → `"2019/20"`; `str(anio + 1)[-2:]` toma los dos
últimos caracteres del año siguiente (2000 → `"00"`, así que 1999 → `"1999/00"`). La usan `resumen_temporadas`,
`resultado_del_favorito`, `auditoria_datos` y `datos_simulador`. **En R (ilustrativo):**
`sprintf("%d/%02d", anio, (anio + 1) %% 100)`.

### 13a.3.2 `cargar_historico`

Líneas 316–325:

```python
@lru_cache(maxsize=None)
def cargar_historico() -> pd.DataFrame:
    """Base consolidada del equipo (E0_consolidado.csv) con temporada y resultado."""
    df = pd.read_csv(ARCHIVO_HISTORICO)
    df["Date"] = pd.to_datetime(df["Date"], dayfirst=True, format="mixed")
    df = df.sort_values("Date", kind="stable").reset_index(drop=True)
    # La temporada va del 1 de agosto al 31 de julio, igual que en wc_predictor.season_stats.
    df["temporada"] = np.where(df["Date"].dt.month >= 8, df["Date"].dt.year, df["Date"].dt.year - 1)
    df["resultado"] = np.where(df["FTHG"] > df["FTAG"], 0, np.where(df["FTHG"] == df["FTAG"], 1, 2))
    return df
```

1. Lee el histórico **con sus nombres originales** (`HomeTeam`, `FTHG`…). `wc_predictor.load_history()` los renombra
   (`home_team`, `home_score`…); por eso el simulador, que llama funciones del módulo, usa `load_history()` y no
   esta función.
2. Convierte la fecha con la misma instrucción que `load_history()`. El CSV ya trae fechas ISO (las exportó la
   limpieza), así que `dayfirst` no cambia nada; se conserva por seguridad.
3. Ordena por fecha con un orden **estable** (`kind="stable"`: los partidos del mismo día conservan su orden
   original).
4. **`temporada`**: el año en que empezó, con corte el 1 de agosto (agosto–diciembre → ese año; enero–julio → el año
   anterior), la misma regla de `season_stats`.
5. **`resultado`**: 0 local, 1 empate, 2 visita, calculado de los goles (no de la columna `FTR`; que coincidan es una
   de las revisiones de `auditoria_datos`).

**Salida real:** 9,540 × 36 (las 34 columnas + `temporada` + `resultado`); 26 temporadas, de 2001 a 2026; 380
partidos en cada temporada completa y 40 en 2026/27.

**En R (ilustrativo):**

```r
cargar_historico <- memoise::memoise(function() {
  readr::read_csv(archivo_historico, show_col_types = FALSE) |>
    arrange(Date) |>                                                   # arrange() también es estable
    mutate(temporada = if_else(lubridate::month(Date) >= 8, lubridate::year(Date), lubridate::year(Date) - 1L),
           resultado = case_when(FTHG > FTAG ~ 1L, FTHG == FTAG ~ 2L, .default = 3L))   # en R: 1, 2, 3
})
```

### 13a.3.3 `cargar_base_modelacion`

```python
@lru_cache(maxsize=None)
def cargar_base_modelacion() -> pd.DataFrame:
    """premier_training_data.csv, la base de variables que construye el notebook (§5), exportada a CSV."""
    td = pd.read_csv(ARCHIVO_VARIABLES)
    td["Date"] = pd.to_datetime(td["Date"])
    return td.sort_values("Date", kind="stable").reset_index(drop=True)
```

Lee la **base de modelación**: 2,696 partidos × 24 columnas (claves, 2 Elo, 17 predictores, 2 goles), del 9-ago-2019
al 14-sep-2026. La construyó el notebook en la §5 con K = 15 y k = 0 y la exportó a CSV (la celda que exporta quedó
comentada en la versión entregada; ver [11.6.3](11_codigo_analisis_notebook.md#1163-celda-14-la-exportación-de-la-caché)).

> **Decisión:** el tablero lee la base ya construida (`premier_training_data.csv`) en lugar de reconstruirla.
> **Alternativas:** (a) **reconstruirla** en el tablero con la lógica de `construir_base_historica` — independiente de
> la caché, pero cada render tardaría ≈ 1 minuto más y habría que copiar otra función larga del notebook; (b) leerla
> del notebook ejecutándolo — minutos por render.
> **Por qué ésta:** es exactamente la base con la que el notebook entrenó y evaluó; leerla toma milisegundos.
> **Evidencia en el proyecto:** si la caché estuviera desactualizada respecto del notebook, los 12 LogLoss de la
> verificación no coincidirían; coinciden los 12. Además, en el [capítulo 11](11_codigo_analisis_notebook.md#1125-celda-5-la-exportación-comentada)
> se reconstruyó la base con el código del notebook y es idéntica a la caché (diferencia máxima 4.5 × 10⁻¹³).
> **Si preguntan:** "El tablero usa la base que exportó el notebook; la verificación confirma que es la misma con la
> que se obtuvieron sus resultados."

### 13a.3.4 `particiones`

```python
def particiones():
    td = cargar_base_modelacion()
    train = td.loc[td["Date"] < FECHA_VALIDACION].copy()
    val = td.loc[(td["Date"] >= FECHA_VALIDACION) & (td["Date"] < FECHA_PRUEBA)].copy()
    test = td.loc[td["Date"] >= FECHA_PRUEBA].copy()
    return train, val, test
```

La misma partición cronológica del final de la §5 del notebook: **1,897** (entrenamiento, 2019/20–2023/24), **380**
(validación, 16-ago-2024 a 25-may-2025) y **419** (prueba, 15-ago-2025 a 14-sep-2026). No tiene caché (filtrar es
instantáneo) y devuelve **copias** (`.copy()`), para que nadie modifique la base guardada. Devuelve una tupla de tres
tablas que se "desempaca": `train, val, test = particiones()` (en R, una `list` con nombres). `index.qmd` muestra los
tres tamaños en "En pocas palabras", "Evaluación" y "Limitaciones y extensiones".

**En R (ilustrativo):** `list(train = filter(td, Date < as.Date("2024-08-01")), val = filter(td, Date >=
as.Date("2024-08-01"), Date < as.Date("2025-08-01")), test = filter(td, Date >= as.Date("2025-08-01")))`.

---

## 13a.4 Sección 4: análisis exploratorio (líneas 344–465)

Todo lo de esta sección es **complemento del dashboard**: describe los datos para la página "¿Qué ocurre?" y
"Patrones". El notebook no lo calcula.

### 13a.4.1 `resumen_general`

Líneas 345–360: cuenta partidos, temporadas y fechas de **todo** el histórico, y calcula los porcentajes de
resultados y los goles por partido sólo con las **temporadas completas** (`temporada <= 2025`, para que la temporada
en curso, con 40 partidos, no pese distinto).

**Salida real:** 9,540 partidos; 26 temporadas; del 18-ago-2001 al 14-sep-2026; 9,500 partidos en temporadas
completas; local **45.6 %**, empate **24.7 %**, visitante **29.7 %**; **2.724** goles por partido (local 1.535,
visitante 1.189).

**Quién lo usa:** las *value boxes* "Partidos analizados" (9,540 y 26 temporadas) y "Gana el equipo local" (los tres
porcentajes); la tarjeta "Cómo funciona"; "Datos y procedencia"; y la fecha final (`fecha_max`) en varios textos
("hasta el 14 de septiembre de 2026"). `fecha_min`, `partidos_completas` y los goles **no se muestran** (la *value
box* escribe "Del 18 de agosto de 2001" como texto fijo).

> **Detalle:** el `2025` de `temporada <= 2025` está escrito a mano. Cuando termine 2026/27 habría que cambiarlo;
> `temporadas_completas()` ([13a.7.2](#13a72-temporadas_completas)), en cambio, detecta sola cuál es la temporada en
> curso.

**En R (ilustrativo):** `completas <- filter(h, temporada <= 2025)`; `mean(completas$resultado == 1)`;
`mean(completas$FTHG + completas$FTAG)`.

### 13a.4.2 `resumen_temporadas`

Líneas 363–377:

```python
t = df.groupby("temporada").agg(
    partidos=("resultado", "size"),
    pct_local=("resultado", lambda s: (s == 0).mean()),
    pct_empate=("resultado", lambda s: (s == 1).mean()),
    pct_visita=("resultado", lambda s: (s == 2).mean()),
    goles_local=("FTHG", "mean"),
    goles_visita=("FTAG", "mean"),
).reset_index()
t["etiqueta"] = t["temporada"].map(_etiqueta_temporada)
t["ventaja_local_pp"] = (t["pct_local"] - t["pct_visita"]) * 100
```

`agg` con **agregaciones con nombre**: `nombre_nuevo=("columna", función)`. `lambda s: (s == 0).mean()` es una función
anónima: la proporción de victorias locales en el grupo. `ventaja_local_pp` es la diferencia local − visitante en
puntos porcentuales.

**Salida real (algunas filas):**

| Temporada | Partidos | Local | Empate | Visitante | Ventaja local (pp) |
|---|---|---|---|---|---|
| 2001/02 | 380 | 43.4 % | 26.6 % | 30.0 % | +13.4 |
| 2003/04 | 380 | 43.9 % | 28.4 % | 27.6 % | +16.3 |
| 2009/10 | 380 | 50.8 % | 25.3 % | 23.9 % | **+26.8** (la mayor) |
| 2019/20 | 380 | 45.3 % | 24.2 % | 30.5 % | +14.7 |
| **2020/21** | 380 | **37.9 %** | 21.8 % | **40.3 %** | **−2.4** (la única negativa: estadios vacíos) |
| 2025/26 | 380 | 42.6 % | 27.4 % | 30.0 % | +12.6 |

**Quién lo usa:** la gráfica "Jugar en casa siempre ayuda… salvo sin público" y la "Tabla por temporada".
**En R (ilustrativo):** `group_by(temporada) |> summarise(partidos = n(), pct_local = mean(resultado == 1), …,
goles_local = mean(FTHG))`.

### 13a.4.3 `resultado_del_favorito`

Líneas 380–397:

```python
df = cargar_historico().dropna(subset=["B365H", "B365D", "B365A"])
local_favorito = df["B365H"] <= df["B365A"]
fav = np.where(local_favorito, 0, 2)
res = df["resultado"].to_numpy()
return {"partidos": len(df), "gana_favorito": (res == fav).mean(), "empate": (res == 1).mean(),
        "gana_no_favorito": ((res != fav) & (res != 1)).mean(), "local_es_favorito": local_favorito.mean(),
        "temporada_min": _etiqueta_temporada(int(df["temporada"].min()))}
```

- El **favorito** es el equipo con la cuota más baja entre local y visitante (el empate nunca es "favorito"). Con
  `<=`, un empate de cuotas cuenta al local como favorito.
- Usa **Bet365** porque es la única casa con cuotas desde 2002/03 (24 temporadas completas más la actual); las cuotas
  promedio sólo existen desde 2019/20. En 2001/02 no hay cuotas: quedan 9,160 partidos.

**Salida real:** 9,160 partidos; el favorito gana **54.2 %**, empate **24.7 %**, gana el no favorito **21.0 %**; el
local es favorito en 69.6 % de los partidos; desde 2002/03.

**Quién lo usa:** la *value box* "Gana el favorito de las cuotas", la gráfica "Ni el favorito es garantía" (que pone
los 9,160 en su eje) y "Qué significa para el modelo" ("si el favorito gana sólo 54 % de las veces, un buen modelo
debe aspirar a acertar cerca de 50 %"). **En R (ilustrativo):** `fav <- if_else(b$B365H <= b$B365A, 1L, 3L);
mean(b$resultado == fav)`.

### 13a.4.4 `resultado_por_elo`

Líneas 400–414:

```python
td = cargar_base_modelacion().copy()
td["resultado"] = resultados_observados(td)
td["grupo"] = pd.qcut(td["elo_diff"], n_grupos, labels=False)
t = td.groupby("grupo").agg(partidos=("resultado", "size"), elo_min=("elo_diff", "min"),
                            elo_max=("elo_diff", "max"), elo_mediana=("elo_diff", "median"),
                            pct_local=..., pct_empate=..., pct_visita=...).reset_index()
```

`pd.qcut(x, 10, labels=False)` corta la diferencia de Elo previa en **deciles** (10 grupos con el mismo número de
partidos, usando los cuantiles como bordes) y numera los grupos de 0 a 9. Usa la base de modelación: 2,696 partidos
de 2019/20 a 2026/27, con el Elo **previo** a cada partido.

**Salida real:**

| Decil | Diferencia de Elo | Mediana | Partidos | Gana local | Empate | Gana visitante |
|---|---|---|---|---|---|---|
| 1 | −428 a −191 | −252 | 270 | **12.6 %** | 20.7 % | 66.7 % |
| 2 | −191 a −122 | −157 | 270 | 26.3 % | 24.8 % | 48.9 % |
| 3 | −122 a −76 | −99 | 269 | 28.3 % | 26.8 % | 45.0 % |
| 4 | −76 a −37 | −56 | 270 | 35.9 % | 24.4 % | 39.6 % |
| 5 | −37 a −3 | −20 | 269 | 45.7 % | 25.7 % | 28.6 % |
| 6 | −3 a +33 | +16 | 270 | 36.7 % | 31.1 % | 32.2 % |
| 7 | +33 a +77 | +53 | 269 | 52.8 % | 22.7 % | 24.5 % |
| 8 | +77 a +124 | +99 | 270 | 54.1 % | 27.0 % | 18.9 % |
| 9 | +124 a +189 | +154 | 269 | 63.2 % | 21.6 % | 15.2 % |
| 10 | +189 a +438 | +251 | 270 | **76.3 %** | 13.7 % | 10.0 % |

La tendencia es clara, pero no perfectamente monótona: el decil 6 tiene menos victorias locales que el 5. Con ≈ 270
partidos por grupo, el error estándar de cada porcentaje es de ≈ 3 puntos: es ruido de muestra.

**Quién lo usa:** la gráfica "A más ventaja de Elo, más victorias locales" (subtítulo con los 2,696 partidos), la
"Tabla: resultado por diferencia de Elo" y "Por qué importan estos patrones" (13 % y 76 %).

**En R (verificado: mismos grupos, conteos y porcentajes):**

```r
resultado_por_elo <- function(td, n_grupos = 10) {
  td |> mutate(resultado = resultados_observados(td),
               grupo = cut(elo_diff, quantile(elo_diff, seq(0, 1, length.out = n_grupos + 1)),
                           include.lowest = TRUE, labels = FALSE) - 1L) |>      # ≈ pd.qcut(…, labels=False)
    group_by(grupo) |>
    summarise(partidos = n(), elo_min = min(elo_diff), elo_max = max(elo_diff), elo_mediana = median(elo_diff),
              pct_local = mean(resultado == 1), pct_empate = mean(resultado == 2), pct_visita = mean(resultado == 3))
}
```

`cut()` con los cuantiles como bordes reproduce `qcut` (los dos usan el cuantil "tipo 7", el de omisión en R y en
numpy). **No** sirve `dplyr::ntile()`: reparte por rango y da grupos de 270, 270, 270, 270, 270, 270, 269, 269, 269,
269 (comprobado), distintos de los de `qcut`.

### 13a.4.5 `ventaja_local_en_elo`

Líneas 417–428:

```python
def ventaja_local_en_elo(tabla: pd.DataFrame) -> float:
    x = tabla["elo_mediana"].to_numpy()
    d = (tabla["pct_local"] - tabla["pct_visita"]).to_numpy()
    for i in range(len(d) - 1):
        if d[i] < 0 <= d[i + 1]:
            return float(-(x[i] + (0 - d[i]) * (x[i + 1] - x[i]) / (d[i + 1] - d[i])))
    return float("nan")
```

**Idea:** si con Elo igual el local ganara tanto como el visitante, jugar en casa no valdría nada. Como el local gana
más, hay que buscar **qué tan débil** tiene que ser el local para que las dos probabilidades se igualen: esa
desventaja, en puntos Elo, es lo que "vale" jugar en casa.

1. Para cada decil, `d` = % gana local − % gana visitante, y `x` = la mediana de la diferencia de Elo.
2. Busca el **primer** par de deciles consecutivos donde `d` pasa de negativo a cero o positivo.
3. Interpola en línea recta entre los dos puntos para hallar la `x` donde `d = 0`:
   x₀ = xᵢ + (0 − dᵢ)·(xᵢ₊₁ − xᵢ)/(dᵢ₊₁ − dᵢ). La ventaja es −x₀.

**Con los datos:** el cruce está entre el decil 4 (mediana −56.48; d = 35.9 − 39.6 = −3.7 puntos) y el decil 5
(mediana −20.29; d = 45.7 − 28.6 = +17.1). x₀ = −56.48 + 0.037 × 36.18 / 0.208 = **−50.03** → jugar en casa vale
**≈ 50 puntos Elo**. `index.qmd` lo redondea a la decena (`round(…, -1)`) y la gráfica lo anota en el punto de cruce.

**En R (verificado: 50.03):**

```r
ventaja_local_en_elo <- function(t) {
  x <- t$elo_mediana; d <- t$pct_local - t$pct_visita
  i <- which(head(d, -1) < 0 & tail(d, -1) >= 0)[1]          # primer cruce de negativo a no negativo
  if (is.na(i)) return(NA_real_)
  -(x[i] + (0 - d[i]) * (x[i + 1] - x[i]) / (d[i + 1] - d[i]))
}
```

Ojo: `approx(d, x, xout = 0)` parece equivalente pero **no lo es**: ordena los puntos por `d`, que no es monótona (por
el decil 6), y daría **23.55** (comprobado).

> **Decisión:** medir la ventaja de jugar en casa en puntos Elo, interpolando el cruce entre deciles.
> **Alternativas:** (a) ajustar una regresión (logística multinomial u ordinal) del resultado contra la diferencia de
> Elo y despejar dónde P(local) = P(visitante) — usa todos los partidos sin agrupar, pero es menos fácil de explicar;
> (b) agregar al Elo un parámetro de localía y estimarlo (como hacen muchos sistemas Elo) — cambiaría el Elo del
> modelo; (c) más o menos grupos (quintiles, veintiles) — más estable o más detallado. Ninguna se probó.
> **Por qué ésta:** sale directo de la tabla que ya muestra el tablero y se explica con una regla de tres.
> **Evidencia en el proyecto:** ≈ 50 puntos con K = 15 (con el Elo anterior, K = 30, salía ≈ 60: depende de la
> escala que produce K, ver [capítulo 4](04_elo.md)). Es una cifra **aproximada**: un decil ruidoso movería el cruce.
> **Si preguntan:** "Buscamos qué tan débil tiene que ser el local para que gane tanto como el visitante: con los
> deciles de Elo, unos 50 puntos. Es lo que vale jugar en casa, aproximadamente."

### 13a.4.6 `calibracion_historica_mercado` y `_tabla_calibracion`

Líneas 431–447:

```python
def calibracion_historica_mercado(ancho: float = 0.05, minimo: int = 50) -> pd.DataFrame:
    """Probabilidad implícita (Bet365) vs frecuencia observada, 2002/03–2026/27."""
    df = cargar_historico().dropna(subset=["B365H", "B365D", "B365A"])
    brutas = 1 / df[["B365H", "B365D", "B365A"]].to_numpy(float)
    q = brutas / brutas.sum(axis=1, keepdims=True)
    ocurrio = np.eye(3)[df["resultado"].to_numpy()]
    return _tabla_calibracion(q.ravel(), ocurrio.ravel(), ancho, minimo)


def _tabla_calibracion(p, o, ancho, minimo):
    bordes = np.arange(0, 1 + ancho, ancho)
    grupo = pd.cut(p, bordes, include_lowest=True)
    t = (pd.DataFrame({"p": p, "o": o, "g": grupo})
         .groupby("g", observed=True)
         .agg(n=("o", "size"), prob_predicha=("p", "mean"), frecuencia=("o", "mean"))
         .reset_index(drop=True))
    return t[t["n"] >= minimo].reset_index(drop=True)
```

**Qué hace:**

1. Probabilidades implícitas de Bet365, normalizadas igual que en `probabilidades_mercado`.
2. `np.eye(3)[resultado]` convierte cada resultado en una fila "uno en caliente": local → `[1, 0, 0]`, empate →
   `[0, 1, 0]`, visita → `[0, 0, 1]`. Así cada probabilidad tiene su "¿ocurrió?" (1 o 0).
3. `ravel()` aplana las matrices de 9,160 × 3 en vectores de **27,480 pares** (probabilidad, ocurrió): se evalúan
   juntas las tres probabilidades de cada partido.
4. `_tabla_calibracion`: corta las probabilidades en intervalos de ancho 0.05 (`np.arange(0, 1.05, 0.05)` da 21
   bordes → 20 intervalos; `include_lowest` incluye el 0). Por intervalo: casos, probabilidad media y **frecuencia
   observada** (la media de los 0 y 1). `observed=True` deja sólo los intervalos con datos. Al final descarta los
   intervalos con menos de `minimo` casos.

**Lectura:** un pronóstico está **calibrado** si, de todas las veces que dice 30 %, ocurre ≈ 30 %. **Salida real:**
18 intervalos (de 19 con datos; se descarta el de 0.90–0.95, con 2 casos), 27,478 casos. Algunos:

| Probabilidad media (Bet365) | Frecuencia observada | Casos |
|---|---|---|
| 4.3 % | 3.4 % | 119 |
| 12.7 % | 11.7 % | 1,637 |
| 27.7 % | 28.0 % | 7,462 (el grupo de los empates) |
| 47.4 % | 46.9 % | 1,453 |
| 62.0 % | 65.7 % | 719 |
| 82.1 % | 87.7 % | 219 |
| 86.8 % | 92.5 % | 67 |

En el centro, la calibración es casi perfecta. En los extremos aparece el sesgo **favorito–no favorito**: lo muy
improbable ocurre algo menos de lo que dicen las cuotas y los grandes favoritos ganan algo más. Es lo que dice la
tarjeta "Por qué importan estos patrones".

**Quién lo usa:** "Las cuotas están bien calibradas" (la gráfica anota el último grupo) y "Tabla: calibración de las
cuotas". `_tabla_calibracion` también la usa `calibracion_modelo_vs_mercado` ([13a.5.9](#13a59-calibracion_modelo_vs_mercado)).

**En R (ilustrativo):**

```r
tabla_calibracion <- function(p, o, ancho, minimo) {
  tibble(p, o, g = cut(p, seq(0, 1, by = ancho), include.lowest = TRUE)) |>
    group_by(g) |> summarise(n = n(), prob_predicha = mean(p), frecuencia = mean(o)) |>
    filter(n >= minimo) |> select(-g)
}
q <- brutas / rowSums(brutas)
ocurrio <- diag(3)[b$resultado, ]                  # ≈ np.eye(3)[resultado], con resultado 1, 2, 3
tabla_calibracion(c(q), c(ocurrio), 0.05, 50)      # c() aplana por columnas: los pares siguen juntos
```

> **Decisión:** intervalos de ancho fijo con un mínimo de casos: 5 puntos y ≥ 50 casos para el mercado histórico
> (27,480 pares); 10 puntos y ≥ 30 casos para modelo contra mercado en validación + prueba (2,397 pares,
> [13a.5.9](#13a59-calibracion_modelo_vs_mercado)).
> **Alternativas (calculadas para esta guía con la misma función):**
>
> | Opción | Mercado histórico (27,480) | M0 en validación + prueba (2,397) |
> |---|---|---|
> | Ancho 0.10 | 9 grupos (el menor, 286 casos) | **8 grupos con mínimo 30** (lo usado) |
> | **Ancho 0.05** | **18 grupos con mínimo 50** (lo usado) | 13 grupos con mínimo 30 (quedan fuera 67 casos) |
> | Ancho 0.025 | 33 grupos (quedan fuera 70 casos) | — |
> | Sin mínimo | 19 grupos; uno con 2 casos | 10 grupos; uno con 12 casos (83 % → 92 %) y otro con 2 (91 % → 100 %) |
>
> Otras no probadas: intervalos con el mismo número de casos (cuantiles), una curva suavizada (loess o regresión
> isotónica), o resumir en un solo número (error de calibración esperado, o la descomposición del puntaje de Brier).
> **Por qué ésta:** con más datos se puede usar un ancho más fino. El mínimo evita puntos que son puro ruido: el error
> estándar de una frecuencia con n casos es a lo más √(0.25/n), ≈ 7 puntos con 50 y ≈ 9 con 30; con 2 casos, un
> "100 %" no dice nada.
> **Si preguntan:** "Agrupamos las probabilidades en intervalos y comparamos con lo que pasó; usamos intervalos más
> finos donde hay más datos y quitamos los grupos con muy pocos casos, porque ahí la frecuencia es puro ruido."

### 13a.4.7 `ajuste_poisson_goles`

Líneas 450–465:

```python
for col, lado in [("FTHG", "Local"), ("FTAG", "Visitante")]:
    g = df[col].astype(int)
    lam = g.mean()
    for k in range(max_goles + 1):
        if k < max_goles:
            obs, teo = (g == k).mean(), poisson.pmf(k, lam)
        else:  # la última categoría acumula "6 o más"
            obs, teo = (g >= k).mean(), poisson.sf(k - 1, lam)
        filas.append({"lado": lado, "goles": k, "etiqueta": f"{k}+" if k == max_goles else str(k),
                      "observado": obs, "poisson": teo, "media": lam, "varianza": g.var()})
```

Para los goles del local y del visitante (9,500 partidos de temporadas completas): la proporción observada de 0, 1,
…, 5 y "6 o más" goles, contra una Poisson **con la misma media**. `poisson.pmf(k, λ)` es P(X = k); `poisson.sf(5, λ)`
es P(X > 5) = P(X ≥ 6), para que la última barra acumule la cola.

**Salida real:**

| Goles | Local observado | Poisson (λ = 1.535) | Visitante observado | Poisson (λ = 1.189) |
|---|---|---|---|---|
| 0 | 23.3 % | 21.6 % | 32.8 % | 30.5 % |
| 1 | 31.8 % | 33.1 % | 34.2 % | 36.2 % |
| 2 | 24.6 % | 25.4 % | 20.0 % | 21.5 % |
| 3 | 12.6 % | 13.0 % | 8.8 % | 8.5 % |
| 4 | 5.2 % | 5.0 % | 3.0 % | 2.5 % |
| 5 | 1.8 % | 1.5 % | 0.9 % | 0.6 % |
| 6+ | 0.8 % | 0.5 % | 0.3 % | 0.1 % |
| Media / varianza | 1.535 / 1.697 | | 1.189 / 1.341 | |

**Lectura:** la forma es muy parecida, con un poco más de ceros y de goleadas que en una Poisson; por eso la varianza
supera a la media (cociente 1.11 y 1.13). Es lo esperable al mezclar equipos de fuerzas distintas: cada partido
puede ser Poisson con su propia λ. Lo que importa para la regresión es la dispersión **condicional**, una vez que el
modelo toma en cuenta la fuerza de cada equipo: 0.996 y 1.036 ([13a.5.11](#13a511-dispersion_pearson)); ver
[capítulo 6](06_poisson_y_regresion.md).

**Quién lo usa:** la gráfica "Los goles se comportan como un conteo de Poisson" (la media y la varianza van en los
subtítulos). **En R (ilustrativo):** `c(sapply(0:5, function(k) mean(g == k)), mean(g >= 6))` contra
`c(dpois(0:5, mean(g)), ppois(5, mean(g), lower.tail = FALSE))`.

---

## 13a.5 Sección 5: modelación y evaluación (líneas 468–694)

Aquí se reentrenan los modelos, se calculan las probabilidades de todos los predictores y, sobre ellas, las
métricas del notebook y los **complementos de evaluación** del tablero.

### 13a.5.1 `modelos_entrenados`

```python
@lru_cache(maxsize=None)
def modelos_entrenados():
    """M0–M4 ajustados en entrenamiento (2019/20–2023/24), como en el notebook §6."""
    train, _, _ = particiones()
    return {nombre: entrenar_modelo(train, *cols) for nombre, cols in ESPECIFICACIONES.items()}
```

- `train, _, _ = particiones()`: el guion bajo es la convención para "este valor no lo uso".
- Una **comprensión de diccionario** (`{clave: valor for … in …}`) ajusta los cinco modelos: `*cols` "desempaca" la
  tupla (columnas del local, columnas del visitante) en dos argumentos.
- Resultado: `{"M0_Base": {...}, …, "M4_Completo": {...}}`, 10 regresiones de Poisson con los 1,897 partidos de
  entrenamiento. Los coeficientes de M0 son los del notebook (0.0433, 0.6283, 0.1678, 0.0778 / 0.0264, −0.6854,
  0.1079, 0.0281).
- Tiene caché: se ajustan una sola vez, aunque los usen la evaluación, los efectos, el diagnóstico y el simulador.

**En R (ilustrativo):** `modelos <- purrr::map(especificaciones, ~ entrenar_modelo(train, .x[[1]], .x[[2]]))`.

### 13a.5.2 `probabilidades_por_conjunto`

Líneas 476–507 (lo esencial):

```python
train, val, test = particiones()
historico = cargar_historico()
modelos = modelos_entrenados()
lh0, la0 = float(train["home_goals"].mean()), float(train["away_goals"].mean())
salida = {}
for nombre_conjunto, datos in [("Validación", val), ("Prueba", test)]:
    n = len(datos)
    P = {"Uniforme": np.full((n, 3), 1 / 3),
         "Ingenua": probabilidades_1x2(np.full(n, lh0), np.full(n, la0))}
    predicciones = {}
    for nombre, modelo in modelos.items():
        predicciones[nombre] = predecir_con_modelo(modelo, datos)
        P[nombre] = predicciones[nombre][PROBS].to_numpy()
    P["Mercado_apertura"], margen = probabilidades_mercado(datos, historico, CUOTAS)
    P["Mercado_cierre"], _ = probabilidades_mercado(datos, historico, CUOTAS_CIERRE)
    salida[nombre_conjunto] = {"datos": datos.reset_index(drop=True), "y": resultados_observados(datos),
                               "P": P, "predicciones": predicciones, "margen": margen}
return salida
```

Es el **corazón de la evaluación**: para cada periodo, una matriz de n × 3 probabilidades por cada uno de los **9
predictores**:

| Predictor | Qué es | Origen |
|---|---|---|
| `Uniforme` | 1/3 a cada resultado (`np.full` llena una matriz con un valor) | Complemento |
| `Ingenua` | La misma Poisson para todos los partidos, con los goles promedio del entrenamiento (λ = 1.561413 y 1.311545 → 43.24 / 24.69 / 32.07 %) | Referencia simple del notebook (§7) |
| `M0_Base` … `M4_Completo` | Los cinco modelos | Notebook (§6 y §9) |
| `Mercado_apertura` | Cuotas promedio de apertura, normalizadas | Notebook (§8 y §9) |
| `Mercado_cierre` | Cuotas promedio de cierre | Complemento |

Además guarda los partidos, el vector `y` de resultados reales (0, 1, 2), las tablas de predicción de los modelos
(para el MAE) y el margen de la apertura (4.49 % y 5.84 %). Con caché: lo usan siete funciones y también `index.qmd`
(toma `y` de prueba para decir que el empate ocurrió en 28.2 % de los partidos de prueba, en la tarjeta "Calibración:
modelo vs. mercado").

**En R (ilustrativo):** una `list` por periodo con `P <- c(list(Uniforme = matrix(1/3, n, 3), Ingenua = …),
purrr::map(pred, ~ as.matrix(.x[, c("P_home", "P_draw", "P_away")])), list(Mercado_apertura = …))`.

### 13a.5.3 `_logloss_por_partido`

```python
def _logloss_por_partido(y, P):
    return -np.log(np.clip(P[np.arange(len(y)), y], 1e-15, 1.0))
```

`P[np.arange(n), y]` toma, de cada fila, la probabilidad de la columna que ocurrió (índices "elegantes": fila i,
columna yᵢ). `np.clip(…, 1e-15, 1)` evita `log(0) = −∞` (la misma protección que usa `sklearn`). El resultado es el
LogLoss **de cada partido**; su promedio es el LogLoss de siempre (M0 en prueba: 1.0330756, igual que
`log_loss`). Se necesita partido por partido para el bootstrap y la descomposición de la brecha.
**En R (ilustrativo):** `-log(pmin(pmax(P[cbind(seq_along(y), y)], 1e-15), 1))`.

### 13a.5.4 `tabla_metricas`

Líneas 514–533:

```python
for conjunto, c in probabilidades_por_conjunto().items():
    y = c["y"]
    for nombre, P in c["P"].items():
        ll = log_loss(y, P, labels=[0, 1, 2])
        fila = {"conjunto": conjunto, "predictor": nombre, "nombre": NOMBRES[nombre],
                "partidos": len(y), "logloss": ll,
                # exp(-LogLoss) = media geométrica de la probabilidad dada al resultado real.
                "prob_resultado_real": float(np.exp(-ll)),
                "aciertos": float((P.argmax(axis=1) == y).mean()),
                "p_empate_media": float(P[:, 1].mean()),
                "mae_promedio": np.nan}
        if nombre in c["predicciones"]:
            fila["mae_promedio"] = evaluar_predicciones(c["predicciones"][nombre])["MAE_promedio"]
        filas.append(fila)
```

Cinco medidas por predictor y periodo (18 filas):

- **`logloss`**: la métrica principal ([capítulo 9](09_evaluacion_y_validacion.md)).
- **`prob_resultado_real` = exp(−LogLoss)**: como el LogLoss es el promedio de −log p, su exponencial es la **media
  geométrica** de la probabilidad que se le dio al resultado real. Traduce el LogLoss a un porcentaje entendible.
- **`aciertos`**: `P.argmax(axis=1)` es el resultado con mayor probabilidad; se compara con el real. Si hay empate
  entre columnas, `argmax` elige la primera (local).
- **`p_empate_media`**: el promedio de P(empate), para ver si se subestiman los empates.
- **`mae_promedio`**: sólo para los cinco modelos, que dan goles esperados; el resto queda `NaN`.

**Salida real:**

| Predictor | LogLoss val. | LogLoss prueba | Prob. al resultado real (prueba) | Aciertos val. / prueba | P(empate) media (prueba) | MAE val. / prueba |
|---|---|---|---|---|---|---|
| Azar (1/3) | 1.098612 | 1.098612 | 33.3 % | 40.8 / 41.5 % | 33.3 % | — |
| Referencia ingenua | 1.079361 | 1.086791 | 33.7 % | 40.8 / 41.5 % | 24.7 % | — |
| **M0 · Base** | 0.989547 | **1.033076** | 35.6 % | 53.2 / **48.0 %** | 23.6 % | 0.918 / 0.902 |
| M1 · + Forma | 0.987603 | 1.034699 | 35.5 % | 52.4 / 46.3 % | 23.6 % | 0.922 / 0.904 |
| M2 · + Tiros | 0.980718 | 1.037331 | 35.4 % | 53.4 / 47.5 % | 23.7 % | 0.921 / 0.902 |
| M3 · + Tiros a puerta | 0.982319 | 1.033868 | 35.6 % | 52.4 / 46.3 % | 24.1 % | 0.921 / **0.894** |
| M4 · Completo | **0.978612** | 1.036739 | 35.5 % | 53.7 / 47.5 % | 23.8 % | 0.922 / 0.899 |
| Mercado · Apertura | 0.970552 | 1.020000 | 36.1 % | 54.2 / 48.9 % | 24.5 % | — |
| Mercado · Cierre | 0.966733 | 1.017024 | 36.2 % | 55.5 / 48.9 % | 24.8 % | — |

El empate ocurrió en 24.5 % de los partidos de validación y en **28.2 %** de los de prueba: todos los predictores lo
subestiman en prueba.

**Detalle curioso:** el azar y la referencia ingenua tienen los **mismos aciertos** (40.8 % y 41.5 %, la frecuencia de
victorias locales) porque los dos "eligen" siempre al local: la ingenua porque 43.2 % es su probabilidad más alta, y el
azar porque, con tres probabilidades iguales, `argmax` toma la primera columna.

**Quién lo usa:** la *value box* "Partidos acertados por el modelo" (48.0 %, mercado 48.9 %, ingenua 41.5 %), la
gráfica principal del Resumen ("El modelo recupera la mayor parte de la ventaja del mercado, sin superarlo": mejora
de cada predictor sobre la ingenua), la tarjeta "Resumen", la tabla "Métricas completas", el subtítulo de
"Calibración: modelo vs. mercado" (P(empate) media) y "Qué significa para el modelo" (brecha de prueba 0.013).

**En R (ilustrativo):** `ll <- -mean(log(P[cbind(seq_along(y), y)])); exp(-ll);
mean(max.col(P, ties.method = "first") == y); mean(P[, 2])`. Ojo: `max.col()` usa por omisión
`ties.method = "random"`; para el azar daría aciertos al azar. `"first"` reproduce `argmax`.

### 13a.5.5 `fraccion_de_mejora`

```python
def fraccion_de_mejora(metricas, conjunto="Prueba", modelo="M0_Base") -> float:
    m = metricas[metricas["conjunto"] == conjunto].set_index("predictor")["logloss"]
    return float((m["Ingenua"] - m[modelo]) / (m["Ingenua"] - m["Mercado_apertura"]))
```

$$\text{fracción}=\frac{LL_{\text{ingenua}}-LL_{M0}}{LL_{\text{ingenua}}-LL_{\text{mercado}}}$$

Pone el LogLoss en una escala donde la referencia ingenua vale 0 y el mercado vale 1.

- **Prueba:** (1.086791 − 1.033076) / (1.086791 − 1.020000) = 0.053715 / 0.066791 = **0.804 → 80 %**.
- **Validación:** (1.079361 − 0.989547) / (1.079361 − 0.970552) = 0.089814 / 0.108809 = **0.825 → 83 %**.

**Quién lo usa:** la *value box* "Ventaja del mercado que alcanza el modelo" (80 %: "de cada 100 puntos que el mercado
mejora sobre una referencia ingenua, el modelo logra 80"). La de validación se calcula en `preparar_todo()` pero el
tablero **no la muestra** (sólo la imprime el bloque `__main__`). Su justificación y su incertidumbre (IC bootstrap de
54 % a 101 % en prueba) están en la decisión D37 del [capítulo 19](19_decisiones_y_alternativas.md#d37-parte-de-la-ventaja-del-mercado-80--para-comunicar--razonada).
**En R (ilustrativo):** `(ll_ingenua - ll_m0) / (ll_ingenua - ll_mercado)`.

### 13a.5.6 `_bootstrap` y `tabla_bootstrap`

Líneas 542–577:

```python
def _bootstrap(diferencias, semilla=SEMILLA, B=N_BOOTSTRAP):
    rng = np.random.default_rng(semilla)
    idx = rng.integers(0, len(diferencias), size=(B, len(diferencias)), dtype=np.int32)
    medias = diferencias[idx].mean(axis=1)
    return float(diferencias.mean()), float(np.percentile(medias, 2.5)), float(np.percentile(medias, 97.5))


@lru_cache(maxsize=None)
def tabla_bootstrap() -> pd.DataFrame:
    c = probabilidades_por_conjunto()
    comparaciones = [
        ("Prueba", "M0_Base", "Ingenua"),
        ("Prueba", "M0_Base", "Mercado_apertura"),
        ("Prueba", "M4_Completo", "M0_Base"),
        ("Prueba", "M4_Completo", "Mercado_apertura"),
        ("Validación", "M4_Completo", "M0_Base"),
        ("Validación", "M0_Base", "Mercado_apertura"),
        ("Validación + prueba", "M0_Base", "Mercado_apertura"),
    ]
    filas = []
    for conjunto, a, b in comparaciones:
        partes = ["Validación", "Prueba"] if conjunto == "Validación + prueba" else [conjunto]
        dif = np.concatenate([
            _logloss_por_partido(c[p]["y"], c[p]["P"][a]) - _logloss_por_partido(c[p]["y"], c[p]["P"][b])
            for p in partes
        ])
        media, lo, hi = _bootstrap(dif)
        filas.append({"conjunto": conjunto, "a": a, "b": b, "partidos": len(dif),
                      "diferencia": media, "ic_inf": lo, "ic_sup": hi,
                      "significativa": bool(lo > 0 or hi < 0)})
    return pd.DataFrame(filas)
```

**La pregunta:** una diferencia de LogLoss de 0.013 entre M0 y el mercado, ¿es real o es suerte de los 419 partidos
que tocaron? El **bootstrap** (Efron y Tibshirani, 1993) responde simulando "otras muestras posibles" a partir de la
que se tiene.

**Paso a paso:**

1. **Diferencia partido por partido** (en `tabla_bootstrap`): para cada partido i, dᵢ = LogLoss de A − LogLoss de B.
   Es **pareado**: A y B se evalúan en el mismo partido, así que lo que tienen en común (un partido sorpresivo
   perjudica a los dos) se cancela en la resta. Para "Validación + prueba" se juntan los 799 partidos.
2. **Remuestreo** (en `_bootstrap`): `rng.integers(0, n, size=(B, n))` crea una matriz de **10,000 × n** números al
   azar entre 0 y n − 1: cada fila es una muestra **con reemplazo** de los n partidos (unos salen dos veces, otros
   ninguna). Con la semilla 2026 y n = 419, la primera muestra empieza con los partidos 356, 74, 11, 268, 153…
   (contando desde 0). `dtype=np.int32` usa 4 bytes por número: la matriz más grande (10,000 × 799) ocupa ≈ 32 MB.
3. **Media de cada muestra:** `diferencias[idx]` arma la matriz de diferencias remuestreadas y `.mean(axis=1)` saca
   las 10,000 medias. Su dispersión muestra cuánto podría variar la diferencia con otra muestra de partidos.
4. **Intervalo de 95 %:** los percentiles 2.5 y 97.5 de esas medias (método de **percentiles**; numpy interpola
   igual que el `quantile()` de R por omisión).
5. **"Significativa"** = el intervalo **no incluye el cero** (`lo > 0` o `hi < 0`). Diferencia negativa: A fue
   mejor.

Las siete comparaciones usan la **misma semilla**: las de prueba (todas con n = 419) remuestrean exactamente los
mismos partidos, así que sus intervalos son comparables entre sí. Las siete juntas tardan 0.28 s.

**Salida real:**

| Periodo | A − B | Partidos | Diferencia | IC 95 % | ¿Distinta de cero? |
|---|---|---|---|---|---|
| Prueba | M0 − Referencia ingenua | 419 | −0.0537 | −0.0861 a −0.0217 | Sí |
| Prueba | M0 − Mercado (apertura) | 419 | +0.0131 | −0.0005 a +0.0264 | No (por muy poco) |
| Prueba | M4 − M0 | 419 | +0.0037 | −0.0063 a +0.0139 | No |
| Prueba | M4 − Mercado | 419 | +0.0167 | +0.0034 a +0.0301 | Sí |
| Validación | M4 − M0 | 380 | −0.0109 | −0.0213 a −0.0001 | Sí (por un margen mínimo: −0.000055) |
| Validación | M0 − Mercado | 380 | +0.0190 | +0.0053 a +0.0328 | Sí |
| Validación + prueba | M0 − Mercado | 799 | +0.0159 | +0.0064 a +0.0255 | Sí |

**Quién lo usa:** la tabla "¿Son significativas las diferencias?" y, en la tarjeta "Resumen", la brecha total con el
mercado (0.016 con validación y prueba juntas). El "10,000 remuestreos" del subtítulo es texto fijo.

**Qué tan estable es (comprobaciones hechas para esta guía, con la misma función):**

- **Otras semillas.** Para M0 − mercado en prueba, con las semillas 1 a 5 el extremo inferior va de −0.00057 a
  −0.00013: siempre incluye el cero. Con 100 semillas, **ninguna** lo excluye. Para M4 − M0 en validación, en cambio,
  el extremo superior va de −0.00041 a +0.00038: **83 de 100 semillas** excluyen el cero. Ese "Sí" está realmente al
  límite.
- **Número de remuestreos.** La variación de los extremos entre semillas (desviación estándar) es ≈ 0.0006 con
  B = 1,000, **≈ 0.0002 con B = 10,000** y ≈ 0.00005 con B = 100,000. Con 10,000 los intervalos son estables hasta la
  cuarta cifra decimal y el cálculo sigue tardando menos de un segundo.
- **Aproximación normal.** Media ± 1.96 × error estándar = 0.0131 ± 1.96 × 0.0069 → −0.0005 a +0.0266: casi idéntico
  al bootstrap (con n = 419, el teorema central del límite ya funciona bien).

**En R (ilustrativo; R y numpy generan números aleatorios distintos, así que los extremos difieren en la cuarta
cifra):**

```r
bootstrap <- function(dif, semilla = 2026, B = 10000) {
  set.seed(semilla)                                                        # ≈ default_rng(2026)
  idx <- matrix(sample.int(length(dif), B * length(dif), replace = TRUE), nrow = B)   # B × n índices
  medias <- rowMeans(matrix(dif[idx], nrow = B))                          # media de cada remuestreo
  c(diferencia = mean(dif), quantile(medias, c(0.025, 0.975), names = FALSE))
}
dif <- logloss_partido(P_m0, y) - logloss_partido(P_mercado, y)           # pareado: mismo partido
bootstrap(dif)
```

([`03_mercado.R`](equivalencias_R/03_mercado.R) lo hace con `replicate()` y obtiene −0.0007 a +0.0265 para M0 − mercado
en prueba: la misma conclusión.)

> **Decisión:** intervalos bootstrap **pareados por partidos**: 10,000 remuestreos, semilla 2026, percentiles 2.5 y
> 97.5; "distinta de cero" si el intervalo no incluye el cero.
> **Alternativas:** (a) **prueba de Diebold y Mariano (1995)**, la clásica para comparar pronósticos; con horizonte de
> un paso equivale a una prueba t sobre las dᵢ — a favor: estándar en pronósticos; en contra: se apoya en la
> normalidad asintótica; (b) **bootstrap por bloques** (remuestrear fechas o jornadas completas) — respeta la posible
> dependencia entre partidos del mismo fin de semana; en contra: con 41 semanas en prueba hay pocos bloques;
> (c) **no reportar incertidumbre**, como el notebook. Ninguna forma parte del tablero; la guía las calculó aparte
> (decisión D36 del [capítulo 19](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)):
> cinco de las siete conclusiones se mantienen con los tres métodos, y las dos que están al límite cambian de lado
> según el método (M0 − mercado en prueba: Diebold–Mariano p = 0.059, pero por semanas el intervalo empieza en
> +0.0002; M4 − M0 en validación: Diebold–Mariano p = 0.048, pero por fechas el intervalo llega a +0.0002).
> **Por qué ésta:** no supone normalidad, es pareada (elimina la variación común), se explica en una frase y es el
> método del curso; B = 10,000 deja el error de simulación en ≈ 0.0002 con un cálculo de 0.3 s; la semilla fija hace
> que el tablero muestre siempre los mismos intervalos.
> **Evidencia en el proyecto:** la tabla de arriba y las comprobaciones de estabilidad. Lo robusto con cualquier
> método: M0 supera a la ingenua, y con validación y prueba juntas el mercado supera a M0.
> **Si preguntan:** "Remuestreamos los partidos 10,000 veces y vimos si el intervalo de la diferencia incluye el cero.
> Es pareado porque los dos pronósticos se evalúan en los mismos partidos. Los casos al límite, como M4 contra M0 en
> validación, hay que leerlos como al límite: cambian con la semilla o con el método."

### 13a.5.7 `delta_contra_m0`

```python
m = metricas.pivot(index="predictor", columns="conjunto", values="logloss")
orden = ["M1_Forma", "M2_Tiros", "M3_SOT", "M4_Completo", "Mercado_apertura"]
d = pd.DataFrame({"predictor": orden, "nombre": [NOMBRES[p] for p in orden],
                  "validacion": [m.loc[p, "Validación"] - m.loc["M0_Base", "Validación"] for p in orden],
                  "prueba": [m.loc[p, "Prueba"] - m.loc["M0_Base", "Prueba"] for p in orden]})
```

`pivot` reacomoda la tabla larga de métricas en una ancha (filas = predictores, columnas = periodos; en R,
`tidyr::pivot_wider()`), y luego resta el LogLoss de M0. Negativo = mejor que M0.

**Salida real:**

| Predictor | Δ validación | Δ prueba |
|---|---|---|
| M1 · + Forma | −0.001944 | +0.001624 |
| M2 · + Tiros | −0.008829 | +0.004255 |
| M3 · + Tiros a puerta | −0.007228 | +0.000792 |
| M4 · Completo | −0.010935 | +0.003664 |
| Mercado · Apertura | −0.018995 | −0.013076 |

En validación los cuatro modelos ampliados mejoran a M0; en prueba los cuatro quedan peor. El mercado es mejor en los
dos periodos. **Quién lo usa:** la gráfica "Agregar variables no generaliza" (círculo hueco = validación, relleno =
prueba). La columna de validación reproduce la de la §6 del notebook; la de prueba la agrega el tablero.
**En R (ilustrativo):** `pivot_wider(names_from = conjunto, values_from = logloss) |> mutate(validacion =
Validación - Validación[predictor == "M0_Base"], …)`.

### 13a.5.8 `brecha_por_resultado`

Líneas 593–614:

```python
c = probabilidades_por_conjunto()
y = np.concatenate([c[p]["y"] for p in ("Validación", "Prueba")])
Pm = np.vstack([c[p]["P"]["M0_Base"] for p in ("Validación", "Prueba")])
Pk = np.vstack([c[p]["P"]["Mercado_apertura"] for p in ("Validación", "Prueba")])
dif = _logloss_por_partido(y, Pm) - _logloss_por_partido(y, Pk)
for k, nombre in enumerate(["Victoria local", "Empate", "Victoria visitante"]):
    s = y == k
    filas.append({"resultado": nombre, "partidos": int(s.sum()),
                  "aporte": float(dif[s].sum() / len(y)),
                  "p_modelo": float(Pm[s, k].mean()), "p_mercado": float(Pk[s, k].mean())})
t = pd.DataFrame(filas)
t.attrs["brecha_total"] = float(dif.mean())
t.attrs["partidos"] = len(y)
```

**La idea:** la brecha total es un promedio de diferencias partido por partido, y ese promedio se puede **repartir**
según el resultado que ocurrió:

$$LL_{M0}-LL_{\text{mercado}}=\frac{1}{N}\sum_{i=1}^{N}d_i=\sum_{k\in\{1,X,2\}}\underbrace{\frac{1}{N}\sum_{i:\,y_i=k}d_i}_{\text{aporte}_k},
\qquad d_i=\ln\frac{p^{\text{mercado}}_{i,y_i}}{p^{M0}_{i,y_i}}$$

Cada aporte se divide entre **N = 799** (no entre los partidos de ese resultado), por eso los tres suman exactamente la
brecha. Un aporte positivo dice que, en esos partidos, el mercado le dio más probabilidad a lo que pasó.

- `np.vstack` apila las matrices de validación y de prueba (en R, `rbind`); `np.concatenate`, los vectores (`c()`).
- `Pm[s, k]`: en los partidos donde ocurrió k, la probabilidad que M0 le dio a k.
- `t.attrs` guarda datos extra dentro de la tabla (la brecha total y N): metadatos de pandas.
- Se usan los dos periodos porque los coeficientes se estimaron sólo con entrenamiento, así que los dos están fuera
  de muestra. (El docstring añade que "M0 no se eligió con ninguno de los dos periodos"; ojo: la preferencia por M0
  sí tomó en cuenta la prueba, ver [capítulo 9](09_evaluacion_y_validacion.md).)

**Salida real:**

| Resultado real | Partidos | Aporte | P media del modelo al resultado | … del mercado |
|---|---|---|---|---|
| Victoria local | 329 | **+0.0185** | 49.7 % | 52.0 % |
| Empate | 211 | **+0.0078** | 23.5 % | 24.3 % |
| Victoria visitante | 259 | **−0.0104** | 41.0 % | 40.3 % |
| **Total** | 799 | **+0.0159** | | |

La mayor parte de la brecha está en las **victorias locales**; después, en los empates. En las victorias visitantes el
modelo fue mejor que el mercado. Partido por partido, el mercado le dio más probabilidad que M0 al resultado real en
**57.8 %** de los 799 partidos.

**Quién lo usa:** la gráfica "No es una derrota..." (barras naranjas donde el mercado fue mejor, azules donde fue mejor
el modelo). **En R (ilustrativo):**

```r
dif <- logloss_partido(Pm, y) - logloss_partido(Pk, y); N <- length(y)
tibble(y, dif) |> group_by(y) |> summarise(partidos = n(), aporte = sum(dif) / N)   # suman mean(dif)
```

### 13a.5.9 `calibracion_modelo_vs_mercado`

```python
def calibracion_modelo_vs_mercado(ancho: float = 0.1, minimo: int = 30) -> pd.DataFrame:
    c = probabilidades_por_conjunto()
    y = np.concatenate([c[p]["y"] for p in ("Validación", "Prueba")])
    ocurrio = np.eye(3)[y].ravel()
    tablas = []
    for nombre in ("M0_Base", "Mercado_apertura"):
        P = np.vstack([c[p]["P"][nombre] for p in ("Validación", "Prueba")])
        t = _tabla_calibracion(P.ravel(), ocurrio, ancho, minimo)
        t["predictor"] = nombre
        tablas.append(t)
    return pd.concat(tablas, ignore_index=True)
```

La misma idea de [13a.4.6](#13a46-calibracion_historica_mercado-y-_tabla_calibracion), ahora para M0 y el mercado de
apertura en validación + prueba: 799 partidos × 3 = **2,397** pares, en intervalos de 10 puntos con al menos 30 casos.
`pd.concat` une las dos tablas una debajo de la otra (en R, `bind_rows`).

**Salida real** (probabilidad media → frecuencia observada, casos):

| Intervalo | M0 | Mercado (apertura) |
|---|---|---|
| 0–10 % | 7.3 → 7.5 % (40) | 7.4 → 5.6 % (54) |
| 10–20 % | 16.3 → 16.8 % (321) | 15.8 → 15.7 % (376) |
| 20–30 % | 24.6 → 26.4 % (990) | 25.2 → 27.1 % (964) |
| 30–40 % | 35.1 → 36.3 % (353) | 35.1 → 36.1 % (330) |
| 40–50 % | 44.6 → 40.6 % (283) | 44.9 → 43.5 % (246) |
| 50–60 % | 54.5 → 54.2 % (214) | 55.0 → 48.3 % (209) |
| 60–70 % | **64.4 → 57.0 %** (135) | 65.0 → 63.7 % (135) |
| 70–80 % | **74.1 → 68.1 %** (47) | 74.2 → 70.3 % (64) |

**Lectura:** M0 **confía de más en los favoritos claros** (cuando dice 64 %, ocurre 57 %; cuando dice 74 %, 68 %); el
mercado se desvía menos en esa zona. En el intervalo de 20–30 %, donde caen casi todos los empates, los dos se
quedan cortos. Quedan fuera los intervalos de 80 % o más (14 casos de M0 y 19 del mercado) por el mínimo de 30.
**Quién lo usa:** la gráfica "Calibración: modelo vs. mercado". La elección del ancho y del mínimo está en el recuadro
de [13a.4.6](#13a46-calibracion_historica_mercado-y-_tabla_calibracion). **En R (ilustrativo):** la misma
`tabla_calibracion(c(P), c(diag(3)[y, ]), 0.1, 30)` para cada predictor y `bind_rows(…, .id = "predictor")`.

### 13a.5.10 `efectos_estandarizados`

Líneas 631–660 (lo esencial):

```python
train, _, _ = particiones()
m = modelos_entrenados()[modelo]
for lado, nombre_lado in [("home", "Goles del local"), ("away", "Goles del visitante")]:
    ajuste = m[lado]
    X = preparar_X(train, m[f"columnas_{lado}"])
    de = X.drop(columns="const").std()
    ic = ajuste.conf_int()
    for v in de.index:
        filas.append({"ecuacion": nombre_lado, "variable": v, "etiqueta": etiquetas.get(v, v),
                      "coef": ajuste.params[v], "p_valor": ajuste.pvalues[v],
                      "efecto": np.exp(ajuste.params[v] * de[v]) - 1,
                      "ic_inf": np.exp(ic.loc[v, 0] * de[v]) - 1,
                      "ic_sup": np.exp(ic.loc[v, 1] * de[v]) - 1})
```

**El problema que resuelve:** los coeficientes de M0 no se pueden comparar entre sí porque las variables tienen escalas
distintas (Elo ÷ 400 contra goles por partido). La solución es preguntar: **si la variable sube una desviación
estándar, ¿en qué porcentaje cambian los goles esperados?** Como log λ = … + βx, subir x en una DE (s) multiplica λ
por e^{βs}:

$$\text{efecto}=e^{\beta s}-1,\qquad \text{IC}=\left[e^{\beta_{\text{inf}}\,s}-1,\;e^{\beta_{\text{sup}}\,s}-1\right]$$

- `X.drop(columns="const").std()`: la DE de cada regresor **en entrenamiento**, ya con Elo ÷ 400 (con `n − 1`, como
  `sd()` de R). El resultado no depende de la escala: β·s es lo mismo con Elo en puntos o dividido entre 400.
- `ajuste.conf_int()`: el intervalo de 95 % de cada β, de tipo **Wald** (β ± 1.96 × error estándar).
- `etiquetas.get(v, v)`: la etiqueta en español, o el nombre original si no la hubiera (la sangría rara de ese
  diccionario viene de una edición web del 24-sep; no afecta).

**Ejemplo a mano (Elo, ecuación del local):** β = 0.628257 y s = 0.377071 (es decir, 150.83 puntos de Elo) →
β·s = 0.2369 → e^0.2369 − 1 = **+26.7 %**.

**Salida real:**

| Ecuación | Variable | β | p | Efecto de +1 DE | IC 95 % |
|---|---|---|---|---|---|
| Goles del local | Diferencia de Elo | 0.6283 | < 0.001 | **+26.7 %** | +21.0 a +32.8 % |
| | Goles a favor del local | 0.1678 | < 0.001 | +10.7 % | +6.3 a +15.4 % |
| | Goles recibidos del visitante | 0.0778 | 0.0498 | +4.0 % | **+0.004** a +8.1 % |
| Goles del visitante | Diferencia de Elo | −0.6854 | < 0.001 | **−22.8 %** | −26.6 a −18.7 % |
| | Goles a favor del visitante | 0.1079 | 0.0039 | +6.9 % | +2.2 a +11.9 % |
| | Goles recibidos del local | 0.0281 | 0.506 | +1.5 % | −2.8 a +5.9 % |

La diferencia de Elo domina en las dos ecuaciones; los goles recibidos por el rival pesan poco: en el límite en la
ecuación del local (p = 0.0498, el intervalo apenas excluye el cero) y sin significancia en la del visitante
(p = 0.506). **Quién lo usa:** la gráfica "Qué variables pesan más" y su subtítulo (los dos p-valores).

**En R (verificado: mismos efectos e intervalos):**

```r
efecto <- function(ajuste, cols, ecuacion) {
  X <- train[, cols]; X$elo_diff <- X$elo_diff / 400
  de <- sapply(X, sd)                                          # desviación estándar (n − 1)
  b <- coef(ajuste)[-1]; ic <- confint.default(ajuste)[-1, ]  # intervalos de Wald, como statsmodels
  tibble(ecuacion, variable = cols, efecto = exp(b * de) - 1,
         ic_inf = exp(ic[, 1] * de) - 1, ic_sup = exp(ic[, 2] * de) - 1)
}
m_home <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away, family = poisson, data = train)
efecto(m_home, c("elo_diff", "gf_home", "ga_away"), "Goles del local")
```

**Cuidado en R:** `confint()` de un `glm` calcula intervalos de **perfil de verosimilitud**, no de Wald. Para los goles
recibidos del visitante da −0.000476 a 0.154878 (**cruza el cero**), mientras que Wald (statsmodels y
`confint.default()`) da 0.000072 a 0.155470. Es otra señal de que ese efecto está exactamente en el límite.

> **Decisión:** comparar las variables con el efecto de subir una desviación estándar, exp(β·DE) − 1, con su IC.
> **Alternativas:** (a) mostrar los coeficientes crudos — dependen de la unidad de cada variable; (b) reajustar el
> modelo con variables estandarizadas — mismo resultado, otro modelo que mantener; (c) importancia por permutación
> (cuánto empeora el LogLoss al revolver una variable) — mide aporte predictivo, no tamaño del efecto. No se probaron.
> **Por qué ésta:** sale del mismo modelo, se lee en porcentaje de goles y conserva el intervalo de confianza.
> **Si preguntan:** "Para comparar variables con escalas distintas, medimos cuánto cambian los goles esperados si cada
> una sube una desviación estándar: el Elo mueve ≈ 27 % los goles del local; los goles recibidos del rival, ≈ 4 %."

### 13a.5.11 `dispersion_pearson`

```python
def dispersion_pearson(modelo="M0_Base"):
    """χ² de Pearson / grados de libertad: ≈ 1 si la varianza condicional ≈ media (Poisson)."""
    m = modelos_entrenados()[modelo]
    return {lado: float(m[lado].pearson_chi2 / m[lado].df_resid) for lado in ("home", "away")}
```

El estadístico χ² de Pearson es la suma de los residuos de Pearson al cuadrado, Σ (yᵢ − λᵢ)² / λᵢ. Si los goles son
Poisson, cada término vale en promedio 1, así que dividido entre los grados de libertad residuales debe dar ≈ 1.

**Salida real:** local 1,886.18 / 1,893 = **0.996**; visitante 1,961.89 / 1,893 = **1.036** (1,893 = 1,897 partidos −
4 coeficientes). Prácticamente 1: no hay sobredispersión que justifique una binomial negativa
([11.4.2](11_codigo_analisis_notebook.md#1142-entrenar_modelo)). El tablero lo escribe con dos decimales ("1.00 en el
local y 1.04 en el visitante") en "Por qué importan estos patrones". El notebook imprime el χ² de Pearson en el
resumen del modelo, pero no lo divide entre los grados de libertad: este cociente es complemento del tablero.
**En R (verificado en [`02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R)):**
`sum(residuals(m, type = "pearson")^2) / df.residual(m)`.

### 13a.5.12 `sensibilidad_sin_publico`

Líneas 669–685:

```python
train, val, test = particiones()
inicio, fin = pd.Timestamp("2020-06-17"), pd.Timestamp("2021-05-23")
cerrado = (train["Date"] >= inicio) & (train["Date"] <= fin)
salida = {"partidos_excluidos": int(cerrado.sum()), "inicio": inicio, "fin": fin}
for etiqueta, datos in [("original", train), ("sin_publico", train[~cerrado])]:
    m = entrenar_modelo(datos, *ESPECIFICACIONES["M0_Base"])
    for conjunto, d in [("val", val), ("test", test)]:
        pred = predecir_con_modelo(m, d)
        salida[f"{etiqueta}_{conjunto}_logloss"] = evaluar_predicciones(pred)["LogLoss_1X2"]
        salida[f"{etiqueta}_{conjunto}_p_local"] = float(pred["P_home"].mean())
```

**La pregunta:** 2020/21 se jugó con estadios vacíos (la única temporada en que ganaron más los visitantes) y está dentro
del entrenamiento. ¿Eso le enseñó al modelo una localía demasiado baja y explica la brecha con el mercado?

1. Marca los partidos de entrenamiento entre el **17-jun-2020** (reanudación de 2019/20 tras la pausa) y el
   **23-may-2021** (fin de 2020/21): **472** = 92 de la reanudación + 380 de 2020/21. `~cerrado` es la negación ("los
   que no").
2. Ajusta M0 dos veces: con los 1,897 partidos y sin los 472 (1,425).
3. Compara LogLoss y P(local) media en validación y prueba. Desde la versión final (`e3bd43f`) también devuelve las
   fechas, para que el texto las muestre.

**Salida real:**

| | M0 original | M0 sin los 472 |
|---|---|---|
| LogLoss validación | 0.9895 | 0.9900 |
| LogLoss prueba | 1.0331 | 1.0328 |
| P(local) media en validación | 43.7 % | 45.0 % |
| P(local) media en prueba | 42.6 % | 44.0 % |

Quitar esos partidos sube la probabilidad del local (como se esperaba), pero el LogLoss casi no cambia (−0.0003 en
prueba), mientras que la brecha con el mercado en prueba es de 0.013: **la pandemia no explica la brecha**. Es la
única alternativa de esta sección que se **probó** de verdad (decisión D38 del
[capítulo 19](19_decisiones_y_alternativas.md#d38-sensibilidad-sin-público--probada)). **Quién lo usa:** "Qué significa
para el modelo" (sólo las cifras de prueba y las fechas). En sentido estricto, unos pocos partidos de diciembre de 2020
y de las dos últimas jornadas de 2020/21 tuvieron público limitado: el corte por fechas es una aproximación.

**En R (ilustrativo):** `cerrado <- train$Date >= as.Date("2020-06-17") & train$Date <= as.Date("2021-05-23")`;
`entrenar_modelo(train[!cerrado, ], …)`.

### 13a.5.13 `comparacion_partido_a_partido`

```python
def comparacion_partido_a_partido(conjunto="Prueba") -> pd.DataFrame:
    c = probabilidades_por_conjunto()[conjunto]
    d = c["datos"][CLAVES].copy()
    d["p_local_modelo"] = c["P"]["M0_Base"][:, 0]
    d["p_local_mercado"] = c["P"]["Mercado_apertura"][:, 0]
    d["resultado"] = np.array(["Local", "Empate", "Visitante"])[c["y"]]
    return d
```

Una fila por partido de prueba (419) con la P(gana local) de M0 y la del mercado, y el resultado en palabras
(`np.array([...])[y]` traduce 0, 1, 2 a texto con un solo índice). Es la única función de la sección sin docstring.

**Salida real (primeras filas):** Liverpool–Bournemouth (15-ago-2025): M0 69.4 %, mercado 72.6 %, ganó el local;
Wolves–Man City: 17.3 % y 14.1 %, ganó el visitante; Aston Villa–Newcastle: 42.7 % y 41.2 %, empate. En los 419
partidos la correlación es **r = 0.939** (la calcula `graficas.py`); la diferencia absoluta media es de 4.5 puntos, la
mayor de 19.6, y sólo 43 partidos difieren en más de 10 puntos. **Quién lo usa:** la gráfica "Modelo vs. mercado,
partido a partido". **En R (ilustrativo):** `tibble(p_local_modelo = P_m0[, 1], p_local_mercado = P_mercado[, 1])` y
`cor(...)`.

---

## 13a.6 Sección 6: simulador (líneas 697–744)

`datos_simulador()` calcula **de antemano** el pronóstico de M0 para todos los cruces posibles de la temporada en curso;
la página "Explora un partido" sólo los filtra y dibuja en el navegador ([cap. 13c](13c_codigo_index_quarto.md)).

```python
def datos_simulador(max_goles: int = 5):
    historial = wc_predictor.load_history(ARCHIVO_HISTORICO)
    historial["date"] = pd.to_datetime(historial["date"])
    fecha_corte = historial["date"].max() + pd.Timedelta(days=1)
    df_pre = historial.loc[historial["date"] < fecha_corte].copy()
    temporada_actual = int(fecha_corte.year if fecha_corte.month >= 8 else fecha_corte.year - 1)
    actuales = df_pre[df_pre["date"] >= pd.Timestamp(temporada_actual, 8, 1)]
    equipos = sorted(set(actuales["home_team"]) | set(actuales["away_team"]))
    elo = wc_predictor.build_elo(df_pre, k=K_ELO, scale=ESCALA_ELO)
    modelo = modelos_entrenados()[MODELO_SIMULADOR]

    filas = [
        {"Date": fecha_corte, "HomeTeam": h, "AwayTeam": a,
         **crear_variables_partido(df_pre, fecha_corte, h, a,
                                   elo.get(h, wc_predictor.ELO_INIT), elo.get(a, wc_predictor.ELO_INIT))}
        for h in equipos for a in equipos if h != a
    ]
    pred = predecir_con_modelo(modelo, pd.DataFrame(filas))
    goles = np.arange(11)
    partidos = []
    for r in pred.itertuples(index=False):
        matriz = np.outer(poisson.pmf(goles, r.lambda_home), poisson.pmf(goles, r.lambda_away))
        gh, ga = np.unravel_index(matriz.argmax(), matriz.shape)
        partidos.append({
            "local": r.HomeTeam, "visita": r.AwayTeam,
            "lambda_local": round(float(r.lambda_home), 3), "lambda_visita": round(float(r.lambda_away), 3),
            "p_local": round(float(r.P_home), 4), "p_empate": round(float(r.P_draw), 4),
            "p_visita": round(float(r.P_away), 4),
            "marcador": f"{gh}-{ga}", "p_marcador": round(float(matriz[gh, ga]), 4),
            "matriz": [[round(float(matriz[i, j]), 4) for j in range(max_goles + 1)]
                       for i in range(max_goles + 1)],
        })

    stats = []
    for e in equipos:
        s = wc_predictor.season_stats(df_pre, e, fecha_corte, k=K_SHRINKAGE)
        n_actual = int(((actuales["home_team"] == e) | (actuales["away_team"] == e)).sum())
        stats.append({"equipo": e, "elo": round(float(elo.get(e, wc_predictor.ELO_INIT)), 1),
                      "gf": round(float(s["gf_avg"]), 2), "ga": round(float(s["ga_avg"]), 2),
                      "partidos_temporada": n_actual})
    return {"fecha_corte": fecha_corte, "temporada": _etiqueta_temporada(temporada_actual),
            "equipos": equipos, "partidos": partidos, "stats": stats}
```

**Qué hace, bloque por bloque:**

1. **Histórico con los nombres del módulo.** `load_history()` renombra columnas (`home_team`, `home_score`…), que es lo
   que esperan `build_elo`, `season_stats` y `recent_form`. La segunda conversión de fecha sobra (`load_history` ya la
   hace), pero no estorba.
2. **Corte de información:** el día siguiente al último partido disponible, **15-sep-2026**. `df_pre` = todo lo
   anterior (aquí, todo el histórico). Es la misma regla que `predecir_partido` del notebook (§10), que usa como corte
   el 20-sep-2026; como no hubo partidos entre el 15 y el 20, los resultados son idénticos.
3. **Equipos de la temporada en curso:** 2026/27 (septiembre ≥ agosto). `set(...) | set(...)` une locales y
   visitantes de los partidos desde el 1-ago-2026 y `sorted()` los ordena: **20 equipos** (Arsenal, Aston Villa, …,
   Coventry, Hull, Ipswich, Sunderland, Tottenham).
4. **Elo al corte** con `build_elo` (K = 15): basta el rating final, no el previo a cada partido
   ([cap. 10, 10.9](10_codigo_wc_predictor.md#109-build_elo)).
5. **Las variables de los 380 cruces:** una lista por comprensión con dos `for` (20 × 19 pares con local ≠
   visitante). `**crear_variables_partido(...)` "derrama" el diccionario de 19 variables dentro de la fila.
   `elo.get(h, ELO_INIT)` daría 1500 a un equipo sin rating (no ocurre: los 20 ya jugaron).
6. **λ y 1X2** de M0 para las 380 filas de una vez (`predecir_con_modelo`).
7. **Marcador más probable:** para cada cruce, `np.outer` forma la matriz de 11 × 11 de P(local = i) × P(visita = j)
   con i, j de 0 a 10 (independencia, como en §10); `argmax` + `unravel_index` dan la fila y la columna del máximo.
   Se guarda, redondeada, la submatriz de **0 a 5 goles** (`max_goles=5`) para el mapa de calor.
8. **Estadísticas de cada equipo** para la tabla "¿De dónde sale el pronóstico?": Elo (1 decimal), goles a favor y en
   contra de la temporada (k = 0) y partidos jugados en 2026/27.
9. Devuelve un diccionario que `index.qmd` pasa al navegador con `ojs_define`.

**Salida real:** corte 2026-09-15, temporada 2026/27, 20 equipos, **380 cruces**; tarda ≈ 7.7 s (es casi todo el tiempo
de `preparar_todo()`). Ejemplo, Arsenal (local) – Man City:

| λ Arsenal | λ City | Gana Arsenal | Empate | Gana City | Marcador más probable |
|---|---|---|---|---|---|
| 1.538 | 1.266 | 43.65 % | 25.00 % | 31.35 % | **1–1** (11.80 %) |

Al revés (City local): λ 1.471 y 1.310; 41.02 / 25.29 / 33.69 %; también 1–1 (11.94 %). La matriz que se guarda
(filas = goles de Arsenal, columnas = goles de City, en %):

| | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| **0** | 6.06 | 7.67 | 4.85 | 2.05 | 0.65 | 0.16 |
| **1** | 9.32 | **11.80** | 7.46 | 3.15 | 1.00 | 0.25 |
| **2** | 7.17 | 9.07 | 5.74 | 2.42 | 0.77 | 0.19 |
| **3** | 3.67 | 4.65 | 2.94 | 1.24 | 0.39 | 0.10 |
| **4** | 1.41 | 1.79 | 1.13 | 0.48 | 0.15 | 0.04 |
| **5** | 0.43 | 0.55 | 0.35 | 0.15 | 0.05 | 0.01 |

**Datos de los 380 cruces:** el marcador más probable es 1–1 en 239, 2–0 en 47, 1–0 en 35, 0–1 en 23, 2–1 en 18, 0–2 en
13, 1–2 en 3 y 3–0 en 2: **nunca pasa de 3 goles**, así que siempre cae dentro del mapa de 0 a 5. La matriz de 0 a 5
contiene entre 90.1 % y 99.8 % de la probabilidad (Arsenal–City: 99.3 %); la de 0 a 10, prácticamente toda (en
Arsenal–City falta 8 × 10⁻⁷). λ del local entre 0.66 y 3.15; P(gana local) entre 8.9 % y 85.2 %. Los 20 equipos llevan 4
partidos de 2026/27; por ejemplo, Arsenal: Elo 1787.1, 2.00 goles a favor y 0.25 en contra; Man City: 1779.2, 2.00 y
0.50.

**Diferencias con `predecir_partido` del notebook:** el corte es automático (no una fecha escrita), recorre todos los
pares, no necesita revisar nombres de equipos (salen de los datos), redondea las salidas y agrega la matriz y las
estadísticas. La verificación compara su Arsenal–City contra el del notebook ([13a.7.6](#13a76-tabla_verificacion)).

> **Detalle de eficiencia:** `season_stats` y `recent_form` se recalculan para cada par, así que las estadísticas de
> cada equipo se calculan 38 veces. Calcularlas una vez por equipo sería ≈ 19 veces más rápido; con 7.7 s no hizo
> falta.

**En R (ilustrativo; las funciones de Elo y de variables son las del [capítulo 11](11_codigo_analisis_notebook.md#1111--10-predicción-individual-celdas-2324)):**

```r
cruces <- tidyr::expand_grid(HomeTeam = equipos, AwayTeam = equipos) |> filter(HomeTeam != AwayTeam)   # 380
filas <- purrr::pmap_dfr(cruces, function(HomeTeam, AwayTeam) as_tibble(c(
  list(Date = fecha_corte, HomeTeam = HomeTeam, AwayTeam = AwayTeam),
  crear_variables_partido(previo, fecha_corte, HomeTeam, AwayTeam, elo[[HomeTeam]], elo[[AwayTeam]]))))
pred <- predecir_con_modelo(modelos$M0_Base, filas)
m <- outer(dpois(0:10, pred$lambda_home[1]), dpois(0:10, pred$lambda_away[1]))   # ≈ np.outer
modal <- arrayInd(which.max(m), dim(m)) - 1                                       # ≈ unravel_index(argmax)
round(m[1:6, 1:6], 4)                                                             # la submatriz de 0 a 5
```

`sorted()` de Python ordena por código de carácter; en R hay que pedir `sort(equipos, method = "radix")` para obtener
el mismo orden.

> **Decisión:** precalcular en Python los 380 cruces (λ, 1X2, marcador más probable y matriz de 0 a 5) y que el
> navegador sólo los filtre y dibuje.
> **Alternativas:** (a) **calcular en el navegador** (JavaScript) a partir de los coeficientes y de las variables de
> cada equipo — datos mucho más pequeños, pero habría que reescribir en JavaScript la construcción de variables o, al
> menos, Poisson y Skellam: una tercera implementación del modelo que la verificación no cubriría; (b) **Shiny** (o
> Streamlit/Dash) — el cálculo sería en vivo, pero necesita un servidor encendido; GitHub Pages sólo sirve archivos
> estáticos; (c) **simular** marcadores (Monte Carlo) — introduce ruido: con 10,000 simulaciones el error estándar de
> P(local) es ≈ 0.005 (calculado en el [capítulo 19](19_decisiones_y_alternativas.md#d44-simulador-en-observable-js-con-los-380-cruces-precalculados--razonada)),
> mientras que Skellam y la matriz son exactos; (d) precalcular sólo algunos partidos — limita la exploración.
> **Por qué ésta:** 380 cruces son pocos (≈ 192 KB de datos dentro de un sitio de ≈ 5 MB), se calculan en ≈ 8 s al
> renderizar, usan exactamente el mismo código y modelo que el resto del tablero y el sitio funciona sin servidor.
> **Evidencia en el proyecto:** el Arsenal–City del simulador coincide con la predicción del notebook en las 5 cifras
> verificadas.
> **Si preguntan:** "El simulador no calcula nada en el navegador: Python precalcula los 380 cruces con el mismo M0 y
> la página sólo los busca y los dibuja; por eso funciona en GitHub Pages sin servidor y da lo mismo que el notebook."

---

## 13a.7 Sección 7: calidad de datos y verificación (líneas 747–857)

### 13a.7.1 `estructura_base`

```python
def estructura_base() -> dict:
    crudo = pd.read_csv(ARCHIVO_HISTORICO)
    comunes = [c for c in crudo.columns if crudo[c].notna().all()]
    return {"columnas": crudo.shape[1], "comunes": len(comunes), "complementarias": crudo.shape[1] - len(comunes)}
```

Cuenta las columnas del CSV tal como está (sin las dos que agrega `cargar_historico`): **34**; las que no tienen ningún
vacío, **23** (las comunes a todas las temporadas); el resto, **11** complementarias (cuotas y xG, que sólo existen en
algunas temporadas). **Quién lo usa:** "Datos y procedencia" ("las 23 columnas presentes en todas las temporadas… y 11
complementarias… 9,540 partidos × 34 variables") y la primera fila de la auditoría.

Dos detalles: vuelve a leer el CSV (no tiene caché; se llama dos veces) y mide "comunes" como "sin vacíos", que aquí
coincide con "presentes en todos los archivos" (el criterio de la limpieza, [cap. 3](03_limpieza_de_datos.md)); si una
columna común tuviera un solo vacío, contaría como complementaria. **En R (ilustrativo):**
`sum(colSums(is.na(crudo)) == 0)`.

### 13a.7.2 `temporadas_completas`

```python
def temporadas_completas() -> dict:
    por_temp = cargar_historico().groupby("temporada").size()
    completas = por_temp[por_temp.index < por_temp.index.max()]   # la última está en curso
    return {"n": len(completas), "partidos_min": int(completas.min()), "partidos_max": int(completas.max())}
```

Partidos por temporada, sin la última (la que está en curso). **Salida real:** 25 temporadas completas, todas con 380
partidos (mínimo y máximo 380). Antes de la limpieza nueva, 2003/04 y 2004/05 tenían 335. **Quién lo usa:** la *value
box* "Gana el equipo local" ("25 temporadas completas") y la auditoría. Supone que la última temporada del archivo está
incompleta; si los datos terminaran justo al final de una temporada, la descartaría. **En R (ilustrativo):**
`count(h, temporada) |> filter(temporada < max(temporada))`.

### 13a.7.3 `diagnostico_m4`

```python
def diagnostico_m4() -> dict:
    train, _, _ = particiones()
    X = preparar_X(train, ESPECIFICACIONES["M4_Completo"][0]).to_numpy(dtype=float)
    vif = [variance_inflation_factor(X, i) for i in range(1, X.shape[1])]
    return {"corr_tiros_puerta": float(train["shots_for_home"].corr(train["sot_for_home"])),
            "vif_max": float(max(vif))}
```

Mide qué tanto se **traslapan** las 9 variables de la ecuación del local de M4, en entrenamiento:

- **VIF** (factor de inflación de la varianza) de cada variable: se regresa contra las demás y VIF = 1 / (1 − R²).
  `range(1, …)` se salta la columna 0, la constante. Un VIF de 5 quiere decir que la varianza de ese coeficiente es 5
  veces la que tendría si la variable no estuviera correlacionada con las otras.
- **Correlación** entre los tiros y los tiros a puerta del local (forma reciente).

**Salida real:** correlación **0.855**; VIF máximo **5.56** (`sot_for_home`). El notebook reporta el VIF de M0 (§7);
este es el complemento para M4. Se nota en los coeficientes: los goles recientes a favor del local pasan de +0.0385 en
M1 a −0.0247 en M4 (cambian de signo al entrar tiros y tiros a puerta). **Quién lo usa:** "Variables del modelo" ("En
M4 las variables se traslapan (correlación de 0.86 entre tiros y tiros a puerta; VIF máximo 5.6), lo que vuelve
inestables sus coeficientes"). **En R (verificado en [`02_modelo_poisson.R`](equivalencias_R/02_modelo_poisson.R),
5.560371):** VIF con `lm()` de cada variable contra las demás.

### 13a.7.4 `partidos_excluidos`

```python
def partidos_excluidos() -> pd.DataFrame:
    df = cargar_historico()
    desde = df.loc[df["Date"] >= FECHA_INICIO, CLAVES]
    cruce = desde.merge(cargar_base_modelacion()[CLAVES], on=CLAVES, how="left", indicator=True)
    faltan = cruce.loc[cruce["_merge"] == "left_only", CLAVES].reset_index(drop=True)
    debut = pd.concat([df[["Date", "HomeTeam"]].set_axis(["Date", "equipo"], axis=1),
                       df[["Date", "AwayTeam"]].set_axis(["Date", "equipo"], axis=1)]).groupby("equipo")["Date"].min()
    faltan["debutante"] = [h if debut[h] == f else a for f, h, a in faltan[CLAVES].itertuples(index=False)]
    return faltan
```

1. **Qué falta:** los partidos del histórico desde agosto de 2019 que **no** están en la base de modelación.
   `merge(..., indicator=True)` agrega la columna `_merge` y `"left_only"` marca los que sólo están en el histórico (en
   R, exactamente `anti_join()`).
2. **Debut de cada equipo:** apila locales y visitantes en una sola columna `equipo` (`set_axis` renombra) y toma su
   primera fecha en todo el histórico (en R, `pivot_longer()` + `summarise(min(Date))`).
3. **Quién debutaba:** en cada partido faltante, el equipo cuya primera fecha es la del partido.

**Salida real (4 partidos):** Brentford–Arsenal (13-ago-2021, Brentford); Newcastle–Nott'm Forest (6-ago-2022, Nott'm
Forest); Brighton–Luton (12-ago-2023, Luton); Arsenal–Coventry (21-ago-2026, Coventry). Es el mismo resultado de la
celda 13 del notebook, obtenido por otro camino: el notebook mira los tiros vacíos; el tablero, qué partidos faltan y
quién debutaba ([11.6](11_codigo_analisis_notebook.md#116-nota-los-4-partidos-sin-historial-celdas-1214)).
**Quién lo usa:** "Limpieza y calidad" ("Se excluyeron 4 partidos de equipos debutantes…") y la auditoría.

**En R (ilustrativo):**

```r
faltan <- anti_join(desde, select(base, Date, HomeTeam, AwayTeam), by = c("Date", "HomeTeam", "AwayTeam"))
debut <- h |> select(Date, HomeTeam, AwayTeam) |> tidyr::pivot_longer(c(HomeTeam, AwayTeam), values_to = "equipo") |>
  group_by(equipo) |> summarise(debut = min(Date))
```

### 13a.7.5 `auditoria_datos`

Líneas 794–825: arma una tabla de **10 revisiones** (Revisión · Resultado · Comentario) que el tablero muestra en
"Limpieza y calidad":

| Revisión | Resultado real | Cómo se calcula |
|---|---|---|
| Registros | 9,540 partidos, 34 columnas (18-08-2001 a 14-09-2026) | `len(df)` y `estructura_base()` |
| Duplicados (fecha, local, visitante) | 0 | `df.duplicated(CLAVES).sum()` |
| Resultado (FTR) incongruente con los goles | 0 | reconstruye H/D/A con los goles y compara con `FTR` |
| Temporadas incompletas | Ninguna ("Las 25 temporadas completas tienen 380 partidos…") | temporadas con menos partidos que el máximo, sin contar la última |
| Tiros a puerta mayores que tiros | 1: Newcastle–West Ham, 15-ago-2021 ("error de la fuente; no se corrigió") | `(HST > HS) \| (AST > AS)` |
| Goles mayores que tiros a puerta | 50 ("plausible: autogoles; no es error") | `FTHG > HST` más `FTAG > AST`, por equipo y partido |
| Cuotas Bet365 | "faltan en 2001/02" | **texto fijo** |
| Cuotas promedio de apertura y cierre | "sólo desde 2019/20" | **texto fijo** |
| Goles esperados (xG) | "sólo 2026/27" | **texto fijo** |
| Partidos excluidos de la base de modelación | 4 (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026) | `partidos_excluidos()` |

- Usa *f-strings* con formato: `{len(df):,}` pone separador de miles (9,540) y `{r.Date:%Y-%m-%d}` da formato a la
  fecha. `"; ".join(...) or "—"` escribe un guion si no hay casos.
- Tres filas son **texto fijo**, no cálculo. Las comprobamos contra los datos y son ciertas: Bet365 tiene 0 partidos en
  2001/02 y 380 desde 2002/03; las cuotas promedio empiezan en 2019/20; xG sólo existe en los 40 partidos de 2026/27.
  La nota "(una primera lectura descartaba 90 de 2003/04 y 2004/05)" también es fija: es registro histórico de la
  limpieza ([cap. 3](03_limpieza_de_datos.md)).

**En R (ilustrativo):** `sum(duplicated(h[, c("Date", "HomeTeam", "AwayTeam")]))`;
`sum(case_when(h$FTHG > h$FTAG ~ "H", h$FTHG < h$FTAG ~ "A", .default = "D") != h$FTR)`;
`sum(h$HST > h$HS | h$AST > h$AS)`.

### 13a.7.6 `tabla_verificacion`

Líneas 828–857:

```python
def tabla_verificacion(metricas: pd.DataFrame, simulador) -> pd.DataFrame:
    """Compara cifras del dashboard contra las que imprimió Analisis.ipynb en su última ejecución."""
    publicadas = cifras_publicadas_notebook()
    filas = []
    m = metricas.set_index(["conjunto", "predictor"])["logloss"]
    orden = {nombre: i for i, nombre in enumerate(NOMBRES)}
    claves = sorted(publicadas["logloss"], key=lambda k: (k[0] != "Validación", orden.get(k[1], 99)))
    for conjunto, pred in claves:
        valor = publicadas["logloss"][(conjunto, pred)]
        calc = m.loc[(conjunto, pred)]
        filas.append({"Cifra": f"LogLoss {NOMBRES[pred]} ({conjunto.lower()})",
                      "Notebook": f"{valor:.6f}", "Dashboard": f"{calc:.6f}",
                      "Coincide": abs(calc - valor) < 5e-7})
    ej = next(p for p in simulador["partidos"] if p["local"] == "Arsenal" and p["visita"] == "Man City")
    comparar = [("λ Arsenal (M0)", "lambda_home", ej["lambda_local"], 3),
                ("λ Man City (M0)", "lambda_away", ej["lambda_visita"], 3),
                ("P(victoria Arsenal) M0", "P_home", ej["p_local"], 4),
                ("P(empate) M0", "P_draw", ej["p_empate"], 4),
                ("P(victoria Man City) M0", "P_away", ej["p_visita"], 4)]
    for nombre, clave, valor, dec in comparar:
        if clave not in publicadas["ejemplo"]:
            continue
        ref = round(publicadas["ejemplo"][clave], dec)
        filas.append({"Cifra": f"Ejemplo Arsenal–Man City: {nombre}", "Notebook": f"{ref:.{dec}f}",
                      "Dashboard": f"{valor:.{dec}f}", "Coincide": abs(valor - ref) < 0.6 * 10 ** -dec})
    # Si el notebook se guardó sin salidas no hay contra qué comparar: se marca como diferencia.
    if not publicadas["logloss"] or len(publicadas["ejemplo"]) < len(comparar):
        filas.append({"Cifra": "Cifras publicadas en Analisis.ipynb", "Notebook": "no encontradas",
                      "Dashboard": "—", "Coincide": False})
    return pd.DataFrame(filas)
```

**Qué hace:**

1. **Ordena** las cifras publicadas: primero validación (`k[0] != "Validación"` vale `False` para validación, y
   `False` se ordena antes que `True`) y, dentro de cada periodo, en el orden de `NOMBRES`.
2. **Compara cada LogLoss** publicado con el calculado por el tablero. La tolerancia, **5 × 10⁻⁷**, es media unidad de
   la sexta cifra decimal: como el notebook imprimió 6 decimales, cualquier valor que **redondee** a lo impreso pasa.
   La diferencia más grande es 4.27 × 10⁻⁷ (M3 en prueba: 1.0338675729 contra 1.033868 impreso).
3. **El ejemplo Arsenal–Man City:** `next(...)` toma el primer cruce del simulador que cumpla la condición. λ se compara
   con 3 decimales y las probabilidades con 4: los dos valores, redondeados igual, deben coincidir (la tolerancia de
   0.6 unidades del último decimal sólo absorbe el ruido de la aritmética).
4. **Si faltan cifras** (no hay LogLoss o el ejemplo está incompleto), agrega una fila "no encontradas" con ✗.

**Salida real: 17 de 17 ✓**

| Cifra | Notebook | Tablero |
|---|---|---|
| LogLoss M0 · M1 · M2 · M3 · M4 (validación) | 0.989547 · 0.987603 · 0.980718 · 0.982319 · 0.978612 | iguales |
| LogLoss mercado de apertura (validación) | 0.970552 | 0.970552 |
| LogLoss M0 · M1 · M2 · M3 · M4 (prueba) | 1.033076 · 1.034699 · 1.037331 · 1.033868 · 1.036739 | iguales |
| LogLoss mercado de apertura (prueba) | 1.020000 | 1.020000 |
| Ejemplo: λ Arsenal · λ Man City | 1.538 · 1.266 | 1.538 · 1.266 |
| Ejemplo: P(Arsenal) · P(empate) · P(Man City) | 0.4365 · 0.2500 · 0.3135 | 0.4365 · 0.2500 · 0.3135 |

**Quién lo usa:** la pestaña "Reproducibilidad": la tabla con ✓/✗ y la frase "todas coinciden" (o "HAY DIFERENCIAS:
revisar antes de publicar" si alguna fila es ✗).

**Qué demuestra** (y qué no):

| Demuestra | No demuestra |
|---|---|
| Que las funciones copiadas reproducen las del notebook (12 LogLoss de 5 modelos y el mercado) | Nada sobre los complementos (bootstrap, calibración…), que el notebook no calcula |
| Que `premier_training_data.csv` es la misma base con la que el notebook obtuvo sus resultados | Que estén **todas** las cifras: si se pierde la salida de una celda, compara menos y no avisa ([13a.1.7](#13a17-cifras_publicadas_notebook)) |
| Que K y k del módulo coinciden con los del notebook (el ejemplo usa el Elo y las variables calculados por el tablero) | Que el notebook sea correcto: compara contra él, no contra una verdad externa |
| Que en GitHub Actions, con las versiones de `requirements.txt`, salen las mismas cifras | — y no detiene la publicación si algo falla: sólo avisa |

**Historia:** la primera versión (22-sep) comparaba contra **15 cifras copiadas a mano** (`REPORTADO_NOTEBOOK`, con los
valores de K = 30: M0 0.983690 en validación, 1.030556 en prueba, …). Al cambiar el modelo a K = 15, esas cifras
quedaron viejas. El 30-sep se cambió a leer las salidas guardadas: **16 cifras** (en ese momento la prueba evaluaba M0,
M1, M2 y M4). Cuando Daniel agregó M3 a la prueba, la tabla pasó **sola** a 17, sin tocar el tablero.

**En R (ilustrativo):** `abs(calc - valor) < 5e-7` para cada LogLoss y `abs(valor - round(ref, dec)) < 0.6 * 10^-dec`
para el ejemplo, con las cifras que devuelve `cifras_publicadas_notebook()` en R ([13a.1.7](#13a17-cifras_publicadas_notebook), verificado).

> **Decisión:** verificar el tablero contra las **salidas guardadas** del notebook, leídas automáticamente en cada
> render.
> **Alternativas:** (a) **cifras copiadas a mano** — así era la primera versión; en contra: la lista también se
> desactualiza (con K = 15 las 15 cifras dejaron de valer); (b) **no verificar** y confiar en que las copias son
> fieles; (c) **ejecutar el notebook** en GitHub Actions y comparar contra su resultado fresco — a favor: no depende de
> que alguien guarde las salidas; en contra: minutos de cómputo por render; (d) **pruebas automáticas** (por ejemplo
> con `pytest`) que **detengan la publicación** si algo no coincide — a favor: nunca se publicaría algo
> inconsistente; en contra: más infraestructura (hoy el tablero avisa, pero publica). No se probaron.
> **Por qué ésta:** compara contra lo que el equipo de Código realmente reportó, sin copiar nada, y se adapta sola a lo
> que el notebook imprima.
> **Evidencia en el proyecto:** 17 de 17 ✓, también en el sitio construido por GitHub Actions; pasó de 16 a 17 cifras
> sola cuando se agregó M3 a la prueba; diferencia máxima 4.27 × 10⁻⁷; y probamos que, con el notebook sin salidas,
> marca ✗ y el texto cambia a "HAY DIFERENCIAS".
> **Si preguntan:** "El tablero lee las salidas que el notebook dejó guardadas y compara 17 cifras contra las suyas;
> coinciden las 17, también en el servidor de GitHub. Cuando Daniel agregó M3, la verificación lo incorporó sola."

(Es la decisión D41 del [capítulo 19](19_decisiones_y_alternativas.md#d41-verificación-automática-contra-las-salidas-del-notebook--razonada).)

---

## 13a.8 Cierre: `preparar_todo()` y el bloque `__main__` (líneas 860–906)

### `preparar_todo()`

```python
@lru_cache(maxsize=None)
def preparar_todo():
    """Calcula todo lo que usa el dashboard en una sola pasada."""
    metricas = tabla_metricas()
    elo_tabla = resultado_por_elo()
    simulador = datos_simulador()
    return {
        "general": resumen_general(),
        "temporadas": resumen_temporadas(),
        ...
        "verificacion": tabla_verificacion(metricas, simulador),
        ...
        "margen": {k: v["margen"] for k, v in probabilidades_por_conjunto().items()},
        "particiones": {k: len(v) for k, v in zip(("train", "val", "test"), particiones())},
    }
```

- Es la **única** función que llama `index.qmd`: `d = dd.preparar_todo()` en su chunk de preparación. Devuelve un
  diccionario con **28 entradas**; cada tarjeta toma la suya (`d["metricas"]`, `d["simulador"]`…).
- Calcula primero las tres piezas que se usan más de una vez: `metricas` (para la fracción de mejora, el Δ contra M0 y
  la verificación), `elo_tabla` (para la ventaja de jugar en casa) y `simulador` (para la página del simulador y la
  verificación).
- `{k: v["margen"] for …}` es una comprensión de diccionario: `{"Validación": 4.49, "Prueba": 5.84}`. `zip` empareja
  los nombres con las tres tablas de `particiones()`: `{"train": 1897, "val": 380, "test": 419}`.
- Con la caché, el tablero calcula todo **una sola vez** (≈ 8 s); una segunda llamada devuelve el mismo diccionario en
  menos de un microsegundo.

| Entrada | Función | Entrada | Función |
|---|---|---|---|
| `general` | `resumen_general` | `calibracion_modelos` | `calibracion_modelo_vs_mercado` |
| `temporadas` | `resumen_temporadas` | `efectos` | `efectos_estandarizados` |
| `favorito` | `resultado_del_favorito` | `dispersion` | `dispersion_pearson` |
| `elo` | `resultado_por_elo` | `sensibilidad` | `sensibilidad_sin_publico` |
| `ventaja_elo` | `ventaja_local_en_elo` | `partido_a_partido` | `comparacion_partido_a_partido` |
| `calibracion_mercado` | `calibracion_historica_mercado` | `simulador` | `datos_simulador` |
| `poisson` | `ajuste_poisson_goles` | `auditoria` | `auditoria_datos` |
| `metricas` | `tabla_metricas` | `verificacion` | `tabla_verificacion` |
| `fraccion_mejora` | `fraccion_de_mejora` (prueba) | `config_notebook` | `configuracion_notebook` |
| `fraccion_mejora_val` | `fraccion_de_mejora` (validación; **no se muestra**) | `estructura` | `estructura_base` |
| `bootstrap` | `tabla_bootstrap` | `temporadas_completas` | `temporadas_completas` |
| `delta_m0` | `delta_contra_m0` | `diagnostico_m4` | `diagnostico_m4` |
| `brecha` | `brecha_por_resultado` | `excluidos` | `partidos_excluidos` |
| `margen` | margen de la apertura por periodo | `particiones` | tamaños de los tres periodos |

Las tarjetas que usa cada entrada están en la [tabla de piezas](#todas-las-piezas-del-archivo) del panorama.

**En R (ilustrativo):** `preparar_todo <- memoise::memoise(function() list(general = resumen_general(), temporadas =
resumen_temporadas(), …))`, y en el chunk de configuración de un R Markdown, `d <- preparar_todo()`.

### El bloque `if __name__ == "__main__"`

```python
if __name__ == "__main__":
    d = preparar_todo()
    pd.set_option("display.width", 200)
    print(d["metricas"].round(4).to_string())
    print(d["bootstrap"].round(4).to_string())
    print(d["verificacion"].to_string())
    print("Fracción de mejora (prueba, validación):", round(d["fraccion_mejora"], 3), round(d["fraccion_mejora_val"], 3))
    print("Ventaja local en Elo:", round(d["ventaja_elo"], 1))
    print("Simulador:", d["simulador"]["fecha_corte"].date(), len(d["simulador"]["partidos"]), "cruces")
```

Python le pone a cada archivo la variable `__name__`: vale `"__main__"` cuando el archivo se ejecuta directamente
(`python datos_dashboard.py`) y `"datos_dashboard"` cuando se importa. Por eso este bloque **no corre** dentro del
tablero; sirve para revisar las cifras desde una terminal. En R, el equivalente para scripts es
`if (sys.nframe() == 0L) { ... }` ([cap. 10, 10.6](10_codigo_wc_predictor.md#106-el-bloque-que-se-ejecuta-al-importar)).

**Salida real** (2-oct-2026, ≈ 12 s; se omiten las tablas, que son las de [13a.5.4](#13a54-tabla_metricas),
[13a.5.6](#13a56-_bootstrap-y-tabla_bootstrap) y [13a.7.6](#13a76-tabla_verificacion)):

```text
Fracción de mejora (prueba, validación): 0.804 0.825
Ventaja local en Elo: 50.0
Simulador: 2026-09-15 380 cruces
```

---

## 13a.9 Detalles raros y comentarios desactualizados

Ninguno cambia una cifra del tablero, pero conviene conocerlos por si alguien lee el código durante la exposición.

| # | Dónde | Qué pasa | Si preguntan |
|---|---|---|---|
| 1 | Docstring de `_importar_wc_predictor` (líneas 56–59) | Dice que `wc_predictor` "imprime el ranking Elo" al importarse; ya no lo hace desde el 30-sep | "Quedó de la versión anterior del módulo; el silencio sobra, el cambio de carpeta no" |
| 2 | Encabezados de sección | Los de las secciones 0 y 1 se borraron en una edición web (22-sep); la numeración visible empieza en 2 | "La primera parte, sin encabezado, es la configuración" |
| 3 | Encabezado de la sección 2 | Dice "secciones 2 y 4" del notebook, pero incluye `probabilidades_mercado`, que corresponde a la §8 | — |
| 4 | Docstring del módulo | Dice que los complementos están marcados "en cada función"; algunos lo están sólo por el encabezado de su sección y `comparacion_partido_a_partido` no tiene docstring | — |
| 5 | `resultado_del_favorito` | "24 temporadas" con Bet365: son las completas; con 2026/27, 25 | — |
| 6 | `resumen_general`, `resumen_temporadas`, `ajuste_poisson_goles` | `temporada <= 2025` escrito a mano (habrá que cambiarlo cuando termine 2026/27) | "`temporadas_completas()` sí lo detecta sola" |
| 7 | `auditoria_datos` | Tres filas son texto fijo (Bet365, cuotas promedio, xG) y la nota de los 90 partidos recuperados también; las comprobamos y son ciertas | — |
| 8 | `brecha_por_resultado` | El docstring dice que "M0 no se eligió con ninguno de los dos periodos"; los coeficientes no, pero la preferencia por M0 sí miró la prueba | Ver [capítulo 9](09_evaluacion_y_validacion.md) |
| 9 | `MODELO_SIMULADOR` | Se justifica como "el mejor en prueba": eso usa la prueba para elegir; la parsimonia basta como razón | "Lo elegimos por simple; además fue el mejor en prueba" |
| 10 | `datos_simulador` | Convierte la fecha dos veces y recalcula las estadísticas de cada equipo 38 veces (≈ 7.7 s) | "Se podría acelerar; no hacía falta" |
| 11 | `estructura_base` | Vuelve a leer el CSV (sin caché) y define "comunes" como "sin vacíos" | — |
| 12 | `temporadas_completas` | Supone que la última temporada del archivo está en curso | — |
| 13 | `preparar_todo` | Calcula cosas que el tablero no muestra: `fraccion_mejora_val`, `fecha_min`, los goles promedio, `local_es_favorito`, las cifras de validación de la sensibilidad | "Se usan para revisar desde la terminal" |
| 14 | `tabla_verificacion` | Si se pierde la salida de una sola celda, compara menos cifras sin avisar; y si algo no coincide, avisa pero no detiene la publicación | Ver [13a.7.6](#13a76-tabla_verificacion) |
| 15 | `efectos_estandarizados` | El diccionario de etiquetas tiene una sangría distinta (edición web del 24-sep) | Cosmético |
| 16 | `index.qmd` (no este archivo) | Algunos números son texto fijo, no salen del backend: el "3" de la *value box* "Variables en el mejor modelo", "10,000 remuestreos" en un subtítulo y "Del 18 de agosto de 2001"; los tres son correctos | Ver [cap. 13c](13c_codigo_index_quarto.md) |

---

## 13a.10 Preguntas rápidas

**¿De dónde salen las cifras del tablero?** De `datos_dashboard.py`, que las recalcula en cada render con los archivos
del equipo: `E0_consolidado.csv`, `premier_training_data.csv`, `wc_predictor.py` y el propio `Analisis.ipynb` (su código
y sus salidas). Ninguna se copió a mano.

**¿Por qué copiar funciones del notebook en vez de importarlas?** Porque un notebook no se puede importar como un
módulo; ejecutarlo tardaría minutos en cada render. Se copiaron con los mismos nombres y la misma lógica, y la
verificación demuestra que dan lo mismo (17 de 17).

**¿Qué pasa si el equipo cambia K en `wc_predictor.py`?** El tablero lo lee solo (textos y simulador). Los modelos, en
cambio, usan la base que exportó el notebook, que no cambia hasta que el notebook se vuelva a ejecutar con ese K;
mientras no coincidan, el ejemplo Arsenal–City de la verificación saldría con ✗.

**¿Y si el notebook se guarda sin salidas?** La verificación no encuentra contra qué comparar, marca ✗ y el tablero dice
"HAY DIFERENCIAS: revisar antes de publicar" (se publica de todos modos).

**¿Qué hace `@lru_cache`?** Guarda el resultado de la primera llamada y lo devuelve en las siguientes (en R,
`memoise`). Así el histórico se lee una vez aunque se pida 11 veces.

**¿Qué significa "distinta de cero" en la tabla del bootstrap?** Que el intervalo de 95 % de la diferencia de LogLoss,
obtenido remuestreando los partidos 10,000 veces, no incluye el cero. M0 contra el mercado en prueba sola no lo es
(−0.0005 a +0.0264); con validación y prueba juntas, sí (+0.0064 a +0.0255).

**¿Por qué el simulador usa M0?** Por parsimonia (3 variables por ecuación contra 9 de M4) y porque fue el mejor en
prueba; además es el modelo del ejemplo del notebook, lo que permite verificarlo.

**¿Por qué 380 cruces?** 20 equipos × 19 rivales, con local y visitante distintos: una temporada completa de ida y
vuelta.

**¿Por qué el marcador más probable casi siempre es 1–1?** Porque es un solo marcador, mientras que "gana el local" se
reparte entre 1–0, 2–0, 2–1… El 1–1 es el más probable en 239 de los 380 cruces, aunque en muchos de ellos el resultado
más probable sea la victoria de alguien.

**¿De dónde sale "jugar en casa vale ≈ 50 puntos Elo"?** De interpolar en qué diferencia de Elo el local y el
visitante ganan con la misma frecuencia, usando los deciles de 2019/20–2026/27: −50.03.

---

## 13a.11 Cómo se verificó este capítulo

| Qué | Cómo | Resultado |
|---|---|---|
| Código | Copiado del archivo entregado (`e3bd43f`, 906 líneas); historial con `git log` | — |
| Salidas de ejemplo | Ejecutando el propio módulo con Python 3.10 (2-oct-2026), sin modificarlo | Todas las cifras de este capítulo |
| Casos límite | Copias del notebook modificadas en memoria (sin salidas; sin la celda 22; `N_FORMA = 12`; sin la rejilla comentada; comillas simples) | Tablas de [13a.1.6](#13a16-configuracion_notebook) y [13a.1.7](#13a17-cifras_publicadas_notebook) |
| Estabilidad del bootstrap | La misma `_bootstrap` con otras semillas (1–100) y con B = 1,000 y 100,000 | [13a.5.6](#13a56-_bootstrap-y-tabla_bootstrap) |
| Alternativas de calibración | La misma `_tabla_calibracion` con otros anchos y mínimos | [13a.4.6](#13a46-calibracion_historica_mercado-y-_tabla_calibracion) |
| Bloques de R **(verificado)** | R 4.3.2: `configuracion_notebook` y `cifras_publicadas_notebook`; `resultado_por_elo` y `ventaja_local_en_elo`; `efectos_estandarizados` | Mismos resultados que Python |
| Bloques de R **(ilustrativo)** | Los demás; varios equivalen a scripts ya verificados de [`equivalencias_R`](equivalencias_R/README.md) o del [capítulo 11](11_codigo_analisis_notebook.md) | — |

Lo que **no** se probó en el proyecto y aparece aquí como alternativa razonada: calcular el simulador en el navegador,
ejecutar el notebook desde el tablero, pruebas automáticas que detengan la publicación, otros métodos para medir la
ventaja de jugar en casa y otras formas de agrupar la calibración (salvo las que se calcularon para esta guía con la
misma función). Diebold–Mariano y el bootstrap por bloques los calculó la guía aparte (capítulo 19, D36); no forman
parte del tablero.

[← El dashboard](13_dashboard.md) · [Índice](README.md) · [Siguiente: `graficas.py` →](13b_codigo_graficas.md)
