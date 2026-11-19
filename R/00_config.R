# ===============================
# CONFIGURAÇÕES GERAIS
# ===============================
# Todos os scripts partem da raiz do repositório
# (abrir o .Rproj ou usar setwd() na pasta do projeto).

# Estação INMET 83737 - Passa Quatro (MG)
lat_est <- -22.382778
lon_est <- -44.966944

# Pastas de dados de entrada
pasta_links    <- "dados/links"
arquivo_links_hist <- file.path(pasta_links, "chelsa_tas_mensal_1979_2019.txt")
arquivo_estacao    <- "dados/estacao/dados_83737_M_1965-12-01_2025-12-31.csv"
shp_area           <- "dados/area_estudo/area_estudo.shp"

# Pasta onde ficam os rasters baixados (não vão para o repositório)
pasta_rasters <- "rasters"

# Pastas de saída
pasta_hist      <- "resultados/historico"
pasta_proj      <- "resultados/projecoes"
pasta_figuras   <- "resultados/figuras"

arquivo_unificado <- file.path(pasta_hist, "PassaQuatro_Temperaturas_Unificadas.xlsx")

# Projeções CMIP6 (CHELSA V2.1)
modelo    <- "IPSL-CM6A-LR"
cenarios  <- c("ssp126", "ssp370", "ssp585")
periodos  <- c("2011_2040", "2041_2070", "2071_2100")

nomes_cenarios <- c(
  ssp126 = "SSP1-2.6",
  ssp370 = "SSP3-7.0",
  ssp585 = "SSP5-8.5"
)

for (p in c(pasta_rasters, pasta_hist, pasta_proj, pasta_figuras)) {
  if (!dir.exists(p)) dir.create(p, recursive = TRUE)
}
