# S5 (P08): rebuild the S3 (pair-B) person file with row_id kept, link it row-by-row to the
# authors' Augmented sheet. repro_r/01_clean.R is read and evaluated with three textual
# substitutions (scratch output dirs; keep row_id). repro_r/ is not modified.
# Output (D: scratch only): linked.rds. No names are written.
suppressMessages({library(tidyverse); library(readxl)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
SC <- dscratch("P08_SAC", "compare")
src <- readLines(file.path(PROJ, "P08_SAC/repro_r/01_clean.R"))
src <- sub('^OUT  <- .*$', 'OUT <- SC', src)
src <- sub('^SCR  <- .*$', 'SCR <- SC', src)
src <- sub('keep <- c("person_id",', 'keep <- c("row_id","person_id",', src, fixed = TRUE)
stopifnot(any(grepl('"row_id","person_id"', src)))
tmpf <- file.path(SC, "clean_mod.R"); writeLines(src, tmpf)
source(tmpf, local = new.env())
B <- readRDS(file.path(SC, "sac_terms.rds"))
# link Original rows -> Augmented rows on transcribed fields + occurrence index
X <- dpath("P08_SAC","original","FourieSAC2026","SAC final.xlsx")
o <- read_excel(X, sheet="Original", col_types="text") %>% mutate(row_id = row_number())
a <- read_excel(X, sheet="Augmented", col_types="text") %>% mutate(a_row = row_number())
fo <- c("Register","Surname","Names","IMG","Country","Age","Place","Date of birth","Weight","Origheight","Wage")
fa <- c("Register","Surname","Names","IMG","Country Origin","AgeOrigin","Place origin","Date of birth","WeightOrigin","Origheight","Wage origin")
mk <- function(df, f) do.call(paste, c(lapply(df[f], function(z) trimws(tolower(z))), sep="|"))
o$key <- mk(o, fo); a$key <- mk(a, fa)
for (j in seq_along(fo)) cat(fo[j], round(mean(trimws(tolower(a[[fa[j]]])) %in% trimws(tolower(o[[fo[j]]]))),4), "
")
o <- o %>% filter(row_id %in% B$row_id) %>% group_by(key) %>% mutate(occ = row_number()) %>% ungroup()
a <- a %>% group_by(key) %>% mutate(occ = row_number()) %>% ungroup()
lk <- inner_join(o %>% select(row_id, key, occ), a %>% select(a_row, key, occ), by = c("key","occ"))
cat("Augmented rows:", nrow(a), " linked:", nrow(lk), " unique a_row:", n_distinct(lk$a_row), "\n")
# authors' analysis variables (numeric)
num <- function(x) suppressWarnings(as.numeric(x))
av <- a %>% transmute(a_row, lwage_a = num(Lwage), wage_a = num(Wage), afr_a = num(Afrikaans), age_a = num(Age),
                      height_a = num(Height), weight_a = num(Weight), married_a = num(Married),
                      hisco_a = num(HISCO), hisco2_a = num(HISCO2), region_a = Region, regiondum_a = num(RegionDum),
                      eyear_a = num(EYear), repeatlast_a = num(Repeatlast), class_a = num(Class), farmer_a = num(Farmer))
L <- B %>% left_join(lk %>% select(row_id, a_row), by = "row_id") %>% left_join(av, by = "a_row")
saveRDS(L, file.path(SC, "linked.rds"))
saveRDS(av, file.path(SC, "augmented_vars.rds"))
cat("B rows:", nrow(B), " B rows linked:", sum(!is.na(L$a_row)), "\n")
