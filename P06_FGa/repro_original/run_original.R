# S2 runner for P06_FGa. Emulates interactive RStudio execution of the patched entry point:
# each top-level expression is evaluated in turn in the global environment; an error in one
# expression is logged and execution continues (as when the authors ran the script line by line).
# Usage (from project root):
#   "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" P06_FGa/repro_original/run_original.R
local({
  root <- normalizePath(".", winslash = "/")
  source(file.path(root, "tools", "paths.R"))
  Sys.setenv(P06_ORIG = dpath("P06_FGa", "original"),
             P06_SCRATCH = dscratch("P06_FGa", "repro_original"))
  setwd(Sys.getenv("P06_SCRATCH"))
  script <- file.path(root, "P06_FGa", "repro_original", "FG_Replication_Code.R")
  logf <- file.path(root, "P06_FGa", "repro_original", "run_log.txt")
  exprs <- parse(script, keep.source = TRUE)
  srcref <- attr(exprs, "srcref")
  log <- c(paste("Run:", format(Sys.time())), R.version.string,
           paste("Script:", script), paste("Expressions:", length(exprs)))
  n_err <- 0; n_warn <- 0
  for (i in seq_along(exprs)) {
    line <- srcref[[i]][1]
    res <- withCallingHandlers(
      tryCatch({ eval(exprs[[i]], envir = globalenv()); "ok" },
               error = function(e) paste0("ERROR: ", conditionMessage(e))),
      warning = function(w) { n_warn <<- n_warn + 1; invokeRestart("muffleWarning") })
    if (res != "ok") {
      n_err <- n_err + 1
      log <- c(log, sprintf("line %d: %s", line, res))
    }
  }
  log <- c(log, sprintf("Errors: %d; warnings (muffled): %d", n_err, n_warn))
  writeLines(log, logf)
  # Save the analysis objects the claims map to (aggregate outputs only).
  keep <- intersect(c("fg", "fg_V", "fg2_V", "fgprices", "fgprices2", "descriptives", "sample",
                      "slavesdes", "cattledes", "cattletot", "gini", "desall", "desall2", "desall3",
                      "desall4", "desslaves1", "desslaves2", "gini1", "gini2", "descrops",
                      "fig5", "a", "b", "c", "d"), ls(globalenv()))
  saveRDS(mget(keep, envir = globalenv()), file.path(Sys.getenv("P06_SCRATCH"), "objects.rds"))
  cat(log, sep = "\n")
})
