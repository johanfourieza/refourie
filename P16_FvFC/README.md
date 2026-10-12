# The dynamics of inequality in a newly settled, pre-industrial society: the Cape Colony
Fourie, J. and von Fintel, D. (2010), The dynamics of inequality in a newly settled, pre-industrial society: the case of the Cape Colony, Cliometrica.

## Folders
- `original/`: released original data files: `Wealth inequality/Time 1663 - 1757 ----  EDITED.xls` (compiled opgaafrolle household returns, 1663-1757).
- `repro_original/`: the surviving original code with path patches only (PATCHES.md).
- `repro_r/`: independent R rebuild.
- `modern/`: modern reanalysis (method_card.md).

## Running
Run from the repository root. Run `Rscript P16_FvFC/repro_r/01_clean.R`, `02_analysis.R`, `03_figures.R` in order, then `modern/01_central.R` to `06_figures.R` (`00_common.R` is sourced). The `compare/s5_checks/` scripts reuse the same data; `pp_check.do` needs Stata.

## Data not included
- `Ginis.xls`: comparative Ginis from Milanovic, Lindert and Williamson (2008); obtain from the original publication. Needed only by `repro_original/s2_ginis_check.R` and one check in `compare/s5_checks/s5_checks.R`.
