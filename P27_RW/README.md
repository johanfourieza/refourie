# Wealth of the Dutch Cape Colony from probate inventories
Johan Fourie (2013), "The remarkable wealth of the Dutch Cape Colony: measurements from eighteenth-century probate inventories", Economic History Review.

## Folders
- `original/`: Stata files `numbersandwealth.dta`, `frequency_equipment.dta`, `statadata.dta`, `statadata2.dta`, `value_sum.dta`, `opgaafrolle.dta`; `ChapterValue.xlsx`.
- `repro_original/`: Stata and R code written to reproduce the published tables (PATCHES.md); `original_dofiles/` are verbatim 2010 do-files with absolute paths and do not run.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
`repro_original/Stata/01_descriptives.do` runs with released data, then `R/02_excel_chain_and_results.R` (Table 1 rows need the withheld 1732 table). `repro_r` and `modern` need the withheld opgaafrolle workbook.

## Data not included
- `original/Data/Opgaafrolle 1 Des 2010.xlsx`: contains third-party sheets (Crayen and Baten; Coertzen); obtain the opgaafrolle from the author and Crayen and Baten (2010).
- `original/Data/Jobs in 1732.xlsx`: table from Schutte (1988); obtain from that publication.
