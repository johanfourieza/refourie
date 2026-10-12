# S5 check 7: variable labels for Table 6 variables; Table 5 purpose tabulation (category counts only)
suppressMessages({library(haven); library(dplyr)})
source(here::here("tools", "paths.R"))
od <- dpath("P13_FS", "original", "MOOC 8")
a <- read_dta(file.path(od, "DATA20141122.dta"), n_max = 5)
for (v in c("bond", "bond1", "ldebt", "ldebtin", "debt_value", "debt_infl", "year", "year_string", "end_year", "comp", "church", "wees", "both", "farmer", "married", "children", "quintile_wealth"))
  cat(v, ":", attr(a[[v]], "label"), "\n")
p <- zap_labels(read_dta(file.path(od, "PURPOSEDATA_20141117.dta")))
cat("purpose rows", nrow(p), "| value_debt nonNA", sum(!is.na(p$value_debt)), "| purpose_debt nonblank", sum(p$purpose_debt != "" & !is.na(p$purpose_debt)),
    "| purpose nonblank & value NA", sum(p$purpose_debt != "" & !is.na(p$purpose_debt) & is.na(p$value_debt)), "\n")
cat("debt rows by match:", paste(names(table(p$match[!is.na(p$value_debt)])), table(p$match[!is.na(p$value_debt)]), collapse = " "), "\n")
dr <- p[!is.na(p$value_debt) | (p$purpose_debt != "" & !is.na(p$purpose_debt)), ]
print(as.data.frame(dr |> count(category_debt, purpose_debt) |> arrange(category_debt, desc(n))), row.names = FALSE)
