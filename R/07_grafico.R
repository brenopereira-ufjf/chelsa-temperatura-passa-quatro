# ================================
# 07 - GRÁFICO DA TEMPERATURA MÉDIA ANUAL (HISTÓRICO + CENÁRIOS)
# ================================
# Médias anuais suavizadas por LOESS. Os cenários partem do valor
# histórico de 2010 para que as curvas fiquem conectadas.

library(readxl)
library(dplyr)
library(ggplot2)

source("R/00_config.R")

rotulo_hist <- "CHELSA 1985–2010"

# ================================
# 1) HISTÓRICO
# ================================
hist <- read_xlsx(arquivo_unificado)

hist_anual <- hist %>%
  filter(ano <= 2010) %>%
  group_by(ano) %>%
  summarise(
    temperatura = mean(OBSERVADO, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(cenario = rotulo_hist)

valor_2010 <- hist_anual %>%
  filter(ano == 2010) %>%
  select(ano, temperatura)

# suavização do histórico
modelo_hist <- loess(temperatura ~ ano, data = hist_anual, span = 0.4)

hist_anual_suave <- hist_anual %>%
  mutate(temperatura = predict(modelo_hist, newdata = hist_anual))

# ================================
# 2) CENÁRIOS
# ================================
ler_cenario <- function(periodo, cenario) {
  arquivo <- file.path(pasta_proj, periodo, cenario,
                       paste0(cenario, "_delta_change_mensal_", periodo, ".xlsx"))
  read_xlsx(arquivo) %>%
    group_by(ano) %>%
    summarise(
      temperatura = mean(tas_sint, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(cenario = nomes_cenarios[[cenario]])
}

series_cenarios <- lapply(cenarios, function(cenario) {
  bind_rows(
    # âncora em 2010
    valor_2010 %>% mutate(cenario = nomes_cenarios[[cenario]]),
    lapply(periodos, ler_cenario, cenario = cenario)
  )
})

dados_plot <- bind_rows(hist_anual_suave, series_cenarios)

# ================================
# 3) SUAVIZAÇÃO LOESS
# ================================
suavizar_loess <- function(df, span = 0.25) {
  modelo <- loess(temperatura ~ ano, data = df, span = span)
  df %>% mutate(temperatura = predict(modelo, newdata = df))
}

dados_plot_suave <- dados_plot %>%
  group_by(cenario) %>%
  arrange(ano) %>%
  group_modify(~ suavizar_loess(.x)) %>%
  ungroup()

# forçar conexão exata em 2010
valor_2010_suave <- dados_plot_suave %>%
  filter(cenario == rotulo_hist, ano == 2010) %>%
  pull(temperatura)

dados_plot_suave <- dados_plot_suave %>%
  mutate(
    temperatura = ifelse(
      ano == 2010 & cenario != rotulo_hist,
      valor_2010_suave,
      temperatura
    )
  )

# ================================
# 4) GRÁFICO
# ================================
cores <- c("black", "green4", "blue", "red")
names(cores) <- c(rotulo_hist, unname(nomes_cenarios))

grafico_temp <- ggplot(dados_plot_suave,
                       aes(x = ano, y = temperatura, color = cenario)) +
  geom_line(linewidth = 1.3) +
  scale_color_manual(values = cores) +
  labs(
    x = "Ano",
    y = "Temperatura média anual (°C)",
    color = "Cenário",
    title = "Temperatura média anual – Passa Quatro (MG)",
    subtitle = "Histórico (1985–2010) e projeções climáticas (2011–2100)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "top",
    plot.title = element_text(face = "bold"),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "transparent", color = NA)
  )

grafico_temp

ggsave(
  filename = file.path(pasta_figuras, "temperatura_media_anual_passa_quatro_1979_2100.png"),
  plot = grafico_temp,
  width = 12,
  height = 7,
  dpi = 300,
  bg = "transparent"
)
