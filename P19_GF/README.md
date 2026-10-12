# Public sector growth in the British Cape Colony, 1830-1910
Gwaindepi, A. and Fourie, J. (2020), Public sector growth in the British Cape Colony: evidence from new data on expenditure and foreign debt, 1830-1910, South African Journal of Economics.

## Folders
- `original/`: released original data files: None. No input data are released for this paper.
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. Scripts do not run with the released material. With the two workbooks below placed under `colonial govt fiscal/` inside this paper folder, run `Rscript P19_GF/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R`, then `modern/01_primary.R` to `03_figures.R` (`00_common.R` is sourced).

## Data not included
- `Abel Gwaindepi CC fiscal records.xlsx` and `colonialfiscal 18271909.xlsx`: Blue Book compilation by Abel Gwaindepi; obtain from him or from the Cape Colony Blue Books.
