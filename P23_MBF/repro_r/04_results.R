# P23_MBF S3 - 04_results.R: assemble results_r.csv (one row per claim) from aggregate outputs.
suppressMessages({ library(here); library(dplyr); library(readr); library(tidyr); library(stringr) })
proj <- here::here(); rr <- file.path(proj, "P23_MBF", "repro_r"); out <- file.path(rr, "output")
claims <- read_csv(file.path(proj, "P23_MBF", "claims", "claims.csv"), show_col_types = FALSE)
lg <- read_csv(file.path(out, "tables23_logit.csv"), show_col_types = FALSE)
t4 <- read_csv(file.path(out, "table4_spatial.csv"), show_col_types = FALSE) |> filter(W == "delaunay")
t1 <- read_csv(file.path(out, "table1_sample.csv"), show_col_types = FALSE)
tx <- read_csv(file.path(out, "text_numbers.csv"), show_col_types = FALSE)
ld <- read_csv(file.path(out, "leaders_by_country.csv"), show_col_types = FALSE)
six <- read_csv(file.path(out, "fig3_countries_higher.csv"), show_col_types = FALSE)
txv <- function(k) tx$value[tx$key == k]
row <- function(id, v, se = NA, n = NA, st = NA) tibble(claim_id = id, value = v, se = se, n = n, status_override = st)

R <- list()
# Table 1
for (i in seq_len(nrow(claims))) {
  id <- claims$claim_id[i]; if (!str_starts(id, "T1_")) next
  c1 <- t1 |> filter(cntry_name == claims$population[i])
  v <- switch(str_extract(id, "[a-z0-9]+$"), indep = c1$independence, census = c1$census,
              bd0 = c1$bdec_min, bd1 = c1$bdec_max)
  R[[id]] <- row(id, v, n = c1$n)
}
# Tables 2-3
tm <- c(br = "BR", ia = "BRxPI", pi = "preindep")
for (tb in c("T2", "T3")) for (cc in 1:4) {
  g <- lg |> filter(table == tb, col == cc); if (!nrow(g)) next
  n <- g$n[1]; geo <- if (tb == "T2" && cc %in% c(1, 3)) 0 else 8
  for (k in names(tm)) { x <- g |> filter(term == tm[k])
    if (nrow(x)) R[[paste(tb, k, cc)]] <- row(sprintf("%s_%s_c%d", tb, k, cc), x$coef, x$se_cluster, n) }
  R[[paste(tb, "n", cc)]] <- row(sprintf("%s_n_c%d", tb, cc), n, n = n)
  R[[paste(tb, "ci", cc)]] <- row(sprintf("%s_ctrlind_c%d", tb, cc), 5, n = n)
  R[[paste(tb, "cg", cc)]] <- row(sprintf("%s_ctrlgeo_c%d", tb, cc), geo, n = n)
  R[[paste(tb, "r2", cc)]] <- row(sprintf("%s_r2_c%d", tb, cc), g$pr2[1], n = n)
  R[[paste(tb, "cl", cc)]] <- row(sprintf("%s_clus_c%d", tb, cc), g$n_clusters[1], n = n)
}
# Table 4 (col = 2*(decade index) - 1 + controls)
t4 <- t4 |> mutate(col = 2 * ((decade - 1930) / 10) + 1 + (controls == 8))
for (i in seq_len(nrow(t4))) { x <- t4[i, ]; s <- sprintf("T4_%s_%%s_c%d", x$outcome, x$col)
  R[[sprintf(s, "br")]]   <- row(sprintf(s, "br"), x$coef, x$se, x$n)
  R[[sprintf(s, "rho")]]  <- row(sprintf(s, "rho"), x$rho, NA, x$n)
  R[[sprintf(s, "n")]]    <- row(sprintf(s, "n"), x$n, n = x$n)
  R[[sprintf(s, "ctrl")]] <- row(sprintf(s, "ctrl"), x$controls, n = x$n)
  R[[sprintf(s, "r2")]]   <- row(sprintf(s, "r2"), x$pr2, n = x$n) }
# Table 5: data not on allow-list
for (id in claims$claim_id[str_starts(claims$claim_id, "T5_")]) R[[id]] <- row(id, NA, st = "unavailable")
# text
txt <- c(text_p1575_sum = txv("sum"), text_p1575_or = txv("or"), text_p1575_32pct = txv("pct32"),
         text_p1563_leaders = sum(ld$n_leaders), text_p1563_countries = nrow(t1),
         text_p1571_indiv = txv("n_indiv"), text_p1572_6of11 = sum(six$both),
         text_p1570_n623 = txv("n_regions"), text_p1570_n201 = txv("n_lev1"), text_p1570_sd20 = txv("sd_pct"),
         text_fn15_sd_comb = txv("sd_comb"), text_fn15_mean_comb = txv("mean_comb"),
         text_fn15_sd_first = txv("sd_first"), text_fn15_mean_first = txv("mean_first"),
         text_p1579_max645 = txv("max_regions"), text_p1579_min34 = txv("min_regions"),
         text_fn1_thyolo40 = txv("thyolo40"), text_fn1_thyolo60 = txv("thyolo60"),
         text_p1592_bal_ids = txv("bal_ids"), text_p1592_bal_obs = txv("bal_obs"))
for (k in names(txt)) R[[k]] <- row(k, unname(txt[k]))
res <- bind_rows(R) |> mutate(source = "r") |> select(claim_id, source, value, se, n, status_override)
miss <- setdiff(claims$claim_id, res$claim_id)
res <- bind_rows(res, tibble(claim_id = miss, source = "r", status_override = "not-attempted"))
res <- res |> filter(claim_id %in% claims$claim_id) |> arrange(match(claim_id, claims$claim_id))
write_csv(res, file.path(rr, "results_r.csv"), na = "")
cat(nrow(res), "rows; missing mapped:", length(miss), paste(miss, collapse = " "), "\n")
