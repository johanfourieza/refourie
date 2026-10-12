# Parse the Stata logs of the S2 run and the census recalculation into results_original.csv.
# Run from repro_original/ after run_*.do and recalc_census.R.
suppressPackageStartupMessages({ library(dplyr); library(readr); library(stringr); library(tibble) })

cls <- c("White collar", "Farmer", "Skilled/Semiskilled", "Unskilled")
per <- c("Slavery", "Stagnation", "Diamonds", "Gold")
num <- function(x) as.numeric(gsub(",", "", x))

# ---- run_B_tabs2016.log : lines 145-157 of the do-file ------------------------------------
L <- readLines("logs/run_B_tabs2016.log")
section <- function(start_pat) { i <- grep(start_pat, L, fixed = TRUE)[1]; j <- i + which(grepl("^\\. ", L[(i + 1):length(L)]))[1]; L[i:(j - 1)] }
oneway <- function(lines) {   # bysort period: tab x  -> counts[period, class]
  m <- matrix(NA, 4, 4, dimnames = list(per, cls)); p <- NA
  for (l in lines) {
    if (grepl("^-> period = ", l)) p <- sub("^-> period = ", "", l)
    for (k in cls) if (grepl(paste0("^\\s*", k, " \\|"), l)) m[p, k] <- num(str_split(str_trim(sub(".*\\|", "", l)), "\\s+")[[1]][1])
  }
  m
}
twoway <- function(lines) {   # bysort period: tab f s, row -> list of 4x4 count matrices
  out <- list(); p <- NA
  for (idx in seq_along(lines)) { l <- lines[idx]
    if (grepl("^-> period = ", l)) { p <- sub("^-> period = ", "", l); out[[p]] <- matrix(NA, 4, 4, dimnames = list(cls, cls)) }
    for (k in cls) if (!is.na(p) && grepl(paste0("^\\s*", k, " \\|"), l)) {
      v <- num(str_split(str_trim(gsub("\\|", " ", sub(paste0("^\\s*", k), "", l))), "\\s+")[[1]])
      out[[p]][k, ] <- v[1:4] }
  }
  out
}
last_n  <- oneway(section(". bysort period: tab occ_group_last"))
first_n <- oneway(section(". bysort period: tab occ_group_first"))
mob     <- twoway(section(". bysort period: tab f_occ_group_last occ_group_last, row"))
stopifnot(sum(last_n) == 9494, sum(first_n) == 9494)

rows <- list()
add <- function(id, value, se = NA, n = NA, ovr = NA, note = "") rows[[length(rows) + 1]] <<- tibble(claim_id = id, source = "original", value = value, se = se, n = n, status_override = ovr, note = note)
pct_last <- 100 * last_n / rowSums(last_n)

# Table 6 (and SAF columns of Tables 3 and 4): class shares by cohort, line 150
for (r in 1:4) {
  for (c in 1:4) add(sprintf("T6_r%d_c%d", r, c), pct_last[c, r], n = sum(last_n[c, ]), note = "do-file l.150")
  add(sprintf("T6_r%d_c5", r), pct_last[4, r] - pct_last[1, r], note = "Gold minus Slavery, from l.150 output")
}
for (c in 1:4) { add(sprintf("T6_r5_c%d", c), sum(pct_last[c, ]), note = "l.150"); add(sprintf("T6_r6_c%d", c), sum(last_n[c, ]), note = "l.145/150") }
add("T6_r6_c5", sum(last_n), note = "l.145")
t3col <- c(c1 = 1, c2 = 2, c4 = 3, c7 = 4)
for (r in 1:4) for (cc in names(t3col)) add(sprintf("T3_r%d_%s", r, cc), pct_last[t3col[cc], r], note = "SAF column = do-file l.150")
for (cc in names(t3col)) add(sprintf("T3_r5_%s", cc), sum(pct_last[t3col[cc], ]), note = "l.150")
for (r in 1:4) add(sprintf("T4_r%d_c1", r), pct_last[4, r], note = "SAF column = do-file l.150 (Gold)")
add("T4_r5_c1", 100, note = "l.150")

# Table 7: first vs last occupation, all cohorts (sum of l.150/l.151 period tabs)
fN <- colSums(first_n); lN <- colSums(last_n)
for (r in 1:4) { add(sprintf("T7_r%d_c1", r), 100 * fN[r] / sum(fN), n = sum(fN), note = "l.151 summed over periods")
                 add(sprintf("T7_r%d_c2", r), 100 * lN[r] / sum(lN), n = sum(lN), note = "l.150 summed over periods") }
add("T7_r5_c1", 100); add("T7_r5_c2", 100); add("T7_r6_c1", sum(fN)); add("T7_r6_c2", sum(lN))

# Table 8: 4x4 mobility tables by cohort, line 156
for (pi in 1:4) { M <- mob[[per[pi]]]; base <- (pi - 1) * 5
  for (r in 1:4) { for (c in 1:4) add(sprintf("T8_r%d_c%d", base + r, c), 100 * M[r, c] / sum(M[r, ]), n = sum(M[r, ]), note = "l.156")
                   add(sprintf("T8_r%d_c5", base + r), sum(M[r, ]), note = "l.156") }
  for (c in 1:4) add(sprintf("T8_r%d_c%d", base + 5, c), 100 * sum(M[, c]) / sum(M), note = "l.156 column total")
  add(sprintf("T8_r%d_c5", base + 5), sum(M), note = "l.156")
}
# Table 9: Slavery panel is the unadjusted Slavery table by construction; other panels need a
# 4-cohort Deming-Stephan adjustment that is not in the code.
M <- mob[["Slavery"]]
for (r in 1:4) { for (c in 1:4) add(sprintf("T9_r%d_c%d", r, c), 100 * M[r, c] / sum(M[r, ]), n = sum(M[r, ]), note = "l.156 Slavery (reference panel, unadjusted by construction)")
                 add(sprintf("T9_r%d_c5", r), sum(M[r, ]), note = "l.156") }
for (c in 1:4) add(sprintf("T9_r5_c%d", c), 100 * sum(M[, c]) / sum(M), note = "l.156"); add("T9_r5_c5", sum(M), note = "l.156")
for (r in 6:20) for (c in 1:5) add(sprintf("T9_r%d_c%d", r, c), NA, ovr = "unavailable",
  note = "no code for the per-cohort Deming-Stephan adjustment; mstdize block (l.255-276) standardises only the after-1868 table, with mis-set margins")

# Text p.8 and p.12 (from l.156 output)
add("TXT_p8_a", sum(last_n), note = "l.145")
S <- mob[["Slavery"]]; G <- mob[["Gold"]]; rp <- function(M, r, c) 100 * M[r, c] / sum(M[r, ])
add("TXT_p12_a", rp(S, 2, 2), note = "l.156"); add("TXT_p12_b", rp(S, 2, 2) - rp(G, 2, 2), note = "l.156, pp change")
add("TXT_p12_c", rp(G, 1, 1) - rp(S, 1, 1), note = "l.156, pp change"); add("TXT_p12_d", rp(G, 1, 4), note = "l.156")
add("TXT_p12_e", rp(G, 3, 1), note = "l.156"); add("TXT_p12_f", rp(G, 4, 1) - rp(S, 4, 1), note = "l.156, pp change")

# ---- run_C2_altham.log : Table 10 ------------------------------------------------------------
A <- readLines("logs/run_C2_altham.log")
getd <- function(lab) num(sub(".*=", "", A[grepl(paste0("^", lab, "="), A)]))
dpi <- getd("d\\(P,I\\)"); dqi <- getd("d\\(Q,I\\)"); dpq <- getd("d\\(P,Q\\)")
add("T10_r1_c1", dpi[1], note = "l.216-218 (frequencies hard-coded l.184-201)")
add("T10_r1_c2", dqi[1], note = "l.227-229")
add("T10_r1_c3", dpq[1], note = "l.237-239; G2 p=0.066")
add("T10_r1_c4", dpq[2], note = "quasi-independence block l.351-353; G2 p=0.72")
for (id in c("TXT_p15_a", "TXT_p15_b", "TXT_p15_c")) add(id, NA, ovr = "failed",
  note = "farmers-dropped block l.367-378 stops at 'bysort p_split' (variable is psplit) and contains no Altham code ('re-estimate Altham statistics, then')")
for (id in paste0("TXT_p15_fn9", letters[1:4])) add(id, NA, ovr = "unavailable", note = "no five-category (HISCLASS) Altham code")

# ---- run_E_logit.log : Table 11 --------------------------------------------------------------
E <- readLines("logs/run_E_logit.log")
blocks <- grep("^\\. xi: logit", E)
parse_logit <- function(i) {
  j <- blocks[blocks > i][1]; seg <- E[i:(if (is.na(j)) length(E) else j)]
  co <- seg[grepl("^\\s*\\S+ \\|\\s+-?[0-9.]+\\s+[0-9.]+\\s+-?[0-9.]+", seg)]
  nm <- str_trim(sub("\\|.*", "", co)); v <- str_split(str_trim(sub(".*\\|", "", co)), "\\s+")
  list(b = setNames(num(sapply(v, `[`, 1)), nm), se = setNames(num(sapply(v, `[`, 2)), nm),
       n = num(sub(".*Number of obs\\s*=\\s*", "", seg[grepl("Number of obs", seg)][1])),
       r2 = num(sub(".*Pseudo R2\\s*=\\s*", "", seg[grepl("Pseudo R2", seg)][1])),
       p = num(sub(".*Prob > chi2\\s*=\\s*", "", seg[grepl("Prob > chi2", seg)][1])))
}
m1 <- parse_logit(blocks[1]); m3 <- parse_logit(blocks[3])
t11 <- c(r2 = "_Iperiod_2", r3 = "_Iperiod_3", r4 = "_Iperiod_4", r5 = "_If_gen_1",
         r7 = "_Iorigin_2", r8 = "_Iorigin_3", r9 = "_Iorigin_4", r10 = "_Iorigin_5", r11 = "_Iorigin_6",
         r14 = "_Iprov_2", r15 = "_Iprov_3", r16 = "_Iprov_4",
         r18 = "_If_occ_gr~2", r19 = "_If_occ_gr~3", r20 = "_If_occ_gr~4", r21 = "share")
refs <- c("r1", "r6", "r12", "r13", "r17")
for (cl in list(list(m = m1, c = "c1", lab = "do-file model 1 (l.393-395)"), list(m = m3, c = "c3", lab = "do-file model 3 (l.405-407)"))) {
  for (r in names(t11)) { id <- paste0("T11_", r, "_", cl$c); v <- t11[[r]]
    if (v %in% names(cl$m$b)) add(id, exp(cl$m$b[[v]]), se = exp(cl$m$b[[v]]) * cl$m$se[[v]], n = cl$m$n, note = paste(cl$lab, "exp(b); se by delta method"))
  }
  for (r in refs) add(paste0("T11_", r, "_", cl$c), 1, n = cl$m$n, note = paste(cl$lab, "reference category"))
  add(paste0("T11_r22_", cl$c), cl$m$r2, note = cl$lab); add(paste0("T11_r23_", cl$c), cl$m$p, note = cl$lab); add(paste0("T11_r24_", cl$c), cl$m$n, note = cl$lab)
}
# Model 1 has no father's-class term; the printed reference '1' in column 1 is a layout artefact.
rows <- Filter(function(x) x$claim_id != "T11_r17_c1", rows)
add("T11_r17_c1", NA, ovr = "ambiguous", note = "father's class is not in Model 1; printed reference value has no estimate behind it")
# Published Model 2 (father's class, no class size) is not among the do-file's models.
cl <- readr::read_csv("../claims/claims.csv", show_col_types = FALSE)
for (id in cl$claim_id[grepl("^T11_.*_c2$", cl$claim_id)]) add(id, NA, ovr = "unavailable",
  note = "published Model 2 (= Model 1 + father's class) is not in the do-file; do-file model 2 is Model 1 + class size, with i.f_gen_dad")

# ---- census columns (recalc_census.R) ---------------------------------------------------------
cen <- read_csv("output/census_recalc.csv", show_col_types = FALSE)
for (i in seq_len(nrow(cen))) add(cen$claim_id[i], cen$value[i], note = paste("Excel recalculation:", cen$wb[i], cen$sheet[i], cen$addr[i], cen$note[i]))
add("TXT_p9_a", cen$value[cen$claim_id == "T5_r2_c4"], note = "= T5 farmer non-European share (Excel recalculation)")
add("TXT_p9_b", cen$value[cen$claim_id == "T5_r4_c4"], note = "= T5 unskilled non-European share (Excel recalculation)")

# ---- not covered by code -----------------------------------------------------------------------
res <- bind_rows(rows)
miss <- setdiff(cl$claim_id, res$claim_id)
why <- function(id) case_when(
  grepl("^T1_", id) ~ "Table 1 (top birth towns): no code; R+R Tables.xlsx 'Top towns by period' holds values only",
  grepl("^TXT_p5", id) ~ "1865 census sector shares: no formula chain located",
  id == "TXT_p6_a" ~ "cited from Fourie and Van Zanden (2013); not computed in this paper",
  TRUE ~ "not produced by the surviving code")
res <- bind_rows(res, tibble(claim_id = miss, source = "original", value = NA, se = NA, n = NA, status_override = "unavailable", note = why(miss)))
stopifnot(!anyDuplicated(res$claim_id), all(res$claim_id %in% cl$claim_id))
res <- res[match(cl$claim_id, res$claim_id), ]
write_csv(res, "results_original.csv", na = "")
cat("rows:", nrow(res), " with value:", sum(!is.na(res$value)), "\n"); print(table(res$status_override, useNA = "ifany"))
