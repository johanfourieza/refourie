# P17_FvFH S3 recreation -- 01_clean.R: load the allow-listed sources and build the inputs
library(tidyverse); library(readxl); library(haven); library(here)
source(here::here("tools", "paths.R"))
set.seed(1)
root <- dpath("P17_FvFH", "original")
scr <- dscratch("P17_FvFH", "repro_r")
rd <- function(f, s) suppressMessages(read_excel(file.path(root, f), sheet = s, col_names = FALSE, .name_repair = "minimal"))

# opgaafrolle (cleaned): sample counts by category and year
o <- read_dta(file.path(root, "Statafiles", "opgaafrolle.dta"))
cur <- o %>% filter(jaar %in% c(1700, 1702, 1723, 1757)) %>% group_by(year = jaar) %>%
  summarise(adult_males = sum(m, na.rm = TRUE), adult_females = sum(v, na.rm = TRUE),
            boys = sum(s, na.rm = TRUE), girls = sum(d, na.rm = TRUE), knecht = sum(k, na.rm = TRUE),
            male_slave = sum(sm, na.rm = TRUE), female_slave = sum(sv, na.rm = TRUE),
            boy_slave = sum(ss, na.rm = TRUE), girl_slave = sum(sd, na.rm = TRUE), .groups = "drop") %>%
  mutate(burgher_total = adult_males + adult_females + boys + girls,
         slave_total_burgher = male_slave + female_slave + boy_slave + girl_slave,
         voc_slaves = 0)  # the opgaafrolle contain no VOC-owned slaves by construction

# Van Duin & Ross population sheet (rows for the table years)
p <- rd("Income inequality/Van Duin en Ross.xlsx", "Population")
pp <- p[p[[1]] %in% c("1702", "1723", "1757"), 1:10]
names(pp) <- c("year", "adult_males", "adult_females", "boys", "girls", "knecht", "male_slave", "female_slave", "boy_slave", "girl_slave")
vdr <- pp %>% mutate(across(everything(), as.numeric)) %>%
  mutate(burgher_total = adult_males + adult_females + boys + girls,
         slave_total_burgher = male_slave + female_slave + boy_slave + girl_slave)

# Company establishment (VOC employees), for T3 vdr counts
ce <- rd("Income inequality/Van Duin en Ross.xlsx", "Company establishment")
ce <- ce %>% setNames(c("year", "n")) %>% mutate(across(everything(), as.numeric)) %>% filter(!is.na(year))

# Prices: authors' documented price plan (Summary workbook, Burghers sheet)
b <- rd("Income inequality/Summary of data sources conversions and calculations.xlsx", "Burghers")
pc <- which(grepl("^Price", as.character(unlist(b[1, ]))))[1]
pr <- tibble(year = as.numeric(b[[1]][2:25]), unit = b[[2]][2:25], price = as.numeric(b[[pc]][2:25]))
saveRDS(list(cur = cur, vdr = vdr, ce = ce, pr = pr), file.path(scr, "clean.rds"))
