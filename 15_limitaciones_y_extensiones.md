# 15. Limitaciones y extensiones

[← Publicación en GitHub](14_publicacion_en_github.md) · [Índice](README.md) · [Siguiente: guion de la exposición →](16_guion_exposicion.md)

Las instrucciones piden que cualquier integrante pueda explicar "cuáles son las principales
limitaciones". Conocerlas **no debilita el proyecto: demuestra que se entiende**. La regla para
hablar de ellas es: **qué es → qué efecto tiene (con número si lo hay) → cómo se corregiría.**

## 15.1 Las cinco que hay que saber de memoria

| # | Limitación | Efecto medido | Cómo se corregiría |
|---|---|---|---|
| 1 | **Independencia de goles** (dos Poisson independientes) | **Subestima los empates:** en prueba M0 asignó 23.7 % en promedio y ocurrieron 28.2 % (el mercado asignó 24.5 %) | Corrección de **Dixon–Coles** (1997) o Poisson bivariada |
| 2 | **Parámetros sin optimizar** (K = 30, k = 10, decaimiento 0.85, 10 partidos, escala 400) | Desconocido: son valores razonables, no los mejores posibles | Búsqueda en rejilla con **validación temporal** (ventanas que avanzan en el tiempo) |
| 3 | **Sin información de alineaciones, lesiones ni noticias** | Es la ventaja principal del mercado; el **cierre**, con más información, es aún mejor (1.0170 contra 1.0200 de la apertura) | Variables de disponibilidad de jugadores; comparar contra cuotas de cierre |
| 4 | **Equipos ascendidos y Elo solo de Premier** | Un equipo que regresa conserva su Elo de hace años; uno nuevo empieza en 1,500; su "temporada anterior" es el promedio de la liga | Elo que incluya la segunda división, o una regresión parcial a la media al inicio de cada temporada |
| 5 | **Muestra de prueba de 419 partidos** | Intervalos amplios: la brecha M0 − mercado en prueba (+0.011) tiene IC de −0.004 a +0.025; entre M0 y M4 nada es concluyente | Evaluar la siguiente temporada completa; juntar periodos (con 799 partidos la brecha sí es distinta de cero) |

## 15.2 Todas las limitaciones, por tipo

### Del modelo

| Limitación | Detalle | Qué tan grave |
|---|---|---|
| Independencia condicional de goles | El supuesto hace que el 0–0 y el 1–1 salgan menos probables de lo que son ([cap. 7](07_de_goles_a_probabilidades.md)) | **Alta**: los empates son una de las dos fuentes de la brecha con el mercado (aportan +0.010; las victorias locales +0.011; en victorias visitantes el modelo es mejor, −0.010; total +0.012) |
| Sobreconfianza con favoritos | Cuando M0 dice 64.6 %, ocurre 58.5 %; cuando dice 74.7 %, ocurre 68.1 % ([cap. 9](09_evaluacion_y_validacion.md)) | Media |
| Coeficientes fijos en el tiempo | Se estiman una vez con 2019–2024 y no se actualizan, aunque el fútbol cambia (reglas, estilos, tiempo añadido) | Media; un modelo que se reentrena cada jornada lo resolvería |
| La ventaja de local es la misma para todos | El intercepto de cada ecuación da una ventaja promedio; no hay estadios "más difíciles" | Baja |
| Modelo predictivo, no causal | Los coeficientes indican **asociación**. "Más Elo" no **causa** más goles; ambos reflejan la calidad del equipo | Es de interpretación: no afecta las predicciones, pero cambia qué se puede afirmar |
| Selección de modelo con información de prueba | La validación eligió M4, pero se presenta M0 porque fue mejor en prueba ([cap. 18](18_hallazgos_y_pendientes.md), C6) | Se reconoce abiertamente; hay que confirmarla con la siguiente temporada |

### De las variables

| Limitación | Detalle |
|---|---|
| Parámetros operativos | K, k, decaimiento, número de partidos y escala 400 no se optimizaron |
| Elo sin margen de victoria | Ganar 1–0 o 5–0 mueve el Elo igual |
| Elo sin localía | Las expectativas de Elo no suman la ventaja de local. El modelo la estima aparte, con el intercepto de cada ecuación |
| Forma de ascendidos | Sus últimos 10 partidos en la base pueden ser de hace años (Norwich en 2019 usaba partidos de 2016) |
| Sin xG | Los goles esperados (xG) solo existen en 2026/27 (40 partidos), así que no pudieron usarse |

### De los datos

| Limitación | Detalle | Impacto |
|---|---|---|
| 2003/04 y 2004/05 incompletas | 335 de 380 partidos cada una (probablemente filas descartadas al leer) | Solo afecta el Elo de hace 20 años |
| Un error de la fuente | Newcastle–West Ham (15-ago-2021): el visitante aparece con 8 tiros y 9 a puerta | Despreciable |
| Cuotas promedio desde 2019/20 | Por eso la modelación empieza en 2019 | Define el periodo |
| Solo Premier League | Otras ligas pueden comportarse distinto | Limita la generalización |

### De la comparación con el mercado

| Limitación | Detalle |
|---|---|
| "Apertura" no es la primera cuota | Football-Data registra las cuotas `Avg` el viernes por la tarde (partidos de fin de semana) o el martes (entre semana) |
| Normalización proporcional | Quita el margen repartiéndolo en proporción. No corrige el **sesgo favorito–sorpresa**; hay métodos más finos (Shin, potencia) ([cap. 8](08_cuotas_y_mercado.md)) |
| Cuota promedio del mercado | Es un promedio de casas. Una casa "afilada" como Pinnacle podría ser una vara más exigente |
| No se evaluó rentabilidad | Fuera del alcance. Con un margen de ≈ 5 % y un modelo que no supera al mercado, no hay evidencia de ventaja explotable |

### Del tablero

| Limitación | Detalle |
|---|---|
| Foto fija | Los datos llegan al 14-sep-2026; actualizar requiere nuevos datos y un push (la publicación sí es automática) |
| Simulador precalculado | 380 combinaciones con M0 y datos al 15-sep-2026; no admite ajustes (lesiones, alineaciones) |
| Depende de JavaScript | Sin JavaScript no se ven las gráficas (las tablas de las pestañas sí) |
| Solo en español | Audiencia del diplomado |

## 15.3 Extensiones, en orden de prioridad

1. **Corrección de Dixon–Coles.** Ajusta las probabilidades de 0–0, 1–0, 0–1 y 1–1 con un parámetro
   ρ estimado de los datos. Ataca directamente la mayor debilidad (empates). En R existen paquetes
   que lo implementan (`regista`, `goalmodel`; no están instalados en esta computadora). En Python
   se programa maximizando la verosimilitud con `scipy.optimize`.
2. **¿El modelo aporta información que el mercado no tiene?** Una regresión (logística multinomial)
   del resultado contra las probabilidades del mercado **y** las del modelo. Si el coeficiente del
   modelo es distinto de cero, el modelo contiene información que las cuotas no incorporan. Es la
   prueba más directa de la pregunta de investigación.
3. **Optimizar los parámetros con validación temporal.** Probar varios valores de K, k y
   decaimiento con ventanas que avanzan en el tiempo (*rolling origin*), sin tocar la prueba.
4. **Elo mejorado:** ventaja de local dentro del Elo, margen de victoria, regresión parcial a la
   media entre temporadas y ratings que incluyan la segunda división (para los ascendidos).
5. **Reentrenar cada jornada** (ventana móvil), para que los coeficientes se adapten a los cambios
   del juego.
6. **Más información:** xG cuando haya historial, disponibilidad de jugadores y días de descanso.
7. **Otras varas de comparación:** cuotas de cierre como referencia principal y casas "afiladas".
8. **Otros modelos:** logística multinomial u ordinal, que predicen el 1X2 directamente (en R,
   `nnet::multinom()` y `MASS::polr()`); binomial negativa (`MASS::glm.nb()`), que no hace falta
   porque la dispersión es ≈ 1; o *gradient boosting* (`xgboost`, instalado en Python), sabiendo que
   se pierde interpretabilidad.
9. **Pregunta sugerida no analizada:** ¿hay equipos sistemáticamente sobre o infravalorados por el
   mercado? Se respondería comparando por equipo la probabilidad implícita contra la frecuencia real.
10. **Simulación académica de apuestas con capital ficticio**, como permiten las instrucciones,
    incluyendo el margen de la casa.
11. **Tablero que se actualiza solo:** un flujo de GitHub Actions programado (`schedule` con `cron`)
    que descargue los datos nuevos cada semana y vuelva a publicar.

## 15.4 Lo que se decidió no mostrar (y por qué)

| Fuera del tablero | Por qué |
|---|---|
| xG | Solo existe para 40 partidos (2026/27) |
| Córners, faltas, tarjetas, árbitro | No entran al modelo ni responden la pregunta |
| Rentabilidad o simulación de apuestas | Fuera del alcance; tema sensible |
| Coeficientes crudos de M4 en portada | Con VIF de hasta 5.5, sus signos individuales son inestables y confunden |
| M1–M3 en el Resumen | Están en *El modelo*; en portada se muestran solo M0, M4 y el mercado, para no saturar |
| Equipos sobre o infravalorados | El equipo no lo analizó; queda como extensión |
| Gauges y pasteles | El tutorial del módulo pregunta si el gauge "facilita una decisión o solamente ocupa espacio" |

## 15.5 Cómo responder "¿qué harían diferente?" en 20 segundos

> "Tres cosas. Primero, corregir la independencia de goles con Dixon–Coles, porque subestimar los
> empates es una de las dos fuentes de nuestra brecha con el mercado. Segundo, optimizar los parámetros del
> Elo y del *shrinkage* con validación temporal, porque hoy son valores razonables pero no
> optimizados. Y tercero, probar formalmente si el modelo aporta información que el mercado no
> tiene, combinando ambos en una regresión."
