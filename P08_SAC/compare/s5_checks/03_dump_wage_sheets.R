# S5 (P08): print the regression-output sheets of Descriptives.xlsx (aggregate output only)
suppressMessages(library(readxl))
X <- "./P08_SAC/original/FGM The SAC/Descriptives.xlsx"
print(excel_sheets(X))
for (s in grep("[Ww]age|Oaxaca", excel_sheets(X), value = TRUE)) {
  cat("=====", s, "\n"); d <- read_excel(X, sheet = s, col_names = FALSE, col_types = "text"); d[is.na(d)] <- ""
  print(as.data.frame(d)[1:min(60, nrow(d)), 1:min(9, ncol(d))], right = FALSE) }
