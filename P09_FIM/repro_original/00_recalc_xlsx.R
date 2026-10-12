# P09_FIM S2 (EARLIER-VERSION run): environment step that replaces the missing
# "Whitelivingstandards dataset" (.dta). The 2015 do-files start with
# "*Use Whitelivingstandards dataset" and contain no load statement; the only
# surviving 2015 data are the sheet Data of Whitelivingstandards_7July.xlsx.
# This script re-evaluates the workbook formula chain from raw inputs with
# tidyxl (not cached values), checks it against the cached values, and writes a
# Stata file to _scratch. Excel's "." text (missing) becomes Stata missing, as a
# paste into the Stata data editor would do. Identifier columns not used by the
# do-files (names, surname, place, calling) are dropped (data minimisation).
# Output: aggregate check only (recalc_check.csv); no individual rows.

suppressMessages({library(tidyxl); library(dplyr); library(tidyr); library(stringr); library(haven); library(here)})
source(here::here("tools", "paths.R"))  # here() = project root (git repo)

f <- dpath("P09_FIM", "original", "FM White living standards", "Whitelivingstandards_7July.xlsx")
out_dta <- dscratch("P09_FIM", "repro_original", "whiteliving2015.dta")
out_chk <- here::here("P09_FIM", "repro_original", "recalc_check.csv")

cells <- xlsx_cells(f, sheets = c("Data", "Afrikaans", "Occu", "Place", "Towns 2"))

# Typed value per cell: type in {n,s,b,e}, num, chr
cv <- cells %>% transmute(sheet, row, col, formula,
  type = case_when(data_type == "numeric" ~ "n", data_type == "character" ~ "s",
                   data_type == "error" ~ "e", data_type == "logical" ~ "n", TRUE ~ "b"),
  num = ifelse(data_type == "logical", as.numeric(logical), numeric),
  chr = ifelse(data_type == "error", error, character))

grid <- function(sh, cols, rows = NULL) {
  g <- cv %>% filter(sheet == sh, col %in% cols)
  if (!is.null(rows)) g <- g %>% filter(row %in% rows)
  g
}
getcol <- function(sh, cl, rows) {
  g <- cv %>% filter(sheet == sh, col == cl)
  m <- match(rows, g$row)
  tibble(type = ifelse(is.na(m), "b", g$type[m]), num = g$num[m], chr = g$chr[m])
}

# Excel coercion of a value to number in arithmetic (blank -> 0, numeric text -> number)
to_num <- function(v) {
  out <- rep(NA_real_, nrow(v))
  out[v$type == "n"] <- v$num[v$type == "n"]
  out[v$type == "b"] <- 0
  s <- v$type == "s"
  out[s] <- suppressWarnings(as.numeric(str_trim(v$chr[s])))
  out
}
vstr <- function(v) ifelse(v$type == "n", paste0("n:", format(v$num, digits = 15, trim = TRUE)),
                    ifelse(v$type == "s", paste0("s:", v$chr), ifelse(v$type == "b", "b:", paste0("e:", v$chr))))
mk <- function(type, num = NA_real_, chr = NA_character_) tibble(type = type, num = num, chr = chr)

# VLOOKUP(key, table, k, FALSE): exact, case-insensitive for text, type-sensitive,
# first match; wildcards * ? in text keys; returned blank -> 0. Not found -> #N/A.
vlookup <- function(key, sh, keycol, retcol, rows) {
  kc <- getcol(sh, keycol, rows); rc <- getcol(sh, retcol, rows)
  kn <- ifelse(kc$type == "n", kc$num, NA); ks <- ifelse(kc$type == "s", tolower(kc$chr), NA)
  res <- mk(rep("e", nrow(key)), NA_real_, rep("#N/A", nrow(key)))
  idx <- rep(NA_integer_, nrow(key))
  isn <- key$type == "n"; idx[isn] <- match(key$num[isn], kn)
  iss <- key$type == "s"; kl <- tolower(key$chr)
  wild <- iss & str_detect(kl, "[*?~]")
  idx[iss & !wild] <- match(kl[iss & !wild], ks)
  for (i in which(wild)) {
    rx <- paste0("^", str_replace_all(str_replace_all(kl[i], "([.\\\\+^$()\\[\\]{}|])", "\\\\\\1"), c("\\*" = ".*", "\\?" = ".")), "$")
    hit <- which(!is.na(ks) & str_detect(ks, rx)); idx[i] <- if (length(hit)) hit[1] else NA
  }
  ok <- !is.na(idx)
  res$type[ok] <- rc$type[idx[ok]]; res$num[ok] <- rc$num[idx[ok]]; res$chr[ok] <- rc$chr[idx[ok]]
  bl <- ok & res$type == "b"; res$type[bl] <- "n"; res$num[bl] <- 0
  attr(res, "nwild") <- sum(wild)
  res
}
iferror <- function(v, alt) { e <- v$type == "e"; v$type[e] <- alt$type; v$num[e] <- alt$num; v$chr[e] <- alt$chr; v }
proper <- function(x) {
  x <- tolower(x)
  str_replace_all(x, "(^|[^a-z])([a-z])", function(m) paste0(substr(m, 1, nchar(m) - 1), toupper(substr(m, nchar(m), nchar(m)))))
}

checks <- list()
chk <- function(name, sh, cl, new, rows) {
  old <- getcol(sh, cl, rows)
  fr <- cv %>% filter(sheet == sh, col == cl, row %in% rows) %>% pull(formula)
  # numeric tolerance
  same <- vstr(old) == vstr(new) | (old$type == "n" & new$type == "n" & abs(old$num - new$num) < 1e-9)
  checks[[length(checks) + 1]] <<- tibble(sheet = sh, column = name, formula_cells = length(rows),
                                          mismatches = sum(!same, na.rm = TRUE))
}
frows <- function(sh, cl) cv %>% filter(sheet == sh, col == cl, !is.na(formula)) %>% pull(row) %>% sort()

## --- 1. Lookup sheets ---------------------------------------------------------
# Afrikaans!B = PROPER(A)
ra <- frows("Afrikaans", 2); a_in <- getcol("Afrikaans", 1, ra)
a_new <- mk(ifelse(a_in$type == "b", "s", "s"), NA, ifelse(a_in$type == "b", "", proper(ifelse(a_in$type == "n", format(a_in$num), a_in$chr))))
chk("Afrikaans!B PROPER", "Afrikaans", 2, a_new, ra)
cv <- cv %>% rows_update(tibble(sheet = "Afrikaans", row = ra, col = 2L, type = a_new$type, chr = a_new$chr), by = c("sheet", "row", "col"), unmatched = "ignore")

# Occu!C = IFERROR(ROUNDDOWN(INT(B/10),1),".")
ro <- frows("Occu", 3); b <- to_num(getcol("Occu", 2, ro))
o_new <- mk(ifelse(is.na(b), "s", "n"), ifelse(is.na(b), NA, floor(b / 10)), ifelse(is.na(b), ".", NA))
chk("Occu!C hisco", "Occu", 3, o_new, ro)
cv <- cv %>% rows_update(tibble(sheet = "Occu", row = ro, col = 3L, type = o_new$type, num = o_new$num, chr = o_new$chr), by = c("sheet", "row", "col"), unmatched = "ignore")

# Place!C (formula rows) = IFERROR(VLOOKUP(A, A$4:C$505, 3, FALSE), "")
rp <- frows("Place", 3)
p_new <- iferror(vlookup(getcol("Place", 1, rp), "Place", 1, 3, 4:505), mk("s", NA, ""))
chk("Place!C region", "Place", 3, p_new, rp)
cv <- cv %>% rows_update(tibble(sheet = "Place", row = rp, col = 3L, type = p_new$type, num = p_new$num, chr = p_new$chr), by = c("sheet", "row", "col"), unmatched = "ignore")

## --- 2. Data sheet -------------------------------------------------------------
R <- 2:max(cv$row[cv$sheet == "Data"])
D <- function(cl) getcol("Data", cl, R)
upd <- function(cl, v) {
  rr <- frows("Data", cl); m <- match(rr, R)
  chk(paste0("Data col ", cl), "Data", cl, v[m, ], rr)
  cv <<- cv %>% rows_update(tibble(sheet = "Data", row = rr, col = as.integer(cl), type = v$type[m], num = v$num[m], chr = v$chr[m]), by = c("sheet", "row", "col"), unmatched = "ignore")
}
# E Afrikaans = IFERROR(VLOOKUP(D, Afrikaans!B2:C1013, 2, FALSE), "0")
afr <- iferror(vlookup(D(4), "Afrikaans", 2, 3, 2:1013), mk("s", NA, "0")); nw_afr <- attr(afr, "nwild"); upd(5, afr)
# G Repeat = IF((C&D)=(C[-1]&D[-1]),1,0)   (Excel "=" on text is case-insensitive)
txt <- function(v) ifelse(v$type == "n", format(v$num, digits = 15, trim = TRUE), ifelse(v$type == "s", v$chr, ""))
cd <- tolower(paste0(txt(D(3)), txt(D(4))))
rep_new <- mk("n", c(NA, as.numeric(cd[-1] == cd[-length(cd)])))
upd(7, rep_new)
# N Birthyear = IF(J="","",IFERROR(J-ROUNDDOWN(M,0),""))
J <- D(10); M <- D(13); jn <- to_num(J); mn <- to_num(M)
by_new <- mk(ifelse(J$type == "b" | is.na(jn) | is.na(mn), "s", "n"), jn - trunc(mn), ifelse(J$type == "b" | is.na(jn) | is.na(mn), "", NA))
by_new$num[by_new$type == "s"] <- NA
upd(14, by_new)
# R HISCO = IFERROR(VLOOKUP(Q, Occu!A2:H11653, 3, FALSE), "")
his <- iferror(vlookup(D(17), "Occu", 1, 3, 2:11653), mk("s", NA, "")); nw_his <- attr(his, "nwild"); upd(18, his)
# S Class = IF(R=".",".",IF(R<6,1,IF(R=6,0,2)))  (text > any number in Excel comparisons)
Rv <- D(18); rn <- ifelse(Rv$type == "n", Rv$num, ifelse(Rv$type == "b", 0, NA))
cls <- mk(ifelse(Rv$type == "s" & Rv$chr == ".", "s", "n"), ifelse(is.na(rn), 2, ifelse(rn < 6, 1, ifelse(rn == 6, 0, 2))), ifelse(Rv$type == "s" & Rv$chr == ".", ".", NA))
cls$num[cls$type == "s"] <- NA; upd(19, cls)
# T Farmer = IF(S=".",".",IF(S=0,1,0))
Sv <- D(19); fa <- mk(ifelse(Sv$type == "s" & Sv$chr == ".", "s", "n"), ifelse(Sv$type == "n" & Sv$num == 0, 1, 0), ifelse(Sv$type == "s" & Sv$chr == ".", ".", NA))
fa$num[fa$type == "s"] <- NA; upd(20, fa)
# V Region = [IFERROR(]VLOOKUP(U, Place!A2:C1500 | A2:C505, 3, FALSE)[,"")]
rr22 <- frows("Data", 22); f22 <- cv %>% filter(sheet == "Data", col == 22, !is.na(formula)) %>% arrange(row)
U <- D(21)
reg_a <- iferror(vlookup(U, "Place", 1, 3, 2:1500), mk("s", NA, ""))
reg_b <- vlookup(U, "Place", 1, 3, 2:505)
use_b <- R %in% f22$row[str_detect(f22$formula, "C\\$505")]
reg <- reg_a; reg[use_b, ] <- reg_b[use_b, ]; upd(22, reg)
# X Urban = IFERROR(VLOOKUP(U, 'Towns 2'!C1:E1310, 3, FALSE), ".")
urb <- iferror(vlookup(U, "Towns 2", 3, 5, 1:1310), mk("s", NA, ".")); upd(24, urb)
# AC Black = IF(AA=".",".",IF(AA<5,0,1))
AA <- D(27); an <- ifelse(AA$type == "n", AA$num, ifelse(AA$type == "b", 0, NA))
blk <- mk(ifelse(AA$type == "s" & AA$chr == ".", "s", "n"), ifelse(is.na(an), 1, ifelse(an < 5, 0, 1)), ifelse(AA$type == "s" & AA$chr == ".", ".", NA))
blk$num[blk$type == "s"] <- NA; upd(29, blk)

chk_tab <- bind_rows(checks) %>% mutate(wildcard_keys = case_when(column == "Data col 5" ~ nw_afr, column == "Data col 18" ~ nw_his, TRUE ~ NA_integer_))
write.csv(chk_tab, out_chk, row.names = FALSE)
print(chk_tab)

## --- 3. Build the Stata dataset (recalculated values) -------------------------
hdr <- cv %>% filter(sheet == "Data", row == 1) %>% arrange(col)
keep <- c(Source = 1, Sourcedum = 2, Afrikaans = 5, Repeat = 7, Day = 8, Month = 9, Year = 10, HeightOriginal = 12,
          Age = 13, Birthyear = 14, Height = 15, Weight = 16, HISCO = 18, Class = 19, Farmer = 20, Regiondum = 23,
          Urban = 24, Nationalitydum = 27, Sadummy = 28, Black = 29, by1 = 30, by2 = 31, by3 = 32, by4 = 33, by5 = 34, by6 = 35)
dat <- tibble(.rows = length(R))
for (nm in names(keep)) {
  v <- D(keep[[nm]])
  n <- to_num(v)                               # numeric text -> number
  miss <- v$type == "b" | (v$type == "s" & str_trim(v$chr) %in% c(".", ""))
  nonnum <- !miss & is.na(n)
  if (any(nonnum) && nm != "Source") message(nm, ": ", sum(nonnum), " non-numeric cells -> kept as string")
  dat[[tolower(nm)]] <- if (nm == "Source" || any(nonnum)) ifelse(v$type == "n", format(v$num), ifelse(miss, "", v$chr)) else ifelse(miss, NA_real_, n)
}
write_dta(dat, out_dta, version = 13)
cat("Wrote", nrow(dat), "rows,", ncol(dat), "vars to", out_dta, "\n")
