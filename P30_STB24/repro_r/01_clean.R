# P30_STB24 — S3 independent recreation, step 1: clean and harmonise
# Fourie, Green et al. (2024), "Waar is beter dorp ...", SAHJ 76(4).
# Input : stellenbosch_panel_raw.xlsx (one sheet per census year, raw transcription),
#         extracted from cape_panel_raw_data_processing-main.zip into the D: scratch folder.
# Output: household-level harmonised file (D: scratch, data never in Dropbox),
#         column map and per-census counts (aggregate metadata, repro_r/output/).

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})
here::i_am("P30_STB24/repro_r/01_clean.R")
source(here("tools", "paths.R"))
set.seed(20261011)

PAPER <- "P30_STB24"
OUT   <- here(PAPER, "repro_r", "output")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

zipf <- dpath(PAPER, "original", "Data", "cape_panel_raw_data_processing-main.zip")
raw  <- dscratch(PAPER, "repro_r", "zip", "stellenbosch_panel_raw.xlsx")
if (!file.exists(raw)) {
  unzip(zipf, files = "cape_panel_raw_data_processing-main/data/raw/stellenbosch_panel_raw.xlsx",
        exdir = dirname(raw), junkpaths = TRUE)
}

sheets <- excel_sheets(raw)
years  <- sheets[str_detect(sheets, "^[0-9]{4}$")]

# ---- value parsing ---------------------------------------------------------
# Fractions are written as unicode glyphs ("4¾", "½") or as "1/2"; strip other text.
frac_map <- c("¼" = 0.25, "½" = 0.5, "¾" = 0.75, "⅓" = 1/3, "⅔" = 2/3, "⅛" = 0.125,
              "⅜" = 0.375, "⅝" = 0.625, "⅞" = 0.875)
parse_num <- function(x) {
  x <- str_squish(x)
  x[x %in% c("", "-", "--", "—", ".")] <- NA
  out <- rep(NA_real_, length(x))
  ok  <- !is.na(x)
  y   <- x[ok]
  y   <- str_replace_all(y, ",", ".")
  fr  <- rep(0, length(y))
  for (g in names(frac_map)) {
    has <- str_detect(y, fixed(g))
    fr[has] <- fr[has] + frac_map[[g]]
    y <- str_remove_all(y, fixed(g))
  }
  # "a b/c" or "b/c"
  m  <- str_match(y, "^\\s*([0-9]+)?\\s*([0-9]+)/([0-9]+)\\s*$")
  isf <- !is.na(m[, 3])
  v  <- suppressWarnings(as.numeric(str_remove_all(y, "[^0-9.]")))
  v[str_detect(y, "^[^0-9]*$")] <- NA          # no digit at all (e.g. "do.", "?")
  v[str_detect(y, "^[^0-9]*$") & fr > 0] <- 0   # pure fraction glyph
  v[isf] <- coalesce(as.numeric(m[isf, 2]), 0) + as.numeric(m[isf, 3]) / as.numeric(m[isf, 4])
  # multiple dots after stripping -> unparseable
  v[str_count(str_remove_all(y, "[^0-9.]"), "\\.") > 1 & !isf] <- NA
  out[ok] <- v + fr
  out
}

# ---- header block ----------------------------------------------------------
read_sheet <- function(y) {
  d <- suppressMessages(read_excel(raw, sheet = y, col_names = FALSE, col_types = "text",
                                   .name_repair = "minimal"))
  m <- as.matrix(d)
  m
}

header_info <- function(m) {
  c1 <- str_squish(coalesce(m[, 1], ""))
  first_folio <- which(str_detect(tolower(c1), "^folio( [0-9]+[a-z]?)?$"))[1]
  first_num   <- which(str_detect(c1, "^[0-9]+$"))[1]
  hb <- min(c(first_folio, first_num), na.rm = TRUE) - 1
  H  <- m[seq_len(hb), , drop = FALSE]
  H[is.na(H)] <- ""
  H  <- matrix(str_squish(gsub("[\r\n]+", " ", H)), nrow = hb)
  nb <- apply(H, 1, function(r) any(str_detect(r, "^(NB|Spelling|Opgaafrol |1 July|Van den 1)")) &
                                  sum(r != "") <= 2)
  # note rows: one or two long free-text cells (e.g. "Stellenbosch 1792 J219 NB: ...")
  note <- apply(H, 1, function(r) sum(r != "") <= 2 && max(nchar(r)) > 25)
  H  <- H[!(nb | note), , drop = FALSE]
  # drop rows that are just column numbers (1804 has a numbering row)
  numrow <- apply(H, 1, function(r) mean(str_detect(r[r != ""], "^[0-9]+$")) > 0.8)
  H  <- H[!numrow, , drop = FALSE]
  # drop currency rows (£ s d)
  cur <- apply(H, 1, function(r) all(r[r != ""] %in% c("£", "s", "s.", "d", "d.")))
  H  <- H[!cur, , drop = FALSE]
  L <- if (nrow(H) >= 1) H[nrow(H), ] else rep("", ncol(m))
  T <- rep("", ncol(m))
  if (nrow(H) >= 2) {
    for (i in seq_len(nrow(H) - 1)) {
      r <- H[i, ]
      for (j in seq_along(r)[-1]) if (r[j] == "" && L[j] != "") r[j] <- r[j - 1]
      T <- str_squish(paste(T, r))
    }
  }
  # a column with only a top label: promote it
  only_top <- L == "" & T != ""
  list(hb = hb, L = tolower(L), T = tolower(T), raw_only_top = only_top)
}

# ---- column classification -------------------------------------------------
classify <- function(L, T) {
  lt <- paste(T, "/", L)
  tax  <- str_detect(L, "amount|tax|£|^s\\.?$|^d\\.?$")
  slvT <- str_detect(T, "slaven kinderen|^slave$|slaves|sla+ven|slaven/apprenticen|apprenticen ?/ ?slaves")
  sown <- str_detect(lt, "gesa|geza|sown|zaad")
  reap <- str_detect(lt, "gewon|reaped")
  case_when(
    tax ~ NA_character_,
    # slaves (age/sex split, 1804 onwards and English 1825-29)
    slvT & str_detect(L, "^(mannen|mans|males) (boven|above)") ~ "slave_men",
    slvT & str_detect(L, "^(mannen|mans|males) (beneden|below|under)") ~ "slave_boys",
    slvT & str_detect(L, "^(vrouwen|females) (boven|above)") ~ "slave_women",
    slvT & str_detect(L, "^(vrouwen|females) (beneden|below|under)") ~ "slave_girls",
    str_detect(L, "^(slaven|slaaven|slave)$") ~ "slave_men",
    str_detect(L, "^(slavinnen|slaavinnen|slavin)$") ~ "slave_women",
    str_detect(L, "^(slaaven )?(jongetjes|jongens|jonges|jong)$") ~ "slave_boys",
    str_detect(L, "^(slaaven )?(meisjes|meijsjes|meijsies|meijsjens|mijsies|meijsjes|meijd)$") ~ "slave_girls",
    str_detect(T, "^slave$|slaven kinderen") & L == "kinderen" ~ "slave_children",
    str_detect(T, "slave") & L == "kinderen" ~ "slave_children",
    # horses
    str_detect(L, "paard|horse") ~ "horses",
    str_detect(T, "horses") & str_detect(L, "riding|agricult|saddle|breeding|pleasure|trade|carriage") ~ "horses",
    L == "aanteel" & str_detect(T, "paarden$") ~ "horses",
    str_detect(T, "paarden$") & str_detect(L, "trek|ryd|rijd|wagen") ~ "horses",
    # sheep (before cattle: 'cattle / wethers' is a header-fill artifact)
    str_detect(L, "wether|hamel|wolge|spaansche|spanish|schaap|schap|^sheep") ~ "sheep",
    str_detect(T, "sheep$") & str_detect(L, "breeding") ~ "sheep",
    L == "aanteel" & str_detect(T, "schaapen$|schapen$") ~ "sheep",
    # cattle
    str_detect(L, "ossen|koeijen|koeien|^vaer|^vaar|^vars|kalver|kalven|calver|rund|beesten|hoornvee|^cattle|oxen") ~ "cattle",
    str_detect(T, "cattle$") & str_detect(L, "breeding") ~ "cattle",
    L == "aanteel" & str_detect(T, "runderen$") ~ "cattle",
    # grains: pre-1804 layout (crop on top, sown/reaped below); later layout (reaped on top, crop below)
    str_detect(L, "^gewon") & str_detect(T, "tarwe$") ~ "wheat",
    str_detect(L, "^gewon") & str_detect(T, "garst$") ~ "barley",
    str_detect(L, "^gewon") & str_detect(T, "rog(ge)?$") ~ "rye",
    str_detect(L, "^(tarwe|koorn|wheat)( gewonnen)?$") & reap & !sown ~ "wheat",
    str_detect(L, "^(garst|barley)( gewonnen)?$") & reap & !sown ~ "barley",
    str_detect(L, "^(rog|rogge|rye)( gewonnen)?$") & reap & !sown ~ "rye",
    str_detect(L, "^(haver|hawer|oats)$") & reap & !sown ~ "oats",
    str_detect(L, "^tarwe gewonnen$") ~ "wheat",
    str_detect(L, "^garst gewonnen$") ~ "barley",
    # 1842-44 headers carry no 'gewonnen' context; only reaped grain is recorded there
    str_detect(L, "^koorn$") & !sown & str_detect(T, "huisgezin|1 july|van den") ~ "wheat",
    str_detect(L, "^garst$") & !sown & str_detect(T, "huisgezin|1 july|van den") ~ "barley",
    str_detect(L, "^muids of barley, rye, oats and wheat reaped$|^muids reaped$") ~ "grain_all",
    # wine (leaguers), vines, brandy
    str_detect(L, "^(leggers )?(wijn|wyn|wine|wijnen)( gewonnen| made)?$") &
      !str_detect(T, "stok|stock") ~ "wine",
    str_detect(L, "leagers of wine|leggers wijn|leggers wyn") ~ "wine",
    L == "leggers" & str_detect(T, "wijn$") ~ "wine",
    L == "gewonnen" & str_detect(T, "leggers wijn$") ~ "wine",
    str_detect(L, "wijnstok|wynstok|wijngaard|^vines$|^stocken$|^stokken$") ~ "vines",
    str_detect(L, "brande|brandy") ~ "brandy",
    # other assets
    str_detect(L, "^(varken|varkens|varckens|varcken|pigs)$") ~ "pigs",
    str_detect(L, "^(bokken|goats)$") ~ "goats",
    str_detect(L, "^(ezels|asses.*)$") ~ "donkeys",
    str_detect(L, "^snaphaan|^snaphanen|snaphaanen") ~ "guns",
    str_detect(L, "^pistolen") ~ "pistols",
    str_detect(L, "^degens|^houwens") ~ "swords",
    str_detect(L, "^wagens$|4 wielen|on 4 wheels") ~ "wagons",
    str_detect(L, "^karren$|2 wielen|on 2 wheels") ~ "carts",
    str_detect(T, "hottentot|khoe") & str_detect(L, "mannen|mans") ~ "khoe_men",
    str_detect(T, "hottentot|khoe") & str_detect(L, "vrouwen") ~ "khoe_women",
    str_detect(L, "^knegts|^knechts|^knegt") ~ "knechts",
    str_detect(L, "^(zoonen|zoons|sons|sonen)") & !str_detect(T, "free|hottentot|prys|prijs|vry") ~ "settler_sons",
    str_detect(L, "^(dogters|dogteren|dochters|daughters)") & !str_detect(T, "free|hottentot|prys|prijs|vry") ~ "settler_daughters",
    TRUE ~ NA_character_
  )
}

# ---- name columns ----------------------------------------------------------
# Name columns are the text columns whose header names men/women (or names in general).
pick_name_cols <- function(L, T, body) {
  txt <- map_dbl(seq_len(ncol(body)), function(j) {
    v <- body[, j]; v <- v[!is.na(v) & str_squish(v) != ""]
    if (length(v) < 5) return(0)
    mean(str_detect(v, "[A-Za-z]{3,}"))
  })
  lt <- paste(T, L)
  is_men   <- str_detect(L, "^(name mannen|mannen|men|mans|mannen namen|names|surname|namen der christen mans|namen der bezitters|1\\. of the husband)") |
              str_detect(L, "mannen \\(alph|^men½|of the husband")
  is_women <- str_detect(L, "^(vrouwen|women|vrouw|vrouwen namen|namen der christen vrouwen|1\\. of the wives)")
  bad <- str_detect(L, "district|cornet|additional|ward|information|comment") |
         (str_detect(L, "plaatsen") & !str_detect(L, "bezitters"))
  cand <- which(txt > 0.6 & !bad)
  men <- cand[is_men[cand]][1]
  wom <- cand[is_women[cand]][1]
  if (is.na(men)) men <- cand[1]
  if (!is.na(wom) && wom == men) wom <- NA
  if (is.na(wom) && length(cand) >= 2 && !is.na(men)) {
    nxt <- cand[cand > men][1]
    if (!is.na(nxt) && nxt == men + 1 && !bad[nxt]) wom <- nxt
  }
  c(men = men, women = wom)
}

# ---- process one census -----------------------------------------------------
process_year <- function(y) {
  m  <- read_sheet(y)
  hi <- header_info(m)
  body <- m[(hi$hb + 1):nrow(m), , drop = FALSE]
  L <- hi$L; T <- hi$T
  L[hi$raw_only_top] <- word(T[hi$raw_only_top], -1, sep = fixed(" "))
  # columns 1 holds Nr./folio
  c1 <- str_squish(coalesce(body[, 1], ""))
  nc <- pick_name_cols(L, T, body)
  nm_men <- if (!is.na(nc["men"])) str_squish(body[, nc["men"]]) else rep(NA, nrow(body))
  nm_wom <- if (!is.na(nc["women"])) str_squish(body[, nc["women"]]) else rep(NA, nrow(body))
  lab <- classify(L, T)
  # Pre-1804 layout: crop label on top of a (sown, reaped) pair. The reaped column takes
  # the crop of the sown column to its left (fixes mislabelled tops, e.g. 1738).
  crop_of <- function(t) case_when(str_detect(t, "tarwe$") ~ "wheat", str_detect(t, "garst$") ~ "barley",
                                   str_detect(t, "rog(ge)?$") ~ "rye", TRUE ~ NA_character_)
  for (j in seq_along(L)[-1]) {
    if (str_detect(L[j], "^gewon") && str_detect(L[j - 1], "^(gez|ges)")) {
      cj <- crop_of(T[j - 1]); if (!is.na(cj)) lab[j] <- cj
    }
  }
  # Later layout without a 'gewonnen' top (1823): a crop listed twice -> the second is reaped.
  for (pat in c(wheat = "^(koorn|tarwe)$", barley = "^garst$", rye = "^(rog|rogge)$", oats = "^haver$")) {
    v <- names(which(c(wheat = "^(koorn|tarwe)$", barley = "^garst$", rye = "^(rog|rogge)$", oats = "^haver$") == pat))
    hits <- which(str_detect(L, pat))
    if (!(v %in% lab) && length(hits) == 2) lab[hits[2]] <- v
  }
  lab[c(1, nc[!is.na(nc)])] <- NA
  numcols <- which(!is.na(lab))
  # any numeric content in mapped columns
  vals <- map(numcols, ~ parse_num(body[, .x]))
  anynum <- if (length(vals)) Reduce(`|`, map(vals, ~ !is.na(.x) & .x != 0)) else rep(FALSE, nrow(body))
  has_name <- (!is.na(nm_men) & nm_men != "") | (!is.na(nm_wom) & nm_wom != "")
  junk <- str_detect(tolower(c1), "^(folio|nb|totaal|total|transport|somma|summa)") |
          str_detect(tolower(coalesce(nm_men, "")), "^(totaal|total|transport|somma|summa|folio)")
  is_hh <- !junk & (str_detect(c1, "^[0-9]+[a-z]?$") | has_name)
  tibble(row = seq_len(nrow(body)), year = as.integer(y), nr = c1,
         name_men = nm_men, name_women = nm_wom, is_hh = is_hh) |>
    bind_cols(
      if (length(numcols)) {
        long <- map2_dfr(numcols, vals, ~ tibble(row = seq_len(nrow(body)), var = lab[.x], v = .y))
        long |> group_by(row, var) |>
          summarise(v = if (all(is.na(v))) NA_real_ else sum(v, na.rm = TRUE), .groups = "drop") |>
          pivot_wider(names_from = var, values_from = v) |> arrange(row) |> select(-row)
      } else tibble(.rows = nrow(body))
    ) |>
    filter(is_hh) |> select(-is_hh) |>
    list(map = tibble(year = as.integer(y), col = seq_along(L), T = T, L = L, var = lab,
                      name_col = case_when(seq_along(L) == nc["men"] ~ "name_men",
                                           seq_along(L) == nc["women"] ~ "name_women",
                                           TRUE ~ NA_character_))) |>
    setNames(c("hh", "map"))
}

if (exists("CLEAN_LIB_ONLY")) stop_here <- TRUE else {
res <- map(years, process_year)
hh  <- map_dfr(res, "hh")
cmap <- map_dfr(res, "map")

# ---- missing-data rule (paper p.434-435) -----------------------------------
# A variable with no entry in a census is 'not recorded' (NA); if it has at least
# one entry, every other household in that census gets zero.
vars <- setdiff(names(hh), c("row", "year", "nr", "name_men", "name_women"))
hh <- hh |>
  group_by(year) |>
  mutate(across(all_of(vars), ~ if (all(is.na(.x))) NA_real_ else coalesce(.x, 0))) |>
  ungroup() |>
  mutate(hh_id = row_number())

saveRDS(hh, dscratch(PAPER, "repro_r", "households.rds"))

# ---- aggregate metadata (safe to keep in Dropbox) ---------------------------
write_csv(cmap |> filter(!is.na(var) | !is.na(name_col)), file.path(OUT, "column_map.csv"))
per_census <- hh |> group_by(year) |>
  summarise(n_rows = n(), n_named = sum(!is.na(name_men) | !is.na(name_women)),
            across(all_of(vars), ~ any(!is.na(.x)), .names = "rec_{.col}"))
write_csv(per_census, file.path(OUT, "per_census_counts.csv"))
cat("Censuses:", n_distinct(hh$year), " Household rows:", nrow(hh), "\n")
}
