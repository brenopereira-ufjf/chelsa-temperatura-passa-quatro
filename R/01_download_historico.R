# ===============================
# 01 - SÉRIE HISTÓRICA MENSAL CHELSA V2.1 (tas)
# ===============================
# Baixa cada raster mensal global, extrai o valor do pixel da estação
# e apaga o arquivo em seguida (cada .tif global ocupa bastante espaço).
# Gera uma planilha por mês: PassaQuatro_Temperatura_Mes_XX.xlsx
#
# O valor salvo é o valor bruto do raster (K x 10). A conversão para °C
# é feita no script 02.

library(raster)
library(openxlsx)

source("R/00_config.R")
source("R/funcoes.R")

linhas <- ler_links(arquivo_links_hist)

# Buffer e extensão (recorte pequeno em volta da estação antes de extrair)
buffer <- 0.05
ext_est <- extent(lon_est - buffer, lon_est + buffer,
                  lat_est - buffer, lat_est + buffer)

# ===============================
# BAIXAR, EXTRAIR E APAGAR O ARQUIVO
# ===============================
baixar_e_extrair <- function(url) {
  nome_arquivo <- file.path(pasta_rasters, basename(url))
  ok <- baixar_seguro(url, nome_arquivo, tentativas = 5, timeout = 300)
  if (!ok) return(NA_real_)

  valor <- NA_real_
  try({
    r <- raster(nome_arquivo)
    r_crop <- crop(r, ext_est)
    extr <- raster::extract(r_crop, matrix(c(lon_est, lat_est), ncol = 2))
    if (!is.null(extr) && length(extr) > 0) {
      valor <- extr[1]
    }
  }, silent = TRUE)

  suppressWarnings(file.remove(nome_arquivo))

  if (length(valor) == 0 || is.null(valor)) valor <- NA_real_
  return(valor)
}

# ===============================
# PROCESSAR UM MÊS DE CADA VEZ
# ===============================
meses <- sprintf("%02d", 1:12)

for (mes in meses) {
  cat("\n===== PROCESSANDO MÊS", mes, "=====\n")

  arquivos_mes <- linhas[grepl(paste0("_", mes, "_"), linhas)]
  if (length(arquivos_mes) == 0) {
    cat("Nenhum arquivo encontrado para o mês", mes, "\n")
    next
  }

  anos <- sub(".*_(\\d{4})_.*", "\\1", basename(arquivos_mes))
  resultados <- numeric(length(arquivos_mes))

  for (i in seq_along(arquivos_mes)) {
    cat(sprintf("Baixando %s (%s/%s)...\n", basename(arquivos_mes[i]), mes, anos[i]))
    resultados[i] <- baixar_e_extrair(arquivos_mes[i])
    cat(sprintf("   valor extraído: %.0f\n", resultados[i]))
  }

  df <- data.frame(Ano = anos,
                   Mes = mes,
                   Temperatura_K = resultados)

  nome_xlsx <- file.path(pasta_hist, paste0("PassaQuatro_Temperatura_Mes_", mes, ".xlsx"))
  write.xlsx(df, nome_xlsx, overwrite = TRUE)

  cat("Mês", mes, "salvo em", nome_xlsx, "\n")
}
