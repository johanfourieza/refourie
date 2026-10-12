# The great divergence in South Africa
Dieter von Fintel and Johan Fourie (2019), "The great divergence in South Africa: population and wealth dynamics over two centuries", Journal of Comparative Economics.

## Folders
- `original/`: `Reversal of Fortunes/Census 1911.xlsx` (1911 census population table).
- `repro_original/`: surviving Stata code with path patches (PATCHES.md), results and Conley estimates.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md, DEVIATIONS.md).

## Running
Run from the repository root; Stata is needed for `repro_original`. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
No script runs without data that must be obtained elsewhere. Order: `repro_original/setup_ado.do`, the `analysis_Dec2018_run*.do` files, `build_results.R`; `repro_r/01` to `03`; `modern/00` to `05`.

## Data not included
- `data.dta`, `data.csv`: district file built from Stats SA census microdata (restricted licence) and third-party covariates; obtain from the authors and rebuild from Stats SA/DataFirst Census 1996 and 2011.
- 1911 district shapefiles: attribute tables carry NOAA and census-derived values; obtain from the authors.
- `lights.shp` and DMSP-OLS night lights: NOAA/NGDC Earth Observation Group (see `modern/provenance.csv`).
