# S5 effects: group-level (between-group) Gini from the printed Figure 2 shares (pacht income excluded),
# used to size (a) the undocumented x1.3 factor on slave incomes (text 40/20 vs T4 52/26) and
# (b) the 1757 burgher sample-count gap (rebuild weight 1.0038 vs published 0.993). Approximate: within-group terms held fixed.
library(readr); library(dplyr)
d <- read_csv(here::here("P17_FvFH", "claims", "claims.csv"), show_col_types = FALSE)
v <- setNames(d$reported_value, d$claim_id); g <- function(id) unname(v[id])
gb <- function(p, s) { p <- p / sum(p); s <- s / sum(s); mu <- s / p; sum(outer(p, p) * abs(outer(mu, mu, "-"))) / 2 }
grp <- c("slave", "farming", "voc", "other")
out <- list()
for (y in c(1700, 1757)) {
  p <- g(paste0("F2_", y, "_population_", grp)); s <- g(paste0("F2_", y, "_income_", grp))
  b0 <- gb(p, s)
  s1 <- s; s1[1] <- s[1] / 1.3; b1 <- gb(p, s1)                      # slaves at text values 40/20
  r <- 1.0037650602 / 0.993; p2 <- p; p2[c(2, 4)] <- p[c(2, 4)] * r; s2 <- s; s2[c(2, 4)] <- s[c(2, 4)] * r; b2 <- gb(p2, s2)  # burgher weight per surviving .dta
  cat(y, "between-group Gini base", round(b0, 3), "| slave/1.3", round(b1, 3), "d=", round(b1 - b0, 3), "| burgher wf from .dta", round(b2, 3), "d=", round(b2 - b0, 4), "\n")
  out[[as.character(y)]] <- c(b0 = b0, d1 = b1 - b0, d2 = b2 - b0) }
dl <- unname(out[["1700"]]["d1"]); d7 <- unname(out[["1757"]]["d2"])
e <- tribble(~scenario, ~claim_id, ~published, ~original_code, ~scenario_value, ~note,
  "S2 rerun", "T6_wp_all_defl_1700", 0.792, NA, NA, "no original code survives (S2 not-attempted); every headline claim is unavailable in pairs A and B",
  "slave income at text values 40/20 (T4 prints 52/26), between-group approx.", "T6_wp_xp_defl_1700", 0.569, NA, round(0.569 + dl, 3), sprintf("F2-based between-group Gini shift %+.3f; within-group terms held fixed", dl),
  "slave income at text values 40/20 (T4 prints 52/26), between-group approx.", "T6_wp_xp_p1757_1700", 0.543, NA, round(0.543 + dl, 3), sprintf("same 1700 shift %+.3f applied", dl),
  "1757 burgher count from surviving .dta (5312 vs 5367), between-group approx.", "T6_fb_defl_1757", 0.689, NA, 0.689, "uniform reweighting within farming burghers leaves their Gini unchanged",
  "1757 burgher count from surviving .dta (5312 vs 5367), between-group approx.", "T6_wp_all_defl_1700", 0.792, NA, 0.792, sprintf("1700 counts match the .dta exactly; 1757 whole-population between-group shift %+.4f", d7),
  "lower-bound comparison with T9 European Ginis", "T6_wp_xp_p1757_1700", 0.543, NA, 0.543, "below Holland 1561 (0.560), France 1788 (0.559), Netherlands 1808 (0.570): 'worse than the European countries (except Holland 1732)' fails at the lower bound",
  "T8 elasticities by year", "T8_1757_wine_contrib", 0.519, NA, 0.519, "wine elasticity exceeds grain only in 1757 (0.078 vs 0.043); 1700 sheep 0.010 > wine 0.008 > grain 0.007; 1723 grain 0.036 > wine 0.002",
  "ex-pacht trend 1700->1757, deflated series", "T6_wp_xp_defl_1700", 0.569, NA, 0.559, "1757 deflated Gini 0.559 < 0.569: 'slight increase' holds in 2 of 3 price series",
  "1700 identity: deflated = 1700 prices", "T6_wp_all_p1757_1700", 0.837, NA, 0.837, "identity holds for the headline rows; fails for T6 wp_xps (0.475 vs 0.477) and 7 T7 rows")
write_csv(e, here::here("P17_FvFH", "compare", "s5_effects.csv"), na = "")
