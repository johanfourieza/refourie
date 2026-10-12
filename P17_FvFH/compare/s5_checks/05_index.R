# S5: does the authors' price index explain the x1.3 factor (slaves 40->52, knechts 156->204 in "1700 prices")?
library(tidyxl); library(dplyr); source(here::here("tools", "paths.R"))
f <- file.path(dpath("P17_FvFH", "original"), "Income inequality", "December price data in excel.xlsx")
c <- xlsx_cells(f)
hd <- c %>% filter(data_type == "character", grepl("index", character, ignore.case = TRUE)) %>% select(sheet, row, col, character)
print(head(hd, 20))
yr <- c %>% filter(numeric %in% c(1700, 1717, 1723, 1724, 1756, 1757), col <= 2) %>% select(sheet, row, yr = numeric)
for (i in seq_len(min(nrow(hd), 8))) { h <- hd[i, ]
  vals <- c %>% filter(sheet == h$sheet, col == h$col) %>% inner_join(filter(yr, sheet == h$sheet), by = c("sheet", "row")) %>% select(yr, numeric)
  if (nrow(vals)) { cat("==", h$sheet, "|", h$character, "\n"); print(as.data.frame(vals)) } }
