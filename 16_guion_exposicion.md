# 16. Guion de la exposición (5 minutos)

[← Limitaciones](15_limitaciones_y_extensiones.md) · [Índice](README.md) · [Siguiente: banco de preguntas →](17_banco_de_preguntas.md)

**Formato:** 5 minutos de exposición (problema, datos, análisis y modelado, resultados y
conclusión) y después **2 preguntas que pueden hacerle a cualquier integrante**. 

## 16.1 Esbozo de la expo

| Tiempo | Parte | Página del tablero | Qué señalar |
|---|---|---|---|
| 0:00–0:40 | **Problema** | Resumen | Tarjeta "Pregunta" (pregunta, hipótesis y resultado: "se acerca mucho al mercado, pero no lo supera") |
| 0:40–1:20 | **Datos** | ¿Qué ocurre? | Los 3 indicadores (9,540 · 45.6 % · 54.2 %) y la línea de 2020/21 |
| 1:20–2:30 | **Análisis y modelado** | Patrones → El modelo | Curvas de Elo, diagonal de calibración y diagrama "Cómo funciona" |
| 2:30–4:00 | **Resultados** | Resumen → El modelo | Barras M0 contra mercado; gráfica de "pesas"; barras de la brecha |
| 4:00–4:40 | **Conclusión y limitaciones** | Resumen | Tarjeta de la derecha, "Resumen" (la "lectura en 20 segundos") |
| 4:40–5:00 | **Cierre con demostración** | Explora un partido | Arsenal contra Man City |

Cifras vigentes que hay que tener a mano (todas salen de [`Analisis.ipynb`](11_codigo_analisis_notebook.md) y del
tablero; el detalle, en el [capítulo 12](12_resultados.md)):

| Cifra | Valor |
|---|---|
| Partidos · temporadas | 9,540 · 26 (2001/02 a 2026/27, 14-sep-2026) |
| Gana local · favorito de las cuotas | 45.6 % · 54.2 % |
| Entrenamiento · validación · prueba | 1,897 · 380 · 419 partidos |
| K del Elo y k de los promedios de la temporada, calibrados | **K = 15, k = 0** (validación temporal, 35 combinaciones) |
| Aciertos en prueba: modelo base · mercado · ingenua | 48.0 % · 48.9 % · 41.5 % |
| LogLoss en prueba: modelo base · mercado de apertura | 1.033 · 1.020 (en validación: 0.990 · 0.971) |
| Ventaja del mercado que alcanza el modelo (así se llama la caja del tablero) | **80 %** en prueba (83 % en validación) |
| Brecha M0 − mercado con validación y prueba juntas | +0.016 (IC 95 %: +0.006 a +0.025) |
| Arsenal – Man City (M0) | 43.7 % · 25.0 % · 31.4 %; marcador más probable 1–1 (11.8 %) |

## 16.2 Resumen esbozo

Es una guía, no un texto para leer. Lo que va entre **[corchetes]** es la acción en el tablero; lo
marcado *(opcional)* se omite si van atrasados.

### 0:00–0:40 · Problema — [Resumen]

> Buenas tardes. Nuestro proyecto es **Fútbol y mercados de apuestas**. Las casas de apuestas
> publican cuotas, y cada cuota implica una probabilidad: una cuota de 2.50 equivale a 40 %.
> **[Señalar la tarjeta "Pregunta"]** Nos preguntamos qué tan bien anticipan el resultado de un
> partido de la Premier League las estadísticas disponibles antes del encuentro, comparadas con esas
> probabilidades del mercado. Nuestra hipótesis fue que las estadísticas sí contienen información,
> pero que el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor. La
> respuesta corta, que está en la misma tarjeta: **el modelo se acerca mucho al mercado, pero no lo
> supera.**

### 0:40–1:20 · Datos — [¿Qué ocurre?]

> Usamos **9,540 partidos** de la Premier League, de 2001 a septiembre de 2026, de Football-Data:
> resultados, estadísticas de cada partido y cuotas. Unimos los 26 archivos de temporada,
> homologamos las fechas y ordenamos todo cronológicamente. Dos hechos marcan el problema.
> **[Señalar la gráfica de localía]** El local gana 46 % de las veces, pero en la temporada sin
> público por la pandemia esa ventaja desapareció. **[Señalar "Ni el favorito es garantía"]** Y el
> favorito de las casas de apuestas solo gana 54 % de los partidos. El fútbol es incierto por
> naturaleza: acertar la mitad ya es bueno.

### 1:20–2:30 · Análisis y modelado — [Patrones → El modelo]

> Tres patrones guiaron el modelo. **[Patrones: curvas de Elo]** La diferencia de fuerza, medida con
> un rating **Elo**, ordena los resultados: cuando el local es mucho más débil gana 13 % de las veces;
> cuando es mucho más fuerte, 76 %. **[Calibración]** Las cuotas están bien calibradas: cuando dicen
> 70 %, ocurre cerca de 70 %. *(opcional: Y los goles se comportan como un conteo de Poisson.)*
>
> **[El modelo: "Cómo funciona"]** Por eso ajustamos **dos regresiones de Poisson**, una para los
> goles del local y otra para los del visitante, con variables calculadas **solo con partidos
> anteriores**: la diferencia de Elo y los goles a favor y en contra **de la temporada**. De los goles
> esperados sale la probabilidad de cada marcador y, sumando, las de victoria local, empate y
> visita. Entrenamos con 2019 a 2024 y elegimos entre cinco especificaciones con la temporada 2024/25.
> Los parámetros del Elo y de los promedios, **K = 15 y k = 0**, los calibramos con validación
> temporal en tres temporadas anteriores, sin tocar la validación ni la prueba. Medimos con partidos
> que el modelo nunca vio, de agosto de 2025 a septiembre de 2026. La métrica principal es el
> **LogLoss**, que evalúa las probabilidades completas y no solo si se acertó.

### 2:30–4:00 · Resultados — [Resumen → El modelo]

> **[Resumen: gráfica principal]** Encontramos tres cosas. Primero, **las estadísticas sí anticipan
> resultados**: el modelo base, con solo tres variables, acierta **48 %** de los partidos de prueba,
> contra 41.5 % de apostar siempre por el local, y su mejora sobre una referencia ingenua es
> estadísticamente significativa.
>
> Segundo, **el mercado sabe un poco más**: acierta 49 % y tiene menor LogLoss en validación y en
> prueba (1.020 contra 1.033). Nuestro modelo logra el **80 % de la mejora** que consigue el mercado
> sobre esa referencia ingenua. Juntando ambos periodos, 799 partidos, la diferencia es pequeña pero
> distinta de cero. Es decir, nos acercamos mucho, pero no lo superamos.
>
> **[El modelo: gráfica de pesas]** Tercero, **más variables no es mejor**: forma reciente y tiros
> ayudaron en validación y dejaron de ayudar en prueba. Las diferencias entre especificaciones
> están dentro del ruido, así que preferimos el modelo más simple. Por eso la hipótesis de que las
> variables adicionales mejoran el modelo, que es la que plantea el reporte, se respalda **sólo
> parcialmente**.
>
> **[Barras de la brecha]** ¿Dónde pierde contra el mercado? Sobre todo en victorias locales y, en
> menor medida, en empates, que el modelo subestima: en prueba les da 23.6 % y ocurrieron 28.2 %.
> *(opcional: En victorias visitantes, en cambio, el modelo es ligeramente mejor.)*

### 4:00–4:40 · Conclusión — [Resumen: tarjeta "Resumen", la lectura en 20 segundos]

> En conclusión: **las cuotas ya incorporan la información estadística pública, y más.** Un modelo
> simple y transparente se acerca mucho, pero no supera al mercado ni encuentra una ventaja
> sistemática. Las principales limitaciones son tres: el supuesto de independencia de goles; que
> calibramos sólo K y k y no los demás parámetros; y la falta de información de alineaciones y
> lesiones, que el mercado sí tiene.

### 4:40–5:00 · Cierre — [Explora un partido]

> Para cerrar, el tablero permite explorar cualquier partido. **[Arsenal contra Man City]** Nuestro
> modelo da 43.7 % para Arsenal, 25.0 % de empate y 31.4 % para el City, y el marcador más probable
> es 1–1. Todo está publicado y se puede reproducir desde el repositorio. Gracias.

## 16.3 Frases de transición para las preguntas

Después de los 5 minutos vienen **2 preguntas**. Estas frases sirven para **empezar a contestar con seguridad** y
volver al hilo del guion; el resto de la respuesta está en el capítulo que se indica y en el
[banco de preguntas](17_banco_de_preguntas.md). Qué decir y qué no decir, en el
[capítulo 12](12_resultados.md#125-qué-decir-y-qué-no-decir): por ejemplo, **no** decir "K = 15 es el óptimo", "casi
empatamos con el mercado" ni "M4 es mejor que M0".

**Si preguntan por la calibración de K y k (el Elo y los promedios):**

> "K y k no los fijamos a mano: los calibramos con validación temporal en tres temporadas anteriores a la validación,
> probando 35 combinaciones, y K = 15 con k = 0 dio el menor LogLoss. K quedó en el borde de la rejilla y su efecto es
> pequeño, así que no decimos que sea el óptimo; y la conclusión frente al mercado no depende de ellos."
> ([9.3](09_evaluacion_y_validacion.md#93-la-calibración-de-k-y-k-validación-temporal-de-ventana-creciente) y
> [12.2](12_resultados.md#la-configuración-anterior-de-k-y-k-fuera-de-muestra))

**Si preguntan si el modelo está calibrado (las probabilidades):**

> "Las cuotas están mejor calibradas que nuestro modelo. M0 es algo sobreconfiado con los favoritos: cuando dice 64 %,
> ocurre 57 %, aunque hay pocos casos en esos grupos. Es una de las razones por las que el mercado gana, y no la única:
> además tiene información que nosotros no tenemos."
> ([12.4](12_resultados.md#calibración-lo-que-dice-cada-uno-contra-lo-que-ocurre))

**Si preguntan por el reporte:**

> "El reporte pregunta si agregar variables mejora la predicción, y responde que sólo en parte: M4 gana en validación
> por un margen mínimo, pero en prueba el mejor LogLoss es el de M0, y el MAE favorece a otro modelo. El tablero
> pregunta lo mismo frente al mercado: el modelo logra el 80 % de su mejora, sin superarlo. Son dos lecturas de los
> mismos números."
> ([capítulo 20](20_el_reporte_entregado.md#202-la-pregunta-y-la-hipótesis-dos-formulaciones-que-conviene-saber-conciliar))



