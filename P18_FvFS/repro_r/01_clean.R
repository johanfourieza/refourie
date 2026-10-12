# P18_FvFS - S3 independent recreation - 01_clean.R
# Builds the farmer analysis sample (1700-1773, 14 censuses) from
#   original/Statafiles/opgaafrolle.dta  (sample + production variables)
#   original/French Huguenots/Working - 26 May 2010 - Prov.xlsx (Huguenot coding)
#   original/French Huguenots/Province-group split.xlsx (WH/NWH region classification)
#   original/French Huguenots/MOOC.xlsx (probate inventories)
# See repro_r/decisions.md for every choice.

suppressPackageStartupMessages({
  library(tidyverse); library(readxl); library(haven); library(here)
})
set.seed(20261011)
root <- here("P18_FvFS"); source(here("tools", "paths.R"))
orig <- dpath("P18_FvFS", "original")
out  <- dpath("P18_FvFS", "repro_r", "data")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

yrs <- c(1700, 1702, 1705, 1709, 1712, 1719, 1723, 1731, 1738, 1741, 1752, 1757, 1762, 1773)
num0 <- function(v) { z <- suppressWarnings(as.numeric(v)); z[is.na(z)] <- 0; z }
normname <- function(v) toupper(gsub("\\s+", " ", trimws(v)))

# ---------------------------------------------------------------- xlsx coding
fx <- file.path(orig, "French Huguenots", "Working - 26 May 2010 - Prov.xlsx")
hdr <- unlist(read_excel(fx, "Data", col_names = FALSE, n_max = 1, .name_repair = "minimal"))
x <- suppressMessages(read_excel(fx, "Data", col_names = FALSE, skip = 1, guess_max = 30000,
                                 col_types = "text", .name_repair = "minimal"))
x <- x[, seq_along(hdr)]
names(x) <- make.unique(as.character(hdr))

xc <- x %>%
  transmute(van = normname(Van), naam = normname(Naam), jaar = as.numeric(Jaar),
            ds = suppressWarnings(as.numeric(DS)),
            hug_x = num0(HUG), wyn_flag = num0(WYN), prov = trimws(PROV),
            marh = num0(MARH), marhw = num0(MARHW),
            assist = num0(`Assistance in 1690`),
            id_first = suppressWarnings(as.numeric(substr(ID, 8, 11)))) %>%
  group_by(van, naam, jaar, ds) %>% mutate(kk = row_number()) %>% ungroup()

# ---------------------------------------------------- WH/NWH classification
# Authors' Province-group split (Sheet2): Region column
pg <- read_excel(file.path(orig, "French Huguenots", "Province-group split.xlsx"),
                 "Sheet2", col_names = FALSE, .name_repair = "minimal")
pg <- tibble(prov = pg[[1]][-1], region_type = pg[[2]][-1]) %>% filter(!is.na(prov), prov != "Total")
print(pg)
prov_alias <- c(Daupine = "Dauphine", Hesse = "Deutschland", Flanders = "Flandre",
                Artois = "Flandre", `Pays de Vaud` = "Suisse")
xc <- xc %>%
  mutate(prov_std = ifelse(prov %in% names(prov_alias), prov_alias[prov], prov),
         prov_std = ifelse(hug_x == 1, prov_std, NA)) %>%
  left_join(pg, by = c("prov_std" = "prov")) %>%
  mutate(wh_x = case_when(hug_x == 0 ~ 0,
                          region_type == "Wine-producing" ~ 1,
                          region_type == "Non-wine producing" ~ 0,
                          region_type == "Mixed" ~ wyn_flag,      # Dauphine: individual split
                          TRUE ~ wyn_flag))                        # unknown province
# 16 sending regions used in appendix (Swiss excluded)
reg16 <- c(Aunis = "Aunis", Bearn = "Bearn", Bretagne = "Brittany", Champagne = "Champagne",
           Dauphine = "Dauphine", Deutschland = "Germany", Flandre = "Flanders",
           `Ile-de-France` = "IledeFrance", Italia = "Italy", Lanquedoc = "Languedoc",
           Nederland = "Netherlands", Normandie = "Normandy", Orleanais = "Orleanais",
           Picardie = "Picardy", Poitou = "Poitou", Provence = "Provence")
xc$region <- unname(reg16[xc$prov_std])

# numeracy (Crayen and Baten sheet, cols 9-10)
cb <- read_excel(fx, "Crayen and Baten", col_names = FALSE, .name_repair = "minimal")
cb <- tibble(cbname = cb[[9]], numeracy = as.numeric(cb[[10]])) %>% filter(!is.na(cbname), !is.na(numeracy))
cb_map <- c(Aunis = "Aunis", Bearn = "Bearn", Bretagne = "Bretagne", Champagne = "Champagne",
            Dauphine = "Dauphine", `Ile-de-France` = "Ile de France", Lanquedoc = "Longuedoc",
            Normandie = "Normandie", Orleanais = "Orleanais", Picardie = "Picardie",
            Poitou = "Poitou", Provence = "Provence")
xc$numeracy <- cb$numeracy[match(unname(cb_map[xc$prov_std]), cb$cbname)]

# ------------------------------------------------------------- panel (.dta)
d <- read_dta(file.path(orig, "Statafiles", "opgaafrolle.dta")) %>% zap_labels() %>%
  mutate(van = normname(van), naam = normname(naam)) %>% rename(hug_dta = hug) %>%
  group_by(van, naam, jaar, ds) %>% mutate(kk = row_number()) %>% ungroup()
cat("dta rows:", nrow(d), "\n")
ag <- c("pd", "bste", "skpe", "vk", "wingst", "wyn", "kgs", "kgw", "rgs", "rgw", "cgs", "cgw")
d <- d %>% mutate(across(all_of(c(ag, "m", "v", "s", "d", "k", "sm", "sv", "ss", "sd")), ~ replace_na(.x, 0)))
d$farmer <- rowSums(d[, ag]) > 0
cat("dta rows in 14 census years:", sum(d$jaar %in% yrs), "\n")

s <- d %>% filter(jaar %in% yrs, farmer) %>%
  left_join(xc %>% select(van, naam, jaar, ds, kk, hug_x, wh_x, wyn_flag, prov, prov_std, region,
                          marh, marhw, assist, id_first, numeracy),
            by = c("van", "naam", "jaar", "ds", "kk"))
cat("farmers (14 yrs):", nrow(s), " unmatched to xlsx:", sum(is.na(s$hug_x)), "\n")
# unmatched rows: fall back to surname-level Huguenot coding from xlsx
sur <- xc %>% filter(hug_x == 1) %>% count(van, wh_x, prov_std, region, numeracy) %>%
  group_by(van) %>% slice_max(n, n = 1, with_ties = FALSE) %>% ungroup()
um <- which(is.na(s$hug_x))
for (i in um) {
  j <- match(s$van[i], sur$van)
  s$hug_x[i] <- ifelse(is.na(j), 0, 1)
  s$wh_x[i] <- ifelse(is.na(j), 0, sur$wh_x[j])
  s$prov_std[i] <- ifelse(is.na(j), NA, sur$prov_std[j]); s$region[i] <- ifelse(is.na(j), NA, sur$region[j])
  s$numeracy[i] <- ifelse(is.na(j), NA, sur$numeracy[j])
  s$marh[i] <- 0; s$marhw[i] <- 0; s$assist[i] <- 0
}
cat("district missing:", sum(is.na(s$ds)), "\n")
s <- s %>% filter(!is.na(ds))

s <- s %>% mutate(
  hhsize   = m + v + s + d,
  slaves   = sm + sv + ss + sd,
  knechts  = k,
  vines    = wingst / 1000,
  wine     = wyn,
  wheat    = kgw,
  sown     = kgs,
  cattle   = bste,
  horses   = pd,
  hug      = hug_x,
  wh       = as.integer(hug == 1 & wh_x == 1),
  nwh      = as.integer(hug == 1 & wh_x == 0),
  group    = factor(case_when(wh == 1 ~ "WH", nwh == 1 ~ "NWH", TRUE ~ "NH"), levels = c("NH", "NWH", "WH")),
  mar_nw   = as.integer(marh == 1 & marhw == 0),
  mar_w    = as.integer(marhw == 1),
  born_abroad     = as.integer(assist == 1),
  born_abroad_alt = as.integer(assist == 1 | (hug == 1 & !is.na(id_first) & id_first <= 1692)),
  # alternative WH codings (sensitivity)
  wh_flag  = as.integer(hug == 1 & wyn_flag == 1), nwh_flag = as.integer(hug == 1 & wyn_flag == 0),
  wh_dta   = as.integer(hug_dta == 1 & wyns == 1),
  nwh_dta  = as.integer(hug_dta == 1 & wyns == 0),
  district = factor(ds, levels = 1:4, labels = c("CapeTown", "Stellenbosch", "Drakenstein", "Swellendam")),
  year     = factor(jaar),
  numeracy0 = replace_na(ifelse(hug == 1, numeracy, 0), 0)
)
cat("hhsize==0 rows:", sum(s$hhsize == 0), "\n")
s <- s %>% mutate(
  den = ifelse(hhsize > 0, hhsize, 1),
  wine_pc  = wine / den,
  wheat_pc = wheat / den
)
s$lat <- NA; s$long <- NA; s$grp <- NA
a2 <- tribble(~region, ~lat, ~long, ~grp,
  "Aunis", "Central", "West", "High", "Bearn", "South", "West", "Poor",
  "Brittany", "North", "West", "High", "Champagne", "North", "Central", "Moderate",
  "Dauphine", "South", "East", "Moderate", "Germany", "North", "East", "High",
  "Flanders", "North", "Central", "Moderate", "IledeFrance", "North", "Central", "Moderate",
  "Italy", "South", "East", "High", "Languedoc", "South", "Central", "Poor",
  "Netherlands", "North", "Central", "Poor", "Normandy", "North", "West", "Moderate",
  "Orleanais", "North", "Central", "Moderate", "Picardy", "North", "Central", "Moderate",
  "Poitou", "Central", "West", "Moderate", "Provence", "South", "East", "Moderate")
s <- s %>% select(-lat, -long, -grp) %>% left_join(a2, by = "region") %>%
  mutate(region = ifelse(hug == 1, region, NA))

cat("\nFinal N:", nrow(s), "\n"); print(table(s$group)); print(table(s$jaar))
cat("born abroad (Huguenot):", sum(s$born_abroad == 1 & s$hug == 1), " alt:", sum(s$born_abroad_alt == 1 & s$hug == 1), "\n")
cat("Huguenot with known region:", sum(s$hug == 1 & !is.na(s$region)), " with numeracy:", sum(s$hug == 1 & !is.na(s$numeracy)), "\n")
print(table(s$region[s$hug == 1], s$group[s$hug == 1], useNA = "ifany"))
cat("Alt codings: flag WH", sum(s$wh_flag), "NWH", sum(s$nwh_flag), "; dta wyns WH", sum(s$wh_dta), "NWH", sum(s$nwh_dta), "\n")
cat("share zero wine:", mean(s$wine == 0), " zero wheat:", mean(s$wheat == 0), "\n")

saveRDS(s, file.path(out, "farmers.rds"))

# ------------------------------------------------------------- probate (MOOC)
mo <- read_excel(file.path(orig, "French Huguenots", "MOOC.xlsx"), "Volledige lys", guess_max = 10000,
                 .name_repair = "unique_quiet")
mo <- mo %>% transmute(name = `Standard Name New`, year = suppressWarnings(as.numeric(Year)),
                       slaves = suppressWarnings(as.numeric(Combined))) %>%
  mutate(van = toupper(gsub("[^A-Za-z]", "", sub(",.*$", "", name))))
# opgaaf surname coding: remove spaces/punctuation the same way
surmap <- xc %>% mutate(vk = toupper(gsub("[^A-Za-z]", "", van))) %>% filter(hug_x == 1) %>%
  count(vk, wh_x) %>% group_by(vk) %>% slice_max(n, n = 1, with_ties = FALSE) %>% ungroup()
mo <- mo %>% left_join(surmap %>% select(vk, wh_x), by = c("van" = "vk")) %>%
  mutate(group = case_when(is.na(wh_x) ~ "NH", wh_x == 1 ~ "WH", TRUE ~ "NWH"))
cat("\nMOOC rows:", nrow(mo), " with year 1673-1844:", sum(mo$year >= 1673 & mo$year <= 1844, na.rm = TRUE),
    " and non-missing slaves:", sum(mo$year >= 1673 & mo$year <= 1844 & !is.na(mo$slaves), na.rm = TRUE), "\n")
saveRDS(mo, file.path(out, "mooc.rds"))
