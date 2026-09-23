# =============================================================================
# 03_mercado.R — Las cuotas como probabilidades y la comparación contra el modelo, en R
#
# Equivale a Analisis.ipynb §7-8 (cargar_cuotas, comparar_con_mercado) y a los
# complementos del tablero (referencia ingenua, bootstrap).
# Requiere haber corrido antes 02_modelo_poisson.R (usa probabilidades_prueba.rds).
#
#   Rscript equivalencias_R/03_mercado.R
# =============================================================================

library(readr)
library(dplyr)

RUTA_LOCAL <- "../06_proyecto/Codigo/proyecto_mod_8"
RUTA_WEB <- "https://raw.githubusercontent.com/pitirringo/futbol-apuestas/main/Codigo/proyecto_mod_8"
ruta <- function(archivo) {
  local <- file.path(RUTA_LOCAL, archivo)
  if (file.exists(local)) local else paste(RUTA_WEB, archivo, sep = "/")
}

guardado <- readRDS("equivalencias_R/probabilidades_prueba.rds")
prueba <- guardado$prueba
P_m0 <- guardado$P_m0

resultado <- function(d) ifelse(d$home_goals > d$away_goals, 1L,
                                ifelse(d$home_goals == d$away_goals, 2L, 3L))
logloss_partido <- function(P, y) -log(P[cbind(seq_along(y), y)])
y <- resultado(prueba)

# --- 1. Cuotas -> probabilidad implícita (notebook §7) -----------------------
# Python: pd.read_csv(..., usecols=CLAVES + CUOTAS) y un merge por fecha y equipos.
cuotas <- read_csv(ruta("E0_consolidado.csv"), show_col_types = FALSE) |>
  select(Date, HomeTeam, AwayTeam, AvgH, AvgD, AvgA)
prueba_cuotas <- prueba |> left_join(cuotas, by = c("Date", "HomeTeam", "AwayTeam"))
stopifnot(nrow(prueba_cuotas) == nrow(prueba), !anyNA(prueba_cuotas$AvgH))

# Probabilidad bruta = 1 / cuota. Las tres suman más de 1: el exceso es el margen de la casa.
brutas <- 1 / as.matrix(prueba_cuotas[, c("AvgH", "AvgD", "AvgA")])
margen <- mean(rowSums(brutas) - 1)
# Normalización proporcional: se divide cada probabilidad entre la suma de las tres.
P_mercado <- brutas / rowSums(brutas)

cat(sprintf("Margen promedio de las casas en prueba: %.2f %% (notebook: 5.84 %%)\n", 100 * margen))
cat(sprintf("LogLoss del mercado en prueba: %.6f (notebook: 1.020000)\n", mean(logloss_partido(P_mercado, y))))
cat(sprintf("LogLoss del modelo M0 en prueba: %.6f (notebook: 1.030556)\n\n", mean(logloss_partido(P_m0, y))))

# --- 2. Referencia ingenua ----------------------------------------------------
# Poisson con los goles promedio del entrenamiento, igual para todos los partidos.
ent <- guardado$entrenamiento
m <- outer(dpois(0:15, mean(ent$home_goals)), dpois(0:15, mean(ent$away_goals)))
p_ingenua <- c(sum(m[lower.tri(m)]), sum(diag(m)), sum(m[upper.tri(m)]))
P_ingenua <- matrix(p_ingenua, nrow = length(y), ncol = 3, byrow = TRUE)
ll_ingenua <- mean(logloss_partido(P_ingenua, y))
ll_m0 <- mean(logloss_partido(P_m0, y))
ll_mercado <- mean(logloss_partido(P_mercado, y))
cat(sprintf("LogLoss de la referencia ingenua: %.4f (tablero: 1.0868)\n", ll_ingenua))
cat(sprintf("Parte de la mejora del mercado que logra M0: %.1f %% (tablero: 84 %%)\n\n",
            100 * (ll_ingenua - ll_m0) / (ll_ingenua - ll_mercado)))

# --- 3. Aciertos ----------------------------------------------------------------
cat(sprintf("Aciertos: M0 %.1f %% · mercado %.1f %% · siempre local %.1f %%\n\n",
            100 * mean(max.col(P_m0) == y), 100 * mean(max.col(P_mercado) == y), 100 * mean(y == 1)))

# --- 4. Bootstrap de la diferencia M0 - mercado ---------------------------------
# Remuestrear partidos con reemplazo 10,000 veces y ver cómo varía la diferencia promedio.
# Python (tablero): numpy.random.default_rng(2026).integers(...)
set.seed(2026)
dif <- logloss_partido(P_m0, y) - logloss_partido(P_mercado, y)
medias <- replicate(10000, mean(sample(dif, replace = TRUE)))
ic <- quantile(medias, c(0.025, 0.975))
cat(sprintf("M0 - mercado en prueba: %+.4f · IC 95 %% [%+.4f, %+.4f]\n", mean(dif), ic[1], ic[2]))
cat("(El tablero reporta +0.0106 [-0.0044, +0.0254]; los extremos varían en la cuarta cifra\n",
    " porque R y Python generan números aleatorios distintos, pero la conclusión es la misma:\n",
    " en prueba sola el intervalo incluye el cero.)\n", sep = "")
