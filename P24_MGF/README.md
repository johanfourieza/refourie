# The missing boys: sex ratios in South Africa, 1894-2011
Francisco J. Marco-Gracia and Johan Fourie (2022), "The missing boys: understanding the unbalanced sex ratio in South Africa, 1894-2011", Economic History of Developing Regions.

## Folders
- `original/`: no data released.
- `repro_original/`: no original code survives; results_original.csv only.
- `repro_r/`: independent R rebuild; aggregate outputs only.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
`repro_r/01_clean.R` and `02_analysis.R` need the withheld registers. `modern/02_figures.R` runs from released aggregate outputs; `modern/01_reanalysis.R` needs the cleaned register file produced by `repro_r/01_clean.R`.

## Data not included
- `original/Death/*.xlsx` (Kimberley death registers 1895 to 1940): individual-level records; obtain the digitised registers from the National Archives Pretoria via FamilySearch, or the transcriptions from the authors.
- The tabulation of raw race strings from the registers is withheld because it reproduces register text.
