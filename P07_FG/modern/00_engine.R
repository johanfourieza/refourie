# P07_FG S6: shared engine for the frozen method card (modern/method_card.md, commit 17a056d).
# R re-implementation of CreatingKhoe.do l.3-67 (repro_original/CreatingKhoe.do, verified in S2/S5),
# restricted to the estimands of card section 3, with Stata missing-value semantics (card 4.1).
# Sourced by 01_..05_ scripts. No outputs are written here.
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr); library(readr)})
ROOT <- here::here()
source(file.path(ROOT, "tools", "paths.R"))
MOD <- file.path(ROOT, "P07_FG", "modern")
OUT <- file.path(MOD, "output"); dir.create(OUT, showWarnings = FALSE)

# ---- Stata semantics: missing is greater than every number ----
s_gt <- function(x, c) is.na(x) | x > c
s_lt <- function(x, c) !is.na(x) & x < c
s_eq <- function(x, c) !is.na(x) & x == c
s_ne <- function(x, c) is.na(x) | x != c
s_div <- function(a, b) ifelse(is.na(a) | is.na(b) | b == 0, NA_real_, a / b)

# ---- constants (card 4.2) ----
BOTHA_V <- 3375.2; TAS_V <- 2041.2; D_TAS <- 185.6; TAS_YEAR <- 1709; TEXT_YEAR <- 1773
GAMMA <- list(stated = c(">5" = 1, "1-5" = 57.5 / 67.5, "0" = 47.5 / 67.5),
              none   = c(">5" = 1, "1-5" = 1, "0" = 1))
G_PUB <- 100 * ((6843 / 122)^(1 / 88) - 1)       # I1a-fid, printed endpoints, fixed

# ---- data and sample (card 4.1; CK l.4-8, 13-22, 51, 62) ----
load_data <- function(keep5262 = FALSE, keep0 = FALSE) {
  d <- read_dta(dpath("P07_FG", "original", "14 FG Missing People", "missingpeople.dta")) |> zap_labels() |> as.data.frame()
  d <- d[!s_eq(d$output, 0), ]
  dy <- c(1752, 1702, 1678, 1670, 1762, 1705, 1716, 1688)
  if (keep5262) dy <- setdiff(dy, c(1752, 1762))
  d <- d[!(d$year %in% dy), ]
  d <- d[!(s_eq(d$district, 4) & s_eq(d$year, 1723)), ]
  if (!keep0) d <- d[!s_eq(d$district, 0), ]
  d$dsow  <- as.integer(s_gt(d$wheatsown, 0) | s_gt(d$ryesown, 0) | s_gt(d$barleysown, 0))
  d$dviti <- as.integer(s_gt(d$vineyards, 0))
  d$dmix  <- d$dsow + d$dviti
  d$vherd <- d$vcattle + d$vsheep + d$vhorses                       # NA if any component NA
  d$grain <- d$wheatreaped + d$ryereaped + d$barleyreaped
  d$wheat <- d$wheatreaped
  # slave category: 0; 1-5; >5 (missing counts as >5, Stata semantics)
  d$cat <- ifelse(s_eq(d$slaves, 0), "0", ifelse(s_gt(d$slaves, 0) & s_lt(d$slaves, 6), "1-5", ">5"))
  d$botha <- s_eq(d$year, 1773) & s_eq(d$district, 4) & abs(d$vherd - BOTHA_V) < 0.05 & grepl("BOTHA", d$surname)
  d$tas   <- s_eq(d$year, TAS_YEAR) & s_eq(d$district, 2) & abs(d$vherd - TAS_V) < 0.05 & grepl("^TAS", d$surname)
  d
}

# Tas anchor category a_Tas, read from the data before the run (card 4.2, 10)
tas_lookup <- function(d) {
  t <- d[d$tas %in% TRUE, ]
  if (nrow(t) != 1) return(list(found = FALSE, a = NA_character_, n = nrow(t), row = t))
  list(found = TRUE, a = t$cat, n = 1, row = t)
}

# ---- divisor d_i = D(district, year) * gamma_c / gamma_a (card 4.2) ----
divisor <- function(d, lambda, S, gamma, a_tas, cape = FALSE) {
  G <- GAMMA[[gamma]]; g <- unname(G[d$cat])
  dv <- rep(Inf, nrow(d))                                   # Inf -> L = 0 (Cape, district 0)
  st <- s_eq(d$district, 2); dk <- s_eq(d$district, 3); sw <- s_eq(d$district, 4)
  dv[sw] <- (67.5 / lambda) * g[sw]                          # Botha anchor, a = >5
  sd_rule <- function(dist_mask, mult) {
    if (S == "text" || S == "code") return((mult * 67.5 / lambda) * g)
    gA <- if (is.na(a_tas)) NA_real_ else unname(G[a_tas])
    dT <- D_TAS * g / gA
    if (S == "Tas") return(dT)
    if (S == "drift") {
      dX <- (2 * 67.5 / lambda) * g
      w <- (d$year - TAS_YEAR) / (TEXT_YEAR - TAS_YEAR)
      return(exp(log(dT) + w * (log(dX) - log(dT))))
    }
    stop("unknown S")
  }
  stel_mult <- if (S == "code") 3 else 2
  ds <- sd_rule(st, stel_mult); dd <- sd_rule(dk, 2)
  dv[st] <- ds[st]; dv[dk] <- dd[dk]
  if (cape) { cp <- s_eq(d$district, 1); dv[cp] <- dd[cp] }  # sensitivity 6: Cape at the Drakenstein divisor
  dv
}

labour <- function(d, dv, concave = FALSE) {
  L <- ifelse(is.infinite(dv), 0, if (concave) (BOTHA_V / dv) * (d$vherd / BOTHA_V)^0.75 else d$vherd / dv)
  L[!is.infinite(dv) & is.na(d$vherd)] <- NA_real_         # missing when vherd missing (where replaced)
  L
}

# ---- productivity statistic (card 3: mean of ratios, each column on its own support) ----
prod_stat <- function(d, L, smp, out = "grain", alpha = 1, rom = FALSE, dists = 1:3) {
  y <- d[[out]]; m <- smp & d$district %in% dists
  wo <- s_div(y, d$slavemales); wi <- s_div(y, d$slavemales + alpha * L)
  if (rom) {
    ok_wo <- m & !is.na(y) & !is.na(d$slavemales); ok_wi <- m & !is.na(y) & !is.na(d$slavemales + alpha * L)
    mwo <- sum(y[ok_wo]) / sum(d$slavemales[ok_wo]); mwi <- sum(y[ok_wi]) / sum((d$slavemales + alpha * L)[ok_wi])
    nwo <- sum(ok_wo); nwi <- sum(ok_wi)
  } else {
    mwo <- mean(wo[m], na.rm = TRUE); mwi <- mean(wi[m], na.rm = TRUE)
    nwo <- sum(!is.na(wo[m])); nwi <- sum(!is.na(wi[m]))
  }
  P <- 100 * (mwi - mwo) / mwo
  Ppair <- NA_real_
  if (nwo != nwi) { cs <- m & !is.na(wo) & !is.na(wi); Ppair <- 100 * (mean(wi[cs]) - mean(wo[cs])) / mean(wo[cs]) }
  c(without = mwo, with = mwi, n_without = nwo, n_with = nwi, P = P, P_paired = Ppair)
}

samples <- function(d, cap5 = TRUE) {
  list(T3 = d$year >= 1719 &s_lt(d$vherd, 1000) & s_eq(d$dviti, 0) & s_ne(d$dsow, 0) & s_ne(d$slavemales, 0),
       T5 = d$year >= 1719 & (if (cap5) s_lt(d$vherd, 1000) else TRUE) & s_ne(d$dmix, 0) & s_ne(d$slavemales, 0))
}

gr <- function(a, b) 100 * ((b / a)^(1 / 88) - 1)

# ---- one scenario: every card-3 statistic plus secondary rows ----
run_scenario <- function(d, lambda = 1, S = "text", gamma = "stated", a_tas = NA, alpha = 1, cap5 = TRUE,
                         out = "grain", rom = FALSE, cape = FALSE, concave = FALSE, dists = 1:3) {
  dv <- divisor(d, lambda, S, gamma, a_tas, cape); L <- labour(d, dv, concave)
  sm <- samples(d, cap5)
  K  <- function(y, mask = TRUE) sum(L[d$year == y & mask], na.rm = TRUE)
  Sl <- function(y, mask = TRUE) sum(d$slaves[d$year == y & mask], na.rm = TRUE)
  csd <- d$district < 4
  r <- list(K1685 = K(1685), K1773 = K(1773), S1685 = Sl(1685), S1773 = Sl(1773),
            K1685_csd = K(1685, csd), K1773_csd = K(1773, csd), S1685_csd = Sl(1685, csd), S1773_csd = Sl(1773, csd))
  r$gK <- gr(r$K1685, r$K1773); r$gS <- gr(r$S1685, r$S1773); r$rKS <- r$gK / r$gS; r$I1c <- r$K1773 / 6843
  r$gK_csd <- gr(r$K1685_csd, r$K1773_csd); r$gS_csd <- gr(r$S1685_csd, r$S1773_csd); r$rKS_csd <- r$gK_csd / r$gS_csd
  t3 <- prod_stat(d, L, sm$T3, out, alpha, rom, dists); t5 <- prod_stat(d, L, sm$T5, out, alpha, rom, dists)
  r$T3_without <- t3[["without"]]; r$T3_with <- t3[["with"]]; r$T3_n_without <- t3[["n_without"]]; r$T3_n_with <- t3[["n_with"]]
  r$P_T3 <- t3[["P"]]; r$P_T3_paired <- t3[["P_paired"]]
  r$T5_without <- t5[["without"]]; r$T5_with <- t5[["with"]]; r$T5_n_without <- t5[["n_without"]]; r$T5_n_with <- t5[["n_with"]]
  r$P_T5 <- t5[["P"]]; r$P_T5_paired <- t5[["P_paired"]]
  for (k in c(2, 3)) { nm <- c("", "Stel", "Drak")[k]
    a <- prod_stat(d, L, sm$T3, out, alpha, rom, k); b <- prod_stat(d, L, sm$T5, out, alpha, rom, k)
    r[[paste0("T3_", nm, "_without")]] <- a[["without"]]; r[[paste0("T3_", nm, "_with")]] <- a[["with"]]
    r[[paste0("P_T5_", nm)]] <- b[["P"]] }
  r$L_botha <- sum(L[d$botha %in% TRUE]); r$L_tas <- sum(L[d$tas %in% TRUE])
  if ((S %in% c("Tas", "drift")) && is.na(a_tas)) for (k in names(r)) if (is.numeric(r[[k]])) r[[k]] <- NA_real_
  as_tibble(r)
}

# card 4.2: the 16 joint scenarios
grid_A <- expand_grid(lambda = c(1, 0.5), S = c("text", "code", "Tas", "drift"), gamma = c("stated", "none")) |>
  mutate(central = lambda == 1 & S == "text" & gamma == "stated",
         scenario = paste0("lam", lambda, "_", S, "_", gamma))
