# P03_BoF17 S6 03: sensitivities §5A (H1-H3) and §5B (K1-K2); never verdict-setting. §5C/5D are assembled in 04.
source(here::here("P03_BoF17", "modern", "00_common.R"))
suppressMessages(library(mFilter))
S <- list(); add <- function(group, claim, item, kind, label, est, L99 = NA, U99 = NA, L95 = NA, U95 = NA, p = NA, n = NA, note = "")
  S[[length(S) + 1]] <<- data.frame(group, claim, item = as.character(item), kind, label, est, L99, U99, L95, U95, p, n, note)
bsint <- function(x, y, l, mp = 3) { b <- mbb(x, y, l, minpairs = mp); c(q7(b, .005), q7(b, .995), q7(b, .025), q7(b, .975)) }
mover <- function(r1, r2, c1, c2, rho) { # c = (l, u); Zou (2007)
  d <- r1 - r2; if (rho == -1) return(c(c1[1] - c2[2], c1[2] - c2[1]))
  c(d - sqrt((r1 - c1[1])^2 + (c2[2] - r2)^2), d + sqrt((c1[2] - r1)^2 + (r2 - c2[1])^2)) }
fz <- function(r, Ns, lev) { z <- atanh(r); h <- qnorm(1 - (1 - lev) / 2) / sqrt(Ns - 3); tanh(c(z - h, z + h)) }
fzp <- function(r, Ns) 2 * pnorm(-abs(atanh(r)) * sqrt(Ns - 3))
pp_N <- function(x, y) { n <- length(x); L <- floor(n / 5); ax <- acf(x, L, plot = FALSE)$acf[-1]; ay <- acf(y, L, plot = FALSE)$acf[-1]
  min(n, 1 / (1 / n + (2 / n) * sum(((n - 1:L) / n) * ax * ay))) }
br_N <- function(x, y) { n <- length(x); a <- acf(x, 1, plot = FALSE)$acf[2]; b <- acf(y, 1, plot = FALSE)$acf[2]; n * (1 - a * b) / (1 + a * b) }
ebis <- function(x, y, nsur = 999) { set.seed(SEED, kind = "L'Ecuyer-CMRG"); n <- length(x); r0 <- cor(x, y); X <- fft(x - mean(x)); h <- floor((n - 1) / 2)
  rs <- replicate(nsur, { ph <- runif(h, 0, 2 * pi); Z <- X; Z[2:(h + 1)] <- Mod(X[2:(h + 1)]) * exp(1i * ph)
    Z[n - (1:h) + 1] <- Conj(Z[2:(h + 1)]); if (n %% 2 == 0) Z[n / 2 + 1] <- Mod(X[n / 2 + 1]); cor(Re(fft(Z, inverse = TRUE)) / n, y) })
  (1 + sum(abs(rs) >= abs(r0))) / (nsur + 1) }

## ================= 5A: H1-H3 =================
tr <- read_trends(); pre <- subset(tr, year <= 1871); post <- subset(tr, year >= 1872)
rp <- cor(pre$sa, pre$uk); rq <- cor(post$sa, post$uk)
for (l in c(4, 12)) { a <- bsint(pre$sa, pre$uk, l); b <- bsint(post$sa, post$uk, l)
  add("5A", "H1", 1, "admissible", paste0("block length ", l), rp, a[1], a[2], a[3], a[4], n = 36)
  add("5A", "H2", 1, "admissible", paste0("block length ", l), rq, b[1], b[2], b[3], b[4], n = 42)
  bp <- mbb(pre$sa, pre$uk, l); bq <- mbb(post$sa, post$uk, l)
  h99 <- mover(rq, rp, c(q7(bq, .0025), q7(bq, .9975)), c(q7(bp, .0025), q7(bp, .9975)), -1)
  h95 <- mover(rq, rp, c(q7(bq, .0125), q7(bq, .9875)), c(q7(bp, .0125), q7(bp, .9875)), -1)
  add("5A", "H3", 1, "admissible", paste0("block length ", l, ", rho = -1"), rq - rp, h99[1], h99[2], h95[1], h95[2]) }
for (cl in list(list("H1", pre, rp), list("H2", post, rq))) { d <- cl[[2]]; r <- cl[[3]]
  Np <- pp_N(d$sa, d$uk); Nb <- br_N(d$sa, d$uk)
  add("5A", cl[[1]], 2, "admissible", "Pyper-Peterman N* Fisher-z", r, fz(r, Np, .99)[1], fz(r, Np, .99)[2], fz(r, Np, .95)[1], fz(r, Np, .95)[2], fzp(r, Np), Np)
  add("5A", cl[[1]], 2, "admissible", "Bretherton N* Fisher-z", r, fz(r, Nb, .99)[1], fz(r, Nb, .99)[2], fz(r, Nb, .95)[1], fz(r, Nb, .95)[2], fzp(r, Nb), Nb)
  add("5A", cl[[1]], 3, "admissible", "Ebisuzaki phase randomisation (999)", r, p = ebis(d$sa, d$uk), n = nrow(d)) }
bp <- readRDS(file.path(scr, "bs_H.rds"))
h99 <- mover(rq, rp, c(q7(bp$post, .005), q7(bp$post, .995)), c(q7(bp$pre, .005), q7(bp$pre, .995)), 0)
h95 <- mover(rq, rp, c(q7(bp$post, .025), q7(bp$post, .975)), c(q7(bp$pre, .025), q7(bp$pre, .975)), 0)
add("5A", "H3", 4, "admissible", "independent periods (rho = 0)", rq - rp, h99[1], h99[2], h95[1], h95[2])
## raw-data rebuilds (S3 annual series), CF 2-8 cycle removed, UK 1866 interpolated
ann <- readRDS(dpath("P03_BoF17", "repro_r", "_scratch", "annual.rds")) |> arrange(year)
ann <- data.frame(year = 1836:1913) |> left_join(ann, by = "year")
fill <- function(v) { i <- which(is.finite(v)); approx(ann$year[i], v[i], ann$year)$y }
cft <- function(v, pl, pu) { v <- fill(v); f <- cffilter(v, pl = pl, pu = pu, root = TRUE, drift = TRUE); as.numeric(v - f$cycle) }
cfc <- function(v, pl, pu) { v <- fill(v); as.numeric(cffilter(v, pl = pl, pu = pu, root = TRUE, drift = TRUE)$cycle) }
corr_pair <- function(item, kind, lab, sa, uk, split = 1871) { ip <- ann$year <= split; iq <- ann$year > split
  for (s in list(list("H1", ip), list("H2", iq))) { ok <- s[[2]] & is.finite(sa) & is.finite(uk); a <- bsint(sa[ok], uk[ok], 8)
    add("5A", s[[1]], item, kind, lab, cor(sa[ok], uk[ok]), a[1], a[2], a[3], a[4], n = sum(ok)) } }
corr_pair(5, "admissible", "raw data, CF 2-8 trend (Cape+Natal)", cft(ann$ln_sa_capenatal, 2, 8), cft(ann$ln_uk, 2, 8))
corr_pair(7, "changed estimand", "log levels (UK 1866 missing)", ann$ln_sa_capenatal, ann$ln_uk)
corr_pair(7, "changed estimand", "CF 8-50-year medium-term cycle", cfc(ann$ln_sa_capenatal, 8, 50), cfc(ann$ln_uk, 8, 50))
corr_pair(7, "changed estimand", "UK as mean of logs, CF 2-8 trend", cft(ann$ln_sa_capenatal, 2, 8), cft(ann$uk_mean_log, 2, 8))
corr_pair(8, "changed population", "Cape-only SA, CF 2-8 trend", cft(ann$ln_sa_cape, 2, 8), cft(ann$ln_uk, 2, 8))
corr_pair(8, "changed population", "split after 1874 (in-sheet trends)", tr$sa, tr$uk, 1874)
## split-year scan 1860-1885, rho = -1 MOVER at 95% (component 0.0125/0.9875)
for (s in 1860:1885) { a <- subset(tr, year < s); b <- subset(tr, year >= s); ba <- mbb(a$sa, a$uk, 8); bb <- mbb(b$sa, b$uk, 8)
  h95 <- mover(cor(b$sa, b$uk), cor(a$sa, a$uk), c(q7(bb, .0125), q7(bb, .9875)), c(q7(ba, .0125), q7(ba, .9875)), -1)
  add("5A", "H3", 6, "admissible (descriptive)", paste0("split ", s - 1, "/", s), cor(b$sa, b$uk) - cor(a$sa, a$uk), L95 = h95[1], U95 = h95[2]) }
## error documentation: annual first differences across the UK 1866 gap vs consecutive years only
dgap <- function(v) { o <- rep(NA, length(v)); i <- which(is.finite(v)); o[i[-1]] <- diff(v[i]); o }
dcon <- function(v) c(NA, diff(v))
for (s in list(list("H1", ann$year <= 1871), list("H2", ann$year >= 1872))) {
  for (dd in list(list("first differences across the 1866 gap", dgap), list("first differences, consecutive years only", dcon))) {
    a <- dd[[2]](ann$ln_sa_capenatal); b <- dd[[2]](ann$ln_uk); ok <- s[[2]] & is.finite(a) & is.finite(b)
    add("5A", s[[1]], "err", "error documentation", dd[[1]], cor(a[ok], b[ok]), n = sum(ok)) } }

## ================= 5B: K1-K2 =================
pp_month <- function(x, y) { n <- sum(is.finite(x)); L <- floor(n / 5)
  rh <- function(v, j) { m <- mean(v, na.rm = TRUE); s2 <- mean((v - m)^2, na.rm = TRUE); a <- v[(j + 1):length(v)] - m; b <- v[1:(length(v) - j)] - m
    ok <- is.finite(a) & is.finite(b); if (sum(ok) < 5) 0 else sum(a[ok] * b[ok]) / (sum(ok) * s2) }
  min(n, 1 / (1 / n + (2 / n) * sum(sapply(1:L, function(j) ((n - j) / n) * rh(x, j) * rh(y, j))))) }
deseas <- function(d) { ok <- is.finite(d); r <- rep(NA, length(d)); r[ok] <- resid(lm(d[ok] ~ factor(grid$month[ok]))); r }
mask <- function(x, y) { na <- !(is.finite(x) & is.finite(y)); x[na] <- NA; y[na] <- NA; list(x = x, y = y) }
for (k in list(c("K1", "Wheat"), c("K2", "Mealies"))) {
  kv <- lp("Kimberley", k[2]); cv <- lp("Cape Town", k[2]); m <- mask(dl(cv), dl(kv)); r <- cor(m$x, m$y, use = "complete.obs"); n <- sum(is.finite(m$x))
  for (l in c(6, 24)) { a <- bsint(m$x, m$y, l, 10); add("5B", k[1], 1, "admissible", paste0("block length ", l), r, a[1], a[2], a[3], a[4], n = n) }
  se <- sqrt((1 - r^2) / (n - 2)); tq <- qt(c(.995, .975), n - 2)
  add("5B", k[1], 2, "admissible", "conventional iid SE", r, r - tq[1] * se, r + tq[1] * se, r - tq[2] * se, r + tq[2] * se, 2 * pt(-abs(r / se), n - 2), n)
  add("5B", k[1], 2, "admissible", "Fisher-z, 1/sqrt(n-3)", r, fz(r, n, .99)[1], fz(r, n, .99)[2], fz(r, n, .95)[1], fz(r, n, .95)[2], fzp(r, n), n)
  Np <- pp_month(m$x, m$y)
  add("5B", k[1], 3, "admissible", "Pyper-Peterman N*, lag-specific pairs", r, fz(r, Np, .99)[1], fz(r, Np, .99)[2], fz(r, Np, .95)[1], fz(r, Np, .95)[2], fzp(r, Np), Np)
  if (k[1] == "K2") add("5B", "K2", 4, "admissible (descriptive)", "2013 Mealies analysis.xlsx value", 0.186, n = 74)
  md <- mask(deseas(dl(cv)), deseas(dl(kv))); a <- bsint(md$x, md$y, 12, 10)
  add("5B", k[1], 5, "changed estimand", "deseasonalised differences", cor(md$x, md$y, use = "complete.obs"), a[1], a[2], a[3], a[4], n = sum(is.finite(md$x)))
  mi <- mask(dl(interp(cv)), dl(interp(kv))); a <- bsint(mi$x, mi$y, 12, 10)
  add("5B", k[1], 6, "changed data (A4d)", "linearly interpolated gaps", cor(mi$x, mi$y, use = "complete.obs"), a[1], a[2], a[3], a[4], n = sum(is.finite(mi$x)))
  for (sp in list(list("subperiod 1897-1901", grid$year <= 1901), list("subperiod 1902-1906", grid$year >= 1902))) {
    xs <- m$x[sp[[2]]]; ys <- m$y[sp[[2]]]; a <- bsint(xs, ys, 12, 10)
    add("5B", k[1], 6, "changed population (A4d)", sp[[1]], cor(xs, ys, use = "complete.obs"), a[1], a[2], a[3], a[4], n = sum(is.finite(xs))) }
  dg <- mask(dgap(cv), dgap(kv)); add("5B", k[1], "err", "error documentation", "differences across gaps", cor(dg$x, dg$y, use = "complete.obs"), n = sum(is.finite(dg$x)))
  add("5B", k[1], "err", "error documentation", "printed Table 1 cell", c(K1 = 0.27, K2 = 0.30)[[k[1]]], note = "SE 0.17; unreproducible (S5-03)")
}
S <- bind_rows(S); print(S |> filter(item != 6 | group != "5A"), digits = 3)
write.csv(S, file.path(odir, "sensitivities_corr.csv"), row.names = FALSE)
