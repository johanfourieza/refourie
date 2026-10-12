# Cape private capital market, 1892-1902
Lloyd Melusi Maphosa, Anton Ehlers, Johan Fourie and Edward M. Kerby (2021), "The growth and diversity of the Cape private capital market, 1892-1902", Economic History of Developing Regions.

## Folders
- `original/`: no data released.
- `repro_original/`: no original code survives; results_original.csv only.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
No script runs without the withheld workbook. Once it is in place: `Rscript P22_MEFK/repro_r/01_clean.R`, `02_analysis.R`; then `modern/01_clean.R` to `04_figures.R`.

## Data not included
- `original/Limited liability/Shareholder Record.xlsx`: shareholder transcription by a third party (Lloyd Maphosa); obtain from the author (Cape Archives LC 1 to LC 467 company files).
- Frequency tables of free-text addresses and occupations are withheld because they reproduce text from that workbook.
