# P24_MGF S3 rebuild, step 1: clean the two surviving inputs.
# (a) Supplementary Data - DATA POPULATION (authors' published table of under-five
#     males/females by race, 1894-2011), transcribed with pdftotext -raw.
# (b) Kimberley death-register transcriptions, 1895-1940 (personal data: the
#     cleaned row-level file stays on D:; only aggregates go to output/).
suppressMessages({library(tidyverse); library(readxl); library(here)})

P <- "P24_MGF"
source(here::here("tools", "paths.R"))  # here() is the project root

orig <- dpath(P, "original")

## (a) Supplementary population table ------------------------------------
pdf <- file.path(orig, "Missing boys", "Supplementary Data - DATA POPULATION (2020_06_29 14_42_57 UTC).pdf")
txt <- system2("pdftotext", c("-raw", shQuote(pdf), "-"), stdout = TRUE)
rows <- txt[grepl("^(1894|1904|19[1-9][0-9]|20[01][0-9])", txt)]
supp <- map_dfr(rows, function(r) {
  yr <- as.integer(substr(r, 1, 4))
  nums <- str_extract_all(sub("^[0-9]{4}[*]?( [(]Cape[)])?", "", r), "[0-9]+([.][0-9]+)?")[[1]]
  stopifnot(length(nums) == 9)
  v <- as.numeric(nums)
  tibble(year = yr, race = c("black", "coloured", "white"),
         males = v[c(1, 4, 7)], females = v[c(2, 5, 8)], sr_printed = v[c(3, 6, 9)])
})
stopifnot(nrow(supp) == 39)
write_csv(supp, here::here(P, "repro_r", "output", "supp_population_transcribed.csv"))  # published aggregates

## (b) Kimberley death registers ------------------------------------------
dd <- file.path(orig, "Death")
# Non-duplicated sources: 1895 file; 1900 sheet of the 1900 workbook (its 1895 sheet
# repeats the 1895 file); the combined 1905+1910 workbook; 1925-1940 files. The
# alternative 1905 transcription (2020-04 AF ...) and the one-row template are not used.
src <- tribble(~file, ~sheet,
  "Kimberley 1895.xlsx", "1895",
  "Kimberley 1900.xlsx", "1900",
  "Kimberley 1905 and 1910.xlsx", "Sheet1",
  "Martie 1925 Kimberley (1100).xlsx", "Paarl",
  "Martie en Nicola 1930 Kimberley (1217) 1081.xlsx", "Kimberley",
  "Nicola en Martie 1935 Kimberley (1118).xlsx", "Kimberley",
  "Martie 1940 Kimberley (1321).xlsx", "Kimberley")
raw <- pmap_dfr(src, function(file, sheet) {
  x <- suppressMessages(read_excel(file.path(dd, file), sheet = sheet, col_types = "text"))
  tibble(file = file, reg_year = x$Year, sex_raw = x$Sex, age_raw = x$Age, race_raw = x$Race)
})

sex_map <- function(s) {
  s <- str_to_lower(str_squish(s))
  case_when(str_detect(s, "^(male|manlik|mannelik|boy|seun)") ~ "M",
            str_detect(s, "female|^vrou|^girl") ~ "F",
            TRUE ~ NA_character_)
}

# Age in months. Bare numbers are years. "Adult" etc. -> NA (not a child).
age_months <- function(a) {
  a <- str_to_lower(str_squish(a))
  a <- a |> str_replace_all(" ?\u00bd", ".5") |> str_replace_all(" ?\u00bc", ".25") |> str_replace_all(" ?\u00be", ".75") |>
    str_replace_all("([0-9]) ?1/2", "\\1.5") |> str_replace_all("^1/2", "0.5") |>
    str_replace_all("^1/365 ", "0.0027 ") |> str_replace_all("^15/12 ", "1.25 ") |> str_replace_all("^2 1/3 ", "2.33 ") |>
    str_replace_all("^four weeks$", "4 weeks") |> str_replace_all("^few days$|immediately after birth", "0 days") |>
    str_replace_all("[?()]|\\bsic\\b|\\babout\\b|\\babt\\b|\\+", " ") |> str_replace_all("([0-9])o\\b", "\\10") |>
    str_replace_all("\\b2o\\b", "20") |> str_squish()
  # every number-word pair; the unit is classified by the word's first letters (tolerates typos)
  one <- function(s) {
    if (is.na(s)) return(NA_real_)
    if (str_detect(s, "^[0-9]+([.][0-9]+)?$")) return(as.numeric(s) * 12)       # bare number = years
    if (str_detect(s, "min|sec|hour|houer|uur|ure|new|born|still|prem")) return(0) # under a day
    m <- str_match_all(s, "([0-9]+(?:[.][0-9]+)?) *([a-z]*)")[[1]]
    if (nrow(m) == 0) return(NA_real_)
    v <- as.numeric(m[, 2]); u <- m[, 3]
    f <- case_when(str_detect(u, "^(mi|se|h)") ~ 0,
                   str_detect(u, "^d") ~ 1 / 30.44,
                   str_detect(u, "^w") ~ 7 / 30.44,
                   str_detect(u, "^m") ~ 1,
                   str_detect(u, "^(y|j|e|t|u)") ~ 12,
                   u == "" & nrow(m) == 1 ~ 12,
                   TRUE ~ NA_real_)
    sum(v * f)
  }
  map_dbl(a, one)
}

race_map <- function(r) {
  r <- str_to_lower(str_squish(r))
  r <- str_remove(r, "^[(](native|coloured|european)[)] *")  # keep the specific label
  case_when(
    r %in% c(".", "illegible", "unknown", "", "male", "single") | is.na(r) ~ NA_character_,
    str_detect(r, "europ|white|blanke|^wit|dutch|english|ireland|irish|scot|german|brit|french|jew|russ|swed|norw|americ|austral") ~ "white",
    str_detect(r, "mixed|colou?r|coulou?r|groq|kleurling|hottentot|malay|gri[a-z]*a$|griq|grique|koran|korona|basta+rd|boesman|cape|st[.]? helena|bushman|namaqua|gonah|gemeng") ~ "coloured",
    str_detect(r, "india|asiatic|chin|arab|mauritian|syrian|japan|abyssin") ~ "asian_other",
    str_detect(r, "blantyre|natvie|negro|nyeka|onorolong|sesuto|swahil|tanganyika|zanzibar|kosa|fongo|beacuana|buchuana|bochwe|musuthu|m' ?c?k?l[ae]p|m'clep|leao?wa|gattharo|kuruman|^b|^m") ~ "black",
    str_detect(r, "kaf|native|bantu|bechuana|basuto|fingo|zulu|xosa|xhosa|morolong|marolong|barolong|batlap|matlap|motlap|batlhap|shangaan|inhamba|pondo|tembu|mosuto|mochuana|baca|swazi|matabele|mashona|bakwena|mokwena|mangwato|bamangwato|hlubi|gaika|galeka|zambesi|nyasa|portuguese east|mozambique|tonga|mpondo|bavenda|venda|shona|bakhatla|bataung|motaung|bahurutse|morolong|bapedi|mopedi|pedi|damara|herero|ovambo|langeberg|batlaro|motlhaping|mohurutse|mokgatla|mangwato|lovedu|baralong|bechuana|^ba|^mo|^ma") ~ "black",
    TRUE ~ NA_character_)
}

kim <- raw |> mutate(sex = sex_map(sex_raw), age_m = age_months(age_raw), race = race_map(race_raw),
                     reg_year = as.integer(reg_year))
saveRDS(kim, dpath(P, "repro_r", "kimberley_clean.rds"))   # row-level, local only

# Diagnostics (aggregates of labels only, no individual rows)
diag_dir <- dscratch(P, "repro_r")
kim |> count(file, name = "records") |> write_csv(here::here(P, "repro_r", "output", "kimberley_records_by_file.csv"))
kim |> filter(is.na(age_m)) |> count(age_raw, sort = TRUE) |> write_csv(file.path(diag_dir, "age_unparsed.csv"))
kim |> filter(age_m < 60 | is.na(age_m)) |> filter(is.na(race)) |> count(race_raw, sort = TRUE) |> write_csv(file.path(diag_dir, "race_unmapped.csv"))
kim |> filter(is.na(sex)) |> count(sex_raw, sort = TRUE) |> write_csv(file.path(diag_dir, "sex_unmapped.csv"))
kim |> count(race_raw, race, sort = TRUE) |> write_csv(here::here(P, "repro_r", "output", "race_crosswalk_counts.csv"))
cat("records:", nrow(kim), "\n")
