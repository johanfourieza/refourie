# P29_INEQ25 -- S3 independent recreation, step 1: cleaning
# Fourie (2025) "Inequality in the Cape Colony, 1685-1844", SAJS.
# Builds analysis-ready household files from the as-raw-as-available workbooks.
# Every construction choice is documented in decisions.md (D-numbers cited below).
# Outputs (data, so on D:, never Dropbox): repro_r/_scratch/clean_*.rds

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})
PROJ  <- "."
source(file.path(PROJ, "tools", "paths.R"))
SRC   <- dpath("P29_INEQ25", "original", "2024F_Inequality")
SCR   <- dscratch("P29_INEQ25", "repro_r")
f_in  <- function(x) file.path(SRC, x)

# Parse transcribed numbers ("7½", "6.25E-2", "?", "12 ")  -------------------
parse_num <- function(z) {
  z <- as.character(z)
  z <- str_replace_all(z, "(\\d)\u00bd", "\\1.5")
  z <- str_replace_all(z, "(\\d)\u00bc", "\\1.25")
  z <- str_replace_all(z, "(\\d)\u00be", "\\1.75")
  z <- str_replace_all(z, "\u00bd", "0.5")
  z <- str_replace_all(z, "\u00bc", "0.25")
  z <- str_replace_all(z, "\u00be", "0.75")
  z <- str_replace_all(z, ",", ".")
  z <- str_replace_all(z, "[^0-9.Ee+-]", "")
  suppressWarnings(as.numeric(z))
}

# ============================================================================
# 1. Stellenbosch-Drakenstein opgaaf panel (D1-D8)
# ============================================================================
st <- read_excel(f_in("stellenbosch_clean_april2025.xlsx"), guess_max = 200000)
st$vines <- parse_num(st$vines)

comp <- list(   # asset -> components summed (D3)
  horses = c("horses", "horse_work", "horse_riding", "horse_breeding", "horse_pleasure"),
  cattle = c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
             "cattle_heifers", "cattle_calves"),
  sheep  = c("sheep", "sheep_breeding", "sheep_wool", "sheep_wether"),
  wheat  = "wheat_vol",
  vines  = "vines",
  wine   = "wine",
  slaves_men = "slave_men",
  slaves_all = c("slave_men", "slave_women", "slave_sons", "slave_daughters")
)
allc <- unique(unlist(comp))
st <- st %>% mutate(across(all_of(allc), as.numeric)) %>% mutate(row_id = row_number())

# D2: a component counts as recorded in a year if any household has a non-missing
#     value; within recorded years a blank cell is a zero.
rec <- st %>% group_by(year) %>% summarise(across(all_of(allc), ~ any(!is.na(.x))), .groups = "drop")
long <- st %>% select(row_id, year, all_of(allc)) %>%
  pivot_longer(all_of(allc), names_to = "component", values_to = "value") %>%
  left_join(rec %>% pivot_longer(-year, names_to = "component", values_to = "recorded"),
            by = c("year", "component")) %>%
  mutate(value = if_else(recorded & is.na(value), 0, value))

# D4: outlier trimming. Values above 10 x the year-specific 99th percentile of
#     positive values of that component are treated as transcription errors.
long <- long %>% group_by(year, component) %>%
  mutate(p99 = suppressWarnings(quantile(value[value > 0], 0.99, na.rm = TRUE, names = FALSE)),
         trimmed = !is.na(value) & value > 0 & !is.na(p99) & value > 10 * p99,
         value = if_else(trimmed, NA_real_, value)) %>% ungroup()
trim_log <- long %>% filter(trimmed) %>% count(component, name = "n_trimmed")

trim_hh <- long %>% filter(component %in% setdiff(allc, comp$slaves_all)) %>%
  group_by(row_id) %>% summarise(any_trim = any(trimmed), .groups = "drop")
wide <- long %>% select(row_id, component, value) %>%
  pivot_wider(names_from = component, values_from = value)
st_c <- st %>% select(row_id, persid, hhid, year) %>% left_join(wide, by = "row_id") %>%
  left_join(trim_hh, by = "row_id")

# Asset totals in physical units (NA if any recorded component was trimmed, or
# if no component of the asset is recorded that year)
for (a in names(comp)) {
  cs <- comp[[a]]
  m  <- as.matrix(st_c[, cs, drop = FALSE])
  recm <- as.matrix(rec[match(st_c$year, rec$year), cs, drop = FALSE])
  anyrec <- rowSums(recm) > 0
  trim_any <- rowSums(is.na(m) & recm) > 0
  st_c[[paste0("q_", a)]] <- ifelse(anyrec & !trim_any, rowSums(m, na.rm = TRUE), NA_real_)
}

# Prices (D5-D6): decade price series from MOOC10 auctions; year -> decade,
# clamped to the 1690-1830 range of the series. Component-specific prices
# where the series has them, otherwise the generic asset price.
pr <- read_excel(f_in("price_series.xlsx"))
dec <- function(y) pmin(pmax(10 * floor(y / 10), 1690), 1830)
pp  <- function(col, fallback = NULL) {
  v <- pr[[col]]
  if (!is.null(fallback)) v <- ifelse(is.na(v), pr[[fallback]], v)
  setNames(v, pr$period)
}
price_map <- list(
  horses = pp("horses"), horse_work = pp("horses"), horse_riding = pp("horses"),
  horse_pleasure = pp("horses"), horse_breeding = pp("horse_breeding", "horses"),
  cattle_bull = pp("cattle_bull"), cattle_breeding = pp("cattle_breeding"),
  cattle_work = pp("cattle_work"), cattle_cows = pp("cattle_cows"),
  cattle_heifers = pp("cattle_heifers"), cattle_calves = pp("cattle_calves"),
  sheep = pp("sheep"), sheep_wool = pp("sheep"),
  sheep_breeding = pp("sheep_breeding", "sheep"), sheep_wether = pp("sheep_wether", "sheep"),
  wheat_vol = pp("wheat_vol"), wine = pp("wine")
)
st_c$decade_p <- dec(st_c$year)
st_c$p_sheep  <- price_map$sheep[as.character(st_c$decade_p)]
valc <- function(a) {   # rix-dollar value of one asset from its components
  cs <- intersect(comp[[a]], names(price_map))
  v <- 0
  for (cc in cs) v <- v + coalesce(st_c[[cc]], 0) * price_map[[cc]][as.character(st_c$decade_p)]
  ifelse(is.na(st_c[[paste0("q_", a)]]), NA_real_, v)
}
for (a in c("horses", "cattle", "sheep", "wheat", "wine")) st_c[[paste0("v_", a)]] <- valc(a)
# D7: total value = sum of priced basket assets (vines have no price in the
# series and are excluded from the value basket). Household dropped from the
# value Gini if any of its recorded assets was trimmed.
st_c <- st_c %>% mutate(
  total_value = rowSums(across(c(v_horses, v_cattle, v_sheep, v_wheat, v_wine)), na.rm = TRUE),
  total_value = if_else(any_trim, NA_real_, total_value),
  slave_asset = 200 * coalesce(q_slaves_all, 0) * p_sheep          # D9
)
saveRDS(list(hh = st_c, trim_log = trim_log, rec = rec), file.path(SCR, "clean_stellenbosch.rds"))

# ============================================================================
# 2. c.1825 district cross-section (D10-D12)
# ============================================================================
# Column positions read from the multi-row headers of each sheet:
# horses = saddle/wagon + breeding; oxen = draught oxen; cattle = breeding cattle;
# sheep = wethers + breeding + Spanish/wool; wheat = muids reaped; wine = leggers.
cmap <- tribble(
  ~sheet,               ~district,      ~h1, ~h2, ~ox, ~ca, ~s1, ~s2, ~s3, ~wh, ~wi,
  "Cape district 1825", "Cape",          25,  26,  27,  28,  29,  30,  31,  39,  45,
  "Stellenbosch 1825",  "Stellenbosch",  27,  28,  29,  30,  31,  32,  33,  41,  47,
  "Graaff-Reinet 1825", "Graaff-Reinet", 26,  27,  28,  29,  30,  31,  32,  40,  45,
  "Swellendam 1825",    "Swellendam",    25,  26,  27,  28,  29,  30,  31,  39,  44,
  "Albany 1825",        "Albany",        27,  28,  29,  30,  31,  32,  33,  41,  46,
  "Beaufort 1825",      "Beaufort",      27,  28,  29,  30,  31,  32,  33,  41,  46,
  "Clanwilliam 1824",   "Clanwilliam",   24,  25,  26,  27,  28,  29,  30,  37,  42,
  "Cradock 1823",       "Cradock",       20,  21,  22,  23,  24,  25,  26,  33,  38,
  "George 1825",        "George",        27,  28,  29,  30,  31,  32,  33,  41,  46,
  "Worcester 1824",     "Worcester",     25,  26,  27,  28,  29,  30,  31,  39,  44,
  "Uitenhage 1825",     "Uitenhage",     27,  28,  29,  30,  31,  32,  33,  41,  46
)
slave_cols <- list(   # enslaved persons columns (used only for D16 non-owner allocation)
  "Cape" = 23:24, "Stellenbosch" = 21:24, "Graaff-Reinet" = 18:21, "Swellendam" = 17:20,
  "Albany" = 19:22, "Beaufort" = 19:22, "Clanwilliam" = 20:23, "Cradock" = 16:19,
  "George" = 19:22, "Worcester" = 21:24, "Uitenhage" = 19:22)

# D11: a household is a row whose first column is a register number; following
# unnumbered rows (wives, sons, inmates) belong to that household and their
# holdings are added to it.
read_1825 <- function(sheet, district, cols, f = f_in("1825 series.xlsx"), slave_c = NULL, agg = TRUE) {
  x <- read_excel(f, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  is_num <- str_detect(coalesce(x[[1]], ""), "^\\s*\\d+\\s*$")
  first  <- which(is_num)[1]
  hh <- cumsum(is_num); hh[seq_len(first - 1)] <- 0
  # stop at the archival footer (first row after the last numbered row whose
  # first cell is non-numeric text such as "J56" / "Opgaafrolle ...")
  last <- max(which(is_num))
  tail_txt <- which(seq_len(nrow(x)) > last & !is.na(x[[1]]) & !is_num)
  if (length(tail_txt)) hh[tail_txt[1]:nrow(x)] <- 0
  g <- function(j) parse_num(x[[j]])
  d <- tibble(hh = hh,
              horses = coalesce(g(cols$h1), 0) + coalesce(g(cols$h2), 0),
              oxen   = coalesce(g(cols$ox), 0),
              cattle = coalesce(g(cols$ca), 0),
              sheep  = coalesce(g(cols$s1), 0) + coalesce(g(cols$s2), 0) + coalesce(g(cols$s3), 0),
              wheat  = coalesce(g(cols$wh), 0),
              wine   = coalesce(g(cols$wi), 0),
              slaves = if (is.null(slave_c)) 0 else rowSums(sapply(slave_c, function(j) coalesce(g(j), 0))))
  if (!agg) return(d %>% mutate(has_name = !is.na(x[[2]]) | !is.na(x[[3]])) %>%
    filter(hh > 0) %>% mutate(district = district))
  d %>% filter(hh > 0) %>% group_by(hh) %>% summarise(across(everything(), sum), .groups = "drop") %>%
    mutate(district = district)
}
d1825 <- map_dfr(seq_len(nrow(cmap)), function(i) {
  r <- cmap[i, ]
  read_1825(r$sheet, r$district, as.list(r), slave_c = slave_cols[[r$district]])
})
saveRDS(d1825, file.path(SCR, "clean_1825.rds"))
# Post-hoc sensitivity P2: Cape and Swellendam at row (person-entry) level
d1825_rows <- map_dfr(which(cmap$district %in% c("Cape", "Swellendam")), function(i) {
  r <- cmap[i, ]; read_1825(r$sheet, r$district, as.list(r), agg = FALSE)
})
saveRDS(d1825_rows, file.path(SCR, "clean_1825_rows_cape_swellendam.rds"))

# ============================================================================
# 3. Probate inventories, MOOC8 (D13)
# ============================================================================
mo <- read_excel(f_in("MOOC_probates.xlsx"), guess_max = 1e5) %>%
  transmute(year, cattle = coalesce(cattle_nr, 0), horses = coalesce(horse_nr, 0),
            sheep = coalesce(sheep_nr, 0), ploughs = coalesce(plough_nr, 0),
            wagons = coalesce(wagon_nr, 0)) %>%
  filter(!is.na(year), year >= 1700, year <= 1839) %>%
  mutate(decade = 10 * floor(year / 10))
saveRDS(mo, file.path(SCR, "clean_probates.rds"))

# ============================================================================
# 4. Slave Emancipation Data set, 1834 (D14-D16)
# ============================================================================
se <- read_excel(f_in("Slave Emancipation Dataset.xlsx"), guess_max = 1e5)
n_slaves <- nrow(se)
owners <- se %>%
  mutate(owner = paste(District_name, str_squish(tolower(Owner_surname)),
                       str_squish(tolower(Owner_name)), sep = "|")) %>%
  group_by(District_name, owner) %>%
  summarise(n_sl = n(),
            n_val = sum(!is.na(Valuation)),
            valuation = sum(Valuation, na.rm = TRUE),
            compensation = sum(Compensation, na.rm = TRUE),
            n_comp = sum(!is.na(Compensation)), .groups = "drop") %>%
  rename(district = District_name)
saveRDS(list(owners = owners, n_slaves = n_slaves,
             slaves = se %>% transmute(district = District_name, valuation = Valuation)), file.path(SCR, "clean_emancipation.rds"))

# ============================================================================
# 5. Khoe settlements (D17-D19)
# ============================================================================
be <- read_excel(f_in("EBTstation.xlsx"), sheet = "Bethelsdorp", guess_max = 1e4)
beth <- be %>% transmute(settlement = "Bethelsdorp", year = as.numeric(year),
  horses = coalesce(parse_num(horseM), 0) + coalesce(parse_num(horseF), 0),
  oxen   = coalesce(parse_num(cattleM), 0),
  cattle = coalesce(parse_num(cattleF), 0),
  sheep  = coalesce(parse_num(sheep_goats), 0),
  wheat  = coalesce(parse_num(wheat_reaped), 0))
sw <- read_excel(f_in("Swartrivier.xlsx"), sheet = "Data", col_types = "text", .name_repair = "unique_quiet")
swart <- tibble(settlement = "Swartrivier", year = 1825,
  horses = coalesce(parse_num(sw$`Wagon and Saddle Horses`), 0) + coalesce(parse_num(sw$`Breeding Horses`), 0),
  oxen   = coalesce(parse_num(sw$Oxen), 0),
  cattle = coalesce(parse_num(sw$`Breeding cattle`), 0),
  sheep  = coalesce(parse_num(sw$Wethers), 0) + coalesce(parse_num(sw$`Breeding Sheep`), 0),
  wheat  = coalesce(parse_num(sw$Wheat), 0))
gk <- read_1825("1825", "Groenekloof", as.list(cmap[cmap$district == "Cape", ]), f = f_in("Groenekloof.xlsx"))
groen <- gk %>% transmute(settlement = "Groenekloof", year = 1825, horses, oxen, cattle, sheep, wheat)
khoe <- bind_rows(beth, swart, groen)
# Post-hoc sensitivity P4: Bethelsdorp cattle = cattleM + cattleF
beth_alt <- be %>% transmute(cattle_all = coalesce(parse_num(cattleM), 0) + coalesce(parse_num(cattleF), 0))
saveRDS(beth_alt, file.path(SCR, "clean_beth_alt.rds"))
saveRDS(khoe, file.path(SCR, "clean_khoe.rds"))

cat("01_clean.R done\n")
cat("Stellenbosch rows:", nrow(st_c), " years:", n_distinct(st_c$year), "\n")
print(trim_log)
print(d1825 %>% count(district))
cat("1825 households:", nrow(d1825), "\n")
print(khoe %>% count(settlement))
cat("probates:", nrow(mo), " slaves:", n_slaves, " owners:", nrow(owners), "\n")
