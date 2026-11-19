# Temperatura do ar em Passa Quatro (MG) a partir do CHELSA V2.1

Scripts em R usados para coletar e tratar os dados de temperatura média do ar (`tas`) do CHELSA V2.1 para o município de Passa Quatro (MG), tanto para a série histórica quanto para as projeções do CMIP6, e para gerar as séries futuras pelo método *delta change* tendo como base a estação meteorológica do INMET de Passa Quatro (código 83737).

## Dados utilizados

| Dado | Fonte | Detalhes |
|---|---|---|
| Temperatura média mensal 1979–2019 | CHELSA V2.1 (*monthly*) | ~1 km, valores em K × 10 |
| Normais mensais futuras | CHELSA V2.1 / CMIP6 (*climatologies*) | modelo IPSL-CM6A-LR; SSP1-2.6, SSP3-7.0 e SSP5-8.5; 2011–2040, 2041–2070 e 2071–2100 |
| Temperatura média compensada mensal | INMET / BDMEP, estação 83737 | lat −22,382778; lon −44,966944; alt. 919,55 m |
| Limite da área de estudo | shapefile próprio | SIRGAS 2000 / UTM 23S |

Os rasters do CHELSA não estão no repositório por causa do tamanho (cada normal futura tem ~118 MB). As listas com os links de download estão em `dados/links/`.

## Etapas

Os scripts estão numerados na ordem em que devem ser rodados. Todos usam caminhos relativos à raiz do repositório, então é só abrir o `.Rproj` no RStudio (ou dar `setwd()` na pasta) antes de rodar. Coordenadas, cenários e períodos ficam em `R/00_config.R`.

1. **`01_download_historico.R`** — baixa os 491 rasters mensais do CHELSA (1979–2019), extrai o valor do pixel onde está a estação e apaga o arquivo logo em seguida. Gera uma planilha por mês em `resultados/historico/`.
2. **`02_organiza_historico.R`** — junta as planilhas mensais, converte para °C (`valor × 0,1 − 273,15`) e faz o pareamento com a temperatura média compensada da estação, mantendo só os meses em que a estação tem dado (303 meses, entre 1979 e 2012). O resultado é `PassaQuatro_Temperaturas_Unificadas.xlsx`, com as colunas `temperatura_c` (CHELSA) e `OBSERVADO` (estação).
3. **`03_download_projecoes.R`** — baixa as 108 normais futuras (3 períodos × 3 cenários × 12 meses) para `rasters/`. Arquivos já baixados são pulados, então dá para rodar de novo se a conexão cair.
4. **`04_extracao_normais.R`** — extrai o valor de cada normal futura no ponto da estação. Nessas normais o pacote `raster` já aplica escala e offset, então o valor sai em °C.
5. **`05_recorte_area.R`** — recorta as normais pelo limite da área de estudo e gera o raster médio de cada período/cenário (usado nos mapas).
6. **`06_delta_change.R`** — calcula o delta mensal (normal futura − média mensal observada na estação), soma esse delta à série observada e monta a série mensal sintética de 30 anos de cada período e cenário.
7. **`07_grafico.R`** — calcula as médias anuais, suaviza com LOESS e gera o gráfico com a série histórica e os três cenários até 2100.

## Estrutura

```
R/                       scripts
dados/
  links/                 links de download do CHELSA
  estacao/               dados mensais da estação INMET 83737
  area_estudo/           shapefile da área de estudo
resultados/
  historico/             valores mensais extraídos e tabela pareada com a estação
  projecoes/             valores no ponto e séries delta change por período/cenário
  figuras/               gráfico final
```

## Pacotes

R 4.4 ou mais recente, com `raster`, `sf`, `sp`, `dplyr`, `stringr`, `readxl`, `openxlsx`, `writexl` e `ggplot2`.

```r
install.packages(c("raster", "sf", "sp", "dplyr", "stringr", "readxl",
                   "openxlsx", "writexl", "ggplot2"))
```

## Referências

Karger, D. N., Conrad, O., Böhner, J., Kawohl, T., Kreft, H., Soria-Auza, R. W., Zimmermann, N. E., Linder, H. P., Kessler, M. (2017). Climatologies at high resolution for the earth's land surface areas. *Scientific Data*, 4, 170122. https://doi.org/10.1038/sdata.2017.122

Karger, D. N., Conrad, O., Böhner, J., Kawohl, T., Kreft, H., Soria-Auza, R. W., Zimmermann, N. E., Linder, H. P., Kessler, M. (2021). Climatologies at high resolution for the earth's land surface areas. EnviDat. https://doi.org/10.16904/envidat.228

Boucher, O. et al. (2020). Presentation and evaluation of the IPSL-CM6A-LR climate model. *Journal of Advances in Modeling Earth Systems*, 12, e2019MS002010. https://doi.org/10.1029/2019MS002010

INMET – Instituto Nacional de Meteorologia. Banco de Dados Meteorológicos (BDMEP). https://bdmep.inmet.gov.br

## Licença

Código sob licença MIT. Os dados do CHELSA e do INMET seguem as condições de uso das respectivas fontes.
