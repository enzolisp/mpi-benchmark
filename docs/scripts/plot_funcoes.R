library(dplyr)
library(ggplot2)
library(tidyr)

pdf(NULL)

df <- read.csv("../../results/rastro_completo.csv", stringsAsFactors = FALSE)

# Funções relevantes (exclui MPI_Finalize, MPI_Comm_rank/size, MPI_Wtime)
funcs_keep <- c("MPI_Scatter", "MPI_Gather", "MPI_Bcast",
                "MPI_Send", "MPI_Recv",
                "MPI_Isend", "MPI_Irecv", "MPI_Wait")

# Tempo médio por processo por função (média entre ranks, mediana entre reps)
func_time <- df %>%
  filter(funcao %in% funcs_keep) %>%
  group_by(tipo, size, nproc, nodes, rep, rank, funcao) %>%
  summarise(t_rank = sum(duracao), .groups = "drop") %>%
  group_by(tipo, size, nproc, nodes, rep, funcao) %>%
  summarise(t_mean_rank = mean(t_rank), .groups = "drop") %>%
  group_by(tipo, size, nproc, nodes, funcao) %>%
  summarise(t = median(t_mean_rank), .groups = "drop")

func_time <- func_time %>%
  mutate(
    tipo = recode(tipo,
      "coletiva"          = "Coletiva",
      "p2p_bloqueante"    = "P2P Bloqueante",
      "p2p_naobloqueante" = "P2P Não Bloqueante"
    ),
    size_label = paste0(size, "×", size),
    # Agrupar Bcast das versões coletiva/bloqueante como a mesma função visualmente
    funcao = factor(funcao, levels = c(
      "MPI_Scatter","MPI_Gather","MPI_Bcast",
      "MPI_Send","MPI_Recv",
      "MPI_Isend","MPI_Irecv","MPI_Wait"
    ))
  )

cores_funcao <- c(
  "MPI_Scatter" = "#f4a582",
  "MPI_Gather"  = "#d6604d",
  "MPI_Bcast"   = "#e31a1c",
  "MPI_Send"    = "#9970ab",
  "MPI_Recv"    = "#762a83",
  "MPI_Isend"   = "#74c476",
  "MPI_Irecv"   = "#238b45",
  "MPI_Wait"    = "#8c510a"
)

# Gráfico: size=1500, todos nodes e nproc, stacked bar por tipo
plot_data <- func_time %>% filter(size == 1500)

ggplot(plot_data, aes(x = factor(nproc), y = t, fill = funcao)) +
  geom_col(position = "stack", width = 0.8) +
  facet_grid(tipo ~ paste0(nodes, ifelse(nodes==1," nó"," nós")),
             scales = "free_x", space = "free_x") +
  scale_fill_manual(values = cores_funcao) +
  labs(
    title    = "Tempo médio por processo em cada função MPI (size = 1500×1500)",
    subtitle = "Mediana de 2 repetições; média entre os ranks",
    x        = "Número de processos",
    y        = "Tempo (s)",
    fill     = "Função MPI"
  ) +
  theme_bw(base_size = 10) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#f0f0f0"),
    axis.text.x      = element_text(angle = 45, hjust = 1)
  )

ggsave("../imgs/plot_funcoes_stacked.pdf", width = 12, height = 7)
ggsave("../imgs/plot_funcoes_stacked.png", width = 12, height = 7, dpi = 150)
message("Salvo: plot_funcoes_stacked.pdf / .png")


# --- Gráfico 2: só MPI_Wait e MPI_Bcast para destacar o colapso da versão NB ---
plot_nb <- func_time %>%
  filter(size == 1500, funcao %in% c("MPI_Wait", "MPI_Bcast")) %>%
  mutate(nodes_label = paste0(nodes, ifelse(nodes==1," nó"," nós")))

ggplot(plot_nb, aes(x = nproc, y = t, color = funcao, linetype = tipo, shape = tipo)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  facet_wrap(~ nodes_label, ncol = 3, scales = "free_x") +
  scale_color_manual(values = c("MPI_Wait" = "#8c510a", "MPI_Bcast" = "#e31a1c")) +
  labs(
    title    = "MPI_Wait (não bloqueante) vs MPI_Bcast (coletiva/bloqueante) — size=1500",
    x        = "Número de processos",
    y        = "Tempo médio por processo (s)",
    color    = "Função",
    linetype = "Versão",
    shape    = "Versão"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#f0f0f0")
  )

ggsave("../imgs/plot_wait_vs_bcast.pdf", width = 10, height = 4)
ggsave("../imgs/plot_wait_vs_bcast.png", width = 10, height = 4, dpi = 150)
message("Salvo: plot_wait_vs_bcast.pdf / .png")
