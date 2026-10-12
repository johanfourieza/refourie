# P28_VFF  S3 independent R recreation - 02_analysis.R
# Table 1 (correlations), Table 2 (population persistence, 9 cols),
# Table 3 (reversals, 12 cols). OLS via fixest. SEs: iid (published analogue),
# HC1, Conley 100 km (uniform kernel, great-circle distance, 1911 centroids).
options(modelsummary_format_numeric_latex = "plain")
suppressPackageStartupMessages({
  library(tidyverse); library(fixest); library(modelsummary); library(here)
  library(conleyreg)
})
set.seed(20261011)
root <- here::here()
if (!dir.exists(file.path(root, "P28_VFF"))) stop("Run from the Fourie_ReplicateMe root")
pdir <- file.path(root, "P28_VFF"); rdir <- file.path(pdir, "repro_r")
source(file.path(root, "tools", "paths.R"))   # A6: data root on D:
an <- readRDS(dscratch("P28_VFF", "repro_r", "analysis.rds"))
claims <- read_csv(file.path(pdir, "claims", "claims.csv"), show_col_types = FALSE)
stopifnot(nrow(an) == 138)

# ---------------- Table 1: Pearson correlation matrix ----------------
t1v <- c("Settle1830", "Pop1911", "Pop1996", "Pop2011", "Unem1996", "Unem2011",
         "Light1996", "Light2011", "Rain", "Rugged", "Soil")
cm <- cor(an[, t1v], method = "pearson")
t1 <- expand_grid(r = seq_along(t1v), c = seq_along(t1v)) |>
  mutate(claim_id = sprintf("T1_r%d_c%d", r, c), value = cm[cbind(r, c)],
         se = NA_real_, n = nrow(an))
cm_out <- cm; cm_out[upper.tri(cm_out)] <- NA
kableExtra::kbl(round(cm, 3), format = "latex", booktabs = TRUE, digits = 3,
                caption = "Correlation matrix (R recreation)") |>
  writeLines(file.path(rdir, "output", "table1_corr.tex"))

# ---------------- Table 2 ----------------
geo <- "Rugged + Rain"
t2f <- list(
  `1` = Pop1911 ~ Settle1830,
  `2` = as.formula(paste("Pop1911 ~ Settle1830 +", geo)),
  `3` = as.formula(paste("Homeland ~ Pop1911 +", geo)),
  `4` = Pop1996 ~ Pop1911 + Homeland,
  `5` = as.formula(paste("Pop1996 ~ Pop1911 + Homeland +", geo)),
  `6` = Pop2011 ~ Pop1911 + Homeland,
  `7` = as.formula(paste("Pop2011 ~ Pop1911 + Homeland +", geo)),
  `8` = Pop2011 ~ Pop1911 + Homeland + Pop1996,
  `9` = as.formula(paste("Pop2011 ~ Pop1911 + Homeland + Pop1996 +", geo)))
t2rows <- c("Settle1830", "Pop1911", "Homeland", "Pop1996", "Rugged", "Rain", "(Intercept)")

# ---------------- Table 3 ----------------
t3f <- list(
  `1`  = Unem1996 ~ Pop1911 + Homeland,
  `2`  = as.formula(paste("Unem1996 ~ Pop1911 + Homeland +", geo)),
  `3`  = Light1996 ~ Pop1911 + Homeland,
  `4`  = as.formula(paste("Light1996 ~ Pop1911 + Homeland +", geo)),
  `5`  = Unem2011 ~ Pop1911 + Homeland,
  `6`  = as.formula(paste("Unem2011 ~ Pop1911 + Homeland +", geo)),
  `7`  = as.formula(paste("Unem2011 ~ Pop1911 + Homeland + Pop2011 +", geo)),
  `8`  = as.formula(paste("Unem2011 ~ Pop1911 + Homeland + Pop2011 + NetMig11 +", geo)),
  `9`  = Light2011 ~ Pop1911 + Homeland,
  `10` = as.formula(paste("Light2011 ~ Pop1911 + Homeland +", geo)),
  `11` = as.formula(paste("Light2011 ~ Pop1911 + Homeland + Pop2011 +", geo)),
  `12` = as.formula(paste("Light2011 ~ Pop1911 + Homeland + Pop2011 + NetMig11 +", geo)))
t3rows <- c("Pop1911", "Homeland", "Pop2011", "NetMig11", "Rugged", "Rain", "(Intercept)")

fit_all <- function(fl, data) map(fl, ~ feols(.x, data = data, vcov = "iid"))
conley_se <- function(m, data, cutoff = 100) {
  sqrt(diag(vcov(m, vcov = conley(cutoff = cutoff, distance = "spherical"))))
}
dat <- an |> rename(latitude = lat, longitude = lon)  # fixest conley auto-detects lat/lon names

extract_tab <- function(ms, rows, tab, data) {
  imap_dfr(ms, function(m, j) {
    j <- as.integer(j)
    b <- coef(m); s_iid <- se(m); s_hc1 <- se(summary(m, vcov = "hetero"))
    s_con <- conley_se(m, data)
    coefs <- tibble(term = names(b), value = b, se = s_iid, se_hc1 = s_hc1[names(b)],
                    se_conley100 = s_con[names(b)]) |>
      filter(term %in% rows) |>
      mutate(r = match(term, rows))
    stats <- tibble(term = c("R2", "N", "F"),
                    value = c(r2(m, "r2"), nobs(m), fitstat(m, "f")$f$stat),
                    r = length(rows) + 1:3)
    bind_rows(coefs, stats) |> mutate(c = j, tab = tab, n = nobs(m))
  })
}

m2 <- fit_all(t2f, dat); m3 <- fit_all(t3f, dat)
r2t <- extract_tab(m2, t2rows, "T2", dat); r3t <- extract_tab(m3, t3rows, "T3", dat)

# claims rows use the published row order; Table 2: Settle1830, Pop1911, Homeland,
# Pop1996, Rugged, Rain, Constant, R2, N, F (= r1..r10); Table 3: Pop1911, Homeland,
# Pop2011, NetMig11, Rugged, Rain, Constant, R2, N, F.
reg <- bind_rows(r2t, r3t) |> mutate(claim_id = sprintf("%s_r%d_c%d", tab, r, c))

# conleyreg cross-check of Conley SEs for the three headline columns
cr_check <- map_dfr(list(T2_7 = t2f[["7"]], T3_6 = t3f[["6"]], T3_10 = t3f[["10"]]), function(f) {
  x <- conleyreg(f, data = an, lat = "lat", lon = "lon", dist_cutoff = 100, kernel = "uniform",
                 st_distance = FALSE, gof = FALSE)
  tibble(term = rownames(x), est = x[, 1], se_conleyreg = x[, 2])
}, .id = "model")
write_csv(cr_check, file.path(rdir, "output", "conleyreg_crosscheck.csv"))

# ---------------- alternative-variable sensitivity (not used in results_r) ----------
alt <- an |> mutate(Unem2011 = Unem2011_alt, Unem1996 = Unem1996_alt) |>
  rename(latitude = lat, longitude = lon)
m3alt <- fit_all(t3f, alt)
alt_tab <- extract_tab(m3alt, t3rows, "T3alt_Unem_l_u11_u96old", alt) |>
  filter(c %in% c(1, 2, 5:8)) |> mutate(claim_id = sprintf("T3_r%d_c%d", r, c))
write_csv(alt_tab |> select(claim_id, term, value, se, se_hc1, se_conley100),
          file.path(rdir, "output", "sensitivity_alt_unemployment.csv"))

# ---------------- write results_r.csv ----------------
allv <- bind_rows(t1 |> select(claim_id, value, se, n),
                  reg |> select(claim_id, value, se, n))
res <- claims |> select(claim_id) |>
  left_join(allv, by = "claim_id") |>
  mutate(source = "r",
         status_override = if_else(is.na(value), "not-attempted", NA_character_)) |>
  select(claim_id, source, value, se, n, status_override)
stopifnot(sum(!is.na(res$value)) == sum(grepl("^T[123]_", claims$claim_id)))
write_csv(res, file.path(rdir, "results_r.csv"), na = "")

se_alt <- reg |> filter(!is.na(se)) |>
  select(claim_id, term, value, se_iid = se, se_hc1, se_conley100)
write_csv(se_alt, file.path(rdir, "output", "results_r_se_types.csv"))

# ---------------- .tex tables ----------------
gm <- tibble::tribble(~raw, ~clean, ~fmt, "r.squared", "R-squared", 3, "nobs", "N", 0)
for (spec in list(list(m = m2, nm = "table2", rows = t2rows, ttl = "Population persistence"),
                  list(m = m3, nm = "table3", rows = t3rows, ttl = "Reversals of fortune"))) {
  for (vc in c("iid", "hetero")) {
    ms_v <- map(spec$m, ~ summary(.x, vcov = vc))
    modelsummary(ms_v, output = file.path(rdir, "output", sprintf("%s_%s.tex", spec$nm, if (vc == "hetero") "hc1" else vc)),
                 fmt = 3, stars = c("*" = .1, "**" = .05, "***" = .01),
                 coef_map = setNames(sub("(Intercept)", "Constant", spec$rows, fixed = TRUE), spec$rows),
                 gof_map = gm, title = paste0(spec$ttl, " (R recreation, SE: ", vc, ")"))
  }
  ms_con <- map(spec$m, ~ summary(.x, vcov = conley(cutoff = 100, distance = "spherical")))
  modelsummary(ms_con, output = file.path(rdir, "output", sprintf("%s_conley100.tex", spec$nm)),
               fmt = 3, stars = c("*" = .1, "**" = .05, "***" = .01),
               coef_map = setNames(sub("\\(Intercept\\)", "Constant", spec$rows), spec$rows),
               gof_map = gm, title = paste0(spec$ttl, " (R recreation, Conley 100 km)"))
}
cat("Done. Non-missing results:", sum(!is.na(res$value)), "of", nrow(res), "\n")
