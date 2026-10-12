# S5 internal-consistency checks on the published tables (no original code survives)
library(readr); library(dplyr)
d <- read_csv(here::here("P17_FvFH", "claims", "claims.csv"), show_col_types = FALSE)
v <- setNames(d$reported_value, d$claim_id)
g <- function(id) unname(v[id])
cat("== T2 slave weights: wf vs 1/pc and VOC inflation\n")
for (y in c(1702, 1723, 1757)) for (s in c("male_slave","female_slave","boy_slave","girl_slave","burgher_total","knecht")) {
  pc <- g(paste0("T2_pc_", y, "_", s)); wf <- g(paste0("T2_wf_", y, "_", s))
  cur <- g(paste0("T2_cur_", y, "_", s)); vdr <- g(paste0("T2_vdr_", y, "_", s))
  cat(y, s, "cur/vdr=", round(cur/vdr, 3), "pc=", pc, "1/pc=", round(1/pc, 3), "wf=", wf, "wf*pc=", round(wf*pc, 3), "\n") }
for (y in c(1702, 1723, 1757)) cat(y, "vdr voc_slaves=", g(paste0("T2_vdr_", y, "_voc_slaves")), "voc_burgher=", g(paste0("T2_vdr_", y, "_voc_burgher")),
  "slave_total_burgher=", g(paste0("T2_vdr_", y, "_slave_total_burgher")), "\n")
cat("== T4 represented pops vs T2/T3 (cur x wf)\n")
for (s in c("male_slave","female_slave","boy_slave","girl_slave","knecht")) for (y in c(1700, 1723, 1757)) {
  wy <- if (y == 1700) 1702 else y; tp <- paste0("T4_", y, "_", sub("_slave$", "_slaves", sub("knecht", "knechts", s)), "_pop")
  cat(y, s, "cur*wf=", round(g(paste0("T2_cur_", y, "_", s)) * g(paste0("T2_wf_", wy, "_", s))), "T4=", g(tp), "\n") }
cat("burghers: cur*wf ="); for (y in c(1700,1723,1757)) { wy <- if (y == 1700) 1702 else y
  cat(" ", y, round(g(paste0("T2_cur_", y, "_burgher_total")) * g(paste0("T2_wf_", wy, "_burgher_total")))) }
cat("\nT4 burgher pops (fb+nfb+fp+nfp):", sapply(c(1700,1723,1757), function(y) sum(g(paste0("T4_", y, c("_farming_burgher_pop","_nonfarming_burgher_pop","_farming_pachter_pop","_nonfarming_pachter_pop"))))), "\n")
cat("VOC: tepc*wf 1724/1756 =", round(g("T3_1724_tepc")*g("T3_1724_wf")), round(g("T3_1756_tepc")*g("T3_1756_wf")), "T4 =", g("T4_1723_voc_employee_pop"), g("T4_1757_voc_employee_pop"),
  "; 1699 tepc", g("T3_1699_tepc"), "wf", g("T3_1699_wf"), "T4 1700", g("T4_1700_voc_employee_pop"), "\n")
cat("== T6/T7: deflated 1700 vs 1700-prices 1700 (should be identical)\n")
for (t in c("T6", "T7")) { a <- d$claim_id[grepl(paste0("^", t, "_.*_defl_1700$"), d$claim_id)]
  b <- sub("_defl_1700", "_p1700_1700", a); dd <- g(a) - g(b); print(data.frame(a, defl = g(a), p1700 = g(b))[abs(dd) > 1e-9, ]) }
cat("== T7 between+within = 1\n")
w <- d$claim_id[grepl("^T7_btw_", d$claim_id)]; s <- g(w) + g(sub("btw", "wth", w)); print(range(s))
cat("== T8 adding-up and contrib = share*gini*rank/G; elast = contrib - share\n")
for (y in c(1700, 1723, 1757)) { src <- c("grain","cattle","wine","sheep","pigs","horses"); f <- function(k) g(paste0("T8_", y, "_", src, "_", k))
  G <- g(paste0("T8_", y, "_total_gini")); cat(y, "sum share", sum(f("share")), "sum contrib", sum(f("contrib")), "implied G", round(sum(f("share")*f("gini")*f("rank")), 3), "printed G", G,
    "\n  max|contrib - S*G*R/G|", round(max(abs(f("contrib") - f("share")*f("gini")*f("rank")/G)), 3), " max|elast-(contrib-share)|", round(max(abs(f("elast") - (f("contrib") - f("share")))), 3),
    "\n  contrib>share:", paste(src[f("contrib") > f("share")], collapse = ","), "\n") }
cat("== F2 shares sum\n"); for (y in c(1700,1723,1757)) for (k in c("income","population")) cat(y, k, sum(g(paste0("F2_", y, "_", k, "_", c("slave","farming","voc","other")))), "\n")
cat("== Text ranges vs T6\n"); for (s in c("wp_all","wp_xp","wp_xps","fb")) for (y in c(1700,1723,1757)) cat(s, y, range(g(paste0("T6_", s, c("_defl_","_p1700_","_p1757_"), y))), "\n")
cat("== T4 slave/knecht means vs text (40/20 per year; knecht 13/month = 156)\n"); print(v[grepl("T4_.*(slaves|knechts)_mean", names(v))])
