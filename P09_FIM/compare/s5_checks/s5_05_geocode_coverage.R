# P09_FIM S5 check 5 (Claude). Pair-B gap: does geocode coverage of place of birth explain the
# SAC/CMP/WWI count excess (rebuild 155/446/2641 vs published 91/358/2557)? Counts only.
suppressPackageStartupMessages({ library(tidyverse); library(readxl) })
root <- here::here()
source(file.path(root, "tools", "paths.R"))
out <- file.path(root, "P09_FIM", "compare", "s5_checks")
src <- dpath("P09_FIM", "original", "FM White living standards")
num <- function(v) suppressWarnings(as.numeric(v))
g <- read_excel(file.path(src, "Geocodes.xlsx"), col_types = "text") %>%
  transmute(pob = str_to_lower(str_squish(placeofbirth)), lon = num(Longitude)) %>% filter(!is.na(pob))
D <- read_excel(file.path(src, "Whitelivingstandards_7July.xlsx"), sheet = "Data", col_types = "text")
sa <- c("Western Cape", "Eastern Cape", "Northern Cape", "Natal", "Orange Free State", "Transvaal")
d <- D %>% transmute(force = Source, pob = str_to_lower(str_squish(`Place of birth`)), region = Region,
                     year = num(Year), age = num(Age), by = num(Birthyear), h = num(Height), rep = num(Repeat),
                     black = num(Black), nat = num(Nationalitydum), urban = num(Urban)) %>%
  filter(region %in% sa, is.na(rep) | rep != 1, between(year, 1890, 1945), between(by, 1865, 1920),
         age > 20, age < 50, !is.na(h), !is.na(urban),
         if_else(force == "WWI", nat == 4, is.na(black) | black == 0)) %>%
  mutate(geocoded = pob %in% g$pob[!is.na(g$lon)], cohort = cut(by, c(1864, 1874, 1884, 1894), labels = c("c1", "c2", "c3")))
res <- d %>% group_by(force) %>% summarise(n = n(), geocoded = sum(geocoded), .groups = "drop") %>%
  mutate(published = c(AOF = 289, CMP = 358, SAC = 91, WWI = 2557)[force])
res_c <- d %>% filter(geocoded) %>% count(force, cohort)
write_csv(res, file.path(out, "s5_geocode_coverage.csv")); write_csv(res_c, file.path(out, "s5_geocode_coverage_cohort.csv"))
print(res); print(res_c)
