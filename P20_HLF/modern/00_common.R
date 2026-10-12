# P20_HLF S6: shared inputs and functions (method card v3, commit d240e89).
# Inputs are the printed cells in claims/claims.csv (card §4); the chain mirrors compare/s5_checks/s5_verify.R.
suppressPackageStartupMessages(library(tidyverse))
root <- "."
source(file.path(root, "tools", "paths.R"))
out_dir <- file.path(root, "P20_HLF", "modern", "output")
set.seed(20261012)                                   # for form only; nothing is random (card §4)
cl <- read_csv(file.path(root, "P20_HLF", "claims", "claims.csv"), show_col_types = FALSE)
v <- function(id) { x <- as.numeric(cl$reported_value[cl$claim_id == id]); if (length(x) != 1) NA_real_ else x }
prec <- function(id) as.numeric(cl$precision[cl$claim_id == id])
Tn <- 1905 - 1873                                    # 32 years, annual compounding

central_ids <- c("T3_a", "T3_c", "T3_f", "T3_SS", "T3_pct", "T6_b", "T6_c",
                 "T7_sp_lo", "T7_sp_hi", "T8_b", "T8_d", "T8_e", "T8_g")
inp0 <- setNames(map_dbl(central_ids, v), central_ids)

# Fogel-Leunig ratio (card §4 step 3); NA outside the domain phi > 1
ratio <- function(phi, eps) {
  if (!is.finite(phi) || phi <= 1) return(NA_real_)
  if (abs(eps - 1) < 1e-12) log(phi) / (phi - 1) else (phi^(1 - eps) - 1) / ((1 - eps) * (phi - 1))
}
ratio_lin <- function(phi, eps) {                    # 5B-7 linear demand
  if (!is.finite(phi) || phi <= 1) return(NA_real_)
  z <- eps * (phi - 1); if (z <= 1) 1 - z / 2 else 1 / (2 * z)
}

# Anchors (card §3): returns b_j and g_j (percent) or NA if undefined
anchors <- function(GDP, b, g_pct) {
  b_g <- GDP * (1 - (1 + g_pct / 100)^(-Tn))
  g_b <- if (GDP - b > 0) (GDP / (GDP - b))^(1 / Tn) - 1 else NA_real_
  list(A_g = c(b = if (is.finite(b_g) && b_g > 0) b_g else NA_real_, g = g_pct),
       A_b = c(b = b, g = if (is.finite(g_b) && g_b > 0) 100 * g_b else NA_real_))
}

# Full chain. Arguments allow the 5A/5B one-at-a-time changes; defaults = central analysis.
chain <- function(inp = inp0, p_alt = NULL, eps = c(lo = 0.8, hi = 0.5), rfun = ratio,
                  cs_pax = NULL, sp = NULL, rail_rev = NULL, ton_miles = NULL, SS_override = NULL) {
  a <- if (is.null(ton_miles)) inp[["T3_a"]] else ton_miles
  rev <- if (is.null(rail_rev)) inp[["T3_c"]] else rail_rev
  GDP <- inp[["T3_SS"]] / (inp[["T3_pct"]] / 100)
  p_rw <- rev / a
  if (is.null(p_alt)) p_alt <- inp[["T3_f"]] / inp[["T3_a"]]
  phi <- p_alt / p_rw
  SS <- a * p_alt - rev
  dom_ok <- is.finite(GDP) && GDP > 0 && p_rw > 0 && p_alt > 0 && phi > 1
  if (is.null(cs_pax)) cs_pax <- inp[["T6_b"]] + inp[["T6_c"]]
  if (is.null(sp)) sp <- c(lo = inp[["T7_sp_hi"]], hi = inp[["T7_sp_lo"]])   # envelope pairing (card §4 step 4)
  R <- c(lo = rfun(phi, eps[["lo"]]), hi = rfun(phi, eps[["hi"]]))
  CS <- R * SS + cs_pax
  a_k <- CS + sp
  f <- inp[["T8_d"]] * inp[["T8_e"]] / 100
  A <- anchors(GDP, inp[["T8_b"]], inp[["T8_g"]])
  Tval <- map_dfr(names(A), function(j) {
    bj <- A[[j]][["b"]]; gj <- A[[j]][["g"]]
    ak <- unname(a_k[c("lo", "hi")])
    tibble(anchor = j, k = c("lo", "hi"), b_j = bj, g_j = gj, a_k = ak,
           T = 100 * ak / bj + 100 * f / gj,
           crafts = 100 * (log(GDP / (GDP - ak)) / Tn + f / 100) / log(1 + gj / 100))
  })
  if (!dom_ok) Tval <- mutate(Tval, T = NA_real_, crafts = NA_real_)
  Tval <- mutate(Tval, T = if_else(is.finite(T), T, NA_real_), crafts = if_else(is.finite(crafts), crafts, NA_real_))
  list(GDP = GDP, p_rw = p_rw, p_alt = p_alt, phi = phi, SS = SS, R = R, CS = CS, a_k = a_k, f = f, A = A, Tval = Tval,
       T3_pct = if (dom_ok) 100 * SS / GDP else NA_real_,
       T6_pct = if (dom_ok) 100 * CS / GDP else c(lo = NA_real_, hi = NA_real_))
}

claims_H1 <- tibble(claim = c("H1a", "H1b"), id = c("T8_tot_lo", "T8_tot_hi"), k = c("lo", "hi"),
                    X = c(22.35, 25.09), b_lo = c(20.115, 22.581), b_hi = c(24.585, 27.599))

# §8 verdict rules, checked in order
verdict_rule <- function(L, U, X, blo, bhi) {
  if (!is.finite(L) || !is.finite(U)) return(c("not-testable", "0"))
  if (blo <= L && U <= bhi) return(c("confirmed", "1"))
  if (U < 0) return(c("overturned (opposite sign)", "2a"))
  if (L >= 0 && U < 0.5 * X) return(c("overturned (below floor)", "2b"))
  if (L < 0 && U >= 0) return(c("weakened (sign-straddling)", "3a"))
  if (L >= 0 && L < 0.5 * X && U >= 0.5 * X) return(c("weakened (reaches below floor)", "3b"))
  if (L > bhi) return(c("qualified (above)", "4"))
  if (U < blo && L >= 0.5 * X) return(c("qualified (below)", "5"))
  c("qualified (envelope straddles the band)", "6")
}
ord <- c("not-testable" = 0, "overturned" = 1, "weakened" = 2, "qualified" = 3, "confirmed" = 4)
