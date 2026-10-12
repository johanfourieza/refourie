# P26_NF S3 independent recreation: 01_clean. Reads 1909 (race) and year-roll sheets, builds surname keys.
suppressMessages({library(readxl); library(dplyr); library(tidyr); library(stringr); library(here)})
source(here::here("tools", "paths.R"))
set.seed(1)
b <- dpath("P26_NF", "original")
scr <- dscratch("P26_NF", "repro_r")   # ./P26_NF/repro_r/_scratch/
nm <- c("folder","image","div","cornet","no","surname","first","prof","qual","sit","emp","race","italics")
rd <- function(f, s) {
  d <- read_excel(file.path(b, f), sheet = s, col_names = FALSE, .name_repair = "minimal", col_types = "text", skip = 1)
  while (ncol(d) < 13) d[[paste0("x", ncol(d))]] <- NA_character_
  d <- d[, 1:13]; names(d) <- nm; d$sheet <- paste(basename(f), s); d
}
# surname key: lower case, drop jun/sen suffixes and Dutch prefixes, letters only ("Zyl, van" == "van Zyl")
skey <- function(x) {
  x <- tolower(x); x <- gsub("[^a-z ]", " ", x)
  vapply(strsplit(x, "[[:space:]]+"), function(t) paste(t[!t %in% c("", "van","der","de","du","le","la","von","den","ten","te","jun","junr","jr","sen","senr","sr")], collapse = ""), "")
}
# ---- 1909 rolls with race: July 2018 sheets 59, 57 and Voters1 sheet 58
r09 <- bind_rows(rd("1870-1909/July 2018.xlsx", "59"), rd("1870-1909/July 2018.xlsx", "57"), rd("Laura Voters/Voters1.xls", "58")) |>
  filter(!is.na(surname), surname != ".") |>
  mutate(key = skey(surname), race = toupper(trimws(race)))
saveRDS(r09, file.path(scr, "r09.rds"))
# ---- year rolls (folder -> year assignment is an assumption, see decisions.md)
sheets <- list(c("1870-1909/July 2018.xlsx", c("18","22","24","28","30","34")), c("Laura Voters/Voters1.xls", c("19","21","25","33")))
yr <- bind_rows(lapply(sheets, function(s) bind_rows(lapply(s[-1], function(sh) rd(s[1], sh)))))
yr <- yr |> mutate(k = paste0(ifelse(grepl("July", sheet), "J", "V"), str_extract(sheet, "[0-9]+$"))) |>
  group_by(k) |> fill(div, .direction = "down") |> ungroup() |>
  filter(!is.na(surname), surname != ".") |>
  mutate(key = skey(surname), dl = tolower(div),
    division = case_when(
      grepl("kimber", dl) ~ "Kimberle", grepl("king w", dl) ~ "KingWill", grepl("port eliz", dl) ~ "PortEliz",
      grepl("queen", dl) ~ "Queensto", grepl("somerset", dl) ~ "Somerset", grepl("tembu", dl) ~ "Thembula",
      grepl("griqua", dl) ~ "Griquala", grepl("wodeho|woodho", dl) ~ "Wodehous", grepl("uitenh", dl) ~ "Uitenhag",
      grepl("victoria east", dl) ~ "Victoria", TRUE ~ NA_character_))
yearmap <- c(J18 = 1886, V19 = 1886, M21 = 1887, V21 = 1887, J22 = 1887, J24 = 1889, V25 = 1889, J30 = 1891, J28 = 1891, V33 = 1893, J34 = 1893)
yr$year <- unname(yearmap[yr$k])
saveRDS(yr, file.path(scr, "yr.rds"))
cat("1909 records:", nrow(r09), " year-roll records:", nrow(yr), "\n")
