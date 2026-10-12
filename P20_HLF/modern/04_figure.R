# P20_HLF S6: range plot of the central envelope and the sensitivities (A_b to A_g) against the A8 band. LEAP palette.
source("./P20_HLF/modern/00_common.R")
s <- read_csv(file.path(out_dir, "sensitivities.csv"), show_col_types = FALSE) |>
  filter(!is.na(claim), !str_detect(item, "diagnostic"), block != "5B-4" | str_detect(item, "central", negate = TRUE))
s <- s |> mutate(row = if_else(block == "central", "Central envelope", paste(block, item, sep = ": ")),
                 grp = case_when(block == "central" ~ "Central", block == "5A" ~ "5A grid", TRUE ~ "5B item"))
lv <- rev(unique(s$row)); s$row <- factor(s$row, levels = lv)
seg <- s |> group_by(claim, row, grp) |> summarise(lo = min(T), hi = max(T), .groups = "drop")
bands <- claims_H1 |> mutate(claim = paste0(claim, " (printed ", X, "%)"))
seg$claim <- bands$claim[match(seg$claim, claims_H1$claim)]; s$claim <- bands$claim[match(s$claim, claims_H1$claim)]
pal <- c("Central" = "#5C2346", "5A grid" = "#3D8EB9", "5B item" = "#6B8E5E")
p <- ggplot() +
  geom_rect(data = bands, aes(xmin = b_lo, xmax = b_hi, ymin = -Inf, ymax = Inf), fill = "#AAAAAA", alpha = 0.3) +
  geom_vline(data = bands, aes(xintercept = X), colour = "#D4A03E", linewidth = 0.8) +
  geom_segment(data = seg, aes(x = lo, xend = hi, y = row, yend = row, colour = grp), linewidth = 1.1) +
  geom_point(data = s, aes(x = T, y = row, colour = grp, shape = anchor), size = 2.2) +
  facet_wrap(~claim, scales = "free_x") + scale_colour_manual(values = pal, name = NULL) +
  scale_shape_manual(values = c(A_b = 16, A_g = 17), name = "Anchor") +
  labs(x = "Share of 1873-1905 labour-productivity increase attributed to the railway (%)", y = NULL,
       caption = "Grey: A8 band (±10%). Gold: printed value. Segments join the A_b and A_g anchors.") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank())
for (ext in c("pdf", "png")) ggsave(file.path(root, "P20_HLF", "modern", paste0("fig_envelope.", ext)), p, width = 10, height = 5.5, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(root, "P20_HLF", "modern", "sessionInfo.txt"))
