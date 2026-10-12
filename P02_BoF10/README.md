# Cape trade route and the business cycle
Boshoff, Willem H. and Johan Fourie (2010), The significance of the Cape trade route to economic activity in the Cape Colony: a medium-term business cycle analysis, European Review of Economic History.

## Folders
- `original/`: released original data files: annual ship counts (`ships for eviews FROM 1652.xls`) and ship-days (`shipdays for eviews.xls`), counted by the authors from the Dutch-Asiatic Shipping dataset (Bruijn, Gaastra and Schoffer; DANS).
- `repro_original/`: no code survives (EViews); `PATCHES.md` records this.
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (`method_card.md`).
- `compare/`: comparison tables and check scripts; `claims/claims.csv`: published numbers; `tools/`: path helpers (`paths.R`, `paths.do`).

## Running
Run from the repository root, e.g. `Rscript P02_BoF10/repro_r/01_clean.R`, in numbered order. `repro_r/01_clean.R` and the modern scripts read wheat series that are not released, so they stop until those files are placed under `D:/Data/ReplicateMe/P02_BoF10/original/Boshoff Fourie Ships/` (see `tools/paths.R`).

## Data not included
- `Van Duin en Ross.xls`: Van Duin and Ross (1987); obtain from that book.
- `agricultural output data for eviews.xls`: Brunt (2007) wheat series; obtain from Brunt (2007) and Van Duin and Ross (1987).
- `Beyers (1929).xls`: Beyers (1929), Die Kaapse Patriotte.
- `causality for med freq.XLS`, `med frequency fluctuations.xls`: filtered series built from the wheat data above; rebuild as described in the paper.
