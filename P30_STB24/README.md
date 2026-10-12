# Stellenbosch-Drakenstein tax censuses
Johan Fourie, Erik Green, Christiaan Burger, Chris de Wit, Kate Ekama, Jan Greyling, Hans Heese, Jan-Hendrik Pretorius, Robert Ross and Dieter von Fintel (2024), "'Waar is beter dorp in Zuid Africa dan Stellenbos?': what the Stellenbosch-Drakenstein tax censuses reveal", South African Historical Journal.

## Folders
- `original/`: `2024F_Stellenbosch/stellenbosch_clean.xlsx`; `Data/cape_panel_raw_data_processing-main.zip` (raw transcription and Python cleaning pipeline).
- `repro_original/`: the original script with environment patches (PATCHES.md) and a wrapper.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
All scripts run with the released data, in this order: `Rscript P30_STB24/repro_original/run_original.R`; `repro_r/01_clean.R` to `03_figures.R`; `compare/s5_checks/*.R`; `modern/00_common.R` to `09_figures.R`.

## Data not included
- None. The 1685 scan image is not read by any script and is not released.
