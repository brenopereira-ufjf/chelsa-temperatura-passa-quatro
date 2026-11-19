# ===============================
# 05 - RECORTE DOS RASTERS PELA ÁREA DE ESTUDO
# ===============================
# Recorta (crop + mask) as normais futuras pelo polígono da área de estudo
# e gera um raster com a média dos 12 meses (média anual) para cada
# período/cenário. Usado na elaboração dos mapas.
# Saída: rasters/<periodo>/<cenario>/recortado/

library(raster)
library(sf)

source("R/00_config.R")

area_estudo <- st_read(shp_area, quiet = TRUE)
area_sp <- as(area_estudo, "Spatial")

recortar_periodo <- function(periodo, cenario) {

  pasta_entrada <- file.path(pasta_rasters, periodo, cenario)
  pasta_saida   <- file.path(pasta_entrada, "recortado")
  if (!dir.exists(pasta_saida)) dir.create(pasta_saida, recursive = TRUE)

  rasters <- list.files(pasta_entrada, pattern = "\\.tif$", full.names = TRUE)

  # ==========================
  # 1) RECORTE
  # ==========================
  for (r in rasters) {

    cat("Recortando:", basename(r), "\n")

    rast <- raster(r)

    # garantir CRS compatível (shapefile está em SIRGAS 2000 / UTM 23S)
    if (!compareCRS(rast, area_sp)) {
      area_proj <- spTransform(area_sp, crs(rast))
    } else {
      area_proj <- area_sp
    }

    rast_crop <- crop(rast, area_proj)
    rast_mask <- mask(rast_crop, area_proj)

    writeRaster(
      rast_mask,
      filename  = file.path(pasta_saida, basename(r)),
      format    = "GTiff",
      overwrite = TRUE
    )
  }

  # ==========================
  # 2) MÉDIA DOS RASTERS RECORTADOS
  # ==========================
  rasters_recortados <- list.files(
    pasta_saida,
    pattern = "_norm\\.tif$",
    full.names = TRUE
  )

  stack_rasters <- stack(rasters_recortados)
  media_raster <- calc(stack_rasters, fun = mean, na.rm = TRUE)

  writeRaster(
    media_raster,
    filename  = file.path(pasta_saida, paste0(cenario, "_media_", periodo, ".tif")),
    format    = "GTiff",
    overwrite = TRUE
  )
}

for (periodo in periodos) {
  for (cenario in cenarios) {
    cat("\n=====", periodo, cenario, "=====\n")
    recortar_periodo(periodo, cenario)
  }
}
