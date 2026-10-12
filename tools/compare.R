# S4 comparison engine (PROTOCOL.md S4). Source this file; do not run it directly.
#
#   source(here::here("..", "tools", "compare.R"))   # from a paper folder
#   cmp <- compare_claims(claims, results)
#
# claims  : the paper's frozen claims/claims.csv (read with readr::read_csv)
# results : tibble with columns claim_id, source ("original" | "r"), value, se, n,
#           status_override (optional: unavailable / inaccessible / failed / ambiguous / not-attempted)
# Returns one row per claim x pair (A = published vs original, B = published vs R,
# C = original vs R), with numeric status, delta, relative delta and inferential agreement.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr)
})

tol_table <- tibble::tribble(
  ~quantity_type, ~rel_tol,
  "coef",   0.02, "mean", 0.02, "ratio", 0.02, "index", 0.02, "other", 0.02,
  "se",     0.05,
  "share",  0.01,
  "gini",   0.01,
  "tstat",  0.05,
  "pvalue", NA_real_,
  "count",  0.005, "n", 0.005
)

num_status <- function(ref, rep, precision, qtype) {
  if (is.na(ref) || is.na(rep)) return(NA_character_)
  p <- ifelse(is.na(precision), 0, precision)
  half <- 0.5 * 10^(-p)
  if (qtype %in% c("count", "n")) {
    if (round(rep) == round(ref)) return("exact")
    return(ifelse(abs(rep - ref) / max(abs(ref), 1) <= 0.005, "close", "differs"))
  }
  if (abs(rep - ref) <= half + 1e-12) return("exact")
  if (qtype == "pvalue") return("differs")
  abs_tol <- if (qtype == "tstat") 0.1 else 10^(-p)
  rel <- tol_table$rel_tol[match(qtype, tol_table$quantity_type)]
  if (is.na(rel)) rel <- 0.02
  ifelse(abs(rep - ref) <= max(abs_tol, rel * abs(ref)), "close", "differs")
}

# Two-sided 5% decision from estimate and SE (or, failing an SE, from stars).
STARS05 <- 2  # number of stars that marks p < 0.05; set per paper from claims/stars05.txt (Amendment A7)
sig05 <- function(value, se, stars = NA_character_) {
  if (!is.na(se) && se > 0) return(abs(value / se) >= qnorm(0.975))
  if (!is.na(stars)) return(nchar(gsub("[^*]", "", stars)) >= STARS05)
  NA
}

infer_agree <- function(ref, ref_se, ref_lo, ref_hi, ref_stars, rep, rep_se) {
  if (is.na(ref) || is.na(rep)) return(NA)
  same_sign <- sign(ref) == sign(rep)
  s_ref <- sig05(ref, ref_se, ref_stars); s_rep <- sig05(rep, rep_se)
  same_side <- if (is.na(s_ref) || is.na(s_rep)) NA else s_ref == s_rep
  lo <- ref_lo; hi <- ref_hi
  if (is.na(lo) && !is.na(ref_se)) { lo <- ref - 1.96 * ref_se; hi <- ref + 1.96 * ref_se }
  in_ci <- if (is.na(lo)) NA else (rep >= lo & rep <= hi)
  if (is.na(in_ci)) return(all(c(same_sign, same_side)))  # stars-only: sign + 5% side (Amendment A2)
  all(c(same_sign, same_side, in_ci), na.rm = FALSE)
}

compare_claims <- function(claims, results) {
  if (!"status_override" %in% names(results)) results$status_override <- NA_character_
  wide <- results |>
    select(claim_id, source, value, se, n, status_override) |>
    pivot_wider(names_from = source, values_from = c(value, se, n, status_override))
  for (s in c("original", "r")) for (v in c("value", "se", "n", "status_override")) {
    nm <- paste0(v, "_", s); if (!nm %in% names(wide)) wide[[nm]] <- if (v == "status_override") NA_character_ else NA_real_
  }
  base <- claims |> left_join(wide, by = "claim_id")
  one_pair <- function(df, pair_id, ref_col, rep_col, rep_se_col, ovr_col, ref_prec = TRUE) {
    df |> mutate(
      pair = pair_id,
      ref = .data[[ref_col]], rep = .data[[rep_col]], rep_se = .data[[rep_se_col]],
      status = pmap_chr(list(ref, rep, precision, quantity_type, .data[[ovr_col]]),
        function(a, b, p, q, o) {
          if (!is.na(o)) return(o)
          if (is.na(b)) return("not-attempted")
          num_status(a, b, p, q)
        }),
      delta = rep - ref,
      rel_delta = ifelse(is.na(ref) | ref == 0, NA_real_, (rep - ref) / abs(ref)),
      inferential_agree = if (pair_id == "C") NA else pmap_lgl(
        list(quantity_type, ref, as.numeric(reported_se), as.numeric(reported_ci_lo),
             as.numeric(reported_ci_hi), as.character(reported_stars), rep, rep_se),
        function(q, a, b, c, d, e, f, g) if (identical(q, "coef")) infer_agree(a, b, c, d, e, f, g) else NA)
    ) |> select(claim_id, location, quantity_type, headline, pair, ref, rep, rep_se, status, delta, rel_delta, inferential_agree)
  }
  base <- base |> mutate(reported_value = as.numeric(reported_value))
  A <- one_pair(base, "A", "reported_value", "value_original", "se_original", "status_override_original")
  B <- one_pair(base, "B", "reported_value", "value_r", "se_r", "status_override_r")
  # Pair C has no published reference: the original-code value is the reference.
  C <- one_pair(base, "C", "value_original", "value_r", "se_r", "status_override_r")
  out <- bind_rows(A, B, C)
  out$inferential_agree[out$quantity_type != "coef"] <- NA
  out
}

summarise_comparison <- function(cmp) {
  cmp |> count(pair, status) |> pivot_wider(names_from = status, values_from = n, values_fill = 0)
}
