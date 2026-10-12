# P10_FI S6 step 5: verdict tables (card §8), primary.csv, verdict.csv, family summaries and figures.
# Run from the project root after 01-03 (04 only feeds sensitivities.csv): Rscript P10_FI/modern/05_verdicts.R
source(file.path("P10_FI", "modern", "00_functions.R"))
suppressPackageStartupMessages(library(ggplot2))
h1 <- fread(file.path(OUT, "h1_primary.csv")); its <- fread(file.path(OUT, "its_primary.csv")); lpm <- fread(file.path(OUT, "lpm_primary.csv"))
fail <- fread(file.path(OUT, "bootstrap_failures.csv"))
q <- function(x) h1[quantity == x]
fr <- function(x) fail[quantity == x, fail_rate]

# ---- primary.csv (long) ----------------------------------------------------------------------------
prim <- rbindlist(list(
  h1[, .(block = "H1", quantity, estimate, lo, hi, p = NA_real_, p_holm = NA_real_, fail_rate = fail,
         note = fifelse(quantity == "F", sprintf("Fieller-type set [%.4f, %.4f], bounded=%d", fieller_lo, fieller_hi, as.integer(fieller_bounded)), note))],
  its[, .(block = "H2-ITS", quantity, estimate, lo = hac_lo, hi = hac_hi, p = hac_p, p_holm = NA_real_, fail_rate = NA_real_,
          note = sprintf("HAC 95%% CI; block bootstrap 95%% [%.4f, %.4f]", block_lo, block_hi))],
  lpm[, .(block = paste0("LPM family ", family), quantity = row, estimate, lo, hi, p, p_holm, fail_rate = NA_real_,
          note = sprintf("%s; N=%d; Bonferroni CI 1-0.05/4; degenerate draws %d", source, N, degenerate))]), fill = TRUE)
fwrite(prim, file.path(OUT, "primary.csv"))

# ---- verdicts ---------------------------------------------------------------------------------------
vr <- list()
addv <- function(claim, est, lo, hi, p, ph, thr, v, flag = "") vr[[length(vr) + 1]] <<- data.table(claim = claim, estimate = est, ci_lo = lo, ci_hi = hi,
  p = p, p_holm = ph, threshold = thr, verdict = v[["verdict"]], rule = v[["rule"]], flag = flag)
addv("H1-30s", q("L30")$estimate, NA, NA, NA, NA, "L30 < 2.5 (pp)", v_h130(q("L30")$estimate))
addv("H1-dec", q("d30")$estimate, q("d30")$lo, q("d30")$hi, NA, NA, "Bonferroni CI of s1 - L30 > 0", v_comp(q("d30")$lo, q("d30")$hi, fr("d30")))
addv("H1-25s", q("S25")$estimate, NA, NA, NA, NA, "[3.24, 3.96] (pp)", v_h125s(q("S25")$estimate),
     ifelse(q("S25")$estimate > 1.5 * 3.6, "plausibility flag: > 1.5x stated", ""))
addv("H1-25r", q("R25")$estimate, NA, NA, NA, NA, "[3.6, 4.4]", v_h125r(q("R25")$estimate),
     ifelse(q("R25")$estimate > 1.5 * 4, "plausibility flag: > 1.5x stated", ""))
addv("H1-UX", q("E25")$estimate, q("E25")$lo, q("E25")$hi, NA, NA, "Bonferroni CI of S25 - 0.9 > 0", v_comp(q("E25")$lo, q("E25")$hi, fr("E25")))
addv("H1-F", q("F")$estimate, q("G")$lo, q("G")$hi, NA, NA, sprintf("CIs of D and G > 0 (D CI [%.3f, %.3f]; G = %.3f; CI shown is G's; F Fieller set [%.3f, %.3f])",
     q("D")$lo, q("D")$hi, q("G")$estimate, q("F")$fieller_lo, q("F")$fieller_hi), v_F(q("D")$lo, q("D")$hi, q("G")$lo, q("G")$hi, fr("D"), fr("G")))
for (i in seq_len(nrow(lpm))) { z <- lpm[i]
  thr <- switch(z$row, "H2-c2" = "Holm p >= 0.05 and p >= 0.05 (null claim, A4b)", "H2-c2L" = "Holm p >= 0.05 (null claim)",
                if (z$family == "E") sprintf("Holm p < 0.05 (A4b ladder; b0 = %g)", z$b0) else sprintf("same sign, Holm p < 0.05, |b| >= %g; null band +/-%g", 0.5 * abs(z$b0), 0.5 * abs(z$b0)))
  flag <- c(if (z$row %in% c("H2-c4", "H3-c2", "H3-c4", "H2-c4L", "H3-c2L", "H3-c4L") && abs(z$estimate) > 1.5 * abs(z$b0)) "plausibility flag: |b| > 1.5|b0|",
            if (is.finite(z$p_holm) && z$p_holm < 0.05 && z$lo <= 0 && z$hi >= 0) "Holm-Bonferroni discordance",
            if (z$source != "WCR two-way") "CR1 fallback")
  addv(z$row, z$estimate, z$lo, z$hi, z$p, z$p_holm, thr, lpm_verdict(z$row, z$estimate, z$b0, z$lo, z$hi, z$p, z$p_holm), paste(flag, collapse = "; ")) }
addv("H2-minor", NA, NA, NA, NA, NA, "no A8 default for 'minor'", V("not-testable", "card §1"))
addv("H3-causal", NA, NA, NA, NA, NA, "no exogenous variation", V("not-testable", "card §1"))
addv("H2-ITS", its[quantity == "theta", estimate], its[quantity == "theta", hac_lo], its[quantity == "theta", hac_hi], its[quantity == "theta", hac_p], NA,
     "descriptive: theta (pp), HAC 95% CI", V("different-estimand", "card §8"),
     sprintf("dslope %.3f pp/yr [%.3f, %.3f]; theta block-bootstrap [%.3f, %.3f]", its[quantity == "dslope", estimate], its[quantity == "dslope", hac_lo], its[quantity == "dslope", hac_hi],
             its[quantity == "theta", block_lo], its[quantity == "theta", block_hi]))
vt <- rbindlist(vr)
fwrite(vt, file.path(OUT, "verdict.csv"))
print(vt[, .(claim, estimate = signif(estimate, 4), ci_lo = signif(ci_lo, 3), ci_hi = signif(ci_hi, 3), p = signif(p, 3), p_holm = signif(p_holm, 3), verdict, rule, flag)])

# ---- family coverage and weakest verdict (card §8 summaries) ------------------------------------------
rank_v <- function(v) ifelse(grepl("^overturned", v), 1, ifelse(grepl("^weakened", v), 2, ifelse(grepl("^qualified", v), 3, ifelse(grepl("^confirmed", v), 4, NA))))
grp <- list(`H1 (Family Q + point rows)` = c("H1-30s", "H1-dec", "H1-25s", "H1-25r", "H1-UX", "H1-F"),
            `Family E (primary LPM rows)` = c("H2-c2", "H2-c4", "H3-c2", "H3-c4"),
            `Family L (correction rows)` = c("H2-c2L", "H2-c4L", "H3-c2L", "H3-c4L"),
            `Not-testable / different-estimand` = c("H2-minor", "H3-causal", "H2-ITS"))
sm <- rbindlist(lapply(names(grp), function(g) { x <- vt[claim %in% grp[[g]]]; r <- rank_v(x$verdict)
  data.table(group = g, rows = nrow(x), assessed = sum(!is.na(r)), not_testable_or_diff = sum(is.na(r)),
             weakest = if (any(!is.na(r))) x$verdict[which.min(replace(r, is.na(r), 99))] else NA_character_) }))
print(sm); fwrite(sm, file.path(OUT, "verdict_summary.csv"))

# ---- figures (LEAP palette) ------------------------------------------------------------------------------
leap <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
th <- theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), legend.position = "bottom", plot.title = element_text(face = "bold"))
fd <- lpm[, .(row, family = ifelse(family == "E", "Published specification (Family E)", "Literacy-corrected (Family L)"), estimate, lo, hi, b0,
              hyp = ifelse(hyp == "H2", "Act (H2)", "Segregation (H3)"))]
fd[, lab := factor(row, levels = rev(row))]
p1 <- ggplot(fd, aes(y = lab)) + geom_vline(xintercept = 0, colour = leap["grey"]) +
  geom_errorbar(aes(xmin = lo, xmax = hi, colour = family), width = 0.25, orientation = "y") + geom_point(aes(x = estimate, colour = family), size = 2) +
  geom_point(aes(x = b0), shape = 4, colour = leap["gold"], size = 2.5) + facet_wrap(~hyp, scales = "free") +
  scale_colour_manual(values = unname(leap[c("blue", "plum")]), name = NULL) +
  labs(x = "LPM coefficient; two-way wild cluster bootstrap CI (1 - 0.05/4); x = published value", y = NULL) + th
ggsave(file.path(OUT, "fig_s6_lpm_forest.pdf"), p1, width = 7, height = 3.6); ggsave(file.path(OUT, "fig_s6_lpm_forest.png"), p1, width = 7, height = 3.6, dpi = 300)
ser <- fread(file.path(OUT, "its_series.csv"))
p2 <- ggplot(ser, aes(year)) + geom_vline(xintercept = 1948.5, colour = leap["grey"], linetype = 2) +
  geom_point(aes(y = share), colour = leap["plum"], size = 1.4) +
  geom_line(data = ser[year < 1949], aes(y = fitted), colour = leap["blue"]) + geom_line(data = ser[year >= 1949], aes(y = fitted), colour = leap["blue"]) +
  labs(x = NULL, y = "Interracial marriages, % of couples", title = NULL) + th
ggsave(file.path(OUT, "fig_s6_its.pdf"), p2, width = 6, height = 3.4); ggsave(file.path(OUT, "fig_s6_its.png"), p2, width = 6, height = 3.4, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path("P10_FI", "modern", "sessionInfo.txt"))
