# P30_STB24 S6: shared definitions for the frozen method card (modern/method_card.md, v3, commit d59616d).
# Sourced by every numbered script. Run all scripts from the project root:
#   Rscript P30_STB24/modern/01_build.R   (and so on)
suppressPackageStartupMessages({library(data.table); library(readxl); library(ineq); library(parallel)})
source("tools/paths.R")
PAPER <- "P30_STB24"
MOD   <- file.path(PAPER, "modern")
OUT   <- file.path(MOD, "output"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
XLSX  <- dpath(PAPER, "original", "2024F_Stellenbosch", "stellenbosch_clean.xlsx")
SCR   <- function(...) dscratch(PAPER, "modern", ...)
SEED  <- 20261011
NCORE <- 8

ASSETS <- c("horses", "cattle", "sheep", "wheat", "barley", "wine")
HC <- c("horse_foals", "horse_work", "horse_riding", "horse_breeding", "horse_pleasure")
CC <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
SC <- c("sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")
SLAVE <- c("slave_men", "slave_women", "slave_sons", "slave_daughters", "slave_children")
COMP  <- c("horses", HC, CC, "sheep", SC, "sheep_goats_pigs", "wheat_vol", "barley_vol", "wine", "vines", SLAVE)

# Family levels (card s6)
ALPHA <- c(H2 = 0.05 / 6, H4 = 0.05 / 2, H5 = 0.05 / 19, H3 = 0.05)
FAILMAX <- function(fam, B) floor(B * c(H2 = 0.05 / 12 / 10, H4 = 0.05 / 4 / 10, H5 = 0.05 / 38 / 10)[[fam]])

# ---- reading (card s3, "Common data") --------------------------------------------------------
read_raw <- function(guess = FALSE) {
  cache <- SCR(if (guess) "raw_guess.rds" else "raw_full.rds")
  if (file.exists(cache)) return(readRDS(cache))
  x <- if (guess) read_excel(XLSX, sheet = "Sheet1") else read_excel(XLSX, sheet = "Sheet1", guess_max = 200000)
  x <- as.data.table(x)
  saveRDS(x, cache); x
}
coerce_components <- function(dt, strict = TRUE) {
  for (v in intersect(COMP, names(dt))) {
    x <- dt[[v]]
    if (is.numeric(x)) next
    if (is.logical(x) && (all(is.na(x)) || !strict)) { set(dt, j = v, value = as.numeric(x)); next }   # logical -> numeric (TRUE = 1 when K1 off)
    stop("component column ", v, " is ", class(x)[1], " and not entirely NA")
  }
  dt
}

# ---- asset construction (card s3 steps 1-5), with each correction as a switch ----------------
# K1 = types from all rows; K3 = horse_riding in horses; K4 = aggregate NA when all components NA;
# K5 = wine > cap set NA after zero-fill. K2 (base year) only affects the Fig 5 index.
# zerofill = year-level NA -> 0 (paper rule); sgp = sheep_goats_pigs added to sheep (s5C item 4).
build <- function(K1 = TRUE, K3 = TRUE, K4 = TRUE, K5 = TRUE, cap = 1000, zerofill = TRUE, sgp = FALSE,
                  relabel = TRUE) {
  raw <- if (K1) read_raw(FALSE) else read_raw(TRUE)
  dt <- copy(raw[, c("nr", "year", "names_men", "names_women", intersect(COMP, names(raw))), with = FALSE])
  dt <- coerce_components(dt, strict = K1)
  dt[, year := as.numeric(year)]
  dt[, row := seq_len(.N), by = year]
  if (zerofill) for (v in intersect(COMP, names(dt)))                     # step 2, l.236-281
    dt[, (v) := if (all(is.na(get(v)))) get(v) else fifelse(is.na(get(v)), 0, get(v)), by = year]
  hcols <- if (K3) HC else setdiff(HC, "horse_riding")
  scols <- if (sgp) c(SC, "sheep_goats_pigs") else SC
  rs <- function(cols) { m <- as.matrix(dt[, ..cols]); s <- rowSums(m, na.rm = TRUE)
    if (K4) s[rowSums(!is.na(m)) == 0] <- NA; s }
  dt[, horses := fifelse(is.na(horses), rs(hcols), horses)]
  dt[, sheep := fifelse(is.na(sheep), rs(scols), sheep)]
  dt[, cattle := rs(CC)]
  dt[, wheat := wheat_vol][, barley := barley_vol]
  dt[, wine_uncapped := wine]
  if (K5) dt[wine > cap, wine := NA]                                        # step 4 (after zero-fill)
  # slave columns (card s3 H5): relabel for years <= 1737 as coded (l.888-890)
  if (relabel) dt[year <= 1737, `:=`(slave_sons = slave_children, slave_children = NA_real_)]
  dt[, children := slave_sons + slave_daughters]   # without the relabel, unsexed slave_children never enter (s5C item 13)
  dt[, owner := year < 1830 & (fcoalesce(slave_men > 0, FALSE) | fcoalesce(slave_women > 0, FALSE) |
                               fcoalesce(slave_sons > 0, FALSE) | fcoalesce(slave_daughters > 0, FALSE))]
  dt[]
}

# ---- point quantities --------------------------------------------------------------------------
year_means <- function(dt, assets = ASSETS) dt[, lapply(.SD, function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)),
                                               by = year, .SDcols = assets][order(year)]
gini_def <- function(x) { x <- x[!is.na(x)]; if (!length(x) || sum(x) <= 0) NA_real_ else ineq::Gini(x) }
year_ginis <- function(dt, assets = ASSETS, f = gini_def) dt[, lapply(.SD, f), by = year, .SDcols = assets][order(year)]

# Gini of a sample expanded by integer counts cnt over sorted values xs (identical to ineq::Gini on rep(xs, cnt))
gini_w <- function(xs, cnt) {
  N <- sum(cnt); if (N == 0) return(NA_real_)
  S <- sum(cnt * xs); if (S <= 0) return(NA_real_)
  cc <- cumsum(cnt); prev <- cc - cnt
  (2 * sum(xs * (cnt * prev + cnt * (cnt + 1) / 2)) / S - (N + 1)) / N
}

# window-stratified delete-one-unit jackknife SE (card s4). units: list over windows of per-unit stats;
# theta_fun(list of unit-index vectors) recomputes theta from the kept units.
jack_se <- function(nunits, theta_fun) {
  W <- length(nunits); keep0 <- lapply(nunits, seq_len); tot <- 0
  for (w in seq_len(W)) {
    nw <- nunits[w]; if (nw < 2) return(NA_real_)
    th <- vapply(seq_len(nw), function(j) { k <- keep0; k[[w]] <- k[[w]][-j]; theta_fun(k) }, 0)
    if (any(!is.finite(th))) return(NA_real_)
    tot <- tot + (nw - 1) / nw * sum((th - mean(th))^2)
  }
  sqrt(tot)
}

# percentile-t interval and its MC precision over 10 consecutive batches of defined draws
pt_interval <- function(theta, se, tstar, alpha) {
  q <- quantile(tstar, c(1 - alpha / 2, alpha / 2), type = 7, names = FALSE)
  c(lo = unname(theta - q[1] * se), hi = unname(theta - q[2] * se))
}
pt_mcse <- function(theta, se, tstar, alpha) {
  b <- split(tstar, cut(seq_along(tstar), 10, labels = FALSE))
  e <- sapply(b, function(t) pt_interval(theta, se, t, alpha))
  c(lo = sd(e["lo", ]) / sqrt(10), hi = sd(e["hi", ]) / sqrt(10))
}

# reproducible per-replicate L'Ecuyer streams (replicate b always gets the same stream, whatever B)
make_streams <- function(B, seed = SEED) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  s <- vector("list", B); cur <- .Random.seed
  for (b in seq_len(B)) { cur <- nextRNGStream(cur); s[[b]] <- cur }
  s
}
# replicates from..B (from > 1 extends an earlier run: replicate b always uses stream b, so 1..19999 then
# 20000..49999 equals one 49,999 run with the same seed). fun(b) must only use objects in `export`.
run_boot <- function(B, fun, export = character(), envir = parent.frame(), seed = SEED, ncore = NCORE, from = 1) {
  streams <- make_streams(B, seed)[from:B]
  cl <- makeCluster(ncore); on.exit(stopCluster(cl))
  clusterEvalQ(cl, suppressPackageStartupMessages(library(data.table)))
  clusterExport(cl, c("rcount", "gini_w", "st_means", "st_gini", "st_slave", "occ_two_stage", "occ_within", "occ_block",
                      "occ_names", "occ_fixed", "ASSETS", export), envir = envir)
  chunks <- split(seq_along(streams), cut(seq_along(streams), ncore * 4, labels = FALSE))
  jobs <- lapply(chunks, function(ii) list(b = ii + from - 1, st = streams[ii]))
  res <- parLapply(cl, jobs, function(job, ff) lapply(seq_along(job$b), function(i) {
    assign(".Random.seed", job$st[[i]], envir = .GlobalEnv); ff(job$b[i]) }), ff = fun)
  unlist(res, recursive = FALSE)
}

# multinomial row counts for one year occurrence
rcount <- function(n) tabulate(sample.int(n, n, replace = TRUE), n)

classify_cmp <- function(lo, hi, est, side) {          # card s8 comparative categories for one contrast
  if (any(!is.finite(c(lo, hi, est)))) return("undefined")
  if (side > 0) { if (hi < 0) "opposite" else if (lo > 0) "claimed" else if (est > 0) "includes0_pt_claimed" else "includes0_pt_not" }
  else          { if (lo > 0) "opposite" else if (hi < 0) "claimed" else if (est < 0) "includes0_pt_claimed" else "includes0_pt_not" }
}
classify_h2 <- function(lo, hi, est, b = log(1.25), a = log(0.80)) {
  if (any(!is.finite(c(lo, hi, est)))) return("NT")
  if (a <= lo && hi <= b) "C" else if (lo > b) "O" else if (hi < a) "D" else if (est >= a && est <= b) "Q" else "W"
}

# ---- per-year structures for resampling ------------------------------------------------------
# S3 rule-15 surname parser (repro_r/02_analysis.R l.112-127), reused for the s5B item 4 name key
surname_split <- function(x) {
  x <- trimws(gsub("\\s+", " ", gsub("\\(.*?\\)|\\[.*?\\]|\\?", "", ifelse(is.na(x), "", x))))
  x <- sub(";.*$", "", x)
  sur <- giv <- rep(NA_character_, length(x))
  com <- grepl(",", x)
  sur[com] <- trimws(sub(",.*$", "", x[com])); giv[com] <- trimws(sub("^[^,]*,", "", x[com]))
  nc <- which(!com & x != "")
  for (i in nc) {
    t <- strsplit(x[i], " ")[[1]]; t <- t[t != ""]; k <- length(t)
    while (k > 1 && tolower(t[k - 1]) %in% c("de", "du", "le", "la", "van", "der", "den", "von", "v.d.", "vd")) k <- k - 1
    sur[i] <- paste(t[k:length(t)], collapse = " "); giv[i] <- if (k > 1) paste(t[1:(k - 1)], collapse = " ") else ""
  }
  keyify <- function(s) gsub("[^a-z]", "", tolower(s))
  key <- paste0(keyify(sur), "|", keyify(giv))
  key[is.na(sur) | keyify(sur) == ""] <- NA
  key
}

prep_years <- function(d, owner_col = "owner") {
  d <- d[order(year, row)]
  Y <- split(d, by = "year", keep.by = TRUE)
  lapply(Y, function(y) {
    X <- as.matrix(y[, ..ASSETS]); R <- !is.na(X) * 1; X0 <- X; X0[is.na(X0)] <- 0
    ord <- lapply(ASSETS, function(a) { o <- which(!is.na(X[, a])); o[order(X[o, a])] }); names(ord) <- ASSETS
    xs  <- lapply(ASSETS, function(a) X[ord[[a]], a]); names(xs) <- ASSETS
    ow <- y[[owner_col]]
    men <- y$slave_men; wom <- y$slave_women; chi <- y$children
    mn <- ow & !is.na(men); wn <- ow & !is.na(wom); cn <- ow & !is.na(chi); cc <- mn & wn & cn
    z <- function(v) fifelse(is.na(v), 0, v)
    V <- cbind(men_n = mn, men_s = mn * z(men), wom_n = wn, wom_s = wn * z(wom), chi_n = cn, chi_s = cn * z(chi),
               zm = mn & z(men) == 0, zw = wn & z(wom) == 0, cc_n = cc, cc_m = cc * z(men), cc_w = cc * z(wom), cc_c = cc * z(chi),
               w2 = wn & z(wom) >= 2) * 1
    list(year = y$year[1], n = nrow(y), X0 = X0, R = R, ord = ord, xs = xs, V = V,
         key = { k <- surname_split(y$names_men); k[is.na(k)] <- paste0("single_", y$year[1], "_", which(is.na(k))); k })
  })
}

# occurrence generators. win: vector of census years (character keys into Y). Returns list of list(y = key, cnt = counts)
occ_two_stage <- function(Y, win) lapply(win[sample.int(length(win), length(win), replace = TRUE)], function(k) list(y = k, cnt = rcount(Y[[k]]$n)))
occ_within    <- function(Y, win) lapply(win, function(k) list(y = k, cnt = rcount(Y[[k]]$n)))
occ_block     <- function(Y, win, L = 3) {
  n <- length(win); nb <- ceiling(n / L); st <- sample.int(n, nb, replace = TRUE)
  ii <- unlist(lapply(st, function(s) ((s - 1 + 0:(L - 1)) %% n) + 1))[seq_len(n)]
  lapply(win[ii], function(k) list(y = k, cnt = rcount(Y[[k]]$n)))
}
make_clusters <- function(Y, win) {                       # cluster index per row, per year of the window
  keys <- unlist(lapply(win, function(k) Y[[k]]$key)); u <- unique(keys)
  list(K = length(u), idx = lapply(win, function(k) match(Y[[k]]$key, u)), win = win,
       sizes = tabulate(match(keys, u), length(u)))
}
occ_names <- function(Y, cl) { kc <- tabulate(sample.int(cl$K, cl$K, replace = TRUE), cl$K)
  Map(function(k, ix) list(y = k, cnt = kc[ix]), cl$win, cl$idx) }
occ_fixed <- function(Y, win) lapply(win, function(k) list(y = k, cnt = rep(1L, Y[[k]]$n)))   # original data

# per-occurrence statistics
st_means <- function(Y, occ) t(vapply(occ, function(o) { y <- Y[[o$y]]
  s <- crossprod(o$cnt, y$X0)[1, ]; n <- crossprod(o$cnt, y$R)[1, ]; ifelse(n > 0, s / n, NA_real_) }, numeric(6)))
st_gini <- function(Y, occ, a) vapply(occ, function(o) { y <- Y[[o$y]]; gini_w(y$xs[[a]], o$cnt[y$ord[[a]]]) }, 0)
st_slave <- function(Y, occ) t(vapply(occ, function(o) crossprod(o$cnt, Y[[o$y]]$V)[1, ], numeric(13)))

# ---- claim statistics (theta and jackknife SE), shared by 03, 05, 07 ----------------------------
# H2: theta and window-stratified jackknife SE per asset from per-occurrence means
h2_stats <- function(mE, mL) {
  out <- matrix(NA_real_, 6, 4, dimnames = list(ASSETS, c("theta", "se", "nE", "nL")))
  for (a in 1:6) {
    e <- mE[, a]; e <- e[!is.na(e)]; l <- mL[, a]; l <- l[!is.na(l)]
    nE <- length(e); nL <- length(l); out[a, 3:4] <- c(nE, nL)
    if (nE == 0 || nL == 0) next
    th <- log(mean(l) / mean(e)); out[a, 1] <- if (is.finite(th)) th else NA
    if (nE < 2 || nL < 2 || !is.finite(th)) next
    jE <- log(mean(l) / ((sum(e) - e) / (nE - 1))); jL <- log(((sum(l) - l) / (nL - 1)) / mean(e))
    if (any(!is.finite(c(jE, jL)))) next
    out[a, 2] <- sqrt((nE - 1) / nE * sum((jE - mean(jE))^2) + (nL - 1) / nL * sum((jL - mean(jL))^2))
  }
  out
}

# H4: theta = (D_rise, D_fall); jackknife SE per contrast (delete-one-unit of a mean = s^2/n, summed over the contrast's two windows)
h4_stats <- function(g) {           # g: list Pre/Peak/Post of per-occurrence Ginis
  if (any(sapply(g, function(x) any(!is.finite(x)) || length(x) == 0))) return(rep(NA_real_, 4))
  m <- sapply(g, mean); v <- sapply(g, function(x) if (length(x) < 2) NA else var(x) / length(x))
  c(rise = m[["Peak"]] - m[["Pre"]], fall = m[["Peak"]] - m[["Post"]],
    se_rise = sqrt(v[["Peak"]] + v[["Pre"]]), se_fall = sqrt(v[["Peak"]] + v[["Post"]]))
}

# H5: windows and contrasts (card s3 H5). U: named list (one per window) of per-unit matrices of st_slave columns.
h5_windows <- function(yrs) {
  y <- as.numeric(yrs); y <- y[y < 1830]; k <- function(s) as.character(s)
  rows <- split(k(y), floor(y / 20) * 20); names(rows) <- paste0("R", names(rows))
  c(rows, list(Pre5 = k(y[y >= 1787 & y <= 1806]), Post5 = k(y[y >= 1807 & y <= 1829]),
               C1 = k(y[y >= 1800 & y <= 1809]), C2 = k(y[y >= 1820 & y <= 1829])))
}
rat <- function(S, num, den) S[[num]] / S[[den]]
h5_contrasts <- function(rows) {
  cs <- list()
  for (r in rows) {
    cs[[paste0("H5a_W_", sub("R", "", r))]] <- list(win = r, side = 1, req = list(c(r, "men_n"), c(r, "wom_n")),
      f = function(S) rat(S[[1]], "men_s", "men_n") - rat(S[[1]], "wom_s", "wom_n"))
    cs[[paste0("H5a_C_", sub("R", "", r))]] <- list(win = r, side = 1, req = list(c(r, "men_n"), c(r, "chi_n")),
      f = function(S) rat(S[[1]], "men_s", "men_n") - rat(S[[1]], "chi_s", "chi_n"))
  }
  cs$H5b_ZM <- list(win = c("Post5", "Pre5"), side = 1, req = list(c("Post5", "men_n"), c("Pre5", "men_n")),
                    f = function(S) rat(S[[1]], "zm", "men_n") - rat(S[[2]], "zm", "men_n"))
  cs$H5b_ZW <- list(win = c("Post5", "Pre5"), side = -1, req = list(c("Post5", "wom_n"), c("Pre5", "wom_n")),
                    f = function(S) rat(S[[1]], "zw", "wom_n") - rat(S[[2]], "zw", "wom_n"))
  cshare <- function(s) s[["cc_c"]] / (s[["cc_m"]] + s[["cc_w"]] + s[["cc_c"]])
  cs$H5c_C <- list(win = c("C2", "C1"), side = 1, req = list(c("C2", "cc_n"), c("C1", "cc_n")),
                   f = function(S) cshare(S[[1]]) - cshare(S[[2]]))
  cs
}
h5_stats <- function(U, cs) {
  out <- matrix(NA_real_, length(cs), 2, dimnames = list(names(cs), c("theta", "se")))
  Ssum <- lapply(U, colSums)
  for (i in seq_along(cs)) {
    c0 <- cs[[i]]; S <- Ssum[c0$win]; th <- c0$f(S)
    if (!is.finite(th)) next
    out[i, 1] <- th; tot <- 0; bad <- FALSE
    for (w in seq_along(c0$win)) {
      u <- U[[c0$win[w]]]; nw <- nrow(u); if (nw < 2) { bad <- TRUE; break }
      tj <- vapply(seq_len(nw), function(j) { S2 <- S; S2[[w]] <- S[[w]] - u[j, ]; c0$f(S2) }, 0)
      if (any(!is.finite(tj))) { bad <- TRUE; break }
      tot <- tot + (nw - 1) / nw * sum((tj - mean(tj))^2)
    }
    if (!bad) out[i, 2] <- sqrt(tot)
  }
  out
}
