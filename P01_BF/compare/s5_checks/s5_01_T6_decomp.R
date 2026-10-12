# P01_BF S5 check 1: Table 6 headline coefficients.
# (a) Replicate the original Stata logit + mfx (MEM, discrete change for dummies) on data.dta in R.
# (b) Decompose the pair-B gap: swap gender variable, birth-decade construction and origin coding
#     between the original (data.dta) and the S3 rebuild (p01_full.rds), one at a time and jointly.
# (c) Headline sensitivity: SE type (conventional / HC1 / cluster by court volume), AME, LPM.
# Inputs : ./P01_BF/original/Baten Fourie/data.dta; repro_r/_scratch/p01_full.rds (D:)
# Output : compare/s5_checks/s5_01_T6_decomp.csv
suppressPackageStartupMessages({library(tidyverse); library(haven); library(sandwich); library(here)})
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
out  <- file.path(proj, "P01_BF", "compare", "s5_checks")

o <- read_dta(dpath("P01_BF", "original", "Baten Fourie", "data.dta")) |> zap_labels()
f <- readRDS(dscratch("P01_BF", "repro_r", "p01_full.rds"))
stopifnot(nrow(o) == nrow(f), all(o$age == f$age, na.rm = TRUE))

grp_r <- c("Cape-born" = "za", "Chinese" = "cn", "European" = "eur", "South-east Asian" = "id",
           "Indian" = "in", "Khoesan" = "ko", "Mozambican" = "mz", "Slave, unknown" = "oth_bl")
d <- o |>
  transmute(age, cyear, source, exact = exactage, age23, female_orig = female2, female_r = f$female,
            bdec_orig = bdec, bdec_r = f$bdec, grp_orig = bco, grp_r = unname(grp_r[as.character(f$group)])) |>
  filter(age > 22, age < 83, bdec_orig >= 1650, !is.na(cyear))          # l.1656 sample (1,802)
stopifnot(nrow(d) == 1802)

lv <- c("za", "cn", "eur", "id", "in", "ko", "mz", "oth_bl")
fit6 <- function(dd, fem, bd, gr) {
  dd <- dd |> mutate(fem = .data[[fem]], bd = factor(.data[[bd]]), g = factor(.data[[gr]], levels = lv))
  glm(exact ~ fem + age23 + g + bd, family = binomial, data = dd)
}
# Stata mfx: discrete change 0->1 for each dummy, all other regressors at their sample means
mem <- function(m, V = vcov(m)) {
  X <- model.matrix(m); xb <- colMeans(X); b <- coef(m)
  terms <- grep("^g", names(b), value = TRUE)
  dc <- function(bb, t) { x1 <- xb; x0 <- xb; x1[t] <- 1; x0[t] <- 0; plogis(sum(x1 * bb)) - plogis(sum(x0 * bb)) }
  map_dfr(terms, function(t) {
    est <- dc(b, t)
    J <- sapply(seq_along(b), function(k) { h <- 1e-6; bb <- b; bb[k] <- bb[k] + h; (dc(bb, t) - est) / h })
    se <- sqrt(drop(t(J) %*% V %*% J))
    tibble(term = sub("^g", "", t), me125 = 125 * est, se125 = 125 * se, p = 2 * pnorm(-abs(est / se)))
  })
}
ame <- function(m) {
  dd <- m$model; b <- coef(m); X <- model.matrix(m)
  map_dfr(grep("^g", names(b), value = TRUE), function(t) {
    gl <- sub("^g", "", t); X1 <- X; X0 <- X
    X1[, grep("^g", colnames(X))] <- 0; X0[, grep("^g", colnames(X))] <- 0; X1[, t] <- 1
    tibble(term = gl, me125 = 125 * mean(plogis(X1 %*% b) - plogis(X0 %*% b)))
  })
}

swap <- tribble(~scenario, ~fem, ~bd, ~gr,
  "orig_all",          "female_orig", "bdec_orig", "grp_orig",
  "swap_gender",       "female_r",    "bdec_orig", "grp_orig",
  "swap_bdec",         "female_orig", "bdec_r",    "grp_orig",
  "swap_origin",       "female_orig", "bdec_orig", "grp_r",
  "swap_bdec_origin",  "female_orig", "bdec_r",    "grp_r",
  "rebuild_all",       "female_r",    "bdec_r",    "grp_r")
res <- pmap_dfr(swap, function(scenario, fem, bd, gr) {
  m <- fit6(d, fem, bd, gr)
  mem(m) |> mutate(scenario = scenario, vcov = "conv", N = nobs(m),
                   r2p = 1 - m$deviance / m$null.deviance)
})

# sensitivity on the original codings
m0 <- fit6(d, "female_orig", "bdec_orig", "grp_orig")
dm <- d |> mutate(g = factor(grp_orig, levels = lv))
sens <- bind_rows(
  mem(m0, vcovHC(m0, type = "HC0") * nobs(m0) / (nobs(m0) - 1)) |> mutate(scenario = "orig_robust", vcov = "robust"),
  mem(m0, vcovCL(m0, cluster = ~source, type = "HC0")) |> mutate(scenario = "orig_cluster_source", vcov = "cluster(source)"),
  ame(m0) |> mutate(scenario = "orig_AME", vcov = NA_character_),
  {
    l <- lm(I(125 * exact) ~ female2 + age23 + g + factor(bdec_orig), data = dm |> mutate(female2 = female_orig))
    V <- vcovHC(l, type = "HC1")
    tibble(term = sub("^g", "", names(coef(l))), me125 = coef(l), se125 = sqrt(diag(V))) |>
      filter(term %in% lv) |> mutate(p = 2 * pt(-abs(me125 / se125), l$df.residual), scenario = "orig_LPM_HC1", vcov = "HC1")
  }
) |> mutate(N = nobs(m0))
res <- bind_rows(res, sens) |> mutate(n_clusters = n_distinct(d$source))
write_csv(res, file.path(out, "s5_01_T6_decomp.csv"))
print(res |> filter(term %in% c("eur", "id", "in", "mz")) |> select(scenario, term, me125, se125, p) |>
        mutate(across(where(is.numeric), ~ round(., 3))), n = 60)
cat("court volumes (source):", n_distinct(d$source), "\n")
cat("cross-tab origin coding (orig rows x rebuild cols):\n"); print(table(d$grp_orig, d$grp_r))
cat("female2 vs rebuild female disagree:", sum(d$female_orig != d$female_r), "\n")
cat("birth decade disagree:", sum(d$bdec_orig != d$bdec_r), "\n")
