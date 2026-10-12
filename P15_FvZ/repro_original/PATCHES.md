# P15_FvZ S2 environment patches

**None.** The original analysis is an Excel formula chain, not code, so there is
nothing to patch. The workbooks in `original/` were read only; nothing was edited,
re-saved or recalculated in Excel or LibreOffice.

The chain was re-implemented in R (`01_recalc_workbook.R`): every formula is
lexed with `tidyxl::xlex()` and translated token by token into R, then evaluated in
dependency order from the input cells only. The translation is mechanical. No
formula was changed, no constant altered, and no cell overridden. Every analytic
quirk in the workbook (see audit.md, "Candidate S5 findings (from S2)") is kept
as is.

| # | file | diff | type |
|---|---|---|---|
| (none) | | | |

Environment: R 4.5.2, tidyxl 1.0.10, dplyr 1.2.0, tidyr 1.3.2, readr 2.1.6,
stringr 1.6.0, purrr 1.2.1 (full list in `sessionInfo.txt`). The scripts are
written to `repro_original/` and nothing is installed.

## A6 path refactor (2026-10-11)

Path-only edits under Amendment A6. All data files now live at
`D:/Data/ReplicateMe/P15_FvZ/<same relative path>` (log: `registry/data_moves.csv`).
Each script sources `tools/paths.R` and reads workbooks via `dpath("P15_FvZ", "original", ...)`;
`01_recalc_workbook.R` writes `recalc_cells_{primary,copy}.rds` to `dpath("P15_FvZ", "repro_original")`
and `02`/`03`/`04`, `modern/01_scenarios.R` read them there; `modern/01_scenarios.R` writes its
temporary `enumeration_res.rds` via `dscratch("P15_FvZ", "modern", ...)`. Scripts edited:
`repro_original/01-04`, `repro_r/01_clean.R`, `compare/s5_checks/s5_p15_scenarios.R`,
`modern/01_scenarios.R`. No computation changed. Line numbers in `01_recalc_workbook.R` are
preserved (the engine at lines 32-34 and 44-190 is read by `s5_p15_scenarios.R` and
`modern/01_scenarios.R`). Aggregate CSV/PDF/PNG outputs stay in the project. The full pipeline
was re-run and all tracked text outputs are byte-identical to the committed versions.
