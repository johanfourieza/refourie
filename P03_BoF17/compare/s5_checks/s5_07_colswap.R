# S5 check 7: is any published Table 1 column a mislabelled/shifted copy of another product or row order? (4x4 column cross-correlation)
suppressMessages({library(dplyr); library(tidyr)})
cl <- read.csv("P03_BoF17/claims/claims.csv") |> filter(grepl("^T1_", claim_id)) |> transmute(claim_id, pub = reported_value)
rb <- read.csv("P03_BoF17/repro_r/output/table1_recreated.csv") |> left_join(cl, by = "claim_id") |> mutate(row = as.integer(gsub("T1_r|_c.*", "", claim_id)))
P <- rb |> select(row, product, pub) |> pivot_wider(names_from = product, values_from = pub) |> arrange(row)
R <- rb |> select(row, product, r) |> pivot_wider(names_from = product, values_from = r) |> arrange(row)
m <- cor(P[,-1], R[,-1]); dimnames(m) <- list(paste0("pub_", colnames(P)[-1]), paste0("rb_", colnames(R)[-1])); print(round(m, 2))
# row shift by one (alphabetical misalignment)?
for (s in c(-1, 1)) { cat("shift", s, ":", round(sapply(colnames(P)[-1], function(p) { x <- P[[p]]; y <- R[[p]]; i <- seq_along(x); j <- i + s; ok <- j >= 1 & j <= length(y); cor(x[ok], y[j[ok]]) }), 2), "\n") }
