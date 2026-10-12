# The missing people: Khoesan productivity
Fourie, Johan and Erik Green (2015), The missing people: accounting for the productivity of indigenous populations in Cape colonial history, Journal of African History.

## Folders
- `original/`: released original data files: `14 FG Missing People/missingpeople.dta`, `slaveproductivity.dta`, `Data.xlsx` (opgaafrolle household data).
- `repro_original/`: Stata do-files and extraction scripts. the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P07_FG/repro_r/01_clean.R`, in numbered order. The Stata scripts `run_CreatingKhoe.do`, `run_Do.do` and `run_productivity.do`, and `repro_r/`, use released data. `repro_original/excel_recalc.R`, `modern/04_theil.R` and the GDP checks need the workbooks below. Stata scripts use `tools/paths.do`.

## Data not included
- `Dataset.xlsx`: mixes Van Duin and Ross (1987), Shell (1994) and other third-party series with the authors' counts; obtain the sources or ask the authors.
- `KhoesanGDPnew.xlsx`: contains Van Duin and Ross (1987) accounts and export series.
