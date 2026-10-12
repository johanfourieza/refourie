# S5 check 1: stored estimation markers and candidate debt variables in DATA20141122.dta (aggregates only)
suppressMessages({library(haven); library(dplyr)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
cat(grep("est|debt|lnd|infl|inher|wealth|pca|pc1|perc|child|age|farm|slave|sheep|cattle|horse", names(a), value = TRUE, ignore.case = TRUE), "\n")
for (e in grep("^_est", names(a), value = TRUE)) {
  m <- a[[e]] == 1 & !is.na(a[[e]])
  cat(e, "N =", sum(m), " match1 =", sum(m & a$match == 1, na.rm=TRUE), " debt>0 =", sum(m & a$debt_value > 0, na.rm=TRUE),
      " year range", range(a$year[m], na.rm=TRUE), " children nonmiss", sum(m & !is.na(a$children)), "\n")
}
