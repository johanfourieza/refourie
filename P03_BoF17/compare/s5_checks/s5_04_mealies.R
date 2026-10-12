# S5 check 4: do the Mealies analysis workings reproduce the published Table 1 mealies column?
suppressMessages({library(readxl); library(dplyr)})
source("tools/paths.R")
mea <- dpath("P03_BoF17","original","Boshoff Fourie","Mealies analysis.xlsx")
pub <- read.csv("P03_BoF17/claims/claims.csv") |> filter(grepl("^T1_r[0-9]+_c2$", claim_id)) |>
  transmute(claim_id, town = trimws(gsub("T1 row | col.*", "", location)), pub = reported_value, pub_se = reported_se)
nm <- function(x) tolower(gsub("[^a-z]", "", tolower(x)))
res <- list()
for (sn in c("difflogs","difflogs+seas")) {
  d <- read_excel(mea, sheet = sn) |> suppressMessages()
  cat("##", sn, "dims", dim(d), "first cols:", paste(head(names(d), 4), collapse=","), "\n")
  num <- as.data.frame(lapply(d[,-1], function(v) suppressWarnings(as.numeric(v)))); names(num) <- names(d)[-1]; cat("cols:", paste(names(num), collapse=" "), "
"); ct <- grep("cape", names(num), ignore.case = TRUE)[1]
  for (j in setdiff(seq_along(num), ct)) { ok <- complete.cases(num[[ct]], num[[j]]); if (sum(ok) < 5) next
    r <- cor(num[[ct]][ok], num[[j]][ok]); res[[length(res)+1]] <- data.frame(sheet = sn, key = nm(sub("^RESID","",names(num)[j])), r = r, n = sum(ok), se = sqrt((1-r^2)/(sum(ok)-2))) }
}
res <- bind_rows(res); pub$key <- nm(pub$town); pub$key[pub$key=="burgersdorp"] <- "burghersdorp"
m <- left_join(pub, res, by = "key", relationship = "many-to-many") |> select(town, sheet, pub, r, pub_se, se, n)
print(m, digits = 2)
m |> group_by(sheet) |> summarise(n_cells = sum(!is.na(r)), cor_with_pub = cor(pub, r, use = "complete"), mad = mean(abs(pub - r), na.rm = TRUE)) |> print()
