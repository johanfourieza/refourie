# S5 C4: father cluster id for the 2016 analysis file.
# fathers_id from the 2017 file via composite-key link (s5_link.R); father ids of duplicate son records
# (identical first names, dob, occupation strings, father dob; s5_duplicates.R) are merged, which also
# resolves the 318 key-ambiguous rows. Output: id, clus_n (integer), dupflag (second record of a duplicate pair).
suppressMessages({library(haven); library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
a <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "CF_mobility_replication_data_anonymized.dta")) |> zap_labels()
b <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
b$brow <- seq_len(nrow(b))
dg <- readRDS(dpath("P04_CF", "compare", "_scratch_s5", "dup_groups.rds"))
# union father ids within duplicate groups
f <- b |> select(brow, fathers_id) |> left_join(dg, by="brow")
par <- setNames(unique(b$fathers_id), unique(b$fathers_id))
find <- function(x){ while(par[[x]]!=x) x <- par[[x]]; x }
for (gg in unique(na.omit(f$grp))) { ids <- unique(f$fathers_id[f$grp %in% gg]); r0 <- find(ids[1]); for (i in ids[-1]) par[[find(i)]] <- r0 }
b$froot <- vapply(b$fathers_id, find, "")
prov <- c(CP=1, Natal=2, OFS=3, Tvl=4)[b$prov_final]; prov[is.na(prov)] <- 5; b$prov <- prov
k <- function(...) do.call(paste, c(lapply(list(...), function(z) ifelse(is.na(z), "NA", as.character(round(z,4)))), sep="|"))
a$key <- k(a$dob, a$gen, a$sibrank, a$sibtot, a$first_son, a$f_gen, a$hhc, a$f_hhc, a$hc_share, a$prov, a$f_hc_first, a$hc_first)
b$key <- k(b$dob, b$generation, b$sib_rank_dad, b$sib_tot_dad, b$first_son, b$gen_dad, b$sons_hhc, b$fathers_hhc, b$hc_share, b$prov, b$fathers_hhc_first, b$sons_hhc_first)
cand <- a |> select(id, key, ol=occ_group_last, fl=f_occ_group_last) |>
  inner_join(b |> select(brow, key, froot, fathers_id, bol=occ_group_last, bfl=f_occ_group_last), by="key", relationship="many-to-many") |>
  group_by(id) |> mutate(agree=(ol==bol & fl==bfl)) |> filter(agree | !any(agree)) |> ungroup()
s <- cand |> group_by(id) |> summarise(nc=n(), nroot=n_distinct(froot), froot=first(froot), nfid=n_distinct(fathers_id), .groups="drop")
cat("rows:", nrow(s), " single father root:", sum(s$nroot==1), " ambiguous:", sum(s$nroot>1), "\n")
# dupflag: within each key-ambiguous pair (nc==2) flag the second 2016 row
amb <- cand |> filter(id %in% s$id[s$nc>1]) |> group_by(key) |> summarise(ids=list(sort(unique(id))), .groups="drop")
second <- unlist(lapply(amb$ids, function(v) v[-1]))
s$dupflag <- as.integer(s$id %in% second)
cat("duplicate second records flagged:", sum(s$dupflag), "\n")
s$clus_n <- as.integer(factor(s$froot))
cat("father clusters (merged):", n_distinct(s$clus_n), " size dist:\n"); print(table(table(s$clus_n)))
write_dta(s |> select(id, clus_n, dupflag), dpath("P04_CF", "compare", "_scratch_s5", "clusters.dta"))
