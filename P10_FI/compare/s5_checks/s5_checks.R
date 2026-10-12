# P10_FI S5 verification checks (Claude auditor). Run from project root:
#   Rscript P10_FI/compare/s5_checks/s5_checks.R
# Reads the S2 snapshots (microdata, on D: only). Writes aggregate coefficients and counts only
# (no names, no individual rows) to P10_FI/compare/s5_checks/s5_results.csv.
suppressPackageStartupMessages({library(data.table); library(sandwich); library(lmtest); library(fwildclusterboot)})
source(file.path("tools", "paths.R"))
set.seed(20261011)
out <- list()
add <- function(scen, vint, spec, term, coef, se, p = NA, n = NA, note = "")
  out[[length(out) + 1]] <<- data.frame(scenario = scen, vintage = vint, spec = spec, term = term,
                                        coef = unname(coef), se = unname(se), p = unname(p), n = n, note = note)
iid <- function(m, tm) c(coef(m)[tm], sqrt(diag(vcov(m)))[tm], coeftest(m)[tm, 4])

for (v in c("v2018", "main")) {
  s <- readRDS(dpath("P10_FI", "repro_original", "_scratch", v, "snap_table3.rds"))
  a <- as.data.table(s$angreg)
  a[, pyear := paste(parishdum, year)]; angreg <- a  # model calls refer to angreg
  ms <- list(c1 = s$model5, c2 = s$model6, c3 = s$model7, c4 = s$model8)
  for (k in names(ms)) {
    m <- ms[[k]]; d <- a[as.integer(rownames(model.frame(m)))]
    for (tm in c("act", "inequality")) {
      r <- iid(m, tm); add("as_written_iid", v, k, tm, r[1], r[2], r[3], nobs(m))
      for (cl in c("parishdum", "year", "pyear")) {
        cv <- d[[cl]]
        if (anyNA(cv)) { add(paste0("cluster_", cl), v, k, tm, NA, NA, NA, nobs(m), paste0("skipped: ", sum(is.na(cv)), " obs without parish map")); next }
        V <- vcovCL(m, cluster = cv, type = "HC1"); se <- sqrt(V[tm, tm]); G <- length(unique(cv))
        add(paste0("cluster_", cl), v, k, tm, coef(m)[tm], se, 2 * pt(-abs(coef(m)[tm] / se), G - 1), nobs(m), paste0("CR1 G=", G, " t(G-1)"))
      }
    }
    if (k != "c1") for (cl in c("parishdum", "year")) for (tm in c("act", "inequality")) {
      bt <- tryCatch(boottest(m, param = tm, clustid = cl, B = 9999, type = "webb"),
                     error = function(e) { message("boottest ", v, k, cl, tm, ": ", conditionMessage(e)); NULL })
      if (!is.null(bt)) add(paste0("wcr_", cl), v, k, tm, coef(m)[tm], NA, pval(bt), nobs(m),
                            paste0("WCR Webb B=9999; 95% CI ", paste(signif(confint(bt), 3), collapse = " to ")))
    }
  }
  # Logit col 1 with month, parish and year as the table labels claim
  m1b <- update(s$model5, . ~ . + monthnumber + parishdum + year)
  for (tm in c("act", "inequality")) { r <- iid(m1b, tm); add("c1_logit_month_parish_year", v, "c1", tm, r[1], r[2], r[3], nobs(m1b)) }
  d1 <- a[as.integer(rownames(model.frame(m1b)))]
  V <- vcovCL(m1b, cluster = d1$parishdum, type = "HC1")
  for (tm in c("act", "inequality")) add("c1_logit_month_parish_year_parishCL", v, "c1", tm, coef(m1b)[tm], sqrt(V[tm, tm]), NA, nobs(m1b))
  m1c <- update(s$model5, . ~ . + year)
  for (tm in c("act", "inequality")) { r <- iid(m1c, tm); add("c1_logit_plus_year", v, "c1", tm, r[1], r[2], r[3], nobs(m1c)) }
  # Act identification under year fixed effects
  dd <- a[as.integer(rownames(model.frame(s$model6)))]
  mfe <- lm(update(formula(s$model6), . ~ . - year + factor(year)), data = dd)
  add("c2_yearFE", v, "c2", "act", coef(mfe)["act"], NA, NA, nobs(mfe),
      ifelse(is.na(coef(mfe)["act"]), "Act aliased with year FE: not identified", "Act estimated (lm dropped a year dummy instead)"))
  mfe2 <- lm(update(formula(s$model6), . ~ . - year - act + factor(year)), data = dd)
  V <- vcovCL(mfe2, cluster = dd$parishdum, type = "HC1")
  add("c2_yearFE", v, "c2", "inequality", coef(mfe2)["inequality"], sqrt(diag(vcov(mfe2)))["inequality"], coeftest(mfe2)["inequality", 4], nobs(mfe2), "iid")
  add("c2_yearFE_parishCL", v, "c2", "inequality", coef(mfe2)["inequality"], sqrt(V["inequality", "inequality"]), NA, nobs(mfe2), "parish CR1")
  # Trend form for Act
  dc <- copy(dd); dc[, yc := year - 1935]
  for (tr in c("quad", "cubic")) {
    f <- if (tr == "quad") . ~ . + I(yc^2) else . ~ . + I(yc^2) + I(yc^3)
    mt <- lm(update(formula(s$model6), f), data = dc)
    r <- iid(mt, "act"); add(paste0("c2_trend_", tr), v, "c2", "act", r[1], r[2], r[3], nobs(mt))
  }
  # Act flip decomposition
  m <- lm(formula(s$model6), data = dd[year > 1920])
  for (tm in c("act", "inequality")) { r <- iid(m, tm); add("c2_from1921", v, "c2", tm, r[1], r[2], r[3], nobs(m)) }
  V <- vcovCL(m, cluster = dd[year > 1920]$parishdum, type = "HC1")
  add("c2_from1921_parishCL", v, "c2", "act", coef(m)["act"], sqrt(V["act", "act"]), NA, nobs(m))
  m <- lm(formula(s$model6), data = dd[year > 1920 & year < 1961])
  r <- iid(m, "act"); add("c2_1921_1960", v, "c2", "act", r[1], r[2], r[3], nobs(m))
  d3 <- a[as.integer(rownames(model.frame(s$model7)))]
  m <- lm(formula(s$model6), data = d3)
  r <- iid(m, "act"); add("c2_formula_on_c3_sample", v, "c2", "act", r[1], r[2], r[3], nobs(m))
  add("note", v, "c2", "year_range", min(dd$year), max(dd$year), NA, nobs(s$model6), "coef=min year, se=max year")
  add("note", v, "c3", "year_range", min(d3$year), max(d3$year), NA, nobs(s$model7), "coef=min year, se=max year")
  # Segregation: drop small parish-years (HHI near 1 mechanically when few marriages)
  ny <- a[, .N, by = pyear]; dd2 <- merge(dd, ny, by = "pyear")
  m <- lm(formula(s$model6), data = dd2[N >= 10])
  r <- iid(m, "inequality"); add("c2_parishyear_N_ge10", v, "c2", "inequality", r[1], r[2], r[3], nobs(m))
  # Male age col 2
  r <- iid(s$model6, "mage"); add("maleage", v, "c2", "mage", r[1], r[2], r[3], nobs(s$model6))
}

# Unmapped parishes and pid 557 (main vintage; aggregate counts only)
t <- readRDS(dpath("P10_FI", "repro_original", "_scratch", "main", "snap_tables24.rds")); g <- as.data.table(t$ang)
g <- g[!is.na(interdum) & year > 1910 & year < 1965]
un <- c(555, 557, 565, 566, 568, 569)
for (p in un) add("unmapped_parish", "main", "-", paste0("pid_", p), g[pid == p, sum(interdum)], g[pid == p, .N], NA, g[pid == p, .N],
                  paste0("coef=interracial n, se=marriages n; years ", g[pid == p, min(year)], "-", g[pid == p, max(year)]))
f3 <- g[year >= 1955 & year <= 1962, .(all = 100 * mean(interdum), no557 = 100 * mean(interdum[pid != 557]), mapped = 100 * mean(interdum[!pid %in% un])), by = year][order(year)]
for (i in seq_len(nrow(f3))) add("fig3_share_main", "main", "-", paste0("y", f3$year[i]), f3$all[i], f3$no557[i], f3$mapped[i], NA, "coef=all %, se=excl pid557 %, p=mapped parishes only %")
add("sexmerge", "main", "-", "rows_added_by_all_TRUE", sum(is.na(t$ang$pid)), NA, NA, nrow(t$ang), "sex sheet: 120 rows = 40 years x 3 races, unique keys")

# Period shares (published vintage)
y8 <- as.data.table(readRDS(dpath("P10_FI", "repro_original", "_scratch", "v2018", "snap_end.rds"))$years)
for (pp in list(c(1911, 1919), c(1920, 1929), c(1930, 1938), c(1939, 1948), c(1949, 1963)))
  add("period_share_v2018", "v2018", "-", paste(pp, collapse = "-"), y8[year >= pp[1] & year <= pp[2], 100 * sum(m) / sum(m + s)], NA, NA, NA, "pooled interracial share %")

res <- rbindlist(out)
fwrite(res, file.path("P10_FI", "compare", "s5_checks", "s5_results.csv"))
print(res[, .(scenario, vintage, spec, term, coef = signif(coef, 4), se = signif(se, 3), p = signif(p, 3), n, note)], nrows = 500)
