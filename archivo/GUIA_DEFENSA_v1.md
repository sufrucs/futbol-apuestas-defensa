# Guía para la defensa oral

- **Dashboard:** https://pitirringo.github.io/futbol-apuestas/
- **Repositorio:** https://github.com/pitirringo/futbol-apuestas

Exposición de **5 minutos** (problema, datos, análisis y modelado, resultados, conclusión) + **2 preguntas** que pueden dirigirse a cualquier integrante. Esta guía propone un guion que usa el tablero como apoyo visual, las preguntas más probables con respuestas cortas y las cifras que conviene tener a la mano. El detalle de cada decisión está en `DECISIONES.md`.

---

## 1. Guion de 5 minutos

| Tiempo | Parte | Página del tablero | Qué decir (idea, no texto literal) |
|---|---|---|---|
| 0:00–0:40 | **Problema** | Resumen → tarjeta "Pregunta" | Las casas de apuestas publican cuotas que implican probabilidades. ¿Pueden las estadísticas previas al partido anticipar el resultado tan bien como el mercado? Hipótesis: contienen información, pero el mercado sabe más. |
| 0:40–1:20 | **Datos** | ¿Qué ocurre? | 9,450 partidos de la Premier League (2001–2026) de Football-Data. El local gana 46 %; en 2020/21, sin público, la ventaja desapareció. El favorito del mercado sólo gana 54 %: el fútbol es incierto por naturaleza. |
| 1:20–2:30 | **Análisis y modelado** | Patrones → El modelo ("Cómo funciona") | La diferencia de Elo ordena los resultados; las cuotas están bien calibradas; los goles se comportan como Poisson. Por eso: dos regresiones de Poisson (goles del local y del visitante) con variables calculadas sólo con partidos anteriores; de los goles esperados salen las probabilidades 1X2. Partición temporal: entrenamiento 2019–2024, validación 2024/25, prueba ago-2025 a sep-2026. |
| 2:30–4:00 | **Resultados** | Resumen (gráfica principal) → El modelo (pesas y brecha) | El modelo base acierta 48 % (mercado 49 %, "siempre local" 41.5 %) y logra 84 % de la mejora del mercado sobre la referencia ingenua. Más variables ayudaron en validación pero no en prueba. El mercado le gana sobre todo en victorias locales y empates. |
| 4:00–4:40 | **Conclusión** | Resumen → "Lectura en 20 segundos" | Las cuotas ya incorporan la información estadística pública, y más (alineaciones, lesiones). Un modelo simple y transparente se acerca, pero no encuentra ventaja sistemática. Principales limitaciones: independencia de goles, parámetros sin optimizar, sin información de alineaciones. |
| 4:40–5:00 | (opcional) | Explora un partido | Demostración de 15 segundos: Arsenal vs Man City → 45.8 % / 25.0 % / 29.3 %, marcador más probable 1–1. |

**Consejo:** abrir el tablero (https://pitirringo.github.io/futbol-apuestas/) antes de empezar, con la página Resumen visible, y esperar unos segundos a que cargue el simulador. Si falla internet, llevar una copia local (`_site/` servida con `python -m http.server`) o capturas de pantalla.

**Si preguntan cómo se publicó:** el repositorio es público; en cada `git push` a `main`, GitHub Actions instala Python y Quarto en una máquina limpia, recalcula todo desde los datos, renderiza el tablero y lo publica en GitHub Pages. La primera publicación tardó menos de 2 minutos, y las 15 cifras de verificación coincidieron también en esa máquina.

---

## 2. Cifras que conviene tener a la mano

| Tema | Cifra |
|---|---|
| Base de datos | 9,450 partidos · 26 temporadas · 33 variables · 18-ago-2001 a 14-sep-2026 |
| Base de modelación | 2,696 partidos: 1,897 entrenamiento · 380 validación · 419 prueba |
| Resultados históricos | Local 45.6 % · empate 24.7 % · visitante 29.8 % |
| Favorito de las cuotas | Gana 54.3 % · empata 24.6 % · pierde 21.0 % |
| Elo | Inicial 1,500 · K = 30 · entra como diferencia/400 · la localía vale ≈60 puntos |
| *Shrinkage* | k = 10 (con 10 partidos jugados, la temporada actual pesa 50 %) |
| Forma reciente | 10 partidos · decaimiento 0.85 (los 3 últimos pesan ≈48 %) |
| LogLoss en prueba | M0 1.031 · M4 1.034 · mercado 1.020 · ingenua 1.087 · azar 1.099 |
| LogLoss en validación | M0 0.984 · M4 0.975 · mercado 0.971 · ingenua 1.079 |
| Aciertos en prueba | M0 48.0 % · mercado 48.9 % · "siempre local" 41.5 % |
| Parte de la ventaja del mercado | 84 % en prueba · 88 % en validación |
| Brecha M0 − mercado | Prueba +0.011 (IC 95 %: −0.004 a +0.025) · validación + prueba +0.012 (IC: +0.002 a +0.022) |
| M0 vs ingenua (prueba) | −0.056 (IC: −0.086 a −0.026): mejora clara |
| Dispersión de Pearson (M0) | 0.99 local · 1.04 visitante (≈1, como supone Poisson) |
| Margen de las casas | 4.49 % validación · 5.84 % prueba |
| Ejemplo del reporte (M0) | Arsenal–Man City: λ 1.57 y 1.20 · 45.8 % / 25.0 % / 29.3 % · marcador 1–1 (11.8 %) |

---

## 3. Preguntas probables y respuestas cortas

### Datos y limpieza

**¿De dónde salen los datos y cómo se obtuvieron?**
De Football-Data.co.uk: un CSV por temporada de la Premier League (archivos `E0`), de 2001/02 a 2026/27, descargados directamente del sitio (no hubo API). Se consolidaron en `E0_consolidado.csv` con `Limpieza de datos.ipynb`.

**¿Por qué usar datos desde 2001 si el modelo empieza en 2019?**
Porque el Elo necesita historia para estabilizarse. Con 18 años de partidos previos, en 2019 los ratings ya reflejan la fuerza real de cada equipo. El análisis exploratorio también usa todo el histórico.

**¿Por qué el modelo empieza en 2019?**
Porque desde 2019/20 existen las cuotas promedio del mercado (apertura y cierre), que son nuestra referencia. Además deja cinco temporadas de entrenamiento.

**¿Qué decisiones de limpieza tomaron?**
Conservar las columnas comunes a todas las temporadas más cuotas y xG; no eliminar partidos por faltar cuotas; homologar las fechas (formatos `dd/mm/aa` y `dd/mm/aaaa`) y ordenar cronológicamente, que es indispensable para no usar información del futuro.

**¿Qué problemas de calidad encontraron?**
Sin duplicados ni resultados incongruentes. Hay dos temporadas incompletas (2003/04 y 2004/05, con 335 de 380 partidos), un partido con más tiros a puerta que tiros (error de la fuente), xG sólo en 2026/27 y cuotas promedio sólo desde 2019/20. Ninguno afecta el periodo de modelación.

**¿Por qué quedaron 2,696 partidos y no 2,700?**
Se excluyeron 4 partidos cuyos equipos no tenían partidos previos en la base para calcular tiros (Brentford 2021, Nott'm Forest 2022, Luton 2023 y Coventry 2026, en su primer partido).

### Variables

**¿Qué es el Elo?**
Un rating de fuerza: cada equipo empieza con 1,500 y tras cada partido gana o pierde puntos según qué tan inesperado fue el resultado. La diferencia de Elo entre dos equipos predice quién debería ganar. K = 30 controla cuánto se mueve el rating por partido; es un valor habitual, no optimizado.

**¿Qué es el shrinkage y por qué k = 10?**
Al inicio de la temporada, con pocos partidos, el promedio de goles es muy ruidoso. El *shrinkage* lo mezcla con el promedio de la temporada anterior: con n partidos, la temporada actual pesa n/(n+10). Con 10 partidos pesa la mitad. k = 10 es un valor operativo, no optimizado.

**¿Cómo se aseguraron de no usar información del futuro?**
Cada variable se calcula sólo con partidos de fechas anteriores al encuentro (`date < fecha`), y el Elo se actualiza después de procesar todos los partidos del día. Además, la partición es temporal: entrenamos con el pasado y evaluamos con el futuro.

### Modelo

**¿Por qué regresión de Poisson?**
Los goles son conteos pequeños de eventos poco frecuentes, el caso típico de Poisson y el enfoque clásico en la literatura (Maher, 1982; Dixon y Coles, 1997). Los datos lo respaldan: la distribución de goles se parece a una Poisson con la misma media, y dentro del modelo la dispersión es ≈1.

**¿Por qué no clasificar directamente victoria / empate / derrota?**
Modelar goles usa más información (no es lo mismo ganar 1–0 que 4–0), da probabilidades de cada marcador y produce probabilidades 1X2 coherentes. Una regresión logística multinomial sería una buena comparación como extensión.

**¿Por qué dos regresiones?**
Una para los goles del local y otra para los del visitante. Así cada una tiene su propio intercepto y sus coeficientes, y la ventaja de local se estima en lugar de imponerla.

**¿Cómo pasan de goles esperados a probabilidades?**
Suponiendo que, dadas las variables, los goles de ambos equipos son independientes: la probabilidad de un marcador es el producto de dos Poisson, y la diferencia de goles sigue una distribución de Skellam. P(local) es la probabilidad de que la diferencia sea positiva, P(empate) de que sea cero y P(visitante) de que sea negativa.

**¿Cómo se interpretan los coeficientes?**
Con enlace logarítmico los efectos son multiplicativos. En M0, +100 puntos de Elo del local multiplican sus goles esperados por ≈1.11 (+11 %) y los del visitante por ≈0.89 (−11 %). La diferencia de Elo es la variable con más peso (+18.6 % de goles por una desviación estándar).

**¿Por qué el marcador más probable es 1–1 si gana el local?**
Porque la victoria local agrupa muchos marcadores (1–0, 2–0, 2–1…) y el empate pocos. El 1–1 es el marcador individual más probable, pero la suma de todos los marcadores de victoria local es mayor.

**¿Qué es la multicolinealidad de M4? ¿Es un problema?**
Tiros y tiros a puerta están muy correlacionados (0.85; VIF máximo 5.5). No sesga las predicciones, pero vuelve inestables los coeficientes individuales. Por eso comparamos modelos por su desempeño fuera de muestra, no por la significancia de cada coeficiente.

**¿Qué modelo eligieron?**
La validación eligió M4 por poco. En prueba su ventaja no se sostuvo y M0 fue mejor. Las diferencias entre especificaciones son menores al ruido (los intervalos bootstrap incluyen el cero), así que por parsimonia preferimos M0: tres variables, fácil de explicar y el mejor en prueba. Somos conscientes de que esa preferencia usa información de prueba y habría que confirmarla con la siguiente temporada.

### Evaluación

**¿Por qué LogLoss y no porcentaje de aciertos?**
El LogLoss evalúa las probabilidades completas: premia asignar mucha probabilidad a lo que ocurre y castiga la sobreconfianza. Los aciertos ignoran la confianza (60 % y 90 % cuentan igual) y nadie pronostica empates, así que los aciertos casi no distinguen modelos. Mostramos aciertos sólo como traducción intuitiva.

**¿Qué significa un LogLoss de 1.031?**
Que en promedio (geométrico) el modelo asignó 35.7 % de probabilidad al resultado que ocurrió (e^−1.031). Adivinar al azar da 33.3 % (LogLoss 1.099) y el mercado 36.1 % (1.020).

**¿Qué es la referencia ingenua?**
Un modelo de Poisson sin información de los equipos: usa los goles promedio del entrenamiento para todos los partidos. Como siempre favorece al local, acierta lo mismo que "siempre gana el local". Sirve para medir cuánto aportan las variables.

**¿Cómo convierten las cuotas en probabilidades?**
La probabilidad bruta es 1/cuota. Como las tres suman más de 100 % (ese exceso es el margen de la casa: ≈5 %), se normalizan dividiendo entre la suma. Las cuotas nunca entran al modelo: sólo son la vara de comparación.

**¿Qué son las "cuotas de apertura"?**
Las cuotas promedio del mercado que Football-Data registra el viernes por la tarde (partidos de fin de semana) o el martes (entre semana). Las de cierre son las últimas antes del partido y son un poco más precisas.

**¿Por qué partición temporal y no validación cruzada aleatoria?**
Porque una partición aleatoria mezclaría partidos futuros en el entrenamiento (fuga de información) y daría resultados optimistas. La temporal imita el uso real.

**¿Son significativas las diferencias?**
Contra la referencia ingenua, sí, con claridad. Contra el mercado: en prueba sola el intervalo incluye el cero, pero en validación y en ambos periodos juntos (799 partidos) no, así que el mercado es mejor de forma consistente. Entre M0 y M4, ninguna diferencia es concluyente.

**¿Por qué todos empeoran en prueba?**
El periodo de prueba fue más difícil de predecir para todos, incluido el mercado: hubo más empates (28.2 % contra 24.5 %), y el empate es el resultado más difícil de anticipar.

### Resultados y conclusiones

**Si el modelo no le gana al mercado, ¿qué aporta?**
Tres cosas: demuestra que las estadísticas públicas contienen información (mejora clara sobre la referencia ingenua y 84 % de la ventaja del mercado); es transparente (sabemos qué variables pesan y cuánto); y estima goles y marcadores, no sólo 1X2.

**¿Por qué el mercado es mejor?**
Incorpora información que el modelo no tiene (alineaciones, lesiones, noticias, rotaciones) y agrega las opiniones de muchos participantes. Consistente con eso, las cuotas de cierre, con más información, son aún mejores que las de apertura.

**¿Dónde falla el modelo frente al mercado?**
En victorias locales y empates. Asigna menos probabilidad a los empates que el mercado y es algo sobreconfiado con los favoritos claros. En victorias visitantes, en cambio, es ligeramente mejor.

**¿Afectó la pandemia al modelo?**
El entrenamiento incluye la temporada sin público (2020/21), cuando la ventaja local desapareció. Reentrenamos M0 sin esos 472 partidos: el modelo favorece un poco más al local, pero el LogLoss no mejora. La pandemia no explica la brecha con el mercado.

**¿Se podría ganar dinero con este modelo?**
No lo evaluamos y no es el objetivo; el proyecto es académico. Como el modelo no supera al mercado y las casas cobran un margen de ≈5 %, no hay evidencia de una ventaja explotable.

**¿Qué harían para mejorarlo?**
Corrección de Dixon–Coles para los empates, optimizar K, k y el decaimiento con validación temporal, un Elo que incluya la segunda división (para los ascendidos), agregar xG cuando haya historial y comparar contra cuotas de cierre.

**¿Cuáles son las principales limitaciones?**
La independencia de goles (subestima empates), parámetros sin optimizar, el trato a los equipos ascendidos, la falta de información de alineaciones y lesiones, y una muestra de prueba de 419 partidos.

### Visualización

**¿Por qué Quarto y no Flexdashboard o Shiny?**
El análisis está en Python; Quarto permite que el tablero ejecute el mismo código del equipo, así que las cifras coinciden con el reporte por construcción. Usa la misma lógica que Flexdashboard (páginas, filas, value boxes, pestañas). Shiny necesitaría un servidor; la interactividad que queríamos funciona en el navegador.

**¿Cómo se construyó y publicó?**
`datos_dashboard.py` recalcula todo desde los datos del equipo, `graficas.py` hace las gráficas con Plotly e `index.qmd` define páginas y textos. GitHub Actions instala Python y Quarto, renderiza el tablero y lo publica en GitHub Pages en cada `push`, como en el ejemplo de clase.

**¿Cómo funciona el simulador sin servidor?**
Las 380 combinaciones de equipos se calculan en Python al generar el tablero; el navegador sólo filtra y dibuja con Observable JS. Es interactividad del navegador, no reactividad de un servidor.

**¿Cómo garantizan que las cifras del tablero coinciden con el reporte?**
Ninguna cifra está escrita a mano: todas se calculan al generar el tablero. Y la pestaña *Reproducibilidad* compara automáticamente 15 cifras con las del notebook y el reporte; todas coinciden.

**¿Por qué ese orden de páginas y esos colores?**
El orden sigue el arco de storytelling (conclusión primero, luego contexto, patrones y modelo) y cada página responde una de las cuatro preguntas mínimas. Los colores son fijos por entidad (azul modelo, naranja mercado, verde local, violeta visitante, gris contexto), validados para daltonismo; el gris se usa para todo lo que no es protagonista.
