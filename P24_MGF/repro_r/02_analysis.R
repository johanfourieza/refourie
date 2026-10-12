# P24_MGF S3 rebuild, step 2: Figure 1 sex ratios with exact binomial CIs, Table 5
# (Kimberley sex ratios at death, ages 0-4, by age band and race), the text claims that
# follow from them, and results_r.csv for every claim_id.
# Inputs: output/supp_population_transcribed.csv (from 01_clean.R) and the row-level
# Kimberley file on D: (personal data; only aggregates are written here).
suppressMessages({library(tidyverse); library(here)})
P <- "P24_MGF"
source(here::here("tools", "paths.R"))
out <- here::here(P, "repro_r", "output")
set.seed(20221)   # nothing stochastic below; set for the record

supp   <- read_csv(file.path(out, "supp_population_transcribed.csv"), show_col_types = FALSE)
kim    <- readRDS(dpath(P, "repro_r", "kimberley_clean.rds"))
claims <- read_csv(here::here(P, "claims", "claims.csv"), show_col_types = FALSE)

# Sex ratio 100*M/F with an exact (Clopper-Pearson) CI on p = M/(M+F), mapped to
# SR = 100 p/(1-p). se: delta method on log SR (Poisson counts).
sr_ci <- function(m, f) {
  ci <- binom.test(m, m + f)$conf.int
  tibble(sr = 100 * m / f, lo = 100 * ci[1] / (1 - ci[1]), hi = 100 * ci[2] / (1 - ci[2]),
         se = 100 * m / f * sqrt(1 / m + 1 / f), n = m + f)
}

## Figure 1 -------------------------------------------------------------------
fig1 <- supp |> mutate(r = map2(males, females, sr_ci)) |> unnest(r) |>
  mutate(sr_diff_vs_printed = round(sr, 2) - sr_printed)
write_csv(fig1, file.path(out, "fig1_sex_ratios_exactCI.csv"))
pal <- c(black = "#1B3A5C", coloured = "#C8102E", white = "#8C8C8C")
g <- ggplot(fig1, aes(year, sr, colour = race)) +
  geom_hline(yintercept = 100, linewidth = 0.3, colour = "grey60") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 1.2) + geom_line() + geom_point(size = 1.4) +
  scale_colour_manual(values = pal, labels = c("Black children", "Coloured children", "White children")) +
  labs(x = NULL, y = "Boys per 100 girls, ages 0-4", colour = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank())
ggsave(file.path(out, "fig1_rebuild.pdf"), g, width = 6.5, height = 4)
ggsave(file.path(out, "fig1_rebuild.png"), g, width = 6.5, height = 4, dpi = 300)

## Table 5 --------------------------------------------------------------------
band_main <- function(a) cut(a, c(0, 6, 18, 60), right = FALSE, labels = c("0-5months", "6months-1p5years", "1p5-4years"))
band_alt  <- function(a) cut(a, c(-Inf, 6, 18, 60), right = TRUE, labels = c("0-5months", "6months-1p5years", "1p5-4years"))
kids <- kim |> filter(!is.na(sex), race %in% c("black", "coloured", "white"), !is.na(age_m), age_m < 60)

tab5 <- function(d, band_fun, label) {
  d <- d |> mutate(band = band_fun(age_m)) |> filter(!is.na(band))
  bind_rows(d |> mutate(band = "0-4years"), d |> mutate(band = as.character(band))) |>
    count(race, band, sex) |> pivot_wider(names_from = sex, values_from = n, values_fill = 0) |>
    mutate(r = map2(M, F, sr_ci)) |> unnest(r) |> mutate(spec = label)
}
t5 <- bind_rows(
  tab5(kids, band_main, "main: [0,6) [6,18) [18,60) months"),
  tab5(kids, band_alt, "alt: boundaries inclusive at 6 and 18 months"),
  tab5(filter(kids, file != "Kimberley 1900.xlsx"), band_main, "main, excluding 1900 (siege year)"),
  tab5(filter(kids, file %in% c("Kimberley 1895.xlsx", "Kimberley 1900.xlsx", "Kimberley 1905 and 1910.xlsx")), band_main, "main, 1895-1910 only"))
write_csv(t5, file.path(out, "table5_rebuild.csv"))
t5m <- filter(t5, str_starts(spec, "main: "))

# Coverage of the register files (aggregates only)
cov <- kim |> summarise(records = n(), sex_missing = sum(is.na(sex)), age_missing = sum(is.na(age_m)),
                        race_missing = sum(is.na(race)), asian_other = sum(race %in% "asian_other", na.rm = TRUE),
                        under5_bcw_sexknown = nrow(kids))
write_csv(cov, file.path(out, "kimberley_coverage.csv"))
kids |> count(file, race) |> pivot_wider(names_from = race, values_from = n) |>
  write_csv(file.path(out, "kimberley_under5_by_file_race.csv"))

## Internal consistency of the published Table 5 --------------------------------
pub5 <- claims |> filter(str_starts(claim_id, "T5_")) |>
  mutate(race = str_match(claim_id, "^T5_([a-z]+)_")[, 2], band = str_match(claim_id, "^T5_[a-z]+_(.+)_(sr|n)$")[, 2],
         what = str_match(claim_id, "_(sr|n)$")[, 2]) |>
  mutate(reported_value = as.numeric(reported_value)) |> select(race, band, what, reported_value) |> pivot_wider(names_from = what, values_from = reported_value) |>
  mutate(m_impl = n * sr / (100 + sr), f_impl = n - m_impl)
cons <- pub5 |> filter(band != "0-4years") |> group_by(race) |>
  summarise(n_sum = sum(n), m = sum(m_impl), f = sum(f_impl), sr_from_bands = 100 * m / f,
            fall_m_0to5_vs_18to59 = 100 * (1 - m_impl[band == "1p5-4years"] / m_impl[band == "0-5months"])) |>
  left_join(pub5 |> filter(band == "0-4years") |> select(race, n_pub = n, sr_pub = sr), by = "race")
write_csv(cons, file.path(out, "table5_published_internal_consistency.csv"))

## results_r.csv ----------------------------------------------------------------
res <- list()
add <- function(id, value, se = NA, n = NA) res[[length(res) + 1]] <<- tibble(claim_id = id, value = value, se = se, n = n)
for (i in seq_len(nrow(fig1))) {
  r <- fig1[i, ]; add(sprintf("F1_%s_%d", r$race, r$year), r$sr, r$se, r$n)   # 1921 black = under-one counts (as printed)
}
# Table 4 SR 0-4: census under-five ratios from the supplementary table, census year
# chosen as the census inside each Yearbook period (1960, 1970, 1980, 1991).
t4map <- tribble(~id, ~race, ~year,
  "T4_coloured_1955_sr_04", "coloured", 1960, "T4_coloured_1965_sr_04", "coloured", 1970,
  "T4_coloured_1975_sr_04", "coloured", 1980, "T4_coloured_1985_sr_04", "coloured", 1991,
  "T4_white_1955_sr_04", "white", 1960, "T4_white_1965_sr_04", "white", 1970,
  "T4_white_1975_sr_04", "white", 1980, "T4_white_1985_sr_04", "white", 1991,
  "T4_black_1980_sr_04", "black", 1980, "T4_black_1985_sr_04", "black", 1991)
t4 <- t4map |> left_join(fig1, by = c("race", "year"))
for (i in seq_len(nrow(t4))) add(t4$id[i], t4$sr[i], t4$se[i], t4$n[i])
for (i in seq_len(nrow(t5m))) {
  r <- t5m[i, ]
  add(sprintf("T5_%s_%s_sr", r$race, r$band), r$sr, r$se, r$n)
  add(sprintf("T5_%s_%s_n", r$race, r$band), r$n, NA, r$n)
}
b21 <- filter(fig1, race == "black", year == 1921)
add("TX_p130_black_1921_u1", b21$sr, b21$se, b21$n)
add("TX_p130_cohort_1951", with(filter(fig1, race == "black", year == 1951), males + females))
add("TX_p129_u5_sr_close_to_90", min(filter(fig1, race == "black", year > 1900, year < 1951)$sr))
add("TX_p137_certs", nrow(kim))
mband <- function(rc, b) filter(t5m, race == rc, band == b)$M
add("TX_p138_black_gt101", filter(t5m, race == "black", band == "1p5-4years")$sr)
add("TX_p138_white_92", filter(t5m, race == "white", band == "1p5-4years")$sr)
for (rc in c("white", "black", "coloured"))
  add(sprintf("TX_p138_%s_fall", rc), 100 * (1 - mband(rc, "1p5-4years") / mband(rc, "0-5months")))
res <- bind_rows(res)

out_r <- claims |> select(claim_id) |> left_join(res, by = "claim_id") |>
  mutate(source = "r", status_override = if_else(is.na(value), "unavailable", NA_character_)) |>
  select(claim_id, source, value, se, n, status_override)
stopifnot(nrow(out_r) == nrow(claims), !anyDuplicated(out_r$claim_id))
write_csv(out_r, here::here(P, "repro_r", "results_r.csv"), na = "")

## results_original.csv: no code survives. The only authors' outputs in the surviving
## files are the printed SEX RATIO cells of the supplementary table (F1 points, 1921 u1).
orig_vals <- bind_rows(
  supp |> transmute(claim_id = sprintf("F1_%s_%d", race, year), value = sr_printed,
                    note = sprintf("Supplementary DATA POPULATION PDF, SEX RATIO column, row %d, %s", year, race)),
  supp |> filter(race == "black", year == 1921) |>
    transmute(claim_id = "TX_p130_black_1921_u1", value = sr_printed,
              note = "Supplementary DATA POPULATION PDF, SEX RATIO column, row 1921*, black (under-one)"))
out_o <- claims |> select(claim_id) |> left_join(orig_vals, by = "claim_id") |>
  mutate(source = "original", se = NA, n = NA, status_override = if_else(is.na(value), "unavailable", NA_character_),
         note = coalesce(note, "no original code or tabulation survives")) |>
  select(claim_id, source, value, se, n, status_override, note)
dir.create(here::here(P, "repro_original"), showWarnings = FALSE)
write_csv(out_o, here::here(P, "repro_original", "results_original.csv"), na = "")

## console summary (aggregates)
print(cov); print(select(t5, spec, race, band, M, F, sr, lo, hi), n = 60, width = 200); print(cons, width = 200)
print(filter(fig1, abs(sr_diff_vs_printed) > 0.006) |> select(year, race, sr, sr_printed))
cat("r non-missing:", sum(!is.na(out_r$value)), " original non-missing:", sum(!is.na(out_o$value)), "\n")
