# S2 runner for P05_DK (de Kadt et al. 2021). Environment harness only; the analysis scripts are in code/R_scripts.
# The authors ran these scripts interactively in one RStudio session (later scripts use objects such as findat/plotdat
# created by earlier ones, and railways_1907_cleaning_ddk.R:92 and census_1936_cleanedversion_ddk.R:117 reference objects
# that never exist). [ENV P6] We therefore evaluate every top-level expression in a single global session, log any error
# with its line, and continue, which is what line-by-line execution in RStudio does.
# Usage (from P05_DK/repro_original):  Rscript run_all.R
source(file.path("..", "..", "tools", "paths.R"))
repro <- normalizePath(".", winslash = "/")
work <- dpath("P05_DK", "repro_original", "work")
Sys.setenv(P05_REPRO = repro, P05_WORK = work)
dir.create(file.path(repro, "logs"), showWarnings = FALSE)

# [ENV P5] sf >= 1.0 switched geographic operations to s2; the authors' runs (2020 to Jan 2021) used sf 0.9 with planar GEOS.
sf::sf_use_s2(FALSE)

# [ENV P7] tibble >= 3.0.0 (2020-04-20) added a strict `[<-.tbl_df`. Before it, tibbles fell through to `[<-.data.frame`,
# which accepts df[, cols] <- <vector of length nrow*ncol> and a logical column index shorter than ncol (a no-op when
# all FALSE). census_1936_cleanedversion_ddk.R:41,50,59,67,88 rely on those base semantics. This shim restores them
# for calls made from the scripts (global env) only; package code keeps tibble's own method (S3 lookup from a namespace
# skips the global env).
`[<-.tbl_df` <- function(x, i, j, value) {
  cls <- class(x); class(x) <- "data.frame"; na <- nargs()
  x <- if (na == 3) { if (missing(i)) `[<-.data.frame`(x, value = value) else `[<-.data.frame`(x, i, value = value) }
       else if (missing(i) && missing(j)) `[<-.data.frame`(x, , , value = value)
       else if (missing(i)) `[<-.data.frame`(x, , j, value = value)
       else if (missing(j)) `[<-.data.frame`(x, i, , value = value)
       else `[<-.data.frame`(x, i, j, value = value)
  class(x) <- cls; x
}

scripts <- c("census_1904_1970_cleaning_ddk.R", "railways_1907_cleaning_ddk.R", "rainfall_1910_1950_cleaning_ddk.R",
             "covariates_building_ddk.R", "predicting_mortality_analysis_ddk.R", "census_1936_cleanedversion_ddk.R")

logf <- file(file.path(repro, "logs", "run_all.log"), open = "wt")
sink(logf); sink(logf, type = "message")
cat("P05_DK S2 run", format(Sys.time()), "\n", R.version.string, "\n")
cat("sf", as.character(packageVersion("sf")), "| s2:", sf::sf_use_s2(), "| stargazer", as.character(packageVersion("stargazer")),
    "| estimatr", as.character(packageVersion("estimatr")), "| dplyr", as.character(packageVersion("dplyr")), "\n")

snap <- list()
errs <- list()
for (s in scripts) {
  cat("\n==================== ", s, " ====================\n")
  ex <- parse(file.path(repro, "code", "R_scripts", s), keep.source = TRUE)
  sr <- attr(ex, "srcref")
  for (k in seq_along(ex)) {
    ln <- sr[[k]][1]
    r <- tryCatch({ withVisible(eval(ex[[k]], envir = globalenv())); "ok" },
                  error = function(e) conditionMessage(e))
    if (!identical(r, "ok")) {
      cat(sprintf("[ERROR] %s:%d  %s\n", s, ln, r))
      errs[[length(errs) + 1]] <- data.frame(script = s, line = ln, error = r)
    }
    # Harness snapshot (no analytic effect): Table 1 models are overwritten at predicting_mortality_analysis_ddk.R:94,
    # so keep them as they stood when stargazer() wrote the table.
    txt <- paste(deparse(ex[[k]])[1], collapse = "")
    if (startsWith(txt, "stargazer(")) {
      key <- sub("[.]R$", "", s)
      nm <- intersect(c("model1", "model2", "model1excl", "model2excl", "total_model", "female_model", "male_model", "meansy"),
                      ls(globalenv()))
      snap[[key]] <- mget(nm, envir = globalenv())
    }
  }
}
snap$analysis_data <- if (exists("analysis_data")) sf::st_drop_geometry(analysis_data) else NULL
snap$census_1936_reduced <- if (exists("census_1936_reduced")) as.data.frame(census_1936_reduced) else NULL
snap$n_mortality_rows <- if (exists("mortality")) nrow(mortality) else NA
saveRDS(snap, dpath("P05_DK", "repro_original", "_scratch", "s2_snapshot.rds"))
write.csv(do.call(rbind, errs), file.path(repro, "logs", "run_errors.csv"), row.names = FALSE)
cat("\nDone", format(Sys.time()), "\n")
sink(type = "message"); sink(); close(logf)
