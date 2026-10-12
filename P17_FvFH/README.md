# A history with evidence: income inequality in the Dutch Cape Colony
Fourie, J. and von Fintel, D. (2011), A history with evidence: income inequality in the Dutch Cape Colony, Economic History of Developing Regions.

## Folders
- `original/`: released original data files: `Statafiles/opgaafrolle.dta`, `Wealth inequality/Time 1663 - 1757 ----  EDITED.xls`, `Income inequality/Summary of data sources conversions and calculations.xlsx`.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. `Rscript P17_FvFH/modern/01_build.R` and `02_primary.R` run with the released data (`00_functions.R` is sourced). `repro_r/01_clean.R` to `03_figures.R` need the Van Duin & Ross workbook listed below, and `modern/03_sensitivities.R` needs the output of `repro_r/01_clean.R`. `compare/s5_checks/05_index.R` needs the price workbook.

## Data not included
- `Van Duin en Ross.xlsx`: third-party series; obtain from Van Duin & Ross (1987).
- `December price data in excel.xlsx`: Du Plessis and Du Plessis price index; obtain from S. du Plessis.
- `Comparative.xlsx`: Milanovic et al. (2008) Ginis; obtain from the publication.
- TEPC monsterrollen wage data: obtain from TEPC / TANAP.
