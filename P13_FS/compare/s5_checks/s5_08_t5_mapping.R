# S5 check 8: Table 5 headline shares under a purpose-based mapping (classify by purpose_debt, not category_debt)
suppressMessages({library(haven); library(dplyr)})
source(here::here("tools", "paths.R"))
p <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "PURPOSEDATA_20141117.dta")))
cons <- c("Child Care", "Clothing and Shoes", "Food", "Funeral Expenses", "Household Expenditure", "Medical Expenses", "Wedding Expenses")
prod <- c("Agricultural Output", "Cattle", "Slaves", "Wages", "Working Capital")
mixd <- c("Accounts", "Auctions", "Taxes", "Wares", "Donations", "Inheritance")
landp <- c("Land", "Bond", "Bonds")
f <- function(dr, lab) {
  pd <- dr$purpose_debt; cg <- dr$category_debt
  land <- pd %in% landp | (pd == "Buildings/Real Estate" & cg != "General Purpose Given")
  co <- pd %in% cons | (pd == "Other" & cg == "Consumption")
  pr <- land | pd %in% prod | (pd == "Other" & cg == "Production")
  mx <- pd %in% mixd | (pd == "Other" & cg %in% c("Mixed", "."))
  spec <- co | pr | mx
  cat(sprintf("%-28s rows %5d | cons %4d land %4d bonds %4d inh %3d | specific %4d | cons%% %.2f land%% %.2f | land%%(base 4418) %.2f\n",
      lab, nrow(dr), sum(co), sum(land), sum(pd %in% c("Bond", "Bonds")), sum(pd == "Inheritance"), sum(spec), 100 * sum(co) / sum(spec), 100 * sum(land) / sum(spec), 100 * sum(land) / 4418))
  c(cons = 100 * sum(co) / sum(spec), land = 100 * sum(land) / sum(spec))
}
r1 <- f(p[!is.na(p$value_debt), ], "debt rows (value_debt)")
r2 <- f(p[!(p$purpose_debt %in% c(".", "")) | !is.na(p$value_debt), ], "debt rows or purpose given")
cat("blank-category consumption-purpose rows with value_debt:", sum(!is.na(p$value_debt) & p$category_debt == "." & p$purpose_debt %in% cons), "\n")
saveRDS(list(r1 = r1, r2 = r2), file.path(dscratch("P13_FS", "compare"), "s5_08.rds"))
