library(dplyr)
library(ggplot2)
library(tidyr)

pdf(NULL)

df <- read.csv("../../results/rastro_completo.csv", stringsAsFactors = FALSE)

# Tempo total = fim do último evento - início do primeiro evento no rank0
exec <- df %>%
  filter(rank == "rank0") %>%
  group_by(tipo, size, nproc, nodes, rep) %>%
  summarise(exec_time = max(fim) - min(inicio), .groups = "drop") %>%
  group_by(tipo, size, nproc, nodes) %>%
  summarise(tempo = median(exec_time), .groups = "drop")

exec <- exec %>%
  mutate(
    tipo = recode(tipo,
      "coletiva"         = "Coletiva",
      "p2p_bloqueante"   = "P2P Bloqueante",
      "p2p_naobloqueante"= "P2P Não Bloqueante"
    ),
    size_label = paste0(size, "×", size),
    nodes_label = paste0(nodes, ifelse(nodes == 1, " nó", " nós"))
  )

# Um painel por tamanho de matriz
# Eixo x = nproc, curva por tipo, facet por nodes
ggplot(exec, aes(x = nproc, y = tempo, color = tipo, shape = tipo)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  facet_grid(size_label ~ nodes_label, scales = "free_y") +
  scale_x_log10(breaks = c(1,2,3,4,6,8,12,16,24,32,48,64,96)) +
  scale_color_manual(values = c(
    "Coletiva"           = "#2166ac",
    "P2P Bloqueante"     = "#4dac26",
    "P2P Não Bloqueante" = "#d01c8b"
  )) +
  labs(
    # title    = "Tempo total de execução (média de 2 repetições)",
    x        = "Número de processos (escala log)",
    y        = "Tempo (s)",
    color    = "Versão",
    shape    = "Versão"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 15),
    strip.background = element_rect(fill = "#f0f0f0"),
    legend.title = element_text(size = 15),
    legend.text = element_text(size = 13)
  )

ggsave("../imgs/plot_tempo_total.pdf", width = 10, height = 8)
# ggsave("../imgs/plot_tempo_total.png", width = 10, height = 8, dpi = 150)
message("Salvo: plot_tempo_total.pdf")
