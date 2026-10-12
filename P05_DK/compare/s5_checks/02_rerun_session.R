# S5: re-run the authors' R pipeline in a scratch copy of the S2 working tree (D:, A6) with the same environment
# harness as repro_original/run_all.R (patches P1-P7), and save the full workspace to D: scratch for the S5 checks.
# Nothing is written to repro_original/. Usage (project root): Rscript P05_DK/compare/s5_checks/02_rerun_session.R
root <- normalizePath(".", winslash = "/")
source(file.path(root, "tools", "paths.R"))
repro <- file.path(root, "P05_DK", "repro_original")
work <- dscratch("P05_DK", "compare", "work")
unlink(work, recursive = TRUE); dir.create(work, recursive = TRUE)
file.copy(list.files(dpath("P05_DK", "repro_original", "work"), full.names = TRUE), work, recursive = TRUE)
Sys.setenv(P05_REPRO = repro, P05_WORK = work)
sf::sf_use_s2(FALSE)
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
keep <- list()
sink(dscratch("P05_DK", "compare", "rerun.log"))
for (s in scripts) {
  ex <- parse(file.path(repro, "code", "R_scripts", s), keep.source = TRUE)
  for (k in seq_along(ex)) {
    r <- tryCatch({ withVisible(eval(ex[[k]], envir = globalenv())); "ok" }, error = function(e) conditionMessage(e))
    if (!identical(r, "ok")) cat("[ERROR]", s, attr(ex, "srcref")[[k]][1], r, "\n")
    if (startsWith(paste(deparse(ex[[k]])[1], collapse = ""), "stargazer(") && s == scripts[5])
      keep$t1 <- mget(c("model1", "model2", "model1excl", "model2excl", "analysis_data", "analysis_data_excloutliers"), envir = globalenv())
  }
}
sink()
setwd(root)
keep$findat <- sf::st_drop_geometry(findat); keep$mortality <- mortality; keep$distinct_OrgnlNm_1918 <- NULL
keep$census_1936_merge <- census_1936_merge; keep$census_1936_reduced <- census_1936_reduced
keep$european_ages_1936 <- european_ages_1936; keep$unemployment_1936 <- unemployment_1936
keep$mag19181937_key <- mag19181937_key; keep$distinct_1936 <- distinct_OrgnlNm; keep$covariates <- covariates
keep$t3 <- list(total_model = total_model, female_model = female_model, male_model = male_model)
saveRDS(keep, dscratch("P05_DK", "compare", "s5_session.rds"))
cat("saved", dscratch("P05_DK", "compare", "s5_session.rds"), "\n")
