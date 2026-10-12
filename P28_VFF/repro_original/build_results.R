# build_results.R (P28_VFF, S2/S4): map Stata outputs of Run A and Run A' to frozen claim_ids,
# run S4 pair A, and collect the Conley results.
# Inputs : repro_original/runA/{T1_corr,regs_est,conley*_pop,conley*_welfare}.csv
#          repro_original/runAprime/{same}
# Outputs: repro_original/results_original.csv (Run A), results_original_Aprime.csv (Run A'),
#          repro_original/conley_results.csv,
#          compare/comparison_A.csv, comparison_A_summary.csv,
#          compare/comparison_Aprime.csv, comparison_Aprime_summary.csv
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr); library(purrr); library(stringr)})
paper <- "./P28_VFF"
ro <- file.path(paper, "repro_original")
source(file.path(paper, "..", "tools", "compare.R"))
claims <- read_csv(file.path(paper, "claims/claims.csv"), show_col_types = FALSE,
                   col_types = cols(.default = "c"))
claims <- claims |> mutate(across(c(reported_se, reported_ci_lo, reported_ci_hi, reported_n, precision, headline),
                                  as.numeric))

# ---- mappings (claims row/col -> Stata names) ----
t1_vars <- c("bl100", "l_pop1911", "l_pop1996", "l_pop2011", "l_u1996", "l_u2011",
             "l_lights96", "l_lights11", "rain_level", "tri", "csi")
t2_models <- c("pop1911_1a", "pop1911_1b", "home_3", "pop1996_3", "pop1996_4",
               "pop2011_3", "pop2011_4", "pop2011_5", "pop2011_6")      # do-file col 10 pop2011_7 not printed
t2_rows <- c("bl100", "l_pop1911", "p_homeland", "l_pop1996", "tri", "rain_level", "_cons", "R2", "N", "F")
t3_models <- c("u1996_3", "u1996_4", "lights96_3", "lights96_4", "u2011_3", "u2011_4", "u2011_6",
               "u2011_7", "lights11_3", "lights11_4", "lights11_6", "lights11_7")
t3_rows <- c("l_pop1911", "p_homeland", "l_pop2011", "l_netmig_11", "tri", "rain_level", "_cons", "R2", "N", "F")

build <- function(run) {
  d <- file.path(ro, run)
  cor <- read_csv(file.path(d, "T1_corr.csv"), show_col_types = FALSE)
  # Run A' names the swapped columns differently; position is what defines the printed row/col
  rn <- unique(cor$row)
  cor <- cor |> mutate(i = match(row, rn), j = match(col, rn))
  stopifnot(length(rn) == 11)
  t1 <- cor |> transmute(claim_id = paste0("T1_r", i, "_c", j), value = r, se = NA_real_, n = 138)
  est <- read_csv(file.path(d, "regs_est.csv"), show_col_types = FALSE)
  # F from R2 (exact for OLS with constant): F = (R2/k) / ((1-R2)/df_r), k = N - df_r - 1
  stats <- est |> group_by(model) |> summarise(N = first(N), r2 = first(r2), df_r = first(df_r),
                                               vce = first(vce), .groups = "drop") |>
    mutate(k = N - df_r - 1, F = (r2 / k) / ((1 - r2) / df_r))
  tab <- function(tid, models, rows) {
    map_dfr(seq_along(models), function(cc) {
      m <- models[cc]; e <- est |> filter(model == m); s <- stats |> filter(model == m)
      map_dfr(seq_along(rows), function(rr) {
        v <- rows[rr]; id <- paste0(tid, "_r", rr, "_c", cc)
        if (v == "R2") return(tibble(claim_id = id, value = s$r2, se = NA_real_, n = s$N))
        if (v == "N")  return(tibble(claim_id = id, value = s$N, se = NA_real_, n = s$N))
        if (v == "F")  return(tibble(claim_id = id, value = s$F, se = NA_real_, n = s$N))
        x <- e |> filter(var == v)
        if (nrow(x) == 0) return(NULL)
        tibble(claim_id = id, value = x$b, se = x$se, n = s$N)
      })
    })
  }
  out <- bind_rows(t1, tab("T2", t2_models, t2_rows), tab("T3", t3_models, t3_rows)) |>
    mutate(source = "original", status_override = NA_character_)
  # text claims are not produced by the code
  txt <- claims |> filter(str_starts(claim_id, "TXT")) |>
    transmute(claim_id, value = NA_real_, se = NA_real_, n = NA_real_, source = "original",
              status_override = "not-attempted")
  out <- bind_rows(out, txt) |> semi_join(claims, by = "claim_id") |>
    select(claim_id, source, value, se, n, status_override)
  missing <- setdiff(claims$claim_id, out$claim_id)
  if (length(missing)) stop("unmapped claims: ", paste(missing, collapse = ", "))
  list(res = out, vce = unique(stats$vce))
}

A  <- build("runA");      write_csv(A$res,  file.path(ro, "results_original.csv"), na = "")
Ap <- build("runAprime"); write_csv(Ap$res, file.path(ro, "results_original_Aprime.csv"), na = "")
cat("SE type (e(vce)) Run A:", A$vce, " Run A':", Ap$vce, "\n")

cmpA <- function(res, tag) {
  cmp <- compare_claims(claims, res) |> filter(pair == "A")
  write_csv(cmp, file.path(paper, "compare", paste0("comparison_", tag, ".csv")), na = "")
  s <- cmp |> mutate(block = str_extract(claim_id, "^(T[0-9]|TXT)")) |>
    count(block, status) |> pivot_wider(names_from = status, values_from = n, values_fill = 0)
  tot <- cmp |> count(status) |> pivot_wider(names_from = status, values_from = n, values_fill = 0) |>
    mutate(block = "ALL")
  hl <- cmp |> filter(headline == 1) |> count(status) |>
    pivot_wider(names_from = status, values_from = n, values_fill = 0) |> mutate(block = "HEADLINE")
  inf <- cmp |> filter(!is.na(inferential_agree)) |>
    summarise(block = "INFERENTIAL(coef)", agree = sum(inferential_agree), disagree = sum(!inferential_agree))
  summ <- bind_rows(s, tot, hl, inf)
  write_csv(summ, file.path(paper, "compare", paste0("comparison_", tag, "_summary.csv")), na = "")
  print(summ, width = 200)
  print(cmp |> filter(!status %in% c("exact", "not-attempted")) |>
          select(claim_id, ref, rep, status, delta), n = 200)
  invisible(cmp)
}
cA  <- cmpA(A$res, "A")
cAp <- cmpA(Ap$res, "Aprime")

# ---- Conley results (online supplement; not in claims) for later S6 use ----
conley <- map_dfr(c("runA", "runAprime"), function(run) {
  fs <- list.files(file.path(ro, run), pattern = "^conley[0-9]+_(pop|welfare)\\.csv$", full.names = TRUE)
  map_dfr(fs, function(f) read_csv(f, show_col_types = FALSE) |>
            mutate(run = run, block = str_match(basename(f), "_(pop|welfare)")[, 2]))
}) |>
  mutate(cutoff_km = as.integer(str_extract(tag, "[0-9]+")),
         variant = if_else(run == "runA", "A (as found)", "A' (version-gap aligned; ANALYTIC)")) |>
  select(variant, block, cutoff_km, model, var, b, conley_se = se, N) |>
  arrange(variant, block, cutoff_km, model, var)
write_csv(conley, file.path(ro, "conley_results.csv"), na = "")
cat("conley rows:", nrow(conley), "\n")
