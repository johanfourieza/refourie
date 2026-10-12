# P30_STB24 S5 check 3: (a) decomposes pair-B gaps for Fig 5/6 anchors using the 01 scenarios;
# (b) audits the Fig 3 surname parser (l.692-700) for name-format dependence; (c) per-census row counts, original vs S3.
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(stringr); library(purrr)})
source("tools/paths.R")
o <- "P30_STB24/compare/s5_checks/output"
cmp <- read_csv("P30_STB24/compare/comparison_ABC.csv", show_col_types = FALSE)
interp <- function(d, v, y) { d <- d[is.finite(d[[v]]), ]; if (y %in% d$year) d[[v]][d$year == y] else approx(d$year, d[[v]], y)$y }
amap <- c(horses = "horses", cattle = "cattle", sheep = "sheep", wheat = "wheat_vol", barley = "barley_vol", wine = "wine")
scen <- c("S0_baseline_as_run", "S1_types_fixed", "S2_types_fixed_base1795", "S5_all_fixes_base1795")
anch <- cmp |> filter(pair == "B", str_detect(claim_id, "^F[56]_") , !str_detect(claim_id, "nobs")) |>
  mutate(fig = substr(claim_id, 1, 2), asset = str_match(claim_id, "^F[56]_([a-z]+)_")[, 2], year = as.numeric(str_extract(claim_id, "[0-9]{4}$")))
for (s in scen) {
  i5 <- read_csv(file.path(o, paste0("fig5_index_", s, ".csv")), show_col_types = FALSE)
  g6 <- read_csv(file.path(o, paste0("fig6_gini_", s, ".csv")), show_col_types = FALSE)
  anch[[s]] <- pmap_dbl(anch, function(fig, asset, year, ...) interp(if (fig == "F5") i5 else g6, amap[[asset]], year))
}
anch <- anch |> select(claim_id, published = ref, pairB = rep, all_of(scen)) |> mutate(across(where(is.numeric), ~ signif(., 3)))
write_csv(anch, file.path(o, "pairB_anchor_decomposition.csv")); print(as.data.frame(anch))

# (b) surname parser
guess <- readRDS(dscratch("P30_STB24", "compare", "reads.rds"))$guess
nm <- guess |> transmute(year = as.numeric(year), names_men) |> filter(!is.na(names_men), year >= 1700, year <= 1830) |>
  mutate(comma = str_detect(names_men, ","), surname = if_else(comma, str_trim(str_extract(names_men, "^[^,]+")), str_trim(word(names_men, -1))),
         dec = floor(year / 10) * 10, dv_any = str_detect(str_to_lower(names_men), "villiers"))
top12 <- c("De Villiers", "Du Plessis", "Du Toit", "Joubert", "Le Roux", "Louw", "Marais", "Rossouw", "Roux", "Smit", "Swart", "Van der Merwe")
fs <- nm |> group_by(dec) |> summarise(rows = n(), share_comma = mean(comma), n_top12 = sum(surname %in% top12),
  dv_parsed = sum(surname == "De Villiers"), dv_anyform = sum(dv_any), dv_lastword_villiers = sum(!comma & surname == "Villiers"),
  share_dv_parsed_top12 = 100 * dv_parsed / n_top12, share_dv_anyform_all = 100 * dv_anyform / rows)
write_csv(fs, file.path(o, "fig3_parser_audit.csv")); print(as.data.frame(fs |> mutate(across(where(is.double), ~ round(., 2)))))

# (c) per-census rows: original analysis file vs S3 rebuild
oc <- guess |> count(year = as.numeric(year), name = "n_original")
rc <- read_csv("P30_STB24/repro_r/output/per_census_counts.csv", show_col_types = FALSE)
print(names(rc))
rows <- full_join(oc, rc |> select(year, n_rows_S3 = n_rows), by = "year") |> mutate(diff = n_rows_S3 - n_original)
write_csv(rows, file.path(o, "rows_by_census_original_vs_S3.csv"))
cat("total diff:", sum(rows$diff, na.rm = TRUE), "; censuses differing:", sum(rows$diff != 0, na.rm = TRUE), "; years in one only:", paste(rows$year[is.na(rows$diff)], collapse = " "), "\n")
print(as.data.frame(rows |> filter(diff != 0 | is.na(diff)) |> arrange(desc(abs(diff)))), max = 200)
