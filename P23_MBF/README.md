# Leader selection and education in 11 African countries
Laura Maravall, Joerg Baten and Johan Fourie (2023), "Leader selection and why it matters: education and the endogeneity of favouritism in 11 African countries", Review of Development Economics.

## Folders
- `original/`: no data released.
- `repro_original/`: surviving Stata code with path patches (PATCHES.md), result tables and `code/run_t2.do` to `run_t5.do` wrappers.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis in Stata and R (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root; Stata scripts need Stata, and `outreg2` and `corrtex` from SSC. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
No script runs without data that must be obtained elsewhere (listed below).

## Data not included
- IPUMS-International census microdata and every file derived from it (collapsed region-by-birth-decade files, IPUMS boundary shapefiles): IPUMS user agreement; obtain by re-extracting the 11 censuses from international.ipums.org.
- Murdock/Nunn tribe-level files and the Brookings African Leadership Transitions Tracker: third-party data; obtain from the Nunn and Wantchekon replication data and the Brookings Institution.
- Aggregate result tables are released.
