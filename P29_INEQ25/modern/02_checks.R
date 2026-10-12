# P29_INEQ25 S6 step 2: the card's verification checks (§4 "Checks before any verdict").
# (a) corrections OFF (raw-unit Fig 2 on the code's populations, Bethelsdorp1825 sheet, no Swartrivier sheep) must reproduce
#     the S2 values to < 1e-6: Fig 1 nodes, Fig 2 lines, Fig 6 points.
# (b) one synthetic zero row per enslaved man (per-year totals = sum of slave_men).
# (c) the weighted Gini used in the bootstrap equals ineq::Gini on the expanded sample.
# Run: Rscript P29_INEQ25/modern/02_checks.R
source("P29_INEQ25/modern/00_functions.R")
D <- readRDS(file.path(SCR, "data.rds"))
H <- function(k) readRDS(dpath(PAPER, "compare", "_scratch", "hooks", paste0(k, ".rds")))   # S2/S5 hooks (patched original code)
chk <- list(); addc <- function(check, quantity, s2, here) chk[[length(chk) + 1]] <<- tibble(check, quantity, s2_value = s2, modern = here, abs_diff = abs(s2 - here))

d <- value_rows(D$panel, D$prices)
# (a1) Fig 1 total-value nodes (author-instructed state, hook at l.694)
ps <- H("pre_slaves")$gini_total_production
for (dn in ps$period) addc("Fig1 total value", paste("decade", dn), ps$gini_total_value[ps$period == dn], gpt(h1_rows(d, dn)))
# (a2) Fig 2 four lines, raw units, code populations
h2 <- H("fig2") |> filter(!is.na(period)) |>
  mutate(s = recode(scenario, "Settlers only (no slaves)" = "settlers", "Settlers + slave assets (slaves not as households)" = "slaveassets",
                    "Settlers + slaves (slaves as households with zero assets)" = "zero", "Settlers + slaves (slaves with 12 sheep/year)" = "sheep12"))
for (i in seq_len(nrow(h2))) addc("Fig2 raw units", paste(h2$s[i], h2$period[i]), h2$gini[i], gpt(raw_rows(d, h2$period[i], h2$s[i])))
# (a3) Fig 6 points with corrections off
f6 <- H("fig6") |> filter(!is.na(gini))
off <- c(`Groenekloof Horses` = G(D$gk$horses), `Groenekloof Oxen` = G(D$gk$cattle_oxen), `Groenekloof Cattle` = G(D$gk$cattle_breeding),
         `Groenekloof Sheep` = G(D$gk$sheep), `Groenekloof Wheat reaped` = G(D$gk$wheat_reaped),
         `Swartrivier Horses` = G(D$sr$horses), `Swartrivier Oxen` = G(D$sr$cattle_oxen), `Swartrivier Cattle` = G(D$sr$cattle_breeding),
         `Swartrivier Wheat reaped` = G(D$sr$wheat_reaped),
         `Bethelsdorp Horses` = G(D$bd25$horses), `Bethelsdorp Oxen` = G(D$bd25$cattle_oxen), `Bethelsdorp Cattle` = G(D$bd25$cattle_breeding),
         `Bethelsdorp Sheep` = G(D$bd25$sheep))
for (i in seq_len(nrow(f6))) { k <- paste(f6$region[i], f6$asset[i]); addc("Fig6 (1825 BD sheet, no SR sheep)", k, f6$gini[i], off[[k]]) }
stopifnot(length(off) == nrow(f6))

# (b) synthetic zero rows: per-year count equals sum(slave_men), for every priced year
zr <- rbindlist(lapply(seq(1680, 1820, 20), function(p) h2_rows(d, p, "zero")))
zc <- zr[synth == TRUE, .(n_zero = .N), by = year]
sm <- d[is.finite(v), .(sum_slave_men = sum(slave_men)), by = year]
zz <- merge(sm, zc, by = "year", all = TRUE)[, n_zero := fifelse(is.na(n_zero), 0L, n_zero)]
syn_ok <- all(zz$n_zero == zz$sum_slave_men)
# (c) weighted Gini vs ineq::Gini on an expanded resample
set.seed(1); nd <- make_node(h1_rows(d, 1780)$x, h1_rows(d, 1780)$hh)
cnt <- tabulate(sample.int(max(d$hh), max(d$hh), replace = TRUE), max(d$hh))
w <- cnt[nd$cl]; wg <- wgini(nd$x, w); ig <- ineq::Gini(rep(nd$x, w))
addc("weighted Gini = ineq::Gini(rep(x, w))", "decade 1780, one cluster resample", ig, wg)

out <- bind_rows(chk)
res <- out |> group_by(check) |> summarise(n = n(), max_abs_diff = max(abs_diff), pass = all(abs_diff < 1e-6), .groups = "drop")
res <- bind_rows(res, tibble(check = "synthetic zero rows = sum(slave_men) per year", n = nrow(zz), max_abs_diff = max(abs(zz$n_zero - zz$sum_slave_men)), pass = syn_ok))
write_csv(out, file.path(OUT, "checks_detail.csv")); write_csv(res, file.path(OUT, "checks.csv"))
print(as.data.frame(res)); cat("total synthetic zero rows (1680-1839 priced years):", sum(zz$n_zero), "\n")
stopifnot(all(res$pass))
