# P04_CF  S3 independent recreation  01_clean.R
# Builds the analysis file from raw occupation term strings (own dictionary).
# Personal data: the analysis file is written to repro_r/_scratch only (local).
suppressMessages({
  library(haven); library(dplyr); library(tidyr); library(stringr); library(readr)
})
set.seed(20261011)
args <- commandArgs(trailingOnly = FALSE)
sp <- sub("--file=", "", args[grep("--file=", args)])
ROOT <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath("..")
RR   <- file.path(ROOT, "repro_r")
source(file.path(dirname(ROOT), "tools", "paths.R"))  # [A6] data root on D:
SCR  <- dpath("P04_CF", "repro_r", "_scratch"); OUT <- file.path(RR, "output")
dir.create(SCR, FALSE, TRUE); dir.create(OUT, FALSE, TRUE)
RAW  <- dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")
ANON <- dpath("P04_CF", "original", "CF Mobility", "Data", "CF_mobility_replication_data_anonymized.dta")

r <- read_dta(RAW) |> zap_labels()
stopifnot(nrow(r) == 9494)

# ---------------------------------------------------------------- dictionary
W <- c("teacher","clerk","merchant","minister","missionary","solicitor","general","manager",
  "magistrate","field cornet","judge","physician","secretary","councillor","chairman","author",
  "commandant","mayor","surveyor","businessman","advocate","medical doctor","bookkeeper","captain",
  "postmaster","professor","commissioner","superintendent","bank manager","senator","accountant",
  "organist","editor","member of parliament","wine merchant","law agent","chemist","dentist",
  "lecturer","lieutenant","town clerk","major","auditor","railway official","surgeon",
  "surveyor-general","colonel","jurist","geologist","governor","sheriff","compiler",
  "State President","orphan-master","reader","Prime Minister","prime minister","auctioneer",
  "publisher","district councillor","poet","chief clerk","ensign","shipping agent","artist",
  "receiver","sculptor","explorer","magistrate’s clerk","wholesale merchant","chief detective",
  "harbour master","local official","newspaper owner","church secretary")
F <- c("farmer","grazier","sheepfarmer","dairy farmer")
S <- c("carpenter","wheelwright","shopkeeper","blacksmith","miner","butcher","mason","contractor",
  "painter","cobbler","barber","general dealer","engineer","baker","miller","tailor","printer",
  "overseer","cooper","constable","ranger","saddler","craftsman","cabinet maker","harness-maker",
  "tanner","clockmaker","sergeant","turner","hatmaker","jeweller","corporal","brewer","brickmaker",
  "gunsmith","innkeeper","locksmith","stone mason","telegraphist","signal man","steward",
  "road-builder","road constructor","shipwright","sail-maker","silversmith","confectioner",
  "greengrocer","cook","dresser","chief mate","boatswain","bombardier","policeman")
U <- c("labourer","assistant","digger","diamond digger","fisherman","transport rider","soldier",
  "messenger of the court","prison warder","coachman","apprentice","sailor","woodcutter",
  "lumberman","slave","bodyguard","gardener","ferryman","farm labourer","transport driver",
  "gold prospector","artillerist","midshipman")
NONOCC <- c("century","prisoner","smith","tenant","elder","deacon","guardian","duke","deserter")
dict <- bind_rows(tibble(term=W, cls="W"), tibble(term=F, cls="F"), tibble(term=S, cls="S"),
                  tibble(term=U, cls="U"), tibble(term=NONOCC, cls=NA_character_))
stopifnot(!anyDuplicated(dict$term))

# long term table
long_terms <- function(prefix, who) {
  cols <- grep(paste0("^", prefix, "[0-9]+$"), names(r), value = TRUE)
  r |> select(individual_id, all_of(cols)) |>
    pivot_longer(-individual_id, names_to = "pos", values_to = "term") |>
    filter(!is.na(term), term != "") |>
    mutate(pos = as.integer(str_extract(pos, "[0-9]+$")), who = who)
}
lt <- bind_rows(long_terms("occup", "son"), long_terms("f_occup", "father"))
unmapped <- setdiff(unique(lt$term), dict$term)
if (length(unmapped)) stop("Unmapped terms: ", paste(unmapped, collapse = "; "))

lt <- lt |> left_join(dict, by = "term") |>
  group_by(individual_id, who) |>
  mutate(cls = case_when(term == "general" & any(term == "general dealer") ~ NA_character_,
                         TRUE ~ cls),
         cls_prisU = ifelse(term == "prisoner", "U", cls)) |>
  ungroup()

# dictionary output (term-level, no personal data)
dict_out <- lt |> count(term, cls, name = "mentions") |>
  mutate(rule = case_when(term == "general" ~ "W when alone; NA when list also has 'general dealer'",
                          is.na(cls) ~ "non-occupation", TRUE ~ "")) |>
  arrange(cls, desc(mentions))
write_csv(dict_out, file.path(OUT, "occ_dictionary.csv"))

pick <- function(d, var) {
  d |> filter(!is.na(.data[[var]])) |> group_by(individual_id, who) |>
    summarise(occfirst = .data[[var]][which.min(pos)], last = .data[[var]][which.max(pos)], .groups = "drop") |>
    pivot_wider(names_from = who, values_from = c(occfirst, last))
}
oc  <- pick(lt, "cls")
ocP <- pick(lt, "cls_prisU") |> rename_with(~ paste0(.x, "_prisU"), -individual_id)

# ---------------------------------------------------------------- origin (from anonymised file)
a <- read_dta(ANON) |> zap_labels()
pm <- c(CP = 1, Natal = 2, OFS = 3, Tvl = 4)
key_r <- r |> transmute(dob, gen = generation, sibrank = sib_rank_dad, sibtot = sib_tot_dad, first_son,
  f_gen = gen_dad, prov = ifelse(is.na(prov_final) | prov_final == "", 5, pm[prov_final]),
  hhc = sons_hhc, f_hhc = fathers_hhc, hc_share)
key_a <- a |> select(dob, gen, sibrank, sibtot, first_son, f_gen, prov, hhc, f_hhc, hc_share)
kr <- do.call(paste, c(key_r, sep = "|")); ka <- do.call(paste, c(key_a, sep = "|"))
uniq_a <- ka[!ka %in% ka[duplicated(ka)]]
lk <- tibble(k = ka, origin = a$origin) |> filter(k %in% uniq_a)
link <- tibble(individual_id = r$individual_id, surname = r$surname, k = kr) |>
  inner_join(lk, by = "k")
smap <- link |> count(surname, origin) |> group_by(surname) |> slice_max(n, n = 1, with_ties = FALSE) |>
  ungroup() |> select(surname, origin)
org_lab <- c("Netherlands","France","Germany","UK","Other west Europe","Other east Europe","Unknown")
link_diag <- tibble(rows_linked_unique = nrow(link),
  surnames_mapped = nrow(smap), surnames_total = n_distinct(r$surname),
  surnames_multi_origin = sum(table(unique(link[c("surname","origin")])$surname) > 1))

# ---------------------------------------------------------------- assemble
d <- r |>
  transmute(individual_id, fathers_id, surname, year, dob,
            generation, gen_dad, first_son, prov_final,
            birth_place = na_if(birth_place, ""), baptism_place = na_if(baptism_place, ""),
            coded_son = occ_group_last, coded_father = f_occ_group_last,
            hc_son = sons_hcgroup, hc_father = fathers_hcgroup) |>
  left_join(oc, by = "individual_id") |> left_join(ocP, by = "individual_id") |>
  left_join(smap, by = "surname") |>
  mutate(
    cohort = cut(year, c(1805, 1834, 1867, 1886, 1910), labels = c("Slavery","Stagnation","Diamonds","Gold")),
    born1910 = year == 1910,
    origin = factor(org_lab[coalesce(as.integer(origin), 7L)], levels = org_lab),
    prov = factor(case_when(prov_final == "CP" ~ "Cape", prov_final == "Natal" ~ "Natal",
                            prov_final == "OFS" ~ "OFS", prov_final == "Tvl" ~ "Transvaal",
                            TRUE ~ "Unknown"), levels = c("Cape","Natal","OFS","Transvaal","Unknown")),
    migrant_father_gen = generation == 2,
    migrant_father = gen_dad == 1,
    later_born = first_son == 2,
    coded_son = c("W","F","S","U")[coded_son], coded_father = c("W","F","S","U")[coded_father])
mig_check <- table(gen_from_generation = d$migrant_father_gen, gen_dad_flag = d$migrant_father)

# Table 1 place normalisation
norm_place <- function(x) {
  x <- str_replace_all(x, "[ôö'\"]", "")
  x <- ifelse(str_detect(x, "dist\\.? "), str_replace(x, "^.*dist\\.? ", ""), x)
  x <- str_replace(x, "^(NGK|GK|NHK|Anglikaanse Kerk\\.?|Lutherse Kerk|Rynse Kerk|Metodiste Kerk)[ ,]*", "")
  parts <- str_split(x, ",\\s*")
  x <- vapply(parts, function(p) {
    p <- p[!str_detect(p, "^(Kp|KP|Kaap|Tvl\\.?|Transvaal|Natal|OVS|OVS\\.|Afd\\. Kaap|Kaapkolonie)$")]
    if (length(p) == 0) NA_character_ else p[length(p)]
  }, character(1))
  x <- str_replace(x, "\\s+[0-9].*$", "")
  x <- str_replace(x, "\\s+(Kp|KP|Tvl\\.?|OVS)$", "")
  x <- str_replace_all(x, "Graaff[ ?]Reinet", "Graaff-Reinet")
  x <- str_squish(x); ifelse(x == "", NA, x)
}
d <- d |> mutate(place = norm_place(coalesce(birth_place, baptism_place)))

d <- d |> mutate(keep = !is.na(last_son) & !is.na(last_father),
                 keep_prisU = !is.na(last_son_prisU) & !is.na(last_father_prisU))
diag <- tibble(n_raw = nrow(d), n_keep = sum(d$keep), n_drop_son = sum(is.na(d$last_son)),
               n_drop_father = sum(is.na(d$last_father)), n_keep_prisU = sum(d$keep_prisU),
               n_1910 = sum(d$born1910)) |> bind_cols(link_diag)
write_csv(diag, file.path(OUT, "clean_diagnostics.csv"))
capture.output(print(mig_check), file = file.path(OUT, "migrant_check.txt"))
saveRDS(d |> select(-surname, -birth_place, -baptism_place), file.path(SCR, "analysis.rds"))
print(diag); print(mig_check)
