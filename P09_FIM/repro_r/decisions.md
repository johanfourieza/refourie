# P09_FIM — S3 decisions log

Fourie, Inwood and Mariotti (2022), "Living standards in settler South Africa, 1865–1920", *EHB* 47.
S3 agent, 11 October 2026. Inputs: the PDF and wiki markdown, `claims.csv` and `claims_spec.md`, `PROTOCOL.md` and `CLAUDE.md`, and four workbooks in `D:/Data/ReplicateMe/P09_FIM/original/FM White living standards/`: `Whitelivingstandards_7July.xlsx` (sheets `Data` and `WWI`), `WhitesWWII.xlsx` (sheet `WhitesWW2`), `Final.xlsx` and `Geocodes.xlsx`.

**The recreation is not outcome-blind.** The published tables were visible throughout, as the protocol expects.

## Independence level: conditional

No code was seen. The `Data` sheet is a cleaned, stacked file: one row per attestation, with harmonised `Region`, `Urban`, `HISCO` (major group only), `Repeat` and `Nationalitydum` already built. The region coding, urban flag, repeat-enlistment flag and race flag are therefore shared with the original data construction. The WWII heights, birth years and enlistment years are built here from the raw feet and inches and two-digit years in `WhitesWW2`.

**Incidental exposure.** One exploratory call that listed sheet and column names (no cell contents) printed the header row of the deny-listed sheets in `Whitelivingstandards_7July.xlsx` (for example, "Regression 1" with column headers "Spec (1)"…"Spec (4)", and "Descriptives"). No cell values from those sheets were read. After that only the `Data` and `WWI` sheets were opened. `Final.xlsx` (sheet `Final`) and the other `WhitesWWII.xlsx` sheets were tabulated once for structure and then not used.

## What the allow-listed data can and cannot support

| Item | Status | Reason |
|---|---|---|
| T1 source shares, Observations; T2 Total and Force rows | built for all cohorts | heights, birth year, age and enlistment year exist for all five forces |
| T1/T2 region, occupation and town ≥10,000 rows | cohorts 1–2 built in full; cohort 3 built **without its WWII recruits** (paper: 6.21% of the cohort) | **`WhitesWW2` has no province, occupation, town or religion** |
| T1/T2 cohorts 4–6 for covariates; religion rows | unavailable | the same gap: WWII covariates |
| T1/T2 town sizes Rural, <1000, 1000–1999, 2000–9999 | unavailable | the data hold only a binary urban flag (`Urban`; `Geocodes.Urban` marks 72 place names in 13 cities). No town population figures are in the allowed files |
| T3 cols 3 (SAC), 4 (CMP), 5 (AOF), 6 (WW1) | built, but town size enters as one dummy (≥10,000 vs the rest) | see above |
| T3 cols 1, 2, 7, 8; T4 col 2 | unavailable | need WWII covariates |
| T4 col 1 (WWI enlisted 1915) | built (same town caveat) | |
| T5 transitions r1 (1865–74→1875–84) and r2 (→1885–94, WWII excluded) | built; town size binary | r3–r5 need WWII covariates |
| T5 height change r1–r5 | built from the T2 totals | |
| Figs 8–10 (international) | unavailable | no Australian, Canadian, NZ or English microdata in the allowed files |
| Text numbers on enlistment shares, census shares, footnote 9 | unavailable | external sources, not data |

## Decisions (made before the regression output was seen, except where marked post-hoc)

**D1 Sources.**
- Colonial forces and WWI come from sheet `Data` (`Source` ∈ AOF, CMP, SAC, WWI). WWI rows in `Data` match the 7,106 rows of sheet `WWI`. `Data` is used for uniformity.
- WWII comes from `WhitesWW2` (10,560 rows; the rawest WWII sheet).
  - Height = (feet × 12 + inches) × 2.54. Feet must be 4–6 and inches 0–<12; otherwise height is missing.
  - Enlistment year = 1900 + `newyr`, for `newyr` 39–46 only.
  - Birth year is a two-digit year. The century is chosen so that enlistment year − birth year agrees with recorded age within ±1 year; otherwise birth year is missing.

**D2 SA-born and White.**
- Colonial and WWI records: SA-born means `Region` is one of the six regions. `Region` = "Africa" or missing is excluded.
- WWII: SA-born means `birco` = "rsa".
- White: in WWI, `Nationalitydum` = 4 (RACE = W). The 2,746 Coloured WWI records are excluded. In the colonial forces, `Black` ≠ 1. The WWII sheet holds only Whites.

**D3 Sample rules (paper p.5), applied in this order:**
1. drop `Repeat` = 1;
2. enlistment year 1890–1945;
3. birth year 1865–1920;
4. age at enlistment >20 and <50, i.e. **21–49** (see post-hoc P1);
5. height observed.

Colonial and WWI records must also be complete on region, occupation class and town flag. Table 1's shares sum to 100 in every cohort with no missing category, which implies complete cases. WWII records cannot meet this rule and are kept for T1 and T2.

**D4 Cohorts.** Ten-year bins 1865–74, …, 1905–14, plus 1915–20. Upper bounds are inclusive.

**D5 Occupation (Armstrong 1972, five classes).** HISCO in the data is the major group only (0–9). Classes are therefore assigned from the occupation string (`Calling`) with ordered keyword rules in `occupation_rules.csv`, where the first match wins:
- none, nil, student or scholar → missing;
- farm or agricultural → Agriculture;
- labourer, porter, messenger, cleaner, watchman or handyman → Unskilled;
- clerk or bookkeeper → Skilled;
- professions, managers, merchants, teachers, surveyors or draughtsmen → Middle class;
- railway firemen, stokers, shunters, platelayers, barmen, waiters, postmen, mine process workers (cyaniders, amalgamators, samplers), sorters, guards, police, soldiers or machine minders → Semi-skilled.

Where no rule fires, the class falls back on the HISCO major group: 6 → Agriculture; 0–2 → Middle class; 3, 4, 7, 8, 9 → Skilled; 5 → Semi-skilled.
- Two coding bugs in the first draft were fixed before any regression was run: "civil servant" matched "servant", and the HISCO-9 fallback sent carpenters to Semi-skilled. "Transport rider" was moved out of Agriculture.
- The resulting class shares are close to Table 1 but not equal to it. Middle class is about 5% against the paper's 2–3%, because overseers and foremen fall back to Middle class through HISCO group 2. Semi-skilled is about 11% against 6–8%. This is a genuine ambiguity: the paper gives no crosswalk.

**D6 Town size.** Only a binary flag exists: `Urban` = 1 for towns of ≥10,000 (`Geocodes.Urban` = 1 lists Cape Town, Johannesburg, Durban, Port Elizabeth, Kimberley, Pretoria, Pietermaritzburg, East London, Bloemfontein and Rand towns). The reference category "rural" in my regressions is therefore *rural plus all towns below 10,000*. The coefficient on ">10000" is comparable in spirit to the paper's, but its reference group differs.

**D7 Weights.** The paper says only "weights derived from the population censuses" (Table A.1); it gives neither the formula nor the dimensions.
- Choice: post-stratification on the margins, w = Π_d (census share_d / own-sample share_d) for d ∈ {province (Cape, Natal, Tvl, OFS), occupation (5), town (≥10,000 vs rest)}.
- The census shares come from the A.1 "Census 1911, 1918, 1921" column. The town share below 10,000 = 100 − 56.24.
- The sample shares come from the pooled colonial + WWI covariate sample. Weights are normalised to mean 1, and the same weights are used in every column.
- Religion is not used (WWII only). Unweighted estimates are also reported (`output/trunc_models_r.csv`, `weighted = FALSE`).
- Table 1, Table 2 and Table 5 are unweighted: their notes do not mention weights.

**D8 Truncated regression.**
- Left truncation at 160.02 cm. Observations below the truncation point are dropped from the regressions, as truncreg does, but kept in T1 and T2.
- The model is weighted ML for the truncated normal, coded by hand and checked against `truncreg` unweighted (`output/truncreg_check.txt`).
- "Conventional" SE = inverse of the negative Hessian of the weighted log-likelihood. This is the analogue of Stata's iweight/aweight model-based SE and is reported in `results_r.csv`. A sandwich (pweight-style) SE is also reported in `trunc_models_r.csv`.
- The paper prints t statistics, so the `_t` rows carry conventional t.
- "Attestation" is undefined in the paper. I code it as enlistment year − 1900. The published constants make this the only scale consistent with plausible heights; for example, col 7: 202.9 − 0.691 × 41 ≈ 174.6. This inference uses published numbers.
- Reference cohorts follow the Table 3 notes: SAC, CMP and AOF use 1875–84; WW1 uses 1895–1904; T4 col 1 uses 1885–94. Cohort dummies enter for every cohort present in a column, so SAC has a 1885–94 dummy (10 obs) and CMP a 1895–1904 dummy (1 obs). The paper shows neither.
- T4 col 1 omits Attestation, as in the paper.

**D9 Decomposition (T5).** The formulas are those printed in claims_spec (d). Category means and shares are unweighted. Region uses 6 regions, Class 5 classes and Town size the binary flag. The total change in the denominator is the change in the mean of the covariate sample (WWII excluded). The T5 "Height change" rows use the full-sample T2 totals.

**D10 Text numbers.**
- X_p4_forms = rows in `Data` + `WhitesWW2`.
- X_p5_sac_total = SAC rows in `Data`.
- X_p5_wwi_n = WWI rows; X_p5_wwii_n = `WhitesWW2` rows.
- X_p5_aof_town = AOF share from towns ≥10,000. The paper's "70% from Cape Colony cities" may use a broader definition of "city".

## Post-hoc changes (made after seeing sample counts against Table 1)

- **P1 Age bound.** The first run used ages 20–49, following the claims-spec paraphrase "aged 20–49". It was changed to 21–49, the paper's literal "older than 20 years and younger than 50". The change was made after seeing that the force-by-cohort counts were above the Table 1 counts. It moves the AOF counts to 36/148/109 (published ≈ 36/146/108). It is logged as post-hoc.
- **P2 Complete cases (D3).** Added in the same iteration. It is implied by the shape of Table 1, but it was added after the counts were seen.
- No other filter was tuned. Remaining count gaps are recorded as found:
  - CMP: 110/292/43 against ≈93/228/37;
  - SAC: 31/114/10 against ≈18/73/0;
  - WWII: about 5,900 against ≈3,660.

  The WWII excess is expected, because the published WWII sample must be complete on covariates I do not have.

## Post-hoc changes after regression output

- **R1 Numerical only, no change of specification.** After the first run, a Newton polish step was added to the BFGS optimum in `trunc_fit`. The `truncreg` check still shows a maximum coefficient gap of 8e-4, which is within `truncreg`'s own default convergence tolerance. Estimates changed only in the fourth decimal.
- No filter, coding rule, weight or reference category was changed after the regression output was seen.

## Output summary

- `results_r.csv`: 1,013 rows, one per claim.
  - 365 rows carry a value.
  - 647 rows are `unavailable`. The causes are missing WWII covariates, the four-way small-town split, the religion rows and the international data.
  - X_p9_trunc is `not-attempted`, because it is an input.
- Coefficient rows report the conventional SE in `se`. The `_t` rows report conventional t.
- `output/trunc_models_r.csv` holds the weighted and unweighted fits with conventional and sandwich SEs, plus supplementary pooled regressions without WWII (`s1_noWWII`, `s2_noWWII`). The supplementary fits are not mapped to claims.
- Sample: N = 9,216, of which 5,681 are WWII without covariates. The paper's N is 6,972. Regression Ns:
  - SAC 155 (published 91);
  - CMP 446 (358);
  - AOF 293 (289);
  - WW1 2,641 (2,557);
  - T4 col 1: 741 (719).
- Outputs contain aggregates only. No individual rows are written; `fig2_r.csv` keeps only birth-year cells with at least 10 recruits.
