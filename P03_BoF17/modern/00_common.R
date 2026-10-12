# P03_BoF17 S6: shared helpers (method card v3, d240e89). Sourced by 01-04.
suppressMessages({library(dplyr); library(tidyr); library(tidyxl); library(here)})
source(here::here("tools", "paths.R"))
SEED <- 20261012; B <- 9999
mdir <- here::here("P03_BoF17", "modern"); odir <- file.path(mdir, "output"); dir.create(odir, showWarnings = FALSE)
scr <- dscratch("P03_BoF17", "modern")

## ---- annual in-sheet trend series ('SA & UK graphs'!C2:F79), the cells the printed CORREL formulas use ----
read_trends <- function() {
  g <- dpath("P03_BoF17", "original", "Boshoff Fourie Globalisation", "Globalisation data.xlsx")
  c <- xlsx_cells(g, sheets = "SA & UK graphs") |> filter(row >= 2, row <= 79, col %in% c(3, 5, 6))
  w <- c |> select(row, col, numeric) |> pivot_wider(names_from = col, values_from = numeric) |> arrange(row)
  data.frame(year = w$`3`, sa = w$`5`, uk = w$`6`)
}

## ---- monthly Kimberley / Cape Town grid (S3 panel, repro_r/01_clean.R) ----
panel <- readRDS(dpath("P03_BoF17", "repro_r", "_scratch", "panel_raw.rds"))
grid <- expand.grid(year = 1897:1906, month = 1:12) |> arrange(year, month)
lp <- function(town, prod) { z <- panel |> filter(town == !!town, product == prod); log(z$price[match(paste(grid$year, grid$month), paste(z$year, z$month))]) }
dl <- function(v) c(NA, diff(v))   # consecutive calendar months only
interp <- function(v) { i <- which(is.finite(v)); out <- v; out[min(i):max(i)] <- approx(i, v[i], min(i):max(i))$y; out }

## ---- moving-block bootstrap of paired rows (card §4, steps 1-5) ----
rcor <- function(x, y, minpairs) { ok <- is.finite(x) & is.finite(y); if (sum(ok) < minpairs) return(NA_real_)
  if (sd(x[ok]) == 0 || sd(y[ok]) == 0) return(NA_real_); cor(x[ok], y[ok]) }
mbb <- function(x, y, l, B = 9999, minpairs = 3, seed = SEED) {
  set.seed(seed, kind = "L'Ecuyer-CMRG"); N <- length(x); nb <- ceiling(N / l)
  vapply(seq_len(B), function(b) { s <- sample.int(N - l + 1, nb, replace = TRUE)
    idx <- as.vector(outer(0:(l - 1), s, `+`))[1:N]; rcor(x[idx], y[idx], minpairs) }, numeric(1))
}
q7 <- function(r, p) unname(quantile(r, p, type = 7, na.rm = TRUE))
FAIL_MAX <- 0.00025
