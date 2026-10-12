# Health inequality and the 1918 influenza in South Africa
Fourie, J. and Jayes, J. (2021), Health inequality and the 1918 influenza in South Africa, World Development.

## Folders
- `original/`: released original data files: None. No input data are released for this paper.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. No script runs with the released material, because every script starts from individual-level death certificates. Scripts are provided for inspection. With the data placed at the paths read by `01_clean.R` and `modern/00_common.R`, run `Rscript P12_FJ/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R`, then `modern/01_build.R` to `04_verdicts.R` (`03b_score_boot.do` in Stata). Output tables and figures are included.

## Data not included
- Death certificates 1915-1920 (`New 10 towns 1915-1920.xlsx`, `2020-05 JB Sea Point 1915-1920.xlsx`): individual-level personal records; obtain from FamilySearch (Cape Province Civil Deaths 1895-1972) or the National Archives, Pretoria.
- `Phillips Table 13_all.xlsx`: published table by a third party; obtain from Phillips (1984).
