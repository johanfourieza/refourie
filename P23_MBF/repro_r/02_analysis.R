# P23_MBF S3 independent recreation - 02_analysis.R
# Tables 2-4 and text numbers. Writes aggregate outputs only (coefficients, SEs, counts).
suppressMessages({
  library(here); library(dplyr); library(readr); library(tidyr); library(fixest); library(spdep)
})
proj <- here::here()
source(file.path(proj, "tools", "paths.R"))
P <- "P23_MBF"
scr <- function(...) dscratch(P, "repro_r", ...)
out <- file.path(proj, "P23_MBF", "repro_r", "output")
dir.create(out, showWarnings = FALSE)
set.seed(20231)

ind <- readRDS(scr("ind_sample.rds"))
reg <- readRDS(scr("regions.rds"))
agg <- readRDS(scr("region_decade.rds"))

ictl <- c("age", "age2", "female", "d_muslim", "d_christian", "rural")
gctl <- c("tse_r", "railway_density", "count_tribe", "slave_density", "d_mission", "dist_cap",
          "d_western", "d_capital")

# ---------------------------------------------------------------- Tables 2-3 (logit)
fit_logit <- function(data, br, inter, geo) {
  data$BR <- data[[br]]
  data <- data[!is.na(data$BR), ]
  data$BRxPI <- data$BR * data$preindep
  rhs <- c("BR", if (inter) c("BRxPI", "preindep"), ictl, if (geo) gctl)
  fml <- as.formula(paste("primary ~", paste(rhs, collapse = " + "), "| cntry_name"))
  m <- feglm(fml, data = data, family = binomial("logit"), vcov = ~id_birth)
  se_cl <- se(m); se_iid <- se(summary(m, vcov = "iid")); se_hc <- se(summary(m, vcov = "hetero"))
  terms <- intersect(c("BR", "BRxPI", "preindep"), names(coef(m)))
  tibble(term = terms, coef = coef(m)[terms], se_cluster = se_cl[terms], se_iid = se_iid[terms],
         se_hc1 = se_hc[terms], n = nobs(m), pr2 = as.numeric(fitstat(m, "pr2")),
         n_clusters = length(unique(data$id_birth[obs(m)])))
}

specs <- tribble(
  ~table, ~col, ~sample, ~br, ~inter, ~geo,
  "T2", 1, "all", "d_birth_all", FALSE, FALSE,
  "T2", 2, "all", "d_birth_all", FALSE, TRUE,
  "T2", 3, "all", "d_birth_all", TRUE, FALSE,
  "T2", 4, "all", "d_birth_all", TRUE, TRUE,
  "T3", 1, "all", "d_birth_coup", TRUE, TRUE,
  "T3", 2, "all", "d_birth_elite", TRUE, TRUE,
  "T3", 3, "k2", "d_birth_all", TRUE, TRUE,
  "T3", 4, "k3", "d_birth_all", TRUE, TRUE)

res <- list()
for (i in seq_len(nrow(specs))) {
  s <- specs[i, ]
  dat <- switch(s$sample, all = ind, k2 = filter(ind, !drop_k2), k3 = filter(ind, !drop_k3))
  if (s$sample != "all") dat$preindep <- as.numeric(dat$age_ind > 13)
  r <- fit_logit(dat, s$br, s$inter, s$geo)
  res[[i]] <- bind_cols(s[rep(1, nrow(r)), c("table", "col")], r)
  cat(s$table, s$col, "done\n"); rm(dat); gc(verbose = FALSE)
}
logit_res <- bind_rows(res)
write_csv(logit_res, file.path(out, "tables23_logit.csv"))

# ---------------------------------------------------------------- Table 4 (spatial error GM)
# Kelejian-Prucha (1999) GM estimator for rho in u = rho W u + e, then spatial FGLS.
gm_error <- function(y, X, W) {
  n <- length(y)
  b0 <- qr.coef(qr(X), y); u <- as.vector(y - X %*% b0)
  ub <- as.vector(W %*% u); ubb <- as.vector(W %*% ub)
  trWW <- sum(W * W)
  G <- rbind(c(2 * sum(u * ub), -sum(ub * ub), n),
             c(2 * sum(ubb * ub), -sum(ubb * ubb), trWW),
             c(sum(u * ubb) + sum(ub * ub), -sum(ub * ubb), 0)) / n
  g <- c(sum(u * u), sum(ub * ub), sum(u * ub)) / n
  obj <- function(p) { v <- g - G %*% c(p[1], p[1]^2, p[2]); sum(v^2) }
  op <- optim(c(0.5, var(u)), obj, method = "L-BFGS-B", lower = c(-0.99, 1e-8), upper = c(1.5, Inf))
  rho <- op$par[1]
  ys <- y - rho * as.vector(W %*% y); Xs <- X - rho * (W %*% X)
  q <- qr(Xs); b <- qr.coef(q, ys); e <- as.vector(ys - Xs %*% b)
  s2 <- sum(e^2) / (n - ncol(X))
  V <- s2 * chol2inv(qr.R(q))
  fit <- as.vector(X %*% b)
  list(b = setNames(b, colnames(X)), se = setNames(sqrt(diag(V)), colnames(X)), rho = rho,
       n = n, pr2 = cor(y, fit)^2, conv = op$convergence)
}

make_W <- function(df, type = c("delaunay", "knn5")) {
  type <- match.arg(type)
  xy <- cbind(df$lon_id_bir, df$lat_id_bir)
  xy <- xy + matrix(rnorm(length(xy), 0, 1e-7), ncol = 2)  # break exact ties in centroids
  nb <- if (type == "delaunay") tri2nb(xy) else knn2nb(knearneigh(xy, k = 5, longlat = TRUE))
  nb2mat(nb, style = "W", zero.policy = TRUE)
}

t4 <- list(); k <- 0
for (yv in c("yrschool", "abcc", "gini")) {
  for (dec in c(1930, 1940, 1950, 1960, 1970)) {
    for (geo in c(FALSE, TRUE)) {
      for (wt in c("delaunay", "knn5")) {
        df <- agg |> filter(bdec_r == dec, !is.na(.data[[yv]]))
        if (geo) df <- df |> filter(if_all(all_of(gctl), ~ !is.na(.x)))
        fe <- !(yv == "abcc" && dec == 1930 && !geo)
        rhs <- c("d_birth_all", if (geo) gctl)
        X <- model.matrix(as.formula(paste("~", paste(rhs, collapse = "+"),
                                           if (fe) "+ factor(cntry_name)")), df)
        X <- X[, qr(X)$pivot[seq_len(qr(X)$rank)], drop = FALSE]
        W <- make_W(df, wt)
        r <- gm_error(df[[yv]], X, W)
        k <- k + 1
        t4[[k]] <- tibble(outcome = yv, decade = dec, controls = ifelse(geo, 8, 0), W = wt,
                          country_fe = fe, coef = r$b["d_birth_all"], se = r$se["d_birth_all"],
                          rho = r$rho, n = r$n, pr2 = r$pr2, conv = r$conv)
      }
    }
  }
}
t4 <- bind_rows(t4)
write_csv(t4, file.path(out, "table4_spatial.csv"))

# ---------------------------------------------------------------- text numbers
c4 <- logit_res |> filter(table == "T2", col == 4)
b1 <- c4$coef[c4$term == "BR"]; b3 <- c4$coef[c4$term == "BRxPI"]
regs_dec <- agg |> filter(!is.na(yrschool)) |> count(bdec_r, name = "n_regions")
bal <- agg |> filter(bdec_r %in% c(1940, 1950, 1960), !is.na(yrschool)) |>
  count(id_birth) |> filter(n == 3)
lev1 <- reg |> group_by(cntry_name, geolev1) |> summarise(area = sum(area_km2), .groups = "drop")
thy <- agg |> filter(cntry_name == "Malawi") |>
  group_by(bdec_r) |>
  summarise(nat = weighted.mean(yrschool, n_ind, na.rm = TRUE),
            thy = yrschool[grepl("thyolo", admin_name, ignore.case = TRUE)][1], .groups = "drop") |>
  mutate(pct_below = 100 * (nat - thy) / nat)
txt <- tibble(
  key = c("sum", "or", "pct32", "n_indiv", "n_regions", "n_lev1", "sd_comb", "mean_comb",
          "sd_first", "mean_first", "sd_pct", "max_regions", "min_regions", "bal_ids", "bal_obs",
          "thyolo40", "thyolo60"),
  value = c(b1 + b3, exp(b1 + b3), 100 * (exp(b3) - 1), nrow(ind), n_distinct(reg$id_birth),
            nrow(lev1), sd(reg$area_km2), mean(reg$area_km2), sd(lev1$area), mean(lev1$area),
            100 * (sd(lev1$area) / sd(reg$area_km2) - 1), max(regs_dec$n_regions),
            min(regs_dec$n_regions), nrow(bal), 3 * nrow(bal),
            thy$pct_below[thy$bdec_r == 1940], thy$pct_below[thy$bdec_r == 1960]))
write_csv(txt, file.path(out, "text_numbers.csv"))
write_csv(regs_dec, file.path(out, "regions_by_decade.csv"))
print(logit_res, n = 50, width = 200); print(t4, n = 70, width = 200); print(txt)
