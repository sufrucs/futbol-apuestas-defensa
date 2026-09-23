# Decisiones y su justificación

**Proyecto 1 · Fútbol y mercados de apuestas · Módulo 8, Comunicación de resultados**

- **Dashboard:** https://pitirringo.github.io/futbol-apuestas/
- **Repositorio:** https://github.com/pitirringo/futbol-apuestas

Documento para revisar en equipo antes de entregar. Tiene tres partes:

- **Parte A:** decisiones del dashboard (qué se hizo y por qué, con referencia a lo visto en el módulo).
- **Parte B:** el código del equipo explicado: el "por qué" de cada decisión de datos, variables, modelo y evaluación, para que cualquiera pueda defenderlo.
- **Parte C:** hallazgos de la revisión que conviene corregir o acordar antes de la entrega del 28 de septiembre.

Todas las cifras de este documento salen de `datos_dashboard.py`, que recalcula todo desde los archivos del equipo.

---

## La historia en 30 segundos

> Con sólo tres variables conocidas antes del partido (diferencia de Elo y goles a favor y en contra ajustados), un modelo de Poisson acierta el resultado en **48.0 %** de los partidos de prueba, contra 41.5 % de apostar siempre por el local, y logra **84 %** de la mejora que consiguen las casas de apuestas sobre una referencia ingenua. Pero **no supera al mercado**: las cuotas de apertura tienen menor LogLoss en validación y en prueba, y con ambos periodos juntos (799 partidos) la diferencia es pequeña (+0.012) y estadísticamente distinta de cero. Agregar forma reciente y tiros ayudó en validación y dejó de ayudar en prueba. **Conclusión:** las cuotas ya incorporan la información estadística pública, y más.

---

# Parte A. El dashboard

## A1. Qué pide la rúbrica y dónde se cumple

| Requisito (instrucciones del proyecto) | Dónde está en el tablero |
|---|---|
| Visualización publicada y accesible por URL | GitHub Pages, publicado con GitHub Actions (`.github/workflows/publicar-dashboard.yml`) |
| ¿Qué ocurre? | Página **¿Qué ocurre?**: localía, resultados por temporada, qué tan seguido gana el favorito |
| ¿Qué patrones o relaciones encontraron? | Página **Patrones**: Elo → resultado, calibración de las cuotas, goles tipo Poisson |
| ¿Qué aporta el modelo? | Página **El modelo**: cómo funciona, validación vs prueba, dónde pierde contra el mercado, variables, calibración, métricas e incertidumbre; página **Explora un partido** |
| ¿Cuál es la conclusión principal? | Página **Resumen**: pregunta, hipótesis, respuesta corta, 3 indicadores y "Lectura en 20 segundos" |
| Documentar datos, limpieza, limitaciones, reproducibilidad | Página **Datos y método** (8 pestañas) |

Cada pregunta mínima tiene su propia página, en el orden de la historia. Así, si en la exposición preguntan "¿qué aporta el modelo?", hay un lugar exacto al cual ir.

## A2. Herramienta: Quarto (formato dashboard) + Python

**Decisión.** El tablero se construyó con Quarto en formato `dashboard`, con chunks de Python, gráficas de Plotly y un simulador en Observable JS (OJS).

**Por qué:**

1. **Una sola fuente de verdad.** El análisis del equipo está en Python (`wc_predictor.py`, `Analisis.ipynb`). El tablero importa ese mismo código y recalcula los modelos al generarse, así que sus cifras coinciden con las del notebook y del reporte por construcción. Se verificó: los 10 valores de LogLoss publicados coinciden a 6 decimales y el ejemplo Arsenal–Man City del reporte coincide exactamente (pestaña *Reproducibilidad*).
2. **Misma lógica que Flexdashboard.** Quarto dashboards usa los mismos conceptos vistos en el tutorial de Flexdashboard: páginas (nivel 1), filas y columnas (nivel 2), tarjetas, `valueBox`, `.tabset`, anchos relativos y `orientation: rows` con `scrolling`. Lo aprendido en el tema 2 aplica tal cual.
3. **Quarto se vio en la clase 8**, incluidas las plantillas con chunks de Python y su publicación con GitHub Actions.
4. **La rúbrica no evalúa la herramienta** sino la capacidad de comunicar.

**Alternativas descartadas:**

| Alternativa | Por qué no |
|---|---|
| Flexdashboard en R | Habría obligado a reimplementar el modelo en R o a leer resultados exportados de Python: dos lenguajes y riesgo de que las cifras del tablero no coincidan con las del reporte |
| Shiny | Requiere un servidor encendido (shinyapps.io). Para lo que necesitamos, la interactividad del navegador basta: el propio tutorial distingue "interactividad del navegador" de "reactividad de R" |
| Blogdown / sitio web | Un sitio organiza varias historias o actualizaciones; aquí hay una sola historia con evidencia densa, que es justo el caso de un tablero |

## A3. Publicación: GitHub Actions → GitHub Pages

**Decisión.** Mismo esquema que el ejemplo `dashboard-vuelos` de clase: un job `build` (instala Quarto y Python, renderiza) y un job `deploy` (publica `_site/`).

**Por qué:**

- Es el flujo enseñado en el módulo (tema de GitHub Actions).
- **Prueba la reproducibilidad:** el runner parte de una máquina vacía. Si el tablero se construye ahí, cualquiera puede reproducirlo con el repositorio (la guía de clase lo dice: GitHub Actions "nos obliga a comprobar que el proyecto es reproducible").
- Versiones fijadas (Python 3.10, Quarto 1.8.25, paquetes en `requirements.txt`) para que el runner obtenga exactamente las mismas cifras.
- No requiere secretos ni tokens en el repositorio.

## A4. Audiencia y mensaje (storytelling, paso 1: entender el contexto)

- **Audiencia:** profesores del diplomado (conocen LogLoss y regresión) y compañeros (no necesariamente conocen apuestas). Contexto: exposición de 5 minutos + 2 preguntas a cualquier integrante.
- **Idea central que debe quedar:** *las estadísticas previas al partido sí anticipan resultados, pero el mercado ya las incorpora; el modelo se acerca sin superarlo.*
- Consecuencia de diseño: se usan dos lenguajes a la vez. La métrica técnica (LogLoss) para los profesores y traducciones intuitivas (porcentaje de aciertos, "84 % de la ventaja del mercado", probabilidad media asignada al resultado real) para todos.

## A5. Estructura narrativa

Sigue el arco del material de storytelling: **planteamiento → conflicto/hallazgo → resolución**.

| Página | Papel en la historia | Pregunta que responde |
|---|---|---|
| Resumen | Conclusión primero (lectura ejecutiva, como la página "Resumen ejecutivo" del ejemplo de vuelos) | ¿Cuál es la conclusión? |
| ¿Qué ocurre? | Planteamiento: el fenómeno y por qué es difícil predecirlo | ¿Qué ocurre? |
| Patrones | Desarrollo: la evidencia que justifica el modelo | ¿Qué patrones hay? |
| El modelo | Conflicto y resolución: el modelo contra el mercado | ¿Qué aporta el modelo? |
| Explora un partido | Exploración libre (segundo nivel) | — |
| Datos y método | Respaldo para quien quiera auditar | — |

El Resumen va primero porque un tablero es "una vista rápida del estado de algo" (definición del módulo) y porque el principio de pre-atención dice que "los usuarios escanean, no leen". La tarjeta "Lectura en 20 segundos" viene del ejercicio del dashboard de vuelos. El "Recorrido sugerido" al final de esa tarjeta es la agenda de la exposición ("En los próximos 5 minutos…").

## A6. Pregunta de investigación e hipótesis

El código del equipo documenta el objetivo del sistema pero no una pregunta formal, y las instrucciones la piden. El tablero propone esta redacción, **a validar con el equipo de Reporte para que ambos entregables digan lo mismo**:

- **Pregunta:** ¿Qué tan bien anticipan el resultado de un partido de la Premier League (victoria local, empate o victoria visitante) las estadísticas disponibles antes del encuentro, comparadas con las probabilidades implícitas en las cuotas de apuestas?
- **Preguntas secundarias:** ¿qué variables pesan más?, ¿cómo cambia el desempeño local y visitante?, ¿qué tan calibradas están las cuotas?, ¿más variables mejoran el pronóstico?
- **Hipótesis:** las estadísticas contienen información útil (el modelo supera a una referencia ingenua), pero el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor (el modelo no supera a las cuotas).
- **Variable objetivo:** goles del local y del visitante (conteos), de donde se deriva el resultado 1X2.
- **Variables explicativas:** diferencia de Elo, goles a favor y en contra ajustados, forma reciente, tiros y tiros a puerta, todas previas al partido.
- **Población / unidad / periodo / alcance:** partidos de la Premier League / el partido / 2001–2026 para el histórico y 2019/20–2026/27 para modelar / Inglaterra.

## A7. Indicadores (value boxes)

Criterio del módulo: relevancia, interpretabilidad y "un KPI debe responder una pregunta relevante, no solamente demostrar que podemos calcularlo". Máximo 3 por página, para no perder jerarquía.

| Página | Indicador | Por qué |
|---|---|---|
| Resumen | **84 %** de la ventaja del mercado que logra el modelo | Resume la respuesta en un número: el modelo está cerca pero debajo. Se calcula con la métrica oficial (LogLoss): (ingenua − M0) / (ingenua − mercado) en prueba = 0.0562 / 0.0668 |
| Resumen | **48.0 %** de partidos acertados | La traducción más intuitiva; incluye las referencias (mercado 48.9 %, "siempre local" 41.5 %) para que el número tenga contexto |
| Resumen | **3 variables** | Comunica la tercera conclusión: el modelo simple fue el más robusto |
| ¿Qué ocurre? | **9,450** partidos | Escala y credibilidad de la base |
| ¿Qué ocurre? | **45.6 %** gana el local | La localía es el primer patrón que cualquier modelo debe capturar |
| ¿Qué ocurre? | **54.3 %** gana el favorito | Fija expectativas: si el favorito del mercado sólo gana la mitad de las veces, acertar ~50 % ya es bueno |

Los tintes de fondo siguen la paleta: azul claro para indicadores del modelo, naranja claro para el mercado, verde claro para la localía y gris para contexto.

## A8. Gráficas: forma, título y propósito

Reglas del módulo aplicadas en todas: **títulos que comunican el hallazgo** (no "Gráfica de Elo", sino "La diferencia de fuerza ordena los resultados…"), **barras desde cero**, **etiquetas directas** en lugar de leyendas cuando hay pocas series, **sin 3D ni pasteles**, **barras ordenadas**, **precisión que sigue a la decisión** (LogLoss con 3 decimales porque las diferencias están en la tercera cifra; porcentajes con 1).

| Gráfica (página) | Forma y por qué | Qué responde |
|---|---|---|
| El modelo recupera la mayor parte de la ventaja del mercado (Resumen) | Barras horizontales agrupadas **desde cero**: la longitud es la mejora sobre la referencia ingenua, así que la proporción entre barras es honesta (la de M0 mide 84 % de la del mercado). Tono claro = validación, sólido = prueba | Conclusión principal en una imagen: todos mejoran a la ingenua, el mercado más; M4 gana en validación y pierde en prueba |
| La ventaja de jugar en casa es persistente… salvo sin público (¿Qué ocurre?) | Líneas por temporada (cambio en el tiempo) con etiquetas directas al final; bandas de fondo para los periodos del modelo; anotación en 2020/21 | La localía existe y es estable; la pandemia la borró; el entrenamiento incluye esa temporada |
| Ni el favorito es garantía (¿Qué ocurre?) | Tres barras ordenadas, un solo color (una serie) | Incertidumbre intrínseca del fútbol |
| La diferencia de Elo ordena los resultados (Patrones) | Líneas por decil de Elo; el cruce local = visitante señalado | Relación más fuerte de los datos y cuánto "vale" la localía (≈60 puntos Elo) |
| Las cuotas están bien calibradas (Patrones) | Diagrama de calibración con diagonal de referencia, ejes cuadrados | ¿Qué tan informativas y calibradas son las cuotas? (pregunta sugerida en las instrucciones) |
| Los goles se comportan como Poisson (Patrones, pestaña) | Barras observadas + marcadores teóricos | Justifica la elección del modelo |
| Más variables ayudaron en validación, pero no en prueba (El modelo) | Gráfica de "pesas" (dumbbell): hueco = validación, relleno = prueba, línea vertical en M0 | Selección de modelo y sobreajuste en una sola vista |
| El mercado supera al modelo en victorias locales y empates (El modelo) | Barras divergentes desde cero; naranja si ganó el mercado, azul si ganó el modelo | Dónde está la brecha con el mercado |
| Qué variables pesan más (pestaña) | Puntos con intervalos de 95 %, efectos estandarizados | ¿Qué variables ayudan a anticipar el resultado? (pregunta sugerida) |
| Calibración modelo vs mercado (pestaña) | Dos series sobre la diagonal | Sobreconfianza del modelo con favoritos; subestima empates |
| Modelo vs mercado partido a partido (pestaña) | Dispersión con diagonal | Coinciden en lo esencial (r = 0.93) |

**Tablas.** Cada gráfica tiene su tabla en una pestaña (temporadas, deciles de Elo, calibración, métricas, bootstrap). Así ningún dato depende sólo del color o del tooltip.

## A9. Color

- **Colores fijos por entidad en todo el tablero:** azul `#2a78d6` = modelo; naranja `#eb6834` = mercado; verde `#008300` = local; violeta `#4a3aa7` = visitante; gris `#898781` = empate y contexto. Es la convención del ejemplo de clase ("azul = información principal; naranja = énfasis puntual; gris = apoyo") llevada a las entidades del proyecto.
- **El color se reserva para lo importante** (tip del material de storytelling): lo que no es protagonista va en gris (M4, referencias, empates).
- **Validada para daltonismo** con un validador de paletas: modelo/mercado y local/visitante pasan todas las pruebas; la primera opción para el empate (gris junto a un aqua) **falló** con deuteranopía y por eso el local pasó a verde `#008300`, que además cumple contraste ≥ 3:1 sobre blanco.

## A10. Maquetación y jerarquía

- **Gráfica principal ≈ 2/3 del ancho** y texto o gráfica secundaria ≈ 1/3, como el 650/350 del tutorial ("la gráfica principal recibe aproximadamente dos tercios del ancho porque contiene el patrón que queremos que el lector observe primero").
- **Pestañas (`.tabset`) para el segundo nivel:** "permiten mantener disponible información útil de segundo nivel sin saturar la vista principal" (ejemplo de vuelos).
- **Consistencia:** una tipografía, una paleta, títulos con hallazgo y subtítulo explicativo en todas las tarjetas.
- **Tema `cosmo`** (el del ejemplo de clase) con ajustes en `estilos.scss`: tarjetas sin sombra, fondo cálido y tipografía del sistema.
- Tema claro únicamente: se proyectará en salón y los proyectores leen mejor fondos claros.

## A11. Interactividad

- **Tooltips** en todas las gráficas (valores exactos, número de casos).
- **Simulador "Explora un partido"** con Observable JS: el usuario elige local y visitante y ve probabilidades 1X2, goles esperados, marcador más probable, la matriz de marcadores y las variables que explican el pronóstico. Las 380 combinaciones de los 20 equipos de 2026/27 se calculan en Python al generar el tablero; el navegador sólo las muestra. Por eso no necesita servidor.
- **Modelo del simulador: M0.** Fue el mejor en prueba, tiene 3 variables fáciles de explicar y sus diferencias con M4 son mínimas (≈0.3 puntos porcentuales en el ejemplo del reporte). Ver la discusión sobre selección de modelo en C6.
- **Aviso de uso académico**, como piden las instrucciones ("cualquier simulación relacionada con apuestas deberá utilizar exclusivamente capital ficticio y objetivos académicos").

## A12. Análisis que el tablero agrega al notebook

El notebook contiene el modelado; las instrucciones también piden análisis exploratorio y "cada elemento debe tener un propósito dentro de la historia". Estos complementos se calculan en `datos_dashboard.py` con los mismos datos. **Conviene que el equipo de Reporte decida si los incluye.**

| Complemento | Resultado | Por qué se agregó |
|---|---|---|
| Resultados por temporada y localía | Local 45.6 %, empate 24.7 %, visita 29.8 %; en 2020/21 ganan más los visitantes (40.3 % vs 37.9 %) | Responde "¿cómo cambia el desempeño local y visitante?" |
| Favorito de Bet365 | Gana 54.3 %, empate 24.6 %, pierde 21.0 % (9,070 partidos) | Fija qué tan predecible es el fútbol |
| Resultado por decil de Elo | Victoria local de 14 % a 76 %; equivalencia de la localía ≈ 63 puntos Elo | Muestra la relación que el modelo explota |
| Calibración histórica de Bet365 | Bien calibradas; leve sesgo favorito–sorpresa en los extremos | Responde "¿qué tan bien calibradas están las probabilidades implícitas?" |
| Ajuste Poisson de goles | Media ≈ varianza (1.53 vs 1.69 local; 1.19 vs 1.34 visita); dispersión de Pearson del modelo 0.99 y 1.04 | Justifica el modelo de Poisson |
| Tasa de aciertos y probabilidad media asignada al resultado real | M0 48.0 %, mercado 48.9 %; exp(−LogLoss) = 35.7 % vs 36.1 % | Traduce el LogLoss a algo intuitivo |
| Intervalos bootstrap (10,000 remuestreos) | M0 vs ingenua: −0.056 [−0.086, −0.026]; M0 vs mercado en prueba: +0.011 [−0.004, +0.025]; en validación + prueba: +0.012 [+0.002, +0.022] | El reporte dice que las diferencias "no establecen, por sí solas, diferencias significativas"; el bootstrap lo cuantifica |
| Descomposición de la brecha con el mercado | Victorias locales +0.011, empates +0.010, victorias visitantes −0.010 (total +0.012) | Explica *dónde* pierde el modelo |
| Calibración del modelo | Cuando M0 asigna 60–70 %, ocurre 58.5 %; 70–80 %, ocurre 68.1 % | El modelo es algo sobreconfiado con los favoritos |
| Efectos estandarizados | +1 desviación estándar de Elo: +18.6 % goles del local y −18.4 % del visitante | Compara variables con escalas distintas |
| Sensibilidad sin partidos a puerta cerrada | Sin los 472 partidos sin público, P(local) media en prueba sube de 42.9 % a 44.1 %, pero el LogLoss no mejora (1.0306 → 1.0311) | Descarta que la pandemia explique la brecha |
| Mercado al cierre (sólo en la tabla de métricas) | LogLoss 1.0170 en prueba, un poco mejor que la apertura (1.0200) | Consistente con que el mercado mejora al llegar información (alineaciones) |

## A13. Qué se decidió no mostrar

El ejercicio de clase pedía explicar "qué información decidiste no mostrar". Quedaron fuera:

- **xG:** sólo existe en 2026/27 (40 partidos).
- **Córners, faltas, tarjetas y árbitro:** no entran al modelo y no aportan a la pregunta.
- **Rentabilidad o simulación de apuestas:** fuera del alcance del equipo y sensible; se deja como extensión con capital ficticio.
- **Coeficientes crudos de M4 en portada:** con VIF de hasta 5.5 sus signos individuales son inestables y confunden; están en el notebook.
- **M1–M3 en el Resumen:** se muestran en *El modelo*; en portada sólo M0, M4 y el mercado, para no saturar.
- **Equipos sobre o infravalorados por el mercado:** pregunta sugerida pero no analizada por el equipo; queda como extensión.
- **Gauges y pasteles:** el tutorial pregunta "¿el gauge facilita una decisión o solamente ocupa espacio?".

## A14. Reproducibilidad y control de calidad

- **Una sola fuente de verdad:** ninguna cifra está escrita a mano en el tablero; todas salen de `datos_dashboard.py` mediante expresiones en línea de Quarto.
- **Verificación automática** contra el notebook y el reporte (pestaña *Reproducibilidad*).
- **Caché del equipo verificada:** se reconstruyó `premier_training_data.csv` desde cero y coincide con la del equipo en los 2,696 partidos (diferencias de 10⁻¹³, precisión de punto flotante).
- **Revisión visual** a 1440 px, 1280 px (proyector) y 375 px (celular).
- Los problemas técnicos encontrados y su solución están en el `README.md`.

---

# Parte B. El código del equipo: qué se hizo y por qué

## B1. Datos y alcance

- **Fuente:** Football-Data.co.uk, archivos `E0` (Premier League) de 2001/02 a 2026/27, descargados a mano (sin API).
- **Por qué Premier League:** es la liga con la cobertura más completa y estable (estadísticas de partido y cuotas en todas las temporadas).
- **Por qué desde 2001:** el Elo necesita historia para estabilizarse; empezar en 2001 garantiza que en 2019 (inicio de la modelación) los ratings ya reflejen fuerza real.

## B2. Limpieza (`Limpieza de datos.ipynb`)

| Decisión | Justificación |
|---|---|
| Conservar 22 columnas comunes y 11 complementarias (cuotas, xG) | Las comunes existen en todas las temporadas; las complementarias sirven donde existan |
| `reindex(columns=...)` deja vacías las columnas ausentes | No se pierden partidos porque a una temporada le falte una columna |
| Eliminar filas sin equipos | Son filas vacías al final de algunos CSV |
| Fechas con `dayfirst=True` y `format='mixed'`, exportadas en ISO | Los archivos antiguos usan `dd/mm/aa` y los recientes `dd/mm/aaaa`. Se verificó que ninguna fecha invirtió día y mes |
| Orden cronológico | Condición para construir variables sin usar el futuro |
| No eliminar partidos sin cuotas | El histórico completo alimenta el Elo; las cuotas sólo se usan donde existen |

## B3. Periodo de modelación y partición temporal

- **Modelación desde agosto de 2019:** es cuando aparecen las cuotas promedio de apertura y cierre (`Avg`), que son la referencia de mercado; deja cinco temporadas de entrenamiento.
- **Entrenamiento** 2019/20–2023/24 (1,897 partidos) · **validación** 2024/25 (380) · **prueba** 15-ago-2025 a 14-sep-2026 (419 = 380 de 2025/26 + 39 de 2026/27).
- **Por qué temporal y no aleatoria:** en series ordenadas en el tiempo una partición aleatoria mezclaría futuro y pasado (fuga de información) y sobreestimaría el desempeño. La temporal imita el uso real: ajustar con el pasado, pronosticar el futuro.
- **Por qué tres conjuntos:** validación para elegir entre especificaciones; prueba, intacta hasta el final, para una estimación honesta.
- **Partidos excluidos:** 4 (Brentford 2021, Nott'm Forest 2022, Luton 2023, Coventry 2026) porque esos equipos no tenían partidos previos en la base para calcular tiros.

## B4. Variables previas al partido (`wc_predictor.py`)

Principio: **toda variable se calcula sólo con partidos anteriores a la fecha del encuentro** (`df_pre = historial[date < fecha]`). El Elo se actualiza después de procesar todos los partidos del día.

**Elo** (inicial 1,500; K = 30):
- Expectativa del local E = 1 / (1 + 10^((R_visita − R_local)/400)); tras el partido R ← R + K·(S − E), con S = 1, 0.5 o 0.
- Por qué: resume en un número la fuerza relativa acumulada y se ajusta más cuando el resultado es inesperado. Ejemplo: ganarle a un rival igual suma 15 puntos; ganarle a uno 200 puntos más fuerte suma ≈23.
- Entra al modelo como D = (Elo local − Elo visitante)/400, la misma escala de la fórmula de Elo.
- Una desviación estándar de la diferencia de Elo equivale a unos 167 puntos.

**Goles a favor y en contra ajustados** (*shrinkage*, k = 10):
- GF_ajustado = n/(n+k)·GF_temporada_actual + k/(n+k)·GF_temporada_anterior.
- Por qué: al inicio de temporada, con 2 o 3 partidos, el promedio es muy ruidoso; se "contrae" hacia la temporada anterior. Con 10 partidos la temporada actual pesa 50 %; con 19, 66 %; con 38, 79 %.
- Si el equipo no jugó la temporada anterior en Premier (ascendido), se usa el promedio de la liga.
- k = 10 es un valor operativo, no optimizado.

**Forma reciente** (últimos 10 partidos, decaimiento 0.85):
- Promedio ponderado con pesos 0.85^(antigüedad) normalizados: el partido más reciente pesa 18.7 %, el más antiguo 4.3 %, y los 3 más recientes suman ≈48 %.
- Se aplica a goles, tiros y tiros a puerta, a favor y concedidos.

## B5. Modelo: dos regresiones de Poisson

**Por qué Poisson:** los goles son conteos pequeños (0, 1, 2…) de eventos poco frecuentes; la distribución de Poisson es el modelo clásico para ese tipo de dato y la base de la literatura de pronóstico de fútbol (Maher, 1982; Dixon y Coles, 1997). Los datos lo respaldan: la distribución observada se parece a una Poisson con la misma media y, dentro del modelo, la dispersión de Pearson es 0.99 (local) y 1.04 (visitante), muy cerca del 1 que supone Poisson.

**Por qué dos ecuaciones:** una para los goles del local y otra para los del visitante, cada una con su intercepto y sus coeficientes. Así la ventaja de local no se impone como constante: se estima.

**Enlace logarítmico:** log λ = Xβ garantiza que λ (goles esperados) sea siempre positiva y hace que los efectos sean multiplicativos. Estimación por máxima verosimilitud (`statsmodels.GLM`, familia Poisson).

**Cómo leer los coeficientes de M0:**
- Local: log λ = −0.3864 + 0.4082·D + 0.3338·GF_local + 0.2158·GA_visitante.
- Visitante: log λ = −0.3009 − 0.4870·D + 0.2101·GF_visitante + 0.1589·GA_local.
- Ejemplo: +100 puntos de Elo del local (D = +0.25) multiplican sus goles esperados por e^(0.4082·0.25) ≈ 1.107 (+10.7 %) y los del visitante por e^(−0.4870·0.25) ≈ 0.885 (−11.5 %).
- En escala comparable (+1 desviación estándar): diferencia de Elo +18.6 % goles del local / −18.4 % del visitante; goles a favor del local +16.0 %; goles en contra del visitante +6.9 %; goles en contra del local en la ecuación del visitante +5.1 % (no significativo, p = 0.075).
- El signo de la diferencia de Elo es el esperado en ambas ecuaciones (positivo para el local, negativo para el visitante) y es la variable más significativa (z > 5).

## B6. De goles esperados a probabilidades

- Supuesto: condicional a las variables, los goles de ambos equipos son independientes. Entonces P(marcador h–a) = Poisson(h; λ_local)·Poisson(a; λ_visita).
- La diferencia de goles sigue una distribución de **Skellam**; de ella salen P(local) = P(dif > 0), P(empate) = P(dif = 0) y P(visitante) = P(dif < 0).
- El **marcador más probable** (p. ej. 1–1) puede no coincidir con el **resultado más probable** (p. ej. victoria local): la victoria agrupa muchos marcadores (1–0, 2–0, 2–1…), el empate pocos.

## B7. Especificaciones M0–M4 y multicolinealidad

- M0 (base, 3 variables por ecuación) → M1 (+ forma) → M2 (+ tiros) → M3 (+ tiros a puerta) → M4 (todo, 9 variables). Comparar especificaciones anidadas permite ver si cada bloque aporta.
- En M4 las variables están correlacionadas (tiros vs tiros a puerta: 0.85; VIF máximo 5.5). La multicolinealidad no sesga las predicciones, pero vuelve inestables los coeficientes individuales (en M4, forma y tiros a puerta no son significativos y algunos cambian de signo). Por eso **la evaluación se hace con datos fuera de muestra y no con la significancia de cada coeficiente**, como dice el reporte técnico.

## B8. Evaluación

- **LogLoss (métrica principal):** −promedio de log(probabilidad asignada al resultado que ocurrió). Es una regla de puntuación propia: se minimiza reportando las probabilidades verdaderas, y castiga fuerte la sobreconfianza. Referencias: azar (1/3 cada resultado) = ln 3 ≈ 1.099; exp(−LogLoss) es la probabilidad media (geométrica) asignada a lo que pasó.
- **MAE de goles:** evalúa λ; complementa pero no sustituye al LogLoss (un modelo puede estimar mejor los goles y peor las probabilidades, como pasó con M4 en prueba).
- **Referencia ingenua:** Poisson con las medias de goles del entrenamiento (1.56 del local y 1.31 del visitante), igual para todos los partidos. Es "el modelo sin información sobre los equipos"; como siempre favorece al local, sus aciertos equivalen al porcentaje de victorias locales.
- **Mercado:** p_j = (1/cuota_j) / Σ(1/cuota). La normalización quita el margen de la casa (4.49 % en validación, 5.84 % en prueba) repartiéndolo proporcionalmente; no corrige el sesgo favorito–sorpresa. Las cuotas **nunca** entran al modelo: son sólo la vara de comparación.

## B9. Resultados

| Predictor | LogLoss validación | LogLoss prueba | Aciertos prueba |
|---|---|---|---|
| Azar (1/3) | 1.0986 | 1.0986 | — |
| Referencia ingenua | 1.0794 | 1.0868 | 41.5 % |
| M0 · base | 0.9837 | **1.0306** | 48.0 % |
| M1 · + forma | 0.9823 | 1.0314 | 47.7 % |
| M2 · + tiros | 0.9770 | 1.0352 | 48.7 % |
| M3 · + tiros a puerta | 0.9772 | 1.0326 | 46.5 % |
| M4 · completo | **0.9753** | 1.0344 | 48.2 % |
| Mercado (apertura) | 0.9706 | 1.0200 | 48.9 % |
| Mercado (cierre) | 0.9667 | 1.0170 | 48.9 % |

(El notebook evaluó en prueba sólo M0, M2 y M4; M1 y M3 se agregan aquí con el mismo código para completar la tabla.)

**Lectura:**
1. Todos los modelos superan con claridad a la referencia ingenua: las estadísticas previas sí contienen información.
2. El mercado es mejor en ambos periodos; con ambos juntos la diferencia con M0 (+0.012) es estadísticamente distinta de cero.
3. En validación ganó M4; en prueba ganó M0. Las diferencias entre especificaciones (< 0.01) caen dentro del ruido (IC bootstrap de M4 − M0 incluye el cero en ambos periodos).
4. Todos los LogLoss suben en prueba (incluido el mercado): el periodo de prueba fue más difícil de predecir, con más empates (28.2 % contra 24.5 % en validación).
5. Ningún predictor, ni el mercado, pronostica nunca el empate como resultado más probable, aunque ocurre en uno de cada cuatro partidos.

## B10. Limitaciones

- Independencia de goles (Poisson + Skellam): subestima empates (en prueba M0 asigna 23.7 % en promedio; ocurrieron 28.2 %).
- Parámetros operativos sin optimizar (K = 30, k = 10, 0.85, 10 partidos).
- Elo sólo con partidos de Premier: un equipo que regresa conserva su Elo de hace años y uno nuevo entra con 1,500; no hay regresión a la media entre temporadas.
- Forma reciente de ascendidos puede venir de temporadas lejanas; su promedio previo es el de la liga, lo que los favorece.
- Sin alineaciones, lesiones, calendario ni fichajes: información que el mercado sí tiene.
- Temporadas 2003/04 y 2004/05 incompletas (sólo afectan al Elo inicial).
- Prueba de 419 partidos: intervalos amplios.
- Mercado aproximado (cuotas promedio con normalización proporcional); no se evaluó rentabilidad.

---

# Parte C. Hallazgos de la revisión (para acordar antes de entregar)

Lo positivo primero: **el análisis es reproducible y consistente.** Las métricas del notebook se reproducen a 6 decimales, la caché de variables se reconstruye idéntica y no hay fuga de información en la construcción de variables. Lo que sigue son detalles que un evaluador podría notar.

| # | Tipo | Hallazgo | Sugerencia |
|---|---|---|---|
| C1 | Reproducibilidad | En `Analisis.ipynb`, la celda que imprime el resumen de M0 (`modelos_entrenados["M0_Base"]…summary()`) está **antes** de la celda que define `modelos_entrenados` (sección 5). "Ejecutar todo" desde cero fallaría con `NameError`. | Mover esa celda después de la sección 5 y volver a ejecutar el notebook completo |
| C2 | Consistencia | `main.tex` reporta el LogLoss del mercado en validación como **0.970600**; el notebook da **0.970552** (se redondeó a 4 decimales y se rellenó con ceros). | Corregir a 0.970552 en la tabla de validación |
| C3 | Reproducibilidad | `Limpieza de datos.ipynb`: rutas absolutas (`C:\Users\Daniel\Downloads\...`), el `to_csv` está comentado, el nombre de salida (`E0_filtrado_consolidado.csv`) no coincide con el que usa el análisis (`E0_consolidado.csv`), la salida guardada muestra otra ruta (`roski`), y el texto dice "desde 2021" cuando los datos empiezan en 2001. | Usar rutas relativas, descomentar `to_csv`, unificar el nombre y corregir el año |
| C4 | Datos | 2003/04 y 2004/05 tienen 335 partidos en vez de 380. Hipótesis: `on_bad_lines="skip"` descartó filas con un número de campos distinto al encabezado. | Releer esos dos archivos con `on_bad_lines="warn"` para confirmarlo. Impacto bajo: sólo afecta al Elo de hace 20 años |
| C5 | Código | `wc_predictor.py` se adaptó de un predictor del Mundial: quedan constantes y funciones que el análisis no usa (`N_SIMS`, `AVG_WC_GOALS`, `HIST_URL`, `NAME_MAP`, `INJURY_FACTOR`, `get_lambda` con pesos 50/35/15, `simular_partido` con penales). Además, al importarse lee el CSV con ruta relativa, imprime el ranking Elo y se importa a sí mismo (líneas finales). | Mover lo no usado a otro archivo o documentarlo como "no utilizado". Todos deben saber que **el modelo final es el GLM de Poisson del notebook**, no `get_lambda` |
| C6 | Metodología | Selección de modelo: por validación se elegiría M4; en prueba se compararon tres modelos y ganó M0. Elegir "el mejor en prueba" usa la prueba para seleccionar. | Presentarlo así: "La validación eligió M4; la prueba mostró que su ventaja no generaliza. Las diferencias son menores al ruido, así que por parsimonia preferimos M0, sabiendo que esa preferencia debe confirmarse con la siguiente temporada." |
| C7 | Terminología | Las cuotas `Avg` no son estrictamente "de apertura": Football-Data las registra el viernes por la tarde (partidos de fin de semana) o el martes (entre semana). | Aclararlo una vez en el reporte ("cuotas previas registradas por Football-Data, que llamamos de apertura") |
| C8 | Datos | Un partido tiene más tiros a puerta que tiros: Newcastle–West Ham, 15-ago-2021 (visitante: 8 tiros, 9 a puerta). | Mencionarlo como error de la fuente; su efecto es despreciable |
| C9 | Documentación | El código no enuncia la pregunta de investigación ni la hipótesis que piden las instrucciones. | Acordar la redacción propuesta en A6 para reporte, tablero y exposición |
| C10 | Documentación | `Analisis.ipynb` menciona un `Prueba.ipynb` "que se conserva sin modificaciones", pero no está en la carpeta. | Incluirlo o quitar la mención |
| C11 | Repositorio | Para que GitHub Actions construya el tablero, el repositorio debe incluir `Codigo/proyecto_mod_8` con los dos CSV (≈2.4 MB en total). | Subir la carpeta `06_proyecto` completa como raíz del repositorio |
