# P01_BF S6 step 2: pre-verdict check G5, then the H3 primary (card §4B): unconditional Khoesan cohort difference
# (T9_r5), wild cluster restricted bootstrap by court volume (Webb, B = 9,999; Monte Carlo rule -> 99,999),
# p-value from a conf_int = FALSE call; Bonferroni interval from a separate call (reported only).
# Outputs: output/checks_h3.csv, h3_primary.csv, h3_cluster_assessment.csv
source(here::here("P01_BF", "modern", "00_common.R"))

d <- load_sample(); h <- h3_frame(d)
m <- lm(y ~ mid, data = h); D <- unname(coef(m)["mid"])
ref <- read_csv(file.path(root, "compare", "s5_checks", "s5_03_T9_pvalues.csv"), show_col_types = FALSE)
r5 <- ref$est[ref$id == "T9_r5"]
g1 <- nrow(h) == 217 && sum(h$mid == 0) == 28
chk <- tibble(check = c("G1", "G5"), item = c("Khoesan n early/mid", "D"),
              computed = c(sprintf("%d/%d", sum(h$mid == 0), sum(h$mid == 1)), sprintf("%.12f", D)),
              reference = c("28/189", sprintf("%.12f", r5)), tolerance = c("exact", "1e-8"),
              pass = c(g1, abs(D - r5) <= 1e-8))
write_csv(chk, file.path(out, "checks_h3.csv")); print(chk)
gate <- all(chk$pass)

# ---- step 1: p-value ----------------------------------------------------------------------------------
step1 <- function(B) tryCatch(h3_boot(h, B, conf_int = FALSE), error = function(e) e)
B <- 9999; b1 <- step1(B); p1 <- if (inherits(b1, "error")) NA_real_ else b1$p_val
p_B9999 <- p1; mc_rerun <- is.finite(p1) && mc_near(p1, B)
if (mc_rerun) { B <- 99999; b1 <- step1(B); p1 <- if (inherits(b1, "error")) NA_real_ else b1$p_val }
p_step1 <- p1; B_final <- B
cat("step 1: B =", B_final, " p =", p_step1, " MC rerun:", mc_rerun, "\n")

# ---- step 2: interval (reported only) -----------------------------------------------------------------
b2 <- tryCatch(h3_boot(h, B_final, conf_int = TRUE), error = function(e) e)
ci <- if (inherits(b2, "error") || is.null(b2$conf_int) || any(!is.finite(b2$conf_int))) c(NA, NA) else sort(b2$conf_int)
ci_note <- if (anyNA(ci)) paste("not inverted:", if (inherits(b2, "error")) conditionMessage(b2) else "non-finite") else "inverted"

h3 <- tibble(row = "H3", est = D, b0 = B0_H3, p = p_step1, B = B_final, mc_rerun, p_B9999, t_stat = if (inherits(b1, "error")) NA else b1$t_stat,
             ci_lo = ci[1], ci_hi = ci[2], ci_level = 1 - ALPHA / M_FAM, ci_note, n = nrow(h), n_early = sum(h$mid == 0),
             G = n_distinct(h$source), gate_pass = gate, fail = !gate | !is.finite(p_step1),
             boot_error = if (inherits(b1, "error")) conditionMessage(b1) else NA_character_,
             version = as.character(packageVersion("fwildclusterboot")))
write_csv(h3, file.path(out, "h3_primary.csv")); print(t(h3))

# ---- cluster assessment (reported; decides nothing) ---------------------------------------------------
sz <- table(h$source)
vol <- h |> group_by(source) |> summarise(n_early = sum(mid == 0), n_mid = sum(mid == 1), .groups = "drop")
ypv <- h |> group_by(source) |> summarise(k = n_distinct(cyear)); vpy <- h |> group_by(cyear) |> summarise(k = n_distinct(source))
nest <- if (all(ypv$k == 1) && all(vpy$k == 1)) "one-to-one" else if (all(ypv$k == 1)) "volumes nest within years" else
  if (all(vpy$k == 1)) "years nest within volumes" else "crossed"
X <- model.matrix(m)
ca <- tibble(item = c("G (volumes with Khoesan cohorts 1-2)", "cluster size min/median/max", "volumes with early-cohort Khoesan",
                      "largest volume share of the 28 early", "volumes with both cohorts", "volumes with one cohort only",
                      "nesting (cyear per source max; source per cyear max)", "G* (CSS 2017), rho = 0", "G* (CSS 2017), rho = 1"),
             text = c(n_distinct(h$source), paste(min(sz), median(sz), max(sz), sep = "/"), sum(vol$n_early > 0),
                      sprintf("%.3f", max(vol$n_early) / sum(vol$n_early)), sum(vol$n_early > 0 & vol$n_mid > 0),
                      sum(xor(vol$n_early > 0, vol$n_mid > 0)), sprintf("%s (%d; %d)", nest, max(ypv$k), max(vpy$k)),
                      sprintf("%.2f", g_star(X, h$source, "mid", 0)), sprintf("%.2f", g_star(X, h$source, "mid", 1))))
write_csv(ca, file.path(out, "h3_cluster_assessment.csv")); print(ca)
