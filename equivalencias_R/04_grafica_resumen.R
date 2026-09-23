# =============================================================================
# 04_grafica_resumen.R — La gráfica principal del tablero, hecha con ggplot2 (+ plotly)
#
# En el tablero (Python) esta gráfica la construye graficas.mejora_sobre_ingenua() con
# plotly.graph_objects. Aquí se muestra cómo se haría con las herramientas de R que se
# vieron en el módulo: ggplot2 para la gráfica y plotly::ggplotly() para volverla interactiva
# (como en el tutorial de Flexdashboard).
#
#   Rscript equivalencias_R/04_grafica_resumen.R   -> guarda grafica_resumen.png
# =============================================================================

library(ggplot2)

# Valores de LogLoss (salen de 02_modelo_poisson.R y 03_mercado.R; aquí se escriben para
# que el ejemplo se concentre en la gráfica).
logloss <- data.frame(
  predictor = rep(c("Mercado (cuotas de apertura)", "Modelo base M0 · 3 variables",
                    "Modelo completo M4 · 9 variables"), times = 2),
  periodo = rep(c("Validación 2024/25", "Prueba 2025/26 – sep 2026"), each = 3),
  logloss = c(0.970552, 0.983690, 0.975296, 1.020000, 1.030556, 1.034434),
  ingenua = rep(c(1.079361, 1.086791), each = 3)   # referencia ingenua: validación, prueba
)
# Mejora = LogLoss de la referencia ingenua - LogLoss del predictor (más es mejor)
logloss$mejora <- logloss$ingenua - logloss$logloss
logloss$predictor <- factor(logloss$predictor, levels = rev(unique(logloss$predictor)))
logloss$periodo <- factor(logloss$periodo, levels = c("Validación 2024/25", "Prueba 2025/26 – sep 2026"))

colores <- c("Mercado (cuotas de apertura)" = "#eb6834",       # naranja = mercado
             "Modelo base M0 · 3 variables" = "#2a78d6",       # azul = modelo
             "Modelo completo M4 · 9 variables" = "#898781")   # gris = contexto

# group = periodo: le dice a position_dodge() qué barras van juntas; sin él, las etiquetas
# de geom_text() no sabrían a cuál de las dos barras del grupo pertenecen.
grafica <- ggplot(logloss, aes(x = mejora, y = predictor, fill = predictor, alpha = periodo, group = periodo)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +     # barras agrupadas desde 0
  geom_text(aes(label = sprintf("%.3f", mejora)),                        # etiquetas directas
            position = position_dodge(width = 0.75), hjust = -0.15, size = 3.5, alpha = 1) +
  scale_fill_manual(values = colores, guide = "none") +                  # el color = quién pronostica
  scale_alpha_manual(values = c(0.4, 1), name = NULL) +                  # el tono = el periodo
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "El modelo recupera la mayor parte de la ventaja del mercado,\npero no lo supera",
       subtitle = "Reducción del LogLoss respecto a la referencia ingenua (más es mejor)",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", panel.grid.major.y = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave("equivalencias_R/grafica_resumen.png", grafica, width = 9, height = 4.8, dpi = 120)
cat("Gráfica guardada en equivalencias_R/grafica_resumen.png\n")

# Versión interactiva (tooltips), como en el tutorial de Flexdashboard:
#   plotly::ggplotly(grafica)
# Dentro de un flexdashboard bastaría con poner ese objeto como salida de un chunk.
