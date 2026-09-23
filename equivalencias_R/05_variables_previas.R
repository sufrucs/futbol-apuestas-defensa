# =============================================================================
# 05_variables_previas.R — Promedios ajustados (shrinkage) y forma reciente, en R
#
# Equivale a wc_predictor.season_stats() y wc_predictor.recent_form() (Python).
# Calcula las variables del primer partido de la base de modelación (Liverpool vs Norwich,
# 9 de agosto de 2019) y las compara con premier_training_data.csv.
#
#   Rscript equivalencias_R/05_variables_previas.R
# =============================================================================

library(readr)
library(dplyr)

RUTA_LOCAL <- "../06_proyecto/Codigo/proyecto_mod_8"
RUTA_WEB <- "https://raw.githubusercontent.com/pitirringo/futbol-apuestas/main/Codigo/proyecto_mod_8"
ruta <- function(archivo) {
  local <- file.path(RUTA_LOCAL, archivo)
  if (file.exists(local)) local else paste(RUTA_WEB, archivo, sep = "/")
}

historico <- read_csv(ruta("E0_consolidado.csv"), show_col_types = FALSE) |> arrange(Date)

# --- Goles a favor y en contra desde el punto de vista de un equipo -------------
# Python: np.where(matches["home_team"] == team, matches["home_score"], matches["away_score"])
desde_equipo <- function(partidos, equipo) {
  es_local <- partidos$HomeTeam == equipo
  tibble(gf = ifelse(es_local, partidos$FTHG, partidos$FTAG),
         ga = ifelse(es_local, partidos$FTAG, partidos$FTHG),
         tiros_f = ifelse(es_local, partidos$HS, partidos$AS),
         tiros_c = ifelse(es_local, partidos$AS, partidos$HS),
         puerta_f = ifelse(es_local, partidos$HST, partidos$AST),
         puerta_c = ifelse(es_local, partidos$AST, partidos$HST))
}

# --- season_stats(): promedio de la temporada actual contraído hacia la anterior --
promedios_ajustados <- function(historico, equipo, fecha, k = 10) {
  previo <- historico |> filter(Date < fecha)                     # sólo el pasado
  anio <- if (as.integer(format(fecha, "%m")) >= 8) as.integer(format(fecha, "%Y")) else
          as.integer(format(fecha, "%Y")) - 1                      # la temporada empieza el 1 de agosto
  inicio <- as.Date(sprintf("%d-08-01", anio))
  inicio_anterior <- as.Date(sprintf("%d-08-01", anio - 1))

  juega <- function(d) d$HomeTeam == equipo | d$AwayTeam == equipo
  actual <- previo |> filter(Date >= inicio) |> filter(juega(pick(everything())))
  liga_anterior <- previo |> filter(Date >= inicio_anterior, Date < inicio)
  anterior <- liga_anterior |> filter(juega(pick(everything())))

  if (nrow(anterior) == 0) {
    # Equipo que no jugó la temporada anterior en Premier: promedio de goles de la liga
    media_liga <- (sum(liga_anterior$FTHG) + sum(liga_anterior$FTAG)) / (2 * nrow(liga_anterior))
    gf_previo <- media_liga; ga_previo <- media_liga
  } else {
    s <- desde_equipo(anterior, equipo); gf_previo <- mean(s$gf); ga_previo <- mean(s$ga)
  }
  n <- nrow(actual)
  if (n == 0) return(c(gf = gf_previo, ga = ga_previo))
  s <- desde_equipo(actual, equipo)
  peso <- n / (n + k)                                               # peso de la temporada actual
  c(gf = peso * mean(s$gf) + (1 - peso) * gf_previo,
    ga = peso * mean(s$ga) + (1 - peso) * ga_previo)
}

# --- recent_form(): promedio ponderado de los últimos 10 partidos -----------------
forma_reciente <- function(historico, equipo, fecha, n = 10, decaimiento = 0.85) {
  ultimos <- historico |> filter(Date < fecha, HomeTeam == equipo | AwayTeam == equipo) |>
    arrange(Date) |> tail(n)                                        # del más antiguo al más reciente
  m <- nrow(ultimos)
  pesos <- decaimiento^((m - 1):0)                                  # el más reciente pesa 0.85^0 = 1
  pesos <- pesos / sum(pesos)                                       # normalizados: suman 1
  s <- desde_equipo(ultimos, equipo)
  sapply(s, function(x) sum(pesos * x))                             # ≈ np.average(x, weights=w)
}

fecha <- as.Date("2019-08-09")
cat("Liverpool (local):\n");  print(round(promedios_ajustados(historico, "Liverpool", fecha), 4))
print(round(forma_reciente(historico, "Liverpool", fecha), 4))
cat("Norwich (visitante, recién ascendido):\n"); print(round(promedios_ajustados(historico, "Norwich", fecha), 4))
print(round(forma_reciente(historico, "Norwich", fecha), 4))

# Comparación contra la caché que generó Python
cache <- read_csv(ruta("premier_training_data.csv"), show_col_types = FALSE)[1, ]
r <- c(promedios_ajustados(historico, "Liverpool", fecha)["gf"],
       forma_reciente(historico, "Liverpool", fecha)[c("gf", "tiros_f")],
       forma_reciente(historico, "Norwich", fecha)["ga"])
p <- c(cache$gf_home, cache$form_gf_home, cache$shots_for_home, cache$form_ga_away)
stopifnot(all(abs(r - p) < 1e-9))
cat("\nOK: mismas variables que la caché de Python.\n")
