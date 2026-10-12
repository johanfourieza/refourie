# P26_NF S6 deviations from the frozen method card (v3, commit d240e89)

- **D1. S5/S6 read the locked rebuild's scratch outputs.** §5 S5 names `repro_r/01_clean.R` at 35b12d7 as the implementation. `02_sensitivities.R` reads that script's outputs (`D:/Data/ReplicateMe/P26_NF/repro_r/_scratch/r09.rds`, `yr.rds`) rather than re-running it. `git diff 35b12d7 -- repro_r` is empty, so the outputs come from the frozen code. The matching rules, normalisation, sheet choice (more rows per division-year) and 1886/1887 sheet map are copied verbatim from `repro_r/02_analysis.R`. For the F6 counts only, the four 1886/87 sheets (J18, J22, V19, V21) are re-read with the same `rd()` reader before the surname filter. Reason: runtime and reuse. Not informed by results.
- **D2. The c4 cross-check (§4 A) is re-implemented in R** inside `01_primary.R`, using the same regex logic as `compare/s5_checks/c4_docx_vs_published.py`, so that the primary script is self-contained. It gives the same result as S5: 200 cells, 0 mismatches. Not informed by results.
- **D3. Extra script `04_figure.R`.** §6 lists scripts 01–03. A fourth script draws the figure and writes `sessionInfo.txt`. It computes nothing that enters a verdict. Not informed by results.

No packages were installed. No integrity failure occurred, and |D| = 14, so no reconciliation entry was needed (§4 D).
