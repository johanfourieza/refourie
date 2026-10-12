# Builds results_original.csv for P30_STB24 from the aggregates exported by run_original.R (output/*.csv).
# Usage (from project root): Rscript P30_STB24/repro_original/extract_results.R
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr)})
od <- "P30_STB24/repro_original/output"
rd <- function(f) read_csv(file.path(od, f), show_col_types = FALSE)
facts <- rd("facts.csv"); fv <- function(i) as.numeric(facts$value[facts$item == i])
f3 <- rd("fig3_top_surname_data.csv"); f4 <- rd("fig4_surname_connections.csv")
f5 <- rd("fig5_indexed_long.csv"); f6 <- rd("fig6_gini_values.csv"); f2 <- rd("fig2_completeness.csv")
claims <- read_csv("P30_STB24/claims/claims.csv", show_col_types = FALSE, col_types = cols(.default = "c"))

# Value of the plotted line at year y. Gap years (no census) are read off the segment ggplot draws between the
# neighbouring census years: linear in log10 for Fig 5 (scale_y_log10), linear for Fig 6.
at <- function(y, yrs, vals, logy = FALSE) {
  ok <- !is.na(vals); yrs <- yrs[ok]; vals <- vals[ok]
  if (y %in% yrs) return(list(v = vals[yrs == y], gap = ""))
  lo <- max(yrs[yrs < y]); hi <- min(yrs[yrs > y])
  f <- function(x) if (logy) log10(x) else x
  v <- approx(c(lo, hi), f(c(vals[yrs == lo], vals[yrs == hi])), xout = y)$y
  list(v = if (logy) 10^v else v, gap = sprintf("; no census in %d: value read off the plotted segment %d-%d%s", y, lo, hi, if (logy) " (log-linear)" else ""))
}
RUN <- "StellenboschScript.R run with env patches E1-E3 (run_original.R; line-52 typo kept, lines 57-64 error as in the authors' session)"
out <- list()
add <- function(id, value, n = NA, status = "", note = "", cause = "") {
  out[[length(out) + 1]] <<- tibble(claim_id = id, source = "original", value = value, se = NA_real_, n = n,
                                    status_override = status, note = paste(RUN, note, sep = "; "), cause = cause)
}

# Text counts
add("TX_rows", fv("rows_opgaaf"), note = "nrow(stellenbosch_clean.xlsx)")
add("TX_censuses", fv("unique_years"), note = "n_distinct(year) printed at script l.214-218; the data hold 143 census years (1685-1844 minus 17 gap years)", cause = "unresolved")
add("TX_volumes", NA, status = "unavailable", note = "volume identifiers are not in the analysis file or code")
add("TX_vars", fv("cols_opgaaf"), note = "ncol of the analysis file = 172, incl. nr, year, add_info, district, field_cornet, names_*; the 168 in the text cannot be matched to a defined subset", cause = "data-vintage")
add("TX_cols50", NA, status = "unavailable", note = "refers to the columns of the archival forms, not computed by code")
add("TX_fn31_drop20", fv("heatmap_vars_dropped"), note = "script l.293 drops the 100 least complete of 172 columns (72 plotted); fn 31 says twenty", cause = "code-bug")
add("TX_top12", ncol(f3) - 2, note = "top_n(12) at l.712-715; no ties")
add("TX_pairs100", nrow(f4), note = "head(100) at l.847")
add("TX_years159", fv("year_max") - fv("year_min"), note = "max(year)-min(year)")

# Gini range (Fig 6): six assets x years
gl <- f6 |> pivot_longer(-year, names_to = "asset", values_to = "gini") |> filter(!is.na(gini))
sh <- mean(gl$gini >= 0.4)
add("TX_gini_lo", min(gl$gini), n = nrow(gl),
    note = sprintf("minimum annual Gini across six assets and all years (%s %d); %.1f%% of %d asset-years lie in [0.4,1]; 'for most of the period' admits several operationalisations",
                   gl$asset[which.min(gl$gini)], gl$year[which.min(gl$gini)], 100 * sh, nrow(gl)))
add("TX_gini_hi", max(gl$gini), n = nrow(gl), note = sprintf("maximum annual Gini (%s %d)", gl$asset[which.max(gl$gini)], gl$year[which.max(gl$gini)]))
wd <- f6 |> filter(!is.na(wine)) |> mutate(decade = year %/% 10 * 10) |> group_by(decade) |> summarise(g = mean(wine))
add("TX_wineGini_peak", wd$decade[which.max(wd$g)],
    note = "decade with highest mean annual wine Gini; NB the script's wine variable is logical (read_excel type guess), so this 'Gini' is ~1 minus the share of households reporting wine")
for (id in c("TX_shift_lo", "TX_shift_hi", "TX_break1804", "TX_frag1830", "TX_DV_rise", "TX_const1750", "TX_var3dec"))
  add(id, NA, status = "unavailable", note = "visual reading of a figure; no quantity defined in the code (figure itself reproduces)")
for (id in c("TX_fourie_1700", "TX_fourie_17", "TX_fourie_1718", "TX_fourie_1750"))
  add(id, NA, status = "unavailable", note = "Louis Fourie spelling history is not computed by the code")

# Fig 3: share of each surname within the top-12 total, by decade
nm <- c(DeVilliers = "De Villiers", Swart = "Swart", Smit = "Smit", Joubert = "Joubert", Marais = "Marais", Louw = "Louw",
        Roux = "Roux", VanderMerwe = "Van der Merwe", DuToit = "Du Toit", DuPlessis = "Du Plessis", LeRoux = "Le Roux", Rossouw = "Rossouw")
for (id in claims$claim_id[grepl("^F3_", claims$claim_id)]) {
  p <- strsplit(id, "_")[[1]]; s <- nm[[p[2]]]; dec <- as.numeric(p[3])
  add(id, f3[[s]][f3$decade == dec], note = "top_surname_data (l.727-735): percent of the top-12 total, not of all surnames")
}
# Fig 5: observations per census and index (script base_year = 1780, l.526, though the axis says 1795)
cnt <- f5 |> distinct(year, count)
for (id in claims$claim_id[grepl("^F5_nobs_", claims$claim_id)]) {
  y <- as.numeric(sub("F5_nobs_", "", id)); add(id, cnt$count[cnt$year == y], note = "obs_per_year (l.521-523), digitised claim")
}
vmap <- c(cattle = "cattle", horses = "horses", sheep = "sheep", wheat = "wheat_vol", barley = "barley_vol", wine = "wine")
for (id in claims$claim_id[grepl("^F5_", claims$claim_id) & !grepl("nobs", claims$claim_id)]) {
  p <- strsplit(id, "_")[[1]]; v <- vmap[[p[2]]]; y <- as.numeric(p[3])
  fv5 <- f5 |> filter(variable == v); a <- at(y, fv5$year, fv5$value, logy = TRUE)
  add(id, a$v, note = paste0("index_", v, " (l.540); base year in code is 1780, not 1795", a$gap,
                             if (v == "wine") "; wine is logical in the script, so this indexes the share of households reporting wine" else ""))
}
# Fig 6
for (id in claims$claim_id[grepl("^F6_", claims$claim_id)]) {
  p <- strsplit(id, "_")[[1]]; v <- vmap[[p[2]]]; y <- as.numeric(p[3])
  a <- at(y, f6$year, f6[[v]])
  add(id, a$v, note = paste0("gini_values (l.631-633)", a$gap, if (v == "wine") "; wine is logical, so Gini ~ 1 - share reporting wine" else ""))
}

res <- bind_rows(out)
stopifnot(setequal(res$claim_id, claims$claim_id), !anyDuplicated(res$claim_id))
res <- res[match(claims$claim_id, res$claim_id), ]
write_csv(res, "P30_STB24/repro_original/results_original.csv", na = "")
cat("Wrote", nrow(res), "rows;", sum(res$status_override == ""), "with values\n")

# Cause for non-exact pair-A rows (run after tools/run_compare.R). The regenerated Figs 3, 5 and 6 are identical to the
# published files (output/, pixel comparison in audit.md), so figure-claim gaps are S0 digitisation error; the protocol's
# closest cause label is rounding-or-transcription-in-paper.
cf <- "P30_STB24/compare/comparison_ABC.csv"
if (file.exists(cf)) {
  ne <- read_csv(cf, show_col_types = FALSE, col_types = cols(.default = "c")) |> filter(pair == "A", status %in% c("close", "differs"))
  fig <- res$claim_id %in% ne$claim_id & grepl("^F[356]_", res$claim_id)
  res$cause[fig] <- "rounding-or-transcription-in-paper"
  res$note[fig] <- paste0(res$note[fig], "; gap is S0 digitisation (figure reproduces identically; neighbouring census years bracket the digitised value)")
  res$cause[res$claim_id == "TX_gini_lo"] <- "rounding-or-transcription-in-paper"
  write_csv(res, "P30_STB24/repro_original/results_original.csv", na = "")
  cat("Causes filled for", sum(fig) + 1, "rows\n")
}
