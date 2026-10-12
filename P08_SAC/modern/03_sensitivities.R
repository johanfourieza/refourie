# =============================================================================
# P08_SAC  S6 modern reanalysis  --  03_sensitivities.R
# Reported sensitivities, card §5.1-5.9 and §5.11 (none decides a verdict).
# §5.9e (quantiles) and §5.10 (persons, missingness) are descriptive and live
# in 04_descriptives.R. Output: output/sensitivities.csv (aggregates only).
# =============================================================================
suppressMessages({library(tidyverse); library(sandwich); library(clubSandwich)
  library(fwildclusterboot); library(dqrng); library(parallel)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
MOD <- file.path(PROJ, "P08_SAC", "modern"); OUT <- file.path(MOD, "output")
SCR <- dscratch("P08_SAC", "modern")
d <- readRDS(file.path(SCR, "sac_all.rds")); W <- readRDS(file.path(SCR, "wage_sample.rds"))
stockA <- readRDS(file.path(SCR, "stockA.rds"))
ALPHA <- 0.01; SEED <- 20261011; B <- 9999; BB <- 4999; NCORE <- max(1, min(8, detectCores() - 1))
W <- W %>% mutate(ym = factor(ym), place_c = factor(place_c))
first <- d %>% filter(repeatlast == 0) %>% mutate(ym = factor(ym), place_c = factor(place_c))
res <- list()
add <- function(section, row, variant, estimate, se = NA, p = NA, lo = NA, hi = NA, n = NA, note = "")
  res[[length(res) + 1]] <<- tibble(section, row, variant, estimate, se, p, ci99_lo = lo, ci99_hi = hi, n, note)
tci <- function(b, se, df) { q <- qt(1 - ALPHA / 2, df); c(p = 2 * pt(-abs(b / se), df), lo = b - q * se, hi = b + q * se) }
add_V <- function(section, row, variant, m, term, V, df, note = "") {
  b <- unname(coef(m)[term]); se <- sqrt(V[term, term]); z <- tci(b, se, df)
  add(section, row, variant, b, se, z[["p"]], z[["lo"]], z[["hi"]], nobs(m), note) }
wcr <- function(m, term, clustid, type = "webb", bootcluster = "max", seed = SEED) {
  set.seed(seed); dqrng::dqset.seed(seed)
  tryCatch({ o <- boottest(m, param = term, B = B, clustid = clustid, bootcluster = bootcluster, type = type,
                           sign_level = ALPHA, impose_null = TRUE, p_val_type = "two-tailed", conf_int = TRUE)
    list(p = o$p_val, lo = o$conf_int[1], hi = o$conf_int[2], ok = TRUE) },
    error = function(e) list(p = NA, lo = NA, hi = NA, ok = FALSE, msg = conditionMessage(e))) }
add_wcr <- function(section, row, variant, m, term, clustid, ...) {
  w <- wcr(m, term, clustid, ...)
  add(section, row, variant, unname(coef(m)[term]), NA, w$p, w$lo, w$hi, nobs(m), if (w$ok) "" else paste("WCR failed:", w$msg)) }
cr2 <- function(section, row, variant, m, term, cl) {
  ct <- coef_test(m, vcov = "CR2", cluster = cl, test = "Satterthwaite", coefs = term)
  ci <- conf_int(m, vcov = "CR2", cluster = cl, level = 1 - ALPHA, coefs = term, test = "Satterthwaite")
  add(section, row, variant, ct$beta, ct$SE, ct$p_Satt, ci$CI_L, ci$CI_U, nobs(m), sprintf("BM df %.1f", ct$df_Satt)) }

# ------------------------------------------------ base models -------------
f4 <- lwage ~ afr + age + height + weight + married + hisco_f + reg_f + yr_f
m4 <- lm(f4, data = W); dfr <- df.residual(m4)
terms4 <- c(I4 = "afr", I5 = "reg_f1")

# ================================================ §5.1 inference variants ==
for (h in names(terms4)) { tm <- terms4[[h]]
  add_V("5.1", h, "HC1, t(N-k)", m4, tm, vcovHC(m4, type = "HC1"), dfr)
  add_V("5.1", h, "HC3, t(N-k)", m4, tm, vcovHC(m4, type = "HC3"), dfr)
  cr2("5.1", h, "CR2 by EYear x EMonth, BM df", m4, tm, W$ym)
  add_wcr("5.1", h, "WCR Rademacher, clusters EYear x EMonth", m4, tm, "ym", type = "rademacher") }
# difference-in-means rows as regressions on a group dummy
h1 <- first %>% filter(regiondum %in% c(1, 9), !is.na(height)) %>% mutate(g = as.numeric(regiondum == 9))
h2 <- first %>% filter(regiondum %in% c(5, 9, 1, 8, 10), !is.na(height), !is.na(birthyear), birthyear >= 1860, birthyear <= 1885) %>%
  mutate(g = as.numeric(regiondum %in% c(5, 9)))
h3 <- first %>% filter(!is.na(regiondum), !is.na(wage)) %>% mutate(g = as.numeric(regiondum == 5))
dm <- list(I3a = list(dat = h1, y = "height"), I3b = list(dat = h2, y = "height"), `I6-C` = list(dat = h3, y = "wage"))
for (h in names(dm)) { dd <- dm[[h]]$dat; mm <- lm(reformulate("g", dm[[h]]$y), data = dd)
  add_V("5.1", h, "HC1, t(N-2)", mm, "g", vcovHC(mm, type = "HC1"), df.residual(mm))
  add_V("5.1", h, "HC3, t(N-2)", mm, "g", vcovHC(mm, type = "HC3"), df.residual(mm))
  cr2("5.1", h, "CR2 by EYear x EMonth, BM df", mm, "g", dd$ym)
  # §5.2 for difference rows: CR1 by place and two-way (place, year x month)
  Gp <- n_distinct(dd$place_c); Gy <- n_distinct(dd$ym)
  add_V("5.2", h, "CR1 by place, t(G-1)", mm, "g", vcovCL(mm, cluster = ~place_c, type = "HC1"), Gp - 1)
  add_V("5.2", h, "CR1 two-way place x (EYear x EMonth), t(min G-1)", mm, "g", vcovCL(mm, cluster = ~place_c + ym, type = "HC1", multi0 = FALSE), min(Gp, Gy) - 1) }

# ================================================ §5.2 dependence by place ==
Gp <- n_distinct(W$place_c)
for (h in names(terms4)) { tm <- terms4[[h]]
  add_V("5.2", h, "CR1 by place, t(G-1)", m4, tm, vcovCL(m4, cluster = ~place_c, type = "HC1"), Gp - 1)
  add_V("5.2", h, "CR1 two-way place x (EYear x EMonth), t(min G-1)", m4, tm,
        vcovCL(m4, cluster = ~place_c + ym, type = "HC1", multi0 = FALSE), min(Gp, nlevels(droplevels(W$ym))) - 1)
  add_wcr("5.2", h, "WCR Webb, clusters place", m4, tm, "place_c")
  add_wcr("5.2", h, "WCR Webb, two-way place x (EYear x EMonth), bootcluster = place", m4, tm, c("place_c", "ym"), bootcluster = "place_c") }
add("5.2", "all", "number of place clusters (wage sample; missing place = one 'unknown' cluster)", Gp, n = nrow(W),
    note = sprintf("share of wage sample in 'unknown': %.3f", mean(W$place_c == "unknown")))

# ============================================ §5.3a S3 surname rule ========
W <- W %>% mutate(afr_A = afr)
mS3 <- lm(update(f4, . ~ . - afr + afr_S3), data = W)
add_V("5.3a", "I4", "S3 rule boer_surname(), spec 4, HC3", mS3, "afr_S3", vcovHC(mS3, type = "HC3"), df.residual(mS3))
add_wcr("5.3a", "I4", "S3 rule boer_surname(), spec 4, WCR Webb", mS3, "afr_S3", "ym")
add_V("5.3a", "I5", "S3 rule boer_surname(), spec 4, HC3", mS3, "reg_f1", vcovHC(mS3, type = "HC3"), df.residual(mS3))
add_wcr("5.3a", "I5", "S3 rule boer_surname(), spec 4, WCR Webb", mS3, "reg_f1", "ym")
add("5.3a", "I4", "SA-born wage-sample recruits on which authors' flag and S3 rule disagree (count)",
    sum(W$sa == 1 & W$afr != W$afr_S3), n = sum(W$sa == 1))

# ============================================ §5.4 compatriot sample setup ==
merge_years <- function(y) { y <- as.integer(y); map <- y
  repeat { cnt <- table(map); small <- as.integer(names(cnt)[cnt < 10]); if (!length(small) || length(cnt) == 1) break
    yy <- min(small); others <- setdiff(as.integer(names(cnt)), yy)
    tgt <- if (any(others < yy)) max(others[others < yy]) else min(others); map[map == yy] <- tgt }
  factor(map) }
Ws <- W %>% filter(sa == 1)
hc_cnt <- table(Ws$hisco)
Ws <- Ws %>% mutate(hisco_m = relevel(factor(if_else(as.character(hisco) %in% names(hc_cnt)[hc_cnt >= 10], as.character(hisco), "other")),
                                      ref = if ("6" %in% names(hc_cnt)[hc_cnt >= 10]) "6" else "other"),
                    yr_m = merge_years(eyear), boer = as.numeric(regiondum == 5), y1902 = as.numeric(eyear == 1902), ym = droplevels(ym))
fS <- function(v) as.formula(paste("lwage ~", v, "+ age + height + weight + married + hisco_m + boer + yr_m"))
add("5.4", "all", "SA-born spec 4 sample: N; HISCO levels after merge; year levels after merge", nrow(Ws),
    note = sprintf("HISCO levels %d; year levels %s", nlevels(Ws$hisco_m), paste(levels(Ws$yr_m), collapse = "/")), n = nrow(Ws))

# ============================================ §5.3b score: construction ====
FT <- first  # SAC first-term file; clusters = ym
names_all <- sort(unique(c(stockA$nsn, FT$nsn[FT$nsn != ""])))
idA <- match(stockA$nsn, names_all); famA <- as.integer(factor(stockA$family_id)); nfam <- max(famA)
FT$nid <- match(FT$nsn, names_all)            # NA for empty names
FT$cl <- as.integer(FT$ym); ncl <- max(FT$cl)
isB <- FT$regiondum %in% c(1, 7, 8, 10) & !is.na(FT$nid)
isSA <- FT$regiondum %in% c(5, 9)
ALPH <- 0.5; NN <- length(names_all)
score_fit <- function(wF, wA) {
  # wF: weight per F row (cluster multiplicity); wA: weight per stock-A record (family multiplicity)
  nA <- numeric(NN); ta <- rowsum(wA, idA); nA[as.integer(rownames(ta))] <- ta[, 1]
  nB <- numeric(NN); tb <- rowsum(wF[isB], FT$nid[isB]); nB[as.integer(rownames(tb))] <- tb[, 1]
  NA_ <- sum(nA); NB_ <- sum(nB); VA <- sum(nA > 0); VB <- sum(nB > 0)
  fA <- (nA + ALPH) / (NA_ + ALPH * (VA + 1)); fB <- (nB + ALPH) / (NB_ + ALPH * (VB + 1))
  p <- rep(NA_real_, nrow(FT)); p[!isSA] <- 0; pis <- c(`5` = NA, `9` = NA); fail <- FALSE
  for (r in c(5, 9)) {
    ir <- which(FT$regiondum == r & !is.na(FT$nid) & wF > 0)
    seen <- ir[(nA[FT$nid[ir]] + nB[FT$nid[ir]]) > 0]
    if (!length(seen)) { fail <- TRUE; next }
    a_ <- fA[FT$nid[seen]]; b_ <- fB[FT$nid[seen]]; ws <- wF[seen]
    pi <- 0.5; conv <- FALSE
    for (it in 1:1000) { post <- pi * a_ / (pi * a_ + (1 - pi) * b_); pin <- sum(ws * post) / sum(ws)
      if (abs(pin - pi) < 1e-8) { pi <- pin; conv <- TRUE; break }; pi <- pin }
    if (!conv || pi < 1e-6 || pi > 1 - 1e-6) fail <- TRUE
    pis[as.character(r)] <- pi
    iall <- which(FT$regiondum == r & !is.na(FT$nid))
    sn <- (nA[FT$nid[iall]] + nB[FT$nid[iall]]) > 0
    p[iall] <- ifelse(sn, pi * fA[FT$nid[iall]] / (pi * fA[FT$nid[iall]] + (1 - pi) * fB[FT$nid[iall]]), pi)
  }
  list(p = p, pi = pis, fail = fail) }
s0 <- score_fit(rep(1, nrow(FT)), rep(1, nrow(stockA)))
FT$score <- s0$p
cat("EM pi (full sample):", round(s0$pi, 4), " fail:", s0$fail, "\n")
add("5.3b", "score", "EM pi_r, region 5 (Boer republics)", s0$pi[["5"]]); add("5.3b", "score", "EM pi_r, region 9 (Cape/Natal)", s0$pi[["9"]])
add("5.3b", "score", "SA-born first terms with empty normalised surname (dropped from score rows)", sum(isSA & is.na(FT$nid)))
add("5.3b", "score", "SA-born first terms with names unseen in both stocks (p = pi_r)",
    sum(isSA & !is.na(FT$nid) & !(FT$nid %in% c(idA, FT$nid[isB]))))
W$score <- FT$score[match(W$a_row, FT$a_row)]; Ws$score <- FT$score[match(Ws$a_row, FT$a_row)]

# design matrices for fast refits in the bootstrap
Wsc <- W %>% filter(!is.na(score)); rowW <- match(Wsc$a_row, FT$a_row)
XW <- model.matrix(update(f4, . ~ . - afr + score), data = Wsc); jW <- which(colnames(XW) == "score")
Wssc <- Ws %>% filter(!is.na(score)); rowWs <- match(Wssc$a_row, FT$a_row)
XS <- model.matrix(fS("score"), data = Wssc); jS <- which(colnames(XS) == "score")
fitw <- function(X, y, w, j) { k <- w > 0; f <- lm.wfit(X[k, , drop = FALSE], y[k], w[k]); unname(f$coefficients[j]) }
b_score_pooled <- fitw(XW, Wsc$lwage, rep(1, nrow(Wsc)), jW)
b_score_sa <- fitw(XS, Wssc$lwage, rep(1, nrow(Wssc)), jS)

# ============================================ §5.3b score: bootstrap =======
boot_draw <- function(i) {
  wcl <- tabulate(sample.int(ncl, ncl, replace = TRUE), ncl); wfa <- tabulate(sample.int(nfam, nfam, replace = TRUE), nfam)
  wF <- wcl[FT$cl]; wA <- wfa[famA]
  s <- score_fit(wF, wA)
  pSA <- s$p[isSA & wF > 0 & !is.na(s$p)]
  if (s$fail || length(unique(round(pSA, 12))) <= 1) return(c(fail = 1, b = NA, bs = NA))
  XW[, jW] <- s$p[rowW]; XS[, jS] <- s$p[rowWs]
  b <- fitw(XW, Wsc$lwage, wF[rowW], jW); bs <- fitw(XS, Wssc$lwage, wF[rowWs], jS)
  c(fail = as.numeric(is.na(b)), b = b, bs = bs) }
cl <- makeCluster(NCORE); RNGkind("L'Ecuyer-CMRG"); set.seed(SEED); clusterSetRNGStream(cl, SEED)
clusterExport(cl, c("FT", "idA", "famA", "nfam", "ncl", "isB", "isSA", "NN", "ALPH", "score_fit", "XW", "XS", "jW", "jS",
                    "rowW", "rowWs", "Wsc", "Wssc", "fitw"))
t0 <- Sys.time(); bt <- do.call(rbind, parLapply(cl, seq_len(BB), boot_draw)); stopCluster(cl)
cat("score bootstrap:", format(Sys.time() - t0), "\n")
nfail <- sum(bt[, "fail"] == 1); ok <- bt[, "fail"] == 0; unstable <- nfail / BB > 0.05
qq <- function(x) quantile(x, c(ALPHA / 2, 1 - ALPHA / 2), na.rm = TRUE, names = FALSE)
ciP <- if (unstable) c(NA, NA) else qq(bt[ok, "b"]); ciS <- if (unstable) c(NA, NA) else qq(bt[ok, "bs"])
add("5.3b", "I4", "probabilistic surname score (UNVALIDATED, different estimand), spec 4 pooled; percentile 99% CI, joint SAC-cluster + SAF-family bootstrap",
    b_score_pooled, sd(bt[ok, "b"]), NA, ciP[1], ciP[2], nrow(Wsc), sprintf("B=%d, failed draws %d%s", BB, nfail, if (unstable) "; UNSTABLE (>5%% failed)" else ""))
add("5.4", "I4", "SA-born only, probabilistic score (UNVALIDATED, different estimand); percentile 99% CI",
    b_score_sa, sd(bt[ok, "bs"], na.rm = TRUE), NA, ciS[1], ciS[2], nrow(Wssc),
    sprintf("B=%d, failed draws %d; SA-born refit not identified in %d further draws", BB, nfail, sum(ok & is.na(bt[, "bs"]))))
# Languages diagnostic (weak): SA-born first terms with any language entry
L <- FT %>% filter(isSA, lang_any)
add("5.3", "diag", "SA-born first terms with a language entry (n); share recording Dutch", mean(L$dutch_rec), n = nrow(L))
add("5.3", "diag", "agreement with recorded Dutch: authors' flag", mean(L$afr == L$dutch_rec, na.rm = TRUE), n = sum(!is.na(L$afr)))
add("5.3", "diag", "agreement with recorded Dutch: S3 rule", mean(L$afr_S3 == L$dutch_rec), n = nrow(L))
add("5.3", "diag", "agreement with recorded Dutch: score > 0.5", mean((L$score > 0.5) == L$dutch_rec, na.rm = TRUE), n = sum(!is.na(L$score)))
add("5.3", "diag", "mean score | recorded Dutch = 1 minus mean score | = 0",
    mean(L$score[L$dutch_rec == 1], na.rm = TRUE) - mean(L$score[L$dutch_rec == 0], na.rm = TRUE), n = sum(!is.na(L$score)))

# ============================================ §5.4 compatriot sample =========
for (cls in list(c("afr", "authors' flag"), c("afr_S3", "S3 rule"))) {
  mm <- lm(fS(cls[1]), data = Ws)
  add_V("5.4", "I4", paste0("SA-born only, ", cls[2], ", HC3"), mm, cls[1], vcovHC(mm, type = "HC3"), df.residual(mm))
  add_wcr("5.4", "I4", paste0("SA-born only, ", cls[2], ", WCR Webb (clusters EYear x EMonth)"), mm, cls[1], "ym")
  mi <- lm(as.formula(paste("lwage ~", cls[1], "+", cls[1], ":y1902 + age + height + weight + married + hisco_m + boer + yr_m")), data = Ws)
  it <- grep(":y1902", names(coef(mi)), value = TRUE)
  add_V("5.4", "I4", paste0("SA-born only, ", cls[2], ": main effect (non-1902) in year-heterogeneity model, HC3"), mi, cls[1], vcovHC(mi, type = "HC3"), df.residual(mi))
  add_V("5.4", "I4", paste0("SA-born only, ", cls[2], ": D x 1{EYear = 1902}, HC3"), mi, it, vcovHC(mi, type = "HC3"), df.residual(mi)) }
add("5.4", "all", "SA-born spec 4 clusters (EYear x EMonth)", nlevels(Ws$ym), n = nrow(Ws))

# ============================================ §5.5 Oaxaca-Blinder ===========
ob_X <- model.matrix(~ age + height + weight + married + hisco_m + boer + yr_m, data = Ws)
ob_once <- function(w, D) {  # D = 1 Dutch group; English = D == 0. R = mean(E) - mean(D)
  k <- w > 0; y <- Ws$lwage
  wm <- function(z, s) sum(w[s] * z[s]) / sum(w[s])
  sE <- k & D == 0; sD <- k & D == 1
  if (sum(w[sE]) < 2 || sum(w[sD]) < 2) return(rep(NA, 7))
  R <- wm(y, sE) - wm(y, sD)
  xE <- colSums(ob_X[sE, , drop = FALSE] * w[sE]) / sum(w[sE]); xD <- colSums(ob_X[sD, , drop = FALSE] * w[sD]) / sum(w[sD])
  bp <- lm.wfit(cbind(ob_X, D = D)[k, ], y[k], w[k])$coefficients[colnames(ob_X)]; bp[is.na(bp)] <- 0
  bE <- lm.wfit(ob_X[sE, ], y[sE], w[sE])$coefficients; bE[is.na(bE)] <- 0
  bD <- lm.wfit(ob_X[sD, ], y[sD], w[sD])$coefficients; bD[is.na(bD)] <- 0
  Qp <- sum((xE - xD) * bp); QE <- sum((xE - xD) * bE); QD <- sum((xE - xD) * bD)
  c(R = R, Q_pooled = Qp, U_pooled = R - Qp, Q_Eref = QE, U_Eref = R - QE, Q_Dref = QD, U_Dref = R - QD) }
Ws_cl <- as.integer(Ws$ym); nWs <- max(Ws_cl)
for (cls in list(c("afr", "authors' flag (R_A)"), c("afr_S3", "S3 rule (R_B)"))) {
  D <- Ws[[cls[1]]]; est <- ob_once(rep(1, nrow(Ws)), D)
  set.seed(SEED)  # L'Ecuyer-CMRG set above
  bo <- t(sapply(seq_len(BB), function(i) ob_once(tabulate(sample.int(nWs, nWs, replace = TRUE), nWs)[Ws_cl], D)))
  okb <- complete.cases(bo)
  tag <- paste0("OB (decomposition of associations; discrimination not identified), ", cls[2])
  for (v in c("pooled", "Eref", "Dref")) {
    Uv <- est[[paste0("U_", v)]]; Ub <- bo[okb, paste0("U_", v)]
    # joint 99% sup-t band for (R, U - 0.5R)
    th <- c(est[["R"]], Uv - 0.5 * est[["R"]]); tb <- cbind(bo[okb, "R"], Ub - 0.5 * bo[okb, "R"]); s <- apply(tb, 2, sd)
    cst <- quantile(apply(abs(sweep(sweep(tb, 2, colMeans(tb)), 2, s, "/")), 1, max), 1 - ALPHA, names = FALSE)
    if (v == "pooled") add("5.5", "I4-D", paste(tag, "- raw gap R (English minus Dutch), joint 99% sup-t band"), th[1], s[1], NA, th[1] - cst * s[1], th[1] + cst * s[1], nrow(Ws),
                           sprintf("share of draws with R* <= 0: %.3f; failed draws %d", mean(bo[okb, "R"] <= 0), sum(!okb)))
    add("5.5", "I4-D", paste(tag, "- U - 0.5R,", v, "reference, joint 99% sup-t band"), th[2], s[2], NA, th[2] - cst * s[2], th[2] + cst * s[2], nrow(Ws),
        sprintf("explained Q = %.4f; unexplained U = %.4f; U/R (descriptive) = %.3f", est[[paste0("Q_", v)]], Uv, Uv / est[["R"]]))
  } }
# Authors' Descriptives.xlsx 'Oaxaca' re-run: threefold, by sa, lwage ~ age height weight farmer married
oa <- d %>% filter(is.na(region) | region != ".", is.na(age) | age > 18, repeatlast == 0, !is.na(regiondum)) %>%
  filter(complete.cases(lwage, age, height, weight, farmer, married))
X1 <- model.matrix(~ age + height + weight + farmer + married, oa)
g1 <- oa$sa == 0; g2 <- oa$sa == 1
b1 <- lm.fit(X1[g1, ], oa$lwage[g1])$coefficients; b2 <- lm.fit(X1[g2, ], oa$lwage[g2])$coefficients
x1 <- colMeans(X1[g1, ]); x2 <- colMeans(X1[g2, ])
add("5.5", "I4-D", "authors' grouping by sa, threefold: raw difference (sa=0 minus sa=1)", sum(x1 * b1) - sum(x2 * b2), n = nrow(oa),
    note = sprintf("N sa=0 %d, sa=1 %d (published 7,137/289; diff 0.0508)", sum(g1), sum(g2)))
add("5.5", "I4-D", "authors' grouping by sa, threefold: endowments", sum((x1 - x2) * b2), n = nrow(oa), note = "published 0.0302")
add("5.5", "I4-D", "authors' grouping by sa, threefold: coefficients", sum(x2 * (b1 - b2)), n = nrow(oa), note = "published 0.0492")
add("5.5", "I4-D", "authors' grouping by sa, threefold: interaction", sum((x1 - x2) * (b1 - b2)), n = nrow(oa), note = "published -0.0286")

# ============================================ §5.6 prior residence ==========
Wr <- W %>% filter(!is.na(yrs_sa)) %>% droplevels()
mr <- lm(update(f4, . ~ . + yrs_sa), data = Wr)
for (h in names(terms4)) { tm <- terms4[[h]]
  if (is.na(coef(mr)[tm])) { add("5.6", h, "spec 4 + years in South Africa: not identified", NA, n = nobs(mr)); next }
  add_V("5.6", h, "spec 4 + years in South Africa (changed population, A4d), HC3", mr, tm, vcovHC(mr, type = "HC3"), df.residual(mr),
        note = sprintf("max leverage %.4f (HC3 undefined if 1)", max(hatvalues(mr))))
  add_V("5.6", h, "spec 4 + years in South Africa (changed population, A4d), HC1", mr, tm, vcovHC(mr, type = "HC1"), df.residual(mr))
  add_wcr("5.6", h, "spec 4 + years in South Africa (changed population, A4d), WCR Webb", mr, tm, "ym") }
add("5.6", "all", "Afrikaans = 1 observations in the prior-residence sample", sum(Wr$afr == 1), n = nrow(Wr))

# ============================================ §5.7 specification variants ===
m3 <- lm(lwage ~ afr + age + height + weight + married + hisco_f + reg_f, data = W)
Wc <- W %>% filter(!is.na(class)) %>% droplevels() %>% mutate(cls_f = relevel(factor(class), "1"))
mc <- lm(lwage ~ afr + age + height + weight + married + cls_f + reg_f + yr_f, data = Wc)
for (h in names(terms4)) { tm <- terms4[[h]]
  add_V("5.7", h, "spec 3 (no year effects), HC3", m3, tm, vcovHC(m3, type = "HC3"), df.residual(m3))
  add_wcr("5.7", h, "spec 3 (no year effects), WCR Webb", m3, tm, "ym")
  add_V("5.7", h, "spec 4 with class dummies instead of HISCO, HC3", mc, tm, vcovHC(mc, type = "HC3"), df.residual(mc))
  add_wcr("5.7", h, "spec 4 with class dummies instead of HISCO, WCR Webb", mc, tm, "ym") }

# ============================================ §5.8 I6 comparators ===========
welch <- function(x1, x0) { n1 <- length(x1); n0 <- length(x0); v1 <- var(x1) / n1; v0 <- var(x0) / n0
  se <- sqrt(v1 + v0); df <- (v1 + v0)^2 / (v1^2 / (n1 - 1) + v0^2 / (n0 - 1)); D <- mean(x1) - mean(x0); z <- tci(D, se, df)
  c(D = D, se = se, z) }
for (cmp in list(list("England-born", 1), list("European-born (England, Scotland, Wales, Ireland, Europe)", c(1, 8, 10, 7, 6)))) {
  w <- welch(h3$wage[h3$regiondum == 5], h3$wage[h3$regiondum %in% cmp[[2]]])
  add("5.8", "I6-C", paste("Boer-republic minus", cmp[[1]], "mean wage, HC2/Welch"), w[["D"]], w[["se"]], w[["p"]], w[["lo"]], w[["hi"]],
      sum(h3$regiondum %in% c(5, cmp[[2]]))) }
h3y <- h3 %>% filter(!is.na(eyear)) %>% mutate(yr_f = factor(eyear))
my <- lm(wage ~ g + yr_f, data = h3y)
add_V("5.8", "I6-C", "Boer-republic minus all others, enlistment-year FE, HC2, t(N-k)", my, "g", vcovHC(my, type = "HC2"), df.residual(my))

# ============================================ §5.9 heights ===================
afe <- function(a) factor(pmin(floor(a), 35))   # single-year age FE, 35+ pooled (35-50 pooled within 20-50 samples)
hreg <- function(dat, tag, agevar) {
  for (cmp in list(list("I3a", "Cape/Natal minus England", c(9), c(1)), list("I3b", "SA-territory minus GB (all cohorts)", c(5, 9), c(1, 8, 10)))) {
    dd <- dat %>% filter(regiondum %in% c(cmp[[3]], cmp[[4]])) %>% mutate(g = as.numeric(regiondum %in% cmp[[3]]), af = afe(.data[[agevar]]))
    mm <- lm(height ~ g + af, data = dd)
    add_V("5.9", cmp[[1]], paste0(tag, ": ", cmp[[2]], ", single-year age FE, HC2 (different estimand)"), mm, "g", vcovHC(mm, type = "HC2"), df.residual(mm)) } }
hb <- first %>% filter(!is.na(regiondum), !is.na(height))
hreg(hb %>% filter(!is.na(age_adult), age_adult >= 20, age_adult <= 50), "(a) adult 20-50, age from dates (365.25) else stated", "age_adult")
add("5.9", "all", "(a) recruits dropped for missing age (dates and stated both missing)", sum(is.na(hb$age_adult)))
hreg(hb %>% filter(!is.na(age), age >= 20, age <= 50), "(b) stated age 20-50", "age")
hreg(hb %>% filter(!is.na(age_adult), age_adult >= 23), "(c) age >= 23", "age_adult")
hs <- hb %>% filter(regiondum %in% c(5, 9))
for (cls in list(c("afr", "authors' flag"), c("afr_S3", "S3 rule"))) {
  z <- hs %>% filter(!is.na(.data[[cls[1]]])); w <- welch(z$height[z[[cls[1]]] == 1], z$height[z[[cls[1]]] == 0])
  add("5.9", "p591", paste0("(d) SA-born Dutch- minus English-surnamed mean height, ", cls[2], ", Welch"), w[["D"]], w[["se"]], w[["p"]], w[["lo"]], w[["hi"]],
      nrow(z), sprintf("n Dutch %d, English %d", sum(z[[cls[1]]] == 1), sum(z[[cls[1]]] == 0))) }
hs$score <- FT$score[match(hs$a_row, FT$a_row)]; zs <- hs %>% filter(!is.na(score)); msc <- lm(height ~ score, data = zs)
add_V("5.9", "p591", "(d) SA-born height on probabilistic score (UNVALIDATED), HC2", msc, "score", vcovHC(msc, type = "HC2"), df.residual(msc))
add("5.9", "all", "(f) truncated-normal ML: not run (threshold undocumented)", NA,
    note = "'SAC comparisons' truncreg uses ll(160) with no named source; the paper documents no minimum-height standard")

# ============================================ §5.11 published conventional SEs ==
for (h in names(terms4)) add_V("5.11", h, "published spec 4, conventional OLS SE", m4, terms4[[h]], vcov(m4), dfr)

S <- bind_rows(res)
print(S %>% mutate(across(where(is.numeric), ~ signif(., 4))) %>% select(-note) %>% as.data.frame(), right = FALSE)
write_csv(S, file.path(OUT, "sensitivities.csv"))
saveRDS(list(score_pi = s0$pi, nfail = nfail, unstable = unstable), file.path(SCR, "score_meta.rds"))
