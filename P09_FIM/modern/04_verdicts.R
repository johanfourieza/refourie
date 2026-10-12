# P09_FIM S6 04_verdicts.R. Card §8A verdict rows (applied mechanically) and §8B recruit-pattern findings
# (separate block; they decide no verdict). Reads primary_objects.rds and the reproduction check.
source("./P09_FIM/modern/00_common.R")
PO <- readRDS(file.path(OUT, "primary_objects.rds"))
REPRO_OK <- read_csv(file.path(OUT, "check_sample.csv"), show_col_types = FALSE)$value[1] == 1
m <- PO$m; fD <- PO$fD
f3 <- function(x) sprintf("%.3f", x)

# Single-step sup-t adjusted p for Family D (reported; the decision uses the intervals)
v <- m$s2 / m$n; j <- c(1, 2, 3, 5, 6); V <- matrix(v[4], 5, 5); diag(V) <- v[j] + v[4]; R <- cov2cor(V)
adjp <- sapply(abs(fD$est / fD$se), function(t) { set.seed(SEED)
  1 - pmvnorm(lower = rep(-t, 5), upper = rep(t, 5), corr = R, algorithm = GenzBretz(maxpts = 250000, abseps = 1e-6))[1] })

# T2-c1 / T2-c4: A8 band, closed
band_rule <- function(X, lo, hi) {
  if (!REPRO_OK || !is.finite(X)) return(c("not-testable", "0"))
  if (X >= lo && X <= hi) return(c("confirmed", "1"))
  if (X < lo) return(c("qualified (mean below the stated value)", "2"))
  c("qualified (mean above the stated value)", "3")
}
v1 <- band_rule(m$m[1], 157.824, 192.896); v4 <- band_rule(m$m[4], 156.303, 191.037)
# T2-dec
e1 <- fD[fD$contrast == "e1", ]
vdec <- if (!REPRO_OK || PO$fail_D) c("not-testable", "0") else if (e1$lo > 0) c("confirmed", "1") else
  if (e1$est > 0) c("qualified (inference-fragile)", "2") else c("weakened", "3")
# T2-min
vmin <- if (!REPRO_OK || PO$fail_D || any(!is.finite(fD$lo))) c("not-testable", "0") else if (all(fD$lo > 0)) c("confirmed", "1") else
  if (all(fD$est > 0)) c("qualified (inference-fragile)", "2") else c("weakened", "3")
fail_min <- fD$contrast[fD$lo <= 0]

verdict <- tibble(
  claim = c("T2-c1", "T2-c4", "T2-dec", "T2-min", "H3-65", "H3-15", "H3-dec", "H3-rec", "H3-15-all", "F8-gap", "F8-all"),
  estimate = c(f3(m$m[1]), f3(m$m[4]), f3(e1$est), paste0("min e_j = ", f3(min(fD$est)), " (", fD$contrast[which.min(fD$est)], ")"),
               rep("", 7)),
  interval = c("none (no inference; card §4A)", "none (no inference; card §4A)",
               sprintf("[%s, %s] simultaneous 95%% (Family D, c_D = %.4f)", f3(e1$lo), f3(e1$hi), e1$c_D),
               paste(sprintf("%s [%s, %s]", fD$contrast, f3(fD$lo), f3(fD$hi)), collapse = "; "),
               rep("", 7)),
  test_p = c("", "", sprintf("sup-t adjusted %.3g (raw %.3g)", adjp[1], e1$p_unadj),
             sprintf("max sup-t adjusted %.3g (%s); raw max %.3g", max(adjp), fD$contrast[which.max(adjp)], max(fD$p_unadj)),
             rep("", 7)),
  threshold_or_band = c("[157.824, 192.896] (A8 +/-10%, closed)", "[156.303, 191.037] (A8 +/-10%, closed)",
                        "simultaneous CI of e1 entirely > 0 (A8 comparative; A4b ladder)",
                        "every simultaneous CI of e_j entirely > 0 (conjunction; A4b ladder)",
                        rep("none: verdict fixed by card §0", 4), rep("none", 3)),
  verdict = c(v1[1], v4[1], vdec[1], vmin[1], rep("different-estimand", 4), rep("not-testable", 3)),
  rule = c(paste("§8A T2-c1 rule", v1[2]), paste("§8A T2-c4 rule", v4[2]), paste("§8A T2-dec rule", vdec[2]),
           paste0("§8A T2-min rule ", vmin[2], if (length(fail_min)) paste0(" (CI includes 0: ", paste(fail_min, collapse = ", "), ")") else ""),
           rep("§8A; §0 (unconditional)", 4), rep("§8A; §1 (not-testable)", 3)))
write_csv(verdict, file.path(OUT, "verdict.csv"))

# §8B recruit-pattern findings (separate block)
ft <- PO$ft; fnd <- PO$fnd
g <- function(x) ft[ft$contrast == x, ]
fmt_ci <- function(r) sprintf("[%s, %s]", f3(r$lo), f3(r$hi))
dd <- ft[ft$contrast %in% c("d1", "d2", "d3"), ]
rec <- tibble(
  row = c("R-65", "R-15", "R-dec", "R-rec"), beside = c("H3-65", "H3-15", "H3-dec", "H3-rec"),
  estimate = c(f3(g("b65")$est), f3(g("b15")$est), paste(sprintf("%s %s", dd$contrast, f3(dd$est)), collapse = "; "), f3(g("r")$est)),
  interval = c(fmt_ci(g("b65")), fmt_ci(g("b15")), paste(sprintf("%s %s", dd$contrast, fmt_ci(dd)), collapse = "; "), fmt_ci(g("r"))),
  interval_type = sprintf("simultaneous 95%% (Family T, c_T = %.4f, MC se %.5f, rank %d)", ft$c_T[1], ft$c_T_mcse[1], ft$rank[1]),
  test_p = c(sprintf("raw %.3g", g("b65")$p_unadj), sprintf("raw %.3g", g("b15")$p_unadj),
             sprintf("intersection-union one-sided %.3g", PO$iu_p), sprintf("raw %.3g", g("r")$p_unadj)),
  threshold = c("CI > 0 and b >= 0.514; null band (-0.514, 0.514); plausibility |b| > 1.542",
                "CI > 0 and b >= 0.7755; null band (-0.7755, 0.7755); plausibility |b| > 2.3265",
                "simultaneous CIs of d1, d2, d3 all > 0", "simultaneous CI of r > 0"),
  finding = fnd$finding, rule = paste("§8B rule", fnd$rule),
  plausibility_flag = c(abs(g("b65")$est) > 1.542, abs(g("b15")$est) > 2.3265, NA, NA),
  boundary_sensitive = c(any(unlist(PO$bflag[PO$bflag$contrast == "b65", c("near0", "nearnull")])),
                         any(unlist(PO$bflag[PO$bflag$contrast == "b15", c("near0", "nearnull")])),
                         any(PO$bflag$near0[PO$bflag$contrast %in% c("d1", "d2", "d3")]),
                         PO$bflag$near0[PO$bflag$contrast == "r"]),
  label = "recruit-pattern finding on the surviving vintage; decides no verdict")
write_csv(rec, file.path(OUT, "findings_recruit_pattern.csv"))

cov <- tibble(item = c("verdict rows", "assessed (T2)", "not-testable", "different-estimand", "weakest assessed T2 verdict"),
              value = c(nrow(verdict), sum(grepl("^T2", verdict$claim) & verdict$verdict != "not-testable"),
                        sum(verdict$verdict == "not-testable"), sum(verdict$verdict == "different-estimand"),
                        { ord <- c("overturned", "weakened", "qualified", "confirmed")
                          vv <- verdict$verdict[grepl("^T2", verdict$claim)]; k <- sapply(vv, function(x) which(startsWith(x, ord)))
                          vv[which.min(k)] }))
write_csv(cov, file.path(OUT, "verdict_summary.csv"))
print(verdict %>% select(claim, estimate, verdict, rule)); print(rec %>% select(row, estimate, interval, finding))
