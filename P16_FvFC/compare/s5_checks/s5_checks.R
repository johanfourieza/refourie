# P16_FvFC S5 verification checks (Claude auditor, 11 October 2026).
# No original analysis code survives, so S5 audits (i) the S2 candidates, (ii) the pair-B gaps
# between the independent R rebuild and the published numbers, and (iii) data issues that bear on
# the headline claims. Reuses the S3 household file (read-only) and re-implements the S3 index/Gini
# functions verbatim so that every scenario differs from the S3 baseline in one choice only.
# Inputs : D:/.../P16_FvFC/repro_r/data/households.rds; P16_FvFC/claims/claims.csv;
#          P16_FvFC/repro_r/output/fig5c_core1_gini_ci.csv; Ginis.xls (converted xlsx, D: scratch)
# Outputs: P16_FvFC/compare/s5_checks/*.csv, P16_FvFC/compare/s5_effects.csv

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(purrr); library(readr); library(tidyxl)})
setwd(here::here()); source("tools/paths.R")
out <- "P16_FvFC/compare/s5_checks"
set.seed(20261011)

hh  <- readRDS(dpath("P16_FvFC", "repro_r", "data", "households.rds"))
cl  <- read_csv("P16_FvFC/claims/claims.csv", show_col_types = FALSE)
f5r <- read_csv("P16_FvFC/repro_r/output/fig5c_core1_gini_ci.csv", show_col_types = FALSE)
pub <- function(id) cl$reported_value[match(id, cl$claim_id)]
yrs <- sort(unique(hh$year))

# ---- S3 functions (copied verbatim from repro_r/02_analysis.R) ------------------------------
core1 <- c("SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE", "VK", "WINGST")
pca_weights <- function(df, vars) {
  X <- as.matrix(df[, vars]); sd <- apply(X, 2, sd)
  e <- eigen(cor(X), symmetric = TRUE); v <- e$vectors[, 1]; if (sum(v) < 0) v <- -v
  list(w = setNames(v, vars), sd = sd)
}
score <- function(df, p) as.vector(as.matrix(df[, names(p$w)]) %*% (p$w / p$sd))
gini_w <- function(y, w) {
  o <- order(y); y <- y[o]; w <- w[o]; W <- sum(w); mu <- sum(w * y) / W; C <- cumsum(w)
  sum(y * w * (2 * C - w + 1)) / (W^2 * mu) - (W + 1) / W
}
# Stata ineqdeco-style Gini with aweights (weights normalised; no integer-person correction)
gini_aw <- function(y, w) {
  o <- order(y); y <- y[o]; w <- w[o] / sum(w); mu <- sum(w * y); F <- cumsum(w) - w / 2
  2 * sum(w * y * F) / mu - 1
}
gini_series <- function(df, idx, size = "hhsize", incl_slaves = FALSE, gfun = gini_w) {
  df |> mutate(pc = idx / .data[[size]], wt = .data[[size]]) |> group_by(year) |>
    group_modify(\(d, k) { y <- d$pc; w <- d$wt
      if (incl_slaves) { ns <- sum(d$slaves); y <- c(y, rep(0, ns)); w <- c(w, rep(1, ns)) }
      tibble(gini = gfun(y, w), n = nrow(d)) }) |> ungroup()
}
far <- hh |> filter(farmer)
p_far <- pca_weights(far, core1); p_all <- pca_weights(hh, core1)
base5c <- gini_series(far, score(far, p_far))
f4i <- gini_series(hh, score(hh, p_all), incl_slaves = TRUE)
f4e <- gini_series(hh, score(hh, p_all))
stopifnot(abs(base5c$gini[base5c$year == 1709] - 0.6471974) < 1e-6)   # equals S3 baseline

pubF5c <- tibble(year = yrs, pub = pub(paste0("F5c_", yrs)),
                 lo = cl$reported_ci_lo[match(paste0("F5c_", yrs), cl$claim_id)],
                 hi = cl$reported_ci_hi[match(paste0("F5c_", yrs), cl$claim_id)])
fit <- \(s) { z <- left_join(s, pubF5c, by = "year")
  c(mad = mean(abs(z$gini - z$pub)), max = max(abs(z$gini - z$pub)), n_within_005 = sum(abs(z$gini - z$pub) <= 0.005),
    g1663 = z$gini[z$year == 1663], g1709 = z$gini[z$year == 1709], g1757 = z$gini[z$year == 1757]) }

# =============================================================================================
# 1. District coverage by year (DS) -- composition of each cross-section
# =============================================================================================
cov <- hh |> count(year, DS) |> pivot_wider(names_from = DS, values_from = n, values_fill = 0, names_prefix = "DS")
write_csv(cov, file.path(out, "district_coverage.csv"))

# Gini of core 1 (farmers, pooled weights) within district 1 (Cape) only and districts 1-3 only
c1f <- score(far, p_far)
by_ds <- bind_rows(
  gini_series(far |> mutate(i = c1f) |> filter(DS == 1), (far |> mutate(i = c1f) |> filter(DS == 1))$i) |> mutate(sample = "DS1 (Cape) only"),
  gini_series(far |> mutate(i = c1f) |> filter(DS %in% 1:3), (far |> mutate(i = c1f) |> filter(DS %in% 1:3))$i) |> mutate(sample = "DS1-3 only"),
  base5c |> mutate(sample = "all (S3 baseline)"))
# bootstrap SE (fixed weights) for the restricted series, B = 499
boot_se <- function(d) { pc <- d$i / d$hhsize
  sd(replicate(499, { j <- sample.int(nrow(d), replace = TRUE); gini_w(pc[j], d$hhsize[j]) })) }
se_ds <- bind_rows(lapply(c("DS1 (Cape) only", "DS1-3 only"), \(s) {
  d0 <- far |> mutate(i = c1f) |> filter(if (s == "DS1 (Cape) only") DS == 1 else DS %in% 1:3)
  d0 |> group_by(year) |> group_modify(\(d, k) tibble(se = boot_se(d))) |> ungroup() |> mutate(sample = s) }))
by_ds <- by_ds |> left_join(bind_rows(se_ds, f5r |> transmute(year, se = se_boot, sample = "all (S3 baseline)")),
                            by = c("year", "sample"))
write_csv(by_ds, file.path(out, "gini_by_district_sample.csv"))

# =============================================================================================
# 2. 1723 multi-record holders (N = 1681, matches appendix Table 3, so the paper used them)
# =============================================================================================
key <- paste(hh$year, hh$Van, hh$Naam)
dup <- hh |> mutate(k = key) |> group_by(year) |>
  summarise(n = n(), name_dup_rows = sum(duplicated(k)), share = name_dup_rows / n, .groups = "drop")
write_csv(dup, file.path(out, "name_duplicates_by_year.csv"))
# Scenario: aggregate same-name records within 1723 into one household (sum assets, max hhsize)
agg23 <- function(df) {
  a <- df |> filter(year == 1723) |> group_by(year, Van, Naam) |>
    summarise(across(c(SM, SV, SS, SD, PD, BSTE, SKPE, VK, WINGST, slaves), sum), hhsize = max(hhsize),
              DS = first(DS), .groups = "drop") |> mutate(farmer = (PD + BSTE + SKPE + VK + WINGST) > 0)
  bind_rows(df |> filter(year != 1723), a)
}

# =============================================================================================
# 3. Pair-B gap explorations: scenarios that each change one choice relative to S3
# =============================================================================================
scen <- list()
add <- function(name, s5c, w = NULL) scen[[name]] <<- list(s5c = s5c, w = w)
add("S3 baseline", base5c, p_far$w)
add("whole-sample PCA weights", gini_series(far, score(far, p_all)), p_all$w)
add("hhsize incl knegte", gini_series(far, c1f, size = "hhsize_k"), p_far$w)
add("Gini aweight (ineqdeco-style)", gini_series(far, c1f, gfun = gini_aw), p_far$w)
add("unweighted Gini, per capita", gini_series(far |> mutate(one = 1), c1f / far$hhsize, size = "one"), p_far$w)
far23 <- agg23(hh) |> filter(farmer); p23 <- pca_weights(far23, core1)
add("1723 same-name records merged", gini_series(far23, score(far23, p23)), p23$w)
farDS <- far |> filter(DS %in% 1:3); pDS <- pca_weights(farDS, core1)
add("drop DS4/DS5 rows", gini_series(farDS, score(farDS, pDS)), pDS$w)
# vines: winsorise at the 99.9th pct (a handful of very large WINGST counts drive their SD/correlation)
q <- quantile(far$WINGST[far$WINGST > 0], 0.999)
farW <- far |> mutate(WINGST = pmin(WINGST, q)); pW <- pca_weights(farW, core1)
add("vines winsorised p99.9", gini_series(farW, score(farW, pW)), pW$w)
# PCA estimated on farmers with 1705 included would need the raw file; 1705 lacks weapons only,
# and core 1 has no weapons, so 1705 could have entered the pooled PCA.
raw <- readxl::read_excel(dpath("P16_FvFC", "original", "Wealth inequality", "Time 1663 - 1757 ----  EDITED.xls"),
                          sheet = "Data", col_types = "text")
num <- \(x) { v <- suppressWarnings(as.numeric(x)); ifelse(is.na(v), 0, v) }
r05 <- raw |> filter(Jaar == "1705") |> transmute(year = 1705L, SM = num(SM), SV = num(SV), SS = num(SS), SD = num(SD),
  PD = num(PD), BSTE = num(BSTE), SKPE = num(SKPE), VK = num(VK), WINGST = num(WINGST), WYN = num(WYN),
  G = num(KGS) + num(KGW) + num(RGS) + num(RGW) + num(GGS) + num(GGW)) |>
  filter(PD + BSTE + SKPE + VK + WINGST + WYN + G > 0)
p05 <- pca_weights(bind_rows(far[, core1], r05[, core1]), core1)
add("PCA incl 1705 farmers", gini_series(far, score(far, p05)), p05$w)

t1pub <- pub(paste0("T1_r", 1:9, "_c1"))
scen_tab <- imap_dfr(scen, \(s, nm) { f <- fit(s$s5c)
  tibble(scenario = nm, mad_F5c = f["mad"], max_F5c = f["max"], n_within_005 = f["n_within_005"],
         g1663 = f["g1663"], g1709 = f["g1709"], g1757 = f["g1757"],
         vine_w = s$w["WINGST"], maxabs_T1w = max(abs(s$w - t1pub))) })
write_csv(scen_tab, file.path(out, "pairB_gap_scenarios.csv"))

# 1663 in detail (N = 24 farmers): leave-one-out Gini, to show how fragile the point estimate is
d63 <- far |> mutate(i = c1f) |> filter(year == 1663)
loo <- sapply(seq_len(nrow(d63)), \(j) gini_w(d63$i[-j] / d63$hhsize[-j], d63$hhsize[-j]))
write_csv(tibble(drop_row = seq_len(nrow(d63)), Van = d63$Van, Naam = d63$Naam, hhsize = d63$hhsize,
                 slaves = d63$slaves, gini_loo = loo), file.path(out, "f5c_1663_leave_one_out.csv"))

# =============================================================================================
# 4. Pigs: text p.13 "less than 1% of the sample registers positive values"
# =============================================================================================
pigs <- tibble(sample = c("all households", "farmers", "all, incl 1705"),
               pct_pigs_pos = c(100 * mean(hh$VK > 0), 100 * mean(far$VK > 0),
                                100 * mean(c(hh$VK, num(raw$VK[raw$Jaar == "1705"])) > 0)),
               pct_pig_obs_of_all_cells = NA_real_)
pigs_y <- hh |> group_by(year) |> summarise(pct_pigs_pos = 100 * mean(VK > 0), .groups = "drop")
write_csv(bind_rows(pigs, pigs_y |> mutate(sample = paste("year", year)) |> select(sample, pct_pigs_pos)),
          file.path(out, "pigs_share.csv"))

# =============================================================================================
# 5. Significance of the headline changes: fn-14 rule vs a two-sample test on the difference
# =============================================================================================
se_pub <- (pubF5c$hi - pubF5c$lo) / (2 * 1.96)
pubF5c$se <- se_pub
tst <- function(a, b, src) {
  if (src == "published") { A <- pubF5c[pubF5c$year == a, ]; B <- pubF5c[pubF5c$year == b, ]; ga <- A$pub; gb <- B$pub; sa <- A$se; sb <- B$se }
  else { A <- f5r[f5r$year == a, ]; B <- f5r[f5r$year == b, ]; ga <- A$gini; gb <- B$gini
    sa <- if (src == "rebuild_fixedW") A$se_boot else A$se_boot_pca; sb <- if (src == "rebuild_fixedW") B$se_boot else B$se_boot_pca }
  z <- (ga - gb) / sqrt(sa^2 + sb^2)
  tibble(year = a, vs = b, source = src, gini = ga, gini_vs = gb, diff = ga - gb,
         fn14_outside_prev_CI = abs(ga - gb) > 1.96 * sb, z = z, p_two_sided = 2 * pnorm(-abs(z)))
}
pairs <- list(c(1709, 1663), c(1709, 1670), c(1709, 1678), c(1709, 1682), c(1738, 1709), c(1757, 1738), c(1716, 1712))
sig <- bind_rows(lapply(c("published", "rebuild_fixedW", "rebuild_pcaW"), \(s) bind_rows(lapply(pairs, \(p) tst(p[1], p[2], s)))))
# district-consistent versions (DS1-3 only) of the two key comparisons
dsx <- by_ds |> filter(sample == "DS1-3 only")
for (p in list(c(1709, 1682), c(1757, 1738), c(1738, 1709))) {
  A <- dsx[dsx$year == p[1], ]; B <- dsx[dsx$year == p[2], ]; z <- (A$gini - B$gini) / sqrt(A$se^2 + B$se^2)
  sig <- bind_rows(sig, tibble(year = p[1], vs = p[2], source = "rebuild_DS1-3", gini = A$gini, gini_vs = B$gini,
    diff = A$gini - B$gini, fn14_outside_prev_CI = abs(A$gini - B$gini) > 1.96 * B$se, z = z, p_two_sided = 2 * pnorm(-abs(z))))
}
write_csv(sig, file.path(out, "headline_significance.csv"))

# =============================================================================================
# 6. Slave gap (text p.23 "roughly 0.2 Gini points over the period"; p.29 "above 0.70")
# =============================================================================================
gap <- tibble(year = yrs, pub_incl = pub(paste0("F4_incl_", yrs)), pub_excl = pub(paste0("F4_excl_", yrs)),
              reb_incl = f4i$gini, reb_excl = f4e$gini) |>
  mutate(pub_gap = pub_incl - pub_excl, reb_gap = reb_incl - reb_excl)
write_csv(gap, file.path(out, "slave_gap_by_year.csv"))
gap_sum <- tibble(stat = c("mean gap", "min gap", "max gap", "mean gap 1663-1723", "mean gap 1731-1757",
                           "years gap >= 0.15", "min Gini incl slaves", "years incl < 0.70"),
  published_digitised = c(mean(gap$pub_gap), min(gap$pub_gap), max(gap$pub_gap), mean(gap$pub_gap[gap$year <= 1723]),
                          mean(gap$pub_gap[gap$year >= 1731]), sum(gap$pub_gap >= 0.15), min(gap$pub_incl), sum(gap$pub_incl < 0.70)),
  rebuild = c(mean(gap$reb_gap), min(gap$reb_gap), max(gap$reb_gap), mean(gap$reb_gap[gap$year <= 1723]),
              mean(gap$reb_gap[gap$year >= 1731]), sum(gap$reb_gap >= 0.15), min(gap$reb_incl), sum(gap$reb_incl < 0.70)))
# linear trend in the gap (widening?) and slaves per settler
tr <- coef(summary(lm(pub_gap ~ year, gap)))["year", ]
gap_sum <- bind_rows(gap_sum, tibble(stat = c("trend in gap per decade (pub)", "trend t (pub)"),
  published_digitised = c(10 * tr[1], tr[3]), rebuild = c(10 * coef(lm(reb_gap ~ year, gap))[2], NA)))
write_csv(gap_sum, file.path(out, "slave_gap_summary.csv"))

# =============================================================================================
# 7. S2-3: does the Ginis.xls Cape series match ANY rebuilt series (index x weights x sample x measure)?
# =============================================================================================
x <- xlsx_cells(dpath("P16_FvFC", "repro_original", "_scratch", "Ginis_conv.xlsx"), sheets = "Sheet1")
xs <- tibble(year = x$numeric[x$col == 5 & x$row %in% 3:22], xls = x$numeric[x$col == 7 & x$row %in% 3:22])
ser <- read_csv("P16_FvFC/repro_r/output/inequality_series.csv", show_col_types = FALSE) |>
  pivot_longer(c(gini, theil), names_to = "measure")
add_ser <- bind_rows(scen_tab |> select(scenario) |> mutate(dummy = 1) |> select(-dummy) |>
  (\(z) bind_rows(lapply(z$scenario, \(s) scen[[s]]$s5c |> transmute(year, value = gini, index = "Core (1)", weights = s,
                                                              sample = "farmers", slaves = "excl", measure = "gini"))))())
cand <- bind_rows(ser |> select(year, value, index, weights, sample, slaves, measure), add_ser) |>
  inner_join(xs, by = "year") |>
  group_by(index, weights, sample, slaves, measure) |>
  summarise(n = n(), r = cor(value, xls), mad = mean(abs(value - xls)), max = max(abs(value - xls)),
            within_01 = sum(abs(value - xls) <= 0.01), .groups = "drop") |> arrange(mad)
write_csv(cand, file.path(out, "ginis_xls_vs_all_rebuilt_series.csv"))

# =============================================================================================
# 8. s5_effects.csv: effect of each verified issue on the headline claims
# =============================================================================================
hid <- c("text_p26_gini_initial", "text_p26_gini_1709", "text_p26_gini_1757", "text_p23_slave_gap")
pubv <- setNames(pub(hid), hid)
val <- function(s5c, gp = NULL) c(text_p26_gini_initial = s5c$gini[s5c$year == 1663], text_p26_gini_1709 = s5c$gini[s5c$year == 1709],
                                   text_p26_gini_1757 = s5c$gini[s5c$year == 1757], text_p23_slave_gap = if (is.null(gp)) NA else gp)
eff <- list()
e <- function(scn, v, note) eff[[length(eff) + 1]] <<- tibble(scenario = scn, claim_id = hid, published = pubv,
  original_code = NA_real_, scenario_value = unname(v[hid]), note = note)
e("S3 rebuild (baseline)", val(base5c, mean(gap$reb_gap)), "Independent R rebuild, D1-D12; original code unavailable (S1)")
e("published figure, digitised", c(text_p26_gini_initial = pub("F5c_1663"), text_p26_gini_1709 = pub("F5c_1709"),
  text_p26_gini_1757 = pub("F5c_1757"), text_p23_slave_gap = mean(gap$pub_gap)),
  "Digitised Fig 5c / Fig 4 (gap = mean over 20 years); shows the text-vs-figure rounding and the 0.2 vs 0.14 gap")
for (nm in setdiff(names(scen), "S3 baseline")) e(nm, val(scen[[nm]]$s5c), paste("Pair-B gap scenario; vine weight", round(scen[[nm]]$w["WINGST"], 4)))
dsv <- \(s) { z <- by_ds |> filter(sample == s); c(text_p26_gini_initial = z$gini[z$year == 1663], text_p26_gini_1709 = z$gini[z$year == 1709],
                                                  text_p26_gini_1757 = z$gini[z$year == 1757], text_p23_slave_gap = NA) }
e("districts 1-3 only (consistent coverage)", dsv("DS1-3 only"), "Drops DS4 (1723, 1752, 1757) and DS5 (1688); weights unchanged")
e("Cape district (DS1) only", dsv("DS1 (Cape) only"), "Single-district series; the initial years are Cape-only in the data")
e("slave gap: farmers' slaves only", c(text_p23_slave_gap = mean(gini_series(hh |> mutate(slaves = ifelse(farmer, slaves, 0)),
  score(hh, p_all), incl_slaves = TRUE)$gini - f4e$gini)), "Fig 4 variant: only farmers' slaves added as zero households")
eff <- bind_rows(eff) |> filter(!is.na(scenario_value))
write_csv(eff, "P16_FvFC/compare/s5_effects.csv")

print(cov, n = 25); print(scen_tab, width = 200); print(sig, n = 40, width = 200); print(gap_sum)
print(head(cand, 8), width = 200); print(pigs); print(by_ds |> filter(year %in% c(1663, 1682, 1709, 1716, 1738, 1752, 1757)) |> arrange(year), n = 30)
cat("1663 LOO range:", range(loo), "\n")
