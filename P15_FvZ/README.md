# GDP in the Dutch Cape Colony: the national accounts of a slave-based society
Fourie, J. and van Zanden, J. L. (2013), GDP in the Dutch Cape Colony: the national accounts of a slave-based society, South African Journal of Economics.

## Folders
- `original/`: released original data files: None. No input data are released for this paper.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. Scripts do not run with the released material. With the files below placed inside this paper folder, run `repro_original/01_recalc_workbook.R` to `04_year_alignment_check.R`, `repro_r/01_clean.R` to `03_figures.R`, then `modern/01_scenarios.R` to `03_figures.R`.

## Data not included
- `Van Duin en Ross.xlsx` (three versions): built on Van Duin & Ross (1987); obtain from Johan Fourie or the original publication.
- `Verwerk.xls`: shipping records from Bruijn et al.; obtain from the Dutch Asiatic Shipping database.
- `Slave prices.xlsx`: compiler not established; obtain from Johan Fourie.
