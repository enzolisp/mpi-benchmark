library(dplyr)
library(ggplot2)

pdf(NULL)

df <- read.csv("../../results/rastro_completo.csv", stringsAsFactors = FALSE)

# Paleta de cores igual ao gráfico original
cores_funcao <- c(
  "MPI_Bcast"     = "#e31a1c",
  "MPI_Gather"    = "#33a02c",
  "MPI_Isend"     = "#b2df8a",
  "MPI_Scatter"   = "#ff7f00",
  "MPI_Wait"      = "#8c510a",
  "MPI_Finalize"  = "#aaaaaa",
  "MPI_Irecv"     = "#1f78b4",
  "MPI_Recv"      = "#6a3d9a",
  "MPI_Send"      = "#fb9a99",
  "MPI_Comm_rank" = "#dddddd",
  "MPI_Comm_size" = "#dddddd",
  "MPI_Wtime"     = "#dddddd"
)

# Funções a mostrar (exclui as triviais)
funcs_show <- c("MPI_Bcast", "MPI_Gather", "MPI_Isend", "MPI_Scatter",
                "MPI_Wait", "MPI_Finalize", "MPI_Irecv", "MPI_Recv", "MPI_Send")

# Filtrar execução: size=1500, nproc=96, nodes=3, rep=1
gantt <- df %>%
  filter(size == 1500, nproc == 96, nodes == 3, rep == 1,
         funcao %in% funcs_show) %>%
  mutate(
    # Extrair número do rank para ordenação numérica correta
    rank_num = as.integer(sub("rank", "", rank)),
    tipo = recode(tipo,
      "coletiva"          = "coletiva",
      "p2p_bloqueante"    = "p2p_bloqueante",
      "p2p_naobloqueante" = "p2p_naobloqueante"
    ),
    tipo = factor(tipo, levels = c("coletiva", "p2p_bloqueante", "p2p_naobloqueante"))
  )

# ─── Gráfico 1: Gantt Geral ───────────────────────────────────────────────────
p_geral <- ggplot(gantt,
    aes(xmin = inicio, xmax = fim,
        ymin = rank_num - 0.45, ymax = rank_num + 0.45,
        fill = funcao)) +
  geom_rect() +
  facet_wrap(~ tipo, ncol = 1, strip.position = "top") +
  scale_fill_manual(values = cores_funcao, name = "Funcao MPI") +
  scale_y_continuous(breaks = c(0, 16, 32, 48, 64, 80, 96),
                     name = "Rank") +
  scale_x_continuous(name = "Tempo [s]") +
  labs(
    # title    = "Linha do tempo de cada rank (size=1500, nproc=96, 3 nos, rep 1)",
    subtitle = "Espaco em branco = computacao local; cinza = espera na sincronizacao final"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = "top",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    strip.text = element_text(size = 15),
    strip.background = element_rect(fill = "#e0e0e0"),
    legend.text       = element_text(size = 15),
    legend.title      = element_text(size = 13),
    legend.key.size   = unit(0.8, "cm")
  ) +
  guides(fill = guide_legend(nrow = 2))

ggsave("../imgs/gantt_geral.pdf", p_geral, width = 11, height = 9)
# ggsave("../imgs/gantt_geral.png", p_geral, width = 11, height = 9, dpi = 150)
message("Salvo: gantt_geral.pdf")

# ─── Gráfico 2: Zoom na fase de distribuição (primeiros 0.6s) ────────────────
gantt_zoom <- gantt %>%
  # Clipa os segmentos ao intervalo [0, 0.6]
  filter(inicio < 0.6) %>%
  mutate(fim = pmin(fim, 0.6))

p_zoom <- ggplot(gantt_zoom,
    aes(xmin = inicio, xmax = fim,
        ymin = rank_num - 0.45, ymax = rank_num + 0.45,
        fill = funcao)) +
  geom_rect() +
  facet_wrap(~ tipo, ncol = 1, strip.position = "top") +
  scale_fill_manual(values = cores_funcao, name = "Funcao MPI",
                    # Mostrar só as funções que aparecem nesse zoom
                    breaks = c("MPI_Scatter","MPI_Bcast","MPI_Recv",
                               "MPI_Isend","MPI_Irecv","MPI_Wait","MPI_Send")) +
  scale_y_continuous(breaks = c(0, 16, 32, 48, 64, 80, 96),
                     name = "Rank") +
  scale_x_continuous(name = "Tempo [s]", limits = c(0, 0.6)) +
  labs(
    # title    = "Zoom na fase de distribuicao (primeiros 0.6s)",
    subtitle = "Mesma execucao da figura anterior"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = "top",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    strip.background = element_rect(fill = "#e0e0e0"),
    strip.text        = element_text(size = 15),
    legend.text       = element_text(size = 15),
    legend.title      = element_text(size = 13),
    legend.key.size   = unit(0.8, "cm")
  ) +
  guides(fill = guide_legend(nrow = 2))

ggsave("../imgs/gantt_dist.pdf", p_zoom, width = 11, height = 9)
# ggsave("../imgs/gantt_dist.png", p_zoom, width = 11, height = 9, dpi = 150)
message("Salvo: gantt_dist.pdf")
