# When did South African markets integrate
Boshoff, Willem H. and Johan Fourie (2017), When did South African markets integrate into the global economy?, Journal for Studies in Economics and Econometrics.

## Folders
- `original/`: released original data files: `Boshoff Fourie/AgrPriceData 1.3.xlsx`, monthly Cape agricultural prices transcribed from the Statistical Registers.
- `repro_original/`: no code survives; `PATCHES.md` records this.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P03_BoF17/repro_r/01_clean.R`, in numbered order. `repro_r/01_clean.R` builds the monthly price panel from the released workbook, then stops at the annual series. `02_analysis.R`, `03_figures.R` and the bounds scripts in `modern/` need the annual series and therefore the workbook below.

## Data not included
- `Boshoff Fourie Globalisation/Globalisation data.xlsx`: contains Jacks (2006) city wheat prices and De Zwart Cape and Natal series; obtain from Jacks (2006) and De Zwart (2011).
- `Boshoff Fourie/Mealies analysis.xlsx`: provenance unconfirmed; used only in `compare/s5_checks`; ask the authors.
