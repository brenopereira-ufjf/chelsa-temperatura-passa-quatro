# ===============================
# FUNÇÕES AUXILIARES
# ===============================

# Download com novas tentativas.
# tamanho_min evita aceitar arquivo corrompido/incompleto
# (os mensais históricos são pequenos; as normais futuras têm ~118 MB).
baixar_seguro <- function(url, destino, tentativas = 5, tamanho_min = 5000,
                          timeout = 1800, espera = 2) {

  url <- trimws(url)

  for (i in 1:tentativas) {

    # apagar arquivo parcial antes de tentar de novo
    if (file.exists(destino)) file.remove(destino)

    try({
      utils::download.file(
        url      = url,
        destfile = destino,
        mode     = "wb",
        method   = "libcurl",
        timeout  = timeout,
        quiet    = TRUE
      )
    }, silent = TRUE)

    if (file.exists(destino) && file.size(destino) > tamanho_min) {
      return(TRUE)
    }

    cat(sprintf("Tentativa %d falhou para %s - tentando novamente...\n",
                i, basename(url)))
    Sys.sleep(espera)
  }

  cat("Falha final em:", basename(url), "\n")
  return(FALSE)
}

# Lê lista de links (uma URL por linha), ignorando linhas vazias
ler_links <- function(arquivo) {
  links <- trimws(readLines(arquivo, encoding = "UTF-8"))
  links[links != ""]
}

# Lê o CSV mensal exportado do BDMEP/INMET
ler_estacao_inmet <- function(arquivo) {
  est <- read.csv2(arquivo, skip = 10, na.strings = "null",
                   check.names = FALSE)
  est <- est[, 1:4]
  names(est) <- c("data_medicao", "tmax", "tmed", "tmin")
  est$ano <- as.integer(substr(est$data_medicao, 1, 4))
  est$mes <- as.integer(substr(est$data_medicao, 6, 7))
  est
}
