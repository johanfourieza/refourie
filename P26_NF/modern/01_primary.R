# P26_NF S6 primary analysis (method card v3, frozen d240e89, §4).
# Like-for-like 1886-87 falls on the comparable divisions D, from the published per-division cells of Tables 1-2.
# Steps: (A) docx-journal cross-check (S5 c4 re-run); (B1) 64-key integrity assertions; (B2) D by rule;
# (B3) B, W, Delta, R and the published-set check; (B5) Total-row check. No randomness, no inference (§4 C, F).
suppressMessages({library(tidyverse); library(here)})
source(here::here("tools", "paths.R"))
od <- here::here("P26_NF", "modern", "output"); dir.create(od, showWarnings = FALSE)
log_lines <- character(); say <- function(...) { m <- paste0(...); log_lines <<- c(log_lines, m); cat(m, "\n") }

cl <- read_csv(here::here("P26_NF", "claims", "claims.csv"), col_types = cols(.default = "c"))
cells <- cl |> filter(str_detect(claim_id, "^T[12]_")) |>
  mutate(tab = str_extract(location, "^T[12]"), name = str_match(location, "row (.*) col")[, 2],
         year = str_extract(location, "[0-9]{4}$"), code = str_split_i(claim_id, "_", 2))

# ---- (A) S5 c4 re-run: Tables and figures.docx vs published cells (journal values decide on mismatch)
docx <- dpath("P26_NF", "original", "2. DEMOCRACY AND DISENFRANCHISEMENT", "Tables and figures.docx")
tmp <- dscratch("P26_NF", "modern"); unzip(docx, "word/document.xml", exdir = tmp)
x <- paste(readLines(file.path(tmp, "word", "document.xml"), encoding = "UTF-8", warn = FALSE), collapse = "")
rx <- function(s, p) regmatches(s, gregexpr(p, s, perl = TRUE))[[1]]
yrs <- c("1886", "1887", "1889", "1891", "1893", "1895")
dcode <- function(n) substr(gsub("[^A-Za-z]", "", sub("Graaf", "Graaff", sub("Vic East", "Victoria", n))), 1, 8)
docv <- list()
for (ti in 1:2) {
  tbl <- rx(x, "<w:tbl>.*?</w:tbl>")[ti]
  for (row in rx(tbl, "<w:tr[ >].*?</w:tr>")[-1]) {
    tc <- vapply(rx(row, "<w:tc>.*?</w:tc>"), function(c) paste(gsub("<[^>]+>", "", rx(c, "<w:t(?: [^>]*)?>.*?</w:t>")), collapse = ""), "")
    if (!nzchar(trimws(tc[1]))) next
    for (j in seq_along(yrs)) docv[[sprintf("T%d_%s_%s", ti, dcode(tc[1]), yrs[j])]] <- gsub(",", "", tc[j + 1])
  }
}
pubv <- setNames(gsub(",", "", cells$reported_value), cells$claim_id)
both <- intersect(names(pubv), names(docv))
mism <- both[pubv[both] != docv[both]]
say("(A) c4 re-run: cells compared ", length(both), "; docx-journal mismatches ", length(mism),
    if (length(mism)) paste0(" [", paste(mism, collapse = ", "), "]") else "")

# ---- (B1) key assertions before any filtering
names16 <- cells |> filter(tab == "T1", year == "1887", name != "Total") |> pull(name) |> unique()
integrity <- character()
if (length(names16) != 16) integrity <- c(integrity, sprintf("1887 column yields %d names, not 16", length(names16)))
structural <- c("T1_Griqualand East_1886", "T2_Griqualand East_1886", "T1_Thembuland_1886", "T2_Thembuland_1886")
keys <- expand_grid(tab = c("T1", "T2"), name = names16, year = c("1886", "1887")) |> mutate(key = paste(tab, name, year, sep = "_"))
rec <- cells |> filter(year %in% c("1886", "1887"), name != "Total") |> mutate(key = paste(tab, name, year, sep = "_"))
extra <- setdiff(rec$key, keys$key); if (length(extra)) integrity <- c(integrity, paste("unexpected keys:", paste(extra, collapse = "; ")))
keys <- keys |> rowwise() |> mutate(nrec = sum(rec$key == key), raw = if (nrec == 1) rec$reported_value[rec$key == key] else NA_character_) |> ungroup() |>
  mutate(flag = case_when(key %in% structural & nrec == 0 ~ "structural",
                          key %in% structural ~ "record present for structural key",
                          nrec == 0 ~ "missing", nrec > 1 ~ "duplicate",
                          toupper(trimws(raw)) == "N/A" ~ "literal N/A",
                          !str_detect(gsub(",", "", raw), "^[0-9]+$") ~ "malformed",
                          TRUE ~ "ok"),
         value = ifelse(flag == "ok", as.numeric(gsub(",", "", raw)), NA_real_))
bad <- keys |> filter(!flag %in% c("ok", "structural"))
if (nrow(bad)) integrity <- c(integrity, paste(bad$key, bad$flag, sep = ": "))
say("(B1) keys ", nrow(keys), "; ok ", sum(keys$flag == "ok"), "; structural ", sum(keys$flag == "structural"),
    " (", paste(keys$key[keys$flag == "structural"], collapse = ", "), "); integrity failures ", length(integrity))
write_csv(keys |> select(key, tab, name, year, nrec, raw, flag, value), file.path(od, "primary_keys.csv"))
if (length(integrity)) { writeLines(c(log_lines, integrity), file.path(od, "primary_log.txt")); stop("INTEGRITY FAILURE (§4 D): ", paste(integrity, collapse = " | ")) }

# ---- (B2) comparable set D by the §3 rule
wide <- keys |> select(tab, name, year, value) |> pivot_wider(names_from = c(tab, year), values_from = value)
D <- wide |> filter(if_all(c(T1_1886, T1_1887, T2_1886, T2_1887), ~ !is.na(.x)))
say("(B2) |D| = ", nrow(D), ": ", paste(D$name, collapse = ", "))
coverage_ok <- nrow(D) == 14
if (!coverage_ok) say("WARNING: |D| != 14; rows not-testable until a reconciliation entry exists (§4 D)")

# ---- (B5) Total rows equal column sums (all 16 divisions, NA treated as blank)
tot <- cells |> filter(name == "Total", year %in% c("1886", "1887")) |> transmute(col = paste(tab, year, sep = "_"), printed = as.numeric(gsub(",", "", reported_value)))
tot$colsum <- vapply(tot$col, function(cc) sum(wide[[cc]], na.rm = TRUE), 0); tot$gap <- tot$printed - tot$colsum
for (i in seq_len(nrow(tot))) say("(B5) ", tot$col[i], " printed ", tot$printed[i], " column sum ", tot$colsum[i], " gap ", tot$gap[i])

# ---- (B3) estimands
s <- function(d, cc) sum(d[[cc]])
B <- s(D, "T1_1886") - s(D, "T1_1887"); W <- s(D, "T2_1886") - s(D, "T2_1887")
B_pub <- sum(wide$T1_1886, na.rm = TRUE) - sum(wide$T1_1887, na.rm = TRUE)
W_pub <- sum(wide$T2_1886, na.rm = TRUE) - sum(wide$T2_1887, na.rm = TRUE)
say("(B3) published-set check: B = ", B_pub, " (paper 2,825), W = ", W_pub, " (paper 7,934)")
primary <- tibble(
  quantity = c("sum_T1_1886_D", "sum_T1_1887_D", "sum_T2_1886_D", "sum_T2_1887_D", "B", "W", "Delta", "R", "B_over_30000", "B_published_sets", "W_published_sets", "n_D"),
  value = c(s(D, "T1_1886"), s(D, "T1_1887"), s(D, "T2_1886"), s(D, "T2_1887"), B, W, W - B, 30000 - B, B / 30000, B_pub, W_pub, nrow(D)),
  note = c(rep("comparable set D", 4), "net fall in black registrations on D", "net fall in white/coloured registrations on D", "W - B", "30,000 - B", "ratio",
           "S1 benchmark (14-div 1886 minus 16-div 1887)", "S1 benchmark", "divisions in D"),
  label = "conditional arithmetic on published cells; no inference (card §0, §4 C)")
primary$plausibility_flag <- c(rep(NA, 4), B > 4237.5, W > 11901, rep(NA, 6))
write_csv(primary, file.path(od, "primary.csv"))
saveRDS(list(D = D, wide = wide, B = B, W = W, coverage_ok = coverage_ok, integrity = integrity), file.path(tmp, "primary.rds"))
say("(B3) B = ", B, "; W = ", W, "; Delta = ", W - B, "; R = ", 30000 - B, "; B/30000 = ", round(B / 30000, 4))
writeLines(log_lines, file.path(od, "primary_log.txt"))
