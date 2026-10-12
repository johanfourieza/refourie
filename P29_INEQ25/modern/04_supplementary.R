# P29_INEQ25 S6 step 4: supplementary analyses (card §5B, §5C.1-2) and secondary outputs S-d, S-e, S-f.
# None of these sets a verdict. Writes output/sensitivities.csv (with the central-draw rows from 03) and output/influence.csv.
# Run after 03: Rscript P29_INEQ25/modern/04_supplementary.R
source("P29_INEQ25/modern/00_functions.R")
D <- readRDS(file.path(SCR, "data.rds"))
d <- value_rows(D$panel, D$prices)
DECS <- seq(1690, 1830, 10)
sec <- list(); adds <- function(item, quantity, est, L = NA, U = NA, note = "", n_undef = NA) sec[[length(sec) + 1]] <<-
  tibble(section = item, quantity = quantity, estimate = est, L = L, U = U, n_undefined_draws = n_undef, note = note)
h1_all <- function(dd, decs = DECS) sapply(decs, function(dn) gpt(h1_rows(dd, dn)))
rep_h1h2 <- function(item, dd, note = "", decs = DECS, h2 = TRUE) {
  g <- h1_all(dd, decs)
  ok <- is.finite(g)
  adds(item, "H1 min decade Gini", min(g[ok]), note = sprintf("%s; argmin %d; max %.3f; all computable > 0.60: %s; nodes %d-%d; not computable (no rows): %s", note,
       decs[ok][which.min(g[ok])], max(g[ok]), all(g[ok] > 0.60), min(decs), max(decs), if (all(ok)) "none" else paste(decs[!ok], collapse = " ")))
  if (h2) { g2 <- gpt(h2_rows(dd, 1780, "zero")); adds(item, "H2 1780 Gini", g2, note = sprintf("%s; in [0.89, 0.95]: %s", note, g2 >= 0.89 & g2 <= 0.95)) }
}

## ---- §5B changed estimand or population (points only, one item at a time) ------------------------------------
rep_h1h2("5B.1 V2b vines at one year's yield value (six-asset basket; double counts the wine flow)", value_rows(D$panel, D$prices, vines = "yield"), "different estimand")
rep_h1h2("5B.1 V2c vines at 0.5 rix-dollars per vine (exploratory; undocumented 2026 rule)", value_rows(D$panel, D$prices, vines = "half"), "different estimand, exploratory")
dv1 <- value_rows(D$panel, D$prices, cover = TRUE)
n_end <- c(`1680` = nrow(dv1[dnode == 1680 & is.finite(v)]), `1840` = nrow(dv1[dnode == 1840 & is.finite(v)]))
decs_v1 <- sort(c(DECS, as.numeric(names(n_end)[n_end >= 100])))
rep_h1h2("5B.2 V1 coverage: 1685-89 at 1690 prices, 1840-44 at 1830 prices", dv1, sprintf("rows 1685-89 %d, 1840-44 %d; node 1680 G=%.3f, 1840 G=%.3f",
  n_end[1], n_end[2], gpt(h1_rows(dv1, 1680)), gpt(h1_rows(dv1, 1840))), decs = decs_v1)
ann1 <- sapply(DECS, function(dn) { r <- h1_rows(d, dn); mean(sapply(split(r$x, r$year), G)) })
r2 <- h2_rows(d, 1780, "zero"); ann2 <- mean(sapply(split(r2$x, r2$year), G))
adds("5B.3 V5 mean of annual Ginis (Fig 1 caption)", "H1 min decade", min(ann1), note = sprintf("argmin %d; max %.3f; all > 0.60: %s", DECS[which.min(ann1)], max(ann1), all(ann1 > 0.60)))
adds("5B.3 V5 mean of annual Ginis (Fig 1 caption)", "H2 1780 Gini", ann2, note = sprintf("in [0.89, 0.95]: %s", ann2 >= 0.89 & ann2 <= 0.95))
# V6: thresholds once on the full data; a component > 10 x that year's p99 of positive values -> NA -> row dropped (with its synthetic rows)
comp <- c("horses", "cattle", "sheep", "wheat_vol", "wine")
flag <- rep(FALSE, nrow(d))
for (cc in comp) { thr <- d[get(cc) > 0, .(t = 10 * quantile(get(cc), 0.99, type = 7)), by = year]
  x <- thr[d, on = "year"]; flag <- flag | (!is.na(x$t) & x[[cc]] > x$t) }
dv6 <- copy(d); dv6[flag, v := NA_real_]
rep_h1h2("5B.4 V6 trimming (> 10 x year p99 of positive values; rows dropped)", dv6, sprintf("%d rows flagged (of %d priced rows)", sum(flag & is.finite(d$v)), sum(is.finite(d$v))))
for (s in c("V7b", "V7c")) { g <- gpt(h2_rows(d, 1780, s))
  adds(sprintf("5B.5 %s enslaved people in owners' wealth (%s)", s, ifelse(s == "V7b", "200 x sheep price", "MOOC10 category prices")), "H2 1780 Gini", g,
       note = sprintf("different estimand; in [0.89, 0.95]: %s", g >= 0.89 & g <= 0.95)) }
rep_h1h2("5B.6 settler-only population (settler_men > 0 or settler_women > 0)", d[settler_men > 0 | settler_women > 0], "changed population")
for (p in c(1760, 1800)) { g <- gpt(h2_rows(d, p, "zero")); adds("5B.7 H2 in other periods", paste("H2 period", p), g, note = sprintf("in [0.89, 0.95]: %s", g >= 0.89 & g <= 0.95)) }
g <- gpt(h2_rows(d, 1780, "zero", zero_def = "adults"))
adds("5B.8 H2 with all enslaved adults (men + women) as zero-value rows", "H2 1780 Gini", g, note = sprintf("in [0.89, 0.95]: %s", g >= 0.89 & g <= 0.95))
rep_h1h2("5B.11 vines capitalised at 6% (exploratory; the paper's rate for enslaved people)", value_rows(D$panel, D$prices, vines = "cap6"), "different estimand, exploratory")
# H3 items
h3set <- function(bd, gk, sr, sr_sheep = TRUE) {
  g <- c(`Bethelsdorp Cattle` = G(bd$cattle_breeding), `Bethelsdorp Horses` = G(bd$horses), `Bethelsdorp Oxen` = G(bd$cattle_oxen), `Bethelsdorp Sheep` = G(bd$sheep),
         `Groenekloof Horses` = G(gk$horses), `Groenekloof Oxen` = G(gk$cattle_oxen), `Groenekloof Cattle` = G(gk$cattle_breeding), `Groenekloof Sheep` = G(gk$sheep),
         `Groenekloof Wheat reaped` = G(gk$wheat_reaped), `Swartrivier Horses` = G(sr$horses), `Swartrivier Oxen` = G(sr$cattle_oxen),
         `Swartrivier Cattle` = G(sr$cattle_breeding), `Swartrivier Sheep` = G(sr$sheep), `Swartrivier Wheat reaped` = G(sr$wheat_reaped))
  if (!sr_sheep) g <- g[names(g) != "Swartrivier Sheep"]
  g }
g9 <- h3set(D$bd25, D$gk, D$sr); oth9 <- g9[-1]
adds("5B.9 H3 with the code's Bethelsdorp1825 sheet", "H3a Bethelsdorp cattle", g9[1], note = sprintf("in [0.69, 0.75]: %s", g9[1] >= 0.69 & g9[1] <= 0.75))
adds("5B.9 H3 with the code's Bethelsdorp1825 sheet", "H3b min other asset (computable)", min(oth9, na.rm = TRUE),
     note = sprintf("argmin %s; all computable > 0.75: %s; not computable: %s", names(which.min(oth9)), all(oth9[is.finite(oth9)] > 0.75), paste(names(oth9)[!is.finite(oth9)], collapse = ", ")))
g10 <- h3set(D$bd14, D$gk, D$sr, sr_sheep = FALSE)[-1]
adds("5B.10 H3b without Swartrivier sheep (the plotted set), central sheets", "H3b min other asset", min(g10),
     note = sprintf("argmin %s; all > 0.75: %s (points only)", names(which.min(g10)), all(g10 > 0.75)))

## ---- §5C.1 missingness ------------------------------------------------------------------------------------------
pn <- D$panel[, dnode := (year %/% 10) * 10]
miss <- pn[, .(n = .N, na_clean_horses = mean(is.na(horses)), na_clean_sheep = mean(is.na(sheep)), na_clean_wheat = mean(is.na(wheat_vol)),
               na_clean_vines = mean(is.na(vines)), na_clean_wine = mean(is.na(wine)), na_clean_cattle = mean(is.na(cattle)),
               blank_horses = mean(na_horses), blank_cattle = mean(na_cattle), blank_sheep = mean(na_sheep), blank_wheat = mean(na_wheat_vol),
               blank_vines = mean(na_vines), blank_wine = mean(na_wine)), by = dnode][order(dnode)]
write_csv(miss |> mutate(across(where(is.double) & !dnode, ~ round(.x, 4))), file.path(OUT, "missingness.csv"))
for (a in c("horses", "cattle", "sheep", "wheat", "vines", "wine"))
  adds("5C.1 missingness (share of rows; full table in missingness.csv)", paste(a, "raw blank, all rows 1685-1844"), mean(pn[[paste0("na_", ifelse(a == "wheat", "wheat_vol", a))]]),
       note = sprintf("after the code's year-level NA->0: %.4f; decades with any post-cleaning NA: %s", mean(is.na(pn[[ifelse(a == "wheat", "wheat_vol", a)]])),
                      paste(miss$dnode[miss[[paste0("na_clean_", a)]] > 0], collapse = " ")))
for (s in c("gk", "sr")) { m <- D[[paste0(s, "_na")]]; for (a in names(m))
  adds("5C.1 missingness, Khoe settlements (raw blank share)", paste(c(gk = "Groenekloof", sr = "Swartrivier")[s], a), mean(m[[a]])) }
for (a in c("cattle_breeding", "horses", "cattle_oxen", "sheep")) adds("5C.1 missingness, Khoe settlements (raw blank share)", paste("Bethelsdorp 1814", a), mean(is.na(D$bd14[[a]])))
# alternatives (report only): post-cleaning NA status of the five basket assets (the NAs that the basket's NA->0 rule zeroes)
mna <- D$panel[, .(all_na = is.na(horses) & is.na(sheep) & is.na(wheat_vol) & is.na(wine), any_na = is.na(horses) | is.na(sheep) | is.na(wheat_vol) | is.na(wine))]
rep_h1h2("5C.1 alternative (a): rows with every basket asset NA dropped", d[!mna$all_na], sprintf("%d rows dropped (cattle is a row sum and never NA)", sum(mna$all_na)))
rep_h1h2("5C.1 alternative (b): complete cases for the basket", d[!mna$any_na], sprintf("%d rows dropped", sum(mna$any_na)))

## ---- §5C.2 influence: leave-one-cluster-out ---------------------------------------------------------------------
loo <- function(r, label) {
  nd <- make_node(r$x, r$hh); g0 <- wgini(nd$x, rep(1L, length(nd$x)))
  cls <- unique(nd$cl); dg <- vapply(cls, function(c) wgini(nd$x, as.integer(nd$cl != c)) - g0, numeric(1))
  o <- order(-abs(dg))[1:10]
  info <- r[!r$synth, .(rows = paste(sprintf("%d:%d", d$original_row[row], year), collapse = " ")), by = hh]
  list(max = max(abs(dg)), top = tibble(node = label, rank = 1:10, hhid_ext_safe = D$panel$hhid_ext_safe[match(cls[o], D$panel$hh)],
                                       delta_G = dg[o], rows_original_row_year = info$rows[match(cls[o], info$hh)]))
}
infl <- list()
for (dn in DECS) { L1 <- loo(h1_rows(d, dn), paste("H1 decade", dn)); infl[[length(infl) + 1]] <- L1$top
  adds("5C.2 influence: max |dG| leaving one household cluster out", paste("H1 decade", dn), L1$max) }
L2 <- loo(h2_rows(d, 1780, "zero"), "H2 1780"); infl[[length(infl) + 1]] <- L2$top
adds("5C.2 influence: max |dG| leaving one household cluster out", "H2 1780", L2$max)
write_csv(bind_rows(infl) |> mutate(delta_G = round(delta_G, 6)), file.path(OUT, "influence.csv"))
h3m <- list(`Bethelsdorp 1814` = D$bd14 |> transmute(Cattle = cattle_breeding, Horses = horses, Oxen = cattle_oxen, Sheep = sheep),
            Groenekloof = D$gk |> transmute(Horses = horses, Oxen = cattle_oxen, Cattle = cattle_breeding, Sheep = sheep, `Wheat reaped` = wheat_reaped),
            Swartrivier = D$sr |> transmute(Horses = horses, Oxen = cattle_oxen, Cattle = cattle_breeding, Sheep = sheep, `Wheat reaped` = wheat_reaped))
for (s in names(h3m)) for (a in names(h3m[[s]])) { x <- h3m[[s]][[a]]; g0 <- G(x); np <- sum(x > 0, na.rm = TRUE)
  mx <- if (is.finite(g0)) max(abs(sapply(seq_along(x), function(i) G(x[-i]) - g0)), na.rm = TRUE) else NA
  adds("5C.2 influence, Khoe settlements: positive holders and max |dG| leaving one household out", paste(s, a), g0,
       note = sprintf("positive holders %d of %d%s; max |dG| %s", np, length(x), ifelse(np < 10, " [FLAG: < 10 holders]", ""), ifelse(is.na(mx), "NA", sprintf("%.4f", mx)))) }

## ---- secondary bootstraps: S-d (Fig 5 owner level), S-e (Khoe + Swellendam), S-f (probates) ---------------------
B2 <- 9999
sed <- D$sed |> mutate(owner = paste(Owner_name, Owner_surname, sep = " "))
own <- sed |> group_by(District_name, owner) |>
  summarise(val = if (all(is.na(Valuation))) NA_real_ else sum(Valuation, na.rm = TRUE),
            comp = if (all(is.na(Compensation))) NA_real_ else sum(Compensation, na.rm = TRUE), .groups = "drop")
k30 <- sed |> group_by(District_name) |> summarise(cur = n_distinct(owner), .groups = "drop") |> mutate(k30 = ceiling(cur * (100 / 30)) - cur)
ad <- D$all_districts
sh25 <- ad |> mutate(o = (slaves_men + slaves_women + slaves_sons + slaves_daughters) > 0) |> group_by(district) |> summarise(s = mean(o))
sh25 <- bind_rows(sh25, tibble(district = "Somerset", s = sh25$s[sh25$district == "Graaff-Reinet"])) |> mutate(District_name = recode(district, "Graaff-Reinet" = "Graaff Reinet"))
dist <- own |> count(District_name, name = "n_own") |> left_join(k30, by = "District_name") |> left_join(select(sh25, District_name, s), by = "District_name") |>
  mutate(k25 = round(n_own * (1 - s) / s))
OWN <- lapply(split(own, own$District_name), as.data.frame); DI <- as.data.frame(dist)
sd_stat <- function(OWN) unlist(lapply(names(OWN), function(dn) { o <- OWN[[dn]]; k <- DI[DI$District_name == dn, ]
  m <- !is.na(o$val) & !is.na(o$comp)
  setNames(c(G(o$val), G(o$comp), G(c(o$val[!is.na(o$val)], rep(0, k$k30))), G(c(o$comp[!is.na(o$comp)], rep(0, k$k30))),
             if (is.na(k$k25)) NA else G(c(o$val[!is.na(o$val)], rep(0, k$k25))), if (is.na(k$k25)) NA else G(c(o$comp[!is.na(o$comp)], rep(0, k$k25))),
             if (sum(m) > 1) G(o$val[m]) - G(o$comp[m]) else NA, sum(m)),
           paste(dn, c("valuation owners", "compensation owners", "valuation + non-owners (30% rule)", "compensation + non-owners (30% rule)",
                       "valuation + non-owners (1825 shares)", "compensation + non-owners (1825 shares)", "matched owners: valuation minus compensation", "n matched"))) }))
pt_d <- sd_stat(OWN)
rep_sd <- function() sd_stat(lapply(OWN, function(o) o[sample.int(nrow(o), nrow(o), replace = TRUE), ]))
BD_ <- run_boot(B2, rep_sd, c("OWN", "DI", "sd_stat", "G"), environment(), seed = SEED)
for (j in seq_along(pt_d)) if (!grepl("n matched$", names(pt_d)[j])) { q <- pct_ci(BD_[, j])
  adds("S-d Fig 5 at owner level (owner bootstrap within district; non-owner counts fixed)", names(pt_d)[j], pt_d[j], q[1], q[2], "95% percentile", q[3]) }
nm <- names(pt_d)[grepl("matched owners", names(pt_d))]
vm <- sum(pt_d[nm] > 0, na.rm = TRUE); vs <- sum(apply(BD_[, nm, drop = FALSE], 2, function(v) pct_ci(v)[1] > 0), na.rm = TRUE)
adds("S-d Fig 5 at owner level (owner bootstrap within district; non-owner counts fixed)", "districts with matched valuation Gini > compensation Gini", vm,
     note = sprintf("of %d districts with matched owners; 95%% CI excludes 0 in %d", sum(is.finite(pt_d[nm])), vs))
# S-e
sw <- ad |> filter(district == "Swellendam")
CE <- list(GK = as.matrix(select(D$gk, horses, cattle_oxen, cattle_breeding, wheat_sown, wheat_reaped)),
           SR = as.matrix(select(D$sr, horses, cattle_oxen, cattle_breeding, wheat_sown, wheat_reaped)),
           SW = as.matrix(select(sw, horses, cattle_oxen, cattle_breeding, wheat_sown, wheat_reaped)))
se_stat <- function(CE) { m <- do.call(rbind, CE); k <- rbind(CE$GK, CE$SR)
  c(apply(m, 2, G), setNames(apply(k, 2, G), paste("Khoe only", colnames(k))), setNames(apply(CE$SW, 2, G), paste("Swellendam settlers only", colnames(k)))) }
pt_e <- se_stat(CE)
BE <- run_boot(B2, function() se_stat(lapply(CE, function(m) m[sample.int(nrow(m), nrow(m), replace = TRUE), , drop = FALSE])), c("CE", "se_stat", "G"), environment())
for (j in seq_along(pt_e)) { q <- pct_ci(BE[, j]); nmj <- names(pt_e)[j]
  adds("S-e Khoe (Groenekloof + Swartrivier) + Swellendam settlers combined, filter fixed", ifelse(grepl("only", nmj), nmj, paste("combined", nmj)), pt_e[j], q[1], q[2],
       sprintf("95%% percentile, iid households stratified by group; n = %d Khoe + %d settlers", nrow(CE$GK) + nrow(CE$SR), nrow(CE$SW)), q[3]) }
# S-f
yearlike <- function(v, y) ifelse(!is.na(v) & v >= 1690 & v <= 1845 & abs(v - y) <= 15, NA, v)
pb <- D$probates
pb2 <- pb |> mutate(across(c(horse_nr, wagon_nr), ~ yearlike(.x, year)))   # the eight values named in S5-15 (DEVIATIONS D5)
n_set <- sum(sapply(c("horse_nr", "cattle_nr", "sheep_nr", "plough_nr", "wagon_nr"), function(v) sum(is.na(pb2[[v]]) & !is.na(pb[[v]]))))
stopifnot(n_set == 8)
PB <- split(as.data.frame(pb2[, c("horse_nr", "cattle_nr", "sheep_nr", "plough_nr", "wagon_nr")]), pb2$period)
sf_stat <- function(PB) { g <- sapply(PB, function(x) apply(x, 2, G)); per <- as.numeric(colnames(g))
  c(setNames(as.vector(g), paste(rep(colnames(g), each = nrow(g)), sub("_nr", "", rownames(g)))), `min all` = min(g), `min from 1770` = min(g[, per >= 1770])) }
pt_f <- sf_stat(PB)
BF <- run_boot(B2, function() sf_stat(lapply(PB, function(x) x[sample.int(nrow(x), nrow(x), replace = TRUE), , drop = FALSE])), c("PB", "sf_stat", "G"), environment())
for (j in seq_along(pt_f)) { q <- pct_ci(BF[, j])
  adds("S-f probate Ginis (legend corrected; 8 date-like counts set to NA)", names(pt_f)[j], pt_f[j], q[1], q[2], "95% percentile, iid probates within decade", q[3]) }

## ---- write sensitivities.csv ----------------------------------------------------------------------------------
s3 <- readRDS(file.path(SCR, "secondary_central.rds"))
fac <- readRDS(file.path(SCR, "factorial_5A.rds"))
s5a <- bind_rows(lapply(seq_len(nrow(fac)), function(i) bind_rows(
  tibble(section = "5A price factorial (V3 x V4; points; assumption-conditional, equal weights are not probabilities)", quantity = paste(fac$scenario[i], "H1 min decade"),
         estimate = fac$H1_min[i], note = sprintf("max %.3f; all > 0.60: %s", fac$H1_max[i], fac$H1_all_above_060[i])),
  tibble(section = "5A price factorial (V3 x V4; points; assumption-conditional, equal weights are not probabilities)", quantity = paste(fac$scenario[i], "H2 1780"),
         estimate = fac$H2_1780[i], note = sprintf("in [0.89, 0.95]: %s", fac$H2_in_band[i])))))
sens <- bind_rows(s5a, bind_rows(sec), s3) |> mutate(across(c(estimate, L, U), ~ round(.x, 4)))
write_csv(sens, file.path(OUT, "sensitivities.csv"))
cat("sensitivities rows:", nrow(sens), "\n")
print(as.data.frame(sens |> filter(!grepl("^S-[adf]|5C.3|5C.2 influence:|missingness", section)) |> select(section, quantity, estimate, L, U)), right = FALSE)
