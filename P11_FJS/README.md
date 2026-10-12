# Public finances under private company rule: the Dutch Cape Colony (1652-1795)
Fourie, J., Jansen, A. and Siebrits, K. (2013), Public finances under private company rule: the Dutch Cape Colony (1652-1795), New Contree.

## Folders
- `original/`: released original data files: `base.dta` (opgaafrolle household sample, 1663-1773) and `Loanfarms.xls` (loan farm register), both in `Fourie Jansen Siebrits/`.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. Stata batch scripts in `repro_original/` (`run_0_original.do`, `run_A1_wine48.do`, via `build_runs.sh`) and `Rscript P11_FJS/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R` run with the released data. `repro_original/extract_results.R`, `modern/01_tax.R` and `modern/04_sensitivities.R` need the files listed below. The other `modern/` scripts run in numeric order once those inputs are supplied.

## Data not included
- `Fiscal policy.xlsx`: authors' workbook embedding Van Duin & Ross VOC income series; obtain from Johan Fourie or the original Van Duin & Ross (1987) tables.
- `recalc_cells_primary.rds` (from P15): derived from a Van Duin & Ross based workbook; rebuild with the P15 scripts once that workbook is available.
