# S5: derive the authors' term -> class map from the 2017 file (positional alignment occupK <-> occ_groupK)
suppressMessages({library(haven); library(dplyr); library(tidyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
r <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
r$row <- seq_len(nrow(r))
long_t <- r |> select(row, num_range("occup",1:15)) |> pivot_longer(-row, names_to="k", values_to="term") |>
  mutate(k=as.integer(sub("occup","",k))) |> filter(!is.na(term), term!="")
long_g <- r |> select(row, num_range("occ_group",1:8)) |> pivot_longer(-row, names_to="k", values_to="g") |>
  mutate(k=as.integer(sub("occ_group","",k))) |> filter(!is.na(g))
j <- full_join(long_t, long_g, by=c("row","k"))
cat("group without term:", sum(is.na(j$term)), "\n")
m <- j |> count(term, g) |> group_by(term) |> mutate(nv=n_distinct(g))
cat("terms mapping to >1 value (incl NA):", sum(m$nv>1 & !duplicated(m$term)), "\n")
print(m |> filter(nv>1))
# fathers
lf_t <- r |> select(row, num_range("f_occup",1:9)) |> pivot_longer(-row, names_to="k", values_to="term") |>
  mutate(k=as.integer(sub("f_occup","",k))) |> filter(!is.na(term), term!="")
lf_g <- r |> select(row, num_range("f_occ_group",1:9)) |> pivot_longer(-row, names_to="k", values_to="g") |>
  mutate(k=as.integer(sub("f_occ_group","",k))) |> filter(!is.na(g))
jf <- full_join(lf_t, lf_g, by=c("row","k"))
cat("father group without term:", sum(is.na(jf$term)), "\n")
mf <- jf |> count(term, g) |> group_by(term) |> mutate(nv=n_distinct(g))
print(mf |> filter(nv>1))
both <- bind_rows(m, mf) |> group_by(term, g) |> summarise(n=sum(n), .groups="drop")
chk <- both |> group_by(term) |> summarise(nv=n_distinct(g), .groups="drop")
cat("terms inconsistent son vs father:", sum(chk$nv>1), "\n")
map <- both |> group_by(term) |> summarise(g=first(g), n=sum(n))
write.csv(map, dpath("P04_CF", "compare", "_scratch_s5", "termmap.csv"), row.names=FALSE)
cat("grazier, century, smith, prisoner:\n"); print(map |> filter(term %in% c("grazier","century","smith","prisoner","farmer")))
cat("class totals of terms:\n"); print(map |> group_by(g) |> summarise(terms=n(), n=sum(n)))
