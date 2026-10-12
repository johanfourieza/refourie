# P22_MEFK S3 recreation, step 2: compute every claim that the surviving raw transcription permits.
# Input: scratch RDS from 01_clean.R. Output: repro_r/results_r.csv and aggregate CSVs in repro_r/output/.
# Notes column: "direct" = count/share from raw fields as transcribed; "RE-CODING" = depends on our own
# re-coding of class, residence, region, sector or investor identity (not a reproduction of the authors' coding).
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr); library(here)})
root <- here::here(); if (basename(root) != "Fourie_ReplicateMe") root <- normalizePath(file.path(root, ".."))
source(file.path(root, "tools", "paths.R"))
pdir <- file.path(root, "P22_MEFK"); out <- file.path(pdir, "repro_r", "output")
sh <- readRDS(dscratch("P22_MEFK", "repro_r", "shareholders.rds"))
co <- readRDS(dscratch("P22_MEFK", "repro_r", "companies.rds"))
claims <- read_csv(file.path(pdir, "claims", "claims.csv"), show_col_types = FALSE)

res <- list()
put <- function(id, value, n = NA, note = "direct") res[[id]] <<- tibble(claim_id = id, value = value, n = n, note = note)
pct <- function(x) 100 * mean(x, na.rm = TRUE)
capsh <- function(sel, base = rep(TRUE, nrow(sh))) 100 * sum(sh$val[sel & base], na.rm = TRUE) / sum(sh$val[base], na.rm = TRUE)
N <- nrow(sh); RC <- "RE-CODING"

# ---- sample ----
put("TX_n_shareholders", N, N, "direct: non-empty shareholder rows, Sheet3 (2018 transcription)")
put("TX_n_companies", n_distinct(sh$rec), N, "direct: distinct company records with >=1 shareholder row")
put("TX_missing_occ", pct(sh$cls == "Information not available"), N, "direct: occupation blank/'.'/'?'")
n9297 <- sum(co$found_year %in% 1892:1897); n9296 <- sum(co$found_year %in% 1892:1896)
put("TX_co_1892act", n9297, nrow(co), sprintf("direct: Sheet2 founding year 1892-1897 (1892-1896: %d)", n9296))

# ---- sex, Africans ----
ks <- !is.na(sh$sex)
put("TX_men", pct(sh$sex[ks] == "male"), sum(ks), "RE-CODING light: gender/title fields; entities by name pattern")
put("TX_women", pct(sh$sex[ks] == "female"), sum(ks), "RE-CODING light: gender/title fields")
put("TX_entities", pct(sh$sex[ks] == "entity"), sum(ks), "RE-CODING light: entity name pattern")
put("TX_afr_n", sum(sh$african), N, "direct: Language = Xhosa")
put("TX_africans_share", pct(sh$african), N, "direct: Language = Xhosa")
put("TX_afr_cap", sum(sh$val[sh$african], na.rm = TRUE), sum(sh$african), "direct: sum of Value, Language = Xhosa")

# ---- foreign ----
fr <- sh$foreign
put("TX_foreign_cap_8", pct(fr), N, paste(RC, "address outside Africa; share of shareholders (paper wording ambiguous)"))
put("TX_local", 100 - pct(fr), N, paste(RC, "address not outside Africa"))
put("TX_cap_foreign", capsh(fr), sum(!is.na(sh$val)), paste(RC, "foreign share of summed Value"))
fc <- sh$country[fr]
for (x in list(c("TX_foreign_uk", "UK"), c("TX_foreign_nl", "Netherlands"), c("TX_foreign_de", "Germany"), c("TX_foreign_be", "Belgium")))
  put(x[1], pct(fc == x[2]), length(fc), paste(RC, "country from address"))
put("TX_brit_london", pct(sh$london[sh$country %in% "UK"]), sum(sh$country %in% "UK"), paste(RC, "London/E.C./Stock Exchange in address"))
tv <- sh |> filter(transvaal)
put("TX_transvaal_9296", n_distinct(tv$key[tv$found_year %in% 1892:1896]), nrow(tv), paste(RC, "Transvaal address, company founded 1892-1896, distinct names"))
put("TX_transvaal_9702", n_distinct(tv$key[tv$found_year %in% 1897:1902]), nrow(tv), paste(RC, "Transvaal address, company founded 1897-1902, distinct names"))

# ---- class shares (investors and capital) ----
cl <- c(mid = "Middle class", farm = "Farmers", bus = "Businessmen", rent = "Rentiers", work = "Working class", comp = "Company investors", noinfo = "Information not available")
for (k in names(cl)) {
  if (k != "noinfo") put(paste0("TX_", k, "_inv"), pct(sh$cls == cl[k]), N, paste(RC, "investor class from occupation text"))
  put(paste0("TX_cap_", k), capsh(sh$cls == cl[k]), sum(!is.na(sh$val)), paste(RC, "class share of summed Value"))
  if (!k %in% c("farm", "work")) put(paste0("TX_fc_", k), capsh(sh$cls == cl[k], fr), sum(fr), paste(RC, "class share of foreign Value"))
}
put("TX_fc_wf", capsh(sh$cls %in% c("Working class", "Farmers"), fr), sum(fr), paste(RC, "class share of foreign Value"))
t2 <- c(r1 = "Businessmen", r2 = "Company investors", r3 = "Farmers", r4 = "Middle class", r5 = "Rentiers", r6 = "Working class", r7 = "Information not available")
for (k in names(t2)) { s <- sh$cls == t2[k]; put(paste0("T2_", k, "_share"), pct(fr[s]), sum(s), paste(RC, "foreign share of investors in class (unit assumed: investors)")) }
classtab <- sh |> group_by(cls) |> summarise(n = n(), share_inv = 100 * n / N, capital = sum(val, na.rm = TRUE), foreign_n = sum(foreign), foreign_cap = sum(val[foreign], na.rm = TRUE)) |>
  mutate(share_cap = 100 * capital / sum(capital), foreign_share_inv = 100 * foreign_n / n)
write_csv(classtab, file.path(out, "class_shares_recoded.csv"))

# ---- 1895 / 1896 ----
y95 <- sh$found_year %in% 1895; y96 <- sh$found_year %in% 1896
put("TX_1895_foreign_inv", pct(fr[y95]), sum(y95), paste(RC, "companies founded 1895"))
put("TX_1895_foreign_cap", capsh(fr, y95), sum(y95), paste(RC, "companies founded 1895"))
for (x in list(c("rent", "Rentiers"), c("bus", "Businessmen"), c("mid", "Middle class"))) {
  b <- y95 & sh$cls == x[2]
  put(paste0("TX_1895_", x[1], "_inv"), pct(fr[b]), sum(b), paste(RC, "foreign share within class, 1895 companies"))
  put(paste0("TX_1895_", x[1], "_cap"), capsh(fr, b), sum(b), paste(RC, "foreign Value share within class, 1895 companies"))
}
put("TX_1896_foreign", pct(fr[y96]), sum(y96), paste(RC, "companies founded 1896"))

# ---- subgroups ----
sg <- list(c("TX_women_mid", "Middle class", "women"), c("TX_lmc", "Middle class", "lower-middle"), c("TX_umc", "Middle class", "upper-middle"),
           c("TX_gent", "Rentiers", "gentlemen"), c("TX_lady", "Rentiers", "ladies"), c("TX_land", "Rentiers", "landowners"))
for (x in sg) { b <- sh$cls == x[2]
  put(paste0(x[1], "_inv"), pct(sh$sub[b] == x[3]), sum(b), paste(RC, "subgroup share of class investors"))
  put(paste0(x[1], "_cap"), capsh(sh$sub == x[3], b), sum(b), paste(RC, "subgroup share of class Value")) }
bs <- sh$cls == "Businessmen"
for (x in list(c("TX_merch", "merchants"), c("TX_genbus", "general business"), c("TX_capitalists", "capitalists"), c("TX_manuf", "manufacturers"), c("TX_contr", "contractors")))
  put(x[1], pct(sh$sub[bs] == x[2]), sum(bs), paste(RC, "subgroup share of businessmen investors"))

# ---- named investors (aggregates only) ----
pam <- grepl("\\bpam\\b", sh$name) & y95
put("TX_pam", sum(sh$val[pam], na.rm = TRUE), sum(pam), "direct: rows with surname Pam in 1895 companies, summed Value")
ram <- grepl("ramsay", sh$sname) & grepl("^a", sh$key)
put("TX_ramsay_n", n_distinct(sh$rec[ram]), sum(ram), "direct-ish: A. Ramsay rows (name match), distinct companies")
put("TX_ramsay_cap", sum(sh$val[ram], na.rm = TRUE), sum(ram), "direct-ish: A. Ramsay rows, summed Value")
sil <- grepl("silberbauer", sh$sname) & grepl("^c", sh$key)
put("TX_silb_cap", sum(sh$val[sil], na.rm = TRUE), sum(sil), sprintf("direct-ish: C. Silberbauer rows, summed Value, %d companies", n_distinct(sh$rec[sil])))

# ---- investor-level: diversification, Table 3 ----
mode1 <- function(x) { x <- x[!is.na(x)]; if (!length(x)) NA_character_ else names(sort(table(x), decreasing = TRUE))[1] }
inv <- sh |> filter(key != "") |> group_by(key) |>
  summarise(ncos = n_distinct(rec), value = sum(val, na.rm = TRUE), cls = mode1(cls),
            region = mode1(region[region %in% c("North", "East", "West")]), .groups = "drop")
put("TX_multi", pct(inv$ncos > 1), nrow(inv), paste(RC, "investor identity = normalised full name"))
put("TX_single", pct(inv$ncos == 1), nrow(inv), paste(RC, "investor identity = normalised full name"))
put("TX_div_bus", pct(inv$ncos[inv$cls %in% "Businessmen"] > 1), sum(inv$cls %in% "Businessmen"), paste(RC, "name identity + class"))
put("TX_div_farm", pct(inv$ncos[inv$cls %in% "Farmers"] > 1), sum(inv$cls %in% "Farmers"), paste(RC, "name identity + class"))
t3 <- inv |> filter(ncos > 1, !is.na(region)) |> group_by(region) |>
  summarise(r1 = mean(value), r2 = median(value), r3 = max(value), r4 = min(value), r5 = sd(value), r6 = sum(value), n = n())
write_csv(t3, file.path(out, "table3_recoded.csv"))
for (i in seq_len(nrow(t3))) for (r in paste0("r", 1:6))
  put(sprintf("T3_%s_%s", r, substr(t3$region[i], 1, 1)), t3[[r]][i], t3$n[i], paste(RC, "diversified = >1 company by name; region from address towns"))

# ---- networks, sectors ----
fam <- sh |> filter(sname != "") |> add_count(rec, sname) |> pull(n)
put("TX_family_net", pct(fam > 1), length(fam), paste(RC, "shares surname with another shareholder in same company (address ignored)"))
du <- sh |> add_count(rec, dutch, name = "nd") |> filter(dutch)
put("TX_afrik", pct(du$nd > 1), nrow(du), paste(RC, "Language=Dutch as proxy for Afrikaans names; another Dutch shareholder in company"))
mi <- sh$sector %in% "mining"; fi <- sh$sector %in% "financial"
put("TX_fmin_inv", pct(mi[fr]), sum(fr), paste(RC, "sector from Nature_of_Business; foreign investors in mining"))
put("TX_fmin_cap", capsh(mi, fr), sum(fr), paste(RC, "foreign Value in mining"))
put("TX_ffin_inv", pct(fi[fr]), sum(fr), paste(RC, "foreign investors in financial companies"))
put("TX_ffin_cap", capsh(fi, fr), sum(fr), paste(RC, "foreign Value in financial companies"))
put("TX_mid_mining", pct(mi[sh$cls == "Middle class"]), sum(sh$cls == "Middle class"), paste(RC, "middle-class rows in mining companies"))
put("TX_bus_mining", pct(mi[sh$cls == "Businessmen"]), sum(sh$cls == "Businessmen"), paste(RC, "businessmen rows in mining companies"))

# ---- assemble ----
r <- bind_rows(res)
rr <- claims |> select(claim_id) |> left_join(r, by = "claim_id") |>
  mutate(source = "r", se = NA, value = ifelse(is.finite(value), signif(value, 6), NA),
         status_override = ifelse(is.na(value), "unavailable", ""),
         note = ifelse(is.na(note), "inputs do not survive (geocoding, founders, sector scheme, external sources, or 1861 almanac company list)", note)) |>
  select(claim_id, source, value, se, n, status_override, note)
write_csv(rr, file.path(pdir, "repro_r", "results_r.csv"), na = "")
cat("claims:", nrow(rr), " computed:", sum(!is.na(rr$value)), " unavailable:", sum(is.na(rr$value)), "\n")
print(as.data.frame(rr |> filter(claim_id %in% c("TX_mid_inv", "TX_cap_mid", "TX_cap_foreign", "TX_local", "TX_n_shareholders", "TX_n_companies")) |> select(claim_id, value, n)))
