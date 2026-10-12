# Dump published values for T2-T9, F2 and text rows (compact) to aid the S5 consistency checks
library(readr)
d <- read_csv(here::here("P17_FvFH", "claims", "claims.csv"), show_col_types = FALSE)
x <- d[!grepl("^T1_|^T2_vdr_|^T2_cur_|^T5_", d$claim_id), ]
cat(paste0(x$claim_id, "=", x$reported_value, ifelse(x$headline == 1, "*", "")), sep = "; ")
