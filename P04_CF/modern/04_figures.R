# P04_CF  S6 modern reanalysis, step 4: forest plot (LEAP style). One panel per claim: published value (card b0),
# original-code value (repro_original/results_original.csv; conventional 95% CI for the logits, none printed or
# computable for Altham; no surviving code for I4) and the modern primary estimate with its Bonferroni CI.
# Shading: credible-null band (I1-I3) or equivalence band (I4); dashed: confirm threshold.
# Outputs: output/fig_s6_forest.{pdf,png} (PNG 300 dpi).
suppressPackageStartupMessages({library(dplyr); library(ggplot2)})
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P04_CF"
out <- file.path(root, "modern", "output")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", hjust = 0),
          axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 9, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8), panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.5), panel.grid.minor = element_blank(),
          axis.ticks.x = element_line(color = "#4A4A4A", linewidth = 0.6), legend.position = "none",
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = margin(10, 10, 10, 10), strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D", hjust = 0),
          plot.caption = element_text(size = 8, colour = "#5A5A5A", hjust = 0))
}
pr <- read.csv(file.path(out, "primary.csv"))
ro <- read.csv(file.path(root, "repro_original", "results_original.csv"))
ov <- function(id) ro$value[ro$claim_id == id]; os <- function(id) ro$se[ro$claim_id == id]
lab <- c(I1 = "I1  Altham Delta = d(P,I) - d(Q,I)", `I2-OR` = "I2-OR  Gold, Model 3 (ln OR)", `I2-RR` = "I2-RR  Gold, Model 3 (ln RR)",
         `I3-OR` = "I3-OR  Migrant father, Model 1 (ln OR)", `I3-RR` = "I3-RR  Migrant father, Model 1 (ln RR)",
         I4 = "I4  Farmer persistence, Gold - Slavery (pp)")
orig_ln <- function(id) c(log(ov(id)), log(ov(id)) - 1.96 * os(id) / ov(id), log(ov(id)) + 1.96 * os(id) / ov(id))
o2 <- orig_ln("T11_r4_c3"); o3 <- orig_ln("T11_r5_c1")
orig <- data.frame(claim = c("I1", "I2-OR", "I2-RR", "I3-OR", "I3-RR"),
                   est = c(ov("T10_r1_c1") - ov("T10_r1_c2"), o2[1], o2[1], o3[1], o3[1]),
                   lo = c(NA, o2[2], o2[2], o3[2], o3[2]), hi = c(NA, o2[3], o2[3], o3[3], o3[3]))
pts <- bind_rows(
  pr |> transmute(claim, est = b0, lo = NA, hi = NA, src = "Published"),
  orig |> mutate(src = "Original code"),
  pr |> transmute(claim, est = estimate, lo = ci_lo, hi = ci_hi, src = "Modern primary")) |>
  mutate(src = factor(src, levels = rev(c("Published", "Original code", "Modern primary"))), panel = factor(lab[claim], levels = lab))
bands <- pr |> transmute(panel = factor(lab[claim], levels = lab), thr = threshold)
p <- ggplot(pts, aes(x = est, y = src, colour = src)) +
  geom_rect(data = bands, aes(xmin = -thr, xmax = thr, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#97C5B0", alpha = 0.35) +
  geom_vline(xintercept = 0, colour = "#AAAAAA", linewidth = 0.4) +
  geom_vline(data = bands |> filter(!grepl("^I4", panel)), aes(xintercept = thr), linetype = "dashed", colour = "#45808B", linewidth = 0.4) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.7, na.rm = TRUE) +
  geom_point(size = 2.4) +
  facet_wrap(~ panel, ncol = 2, scales = "free_x") +
  scale_colour_manual(values = c(Published = "#D4A03E", `Original code` = "#3D8EB9", `Modern primary` = "#5C2346")) +
  labs(x = NULL, y = NULL,
       caption = paste("Modern primary: corrected coding (grazier = Farmer, century removed), sons born 1800-1909, father-clustered",
                       "inference; bars are Bonferroni CIs (1 - 0.05/6).\nOriginal code: do-file output; logit bars are conventional 95% CIs;",
                       "the original code reports odds ratios under the RR label; no code survives for I4.\nShading: credible-null band (I1-I3),",
                       "equivalence band +/-5 pp (I4). Dashed: confirm threshold.")) +
  theme_leap()
ggsave(file.path(out, "fig_s6_forest.png"), p, width = 10, height = 7, dpi = 300)
ggsave(file.path(out, "fig_s6_forest.pdf"), p, width = 10, height = 7)
