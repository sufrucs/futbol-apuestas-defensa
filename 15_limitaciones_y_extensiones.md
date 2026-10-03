# 15. Limitaciones y extensiones

[← Publicación en GitHub](14_publicacion_en_github.md) · [Índice](README.md) · [Siguiente: guion de la exposición →](16_guion_exposicion.md)

Las instrucciones piden que cualquier integrante pueda explicar "cuáles son las principales
limitaciones". Conocerlas **no debilita el proyecto: demuestra que se entiende**. La regla para
hablar de ellas es: **qué es → qué efecto tiene (con número si lo hay) → cómo se corregiría.**

Las cifras salen del notebook, el tablero y el reporte; las marcadas como **cálculo propio de la guía** se hicieron
*después de la entrega*, con el código y los datos del proyecto, y sólo se mencionan si preguntan (aclarando que son
posteriores). Qué haríamos distinto, con sus fichas de decisión: [capítulo 19, sección 19.10](19_decisiones_y_alternativas.md#1910-decisiones-que-hoy-tomaríamos-distinto).

## 15.1 Las cinco que hay que saber de memoria

| # | Limitación | Efecto medido | Cómo se corregiría |
|---|---|---|---|
| 1 | **Independencia de goles** (dos Poisson independientes) | **Subestima los empates en validación y prueba:** en prueba M0 asignó 23.6 % en promedio y ocurrieron 28.2 % (el mercado asignó 24.5 %). Pero en entrenamiento no los subestima (22.7 % esperado, 22.8 % real) y el ρ de Dixon–Coles sale ≈ −0.008 (cálculo propio): el problema es **pequeño** y parece de tasa de empates, no de independencia | Corrección de **Dixon–Coles** (1997) o Poisson bivariada (no la binomial negativa) |
| 2 | **Parámetros calibrados sólo en parte:** K = 15 y k = 0 se calibraron (rejilla de 35 combinaciones, sólo con M0) y K quedó en el **borde inferior**; el decaimiento 0.85, la ventana de 10 partidos y la escala 400 no se optimizaron | El efecto de K y k es **pequeño e inestable entre temporadas**: las 35 combinaciones caben en 0.0055 de LogLoss y la configuración anterior (K = 30, k = 10) salió algo mejor fuera de muestra (diferencia no significativa; cálculo propio) | Probar **K < 15**; calibrar también el decaimiento y la ventana con la misma validación temporal |
| 3 | **Sin información de alineaciones, lesiones ni noticias** | Es la ventaja principal del mercado; el **cierre**, con más información, es aún mejor (1.0170 contra 1.0200 de la apertura) | Variables de disponibilidad de jugadores; comparar contra cuotas de cierre |
| 4 | **Equipos ascendidos y Elo solo de Premier** | Un equipo que regresa conserva su Elo de hace años; uno nuevo empieza en 1,500; su "temporada anterior" es el promedio de la liga | Elo que incluya la segunda división, o una regresión parcial a la media al inicio de cada temporada |
| 5 | **Muestra de prueba de 419 partidos, y sin fecha de cierre** | Intervalos amplios: la brecha M0 − mercado en prueba (+0.013) tiene IC de −0.0005 a +0.026; M4 − M0 no es concluyente en prueba y, en validación, es significativa por un margen mínimo y frágil. Además la prueba empieza el 1-ago-2025 y **no termina**: si se agregan partidos al CSV, cambian sus cifras | Evaluar la siguiente temporada completa con una fecha de cierre fija; juntar periodos (con 799 partidos la brecha sí es distinta de cero) |

## 15.2 Todas las limitaciones, por tipo

### Del modelo

| Limitación | Detalle | Qué tan grave |
|---|---|---|
| Independencia condicional de goles | La literatura (Dixon y Coles, 1997) documenta que el 0–0 y el 1–1 ocurren algo más de lo que predice la independencia. En nuestros datos de entrenamiento los marcadores bajos salen bien (0–0: 5.9 % esperado contra 5.6 % observado; 1–1: 10.7 % contra 10.9 %) y el ρ de Dixon–Coles sale ≈ −0.008, indistinguible de cero (cálculo propio; [cap. 7](07_de_goles_a_probabilidades.md#76-la-debilidad-del-supuesto-los-empates)) | **Media**: los empates aportan +0.0078 de los +0.0159 de brecha con el mercado (las victorias locales aportan +0.0185 y en las visitantes el modelo es mejor, −0.0104). Lo que falló en validación y prueba parece ser que hubo **más empates** (24.5 % y 27.4 % de 2024/25 y 2025/26 contra 22.8 % en el entrenamiento), más que un defecto probado del supuesto |
| Sobreconfianza con favoritos | Cuando M0 dice 64.4 %, ocurre 57.0 %; cuando dice 74.1 %, ocurre 68.1 % ([cap. 12](12_resultados.md#calibración-lo-que-dice-cada-uno-contra-lo-que-ocurre)); el mercado está mejor calibrado en esa zona | Media: hay pocos pronósticos en esos grupos (135 y 47), así que es una señal, no una prueba |
| Coeficientes fijos en el tiempo | Se estiman una vez con 2019–2024 y no se actualizan, aunque el fútbol cambia (reglas, estilos, tiempo añadido) | Media; un modelo que se reentrena cada jornada lo resolvería |
| La ventaja de local es la misma para todos | Las dos ecuaciones separadas dan una ventaja promedio (entre equipos idénticos, λ = 1.486 contra 1.248; [cap. 6](06_poisson_y_regresion.md#63-las-dos-ecuaciones-del-proyecto)); las constantes no se distinguen de cero. No hay estadios "más difíciles" | Baja |
| Modelo predictivo, no causal | Los coeficientes indican **asociación**. "Más Elo" no **causa** más goles; ambos reflejan la calidad del equipo | Es de interpretación: no afecta las predicciones, pero cambia qué se puede afirmar |
| Selección de modelo con información de prueba | La validación eligió M4, por un margen mínimo y frágil (IC hasta −0.00005), pero se presenta M0 porque es más simple y fue mejor en prueba ([cap. 18](18_hallazgos_y_pendientes.md), C6) | Se reconoce abiertamente; hay que confirmarla con la siguiente temporada |
| K y k calibrados sólo con M0 | La rejilla usa el LogLoss de M0 en tres temporadas anteriores a la validación; M1–M4 usan los mismos K y k. K quedó en el borde inferior y los pliegues no coinciden (2022/23 prefería K = 35) | Baja: K y k sólo afectan a las variables base, que están en los cinco modelos, y su efecto es pequeño ([cap. 12](12_resultados.md#la-configuración-anterior-de-k-y-k-fuera-de-muestra)) |

### De las variables

| Limitación | Detalle |
|---|---|
| Parámetros operativos | **K y k sí se calibraron** (K = 15 y k = 0, validación temporal de ventana creciente, 35 combinaciones, sólo con M0), pero K quedó en el borde inferior de la rejilla y su efecto es pequeño; el **decaimiento 0.85, la ventana de 10 partidos y la escala 400 no se optimizaron** |
| Elo sin margen de victoria | Ganar 1–0 o 5–0 mueve el Elo igual |
| Elo sin localía | Las expectativas de Elo no suman la ventaja de local. El modelo la estima aparte, con sus dos ecuaciones separadas (local y visitante) |
| Forma de ascendidos | Sus últimos 10 partidos en la base pueden ser de hace años (Norwich en 2019 usaba partidos de 2016) |
| Sin xG | Los goles esperados (xG) solo existen en 2026/27 (40 partidos), así que no pudieron usarse |

> **Decisión:** calibrar sólo K y k con validación temporal y dejar fijos el decaimiento (0.85), la ventana de la forma
> (10 partidos) y la escala del Elo (400). · **Alternativas:** (a) calibrar también el decaimiento y la ventana — a
> favor: los datos decidirían, en vez de valores razonables; en contra: la forma sólo entra en M1–M4, que no mejoraron a
> M0 en prueba, y cada parámetro más multiplica la rejilla (construir la base de M0 tarda ≈ 40 s por combinación,
> cálculo propio), así que no se hizo; (b) calibrar también la escala 400 — a favor: recorrería todas las opciones del
> Elo; en contra: es redundante con K (si se multiplican la escala y K por el mismo número, las probabilidades
> esperadas no cambian), así que calibrar K con la escala fija ya la recorre; (c) calibrar K y k con M4 o con cada
> modelo — a favor: cada modelo tendría sus propios valores; en contra: K y k sólo afectan a las variables base, que
> están en los cinco modelos, y la base de M0 se construye más rápido (no se probó). · **Por qué ésta:** K y k mueven las
> variables de M0, que están en los cinco modelos, y con dos parámetros la rejilla se revisa completa; la forma aportó
> poco (M1 − M0 = −0.0019 en validación y +0.0016 en prueba), así que no era la prioridad. · **Si preguntan:**
> "Calibramos K y k porque afectan a las variables de los cinco modelos. El decaimiento y la ventana de la forma los
> dejamos en valores razonables, porque la forma casi no mejoró a M0; y la escala 400 es redundante con K. Ampliar la
> calibración, empezando por valores de K menores que 15, es la extensión natural."

### De los datos

| Limitación | Detalle | Impacto |
|---|---|---|
| 2003/04 y 2004/05 (**resuelto** en la versión final) | La limpieza anterior descartaba las filas con formato irregular y dejaba 335 de 380 partidos en cada una (90 en total). La versión final lee todos los renglones: las 25 temporadas completas tienen 380 ([cap. 3](03_limpieza_de_datos.md)) | Ninguno ya: recuperarlos movió el modelo en la quinta cifra decimal (cálculo propio) |
| La fuente sigue cambiando | 2026/27 está en curso y Football-Data actualiza su archivo cada semana (y a veces corrige temporadas pasadas): una descarga nueva no da la misma base. La referencia es el `E0_consolidado.csv` del repositorio, con su huella SHA-256 | Afecta la reproducción, no las cifras entregadas |
| Un error de la fuente | Newcastle–West Ham (15-ago-2021): el visitante aparece con 8 tiros y 9 a puerta | Despreciable |
| Cuotas promedio desde 2019/20 | Por eso la modelación empieza en 2019 | Define el periodo |
| Solo Premier League | Otras ligas pueden comportarse distinto | Limita la generalización |

### De la evaluación

| Limitación | Detalle | Qué tan grave |
|---|---|---|
| Muestras de 380 y 419 partidos | Con 380 partidos, el error estándar de la diferencia de LogLoss entre M4 y M0 es de ≈ 0.0055 (cálculo propio, [cap. 9](09_evaluacion_y_validacion.md)): diferencias de ≈ 0.01 están en el límite de lo detectable | Media |
| **La prueba no tiene fecha de cierre** | Empieza el 1-ago-2025 (`FECHA_PRUEBA`) y llega hasta el último partido del archivo (14-sep-2026, 419 partidos). Si se agregan partidos a `E0_consolidado.csv`, cambian las cifras de prueba, la comparación con el mercado y el tablero (README, §5.3; [D32](19_decisiones_y_alternativas.md#d32-partición-temporal-1897--380--419--razonada)) | Media: se maneja fijando la base con su huella SHA-256 |
| Intervalos que tratan los partidos como independientes | El bootstrap remuestrea partidos. Con Diebold–Mariano o con bootstrap por fechas o semanas, las dos comparaciones al límite (M4 − M0 en validación; M0 − mercado en prueba) cambian de lado ([D36](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)) | Media: sólo afecta a esos dos casos; lo robusto no cambia |
| Dos periodos de evaluación | Una validación (2024/25) y una prueba (2025/26 más un tramo de 2026/27): el orden de los modelos se invierte entre ellos (M4 primero en uno; M0 en el otro) | Media: por eso se presenta M0 por parsimonia y se pide confirmarlo con otra temporada |

> **Decisión:** dejar la prueba abierta: todos los partidos desde el 1-ago-2025 (419 hasta el 14-sep-2026), sin fecha de
> cierre. · **Alternativas:** (a) cerrarla en una fecha fija, por ejemplo el 31-jul-2026 (exactamente una temporada de
> 380 partidos) — a favor: las cifras no cambiarían si la fuente se actualiza; en contra: deja fuera los 39 partidos más
> recientes (no se hizo); (b) dejarla abierta y congelar el archivo con su huella SHA-256 — a favor: usa todo lo
> disponible y se puede comprobar que es la misma base; en contra: hay que acordarse de no actualizar el archivo (es lo
> que hoy se hace en el repositorio); (c) reentrenar con entrenamiento + validación antes de la prueba — a favor: 380
> partidos más y más recientes; en contra: ya no se probaría el modelo que se comparó en validación (no se probó). · **Por
> qué ésta:** el notebook no lo justifica explícitamente; razones razonables: lo más reciente es lo más parecido a lo que
> se quiere pronosticar, y el repositorio publica las huellas SHA-256 de los dos CSV para que la base de referencia sea
> comprobable. · **Si preguntan:** "La prueba abarca de agosto de 2025 al 14 de septiembre de 2026 y no tiene fecha de
> cierre: si se agregan partidos al archivo, cambian sus cifras. Por eso el repositorio fija la base con su huella y el
> tablero verifica contra las salidas del notebook. Cerrarla en una fecha fija sería lo mejor para una próxima versión."

### De la comparación con el mercado

| Limitación | Detalle |
|---|---|
| "Apertura" no es la primera cuota | Football-Data registra las cuotas `Avg` el viernes por la tarde (partidos de fin de semana) o el martes (entre semana) |
| Normalización proporcional | Quita el margen repartiéndolo en proporción. No corrige el **sesgo favorito–sorpresa**; hay métodos más finos (Shin, potencia) ([cap. 8](08_cuotas_y_mercado.md)). Con Shin, el LogLoss del mercado sería 0.970635 y 1.020971 (en lugar de 0.970552 y 1.020000): la conclusión no cambia (cálculo propio) |
| Cuota promedio del mercado | Es un promedio de casas. Una casa "afilada" como Pinnacle podría ser una vara más exigente |
| No se evaluó rentabilidad | Fuera del alcance. Con un margen de ≈ 5 % y un modelo que no supera al mercado, no hay evidencia de ventaja explotable |

### Del tablero

| Limitación | Detalle |
|---|---|
| Foto fija | Los datos llegan al 14-sep-2026; actualizar requiere nuevos datos y un push (la publicación sí es automática) |
| Simulador precalculado | 380 combinaciones con M0 y datos al 15-sep-2026; no admite ajustes (lesiones, alineaciones) |
| Depende de JavaScript | Sin JavaScript no se ven las gráficas. Sólo **5 gráficas** tienen vista de tabla (no todas), así que sin JavaScript el resto no tiene alternativa |
| Algunos datos escritos a mano | `index.qmd` conserva datos fijos: el "3" de la tarjeta "Variables en el mejor modelo", "18 de agosto de 2001", "20 equipos" y "10,000 remuestreos". Los comprobamos y son correctos; **no hay que decir que ninguna cifra está escrita a mano** ([cap. 13c](13c_codigo_index_quarto.md)) |
| La verificación avisa pero no detiene la publicación | La tabla compara 17 cifras contra las salidas guardadas del notebook (17 de 17 ✓). Si algo no coincide, el tablero dice "HAY DIFERENCIAS" y se publica de todos modos; y si se pierde la salida de una celda, compara menos cifras sin avisar ([cap. 13a, 13a.7.6](13a_codigo_datos_dashboard.md#13a76-tabla_verificacion)) |
| Solo en español | Audiencia del diplomado |

### Del código entregado (detalles que no cambian ninguna cifra)

Se documentan, **no se corrigieron**: la guía describe el código entregado tal como está. Conviene conocerlos por si
alguien lee el código durante la exposición. La lista con responsables y estado está en el
[capítulo 18](18_hallazgos_y_pendientes.md).

| Dónde | Qué pasa | Qué decir si preguntan |
|---|---|---|
| `wc_predictor.py`, línea 117 | Un comentario dice que K "por defecto es 30"; el valor real es `ELO_K = 15` ([cap. 10](10_codigo_wc_predictor.md#102-qué-cambió-frente-a-la-versión-anterior)) | "Quedó de la versión anterior; el valor que se usa es 15" |
| `datos_dashboard.py`, docstring de `_importar_wc_predictor` | Dice que el módulo imprime el ranking Elo al importarse; la versión final **ya no imprime nada**. Sí sigue leyendo `E0_consolidado.csv` con ruta relativa, por eso se importa desde su carpeta ([13a.9](13a_codigo_datos_dashboard.md#13a9-detalles-raros-y-comentarios-desactualizados)) | "El comentario quedó de la versión anterior; el cambio de carpeta sigue haciendo falta" |
| `wc_predictor.py`, bloque que se ejecuta al importar | Calcula `df`, `parametros`, `HOME_FACTOR` y `AWAY_FACTOR`, que el análisis no usa (sólo se usa `avg_team_goals`, el respaldo de `recent_form`) | "Son restos del módulo; no afectan al modelo" |
| `Limpieza de datos.ipynb`, celda 26 | La tabla de cobertura muestra los rangos al revés y dice "2020/21" para las cuotas promedio (es 2019/20): toma la última **fila** y corta la temporada en julio. El reporte la presenta correcta ([cap. 3](03_limpieza_de_datos.md#36-detalles-conocidos)) | "Es un detalle de presentación; los conteos son correctos y nada del código usa esa tabla" |
| `Limpieza de datos.ipynb`, exportación | Exporta `E0_consolidado_final.csv`, pero el análisis y el tablero leen `E0_consolidado.csv`; hay que renombrarlo (el README lo explica) | "El archivo del repositorio es `E0_consolidado.csv`; su huella se puede comprobar" |
| `Limpieza de datos.ipynb`, lectura | Ruta local (`C:/Users/roski/Downloads`) y, si falta un archivo, lo salta **sin avisar**: por eso el README pide revisar 9,540 filas × 34 columnas | "Se comprueba con las dimensiones y la huella" |
| `Analisis.ipynb`, celda 5 | Exportación a CSV comentada, **duplicada** de la celda 14 (en esa posición daría `NameError` si se descomentara) ([cap. 11](11_codigo_analisis_notebook.md#1125-celda-5-la-exportación-comentada)) | "La que sirve es la 14" |
| `Analisis.ipynb`, §7 | El título dice "diagnóstico del modelo **ampliado**", pero el código diagnostica **M0**; el VIF de M4 lo calcula el tablero ([cap. 11](11_codigo_analisis_notebook.md#118--7-referencia-simple-y-diagnóstico-celdas-1718)) | "El diagnóstico del notebook es el de M0; el de M4 está en el tablero" |

## 15.3 Extensiones, en orden de prioridad

1. **Corrección de Dixon–Coles (o Poisson bivariada).** Ajusta las probabilidades de 0–0, 1–0, 0–1 y 1–1 con un
   parámetro ρ estimado de los datos. Es la corrección clásica para los empates, pero **no hay que prometer mucho**:
   con las λ de M0 fijas, el ρ estimado en el entrenamiento es ≈ −0.008, indistinguible de cero, y el LogLoss cambia
   de 0.989547 a 0.989369 en validación y de 1.033076 a 1.032628 en prueba (cálculo propio de la guía;
   [cap. 7](07_de_goles_a_probabilidades.md#77-decisiones-y-alternativas)). En R existen paquetes
   que lo implementan (`regista`, `goalmodel`; no están instalados en esta computadora). En Python
   se programa maximizando la verosimilitud con `scipy.optimize`.
2. **¿El modelo aporta información que el mercado no tiene?** Una regresión (logística multinomial)
   del resultado contra las probabilidades del mercado **y** las del modelo. Si el coeficiente del
   modelo es distinto de cero, el modelo contiene información que las cuotas no incorporan. Es la
   prueba más directa de la pregunta de investigación.
3. **Ampliar la calibración con validación temporal.** K y k ya se calibraron (ventana creciente, 35 combinaciones,
   sólo con M0). Falta: (a) probar **K < 15**: el mejor valor quedó en el borde inferior de la rejilla y el propio
   notebook advierte que conviene ampliar el rango; (b) calibrar el **decaimiento (0.85) y la ventana de la forma
   (10 partidos)**, que no se optimizaron; y (c) guardar en el repositorio la tabla de las 35 combinaciones (hoy la
   rejilla está comentada en el notebook). Hay que esperar un efecto pequeño: las 35 combinaciones caben en 0.0055 de
   LogLoss, sin tocar la prueba.
4. **Elo mejorado:** ventaja de local dentro del Elo, margen de victoria, regresión parcial a la
   media entre temporadas y ratings que incluyan la segunda división (para los ascendidos).
5. **Reentrenar cada jornada** (ventana móvil), para que los coeficientes se adapten a los cambios
   del juego.
6. **Más información:** xG cuando haya historial, disponibilidad de jugadores y días de descanso.
7. **Otras varas de comparación:** cuotas de cierre como referencia principal y casas "afiladas".
8. **Otros modelos:** logística multinomial u ordinal, que predicen el 1X2 directamente (en R,
   `nnet::multinom()` y `MASS::polr()`); binomial negativa (`MASS::glm.nb()`), que no hace falta
   porque la dispersión es ≈ 1 (0.996 y 1.036) y que **tampoco corregiría los empates**: modela la varianza de cada
   equipo, no la dependencia entre los goles de los dos (para eso, la extensión 1); o *gradient boosting* (`xgboost`,
   instalado en Python), sabiendo que se pierde interpretabilidad.
9. **Pregunta sugerida no analizada:** ¿hay equipos sistemáticamente sobre o infravalorados por el
   mercado? Se respondería comparando por equipo la probabilidad implícita contra la frecuencia real.
10. **Simulación académica de apuestas con capital ficticio**, como permiten las instrucciones,
    incluyendo el margen de la casa.
11. **Tablero que se actualiza solo:** un flujo de GitHub Actions programado (`schedule` con `cron`)
    que descargue los datos nuevos cada semana y vuelva a publicar. Ojo: antes habría que cerrar la prueba
    (extensión 12); si no, sus cifras cambiarían cada semana.
12. **Cerrar la prueba en una fecha fija** (por ejemplo, el 31-jul-2026: una temporada completa de 380 partidos) y
    usar la temporada 2026/27 completa como confirmación de la elección de M0.
13. **Intervalos que respeten la dependencia entre partidos:** bootstrap por jornada (o por fecha) y la prueba de
    Diebold–Mariano para los casos al límite (M4 − M0 en validación; M0 − mercado en prueba), que cambian de lado
    según el método ([D36](19_decisiones_y_alternativas.md#d36-bootstrap-pareado-por-partidos--razonada)).
14. **Pulir el código entregado:** quitar los comentarios desactualizados, corregir la tabla de cobertura de la
    limpieza, exportar con el nombre que lee el análisis (`E0_consolidado.csv`), avisar si falta alguno de los 26
    archivos, hacer que la publicación se detenga si la verificación no da 17 de 17 y calcular los datos que quedaron
    escritos a mano en `index.qmd` (detalle en 15.2, "Del código entregado").

> **Decisión:** si se quisieran corregir los empates, la extensión sería Dixon–Coles (o una Poisson bivariada), y no la
> binomial negativa que el tablero también menciona. · **Alternativas:** (a) Dixon–Coles (1997) — a favor: un parámetro
> ρ ajusta 0–0, 1–0, 0–1 y 1–1 y ataca la dependencia entre goles; en contra: se estima junto con las dos ecuaciones y
> no viene en `statsmodels`; con las λ de M0 fijas, ρ ≈ −0.008 y casi no mejora el LogLoss (0.989547 → 0.989369 en
> validación; 1.033076 → 1.032628 en prueba; cálculo propio); (b) Poisson bivariada (Karlis y Ntzoufras, 2003) — a
> favor: modela la covarianza directamente; en contra: sólo admite dependencia positiva, y la correlación entre los
> residuos de las dos ecuaciones es −0.061 en entrenamiento y +0.004 en validación + prueba; (c) binomial negativa
> (`MASS::glm.nb()`) — a favor: corrige la sobredispersión; en contra: la dispersión de M0 ya es ≈ 1 (0.996 y 1.036) y
> modela la varianza de cada equipo, no la relación entre los goles de los dos, así que **no corrige los empates**
> (colapsa a Poisson en el local, α ≈ 0). · **Por qué ésta:** los empates son la parte de la brecha que corregirían
> (+0.0078 de +0.0159), pero el problema es pequeño: en entrenamiento la P(empate) media coincide con la real (22.7 %
> contra 22.8 %) y lo que cambió fue la tasa de empates (24.5 % en 2024/25 y 27.4 % en 2025/26). · **Si preguntan:**
> "Dixon–Coles o una Poisson bivariada, porque atacan la dependencia entre los goles; la binomial negativa no, porque la
> dispersión ya es casi 1. Después comprobamos que el parámetro de Dixon–Coles sale casi cero: el modelo falló sobre
> todo porque hubo más empates que en el entrenamiento, no porque la independencia sea un gran defecto."

## 15.4 Lo que se decidió no mostrar (y por qué)

| Fuera del tablero | Por qué |
|---|---|
| xG | Solo existe para 40 partidos (2026/27) |
| Córners, faltas, tarjetas, árbitro | No entran al modelo ni responden la pregunta |
| Rentabilidad o simulación de apuestas | Fuera del alcance; tema sensible |
| Coeficientes crudos de M4 en portada | Con VIF de hasta 5.56, sus signos individuales son inestables y confunden |
| M1–M3 en el Resumen | Están en *El modelo*; en portada se muestran solo M0, M4 y el mercado, para no saturar |
| Equipos sobre o infravalorados | El equipo no lo analizó; queda como extensión |
| Gauges y pasteles | El tutorial del módulo pregunta si el gauge "facilita una decisión o solamente ocupa espacio" |

## 15.5 Cómo responder "¿qué harían diferente?" en 20 segundos

> "Tres cosas. Primero, probar una corrección de la independencia de goles, como Dixon–Coles, porque el modelo
> subestima los empates en validación y prueba (en prueba, 23.6 % contra 28.2 %), aunque en el entrenamiento no los
> subestima y esperamos una mejora pequeña. Segundo, ampliar la calibración: K y k los calibramos con validación
> temporal, pero K quedó en el borde de la rejilla, así que hay que probar valores menores, y el decaimiento y la
> ventana de la forma no se optimizaron. Y tercero, probar formalmente si el modelo aporta información que el mercado
> no tiene, combinando ambos en una regresión. Además, cerraríamos la prueba en una fecha fija."
