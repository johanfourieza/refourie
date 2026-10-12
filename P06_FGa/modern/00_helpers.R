# P06_FGa S6 modern reanalysis: shared helpers (sourced by every numbered script).
# Implements the frozen method card (modern/method_card.md, commit 17a056d).
# Run every script from the project root:  Rscript P06_FGa/modern/0X_....R
suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(readr); library(ineq)
})
source("tools/paths.R")
MOD   <- "P06_FGa/modern"
OUT   <- file.path(MOD, "output")
SCR   <- function(...) dscratch("P06_FGa", "modern", ...)        # D: scratch only
ORIG  <- dpath("P06_FGa", "original", "20 FG Comparisons")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

KAPPA   <- 2.8377569          # bu per mud (card K4, V3 = B)
K2FAC   <- 100 / 35.2391      # card K2 divisor for Maine/Massachusetts grain
GRAINS  <- c("Wheatreaped", "Barleyreaped", "Ryereaped", "Oatsreaped", "Cornreaped")
K3VARS  <- c(GRAINS, "Cattle", "Sheep", "Slaves")
CAPE    <- c("Graaff Reinet", "Stellenbosch", "Swellendam", "Tulbagh")
USENUM  <- c("Maine", "Massachusetts")
VA_F    <- 0.20               # Virginia sampling fraction (p.20)
VA_W    <- 1 / VA_F
B_BOOT  <- 9999
SEED    <- 20261011
XRATE   <- 3.931055403 / 3.561536195   # workbook rd per $ (Averages rows 2 vs 6)
LN_SIM  <- log(1.25)          # A8 ratio similarity band ln[0.80, 1.25]
G_SIM   <- 0.03               # A8 Gini similarity band

# ---------------------------------------------------------------- data -----
load_raw <- function() {
  fg <- read_excel(file.path(ORIG, "Data", "FourieGarmenApril2020.xlsx"), "Combined", guess_max = 50000)
  fg <- as.data.frame(fg)
  # Some columns hold the literal text "NA" (Virginia Sheep, US Slaves, early Cape Brandy); the original
  # code's read_excel (guess_max = 1000) coerced them to numeric NA. Do the same explicitly.
  for (v in c(K3VARS, "Wine", "Brandy", "Horses")) fg[[v]] <- suppressWarnings(as.numeric(fg[[v]]))
  fg$row_id <- seq_len(nrow(fg))
  fg$Bench <- fg$Year
  rec <- c(`1787` = 1785, `1784` = 1785, `1806` = 1805, `1798` = 1795, `1814` = 1815,
           `1792` = 1795, `1801` = 1805, `1811` = 1815)          # code l.77-86
  m <- as.character(fg$Year) %in% names(rec); fg$Bench[m] <- rec[as.character(fg$Year[m])]
  fg$County <- ifelse(fg$District == "Virginia", fg$Veldcornet, NA)  # = raw County code (verified 01_)
  fg
}

load_prices <- function() {
  f <- file.path(ORIG, "Prices.xlsx")
  rd <- function(s) { p <- as.data.frame(read_excel(f, s)); rownames(p) <- p$Country; p }
  av <- as.data.frame(suppressMessages(read_excel(f, "Averages", col_names = FALSE)))
  auc <- av[av[[1]] %in% paste0("Auction", 1:4), ]
  names(auc) <- c("Auction", "x", "Wheat", "Barley", "Rye", "Oats", "Corn", "Horses", "Cattle", "Sheep", "Slaves", "Wine", "Brandy")
  for (j in 3:13) auc[[j]] <- suppressWarnings(as.numeric(auc[[j]]))
  wr <- as.data.frame(suppressMessages(read_excel(f, "US Decadal Averages", col_names = FALSE)))
  wr <- wr[wr[[1]] %in% c("1781-1790", "1791-1800", "1801-1810", "1811-1820"), 1:8]
  names(wr) <- c("Decade", "Wheat", "Corn", "CornWholesale", "Rye", "RyeWholesale", "Barley", "Oats")
  for (j in 2:8) wr[[j]] <- suppressWarnings(as.numeric(wr[[j]]))
  wr$Bench <- c(1785, 1795, 1805, 1815)
  list(Final = rd("Final"), Final2 = rd("Final2"), auctions = auc, wright = wr)
}

# K3 coverage map: District x census Year x variable; structurally missing if > 50% NA.
coverage_map <- function(fg) {
  fg |> group_by(District, Year) |>
    summarise(n = n(), across(all_of(K3VARS), list(na = ~ mean(is.na(.x)), zero = ~ all(.x[!is.na(.x)] == 0))), .groups = "drop") |>
    pivot_longer(-c(District, Year, n), names_to = c("variable", ".value"), names_pattern = "(.*)_(na|zero)") |>
    rename(na_share = na, all_zero = zero) |>
    mutate(status = ifelse(na_share > 0.5, "structurally_missing", "recorded"))
}

# Apply corrections. k1/k2 switch C1/N1; k3 = TRUE applies the K3 NA rules, FALSE = code convention (NA = 0).
prep <- function(fg, cmap, k2 = TRUE, k3 = TRUE, k2fac = K2FAC) {
  d <- fg
  if (k2) { us <- d$District %in% USENUM; for (g in GRAINS) d[[g]][us] <- d[[g]][us] / k2fac }
  for (v in c(K3VARS, "Wine", "Brandy", "Horses")) d[[paste0(v, "_raw")]] <- d[[v]]
  key <- paste(d$District, d$Year)
  for (v in K3VARS) {
    miss <- cmap |> filter(variable == v, status == "structurally_missing") |> transmute(k = paste(District, Year)) |> pull(k)
    d[[paste0("rec_", v)]] <- !(key %in% miss)
    # Card K5: Virginia grain is structurally missing everywhere (C7), whatever its NA share (corn is coded 0).
    if (v %in% GRAINS) d[[paste0("rec_", v)]][d$District == "Virginia"] <- FALSE
    x <- d[[v]]
    if (k3) { x[is.na(x) & d[[paste0("rec_", v)]]] <- 0; x[!d[[paste0("rec_", v)]]] <- NA } else x[is.na(x)] <- 0
    d[[v]] <- x
  }
  for (v in c("Wine", "Brandy", "Horses")) d[[v]][is.na(d[[v]])] <- 0   # not in K3: code convention
  d$cov_crop <- Reduce(`&`, lapply(GRAINS, function(g) d[[paste0("rec_", g)]]))
  d$cov_live <- d$rec_Cattle & d$rec_Sheep
  d$cov_cattle <- d$rec_Cattle
  d$cov_slaves <- d$rec_Slaves & d$rec_Cattle
  d$is_cape <- d$District %in% CAPE
  d
}

# Farmer filter. rule: "k4" (>= 1 bu in common units; card K4), "gt0" (> 0, no wine; §5.7),
# "code" (> 0 incl. wine; original l.121). kap = bu/mud for the Cape threshold.
farmer <- function(d, rule = "k4", kap = KAPPA) {
  thr <- ifelse(d$is_cape, 1 / kap, 1)
  g <- rep(FALSE, nrow(d))
  for (v in GRAINS) {
    x <- d[[v]]
    ok <- if (rule == "k4") !is.na(x) & x >= thr else !is.na(x) & x > 0
    if (rule != "code") ok <- ok & d[[paste0("rec_", v)]]
    g <- g | ok
  }
  z <- function(x) !is.na(x) & x > 0
  f <- g | z(d$Cattle) | z(d$Sheep)
  if (rule == "code") f <- f | z(d$Wine)
  f
}

# Household valuation. Returns d with VG (grain), VW, VB, VC, VS, VH (annual livestock values).
# pset: "Final"/"Final2"; v3: "A"/"B"/"C"; wine: Cape wine $ price; us_grain: "Final" or "Wright";
# cape_live: optional named vector (Horses, Cattle, Sheep) in $; us_cattle: optional $ price;
# k1 = FALSE reproduces the prod() bug (C1). na0 = TRUE uses the code's rowSums(na.rm = TRUE).
value_hh <- function(d, P, pset = "Final", r = 0.06, v3 = "A", wine = NULL, us_grain = "Final",
                     cape_live = NULL, us_cattle = NULL, k1 = TRUE, na0 = FALSE) {
  pr <- P[[pset]]; us <- pr["United States", ]; cp <- pr["Cape Colony", ]
  isc <- d$is_cape
  gp <- function(col) {
    pu <- rep(us[[col]], nrow(d))
    if (us_grain == "Wright") {
      wc <- c(PWheat = "Wheat", PBarley = "Barley", PRye = "Rye", POats = "Oats", PCorn = "Corn")[[col]]
      w <- P$wright[[wc]][match(d$Bench, P$wright$Bench)]
      pu <- ifelse(!is.na(w), w, pu)
    }
    pc <- switch(v3, A = rep(cp[[col]], nrow(d)), B = us[[col]] * KAPPA, C = us[[col]] * 3.0)
    ifelse(isc, pc, pu)
  }
  cols <- c(Wheatreaped = "PWheat", Barleyreaped = "PBarley", Ryereaped = "PRye", Oatsreaped = "POats", Cornreaped = "PCorn")
  V <- sapply(names(cols), function(g) d[[g]] * gp(cols[[g]]))
  if (!k1) V[, "Wheatreaped"] <- prod(d$Wheatreaped_raw * ifelse(isc, cp$PWheat, us$PWheat), na.rm = TRUE)
  # Cape corn has no Cape price (PCorn NA): code convention, value treated as 0 via rowSums(na.rm)
  # (Cape corn quantities are all recorded zeros, so nothing is lost.)
  if (v3 == "A") V[isc & !is.na(d$Cornreaped), "Cornreaped"] <- 0
  d$VG <- if (na0) rowSums(V, na.rm = TRUE) else rowSums(V)
  pw <- if (is.null(wine)) cp$PWine else wine
  d$VW <- ifelse(isc, d$Wine * pw, 0)
  d$VB <- ifelse(isc, d$Brandy * cp$PBrandy, 0)
  lc <- c(Horses = cp$PHorses, Cattle = cp$PCattle, Sheep = cp$PSheep)
  if (!is.null(cape_live)) lc[names(cape_live)] <- cape_live
  uc <- if (is.null(us_cattle)) us$PCattle else us_cattle
  d$VC <- r * d$Cattle * ifelse(isc, lc[["Cattle"]], uc)
  d$VS <- r * d$Sheep * ifelse(isc, lc[["Sheep"]], us$PSheep)
  d$VH <- r * d$Horses * ifelse(isc, lc[["Horses"]], us$PHorses)
  if (na0) for (v in c("VC", "VS")) d[[v]][is.na(d[[v]])] <- 0
  d$income <- d$VG + d$VC + d$VS
  d$cropwine <- d$VG + d$VW + d$VB
  d
}

# Gini, corr = FALSE, zeros included; weighted version (equal weights = ineq::Gini(corr = FALSE)).
wgini <- function(x, w = NULL) {
  if (is.null(w)) w <- rep(1, length(x))
  k <- !is.na(x); x <- x[k]; w <- w[k]
  if (length(x) < 2) return(NA_real_)
  o <- order(x); x <- x[o]; w <- w[o]
  S <- cumsum(w * x); T <- S[length(S)]
  if (!is.finite(T) || T <= 0) return(NA_real_)
  1 - sum(w * (c(0, S[-length(S)]) + S)) / (sum(w) * T)
}

# Tail-trimmed Gini (§5.13): drop top 1% (ceiling) or the 10 largest by outcome.
gini_trim <- function(x, mode) {
  x <- sort(x[!is.na(x)], decreasing = TRUE)
  k <- if (mode == "top1pct") ceiling(0.01 * length(x)) else 10
  wgini(x[-seq_len(min(k, length(x)))])
}

# Verdict table for a single comparative contrast (card §8). lo/hi = interval; band = similarity half-width.
verdict_single <- function(lo, hi, band, fail = FALSE) {
  if (fail || !is.finite(lo) || !is.finite(hi)) return(list(verdict = "not-testable", rule = 0L))
  if (hi < 0) return(list(verdict = "overturned (reversed)", rule = 1L))
  if (lo > 0) return(list(verdict = "confirmed", rule = 2L))
  if (lo >= -band && hi <= band) return(list(verdict = "overturned (credible null: similar)", rule = 3L))
  list(verdict = "weakened", rule = 4L)
}
verdict_universal <- function(pair_verdicts) {
  v <- pair_verdicts
  if (all(v == "not-testable")) return(list(verdict = "not-testable", rule = 0L))
  if (any(grepl("^overturned", v))) return(list(verdict = "overturned", rule = 1L))
  if (all(v == "confirmed")) return(list(verdict = "confirmed", rule = 2L))
  if (all(v %in% c("confirmed", "not-testable"))) return(list(verdict = "qualified (partial coverage)", rule = 3L))
  list(verdict = "weakened", rule = 4L)
}
negligible <- function(lo, hi, band, rule) rule %in% c(1L, 2L) && lo >= -band && hi <= band

# Rao-Wu rescaling weights for one replicate. strata: integer vector; base weight w0; f = sampling fraction.
raowu_weights <- function(strata, w0, f = VA_F) {
  w <- numeric(length(strata))
  for (h in unique(strata)) {
    i <- which(strata == h); n <- length(i); m <- n - 1
    r <- tabulate(sample.int(n, m, replace = TRUE), n)
    lam <- sqrt(m * (1 - f) / (n - 1))
    w[i] <- w0[i] * (1 - lam + lam * (n / m) * r)
  }
  w
}

# Stream seeds for B replicates (L'Ecuyer-CMRG), independent of the number of workers.
make_streams <- function(B, seed, skip = 0) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  s <- .Random.seed; out <- vector("list", B + skip)
  for (b in seq_len(B + skip)) { out[[b]] <- s; s <- parallel::nextRNGStream(s) }
  out[(skip + 1):(skip + B)]
}

q99 <- function(x) unname(quantile(x, c(0.005, 0.995), type = 7, na.rm = TRUE))
q95 <- function(x) unname(quantile(x, c(0.025, 0.975), type = 7, na.rm = TRUE))

# ======================================================= estimators =========
# Build the household file for one scenario. Defaults = central scenario (§4.2).
# cape_mult: Cape cattle and sheep multiplier (§5.5). rule/kap: K4 variants (§5.7).
make_d <- function(fg, cmap, P, rule = "k4", kap = KAPPA, pset = "Final", r = 0.06, v3 = "A", wine = NULL,
                   us_grain = "Final", cape_live = NULL, us_cattle = NULL, k1 = TRUE, k2 = TRUE, k3 = TRUE,
                   cape_mult = 1) {
  d <- prep(fg, cmap, k2 = k2, k3 = k3)
  d$farm <- farmer(d, rule, kap)
  if (cape_mult != 1) { d$Cattle[d$is_cape] <- d$Cattle[d$is_cape] * cape_mult; d$Sheep[d$is_cape] <- d$Sheep[d$is_cape] * cape_mult }
  d <- value_hh(d, P, pset, r, v3, wine, us_grain, cape_live, us_cattle, k1 = k1, na0 = !k3)
  if (!k3) { d$cov_crop <- d$cov_live <- d$cov_cattle <- d$cov_slaves <- TRUE }   # D5: uncovered treated as zero
  d
}

DCODE <- c(GR = "Graaff Reinet", Stb = "Stellenbosch", Swe = "Swellendam", Tul = "Tulbagh",
           Maine = "Maine", Mass = "Massachusetts")

# Enumerated-side statistics (Cape districts, Maine, Massachusetts). Returns a named vector.
# cattle_only: Cape restricted to cattle owners (§5.9). income_extra: columns added to income (§5.6).
enum_stats <- function(d, cattle_only = FALSE, income_extra = NULL, gini_mode = "all") {
  f <- d[d$farm & d$District != "Virginia", ]
  cape <- f$is_cape; mm <- f$District %in% USENUM
  inc <- f$income; if (!is.null(income_extra)) for (v in income_extra) inc <- inc + f[[v]]
  s1 <- f$cov_crop & f$cov_live
  out <- c(
    H1_cape = mean(inc[cape & s1]), H1_us = mean(inc[mm & s1]),
    H1_n_cape = sum(cape & s1), H1_n_us = sum(mm & s1),
    H2_cape = mean(f$cropwine[cape & f$cov_crop]), H2_us = mean(f$VG[mm & f$cov_crop]))
  c3 <- cape & f$cov_cattle; if (cattle_only) c3 <- c3 & f$Cattle > 0
  out <- c(out, H3_cape = mean(f$Cattle[c3]), H3_n_cape = sum(c3),
           H3_mm_sum = sum(f$Cattle[mm & f$cov_cattle]), H3_mm_n = sum(mm & f$cov_cattle))
  gfun <- switch(gini_mode, all = function(x) wgini(x), owners = function(x) wgini(x[x > 0]),
                 top1pct = function(x) gini_trim(x, "top1pct"), top10 = function(x) gini_trim(x, "top10"))
  for (k in c("GR", "Stb", "Swe", "Tul")) {
    s <- f$District == DCODE[[k]] & f$cov_slaves; if (cattle_only) s <- s & f$Cattle > 0
    out[paste0("G4_", k)] <- gfun(f$Slaves[s]); out[paste0("G4n_", k)] <- sum(s)
  }
  for (k in names(DCODE)) {
    s <- f$District == DCODE[[k]] & f$cov_crop
    out[paste0("G5_", k)] <- gfun(f$VG[s]); out[paste0("G5n_", k)] <- sum(s)
  }
  sc <- cape & f$cov_slaves; if (cattle_only) sc <- sc & f$Cattle > 0
  out["G4_capepooled"] <- gfun(f$Slaves[sc])
  out["G5_capepooled"] <- gfun(f$VG[cape & f$cov_crop]); out["G5_uspooled"] <- gfun(f$VG[mm & f$cov_crop])
  out
}

# Virginia-side statistics for given farmer weights w (design weights, or Rao-Wu replicate weights).
# v: data frame of covered Virginia farmers (Cattle, Slaves, Bench).
va_stats <- function(v, w, gini_mode = "all") {
  gfun <- switch(gini_mode, all = function(x, w) wgini(x, w), owners = function(x, w) wgini(x[x > 0], w[x > 0]))
  out <- c(VA_cat = sum(w * v$Cattle), VA_w = sum(w), G4_VA = gfun(v$Slaves, w),
           G4own_VA = wgini(v$Slaves[v$Slaves > 0], w[v$Slaves > 0]))
  for (b in c(1785, 1795, 1805, 1815)) {
    s <- v$Bench == b
    out[paste0("VA_cat_", b)] <- sum(w[s] * v$Cattle[s]); out[paste0("VA_w_", b)] <- sum(w[s])
    out[paste0("G4_VA_", b)] <- if (sum(s) >= 2) wgini(v$Slaves[s], w[s]) else NA_real_
  }
  out
}

# Contrasts from enumerated stats (e) and Virginia stats (v; vector or matrix rows). weighted: H3 design weights.
h3_lnR <- function(e, va_cat, va_w, weighted = TRUE) {
  k <- if (weighted) 1 else VA_F   # unweighted: Virginia households count once (w = 5 x 0.2)
  us <- (e[["H3_mm_sum"]] + k * va_cat) / (e[["H3_mm_n"]] + k * va_w)
  log(e[["H3_cape"]] / us)
}
