# P15_FvZ S3 recreation -- 01_clean.R
# Read raw allow-listed inputs and write tidy annual series to repro_r/output/clean_*.csv
suppressPackageStartupMessages({library(tidyverse); library(readxl)})

args <- commandArgs(FALSE)
this <- normalizePath(sub("--file=", "", args[grep("--file=", args)]))
root <- dirname(dirname(this))                      # .../P15_FvZ
out  <- file.path(root, "repro_r", "output"); dir.create(out, showWarnings = FALSE)
source(file.path(root, "..", "tools", "paths.R")); vdr <- dpath("P15_FvZ", "original", "Data", "Van Duin en Ross.xlsx")
fvz  <- dpath("P15_FvZ", "original", "Fourie Van Zanden")

num <- function(x) suppressWarnings(as.numeric(ifelse(toupper(trimws(x)) == "NIL", "0", x)))
rd  <- function(sheet, path = vdr) suppressMessages(read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text"))
yrs <- 1701:1795

# ---- Population (VDR) ----
p <- rd("Population")[4:98, 1:10]
names(p) <- c("year","men","women","boys","girls","kn","slm","slw","slb","slg")
pop <- p %>% mutate(across(everything(), num)) %>% filter(!is.na(year))

# ---- Company establishment ----
ce <- rd("Company establishment")[3:95, 1:2]; names(ce) <- c("year","voc_est")
ce <- ce %>% mutate(across(everything(), num))

# ---- Agricultural production ----
ag <- rd("Agricultural production")[4:98, 1:9]
names(ag) <- c("year","vines","wine_leggers","wheat_sown","wheat_reaped","barley_sown","barley_reaped","rye_sown","rye_reaped")
ag <- ag %>% mutate(across(everything(), num))

# ---- Wheat correction coefficient (5-yr periods) ----
cc <- rd("Production or wheat")[4:20, 1:2]; names(cc) <- c("period","coef")
cc <- cc %>% mutate(start = as.integer(substr(period, 1, 4)), coef = num(coef))
coef_yr <- tibble(year = yrs) %>%
  mutate(coef = map_dbl(year, function(y) { i <- max(c(1, which(cc$start <= y))); cc$coef[i] }))

# ---- Cape Town internal wheat market (5-yr averages; /2.5 = Cape Town pop) ----
cw <- rd("Consumption of wheat")[4:21, 1:5]; names(cw) <- c("period","internal","ships","exports","total")
cw <- cw %>% mutate(start = as.integer(substr(period, 1, 4)), mid = start + 2,
                    internal = num(internal), ct_pop = internal / 2.5)

# ---- Livestock ----
ls <- rd("Livestock in possession")[3:97, 1:5]; names(ls) <- c("year","horses","cattle","sheep","pigs")
ls <- ls %>% mutate(across(everything(), num))

# ---- Meat prices ----
mp <- rd("Prices of meat supplied")[3:95, 1:3]; names(mp) <- c("year","pond_duiten","sheep_stuivers")
mp <- mp %>% mutate(across(everything(), num))

# ---- Wages ----
wg <- rd("The payment of wages (guilders)")
wg <- tibble(year = num(wg[[1]][2:80]), actual = num(wg[[2]][2:80]), nominal = num(wg[[3]][2:80]))

# ---- Wissels ----
ws <- rd("Wissel transfers from the Cape")[3:94, 1:2]; names(ws) <- c("year","wissel")
ws <- ws %>% mutate(across(everything(), num))

# ---- Gross receipts from VOC sales ----
gr <- rd("Gross receipts from VOC sales")[3:31, 1:2]; names(gr) <- c("year","receipts")
gr <- gr %>% mutate(across(everything(), num))

# ---- Exports by value ----
ev <- rd("Exports in money value")[4:48, 1:6]; names(ev) <- c("year","exp_total","exp_grain_val","exp_wine_val","exp_stock_val","exp_other_val")
ev <- ev %>% mutate(across(everything(), num))

# ---- Export quantities ----
eg <- rd("Exports of grains")[3:90, 1:2]; names(eg) <- c("year","exp_grain_mud")
eg <- eg %>% mutate(exp_grain_na = toupper(trimws(exp_grain_mud)) == "N.A.", across(c(year, exp_grain_mud), num))
epb <- rd("Exports of peas and beans")[3:56, 1:2]; names(epb) <- c("year","exp_peas_mud")
epb <- epb %>% mutate(across(everything(), num)) %>% filter(!is.na(year))
ewi <- rd("Exports of wines")[3:48, 1:2]; names(ewi) <- c("year","exp_wine_aam")
ewi <- ewi %>% mutate(across(everything(), num))

# ---- Ships (Verwerk.xls) ----
vw <- file.path(fvz, "Verwerk.xls")
dutch <- suppressMessages(read_excel(vw, sheet = "Gem dae per besoek", col_names = FALSE, col_types = "text"))
dutch <- tibble(year = num(dutch[[1]]), n_dutch = num(dutch[[3]])) %>% filter(!is.na(year))
nond  <- suppressMessages(read_excel(vw, sheet = "Totale skepe", col_names = FALSE, col_types = "text"))
nond  <- tibble(year = num(nond[[1]]), n_nondutch = num(nond[[3]]), shipdays = num(nond[[6]])) %>% filter(!is.na(year))
ships <- full_join(dutch, nond, by = "year") %>% mutate(n_nondutch = replace_na(n_nondutch, 0),
                                                         ships = n_dutch + n_nondutch)

# ---- Slave prices (period medians) ----
sp <- suppressMessages(read_excel(file.path(fvz, "Slave prices.xlsx"), col_names = FALSE, col_types = "text"))[2:14, 1:2]
names(sp) <- c("period","price_rds")
sp <- sp %>% mutate(start = as.integer(substr(period, 1, 4)), end = as.integer(substr(period, 6, 9)), price_rds = num(price_rds))
slave_price <- tibble(year = yrs) %>%
  mutate(price_rds = map_dbl(year, function(y) { i <- max(which(sp$start <= y)); sp$price_rds[i] }))

# ---- Assemble annual frame ----
d <- tibble(year = yrs) %>%
  left_join(pop, by = "year") %>% left_join(ce, by = "year") %>% left_join(ag, by = "year") %>%
  left_join(coef_yr, by = "year") %>% left_join(ls, by = "year") %>% left_join(mp, by = "year") %>%
  left_join(wg, by = "year") %>% left_join(ws, by = "year") %>% left_join(gr, by = "year") %>%
  left_join(ev, by = "year") %>% left_join(eg, by = "year") %>% left_join(epb, by = "year") %>%
  left_join(ewi, by = "year") %>% left_join(ships, by = "year") %>% left_join(slave_price, by = "year")

# Outlier (typo) rule set in decisions.md: value deviating >40% from the centred
# 5-year median of the ORIGINAL series is replaced by that median (revised pre-results, see decisions.md)
fix_log <- list()
fix_outliers <- function(df, cols) {
  for (cl in cols) {
    x0 <- df[[cl]]; x <- x0; n <- length(x)
    for (i in 3:(n - 2)) {
      w <- x0[(i - 2):(i + 2)]
      if (is.na(x0[i]) || sum(!is.na(w)) < 4) next
      m <- median(w, na.rm = TRUE)
      if (m > 0 && abs(x0[i] - m) / m > 0.40) {
        fix_log[[length(fix_log) + 1]] <<- tibble(var = cl, year = df$year[i], old = x0[i], new = m)
        x[i] <- m
      }
    }
    df[[cl]] <- x
  }
  df
}
d <- fix_outliers(d, c("men","women","boys","girls","slm","slw","slb","slg","cattle","sheep","horses","voc_est"))

# Interpolate missing interior years (rule = 2 holds ends)
interp <- function(x, y = yrs) { ok <- !is.na(x); if (sum(ok) < 2) return(x); approx(y[ok], x[ok], xout = y, rule = 2)$y }
d <- d %>% mutate(across(c(men, women, boys, girls, kn, slm, slw, voc_est, vines, wine_leggers,
                           wheat_sown, wheat_reaped, cattle, sheep, horses, wissel), interp))
# Barley/rye: "-" entries (1782-89) are treated as zero; NOT AVAILABLE years interpolated
d <- d %>% mutate(across(c(barley_sown, barley_reaped, rye_sown, rye_reaped), ~ ifelse(year %in% c(1781, 1794), NA, replace_na(.x, 0)))) %>%
  mutate(across(c(barley_sown, barley_reaped, rye_sown, rye_reaped), interp))
# Slave children 1795 missing: use 1793 child share of adult slaves
cs <- with(filter(d, year == 1793), (slb + slg) / (slm + slw))
d <- d %>% mutate(slb = ifelse(year == 1795, cs / 2 * (slm + slw), slb),
                  slg = ifelse(year == 1795, cs / 2 * (slm + slw), slg)) %>%
  mutate(across(c(slb, slg), interp))

# Cape Town population: midpoints of VDR 5-year periods, linear; constant share of total outside
ct <- cw %>% select(mid, ct_pop)
d$ct_pop_raw <- ifelse(d$year >= min(ct$mid) & d$year <= max(ct$mid), approx(ct$mid, ct$ct_pop, xout = d$year)$y, NA)

# Khoesan (TYPED from paper Fig. 1 digitised values; see decisions.md)
claims <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)
kh <- claims %>% filter(str_detect(claim_id, "^F1_\\d{4}_khoesan$")) %>%
  transmute(year = as.integer(str_extract(claim_id, "\\d{4}")), khoesan = reported_value)
d$khoesan <- approx(kh$year, kh$khoesan, xout = d$year, rule = 2)$y

write_csv(d, file.path(out, "clean_annual.csv"))
write_csv(bind_rows(fix_log), file.path(out, "outlier_fixes.csv"))
write_csv(cw, file.path(out, "clean_capetown_wheat.csv"))
cat("01_clean.R done:", nrow(d), "years;", length(fix_log), "outlier fixes\n")
