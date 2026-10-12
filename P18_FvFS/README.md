# Settler skills and colonial development: the Huguenot wine-makers in eighteenth-century Dutch South Africa
Fourie, J. and von Fintel, D. (2014), Settler skills and colonial development: the Huguenot wine-makers in eighteenth-century Dutch South Africa, Economic History Review.

## Folders
- `original/`: released original data files: `Statafiles/opgaafrolle.dta`, `French Huguenots/Province-group split.xlsx`, `French Huguenots/results.zip`, and the unzipped analysis file `repro_original/extracted/results/exclpc/final_excl_1.dta`.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. Stata: `hhsize.do`, `published_spec_attempt.do`, `settlers_from_log.do`; then `Rscript P18_FvFS/repro_original/build_results.R` and `verify_2010log.R`. `repro_r/01_clean.R` to `03_figures.R` run except for the probate-inventory and Huguenot-list steps that need the files below. `modern/00_data.R` to `03_figures.R` run with the released data.

## Data not included
- `MOOC.xlsx`: probate inventories transcribed by TANAP / Groenewald et al.; obtain from the MOOC 8 series, Cape Town Archives.
- `List of Huguenots.xlsx`: compiled from Coertzen (1988) and Botha (1919); obtain from those sources or Johan Fourie.
