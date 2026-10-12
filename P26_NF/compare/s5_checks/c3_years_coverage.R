# S5 check 3: (a) which published year each rebuild sheet's roll total matches; (b) 1909-dictionary coverage by division-year;
# (c) whether a loose (substring) Excel-style match reproduces published black counts. Reads the rebuild's scratch rds (read-only).
suppressMessages({library(tidyverse); library(here)})
source(here::here("tools", "paths.R"))
scr <- dscratch("P26_NF", "repro_r")
r09 <- readRDS(file.path(scr, "r09.rds")); yr <- readRDS(file.path(scr, "yr.rds"))
cl <- read_csv(here::here("P26_NF", "claims", "claims.csv"), show_col_types = FALSE) |> filter(str_detect(claim_id, "^T[12]_")) |>
  separate(claim_id, c("t", "div", "year"), sep = "_") |> mutate(v = as.numeric(reported_value)) |> select(t, div, year, v) |>
  pivot_wider(names_from = t, values_from = v) |> mutate(ptot = T1 + T2)
blk <- unique(r09$key[r09$race %in% c("K","F","I","B") & r09$key != ""]); all09 <- unique(r09$key[r09$key != ""])
blk3 <- blk[nchar(blk) >= 4]
loose <- function(k) vapply(k, function(x) any(startsWith(x, blk3)) || x %in% blk, logical(1))
g <- yr |> filter(!is.na(division)) |> group_by(k, division) |>
  summarise(total = n(), in09 = mean(key %in% all09), any_blk = sum(key %in% blk), loose_blk = sum(loose(unique(key))[match(key, unique(key))]), .groups = "drop")
g <- g |> rowwise() |> mutate(best = { x <- cl |> filter(div == division, !is.na(ptot)); x$year[which.min(abs(x$ptot - total))] },
  best_tot = { x <- cl |> filter(div == division, !is.na(ptot)); x$ptot[which.min(abs(x$ptot - total))] },
  pubT1_best = cl$T1[cl$div == division & cl$year == best]) |> ungroup()
print(g |> mutate(yr_rebuild = c(J18=1886,V19=1886,V21=1887,J22=1887,J24=1889,V25=1889,J28=1891,J30=1891,V33=1893,J34=1893)[k]) |>
  select(k, division, yr_rebuild, best, total, best_tot, in09, any_blk, loose_blk, pubT1_best), n = 60, width = 200)
