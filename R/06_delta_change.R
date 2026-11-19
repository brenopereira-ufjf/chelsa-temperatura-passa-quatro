# ===============================
# 06 - DELTA CHANGE MENSAL
# ===============================
# delta(mês) = normal futura CHELSA no ponto (script 04)
#              - média mensal observada na estação (coluna OBSERVADO)
#
# O delta de cada mês é somado aos valores observados da série histórica
# pareada e a série resultante é organizada em 30 anos x 12 meses para
# cada período futuro.
# Saída: resultados/projecoes/<periodo>/<cenario>/<cenario>_delta_change_mensal_<periodo>.xlsx

library(readxl)
library(dplyr)
library(writexl)

source("R/00_config.R")

hist <- read_xlsx(arquivo_unificado)

norm_hist <- hist %>%
  group_by(mes) %>%
  summarise(
    hist_med = mean(OBSERVADO, na.rm = TRUE),
    .groups = "drop"
  )

delta_change_cenario <- function(periodo, cenario) {

  pasta_saida <- file.path(pasta_proj, periodo, cenario)
  arquivo_norm_fut <- file.path(
    pasta_saida,
    paste0("valores_passa_quatro_", periodo, "_", cenario, ".xlsx")
  )

  ano_inicio <- as.integer(substr(periodo, 1, 4))
  ano_fim    <- as.integer(substr(periodo, 6, 9))

  # normais futuras
  norm_fut <- read_xlsx(arquivo_norm_fut) %>%
    select(mes, fut_med = valor)

  # delta mensal
  delta_m <- norm_hist %>%
    left_join(norm_fut, by = "mes") %>%
    mutate(delta = fut_med - hist_med)

  # aplicar delta aos dados históricos
  serie_sint <- hist %>%
    left_join(delta_m %>% select(mes, delta), by = "mes") %>%
    mutate(tas_sint = OBSERVADO + delta) %>%
    arrange(ano, mes)

  # construir série de 30 anos
  serie_futura <- serie_sint %>%
    slice(rep(1:n(), length.out = 30 * 12)) %>%
    mutate(ano = rep(ano_inicio:ano_fim, each = 12)) %>%
    select(ano, mes, tas_sint)

  write_xlsx(
    serie_futura,
    file.path(pasta_saida,
              paste0(cenario, "_delta_change_mensal_", periodo, ".xlsx"))
  )

  invisible(delta_m)
}

for (periodo in periodos) {
  for (cenario in cenarios) {
    cat("Delta change:", periodo, cenario, "\n")
    delta_change_cenario(periodo, cenario)
  }
}
