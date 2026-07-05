library(dplyr)
library(ggplot2)

pdf(NULL)

df <- read.csv("../../results/rastro_completo.csv", stringsAsFactors = FALSE)

exec <- df %>%
  filter(rank == "rank0") %>%
  group_by(tipo, size, nproc, nodes, rep) %>%
  summarise(exec_time = max(fim) - min(inicio), .groups = "drop") %>%
  group_by(tipo, size, nproc, nodes) %>%
  summarise(tempo = median(exec_time), .groups = "drop")

# Tempo sequencial (nproc=1, nodes=1) por tipo e size
t_seq <- exec %>%
  filter(nproc == 1, nodes == 1) %>%
  select(tipo, size, t1 = tempo)

speedup <- exec %>%
  left_join(t_seq, by = c("tipo", "size")) %>%
  mutate(speedup = t1 / tempo) %>%
  filter(!is.na(speedup))

speedup <- speedup %>%
  mutate(
    tipo = recode(tipo,
      "coletiva"          = "Coletiva",
      "p2p_bloqueante"    = "P2P Bloqueante",
      "p2p_naobloqueante" = "P2P Não Bloqueante"
    ),
    size_label = paste0(size, "×", size)
  )

# Linha de speedup ideal
ideal <- speedup %>%
  distinct(nproc) %>%
  mutate(speedup = nproc, tipo = "Ideal")

ggplot(speedup, aes(x = nproc, y = speedup, color = tipo, shape = tipo)) +
  geom_line(data = ideal, aes(x = nproc, y = speedup),
            color = "gray60", linetype = "dashed", inherit.aes = FALSE) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  facet_wrap(~ size_label, ncol = 3) +
  scale_x_log10(breaks = c(1,2,3,4,6,8,12,16,24,32,48,64,96)) +
  scale_y_log10() +
  scale_color_manual(values = c(
    "Coletiva"           = "#2166ac",
    "P2P Bloqueante"     = "#4dac26",
    "P2P Não Bloqueante" = "#d01c8b"
  )) +
  labs(
    # title    = "Speedup em relação à execução sequencial (1 processo, 1 nó)",
    subtitle = "Linha tracejada cinza = speedup ideal (linear)",
    x        = "Número de processos (escala log)",
    y        = "Speedup (escala log)",
    color    = "Versão",
    shape    = "Versão"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 15),
    strip.background = element_rect(fill = "#f0f0f0"),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 10),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 16)
  )

ggsave("../imgs/plot_speedup.pdf", width = 10, height = 4.5)
# ggsave("../imgs/plot_speedup.png", width = 10, height = 4.5, dpi = 150)
message("Salvo: plot_speedup.pdf")
