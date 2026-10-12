# 'Impending ruin' or 'remarkable wealth'? Private credit markets in the 18th-century Cape Colony
Fourie, J. and Swanepoel, C. (2018), 'Impending ruin' or 'remarkable wealth'? The role of private credit markets in the 18th-century Cape Colony, Journal of Southern African Studies.

## Folders
- `original/`: released original data files: None. No input data are released for this paper.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. No script runs with the released material. With the two `.dta` files below placed under `MOOC 8/` inside this paper folder, run `Rscript P13_FS/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R`, then `modern/01_purpose.R` to `04_verdicts.R`. The `compare/s5_checks/` scripts read the same files.

## Data not included
- `DATA20141122.dta`: MOOC8 household data merged with genealogies, treated as personal; obtain from LEAP and South African Families / GISA.
- `PURPOSEDATA_20141117.dta`: debt-item data with genealogy-matched fields; obtain from LEAP.
- MOOC8 TANAP XML and Skuld transcription workbooks: third-party or intermediate transcriptions, not read by the scripts.
