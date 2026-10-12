# P11_FJS S6 04: the admissible sensitivities of card §5A (items 1-18), point values on the full data.
# None of them votes (§8). Output: output/sensitivities.csv (long: item, variant, quantity, value, note)
source("./P11_FJS/modern/00_common.R")
base <- load_base()
hh   <- readRDS(file.path(SCR, "households.rds"))            # primary taxes + xtile groups (01_tax.R)
res  <- list()
add  <- function(item, variant, quantity, value, note = "") res[[length(res) + 1]] <<- tibble(item, variant, quantity, value, note)
add3 <- function(item, variant, s00, s73, note = "") {
  add(item, variant, "S00", s00, note); add(item, variant, "S73", s73, note); add(item, variant, "Delta", s73 - s00, note) }
by_year <- function(d, f, years = c(1700, 1773)) sapply(years, function(y) { x <- d[d$jaar == y, ]; x <- x[order(x$rid), ]; f(x) })
prim_share <- function(d) by_year(d, function(x) share_top(x$tslaves, x$tax))
p <- prim_share(hh); add3("0", "primary (card §3)", p[1], p[2])

# ---- share definition ----
pub <- tax_off_float(base) |> mutate(dec = hh$dec_xtile)
v <- by_year(pub, function(x) share_wb(x$dec, x$tax)); add3("1", "published construction: run A1 taxes, workbook mean-of-means share", v[1], v[2], "diagnostic; reproduces Image 9")
v <- by_year(hh, function(x) share_xtile(x$dec_xtile, x$tax)); add3("2", "Stata xtile group 10, exact sums", v[1], v[2],
  paste("group-10 sizes:", paste(by_year(hh, function(x) sum(x$dec_xtile == 10)), collapse = " / ")))
v <- by_year(hh, function(x) { c <- attr(top_w(x$tslaves), "c"); 100 * sum(x$tax[x$tslaves >= c]) / sum(x$tax) })
add3("3", "ties kept together (tslaves >= c)", v[1], v[2],
  paste("group sizes:", paste(by_year(hh, function(x) sum(x$tslaves >= attr(top_w(x$tslaves), "c"))), collapse = " / ")))
v <- by_year(hh, function(x) share_taxbreak(x$tslaves, x$tax, x$rid, desc = TRUE));  add3("4a", "ties at c broken by tax, descending", v[1], v[2])
v <- by_year(hh, function(x) share_taxbreak(x$tslaves, x$tax, x$rid, desc = FALSE)); add3("4b", "ties at c broken by tax, ascending", v[1], v[2])
v <- prim_share(tax_off(base)); add3("5", "all tax corrections off (run A1 taxes), primary share rule", v[1], v[2])

# ---- tax construction ----
v <- prim_share(make_tax(base, post_factor = 0.7)); add3("6", "0.7 wine factor after 1743 restored", v[1], v[2])
v <- prim_share(make_tax(base, grain = "net"));     add3("7", "grain net of seed (floored at 0)", v[1], v[2])
rec <- base$wingst > 0 & base$wyn == 0; don <- base$wingst > 0 & base$wyn > 0; ratio <- base$wyn / base$wingst
r_mean_y <- tapply(ratio[don], base$jaar[don], mean); r_med_y <- tapply(ratio[don], base$jaar[don], median)
r_pool <- mean(ratio[don])
nrec <- by_year(base |> mutate(r = rec), function(x) sum(x$r))
imp_note <- sprintf("recipients 1700/1773: %d / %d", nrec[1], nrec[2])
v <- prim_share(make_tax(base, imp_ratio = 0.0008813)); add3("8a", "vine imputation, coded constant 0.0008813", v[1], v[2], imp_note)
v <- prim_share(make_tax(base, imp_ratio = unname(r_mean_y[as.character(base$jaar)])))
add3("8b", "vine imputation, within-year donor mean of wyn/wingst", v[1], v[2], sprintf("%s; r(1700) = %.6f", imp_note, r_mean_y["1700"]))
v <- prim_share(make_tax(base, imp_ratio = unname(r_med_y[as.character(base$jaar)])))
add3("8c", "vine imputation, within-year donor median of wyn/wingst", v[1], v[2], sprintf("%s; r(1700) = %.6f", imp_note, r_med_y["1700"]))
v <- prim_share(make_tax(base, imp_ratio = r_pool)); add3("8d", "vine imputation, donor mean pooled over retained years", v[1], v[2], sprintf("%s; r = %.6f", imp_note, r_pool))
v <- prim_share(make_tax(base, wine_pre = 72)); add3("9", "72 st per leaguer before 1743 (run 0)", v[1], v[2])
v <- prim_share(make_tax(base, poll_swell = 36)); add3("10", "Swellendam (ds == 4) poll tax 36 st", v[1], v[2])
hb <- lapply(c(1700, 1773), function(y) { x <- make_tax(base) |> filter(jaar == y) |> arrange(rid); hearth_bounds(x) })
add("11a", "hearth allocation, upper bound S^max", "S00", hb[[1]]["max"], sprintf("|U| = %d", hb[[1]]["nU"]))
add("11a", "hearth allocation, upper bound S^max", "S73", hb[[2]]["max"], sprintf("|U| = %d", hb[[2]]["nU"]))
add("11b", "hearth allocation, lower bound S^min", "S00", hb[[1]]["min"]); add("11b", "hearth allocation, lower bound S^min", "S73", hb[[2]]["min"])
add("11ab", "bounds on Delta [S73min - S00max, S73max - S00min]", "Delta_lo", hb[[2]]["min"] - hb[[1]]["max"])
add("11ab", "bounds on Delta [S73min - S00max, S73max - S00min]", "Delta_hi", hb[[2]]["max"] - hb[[1]]["min"])
v <- prim_share(make_tax(base, hearth = "none")); add3("11c", "no record pays the hearth tax", v[1], v[2])
v <- prim_share(make_tax(base, hearth = "dsna")); add3("11d", "records with missing ds also pay the hearth tax", v[1], v[2])
v <- prim_share(make_tax(base, pigs_asset = TRUE)); add3("12", "pigs (vk) counted as agricultural assets", v[1], v[2])

# ---- population (A4d) ----
orig_cols <- setdiff(names(base), "rid")
dedup <- base[!duplicated(base[, orig_cols]), ]
v <- prim_share(make_tax(dedup)); add3("13", "full-row duplicates dropped (within year)", v[1], v[2],
  sprintf("excess duplicates removed: %d (1700: %d, 1773: %d)", nrow(base) - nrow(dedup),
          sum(base$jaar == 1700) - sum(dedup$jaar == 1700), sum(base$jaar == 1773) - sum(dedup$jaar == 1773)))
add("14", "complete cases", "S00", NA, "not computed: the §4 missing-input rule is not triggered (check_missing.csv)")

# ---- coverage and influence ----
s7 <- by_year(hh, function(x) share_top(x$tslaves, x$tax), IMG9)
for (i in seq_along(IMG9)) add("15", "primary rule, all Image 9 years", paste0("S_", IMG9[i]), s7[i])
add("15", "primary rule, all Image 9 years", "years with S_t > 50", sum(s7 > 50))
add("15", "primary rule, all Image 9 years", "year-on-year increases (of 6)", sum(diff(s7) > 0))
loo <- lapply(c(1700, 1773), function(y) { x <- hh |> filter(jaar == y) |> arrange(rid)
  vapply(seq_len(nrow(x)), function(i) share_top(x$tslaves[-i], x$tax[-i]), 0) })
add("16", "leave-one-record-out", "max |dS00|", max(abs(loo[[1]] - p[1])))
add("16", "leave-one-record-out", "max |dS73|", max(abs(loo[[2]] - p[2])))
add("16", "leave-one-record-out", "min S00 / max S00", NA, sprintf("%.4f / %.4f", min(loo[[1]]), max(loo[[1]])))
add("16", "leave-one-record-out", "min S73 / max S73", NA, sprintf("%.4f / %.4f", min(loo[[2]]), max(loo[[2]])))
add("16", "leave-one-record-out", "deletions moving S00 to >= 50", sum(loo[[1]] >= 50))
add("16", "leave-one-record-out", "deletions moving S73 to <= 61", sum(loo[[2]] <= 61))
add("16", "leave-one-record-out", "min Delta over single deletions", min(c(p[2] - loo[[1]], loo[[2]] - p[1])))

# ---- H2 ----
claims <- read_csv(file.path(ROOT, P, "claims", "claims.csv"), show_col_types = FALSE)
pv <- function(id) { v <- claims$reported_value[claims$claim_id == id]; if (length(v) == 1) as.numeric(v) else NA_real_ }
for (y in c(1777, 1787, 1789, 1792, 1794)) {
  dp <- pv(sprintf("I6_%d_def", y)); dc <- pv(sprintf("I6_%d_exp", y)) - pv(sprintf("I6_%d_rev", y))
  add("17", "printed Deficit column", paste0("D_", y), dp, sprintf("equals Exp - Rev: %s", isTRUE(all.equal(dp, dc))))
}
gdp15 <- function(f) { x <- readRDS(dpath("P15_FvZ", "repro_original", f)) |> filter(sheet == "total economy", col == 5)
  function(y) { v <- x$recalc[x$row == y - 1698]; if (length(v) == 1 && is.finite(v)) 1000 * v else NA_real_ } }
for (vv in list(c("18a", "recalc_cells_primary.rds"), c("18b", "recalc_cells_copy.rds"))) {
  g <- gdp15(vv[2]); G89 <- g(1789)
  add(vv[1], paste("GDP-vintage substitution:", vv[2], "total economy!E x 1000"), "R89", if (is.na(G89)) NA else 100 * 1403000 / G89,
      if (is.na(G89)) "absent" else sprintf("GDP_1789 = %.0f; currency, price basis and coverage of col. E not shown to match the printed GDP", G89))
  for (y in c(1777, 1787, 1789, 1791, 1792)) add(vv[1], "P15 / printed GDP", paste0("ratio_", y), g(y) / pv(sprintf("I6_%d_gdp", y)))
}

out <- bind_rows(res)
write_csv(out, file.path(OUT, "sensitivities.csv"), na = "")
print(as.data.frame(out |> mutate(value = round(value, 4))), right = FALSE)
