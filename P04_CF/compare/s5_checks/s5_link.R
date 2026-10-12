# S5 C4/C2: link anonymised 2016 analysis file to the 2017 SAF file on non-identifying composite keys,
# to recover a father id for clustering and the term lists for recoding scenarios.
# Writes only id-level keys (no names) to compare/_scratch_s5/.
suppressMessages({library(haven); library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
a <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "CF_mobility_replication_data_anonymized.dta")) |> zap_labels()
b <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
b$brow <- seq_len(nrow(b))
b$prov <- c(CP=1, Natal=2, OFS=3, Tvl=4)[b$prov_final]; b$prov[is.na(b$prov)] <- 5
k <- function(...) do.call(paste, c(lapply(list(...), function(z) ifelse(is.na(z), "NA", as.character(round(z,4)))), sep="|"))
a$key <- k(a$dob, a$gen, a$sibrank, a$sibtot, a$first_son, a$f_gen, a$hhc, a$f_hhc, a$hc_share, a$prov, a$f_hc_first, a$hc_first)
b$key <- k(b$dob, b$generation, b$sib_rank_dad, b$sib_tot_dad, b$first_son, b$gen_dad, b$sons_hhc, b$fathers_hhc, b$hc_share, b$prov, b$fathers_hhc_first, b$sons_hhc_first)
cand <- a |> select(id, key, ol=occ_group_last, fl=f_occ_group_last) |>
  inner_join(b |> select(brow, key, fathers_id, family_id, bol=occ_group_last, bfl=f_occ_group_last), by="key", relationship="many-to-many")
# prefer candidates whose stored 2017 classes agree with the 2016 classes
cand <- cand |> group_by(id) |> mutate(agree = (ol==bol & fl==bfl), anyagree = any(agree)) |>
  filter(agree | !anyagree) |> ungroup()
summ <- cand |> group_by(id) |> summarise(nc=n(), nfath=n_distinct(fathers_id), brow1=first(brow), fid=first(fathers_id), .groups="drop")
cat("2016 rows:", nrow(a), " with >=1 candidate:", nrow(summ), " unique:", sum(summ$nc==1),
    " multi but same father:", sum(summ$nc>1 & summ$nfath==1), " multi diff father:", sum(summ$nfath>1), "\n")
# one-to-one check for unique links
u <- summ |> filter(nc==1); cat("unique links using a 2017 row twice:", sum(duplicated(u$brow1)), "\n")
lk <- a |> select(id) |> left_join(summ, by="id")
# cluster id: father id where unambiguous; otherwise singleton
lk$clus <- ifelse(!is.na(lk$nfath) & lk$nfath==1, lk$fid, paste0("single_", lk$id))
cat("clusters:", n_distinct(lk$clus), " rows with recovered father id:", sum(!grepl("^single_", lk$clus)), "\n")
tab <- table(table(lk$clus)); print(tab)
# integer cluster id for Stata (no identifiers)
lk$clus_n <- as.integer(factor(lk$clus))
write_dta(lk |> select(id, clus_n), dpath("P04_CF", "compare", "_scratch_s5", "clusters.dta"))
# brow link (unique or same-father pick) for term-level recoding
saveRDS(lk |> select(id, nc, nfath, brow1), dpath("P04_CF", "compare", "_scratch_s5", "link.rds"))
