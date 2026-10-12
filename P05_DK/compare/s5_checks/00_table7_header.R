# S5 check: column layout of 1936 census Table 7 (European ages); header rows only (published aggregate table).
suppressMessages(library(readxl)); source(file.path("tools", "paths.R"))
f <- dpath("P05_DK", "original", "Spanish_flu_group_folder", "data", "original", "census", "census1936",
           "Table 7; Ages in years of Europeans, by gender, at MD level..xlsx")
x <- read_excel(f, col_names = FALSE, col_types = "text", .name_repair = "minimal")
print(dim(x))
for (i in 1:6) cat(i, ":", paste(seq_len(ncol(x)), ifelse(is.na(unlist(x[i, ])), ".", unlist(x[i, ])), sep = "=", collapse = " | "), "\n")
