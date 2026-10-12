# Substitutability of slaves on the eastern frontier
Calumet Links, Johan Fourie and Erik Green (2020), "The substitutability of slaves: evidence from the eastern frontier of the Cape Colony", Economic History of Developing Regions.

## Folders
- `original/`: `Calumet Links/processed.dta` (Graaff-Reinet opgaafrolle household-years with prices and output values).
- `repro_original/`: no original code survives; results_original.csv and PATCHES.md only.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
All scripts run with the released data: `Rscript P21_LFG/repro_r/01_clean.R`, then `02_analysis.R` and `03_figures.R`; then `modern/00_cluster_audit.R`, `01_primary.R`, `02_sensitivities.R`, `03_figures.R` (00_common.R is sourced). Scripts in `compare/s5_checks/` also run.

## Data not included
- None needed. The household linkage series, the cleaned workbook and the MOOC8 inventory files are not read by any released script and are not released.
