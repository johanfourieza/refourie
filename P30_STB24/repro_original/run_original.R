# S2 wrapper for P30_STB24: runs the env-patched original script unchanged and exports the numbers behind Figs 2-7.
# Usage (from project root): Rscript P30_STB24/repro_original/run_original.R
# The script is evaluated in a child environment so that its rm(list = ls()) (line 42) cannot remove OUTDIR/DATAFILE.
source("tools/paths.R")
OUTDIR   <- normalizePath("P30_STB24/repro_original/output", winslash = "/")
DATAFILE <- dpath("P30_STB24", "original", "2024F_Stellenbosch", "stellenbosch_clean.xlsx")
SCRIPT   <- normalizePath("P30_STB24/repro_original/StellenboschScript.R", winslash = "/")
stopifnot(file.exists(DATAFILE))

t0 <- Sys.time()
# Interactive-session emulation: each top-level expression is evaluated in turn; an error is logged and the run
# continues, as in the R console. Needed because the line-52 typo ("stellenbosch_clea.xlsx") makes lines 56-63 fail,
# and the published figures can only come from the state that leaves (opgaaf = the type-guessed read of line 46).
e <- new.env()
wl <- character(); errs <- data.frame(line = integer(), error = character())
exprs <- parse(SCRIPT, keep.source = TRUE)
for (i in seq_along(exprs)) {
  ln <- attr(exprs, "srcref")[[i]][1]
  withCallingHandlers(
    tryCatch(eval(exprs[[i]], envir = e),
             error = function(err) { errs[nrow(errs) + 1, ] <<- list(ln, conditionMessage(err)); cat("ERROR (skipped) at line", ln, ":", conditionMessage(err), "
") }),
    warning = function(w) { wl <<- c(wl, conditionMessage(w)); invokeRestart("muffleWarning") })
}
graphics.off()
cat("Script finished in", format(Sys.time() - t0), "\n")
setwd(OUTDIR)
write.csv(errs, "errors_skipped.csv", row.names = FALSE)

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr)})
wt <- sort(table(substr(wl, 1, 120)), decreasing = TRUE)
writeLines(paste(wt, names(wt), sep = " x "), "warnings_summary.txt")

# Dataset facts
d <- e$opgaaf_new2
facts <- tibble(
  item = c("rows_opgaaf", "cols_opgaaf", "unique_years", "year_min", "year_max",
           "heatmap_vars_kept", "heatmap_vars_dropped",
           paste0("class_", c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine", "slave_men"))),
  value = c(nrow(e$opgaaf), ncol(e$opgaaf), dplyr::n_distinct(d$year), min(d$year, na.rm = TRUE), max(d$year, na.rm = TRUE),
            length(e$variables_to_keep), length(e$ranked_variables) - length(e$variables_to_keep),
            sapply(c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine", "slave_men"), function(v) class(d[[v]])[1])))
write_csv(facts, "facts.csv")
write_csv(tibble(variable = names(e$ranked_variables), nonmissing = unname(e$ranked_variables),
                 kept = names(e$ranked_variables) %in% e$variables_to_keep), "fig2_completeness.csv")

# Fig 5: index (base_year as set in the script), means and counts
write_csv(e$indexed_long, "fig5_indexed_long.csv")
write_csv(e$mean_values, "fig5_mean_values.csv")
# Fig 6: Ginis by year
write_csv(e$gini_values, "fig6_gini_values.csv")
# Fig 3: top-12 shares by decade (percent of the top-12 total, as in the script)
write_csv(e$top_surname_data, "fig3_top_surname_data.csv")
# Fig 4: top-100 surname pairs
write_csv(e$surname_connections, "fig4_surname_connections.csv")
# Fig 7: summary of the plotted distributions (two-decade bins, slave-owning households)
f7 <- e$opgaaf_new2_long |> group_by(decade, category) |>
  summarise(n = n(), mean = mean(count, na.rm = TRUE), share_zero = mean(count == 0, na.rm = TRUE),
            share_gt1 = mean(count > 1, na.rm = TRUE), .groups = "drop")
write_csv(f7, "fig7_summary.csv")
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
cat("Exports written to", OUTDIR, "\n")
