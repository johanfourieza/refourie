# P06_FGa S3 recreation -- 01_clean.R
# Builds household-level Cape and US data and the price table from raw inputs.
# See decisions.md (D1-D12). Derived data are written to the D: scratch folder (A6).
suppressPackageStartupMessages({
  library(tidyverse); library(readxl)
})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
PAPER <- "P06_FGa"
OUT   <- file.path(PROJ, PAPER, "repro_r", "output"); dir.create(OUT, showWarnings = FALSE)
SRC   <- dpath(PAPER, "original", "20 FG Comparisons")
SCR   <- dscratch(PAPER, "repro_r")
set.seed(20261011)

# ---------------------------------------------------------------- helpers
frac_num <- function(x) {
  x <- str_trim(as.character(x))
  map <- c("½" = .5, "¼" = .25, "¾" = .75, "⅛" = .125, "⅜" = .375, "⅝" = .625, "⅞" = .875, "⅓" = 1/3, "⅔" = 2/3)
  out <- suppressWarnings(as.numeric(x))
  todo <- which(is.na(out) & !is.na(x))
  for (i in todo) {
    s <- x[i]; add <- 0
    for (k in names(map)) if (str_detect(s, fixed(k))) { add <- add + map[[k]]; s <- str_remove(s, fixed(k)) }
    if (str_detect(s, "^\\s*\\d+\\s*/\\s*\\d+")) {          # e.g. 1/16th
      p <- as.numeric(str_match(s, "(\\d+)\\s*/\\s*(\\d+)")[, 2:3]); add <- add + p[1] / p[2]; s <- ""
    }
    s <- str_trim(s)
    base <- if (s == "") 0 else suppressWarnings(as.numeric(s))
    out[i] <- if (is.na(base) || add == 0 && s != "" && is.na(suppressWarnings(as.numeric(s)))) NA else base + add
  }
  out
}
z <- function(x) replace_na(x, 0)

# ---------------------------------------------------------------- Cape households
cape_raw <- read_excel(file.path(SRC, "Data", "FourieGarmenCape.xlsx"), sheet = "Full", col_types = "text")
vars <- c("Slaves", "Horses", "Cattle", "Sheep", "Wheatreaped", "Barleyreaped", "Ryereaped",
          "Oatsreaped", "Vines", "Wine", "Brandy")
cape <- cape_raw %>%
  transmute(District = recode(District, "Graaff Reinet" = "Graaff-Reinet"),
            census_year = as.integer(Year), across(all_of(vars), frac_num))

# D7: Stellenbosch 1805 rows shifted one column left from rye onwards
shift <- with(cape, District == "Stellenbosch" & census_year == 1805 & z(Oatsreaped) >= 1000)
cat("Stellenbosch 1805 shifted rows fixed:", sum(shift), "\n")
cape$Oatsreaped[shift] <- frac_num(cape_raw$Ryereaped[shift])
cape$Ryereaped[shift]  <- 0
cape$Vines[shift]      <- frac_num(cape_raw$Oatsreaped[shift])
cape$Wine[shift]       <- frac_num(cape_raw$Vines[shift])
cape$Brandy[shift]     <- frac_num(cape_raw$Wine[shift])

bench_cape <- function(d, y) case_when(y %in% c(1785, 1787) ~ 1785L, y %in% c(1795, 1798) ~ 1795L,
                                       y %in% c(1805, 1806) ~ 1805L, y %in% c(1814, 1815) ~ 1815L)
cape <- cape %>% transmute(
  country = "Cape Colony", district = District, census_year, year = bench_cape(District, census_year),
  wheat = z(Wheatreaped), barley = z(Barleyreaped), rye = z(Ryereaped), oats = z(Oatsreaped), corn = 0,
  wine = z(Wine), brandy = z(Brandy), horses = z(Horses), cattle = z(Cattle), sheep = z(Sheep),
  slaves = z(Slaves), slaves16 = NA_real_, slaves_u16 = NA_real_,
  crops_recorded = TRUE, sheep_recorded = TRUE)

# ---------------------------------------------------------------- US households
us_raw <- read_excel(file.path(SRC, "Data", "Data for Johan - Massachusetts and Virginia.xlsx"),
                     guess_max = 100000)
num <- function(x) suppressWarnings(as.numeric(x))
us <- us_raw %>% transmute(
  country = "United States",
  district = recode(as.character(State), "3" = "Virginia", "4" = "Massachusetts", "10" = "Maine"),
  census_year = as.integer(Year),
  year = case_when(census_year %in% c(1784, 1785, 1787) ~ 1785L, census_year %in% c(1792, 1795) ~ 1795L,
                   census_year %in% c(1801, 1805, 1806) ~ 1805L, census_year %in% c(1811, 1814, 1815) ~ 1815L),
  wheat = z(num(Buschels_Wheat)), barley = z(num(Buschels_Barley)), rye = z(num(Buschels_Rye)),
  oats = z(num(Buschels_Oats)), corn = z(num(Buschels_Corn)), wine = 0, brandy = 0,
  horses = z(num(Total_Horses)), cattle = z(num(Total_Cattle)) + z(num(Total_Oxen)),
  sheep = z(num(Total_Sheep)),
  slaves = z(num(Total_Slaves)), slaves16 = z(num(Slaves16)), slaves_u16 = z(num(Slaves_Under16)),
  crops_recorded = district != "Virginia", sheep_recorded = district != "Virginia")

hh <- bind_rows(cape, us) %>%
  mutate(crops_bu = wheat + barley + rye + oats + corn,
         farmer = crops_bu >= 1 | cattle > 0 | sheep > 0)
stopifnot(!any(is.na(hh$year)))
saveRDS(hh, file.path(SCR, "households.rds"))

# ---------------------------------------------------------------- US crop prices (D9)
pc <- read_excel(file.path(SRC, "Prices.xlsx"), sheet = "US Crops Annual Data Points",
                 col_names = FALSE, col_types = "text", .name_repair = "unique_quiet")
yrs <- num(pc[[1]][3:12])
grab <- function(col) num(str_remove_all(pc[[col]][3:12], "[^0-9.]"))
us_pts <- tibble(year = yrs,
                 wheat_md = grab(9), corn_hi = grab(3), corn_lo = grab(4), rye_hi = grab(5), rye_lo = grab(6),
                 barley = grab(7), oats = grab(8))
stopifnot(pc[[9]][1] == "Maryland", pc[[7]][2] == "Barley", pc[[8]][2] == "Oats")
mid <- function(a, b) ifelse(is.na(a), b, ifelse(is.na(b), a, (a + b) / 2))
w <- us_pts %>% filter(year >= 1785, year <= 1815) %>%
  mutate(corn = mid(corn_hi, corn_lo), rye = mid(rye_hi, rye_lo))
us_crop_p <- c(wheat = mean(w$wheat_md, na.rm = TRUE), barley = mean(w$barley, na.rm = TRUE),
               rye = mean(w$rye, na.rm = TRUE), oats = mean(w$oats, na.rm = TRUE), corn = mean(w$corn, na.rm = TRUE))

# ---------------------------------------------------------------- Cape auction prices (D10)
XR <- 5 / 4.53   # rijksdaalders per US dollar
auc_cols <- list("Cape auction" = c(8, 9), "Cape auction 2" = c(8, 9), "Cape auction 3" = c(7, 8), "Cape auction 4" = c(8, 9))
lots <- map_dfr(names(auc_cols), function(s) {
  a <- read_excel(file.path(SRC, "Prices.xlsx"), sheet = s, col_names = FALSE, col_types = "text",
                  .name_repair = "unique_quiet")
  txt <- a[[3]]; rds <- num(a[[auc_cols[[s]][1]]]); sch <- num(a[[auc_cols[[s]][2]]])
  starts_digit <- str_detect(replace_na(txt, ""), "^\\s*\\d")
  pr <- which(!is.na(rds))
  map_dfr(pr, function(i) {
    if (starts_digit[i] || str_detect(replace_na(txt[i], ""), "^\\s*(slave|1 )")) {
      j <- i + 1; item <- txt[i]
      while (j <= length(txt) && is.na(rds[j]) && !starts_digit[j] && !is.na(txt[j])) { item <- paste(item, txt[j]); j <- j + 1 }
    } else {                                   # price line precedes the item lines
      j <- i + 1; item <- NULL
      while (j <= length(txt) && is.na(rds[j]) && !is.na(txt[j]) && (is.null(item) || !starts_digit[j])) { item <- paste(c(item, txt[j]), collapse = " "); j <- j + 1 }
      if (is.null(item)) item <- txt[i]
    }
    tibble(auction = s, row = i, item = item, price_rd = rds[i] + replace_na(sch[i], 0) / 8)
  })
})
classify <- function(t) {
  t <- str_to_lower(t)
  case_when(
    str_detect(t, "bokken|kaff|hooij|hoop|zakken|varken") ~ NA_character_,
    str_detect(t, "brandewijn") ~ "brandy",
    str_detect(t, "legger") & str_detect(t, "wijn") ~ "wine",
    str_detect(t, "slave|slavin") ~ "slaves",
    str_detect(t, "koorn|coorn") ~ "wheat",
    str_detect(t, "garst") ~ "barley",
    str_detect(t, "rogge|\\brog\\b") ~ "rye",
    str_detect(t, "haver") ~ "oats",
    str_detect(t, "paard|merrij|veulen") ~ "horses",
    str_detect(t, "ossen|koeij|bul|vaars|beest|kalver") ~ "cattle",
    str_detect(t, "schaap|schapen|hamel") ~ "sheep",
    TRUE ~ NA_character_)
}
lots <- lots %>% mutate(
  cat = classify(item),
  composite = str_detect(str_to_lower(item), "\\ben\\b|met haar|kind|met wat wijn|circa"),
  qty = case_when(cat == "slaves" ~ 1,
                  str_detect(str_to_lower(item), "half legger") ~ 0.5,
                  TRUE ~ num(str_match(item, "^\\s*(\\d+)")[, 2])),
  unit_rd = price_rd / qty) %>%
  filter(!is.na(cat), !composite, !is.na(unit_rd), unit_rd > 0)
auction_means <- lots %>% group_by(cat, auction) %>% summarise(n_lots = n(), mean_rd = mean(unit_rd), .groups = "drop")
cape_auc <- auction_means %>% group_by(cat) %>%
  summarise(n_auctions = n(), n_lots = sum(n_lots), price_rd = mean(mean_rd), .groups = "drop") %>%
  mutate(price_usd = price_rd / XR)
write_csv(auction_means, file.path(OUT, "cape_auction_means_by_auction.csv"))
write_csv(cape_auc, file.path(OUT, "cape_auction_prices.csv"))
ca <- setNames(cape_auc$price_usd, cape_auc$cat)

# ---------------------------------------------------------------- cached workbook prices (sensitivity P2 only)
rd_final <- function(s) {
  f <- read_excel(file.path(SRC, "Prices.xlsx"), sheet = s)
  f %>% pivot_longer(-Country, names_to = "item", values_to = "price") %>%
    mutate(item = str_to_lower(str_remove(item, "^P")), price = num(price))
}
wb  <- rd_final("Final"); wb2 <- rd_final("Final2")
wbp <- function(d, ctry, it) d$price[d$Country == ctry & d$item == it]

# ---------------------------------------------------------------- price specifications
mk <- function(spec, country, item, price, source) tibble(spec, country, item, price, source)
P1 <- bind_rows(
  mk("P1", "United States", names(us_crop_p), unname(us_crop_p), "Wright MA / Adams MD data points, 1785-1815 mean (D9)"),
  mk("P1", "United States", c("horses", "cattle", "sheep", "slaves16", "slaves_u16"),
     c(94.93, 16.32, 3.11, 178.51, 162.95), "paper p.15"),
  mk("P1", "Cape Colony", c("wheat", "barley", "rye", "oats", "wine", "brandy", "slaves"),
     unname(ca[c("wheat", "barley", "rye", "oats", "wine", "brandy", "slaves")]), "own auction parse (D10)"),
  mk("P1", "Cape Colony", "corn", 0, "not recorded"),
  mk("P1", "Cape Colony", c("horses", "cattle", "sheep"), c(36.38, 19.28, 1.73), "paper p.16 baseline"),
  mk("P1", "Cape Colony", c("horses_cons", "cattle_cons", "sheep_cons"), c(20.24, 9.37, 1.18), "paper p.16 conservative"),
  mk("P1", "Cape Colony", "slaves_cons", wbp(wb2, "Cape Colony", "slaves"), "Prices.xlsx Final2 (not stated in paper)"))
P2 <- P1 %>% mutate(spec = "P2", source = "Prices.xlsx Final/Final2 cached")
for (i in seq_len(nrow(P2))) {
  it <- P2$item[i]; ct <- P2$country[i]
  if (it %in% c("slaves16")) it2 <- "slaves" else it2 <- it
  if (it == "slaves_u16") next
  if (str_detect(it, "_cons$")) v <- wbp(wb2, ct, str_remove(it, "_cons$")) else v <- wbp(wb, ct, it2)
  if (length(v) == 1 && !is.na(v)) P2$price[i] <- v else P2$source[i] <- paste(P2$source[i], "(fallback P1)")
}
P3 <- P1 %>% mutate(spec = "P3") %>%
  mutate(price = ifelse(country == "Cape Colony" & item %in% c("horses", "cattle", "sheep"), ca[item], price),
         source = ifelse(country == "Cape Colony" & item %in% c("horses", "cattle", "sheep"), "own auction parse (D10)", source))
prices <- bind_rows(P1, P2, P3)
write_csv(prices, file.path(OUT, "prices_used.csv"))
saveRDS(prices, file.path(SCR, "prices.rds"))

cat("Households:", nrow(hh), " farmers:", sum(hh$farmer), "\n")
print(cape_auc)
print(prices %>% filter(spec == "P1"))
