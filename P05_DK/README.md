# The 1918 influenza in South Africa
De Kadt, Daniel, Johan Fourie, Jan Greyling, Elie Murard and Johannes Norling (2021), Correlates and consequences of the 1918 influenza in South Africa, South African Journal of Economics.

## Folders
- `original/`: released original data files: 1936 census tables 1, 3 and 7; `voter_roll_birth.dta` (birth-month counts from the 1984 voters roll); `census_covariates_1911.csv`.
- `repro_original/`: the authors' R and Stata scripts with path patches only (`PATCHES.md`); `run_all.R` expects a `work/` copy of the data tree.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P05_DK/repro_r/01_clean.R`, in numbered order. The voter-roll check (`modern/03_t2_randomization.R`, `compare/s5_checks/01_table2_voterroll.R`) runs on released data. The remaining scripts need the files below.

## Data not included
- `Phillips Table 13_all.xlsx`: Phillips (1984) thesis; obtain from the thesis.
- District, population and railway layers (`SA_1918`, `1937`, `RSA_Pop_1904_70`, `1907_TrainTracks`, Rumsey `Districts`): provenance unconfirmed or David Rumsey Collection; obtain from the authors or the Rumsey collection.
- `rain_monthly_1910-1950.csv`, derived rainfall file and `all_covariates.csv`: rainfall licence unconfirmed.
- 1960 and 1970 census microdata: Stats SA via DataFirst (UCT), restricted licence.
- Cape Town death registers 1915-1920: personal records.
