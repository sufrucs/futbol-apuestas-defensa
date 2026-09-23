# 16. Guion de la exposición (5 minutos)

[← Limitaciones](15_limitaciones_y_extensiones.md) · [Índice](README.md) · [Siguiente: banco de preguntas →](17_banco_de_preguntas.md)

**Formato:** 5 minutos de exposición (problema, datos, análisis y modelado, resultados y
conclusión) y después **2 preguntas que pueden hacerle a cualquier integrante**. 

## 16.1 Esbozo de la expo

| Tiempo | Parte | Página del tablero | Qué señalar |
|---|---|---|---|
| 0:00–0:40 | **Problema** | Resumen | Tarjeta "Pregunta" (pregunta, hipótesis y respuesta corta) |
| 0:40–1:20 | **Datos** | ¿Qué ocurre? | Los 3 indicadores (9,450 · 45.6 % · 54.3 %) y la línea de 2020/21 |
| 1:20–2:30 | **Análisis y modelado** | Patrones → El modelo | Curvas de Elo, diagonal de calibración y diagrama "Cómo funciona" |
| 2:30–4:00 | **Resultados** | Resumen → El modelo | Barras M0 contra mercado; gráfica de "pesas"; barras de la brecha |
| 4:00–4:40 | **Conclusión y limitaciones** | Resumen | Tarjeta "Lectura en 20 segundos" |
| 4:40–5:00 | **Cierre con demostración** | Explora un partido | Arsenal contra Man City |

## 16.2 Resumen esbozo

Es una guía, no un texto para leer. Lo que va entre **[corchetes]** es la acción en el tablero; lo
marcado *(opcional)* se omite si van atrasados.

### 0:00–0:40 · Problema — [Resumen]

> Buenas tardes. Nuestro proyecto es **Fútbol y mercados de apuestas**. Las casas de apuestas
> publican cuotas, y cada cuota implica una probabilidad: una cuota de 2.50 equivale a 40 %.
> **[Señalar la tarjeta "Pregunta"]** Nos preguntamos qué tan bien anticipan el resultado de un
> partido de la Premier League las estadísticas disponibles antes del encuentro, comparadas con esas
> probabilidades del mercado. Nuestra hipótesis fue que las estadísticas sí contienen información,
> pero que el mercado, que además conoce alineaciones, lesiones y noticias, la aprovecha mejor.

### 0:40–1:20 · Datos — [¿Qué ocurre?]

> Usamos **9,450 partidos** de la Premier League, de 2001 a septiembre de 2026, de Football-Data:
> resultados, estadísticas de cada partido y cuotas. Unimos los 26 archivos de temporada,
> homologamos las fechas y ordenamos todo cronológicamente. Dos hechos marcan el problema.
> **[Señalar la gráfica de localía]** El local gana 46 % de las veces, pero en la temporada sin
> público por la pandemia esa ventaja desapareció. **[Señalar "Ni el favorito es garantía"]** Y el
> favorito de las casas de apuestas solo gana 54 % de los partidos. El fútbol es incierto por
> naturaleza: acertar la mitad ya es bueno.

### 1:20–2:30 · Análisis y modelado — [Patrones → El modelo]

> Tres patrones guiaron el modelo. **[Patrones: curvas de Elo]** La diferencia de fuerza, medida con
> un rating **Elo**, ordena los resultados: cuando el local es mucho más débil gana 14 % de las veces;
> cuando es mucho más fuerte, 76 %. **[Calibración]** Las cuotas están bien calibradas: cuando dicen
> 70 %, ocurre cerca de 70 %. *(opcional: Y los goles se comportan como un conteo de Poisson.)*
>
> **[El modelo: "Cómo funciona"]** Por eso ajustamos **dos regresiones de Poisson**, una para los
> goles del local y otra para los del visitante, con variables calculadas **solo con partidos
> anteriores**: la diferencia de Elo y los goles a favor y en contra ajustados. De los goles
> esperados sale la probabilidad de cada marcador y, sumando, las de victoria local, empate y
> visita. Entrenamos con 2019 a 2024, elegimos entre cinco especificaciones con la temporada 2024/25
> y evaluamos **una sola vez** con partidos de agosto de 2025 a septiembre de 2026. La métrica
> principal es el **LogLoss**, que evalúa las probabilidades completas y no solo si se acertó.

### 2:30–4:00 · Resultados — [Resumen → El modelo]

> **[Resumen: gráfica principal]** Encontramos tres cosas. Primero, **las estadísticas sí anticipan
> resultados**: el modelo base, con solo tres variables, acierta **48 %** de los partidos de prueba,
> contra 41.5 % de apostar siempre por el local, y su mejora sobre una referencia ingenua es
> estadísticamente significativa.
>
> Segundo, **el mercado sabe un poco más**: acierta 49 % y tiene menor LogLoss en validación y en
> prueba. Nuestro modelo logra el **84 % de la mejora** que consigue el mercado sobre esa referencia
> ingenua. Juntando ambos periodos, 799 partidos, la diferencia es pequeña pero distinta de cero.
>
> **[El modelo: gráfica de pesas]** Tercero, **más variables no es mejor**: forma reciente y tiros
> ayudaron en validación y dejaron de ayudar en prueba. Las diferencias entre especificaciones
> están dentro del ruido, así que preferimos el modelo más simple.
>
> **[Barras de la brecha]** ¿Dónde pierde contra el mercado? En victorias locales y en empates. El
> modelo supone que los goles de ambos equipos son independientes, y eso subestima los empates.
> *(opcional: En victorias visitantes, en cambio, el modelo es ligeramente mejor.)*

### 4:00–4:40 · Conclusión — [Resumen: "Lectura en 20 segundos"]

> En conclusión: **las cuotas ya incorporan la información estadística pública, y más.** Un modelo
> simple y transparente se acerca mucho, pero no encuentra una ventaja sistemática. Las principales
> limitaciones son el supuesto de independencia de goles, parámetros que no optimizamos y la falta
> de información de alineaciones y lesiones, que el mercado sí tiene.

### 4:40–5:00 · Cierre — [Explora un partido]

> Para cerrar, el tablero permite explorar cualquier partido. **[Arsenal contra Man City]** Nuestro
> modelo da 46 % para Arsenal, 25 % de empate y 29 % para el City, y el marcador más probable es
> 1–1. Todo está publicado y se puede reproducir desde el repositorio. Gracias.



