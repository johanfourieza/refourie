# S5 scenario re-runs of the patched original code (P06_FGa). Never edits repro_original/.
# Each scenario applies a textual substitution to a temp copy of FG_Replication_Code.R (written on D:),
# runs it in a fresh Rscript process expression by expression (as run_original.R; the script calls
# remove(list=ls())), and maps objects to claims with the unmodified extract_results.R logic.
# Output: P06_FGa/compare/s5_checks/scenario_results.csv
# Usage (from project root): Rscript P06_FGa/compare/s5_checks/run_scenarios.R
source("tools/paths.R")
root <- normalizePath(".", winslash = "/")
rs <- file.path(R.home("bin"), "Rscript.exe")
src  <- readLines(file.path(root, "P06_FGa/repro_original/FG_Replication_Code.R"))
ext  <- readLines(file.path(root, "P06_FGa/repro_original/extract_results.R"))
K <- 2.837757  # Combined-sheet US crop quantity = raw US bushels x K (see check_us_factor.R)
fix_wheat <- function(s) gsub("prod(Wheatreaped*PWheat,na.rm = T)", "Wheatreaped*PWheat", s, fixed = TRUE)
fix_units <- function(s) {
  i <- grep("^fg = data.table[(](fouriegarmen|fg)[)]", s)
  stopifnot(length(i) == 2)
  ins <- sprintf('fg[District %%in%% c("Maine","Massachusetts"), c("Wheatreaped","Barleyreaped","Ryereaped","Oatsreaped","Cornreaped") := lapply(.SD, function(x) x / %s), .SDcols = c("Wheatreaped","Barleyreaped","Ryereaped","Oatsreaped","Cornreaped")]', K)
  for (j in rev(i)) s <- append(s, ins, after = j)
  s
}
set_rate <- function(r) function(s) gsub("*0.06", paste0("*", r), s, fixed = TRUE)
keep_va <- function(s) { i <- grep("^desall3 = fg_V", s); stopifnot(grepl("Virginia", s[i + 1])); s[i + 1] <- "  filter(TRUE) %>%  # S5: Virginia kept"; s }
scen <- list(
  base            = list(),
  wheat           = list(fix_wheat),
  units           = list(fix_units),
  wheat_units     = list(fix_wheat, fix_units),
  base_va0        = list(keep_va),
  wheat_va0       = list(fix_wheat, keep_va),
  wheat_units_va0 = list(fix_wheat, fix_units, keep_va),
  base_r03        = list(set_rate(0.03)),
  base_r10        = list(set_rate(0.10)),
  wheat_units_r03 = list(fix_wheat, fix_units, set_rate(0.03)),
  wheat_units_r10 = list(fix_wheat, fix_units, set_rate(0.10)))
runner <- '
args <- commandArgs(TRUE); script <- args[1]; objf <- args[2]
setwd(Sys.getenv("P06_SCRATCH")); exprs <- parse(script); .nerr <- 0
for (.i in seq_along(exprs)) { .r <- tryCatch({ suppressWarnings(suppressMessages(eval(exprs[[.i]], envir = globalenv()))); "ok" }, error = function(e) conditionMessage(e))
  if (!identical(.r, "ok")) { .nerr <- .nerr + 1; cat("ERR expr", .i, .r, "\n") }
  if (!exists("exprs")) { exprs <- parse(commandArgs(TRUE)[1]); objf <- commandArgs(TRUE)[2]; .nerr <- if (exists(".nerr")) .nerr else 0 } }
keep <- intersect(c("fg","fg_V","fg2_V","fgprices","fgprices2","descriptives","sample","slavesdes","cattledes","cattletot","gini","desall","desall2","desall3","desall4","desslaves1","desslaves2","gini1","gini2","descrops","fig5","a","b","c","d"), ls(globalenv()))
saveRDS(mget(keep, envir = globalenv()), commandArgs(TRUE)[2])'
out <- list()
for (nm in names(scen)) {
  s <- src; for (f in scen[[nm]]) s <- f(s)
  sd <- dscratch("P06_FGa", "compare", nm); dir.create(sd, showWarnings = FALSE)
  script <- file.path(sd, "script.R"); writeLines(s, script)
  rf <- file.path(sd, "runner.R"); writeLines(runner, rf)
  objf <- file.path(sd, "objects.rds"); resf <- file.path(sd, "results.csv")
  Sys.setenv(P06_ORIG = dpath("P06_FGa", "original"), P06_SCRATCH = sd)
  log <- system2(rs, c(shQuote(rf), shQuote(script), shQuote(objf)), stdout = TRUE, stderr = TRUE)
  errs <- grep("^ERR expr", log, value = TRUE)
  ex <- ext
  ex <- sub('dscratch("P06_FGa", "repro_original", "objects.rds")', deparse(objf), ex, fixed = TRUE)
  ex <- sub('"P06_FGa/repro_original/results_original.csv"', deparse(resf), ex, fixed = TRUE)
  exf <- file.path(sd, "extract.R"); writeLines(ex, exf)
  system2(rs, shQuote(exf), stdout = FALSE, stderr = FALSE)
  r <- read.csv(resf); r$scenario <- nm; r$n_errors <- length(errs)
  out[[nm]] <- r[, c("scenario", "claim_id", "value", "n_errors")]
  cat(nm, "errors:", length(errs), "|", substr(paste(errs, collapse = " ; "), 1, 300), "\n")
}
res <- do.call(rbind, out)
write.csv(res, file.path(root, "P06_FGa/compare/s5_checks/scenario_results.csv"), row.names = FALSE)
