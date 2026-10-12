# P27_RW S5 verification checks (Claude auditor). Reads numbersandwealth.dta and frequency_equipment.dta only.
source("tools/paths.R")
library(haven); library(dplyr)
sf <- function(...) dpath("P27_RW", "original", "Data", "Statafiles", ...)
d  <- read_dta(sf("numbersandwealth.dta")) |> filter(!is.na(date))
cat("N =", nrow(d), "\n")
# 1. decade bins and the pre-1801 sample
print(d |> group_by(decade) |> summarise(n = n(), lo = min(date), hi = max(date), mean = mean(wealthrijks)))
cat("Total mean all 2577:", mean(d$wealthrijks), " pre-1801:", mean(d$wealthrijks[d$decade <= 1800]), "\n")
# 2. group (slave class) cut vs paper text (1-5, 6-15)
print(table(group = d$group, slaves = cut(d$slavesnumb, c(-1, 0, 4, 5, 15, 1e4))))
# 3. double entries: identical date and identical 28-item vector
items <- c("slavesnumb","beesten","paarden","schapen","ploeg","koornharp","schuijt","emmers","graaven","geweer",
           "brandewijnskeetels","waagen","aambeeld","bankschroef","balans","tang","stoven","kadels","stoel","broek",
           "strijkijsters","boeken","horlogie","snuijfdoos","schilderij","spiegel","vogelkooi","ring")
key <- do.call(paste, c(d[, c("date", items)], sep = "|"))
nz  <- rowSums(d[, items]) > 0
dup <- duplicated(key) & nz
cat("Exact duplicate non-empty rows (date + 28 items):", sum(dup), "; all-zero inventories:", sum(!nz), "\n")
cat("Total mean dropping dups (pre-1801):", mean(d$wealthrijks[!dup & d$decade <= 1800]), "\n")
# 4. bedsteads 1.12 and fishing boats 3%
b <- d$kadels
cat("bedsteads mean all:", mean(b), " pre-1801:", mean(b[d$decade <= 1800]), " sum:", sum(b),
    " implied N for 1.12:", sum(b) / 1.12, "\n")
cat("fishing boats owners:", sum(d$schuijt > 0), " share:", mean(d$schuijt > 0), "\n")
# 5. Table 7 timepieces, windows 1700-09 and 1710-22, by group
fe <- read_dta(sf("frequency_equipment.dta"))
tp <- d |> mutate(w = case_when(date >= 1700 & date <= 1709 ~ "1700_9", date >= 1710 & date <= 1722 ~ "1710_22")) |>
  filter(!is.na(w)) |> group_by(group, w) |> summarise(n = n(), pct = 100 * mean(horlogie > 0), .groups = "drop")
print(tp)
# 6. Representativeness reweighting: inventories vs opgaafrolle 1700-73 slave ownership
opg_zero <- (15587 - 6932) / 15587; inv_zero <- mean(d$slavesnumb == 0)
cat("zero-slave share: opgaaf", opg_zero, " inventories", inv_zero, "\n")
d <- d |> mutate(wt = ifelse(slavesnumb == 0, opg_zero / inv_zero, (1 - opg_zero) / (1 - inv_zero)))
# group-level reweighting to the opgaaf slave-class distribution is not possible (opgaaf class shares not in dta here); use 0/positive split
p <- d |> filter(decade <= 1800)
rw <- c(T5_total_mean = weighted.mean(p$wealthrijks, p$wt),
        T5_1700_mean  = weighted.mean(p$wealthrijks[p$decade == 1700], p$wt[p$decade == 1700]),
        T5_1790_mean  = weighted.mean(p$wealthrijks[p$decade == 1790], p$wt[p$decade == 1790]))
print(rw)
# 7. Wealth excluding slaves (slaves valued at median 1691-1748 price; dominant item)
ns <- p |> mutate(ns = wealthrijks - slawerijks) |> group_by(decade) |> summarise(mean_ns = mean(ns), share_slaves = sum(slawerijks) / sum(wealthrijks))
print(ns); cat("no-slave total mean:", mean(p$wealthrijks - p$slawerijks), "\n")
# 8. Units: text "just above 1,000 stuivers" = rijksdaalders?
cat("1700-30 mean rd:", mean(p$wealthrijks[p$date <= 1730]), " in stuivers:", 48 * mean(p$wealthrijks[p$date <= 1730]), "\n")
out <- data.frame(check = c("pre1801_mean", "dedup_mean", "rw_total", "rw_1700", "rw_1790", "noslave_total"),
                  value = c(mean(p$wealthrijks), mean(d$wealthrijks[!dup & d$decade <= 1800]), rw, mean(p$wealthrijks - p$slawerijks)))
write.csv(out, dscratch("P27_RW", "compare", "s5_checks_out.csv"), row.names = FALSE)
