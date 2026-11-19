# ===============================
# 03 - DOWNLOAD DAS NORMAIS FUTURAS CHELSA V2.1 / CMIP6
# ===============================
# Modelo IPSL-CM6A-LR, cenários SSP1-2.6, SSP3-7.0 e SSP5-8.5,
# períodos 2011-2040, 2041-2070 e 2071-2100 (12 normais mensais cada).
# Os rasters ficam em rasters/<periodo>/<cenario>/ para os scripts 04 e 05.
#
# São 108 arquivos de ~118 MB. Se o download cair no meio, basta rodar
# de novo: arquivos já baixados e completos são pulados.

source("R/00_config.R")
source("R/funcoes.R")

for (periodo in periodos) {
  for (cenario in cenarios) {

    arquivo_links <- file.path(pasta_links, "projecoes",
                               paste0("chelsa_", periodo, "_", cenario, ".txt"))
    links <- ler_links(arquivo_links)

    pasta_saida <- file.path(pasta_rasters, periodo, cenario)
    if (!dir.exists(pasta_saida)) dir.create(pasta_saida, recursive = TRUE)

    cat("\n=====", periodo, cenario, "=====\n")

    for (url in links) {
      destino <- file.path(pasta_saida, basename(url))

      if (file.exists(destino) && file.size(destino) > 100 * 1024^2) {
        cat("Já existe:", basename(url), "\n")
        next
      }

      cat("Baixando:", basename(url), "\n")
      baixar_seguro(url, destino,
                    tentativas  = 3,
                    tamanho_min = 100 * 1024^2,  # arquivo completo ~118 MB
                    timeout     = 1800,
                    espera      = 10)
    }
  }
}
