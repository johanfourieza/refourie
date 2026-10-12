# 03_figures.R -- Figures 7-9 analogues: boxplots of household-level HEC by year (outside values excluded).
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(here)})
out <- here::here("P21_LFG", "repro_r", "output")
pal <- c(annual = "#1F4E79", ma5 = "#C55A11")
pairs <- c(HEC_FS = "Fig7_family_slaves", HEC_FK = "Fig8_family_khoe", HEC_SK = "Fig9_slaves_khoe")
for (spec in c("annual", "ma5")) {
  H <- readRDS(file.path(out, paste0("hec_household_", spec, ".rds"))) |>
    pivot_longer(-year, names_to = "pair", values_to = "hec") |> filter(is.finite(hec))
  for (p in names(pairs)) {
    g <- ggplot(filter(H, pair == p), aes(factor(year), hec)) +
      geom_hline(yintercept = 0, linewidth = .3) +
      geom_boxplot(outlier.shape = NA, fill = "grey90", colour = pal[[spec]], linewidth = .3) +
      coord_cartesian(ylim = c(-3, 5)) + labs(x = NULL, y = "Hicksian elasticity of complementarity") +
      theme_minimal(base_size = 9) + theme(axis.text.x = element_text(angle = 90, vjust = .5), panel.grid.minor = element_blank())
    f <- file.path(out, paste0(pairs[[p]], "_", spec))
    ggsave(paste0(f, ".pdf"), g, width = 6.5, height = 3.2); ggsave(paste0(f, ".png"), g, width = 6.5, height = 3.2, dpi = 300)
  }
}
