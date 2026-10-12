# S2 runner for P10_FI (Fourie & Inwood 2019). Run from the project root:
#   Rscript P10_FI/repro_original/run_original.R            # main run (CT 1 March 2019.xlsx, as in the script)
#   Rscript P10_FI/repro_original/run_original.R v2018      # diagnostic: same code on 'Anglican Cape Town.xlsx' (Mar 2018)
# Evaluates the env-patched original script expression by expression (as an interactive
# session would), logs every error/warning with its source line, keeps going after errors,
# and saves snapshots of the objects that carry the published tables (models are overwritten
# later in the script). Snapshots hold microdata and go to D: scratch only (A6; rights = personal).
# The runner's own objects start with "." so the script's remove(list=ls()) does not touch them.
.root <- normalizePath(".", winslash = "/")
Sys.setenv(REFOURIE_ROOT = .root)
source(file.path(.root, "tools", "paths.R"))
.tag <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "main"
if (.tag == "v2018") Sys.setenv(P10_CT_FILE = "Anglican Cape Town.xlsx")
.scr <- dscratch("P10_FI", "repro_original", .tag)
dir.create(.scr, recursive = TRUE, showWarnings = FALSE)
.script <- file.path(.root, "P10_FI", "repro_original", "CapeTownAnglicanScript.R")
setwd(.scr)                       # descriptives.tex, literacy.tex, Rplots.pdf land in scratch
set.seed(1)
.exprs <- parse(.script, keep.source = TRUE, encoding = "UTF-8")
.refs <- attr(.exprs, "srcref")
.log <- data.frame(line = integer(), type = character(), msg = character())
cat("Expressions:", length(.exprs), "\n")
for (.i in seq_along(.exprs)) {
  .ln <- .refs[[.i]][1]
  .txt <- paste(as.character(.refs[[.i]]), collapse = " ")
  withCallingHandlers(
    tryCatch(eval(.exprs[[.i]], envir = globalenv()),
      error = function(e) { .log[nrow(.log) + 1, ] <<- list(.ln, "error", conditionMessage(e)) }),
    warning = function(w) { .log[nrow(.log) + 1, ] <<- list(.ln, "warning", substr(conditionMessage(w), 1, 200)); invokeRestart("muffleWarning") })
  # Snapshot 1: right after the 'Final regressions' block (models 5-8 = published Table 3)
  if (grepl("^summary\\(model5\\)", .txt) && exists("model8"))
    saveRDS(list(model5 = model5, model6 = model6, model7 = model7, model8 = model8,
                 angreg = angreg), file.path(.scr, "snap_table3.rds"))
  # Snapshot 2: right after literacy table (Tables 2 and 4) + Fig 3 series
  if (grepl("print\\(xtable\\(literacy", .txt))
    saveRDS(list(descriptives = if (exists("descriptives")) descriptives else NULL,
                 literacy = if (exists("literacy")) literacy else NULL,
                 years = years, angreg = angreg, ang = ang), file.path(.scr, "snap_tables24.rds"))
}
saveRDS(list(years = years), file.path(.scr, "snap_end.rds"))
cat("\n==== Condition log (", sum(.log$type == "error"), "errors,", sum(.log$type == "warning"), "warnings )\n")
.agg <- aggregate(line ~ type + msg, .log, function(x) paste(unique(x), collapse = ","))
print(.agg[order(.agg$type), ], right = FALSE)
write.csv(.log, file.path(.root, "P10_FI", "repro_original", "logs", paste0("conditions_", .tag, ".csv")), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(.root, "P10_FI", "repro_original", "logs", paste0("sessionInfo_", .tag, ".txt")))
