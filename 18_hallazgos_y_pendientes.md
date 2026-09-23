# 18. Hallazgos de la revisión y pendientes del equipo

[← Banco de preguntas](17_banco_de_preguntas.md) · [Índice](README.md) · [Glosario →](glosario.md)

> **Solo para el equipo.** Son detalles del trabajo propio que un evaluador podría notar. Conviene
> corregirlos o acordarlos **antes de enviar el reporte (lunes 28 de septiembre de 2026)**.

Lo positivo primero: **el análisis es reproducible y consistente.** Las métricas del notebook se
reproducen a 6 decimales (en Python y en R), la caché de variables se reconstruye idéntica, no hay
fuga de información en la construcción de variables y el tablero se construye desde cero en los
servidores de GitHub con las mismas cifras.

## 18.1 Hallazgos en el código y el reporte

| # | Tipo | Hallazgo | Qué hacer | Responsable sugerido | Estado |
|---|---|---|---|---|---|
| C1 | Reproducibilidad | En `Analisis.ipynb`, la celda que imprime el resumen de M0 (`modelos_entrenados["M0_Base"]…summary()`) está **antes** de la celda que define `modelos_entrenados` (sección 5). "Ejecutar todo" desde cero falla con `NameError`. | Mover la celda después de la sección 5 y volver a ejecutar todo el notebook | Código | Pendiente |
| C2 | Consistencia | `main.tex` reporta el LogLoss del mercado en validación como **0.970600**; el notebook da **0.970552** (se redondeó a 4 decimales y se rellenó con ceros) | Corregir la tabla de validación | Reporte | Pendiente |
| C3 | Reproducibilidad | `Limpieza de datos.ipynb`: rutas absolutas (`C:\Users\Daniel\Downloads\...`); el `to_csv` está comentado; el archivo de salida se llama `E0_filtrado_consolidado.csv`, pero el análisis lee `E0_consolidado.csv`; la salida guardada muestra otra ruta; el texto dice "desde 2021" cuando los datos empiezan en 2001 | Rutas relativas, descomentar `to_csv`, unificar el nombre y corregir el año | Código | Pendiente |
| C4 | Datos | 2003/04 y 2004/05 tienen 335 partidos en vez de 380. Hipótesis: `on_bad_lines="skip"` descartó filas con un número de campos distinto al encabezado | Releer esos dos archivos con `on_bad_lines="warn"` para confirmarlo. Impacto bajo: solo afecta el Elo de hace 20 años | Código | Por confirmar |
| C5 | Código | `wc_predictor.py` conserva constantes y funciones del predictor del Mundial que no se usan (`N_SIMS`, `AVG_WC_GOALS`, `HIST_URL`, `NAME_MAP`, `INJURY_FACTOR`, `get_lambda`, `simular_partido`). Además, al importarse lee el CSV con ruta relativa, imprime el ranking Elo y se importa a sí mismo | Mover lo no usado a otro archivo o marcarlo como "no utilizado". **Todos deben saber que el modelo final es el GLM de Poisson del notebook** | Código | Pendiente |
| C6 | Metodología | Por validación se elegiría M4; en prueba ganó M0. Presentar "el mejor en prueba" usa la prueba para seleccionar | Usar esta redacción: "La validación eligió M4; la prueba mostró que su ventaja no generaliza. Las diferencias son menores al ruido, así que por parsimonia preferimos M0, sabiendo que esa preferencia debe confirmarse con la siguiente temporada" | Reporte + todos | Acordar |
| C7 | Terminología | Las cuotas `Avg` no son estrictamente "de apertura": Football-Data las registra el viernes por la tarde (partidos de fin de semana) o el martes (entre semana) | Aclararlo una vez en el reporte: "cuotas previas registradas por Football-Data, que llamamos de apertura" | Reporte | Pendiente |
| C8 | Datos | Un partido tiene más tiros a puerta que tiros: Newcastle–West Ham, 15-ago-2021 (visitante: 8 tiros, 9 a puerta) | Mencionarlo como error de la fuente; su efecto es despreciable | Reporte | Opcional |
| C9 | Documentación | El código no enuncia la pregunta de investigación ni la hipótesis que piden las instrucciones | Usar la misma redacción en reporte, tablero y exposición ([cap. 2](02_contexto_y_datos.md)) | Reporte | Acordar |
| C10 | Documentación | `Analisis.ipynb` menciona un `Prueba.ipynb` "que se conserva sin modificaciones", pero no está en la carpeta | Incluirlo o quitar la mención | Código | Pendiente |
| C11 | Repositorio | Para que GitHub Actions construya el tablero, el repositorio debe incluir `Codigo/proyecto_mod_8` con los dos CSV | — | — | **Resuelto** (22-sep) |

**Si el equipo de Código corrige C1, C3, C5 o C10 en el repositorio público**, cada push reconstruye
el tablero. La pestaña *Reproducibilidad* avisa si alguna de las 15 cifras cambia.

## 18.2 Decisiones que el equipo debe tomar

| Decisión | Opciones | Recomendación |
|---|---|---|
| **Redacción de la pregunta y la hipótesis** (C9) | Usar la del tablero o acordar otra | Usar la del tablero, para que reporte, tablero y exposición digan lo mismo |
| **"El modelo" es M0** (C6) | M0 (mejor en prueba, más simple) o M4 (mejor en validación) | M0, con la redacción honesta de C6 |
| **¿El reporte incluye los análisis que agregó el tablero?** | Bootstrap, calibración, descomposición de la brecha, sensibilidad sin público, aciertos | Incluir al menos el bootstrap y la descomposición de la brecha: responden "¿son significativas las diferencias?" y "¿dónde pierde el modelo?" |
| **URL de la visualización en el reporte** | https://pitirringo.github.io/futbol-apuestas/ | Ponerla en la portada o el resumen del reporte, junto con la del repositorio |
| **Nombres del equipo visibles en el tablero y el repositorio público** | Mantener o retirar | Confirmar con cada integrante que está de acuerdo |

## 18.3 Lista de verificación antes del lunes 28

**Repositorios**
- [ ] Borrar las dos ejecuciones viejas del flujo en Actions (#35808804918 y #35809813982) ([cap. 14](14_publicacion_en_github.md)).
- [ ] Crear el repositorio privado `futbol-apuestas-defensa` y subir esta guía.
- [ ] Invitar al equipo como colaboradores en el repositorio privado (y en el público, si el equipo de Código va a subir correcciones).
- [ ] Cada integrante acepta la invitación y puede abrir los dos repositorios.

**Código y reporte**
- [ ] C1, C3, C5 y C10 corregidos (o documentados como "no utilizado").
- [ ] C2 y C7 corregidos en `main.tex`.
- [ ] Pregunta, hipótesis y elección de M0 redactadas igual en reporte y tablero.
- [ ] URL del tablero y del repositorio en el reporte.
- [ ] Lista de integrantes en el correo de entrega.

**Exposición (1 o 6 de octubre)**
- [ ] Cada integrante estudió la guía (ruta de estudio en el [índice](README.md)).
- [ ] Dos ensayos cronometrados del [guion](16_guion_exposicion.md).
- [ ] Todos contestaron el [banco de preguntas](17_banco_de_preguntas.md) en voz alta.
- [ ] Respaldo sin internet preparado.

## 18.4 Registro de cambios de esta guía

| Fecha | Cambio |
|---|---|
| 22-sep-2026 | Primera versión como repositorio privado: 18 capítulos, glosario y 5 scripts de R verificados. Reemplaza a `DECISIONES.md` y `GUIA_DEFENSA.md`, que estaban en el repositorio público y se retiraron (versiones anteriores en `archivo/`) |
