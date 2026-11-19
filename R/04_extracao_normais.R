# ===============================
# 04 - EXTRAÇÃO DAS NORMAIS FUTURAS NO PONTO DA ESTAÇÃO
# ===============================
# Para cada período e cenário, lê as 12 normais mensais e extrai o valor
# do pixel que contém a estação. Saída:
# resultados/projecoes/<periodo>/<cenario>/valores_passa_quatro_<periodo>_<cenario>.xlsx
#
# Obs.: diferente dos mensais históricos, nas normais o pacote raster já
# aplica escala e offset do arquivo, então o valor sai direto em °C.

library(raster)
library(stringr)
library(dplyr)
library(writexl)

source("R/00_config.R")

ponto <- matrix(c(lon_est, lat_est), ncol = 2)

extrair_periodo <- function(periodo, cenario) {

  pasta_tifs <- file.path(pasta_rasters, periodo, cenario)
  ano_inicio <- as.integer(substr(periodo, 1, 4))

  arquivos_tif <- list.files(pasta_tifs, pattern = "\\.tif$", full.names = TRUE)

  if (length(arquivos_tif) == 0) {
    warning("Nenhum .tif em ", pasta_tifs)
    return(invisible(NULL))
  }

  resultado <- lapply(arquivos_tif, function(arq) {

    r <- stack(arq)
    valores <- raster::extract(r, ponto)

    nome <- basename(arq)

    variavel <- str_extract(nome, "_(tas|pr|tasmax|tasmin)_")
    variavel <- gsub("_", "", variavel)

    mes <- str_extract(nome, "_[0-9]{2}_")
    mes <- gsub("_", "", mes)

    data.frame(
      arquivo  = nome,
      variavel = variavel,
      ano      = ano_inicio,
      mes      = as.integer(mes),
      lon      = lon_est,
      lat      = lat_est,
      valor    = as.numeric(valores)
    )
  })

  df_final <- bind_rows(resultado) %>% arrange(mes)

  pasta_saida <- file.path(pasta_proj, periodo, cenario)
  if (!dir.exists(pasta_saida)) dir.create(pasta_saida, recursive = TRUE)

  saida_xlsx <- file.path(pasta_saida,
                          paste0("valores_passa_quatro_", periodo, "_", cenario, ".xlsx"))
  write_xlsx(df_final, saida_xlsx)

  cat("Salvo:", saida_xlsx, "\n")
  invisible(df_final)
}

for (periodo in periodos) {
  for (cenario in cenarios) {
    extrair_periodo(periodo, cenario)
  }
}
