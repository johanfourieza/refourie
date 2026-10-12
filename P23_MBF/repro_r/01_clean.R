# P23_MBF S3 independent recreation - 01_clean.R
# Builds (i) the individual-level logit sample (Tables 2-3) and (ii) region x birth-decade
# aggregates (Table 4, Figure 3) from the IPUMS analysis file. Derived data are written to
# ./P23_MBF/repro_r/_scratch (restricted licence; never to Dropbox).
suppressMessages({
  library(here); library(haven); library(dplyr); library(readr)
})
proj <- here::here()                       # project root (git root); paper folder below
source(file.path(proj, "tools", "paths.R"))
out <- file.path(proj, "P23_MBF", "repro_r", "output")
P <- "P23_MBF"
scr <- function(...) dscratch(P, "repro_r", ...)

f <- dpath(P, "original", "ld", "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta")
keep <- c("cntry_name", "admin_name", "cyear", "id_birth", "geolev1", "geolev2", "age", "sex",
          "edattain", "yrschool", "perwt", "independence", "d_muslim", "d_christian", "rural",
          "d_birth_all", "d_birth_coup", "d_birth_elite",
          "tse_r", "railway_density", "count_tribe", "slave_density", "d_mission", "dist_cap",
          "d_western", "d_capital", "area_km2", "lat_id_bir", "lon_id_bir")
d <- read_dta(f, col_select = all_of(keep)) |>
  mutate(across(where(is.labelled), ~ as.numeric(zap_labels(.x))))

# ---- individual variables (own construction from raw IPUMS fields) ----
d <- d |>
  mutate(
    yob       = cyear - age,                         # year of birth
    bdec_r    = floor(yob / 10) * 10,                # birth decade
    age_ind   = independence - yob,                  # age in the independence year
    primary   = case_when(edattain %in% 2:4 ~ 1, edattain %in% 1 ~ 0, TRUE ~ NA_real_),
    female    = as.numeric(sex == 2),
    age2      = age^2,
    yrs       = ifelse(yrschool > 90, NA, yrschool), # IPUMS 9x = unknown/NIU
    # PreIndep = 1 if turned 13 before independence; 0 if turned 6 after; NA if aged 6-13
    preindep  = case_when(age_ind >= 14 ~ 1, age_ind <= 5 ~ 0, TRUE ~ NA_real_),
    # windows for Table 3 cols 3-4: primary ages (6-13) overlap [indep-k, indep+k]
    drop_k2   = age_ind >= 6 - 2 & age_ind <= 13 + 2,
    drop_k3   = age_ind >= 6 - 3 & age_ind <= 13 + 3
  )

ind <- d |>
  filter(!is.na(preindep), !is.na(primary)) |>
  select(cntry_name, id_birth, primary, preindep, d_birth_all, d_birth_coup, d_birth_elite,
         age, age2, female, d_muslim, d_christian, rural, tse_r, railway_density, count_tribe,
         slave_density, d_mission, dist_cap, d_western, d_capital, age_ind, drop_k2, drop_k3)
saveRDS(ind, scr("ind_sample.rds"))

# ---- region-level attributes ----
reg <- d |>
  group_by(cntry_name, id_birth) |>
  summarise(admin_name = first(admin_name), geolev1 = first(geolev1),
            across(c(d_birth_all, tse_r, railway_density, count_tribe, slave_density, d_mission,
                     dist_cap, d_western, d_capital, area_km2, lat_id_bir, lon_id_bir), first),
            .groups = "drop")
saveRDS(reg, scr("regions.rds"))

# ---- region x birth-decade aggregates (unweighted; Table 4) ----
heap <- function(a) as.numeric(a %% 5 == 0)
gini <- function(x) { x <- sort(x[!is.na(x)]); n <- length(x); m <- mean(x)
  if (n < 2 || m == 0) return(NA_real_); sum((2 * seq_len(n) - n - 1) * x) / (n^2 * m) }
# expected heaping share under no heaping, given the ages present in a country x decade
exp_share <- d |> group_by(cntry_name, bdec_r) |>
  summarise(amin = min(age), amax = max(age), .groups = "drop") |>
  rowwise() |> mutate(e_heap = mean(heap(amin:amax))) |> ungroup()
agg <- d |>
  left_join(exp_share, by = c("cntry_name", "bdec_r")) |>
  group_by(cntry_name, id_birth, bdec_r) |>
  summarise(n_ind = n(),
            yrschool = mean(yrs, na.rm = TRUE),
            yrschool_w = weighted.mean(yrs, perwt, na.rm = TRUE),
            wh = 100 * mean(heap(age)) / first(e_heap),
            gini = gini(yrs),
            .groups = "drop") |>
  mutate(abcc = ifelse(wh >= 100, (1 - (wh - 100) / 400) * 100, 100),
         yrschool = ifelse(is.nan(yrschool), NA, yrschool)) |>
  left_join(reg, by = c("cntry_name", "id_birth"))
saveRDS(agg, scr("region_decade.rds"))

# ---- country-level sample description (Table 1) -> aggregate, safe to write ----
t1 <- d |> group_by(cntry_name) |>
  summarise(independence = first(independence), census = first(cyear),
            bdec_min = min(bdec_r), bdec_max = max(bdec_r), n = n(), .groups = "drop")
dir.create(out, showWarnings = FALSE)
write_csv(t1, file.path(out, "table1_sample.csv"))
cat("individual sample:", nrow(ind), "\n")
