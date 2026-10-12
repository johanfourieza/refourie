# S3 independent recreation, P02_BoF10: build annual series 1701-1793
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(here)})
source(here("tools","paths.R"))
b <- "./P02_BoF10/original/Boshoff Fourie Ships/"
rd <- function(f, s, skip = 0) suppressMessages(read_excel(paste0(b, f), sheet = s, col_names = FALSE, skip = skip))
num <- function(x) suppressWarnings(as.numeric(x))
bc <- "Business Cycle Cape Colony/"; vd <- "Business cycle 1652 - 1793/Van Duin en Ross.xls"

# ships: total ships calling (ships for eviews FROM 1652); shipdays alternative
sh <- rd(paste0(bc, "ships for eviews FROM 1652.xls"), 1, 1) |> transmute(year = num(...1), ships = num(...2))
sd <- rd(paste0(bc, "shipdays for eviews.xls"), "Sheet1", 1) |> transmute(year = num(...1), shipdays = num(...2))
by <- rd(paste0(bc, "Beyers (1929).xls"), "Data", 1) |> transmute(year = num(...1), ships_beyers = num(...3))

# Van Duin & Ross: agricultural production (cols: year, vines, wine, wheat sown, reaped, ...)
ag <- rd(vd, "Agricultural production", 3) |>
  transmute(year = num(...1), vines = num(...2), wine = num(...3), wheat_sown = num(...4), wheat_reaped = num(...5)) |>
  filter(!is.na(year), year >= 1701, year <= 1795)
cat_ <- rd(vd, "Livestock in possession", 2) |> transmute(year = num(...1), cattle = num(...3)) |> filter(!is.na(year))
ex <- rd(vd, "Exports of grains", 2) |> transmute(year = num(...1), wheat_exports = num(...2)) |> filter(!is.na(year))

# Brunt (2007) wheat: the WHEAT column of 'agricultural output data for eviews.xls'
br <- rd(paste0(bc, "agricultural output data for eviews.xls"), 1, 1) |> transmute(year = num(...1), wheat_brunt = num(...2))

d <- reduce(list(sh, sd, by, ag, cat_, ex, br), full_join, by = "year") |> filter(year >= 1701, year <= 1793) |> arrange(year)
d <- d |> distinct(year, .keep_all = TRUE)
cat("rows", nrow(d), "\n"); print(summary(d))
cat("cor reaped vs brunt:", cor(d$wheat_reaped, d$wheat_brunt, use = "complete.obs"), "\n")
cat("ships vs beyers diff:", sum(d$ships != d$ships_beyers, na.rm = TRUE), "\n")
print(d |> filter(year %in% c(1701, 1709, 1729, 1759, 1793)))
write_csv(d, dscratch("P02_BoF10", "repro_r", "series.csv"))
