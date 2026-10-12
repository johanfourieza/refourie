# Living standards in settler South Africa
Fourie, Johan, Kris Inwood and Martine Mariotti (2022), Living standards in settler South Africa, 1865-1920, Economics and Human Biology.

## Folders
- `original/`: released original data files: `FM White living standards/Geocodes.xlsx` (place-of-birth coordinates and town indicators).
- `repro_original/`: Stata do-files and R scripts. the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P09_FIM/repro_r/01_clean.R`, in numbered order. All estimation scripts need the height records and stop without them. Stata scripts use `tools/paths.do`.

## Data not included
- `Whitelivingstandards_7July.xlsx`: named attestation records (personal data), including the Inwood and Masakure WWI sample; obtain from the National Archives of South Africa registers or the authors.
- `WhitesWWII.xlsx`, `Final.xlsx`: Inwood's WWII sample and files derived from it; ask Kris Inwood.
