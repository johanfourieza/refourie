# P23_MBF S3 - 02b_posthoc.R (POST-HOC, logged in decisions.md; not the pre-specified estimate)
# Table 3 cols 3-4 re-run on the elite-leader Birth Region coding (d_birth_elite), because the
# published cluster count (609) equals col 2's, not the full sample's 624.
suppressMessages({ library(here); library(dplyr); library(readr); library(fixest) })
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
out <- file.path(proj, "P23_MBF", "repro_r", "output")
ind <- readRDS(dscratch("P23_MBF", "repro_r", "ind_sample.rds"))
ictl <- c("age", "age2", "female", "d_muslim", "d_christian", "rural")
gctl <- c("tse_r", "railway_density", "count_tribe", "slave_density", "d_mission", "dist_cap",
          "d_western", "d_capital")
res <- list()
for (k in c(2, 3)) {
  dat <- ind |> filter(!is.na(d_birth_elite), !(age_ind >= 6 - k & age_ind <= 13 + k)) |>
    mutate(BR = d_birth_elite, preindep = as.numeric(age_ind > 13), BRxPI = BR * preindep)
  fml <- as.formula(paste("primary ~", paste(c("BR", "BRxPI", "preindep", ictl, gctl), collapse = "+"),
                          "| cntry_name"))
  m <- feglm(fml, data = dat, family = binomial("logit"), vcov = ~id_birth)
  t <- c("BR", "BRxPI", "preindep")
  res[[k]] <- tibble(table = "T3", col = k + 1, variant = "elite_posthoc", term = t, coef = coef(m)[t],
                     se_cluster = se(m)[t], se_iid = se(summary(m, vcov = "iid"))[t], n = nobs(m),
                     pr2 = as.numeric(fitstat(m, "pr2")), n_clusters = length(unique(dat$id_birth)))
}
r <- bind_rows(res); write_csv(r, file.path(out, "table3_c34_elite_posthoc.csv")); print(r, width = 200)
