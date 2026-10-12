# P03_BoF17 S3 recreation: 01_clean.R -- build monthly town x product panel (raw sheet) and annual SA/UK wheat series
suppressMessages({library(readxl); library(dplyr); library(tidyr); library(here)})
source(here::here("tools", "paths.R")); set.seed(1)
rd <- function(...) suppressMessages(read_excel(..., col_names = FALSE, .name_repair = "minimal"))
scr <- dscratch("P03_BoF17", "repro_r")

## ---- Monthly prices, raw sheet 'South Africa_original' ----
agr <- dpath("P03_BoF17", "original", "Boshoff Fourie", "AgrPriceData 1.3.xlsx")
d <- rd(agr, "South Africa_original")
hdr <- as.character(unlist(d[6, ]))
pc <- which(hdr == "£"); stopifnot(length(pc) > 100)
pc <- pc[hdr[pc + 1] == "s" & hdr[pc + 2] == "d"]
yr <- suppressWarnings(as.numeric(unlist(d[3, pc])))
mon <- sapply(as.character(unlist(d[4, pc])), function(s) { m <- regmatches(s, regexpr("[A-Za-z]+", s)); if (length(m)) match(substr(tolower(m), 1, 3), tolower(month.abb)) else NA })
body <- d[7:nrow(d), ]
town <- as.character(body[[1]]); prod <- as.character(body[[2]])
num <- function(x) { x <- trimws(as.character(x)); suppressWarnings(as.numeric(ifelse(x %in% c(".", ""), NA, x))) }
long <- lapply(seq_along(pc), function(k) {
  a <- num(body[[pc[k]]]); s <- num(body[[pc[k] + 1]]); p <- num(body[[pc[k] + 2]])
  any_ok <- !(is.na(a) & is.na(s) & is.na(p))
  pence <- ifelse(any_ok, 240 * coalesce(a, 0) + 12 * coalesce(s, 0) + coalesce(p, 0), NA)
  tibble(town, product = prod, year = yr[k], month = unname(mon[k]), pence)
}) |> bind_rows() |>
  filter(!is.na(town), town != "Town", !is.na(year), !is.na(month), !is.na(pence), pence > 0)
cat("issues parsed:", length(pc), "; obs:", nrow(long), "; missing month:", sum(is.na(mon)), "\n")
panel <- long |> group_by(town, product, year, month) |> summarise(price = mean(pence), nraw = n(), .groups = "drop")
saveRDS(panel, file.path(scr, "panel_raw.rds"))

## ---- Annual wheat series, Figure 2 ----
g <- dpath("P03_BoF17", "original", "Boshoff Fourie Globalisation", "Globalisation data.xlsx")
x <- rd(g, "Original 102 cities data")
uk <- c("London","Dover","Exeter","Gloucester","Worcester","Cambridge","Norwich","Leeds","Liverpool","Manchester","Newcastle","Carmarthen")
cities <- as.character(unlist(x[3, ])); i0 <- which(cities == "London")
stopifnot(identical(cities[i0:(i0 + 11)], uk))
yrs <- suppressWarnings(as.numeric(unlist(x[5:nrow(x), 2]))); yrs <- zoo::na.locf(yrs, na.rm = FALSE)  # year printed at month 1 only
ukm <- as.data.frame(lapply(x[5:nrow(x), i0:(i0 + 11)], num)); names(ukm) <- uk
ukm$year <- yrs
ukann <- ukm |> filter(!is.na(year)) |> group_by(year) |> summarise(across(all_of(uk), ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE)), .groups = "drop")
ukann$uk_mean_level <- rowMeans(ukann[uk], na.rm = FALSE)          # equal weight, complete cities only
ukann$uk_mean_log <- rowMeans(log(ukann[uk]), na.rm = FALSE)
ukann$ln_uk <- log(ukann$uk_mean_level)
sa <- rd(g, "RSA wheat price data (logged)")[-1, 1:3]; names(sa) <- c("year", "ln_sa_capenatal", "ln_sa_cape")
sa <- sa |> mutate(across(everything(), num)) |> filter(!is.na(year))
ann <- inner_join(sa, ukann |> select(year, ln_uk, uk_mean_log), by = "year")
saveRDS(ann, file.path(scr, "annual.rds")); print(summary(ann$year)); print(sum(complete.cases(ann)))
