# S5: re-run the patched original script (repro_original/InequalityScript_rev.R, lines 1-3174 = all
# published figures and text blocks; read-only use) in a scratch dir on D:, and save the objects the
# S5 checks need. Inputs are byte copies of original/2024F_Inequality/*. No analytic change.
# Run from project root: Rscript P29_INEQ25/compare/s5_checks/s5_01_run_original.R
source("tools/paths.R")
S <- dscratch("P29_INEQ25", "compare")
Sys.setenv(P29_RUNDIR = file.path(S, "run"), P29_HOOKDIR = file.path(S, "hooks"))
src <- readLines("P29_INEQ25/repro_original/InequalityScript_rev.R")
stopifnot(grepl("swellendam_combined", src[3174]))
e <- new.env()
set.seed(1)
t0 <- Sys.time()
eval(parse(text = src[1:3174]), envir = e)
message("ran in ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
keep <- c("opgaaf_save2", "prices", "all_districts", "district_gk", "district_sr", "district_bd", "probates",
          "sed", "sed_full", "settlers_to_add_per_district", "gini_by_period", "combined_ginis", "gini_combined_all",
          "gini_size_data", "gini_long_with_totals", "gini_bubble_data")
for (k in keep) saveRDS(get(k, envir = e), file.path(S, "obj", paste0(k, ".rds")))
# Fig 4 legend mapping as rendered by the installed ggplot2
b <- ggplot2::ggplot_build(e$gini_probate_graph)
saveRDS(list(ggplot2 = as.character(packageVersion("ggplot2")), plot = e$gini_probate_graph), file.path(S, "obj", "fig4_plot.rds"))
