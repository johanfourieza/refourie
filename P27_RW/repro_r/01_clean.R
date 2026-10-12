# 01_clean.R -- P27_RW independent recreation: build analysis data (inventories, opgaafrolle 1700-73)
suppressMessages({library(haven); library(readxl); library(dplyr)})
source("tools/paths.R")
set.seed(27)
raw <- dpath("P27_RW", "original", "Data")
scr <- dscratch("P27_RW", "repro_r")

b <- read_dta(file.path(raw, "Statafiles", "numbersandwealth.dta"))
inv <- b %>% filter(!is.na(date)) %>%               # the 2,577 dated inventories (867 rows undated/blank)
  transmute(inv, date, decade, group, stb,
            slaves = slavesnumb, cattle = beesten, horses = paarden, sheep = schapen,
            ploughs = ploeg, corn_sieves = koornharp, fishing_boats = schuijt, buckets = emmers,
            spades = graaven, guns = geweer, brandy_stills = brandewijnskeetels, wagons = waagen,
            anvils = aambeeld, bench_vices = bankschroef, balances = balans, fire_tongs = tang,
            ovens = stoven, bedsteads = kadels, chairs = stoel, trousers = broek, irons = strijkijsters,
            books = boeken, timepieces = horlogie, snuff_boxes = snuijfdoos, paintings = schilderij,
            mirrors = spiegel, bird_cages = vogelkooi, gold_rings = ring,
            wealth = wealthrijks)
stopifnot(nrow(inv) == 2577)

o <- suppressMessages(read_excel(file.path(raw, "Opgaafrolle 1 Des 2010.xlsx"), sheet = "Data", .name_repair = "minimal"))
o <- o[!is.na(o$Jaar) & o$Jaar >= 1700 & o$Jaar <= 1773, ]
num <- function(j) { v <- suppressWarnings(as.numeric(unlist(o[, j]))); v[is.na(v)] <- 0; v }
# columns by header: SM,SV,SS,SD (slave men/women/sons/daughters; 2nd of each pair), PD horses, BSTE cattle, SKPE sheep
opg <- data.frame(year = o$Jaar, slaves = num(34) + num(36) + num(38) + num(40),
                  horses = num(42), cattle = num(44), sheep = num(46))
saveRDS(list(inv = inv, opg = opg), file.path(scr, "clean.rds"))
cat("inventories", nrow(inv), " opgaafrolle households", nrow(opg), "\n")
