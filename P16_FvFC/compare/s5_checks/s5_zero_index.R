# P16_FvFC S5: does excluding zero-index households (Stata ineqdeco default, which drops values <= 0)
# explain the pair-B gaps in Fig 5c (esp. 1663) and Fig 4? One change relative to the S3 rebuild.
suppressPackageStartupMessages({library(dplyr); library(readr)})
setwd(here::here()); source("tools/paths.R")
hh <- readRDS(dpath("P16_FvFC", "repro_r", "data", "households.rds"))
cl <- read_csv("P16_FvFC/claims/claims.csv", show_col_types = FALSE); pub <- \(id) cl$reported_value[match(id, cl$claim_id)]
core1 <- c("SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE", "VK", "WINGST")
pca_weights <- function(df, vars) { X <- as.matrix(df[, vars]); sd <- apply(X, 2, sd)
  v <- eigen(cor(X), symmetric = TRUE)$vectors[, 1]; if (sum(v) < 0) v <- -v; list(w = setNames(v, vars), sd = sd) }
score <- function(df, p) as.vector(as.matrix(df[, names(p$w)]) %*% (p$w / p$sd))
gini_w <- function(y, w) { o <- order(y); y <- y[o]; w <- w[o]; W <- sum(w); mu <- sum(w * y) / W; C <- cumsum(w)
  sum(y * w * (2 * C - w + 1)) / (W^2 * mu) - (W + 1) / W }
far <- hh |> filter(farmer); yrs <- sort(unique(hh$year))
res <- list()
for (pcasample in c("all farmers", "farmers with index>0")) {
  base <- far; p <- pca_weights(base, core1); idx <- score(base, p)
  if (pcasample == "farmers with index>0") { base <- base[idx > 0, ]; p <- pca_weights(base, core1); idx <- score(base, p) }
  for (drop0 in c(FALSE, TRUE)) {
    d <- base |> mutate(pc = idx / hhsize); if (drop0) d <- d |> filter(pc > 0)
    g <- d |> group_by(year) |> summarise(gini = gini_w(pc, hhsize), n = n(), .groups = "drop") |>
      mutate(pub = pub(paste0("F5c_", year)))
    res[[length(res) + 1]] <- g |> mutate(pca_sample = pcasample, drop_zero_in_gini = drop0)
  }
}
res <- bind_rows(res)
summ <- res |> group_by(pca_sample, drop_zero_in_gini) |>
  summarise(mad = mean(abs(gini - pub)), max = max(abs(gini - pub)), within_005 = sum(abs(gini - pub) <= 0.005),
            g1663 = gini[year == 1663], g1695 = gini[year == 1695], g1702 = gini[year == 1702], g1709 = gini[year == 1709],
            g1757 = gini[year == 1757], n0_1663 = sum(n[year == 1663]), .groups = "drop")
nzero <- far |> mutate(i = score(far, pca_weights(far, core1))) |> group_by(year) |> summarise(n_zero_index = sum(i <= 0), n = n())
write_csv(res, "P16_FvFC/compare/s5_checks/zero_index_scenarios_by_year.csv")
write_csv(summ, "P16_FvFC/compare/s5_checks/zero_index_scenarios.csv")
print(summ, width = 200); print(nzero, n = 25)
print(res |> filter(!drop_zero_in_gini | TRUE) |> filter(pca_sample == "all farmers") |> select(year, drop_zero_in_gini, gini, pub) |>
  tidyr::pivot_wider(names_from = drop_zero_in_gini, values_from = gini), n = 25)

# ---- append the zero-exclusion scenario to s5_effects.csv (run after s5_checks.R) ----------------
eff <- read_csv("P16_FvFC/compare/s5_effects.csv", show_col_types = FALSE) |> filter(scenario != "Gini excludes zero-index households (ineqdeco default)")
z <- res |> filter(pca_sample == "all farmers", drop_zero_in_gini)
hid <- c("text_p26_gini_initial", "text_p26_gini_1709", "text_p26_gini_1757")
eff <- bind_rows(eff, tibble(scenario = "Gini excludes zero-index households (ineqdeco default)", claim_id = hid,
  published = pub(hid), original_code = NA_real_, scenario_value = z$gini[match(c(1663, 1709, 1757), z$year)],
  note = "Drops farmers with core 1 index = 0 from the Gini (1 such household in 1663); reproduces F5c_1663 = 0.501 exactly"))
write_csv(eff, "P16_FvFC/compare/s5_effects.csv")
