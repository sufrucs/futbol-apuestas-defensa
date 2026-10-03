# =============================================================================
# 02_modelo_poisson.R — Los modelos M0 y M4 del proyecto, escritos en R
#
# Equivale a Analisis.ipynb, secciones 4 a 7 y 9 (Python + statsmodels):
#   - partición temporal entrenamiento / validación / prueba (al final de la §5)
#   - dos regresiones de Poisson (goles del local y goles del visitante)
#   - probabilidades 1X2 a partir de los goles esperados
#   - LogLoss, MAE, dispersión de Pearson y VIF
# Comprueba que R obtiene exactamente los mismos coeficientes y métricas que Python.
#
# Ejecutar desde la carpeta raíz de este repositorio (06_defensa):
#   Rscript equivalencias_R/02_modelo_poisson.R
# =============================================================================

library(readr)
library(dplyr)

RUTA_LOCAL <- "../06_proyecto/Codigo/proyecto_mod_8"
RUTA_WEB <- "https://raw.githubusercontent.com/pitirringo/futbol-apuestas/main/Codigo/proyecto_mod_8"
ruta <- function(archivo) {
  local <- file.path(RUTA_LOCAL, archivo)
  if (file.exists(local)) local else paste(RUTA_WEB, archivo, sep = "/")
}

# --- 1. Datos y partición temporal (notebook, final de §5) --------------------
# premier_training_data.csv: una fila por partido con las variables PREVIAS al partido
# (Elo, goles promedio de la temporada, forma, tiros) y los goles que realmente ocurrieron.
# Python la construyó con los valores calibrados en la §5: K = 15 (Elo) y k = 0 (shrinkage).
variables <- read_csv(ruta("premier_training_data.csv"), show_col_types = FALSE)

entrenamiento <- variables |> filter(Date <  as.Date("2024-08-01"))
validacion    <- variables |> filter(Date >= as.Date("2024-08-01"), Date < as.Date("2025-08-01"))
prueba        <- variables |> filter(Date >= as.Date("2025-08-01"))
cat(sprintf("Entrenamiento %d · validación %d · prueba %d partidos\n\n",
            nrow(entrenamiento), nrow(validacion), nrow(prueba)))

# --- 2. Regresiones de Poisson (notebook §4 y §6) ----------------------------
# Python (statsmodels):
#   X = sm.add_constant(datos[columnas]); X["elo_diff"] = X["elo_diff"] / 400
#   sm.GLM(datos["home_goals"], X, family=sm.families.Poisson()).fit()
# R: glm() agrega el intercepto solo; I(elo_diff / 400) aplica la misma escala.
m0_local <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away,
                family = poisson(link = "log"), data = entrenamiento)
m0_visita <- glm(away_goals ~ I(elo_diff / 400) + gf_away + ga_home,
                 family = poisson(link = "log"), data = entrenamiento)

cat("Coeficientes M0, goles del local:\n");     print(round(coef(m0_local), 4))
cat("Coeficientes M0, goles del visitante:\n"); print(round(coef(m0_visita), 4))
stopifnot(all(abs(coef(m0_local)  - c(0.0433, 0.6283, 0.1678, 0.0778)) < 5e-5))
stopifnot(all(abs(coef(m0_visita) - c(0.0264, -0.6854, 0.1079, 0.0281)) < 5e-5))
cat("OK: mismos coeficientes que statsmodels.\n\n")

# Tabla completa como la de statsmodels (coef, error estándar, z, p-valor):
print(summary(m0_local)$coefficients)

# Dispersión de Pearson: suma de residuos de Pearson al cuadrado / grados de libertad.
# Si ≈ 1, la varianza condicional es ≈ la media, como supone Poisson.
dispersion <- function(m) sum(residuals(m, type = "pearson")^2) / df.residual(m)
cat(sprintf("\nDispersión de Pearson: local %.3f · visitante %.3f\n\n",
            dispersion(m0_local), dispersion(m0_visita)))

# M4: las 9 variables por ecuación
m4_local <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away + form_gf_home + form_ga_away +
                  shots_for_home + shots_against_away + sot_for_home + sot_against_away,
                family = poisson, data = entrenamiento)
m4_visita <- glm(away_goals ~ I(elo_diff / 400) + gf_away + ga_home + form_gf_away + form_ga_home +
                   shots_for_away + shots_against_home + sot_for_away + sot_against_home,
                 family = poisson, data = entrenamiento)

# --- 3. VIF (notebook §7) ----------------------------------------------------
# Python usa statsmodels.variance_inflation_factor sobre la matriz X: para cada variable j,
# regresión lineal de X_j contra las demás y VIF = 1 / (1 - R²). Aquí, lo mismo con lm().
vif_manual <- function(datos, columnas) {
  X <- datos[, columnas]
  X$elo_diff <- X$elo_diff / 400
  sapply(columnas, function(j) {
    r2 <- summary(lm(reformulate(setdiff(columnas, j), response = j), data = X))$r.squared
    1 / (1 - r2)
  })
}
cols_m4_local <- c("elo_diff", "gf_home", "ga_away", "form_gf_home", "form_ga_away",
                   "shots_for_home", "shots_against_away", "sot_for_home", "sot_against_away")
cat("VIF de M4 (ecuación del local), igual que en el notebook:\n")
vif_m4 <- vif_manual(entrenamiento, cols_m4_local)
print(round(sort(vif_m4, decreasing = TRUE), 3))
# Python (tablero): dispersión 0.996399 / 1.036394; VIF máximo 5.560371 (sot_for_home)
stopifnot(abs(dispersion(m0_local) - 0.996399) < 1e-6, abs(dispersion(m0_visita) - 1.036394) < 1e-6,
          abs(max(vif_m4) - 5.560371) < 1e-6)
cat("OK: misma dispersión y mismo VIF que Python.\n")
# Nota: car::vif(m4_local) da otra versión (ponderada por el GLM), con valores parecidos
# pero no idénticos; el notebook usa la versión sin ponderar, que es la que reproduce vif_manual.

# --- 4. De goles esperados a probabilidades 1X2 (notebook §4) ----------------
# Python: scipy.stats.skellam.sf(0, λl, λv), .pmf(0, ...), .cdf(-1, ...).
# R base no trae Skellam, pero es lo mismo sumar la matriz de marcadores:
#   P(local = i, visita = j) = dpois(i, λl) * dpois(j, λv)   (independencia)
#   gana local = celdas con i > j; empate = diagonal; gana visita = celdas con i < j
prob_1x2 <- function(lambda_local, lambda_visita, max_goles = 15) {
  t(mapply(function(ll, lv) {
    m <- outer(dpois(0:max_goles, ll), dpois(0:max_goles, lv))
    c(local = sum(m[lower.tri(m)]), empate = sum(diag(m)), visita = sum(m[upper.tri(m)]))
  }, lambda_local, lambda_visita))
}

# Resultado observado: 1 = local, 2 = empate, 3 = visita (columna de la matriz P)
resultado <- function(d) ifelse(d$home_goals > d$away_goals, 1L,
                                ifelse(d$home_goals == d$away_goals, 2L, 3L))

# LogLoss = -promedio de log(probabilidad asignada a lo que ocurrió)
# Python: sklearn.metrics.log_loss(y, P)
logloss <- function(P, y) -mean(log(P[cbind(seq_along(y), y)]))

evaluar <- function(m_local, m_visita, datos) {
  ll <- predict(m_local,  newdata = datos, type = "response")   # λ del local
  lv <- predict(m_visita, newdata = datos, type = "response")   # λ del visitante
  P <- prob_1x2(ll, lv)
  y <- resultado(datos)
  c(LogLoss = logloss(P, y),
    MAE = (mean(abs(datos$home_goals - ll)) + mean(abs(datos$away_goals - lv))) / 2,
    Aciertos = mean(max.col(P) == y))
}

tabla <- rbind(
  "M0 validación" = evaluar(m0_local, m0_visita, validacion),
  "M4 validación" = evaluar(m4_local, m4_visita, validacion),
  "M0 prueba"     = evaluar(m0_local, m0_visita, prueba),
  "M4 prueba"     = evaluar(m4_local, m4_visita, prueba)
)
cat("\nMétricas (comparar con el notebook: 0.989547, 0.978612, 1.033076, 1.036739):\n")
print(round(tabla, 6))
stopifnot(abs(tabla["M0 validación", "LogLoss"] - 0.989547) < 1e-6,
          abs(tabla["M4 validación", "LogLoss"] - 0.978612) < 1e-6,
          abs(tabla["M0 prueba", "LogLoss"] - 1.033076) < 1e-6,
          abs(tabla["M4 prueba", "LogLoss"] - 1.036739) < 1e-6)
cat("OK: mismos LogLoss que Python.\n")

# Guarda las probabilidades de prueba para 03_mercado.R
saveRDS(list(P_m0 = prob_1x2(predict(m0_local, prueba, type = "response"),
                             predict(m0_visita, prueba, type = "response")),
             prueba = prueba, entrenamiento = entrenamiento),
        file = "equivalencias_R/probabilidades_prueba.rds")
