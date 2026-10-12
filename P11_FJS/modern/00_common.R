# P11_FJS S6 shared setup (sourced by 01-07). Card: modern/method_card.md (v3, frozen at d59616d).
# Tax construction generalises compare/s5_checks/s5_scenarios.R `imp_tax` (validated at S5 against the Stata
# household files to 0.0016 stuivers); share functions implement card §3 (fractional tie rule) and the
# workbook / xtile constructions of §5A 1-2.
suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(readr); library(haven) })
ROOT <- "."
source(file.path(ROOT, "tools", "paths.R"))             # A6: data root on D:
P    <- "P11_FJS"
MOD  <- file.path(ROOT, P, "modern")
OUT  <- file.path(MOD, "output"); dir.create(OUT, showWarnings = FALSE)
SCR  <- dscratch(P, "modern")                            # A6: household-level files on D: only
SEED <- 20261011
IMG9 <- c(1700, 1719, 1731, 1738, 1741, 1757, 1773)
TAX_INPUTS <- c("sm", "sv", "ss", "sd", "bste", "skpe", "wingst", "wyn", "kgs", "kgw", "rgs", "rgw", "cgs", "cgw")
options(warn = 1, dplyr.summarise.inform = FALSE)

# base.dta after fiscalpolicy.do:6-11, with the original record order kept in `rid`
load_base <- function() {
  read_dta(dpath(P, "original", "Fourie Jansen Siebrits", "base.dta")) |> zap_labels() |>
    mutate(rid = row_number()) |>
    filter(!jaar %in% c(1663, 1670, 1685, 1716, 1752, 1762))
}

# Household tax (stuivers). Defaults = card §3 primary. Options switch individual corrections off (§4 check, §5A).
#   wine_pre: st per leaguer before 1743; post_factor: 0.7 restores the coded factor; grain: "gross" | "net";
#   imp_ratio: NA = no imputation, else scalar or per-record vector r (recipients wingst > 0 & wyn == 0);
#   poll_swell: poll tax in ds == 4; hearth: "coded" (ds == 1 pays 192), "none", "dsna" (ds == 1 or missing);
#   pigs_asset: vk counted in assets (§5A 12).
make_tax <- function(d, wine_pre = 48, post_factor = 1, grain = "gross", imp_ratio = NA,
                     poll_swell = 32, hearth = "coded", pigs_asset = FALSE) {
  d |> mutate(
    tslaves = sm + sv + ss + sd,
    assets  = bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw + (if (pigs_asset) vk else 0),
    sassets = tslaves + assets,
    hearth_town = switch(hearth, coded = !is.na(ds) & ds == 1, none = FALSE, dsna = is.na(ds) | ds == 1),
    uset = tslaves > 0 & assets == 0,                                  # hearth-tax uncertain set (§5A 11)
    poll = case_when(sassets == 0 ~ ifelse(!is.na(ds) & ds == 4, poll_swell, 32),
                     uset & hearth_town ~ 192,
                     uset ~ ifelse(!is.na(ds) & ds == 4, poll_swell, 32),
                     TRUE ~ 0),
    wyn2 = if (length(imp_ratio) == 1 && is.na(imp_ratio)) wyn else ifelse(wingst > 0 & wyn == 0, wingst * imp_ratio, wyn),
    winetax = case_when(jaar < 1743 ~ wine_pre * wyn2, jaar > 1743 ~ 144 * wyn2 * post_factor, TRUE ~ 0),
    gk = if (grain == "net") pmax(kgw - kgs, 0) else kgw,
    gr = if (grain == "net") pmax(rgw - rgs, 0) else rgw,
    gc = if (grain == "net") pmax(cgw - cgs, 0) else cgw,
    graintax = 0.1 * 48 * (6 * gk + 3 * gr + 3 * gc),
    meattax  = bste + 0.16 * skpe,
    tax  = poll + winetax + graintax + meattax,
    outO = 6 * kgw + 3 * (rgw + cgw) + 3 * wyn)                       # E-prog gross farm output, Rd (§3)
}
# The coded (all corrections off) construction: run A1 of S2
tax_off <- function(d) make_tax(d, wine_pre = 48, post_factor = 0.7, grain = "net", imp_ratio = 0.0008813)

# Same construction with Stata float storage of each generated variable, as fiscalpolicy.do stores them
# (gen ... = 0 creates floats; arithmetic in double, stored as float). Used only for the §4 Image 9 digit check (D2).
f32 <- function(x) readBin(writeBin(as.numeric(x), raw(), size = 4), "double", size = 4, n = length(x))
tax_off_float <- function(d) {
  d |> mutate(
    tslaves = sm + sv + ss + sd, assets = bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw,
    sassets = tslaves + assets,
    poll = case_when(sassets == 0 ~ 32, tslaves > 0 & assets == 0 & !is.na(ds) & ds == 1 ~ 192,
                     tslaves > 0 & assets == 0 ~ 32, TRUE ~ 0),
    wynf = ifelse(wyn == 0, f32(wingst * .0008813), wyn),
    winetax = f32(case_when(jaar < 1743 ~ 48 * wynf, jaar > 1743 ~ 144 * wynf * .7, TRUE ~ 0)),
    graintax = f32(pmax(kgw - kgs, 0) * .1 * 6 * 48 + pmax(rgw - rgs, 0) * .1 * 3 * 48 + pmax(cgw - cgs, 0) * .1 * 3 * 48),
    meattax = f32(bste + skpe * .16),
    tax = f32(poll + winetax + graintax + meattax))
}

# ---- fractional top-decile weights (card §3) ----
top_w <- function(s, frac = 0.1) {
  n <- length(s); k <- frac * n
  su <- sort(unique(s), decreasing = TRUE)
  gt <- 0; for (c in su) { eq <- sum(s == c); if (gt < k && k <= gt + eq) break; gt <- gt + eq }
  w <- numeric(n); w[s > c] <- 1; w[s == c] <- (k - gt) / sum(s == c)
  attr(w, "c") <- c; attr(w, "n_tied") <- sum(s == c); w
}
share_top <- function(s, v, w = top_w(s)) 100 * sum(w * v) / sum(v)

# Fractional decile membership matrix (n x 10): record i's expected mass in tenth j under random tie-breaking.
dec_w <- function(s) {
  n <- length(s); k <- n / 10
  tb <- table(s); vals <- as.numeric(names(tb)); cnt <- as.numeric(tb)
  hi <- cumsum(cnt); lo <- hi - cnt                    # tie group occupies (lo, hi] in ascending order
  j  <- match(s, vals)
  lo_i <- lo[j]; hi_i <- hi[j]
  W <- sapply(1:10, function(q) pmax(0, pmin(hi_i, q * k) - pmax(lo_i, (q - 1) * k)) / (hi_i - lo_i))
  W
}

# Concentration index by slave rank, ties at mid-rank: C = 2 cov(y, F) / mean(y), F = (midrank - 0.5) / n
conc <- function(s, y) { n <- length(s); F <- (rank(s, ties.method = "average") - 0.5) / n
  2 * mean((y - mean(y)) * (F - mean(F))) / mean(y) }

# E-prog quantities for one year (card §3)
eprog <- function(s, tax, O, w = top_w(s)) {
  S <- 100 * sum(w * tax) / sum(tax); OS <- 100 * sum(w * O) / sum(O)
  W <- dec_w(s); rate <- colSums(W * tax) / (48 * colSums(W * O))
  c(S = S, OS = OS, R = S / OS, Ktax = conc(s, tax), KO = conc(s, O), K = conc(s, tax) - conc(s, O),
    setNames(rate, paste0("rate_d", 1:10)))
}

# ---- Stata xtile (egenmore _gxtile 2.1, p(10(10)90), _pctile default definition) ----
stata_pctile <- function(x, p) { x <- sort(x); n <- length(x)
  vapply(p, function(pp) { P <- n * pp / 100
    if (abs(P - round(P)) < 1e-9) { P <- round(P); (x[P] + x[P + 1]) / 2 } else x[floor(P) + 1] }, 0) }
xtile10 <- function(x) { r <- stata_pctile(x, seq(10, 90, 10)); 1L + vapply(x, function(v) sum(v > r), 0L) }

# Workbook Deciles!Q12:W21 and W24: decile means of tax by xtile group, empty groups filled down; share = m10 / sum(m)
wb_means <- function(dec, tax) {
  m <- tapply(tax, factor(dec, levels = 1:10), mean)
  for (q in 2:10) if (is.na(m[q])) m[q] <- m[q - 1]
  as.numeric(m)
}
share_wb <- function(dec, tax) { m <- wb_means(dec, tax); 100 * m[10] / sum(m) }
share_xtile <- function(dec, tax) 100 * sum(tax[dec == 10]) / sum(tax)

# Ties broken by tax (§5A 4): records at the cut sorted by tax (desc or asc; ties by record order), whole records
# admitted until the group holds k records, the last admitted record carrying the fractional remainder.
share_taxbreak <- function(s, tax, rid, desc = TRUE) {
  w0 <- top_w(s); c <- attr(w0, "c"); k <- length(s) / 10
  w <- as.numeric(s > c); rem <- k - sum(w)
  idx <- which(s == c); idx <- idx[order(if (desc) -tax[idx] else tax[idx], rid[idx])]
  for (i in idx) { if (rem <= 0) break; a <- min(1, rem); w[i] <- a; rem <- rem - a }
  100 * sum(w * tax) / sum(tax)
}

# Hearth-tax allocation bounds (§5A 11): exact max / min of S_t(h) over h_i in {32, 192} for records in U_t
hearth_bounds <- function(d) {
  w <- top_w(d$tslaves); base_tax <- d$tax - d$poll * d$uset    # every non-U record keeps its primary liability
  U <- which(d$uset)
  one <- function(ord) {
    vals <- vapply(0:length(ord), function(j) { h <- rep(32, length(ord)); if (j > 0) h[seq_len(j)] <- 192
      tx <- base_tax; tx[ord] <- tx[ord] + h; 100 * sum(w * tx) / sum(tx) }, 0)
    vals
  }
  ord_desc <- U[order(-w[U], d$rid[U])]; ord_asc <- U[order(w[U], d$rid[U])]
  c(max = max(one(ord_desc)), min = min(one(ord_asc)), nU = length(U))
}
