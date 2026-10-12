# Inequality in the Cape Colony, 1685-1844
Johan Fourie (2025), "Inequality in the Cape Colony, 1685-1844", South African Journal of Science.

## Folders
- `original/2024F_Inequality/`: `stellenbosch_clean_april2025.xlsx`, `stellenbosch_clean_july2024.xlsx`, `1825 series.xlsx`, `Groenekloof.xlsx`, `Swartrivier.xlsx`, `EBTstation.xlsx`, `price_series.xlsx`, `Slave Emancipation Dataset.xlsx` (Ekama, Fourie, Heese and Martin 2021).
- `repro_original/`: the author's script with path and run-flow patches (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
`repro_original/InequalityScript_rev.R` reads the workbooks from the folder in environment variable `P29_RUNDIR`; Figures 1 to 3 and 6 run with released data. `repro_r` and `modern` also read `MOOC_probates.xlsx`, which is not included, and cannot run without it.

## Data not included
- `MOOC_probates.xlsx`: MOOC 8 transcription (TANAP/TEPC); obtain from the TANAP/TEPC project.
