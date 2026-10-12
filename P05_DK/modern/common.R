# P05_DK S6 shared setup (sourced by 01-05). Card: modern/method_card.md (v3, frozen at d59616d).
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(sf); library(sandwich); library(clubSandwich)
})
ROOT <- "."
source(file.path(ROOT, "tools", "paths.R"))          # A6: data root on D:
P    <- "P05_DK"
MOD  <- file.path(ROOT, P, "modern")
OUT  <- file.path(MOD, "output"); dir.create(OUT, showWarnings = FALSE)
SCR  <- dscratch(P, "modern")                         # A6: scratch on D: only
SRC  <- dpath(P, "original", "Spanish_flu_group_folder", "data", "original")
ELIE <- dpath(P, "original", "Spanish_flu_group_folder", "spanishflu_ELIE")
ALB  <- "+proj=aea +lat_1=-24 +lat_2=-33 +lat_0=0 +lon_0=24 +datum=WGS84 +units=m +no_defs"
SEED <- 20261011
ALPHA <- 0.05 / 3                                     # card §4C: Bonferroni, m = 3
sf_use_s2(FALSE)
options(warn = 1)

# Card §6 tolerances
TOL_GATE <- 1e-8; TOL_MASS <- 1e-6; TOL_TIE <- 1e-10
gate_ok <- function(x, ref) abs(x - ref) <= TOL_GATE * max(1, abs(ref))

# ---- Inference rule of card §4A: CR2 with each unit its own cluster (= HC2) and Bell-McCaffrey/Satterthwaite df.
# Falls back to HC2 with t on N - K df (logged by the caller) when the primary fails.
bm_test <- function(m, term, level = 1 - ALPHA) {
  id <- seq_len(nobs(m))
  r <- tryCatch({
    ct <- coef_test(m, vcov = "CR2", cluster = id, test = "Satterthwaite", coefs = term)
    ci <- conf_int(m, vcov = "CR2", cluster = id, test = "Satterthwaite", level = level, coefs = term)
    out <- data.frame(b = ct$beta, se = ct$SE, df = ct$df_Satt, p = ct$p_Satt, lo = ci$CI_L, hi = ci$CI_U,
                      inference = "CR2(=HC2)/BM-Satterthwaite")
    if (!is.finite(out$df) || out$df <= 0 || !is.finite(out$se)) stop("BM failure")
    out
  }, error = function(e) NULL)
  if (is.null(r)) {
    se <- sqrt(vcovHC(m, type = "HC2")[term, term]); b <- unname(coef(m)[term]); df <- df.residual(m)
    if (!is.finite(se) || se == 0) return(data.frame(b = b, se = se, df = df, p = NA, lo = NA, hi = NA, inference = "not-testable"))
    q <- qt(1 - (1 - level) / 2, df)
    r <- data.frame(b = b, se = se, df = df, p = 2 * pt(-abs(b / se), df), lo = b - q * se, hi = b + q * se,
                    inference = "FALLBACK HC2 t(N-K)")
  }
  r
}
se_type <- function(m, term, type) {
  v <- if (type == "const") vcov(m) else vcovHC(m, type = type)
  b <- unname(coef(m)[term]); se <- sqrt(v[term, term]); df <- df.residual(m)
  data.frame(b = b, se = se, df = df, p = 2 * pt(-abs(b / se), df))
}

# ---- Verdict rules, card §8 (H1/H3 table), applied mechanically.
verdict_h13 <- function(b, b0, p, lo, hi, failed = FALSE) {
  if (failed || any(!is.finite(c(b, p, lo, hi)))) return(c("not-testable", 0))
  L <- 0.5 * abs(b0); s <- sign(b); s0 <- sign(b0)
  if (s == -s0 && p < ALPHA) return(c("overturned (reversed)", 1))
  if (lo > -L && hi < L) return(c("overturned (credible null)", 2))
  if (s == s0 && p < ALPHA && abs(b) >= L) return(c("confirmed", 3))
  if (s == s0 && p < ALPHA && abs(b) < L) return(c("qualified (magnitude below the floor)", 4))
  if (p >= ALPHA && s == s0) return(c("weakened", 5))
  c("weakened (direction lost)", 6)
}

# ---- Model formulas (card §4A)
F_H1 <- deaths ~ black_share + col_share + log1p(density) + log_rail + rain + region
F_H3 <- urate ~ log(deaths) + black_share + col_share + log1p(density) + log_rail + rain + region
T_H1 <- "black_share"; T_H3 <- "log(deaths)"
B0 <- c(H1 = 39.432, H2n = -460.648, H2pct = -25, H3 = -0.007)
reg_levels <- c("Cape", "Natal", "Orange Free State", "Transkei", "Transvaal", "Zululand")
