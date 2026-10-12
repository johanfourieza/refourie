# P03_BoF17 S6 02: K3-K4 bootstrap ARDL bounds procedure (McNown, Sam and Goh 2018), card §4, plus the
# bootstrap-based K3-K4 sensitivities of §5C (fixed lags, BIC, Cape Town dependent, interpolation, block residuals).
source(here::here("P03_BoF17", "modern", "00_common.R"))
suppressMessages({library(parallel); library(urca)})
LAG <- function(v, j) if (j == 0) v else c(rep(NA, j), head(v, -j))

## ---- design matrix on a calendar series (true calendar-month lags) ----
build <- function(y, x) {
  dy <- c(NA, diff(y)); dx <- c(NA, diff(x))
  D <- data.frame(dy = dy, y1 = LAG(y, 1), x1 = LAG(x, 1), dx0 = dx)
  for (j in 1:3) { D[[paste0("dy", j)]] <- LAG(dy, j); D[[paste0("dx", j)]] <- LAG(dx, j) }
  D
}
rhs <- function(p, q) c("y1", "x1", "dx0", if (p) paste0("dy", 1:p), if (q) paste0("dx", 1:q))
ols <- function(yv, X) { f <- lm.fit(X, yv); list(rss = sum(f$residuals^2), n = length(yv), k = ncol(X), f = f) }
ic <- function(o, pen) o$n * (log(2 * pi) + 1 + log(o$rss / o$n)) + pen * (o$k + 1)   # = stats::AIC / BIC of lm
## three statistics of one (p, q) on its own maximal complete-case sample, restricted to rows `rows`
stats3 <- function(D, p, q, rows) {
  v <- rhs(p, q); Z <- D[rows, c("dy", v)]; Z <- Z[complete.cases(Z), , drop = FALSE]; n <- nrow(Z)
  out <- c(p = p, q = q, n = n, df = NA, F_ov = NA, t_dep = NA, F_ind = NA)
  if (n <= length(v) + 1) return(out)
  X <- cbind(1, as.matrix(Z[v])); m1 <- ols(Z$dy, X); df1 <- n - ncol(X); out["df"] <- df1
  if (df1 < 20 || m1$f$rank < ncol(X)) return(out)
  m0 <- ols(Z$dy, X[, !colnames(X) %in% c("y1", "x1")]); mi <- ols(Z$dy, X[, colnames(X) != "x1"])
  s2 <- m1$rss / df1; V <- s2 * chol2inv(qr.R(m1$f$qr)); jy <- which(colnames(X)[m1$f$qr$pivot] == "y1")
  out[c("F_ov", "t_dep", "F_ind")] <- c(((m0$rss - m1$rss) / 2) / s2, m1$f$coefficients[["y1"]] / sqrt(V[jy, jy]), (mi$rss - m1$rss) / s2)
  out
}
## steps 1-3: selection over the 16 models on the common (p = q = 3) sample, ties -> fewer params, then smaller p
select_fit <- function(D, rows, crit = c("aic", "bic"), fixed = NULL) {
  if (!is.null(fixed)) return(stats3(D, fixed, fixed, rows))
  crit <- match.arg(crit); cs <- rows[complete.cases(D[rows, c("dy", rhs(3, 3))])]
  if (length(cs) < 12) return(c(p = NA, q = NA, n = NA, df = NA, F_ov = NA, t_dep = NA, F_ind = NA))
  g <- expand.grid(p = 0:3, q = 0:3)
  g$ic <- mapply(function(p, q) { o <- ols(D$dy[cs], cbind(1, as.matrix(D[cs, rhs(p, q)]))); ic(o, if (crit == "aic") 2 else log(o$n)) }, g$p, g$q)
  g$k <- g$p + g$q; g <- g[order(round(g$ic, 9), g$k, g$p), ]
  stats3(D, g$p[1], g$q[1], rows)
}
all_specs <- function(D, rows) rbind(aic = select_fit(D, rows, "aic"), bic = select_fit(D, rows, "bic"),
  fix1 = select_fit(D, rows, fixed = 1), fix2 = select_fit(D, rows, fixed = 2), fix3 = select_fit(D, rows, fixed = 3))

## ---- null DGP (step 4) ----
null_dgp <- function(y, x) {
  D <- build(y, x); D$ddx <- D$dx0
  xv <- c("x1", "y1", paste0("dx", 1:3), paste0("dy", 1:3)); yv <- c("dx0", paste0("dy", 1:3), paste0("dx", 1:3))
  mx <- lm(reformulate(xv, "ddx"), D); my <- lm(reformulate(yv, "dy"), D)
  ux <- rep(NA, nrow(D)); uy <- ux; ux[as.integer(names(resid(mx)))] <- resid(mx); uy[as.integer(names(resid(my)))] <- resid(my)
  pool <- which(is.finite(ux) & is.finite(uy))
  list(bx = coef(mx), by = coef(my), U = cbind(ux[pool] - mean(ux[pool]), uy[pool] - mean(uy[pool])), mx = mx, my = my)
}
gen <- function(dgp, Tt = 170, mode = "iid", l = 12) {
  P <- nrow(dgp$U)
  idx <- if (mode == "iid") sample.int(P, Tt, replace = TRUE) else { s <- sample.int(P - l + 1, ceiling(Tt / l), replace = TRUE); as.vector(outer(0:(l - 1), s, `+`))[1:Tt] }
  u <- dgp$U[idx, , drop = FALSE]; bx <- dgp$bx; by <- dgp$by
  x <- y <- dx <- dy <- numeric(Tt + 3)   # three leading zeros = zero initial lags and levels
  for (t in 4:(Tt + 3)) {
    dx[t] <- bx[1] + bx["x1"] * x[t - 1] + bx["y1"] * y[t - 1] + sum(bx[paste0("dx", 1:3)] * dx[t - 1:3]) + sum(bx[paste0("dy", 1:3)] * dy[t - 1:3]) + u[t - 3, 1]
    x[t] <- x[t - 1] + dx[t]
    dy[t] <- by[1] + by["dx0"] * dx[t] + sum(by[paste0("dy", 1:3)] * dy[t - 1:3]) + sum(by[paste0("dx", 1:3)] * dx[t - 1:3]) + u[t - 3, 2]
    y[t] <- y[t - 1] + dy[t]
  }
  list(y = y[-(1:3)], x = x[-(1:3)])
}
## one replicate: generate 50 + 120, mask grid months as observed, (optionally interpolate), repeat steps 1-3
one_rep <- function(seed, dgp, my, mx, mode, do_interp) {
  assign(".Random.seed", seed, envir = globalenv())
  s <- gen(dgp, 170, mode); g <- 51:170; y <- s$y; x <- s$x
  y[g][my] <- NA; x[g][mx] <- NA
  if (do_interp) { y[g] <- interp(y[g]); x[g] <- interp(x[g]) }
  as.vector(t(all_specs(build(y, x), g)))
}
seeds_for <- function(B) { set.seed(SEED, kind = "L'Ecuyer-CMRG"); s <- .Random.seed; out <- vector("list", B)
  for (b in 1:B) { out[[b]] <- s; s <- nextRNGStream(s) }; out }
run_boot <- function(cl, y, x, B, mode = "iid", do_interp = FALSE) {
  dgp <- null_dgp(y, x); my <- !is.finite(y); mx <- !is.finite(x)
  r <- parLapply(cl, seeds_for(B), one_rep, dgp = dgp, my = my, mx = mx, mode = mode, do_interp = do_interp)
  arr <- array(unlist(r), dim = c(7, 5, B), dimnames = list(c("p", "q", "n", "df", "F_ov", "t_dep", "F_ind"), c("aic", "bic", "fix1", "fix2", "fix3"), NULL))
  arr
}
cvs <- function(a) { # a: 7 x B matrix for one spec; critical values + MC SE over 10 consecutive batches
  B <- ncol(a); bt <- cut(seq_len(B), 10, labels = FALSE)
  f <- function(v) c(F_ov_975 = q7(v["F_ov", ], .975), F_ov_95 = q7(v["F_ov", ], .95), F_ov_90 = q7(v["F_ov", ], .90),
    F_ind_975 = q7(v["F_ind", ], .975), F_ind_95 = q7(v["F_ind", ], .95), F_ind_90 = q7(v["F_ind", ], .90),
    t_025 = q7(v["t_dep", ], .025), t_05 = q7(v["t_dep", ], .05), t_10 = q7(v["t_dep", ], .10))
  cv <- f(a); se <- apply(sapply(1:10, function(k) f(a[, bt == k, drop = FALSE])), 1, sd) / sqrt(10)
  list(cv = cv, se = se, fail = mean(!is.finite(a["F_ov", ]) | !is.finite(a["F_ind", ]) | !is.finite(a["t_dep", ])))
}
rejects <- function(st, cv, lev) c(F_ov = st[["F_ov"]] > cv[[paste0("F_ov_", lev)]], F_ind = st[["F_ind"]] > cv[[paste0("F_ind_", lev)]], t_dep = st[["t_dep"]] < cv[[paste0("t_", ifelse(lev == "975", "025", "10"))]])
cat_rows <- function(r25, r10) if (all(r25)) "row1-2" else if (all(r10)) "row3" else "row4"
## step 7: is any deciding comparison within 2 MC SE of its critical value?
boundary <- function(st, C) {
  r25 <- rejects(st, C$cv, "975"); r10 <- rejects(st, C$cv, "90"); base <- cat_rows(r25, r10)
  nm25 <- c(F_ov = "F_ov_975", F_ind = "F_ind_975", t_dep = "t_025"); nm10 <- c(F_ov = "F_ov_90", F_ind = "F_ind_90", t_dep = "t_10")
  near <- FALSE
  for (s in names(nm25)) {
    if (abs(st[[s]] - C$cv[[nm25[s]]]) < 2 * C$se[[nm25[s]]]) { a <- r25; a[s] <- !a[s]; if (cat_rows(a, r10) != base) near <- TRUE }
    if (abs(st[[s]] - C$cv[[nm10[s]]]) < 2 * C$se[[nm10[s]]]) { a <- r10; a[s] <- !a[s]; if (cat_rows(r25, a) != base) near <- TRUE }
  }
  near
}

## ---- diagnostics D1-D3 on the selected model ----
longest_run <- function(v) { ok <- is.finite(v); r <- rle(ok); e <- cumsum(r$lengths); s <- e - r$lengths + 1
  k <- which(r$values); if (!length(k)) return(numeric(0)); k <- k[which.max(r$lengths[k])]; v[s[k]:e[k]] }
D1 <- function(v) { z <- longest_run(c(NA, diff(v))); if (length(z) < 30) return(c(run = length(z), tau = NA, cv5 = NA, pass = FALSE))
  u <- ur.df(z, type = "drift", lags = 6, selectlags = "AIC"); tau <- u@teststat[1, "tau2"]; cv <- u@cval["tau2", "5pct"]
  c(run = length(z), tau = tau, cv5 = cv, pass = tau < cv) }
diagnostics <- function(y, x, sel) {
  D <- build(y, x); v <- rhs(sel[["p"]], sel[["q"]]); rows <- which(complete.cases(D[c("dy", v)]))
  m <- lm(reformulate(v, "dy"), D[rows, ]); e <- rep(NA, nrow(D)); e[rows] <- resid(m)
  E <- sapply(1:12, function(j) { z <- LAG(e, j); z[!is.finite(z)] <- 0; z[rows] })
  aux <- lm(resid(m) ~ as.matrix(D[rows, v]) + E); LM <- length(rows) * summary(aux)$r.squared; p_bg <- 1 - pchisq(LM, 12)
  d1y <- D1(y); d1x <- D1(x)
  beta <- -coef(m)[["x1"]] / coef(m)[["y1"]]; D$ect1 <- D$y1 - beta * D$x1
  m3 <- lm(dx0 ~ dx1 + dx2 + dx3 + dy1 + dy2 + dy3 + ect1, D); p3 <- summary(m3)$coefficients["ect1", 4]       # D3 as implemented (DEVIATIONS D1)
  m3l <- lm(dx0 ~ x1 + y1 + dx1 + dx2 + dx3 + dy1 + dy2 + dy3 + ect1, D); lit_ok <- !is.na(coef(m3l)[["ect1"]])  # literal card form
  c(D1_dy_run = d1y[["run"]], D1_dy_tau = d1y[["tau"]], D1_dy_cv5 = d1y[["cv5"]], D1_dx_run = d1x[["run"]], D1_dx_tau = d1x[["tau"]], D1_dx_cv5 = d1x[["cv5"]],
    D1_pass = as.numeric(d1y[["pass"]] && d1x[["pass"]]), D2_LM = LM, D2_p = p_bg, D2_pass = as.numeric(p_bg >= 0.05),
    D3_beta = beta, D3_t = summary(m3)$coefficients["ect1", 3], D3_p = p3, D3_pass = as.numeric(p3 >= 0.05), D3_literal_estimable = as.numeric(lit_ok))
}

## ---- run ----
cl <- makeCluster(8); clusterEvalQ(cl, suppressMessages(library(stats)))
clusterExport(cl, c("LAG", "build", "rhs", "ols", "ic", "stats3", "select_fit", "all_specs", "gen", "interp", "one_rep"))
t0 <- Sys.time(); res <- list(); obs_all <- list(); aic_tabs <- list(); diag <- list(); cvtab <- list()
for (k in list(c("K3", "Wheat"), c("K4", "Mealies"))) {
  yK <- lp("Kimberley", k[2]); xC <- lp("Cape Town", k[2])
  ## observed: cross-check the fast fit against lm / anova / stats::AIC
  D <- build(yK, xC); obs <- all_specs(D, 1:120); sel <- obs["aic", ]
  v <- rhs(sel[["p"]], sel[["q"]]); Z <- D[complete.cases(D[c("dy", v)]), ]
  m1 <- lm(reformulate(v, "dy"), Z); m0 <- lm(reformulate(setdiff(v, c("y1", "x1")), "dy"), Z); mi <- lm(reformulate(setdiff(v, "x1"), "dy"), Z)
  stopifnot(abs(anova(m0, m1)$F[2] - sel[["F_ov"]]) < 1e-8, abs(anova(mi, m1)$F[2] - sel[["F_ind"]]) < 1e-8,
            abs(summary(m1)$coefficients["y1", 3] - sel[["t_dep"]]) < 1e-8)
  cs <- which(complete.cases(D[c("dy", rhs(3, 3))]))
  aic_tabs[[k[1]]] <- do.call(rbind, lapply(0:3, function(p) do.call(rbind, lapply(0:3, function(q)
    data.frame(claim = k[1], p = p, q = q, n_common = length(cs), AIC = AIC(lm(reformulate(rhs(p, q), "dy"), D[cs, ])))))))
  diag[[k[1]]] <- c(claim = k[1], diagnostics(yK, xC, sel))
  ## variants: central (+ fixed lags, BIC), Cape Town dependent, interpolated, block residuals
  var <- list(central = list(y = yK, x = xC, mode = "iid", ip = FALSE), cape_dep = list(y = xC, x = yK, mode = "iid", ip = FALSE),
              interp = list(y = interp(yK), x = interp(xC), mode = "iid", ip = TRUE, ym = yK, xm = xC), block12 = list(y = yK, x = xC, mode = "block", ip = FALSE))
  for (vn in names(var)) {
    V <- var[[vn]]; Bv <- B
    o <- all_specs(build(V$y, V$x), 1:120)
    ## the interpolated variant uses the raw missingness mask before interpolation in each replicate
    yb <- if (V$ip) V$ym else V$y; xb <- if (V$ip) V$xm else V$x
    dgp_y <- if (V$ip) V$y else yb; dgp_x <- if (V$ip) V$x else xb
    bootf <- function(Bv) { dgp <- null_dgp(dgp_y, dgp_x)
      r <- parLapply(cl, seeds_for(Bv), one_rep, dgp = dgp, my = !is.finite(yb), mx = !is.finite(xb), mode = V$mode, do_interp = V$ip)
      array(unlist(r), dim = c(7, 5, Bv), dimnames = list(c("p", "q", "n", "df", "F_ov", "t_dep", "F_ind"), c("aic", "bic", "fix1", "fix2", "fix3"), NULL)) }
    arr <- bootf(B); flag <- "none"
    if (vn == "central") { C <- cvs(arr[, "aic", ])
      if (boundary(o["aic", ], C)) { Bv <- 99999; arr <- bootf(Bv); C <- cvs(arr[, "aic", ]); flag <- if (boundary(o["aic", ], C)) "boundary unresolved" else "resolved at 99,999" } }
    saveRDS(arr, file.path(scr, paste0("boot_", k[1], "_", vn, ".rds")))
    specs <- if (vn == "central") c("aic", "bic", "fix1", "fix2", "fix3") else "aic"
    for (sp in specs) { C <- cvs(arr[, sp, ])
      cvtab[[length(cvtab) + 1]] <- data.frame(claim = k[1], variant = vn, spec = sp, B = Bv, mc_flag = if (sp == "aic") flag else NA, fail_rate = C$fail,
        t(o[sp, ]), t(C$cv), setNames(as.data.frame(t(C$se)), paste0("se_", names(C$se))),
        all3_25 = all(rejects(o[sp, ], C$cv, "975")), all3_10 = all(rejects(o[sp, ], C$cv, "90")), check.names = FALSE) }
    cat(k[1], vn, "done", format(Sys.time() - t0), "\n")
  }
}
stopCluster(cl)
cvtab <- bind_rows(cvtab); print(cvtab[, c("claim", "variant", "spec", "B", "p", "q", "n", "df", "F_ov", "t_dep", "F_ind", "F_ov_975", "F_ind_975", "t_025", "all3_25", "all3_10", "fail_rate")], digits = 3)
diag <- bind_rows(lapply(diag, function(z) as.data.frame(as.list(z)))); print(diag)
write.csv(cvtab, file.path(odir, "bounds_boot.csv"), row.names = FALSE)
write.csv(bind_rows(aic_tabs), file.path(odir, "bounds_aic_table.csv"), row.names = FALSE)
write.csv(diag, file.path(odir, "bounds_diagnostics.csv"), row.names = FALSE)
cat("runtime:", format(Sys.time() - t0), "\n")
