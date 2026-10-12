# P19_GF S6: deviations from the frozen method card (v3, commit d240e89)

No deviation touches the central analysis, the margins or the §8 verdict rules.

**D1. Script layout.** Card §4 names one script, `modern/01_primary.R`, that writes every output. The work is split into `00_common.R` (data, mappings, bounds), `01_primary.R` (§4 checks, central analysis, `annual_shares.csv`, `coverage_map.csv`, `primary.csv`, `verdict.csv`), `02_sensitivities.R` (§5A–§5D, `sensitivities.csv`, `missingness_items.csv`, diagnostics) and `03_figures.R`. The computations are those of the card. `verdicts.csv` (card name) and `verdict.csv` (wave-3 name) are identical. Reason: the S6 instructions ask for numbered scripts. Results did not inform this.

**D2. §5A-3 "ten years around t".** Implemented as the column maximum over years with |year − t| ≤ 5, clipped at the sheet ends. The column is unknown in year t, so this is the maximum over the ten surrounding years. If the column is unobserved in all of them, there is no cap and the year is indeterminate (the §4 cap-failure rule). Chosen when writing the code, before the sensitivity was run. Results did not inform it.

**D3. §5A-4 for H2 removes every year.** Every year in 1870–1909 has at least one unknown component of GE, so drop-unknown-years leaves 0 of 40 years. The card does not cover an empty population. It is reported as as-if not-testable (row 3: no determinate year). Found when the sensitivity ran, so the result revealed the case. It does not vote.

**D4. §5D S-b(ii).** The railway-excluded deficit is (Total Expenditure − Total Railways) − (Total Revenue − Railway revenue), with a missing railway-revenue cell counted as 0, which follows the Fig 8 construction Codex used (F6). The card does not spell out the formula. Results did not inform it. Secondary output; does not vote.

No CRAN packages were installed. No bootstrap or random draw is used (card §0); the seed is set to 19 by convention.
