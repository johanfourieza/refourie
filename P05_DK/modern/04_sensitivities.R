# P05_DK S6 step 4: the admissible sensitivities of card §5 (items 1-24 and 26; item 25 is in 03).
# Every row is labelled "sensitivity; does not set the verdict"; rows that change the population or estimand are
# additionally labelled A4d. Aggregate output only.
# Usage (project root): Rscript P05_DK/modern/04_sensitivities.R
source("./P05_DK/modern/common.R")
suppressPackageStartupMessages({ library(spdep); library(conleyreg); library(fwildclusterboot); library(summclust); library(nlme) })
B  <- readRDS(file.path(SCR, "units.rds")); CS <- readRDS(file.path(SCR, "cross_section.rds")); T2 <- readRDS(file.path(SCR, "t2.rds"))
s2 <- readRDS(dpath(P, "repro_original", "_scratch", "s2_snapshot.rds"))
s5 <- readRDS(dscratch(P, "compare", "s5_session.rds"))
A1 <- CS$A1; A3 <- CS$A3; D1 <- CS$D1; D3 <- CS$D3; el <- B$el
polys <- st_drop_geometry(B$polys)
LAB <- "sensitivity; does not set the verdict"
rows <- list()
add <- function(item, row, label, b, se = NA, p = NA, lo = NA, hi = NA, n = NA, method = "", a4d = FALSE, note = "", extra = NA) {
  rows[[length(rows) + 1]] <<- data.frame(item = item, row = row, label = label, estimate = b, se = se, p = p, ci_lo = lo, ci_hi = hi,
    n = n, method = method, a4d = a4d, status = if (a4d) paste(LAB, "(A4d: changed population or estimand)") else LAB,
    note = note, extra = extra)
}
addbm <- function(item, row, label, m, term, a4d = FALSE, note = "") {
  r <- bm_test(m, term)
  add(item, row, label, r$b, r$se, r$p, r$lo, r$hi, nobs(m), paste(r$inference, "Bonferroni"), a4d, note)
  invisible(r)
}
fit <- function(row, d) lm(if (row == "H1") F_H1 else F_H3, data = d)
TERM <- c(H1 = T_H1, H3 = T_H3)
pubset1 <- B$pub1; pubset3 <- B$pub3
A1s <- A1[A1$unit_id %in% pubset1, ]; A3s <- A3[A3$unit_id %in% pubset3, ]

# ================================================================ 1. authors' data, primary inference
addbm(1, "H1", "authors' data and sample, CR2/BM", fit("H1", A1), T_H1, note = "isolates the corrections")
addbm(1, "H3", "authors' data and sample, CR2/BM", fit("H3", A3), T_H3, note = "isolates the corrections")

# ================================================================ 2. one correction at a time, from the authors' data
pv <- function(id, v) polys[[v]][match(id, polys$unit_id)]
x <- A1s; x$black_share <- pv(x$unit_id, "black_share"); x$col_share <- pv(x$unit_id, "col_share")
addbm("2a", "H1", "area-weighted shares only", fit("H1", x), T_H1)
x <- A3s; x$black_share <- pv(x$unit_id, "black_share"); x$col_share <- pv(x$unit_id, "col_share")
addbm("2a", "H3", "area-weighted shares only", fit("H3", x), T_H3)
x <- A1s; x$density <- pv(x$unit_id, "density"); addbm("2b", "H1", "density = interpolated total / covered area only", fit("H1", x), T_H1)
x <- A3s; x$density <- pv(x$unit_id, "density"); addbm("2b", "H3", "density = interpolated total / covered area only", fit("H3", x), T_H3)
# 2c: Port Shepstone added (the authors' construction gives it no covariates, so its corrected covariates are used)
ps <- el[el$unit_id == "port shepstone", ]
x <- rbind(A1s[, c("unit_id", "deaths", "black_share", "col_share", "density", "log_rail", "rain", "region")],
           data.frame(unit_id = ps$unit_id, deaths = ps$deaths, black_share = ps$black_share, col_share = ps$col_share, density = ps$density,
                      log_rail = ps$log_rail, rain = ps$rain, region = factor(ps$region, levels = reg_levels)))
addbm("2c", "H1", "Port Shepstone added only", fit("H1", x), T_H1, note = "Port Shepstone enters with its corrected covariates (none exist in the authors' construction)")
a3ps <- A3[A3$unit_id == "port shepstone", ]
x3 <- rbind(A3s[, c("unit_id", "urate", "deaths", "black_share", "col_share", "density", "log_rail", "rain", "region")],
            data.frame(unit_id = ps$unit_id, urate = a3ps$urate, deaths = ps$deaths, black_share = ps$black_share, col_share = ps$col_share,
                       density = ps$density, log_rail = ps$log_rail, rain = ps$rain, region = factor(ps$region, levels = reg_levels)))
addbm("2c", "H3", "Port Shepstone added only", fit("H3", x3), T_H3, note = if (is.na(a3ps$urate))
  "the authors' 1936 crosswalk gives Port Shepstone no outcome either, so it cannot enter: identical to item 1" else "authors' outcome for Port Shepstone; corrected covariates")
# 2d: Paarl/Wellington dissolved, authors' construction (summed counts, mean of the 1970 densities of both, rail re-run, Paarl's rain)
ag <- B$auth_dens_groups |> filter(StndrdN %in% c("paarl", "wellington"))
pw <- el[el$unit_id == "paarl_wellington", ]
x <- A1s; i <- which(x$unit_id == "paarl")
x$black_share[i] <- sum(ag$B_1911) / sum(ag$T1911); x$col_share[i] <- sum(ag$C_1911) / sum(ag$T1911)
x$density[i] <- mean(ag$TDENS_11); x$log_rail[i] <- pw$log_rail
addbm("2d", "H1", "Paarl/Wellington dissolved only", fit("H1", x), T_H1)
x3 <- A3s; i <- which(x3$unit_id == "paarl"); a3pw <- A3[A3$unit_id %in% c("paarl", "wellington"), ]
x3$urate[i] <- sum(a3pw$u_t) / sum(a3pw$wa); x3$black_share[i] <- x$black_share[x$unit_id == "paarl"]
x3$col_share[i] <- x$col_share[x$unit_id == "paarl"]; x3$density[i] <- mean(ag$TDENS_11); x3$log_rail[i] <- pw$log_rail
addbm("2d", "H3", "Paarl/Wellington dissolved only", fit("H3", x3), T_H3)
# 2e: H3 15-64 denominator only (the authors' merge; subtract the 65-69 column, as in compare/s5_checks/03_checks.R)
ea <- as.data.frame(s5$european_ages_1936)
a65 <- ea |> transmute(mag_dist_1936, sex, a65 = suppressWarnings(as.numeric(as.character(`65`)))) |>
  mutate(a65 = ifelse(is.na(a65), 0, a65)) |> filter(sex == "P") |> group_by(mag_dist_1936) |> summarise(a65 = sum(a65))
red <- as.data.frame(s5$census_1936_merge) |> left_join(a65, by = "mag_dist_1936") |> group_by(StndrdN) |>
  summarise(wa64 = sum(total_workingage_pop_w - a65), u = sum(unemployed_w_t))
x3 <- A3s; x3$urate <- (red$u / red$wa64)[match(x3$unit_id, red$StndrdN)]
addbm("2e", "H3", "15-64 denominator only", fit("H3", x3), T_H3)
x3 <- A3s; x3$urate <- pv(x3$unit_id, "urate_authcounts")
addbm("2f", "H3", "area-weighted 1936 crosswalk only", fit("H3", x3), T_H3, note = "authors' 1936 counts (15-69, NA->0), area-weighted 1937->1918")

# ================================================================ 3. full S3 rebuild (repro_r/, N 206)
u3 <- readRDS(dpath(P, "repro_r", "_scratch", "districts_1918.rds")) |> st_drop_geometry()
u3d <- data.frame(deaths = u3$rate, black_share = u3$black_sh, col_share = u3$col_sh, density = u3$dens11, log_rail = u3$lrail,
                  rain = u3$rain_so_cm * 10, urate = u3$ur_total,
                  region = factor(recode(as.character(u3$region), OFS = "Orange Free State"), levels = reg_levels))
addbm(3, "H1", "full S3 rebuild", fit("H1", u3d), T_H1, a4d = TRUE, note = "S3 rail, rain, outcome; S3 population")
addbm(3, "H3", "full S3 rebuild", fit("H3", u3d), T_H3, a4d = TRUE, note = "S3 rail, rain, outcome; S3 population")

# ================================================================ 4-6, 26 on the primary data
alt <- function(d, ...) { a <- list(...); for (v in names(a)) d[[v]] <- d[[a[[v]]]]; d }
for (rw in c("H1", "H3")) {
  D <- if (rw == "H1") D1 else D3
  addbm(4, rw, "1911 shares from Phillips Table 13", fit(rw, alt(D, black_share = "phillips_black_share", col_share = "phillips_col_share")), TERM[rw])
  addbm(5, rw, "rail: S3 distance (equal-area, existing lines)", fit(rw, alt(D, log_rail = "log_rail_s3")), TERM[rw])
  addbm(5, rw, "rail: all features incl. under construction", fit(rw, alt(D, log_rail = "log_rail_s3_all")), TERM[rw])
  addbm(6, rw, "corrected sample without Port Shepstone", fit(rw, D[D$unit_id != "port shepstone", ]), TERM[rw], a4d = TRUE)
}
for (rw in c("H1", "H3")) {
  E <- el; E$region <- factor(E$region, levels = reg_levels)
  E$black_share <- E$black_share_strict; E$col_share <- E$col_share_strict; E$density <- E$density_strict
  if (rw == "H3") E$urate <- E$urate_strict
  E <- E[E$deaths > 0, ]
  addbm(26, rw, "strict missing-source rule; density on full unit area", fit(rw, E), TERM[rw])
}

# ================================================================ 7-12 inference on the primary data
explicit <- function(d, rw) {           # explicit columns for packages that do not evaluate transformations
  out <- data.frame(y = if (rw == "H1") d$deaths else d$urate, focal = if (rw == "H1") d$black_share else log(d$deaths),
                    black_share = d$black_share, col_share = d$col_share, ldens = log1p(d$density), log_rail = d$log_rail, rain = d$rain,
                    lat = d$lat, lon = d$lon, region = factor(d$region, levels = reg_levels))
  for (l in reg_levels[-1]) out[[paste0("r_", gsub(" ", "", l))]] <- as.integer(out$region == l)
  out
}
rhs <- function(rw) { dum <- paste0("r_", gsub(" ", "", reg_levels[-1]))
  c("focal", if (rw == "H3") "black_share", "col_share", "ldens", "log_rail", "rain", dum) }
dist_gc <- function(lat, lon, R = 6371.0088) {
  p <- lat * pi / 180; l <- lon * pi / 180; dp <- outer(p, p, "-"); dl <- outer(l, l, "-")
  a <- sin(dp / 2)^2 + outer(cos(p), cos(p)) * sin(dl / 2)^2; a[a > 1] <- 1; 2 * R * asin(sqrt(a)) }
conley_V <- function(X, e, W) {         # P28 mechanics (P28_VFF/modern/common.R conley_from_W), eigenvalue clipping
  S <- X * e; meat <- crossprod(S, W %*% S); meat <- (meat + t(meat)) / 2
  ee <- eigen(meat, symmetric = TRUE); if (min(ee$values) < 0) { ee$values[ee$values < 0] <- 0; meat <- ee$vectors %*% diag(ee$values) %*% t(ee$vectors) }
  Bi <- solve(crossprod(X)); V <- Bi %*% meat %*% Bi; (V + t(V)) / 2 }
wild_restricted <- function(X, y, j, Bn = 9999) {   # Rademacher, null imposed, HC2-type residual transformation
  Xr <- X[, -j, drop = FALSE]; br <- qr.solve(Xr, y); ur <- as.vector(y - Xr %*% br)
  hr <- rowSums(Xr * t(solve(crossprod(Xr), t(Xr)))); ut <- ur / sqrt(1 - hr)
  A <- solve(crossprod(X), t(X)); h <- rowSums(X * t(A))
  b <- as.vector(A %*% y); e <- as.vector(y - X %*% b); t_obs <- b[j] / sqrt(sum(A[j, ]^2 * e^2 / (1 - h)))
  RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
  V <- matrix(sample(c(-1, 1), length(y) * Bn, replace = TRUE), length(y))
  RNGkind("default")
  Ys <- as.vector(Xr %*% br) + ut * V
  Bs <- A %*% Ys; Es <- Ys - X %*% Bs
  ts <- Bs[j, ] / sqrt(colSums(A[j, ]^2 * Es^2 / (1 - h)))
  c(t_obs = t_obs, p = mean(abs(ts) >= abs(t_obs)))
}
for (rw in c("H1", "H3")) {
  D <- if (rw == "H1") D1 else D3; m <- fit(rw, D); term <- TERM[rw]
  for (ty in c("const", "HC1", "HC3")) { r <- se_type(m, term, ty); q <- qt(1 - ALPHA / 2, r$df)
    add(7, rw, paste0(c(const = "classical", HC1 = "HC1", HC3 = "HC3")[ty], " SE"), r$b, r$se, r$p, r$b - q * r$se, r$b + q * r$se, nobs(m), "t(N-K), Bonferroni level") }
  Z <- explicit(D, rw); X <- cbind(1, as.matrix(Z[rhs(rw)])); y <- Z$y
  stopifnot(abs(qr.solve(X, y)[2] - coef(m)[term]) < 1e-9 * max(1, abs(coef(m)[term])))
  wb <- wild_restricted(X, y, 2)
  add(8, rw, "restricted wild bootstrap (Rademacher, HC2-type transform, B = 9,999)", coef(m)[term], NA, wb["p"], NA, NA, nobs(m),
      "WRE, two-sided symmetric p", note = sprintf("HC2 t = %.4f", wb["t_obs"]))
  # 9. Conley (conleyreg), Bartlett, great-circle distances between centroids
  f9 <- reformulate(rhs(rw), "y")
  for (cut in c(100, 200, 500)) {
    cr <- tryCatch(conleyreg(f9, data = Z, dist_cutoff = cut, lat = "lat", lon = "lon", kernel = "bartlett", verbose = FALSE, ncores = 1),
                   error = function(e) { message("conleyreg error: ", conditionMessage(e)); NULL })
    if (!is.null(cr)) add(9, rw, sprintf("Conley SE, Bartlett, %d km (conleyreg)", cut), cr["focal", 1], cr["focal", 2], cr["focal", 4],
                          NA, NA, nobs(m), "conleyreg z-test")
  }
  # 10. Moran's I of the primary residuals, k = 5 nearest neighbours, row-standardised
  lw <- nb2listw(knn2nb(knearneigh(cbind(Z$lon, Z$lat), k = 5, longlat = TRUE)), style = "W")
  mi <- lm.morantest(m, lw)
  add(10, rw, "Moran's I of primary residuals (k = 5 NN, row-standardised)", unname(mi$estimate[1]), NA, mi$p.value, NA, NA, nobs(m),
      "lm.morantest", note = sprintf("expectation %.4f; diagnostic", mi$estimate[2]))
  # 11. Kelly (2019) spatial-noise placebo, P28 mechanics, Conley 100 km t
  Dm <- dist_gc(Z$lat, Z$lon); W <- (Dm <= 100) * (1 - Dm / 100)
  e <- as.vector(y - X %*% qr.solve(X, y)); Vc <- conley_V(X, e, W); t_obs <- qr.solve(X, y)[2] / sqrt(Vc[2, 2])
  rr <- resid(lm(Z$focal ~ X[, -(1:2)]))
  nll <- function(p) { C <- exp(p[1]) * exp(-Dm / p[2]); diag(C) <- diag(C) + exp(p[3])
    L <- tryCatch(chol(C), error = function(e) NULL); if (is.null(L)) return(1e10)
    z <- backsolve(L, rr, transpose = TRUE); sum(log(diag(L))) + 0.5 * sum(z^2) }
  v <- var(rr); best <- NULL
  for (rho0 in c(25, 100, 400, 1500)) for (sh in c(0.2, 0.5, 0.8)) {
    o <- tryCatch(optim(c(log(sh * v), rho0, log((1 - sh) * v)), nll, method = "L-BFGS-B",
                        lower = c(log(v) - 15, 1, log(v) - 15), upper = c(log(v) + 5, 2000, log(v) + 5)), error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o }
  C <- exp(best$par[1]) * exp(-Dm / best$par[2]); diag(C) <- diag(C) + exp(best$par[3]); L <- t(chol(C))
  RNGkind("L'Ecuyer-CMRG"); set.seed(SEED); st <- .Random.seed; Rn <- 2000; ts <- numeric(Rn); Xs <- X
  for (k in seq_len(Rn)) {
    st <- parallel::nextRNGStream(st); assign(".Random.seed", st, envir = .GlobalEnv)
    Xs[, 2] <- as.vector(L %*% rnorm(nrow(X))); bs <- qr.solve(Xs, y); es <- as.vector(y - Xs %*% bs)
    ts[k] <- bs[2] / sqrt(conley_V(Xs, es, W)[2, 2]) }
  RNGkind("default")
  pp <- (1 + sum(abs(ts) >= abs(t_obs))) / (Rn + 1)
  add(11, rw, "spatial-noise placebo (exponential ML, R = 2,000, Conley 100 km t)", coef(m)[term], NA, pp, NA, NA, nobs(m), "placebo p",
      note = sprintf("t_obs %.4f; rho %.1f km; nugget share %.3f; ML conv %d; q95|t*| %.3f; MC se %.4f", t_obs, best$par[2],
                     exp(best$par[3]) / (exp(best$par[3]) + exp(best$par[1])), best$convergence, quantile(abs(ts), .95), sqrt(pp * (1 - pp) / Rn)))
  # 12. wild cluster bootstrap by region (6 clusters, Webb, B = 9,999) and summclust
  Z$cl <- as.integer(Z$region); mz <- lm(f9, data = Z)
  set.seed(SEED); dqrng::dqset.seed(SEED)
  bt <- tryCatch(boottest(mz, param = "focal", clustid = "cl", B = 9999, type = "webb"), error = function(e) { message("boottest: ", conditionMessage(e)); NULL })
  sc <- tryCatch(summclust(mz, cluster = ~cl, params = "focal"), error = function(e) NULL)
  ninfo <- paste(sprintf("%s:%d", levels(Z$region), as.integer(table(Z$region))), collapse = " ")
  lev <- if (!is.null(sc)) paste(sprintf("%.3f", sc$leverage_g), collapse = ",") else "summclust failed"
  pl <- if (!is.null(sc)) paste(sprintf("%.3f", sc$partial_leverage["focal", ]), collapse = ",") else ""
  add(12, rw, "wild cluster bootstrap by region (6 clusters, Webb, B = 9,999)", coef(m)[term], NA, if (!is.null(bt)) bt$p_val else NA,
      if (!is.null(bt)) bt$conf_int[1] else NA, if (!is.null(bt)) bt$conf_int[2] else NA, nobs(m), "WCR, 95% CI",
      note = sprintf("SIX CLUSTERS ARE TOO FEW FOR RELIABLE INFERENCE. units per region %s; largest share %.3f; leverage_g %s; partial leverage (focal) %s",
                     ninfo, max(table(Z$region)) / nrow(Z), lev, pl))
}

# ================================================================ 13-16 specification and population (A4d)
mlog <- lm(update(F_H1, log(deaths) ~ .), D1)
addbm(13, "H1", "log outcome (T1 col 2 analogue)", mlog, T_H1, a4d = TRUE)
m1 <- fit("H1", D1); top3 <- D1$unit_id[order(-abs(rstudent(m1)))][1:3]
addbm(14, "H1", "levels model, top-3 |rstudent| excluded (col 3 analogue)", fit("H1", D1[!D1$unit_id %in% top3, ]), T_H1, a4d = TRUE, note = paste(top3, collapse = ", "))
top3l <- D1$unit_id[order(-abs(rstudent(mlog)))][1:3]
addbm(14, "H1", "log model, its own top-3 |rstudent| excluded (col 4 analogue)", lm(update(F_H1, log(deaths) ~ .), D1[!D1$unit_id %in% top3l, ]), T_H1,
      a4d = TRUE, note = paste(top3l, collapse = ", "))
loo_tab <- list()
for (rw in c("H1", "H3")) {
  D <- if (rw == "H1") D1 else D3; term <- TERM[rw]; b0 <- B0[rw]
  prim_cat <- verdict_h13(bm_test(fit(rw, D), term)$b, b0, bm_test(fit(rw, D), term)$p, bm_test(fit(rw, D), term)$lo, bm_test(fit(rw, D), term)$hi)[1]
  for (g in reg_levels) { d <- D[D$region != g, ]; d$region <- droplevels(d$region)
    addbm(15, rw, paste("leave-one-region-out:", g), fit(rw, d), term, a4d = TRUE) }
  lo <- t(sapply(seq_len(nrow(D)), function(i) { r <- bm_test(fit(rw, D[-i, ]), term); c(r$b, r$p, r$lo, r$hi) }))
  cats <- apply(lo, 1, function(z) verdict_h13(z[1], b0, z[2], z[3], z[4])[1])
  loo_tab[[rw]] <- data.frame(row = rw, dropped = D$unit_id, b = lo[, 1], p = lo[, 2], category = cats)
  add(15, rw, "leave-one-unit-out: range of b", min(lo[, 1]), NA, max(lo[, 2]), NA, NA, nrow(D) - 1, "min b; p = max p over drops", a4d = TRUE,
      note = sprintf("b range [%.6g, %.6g]; drops changing the category (%s): %d", min(lo[, 1]), max(lo[, 1]), prim_cat, sum(cats != prim_cat)),
      extra = max(lo[, 1]))
  mm <- fit(rw, D); dfb <- dfbeta(mm)[, term]; dfbs <- dfbetas(mm)[, term]; o <- order(-abs(dfb))[1:10]
  add(15, rw, "ten largest |DFBETA|", NA, NA, NA, NA, NA, nobs(mm), "dfbeta (dfbetas)", a4d = FALSE,
      note = paste(sprintf("%s %.4g (%.3f)", D$unit_id[o], dfb[o], dfbs[o]), collapse = "; "))
}
write.csv(do.call(rbind, loo_tab), file.path(OUT, "sens_item15_leave_one_out.csv"), row.names = FALSE)
addbm(16, "H3", "15-69 denominator, all other corrections", fit("H3", alt(D3, urate = "urate_1569")), T_H3, a4d = TRUE)
Dw <- el[!is.na(el$urate_f) & el$deaths > 0 & complete.cases(el[c("black_share", "col_share", "density", "log_rail", "rain")]), ]; Dw$region <- factor(Dw$region, levels = reg_levels)
addbm(16, "H3", "women (non-headline), all corrections", fit("H3", alt(Dw, urate = "urate_f")), T_H3, a4d = TRUE)
Dm_ <- el[!is.na(el$urate_m) & el$deaths > 0 & complete.cases(el[c("black_share", "col_share", "density", "log_rail", "rain")]), ]; Dm_$region <- factor(Dm_$region, levels = reg_levels)
addbm(16, "H3", "men (non-headline), all corrections", fit("H3", alt(Dm_, urate = "urate_m")), T_H3, a4d = TRUE)
r36 <- s2$census_1936_reduced
for (sx in c("m", "f")) {
  x3 <- A3; x3$urate <- r36[[paste0("unemployment_rate_w_", sx)]][match(x3$unit_id, r36$StndrdN)]
  mm <- fit("H3", x3); r <- se_type(mm, T_H3, "HC2"); q <- qt(1 - ALPHA / 2, r$df)
  add(16, "H3", paste0(c(m = "men", f = "women")[sx], " (non-headline), original data, HC2"), r$b, r$se, r$p, r$b - q * r$se, r$b + q * r$se, nobs(mm),
      "HC2 t(N-K), Bonferroni level", a4d = TRUE)
}

# ================================================================ 17-24 H2
s <- T2$s; Tt <- T2$Tt; theta <- T2$theta; n <- nrow(s)
ri_p0 <- function(y, Tidx, yr, mo) { X <- model.matrix(~ factor(yr) + factor(mo)); a <- as.vector(y - X %*% qr.solve(X, y))
  mean(abs(a) >= abs(a[Tidx]) - TOL_TIE * max(abs(a))) }
yhatT <- s$y[Tt] - theta     # FE prediction from the model without the dummy fitted on the other 107 cells
chk <- lm(y ~ factor(year) + factor(month), data = s[-Tt, ]); stopifnot(abs(predict(chk, s[Tt, ]) - yhatT) < 1e-8)
add(17, "H2-pct", "denominator: counterfactual July 1919 count", 100 * theta / yhatT, NA, NA, NA, NA, n, "100*theta/yhat_T")
add(17, "H2-pct", "denominator: July mean 1915-1923", 100 * theta / mean(s$y[s$month == 7]), NA, NA, NA, NA, n, "100*theta/mean(July)")
m2 <- lm(y ~ D + factor(year) + factor(month), data = s); r <- se_type(m2, "D", "const"); q <- qt(1 - ALPHA / 2, r$df)
add(18, "H2-n", "classical OLS SE and t-test (as published)", r$b, r$se, r$p, r$b - q * r$se, r$b + q * r$se, n, "t(N-K), Bonferroni level")
thc <- T2$a / diag(T2$M)     # one-cell dummy coefficient for each cell
add(19, "H2-n", "placebo one-cell dummies: rank of |theta_T| among 108", theta, NA, mean(abs(thc) >= abs(thc[Tt]) - 1e-9), NA, NA, n,
    "share of cells with |theta_c| >= |theta_T|", note = sprintf("rank %d of 108; min %.1f, max %.1f; next most negative %.1f",
    rank(-abs(thc))[Tt], min(thc), max(thc), sort(thc)[2]))
E <- which(s$year %in% 1919:1920 & seq_len(n) != Tt); ref <- setdiff(seq_len(n), E)
add(20, "H2-n", "diagnostic: rank of |u_T(0)| among cells outside Jan 1919-Dec 1920 (fit on all 108)", theta, NA,
    mean(abs(T2$a[ref]) >= abs(T2$a[Tt])), NA, NA, length(ref), "share of reference cells with score >= |u_T|; not a test",
    note = sprintf("rank %d of %d; no finite-sample guarantee", sum(abs(T2$a[ref]) >= abs(T2$a[Tt])), length(ref)))
s$time <- seq_len(n)
g21 <- tryCatch(gls(y ~ D + factor(year) + factor(month), data = s, correlation = corAR1(form = ~ time), method = "REML"), error = function(e) NULL)
if (!is.null(g21)) { tt <- summary(g21)$tTable["D", ]
  add(21, "H2-n", "FGLS AR(1), year and month FE (nlme::gls)", tt[1], tt[2], tt[4], NA, NA, n, "gls t-test",
      note = sprintf("phi %.3f", coef(g21$modelStruct$corStruct, unconstrained = FALSE))) }
m22 <- lm(log(y) ~ D + factor(year) + factor(month), data = s); r <- se_type(m22, "D", "const")
add(22, "H2-n", "log count outcome (coefficient x100, log-percentage)", 100 * r$b, 100 * r$se, r$p, NA, NA, n, "classical t",
    note = sprintf("randomization p(0) on log scale %.4f", ri_p0(log(s$y), Tt, s$year, s$month)), a4d = TRUE)
w <- s$year >= 1916 & s$year <= 1922; sw <- s[w, ]; Tw <- which(sw$year == 1919 & sw$month == 7)
m23 <- lm(y ~ D + factor(year) + factor(month), data = sw); r <- se_type(m23, "D", "const")
add(23, "H2-n", "birth window 1916-1922", r$b, r$se, r$p, NA, NA, nrow(sw), "classical t", a4d = TRUE,
    note = sprintf("randomization p(0) %.4f (1/%d minimum)", ri_p0(sw$y, Tw, sw$year, sw$month), nrow(sw)))
T8 <- which(s$year == 1919 & s$month == 8); s$D8 <- as.integer(seq_len(n) == T8)
m24 <- lm(y ~ D8 + factor(year) + factor(month), data = s); r <- se_type(m24, "D8", "const")
add(24, "H2-n", "diagnostic: 8-month offset (dummy on Aug 1919 births)", r$b, r$se, r$p, NA, NA, n, "classical t", a4d = TRUE,
    note = sprintf("randomization p(0) %.4f", ri_p0(s$y, T8, s$year, s$month)))

out <- do.call(rbind, rows); rownames(out) <- NULL
write.csv(out, file.path(OUT, "sensitivities.csv"), row.names = FALSE)
print(out[, c("item", "row", "label", "estimate", "se", "p", "ci_lo", "ci_hi", "n")], digits = 4)
cat("04_sensitivities done\n")
