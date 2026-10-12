# P16_FvFC S6 -- 01_central.R: prechecks (card §4 a-c), §0 classification, cluster report,
# central point estimates and the per-year description. No interval is computed here.
# Inputs : households.rds (S3), raw workbook, repro_r/results_r.csv, compare/s5_checks/zero_index_scenarios_by_year.csv
# Outputs: output/precheck.csv, output/classification.csv, output/cluster_report*.csv,
#          output/central_series.csv, output/per_year_static.csv; D: scratch hh_central.rds

source(here::here("P16_FvFC", "modern", "00_common.R"))

hh  <- readRDS(HHF)
raw <- read_raw()

# ---- check 0: the raw rebuild in 00_common equals the S3 household file -------------------------
hb <- build_hh(raw)
cols <- c("year", "farmer", "hhsize", "hhsize_k", "slaves", "DS", "WED", CORE1)
stopifnot(nrow(hb) == nrow(hh), all(sapply(cols, \(v) isTRUE(all.equal(hb[[v]], hh[[v]], check.attributes = FALSE)))),
          identical(hb$Van, hh$Van), identical(hb$Naam, hh$Naam))

hh$key   <- key_coarse(hh$Van, hh$Naam)
hh$key_x <- key_exact(hh$Van, hh$Naam)
P <- prep(hh)

# ---- central and original analyses ------------------------------------------------------------
e  <- evaluate(P, opts = list(extras = TRUE))
stopifnot(is.na(e$fail_far), is.na(e$fail_all))
cen  <- rows_from(e$G, e$gE, e$gI)
orig <- rows_from(e$G_drop0, e$gE, e$gI)            # original = ineqdeco zero rule in the farmer Ginis; Fig 4 keeps zeros

# cross-check the vectorised Gini against the S3 gini_w (explicit slave expansion) for every year
far <- hh |> filter(farmer); pf <- pca_fit(as.matrix(far[, CORE1])); If <- score_shift(as.matrix(far[, CORE1]), pf)
pa <- pca_fit(as.matrix(hh[, CORE1])); Ia <- score_shift(as.matrix(hh[, CORE1]), pa)
ref <- sapply(YEARS, \(y) { k <- far$year == y; j <- hh$year == y; ns <- sum(hh$slaves[j])
  c(G = gini_w(If[k] / far$hhsize[k], far$hhsize[k]),
    gE = gini_w(Ia[j] / hh$hhsize[j], hh$hhsize[j]),
    gI = gini_w(c(Ia[j] / hh$hhsize[j], rep(0, ns)), c(hh$hhsize[j], rep(1, ns)))) })
stopifnot(max(abs(ref["G", ] - e$G)) < 1e-12, max(abs(ref["gE", ] - e$gE)) < 1e-12, max(abs(ref["gI", ] - e$gI)) < 1e-12)

# ---- precheck (a), (b): stored S3/S5 values at full precision, tolerance 1e-9 -------------------
rr <- read.csv(here::here("P16_FvFC", "repro_r", "results_r.csv"), colClasses = c(value = "character"))
sv <- \(id) as.numeric(rr$value[rr$claim_id == id])
zs <- read.csv(here::here("P16_FvFC", "compare", "s5_checks", "zero_index_scenarios_by_year.csv"), colClasses = c(gini = "character"))
z63 <- as.numeric(zs$gini[zs$year == 1663 & zs$pca_sample == "all farmers" & zs$drop_zero_in_gini == "TRUE"])
pre <- tibble(check = c("a: G1663 vs F5c_1663", "a: G1709 vs text_p26_gini_1709", "a: G1757 vs text_p26_gini_1757",
                        "a: m vs text_p23_slave_gap", "b: original G1663 vs S5 zero-index scenario"),
              computed = c(cen["G1663"], cen["G1709"], cen["G1757"], cen["m"], orig["G1663"]),
              stored = c(sv("F5c_1663"), sv("text_p26_gini_1709"), sv("text_p26_gini_1757"), sv("text_p23_slave_gap"), z63)) |>
  mutate(abs_diff = abs(computed - stored), pass = abs_diff < 1e-9)
write_csv(pre, file.path(OUT, "precheck.csv"))
print(pre, width = 200)
stopifnot(all(pre$pass))

# ---- precheck (c): §0 classification -----------------------------------------------------------
rowq <- list(H1 = "G1663", `H2-pt` = "G1709", `H3-pt` = "G1757", `H2-rise` = paste0("d_", INIT),
             `H3-rise` = "d", H4 = "m", `H4-w` = "s")
card_class <- c(H1 = "corrected", `H2-pt` = "unchanged", `H3-pt` = "unchanged", `H2-rise` = "corrected",
                `H3-rise` = "unchanged", H4 = "unchanged", `H4-w` = "unchanged")
cls <- imap_dfr(rowq, \(q, nm) tibble(row = nm, max_abs_diff = max(abs(cen[q] - orig[q])),
                                      class = ifelse(max_abs_diff < 1e-6, "unchanged", "corrected"), card = card_class[nm]))
# per-year zero-rule movers (card: 1663, 1678, 1685, 1688, 1692, 1695, 1719, 1741)
movers <- YEARS[abs(e$G - e$G_drop0) >= 1e-6]
cls <- cls |> mutate(pass = class == card, movers = paste(movers, collapse = " "))
write_csv(cls, file.path(OUT, "classification.csv"))
print(cls)
stopifnot(all(cls$pass), identical(as.numeric(movers), c(1663, 1678, 1685, 1688, 1692, 1695, 1719, 1741)))

# ---- verification: the original analysis against the published Fig 5c series --------------------
cl <- read_csv(here::here("P16_FvFC", "claims", "claims.csv"), show_col_types = FALSE)
pubv <- cl$reported_value[match(paste0("F5c_", YEARS), cl$claim_id)]
ver <- tibble(year = YEARS, published = pubv, original = e$G_drop0, central = e$G) |>
  mutate(diff_orig = original - published, diff_central = central - published)
write_csv(ver, file.path(OUT, "verify_original_vs_published.csv"))
cat(sprintf("Original vs published Fig 5c: mean |diff| %.4f, max %.4f, within 0.005: %d/20; 1663 %.4f vs %.3f\n",
            mean(abs(ver$diff_orig)), max(abs(ver$diff_orig)), sum(abs(ver$diff_orig) <= 0.005), ver$original[1], ver$published[1]))

# ---- cluster report (reported before any interval) ----------------------------------------------
crep <- function(k, label) {
  d <- hh |> mutate(k = k)
  cs <- d |> group_by(k) |> summarise(rows = n(), years = n_distinct(year), .groups = "drop")
  touch <- \(yy) n_distinct(d$k[d$year %in% yy])
  tibble(key = label, clusters = nrow(cs), rows_mean = mean(cs$rows), rows_median = median(cs$rows),
         rows_p90 = unname(quantile(cs$rows, 0.9)), rows_max = max(cs$rows),
         years_mean = mean(cs$years), years_median = median(cs$years), years_p90 = unname(quantile(cs$years, 0.9)),
         years_max = max(cs$years), share_rows_singleton = mean(d$k %in% cs$k[cs$rows == 1]),
         clusters_1663 = touch(1663), clusters_initial = touch(INIT), clusters_1709 = touch(1709),
         clusters_1738 = touch(1738), clusters_1757 = touch(1757))
}
cr <- bind_rows(crep(hh$key, "coarse (central)"), crep(hh$key_x, "exact (5A item 2)"))
write_csv(cr, file.path(OUT, "cluster_report.csv"))
other_year <- hh |> distinct(key, year) |> count(key, name = "n_years")
cr_y <- hh |> left_join(other_year, by = "key") |> group_by(year) |>
  summarise(rows = n(), keys_with_2plus_rows = sum(table(key) >= 2),
            share_rows_key_in_other_year = mean(n_years >= 2), .groups = "drop")
write_csv(cr_y, file.path(OUT, "cluster_report_by_year.csv"))
nonwed_keys <- unique(hh$key[hh$WED == 0])
wed <- hh |> filter(WED == 1) |>
  mutate(type = case_when(grepl("\\|weduwee$", key) ~ "surname|weduwee (name-only widow)",
                          key %in% nonwed_keys ~ "shares key with a WED = 0 record (husband's key)",
                          TRUE ~ "key not shared with any WED = 0 record (own given name or unlinked)")) |>
  count(type)
write_csv(wed, file.path(OUT, "cluster_report_widows.csv"))
print(cr, width = 250); print(wed)

# ---- per-year description (static part; replicate sample sizes are added by 02) ------------------
dsc <- hh |> mutate(DS = paste0("DS", DS)) |> count(year, DS) |> group_by(year) |>
  summarise(districts = paste0(DS, ":", n, collapse = " "), .groups = "drop")
py <- tibble(year = YEARS, households = e$ns, farmers = e$nf, slaves_added = tabulate_w(P$g, P$sl, 20),
             persons_settler = tabulate_w(P$g, P$hh, 20), zero_index_farmers = e$n0,
             G_central = e$G, G_original = e$G_drop0, gini_excl = e$gE, gini_incl = e$gI, gap = e$gI - e$gE) |>
  left_join(dsc, by = "year")
write_csv(py, file.path(OUT, "per_year_static.csv"))
write_csv(tibble(quantity = names(cen), central = cen, original = orig), file.path(OUT, "central_series.csv"))
saveRDS(list(hh = hh, e = e, cen = cen, orig = orig), file.path(SCR, "central.rds"))
print(round(cen, 4))
