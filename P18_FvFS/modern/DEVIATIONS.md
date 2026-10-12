# P18_FvFS S6: deviations and implementation readings (card frozen at 404b4fb)

No analysis outside the card was run. No result informed any item below; each was fixed when the code was written, before the first estimate, except D9, which records how the card's own rules read on the output.

| # | Card text | What was done | Reason | Effect |
|---|---|---|---|---|
| D1 | §4: surname "lower-case, trimmed, diacritics stripped", "built in `compare/s5_checks/`" | `tolower(trimws(iconv(surname, to = "ASCII//TRANSLIT")))`; missing surnames become singletons. | S5 used `toupper(trimws())` and stripped no diacritics. The card's definition was followed. | None. The file has no non-ASCII and no missing surnames, so the partition is the same as in S5 (1,711 surnames). |
| D2 | §4: "year and district fixed effects as published" | Absorbed as `| yr + dist` in `fepois`. Published OLS used dummies. | Standard in fixest. | Same Poisson β. fixest drops observations in fixed-effect groups whose outcome is all zero: 957 in T3 c4 (Swellendam district) and 239 in T4 c7. These observations add nothing to the Poisson score. This is not separation, and WH is never dropped. N_est 8,121 / 1,991 / 368. |
| D3 | §4: fixed effects; samples and regressors "identical to" the do-file | T4 c10 has no fixed effects or controls. | Published spec 10 (ALIGN-6) is bivariate, and the card says "as published". | None. |
| D4 | §4: "the WH cluster share of the largest cluster" | Reported as the share of WH observations in the largest WH cluster, plus the largest cluster's share of all observations. | The wording is ambiguous. | Diagnostic only. |
| D5 | §4: CR1, Holm, Bonferroni | fixest default small-sample correction. Normal reference distribution for `fepois`, and Bonferroni CI = b ± z(1 − 0.05/6)·SE. | The card names no reference distribution. | The small-cluster rule did not bind (WH clusters 116 / 116 / 42 ≥ 30), so no CV3 was computed. |
| D6 | §5.4–5.5: weights not stated | LPM and intensive margin weighted by hhsize, as in the primary. | Keeps the published weighting. | Descriptive rows only. |
| D7 | §5.2: exposure model | Run as specified. | | Algebraically identical to the primary: the Poisson score Σ x(h·y − h·μ) is the same as weighted PPML with weight h. It is reported as identical, not as an independent check. |
| D8 | §5.7: "identical on all variables" | Rows identical on all 114 variables of `final_excl_1.dta`: 14 rows (11 in T3 c4, 4 in T4 c7, 0 in c10). | Literal reading. S5 used a six-variable key (40 rows). | Negligible. |
| D9 | §8: p = Holm p, CI = Bonferroni CI | Applied mechanically. | | For T4 c10, Holm p = 0.028 (< 0.05) while the Bonferroni CI on θ includes zero (−5.1% to 229%). The two adjustments are not dual. The rule uses p, so rule 4 (qualified) applies. Rule 2 does not bind (CI upper bound 2.29 > 0.10). |
| D10 | PROTOCOL S6: deviations go in `AMENDMENTS.md` | Logged here, as the coordinator instructed. | | Coordinator to copy into AMENDMENTS.md if required. |
