# ===============================
# 02 - ORGANIZAÇÃO DA SÉRIE HISTÓRICA E PAREAMENTO COM A ESTAÇÃO
# ===============================
# 1) junta as 12 planilhas mensais do script 01
# 2) converte o valor bruto do CHELSA para °C: (valor * 0.1) - 273.15
# 3) junta com a temperatura média compensada da estação INMET 83737,
#    mantendo apenas os meses com dado observado (coluna OBSERVADO)
# 4) calcula a média mensal do CHELSA nesses meses (colunas meses / média)

library(openxlsx)
library(dplyr)

source("R/00_config.R")
source("R/funcoes.R")

arquivos_xlsx <- list.files(
  pasta_hist,
  pattern = "^PassaQuatro_Temperatura_Mes_\\d{2}\\.xlsx$",
  full.names = TRUE
)

if (length(arquivos_xlsx) == 0) {
  stop("Nenhum arquivo mensal encontrado. Rode antes o 01_download_historico.R")
}

# ===============================
# LER E AJUSTAR OS DADOS
# ===============================
ler_e_ajustar <- function(arq) {
  df <- read.xlsx(arq)
  names(df) <- tolower(names(df))

  # escala do CHELSA (K x 10) -> °C
  df$temperatura_c <- (df$temperatura_k * 0.10) - 273.15

  df$ano <- as.integer(df$ano)
  df$mes <- as.integer(df$mes)
  df$data <- sprintf("%02d/%d", df$mes, df$ano)

  df[, c("ano", "mes", "data", "temperatura_c")]
}

chelsa <- do.call(rbind, lapply(arquivos_xlsx, ler_e_ajustar))
chelsa <- chelsa[order(chelsa$ano, chelsa$mes), ]

write.xlsx(chelsa,
           file.path(pasta_hist, "PassaQuatro_CHELSA_mensal_1979_2019.xlsx"),
           overwrite = TRUE)

# ===============================
# PAREAMENTO COM A ESTAÇÃO INMET
# ===============================
estacao <- ler_estacao_inmet(arquivo_estacao) %>%
  filter(!is.na(tmed)) %>%
  select(ano, mes, OBSERVADO = tmed)

unificado <- chelsa %>%
  inner_join(estacao, by = c("ano", "mes")) %>%
  arrange(mes, ano)

# média mensal do CHELSA nos meses pareados
medias <- unificado %>%
  group_by(mes) %>%
  summarise(média = mean(temperatura_c), .groups = "drop")

nomes_meses <- c("jan", "fev", "mar", "abr", "mai", "jun",
                 "jul", "ago", "set", "out", "nov", "dez")

unificado$meses <- NA_character_
unificado$média <- NA_real_
unificado$meses[1:12] <- nomes_meses[medias$mes]
unificado$média[1:12] <- medias$média

write.xlsx(unificado, arquivo_unificado, overwrite = TRUE)

cat("Meses pareados:", nrow(unificado), "\n")
cat("Arquivo salvo em:", arquivo_unificado, "\n")
