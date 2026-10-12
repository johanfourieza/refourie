# Occupational mobility in South Africa
Cilliers, Jeanne and Johan Fourie (2018), Occupational mobility during South Africa's industrial take-off, South African Journal of Economics.

## Folders
- `original/`: released original data files: `CF Mobility/Results latest/Census_Comparisons.xlsx` and `Census_1911_occupations.xlsx` (published census tables).
- `repro_original/`: Stata do-files and R scripts. the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P04_CF/repro_r/01_clean.R`, in numbered order. `repro_original/recalc_census.R` runs on the released census workbooks. All other scripts need the SAF genealogy files and stop without them. Stata scripts use `tools/paths.do`.

## Data not included
- `CF_mobility_replication_data_anonymized.dta`: South African Families data (GISA); personal data; obtain from the Genealogical Institute of South Africa.
- `SAF mobility data_10.08.2017.dta`: same source; contains names and dates.
