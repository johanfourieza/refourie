# P10_FI S6 step 4: admissible sensitivities 1-26 (card §5). Reported, never verdict-determining.
# Run from the project root: Rscript P10_FI/modern/04_sensitivities.R
source(file.path("P10_FI", "modern", "00_functions.R"))
L <- load_angreg("v2018"); a <- L$a; b <- desc_universe(a)
rows <- fread(file.path(OUT, "lpm_primary.csv"))[, .(row, spec, hyp, corrected, family, b0)]
out <- list()
add <- function(sens, label, target, estimate, lo = NA, hi = NA, p = NA, p_holm = NA, extra = "")
  out[[length(out) + 1]] <<- data.table(sens = sens, label = label, target = target, estimate = estimate, lo = lo, hi = hi,
                                        p = p, p_holm = p_holm, note = extra)

# ---- helpers ----------------------------------------------------------------------------------------
h1_report <- function(sens, label, cnt, win = WIN_PRIMARY, W = NULL, qs = c("L30", "s1", "s3", "s4", "d30", "S25", "R25", "E25", "G", "D", "F")) {
  P <- length(cnt$P); pe <- h1_from_W(cnt, matrix(1, 1, P), win)
  if (is.null(W)) W <- parish_W(P)
  bs <- h1_from_W(cnt, W, win)
  for (q in qs) { ci <- if (q %in% c("R25")) c(lo = NA, hi = NA, fail = NA) else pct_ci(bs[[q]])
    add(sens, label, q, pe[[q]], ci["lo"], ci["hi"], extra = sprintf("parish bootstrap B=9999, CI level 1-0.05/4; fail=%.5f; parishes=%d", ci["fail"], P)) }
  invisible(list(pe = pe, bs = bs))
}
its_report <- function(sens, label, f) {
  add(sens, label, "theta", f$theta["est"], f$theta["lo"], f$theta["hi"], f$theta["p"], extra = sprintf("HAC se %.4f, df %d; 95%% CI", f$theta["se"], f$df))
  add(sens, label, "dslope", f$dslope["est"], f$dslope["lo"], f$dslope["hi"], f$dslope["p"], extra = sprintf("HAC se %.4f, df %d; 95%% CI", f$dslope["se"], f$df))
}
# Eight LPM rows on data d with a formula modifier; Holm within family when all four rows of a family are present.
lpm_report <- function(sens, label, d, fmod = identity, rws = rows, infer = NULL, holm_ok = TRUE) {
  r <- rbindlist(lapply(seq_len(nrow(rws)), function(i) { z <- rws[i]; prm <- PARAM[z$hyp]
    x <- lpm_row(fmod(spec_formula(L$models, z$spec, z$corrected)), d, prm, infer)
    data.table(z, est = x$est, p = x$p, lo = x$lo, hi = x$hi, N = x$N, src = x$source) }))
  if (holm_ok) r[, ph := if (.N == 4) holm(p) else NA_real_, by = family] else r[, ph := NA_real_]
  for (i in seq_len(nrow(r))) add(sens, label, r$row[i], r$est[i], r$lo[i], r$hi[i], r$p[i], r$ph[i],
                                 sprintf("%s; N=%d; CI level 1-0.05/4", r$src[i], r$N[i]))
  invisible(r)
}

cnt <- h1_counts(b, "inter"); P <- length(cnt$P); W0 <- parish_W(P)
ser <- annual_series(b)

# ---- S1 windows ----------------------------------------------------------------------------------
h1_report(1, "1930s = 1930-1938", cnt, modifyList(WIN_PRIMARY, list(L30 = 1930:1938)), W0, c("L30", "d30"))
h1_report(1, "s1 = 1911-1914", cnt, modifyList(WIN_PRIMARY, list(s1 = 1911:1914)), W0, c("s1", "d30", "G", "D", "F"))
h1_report(1, "s3 = 1930-1948", cnt, modifyList(WIN_PRIMARY, list(s3 = 1930:1948)), W0, c("s3", "G", "F"))
# ---- S2 white-nonwhite chronology ------------------------------------------------------------------
cnt_wn <- h1_counts(b, "inter_wn"); h1_report(2, "white-nonwhite definition", cnt_wn, W = W0)
# ---- S3 all-interracial 1925 share (note 15) -----------------------------------------------------------
c3 <- list(I = cnt$I, N = cnt$N, WH = cnt$N[, "1925"], WHI = cnt$I[, "1925"], P = cnt$P)
h1_report(3, "all-interracial 1925 share (note 15)", c3, W = W0, qs = c("S25", "R25", "E25"))
# ---- S4 moving-block bootstrap over years within each period pool ----------------------------------------
It <- colSums(cnt$I); Nt <- colSums(cnt$N)
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
pool_draw <- function(yy) { n <- length(yy); nb <- ceiling(n / 5); st <- sample.int(n, nb, replace = TRUE)
  as.character(yy[(as.vector(outer(0:4, st, "+")) - 1L)[seq_len(n)] %% n + 1L]) }
mb <- t(vapply(seq_len(B_BOOT), function(j) { sh <- sapply(WIN_PRIMARY, function(yy) { k <- pool_draw(yy); 100 * sum(It[k]) / sum(Nt[k]) })
  c(d30 = sh[["s1"]] - sh[["L30"]], G = 0.5 * sh[["s1"]] - sh[["s3"]] + 0.5 * sh[["s4"]], D = sh[["s1"]] - sh[["s4"]]) }, numeric(3)))
pe0 <- h1_from_W(cnt, matrix(1, 1, P))
for (q in c("d30", "G", "D")) { ci <- pct_ci(mb[, q]); add(4, "year moving-block bootstrap (5-year blocks within pools)", q, pe0[[q]], ci["lo"], ci["hi"], extra = "B=9999, CI level 1-0.05/4") }

# ---- ITS sensitivities 5-13 -------------------------------------------------------------------------------
its_report(5, "K = 1", its_fit(ser, K = 1)); its_report(5, "K = 3", its_fit(ser, K = 3))
its_report(6, "donut: drop 1949", its_fit(ser[year != 1949]))
its_report(7, "series from 1921", its_fit(ser[year >= 1921]))
its_report(8, "WLS weighted by N_t", its_fit(ser, w = ser$N))
ser_lo <- copy(ser)[, ylo := qlogis((I + 0.5) / (N + 1))]
its_report(9, "log-odds scale", its_fit(ser_lo, yvar = "ylo"))
pl <- rbindlist(lapply(setdiff(1916:1958, 1947:1951), function(bk) { f <- its_fit(ser, brk = bk); data.table(break_year = bk, theta = f$theta["est"], t = f$theta["t"]) }))
t49 <- its_fit(ser)$theta["t"]
fwrite(pl, file.path(OUT, "its_placebo.csv"))
add(10, "placebo break dates 1916-1958, |b-1949|>=3", "theta |t| rank", abs(t49), extra = sprintf("%d of %d placebo |t_b| >= |t_1949| = %.2f (diagnostic rank %d of %d)",
    sum(abs(pl$t) >= abs(t49)), nrow(pl), abs(t49), sum(abs(pl$t) >= abs(t49)) + 1, nrow(pl) + 1))
pw <- its_pw(ser); add(11, "Prais-Winsten AR(1)", "theta", pw$theta["est"], pw$theta["lo"], pw$theta["hi"], pw$theta["p"], extra = sprintf("rho = %.3f; conventional PW SE, df = T - k - 1; 95%% CI", pw$rho))
add(11, "Prais-Winsten AR(1)", "dslope", pw$dslope["est"], pw$dslope["lo"], pw$dslope["hi"], pw$dslope["p"], extra = sprintf("rho = %.3f; conventional PW SE; 95%% CI", pw$rho))
its_report(12, "HAC lag 1", its_fit(ser, lag = 1)); its_report(12, "HAC lag 6", its_fit(ser, lag = 6))
its_report(13, "second break at 1939 (level + slope, joint)", its_fit(ser, second = 1939))

# ---- S14 conditional micro analogue (spec-2 regressors, segmented trend, primary WCR) ---------------------------
am <- copy(a)[, `:=`(uu = (year - 1949) / 10)][, `:=`(pre_u = (1 - act) * uu, pre_u2 = (1 - act) * uu^2, post_u = act * uu)]
f14 <- update(formula(L$models$c2), . ~ . - year + pre_u + pre_u2 + post_u)
x14 <- lpm_row(f14, am, "act")
add(14, "micro analogue: spec 2, segmented trend (K = 2)", "theta_micro (act)", x14$est, x14$lo, x14$hi, x14$p, extra = sprintf("%s; N=%d; CI level 1-0.05/4", x14$source, x14$N))

# ---- S15 the 258 unrecovered same-race records ------------------------------------------------------------
alloc <- function(n, w) { q <- n * w / sum(w); k <- floor(q); r <- n - sum(k); if (r > 0) k[order(-(q - k))[seq_len(r)]] <- k[order(-(q - k))[seq_len(r)]] + 1; k }
for (sc in list(list("i: 1911-1919", 1911:1919), list("ii: 1930-1939", 1930:1939), list("iii: 1949-1963", 1949:1963), list("iv: proportional, all years", YEARS))) {
  yy <- as.character(sc[[2]]); add_t <- setNames(numeric(length(YEARS)), YEARS); add_t[yy] <- alloc(258, Nt[yy])
  c15 <- cnt; c15$N <- rbind(cnt$N, added = add_t); c15$I <- rbind(cnt$I, added = 0)
  wh_add <- if ("1925" %in% yy) round(add_t["1925"] * 131 / 258) else 0
  c15$WH <- c(cnt$WH, added = wh_add); c15$WHI <- c(cnt$WHI, added = 0); c15$P <- c(cnt$P, "added")
  pe <- h1_from_W(c15, matrix(1, 1, P + 1))
  for (q in c("L30", "s1", "s3", "s4", "d30", "S25", "R25", "E25", "G", "D", "F")) add(15, paste("add 258 same-race couples", sc[[1]]), q, pe[[q]], extra = "point (records allocated by N_t; 1925 white-husband share 131/258)")
  s15 <- copy(ser); s15[, N := N + add_t[as.character(year)]][, y := 100 * I / N]
  its_report(15, paste("add 258 same-race couples", sc[[1]]), its_fit(s15))
}

# ---- S16 two-way parish x five-year blocks aligned at 1949 ----------------------------------------------------
a16 <- copy(a)[, yblock := floor((year - 1949) / 5)]
inf16 <- function(m, param, dd) { w <- wcr(m, param, clustid = c("parishdum", "yblock")); c(w, source = "WCR parish x 5-yr block") }
lpm_report(16, "two-way WCR parish x 5-year block", a16, infer = inf16)
# ---- S17 one-way WCR and CR1 benchmarks ------------------------------------------------------------------------
for (cl in c("parishdum", "year")) {
  inf <- function(m, param, dd) { w <- wcr(m, param, clustid = cl, bootcluster = cl); c(w, source = paste("WCR one-way", cl)) }
  lpm_report(17, paste("one-way WCR by", cl), a, infer = inf)
}
a17 <- copy(a)[, pyear := paste(parishdum, year)]
for (cl in c("parishdum", "year", "pyear")) {
  inf <- function(m, param, dd) { r <- cr1_oneway(m, param, dd[[cl]]); bb <- coef(m)[param]; tq <- qt(1 - ALPHA_FAM / 2, r["G"] - 1)
    list(p = r["p"], lo = bb - tq * r["se"], hi = bb + tq * r["se"], source = sprintf("CR1 one-way %s, t(G-1), G=%d", cl, r["G"])) }
  lpm_report(17, paste("CR1 one-way by", cl), a17, infer = inf)
}

# ---- S18 segregation rows: HHI variants --------------------------------------------------------------------------
g <- L$ang[!is.na(mrace) & mrace %in% c("Black", "Coloured", "White"), .(pid, year, mrace)]
cn <- dcast(g[, .N, by = .(pid, year, mrace)], pid + year ~ mrace, value.var = "N", fill = 0)
hhi <- function(B_, C_, W_) { n <- B_ + C_ + W_; ifelse(n > 0, (B_ / n)^2 + (C_ / n)^2 + (W_ / n)^2, NA_real_) }
cn[, hhi := hhi(Black, Coloured, White)]
a18 <- merge(copy(a)[, rid := .I], cn, by = c("pid", "year"), all.x = TRUE, sort = FALSE)[order(rid)]
chk <- a18[!is.na(inequality), max(abs(hhi - inequality), na.rm = TRUE)]
a18[, mr := as.character(mrace)]
a18[, hhi_loo := hhi(Black - (mr %in% "Black"), Coloured - (mr %in% "Coloured"), White - (mr %in% "White"))]
lagt <- cn[, .(pid, year = year + 1, hhi_lag = hhi)]
a18 <- merge(a18, lagt, by = c("pid", "year"), all.x = TRUE, sort = FALSE)[order(rid)]
a18[, n_py := .N, by = .(parishdum, year)]
seg_rows <- rows[hyp == "H3"]
a18a <- copy(a18)[, inequality := hhi_loo]; lpm_report(18, "leave-one-out HHI", a18a, rws = seg_rows)
a18b <- copy(a18)[, inequality := hhi_lag]; lpm_report(18, "lagged (t-1) HHI", a18b, rws = seg_rows)
lpm_report(18, "year FE instead of linear year", a, fmod = function(f) update(f, . ~ . - year - act + factor(year)), rws = seg_rows)
lpm_report(18, "parish-years with < 10 marriages dropped", a18[n_py >= 10], rws = seg_rows)
add(18, "check", "HHI rebuild max |diff| vs script inequality", chk)

# ---- S19 Act rows: trend form and sample start ----------------------------------------------------------------------
act_rows <- rows[hyp == "H2"]; a19 <- copy(a)[, yc := year - 1935]
lpm_report(19, "quadratic year trend", a19, fmod = function(f) update(f, . ~ . + I(yc^2)), rws = act_rows)
lpm_report(19, "cubic year trend", a19, fmod = function(f) update(f, . ~ . + I(yc^2) + I(yc^3)), rws = act_rows)
lpm_report(19, "sample from 1921", a[year >= 1921], rws = act_rows)
# ---- S20 husband-race dummies only ---------------------------------------------------------------------------------
lpm_report(20, "husband-race dummies only", a, fmod = function(f) update(f, . ~ . - frace))
# ---- S21 col-1 logit with month, parish and year: OR and AME ----------------------------------------------------------
lg <- glm(update(formula(L$models$c1), . ~ . + monthnumber + parishdum + year), family = binomial("logit"), data = as.data.frame(a))
dl <- as.data.frame(a)[as.integer(rownames(model.frame(lg))), ]
Vl <- vcovCL(lg, cluster = ~ parishdum + year, type = "HC1", multi0 = FALSE); ev <- eigen(Vl, symmetric = TRUE)
Vl <- ev$vectors %*% diag(pmax(ev$values, 0)) %*% t(ev$vectors); dimnames(Vl) <- list(names(coef(lg)), names(coef(lg)))
dfl <- min(uniqueN(dl$parishdum), uniqueN(dl$year)) - 1
for (tm in c("act", "inequality")) { bb <- coef(lg)[tm]; se <- sqrt(Vl[tm, tm]); tq <- qt(0.975, dfl)
  add(21, "col-1 logit + month + parish + year", paste0("OR ", tm), exp(bb), exp(bb - tq * se), exp(bb + tq * se), 2 * pt(-abs(bb / se), dfl), extra = sprintf("two-way CR1 (parish, year), t(%d), 95%% CI; N=%d", dfl, nobs(lg))) }
d1 <- dl; d1$act <- 1; d0 <- dl; d0$act <- 0
ame_act <- mean(predict(lg, d1, type = "response") - predict(lg, d0, type = "response"))
pr <- predict(lg, type = "response"); ame_seg <- mean(coef(lg)["inequality"] * pr * (1 - pr))
add(21, "col-1 logit + month + parish + year", "AME act", ame_act, extra = "average discrete change, point")
add(21, "col-1 logit + month + parish + year", "AME inequality", ame_seg, extra = "average derivative, point")
# ---- S22 spec 3 (model7), published and corrected -------------------------------------------------------------------
r22 <- data.table(row = c("H2-c3", "H3-c3", "H2-c3L", "H3-c3L"), spec = "c3", hyp = c("H2", "H3", "H2", "H3"), corrected = c(FALSE, FALSE, TRUE, TRUE), family = c("E", "E", "L", "L"), b0 = NA)
lpm_report(22, "spec 3 (model7)", a, rws = r22, holm_ok = FALSE)

# ---- S23 fixed parish composition -----------------------------------------------------------------------------------
per23 <- list(1911:1919, 1920:1929, 1930:1938, 1939:1948, 1949:1963)
okp <- cnt$P[apply(sapply(per23, function(yy) rowSums(cnt$N[, as.character(yy), drop = FALSE]) >= 10), 1, all)]
b23 <- b[parish %in% okp]; c23 <- h1_counts(b23, "inter")
h1_report(23, sprintf("fixed composition (%d parishes), raw pooled", length(okp)), c23)
wp <- rowSums(c23$N) / sum(c23$N)
std_share <- function(It, Nt, yy) { k <- as.character(yy); i <- rowSums(It[, k, drop = FALSE]); n <- rowSums(Nt[, k, drop = FALSE]); ok <- n > 0; 100 * sum(wp[ok] * i[ok] / n[ok]) / sum(wp[ok]) }
st <- sapply(WIN_PRIMARY, function(yy) std_share(c23$I, c23$N, yy))
okw <- c23$WH > 0; S25s <- 100 * sum(wp[okw] * c23$WHI[okw] / c23$WH[okw]) / sum(wp[okw])
stq <- c(L30 = st[["L30"]], s1 = st[["s1"]], s3 = st[["s3"]], s4 = st[["s4"]], d30 = st[["s1"]] - st[["L30"]], S25 = S25s, R25 = S25s / UNION, E25 = S25s - UNION,
         G = 0.5 * st[["s1"]] - st[["s3"]] + 0.5 * st[["s4"]], D = st[["s1"]] - st[["s4"]], F = (st[["s1"]] - st[["s3"]]) / (st[["s1"]] - st[["s4"]]))
for (q in names(stq)) add(23, sprintf("fixed composition (%d parishes), standardised (fixed parish weights)", length(okp)), q, stq[[q]], extra = "point")
s23 <- data.table(year = YEARS, I = NA_real_, N = colSums(c23$N))
s23[, y := sapply(YEARS, function(t) std_share(c23$I, c23$N, t))]
its_report(23, "fixed composition, standardised annual series", its_fit(s23))
lpm_report(23, sprintf("fixed composition (%d parishes)", length(okp)), a[as.character(parishdum) %in% okp])

# ---- S24 leave-one-parish-out ------------------------------------------------------------------------------------------
prim_lpm <- fread(file.path(OUT, "lpm_primary.csv")); prim_h1 <- fread(file.path(OUT, "h1_primary.csv"))
pf <- function(q) prim_h1[quantity == q]
base_v <- c(`H1-30s` = v_h130(pf("L30")$estimate)[["verdict"]], `H1-25s` = v_h125s(pf("S25")$estimate)[["verdict"]], `H1-25r` = v_h125r(pf("R25")$estimate)[["verdict"]],
            `H1-dec` = v_comp(pf("d30")$lo, pf("d30")$hi, pf("d30")$fail)[["verdict"]], `H1-UX` = v_comp(pf("E25")$lo, pf("E25")$hi, pf("E25")$fail)[["verdict"]],
            `H1-F` = v_F(pf("D")$lo, pf("D")$hi, pf("G")$lo, pf("G")$hi, pf("D")$fail, pf("G")$fail)[["verdict"]])
for (i in seq_len(nrow(prim_lpm))) { z <- prim_lpm[i]; base_v[z$row] <- lpm_verdict(z$row, z$estimate, z$b0, z$lo, z$hi, z$p, z$p_holm)[["verdict"]] }
lopo <- list()
for (pp in cnt$P) {
  keep <- cnt$P != pp
  ck <- list(P = cnt$P[keep], N = cnt$N[keep, ], I = cnt$I[keep, ], WH = cnt$WH[keep], WHI = cnt$WHI[keep])
  pe <- h1_from_W(ck, matrix(1, 1, P - 1)); bs <- h1_from_W(ck, parish_W(P - 1))
  ci <- lapply(c(d30 = "d30", E25 = "E25", G = "G", D = "D"), function(q) pct_ci(bs[[q]]))
  vv <- c(`H1-30s` = v_h130(pe$L30)[["verdict"]], `H1-25s` = v_h125s(pe$S25)[["verdict"]], `H1-25r` = v_h125r(pe$R25)[["verdict"]],
          `H1-dec` = v_comp(ci$d30["lo"], ci$d30["hi"], ci$d30["fail"])[["verdict"]], `H1-UX` = v_comp(ci$E25["lo"], ci$E25["hi"], ci$E25["fail"])[["verdict"]],
          `H1-F` = v_F(ci$D["lo"], ci$D["hi"], ci$G["lo"], ci$G["hi"], ci$D["fail"], ci$G["fail"])[["verdict"]])
  est <- c(`H1-30s` = pe$L30, `H1-25s` = pe$S25, `H1-25r` = pe$R25, `H1-dec` = pe$d30, `H1-UX` = pe$E25, `H1-F` = pe$F)
  sk <- annual_series(b[parish != pp]); th <- its_fit(sk)$theta["est"]
  r <- rbindlist(lapply(seq_len(nrow(rows)), function(i) { z <- rows[i]; x <- lpm_row(spec_formula(L$models, z$spec, z$corrected), a[parishdum != pp], PARAM[z$hyp])
    data.table(z, est = x$est, p = x$p, lo = x$lo, hi = x$hi, src = x$source) }))
  r[, ph := holm(p), by = family]
  r[, verdict := mapply(function(rw, e, b0, lo, hi, p, ph) lpm_verdict(rw, e, b0, lo, hi, p, ph)[["verdict"]], row, est, b0, lo, hi, p, ph)]
  lopo[[pp]] <- rbindlist(list(data.table(dropped = pp, row = names(vv), estimate = est[names(vv)], verdict = vv),
                      data.table(dropped = pp, row = "H2-ITS", estimate = th, verdict = "different-estimand"),
                      data.table(dropped = pp, row = r$row, estimate = r$est, verdict = r$verdict, src = r$src)), fill = TRUE)
}
lopo <- rbindlist(lopo); lopo[, base := base_v[row]]; lopo[row == "H2-ITS", base := "different-estimand"]
lsum <- lopo[, .(min = min(estimate, na.rm = TRUE), max = max(estimate, na.rm = TRUE), n_drops = .N, n_changed = sum(verdict != base),
                 changed_to = paste(unique(verdict[verdict != base]), collapse = "; "), n_cr1_fallback = sum(!is.na(src) & src != "WCR two-way")), by = row]
fwrite(lsum, file.path(OUT, "lopo_summary.csv"))
for (i in seq_len(nrow(lsum))) add(24, "leave-one-parish-out", lsum$row[i], NA, lsum$min[i], lsum$max[i],
                                  extra = sprintf("range over %d drops; %d change the verdict category%s; CR1 fallback in %d drops", lsum$n_drops[i], lsum$n_changed[i], ifelse(lsum$n_changed[i] > 0, paste0(" (", lsum$changed_to[i], ")"), ""), lsum$n_cr1_fallback[i]))

# ---- S25 changed population: 2019 file, six unmapped parishes added, pid 557 excluded (A4d) ------------------------
M <- load_angreg("main"); am2 <- M$a[pid != 557 | is.na(pid)]
am2[is.na(parishdum) & !is.na(pid), parishdum := paste0("pid", pid)]
b25 <- desc_universe(am2); c25 <- h1_counts(b25, "inter")
h1_report(25, sprintf("2019 file + six parishes, pid 557 excluded (%d parishes)", length(c25$P)), c25)
its_report(25, "2019 file + six parishes, pid 557 excluded", its_fit(annual_series(b25)))
lpm_report(25, "2019 file + six parishes, pid 557 excluded", am2)

# ---- S26 diagnostic: original Figure 3 definition on the 2018 file ---------------------------------------------------
yo <- L$years[year >= 1911 & year <= 1963]
osh <- function(yy) yo[year %in% yy, 100 * sum(m) / sum(m + s)]
o <- sapply(WIN_PRIMARY, osh)
for (q in names(o)) add(26, "original Figure 3 definition (diagnostic)", q, o[[q]])
add(26, "original Figure 3 definition (diagnostic)", "d30", o[["s1"]] - o[["L30"]]); add(26, "original Figure 3 definition (diagnostic)", "G", 0.5 * o[["s1"]] - o[["s3"]] + 0.5 * o[["s4"]])
add(26, "original Figure 3 definition (diagnostic)", "D", o[["s1"]] - o[["s4"]]); add(26, "original Figure 3 definition (diagnostic)", "F", (o[["s1"]] - o[["s3"]]) / (o[["s1"]] - o[["s4"]]))
add(26, "original Figure 3 definition (diagnostic)", "1925 all-couple share", yo[year == 1925, share])

sens <- rbindlist(out)
fwrite(sens, file.path(OUT, "sensitivities.csv"))
print(sens[, .(sens, label = substr(label, 1, 45), target, estimate = signif(estimate, 4), lo = signif(lo, 3), hi = signif(hi, 3), p = signif(p, 3), p_holm = signif(p_holm, 3))], nrows = 1000)
