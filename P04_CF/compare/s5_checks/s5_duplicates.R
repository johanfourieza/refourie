# S5: are the 159 key-ambiguous pairs duplicate persons in the SAF sample? (aggregates only; no names printed)
suppressMessages({library(haven); library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
b <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
b$brow <- seq_len(nrow(b))
g <- b |> group_by(dob, generation, sib_rank_dad, sib_tot_dad, first_son, gen_dad, sons_hhc, fathers_hhc) |> filter(n()>1) |>
  mutate(grp=cur_group_id()) |> ungroup()
s <- g |> group_by(grp) |> summarise(n=n(), same_surname=n_distinct(surname)==1, same_first=n_distinct(first_names)==1,
  same_fdob=n_distinct(fathers_dob)==1, same_father=n_distinct(fathers_id)==1, same_family=n_distinct(family_id)==1,
  same_occ=n_distinct(occup)==1, same_focc=n_distinct(f_occup)==1, .groups="drop")
cat("groups of records identical on dob+gen+sibrank+sibtot+first_son+gen_dad+HISCLASS codes:", nrow(s), " records:", sum(s$n), "\n")
print(colSums(s[,-1]))
# exact duplicate persons: same surname, first names, dob but different father id
dp <- b |> group_by(surname, first_names, dob) |> filter(n()>1) |> summarise(n=n(), nf=n_distinct(fathers_id), nfam=n_distinct(family_id),
   same_focc=n_distinct(f_occup)==1, same_fdob=n_distinct(fathers_dob)==1, .groups="drop")
cat("person (surname+first names+dob) duplicates: groups", nrow(dp), " records", sum(dp$n), " with different father ids", sum(dp$nf>1),
    " same father dob", sum(dp$same_fdob), " same father occ string", sum(dp$same_focc), "\n")
# individual_id duplicates?
cat("dup individual_id:", sum(duplicated(b$individual_id)), "\n")
saveRDS(dp |> select(n,nf), dpath("P04_CF", "compare", "_scratch_s5", "dup_summary.rds"))
# surname similarity within the 163 groups (distance only, no names)
sd <- g |> group_by(grp) |> filter(n()==2) |> summarise(d=adist(tolower(surname[1]), tolower(surname[2]))[1,1],
   l=max(nchar(surname)), samefn=first_names[1]==first_names[2], fd=fathers_dob[1]==fathers_dob[2], .groups="drop")
cat("pairs:", nrow(sd), " surname edit distance distribution:\n"); print(table(pmin(sd$d,6)))
cat("pairs with identical first names, occ strings, father occ strings and father dob:", sum(sd$samefn & sd$fd, na.rm=TRUE), "\n")
saveRDS(g |> select(brow, grp), dpath("P04_CF", "compare", "_scratch_s5", "dup_groups.rds"))
