# Black disenfranchisement in the Cape Colony, c.1887-1909
Farai Nyika and Johan Fourie (2020), "Black disenfranchisement in the Cape Colony, c.1887-1909: challenging the numbers", Journal of Southern African Studies.

## Folders
- `original/`: `1870-1909/July 2018.xlsx` and `Laura Voters/Voters1.xls` (voters' roll transcriptions, CCP 11/1).
- `repro_original/`: no original code survives; results_original.csv and PATCHES.md.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
`Rscript P26_NF/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R` run with the released data. `modern/01_primary.R` also reads the withheld Word file, so `modern/02` to `04` cannot run until it is supplied. The `compare/s5_checks` Python scripts read Word documents that are not released.

## Data not included
- `original/2. DEMOCRACY AND DISENFRANCHISEMENT/Tables and figures.docx`: manuscript tables of the published article; obtain from the article in the Journal of Southern African Studies.
