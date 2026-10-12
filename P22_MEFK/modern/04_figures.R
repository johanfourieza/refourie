# P22_MEFK S6, step 4: figures (LEAP palette). Input: modern/output/{primary,cohort_foreign}.csv. Output: modern/fig_*.{pdf,png}, sessionInfo.txt
suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2); library(here)})
root <- here::here(); if (basename(root) != "Fourie_ReplicateMe") root <- normalizePath(file.path(root, ".."))
md <- file.path(root, "P22_MEFK", "modern"); out <- file.path(md, "output")
leap <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
theme_leap <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
  legend.position = "bottom", plot.title.position = "plot", axis.title.y = element_blank())
save2 <- function(p, f, w = 7, h = 4) { ggsave(file.path(md, paste0(f, ".pdf")), p, width = w, height = h); ggsave(file.path(md, paste0(f, ".png")), p, width = w, height = h, dpi = 300) }

pr <- read_csv(file.path(out, "primary.csv"), show_col_types = FALSE)
get <- function(q) unlist(pr[pr$quantity == q, c("L", "U")])
d <- tibble(row = c("M-inv: middle class, % of rows", "M-cap: middle class, % of Value", "F-cap: foreign, % of Value (11%)", "F-cap8: foreign, % of Value (8%)", "L-inv: local, % of rows"),
            q = c("share_rows: Middle class", "share_value: Middle class", "share_value: Foreign (C1)", "share_value: Foreign (C1)", "share_rows: Local (C1)"),
            pub = c(27, 31, 11, 8, 95), lo = c(24.3, 28, 9.9, 7.2, 92), hi = c(29.7, 34, 12.1, 8.8, 98)) |>
  rowwise() |> mutate(L = get(q)[1], U = get(q)[2]) |> ungroup() |> mutate(row = factor(row, rev(row)))
p1 <- ggplot(d, aes(y = row)) +
  geom_linerange(aes(xmin = L, xmax = U, colour = "Identified set (unknowns to none / all)"), linewidth = 3.5) +
  geom_linerange(aes(xmin = lo, xmax = hi, colour = "Equivalence band (A8/A8a)"), linewidth = 1.6) +
  geom_point(aes(x = pub, shape = "Published value"), colour = leap["plum"], size = 2.6) +
  scale_colour_manual(values = c("Identified set (unknowns to none / all)" = unname(leap["sage"]), "Equivalence band (A8/A8a)" = unname(leap["gold"])), name = NULL) +
  scale_shape_manual(values = c("Published value" = 18), name = NULL) +
  labs(x = "Per cent", title = "Identified sets on the surviving transcription (C1 applied) against published values") + theme_leap
save2(p1, "fig_identified_sets", 8, 3.8)

ch <- read_csv(file.path(out, "cohort_foreign.csv"), show_col_types = FALSE)
p2 <- ggplot(ch, aes(x = found_year)) +
  geom_linerange(aes(ymin = foreign_L, ymax = foreign_U, colour = "Identified set"), linewidth = 3) +
  geom_point(aes(y = foreign_L, colour = "Unknown location as local"), size = 2) +
  scale_colour_manual(values = c("Identified set" = unname(leap["grey"]), "Unknown location as local" = unname(leap["blue"])), name = NULL) +
  scale_x_continuous(breaks = 1892:1902) +
  labs(x = "Founding year of company (cohort composition, not investment over time)", y = "Foreign share of Value, %",
       title = "Foreign capital share by founding cohort, 1892-1902") + theme_leap + theme(axis.title.y = element_text())
save2(p2, "fig_cohort_foreign", 7, 4)
writeLines(capture.output(sessionInfo()), file.path(md, "sessionInfo.txt"))
