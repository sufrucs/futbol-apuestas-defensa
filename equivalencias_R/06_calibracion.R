# =============================================================================
# 06_calibracion.R — Calibración de K (Elo) y k (shrinkage), escrita en R
#
# Equivale a Analisis.ipynb §5 (construir_base_historica + calibrar_hiperparametros).
# Para cada una de las 35 combinaciones de la rejilla K ∈ {15, …, 45} × k ∈ {0, …, 20}:
#   1. reconstruye las variables de M0: Elo previo al partido y goles a favor y en contra
#      de la temporada (con shrinkage k);
#   2. valida con ventana creciente en 2021/22, 2022/23 y 2023/24: entrena M0 con todos los
#      partidos anteriores a cada temporada y mide el LogLoss en esa temporada;
#   3. promedia los tres LogLoss, ponderados por el número de partidos.
# Al final comprueba que las 35 cifras coinciden con las de Python y que gana K = 15, k = 0.
#
# Ejecutar desde la carpeta raíz de este repositorio (06_defensa); tarda unos 10 segundos:
#   Rscript equivalencias_R/06_calibracion.R
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)
options(width = 120)   # para que la tabla de la rejilla se imprima en una línea por combinación

RUTA_LOCAL <- "../06_proyecto/Codigo/proyecto_mod_8"
RUTA_WEB <- "https://raw.githubusercontent.com/pitirringo/futbol-apuestas/main/Codigo/proyecto_mod_8"
ruta <- function(archivo) {
  local <- file.path(RUTA_LOCAL, archivo)
  if (file.exists(local)) local else paste(RUTA_WEB, archivo, sep = "/")
}

# Configuración de la §1 del notebook
FECHA_INICIO <- as.Date("2019-08-01")                  # Python: FECHA_INICIO
FOLDS <- list(c("2021-08-01", "2022-08-01"),           # Python: FOLDS_HIPERPARAMETROS
              c("2022-08-01", "2023-08-01"),
              c("2023-08-01", "2024-08-01"))
K_CANDIDATOS <- c(15, 20, 25, 30, 35, 40, 45)          # Python: K_ELO_CANDIDATOS (rejilla completa)
k_CANDIDATOS <- c(0, 5, 10, 15, 20)                    # Python: K_SHRINKAGE_CANDIDATOS

historico <- read_csv(ruta("E0_consolidado.csv"), show_col_types = FALSE) |>
  arrange(Date) |>
  mutate(id = row_number(),
         # La temporada va del 1 de agosto al 31 de julio (igual que season_stats en Python)
         temporada = ifelse(as.integer(format(Date, "%m")) >= 8,
                            as.integer(format(Date, "%Y")), as.integer(format(Date, "%Y")) - 1))

# --- 1. Elo previo a cada partido -------------------------------------------------
# Python (construir_base_historica): las variables de un día usan los ratings de antes de ese día
# y después se actualizan con update_elo(). Como un equipo juega a lo más un partido por día,
# recorrer los partidos en orden y guardar el rating ANTES de actualizarlo da lo mismo.
# Los equipos se numeran (1, 2, …) para que el bucle sea rápido: el rating vive en un vector.
equipos <- sort(unique(c(historico$HomeTeam, historico$AwayTeam)))
idx_local <- match(historico$HomeTeam, equipos)
idx_visita <- match(historico$AwayTeam, equipos)
s_local <- ifelse(historico$FTHG > historico$FTAG, 1, ifelse(historico$FTHG < historico$FTAG, 0, 0.5))

elo_previo <- function(K, inicial = 1500, escala = 400) {
  rating <- rep(inicial, length(equipos))      # Python: ratings.get(equipo, ELO_INIT)
  pre_l <- pre_v <- numeric(nrow(historico))
  for (i in seq_len(nrow(historico))) {
    rl <- rating[idx_local[i]]; rv <- rating[idx_visita[i]]
    pre_l[i] <- rl; pre_v[i] <- rv
    e <- 1 / (1 + 10^((rv - rl) / escala))      # Python: expected_score(rh, ra, scale)
    rating[idx_local[i]]  <- rl + K * (s_local[i] - e)          # update_elo(rh, ra, sh)
    rating[idx_visita[i]] <- rv + K * ((1 - s_local[i]) - (1 - e))  # update_elo(ra, rh, 1 - sh)
  }
  tibble(id = historico$id, elo_home = pre_l, elo_away = pre_v)
}

# --- 2. Goles de la temporada para cada equipo y partido (Python: season_stats) ---
# Tabla larga: una fila por equipo y partido. Dentro de cada equipo y temporada, en orden
# cronológico, n = partidos ya jugados ANTES de éste y sus promedios (sumas acumuladas).
largo <- bind_rows(
  historico |> transmute(id, Date, temporada, lado = "home", equipo = HomeTeam, gf = FTHG, ga = FTAG),
  historico |> transmute(id, Date, temporada, lado = "away", equipo = AwayTeam, gf = FTAG, ga = FTHG)) |>
  arrange(equipo, Date) |>
  group_by(equipo, temporada) |>
  mutate(n = row_number() - 1,
         gf_actual = (cumsum(gf) - gf) / n,     # NaN cuando n = 0; ese caso usa la referencia previa
         ga_actual = (cumsum(ga) - ga) / n) |>
  ungroup()

# Referencia previa: promedio del equipo en la temporada anterior; si no jugó en Premier,
# promedio de goles por equipo y partido de toda la liga en esa temporada.
previa_equipo <- largo |>
  group_by(equipo, temporada) |>
  summarise(gf_prev = mean(gf), ga_prev = mean(ga), .groups = "drop") |>
  mutate(temporada = temporada + 1)
previa_liga <- historico |>
  group_by(temporada) |>
  summarise(media_liga = (sum(FTHG) + sum(FTAG)) / (2 * n()), .groups = "drop") |>
  mutate(temporada = temporada + 1)
largo <- largo |>
  left_join(previa_equipo, by = c("equipo", "temporada")) |>
  left_join(previa_liga, by = "temporada") |>
  mutate(gf_prev = coalesce(gf_prev, media_liga), ga_prev = coalesce(ga_prev, media_liga))

# Para un k dado: peso n/(n+k) a la temporada actual y el resto a la referencia previa.
# Con n = 0 se usa sólo la referencia previa; con k = 0 y n >= 1, sólo la temporada actual.
variables_m0 <- function(elo, k) {
  g <- largo |>
    mutate(w = ifelse(n == 0, 0, n / (n + k)),
           gf_k = ifelse(n == 0, gf_prev, w * gf_actual + (1 - w) * gf_prev),
           ga_k = ifelse(n == 0, ga_prev, w * ga_actual + (1 - w) * ga_prev)) |>
    select(id, lado, gf_k, ga_k) |>
    pivot_wider(names_from = lado, values_from = c(gf_k, ga_k))
  historico |>
    filter(Date >= FECHA_INICIO) |>                      # Python: desde=FECHA_INICIO
    select(id, Date, home_goals = FTHG, away_goals = FTAG) |>
    left_join(elo, by = "id") |>
    left_join(g, by = "id") |>
    transmute(Date, home_goals, away_goals, elo_diff = elo_home - elo_away,
              gf_home = gf_k_home, ga_home = ga_k_home, gf_away = gf_k_away, ga_away = ga_k_away)
}

# --- 3. M0 y LogLoss en un pliegue (Python: entrenar_modelo, predecir_con_modelo) ---
prob_1x2 <- function(lambda_local, lambda_visita, max_goles = 25) {
  t(mapply(function(ll, lv) {
    m <- outer(dpois(0:max_goles, ll), dpois(0:max_goles, lv))
    c(sum(m[lower.tri(m)]), sum(diag(m)), sum(m[upper.tri(m)]))
  }, lambda_local, lambda_visita))
}
logloss_pliegue <- function(datos, inicio, fin) {
  entrena <- datos |> filter(Date < as.Date(inicio))                       # todo lo anterior
  valida <- datos |> filter(Date >= as.Date(inicio), Date < as.Date(fin))  # la temporada siguiente
  m_local <- glm(home_goals ~ I(elo_diff / 400) + gf_home + ga_away, family = poisson, data = entrena)
  m_visita <- glm(away_goals ~ I(elo_diff / 400) + gf_away + ga_home, family = poisson, data = entrena)
  P <- prob_1x2(predict(m_local, valida, type = "response"), predict(m_visita, valida, type = "response"))
  y <- ifelse(valida$home_goals > valida$away_goals, 1L, ifelse(valida$home_goals == valida$away_goals, 2L, 3L))
  c(logloss = -mean(log(P[cbind(seq_along(y), y)])), partidos = nrow(valida))
}

# --- 4. La rejilla (Python: calibrar_hiperparametros con itertools.product) -------
inicio <- Sys.time()
filas <- list()
for (K in K_CANDIDATOS) {
  elo <- elo_previo(K)
  for (k in k_CANDIDATOS) {
    datos <- variables_m0(elo, k)
    r <- sapply(FOLDS, function(f) logloss_pliegue(datos, f[1], f[2]))
    filas[[length(filas) + 1]] <- tibble(
      K_Elo = K, k_shrinkage = k,
      LogLoss_promedio = weighted.mean(r["logloss", ], r["partidos", ]),  # Python: np.average(weights=)
      LogLoss_2021_22 = r["logloss", 1], LogLoss_2022_23 = r["logloss", 2], LogLoss_2023_24 = r["logloss", 3],
      Partidos = sum(r["partidos", ]))
  }
}
rejilla <- bind_rows(filas) |> arrange(LogLoss_promedio)
cat(sprintf("Rejilla calculada en %.0f s (%d partidos en la base, %d por combinación en los pliegues)\n\n",
            as.numeric(difftime(Sys.time(), inicio, units = "secs")), nrow(datos), rejilla$Partidos[1]))
print(as.data.frame(rejilla |> mutate(across(starts_with("LogLoss"), \(x) round(x, 6)))), row.names = FALSE)

# --- 5. Verificación contra Python (salida de la §5 con la rejilla completa) -------
python <- tribble(
  ~K_Elo, ~k_shrinkage, ~LL,
  15, 0, 0.959558,  20, 0, 0.959589,  25, 0, 0.960162,  15, 5, 0.960369,  20, 5, 0.960464,
  25, 5, 0.960956,  30, 0, 0.961021,  20, 10, 0.961203, 15, 10, 0.961220, 25, 10, 0.961593,
  30, 5, 0.961648,  20, 15, 0.961961, 35, 0, 0.962039,  15, 15, 0.962085, 30, 10, 0.962178,
  25, 15, 0.962279, 35, 5, 0.962428,  20, 20, 0.962578, 15, 20, 0.962794, 30, 15, 0.962804,
  35, 10, 0.962840, 25, 20, 0.962845, 40, 0, 0.963143,  40, 5, 0.963232,  30, 20, 0.963336,
  35, 15, 0.963408, 40, 10, 0.963514, 35, 20, 0.963912, 45, 5, 0.964021,  40, 15, 0.964024,
  45, 10, 0.964165, 45, 0, 0.964290,  40, 20, 0.964506, 45, 15, 0.964620, 45, 20, 0.965084)
comparacion <- rejilla |> inner_join(python, by = c("K_Elo", "k_shrinkage"))
mejor <- rejilla[1, ]
anterior <- rejilla |> filter(K_Elo == 30, k_shrinkage == 10)
stopifnot(nrow(comparacion) == 35,
          all(abs(comparacion$LogLoss_promedio - comparacion$LL) < 1e-6),
          mejor$K_Elo == 15, mejor$k_shrinkage == 0,
          abs(mejor$LogLoss_2021_22 - 0.960230) < 1e-6, abs(mejor$LogLoss_2022_23 - 0.989315) < 1e-6,
          abs(mejor$LogLoss_2023_24 - 0.929130) < 1e-6)
cat("\nOK: las 35 combinaciones coinciden con Python (6 decimales) y gana K = 15, k = 0.\n")
cat(sprintf("Configuración anterior (K = 30, k = 10): %.6f, %.6f peor que la elegida.\n",
            anterior$LogLoss_promedio, anterior$LogLoss_promedio - mejor$LogLoss_promedio))
