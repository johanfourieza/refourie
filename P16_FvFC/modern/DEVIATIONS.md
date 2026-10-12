# P16_FvFC S6: implementation deviations from the frozen card (v3, d59616d)

Logged under A5. "Results informed" says whether any S6 estimate, interval or verdict had been seen when the choice was made. Every choice below was written into the code before the script that it governs was first run, unless stated otherwise. No deviation changes a verdict rule, margin, threshold, family or primary design.

**D1. Script layout (results informed: no).** Card §6 names `01_central.R`–`05_verdicts.R`. Two scripts are added: `00_common.R` holds the shared functions (household build, cluster key, PCA/Gini pipeline, interval and §8 verdict functions), and `06_figures.R` draws the figures. Both are sourced or run from clean Rscript sessions like the others.

**D2. Per-draw RNG streams and escalation (results informed: no).** Draw b uses the b-th L'Ecuyer-CMRG stream from seed 20261011. A 39,999-draw run therefore contains the 9,999-draw run as its prefix, and results do not depend on the number of workers. When escalation is triggered (§4), the script computes draws 10,000–39,999 and appends them. This is identical by construction to a fresh 39,999-draw run with the same seed. H2-rise was flagged at B = 9,999 (MC SE of L₁₆₆₃ and U₁₆₆₃ = 0.0030 > 0.002) and was escalated. After escalation no endpoint was flagged, so the 3^k perturbation rule was not needed (k = 0).

**D3. Cluster key, literal reading for "WED <token>" names (results informed: no).** Two rows have `Naam` = "WED CENT" and "WED GUDRT". These are not name-only widow tokens, so under the card's rule (first whitespace token of `Naam`) they get the key surname + "|wed". No other key rule needed interpretation. 5,124 coarse clusters (5,741 exact-name clusters).

**D4. Widow key-type report (results informed: no).** Card §4 asks for the `WED` = 1 rows by key type (husband's key, surname + "|weduwee", own given name). The data carry no gender for given names, so "husband's key" cannot be told apart from "own given name" directly. It is operationalised as "the key is shared with at least one `WED` = 0 record" (560 rows). The remainder is "own given name or unlinked" (166), and name-only widow keys account for 27 (the other 13 name-only rows have `WED` = 0).

**D5. Sensitivity replications (results informed: no).** The card fixes B only for the central run. Every §5A and §5B bootstrap uses B = 9,999 with the same per-draw streams and no escalation. §5B items 5, 11, 16, 17, 18, 19 and 20 change only the Gini population, the weights or the target, not the resampled data or the PCA sample, so they are evaluated within the first 9,999 central draws (common draws).

**D6. Construction of §5B variants not fully specified by the card (results informed: no).**
- Items 6, 7, 8, 9, 10 and 13 (changed samples): both pooled PCAs are re-estimated on the changed sample and the cluster keys are rebuilt from it, so the full central pipeline is applied to the changed population.
- Item 9 follows the S5 merge rule: sum the assets and slaves, take the maximum household size, and treat the household as a farmer if any record is a farmer.
- Item 10 drops exact duplicates over all raw columns except `ID` (25 rows).
- Item 12 caps vines at the 99.9th percentile of positive farmer counts (the S5 rule; cap 159,800 vines), in both pipelines.
- Item 13 adds all 1705 rows to both PCA samples, and they are resampled with their clusters, but they never enter a Gini.
- Item 14 follows the S3 annual-PCA rule: zero-SD items get weight 0 within a year.
- Items 15a and 15b replace core 1 in both pipelines.

**D7. Intervals for single-contrast and normal-approximation variants (results informed: no).** §5B item 20 (pooled and mean initial-period contrasts) uses the sup-t machinery with one contrast at 98.75%; the percentile interval is given in the note. §5A item 4 uses X ± z₀.₉₉₃₇₅·SE for every family quantity, including the four H2-rise contrasts (pointwise, Bonferroni-level), and X − 1.96·SE for L₉₅.

**D8. §5C details (results informed: no).**
- Item 21 (letter decoding) reports point estimates only, as a stress test.
- Item 22 uses `sandwich::vcovHC(type = "HC1")` and `NeweyWest(lag = 1, prewhite = FALSE)`, with t(10) critical values.
- Item 23 applies the fn-14 rule with the central-draw 95% percentile interval of the earlier year.
- Item 24 holds the pooled PCA weights at their central values.

**D9. Reporting additions (results informed: no; none votes).**
- The §8 rules are applied to each sensitivity as a "would-be" verdict, labelled not verdict-determining (`sensitivities.csv`, and a column of `verdict.csv`).
- `test_p` in `verdict.csv` is the two-sided bootstrap percentile p for X = 0 on the single-quantity rows. It enters no rule, and it is NA for the point rows and for H2-rise.
- In the Monte Carlo flag rule, H4's L and U are each compared with all of −0.10, 0 and 0.10. The card's wording ("−0.10 and 0.10 for H4's L and U") is ambiguous, and this is the more conservative reading. No H4 endpoint came near any threshold (MC SE ≤ 0.0002).
- S-5 (Theil with zeros at their limit) is computed on the Fig 4 whole-settler sample.

**D10. Runtime, environment and a code fix (results informed: no).** Six parallel workers (shared machine; the card allows up to eight). The full pipeline 01–06 takes about 8 minutes, well under 2 hours, so no replication count was reduced. No package was installed. During development, the first run of `02_bootstrap.R` stopped with an error because the quantile helper returned named values. The helper was fixed (`unname`) before any interval was produced; the fix changes no number.
