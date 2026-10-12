# build_results.R: map original-code outputs to frozen claim_ids and run S4 pair A.
# Inputs : repro_original/hhsize_results.log (pure S2, hhsize.do)
#          repro_original/published_spec_est.csv (pair A', published_spec_attempt.do)
#          repro_original/settlers_from_log_est.csv (Nov 2010 reconstruction)
# Outputs: repro_original/results_original.csv, results_original_T12_aligned.csv,
#          results_original_2010log.csv; compare/comparison_A.csv, comparison_A_summary.csv,
#          compare/comparison_Aprime_T12.csv
suppressPackageStartupMessages({library(dplyr); library(readr); library(stringr); library(purrr); library(tidyr)})
paper <- "./P18_FvFS"
ro <- file.path(paper, "repro_original")
source(file.path(paper, "..", "tools", "compare.R"))
claims <- read_csv(file.path(paper, "claims/claims.csv"), show_col_types = FALSE)
est <- read_csv(file.path(ro, "published_spec_est.csv"), show_col_types = FALSE,
                col_types = cols(tab = "c", col = "c", term = "c", .default = "d"))

res <- function(id, v, se = NA_real_, n = NA_real_, ovr = NA_character_)
  tibble(claim_id = id, source = "original", value = v, se = se, n = n, status_override = ovr)

# ---------------- (a) Tables 1-2 from hhsize.do (pure S2) ----------------
L <- read_lines(file.path(ro, "hhsize_results.log"))
i0 <- grep("^\\. tabstat", L); i1 <- grep("^\\. table jaar", L)
tl <- L[i0:i1]
grab <- function(lines) {  # rows "  g |  x x x" -> list by group label
  out <- list(); cur <- NULL
  for (ln in lines) {
    m <- str_match(ln, "^\\s*(\\S*)\\s*\\|\\s+([-0-9. ]+)$")
    if (is.na(m[1, 1])) next
    nums <- as.numeric(str_split(str_trim(m[1, 3]), "\\s+")[[1]])
    if (m[1, 2] != "") cur <- m[1, 2]
    out[[cur]] <- c(out[[cur]], list(nums))
  }
  out
}
split_at <- grep("^\\s+group \\|\\s+bste", tl)
p1 <- grab(tl[1:(split_at - 1)]); p2 <- grab(tl[split_at:length(tl)])
vars <- c("c1","c2","c3","c4","c5","c6","c7","c8")  # hh slaves k wingst wyn kgw bste pd
gmap <- c("0" = "r1", "1" = "r2", "2" = "r3", "Total" = "r4")
t1 <- map_dfr(names(gmap), function(g) {
  mean <- c(p1[[g]][[1]], p2[[g]][[1]]); sd <- c(p1[[g]][[2]], p2[[g]][[2]]); n <- p1[[g]][[3]][1]
  mean[4] <- mean[4] / 1000; sd[4] <- sd[4] / 1000      # wingst -> 1,000s (unit mapping only)
  bind_rows(res(paste0("T1_", gmap[g], "_n"), n, n = n),
            res(paste0("T1_", gmap[g], "_", vars, "_mean"), mean, n = n),
            res(paste0("T1_", gmap[g], "_", vars, "_sd"), sd, n = n))
})
tb <- L[(i1 + 1):length(L)]
t2rows <- str_match(tb, "^\\s+(1[67]\\d\\d) \\|\\s+([-0-9. ]+)$")
t2rows <- t2rows[!is.na(t2rows[, 1]), , drop = FALSE]
t2 <- map_dfr(seq_len(nrow(t2rows)), function(k) {
  y <- t2rows[k, 2]; v <- as.numeric(str_split(str_trim(t2rows[k, 3]), "\\s+")[[1]])
  if (!y %in% c("1700","1709","1719","1731","1741","1752","1757","1773")) return(NULL)
  res(paste0("T2_", y, "_wine_", c("NH","NWH","WH")), v)
})
t2_wheat <- claims |> filter(str_detect(claim_id, "^T2_.*_wheat_")) |>
  transmute(claim_id, source = "original", value = NA_real_, se = NA_real_, n = NA_real_,
            status_override = "unavailable")   # hhsize.do computes no wheat series

# ---------------- (b) Tables 3-5, A1, A3-A5 from published_spec_attempt.do ----------------
years <- c(1702,1705,1709,1712,1719,1723,1731,1738,1741,1752,1757,1762,1773)
yr_terms <- paste0(years, ".year")
common_tail <- c("2.district","3.district","4.district", yr_terms, "_cons","r2","N","F")
rowmap <- list(
  T3 = c("2.group","3.group","total_slaves","knechts","cattle","horses","vpc","1.marital","2.marital",
         "wheat_reaped","firstarrivals", common_tail),
  T4 = c("3.group","total_slaves","knechts","cattle","horses","vpc","1.marital","2.marital",
         "wheat_reaped","firstarrivals","nonnumeracy", common_tail),
  T5 = c("2.group","3.group","total_slaves","knechts","cattle","horses","wheat_sown","1.marital","2.marital",
         "nn_imp","firstarrivals", common_tail),
  A3 = c("3.group","latc","latn","lonc","lone","latn_lonc","latn_lone","2.fgrp","3.fgrp","height",
         "firstarrivals","total_slaves","knechts","cattle","horses","vpc","1.marital","2.marital",
         common_tail),
  A5 = c("2.group","3.group","total_slaves","knechts","cattle","horses","wheat_sown","1.marital","2.marital",
         "firstarrivals", common_tail))
stats <- est |> filter(tab %in% names(rowmap)) |> group_by(tab, col) |>
  summarise(N = first(N), r2 = first(r2), F = first(F), .groups = "drop")
lookup <- function(tab_, col_, term_) {
  s <- stats |> filter(tab == tab_, col == col_)
  if (nrow(s) == 0) return(c(NA, NA, NA))
  if (term_ %in% c("r2","N","F")) return(c(s[[term_]], NA, s$N))
  e <- est |> filter(tab == tab_, col == col_, term == term_)
  if (nrow(e) == 0) return(c(NA, NA, s$N))
  c(e$b, e$se, s$N)
}
reg_claims <- claims |> filter(str_detect(claim_id, "^(T[345]|A[35])_r\\d+_c\\d+$")) |>
  mutate(tab = str_extract(claim_id, "^[^_]+"), r = as.integer(str_match(claim_id, "_r(\\d+)_")[, 2]),
         col = str_match(claim_id, "_c(\\d+)$")[, 2])
tab3 <- pmap_dfr(list(reg_claims$claim_id, reg_claims$tab, reg_claims$r, reg_claims$col), function(id, tb, r, cl) {
  term <- rowmap[[tb]][r]
  ovr <- NA_character_
  if (tb == "A3" && cl %in% c("25","26","27")) return(res(id, NA, ovr = "unavailable"))   # height data absent
  if (tb == "A3" && term == "height") return(res(id, NA, ovr = "unavailable"))
  if (tb == "T5" && cl == "16") ovr <- "ambiguous"     # numeracy imputation for N = 9,078 unstated
  v <- lookup(tb, cl, term)
  if (is.na(v[1]) && is.na(ovr)) ovr <- "failed"
  res(id, v[1], v[2], v[3], ovr)
})

# A1 / A4 pairwise region differences (row minus column)
pv_names <- c(Aunis="Aunis", Bearn="Bearn", Brittany="Bretagne", Champagne="Champagne", Dauphine="Dauphine",
              Germany="Deutschland", Flanders="Flandre", IledeFrance="Ile-de-France", Italy="Italia",
              Languedoc="Lanquedoc", Netherlands="Nederland", Normandy="Normandie", Orleanais="Orleanais",
              Picardy="Picardie", Poitou="Poitou", Provence="Provence")
pv_code <- setNames(seq_along(pv_names), names(pv_names))   # encode order is alphabetical in Stata labels
stopifnot(identical(sort(unname(pv_names)), unname(pv_names[order(pv_names)])))
stata_order <- sort(unname(pv_names)); pv_code <- setNames(match(pv_names, stata_order), names(pv_names))
region_b <- function(tb) {
  e <- est |> filter(tab == tb, col == "pv", str_detect(term, "\\.pv$"))
  setNames(e$b, as.integer(str_extract(e$term, "^\\d+")))
}
mat_claims <- claims |> filter(str_detect(claim_id, "^A[14]_")) |>
  mutate(tab = substr(claim_id, 1, 2), rr = str_split_fixed(claim_id, "_", 3)[, 2], cc = str_split_fixed(claim_id, "_", 3)[, 3])
bA <- list(A1 = region_b("A1"), A4 = region_b("A4"))
mats <- pmap_dfr(list(mat_claims$claim_id, mat_claims$tab, mat_claims$rr, mat_claims$cc), function(id, tb, rr, cc) {
  b <- bA[[tb]]
  v <- unname(b[as.character(pv_code[rr])] - b[as.character(pv_code[cc])])
  res(id, v, n = 2045, ovr = if (tb == "A4") "ambiguous" else NA_character_)
})

# A2 classification and text claims
a2 <- claims |> filter(str_detect(claim_id, "^A2_")) |>
  transmute(claim_id, source = "original", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable")
gv <- function(tb, cl, tm) est |> filter(tab == tb, col == cl, term == tm) |> pull(b)
txt <- bind_rows(
  res("TXT_p937_a", 14),                                   # census years in the regression sample (code: 1700-1773 excl. 1716)
  res("TXT_p940_a", 17282),                                # opgaafrolle.dta observations read by hhsize.do
  res("TXT_p943_a", 100 * gv("T3", "4", "3.group")),
  res("TXT_p944_a", 100 * gv("T4", "7", "3.group")),
  res("TXT_p948_a", 100 * gv("T4", "10", "3.group")))
txt_un <- claims |> filter(str_detect(claim_id, "^TXT_"), !claim_id %in% txt$claim_id) |>
  transmute(claim_id, source = "original", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable")

results <- bind_rows(t1, t2, t2_wheat, tab3, mats, a2, txt, txt_un) |>
  mutate(value = round(value, 6), se = round(se, 6))
missing_ids <- setdiff(claims$claim_id, results$claim_id)
if (length(missing_ids)) results <- bind_rows(results, tibble(claim_id = missing_ids, source = "original",
  value = NA_real_, se = NA_real_, n = NA_real_, status_override = "not-attempted"))
stopifnot(!anyDuplicated(results$claim_id))
write_csv(results, file.path(ro, "results_original.csv"), na = "")

# ---------------- Tables 1-2 on the analysis file (A' alignment) ----------------
t1b <- est |> filter(tab == "T1b")
gm <- c(g1 = "r1", g2 = "r2", g3 = "r3", g9 = "r4")
vm <- c(hhsize = "c1", total_slaves = "c2", T_knechts = "c3", v1000 = "c4", T_wine = "c5",
        T_wheat_reaped = "c6", T_cattle = "c7", T_horses = "c8")
t1b_res <- t1b |> mutate(var = str_remove(term, "_(mean|sd)$"), stat = str_extract(term, "(mean|sd)$"),
  claim_id = paste0("T1_", gm[col], "_", vm[var], "_", stat)) |>
  transmute(claim_id, source = "original", value = b, se = NA_real_, n = N, status_override = NA_character_)
t1b_n <- t1b |> distinct(col, N) |> transmute(claim_id = paste0("T1_", gm[col], "_n"), source = "original",
  value = N, se = NA_real_, n = N, status_override = NA_character_)
t2b <- est |> filter(tab == "T2b") |> mutate(v = str_remove(term, "_g\\d$"), g = str_extract(term, "\\d$"),
  claim_id = paste0("T2_", col, "_", ifelse(v == "wine", "wine", "wheat"), "_", c("NH","NWH","WH")[as.integer(g)])) |>
  transmute(claim_id, source = "original", value = b, se = NA_real_, n = N, status_override = NA_character_)
t12_aligned <- bind_rows(t1b_n, t1b_res, t2b)
write_csv(t12_aligned, file.path(ro, "results_original_T12_aligned.csv"), na = "")

# ---------------- Nov 2010 log numbers mapped to the closest claims (reference only) ----------------
nov <- read_csv(file.path(ro, "settlers_from_log_est.csv"), show_col_types = FALSE)
pick <- function(fam, tm, ids, rel) nov |> filter(family == fam, term == tm) |>
  transmute(claim_id = ids, source = "original_nov2010", value = b, se = se, n = N,
            status_override = "reference-only", nov2010_cell = paste0(fam, "_1.xls ", year, " ", tm), relation = rel)
nov_ref <- bind_rows(
  pick("wine_anova", "2.group", "T3_r1_c1", "year-by-year, group dummies only; print spec 1 is pooled with born abroad, district, year"),
  pick("wine_anova", "3.group", "T3_r2_c1", "as above"),
  pick("wine_capital", "2.group", "T3_r1_c4", "main effect in model with group x slaves/knechts/vines interactions; base district Drakenstein"),
  pick("wine_capital", "3.group", "T3_r2_c4", "as above; headline analogue"),
  pick("fwine_anova", "3.group", "T4_r1_c5", "year-by-year Huguenot sample, WH dummy only"),
  pick("fwine_capital", "3.group", "T4_r1_c7", "main effect with WH x input interactions; headline analogue"),
  pick("nfwine_capital", "3.group", "T4_r1_c8", "adds non-numeracy and born abroad"),
  pick("wheat_anova", "2.group", "T5_r1_c11", "year-by-year, group dummies only"),
  pick("wheat_anova", "3.group", "T5_r2_c11", "as above"),
  pick("wheat_capital", "3.group", "T5_r2_c15", "main effect with group x input interactions (wheat sown)"))
write_csv(nov_ref, file.path(ro, "results_original_2010log.csv"), na = "")

# ---------------- S4 pair A ----------------
cmpA <- compare_claims(claims, results) |> filter(pair == "A")
dir.create(file.path(paper, "compare"), showWarnings = FALSE)
write_csv(cmpA, file.path(paper, "compare/comparison_A.csv"), na = "")
summ <- cmpA |> mutate(block = str_extract(claim_id, "^[A-Z]+[0-9]*")) |> count(block, status) |>
  pivot_wider(names_from = status, values_from = n, values_fill = 0)
tot <- cmpA |> count(status) |> mutate(block = "ALL") |> pivot_wider(names_from = status, values_from = n, values_fill = 0)
summ <- bind_rows(summ, tot)
write_csv(summ, file.path(paper, "compare/comparison_A_summary.csv"), na = "")
cmpT12 <- compare_claims(claims |> filter(str_detect(claim_id, "^T[12]_")), t12_aligned) |> filter(pair == "A")
write_csv(cmpT12, file.path(paper, "compare/comparison_Aprime_T12.csv"), na = "")
print(as.data.frame(summ))
cat("\nT1-T2 on analysis file (A' alignment):\n"); print(table(cmpT12$status))
cat("\nHeadline rows:\n"); print(as.data.frame(cmpA |> filter(headline == 1) |> select(claim_id, ref, rep, rep_se, status, inferential_agree)))
cat("\nInferential agreement (coef rows with value):\n"); print(table(cmpA$inferential_agree, useNA = "ifany"))
