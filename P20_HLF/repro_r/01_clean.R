# P20_HLF S3 recreation, step 1: build inputs.
# Inputs = (i) 1911 census population (file), (ii) quantities printed in the paper's tables/text.
# The 1905 Report of the General Manager scan and the carting-price sample were NOT read/recovered:
# printed values stand in for them (arithmetic re-derivation, conditional on printed inputs).
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(here)})
source(here("tools", "paths.R"))
set.seed(20)
sc <- dscratch("P20_HLF", "repro_r")
f  <- dpath("P20_HLF", "original", "Fourie Herranz", "Population numbers 1911 census.xlsx")
x  <- suppressMessages(read_excel(f, col_names = FALSE))
# row 9 = Union, row 12 = Cape of Good Hope; age-group columns 4:59 (columns 60+ empty)
pop <- tibble(area = c("South Africa", "Cape"),
              pop1911 = c(sum(as.numeric(unlist(x[9, 4:59])), na.rm = TRUE),
                          sum(as.numeric(unlist(x[12, 4:59])), na.rm = TRUE)))
stopifnot(pop$pop1911[1] > 5.9e6, pop$pop1911[1] < 6.0e6)

# printed inputs (paper tables 1,3,5,7,8 and text p.9-10)
inp <- list(
  km = c(Cape = 5621, `South Africa` = 12552),
  t3 = c(a = 361.03, b = 0.0065, d = 361.03, e = 0.0204),
  t5 = list(a = c(`1` = 70.771, `23` = 253.710), b = c(`1` = 0.0058, `23` = 0.0032),
            d = c(`1` = 0.0523, `23` = 0.0214), e = c(`1` = 17.13, `23` = 17.13),
            i1 = 0.029, k = c(`1` = 7, `23` = 2)),
  t7 = c(cap = 29.973, e = 0.367, f = 1.073, r = 0.037, dep_lo = 0.017, dep_hi = 0.02),
  t8 = c(b = 25.612, d = 4.06, e = 3.84, g = 2.21),
  elast = c(freight_lo = 0.5, freight_hi = 0.8, first = 1, second_third = 0),
  gdp_pct_printed = 12.01, ss_printed = 5.042)
# carting-price observations printed in the text (GBP of 1905 per ton-mile; distance in miles)
road <- tribble(~obs, ~dist, ~price, ~source,
  "Bloemfontein-Kimberley", 100, 0.031, "price diff",
  "Bloemfontein-Johannesburg", 250, 0.026, "price diff",
  "Kimberley-Johannesburg", 300, 0.014, "price diff",
  "Port Elizabeth-Grahamstown", 80, 0.033, "direct",
  "Robertson-Worcester", 30, 0.024, "direct",
  "Port Elizabeth-Humansdorp", 54, 0.026, "direct",
  "East London-Elliot", 155, 0.013, "direct")
dir.create(here("P20_HLF", "repro_r", "output"), showWarnings = FALSE)
write_csv(pop, here("P20_HLF", "repro_r", "output", "pop1911.csv"))
write_csv(road, here("P20_HLF", "repro_r", "output", "road_obs.csv"))
