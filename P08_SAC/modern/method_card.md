# Method card: P08_SAC, the South African Constabulary attestations

Status: v3 (2026-10-11), the final revision after the Codex compliance check of v2 (`reviews/P08_SAC_codex_S6card_v2.md`, five blocking issues). It is to be FROZEN with the commit message "FREEZE S6 card P08". No modern estimate has been run.

Rights class: personal. Scripts read microdata only from `D:\Data\ReplicateMe\P08_SAC\`; the S5 reference surname stock, used in one sensitivity, is read from `D:\Data\ReplicateMe\P04_CF\`. Scripts write aggregates only, to `P08_SAC/modern/output/`. No row, surname or surname-level score leaves D:. Codex sees this card and aggregate outputs only.

## 0. Type of primary analysis
- **Wage claims (I4, I5): (ii) an inference-only upgrade (A4b ladder).** The primary analysis keeps the published specification, the published sample and the authors' `Afrikaans` regressor. Only the inference changes. Point estimates equal the published ones (spec 4: Afrikaans −0.0568, England 0.0777, N 7,389). Under A4b, "overturned" cannot be reached.
- **Height claims (I3) and the Boer-republic wage (I6): (ii) inference added to published descriptive contrasts.** The Table 1 means are recomputed on the Table 1 sample, and a robust test is added; the authors report none. The p.592 cohort contrast (I3b) is computed on the cohorts the claim names (1860–1885). It has no published number, so it can be reversed.
- **Composition (I1): a descriptive recomputation** judged against A8's default margins.
- **Data scope (I2): not-testable in S6.**

Surname-classification alternatives, the SA-born-only sample, Oaxaca–Blinder decompositions and the corrected adult height sample are **reported sensitivities**. They do not decide any verdict, and no gate or veto rests on them (§5).

## 1. Claims family (headline rows) and interpretations
Interpretations follow the authors' words (claims_spec.md (b)). The rows are split by claim type under A8.

- **I1, composition** (`tx_p585_uk`).
  - **I1-L**, the point claim: UK-born share = 83.1%.
  - **I1-T**, the threshold claim "a volunteer force of mostly English recruits" (abstract): UK-born share > 0.5. The England-born share > 0.5 is reported beside it.
- **I2, data scope** (`tx_p580_terms`, 10,399 service terms). A count of digitised records; S4 governs.
- **I3, colonial-born taller** (`T1_England_height` 172.91, `T1_SouthernAfrica_height` 175.03).
  - **I3-L**, the two levels: point claims 172.91 and 175.03 cm.
  - **I3a-C**, comparative: Cape/Natal-born mean height > England-born mean height (Table 1 sample).
  - **I3a-M**, magnitude: "about two centimetres taller than those born in England" (p.588). b₀ = 175.03 − 172.91 = 2.12 cm.
  - **I3b-C**, comparative (p.592): recruits born in the South African territories (Cape/Natal + Boer republics) **between 1860 and 1885** were "significantly taller than those born in Great Britain" (England, Scotland, Wales) in the same cohorts. No magnitude is stated, so no floor and no credible-null band apply.
  - I3b is a separate claim on a changed population (the named cohorts). It has its own verdict, which never enters the Table 1 height headlines (§8).
  - Scope: the authors read the gap as a difference in early-childhood living standards and acknowledge selection (pp.591–592). The verdict concerns the mean heights of recruits, not population living standards.
- **I4, the Dutch-speaker wage gap** (`T3_afrikaans_s4`). The authors say "Dutch-speakers from across southern Africa earned lower wages (5.1 per cent less in the final specification) than their English-speaking compatriots."
  - **I4-LP**, magnitude claim on the coefficient: b₀ = −0.057 log points.
  - **I4-PCT**, magnitude claim on the stated percentage, judged on 100·(1 − exp(b)): b₀ = 5.1% (the A4c logic of separate rows).
  - **I4-D**, "it is discrimination rather than differences in observable characteristics that explains the discrepancy" (p.594, fn 36): **not-testable**. The data hold no design that identifies discrimination, and a Blinder–Oaxaca decomposition is a decomposition of associations. It is reported as a sensitivity only (§5.5).
- **I5, the Boer-republic vs England wage gap** (`T3_england_s4`). The authors say "those born in the Boer republics earned 8.6 per cent less than those born in England."
  - **I5-LP**, the coefficient: b₀ = 0.078 (Boer republics are the reference).
  - **I5-PCT**, the percentage, judged on 100·(1 − exp(−b)): b₀ = 8.6%.
- **I6, Boer recruits earned lower wages** (`T1_Boerrepublics_wage`; conclusion p.599).
  - **I6-L**, the point claim: mean wage 4.46.
  - **I6-C**, comparative: Δ = mean wage (Boer-republic-born) − mean wage (all other recruits) < 0. The comparator is every first-term recruit not born in the Boer republics. The conclusion lists the Boer contrasts without naming a single comparator, and Table 1's comparison column is the total. Comparators of England-born and European-born recruits are sensitivities (§5.8).
  - Units: shillings per **day** (the transcription labels; Codex F5), not per week as Table 1 says. The relabel changes no number.

## 2. Defects addressed
- **(a) The SEs are conventional OLS, unstated, and the residuals are strongly heteroskedastic** (S5 C7, Codex F7). HC1 |t| on Afrikaans falls from 12.45 to 3.69.
- **(b) No uncertainty is reported for the height and wage comparisons** (claims_spec (e) item 20); "significantly taller" is asserted without a test.
- **(c) Fragilities reported, not corrected, in the primary:**
  - the subjective surname flag (C8);
  - the pooled specification borrowing slopes from British recruits (C9);
  - the unreported decomposition (C9, F7);
  - the script/table height-sample inconsistency (C4, F4);
  - the stale percentages (C3, F3).

Sources:
- White (1980), MacKinnon and White (1985) and Long and Ervin (2000) on HC SEs;
- Cameron and Miller (2015) and Pustejovsky and Tipton (2018) on CR2 with Bell–McCaffrey–Satterthwaite df;
- Carter, Schnepel and Steigerwald (2017) on the effective number of clusters;
- Cameron, Gelbach and Miller (2008), Webb (2023) and MacKinnon, Nielsen and Webb (2023) on the wild cluster bootstrap;
- Roodman et al. (2019) on test-inversion intervals;
- Fortin, Lemieux and Firpo (2011) on the interpretation of the unexplained component.

## 3. Estimands
- **I1:** the UK-born and England-born shares of first-term persons with a known country of birth.
- **I3-L, I6-L:** the Table 1 means. **I3a:** the difference in mean height, Cape/Natal minus England, on the Table 1 sample. **I3b:** the difference in mean height between pooled SA-territory-born and pooled GB-born recruits, both born 1860–1885 (`Birthyear`).
- **I4, I5:** the published spec 4 OLS coefficients, unchanged.
- **I6-C:** Δ as defined in §1.
- Different estimands (sensitivities only): the age-adjusted adult height gap, coefficients under other classifiers or samples, and decomposition components.

## 4. Primary analysis
**Data.**
- Source: the `Augmented` sheet of `original/FourieSAC2026/SAC final.xlsx` (on D:), imported as in S2 patch E2.
- Wage sample: exactly `Occupations.do` spec 4. `Region` ≠ "."; `Repeatlast` = 0; `Age` > 18 or missing; listwise deletion on the spec 4 covariates. The implementer verifies b = −0.0568 and N = 7,389 before any SE is computed. If either check fails, the result is not-testable.
- Height and I6 sample: first terms (`Repeatlast` = 0) with `RegionDum` known and the variable non-missing. This is the Table 1 sample; the implementer verifies 172.91, 175.03 and 4.46 to 2 dp. For I3b, the sample is additionally restricted to 1860 ≤ `Birthyear` ≤ 1885 for RegionDum ∈ {5, 9} (SA territories) against RegionDum ∈ {1, 8, 10} (Great Britain).
- I1 sample: first terms with a known `Country`.

**Only the designated primary test decides a verdict.** Secondary tests are reported. Where a secondary test disagrees with the primary at the 0.01 level, a "secondary disagreement" flag is printed beside the verdict; it never changes the verdict.

**Wage inference (I4, I5).** The model is `reg lwage afrikaans age height weight married ib6.hisco ib5.regiondum i.eyear` (R: `lm`, identical design).
- **Primary test:** the wild cluster restricted (WCR) bootstrap.
  - Clusters: enlistment `EYear` × `EMonth`, defined on the estimation sample.
  - Webb six-point weights, B = 9,999, seed 20261011.
  - Implementation: `fwildclusterboot::boottest`, null imposed, two-sided.
  - CI: test inversion at the decision level (below), so the test and the interval agree by construction.
- **Secondary test (reported, non-deciding):** HC3, with a t-reference on N − k df.
- **Reported diagnostics (not verdict-determining):**
  - the estimation-sample number of clusters G;
  - cluster sizes (minimum, median, maximum);
  - the number of clusters containing an Afrikaans = 1 observation, and the share of those observations in the largest such cluster;
  - the Carter–Schnepel–Steigerwald effective cluster count G* for the coefficient of interest;
  - the CR2 SE with Bell–McCaffrey–Satterthwaite df (clubSandwich) and that df;
  - the maximum leverage h_ii;
  - HC1 and conventional SEs, for the link to S5.
- **Justification for month clusters.** SAC pay rates and recruiting batches changed by date, so recruits who enlisted in the same month shared wage-setting conditions.
- **Independence assumption, stated explicitly.** The primary assumes that scores are independent across enlistment months. That fails if dependence runs across months, for example through a recruiting place, a recruiting officer or a pay-scale regime spanning several months. The assumption is not tested by the primary; sensitivity §5.2 (place and two-way clustering) reports how much it matters, without deciding the verdict.
- **WCR validity diagnostics** (computed on the estimation sample before the WCR p-value is inspected):
  - G₁, the number of clusters containing at least one Afrikaans = 1 observation (the "treated" clusters of MacKinnon and Webb 2017, 2018);
  - the share of Afrikaans = 1 observations in the largest treated cluster;
  - G*, the Carter–Schnepel–Steigerwald effective number of clusters for the coefficient.

  For I5 (England), the same diagnostics are computed with "treated" defined as England = 1 in place of Afrikaans = 1.
- **Validity flag.** The flag is raised if G₁ < 10, **or** the largest treated cluster holds more than 50% of treated observations, **or** G* < 10.
  - Provenance: these cut-offs come from the few-treated-clusters simulations in MacKinnon and Webb (2017, 2018). There, WCR rejection rates fall well below nominal when treated clusters number in single digits, or when one cluster dominates. The cut-offs are round numbers fixed here. S5 computed no cluster counts, and none has been computed since, so no S5 result informed them.
  - Consequence: with few treated clusters, WCR is conservative (it under-rejects), so p₁ < 0.01 remains valid evidence, but p₁ ≥ 0.01 is uninformative. The verdict tables (§8) map "flag raised and p₁ ≥ 0.01" to not-testable (primary inference unreliable).
- **Failure handling.** If `boottest` fails, returns a non-finite statistic, or yields fewer than 399 distinct bootstrap statistics, the run is repeated once with seed 20261012. A second failure makes the row not-testable (primary inference failed). No other test is substituted as the decider.

**Height and I6 inference (I3a, I3b, I6-C).**
- **Primary test:** the HC2 SE of the difference in means (a regression on a group dummy, equivalent to Welch), with Satterthwaite df. This assumes independence across recruits; height measurement and wage assignment are individual.
- **Secondary test (reported, non-deciding):** CR2 clustered by enlistment `EYear` × `EMonth`, with Bell–McCaffrey–Satterthwaite df.
- **Failure handling.** The test is undefined if either group has fewer than 2 non-missing observations, or zero variance. That is a mechanical requirement of the estimator, not a gate; the row is then not-testable.

**Multiplicity and alignment.**
- Five inferential hypotheses: I3a, I3b, I4 (shared by -LP and -PCT, which are monotone transforms of one coefficient), I5 (shared by -LP and -PCT) and I6-C.
- **Bonferroni at α = 0.05/5 = 0.01** is used for every primary and secondary test, and every reported CI is the 99% inversion of the same test. Test and interval therefore always agree.
- Decisions use unrounded values. Rounding (3 dp for log points, 2 dp for cm, shillings and percentages) is for display only.

**Descriptive rows (I1-L, I1-T, I3-L, I6-L).** No sampling inference. The values are computed and compared with the A8 bands.

## 5. Reported sensitivities (exhaustive; none determines a verdict; no gates or vetoes)
1. **Inference variants:** HC1, HC3 and CR2 for every inferential row, plus the WCR bootstrap with Rademacher weights.
2. **Dependence by place:** clusters by recruiting place (`Place`), and two-way clustering by place and year × month (Cameron, Gelbach and Miller 2011). For the WCR bootstrap, the bootstrap clusters are the coarser dimension.
3. **Surname classification:** spec 4 with (a) the S3 rule `boer_surname()` (`repro_r/01_clean.R:276`, sourced unchanged and applied to `Surname`), and (b) a probabilistic surname-origin score.
   - (b) is labelled an **unvalidated, different-estimand** regressor: genealogy membership and British birthplace do not establish home language, and the regression-calibration conditions (E[D | surname, region, X], non-differential error, transportability) are not tested.
   - Score construction, fully specified:
     - **Normalisation.** N(s) = lowercase; transliterate to ASCII (`iconv` to `ASCII//TRANSLIT`); delete every character outside a–z; replace `ij` with `y`. An empty N(s) means a missing score, and the recruit is dropped from this sensitivity and counted.
     - **Stocks.**
       - A: one record per distinct `individual_id` with 1840 ≤ `year` ≤ 1888 in `P04_CF/original/CF Mobility/Data/SAF mobility data_10.08.2017.dta`.
       - B: first-term SAC recruits with `RegionDum` ∈ {1, 7, 8, 10}.
       - n_A(s), n_B(s) are the counts of N(surname) = s; N_A = Σ n_A, N_B = Σ n_B; V_A, V_B are the sets of names with n > 0 in each stock.
     - **Smoothing (within stock; α = 0.5).** f_A(s) = (n_A(s) + α)/(N_A + α·(|V_A| + 1)), and f_B(s) likewise with B's quantities. The "+1" reserves the mass of one unseen type in each stock.
     - **Likelihood and posterior.** For SA-born recruit i, with region r(i) ∈ {5, 9} and name s_i:
       - if n_A(s_i) + n_B(s_i) > 0, then p_i = π_r f_A(s_i) / (π_r f_A(s_i) + (1 − π_r) f_B(s_i));
       - if n_A(s_i) = n_B(s_i) = 0 (unseen in both stocks), then p_i = π_r, because the names carry no information.
       - Non-SA-born recruits have p_i = 0.
     - **EM for π_r (separately for r = 5 and r = 9).** Let S_r be the SA-born recruits of region r whose names are seen in at least one stock (unseen names are excluded, since they do not inform π_r).
       - Start at π_r⁽⁰⁾ = 0.5.
       - Update π_r⁽ᵗ⁺¹⁾ = (1/|S_r|) Σ_{i∈S_r} p_i(π_r⁽ᵗ⁾).
       - Stop when |π_r⁽ᵗ⁺¹⁾ − π_r⁽ᵗ⁾| < 1e-8. Failure: no convergence within 1,000 iterations, a boundary (π_r < 1e-6 or > 1 − 1e-6), or |S_r| = 0.
       - A failure in the full sample means the score sensitivity is reported as "not computed" for all rows.
   - **Uncertainty (joint resampling).** A cluster pairs bootstrap, B = 4,999, seed 20261011 (L'Ecuyer-CMRG). Each draw resamples SAC year × month clusters with replacement, so the outcome, the regressors and stock B move together, and independently resamples SAF `family_id` clusters for stock A. Within each draw, the vocabularies, smoothing, π_r (by EM) and p_i are all recomputed before spec 4 is refitted.
   - **Failed draws.** A draw fails if the EM fails (as above) in either region, all p_i are identical within the SA-born, or the coefficient of interest is not identified (an aliased term in `lm`). Failed draws are discarded and their count is reported. Percentile 99% CIs use the successful draws. If more than 5% of draws fail, the score sensitivity is reported as "unstable" with the point estimate only and no interval. Failed draws are never replaced.
   - Agreement of all three classifiers with a recorded Dutch entry in `Languages`/`Other languages?` is reported as a weak diagnostic.
4. **Compatriot sample:** spec 4 on SA-born recruits only (RegionDum ∈ {5, 9}), under each classifier. HISCO groups and enlistment years with fewer than 10 recruits are merged (HISCO into "other"; a year into the nearest earlier year, or the next year for the first). A year-heterogeneity check adds D × 1{`EYear` = 1902} (S5 C9).
5. **Oaxaca–Blinder, labelled "decomposition of associations; discrimination not identified."**
   - Sample: the SA-born spec 4 sample, groups defined by each **deterministic** classifier (R_A, R_B). No fractional membership.
   - Method: the pooled two-fold decomposition with a group indicator (Jann 2008; Fortin 2008), plus the reference-group variants (English coefficients; Dutch coefficients).
   - Inference: joint inference on the raw gap R and on U − 0.5R (U = unexplained), by the cluster pairs bootstrap over year × month, B = 4,999. The ratio U/R is reported only as a descriptive figure, with the share of draws where R* ≤ 0.
   - The authors' grouping by `sa` in `Descriptives.xlsx` is re-run for comparison with fn 36.
6. **Prior residence:** a control for years in South Africa (`How long in South Africa?`; about 1,475 terms non-missing). This changes the population (A4d).
7. **Specification variants:** spec 3 (no year effects), and class dummies instead of HISCO major groups.
8. **I6 comparators:** England-born; European-born (England, Scotland, Wales, Ireland, Europe); enlistment-year fixed effects added.
9. **Heights (different estimands or descriptive only):**
   - (a) the corrected adult sample, 20 ≤ a ≤ 50, with a computed from dates (365.25-day years) or stated age, missing ages dropped explicitly, and single-year age fixed effects (35–50 pooled);
   - (b) stated age only;
   - (c) a ≥ 23;
   - (d) Dutch- vs English-surnamed SA-born heights under each classifier (p.591);
   - (e) **quantiles of the selected recruits' heights** by region at τ = 0.25, 0.5 and 0.75. These are descriptive of the recruit sample and are **not** truncation-corrected: lower truncation shifts quantile ranks even above the threshold;
   - (f) truncated-normal ML, run **only if a minimum-height standard is documented** in the paper, in the `original/` material (the 'SAC comparisons' truncation point counts only if a source is named), or in SAC regulations cited by works the paper cites. Otherwise it is reported as "not run (threshold undocumented)".
10. **Persons and missingness (Codex F2):** UK and England shares under the S3 `Unique`-run persons and under all service terms; the 8,887 vs 8,873 person count; missingness of height, wage and country by region. A4d: these do not decide I1.
11. **Diagnostic:** the published coefficients with the original conventional SEs.

## 6. Fixed choices
- No weights.
- Listwise deletion as in the published code; no imputation.
- Wages in shillings per day.
- HISCO, region, `Lwage` and `Afrikaans` exactly as in the `Augmented` sheet.
- No trimming.
- Seeds fixed. The scripts are `modern/01_build.R`, `02_inference.R`, `03_sensitivities.R` and `04_descriptives.R`, and they regenerate identically from a clean Rscript session.

## 7. Margins (A8 defaults, A3/A4 floors, no ceilings)
| Row | Claim type (A8) | Published / stated | Same interpretation if | Credible null (A4a) |
|---|---|---|---|---|
| I1-L | point, share | 0.831 | 0.801 ≤ share ≤ 0.861 (±0.03) | n/a |
| I1-T | threshold | > 0.5 | UK share > 0.5 | n/a |
| I3-L | point, level | 172.91; 175.03 cm | each within ±10% | n/a |
| I3a-C | comparative | SA > England | Δ > 0 and the 99% CI excludes 0 | n/a |
| I3a-M | magnitude | 2.12 cm | Δ ≥ 1.06, primary test rejects at 0.01 | not reachable (A4b) |
| I3b-C | comparative | SA > GB, cohorts 1860–85 | Δ > 0 and the 99% CI excludes 0 | n/a (no stated magnitude) |
| I4-LP | magnitude | −0.057 | b ≤ −0.0285 | not reachable (A4b) |
| I4-PCT | magnitude | 5.1% | 100(1 − e^b) ≥ 2.55 | not reachable (A4b) |
| I5-LP | magnitude | 0.078 | b ≥ 0.039 | not reachable (A4b) |
| I5-PCT | magnitude | 8.6% | 100(1 − e^−b) ≥ 4.3 | not reachable (A4b) |
| I6-L | point, level | 4.46 | 4.014 ≤ mean ≤ 4.906 (±10%) | n/a |
| I6-C | comparative | Boer < others | Δ < 0 and the 99% CI excludes 0 | n/a |

- **Plausibility flag (A8, non-deciding).** It is reported for any magnitude row whose estimate exceeds 1.5× the stated value: |b| > 0.0855 (I4-LP), > 7.65% (I4-PCT), > 0.117 (I5-LP), > 12.9% (I5-PCT), > 3.18 cm (I3a-M).
- **Stale percentages.** The published coefficients imply 5.52% and 7.48%, against the text's 5.1% and 8.6% (S5 C3). Both clear the 50% floors, so the stale numbers are reported as a transcription finding, not as a verdict issue.
- **I3-L width.** The ±10% band for the height levels is A8's default and carries no information about the comparison. The comparative rows carry that.

**Disclosure.** The following S5 numbers bear on the verdicts and were seen before this card was written:
- HC1 t for Afrikaans: −8.51, −3.86 and −3.69 (specs 2–4); England s4: 4.87.
- Sample, classifier and decomposition sensitivities:
  - S3-flag swap: −0.0252 (HC1 t −1.74); S3 rebuild: −0.0249 (HC1 t −2.08);
  - SA-born spec 4: −0.020 (HC1 t −1.27); the 1902 concentration;
  - Oaxaca by `sa`: 59% endowments.
- Heights: 2.12 cm (95% CI 1.34–2.90), 2.66, 2.98, 2.43 and 2.413 (Codex); SA-all minus GB 1.92 in the Table 1 sample.
- Counts made while drafting v1, with no outcome attached: 113 SA-born first terms with a `Languages` entry; 5,408 SAF persons; 93 year × month values in the full file.
- No clustered SE, no WCR p-value, no cohort-restricted height contrast and no score has been computed.
- v1 used classification and compatriot gates chosen after C8 and C9. v2 removes them, at Codex's request, so that no results-exposed choice decides a verdict.
- The month cluster dimension was chosen on institutional grounds before any clustered SE was seen.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
p₁ is the **designated primary** p-value: WCR for I4 and I5, HC2 for I3a, I3b and I6-C. It alone decides each verdict. The test level is 0.01 (Bonferroni, m = 5), and each CI is the 99% inversion of the primary test. The secondary p-value p₂ (HC3 for I4/I5; CR2 for I3/I6) is reported for every row. If p₂ falls on the other side of 0.01 from p₁, a "secondary disagreement" flag is printed beside the verdict and does not change it.

**I4-LP, I4-PCT, I5-LP, I5-PCT** (A4b inference-only ladder; overturned not reachable):

| # | Condition | Verdict |
|---|---|---|
| 0 | the published b or N is not reproduced, estimation fails, or the WCR fails twice (§4) | not-testable |
| 1 | WCR validity flag raised and p₁ ≥ 0.01 | not-testable (primary inference unreliable: few treated clusters) |
| 2 | p₁ ≥ 0.01, no flag | weakened |
| 3 | p₁ < 0.01, magnitude below the floor | qualified (magnitude) |
| 4 | p₁ < 0.01, magnitude at or above the floor | confirmed |

- If the flag is raised and p₁ < 0.01, rows 3–4 apply: the conservative WCR test still supports a rejection, and the flag is printed beside the verdict.
- Row 3 cannot occur when the published b reproduces, because the published magnitudes clear the floors; it is kept for exhaustiveness.
- A4b's "qualified (inference-fragile)" is not used: under the one-primary rule, fragility to other SE types is reported through the disagreement flag and §5.1–5.2.

**I3a-C, I3a-M, I6-C** (the published contrast is recomputed on the Table 1 sample; A4b ladder):

| # | Condition | Verdict |
|---|---|---|
| 0 | the Table 1 means are not reproduced to 2 dp, the test is undefined (§4), or Δ = 0 or has the sign opposite to the claim | not-testable (reproduction failure; refer to S4) |
| 1 | p₁ ≥ 0.01 | weakened |
| 2 | p₁ < 0.01, I3a-M only: Δ < 1.06 | qualified (magnitude) |
| 3 | p₁ < 0.01 (and, for I3a-M, Δ ≥ 1.06) | confirmed |

**I3b-C** (the p.592 claim on the 1860–1885 cohorts; a changed population with its own verdict; reversal reachable; no credible-null band, because no magnitude is stated):

| # | Condition | Verdict |
|---|---|---|
| 0 | the test is undefined (§4: fewer than 2 observations or zero variance in a group) | not-testable |
| 1 | Δ < 0, p₁ < 0.01 | overturned (reversed) |
| 2 | Δ ≤ 0, p₁ ≥ 0.01 | weakened (direction lost) |
| 3 | Δ > 0, p₁ ≥ 0.01 | weakened |
| 4 | Δ > 0, p₁ < 0.01 | confirmed |

- Δ = 0 falls in row 2, since an HC2 test of a zero difference cannot reject.
- v2's minimum of 30 recruits per group is removed. Group sizes are reported.

**Point rows I1-L, I3-L, I6-L** (descriptive):

| # | Condition | Verdict |
|---|---|---|
| 0 | the value cannot be computed | not-testable |
| 1 | within the A8 band (inclusive) | confirmed |
| 2 | outside the A8 band | qualified (level differs) |

For I3-L, both levels must be within the band for "confirmed".

**I1-T** (threshold):

| # | Condition | Verdict |
|---|---|---|
| 0 | the share cannot be computed | not-testable |
| 1 | UK share > 0.5 | confirmed |
| 2 | UK share ≤ 0.5 | overturned |

The England-born share > 0.5 is reported beside the verdict, as the literal "English" reading.

**I2:** not-testable in S6. **I4-D:** not-testable (discrimination is not identified by these data).

**Headline mapping.** Each composite takes the weakest member's verdict, ordered not-testable < overturned < weakened < qualified < confirmed. All members are reported.
- `tx_p585_uk`: the weaker of I1-L and I1-T.
- `T1_England_height` and `T1_SouthernAfrica_height`: the weakest of I3-L, I3a-C and I3a-M (Table 1 sample only).
- **p.592 cohort claim:** I3b-C is reported as its own verdict. It is never combined with the Table 1 headlines, and no changed-population result (I3b, §5) enters a Table 1 verdict.
- `T3_afrikaans_s4`: the weaker of I4-LP and I4-PCT. I4-D is reported beside it as not-testable.
- `T3_england_s4`: the weaker of I5-LP and I5-PCT.
- `T1_Boerrepublics_wage`: the weaker of I6-L and I6-C.
- `tx_p580_terms`: I2.

`Strengthened` is not used. The primary analyses change only the inference, and S6 excludes a merely smaller p-value from "strengthened".

## 9. Codex review notes and responses
Codex v1 review (`reviews/P08_SAC_codex_S6card.md`): **reject as drafted**, with 10 required changes and 2 optional ones. Responses:
1. **Primary upgrade.** The primary is now an inference-only upgrade on the published regressor, specification and sample (A4b) (§0, §4). The classifier alternatives are sensitivities (§5.3).
2. **Calibration not established.** The score is no longer primary and is labelled an unvalidated, different-estimand regressor, with the untested regression-calibration conditions stated (§5.3). The BISG claim is withdrawn.
3. **Score construction.** An explicit unseen-name rule (p = π_r), within-stock smoothing, EM convergence and boundary rules, and reference-stock uncertainty through a joint SAC-cluster and SAF-family bootstrap (§5.3).
4. **I4-OB identification.** Fractional membership is removed. The decomposition is a sensitivity on deterministic groups only, labelled "decomposition of associations; discrimination not identified". The discrimination reading is not-testable (I4-D) (§1, §5.5).
5. **Height estimands.** The Table 1 means are descriptive and are judged as published (I3-L, I3a). The adult, age-adjusted sample is a different estimand and non-verdict (§5.9a). The p.592 claim is matched to the 1860–1885 cohorts (I3b-C).
6. **I6.** The comparator is now Boer-republic-born minus all others, with the claim holding when Δ < 0 and the CI excludes 0. The 0.275 floor is removed. The 4.46 level is judged within ±10% (I6-L) (§1, §7).
7. **Asymmetric gates removed.** No classifier or sample gate remains. The I1 alternative person and term definitions are reported only (A4d) (§5.10, §8).
8. **Joint inference.**
   - Estimation-sample G, cluster sizes, imbalance, G*, maximum leverage and CR2 df are reported (§4).
   - Month clustering is justified, and place and two-way dependence are added as a sensitivity (§5.2).
   - The fixed-score fallbacks are removed. The score bootstrap resamples SAC clusters (outcome and f_B jointly) and SAF families (§5.3).
9. **Exhaustive, aligned decisions.**
   - Bonferroni (m = 5) for both tests and intervals, with CIs as inversions of the same test (§4).
   - The OB quantities are inferred jointly on R and U − 0.5R (§5.5).
   - Zero and equality cases are assigned (§8), and decisions use unrounded values.
   - A3/A4 floors and symmetric nulls are kept, with no ceilings, the 1.5× plausibility flag and the ±0.03 band for 83.1% (§7).
10. **Quantile sensitivity.** Relabelled as descriptive quantiles of selected recruits, not truncation-corrected. Truncated ML still requires a documented threshold (§5.9e–f).

Optional suggestions. (1) The F2 person-definition discrepancy and missingness by region are added (§5.10). (2) The U/R ratio is replaced by joint inference on R and U − 0.5R (§5.5).

Codex v2 compliance check (`reviews/P08_SAC_codex_S6card_v2.md`): **revise again**, with 5 blocking issues. Responses in v3:
1. **Secondary tests decided verdicts.** Only the designated primary (WCR for I4/I5; HC2 for I3/I6) now decides. HC3/CR2 disagreement is reported as a non-deciding flag (§4, §8).
2. **Headline mapping reconnected the estimands.** I3b-C has its own verdict. The Table 1 height headlines use only I3-L, I3a-C and I3a-M, and no changed-population result enters a Table 1 verdict (§1, §8).
3. **Undisclosed 30-recruit gate.** Removed. Only the estimator's mechanical requirement remains (at least 2 observations and non-zero variance per group) (§4, §8).
4. **WCR validity.**
   - The cross-month independence assumption is stated explicitly.
   - Validity diagnostics are specified: G₁ treated clusters, dominance of the largest treated cluster, and G*.
   - The flag cut-offs (G₁ < 10, > 50%, G* < 10) come from MacKinnon–Webb, not from S5.
   - A flagged non-rejection is not-testable. Failure handling: one reseeded retry, then not-testable, with no substitute decider (§4, §8).
5. **Score execution details.** The normalisation, the stock definitions, the within-stock smoothing formula with α = 0.5 and one reserved unseen type, the posterior, the unseen-name rule, the EM update over informative names, the convergence and boundary rules, and failed-draw handling (discard, report, more than 5% → "unstable") are fully specified. The score remains a non-deciding sensitivity (§5.3).

## 10. Known limitations at freeze
- **Cross-month dependence.** The primary assumes independence across enlistment months. Place and two-way clustering (§5.2) show sensitivity but cannot decide the verdict, so dependence that spans months could make the confirmed wage verdicts anti-conservative without changing them.
- **Validity-flag cut-offs.** The cut-offs (10 treated clusters, 50% dominance, G* 10) are round numbers informed by published simulations, not derived for this design. A flagged non-rejection yields not-testable, which is asymmetric by construction: a conservative test can support a rejection but not a non-rejection.
- **Primary design.** The primary leaves the authors' undocumented surname flag in place. The classification fragility (S5 C8) and the SA-born concentration (C9) appear only as reported sensitivities, so an A4b "confirmed" on I4 does not resolve them. The discrimination reading (I4-D) stays not-testable.
- **The surname score is unvalidated as a measure of language.** Its sole external check, the `Languages` field (about 113 SA-born entries), is weak. Its results are a different estimand.
- **Heights.** The height verdicts concern selected recruits. Truncation correction depends on a documented threshold that may not exist, in which case it is reported as not run.
- **Prior exposure.** S5 numbers (listed in the §7 Disclosure) were seen before every version of this card.
