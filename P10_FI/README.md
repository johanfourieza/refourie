# Interracial marriages in Cape Town
Fourie, Johan and Kris Inwood (2019), Interracial marriages in twentieth-century Cape Town: evidence from Anglican marriage records, History of the Family.

## Folders
- `original/`: released original data files: `R_CapeTownAnglican/Data/Cape Town sex ratio.xlsx`, `Interrace.xlsx`, `Occupations.xlsx` (census ratios, descriptive tables, occupation coding lookups).
- `repro_original/`: the authors' R script (`CapeTownAnglicanScript.R`) with path patches only (`PATCHES.md`).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P10_FI/repro_r/01_clean.R`, in numbered order. All scripts read the marriage register first and stop without it.

## Data not included
- `CT 1 March 2019.xlsx`, `Anglican Cape Town.xlsx`: named Anglican marriage records 1850-1973 (personal data); transcribed from parish registers held at UCT and Wits archives; obtain from the authors.
