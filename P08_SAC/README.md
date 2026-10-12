# The South African Constabulary
Fourie, Johan, Albert Grundlingh and Martine Mariotti (2017), 'Poor South Africa! Will no nice English people ever come out here?' The South African Constabulary of the Anglo-Boer War, Journal of Imperial and Commonwealth History.

## Folders
- `original/`: released original data files: `FGM The SAC/Descriptives.xlsx` (authors' aggregate tables).
- `repro_original/`: Stata do-files and extraction scripts. the surviving original code with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P08_SAC/repro_r/01_clean.R`, in numbered order. All estimation scripts need the attestation records and stop without them. `repro_original/extract_results.R` reads `Descriptives.xlsx`. Stata scripts use `tools/paths.do`.

## Data not included
- `SAC final.xlsx`, `SAC_FGM.dta`: named attestation records (personal data); held by the authors, transcribed from National Archives of South Africa forms.
- SAF genealogy file (P04) read by `modern/01_build.R`: personal data; obtain from GISA.
