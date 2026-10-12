# S5 data check: the 1723/1757 sample-count gap between opgaafrolle.dta and published Table 2
library(readxl); library(haven); library(dplyr)
source(here::here("tools", "paths.R"))
root <- dpath("P17_FvFH", "original")
o <- read_dta(file.path(root, "Statafiles", "opgaafrolle.dta"))
cat("dta vars:", names(o), "\n")
for (y in c(1700, 1723, 1757)) { z <- o[o$jaar == y, ]
  cat(y, "rows", nrow(z), "dup rows", sum(duplicated(z)), "rows with NA in m:", sum(is.na(z$m)), "NA sm:", sum(is.na(z$sm)), "\n") }
f <- file.path(root, "Wealth inequality", "Time 1663 - 1757 ----  EDITED.xls")
sh <- excel_sheets(f); cat("xls sheets:", sh, "\n")
x <- suppressMessages(read_excel(f, sheet = 1)); cat("xls dims", dim(x), "\nnames:", head(names(x), 40), "\n")
yc <- names(x)[tolower(names(x)) %in% c("jaar","year")][1]
if (!is.na(yc)) for (y in c(1700, 1723, 1757)) { z <- x[x[[yc]] == y & !is.na(x[[yc]]), ]
  num <- intersect(c("M","V","S","D","K","SM","SV","SS","SD","m","v","s","d","k","sm","sv","ss","sd"), names(z))
  cat(y, "xls rows", nrow(z), ":", paste(num, colSums(sapply(z[num], as.numeric), na.rm = TRUE), collapse = " "), "\n") }
