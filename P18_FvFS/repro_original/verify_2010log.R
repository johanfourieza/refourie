# verify_2010log.R: compare settlers_from_log.do estimates with the Nov 2010 outreg2 .xls output
# (results.zip/exclpc). Writes repro_original/compare_2010log.csv.
suppressPackageStartupMessages({library(dplyr); library(readr); library(purrr); library(stringr)})
root <- "./P18_FvFS/repro_original"; source("./tools/paths.R")
est  <- read_csv(file.path(root, "settlers_from_log_est.csv"), show_col_types = FALSE)
xdir <- dpath("P18_FvFS", "repro_original", "extracted/results/exclpc")
fams <- c("wine_anova","wheat_anova","wine_capital","wheat_capital","fwine_anova","fwheat_anova",
          "fwine_capital","fwheat_capital","nfwine_capital","nfwheat_capital")

map_label <- function(lab, fam, seen) {
  f <- startsWith(fam, "f") || startsWith(fam, "nf")
  case_when(
    lab == "Non-Wine Descendant Hugenots" & !seen ~ "2.group",
    lab == "Wine Descendant Hugenots" & !seen ~ "3.group",
    lab == "Total Slaves" ~ "total_slaves",
    lab == "Non-Wine Descendant Hugenots * Slaves" ~ "2.group#c.total_slaves",
    lab == "Wine Descendant Hugenots * Slaves" ~ "3.group#c.total_slaves",
    lab == "Knechts" ~ "knechts",
    lab == "Non-Wine Descendant Hugenots * Knechts" ~ "2.group#c.knechts",
    lab == "Wine Descendant Hugenots * Knechts" ~ "3.group#c.knechts",
    lab == "Number of Vines on Farm (in 1000s)" ~ "vines_planted",
    lab == "_IgroXvines_2" ~ "2.group#c.vines_planted",
    lab == "_IgroXvines_3" ~ "3.group#c.vines_planted",
    lab == "Wheat Sown (in muids)" ~ "wheat_sown",
    lab == "Non-Wine Descendant Hugenots * Wheat Sown" ~ "2.group#c.wheat_sown",
    lab == "Wine Descendant Hugenots * Wheat Sown" ~ "3.group#c.wheat_sown",
    lab == "Cattle" ~ "cattle", lab == "Horses" ~ "horses",
    lab == "Wheat Reaped (in muids)" ~ "wheat_reaped", lab == "Wine (in leaguers)" ~ "wine",
    lab == "Cape Town" ~ "1.district", lab == "Stellenbosch" ~ "2.district", lab == "Swellendam" ~ "4.district",
    lab == "Not married to a  Hugenot" ~ "0.marital",
    lab == "Married to Non-Wine Descendent Hugenot" ~ "1.marital",
    lab == "Married to Wine Descendent Hugenot" ~ "2.marital",
    lab == "Non-numeracy" ~ "nonnumeracy", lab == "Born abroad" ~ "firstarrivals",
    lab == "Constant" ~ "_cons", lab == "R-squared" ~ "r2", lab == "N" ~ "N", lab == "F statistic" ~ "F",
    TRUE ~ NA_character_)
}
num <- function(s) suppressWarnings(as.numeric(str_remove_all(s, "[*()]")))

rows <- map_dfr(fams, function(fam) {
  L <- read_lines(file.path(xdir, paste0(fam, "_1.xls")))
  cells <- str_split(L, "\t")
  years <- as.integer(str_extract(cells[[1]][-1], "\\d{4}"))
  out <- list(); seen_g <- FALSE; seen_w <- FALSE
  for (i in 3:length(cells)) {
    lab <- cells[[i]][1]
    if (lab == "" || str_detect(lab, "^\\*")) next
    seen <- if (lab == "Non-Wine Descendant Hugenots") seen_g else if (lab == "Wine Descendant Hugenots") seen_w else FALSE
    term <- map_label(lab, fam, seen)
    if (lab == "Non-Wine Descendant Hugenots") seen_g <- TRUE
    if (lab == "Wine Descendant Hugenots") seen_w <- TRUE
    if (is.na(term)) next
    se_row <- if (i < length(cells)) cells[[i + 1]] else rep("", length(cells[[i]]))
    for (j in seq_along(years)) {
      out[[length(out) + 1]] <- tibble(family = fam, year = years[j], term = term,
        log_b = num(cells[[i]][j + 1]), log_se = if (term %in% c("r2","N","F")) NA_real_ else num(se_row[j + 1]))
    }
  }
  bind_rows(out)
}) |> filter(!is.na(log_b))

stat <- est |> group_by(family, year) |> summarise(N = first(N), r2 = first(r2), F = first(F), .groups = "drop") |>
  tidyr::pivot_longer(c(N, r2, F), names_to = "term", values_to = "b") |> mutate(se = NA_real_)
coefs <- est |> select(family, year, term, b, se)
cmp <- rows |> left_join(bind_rows(coefs, stat), by = c("family","year","term")) |>
  mutate(tol = ifelse(term == "N", 0, 0.0005 + 1e-9),
         match_b = abs(round(b, 3) - log_b) <= tol | (term == "N" & b == log_b),
         match_se = ifelse(is.na(log_se), NA, abs(round(se, 3) - log_se) <= 0.0005 + 1e-9))
write_csv(cmp, file.path(root, "compare_2010log.csv"))
cat("cells compared:", nrow(cmp), "\n")
cat("b/stat matches:", sum(cmp$match_b, na.rm = TRUE), " mismatches:", sum(!cmp$match_b, na.rm = TRUE), " missing:", sum(is.na(cmp$match_b)), "\n")
cat("se matches:", sum(cmp$match_se, na.rm = TRUE), " mismatches:", sum(!cmp$match_se, na.rm = TRUE), "\n")
print(cmp |> filter(!match_b | match_se %in% FALSE | is.na(match_b)) |> head(40), width = 200)
