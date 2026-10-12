# P25_MCF S3 rebuild, step 2: compensation-shortfall distribution, sample counts, and arithmetic
# checks of derived claims. Writes repro_r/results_r.csv for every claim_id in claims.csv.
suppressMessages({library(dplyr); library(readr); library(ggplot2); library(here)})
source(here::here("tools", "paths.R"))
set.seed(20231)
out <- function(...) here::here("P25_MCF", "repro_r", "output", ...)
owners <- readRDS(dpath("P25_MCF", "repro_r", "derived", "owners.rds"))

# Sample definitions (D3). A = compensation recorded and >= 1 slave valued (paper's wording,
# "value of slaves and/or the compensated value could not be retrieved"); B = A and every slave valued;
# C = B with positive shortfall (paper's Table 1 minimum is 0.88 > 0).
defs <- list(A = filter(owners, has_comp, n_valued >= 1),
             B = filter(owners, has_comp, all_valued),
             C = filter(owners, has_comp, all_valued, AS > 0))
dist <- bind_rows(lapply(names(defs), function(k) {
  x <- defs[[k]]
  tibble(definition = k, N = nrow(x), N_stell = sum(x$stell), N_other = sum(!x$stell),
         AS_mean = mean(x$AS), AS_sd = sd(x$AS), AS_min = min(x$AS), AS_p50 = median(x$AS),
         AS_max = max(x$AS), AS_neg = sum(x$AS < 0),
         compshare_aggregate = sum(x$C) / sum(x$V), compshare_median = median(x$comp_share, na.rm = TRUE),
         V_total = sum(x$V), C_total = sum(x$C))
}))
write_csv(dist, out("shortfall_distribution.csv"))

# Figure: distribution of average shortfall per slave, definition B
fig <- ggplot(defs$B |> filter(AS > -50), aes(AS)) +
  geom_histogram(binwidth = 5, fill = "#1F3A5F", colour = "white") +
  geom_vline(xintercept = 65.93, linetype = "dashed", colour = "#B5524A") +
  labs(x = "Average shortfall per slave (£)", y = "Slaveholders",
       caption = "Owners with compensation and all slaves valued; 14 owners with AS < -£50 omitted. Dashed: paper's Table 1 mean (linked sample).") +
  theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank())
ggsave(out("fig_shortfall_hist.pdf"), fig, width = 7, height = 4.2)
ggsave(out("fig_shortfall_hist.png"), fig, width = 7, height = 4.2, dpi = 300)

# Arithmetic checks of derived claims from other published numbers (D5)
b_stell <- -0.0073; b_all <- -0.0046                  # T2_r1_c1, T2_r1_c4 (log points per £ of AS)
arith <- tribble(~claim_id, ~value, ~basis,
  "text_p11_effect_stell", 100 * (exp(10 * b_stell) - 1), "100*(exp(10*T2_r1_c1)-1), AS in £",
  "text_p11_effect_all",   100 * (exp(10 * b_all) - 1),   "100*(exp(10*T2_r1_c4)-1), AS in £",
  "text_p11_mean_shortfall_effect", 100 * (exp(65 * b_all) - 1), "100*(exp(65*T2_r1_c4)-1)",
  "text_p11_years_lost", 67 * (exp(65 * b_all) - 1), "67*(exp(65*T2_r1_c4)-1)",
  "text_p6_pop_g1", 314 + 665, "text_p6_stell_g1 + text_p5_nonstell_g1",
  "text_p6_pop_g2", 1744 + 4319, "text_p6_stell_g2 + text_p5_nonstell_g2",
  "text_p6_pop_g3", 2458 + 8204, "text_p6_stell_g3 + text_p5_nonstell_g3",
  "text_p4_wealth_loss", 24 * (1 - c(0.5)), "24% slave share x (1 - 0.5) shortfall share; 0.4 gives 14.4")
write_csv(arith, out("arithmetic_checks.csv"))

# results_r.csv: every claim_id (claims.csv holds a duplicated id, T5_r2_c1, kept as two rows)
claims <- read_csv(here::here("P25_MCF", "claims", "claims.csv"), show_col_types = FALSE) |> distinct(claim_id)  # T5_r2_c1 duplicated in frozen claims (F7)
A <- dist |> filter(definition == "A"); B <- dist |> filter(definition == "B")
rebuilt <- tribble(~claim_id, ~value, ~n,
  "text_p5_sample_n", A$N, A$N,
  "text_p5_stell_n",  A$N_stell, A$N_stell,
  "text_p5_other_n",  A$N_other, A$N_other,
  "text_p1_compshare", 100 * B$compshare_aggregate, B$N) |>
  bind_rows(arith |> select(claim_id, value) |> mutate(n = NA_real_))
res <- claims |> select(claim_id) |>
  left_join(rebuilt, by = "claim_id") |>
  mutate(source = "r", se = NA_real_,
         status_override = ifelse(is.na(value), "unavailable", "")) |>
  select(claim_id, source, value, se, n, status_override)
write_csv(res, here::here("P25_MCF", "repro_r", "results_r.csv"), na = "NA")
print(dist, width = 200); print(arith); cat("rebuilt:", sum(!is.na(res$value)), "of", nrow(res), "\n")

# Exogeneity check (F4): AS is mechanically V/S - C/S; correlation with valuation per slave and slave count
xb <- defs$C |> mutate(v_per_slave = V / n_slaves)
exo <- tibble(stat = c("cor(AS, V/S)", "cor(AS, C/S)", "cor(AS, n_slaves)", "R2 AS ~ V/S", "N"),
              value = c(cor(xb$AS, xb$v_per_slave), cor(xb$AS, xb$C / xb$n_slaves), cor(xb$AS, xb$n_slaves),
                        summary(lm(AS ~ v_per_slave, xb))$r.squared, nrow(xb)))
write_csv(exo, out("exogeneity_check.csv")); print(exo)
