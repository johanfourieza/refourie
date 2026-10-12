# Method card: P10_FI, interracial marriages in twentieth-century Cape Town

Status: v3 (2026-10-11), the final revision.
- History: v1 → Codex review (reviews/P10_FI_codex_S6card.md; 8 required changes) → v2 → Codex compliance check (reviews/P10_FI_codex_S6card_v2.md; 5 blocking issues) → v3.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a.
- To be FROZEN with the commit message "FREEZE S6 card P10". Issues not fully resolved are listed in §10.

Rights class: personal. Every script runs locally on D:. Codex sees this card, code and aggregate output only.

## 1. Claims family (frozen headline rows) and interpretations
The six `headline = 1` rows in `claims/claims.csv` (A1 union) map to the verdict rows below. Interpretations are quoted from `claims/claims_spec.md`.
- Where one printed sentence makes a level statement and a comparison, the two are separate rows. Each is judged on its own margin.
- Each verdict row has exactly one primary analysis (§4) and one inference rule (§6).

**H1, chronology. Interracial marriage was rare and already declining before 1949.**

| Row | Source | Claim | A8 type | Margin |
|---|---|---|---|---|
| H1-30s | `txt_p629_share_1930s` | "less than 2.5% during the 1930s" | threshold | L30 < 2.5% (A8 default) |
| H1-dec | `txt_p629_share_1930s` | the fall "from a high of 7.5%" to the 1930s level, i.e. 1930s below 1911–1919 | comparative ">" | s₁ − L30 > 0, adjusted CI excluding 0 (A8 default) |
| H1-25s | `txt_p637_1925_share` | "a share of 3.6%" (white-husband measure, 1925) | point share | [3.24%, 3.96%] (A8a: min of ±0.03 and ±10%) |
| H1-25r | `txt_p637_1925_share` | "four times as large as the share in the total population" (0.9%, external, fixed) | point ratio | [3.6, 4.4] (A8 default ±10%) |
| H1-UX | `txt_p637_1925_share` | the Cape Town share exceeds the Union share | comparative ">" | S25 − 0.9 > 0, adjusted CI excluding 0 (A8 default) |
| H1-F | abstract, built on the H1 rows | the Act "had mostly followed, and not led" the change | threshold | F > 0.5 (**card reading**, not an A8 default; see §7) |

**H2, the Act.**
- **H2-c2** (`T3_act_c2`, 0.0003 (0.002)). "loses its significance in the second specification". Null claim.
- **H2-c4** (`T3_act_c4`, −0.006*** (0.002)). "regains it, but with a small coefficient". Magnitude claim, b₀ = −0.006.
- **H2-c2L, H2-c4L.** The same two claims, judged on the literacy-corrected specification. These are correction rows (§2).
- **H2-minor.** "the Act seems to play, at best, a minor role in explaining the decline" (p.645). **Not-testable.** A8 has no default for "minor", and no wording-based margin can be justified independently of S5.
- **H2-ITS.** The 1949 break in the annual share. A **descriptive extension, labelled `different-estimand`** relative to the published LPM coefficients. It cannot confirm or overturn any row.

**H3, segregation.**
- **H3-c2** (`T3_segregation_c2`, −0.027*** (0.005)) and **H3-c4** (`T3_segregation_c4`, −0.014** (0.006)). "The more segregated a community, the lower the likelihood of interracial marriages." Magnitude claims.
- **H3-c2L, H3-c4L.** The same two claims on the literacy-corrected specification (correction rows).
- **H3-causal.** "convincing evidence of the relevance of contact theory"; "structural factors, notably the level of segregation, help to explain the decline". **Not-testable.** There is no exogenous variation, and segregation is measured from the same marriages.

The causal half of the abstract ("a correlate to rather than the cause") is also not-testable.

**A4c.** No headline row is an odds ratio, and none is stated as an OR-based probability. All headline coefficients are LPM probabilities. The col-1 logit (non-headline) appears only in sensitivity S21, with the OR and AME each on its own scale.

**Stars.** The table notes are silent. The code uses stargazer defaults (* .10, ** .05, *** .01), so `stars05` = 2.

## 2. Defects addressed and classification
S5 (Claude C1–C10, Codex F1–F8, reconciled in `audit.md`) found:
- (a) **Act against a linear trend.** Act is identified only against a linear year trend, and its sign depends on trend form and sample start (C3, F4). This is not fixable for the published estimand. It is handled by sensitivities and the descriptive H2-ITS (Bernal, Cummins and Gasparrini 2017; Wagner et al. 2002).
- (b) **iid SEs.** Act varies by year and segregation by parish-year (C2, F5). Sources: Cameron and Miller (2015); MacKinnon and Webb (2017); Roodman et al. (2019); MacKinnon, Nielsen and Webb (2021, 2023).
- (c) **Literacy gap.** A signed difference instead of the unsigned mismatch the text defines (C8, F1).
- (d) **Data vintage.** The deposited script reads the 2019 file; the print comes from the March 2018 file (C1, C6, F2, F3).
- (e) **Interracial definition.** Figure 3 and the regressions define it differently (F2).
- (f) **Segregation measure.** An endogenous composition proxy (F6). Not fixable with these data; handled through scope and sensitivities S18 and S20.

**Classification, per row.**
- **H1 rows:** (i) correction of the interracial definition, on the published vintage. The comparative rows and H1-F add (iii) uncertainty propagation.
- **H2-c2, H2-c4, H3-c2, H3-c4 (primary LPM rows):** (ii) **inference-only**. The published specification is kept exactly, signed `dlit` included. Only the SEs change. A4b ladder.
- **H2-c2L, H2-c4L, H3-c2L, H3-c4L (correction rows):** (i) correction of a verified code error (C8), plus the same inference. The point estimates may change, so A3/A4 rules apply, including the symmetric credible null.
- **H2-ITS:** (iv) a new estimator of a different estimand. Descriptive only.

## 3. Estimands
- **L30** = 100 × I/N, pooled over calendar 1930–1939 (I = interracial couples, N = all couples).
- **s₁, s₃, s₄** = pooled shares for 1911–1919, 1939–1948 and 1949–1963.
- **H1-dec:** Δ30 = s₁ − L30.
- **H1-25s:** S25 = 100 × (white husband, non-white wife) / (all white-husband marriages), 1925. **H1-25r:** R25 = S25/0.9. **H1-UX:** E25 = S25 − 0.9.
- **H1-F:**
  - F = (s₁ − s₃)/(s₁ − s₄). It is a contrast of pooled period averages, not an exact temporal decomposition.
  - Given D = s₁ − s₄ > 0, the claim F > 0.5 is equivalent to **G = 0.5·s₁ − s₃ + 0.5·s₄ > 0**.
  - G and D are the tested estimands. The D > 0 condition is not an extra gate; F is undefined without it.
  - F is reported with a Fieller-type interval.
- **LPM rows:** the published coefficients of `model6` (spec 2) and `model8` (spec 4). Correction rows: the same coefficients with `ilit` in place of `dlit`.
- **H2-ITS (different-estimand):**
  - θ = the immediate level break in the equally year-weighted annual share at 1949, relative to the extrapolated pre-1949 trend.
  - Δslope = (b − γ₁)/10 pp per year.

## 4. Primary analyses (one per verdict row)

**Common data.**
- File: the March 2018 transcription `original/R_CapeTownAnglican/Data/Anglican Cape Town.xlsx` (data on D:). It is processed by the S2-patched original script (`repro_original/run_original.R v2018`), which reproduces the print.
- Snapshots: `D:\Data\ReplicateMe\P10_FI\repro_original\_scratch\v2018\`.
- Years 1911–1963; race is the script's three-level `mrace`/`frace`.
- **Descriptive universe:** couples with both races non-missing. Interracial = `mrace ≠ frace` (= `interdum`).
- The 258 unrecovered same-race records are bounded in S15.

**A. Point rows (H1-30s, H1-25s, H1-25r).** Point values from pooled counts, as population descriptions of the transcribed records. No inference enters these verdicts.

**A-B. Bootstrapped rows (H1-dec, H1-UX, H1-F).**
- **Sampling population.** A superpopulation of Anglican marriages generated by parishes. Parish is the resampling unit, and each parish carries all its years.
- **Bootstrap.** A parish-cluster bootstrap: parish IDs in the 2018 file drawn with replacement, B = 9,999, seed 20261011. In each draw, L30, s₁, s₃, s₄ and S25 are recomputed jointly, then Δ30, E25, G and D. This preserves their covariance.
- **Intervals.** Percentile intervals at the Family Q Bonferroni level (§6). For F, a Fieller-type interval: the set of f for which the bootstrap interval of (s₁ − s₃) − f·(s₁ − s₄) contains 0. It is reported, may be unbounded, and does not decide any verdict.
- **Undefined draws (symmetric failure rule).**
  - A draw is undefined for a quantity if any share it needs has a zero denominator. Examples: no drawn parish has marriages in a period, or no white-husband marriages in 1925.
  - Intervals use the defined draws only, and the failure rate is reported for every quantity.
  - If a quantity's failure rate exceeds **0.0625%** (6 of 9,999 draws), every row using that quantity is **not-testable**, whatever the direction of the estimate.
  - **Provenance of the threshold:** one-tenth of the smallest tail probability used, 0.05/(2·4) = 0.625%. It is fixed before any bootstrap was run, and no failure rate has been seen.
- The number of parishes, and the number with marriages in each period and in 1925, are reported.

**B. H2-ITS (descriptive; not verdict-determining).**
- Series yₜ = 100·Iₜ/Nₜ, t = 1911…1963 (T = 53), u = (t − 1949)/10.
- OLS: yₜ = Pre·(γ₀ + γ₁u + γ₂u²) + Post·(a + b·u) + εₜ. **K = 2 is frozen** (see §10).
- Outputs: θ = a − γ₀; Δslope = (b − γ₁)/10.
- Inference:
  - Newey–West HAC, Bartlett kernel, lag 3, `NeweyWest(m, lag = 3, prewhite = FALSE, adjust = TRUE)`, with t on T − 5 df;
  - a circular moving-block residual bootstrap, block length 5, B = 9,999, seed 20261011, with percentile intervals.

**C. LPM rows.**
- **Primary rows (H2-c2, H2-c4, H3-c2, H3-c4):** `model6` and `model8` exactly as published, on the v2018 snapshot samples. Signed `dlit`; listwise deletion as published.
- **Correction rows (…L):** the same, with `dlit` replaced by `ilit = abs(mlit − flit)`.
- **Single inference rule (all eight rows): a two-way wild cluster restricted bootstrap by parish and year.**
  - fwildclusterboot, `boottest.lm` (package version recorded in `modern/sessionInfo.txt`), with:
    - `clustid = c("parishdum", "year")`
    - `bootcluster = "min"` (the dimension with fewer clusters after exclusions, reported)
    - `B = 9999`, `type = "webb"`, `impose_null = TRUE`, `p_val_type = "two-tailed"`, `engine = "R"`
    - `ssc = boot_ssc(adj = TRUE, fixef.K = "none", cluster.adj = TRUE, cluster.df = "min")`
    - `conf_int = TRUE`, `sign_level = 0.05/4` (the Family Bonferroni level), inversion `tol = 1e-6`, `maxiter = 10`
  - Seeds: `dqrng::dqset.seed(20261011)` and `set.seed(20261011)`.
  - Each row yields three inputs: the unadjusted p, the Holm-adjusted p within its family (§6), and the Bonferroni CI.
- **Failure and fallback.**
  - **Failure** means boottest errors, returns a non-finite p, or fails to invert the CI.
  - **Fallback inputs:** for a failed row only, all three inputs come from two-way CR1:
    - `sandwich::vcovCL(m, cluster = ~ parishdum + year, type = "HC1", multi0 = FALSE)`, with negative eigenvalues clipped to 0;
    - t reference on min(G_parish, G_year) − 1 df;
    - unadjusted p from that t;
    - Bonferroni CI = b ± t₁₋₀.₀₀₆₂₅·SE;
    - Holm computed over the family with the mixed inputs.
  - If the CR1 SE is non-finite or 0, the row is not-testable.
  - The fallback is logged in DEVIATIONS.md. One-way schemes never replace the primary.
- **Reported for each row:**
  - G_parish, G_year and the number of parish-year intersections;
  - the minimum, median and maximum cluster sizes, and the largest cluster's share of N;
  - the maximum partial leverage by parish and by year (`summclust`);
  - the number of degenerate draws (reported, not dropped).
- **Limitation.** Parish × year clustering misses serially correlated common shocks; S16 addresses this.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
**Descriptive (H1):**
1. Windows: 1930s as 1930–1938; s₁ as 1911–1914; s₃ as 1930–1948.
2. White–nonwhite chronology (the prohibition's definition), for all H1 quantities.
3. The all-interracial 1925 share (note 15's measure).
4. Moving-block bootstrap over years for Δ30, G and D (5-year blocks within each period pool, B = 9,999).

**ITS (H2-ITS):**

5. K = 1 and K = 3.
6. Donut: drop 1949.
7. Series start in 1921.
8. WLS weighted by Nₜ.
9. Log-odds scale, logit((Iₜ + 0.5)/(Nₜ + 1)).
10. Placebo break dates b ∈ [1916, 1958] with |b − 1949| ≥ 3. Diagnostic rank of |t₁₉₄₉| among the placebo |t_b|; no p-value.
11. Prais–Winsten AR(1), an alternative estimator.
12. HAC lags of 1 and 6.
13. A second break at 1939, estimated jointly.
14. Conditional micro analogue: spec-2 regressors (published), with the linear year replaced by the segmented trend and the primary WCR.

**All rows:**

15. The 258 unrecovered same-race records. Add 258 same-race couples to (i) 1911–1919, (ii) 1930–1939, (iii) 1949–1963, and (iv) proportionally across years; recompute the H1 quantities and θ.
16. LPM rows: two-way clustering by parish and five-year blocks aligned at 1949, with the primary WCR settings.
17. LPM rows: one-way WCR by parish and by year; CR1 by parish, by year and by parish-year (benchmarks).
18. Segregation rows: the leave-one-out HHI; the lagged (t − 1) HHI; year FE in place of the linear year; parish-years with fewer than 10 marriages dropped.
19. Act rows: quadratic and cubic year trends; sample from 1921.
20. LPM rows: husband-race dummies only.
21. Col-1 logit with month, parish and year: OR and AME (non-headline).
22. Spec 3 (`model7`), published and corrected, with the primary inference.
23. **Fixed parish composition.** Parishes with at least 10 marriages in each of 1911–19, 1920–29, 1930–38, 1939–48 and 1949–63. All H1 quantities, H2-ITS and the LPM rows. For H1 and H2-ITS, a composition-standardised series with fixed parish weights (each parish's share of all 1911–1963 marriages, among these parishes).
24. **Leave-one-parish-out.** Every primary estimate re-estimated dropping each parish in turn. Report the range, and the number of drops that would change the verdict category.
25. Changed population (A4d): the 2019 file with the six unmapped parishes added and ParishID 557 excluded.
26. Diagnostic only: the original Figure 3 definition on the 2018 file.

## 6. Fixed choices
- **Vintage:** 2018. **Years:** 1911–1963. **Race:** three categories. **Act** = 1[year ≥ 1949]. **No weights** in A, A-B or C.
- **Missing data:** listwise as published (C); couples without both races excluded (A, A-B, B).
- **Multiplicity families.**
  - **Family E: H2-c2, H2-c4, H3-c2, H3-c4** (published specification).
  - **Family L: H2-c2L, H2-c4L, H3-c2L, H3-c4L** (corrected specification).
  - **Family Q: Δ30, E25, G and D.**
  - Each family has four tests: Holm-adjusted p-values and Bonferroni CIs at 1 − 0.05/4.
  - H1-30s, H1-25s and H1-25r have no inference. H2-ITS is unadjusted and descriptive.
- **Holm–Bonferroni rule** (as in P04/P18):
  - **Significance** ("adjusted CI excludes 0", A3 condition 2) is decided by the Holm-adjusted p < 0.05.
  - **Credible-null** decisions (A4a) and the comparative rows of Family Q use the Bonferroni CI.
  - When Holm p < 0.05 but the Bonferroni CI includes 0, significance follows Holm, and the discordance is flagged in `results.md`.
  - Family Q rows have no p-values; they are decided by their Bonferroni percentile CIs alone.
- **Boundary rules.**
  - p = 0.05 is not significant.
  - |b| = 0.5|b₀| meets the floor.
  - Band endpoints are inside the band.
  - L30 = 2.5 fails "< 2.5"; F = 0.5 (G = 0) fails "> 0.5".
  - b = 0, or a CI endpoint at exactly 0, counts as "sign not established" and "CI includes 0".
- **Seeds:** 20261011. Scripts: `modern/01_descriptive.R`, `02_its.R`, `03_lpm.R`, `04_sensitivities.R`, `05_verdicts.R`.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1-30s | L30 < 2.5 | A8 threshold default (T stated by the authors) |
| H1-dec | Bonferroni CI of Δ30 > 0 | A8 comparative default |
| H1-25s | 3.24 ≤ S25 ≤ 3.96 | A8a default |
| H1-25r | 3.6 ≤ R25 ≤ 4.4 | A8 point default (±10%) |
| H1-UX | Bonferroni CI of E25 > 0 | A8 comparative default |
| H1-F | Bonferroni CIs of D and G > 0 | **card reading**: "mostly" = more than half. A8 defines "typically" as a majority but not "mostly"; the card applies the same majority reading. It was fixed after F ≈ 0.77 had been seen (§10). |
| H2-c2 | Holm p ≥ 0.05 and unadjusted p ≥ 0.05 | A4b ladder (null claim) |
| H2-c4 / H3-c2 / H3-c4 | same sign, Holm p < 0.05, \|b\| ≥ 0.5\|b₀\| (0.003 / 0.0135 / 0.007) | A3 and A4b |
| H2-c2L | Holm p ≥ 0.05 | null claim on a corrected specification |
| H2-c4L / H3-c2L / H3-c4L | as the primary row; credible null: Bonferroni CI within ±0.5\|b₀\| | A3 and A4a |

- No ceilings.
- **Plausibility flag** (not verdict-determining): |b| > 1.5|b₀|, or S25 or R25 more than 1.5× the stated value.

**Disclosure.** S5 and S2 numbers seen before this card, all bearing on the verdicts:
- **Pooled shares (2018 vintage):** 1911–13 7.29%; 1911–19 6.06%; 1920s 2.71%; 1930–38 2.10%; 1930–39 2.00% (maximum annual 2.44%); 1939–48 1.75%; 1949–63 0.48%; 1950–63 0.41%.
- **Pooled shares (rebuild):** 8.31%, 2.13% and 0.38%.
- **Implied quantities:** F ≈ 0.77; the 1925 white-husband share 3.67% (ratio 4.08).
- **Act c2:** 0.00027; parish and year CR1 p 0.90 and 0.93. With a quadratic micro trend −0.0077 (p 0.003), with a cubic −0.0091, from 1921 −0.0053, on the spec-3 sample −0.0057.
- **Act c4:** −0.0065. Year CR1 p 0.044; year WCR p 0.061; parish WCR p 0.030. Act c3: year WCR p 0.075.
- **Segregation c2:** −0.0278; parish WCR p 0.0014; with year FE −0.0237; with parish-years ≥ 10, −0.0264.
- **Segregation c4:** −0.0135; parish CR1 p 0.100; parish WCR p 0.091; year WCR p 0.012.
- **Literacy (rebuild):** |m − f| gives −0.0013 against +0.0044 for the signed difference.
- **Col-1 logit with controls:** Act −0.699 (p 0.050).

Two-way WCR, the corrected original-sample LPM, every bootstrap and the ITS have not been run. The A8/A8a margins are protocol defaults. The H1-F reading, the frozen K = 2 and the 0.0625% failure threshold are card choices; their provenance is stated in §4, §7 and §10.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
**H1-30s** (threshold alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails | not-testable |
| 1 | L30 < 2.5 | confirmed |
| 2 | L30 ≥ 2.5 | qualified (threshold missed) |

**H1-25s** (A8a band alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails | not-testable |
| 1 | 3.24 ≤ S25 ≤ 3.96 | confirmed |
| 2 | S25 < 3.24 | qualified (share below the stated value) |
| 3 | S25 > 3.96 | qualified (share above the stated value) |

**H1-25r** (A8 band alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails | not-testable |
| 1 | 3.6 ≤ R25 ≤ 4.4 | confirmed |
| 2 | R25 < 3.6 | qualified (multiple below the stated value) |
| 3 | R25 > 4.4 | qualified (multiple above the stated value) |

**H1-dec and H1-UX** (comparative ">", Bonferroni percentile CI, Family Q; X = Δ30 or E25):
| # | Condition | Verdict |
|---|---|---|
| 0 | bootstrap fails, or failure rate > 0.0625% | not-testable |
| 1 | CI of X entirely > 0 | confirmed |
| 2 | CI of X entirely < 0 | overturned (reversed) |
| 3 | CI of X includes 0 | weakened |

**H1-F** (Family Q):
| # | Condition | Verdict |
|---|---|---|
| 0 | bootstrap fails, or failure rate > 0.0625% for G or D | not-testable |
| 1 | CI of D entirely < 0 | overturned (share rose; F undefined) |
| 2 | CI of D includes 0 | weakened (decline not established; F unstable) |
| 3 | CI of D > 0 and CI of G entirely > 0 | confirmed |
| 4 | CI of D > 0 and CI of G entirely < 0 | overturned (most of the pooled decline at or after 1949) |
| 5 | CI of D > 0, CI of G includes 0 | weakened |

**H2-c2** (A4b ladder, inference-only; Family E):
| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails (primary and fallback) | not-testable |
| 1 | Holm p ≥ 0.05 and unadjusted p ≥ 0.05 | confirmed |
| 2 | Holm p ≥ 0.05, unadjusted p < 0.05 | qualified (inference-fragile) |
| 3 | Holm p < 0.05 | weakened ("loses its significance" not supported) |

**H2-c4, H3-c2, H3-c4** (A4b ladder, inference-only; Family E). The point estimate equals the published-code value, so the sign and magnitude are fixed:
| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails (primary and fallback) | not-testable |
| 1 | Holm p < 0.05 | confirmed |
| 2 | Holm p ≥ 0.05, unadjusted p < 0.05 | qualified (inference-fragile) |
| 3 | unadjusted p ≥ 0.05 | weakened |

"Overturned" is unreachable on these rows (A4b).

**H2-c2L** (corrected specification; Family L):
| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails (primary and fallback) | not-testable |
| 1 | Holm p ≥ 0.05 | confirmed |
| 2 | Holm p < 0.05 | weakened (a detectable coefficient; significance alone does not establish economic importance, so it is not overturned) |

**H2-c4L, H3-c2L, H3-c4L** (corrected specification; A3/A4; Family L):
| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails (primary and fallback) | not-testable |
| 1 | opposite sign, Holm p < 0.05 | overturned (reversed) |
| 2 | Bonferroni CI within ±0.5\|b₀\| | overturned (credible null) |
| 3 | same sign, Holm p < 0.05, \|b\| ≥ 0.5\|b₀\| | confirmed |
| 4 | same sign, Holm p < 0.05, \|b\| < 0.5\|b₀\| | qualified |
| 5 | Holm p ≥ 0.05, same sign | weakened |
| 6 | Holm p ≥ 0.05, sign not established or opposite | weakened (direction lost) |

**H2-minor, H3-causal:** not-testable. **H2-ITS:** different-estimand (θ, Δslope and their HAC and block intervals reported).

**Summaries and coverage.**
- For each family, report coverage (rows assessed; rows not-testable or different-estimand).
- Report the weakest verdict among the assessed rows, ordered overturned < weakened < qualified < confirmed. Correction rows and primary rows are summarised separately.
- Every row-level verdict is reported.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P10_FI_codex_S6card.md): approve-with-changes, 8 required changes, all addressed in v2.
1. One primary per row.
2. H2-ITS labelled `different-estimand`; slope change corrected to (b − γ₁)/10.
3. A8 margins; the ±0.25D band, the ceilings and the 3.75% boundary deleted; "minor" not-testable.
4. Verdict logic and boundary rules; coverage reported separately.
5. F judged through the linear contrast G with D; Fieller-type interval for F.
6. K frozen; block bootstrap added.
7. Clustering settings, counts, leverage, and a two-way fallback.
8. Sensitivities reclassified; parish-composition and leave-one-parish-out checks added.

Optional suggestions: white–nonwhite chronology (S2); bounds for the 258 records (S15).

**Codex v2 compliance check** (reviews/P10_FI_codex_S6card_v2.md): revise again, 5 blocking issues. Responses:
1. **A8a in §8.** The H1-25s table now confirms only within [3.24, 3.96], with misses on both sides covered.
2. **Extra gates removed.**
   - H1-30s, H1-25s and H1-25r are judged on their stated margins alone.
   - The chronology comparison (H1-dec) and the Union excess (H1-UX) are now separate comparative rows, under A8 defaults.
   - §7 states which margins are A8 defaults and which are card readings (H1-F).
3. **A4b.**
   - The primary LPM rows use the published specification (signed `dlit`) and are inference-only under the A4b ladder.
   - The literacy correction is a separate set of rows (…L) under A3/A4, including the credible null.
4. **Single inference rule and complete fallback.**
   - Every LPM row uses two-way WCR. The H2-c2 dependence on CR1 is removed.
   - Failure is defined, and all three fallback inputs (unadjusted p, Holm p and Bonferroni CI) come from two-way CR1 for the failed row.
   - The Holm–Bonferroni rule is stated (§6).
5. **Undefined draws.** The −∞ assignment is replaced by a symmetric failure rule: intervals use defined draws, the failure rate is reported, and a row is not-testable above 0.0625%. The threshold is derived from the Bonferroni tail mass and fixed before any bootstrap was run.

## 10. Known limitations at freeze
1. **H1-F threshold.** The "mostly = more than half" reading is a card reading by analogy with A8's "typically", made after F ≈ 0.77 was seen. Codex has not separately ruled that it is independent of S5.
2. **Frozen K = 2.** The ITS trend degree was frozen after the S5 quadratic micro-trend result had been seen. H2-ITS decides no verdict, which limits the consequence.
3. **Defined-draw intervals.** Below the failure threshold, intervals are computed on the defined draws, which conditions on defined draws to a degree no larger than the threshold.
4. **Holm–Bonferroni discordance.** It can occur for H3-c4-type rows. Significance follows Holm, as in P04/P18, and the discordance is flagged rather than resolved.
5. **Point rows without inference.** H1-30s, H1-25s and H1-25r are judged on point values as population descriptions. In particular, S25 rests on 109 marriages in one year.
6. **External figure.** The Union share of 0.9% (von Scholtz) is treated as fixed, and its uncertainty is not propagated into R25 or E25.
7. **258 unrecovered records.** These same-race records cannot be included. S15 bounds only their effect.
8. **Serial correlation.** Two-way parish × year clustering misses serially correlated common shocks (S16 only), and HAC/block inference on 53 annual points is approximate.
9. **H2-minor and H3-causal** remain not-testable. The card therefore cannot assess the abstract's central causal sentence.
