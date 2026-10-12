# P30_STB24 S6 step 7: supplementary analyses of card s5 (reported, never verdict-setting) and secondary outputs S-a, S-c.
# s5A (corrections off one at a time), s5B items 2 and 5, s5C items 1-15, s5D (K5 evidence), s5F (aggregate conflicts).
# s5B items 1, 3, 4, 6 and S-b, S-d are produced in 03-06; s5E in 02.
source("P30_STB24/modern/00_common.R")
library(sandwich)
t0 <- Sys.time()
d <- readRDS(SCR("central.rds"))
E_YRS <- 1700:1709; L_YRS <- 1790:1799

# ---- point statistics of one build ----------------------------------------------------------------
point_stats <- function(d, gini_f = gini_def, E = E_YRS, L = L_YRS, base = 1795, pre = c(-Inf, 1779), post = c(1790, Inf),
                        h3_years = c(-Inf, Inf)) {
  m <- year_means(d); g <- year_ginis(d, f = gini_f)
  r <- sapply(ASSETS, function(a) log(mean(m[year %in% L & is.finite(get(a)), get(a)]) / mean(m[year %in% E & is.finite(get(a)), get(a)])))
  gl <- melt(g, id.vars = "year", variable.name = "asset", value.name = "G")[is.finite(G) & year >= h3_years[1] & year <= h3_years[2]]
  s <- gl[, .(s = mean(G >= 0.4)), by = asset]
  w <- g[is.finite(wine)]
  gp <- function(rg) mean(w[year >= rg[1] & year <= rg[2], wine])
  peak <- gp(c(1780, 1789))
  c(setNames(r, paste0("r_", ASSETS)), setNames(s$s, paste0("s_", s$asset)), lox_min = min(gl$G),
    lox_p10 = quantile(gl$G, .1, names = FALSE), s_pooled = mean(gl$G >= 0.4),
    D_rise = peak - gp(pre), D_fall = peak - gp(post),
    I_anchor = m[year == 1702, wine] / m[year == base, wine])
}
H34 <- c(paste0("s_", ASSETS), "lox_min", "lox_p10", "s_pooled", "D_rise", "D_fall")
tidy <- function(x, item, scen, label) data.table(item = item, scenario = scen, label = label, quantity = names(x), value = unname(x))

# ---- s5A: each correction switched off in turn (point estimates) ----------------------------------
central <- point_stats(d)
A <- rbind(tidy(central, "central", "K1-K5 on", "central"),
  tidy(point_stats(build(K1 = FALSE)), "5A", "K1 off (types as guessed)", "same estimand, correction off"),
  tidy(point_stats(d, base = 1780), "5A", "K2 off (base 1780)", "same estimand, correction off"),
  tidy(point_stats(build(K3 = FALSE)), "5A", "K3 off (no horse_riding)", "same estimand, correction off"),
  tidy(point_stats(build(K4 = FALSE)), "5A", "K4 off (rowSums zeros)", "same estimand, correction off"),
  tidy(point_stats(build(K5 = FALSE)), "5A", "K5 off (no wine cap)", "same estimand, correction off"))

# ---- s5C: changed measurement, estimand or population (point estimates; labelled) ----------------
m <- year_means(d); g <- year_ginis(d)
C <- rbind(
  tidy(point_stats(build(K5 = FALSE)), "5C1", "wine cap none", "changed measurement"),
  tidy(point_stats(build(cap = 500)), "5C1", "wine cap 500", "changed measurement"),
  tidy(point_stats(d, E = 1700:1719, L = 1780:1799)[1:6], "5C2", "H2 windows 1700-19 vs 1780-99", "changed estimand"),
  tidy(point_stats(d, E = 1700:1749, L = 1750:1799)[1:6], "5C2", "H2 windows 1700-49 vs 1750-99", "changed estimand"),
  tidy(sapply(ASSETS, function(a) log(mean(d[year %in% L_YRS, get(a)], na.rm = TRUE) / mean(d[year %in% E_YRS, get(a)], na.rm = TRUE))),
       "5C3", "H2 pooled row-level means", "changed estimand"),
  tidy(point_stats(build(sgp = TRUE)), "5C4", "sheep_goats_pigs in sheep", "changed measurement"),
  tidy(point_stats(d, gini_f = function(x) gini_def(x[!is.na(x) & x > 0]))[H34], "5C6", "Ginis over positive holders", "changed population"),
  tidy(point_stats(d, h3_years = c(-Inf, 1803))[H34[1:9]], "5C7", "H3 years before 1804 only", "changed period"),
  tidy(point_stats(build(zerofill = FALSE)), "5C8", "no zero-fill", "changed missing-data rule and population"),
  tidy(point_stats(d, gini_f = function(x) { x <- x[!is.na(x)]; n <- length(x); gini_def(x) * n / (n - 1) })[H34], "5C10",
       "Gini x n/(n-1)", "changed estimator"))
C <- rbind(C, tidy(central["s_pooled"], "5C9", "H3 pooled share over all asset-years", "different reading of 'across all assets'"))
# 5C5 log-linear trend 1700-1799 and S-a Gini slopes, Newey-West lag 3
nw <- function(y, x) { ok <- is.finite(y); f <- lm(y[ok] ~ x[ok]); c(slope = unname(coef(f)[2]),
  se_nw3 = sqrt(NeweyWest(f, lag = 3, prewhite = FALSE)[2, 2]), n = sum(ok)) }
c5 <- rbindlist(lapply(ASSETS, function(a) { mm <- m[year >= 1700 & year <= 1799]; y <- log(mm[[a]]); y[!is.finite(y)] <- NA
  as.data.table(t(nw(y, mm$year)))[, asset := a] }))
c5[, `:=`(item = "5C5", label = "changed estimand (slope)", t = slope / se_nw3)]
sa <- function(gg, lab) rbindlist(lapply(ASSETS, function(a) as.data.table(t(nw(gg[[a]], gg$year)))[, `:=`(asset = a, scenario = lab)]))
Sa <- rbind(sa(g, "central"), sa(year_ginis(build(K5 = FALSE)), "5C12 wine cap off"))
Sa[, t := slope / se_nw3]
fwrite(c5, file.path(OUT, "supp_5C5_loglinear_trend.csv")); fwrite(Sa, file.path(OUT, "secondary_Sa.csv"))
# 5C11 H4 first and last decades with wine recorded; 5C12 H4 with the cap off
wy <- g[is.finite(wine), year]; fd <- floor(min(wy) / 10) * 10; ld <- floor(max(wy) / 10) * 10
C <- rbind(C, tidy(point_stats(d, pre = c(fd, fd + 9), post = c(ld, ld + 9))[c("D_rise", "D_fall")], "5C11",
                   paste0("H4 Pre = ", fd, "s, Post = ", ld, "s"), "changed estimand"),
           tidy(point_stats(build(K5 = FALSE))[c("D_rise", "D_fall")], "5C12", "H4 wine cap off", "changed measurement"))

# 5C13-15: H5 alternatives (point estimates of the 19 contrasts)
h5_point <- function(dd, owner_col = "owner", win_mod = NULL) {
  Y <- prep_years(dd, owner_col); WIN <- h5_windows(names(Y)); if (!is.null(win_mod)) WIN <- win_mod(WIN)
  CS <- h5_contrasts(grep("^R", names(WIN), value = TRUE))
  U <- lapply(WIN, function(w) st_slave(Y, occ_fixed(Y, w))); h5_stats(U, CS)[, "theta"]
}
d13 <- build(relabel = FALSE); d14 <- copy(d)[, allhh := year < 1830]
H5alt <- rbind(tidy(h5_point(d), "central", "central", "central"),
  tidy(h5_point(d13), "5C13", "no pre-1738 relabel", "changed measurement"),
  tidy(h5_point(d14, "allhh"), "5C14", "all households", "changed population"),
  tidy(h5_point(d, win_mod = function(W) { W$Pre5 <- W$R1780; W$Post5 <- W$R1820; W$C1 <- W$C1[as.numeric(W$C1) >= 1804]; W }),
       "5C15", "H5b rows 1780 vs 1820; H5c from 1804", "changed estimand"))
H5alt <- H5alt[!(item == "5C15" & grepl("^H5a", quantity))]
H5alt[, claimed_side := fifelse(sign(value) == fifelse(quantity == "H5b_ZW", -1, 1), TRUE, FALSE)]
fwrite(H5alt, file.path(OUT, "supp_5C13_15_h5.csv"))
H5owners <- data.table(scenario = c("central", "5C13 no relabel"), owner_rows_pre1830 = c(d[owner == TRUE, .N], d13[owner == TRUE, .N]))
fwrite(H5owners, file.path(OUT, "supp_5C13_owner_rows.csv"))

AC <- rbind(A, C)
fwrite(AC, file.path(OUT, "supp_5A_5C_points.csv"))

# ---- s5B item 2: analytic Welch interval for each r_a ----------------------------------------------
ann <- fread(file.path(OUT, "h2_annual_means.csv"))
welch <- rbindlist(lapply(ASSETS, function(a) {
  e <- ann[window == "E"][[a]]; l <- ann[window == "L"][[a]]; e <- e[is.finite(e)]; l <- l[is.finite(l)]
  ME <- mean(e); ML <- mean(l); vE <- var(e) / (length(e) * ME^2); vL <- var(l) / (length(l) * ML^2)
  se <- sqrt(vE + vL); df <- (vE + vL)^2 / (vE^2 / (length(e) - 1) + vL^2 / (length(l) - 1))
  tq <- qt(1 - ALPHA[["H2"]] / 2, df); th <- log(ML / ME)
  data.table(asset = a, theta = th, se = se, df = df, lo = th - tq * se, hi = th + tq * se,
             category = classify_h2(th - tq * se, th + tq * se, th))
}))
fwrite(welch, file.path(OUT, "supp_5B2_welch.csv"))

# ---- s5B item 5: leave-one-census-out (primary t* quantiles, jackknife SE recomputed) --------------
Y <- prep_years(d)
qt_of <- function(th, se, R, i, k, alpha) { ok <- is.finite(R[, i]) & is.finite(R[, k + i]) & R[, k + i] > 0
  quantile((R[ok, i] - th) / R[ok, k + i], c(1 - alpha / 2, alpha / 2), names = FALSE) }
loo <- list()
# H2
p2 <- fread(file.path(OUT, "h2_primary.csv")); R2 <- readRDS(SCR("h2_boot_two.rds"))
Ek <- as.character(intersect(E_YRS, as.numeric(names(Y)))); Lk <- as.character(intersect(L_YRS, as.numeric(names(Y))))
mE <- st_means(Y, occ_fixed(Y, Ek)); mL <- st_means(Y, occ_fixed(Y, Lk))
for (a in 1:6) { q <- qt_of(p2$theta[a], p2$se[a], R2, a, 6, ALPHA[["H2"]])
  for (j in c(Ek, Lk)) { s <- if (j %in% Ek) h2_stats(mE[Ek != j, , drop = FALSE], mL) else h2_stats(mE, mL[Lk != j, , drop = FALSE])
    th <- s[a, 1]; se <- s[a, 2]
    loo[[length(loo) + 1]] <- data.table(claim = "H2", contrast = ASSETS[a], drop = j, estimate = th,
      category = classify_h2(th - q[1] * se, th - q[2] * se, th), primary = p2$category[a]) } }
# H4
p4 <- fread(file.path(OUT, "h4_primary.csv")); R4 <- readRDS(SCR("h4_boot_two.rds"))
G0 <- year_ginis(d)[is.finite(wine), .(year, G = wine)]
W4 <- list(Pre = G0[year < 1780, G], Peak = G0[year >= 1780 & year <= 1789, G], Post = G0[year > 1789, G])
Y4 <- list(Pre = G0[year < 1780, year], Peak = G0[year >= 1780 & year <= 1789, year], Post = G0[year > 1789, year])
for (k in 1:2) { q <- qt_of(p4$estimate[k], p4$se[k], R4, k, 2, ALPHA[["H4"]])
  wins <- if (k == 1) c("Pre", "Peak") else c("Peak", "Post")
  for (w in wins) for (j in seq_along(W4[[w]])) { g2 <- W4; g2[[w]] <- g2[[w]][-j]; s <- h4_stats(g2)
    th <- s[k]; se <- s[2 + k]
    loo[[length(loo) + 1]] <- data.table(claim = "H4", contrast = p4$contrast[k], drop = as.character(Y4[[w]][j]), estimate = th,
      category = classify_cmp(th - q[1] * se, th - q[2] * se, th, 1), primary = p4$category[k]) } }
# H5
p5 <- fread(file.path(OUT, "h5_primary.csv")); R5 <- readRDS(SCR("h5_boot_two.rds"))
WIN <- h5_windows(names(Y)); CS <- h5_contrasts(grep("^R", names(WIN), value = TRUE)); k5 <- length(CS)
U0 <- lapply(WIN, function(w) st_slave(Y, occ_fixed(Y, w)))
for (i in seq_len(k5)) { q <- qt_of(p5$estimate[i], p5$se[i], R5, i, k5, ALPHA[["H5"]]); c0 <- CS[i]
  for (j in unique(unlist(WIN[CS[[i]]$win]))) {
    U2 <- U0; for (w in CS[[i]]$win) { keep <- WIN[[w]] != j; U2[[w]] <- U0[[w]][keep, , drop = FALSE] }
    s <- h5_stats(U2, c0); th <- s[1, 1]; se <- s[1, 2]
    loo[[length(loo) + 1]] <- data.table(claim = "H5", contrast = names(CS)[i], drop = j, estimate = th,
      category = classify_cmp(th - q[1] * se, th - q[2] * se, th, CS[[i]]$side), primary = p5$category[i]) } }
loo <- rbindlist(loo)
fwrite(loo, file.path(OUT, "supp_5B5_leave_one_out_detail.csv"))
loos <- loo[, .(min_est = min(estimate, na.rm = TRUE), max_est = max(estimate, na.rm = TRUE), drops = .N,
                drops_changing_row = sum(category != primary)), by = .(claim, contrast, primary)]
fwrite(loos, file.path(OUT, "supp_5B5_leave_one_out.csv"))

# ---- s5D: K5 evidence per capped wine entry ---------------------------------------------------
cap <- d[wine_uncapped > 1000, .(year, row, nr, names_men, wine_uncapped, vines)]
tot_v <- d[, .(census_vines = sum(vines, na.rm = TRUE)), by = year]
cap <- merge(cap, tot_v, by = "year")
yrs <- sort(unique(d$year))
adj <- function(nm, y, dir) { k <- match(y, yrs) + dir; if (is.na(nm) || nm == "" || k < 1 || k > length(yrs)) return(NA_character_)
  v <- d[year == yrs[k] & names_men == nm, wine_uncapped]; if (!length(v)) NA_character_ else paste(v, collapse = ";") }
cap[, `:=`(wine_prev_census = mapply(adj, names_men, year, -1), wine_next_census = mapply(adj, names_men, year, 1))]
cap[, `:=`(eq_row_vines = !is.na(vines) & vines > 0 & abs(wine_uncapped - vines) <= 0.1 * vines,
           eq_census_vines = census_vines > 0 & abs(wine_uncapped - census_vines) <= 0.1 * census_vines)]
cap[, vine_evidence := eq_row_vines | eq_census_vines]
fwrite(cap, SCR("supp_5D_capped_entries_with_names.csv"))                      # row-level table with names stays on D: (A6)
fwrite(cap[, !"names_men"], file.path(OUT, "supp_5D_capped_entries.csv"))
byy <- d[, .(capped = sum(wine_uncapped > 1000, na.rm = TRUE), denom_uncapped = sum(!is.na(wine_uncapped)), denom_capped = sum(!is.na(wine)),
             mean_uncapped = mean(wine_uncapped, na.rm = TRUE), mean_capped = mean(wine, na.rm = TRUE)), by = year][capped > 0]
fwrite(byy, file.path(OUT, "supp_5D_by_year.csv"))
k5sum <- data.table(capped_entries = nrow(cap), census_years = uniqueN(cap$year), with_row_vine_match = sum(cap$eq_row_vines),
                    with_census_vine_match = sum(cap$eq_census_vines), no_vine_evidence = sum(!cap$vine_evidence),
                    row_vines_missing_or_zero = sum(is.na(cap$vines) | cap$vines == 0))
fwrite(k5sum, file.path(OUT, "supp_5D_summary.csv")); print(k5sum)

# ---- s5F: aggregate-versus-component conflicts before the zero-fill -------------------------------
raw <- read_raw(FALSE); raw <- coerce_components(copy(raw)); raw[, year := as.numeric(year)]
conf <- function(tot, comps, asset) {
  cs <- rowSums(as.matrix(raw[, ..comps]), na.rm = TRUE); anyc <- rowSums(!is.na(as.matrix(raw[, ..comps]))) > 0
  recorded_tot <- raw[, .(rt = any(!is.na(get(tot)))), by = year]
  rr <- merge(raw[, .(year, t = get(tot))][, `:=`(cs = cs, anyc = anyc)], recorded_tot, by = "year")
  rr[, .(asset = asset, total_and_components_differ = sum(!is.na(t) & anyc & abs(t - cs) > 1e-9),
         fill_blocks_fallback = sum(is.na(t) & rt & anyc & cs > 0)), by = year]
}
F5 <- rbind(conf("horses", HC, "horses"), conf("sheep", SC, "sheep"))[total_and_components_differ > 0 | fill_blocks_fallback > 0]
fwrite(F5, file.path(OUT, "supp_5F_conflicts.csv"))
print(F5[, .(differ = sum(total_and_components_differ), blocked = sum(fill_blocks_fallback)), by = asset])

# ---- S-c: Fig 5 and Fig 6 series 1790-1810 ----------------------------------------------------------
idx <- copy(m); b <- unlist(m[year == 1795, ..ASSETS]); for (v in ASSETS) set(idx, j = v, value = m[[v]] / b[[v]])
Sc <- merge(merge(m[year >= 1790 & year <= 1810], idx[year >= 1790 & year <= 1810], by = "year", suffixes = c("_mean", "_index1795")),
            setnames(g[year >= 1790 & year <= 1810], ASSETS, paste0(ASSETS, "_gini")), by = "year")
fwrite(Sc, file.path(OUT, "secondary_Sc.csv"))
cat("runtime:", format(Sys.time() - t0), "\n")
