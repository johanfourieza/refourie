# P08_SAC S2: build results_original.csv (source = "original").
# Run from the project root:  Rscript P08_SAC/repro_original/extract_results.R
# Inputs:
#   (1) output/fullprec/fgm_fullprec.txt  - full-precision estout export of the verbatim Occupations.do run (Table 3)
#   (2) Descriptives.xlsx                 - Excel formula chains, re-implemented and recalculated from their input cells
# Every other claim is set to `unavailable` with a reason (no code; workbook cells are pasted values only).
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tidyxl); library(stringr); library(purrr) })
source("tools/paths.R")
P  <- "P08_SAC"
RO <- file.path(P, "repro_original")
claims <- read_csv(file.path(P, "claims", "claims.csv"), col_types = cols(.default = "c"))

# ---------------------------------------------------------------- (1) Table 3 from the Stata run
L <- readLines(file.path(RO, "output", "fullprec", "fgm_fullprec.txt"))
sp <- str_split(L, "\t")
body <- keep(sp[-(1:2)], ~ length(.x) >= 16)
est <- map_dfr(body, function(r) {
  tibble(term = r[1], spec = 1:5,
         b  = suppressWarnings(as.numeric(r[seq(2, 16, 3)])),
         se = suppressWarnings(as.numeric(r[seq(3, 16, 3)])),
         t  = suppressWarnings(as.numeric(r[seq(4, 16, 3)])))
})
stats <- keep(sp, ~ .x[1] %in% c("r2", "N"))
st <- map_dfr(stats, function(r) { v <- suppressWarnings(as.numeric(r[-1])); v <- v[!is.na(v)]
  tibble(term = r[1], spec = 1:5, val = v[1:5]) })

termmap <- c(afrikaans = "afrikaans", age = "age", height = "height", weight = "weight", married = "married",
  setNames(paste0(c(0:5, 7:9), ".hisco"), paste0("hisco", c(0:5, 7:9))),
  england = "1.regiondum", americas = "2.regiondum", asia = "3.regiondum", australasia = "4.regiondum",
  europe = "6.regiondum", ireland = "7.regiondum", scotland = "8.regiondum", capecolonynatal = "9.regiondum",
  wales = "10.regiondum", setNames(paste0(1901:1907, ".eyear"), as.character(1901:1907)), constant = "_cons")

t3 <- claims |> filter(str_detect(claim_id, "^T3_")) |>
  mutate(m = str_match(claim_id, "^T3_([a-z0-9]+)_s([1-5])(_t)?$"),
         key = m[, 2], spec = as.integer(m[, 3]), is_t = !is.na(m[, 4]))
t3_res <- pmap_dfr(list(t3$claim_id, t3$key, t3$spec, t3$is_t), function(id, k, s, is_t) {
  if (k == "r2") return(tibble(claim_id = id, value = st$val[st$term == "r2" & st$spec == s], se = NA, n = st$val[st$term == "N" & st$spec == s]))
  if (k == "n")  return(tibble(claim_id = id, value = st$val[st$term == "N" & st$spec == s], se = NA, n = st$val[st$term == "N" & st$spec == s]))
  r <- est |> filter(term == termmap[[k]], spec == s)
  nn <- st$val[st$term == "N" & st$spec == s]
  if (is_t) tibble(claim_id = id, value = r$t, se = NA, n = nn) else tibble(claim_id = id, value = r$b, se = r$se, n = nn)
}) |> mutate(status_override = NA_character_,
             note = "Occupations.do run verbatim (StataNow 19.5, version 13) on the imported Augmented sheet; output/fgm.txt = authors' fgm.txt",
             cause = NA_character_)
# Printed t-statistics of non-negative coefficients carry a spurious minus sign in the paper (claims spec (e) item 4).
pos_t <- t3_res$claim_id[str_detect(t3_res$claim_id, "_t$")]
t3_res <- t3_res |> mutate(cause = ifelse(claim_id %in% pos_t & value > 0, "rounding-or-transcription-in-paper", cause),
  note = ifelse(claim_id %in% pos_t & value > 0,
    paste0(note, "; paper prints this positive t as negative: the '(x)' strings from estout were converted to -x when pasted into Excel (Descriptives.xlsx 'New Wage regression')"), note))

# ---------------------------------------------------------------- (2) Descriptives.xlsx formula chains
cells <- xlsx_cells(dpath(P, "original", "FGM The SAC", "Descriptives.xlsx")) |> filter(!is_blank)
key <- function(s, a) paste(s, a, sep = "!")
val <- setNames(cells$numeric, key(cells$sheet, cells$address))
frm <- setNames(cells$formula, key(cells$sheet, cells$address))
a2rc <- function(a) { a <- gsub("$", "", a, fixed = TRUE); l <- str_extract(a, "^[A-Z]+"); r <- as.integer(str_extract(a, "[0-9]+$"))
  c <- sum((utf8ToInt(l) - 64) * 26^(rev(seq_len(nchar(l))) - 1)); c(r, c) }
rc2a <- function(r, c) { s <- ""; while (c > 0) { m <- (c - 1) %% 26; s <- paste0(LETTERS[m + 1], s); c <- (c - 1) %/% 26 }; paste0(s, r) }
ev <- function(s, a) {   # recursive re-implementation of the four formula forms used in the workbook
  k <- key(s, gsub("$", "", a, fixed = TRUE)); f <- frm[k]
  if (is.na(f)) return(unname(val[k]))     # input cell (pasted value)
  f <- gsub("$", "", f, fixed = TRUE)
  if (str_detect(f, "^SUM\\([A-Z]+[0-9]+:[A-Z]+[0-9]+\\)$")) {
    ab <- str_match(f, "^SUM\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)$")[, 2:3]; p1 <- a2rc(ab[1]); p2 <- a2rc(ab[2])
    g <- expand.grid(r = p1[1]:p2[1], c = p1[2]:p2[2]); return(sum(map2_dbl(g$r, g$c, ~ { v <- ev(s, rc2a(.x, .y)); ifelse(is.na(v), 0, v) })))
  }
  m <- str_match(f, "^([A-Z]+[0-9]+|[0-9.]+)([-+*/])([A-Z]+[0-9]+|[0-9.]+)$")
  if (is.na(m[1])) stop("unhandled formula ", s, "!", a, ": ", f)
  opnd <- function(z) if (str_detect(z, "^[A-Z]")) ev(s, z) else as.numeric(z)
  x <- opnd(m[2]); y <- opnd(m[4])
  switch(m[3], "/" = x / y, "-" = x - y, "+" = x + y, "*" = x * y)
}
fc <- cells |> filter(!is.na(formula))
fc$recalc <- map2_dbl(fc$sheet, fc$address, ev)
chk <- fc |> summarise(n_formula = n(), max_abs_diff_vs_cached = max(abs(recalc - numeric), na.rm = TRUE))
write_csv(fc |> group_by(sheet) |> summarise(n_formula = n(), max_abs_diff = max(abs(recalc - numeric))),
          file.path(RO, "output", "descriptives_recalc_check.csv"))
rv <- function(s, a) ev(s, a)

xl <- list()
add <- function(id, s, a, mult = 100, note) xl[[length(xl) + 1]] <<- tibble(claim_id = id, value = rv(s, a) * mult, se = NA_real_, n = NA_real_,
  status_override = NA_character_, note = paste0("Descriptives.xlsx '", s, "'!", a, " recalculated from input cells (", frm[key(s, a)], "); ", note), cause = NA_character_)
# Table 4: Occupations!H26:P28 (classes 1-3 x enlistment year; O26:O28 = total shares, computed from P20:P23 which include the 16 recruits of 1907)
yrs <- c(`1900` = "H", `1901` = "I", `1902` = "J", `1903` = "K", `1904` = "L", `1905` = "M", `1906` = "N", total = "O")
cls <- c(farmers = 26, whitecollar = 27, bluecollar = 28)
for (k in names(cls)) for (y in names(yrs)) add(paste0("T4_", k, "_", y), "Occupations", paste0(yrs[[y]], cls[[k]]), note = "class share by year (inputs: pasted Stata tab counts)")
# Table 5: Occupations!N41:X43 (classes x region of birth)
reg5 <- c(Americas = "N", Asia = "O", Australasia = "P", Boerrepublics = "Q", England = "R", Europe = "S", Ireland = "T",
          Scotland = "U", SouthernAfrica = "V", Wales = "W", Total = "X")
c5 <- c(farmers = 41, uppermiddle = 42, lower = 43)
for (k in names(c5)) for (r in names(reg5)) add(paste0("T5_", r, "_", k), "Occupations", paste0(reg5[[r]], c5[[k]]), note = "class share by region (inputs: pasted Stata tab counts)")
# Table 7: Sheet2!B15:L24 (HISCO major group x region, column shares)
reg7 <- c(america = "B", asia = "C", australasia = "D", boerrep = "E", england = "F", europe = "G", ireland = "H",
          scotland = "I", capecolonynatal = "J", wales = "K", total = "L")
for (h in 0:9) for (r in names(reg7)) add(sprintf("T7_h%d_%s", h, r), "Sheet2", paste0(reg7[[r]], 15 + h), note = "HISCO major-group column share (inputs: pasted Stata tab counts)")
# Text: place of enlistment (share of non-missing places), Enlistment!F
add("tx_p584_heidelberg", "Enlistment", "F14", note = "share of non-missing place of enlistment (F4 = B57-B3)")
add("tx_p584_pretoria",   "Enlistment", "F33", note = "share of non-missing place of enlistment")
add("tx_p584_modder",     "Enlistment", "F23", note = "share of non-missing place of enlistment")
add("tx_p584_autumn",     "Enlistment", "N23", mult = 1, note = "sum of March-May percentages (pasted Stata tab)")
# Text: country of birth shares, Personal characteristis!C (= pasted Stata percent / 100; rescale only)
pc <- c(tx_p584_england = "C11", tx_p584_scotland = "C32", tx_p584_ireland = "C19", tx_p585_wales = "C42", tx_p585_cape = "C6",
        tx_p585_natal = "C26", tx_p585_ofs = "C29", tx_p585_tvl = "C39", tx_p585_sa_pct = "C34", tx_p585_aus_pct = "C3", tx_p585_can_pct = "C5")
for (i in names(pc)) add(i, "Personal characteristis", pc[[i]], note = "rescale-only formula (D/100) of a pasted Stata tab percentage")
add("tx_p588_age_all", "Personal characteristis", "K7", mult = 1, note = "mean agen (days) / 365 (inputs: pasted Stata summarize)")
# Text: cause of exit, Discharge!E (= pasted Stata percent / 100; rescale only)
dc <- c(tx_p588_exit_expired = "E13", tx_p588_exit_purchase = "E10", tx_p588_exit_free = "E5", tx_p588_exit_dismiss = "E4",
        tx_p588_exit_unfit = "E6", tx_p588_exit_retrench = "E12", tx_p588_exit_transfer = "E14", tx_p588_exit_desert_pct = "E3")
for (i in names(dc)) add(i, "Discharge", dc[[i]], note = "rescale-only formula (F/100) of a pasted Stata tab percentage")
xl_res <- bind_rows(xl) |>
  mutate(cause = ifelse(claim_id == "tx_p585_sa_pct", "rounding-or-transcription-in-paper", cause),
         note  = ifelse(claim_id == "tx_p585_sa_pct", paste0(note, "; workbook 0.78 per cent prints as 0.7 in the text (truncated, not rounded)"), note))

# ---------------------------------------------------------------- (3) everything else: unavailable
why <- function(id) case_when(
  str_detect(id, "^T1_") ~ "Table 1: no code; Descriptives.xlsx 'Table' holds pasted values only (no formulas)",
  str_detect(id, "^T2_") ~ "Table 2: no code; Descriptives.xlsx 'Discharge' I:Q holds pasted values only",
  str_detect(id, "^T6_") ~ "Table 6: no code; Descriptives.xlsx 'Occupations' minor-group block (total 8,776 at K138) is pasted values only",
  id %in% c("tx_p594_gap_dutch", "tx_p594_gap_boer") ~ "text wage gaps: no code produces them; they equal the Spec (4) Afrikaans (-0.051) and Boer Republics (-0.086) coefficients of the superseded 'Wage regression' sheet (England reference), not published Table 3",
  id %in% c("tx_p586_youngest", "tx_p586_oldest") ~ "no formula maps to the text; the only age-range formula ('Personal characteristis'!H7:I7, agen/365) gives 14.38 and 52.76",
  id %in% c("tx_p591_ht_dutch", "tx_p591_ht_eng", "tx_p591_ht_dutch_n", "tx_p591_ht_eng_n") ~ "no code; Descriptives.xlsx 'Afrikaans' holds pasted means only (174.98/174.77, no N); TimeToShine.do builds the height sample but computes no means",
  TRUE ~ "no code or formula chain produces this number (text value; any workbook source is pasted values only)")
done <- c(t3_res$claim_id, xl_res$claim_id)
rest <- claims |> filter(!claim_id %in% done) |>
  transmute(claim_id, value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable", note = why(claim_id), cause = NA_character_)

out <- bind_rows(t3_res, xl_res, rest) |> mutate(source = "original") |>
  select(claim_id, source, value, se, n, status_override, note, cause)
stopifnot(!anyDuplicated(out$claim_id), setequal(out$claim_id, claims$claim_id))
write_csv(out, file.path(RO, "results_original.csv"), na = "")
cat("Formula cells recalculated:", chk$n_formula, " max |recalc - cached| =", signif(chk$max_abs_diff_vs_cached, 3), "\n")
print(count(out, attempted = is.na(status_override)))
