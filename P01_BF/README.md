# Numeracy in the Cape Colony court registers
Baten, Joerg and Johan Fourie (2015), Numeracy of Africans, Asians, and Europeans during the early modern period: new evidence from Cape Colony court registers, Economic History Review.

## Folders
- `original/`: released original data files: none.
- `repro_original/`: Stata do-files (`run_*.do`, the original `0redo ... .do`) and extraction scripts. the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P01_BF/repro_r/01_clean.R`, in numbered order. All three code sets read the court-record transcription (`data.dta`, `BatenFourie*.xlsx`), which is not released, so none runs as shipped. Place the files under `D:/Data/ReplicateMe/P01_BF/original/Baten Fourie/` (see `tools/paths.R`). Stata scripts use `tools/paths.do`; `install_ado.do` installs outreg2.

## Data not included
- `data.dta`, `BatenFourie.xlsx`, `BatenFourie19Sept.xlsx`: court-record transcription derived from Heese (Reg en onreg) and TEPC convict and exile documents; obtain from the Western Cape Archives (Cape Court of Justice series) and those compilations, or from the authors.
- `br300407.dta` (Rio de Janeiro prison records): Baten et al., Tuebingen Database on Human Capital; not recovered.
