# 04_verdicts.R -- P27_RW S6: apply the card's section 8 verdict tables mechanically to output/primary.csv; figure.
suppressMessages({library(dplyr); library(ggplot2)})
source("P27_RW/modern/00_common.R")
p <- read.csv("P27_RW/modern/output/primary.csv"); g <- function(q, v = "estimate") p[[v]][p$quantity == q]
fmt <- function(lo, hi, d = 2) sprintf("[%s, %s]", formatC(lo, format = "f", digits = d), formatC(hi, format = "f", digits = d))

point_row <- function(claim, q, L, U, d = 1) {
  e <- g(q)
  if (!is.finite(e)) return(data.frame(claim, estimate = NA, interval = NA, test_p = NA, band = fmt(L, U, d), verdict = "not-testable", rule = 0))
  v <- if (e >= L && e <= U) c("confirmed", 1) else if (e < L) c("qualified (level below the stated value)", 2) else c("qualified (level above the stated value)", 3)
  data.frame(claim, estimate = round(e, 3), interval = paste0(fmt(g(q, "lo"), g(q, "hi"), d), " (information only)"), test_p = NA,
             band = fmt(L, U, d), verdict = v[1], rule = as.integer(v[2]))
}
gate <- function(q) g(q, "undef_share") > UNDEF_MAX
iv <- function(q, d) paste0(fmt(g(q, "lo"), g(q, "hi"), d), " 98.75%; undefined draws ", sprintf("%.2f%%", 100 * g(q, "undef_share")))
h5 <- function() { lo <- g("D90", "lo"); hi <- g("D90", "hi")
  v <- if (gate("D90")) c("not-testable", 0) else if (lo > 0) c("confirmed", 1) else if (hi < 0) c("weakened", 3) else c("qualified (inference-fragile)", 2)
  data.frame(claim = "H5", estimate = round(g("D90"), 1), interval = iv("D90", 1), test_p = NA, band = "CI > 0", verdict = v[1], rule = as.integer(v[2])) }
h5w <- function() { lo <- g("D90w", "lo"); hi <- g("D90w", "hi")
  v <- if (!is.finite(g("D90w")) || gate("D90w")) c("not-testable", 0) else if (lo > 0) c("confirmed", 1) else if (hi < 0) c("overturned", 2) else c("weakened", 3)
  data.frame(claim = "H5w", estimate = round(g("D90w"), 1), interval = iv("D90w", 1), test_p = NA, band = "CI > 0", verdict = v[1], rule = as.integer(v[2])) }
h7 <- function() { lo <- g("R", "lo"); hi <- g("R", "hi")
  v <- if (gate("R")) c("not-testable", 0) else if (lo >= 0.80 && hi <= 1.25) c("confirmed", 1) else if (hi < 0.80 || lo > 1.25) c("weakened", 2) else c("qualified (inference-fragile)", 3)
  data.frame(claim = "H7", estimate = round(g("R"), 4), interval = iv("R", 4), test_p = NA, band = "[0.80, 1.25]", verdict = v[1], rule = as.integer(v[2])) }
h8 <- function() { lo <- g("Delta", "lo"); hi <- g("Delta", "hi")
  v <- if (gate("Delta")) c("not-testable", 0) else if (lo >= -0.03 && hi <= 0.03) c("confirmed (ownership margin only)", 1) else if (lo > 0.03 || hi < -0.03) c("overturned (ownership margins differ)", 2) else c("weakened", 3)
  data.frame(claim = "H8", estimate = round(g("Delta"), 4), interval = iv("Delta", 4), test_p = NA, band = "[-0.03, +0.03]", verdict = v[1], rule = as.integer(v[2])) }
nt <- function(claim, why) data.frame(claim, estimate = NA, interval = NA, test_p = NA, band = NA, verdict = paste0("not-testable (", why, ")"), rule = NA)

V <- bind_rows(point_row("H1", "m1700", 683.1, 834.9), point_row("H2", "m1790", 1781.1, 2176.9), point_row("H3", "mtot", 1485, 1815),
               point_row("H4", "mu_inv", 6.741, 8.239, 3), h5(), nt("H6", "no-decline claim; card section 1"), h7(), h8(),
               nt("H9", "no subsistence line"), nt("H10", "no comparator microdata"),
               point_row("H1w", "w1700", 683.1, 834.9), point_row("H2w", "w1790", 1781.1, 2176.9), point_row("H3w", "wtot", 1485, 1815), h5w())
V$estimand <- ifelse(grepl("w$|H8", V$claim), "different-estimand", "published")
write.csv(V, "P27_RW/modern/output/verdict.csv", row.names = FALSE); print(V[, c("claim", "estimate", "interval", "verdict", "rule")])

# figure: estimates with 98.75% intervals against the A8 bands (published = plum, settler-household = blue)
fd <- data.frame(panel = c("Row 1700 mean", "Row 1700 mean", "Row 1790 mean", "Row 1790 mean", "Pre-1801 total", "Pre-1801 total",
                           "Rise 1700 to 1790", "Rise 1700 to 1790", "Slave-owner mean ratio R", "Ownership gap (inv - opg)"),
                 est = c("published", "post-stratified", "published", "post-stratified", "published", "post-stratified",
                         "published", "post-stratified", "published", "different estimand"),
                 q = c("m1700", "w1700", "m1790", "w1790", "mtot", "wtot", "D90", "D90w", "R", "Delta"))
fd <- fd |> rowwise() |> mutate(e = g(q), lo = g(q, "lo"), hi = g(q, "hi")) |> ungroup()
bands <- data.frame(panel = unique(fd$panel), L = c(683.1, 1781.1, 1485, 0, 0.80, -0.03), U = c(834.9, 2176.9, 1815, NA, 1.25, 0.03))
bands$U[is.na(bands$U)] <- max(fd$hi[fd$q %in% c("D90", "D90w")]) * 1.05
fd$panel <- factor(fd$panel, levels = unique(fd$panel)); bands$panel <- factor(bands$panel, levels = levels(fd$panel))
pl <- ggplot(fd, aes(y = est, x = e, colour = est)) +
  geom_rect(data = bands, aes(xmin = L, xmax = U, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#AAAAAA", alpha = 0.3) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0.2, linewidth = 0.6, orientation = "y") + geom_point(size = 2.4) +
  facet_wrap(~panel, scales = "free", ncol = 2) +
  scale_colour_manual(values = c(published = "#5C2346", `post-stratified` = "#3D8EB9", `different estimand` = "#6B8E5E"), guide = "none") +
  labs(x = "Estimate with 98.75% bootstrap interval (grey: A8 band)", y = NULL) +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold"))
ggsave("P27_RW/modern/fig_primary.pdf", pl, width = 7, height = 6); ggsave("P27_RW/modern/fig_primary.png", pl, width = 7, height = 6, dpi = 300)
