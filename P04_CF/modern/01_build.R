# P04_CF  S6 modern reanalysis, step 1: build the analysis frame (method card §4.1-4.4, frozen at 3c01885).
#   1. Link the 2016 analysis file to the 2017 SAF file by the frozen S5 rule (compare/s5_checks/s5_link.R,
#      s5_clusters.R): composite non-identifying key; prefer candidates whose stored classes agree.
#   2. Father clusters: 2017 fathers_id, with father ids of duplicate son records (s5_duplicates.R groups)
#      merged by union-find (s5_clusters.R). Rows that fail to link get a singleton cluster (card §4.1).
#   3. Authors' term -> Long-Ferrie class map recovered from the 2017 file (s5_termmap.R); coding variants:
#      orig2016 (published classes), base (2017 terms, authors' map), grazier (grazier -> Farmer),
#      century (century removed), both (primary: both corrections), highest_both (order-free highest class).
#      Classes rebuilt with the do-file "last non-missing" rule (do l.21-24, 51-54).
#   4. Duplicate flag (second record of each key-ambiguous pair; exact-match key as in s5_duplicates.R).
# Outputs: modern/_scratch/analysis.rds (no names or identifiers; ids are the 2016 anonymised row ids),
#          modern/output/build_checks.csv (aggregate counts that verify the reused S5 code).
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr)})
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P04_CF"
source(file.path(dirname(root), "tools", "paths.R"))  # [A6] data root on D:
scr <- dscratch("P04_CF", "modern"); out <- file.path(root, "modern", "output")
dir.create(scr, showWarnings = FALSE, recursive = TRUE); dir.create(out, showWarnings = FALSE, recursive = TRUE)
dat <- dpath("P04_CF", "original", "CF Mobility", "Data")
a <- read_dta(file.path(dat, "CF_mobility_replication_data_anonymized.dta")) |> zap_labels()
b <- read_dta(file.path(dat, "SAF mobility data_10.08.2017.dta")) |> zap_labels()
b$brow <- seq_len(nrow(b))
chk <- list(); ck <- function(q, v, expect = NA) chk[[length(chk) + 1]] <<- data.frame(check = q, value = v, expected = expect)

## ---- 3a. term map (s5_termmap.R) ----
pos_map <- function(tpref, gpref, Kt, Kg) {
  lt <- b |> select(brow, num_range(tpref, 1:Kt)) |> pivot_longer(-brow, names_to = "k", values_to = "term") |>
    mutate(k = as.integer(sub(tpref, "", k))) |> filter(!is.na(term), term != "")
  lg <- b |> select(brow, num_range(gpref, 1:Kg)) |> pivot_longer(-brow, names_to = "k", values_to = "g") |>
    mutate(k = as.integer(sub(gpref, "", k))) |> filter(!is.na(g))
  j <- full_join(lt, lg, by = c("brow", "k"))
  list(j = j, nogroup_term = sum(is.na(j$term)))
}
ms <- pos_map("occup", "occ_group", 15, 8); mf <- pos_map("f_occup", "f_occ_group", 9, 9)
ck("son class without a term", ms$nogroup_term, 0); ck("father class without a term", mf$nogroup_term, 0)
both <- bind_rows(ms$j, mf$j) |> count(term, g)
ck("terms mapping to more than one non-missing class", sum(both |> filter(!is.na(g)) |> group_by(term) |> summarise(n = n_distinct(g)) |> pull(n) > 1), 0)
map <- both |> group_by(term) |> summarise(g = first(g), .groups = "drop")
ck("grazier class in authors' map (4 = Unskilled)", map$g[map$term == "grazier"], 4)
ck("century class in authors' map (1 = White collar)", map$g[map$term == "century"], 1)

recode <- function(mp, pref, K) {
  M <- matrix(sapply(1:K, function(k) mp$g[match(b[[paste0(pref, k)]], mp$term)]), ncol = K)
  last <- apply(M, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) z[length(z)] else NA_real_ })
  # order-free: highest on Farmer(2) < Unskilled(4) < Semi/skilled(3) < White collar(1)
  rk <- c(`1` = 4, `2` = 1, `3` = 3, `4` = 2); inv <- c(2, 4, 3, 1)
  high <- apply(M, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) inv[max(rk[as.character(z)])] else NA_real_ })
  list(M = M, last = last, high = high)
}
mp_base <- map
mp_graz <- map; mp_graz$g[mp_graz$term == "grazier"] <- 2
mp_cent <- map; mp_cent$g[mp_cent$term == "century"] <- NA
mp_both <- mp_graz; mp_both$g[mp_both$term == "century"] <- NA
S0 <- recode(mp_base, "occup", 8); F0 <- recode(mp_base, "f_occup", 9)
og <- unname(as.matrix(b[paste0("occ_group", 1:8)])); fg <- unname(as.matrix(b[paste0("f_occ_group", 1:9)]))
ck("rebuilt son groups identical to occ_group1-8 (1 = yes)",
   as.numeric(identical(is.na(og), is.na(S0$M)) && all(og == S0$M, na.rm = TRUE)), 1)
ck("rebuilt father groups identical to f_occ_group1-9 (1 = yes)",
   as.numeric(identical(is.na(fg), is.na(F0$M)) && all(fg == F0$M, na.rm = TRUE)), 1)
codings <- list(base = mp_base, grazier = mp_graz, century = mp_cent, both = mp_both)
rc <- lapply(codings, function(mp) list(S = recode(mp, "occup", 8), F = recode(mp, "f_occup", 9)))

## ---- 1-2. link and father clusters (s5_duplicates.R groups; s5_clusters.R union-find) ----
dg <- b |> group_by(dob, generation, sib_rank_dad, sib_tot_dad, first_son, gen_dad, sons_hhc, fathers_hhc) |>
  filter(n() > 1) |> mutate(grp = cur_group_id()) |> ungroup() |> select(brow, grp)
ck("2017 duplicate groups (s5_duplicates.R key)", n_distinct(dg$grp), 163)
f <- b |> select(brow, fathers_id) |> left_join(dg, by = "brow")
par <- setNames(unique(b$fathers_id), unique(b$fathers_id))
find <- function(x) { while (par[[x]] != x) x <- par[[x]]; x }
for (gg in unique(na.omit(f$grp))) {
  ids <- unique(f$fathers_id[f$grp %in% gg]); r0 <- find(ids[1]); for (i in ids[-1]) par[[find(i)]] <- r0
}
b$froot <- vapply(b$fathers_id, find, "")
b$prov <- c(CP = 1, Natal = 2, OFS = 3, Tvl = 4)[b$prov_final]; b$prov[is.na(b$prov)] <- 5
k <- function(...) do.call(paste, c(lapply(list(...), function(z) ifelse(is.na(z), "NA", as.character(round(z, 4)))), sep = "|"))
a$key <- k(a$dob, a$gen, a$sibrank, a$sibtot, a$first_son, a$f_gen, a$hhc, a$f_hhc, a$hc_share, a$prov, a$f_hc_first, a$hc_first)
b$key <- k(b$dob, b$generation, b$sib_rank_dad, b$sib_tot_dad, b$first_son, b$gen_dad, b$sons_hhc, b$fathers_hhc,
           b$hc_share, b$prov, b$fathers_hhc_first, b$sons_hhc_first)
cand <- a |> select(id, key, ol = occ_group_last, fl = f_occ_group_last) |>
  inner_join(b |> select(brow, key, froot, fathers_id, bol = occ_group_last, bfl = f_occ_group_last),
             by = "key", relationship = "many-to-many") |>
  group_by(id) |> mutate(agree = (ol == bol & fl == bfl)) |> filter(agree | !any(agree)) |> ungroup()
s <- cand |> group_by(id) |> summarise(nc = n(), nroot = n_distinct(froot), froot = first(froot), brow1 = first(brow), .groups = "drop")
ck("2016 rows linked (>= 1 candidate)", nrow(s), 9494); ck("2016 rows linked uniquely", sum(s$nc == 1), 9176)
ck("2016 rows with ambiguous father root", sum(s$nroot > 1), 0)
amb <- cand |> filter(id %in% s$id[s$nc > 1]) |> group_by(key) |> summarise(ids = list(sort(unique(id))), .groups = "drop")
second <- unlist(lapply(amb$ids, function(v) v[-1]))
ck("duplicate second records flagged", length(second), 159)
# ambiguous pairs: both candidate 2017 rows are one s5_duplicates group with identical term lists
ambrows <- cand |> filter(id %in% s$id[s$nc > 1]) |> left_join(dg, by = "brow")
ck("ambiguous candidates outside a duplicate group", sum(is.na(ambrows$grp)), 0)
same_terms <- ambrows |> group_by(id) |> summarise(ok = n_distinct(paste(b$occup[brow], b$f_occup[brow])) == 1, .groups = "drop")
ck("ambiguous 2016 rows whose candidates differ in occupation strings", sum(!same_terms$ok), 0)

d <- a |> select(id, dob, period, psplit, origin, f_gen, first_son, prov, sl16 = occ_group_last, fl16 = f_occ_group_last, share) |>
  left_join(s |> select(id, froot, brow1), by = "id")
d$clus <- ifelse(is.na(d$froot), paste0("single_", d$id), d$froot)
d$clus <- as.integer(factor(d$clus)); d$froot <- NULL
d$linked <- !is.na(d$brow1)
d$dupflag <- as.integer(d$id %in% second)
d$year <- as.integer(format(as.Date(d$dob, origin = "1960-01-01"), "%Y"))
for (cn in names(rc)) {
  d[[paste0("sl_", cn)]] <- rc[[cn]]$S$last[d$brow1]; d[[paste0("fl_", cn)]] <- rc[[cn]]$F$last[d$brow1]
}
d$sl_highest_both <- rc$both$S$high[d$brow1]; d$fl_highest_both <- rc$both$F$high[d$brow1]
d$sl_orig2016 <- d$sl16; d$fl_orig2016 <- d$fl16
ck("rows: rebuilt base son class != 2016 class", sum(d$sl_base != d$sl16, na.rm = TRUE), 2)
ck("rows: rebuilt base father class != 2016 class", sum(d$fl_base != d$fl16, na.rm = TRUE), 0)
ck("father clusters (all 9,494 rows)", n_distinct(d$clus), 5261)
ck("pairs codable under both corrections", sum(!is.na(d$sl_both) & !is.na(d$fl_both)), 9336)
# decoded share in the 2016 file equals % of fathers in class within period (C1)
lab <- attr(read_dta(file.path(dat, "CF_mobility_replication_data_anonymized.dta"), n_max = 1)$share, "labels")
d$share_label_code <- d$share; d$share_decoded_2016 <- as.numeric(names(lab))[match(d$share, lab)]
chs <- d |> group_by(period) |> mutate(np = n()) |> group_by(period, fl16) |> mutate(sh = round(100 * n() / np, 2)) |> ungroup()
ck("decoded 2016 share mismatches vs rebuilt share (|diff| > 0.006)", sum(abs(chs$sh - chs$share_decoded_2016) > 0.006), 0)
d <- d |> select(-dob, -brow1, -share, -sl16, -fl16)
saveRDS(d, file.path(scr, "analysis.rds"))
cb <- bind_rows(chk); cb$pass <- with(cb, ifelse(is.na(expected), NA, abs(value - expected) < 1e-9))
write.csv(cb, file.path(out, "build_checks.csv"), row.names = FALSE)
print(cb); if (any(cb$pass == FALSE, na.rm = TRUE)) warning("build check(s) failed")
