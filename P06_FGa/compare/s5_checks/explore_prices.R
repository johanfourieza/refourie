suppressPackageStartupMessages({library(readxl)})
source("tools/paths.R")
f <- dpath("P06_FGa","original","20 FG Comparisons","Prices.xlsx")
print(excel_sheets(f))
print(as.data.frame(read_excel(f,"Final")))
for (s in excel_sheets(f)) { x <- suppressMessages(read_excel(f, s, col_names=FALSE, n_max=6)); cat("\n==", s, dim(x), "\n"); print(as.data.frame(x)[,1:min(10,ncol(x))]) }
