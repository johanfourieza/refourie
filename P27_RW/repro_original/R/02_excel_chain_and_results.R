# P27_RW S2: reimplement the ChapterValue.xlsx chain (Prices2 median x counts -> Value2 -> total -> decade descriptives),
# Table 1 totals, Cape ownership shares for T6-T8, and assemble results_original.csv.
# Run from the project root: Rscript P27_RW/repro_original/R/02_excel_chain_and_results.R
suppressMessages({library(tidyxl);library(dplyr);library(readr);library(haven);library(tidyr);library(stringr)})
source("tools/paths.R"); set.seed(1)
D <- dpath("P27_RW","original","Data"); OUT <- "P27_RW/repro_original"
SC <- dscratch("P27_RW","repro_original")
cl <- read_csv("P27_RW/claims/claims.csv", show_col_types=FALSE, col_types=cols(.default="c"))
res <- tibble(claim_id=cl$claim_id, source="original", value=NA_real_, se=NA_real_, n=NA_real_,
              status_override="unavailable", note="No surviving calculation chain for this claim (S1/S2)")
put <- function(id, v, n=NA, note="") { i <- match(id, res$claim_id); if (is.na(i)) return(invisible())
  res$value[i] <<- v; res$n[i] <<- n; res$status_override[i] <<- NA_character_; res$note[i] <<- note }
cmp <- list()

## ---- Stata outputs: Table 3, Table 4 ----
st <- read_csv(file.path(SC,"stata_out.csv"), show_col_types=FALSE, col_types=cols(claim_id="c",value="d",n="d"))
for (i in seq_len(nrow(st))) if (st$claim_id[i] %in% res$claim_id) put(st$claim_id[i], st$value[i], st$n[i], "Stata 01_descriptives.do")
g <- function(id) st$value[st$claim_id==id]
put("text_n_inv", g("T3_slaves_n"), g("T3_slaves_n"), "Stata: N non-missing")
put("text_bedsteads_mean", g("T3_bedsteads_mean"), g("T3_slaves_n"), "Stata")
put("text_chairs_mean", g("T3_chairs_mean"), g("T3_slaves_n"), "Stata")
put("text_opg_slaves_mean", g("T4_incl_opg_slaves_mean"), g("T4_incl_opg_slaves_n"), "Stata, jaar 1700-73")
put("text_opg_zero_slaves", g("T4_incl_opg_slaves_zeros"), g("T4_incl_opg_slaves_n"), "Stata")
put("text_inv_zero_slaves", g("T3_slaves_zeros"), g("T3_slaves_n"), "Stata")
put("text_nz_slave_mean_opg", g("T4_excl_opg_slaves_mean"), g("T4_excl_opg_slaves_n"), "Stata")
put("text_nz_slave_mean_inv", g("T4_excl_inv_slaves_mean"), g("T4_excl_inv_slaves_n"), "Stata")
put("text_fishing_boats_pct", 100*g("T3_fishing_boats_nonzero")/g("T3_slaves_n"), g("T3_slaves_n"), "share of inventories with >=1 boat")
nw <- read_dta(file.path(D,"Statafiles","numbersandwealth.dta")) |> filter(!is.na(slavesnumb))
put("text_n_inv_pre1801", sum(nw$date < 1801, na.rm=TRUE), nrow(nw), "date < 1801 in numbersandwealth.dta")
put("text_stuivers_per_rds", 48, NA, "constant in Prices2 formulas (B9 = B4/48)")

## ---- Table 5 / Figure 5: Excel chain ----
p <- file.path(D,"ChapterValue.xlsx")
pr <- xlsx_cells(p, sheets="Prices2"); v2 <- xlsx_cells(p, sheets="Value2"); pd <- xlsx_cells(p, sheets="Products2")
num <- function(cells, r, c) { x <- cells$numeric[cells$row==r & cells$col==c]; if (length(x)) x else NA_real_ }
p8 <- sapply(2:29, function(c) num(pr, 8, c)); price_rds <- p8/48                 # row 10 = row 8 / 48
chk_p <- sapply(2:29, function(c) num(pr, 10, c)); cat("Prices2 row10 recompute max abs diff:", max(abs(price_rds-chk_p)), "\n")
colnum <- function(a) sapply(a, function(s) sum((utf8ToInt(s)-64) * 26^((nchar(s)-1):0)))
f2 <- v2 |> filter(row==2, col>=9, col<=36) |> arrange(col)
m <- str_match(f2$formula, "Products2!([A-Z]+)2[*]Prices2!([A-Z]+)[$]10")
stopifnot(!anyNA(m)); pcol <- colnum(m[,2]); prcol <- colnum(m[,3])
# check that every Value2 formula follows the row-2 pattern
fall <- v2 |> filter(row>=2, col>=9, col<=36, !is.na(formula))
exp_f <- paste0("Products2!", m[match(fall$col, f2$col),2], fall$row, "*Prices2!", m[match(fall$col, f2$col),3], "$10")
cat("Value2 item formulas:", nrow(fall), " deviating from row-2 pattern:", sum(exp_f != fall$formula), "\n")
nr <- max(v2$row[v2$col==4], na.rm=TRUE)
cnt <- matrix(NA_real_, nr-1, 28)
pdn <- pd |> filter(row>=2, row<=nr, !is.na(numeric))
for (k in 1:28) { s <- pdn |> filter(col==pcol[k]); cnt[s$row-1, k] <- s$numeric }
cnt[is.na(cnt)] <- 0   # blank cells evaluate to 0 in Excel multiplication
val <- sweep(cnt, 2, price_rds, `*`); total <- rowSums(val)
dec <- (v2 |> filter(col==4, row>=2, row<=nr) |> arrange(row))$numeric
cached <- (v2 |> filter(col==37, row>=2, row<=nr) |> arrange(row))$numeric       # AK = SUM(I:AJ)
cat("Recomputed total vs cached Value2!AK: max abs diff", max(abs(total-cached)), " n =", length(total), "\n")
# Stata summarize,detail percentile definition
sp <- function(x, p) { x <- sort(x); n <- length(x); a <- n*p/100; i <- floor(a)
  if (a == i) (x[i] + x[i+1])/2 else x[i+1] }
stats <- function(x) c(n=length(x), sum=sum(x), mean=mean(x), sd=sd(x), min=min(x), max=max(x),
  p10=sp(x,10), p25=sp(x,25), med=sp(x,50), p75=sp(x,75), p90=sp(x,90))
dd <- xlsx_cells(p, sheets="Descriptives by decade") |> filter(row>=2, row<=13)
agree <- list()
for (d in c(sort(unique(dec)), "total")) {
  x <- if (d=="total") total else total[dec==as.numeric(d)]; s <- stats(x)
  for (q in names(s)) put(paste0("T5_", d, "_", q), unname(s[q]), length(x), "R reimplementation of ChapterValue chain; prices = Prices2 row 8/48 (hardcoded stuiver medians)")
  if (d != "total") { r <- dd |> filter(col==1, numeric==as.numeric(d)) |> pull(row)
    if (length(r)) { cv <- sapply(2:12, function(c) dd$numeric[dd$row==r & dd$col==c]); agree[[d]] <- max(abs(cv - s[c("n","sum","mean","sd","min","max","p10","p25","med","p75","p90")])/pmax(abs(cv),1)) } } }
cat("Max rel. diff vs cached 'Descriptives by decade' per decade:\n"); print(round(unlist(agree), 6))
write_csv(tibble(decade=names(agree), max_rel_diff=unlist(agree)), file.path(SC, "t5_chain_agreement.csv"))
cat("decades in data:", sort(unique(dec)), "\n")

## ---- Table 1: Jobs in 1732 (totals only) ----
jb <- xlsx_cells(file.path(D,"Jobs in 1732.xlsx"), sheets="Jobs in 1732")
for (nm in c("cape_town","stellenbosch","drakenstein")) {
  cc <- c(cape_town="C", stellenbosch="D", drakenstein="E")[nm]
  put(paste0("T1_", nm, "_total_survey"), jb$numeric[jb$address==paste0(cc,"32")], NA, "Jobs in 1732.xlsx row 32 (SUM of line items; formula chain)")
}

## ---- Tables 6-8: Cape Colony ownership shares (frequency_equipment.dta), by group and period ----
fe <- read_dta(file.path(D,"Statafiles","frequency_equipment.dta")); cat("frequency_equipment vars:", names(fe), "\n")
fe <- fe |> filter(!is.na(group), !is.na(date))
parse_per <- function(s) { a <- as.integer(str_extract(s, "^[0-9]{4}")); b <- str_extract(s, "(?<=_)[0-9]+$")
  if (nchar(b) == 4) b <- as.integer(b) else b <- as.integer(paste0(substr(a, 1, 4 - nchar(b)), b)); c(a, b) }
TBV <- c(T6="boeken", T7="horlogie", T8="schilderij")
for (t in names(TBV)) { tb <- TBV[[t]]
  ids <- res$claim_id[startsWith(res$claim_id, paste0(t, "_cape_colony_"))]
  for (id in ids) {
    s <- sub(paste0(t, "_cape_colony_"), "", id)
    if (grepl("^[0-9]{4}$", s)) { res$note[res$claim_id==id] <- "ambiguous: single-year Cape column of Tables 6-8 has no matching period definition in the surviving files"; res$status_override[res$claim_id==id] <- "ambiguous"; next }
    cls <- if (grepl("^c[0-9]_", s)) as.integer(substr(s, 2, 2)) else NA; s2 <- sub("^c[0-9]_", "", s)
    per <- parse_per(s2)
    x <- fe |> filter(date >= per[1], date <= per[2], is.na(cls) | group == cls)
    put(id, 100*mean(x[[tb]] > 0), nrow(x), paste0("frequency_equipment.dta: % of inventories with ", tb, ">0; class = `group` var, dates ", per[1], "-", per[2], " (class definition assumed)"))
  }
}
res <- res |> mutate(note = ifelse(is.na(status_override), note, note))
write_csv(res, file.path(OUT, "results_original.csv"), na = "")
cat("claims:", nrow(res), " with values:", sum(!is.na(res$value)), "\n")
