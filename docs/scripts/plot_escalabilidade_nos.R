library(dplyr)
library(ggplot2)

pdf(NULL)

df <- read.csv("../../results/rastro_completo.csv", stringsAsFactors = FALSE)

exec <- df %>%
  filter(rank == "rank0") %>%
  group_by(tipo, size, nproc, nodes, rep) %>%
  summarise(exec_time = max(fim) - min(inicio), .groups = "drop") %>%
  group_by(tipo, size, nproc, nodes) %>%
  summarise(tempo = median(exec_time), sd = sd(exec_time), .groups = "drop")

exec <- exec %>%
  mutate(
    tipo = recode(tipo,
      "coletiva"          = "Coletiva",
      "p2p_bloqueante"    = "P2P Bloqueante",
      "p2p_naobloqueante" = "P2P Não Bloqueante"
    ),
    size_label  = paste0(size, "×", size),
    nodes_label = paste0(nodes, ifelse(nodes == 1, " nó", " nós"))
  )

# Foco: comparar 1 vs 2 vs 3 nós, fixando processos por nó
# Para cada nproc_por_no, nproc_total = nodes * nproc_por_no
# A grade tem: nodes=1 nproc=1,2,4,8,16,32
#              nodes=2 nproc=2,4,8,16,32,64
#              nodes=3 nproc=3,6,12,24,48,96
# Processos por nó = nproc / nodes

exec_pn <- exec %>%
  mutate(pn = nproc / nodes) %>%
  filter(pn %in% c(1, 2, 4, 8, 16, 32)) %>%
  mutate(pn_label = paste0(pn, " proc/nó"))

ggplot(exec_pn, aes(x = factor(nodes), y = tempo,
                    color = tipo, shape = tipo, group = tipo)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = tempo - sd, ymax = tempo + sd),
                width = 0.15, alpha = 0.5) +
  facet_grid(size_label ~ pn_label, scales = "free_y") +
  scale_color_manual(values = c(
    "Coletiva"           = "#2166ac",
    "P2P Bloqueante"     = "#4dac26",
    "P2P Não Bloqueante" = "#d01c8b"
  )) +
  labs(
    # title    = "Escalabilidade por número de nós (processos por nó fixo)",
    subtitle = "Barras de erro = ±1 desvio padrão entre as 2 repetições",
    x        = "Número de nós",
    y        = "Tempo (s)",
    color    = "Versão",
    shape    = "Versão"
  ) +
  theme_bw(base_size = 10) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#f0f0f0"),
    legend.text       = element_text(size = 12),
    legend.title      = element_text(size = 13),
    legend.key.size   = unit(0.8, "cm")
  )

ggsave("../imgs/plot_escalabilidade_nos.pdf", width = 14, height = 8)
# ggsave("../imgs/plot_escalabilidade_nos.png", width = 14, height = 8, dpi = 150)
message("Salvo: plot_escalabilidade_nos.pdf")
