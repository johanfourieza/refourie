# 'For the public benefit'? Railways in the British Cape Colony
Herranz-Loncan, A. and Fourie, J. (2018), 'For the public benefit'? Railways in the British Cape Colony, European Review of Economic History.

## Folders
- `original/`: released original data files: `Fourie Herranz/Population numbers 1911 census.xlsx` (1911 census population by district and age, published Union tables).
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. `Rscript P20_HLF/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R`, then `modern/01_checks.R`, `02_primary.R`, `03_sensitivities.R`, `04_figure.R` (`00_common.R` is sourced; `01c_check_python.py` needs Python). Parameter values and carting-price observations are typed into the scripts from the published paper.

## Data not included
- Social saving workbooks (road carting prices, CPI/GDP, comparison countries): not recovered; probably held by Alfonso Herranz-Loncan.
- Railway report 1905 (scan): not read by any script; obtain from the Cape government publication.
