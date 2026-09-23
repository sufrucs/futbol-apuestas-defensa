# =============================================================================
# 01_elo.R — El sistema Elo del proyecto, escrito en R
#
# Equivale a wc_predictor.build_elo() (Python). Recorre los 9,450 partidos en orden
# cronológico y actualiza el rating de ambos equipos después de cada uno.
# Al final comprueba que los ratings coinciden con los que imprime Python.
#
# Ejecutar desde la carpeta raíz de este repositorio (06_defensa):
#   Rscript equivalencias_R/01_elo.R
# =============================================================================

library(readr)   # read_csv()   ≈ pandas.read_csv()
library(dplyr)   # arrange()    ≈ DataFrame.sort_values()

# Los datos viven en el repositorio público. Si los dos repositorios están clonados uno al
# lado del otro se leen del disco; si no, se descargan de GitHub (el repositorio es público).
RUTA_LOCAL <- "../06_proyecto/Codigo/proyecto_mod_8"
RUTA_WEB <- "https://raw.githubusercontent.com/pitirringo/futbol-apuestas/main/Codigo/proyecto_mod_8"
ruta <- function(archivo) {
  local <- file.path(RUTA_LOCAL, archivo)
  if (file.exists(local)) local else paste(RUTA_WEB, archivo, sep = "/")
}

ELO_INICIAL <- 1500   # Python: ELO_INIT = 1500
K <- 30               # Python: ELO_K = 30

# Probabilidad "esperada" de que A le gane a B según la diferencia de ratings.
# Python: def expected_score(r_a, r_b): return 1 / (1 + 10 ** ((r_b - r_a) / 400))
esperado <- function(r_a, r_b) 1 / (1 + 10^((r_b - r_a) / 400))

historico <- read_csv(ruta("E0_consolidado.csv"), show_col_types = FALSE) |>
  arrange(Date)   # orden cronológico: indispensable para no usar el futuro

# En Python los ratings se guardan en un diccionario {equipo: rating}.
# En R el equivalente natural es un vector con nombres: elo["Arsenal"].
elo <- numeric(0)

for (i in seq_len(nrow(historico))) {
  local  <- historico$HomeTeam[i]
  visita <- historico$AwayTeam[i]

  # Python: ratings.get(h, elo_init) -> rating actual o 1500 si el equipo es nuevo
  r_local  <- if (local  %in% names(elo)) elo[[local]]  else ELO_INICIAL
  r_visita <- if (visita %in% names(elo)) elo[[visita]] else ELO_INICIAL

  # Resultado real: 1 = gana, 0.5 = empata, 0 = pierde (desde el punto de vista del local)
  s_local <- if (historico$FTHG[i] > historico$FTAG[i]) 1 else
             if (historico$FTHG[i] < historico$FTAG[i]) 0 else 0.5

  # Actualización: rating nuevo = rating previo + K * (resultado real - resultado esperado)
  elo[local]  <- r_local  + K * (s_local       - esperado(r_local,  r_visita))
  elo[visita] <- r_visita + K * ((1 - s_local) - esperado(r_visita, r_local))
}

ranking <- tibble(equipo = names(elo), elo = round(unname(elo), 2)) |> arrange(desc(elo))
cat("Top 10 del Elo al 14-sep-2026 (después del último partido):\n")
print(head(ranking, 10), n = 10)

# Verificación contra Python (ranking que imprime wc_predictor.py al importarse)
python <- c("Arsenal" = 1833.29, "Man City" = 1807.88, "Man United" = 1679.95,
            "Bournemouth" = 1659.96, "Liverpool" = 1656.03)
diferencias <- abs(round(elo[names(python)], 2) - python)
stopifnot(all(diferencias < 0.006))
cat("\nOK: los ratings de R coinciden con los de Python a 2 decimales.\n")

# Ejemplo numérico para estudiar: Arsenal (1833) recibe a Man City (1808)
cat(sprintf("\nProbabilidad esperada de Arsenal vs Man City según Elo: %.3f\n",
            esperado(elo[["Arsenal"]], elo[["Man City"]])))
