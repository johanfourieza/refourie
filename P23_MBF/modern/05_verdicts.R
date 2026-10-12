# P23_MBF S6: verdicts (card §8, applied mechanically), primary.csv, sensitivities.csv, D1 verification table.
suppressPackageStartupMessages({ library(tidyverse) })
root <- "."
mod <- file.path(root, "P23_MBF", "modern")
out <- file.path(mod, "output")
source(file.path(mod, "t5_common.R"))
ASTAR <- 0.05 / 6
BAND <- 0.5 * log(1.32)
f3 <- function(x) formatC(x, format = "f", digits = 3)
f4 <- function(x) formatC(x, format = "f", digits = 4)

# ---------------- inputs
pc <- read_csv(file.path(out, "t2_precondition.csv"), show_col_types = FALSE) |> deframe()
t2 <- read_csv(file.path(out, "t2_primary_raw.csv"), show_col_types = FALSE)
t5 <- read_csv(file.path(out, "t5_primary_raw.csv"), show_col_types = FALSE)
sens2 <- read_csv(file.path(out, "t2_sensitivities_raw.csv"), show_col_types = FALSE)
BFIN <- t2$B_final[1]
pre_ok <- pc[["coef_and_se_match_1e-6"]] == 1 && pc[["FD_ok_scaledstep_D2"]] == 1
pre_ok_literal <- pc[["coef_and_se_match_1e-6"]] == 1 && pc[["FD_ok_literal_absstep1e-5"]] == 1

# ---------------- D1 verification: boottest on the full data vs the cell replica at the same points (must agree exactly)
ver <- list()
for (b in c(9999, 99999)) {
  fa <- file.path(out, sprintf("check_fulldata_boottest_B%d.csv", b))
  fb <- file.path(out, sprintf("check_replica_B%d.csv", b))
  if (!file.exists(fa) || !file.exists(fb)) next
  A <- read_csv(fa, show_col_types = FALSE); Bm <- read_csv(fb, show_col_types = FALSE)
  m <- A |> rename(p_boottest_fulldata = p) |> mutate(k = row_number()) |>
    left_join(Bm |> rename(p_cell_replica = p) |> mutate(k = row_number()) |> select(k, h2 = h, r2 = r, p_cell_replica), by = "k") |>
    mutate(same_point = h == h2 & abs(r - r2) < 1e-9 * pmax(1, abs(r)), exact = abs(p_boottest_fulldata - p_cell_replica) < 1e-12) |>
    select(B, h, r, null, p_boottest_fulldata, p_cell_replica, same_point, exact)
  ver[[length(ver) + 1]] <- m
}
ver <- bind_rows(ver)
write_csv(ver, file.path(out, "check_fulldata_vs_cells.csv"))
mc <- read_csv(file.path(out, "t2_mc_check_B9999.csv"), show_col_types = FALSE)

# ---------------- Table 2 quantities
gt <- function(h, col) t2[[col]][t2$h == h]
p0 <- setNames(sapply(1:6, gt, col = "p0"), 1:6)
uns <- setNames(sapply(1:6, gt, col = "unsupported"), 1:6)
set_str <- function(h) {
  r <- t2[t2$h == h, ]
  if (r$unsupported == 1) return("unsupported")
  segs <- c()
  for (j in 1:3) {
    lo <- r[[paste0("lo", j)]]; hi <- r[[paste0("hi", j)]]
    if (is.na(lo)) next
    segs <- c(segs, sprintf("[%s, %s]", f3(lo), f3(hi)))
  }
  s <- paste(segs, collapse = " U ")
  if (r$nseg > 3) s <- paste0(s, " U ... (", r$nseg, " segments)")
  if (r$any_unres == 1) s <- paste0(s, " (an endpoint or tail unresolved)")
  if (r$n_unsup_pts > 0) s <- paste0(s, sprintf(" (%d grid points unsupported: restricted refit did not converge after R1)", as.integer(r$n_unsup_pts)))
  s
}
padj <- setNames(pmin(1, 6 * p0), 1:6)
est <- setNames(sapply(1:6, gt, col = "rhat"), 1:6)

ladder <- function(p, unsupported) {
  if (!pre_ok || unsupported) return(c("not-testable", 0))
  if (min(1, 6 * p) < .05) return(c("confirmed", 1))
  if (p < .05) return(c("qualified (inference-fragile)", 2))
  c("weakened", 3)
}
v_h1or <- ladder(p0[["1"]], uns[["1"]])
v_h2or <- ladder(p0[["2"]], uns[["2"]])
v_h1p <- (function() {
  if (!pre_ok || uns[["1"]] || uns[["3"]]) return(c("not-testable", 0))
  a <- min(1, 6 * p0[["1"]]); b <- min(1, 6 * p0[["3"]])
  if (a < .05 && b < .05) return(c("confirmed", 1))
  if (p0[["1"]] < .05 && p0[["3"]] < .05) return(c("qualified (inference-fragile)", 2))
  c("weakened (the gap is not established for every cohort group)", 3)
})()
v_h2pd <- (function() {
  th <- est[["4"]]; pa <- padj[["4"]]
  if (!pre_ok || uns[["4"]]) return(c("not-testable", 0))
  if (th > 0 && pa < .05) return(c("confirmed", 1))
  if (th < 0 && pa < .05) return(c("overturned (reversed: the realised probability gap was larger after independence)", 2))
  if (th > 0 && pa >= .05) return(c("weakened", 3))
  c("weakened (direction lost)", 4)
})()
v_mag <- function(h) {
  th <- est[[as.character(h)]]; pa <- padj[[as.character(h)]]
  cn <- gt(h, "cn_status")
  if (!pre_ok || uns[[as.character(h)]]) return(c("not-testable", 0))
  if (th < 0 && pa < .05) return(c("overturned (reversed)", 1))
  if (is.na(cn) || cn == -1) return(c("not-testable", 2))
  if (cn == 1) return(c("overturned (credible null)", 3))
  if (th > 0 && pa < .05 && th >= BAND) return(c("confirmed", 4))
  if (th > 0 && pa < .05 && th < BAND) return(c("qualified (magnitude below the floor)", 5))
  if (th > 0 && pa >= .05) return(c("weakened", 6))
  c("weakened (direction lost)", 7)
}
v_h2lit <- v_mag(6)
v_h2rrr <- v_mag(5)

# ---------------- Table 5
sup_or <- t5$conv_full && t5$conv_null && t5$conv_ci_lo && t5$conv_ci_hi
sup_p <- t5$conv_full && t5$conv_null
v_h3or <- verdict_h3or(t5$beta, t5$plr_p, t5$pl_ci_lo, t5$pl_ci_hi, sup_or)
v_h3p <- verdict_h3p(t5$beta, t5$plr_p, sup_p)

cn_txt <- function(h) c("-1" = "undecidable", "0" = "not inside band", "1" = "inside band")[as.character(gt(h, "cn_status"))]
verdict <- tribble(
  ~claim, ~row, ~claim_level, ~scale, ~estimate, ~interval, ~test_p, ~adj_p, ~threshold_or_band, ~verdict, ~rule,
  "H1", "H1-OR", 1, "log-odds", f4(est[["1"]]), paste0("99.17% WCR set ", set_str(1)), f4(p0[["1"]]), f4(padj[["1"]]),
    "adj p < .05 (floor 0.19 met by fixed point)", v_h1or[1], v_h1or[2],
  "H1", "H1-P", 0, "probability (sign of b1 and b1+b3)", paste0("b1 ", f4(est[["1"]]), "; b1+b3 ", f4(est[["3"]]),
    sprintf("; AME post %s, pre %s", f4(pc[["AMEpost"]]), f4(pc[["AMEpre"]]))),
    paste0("b1: ", set_str(1), "; b1+b3: ", set_str(3)), paste0(f4(p0[["1"]]), "; ", f4(p0[["3"]])),
    paste0(f4(padj[["1"]]), "; ", f4(padj[["3"]])), "both adj p < .05 (A8 comparative, conjunction)", v_h1p[1], v_h1p[2],
  "H2", "H2-OR", 1, "log-odds", f4(est[["2"]]), paste0("99.17% WCR set ", set_str(2)), f4(p0[["2"]]), f4(padj[["2"]]),
    "adj p < .05 (floor 0.14 met by fixed point)", v_h2or[1], v_h2or[2],
  "H2", "H2-Pd", 0, "probability (dAME)", f4(est[["4"]]), paste0("99.17% WCR set ", set_str(4)), f4(p0[["4"]]), f4(padj[["4"]]),
    "dAME > 0, adj p < .05 (A8 comparative)", v_h2pd[1], v_h2pd[2],
  "H2", "H2-lit", 0, "log risk ratio (literal)", f4(est[["6"]]), paste0("99.17% WCR set ", set_str(6), "; credible-null condition: ", cn_txt(6)),
    f4(p0[["6"]]), f4(padj[["6"]]), sprintf("floor 0.5*ln(1.32) = %s; null band (-%s, %s)", f4(BAND), f4(BAND), f4(BAND)), v_h2lit[1], v_h2lit[2],
  "H2", "H2-RRR", 0, "log ratio of risk ratios (reconstructed interpretation)", f4(est[["5"]]), paste0("99.17% WCR set ", set_str(5), "; credible-null condition: ", cn_txt(5)),
    f4(p0[["5"]]), f4(padj[["5"]]), sprintf("floor 0.5*ln(1.32) = %s; null band (-%s, %s)", f4(BAND), f4(BAND), f4(BAND)), v_h2rrr[1], v_h2rrr[2],
  "H3", "H3-OR", 1, "log-odds (Firth)", f3(t5$beta), sprintf("95%% PL CI [%s, %s]", f3(t5$pl_ci_lo), f3(t5$pl_ci_hi)), f4(t5$plr_p), f4(t5$plr_p),
    "p < .05, beta >= 4.55; null band (-4.55, 4.55)", v_h3or[1], v_h3or[2],
  "H3", "H3-P", 0, "probability (sign of beta, Firth)", f3(t5$beta), sprintf("95%% PL CI [%s, %s]", f3(t5$pl_ci_lo), f3(t5$pl_ci_hi)), f4(t5$plr_p), f4(t5$plr_p),
    "beta > 0, p < .05 (A8 comparative)", v_h3p[1], v_h3p[2],
  "H3", "H3-causal", 0, "-", NA, NA, NA, NA, "-", "not-testable", "-",
  "abstract", "created-by / account-for-variation / favouritism-endogenous", 0, "-", NA, NA, NA, NA, "-", "not-testable", "-"
) |> mutate(rule = as.character(rule))
flag <- c(H2lit = est[["6"]] > 1.5 * log(1.32), H2RRR = est[["5"]] > 1.5 * log(1.32), H3OR = t5$beta > 1.5 * 9.10)
verdict <- verdict |> mutate(plausibility_flag = case_when(row == "H2-lit" ~ flag[["H2lit"]], row == "H2-RRR" ~ flag[["H2RRR"]], row == "H3-OR" ~ flag[["H3OR"]], TRUE ~ NA),
                             precondition_literal_FD_check_passed = pre_ok_literal)
write_csv(verdict, file.path(out, "verdict.csv"))
print(verdict |> select(row, estimate, test_p, adj_p, verdict, rule), width = 200)

# ---------------- primary.csv (long)
prim <- bind_rows(
  tibble(analysis = "A", quantity = names(pc), value = unname(pc)),
  t2 |> select(h, rhat, s, p0, mcse, padj, cr1p, B, nseg, lo1, hi1, lo2, hi2, lo3, hi3, lo_res, hi_res, any_unres, disjoint, contains0, consistent, unsupported, n_unsup_pts, cn_status, p_mband, p_pband, n_evals, reruns, escalate) |>
    mutate(across(everything(), as.numeric)) |>
    pivot_longer(-h, names_to = "q", values_to = "value") |>
    mutate(analysis = "A", quantity = paste0("h", h, "_", q)) |> select(analysis, quantity, value),
  t5 |> select(where(is.numeric), conv_full, conv_null, conv_ci_lo, conv_ci_hi) |> mutate(across(everything(), as.numeric)) |>
    pivot_longer(everything(), names_to = "quantity", values_to = "value") |> mutate(analysis = "B")
)
write_csv(prim, file.path(out, "primary.csv"))

# ---------------- sensitivities.csv
hname <- c("b1", "b3", "b1+b3", "dAME", "lnRRR", "lnRRlit")
s2 <- sens2 |> mutate(table = "T2", item = str_extract(scen, "^S[0-9]+[ab]?") |> str_remove("^S")) |>
  transmute(table, item, scenario = scen, statistic = stat, estimate = est, p = p, adj_p = ifelse(stat %in% hname & !str_detect(scen, "_se$"), pmin(1, 6 * p), NA),
            p_mband, p_pband, cnull_status = cnull, N, G)
# item 8 enumeration: per-run verdict categories on the Table 2 rows
loco <- sens2 |> filter(str_detect(scen, "^S8_")) |> select(scen, stat, est, p, cnull) |> filter(stat %in% hname)
cat_run <- function(dd) {
  g <- function(s, col) dd[[col]][dd$stat == s]
  lad <- function(p) if (6 * p < .05) "confirmed" else if (p < .05) "qualified (inference-fragile)" else "weakened"
  h1p <- if (6 * g("b1", "p") < .05 && 6 * g("b1+b3", "p") < .05) "confirmed" else if (g("b1", "p") < .05 && g("b1+b3", "p") < .05) "qualified (inference-fragile)" else "weakened"
  pd <- { th <- g("dAME", "est"); pa <- min(1, 6 * g("dAME", "p")); if (th > 0 && pa < .05) "confirmed" else if (th < 0 && pa < .05) "overturned (reversed)" else if (th > 0) "weakened" else "weakened (direction lost)" }
  mg <- function(s) { th <- g(s, "est"); pa <- min(1, 6 * g(s, "p")); cn <- g(s, "cnull")
    if (th < 0 && pa < .05) "overturned (reversed)" else if (is.na(cn) || cn == -1) "not-testable" else if (cn == 1) "overturned (credible null)" else
      if (th > 0 && pa < .05 && th >= BAND) "confirmed" else if (th > 0 && pa < .05) "qualified (magnitude below the floor)" else if (th > 0) "weakened" else "weakened (direction lost)" }
  tibble(row = c("H1-OR", "H1-P", "H2-OR", "H2-Pd", "H2-lit", "H2-RRR"),
         category = c(lad(g("b1", "p")), h1p, lad(g("b3", "p")), pd, mg("lnRRlit"), mg("lnRRR")),
         estimate = c(g("b1", "est"), g("b1+b3", "est"), g("b3", "est"), g("dAME", "est"), g("lnRRlit", "est"), g("lnRRR", "est")),
         meets_confirm = category == "confirmed")
}
loco_cat <- loco |> group_by(scen) |> group_modify(~ cat_run(.x)) |> ungroup()
prim_cat <- tibble(row = c("H1-OR", "H1-P", "H2-OR", "H2-Pd", "H2-lit", "H2-RRR"),
                   primary = c(v_h1or[1], v_h1p[1], v_h2or[1], v_h2pd[1], v_h2lit[1], v_h2rrr[1]))
loco_sum <- loco_cat |> left_join(prim_cat, by = "row") |>
  mutate(changes = sub(" \\(.*", "", category) != sub(" \\(.*", "", primary)) |>
  group_by(row) |> summarise(min_est = min(estimate), max_est = max(estimate), share_meeting_confirm = mean(meets_confirm),
                             n_drops_changing_category = sum(changes), runs = n(), .groups = "drop")
write_csv(loco_cat, file.path(out, "t2_loco_categories.csv"))
write_csv(loco_sum, file.path(out, "t2_loco_summary.csv"))

lpm <- if (file.exists(file.path(out, "t2_lpm_raw.csv"))) read_csv(file.path(out, "t2_lpm_raw.csv"), show_col_types = FALSE) |>
  transmute(table = "T2", item = "10", scenario = "S10_LPM_WCR_fulldata", statistic = term, estimate = est, p = p_wcr, adj_p = NA, N, G) else NULL
pairs <- if (file.exists(file.path(out, "t2_pairs_bootstrap_draws.csv"))) {
  pb <- read_csv(file.path(out, "t2_pairs_bootstrap_draws.csv"), show_col_types = FALSE)
  ok <- pb |> filter(conv == 1)
  bind_rows(lapply(c("dAME", "lnRRR", "lnRRlit"), function(v) tibble(table = "T2", item = "12b", scenario = "S12b_pairs_cluster_bootstrap",
    statistic = v, estimate = mean(ok[[v]]), ci_lo = quantile(ok[[v]], ASTAR / 2, type = 7), ci_hi = quantile(ok[[v]], 1 - ASTAR / 2, type = 7),
    share_le0 = mean(ok[[v]] <= 0), N = nrow(ok), note = sprintf("B = %d, failed = %d; 99.17%% percentile interval", nrow(pb), nrow(pb) - nrow(ok)))))
} else NULL
s5raw <- read_csv(file.path(out, "t5_sensitivities_raw.csv"), show_col_types = FALSE)
for (v in c("verdict_H3OR", "verdict_H3P", "changes_H3OR", "changes_H3P")) if (!v %in% names(s5raw)) s5raw[[v]] <- NA
s5 <- s5raw |> transmute(table = "T5", item = as.character(item), scenario, statistic = "beta_mission", estimate = est, se, ci_lo, ci_hi, p, N, events, note,
                         verdict_H3OR, verdict_H3P, changes_H3OR, changes_H3P)
sens <- bind_rows(s2, lpm, pairs, s5)
write_csv(sens, file.path(out, "sensitivities.csv"))
loco5 <- s5 |> filter(item == "22")
cat("\nT5 LOCO: range", range(loco5$estimate), "share confirm H3-OR", mean(loco5$verdict_H3OR == "confirmed"), "H3-P", mean(loco5$verdict_H3P == "confirmed"),
    "changes H3-OR", sum(loco5$changes_H3OR), "H3-P", sum(loco5$changes_H3P), "\n")
print(loco_sum)
print(ver)
