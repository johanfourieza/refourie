# P11_FJS S6 05: SP-rise (superpopulation reading; different-estimand) and its diagnostics, card §5B, plus the
# E-prog intervals. B = 9,999 fixed; R default RNG (Mersenne-Twister, Inversion, Rejection); set.seed(20261011) at
# the start of the main run and of diagnostics (i), (ii), (iv); set.seed(20261011 + t) for each intermediate year.
# Run sequentially in one process so that the card's draw order (1700 indices, then 1773, per replicate) holds.
# Percentile intervals (type 7); MC SE of each endpoint from 10 batches of 999 draws (last 9 draws left out).
# Outputs: output/sp_rise.csv, output/eprog_boot.csv, output/cstar_dist.csv, output/bootstrap_run_info.csv;
#          D:/.../modern/_scratch/boot_draws.rds
source("./P11_FJS/modern/00_common.R")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
B <- 9999
hh <- readRDS(file.path(SCR, "households.rds"))
Y <- lapply(setNames(IMG9, IMG9), function(y) hh |> filter(jaar == y) |> arrange(rid))
X00 <- Y[["1700"]]; X73 <- Y[["1773"]]
t0 <- Sys.time()

ep_stat <- function(x, i) { s <- x$tslaves[i]; tx <- x$tax[i]; O <- x$outO[i]
  if (!(sum(tx) > 0)) return(c(eprog_na, cstar = NA))
  w <- top_w(s); c(eprog(s, tx, O, w), cstar = attr(w, "c")) }
eprog_na <- eprog(X00$tslaves, X00$tax, X00$outO) * NA
S_stat <- function(x, i) { s <- x$tslaves[i]; tx <- x$tax[i]; if (!(sum(tx) > 0)) return(NA_real_); share_top(s, tx) }

ci <- function(v) {                              # percentile CI + batch MC SE; undefined if any draw non-finite
  bad <- sum(!is.finite(v))
  if (bad > 0) return(c(lo = NA, hi = NA, mcse_lo = NA, mcse_hi = NA, n_undefined = bad))
  q <- quantile(v, c(.025, .975), type = 7, names = FALSE)
  bq <- sapply(1:10, function(g) quantile(v[(g - 1) * 999 + 1:999], c(.025, .975), type = 7, names = FALSE))
  c(lo = q[1], hi = q[2], mcse_lo = sd(bq[1, ]) / sqrt(10), mcse_hi = sd(bq[2, ]) / sqrt(10), n_undefined = 0)
}

# ---- main run: iid within year, independent across years ----
set.seed(SEED)
main <- vector("list", B)
for (b in 1:B) {
  i1 <- sample.int(nrow(X00), nrow(X00), replace = TRUE)
  i2 <- sample.int(nrow(X73), nrow(X73), replace = TRUE)
  main[[b]] <- c(setNames(ep_stat(X00, i1), paste0(names(eprog_na) |> c("cstar"), "_1700")),
                 setNames(ep_stat(X73, i2), paste0(names(eprog_na) |> c("cstar"), "_1773")))
}
main <- do.call(rbind, main)
main <- cbind(main, Delta = main[, "S_1773"] - main[, "S_1700"], dR = main[, "R_1773"] - main[, "R_1700"])
t_main <- Sys.time()

# ---- (i) district-stratified (missing ds its own stratum) ----
strat_idx <- function(x) { g <- ifelse(is.na(x$ds), "missing", as.character(x$ds)); split(seq_len(nrow(x)), factor(g, levels = sort(unique(g)))) }
st00 <- strat_idx(X00); st73 <- strat_idx(X73)
rs <- function(ix) ix[sample.int(length(ix), length(ix), replace = TRUE)]
set.seed(SEED)
strat <- t(vapply(1:B, function(b) { i1 <- unlist(lapply(st00, rs)); i2 <- unlist(lapply(st73, rs))
  c(S_1700 = S_stat(X00, i1), S_1773 = S_stat(X73, i2)) }, c(0, 0)))
# ---- (ii) district-cluster within year (missing ds its own cluster; D4) ----
set.seed(SEED)
clus <- t(vapply(1:B, function(b) {
  g1 <- sample.int(length(st00), length(st00), replace = TRUE); g2 <- sample.int(length(st73), length(st73), replace = TRUE)
  c(S_1700 = S_stat(X00, unlist(st00[g1])), S_1773 = S_stat(X73, unlist(st73[g2]))) }, c(0, 0)))
# ---- (iv) m-out-of-n, m = floor(n/2), centred on the full-sample estimate, sqrt(m/n) scaling ----
m00 <- floor(nrow(X00) / 2); m73 <- floor(nrow(X73) / 2)
set.seed(SEED)
moon <- t(vapply(1:B, function(b) { i1 <- sample.int(nrow(X00), m00, replace = TRUE); i2 <- sample.int(nrow(X73), m73, replace = TRUE)
  c(S_1700 = S_stat(X00, i1), S_1773 = S_stat(X73, i2)) }, c(0, 0)))
t_diag <- Sys.time()

# ---- intermediate Image 9 years: E-prog decile rates only ----
other <- list()
for (t in c(1719, 1731, 1738, 1741, 1757)) {
  x <- Y[[as.character(t)]]; set.seed(SEED + t)
  other[[as.character(t)]] <- t(vapply(1:B, function(b) ep_stat(x, sample.int(nrow(x), nrow(x), replace = TRUE)), numeric(length(eprog_na) + 1)))
  colnames(other[[as.character(t)]]) <- c(names(eprog_na), "cstar")
}
t_end <- Sys.time()
saveRDS(list(main = main, strat = strat, clus = clus, moon = moon, other = other), file.path(SCR, "boot_draws.rds"))

# ---- summaries ----
S00 <- share_top(X00$tslaves, X00$tax); S73 <- share_top(X73$tslaves, X73$tax); Dl <- S73 - S00
row <- function(run, q, est, v) tibble(run = run, quantity = q, estimate = est, !!!as.list(ci(v)))
sp <- bind_rows(
  row("main iid", "S00", S00, main[, "S_1700"]), row("main iid", "S73", S73, main[, "S_1773"]), row("main iid", "Delta", Dl, main[, "Delta"]),
  row("(i) district-stratified", "S00", S00, strat[, 1]), row("(i) district-stratified", "S73", S73, strat[, 2]),
  row("(i) district-stratified", "Delta", Dl, strat[, 2] - strat[, 1]),
  row("(ii) district-cluster", "S00", S00, clus[, 1]), row("(ii) district-cluster", "S73", S73, clus[, 2]),
  row("(ii) district-cluster", "Delta", Dl, clus[, 2] - clus[, 1]))
# m-out-of-n: interval [est - q975(d*), est - q025(d*)]
d00 <- sqrt(m00 / nrow(X00)) * (moon[, 1] - S00); d73 <- sqrt(m73 / nrow(X73)) * (moon[, 2] - S73)
mrow <- function(q, est, d) { k <- ci(d); tibble(run = "(iv) m-out-of-n", quantity = q, estimate = est,
  lo = est - k[["hi"]], hi = est - k[["lo"]], mcse_lo = k[["mcse_hi"]], mcse_hi = k[["mcse_lo"]], n_undefined = k[["n_undefined"]]) }
sp <- bind_rows(sp, mrow("S00", S00, d00), mrow("S73", S73, d73), mrow("Delta", Dl, d73 - d00)) |>
  mutate(clusters_1700 = length(st00), clusters_1773 = length(st73),
         m_1700 = ifelse(run == "(iv) m-out-of-n", m00, NA), m_1773 = ifelse(run == "(iv) m-out-of-n", m73, NA))
write_csv(sp, file.path(OUT, "sp_rise.csv"), na = "")

# E-prog intervals
ep_pt <- read_csv(file.path(OUT, "eprog_point.csv"), show_col_types = FALSE)
pt <- function(y, q) ep_pt$value[ep_pt$year %in% y & ep_pt$quantity == q]
eb <- list()
for (y in c(1700, 1773)) for (q in c("S", "OS", "R", "Ktax", "KO", "K", paste0("rate_d", 1:10)))
  eb[[length(eb) + 1]] <- row("main iid", paste0(q, "_", y), pt(y, q), main[, paste0(q, "_", y)])
eb[[length(eb) + 1]] <- row("main iid", "dR", ep_pt$value[ep_pt$quantity == "dR (R1773 - R1700)"], main[, "dR"])
for (t in names(other)) for (q in paste0("rate_d", 1:10))
  eb[[length(eb) + 1]] <- row(paste0("per-year iid, seed ", SEED + as.numeric(t)), paste0(q, "_", t), pt(as.numeric(t), q), other[[t]][, q])
write_csv(bind_rows(eb), file.path(OUT, "eprog_boot.csv"), na = "")

# (iii) c* distribution
c0 <- c(`1700` = attr(top_w(X00$tslaves), "c"), `1773` = attr(top_w(X73$tslaves), "c"))
cd <- bind_rows(lapply(c("1700", "1773"), function(y) { v <- main[, paste0("cstar_", y)]
  as.data.frame(table(cstar = v)) |> transmute(year = as.numeric(y), cstar = as.numeric(as.character(cstar)), draws = Freq,
    share = Freq / B, c_full = c0[[y]], share_cstar_ne_c = mean(v != c0[[y]])) }))
write_csv(cd, file.path(OUT, "cstar_dist.csv"))

info <- tibble(item = c("B", "seed", "RNG", "main run (s)", "diagnostics (s)", "intermediate years (s)", "total (s)",
                        "undefined draws (main, any quantity)"),
               value = c(B, SEED, paste(RNGkind(), collapse = "/"), round(as.numeric(difftime(t_main, t0, units = "secs")), 1),
                         round(as.numeric(difftime(t_diag, t_main, units = "secs")), 1), round(as.numeric(difftime(t_end, t_diag, units = "secs")), 1),
                         round(as.numeric(difftime(t_end, t0, units = "secs")), 1), sum(!is.finite(main))))
write_csv(info, file.path(OUT, "bootstrap_run_info.csv"))
print(as.data.frame(sp), digits = 4); print(info); print(cd |> group_by(year) |> slice_max(draws, n = 3))
