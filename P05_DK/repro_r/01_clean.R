# P05_DK (de Kadt et al. 2021, SAJE) -- S3 independent recreation
# 01_clean.R: build the 1918-district analysis file from raw sources.
# Inputs (D:): Phillips Table 13, SA_1918/1937 shapefiles, RSA_Pop_1904_70 (1911 pops),
#              1907 railways, monthly rainfall 1910-1950, 1936 census Tables 1 and 7.
# Output (D: scratch, aggregate district file): districts_1918.rds; summary CSV in output/.

suppressPackageStartupMessages({
  library(tidyverse); library(readxl); library(sf)
})
root <- here::here("P05_DK")
source(here::here("tools", "paths.R"))
sf_use_s2(FALSE)

src <- dpath("P05_DK", "original", "Spanish_flu_group_folder", "data", "original")
out_dir <- file.path(root, "repro_r", "output"); dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
alb <- "+proj=aea +lat_1=-24 +lat_2=-33 +lat_0=0 +lon_0=24 +datum=WGS84 +units=m +no_defs"
norm <- function(s) gsub("[^a-z]", "", tolower(s))

# ---------------------------------------------------------------- Phillips Table 13
ph_raw <- read_excel(file.path(src, "mortality", "Phillips Table 13_all.xlsx"),
                     col_names = FALSE, col_types = "text", .name_repair = "minimal")
names(ph_raw) <- c("name", "w1918", "b1911", "ic1911", "total", "deaths", "rate")
# Region blocks in the table (row ranges, read from the sheet layout)
blocks <- tribble(~from, ~to, ~region,
                  6, 96, "Cape", 99, 125, "Transkei", 128, 156, "Natal",
                  159, 169, "Zululand", 172, 196, "Transvaal", 199, 222, "OFS")
ph <- map_dfr(seq_len(nrow(blocks)), \(i) ph_raw[blocks$from[i]:blocks$to[i], ] |>
                mutate(region = blocks$region[i])) |>
  mutate(across(w1918:rate, as.numeric), name = str_squish(name))
stopifnot(nrow(ph) == 207, !anyNA(ph$rate))

# Crosswalk Phillips name -> SA_1918 StndrdN (first-named district for combined units)
xw_manual <- c(
  "Albert & Venterstad" = "albert", "Aliwal North/ Lady Grey" = "aliwal north",
  "Barkly West/ Klipdam" = "barkly west", "Cape Town (incl. Durbanville)" = "cape",
  "Fraserburg/ Williston" = "fraserburg", "Graaf-Reinet" = "graaff-reinet",
  "Hope Town" = "hopetown", "Kimberey" = "kimberley",
  "Kingwilliamstown & Keiskamahoek & Middeldrift" = "king williams town",
  "Komgha" = "komga", "Malmesbury / Hopefield" = "malmesbury", "Middelburg" = NA,
  "Oudtshoorn/ Calitzdorp" = "oudtshoorn", "Paarl/ Wellington" = "paarl|wellington",
  "Phillipstown" = "phillipstown", "Piquetberg" = "piketberg",
  "Queenstown/ Sterkstroom" = "queenstown", "Richmond" = NA,
  "Stellenbosch/ Somerset West" = "stellenbosch", "Wodehouse/ Indwe" = "wodehouse",
  "Mt Ayliff" = "mount ayliff", "Mt Curie (Kokstad)" = "mount currie",
  "Mt Fletcher" = "mount fletcher", "Mt Frere" = "mount frere",
  "St Marks (Cofimvaba)" = "st marks", "Alexandra (Umzinto)" = "alexandra",
  "Alfred (Harding)" = "alfred", "Durban & Pinetown" = "durban", "Estcourt [sic]" = "estcourt",
  "Impendhle" = "impendle", "Inanda/ Ndedwe (Verulam)" = "inanda",
  "Klip River (Ladysmith)" = "klipriver", "Krantzkop" = "kranskop",
  "Lions River (Howick)" = "lions river", "Lower Tugela (Stanger)" = "lower tugela",
  "Mapumulo" = "maphumulo", "Polela (Bulwer)" = "polela", "Umvoti (Greytown(" = "umvoti",
  "Vryheid & Babanango" = "vryheid", "Emtonjaneni" = "mtonjaneni",
  "Lower Umfolozi (Empangeni)" = "lower umfolozi", "Mahlabatini" = "mahlabathini",
  "Ndwandwe (Nongoma)" = "ndwandwe", "Nkandhla" = "nkandla", "Umbombo" = "ubombo",
  "Bloemhof & Christiana & Schweizer Reineke" = "bloemhof", "Boksburg/ Springs" = "boksburg",
  "Heidelberg & Vereeniging" = "heidelberg t", "Lydenburg, Pilgrims Rest & Belfast" = "lydenburg",
  "Marico (Zeerust)" = "marico", "Potchefstroom & Klerksdorp" = "potchefstroom",
  "Wakkerstroom & Volksrust" = "wakkerstroom", "Waterberg (Nylstroom)" = "waterberg",
  "Zoutpansberg (Louis Trichardt)" = "soutpansberg", "Bethlehem/ Reitz" = "bethlehem",
  "Bloemfontein/ Bradfort/ Dewetsdorp" = "bloemfontein",
  "Fauresmith/ Jagersfontein/ Koffiefontein" = "fauresmith",
  "Ficksburg/ Fouriesburg" = "ficksburg", "Kroonstad/ Bothaville" = "kroonstad",
  "Phillippolis" = "philippolis", "Rouxville/ Zastron" = "rouxville",
  "Thaba 'Nchu" = "thabanchu", "Vredefort/ Parys" = "vredefort")
sa18 <- st_read(file.path(src, "spatial", "SA_1918.shp"), quiet = TRUE) |> st_make_valid()
ph <- ph |> mutate(key = coalesce(unname(xw_manual[name]), tolower(name)))
# Disambiguate duplicated names by region
ph$key[ph$name == "Middelburg" & ph$region == "Cape"] <- "middelburg c"
ph$key[ph$name == "Middelburg" & ph$region == "Transvaal"] <- "middelburg t"
ph$key[ph$name == "Richmond" & ph$region == "Cape"] <- "richmond c"
ph$key[ph$name == "Richmond" & ph$region == "Natal"] <- NA   # no 1918 polygon
ph$key[ph$name == "Taung"] <- "taung"
ph$key[ph$name == "Elliotdale"] <- "elliotdale"
unmatched <- ph |> filter(!is.na(key)) |> separate_longer_delim(key, "|") |>
  filter(!key %in% sa18$StndrdN)
if (nrow(unmatched) > 0) { print(unmatched); stop("unmatched Phillips rows") }

ph <- ph |> filter(!is.na(key)) |> mutate(unit = row_number())
poly_unit <- ph |> select(unit, key) |> separate_longer_delim(key, "|")
stopifnot(!anyDuplicated(poly_unit$key))
units <- sa18 |> inner_join(poly_unit, by = c("StndrdN" = "key")) |>
  st_transform(alb) |> group_by(unit) |>
  summarise(polys = paste(StndrdN, collapse = "|"), iaa_cod = first(iaa_cod), .groups = "drop") |>
  left_join(ph |> select(unit, name, region, w1918, b1911, ic1911, total, deaths, rate), by = "unit")
units$area_km2 <- as.numeric(st_area(units)) / 1e6
cat("Units with mortality and a 1918 polygon:", nrow(units), "\n")
cat("SA_1918 polygons without a Phillips row:", setdiff(sa18$StndrdN, poly_unit$key), "\n")

# ---------------------------------------------------------------- 1911 populations (areal interpolation)
pop <- st_read(file.path(src, "spatial", "RSA_Pop_1904_70.shp"), quiet = TRUE) |>
  st_make_valid() |> st_transform(alb) |>
  transmute(W = W_1911, B = B_1911, C = C_1911, A = A_1911)
pop_aw <- st_interpolate_aw(pop[c("W", "B", "C", "A")], units, extensive = TRUE, keep_NA = TRUE)
units <- units |> mutate(W11 = pop_aw$W, B11 = pop_aw$B, C11 = pop_aw$C, A11 = pop_aw$A,
                         T11 = W11 + B11 + C11 + A11,
                         black_sh = B11 / T11, col_sh = C11 / T11,
                         dens11 = T11 / area_km2,
                         # sensitivity: Phillips 1911 B and I&C on Phillips total
                         black_sh_ph = b1911 / total, col_sh_ph = ic1911 / total,
                         dens_ph = total / area_km2)

# ---------------------------------------------------------------- Rail distance (1907)
rail <- st_read(file.path(src, "spatial", "railways_1907", "1907_TrainTracks.shp"), quiet = TRUE)
st_crs(rail) <- 4326
rail <- st_transform(rail, alb)
rail_exist <- rail |> filter(!str_detect(Legend, "under construction"))
cent <- st_centroid(st_geometry(units))
units$rail_km     <- apply(st_distance(cent, rail_exist), 1, min) / 1000
units$rail_km_all <- apply(st_distance(cent, rail), 1, min) / 1000

# ---------------------------------------------------------------- Rainfall
rain <- read_csv(file.path(src, "rainfall", "rain_monthly_1910-1950.csv"), show_col_types = FALSE)
rain_so <- rain |> filter(month %in% 9:10) |> group_by(StndrdN) |>
  summarise(rain_so_cm = mean(rain) / 10, .groups = "drop")
units <- units |> mutate(first_poly = str_extract(polys, "^[^|]+")) |>
  left_join(rain_so, by = c("first_poly" = "StndrdN"))

# ---------------------------------------------------------------- 1936 census: white unemployment
c36 <- file.path(src, "census", "census1936")
fix36 <- c("fortbeufort" = "fortbeaufort", "graffreinet" = "graaffreinet",
           "keiskamahoek" = "keiskammahoek", "komgha" = "komga", "middleburgc" = "middelburgc",
           "peddle" = "peddie", "philipstown" = "phillipstown", "piquetberg" = "piketberg",
           "stockenstroom" = "stockenstrom", "taungs" = "taung", "victoricaeast" = "victoriaeast",
           "mouthfrere" = "mountfrere", "impendhle" = "impendle", "mapumulo" = "maphumulo",
           "vryheld" = "vryheid", "emtonjaneni" = "mtonjaneni", "lowerumfolosi" = "lowerumfolozi",
           "mahlabatini" = "mahlabathini", "nkandhla" = "nkandla", "barbeton" = "barberton",
           "heidelberg" = "heidelbergt", "middleburgt" = "middelburgt",
           "potgietersrust" = "potgietersrus", "zoutpansberg" = "soutpansberg",
           "bethulile" = "bethulie", "phillippolis" = "philippolis")
k36 <- function(s) { k <- norm(s); ifelse(k %in% names(fix36), fix36[k], k) }
t1 <- read_excel(file.path(c36, "Table 1_ Unemployment, by gender and race, at MD level.xlsx"),
                 col_names = FALSE, col_types = "text", .name_repair = "minimal")
u36 <- tibble(key = k36(t1[[1]]), u_m = as.numeric(t1[[2]]), u_f = as.numeric(t1[[3]]),
              u_p = as.numeric(t1[[4]])) |>
  filter(!is.na(key), key != "") |> mutate(across(u_m:u_p, \(x) replace_na(x, 0)))
t7 <- read_excel(file.path(c36, "Table 7; Ages in years of Europeans, by gender, at MD level..xlsx"),
                 col_names = FALSE, col_types = "text", .name_repair = "minimal")
# Columns: 1 name, 2 sex, 3..23 = ages 0..20, 24.. = 21-,25-,...,60- (col 32); ages 15-64 = cols 18:32
nm <- t7[[1]]; for (i in seq_along(nm)) if (is.na(nm[i]) && i > 1) nm[i] <- nm[i - 1]
wa <- tibble(key = k36(nm), sex = t7[[2]],
             wa = rowSums(sapply(t7[18:32], \(x) replace_na(as.numeric(x), 0)))) |>
  filter(sex %in% c("M", "F", "P")) |>
  pivot_wider(names_from = sex, values_from = wa, names_prefix = "wa_", values_fn = sum)
y37 <- st_read(file.path(src, "spatial", "1937.shp"), quiet = TRUE) |> st_make_valid() |>
  st_transform(alb) |> mutate(key = norm(StndrdN))
d36 <- y37 |> left_join(u36, by = "key") |> left_join(wa, by = "key")
cat("1937 polygons without 1936 unemployment row:", d36$key[is.na(d36$u_p)], "\n")
cat("1937 polygons without 1936 age row:", d36$key[is.na(d36$wa_P)], "\n")
cat("1936 rows not matched to a 1937 polygon (unemployment):",
    setdiff(u36$key, y37$key) |> keep(\(k) !str_detect(k, "total|^cape$|natal|transvaal|ofs|orange|province|zululand|transkei|tembuland|pondoland|griqualand|walvis")), "\n")
d36 <- d36 |> mutate(across(c(u_m, u_f, u_p, wa_M, wa_F, wa_P), \(x) replace_na(x, 0)))
aw36 <- st_interpolate_aw(d36[c("u_m", "u_f", "u_p", "wa_M", "wa_F", "wa_P")], units, extensive = TRUE)
units <- units |> mutate(ur_total = aw36$u_p / aw36$wa_P, ur_women = aw36$u_f / aw36$wa_F,
                         ur_men = aw36$u_m / aw36$wa_M)

# ---------------------------------------------------------------- Final variables
units <- units |> mutate(
  region = factor(region, levels = c("Cape", "Natal", "OFS", "Transkei", "Transvaal", "Zululand")),
  log_rate = log(rate), ldens = log1p(dens11), lrail = log1p(rail_km),
  ldens_ph = log1p(dens_ph), lrail_all = log1p(rail_km_all))

dir.create(dscratch("P05_DK", "repro_r"), showWarnings = FALSE)
saveRDS(units, dscratch("P05_DK", "repro_r", "districts_1918.rds"))
saveRDS(list(phillips_total_deaths = sum(ph_raw |> slice(c(6:96, 99:125, 128:156, 159:169, 172:196, 199:222)) |>
                                           pull(deaths) |> as.numeric()),
             n_polygons_1918 = nrow(sa18)),
        dscratch("P05_DK", "repro_r", "aux_counts.rds"))
# Aggregate summary only (district-level public aggregates)
units |> st_drop_geometry() |>
  select(rate, black_sh, col_sh, dens11, rail_km, rain_so_cm, ur_total, ur_women, ur_men) |>
  pivot_longer(everything()) |> group_by(name) |>
  summarise(n = sum(!is.na(value)), mean = mean(value, na.rm = TRUE), sd = sd(value, na.rm = TRUE),
            min = min(value, na.rm = TRUE), max = max(value, na.rm = TRUE)) |>
  write_csv(file.path(out_dir, "summary_covariates.csv"))
cat("Done: ", nrow(units), "units\n")
