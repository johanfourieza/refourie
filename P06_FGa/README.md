# Tax censuses in the Cape and the early American republic
Fourie, Johan and Frank Garmon Jr (2023), The settlers' fortunes: comparing tax censuses in the Cape Colony and early American republic, Economic History Review.

## Folders
- `original/`: released original data files: `20 FG Comparisons/Data/FourieGarmenCape.xlsx` (Cape opgaafrolle transcriptions).
- `repro_original/`: the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P06_FGa/repro_r/01_clean.R`, in numbered order. Every script needs the US or price inputs below and stops without them; place them under `D:/Data/ReplicateMe/P06_FGa/original/20 FG Comparisons/`.

## Data not included
- `FourieGarmenApril2020.xlsx`, `Data for Johan - Massachusetts and Virginia.xlsx`: Garmon's US tax-census transcriptions; obtain from Frank Garmon Jr. or the archival tax lists.
- `Analysis.xlsx` (Maddison comparisons): Maddison Project Database.
- `Prices.xlsx`: published US and Cape price series cited in the paper.
