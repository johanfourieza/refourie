# P19_GF S3 independent recreation: 01_clean.R
# Builds the expenditure panel (Table 1 functional classes) and the public debt panel.
suppressPackageStartupMessages({library(readxl); library(dplyr); library(tidyr)})
source("./tools/paths.R")
set.seed(19)
pth <- dpath("P19_GF", "original", "colonial govt fiscal", "Abel Gwaindepi CC fiscal records.xlsx")
pth2 <- dpath("P19_GF", "original", "colonial govt fiscal", "colonialfiscal 18271909.xlsx")

e <- suppressMessages(read_excel(pth, sheet = "Expenditure", .name_repair = "minimal"))
names(e) <- make.unique(trimws(gsub("[[:space:]]+", " ", names(e))))
e <- e |> select(-starts_with("YEAR."), year = YEAR) |> mutate(across(everything(), as.numeric))

# Table 1 mapping (column names -> class). Ambiguities logged in decisions.md.
map <- list(
  hr   = c("Pensions","EducationNatives","Education Non- Natives","District Surgeons","Public Health",
           "Public Worship","Eastern Cape hospital and lepers","Somerset , old and new Hospital"),
  adm  = c("Colonial Secretary","The Governor","Crown Forests","Joint parliamentary expenses",
           "Transkeian territories","Rents, rates, insurance, gas , electric light","Headman & Chiefs Allowances"),
  mil  = c("Cape Town & frontier Mounted riflemen","Imperial Military Expr","Defence and Colonial Military allowance"),
  law  = c("Divisional Courts","Registrar of Deeds","High Sheriff","Superior Courts","Police and Gaol",
           "Convicts and Prisons","Robben Island"),
  debt = c("National Debt Servicing"),
  rail = c("Total Railways"),
  pwo  = c("Roads & Bridges","Works & Buildings","Conveyance of mails","Telegraph","Post Office",
           "Ports and Harbours","Customs","Mines","Surveyor General","Commissioner for public works"))
stopifnot(all(unlist(map) %in% names(e)))
s <- function(v) rowSums(e[v], na.rm = TRUE)
x <- tibble(year = e$year, total = e$`Total Expenditure`,
            hr = s(map$hr), adm = s(map$adm), mil = s(map$mil), law = s(map$law),
            debt = s(map$debt), rail = s(map$rail), pwo = s(map$pwo)) |>
  mutate(pw = rail + pwo, classified = hr + adm + mil + law + debt + pw, resid = total - classified)
# individual non-railway infrastructure items (for TX_p352_otherinfra)
items <- e |> select(year, all_of(map$pwo))

d <- suppressMessages(read_excel(pth, sheet = "Public Debt -Blue Books"))
names(d) <- c("year", "gdp", "gen_gov", "corp_boards", "pubdebt", "debt_serv")
d <- d |> mutate(across(everything(), as.numeric), debt_gdp = 100 * pubdebt / gdp)

f <- suppressMessages(read_excel(pth2, sheet = "fiscal"))
names(f) <- c("year", "revenue", "expenditure")
f <- f |> mutate(across(everything(), as.numeric), balance = revenue - expenditure)
# cross-check against the earlier version
chk <- max(abs(f$expenditure - x$total), na.rm = TRUE)
cat("max |expenditure(earlier) - Total Expenditure| =", chk, "\n")
cat("max |resid|/total =", max(abs(x$resid) / x$total, na.rm = TRUE), "\n")

sc <- dscratch("P19_GF", "repro_r", "panel.rds")
saveRDS(list(x = x, items = items, d = d, f = f), sc)
write.csv(x, here::here("P19_GF", "repro_r", "output", "expenditure_classes.csv"), row.names = FALSE)
write.csv(d, here::here("P19_GF", "repro_r", "output", "public_debt_gdp.csv"), row.names = FALSE)
