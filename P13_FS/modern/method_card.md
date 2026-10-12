# Method card: P13_FS, private credit markets in the 18th-century Cape Colony

Status: v3 (2026-10-12). FINAL; to be frozen.
- History: v1 → Codex review (reviews/P13_FS_codex_S6card.md; approve-with-changes, 6 required changes) → v2 → Codex compliance check (reviews/P13_FS_codex_S6card_v2.md; freeze-after-minor-edits, 4 edits) → v3 (this draft; §9 maps each change). Frozen under A9.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a, using defaults only. The card author chose no band, margin or ceiling. The only author-set quantity is the computational failure cutoff for undefined bootstrap draws (§4A-B), which cannot confirm or overturn a verdict.
- To be FROZEN with the commit message "FREEZE S6 card P13" (A9). Issues not resolved are listed in §10.

Rights class: open (MOOC8) and personal (MOOC8 matched to SAF genealogies). Every script runs locally and reads data from D: (`dpath("P13_FS", ...)`). Codex sees this card, the code and aggregate output only.

## 0. Type of analysis and baseline
**No original code survives (S1, S2).** The reproduction baseline is therefore the S3 rebuild (`repro_r/`, independence `conditional`). The primary analyses depart from it only where S5 verified that the rebuild's design differs from the published one, or where the rebuild contradicts the paper's stated method. Each departure is tied to an audit finding in §2.

**Classification, per verdict row.**
- **H1-cons, H1-land** (Table 5 shares, **among purpose-recorded transactions, conditional on the paper's bond-to-land allocation**): (i) **correction** of the rebuild's verified classification error (S5-5, F2). The rows are classified by `purpose_debt`, which reproduces the published counts exactly, and the denominator is computed from the data. These are point descriptions with no inference.
- **H1-main** (land the largest purpose among purpose-recorded transactions, conditional on the bond allocation): (i) the same correction, plus (iii) **uncertainty propagation** through an inventory-cluster bootstrap of fixed land-minus-category contrasts (§4A-B).
- **H2-mag** (slaves coefficient): (i) **correction** of a verified departure from the stated method: the dependent variable includes inheritance debts, but the Table 6 note says it excludes them (S5-2, F4). The correction is applied on the authors' own stored estimation sample, together with an inference upgrade from conventional to HC3 SEs (S5-4, F5). The point estimate changes, so A3/A4 apply, including the symmetric credible null. A4b does not apply. The estimator is OLS on debtors, described as a **reconstruction** of the published "Tobit", not a proven identical estimand (S5-1 is disputed: Codex rules that the censoring command is not identified by agreement with the stored sample). Population: see §3 (H2-mag).
- **H3-ext** (wealth index): (iv) a three-variable index, which is a different regressor and a different sample. It is labelled `different-estimand` and cannot vote.

**A4c.** No headline row is an odds ratio or an OR stated as a probability. The Tobit and OLS coefficients are in log points.

**Runtime.** Every analysis is closed-form OLS, a Tobit or logit on fewer than 1,000 rows, or a bootstrap over about 4,000 inventories run on a precomputed inventory-by-category count matrix (49,999 draws for H1; 9,999 for wild cluster bootstraps). The whole card runs in well under 30 minutes. No lighter substitute was needed.

## 1. Claims family (frozen headline rows, A1 union) and interpretations
Four rows in `claims/claims.csv` have `headline = 1`: `T5_r9_full_pct`, `T5_r10_full_pct`, `T6A_slaves_nom_coef` and `T6B_wealth_nom_coef`. The authors' readings below are quoted from `claims/claims_spec.md` (b) and (c). Where one sentence carries a level and a comparison, or a magnitude and a causal reading, these are separate rows.

**H1, purpose of debt (Table 5, full sample).**

| Row | Source | Claim as the authors state it | A8 type | Margin |
|---|---|---|---|---|
| H1-cons | `T5_r9_full_pct` = 20.89 | "only 20 per cent of debt was incurred for consumption (or non-productive purposes)" (p.17), **assessed as a share of purpose-recorded transactions** | point share | [18.80, 22.98]: A8a, min(±3 pp, ±10% × 20.89 = ±2.089 pp); exact endpoints 18.801 and 22.979 |
| H1-land | `T5_r10_full_pct` = 25.78 | land is 25.78% of purpose-stated debt transactions (bonds allocated to land as in footnote 57), the basis of "the main reason for borrowing was long-term capital investment in land through bonds" | point share | [23.20, 28.36]: A8a, ±2.578 pp; exact endpoints 23.202 and 28.358 |
| H1-main | `T5_r10_full_pct` (the authors' reading) | "the main reason for borrowing was long-term capital investment in land", **among purpose-recorded transactions** | comparative ">" (universal: land > every other purpose category) | conjunction over the K = 21 fixed contrasts Δ_c = L − s_c: confirmed only if every simultaneous interval is entirely > 0 (A8 default, §4A-B) |
| H1-all | same sentences, read as all borrowing | that consumption is only 20% of **all** debt, and land the main reason for **all** borrowing | — | **not-testable**. Only 34.96% of debt-side rows state a purpose (F7). Missing purposes cannot be repaired by a bootstrap, and the unrecorded 65% are not assessed |
| H1-bond | same sentence, "through bonds" | that the land debts were contracted through bonds | — | **not-testable**. The purpose file records "Bond/Bonds" as an instrument coded Mixed in the source (S5-6). Whether a bond financed land is the paper's assertion (footnote 57), not a recorded variable. Every H1 verdict is therefore **conditional on the paper's allocation of the 647 bond rows to land** (sensitivity 2 shows the alternative) |

"Main reason" is read as the largest single category (a plurality). This is the A8 comparative default for "A > B" applied to every competitor. The majority reading (land > 50%) is reported in §5 (sensitivity 9) and does not vote. Codex F7 and audit interpretation (i) agree that the paper supports at most a plurality.

**H2, slave ownership (Table 6 Panel A, nominal).**
- **H2-mag** (`T6A_slaves_nom_coef` = 0.087***, t 5.852, N 570). "The number of slaves remains significant and positive"; the slave-holding coefficient is the evidence for "a particular driver … was slave ownership". This is a magnitude claim with b₀ = 0.087 log points per slave.
- **H2-causal.** "A particular driver of the Colony's extensive use of credit was slave ownership"; "settlers used their capital, in the form of slaves, to gain access to the credit market". **Not-testable.** There is no exogenous variation in slave holdings, and the conclusion itself says "the causal link … remains unclear".

**H3, wealth (Table 6 Panel B, nominal).**
- **H3-mag** (`T6B_wealth_nom_coef` = 0.0185***, SE 0.0039, N 251). "Those who benefited from the Colony's thriving credit market were rich, not poor"; "a one percentage point increase in wealth correlates with a 1.85 per cent increase in debt". **Not-testable.**
  - The published regressor is a percentile of a PCA over six variables. The surviving file has no sheep, cattle or horse variables (S5-8, F4).
  - The 251-row sample is not stored and cannot be reconstructed (decisions.md item 6).
  - Rebuilding the livestock counts from the 75 MOOC8 XML volumes and linking them to the inventories would be a new data construction, not a reanalysis (§10).
- **H3-pct** ("1.85 per cent per percentage point"). **Not-testable**, for the same reason. The unit misreading (log points, percentile) is recorded as S5-9 and is cosmetic.
- **H3-ext** (`different-estimand`, reported, never votes). The S3 rebuild's three-variable index (slaves, properties, cash), with HC3 inference (§4C).
- **H3-benefit** ("benefited", "rich, not poor", "not poverty"). **Not-testable** as a welfare statement. Debt levels do not measure benefits (F8). The extensive margin is reported in §5 (sensitivity 16, participation model) and does not vote.

**Stars.** *** 1%, ** 5%, * 10%; `stars05` = 2 (A7).

## 2. Defects addressed
S5 (Claude S5-1 to S5-10, Codex F1–F8, reconciled in `audit.md`) found these defects and fixes:
- **(a) Table 5 classification and denominator (S5-5, F2; changes-a-number).** The rebuild classified by `category_debt` on rows with a value, which is internally inconsistent (land includes bonds, but the production subtotal does not). Classifying by `purpose_debt`, and keeping purpose-coded rows without a value, reproduces the published counts exactly (923 consumption, 1,139 land). The published base of 4,418 cannot be recovered; the data give 4,122, with the gap in "Other production". **Fix:** the purpose mapping with the base computed from the data. A hard-coded 4,418 would reproduce the published shares mechanically and test nothing.
- **(b) Bond recoding (S5-6, F7; disputed).** 647 Bond/Bonds rows are coded Mixed in the source, and the paper moves them to Land. Codex rules that footnote 57 permits manual reclassification, so this is a sensitivity, not a correction. **Not fixed in the primary; sensitivity 2.**
- **(c) Dependent variable (S5-2, F4; changes-a-number).** The stored `ldebt` = log(`debt_value`) includes inheritance debts, but the Table 6 note says they are excluded "since these were not made for economic reasons". **Fix:** the dependent variable excludes them. The population consequence (inventories whose only debts are inheritance debts leave the debtor sample) is addressed in §3.
- **(d) Inference (S5-4, F5; disputed severity).** The paper says "robust standard errors" but prints t-statistics of unknown type. The rebuild exported conventional SEs. **Fix:** HC3 SEs (MacKinnon and White 1985; Long and Ervin 2000), the conventional leverage correction, preferred to HC1 when n ≈ 560 and k ≈ 30. Long and Ervin do not establish that HC3 dominates in this particular design, so the ladder of sensitivity 23 is reported. **Independence:** the primary follows the published design (no clustering; the paper states none). "One inventory per decedent" does not by itself imply independent errors (common decade shocks, shared households or lenders), so dependence is examined in sensitivity 24 and carried to §10; it does not vote.
- **(e) The "Tobit" has no censored rows (S5-1, F3; disputed status).** The authors' stored 570-row sample contains only debtors, so the published "Tobit" is OLS on debtors. **Not fixed in the primary**, because including zero-debt inventories changes the population, and under A4d it could not decide a verdict. The primary keeps the published population (debtors). A participation model (any economic debt) plus the positive-debt model is sensitivity 16. The primary is an OLS reconstruction on the stored sample restricted to positive economic debt. It is not claimed to be the published estimand: the printed censoring command is not identified (Codex), and the published "Tobit" may differ. Source: Wooldridge (2010, ch. 17) on censoring versus truncation.
- **(f) Wealth index (S5-8, F4).** Not fixable with the surviving data, so H3 is not-testable (§1).
- **(g) Bad controls (F8).** The bonds-present and borrower-and-lender dummies describe borrowing itself (Angrist and Pischke 2009, §3.2.3). Kept in the primary to preserve the published estimand; dropped in sensitivity 18.

## 3. Estimands
- **Table 5 universe U.** All rows of `PURPOSEDATA_20141117.dta` that are debt-side entries, i.e. `!is.na(value_debt) | !(purpose_debt %in% c(".", ""))` (the `r2` universe of `compare/s5_checks/s5_08_t5_mapping.R`). The universe does not depend on linkage to the analysis file (F1). The number of U rows whose `mooc` links to the 4,160 inventories is reported.
- **Frozen aggregation and missingness rules** (all asserted in `01_purpose.R` and `02_slaves.R`; the counts are reported, and a failed assertion makes that row not-testable).
  1. *Unmatched, missing, zero.* A U row is **unmatched** if its `mooc` is not in the inventory file (265 expected, F1); it stays in Table 5's universe. A matched row is **value-missing** if `value_debt` is NA. An inventory is **D-missing** if it has non-inheritance U rows and all of them have `value_debt` NA; it is excluded from S_A and counted, never treated as zero. An inventory has **genuine zero debt** if its non-missing non-inheritance values sum to 0; it is excluded from the log and counted. An inventory with no U rows has no debt and is outside the debtor population.
  2. *Unique joins.* `mooc` is asserted unique in `DATA20141122.dta` (non-missing `household_iden` rows) before any join, and the join is many-to-one from U.
  3. *Categories.* Each U row is asserted to match at most one of {`cons`, `land`, `prod` ∖ `land`, `mixd`}. Rows matching none are outside n_spec and are counted. The 21 competitors (below) and L must satisfy Σc n_c + n_land = n_spec exactly.
  4. *Debt totals.* For each inventory, D_noinh + Σ(inheritance-row values) is asserted equal to the sum of all valued U rows. The number of inventories where the stored `debt_value` differs from that sum is reported. D_noinh therefore changes only through the inheritance exclusion and the missing and zero rules above.
- **Category indicators** (executable, copied from s5_08):
  - `cons` = `purpose_debt` ∈ {Child Care, Clothing and Shoes, Food, Funeral Expenses, Household Expenditure, Medical Expenses, Wedding Expenses} or (`purpose_debt` = "Other" and `category_debt` = "Consumption").
  - `land` = `purpose_debt` ∈ {Land, Bond, Bonds} or (`purpose_debt` = "Buildings/Real Estate" and `category_debt` ≠ "General Purpose Given").
  - `prod` = `land` or `purpose_debt` ∈ {Agricultural Output, Cattle, Slaves, Wages, Working Capital} or (`purpose_debt` = "Other" and `category_debt` = "Production").
  - `mixd` = `purpose_debt` ∈ {Accounts, Auctions, Taxes, Wares, Donations, Inheritance} or (`purpose_debt` = "Other" and `category_debt` ∈ {Mixed, "."}).
  - `spec` = `cons | prod | mixd`; base n_spec = Σ spec.
- **C** = 100 × Σcons / n_spec (H1-cons). **L** = 100 × Σland / n_spec (H1-land).
- **Competitor categories for H1-main** are the non-land category rows at Table 5's level of detail, **fixed at K = 21** (asserted):
  - cons (7): Child Care, Clothing and Shoes, Food, Funeral Expenses, Household Expenditure, Medical Expenses, Wedding Expenses;
  - Other consumption (1);
  - production other than land (6): Agricultural Output, Cattle, Slaves, Wages, Working Capital, Other production;
  - mixd (7): Accounts, Auctions, Taxes, Wares, Donations, Inheritance, Other mixed.
  - For each competitor c, s_c = 100 × n_c / n_spec, and the **fixed contrast** is Δ_c = L − s_c. There is no maximum over c, so the statistic is smooth in the category counts and tied competitors raise no nondifferentiability problem. Because a row matching the `land` rule is never counted as a competitor, each transaction falls in exactly one category, and the 1,139 land rows include "Buildings/Real Estate".
  - The scope is **purpose-recorded transactions** (the n_spec rows, about 35% of debt-side rows) and the **paper's bond allocation** (bonds counted as land).
- **H2-mag.** β_slaves in the OLS regression, on sample S_A (§4B), of y = log(D_noinh) on the published regressors. **Population:** the paper says inheritance debts are excluded "since these were not made for economic reasons", so its stated target population is inventories with positive **economic** debt. Dropping inheritance-only debtors from S_A implements that stated target. It is not an A4d extension (no new group is added), and the dropped inventories are counted and listed in the results. The published-sample alternative (inheritance included, 570 rows) is sensitivity 13. Here D_noinh = Σ `value_debt` over the inventory's U rows with `purpose_debt` ≠ "Inheritance" and a non-missing `value_debt` (the definition of `s5_03_depvar.R`, joined by `mooc`). The published estimand is the printed Tobit coefficient. The stored sample contains only debtors (S5-1), but the printed censoring command is not identified, so the card does not claim that OLS on debtors is the same estimand. The primary is an OLS reconstruction on the stored sample restricted to positive economic debt, and its verdict is labelled accordingly.
- **H3-ext.** The wealth-percentile coefficient of `repro_r/02_analysis.R` (three-variable PCA). A different estimand.

## 4. Primary analyses (one per verdict row)
**A. H1-cons and H1-land (point rows; no inference).** Compute C and L on U as population descriptions of the transcribed records. Report n_spec, Σcons and Σland, and the published-base values (100 × count / 4,418) for reference.

**A-B. H1-main (inventory-cluster bootstrap of K = 21 fixed contrasts; simultaneous intervals).**
- **Resampling unit.** The inventory (`mooc`) in U. Each drawn inventory carries all its debt rows. B = 49,999, `set.seed(20261012)`. A draw is a multinomial resampling of inventories, applied to the precomputed inventory-by-category count matrix.
- **Per draw.** Recompute n_spec, L, every s_c and every Δ_c (a competitor absent from a draw has s_c = 0).
- **Error budget.** H1-main receives the Family F level, two-sided 0.025 (k = 2, §6), split equally across the K = 21 contrasts. Each contrast gets a percentile interval with 0.0125/21 = 0.0595% in each tail, i.e. the 0.0595% and 99.9405% quantiles (`quantile(type = 7)`) of the defined draws, about 30 draws per tail. This is Bonferroni over contrasts, so the intervals are simultaneous.
- **Failure rule (symmetric).** A draw is undefined if n_spec = 0. Undefined draws are discarded and the quantiles use the remaining draws (B_eff = B minus the undefined count). If more than floor(0.1 × 0.000595 × B) = 2 draws are undefined (an author-set computational threshold, one-tenth of the per-contrast tail mass, fixed before any bootstrap was run; it is not a verdict margin), H1-main is not-testable, whatever the direction of the estimate. The failure count is reported.
- **Primary cluster reporting.** Report the number of inventories resampled, and the distribution (min, quartiles, max) of debt rows and of purpose-recorded rows per inventory.
- **Decision inputs.** Per contrast: point Δ_c, lower bound and upper bound. The verdict (§8) uses only the lower bounds (all > 0) and the upper bounds (any < 0).
- **Reported, not deciding.** The argmax competitor in the full data, the smallest point Δ_c and its category, the number of contrasts with lower bound ≤ 0, and the v1 statistic Dmin = L − max_c s_c with its ordinary percentile CI (sensitivity 11).

**B. H2-mag.**
- **Data.** `DATA20141122.dta`, rows with non-missing `household_iden`. The sample is **S_A** = rows with `_est_tobit1 == 1` (the authors' stored Panel A sample, N 570) and D_noinh > 0. Inventories whose only debts are inheritance debts leave the debtor population, because the stated target is economic debt (§3). Their number and identity are reported, and so are the D-missing and zero-debt counts of §3 rule 1.
- **Regressors** (S5 best-matching published specification, `s5_09`): `age`, `male` (= `gender == "m"`), `married`, `children`, `farmer`, `num_slaves`, `num_prop`, `cash1`, `bond1`, `both`, `comp`, `church`, `wees`, and decade factor `dec` = floor(as.numeric(`year_string`)/10)·10. Aliased decade levels are dropped by `lm`. Listwise deletion within S_A.
- **Estimator.** OLS (`lm`), a reconstruction of the published "Tobit" (§0). The number of observations with y ≤ 0 (D_noinh ≤ 1 rds) is reported. They stay in the primary, and the Tobit with left = 0 is sensitivity 13.
- **Inference.** `sandwich::vcovHC(m, type = "HC3")`; t reference on n − k df.
  - p = two-sided unadjusted p.
  - (This is the H2-mag reconstruction, not an identical estimand; see §3.)
  - **Significance** = p < 0.025, the Bonferroni level for Family F, k = 2.
  - **Bonferroni CI** = b ± t₀.₉₈₇₅,ₙ₋ₖ · SE.
- **Failure rule (symmetric; no HC1 fallback).** If any observation has leverage hᵢᵢ = 1 (its residual variance is not identified, so HC3 is undefined), or the HC3 SE is non-finite or 0, or `lm` fails, H2-mag is **not-testable**. HC1, HC2 and conventional results are diagnostics (sensitivity 25) and never decide.
- **Reported:** N, the number dropped for D_noinh = 0, the maximum leverage, the decade cells with fewer than 5 observations, the actual cluster counts and sizes for the groupings of sensitivity 24 (decade; `household_iden`), and the conventional, HC1 and HC3 t-statistics.

**C. H3-ext (different-estimand; reported, never votes).** `repro_r/02_analysis.R` Panel B nominal, exactly as locked (three-variable PCA percentile, N 565), with HC3 in place of conventional SEs, plus the same regression on S_A (sensitivity 22).

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
**Table 5 (H1):**
1. The published base: 100 × counts / 4,418. It reproduces 20.89 and 25.78 by construction and is diagnostic only.
2. Bonds left in their source category (Mixed): L, C and all Δ_c recomputed (S5-6; disputed; footnote 57).
3. Rows with a value only (`!is.na(value_debt)`; the `r1` universe of s5_08).
4. The S3 rebuild mapping as locked (`category_debt`, rows with a value). Reconstruction diagnostic.
5. Value-weighted shares: Σ`value_debt` by category / Σ`value_debt` over spec rows (the "of debt" reading of p.17). Different-estimand.
6. Base = all debt-side rows in U, not only purpose-stated ones. Different-estimand (the H1-all reading, still unassessed as a claim).
7. Matched and unmatched columns separately. Changed population (A4d).
8. "Other" residual rows dropped from the base and from the competitors.
9. The majority reading of H1-main: the percentile CI of L − 50 at the H1-main level (0.0125 per tail).
10. Production total versus consumption total: the bootstrap CI of 100·(Σprod − Σcons)/n_spec.
11. The v1 statistic Dmin = L − max_c s_c with an ordinary percentile bootstrap at 1.25% tails. Diagnostic only: it is not smooth at tied competitors (Fang and Santos 2019).
12. Dependence: the H1 bootstrap resampling `household_iden` clusters instead of inventories (if the purpose universe links to it), and decade-block resampling. Cluster counts and sizes reported.

**Table 6 Panel A (H2):**

13. The published dependent variable `ldebt` (inheritance included, hence inheritance-only debtors kept) on S_A's parent sample `_est_tobit1 == 1` (N 570; the S5 best match). The population alternative to §3.
14. Covariate versions `bond` in place of `bond1`, and decades from `year` in place of `year_string`.
15. `AER::tobit(left = 0)` on the primary sample and specification, with conventional SEs. Reconstruction diagnostic, not corrective evidence: the censoring point depends on the currency unit (S5 F3).
16. **Participation plus positive-debt decomposition (replaces v1's "true Tobit").** Matched inventories with complete covariates, zero-debt inventories included. (a) Participation: logit and LPM of 1[D_noinh > 0] on the same regressors, reported as odds ratio and average marginal effect (A4c). (b) Positive-debt: the primary OLS. No censoring at log 0 is imposed, and nothing is coded as zero beside log values. Different-estimand and changed population (A4d); reported separately from the primary and never voting.
17. Real column: `_est_tobitin == 1`, `ldebtin`, with and without the inheritance exclusion (deflated by the ratio `debt_infl`/`debt_value`). Non-headline.
18. `children` dropped (label doubt, S5-7), on S_A.
19. Functional form: log(1 + slaves), and the Table 2 slave groups (0, 1–5, 6–10, 11–24, ≥25) as dummies.
20. Bad controls dropped: without `bond1` and `both` (F8).
21. The S3 rebuild Panel A as locked (Tobit with zeros, N 736, `bond`, `year` decades). Reconstruction diagnostic.
22. Influence: leave-one-decade-out; observations with `num_slaves` ≥ the 99th percentile of S_A (`quantile(type = 7)`; all ties at the cutoff dropped) removed; the maximum DFBETA for `num_slaves` reported.
23. Inference ladder on the primary point estimate: conventional, HC1, HC2, HC3, and a wild bootstrap (Rademacher, null imposed, B = 9,999, seed 20261012).
24. **Dependence.** Actual cluster counts and sizes are reported for (i) decade of death and (ii) `household_iden` (if it identifies shared households or estates). With few clusters (G < 30), CR2 with Satterthwaite df (clubSandwich) and the wild cluster bootstrap with Webb weights (fwildclusterboot, B = 9,999) are reported (Cameron and Miller 2015). The primary stays HC3 because the published design states no clustering. A substantial discrepancy is carried to §10 and the synthesis but does not change the verdict.
25. Leverage and fallback diagnostics: HC1 and HC2 results, and the list of observations with hᵢᵢ > 0.5.

**Table 6 Panel B (H3):**

26. The three-variable index percentile, with H2's controls minus the index components, on S_A with y = log(D_noinh). Different-estimand.

## 6. Fixed choices
- **Weights:** none (the paper states none). **Clustering:** none in the Table 6 primary (§2d; dependence sensitivities 12 and 24). The Table 5 bootstrap clusters by inventory.
- **Missing data:** listwise deletion within S_A (as published). Table 5 uses universe U as defined in §3.
- **Multiplicity family F = {H1-main, H2-mag}**, the two inferential verdict rows. Bonferroni with k = 2, two-sided level 0.025 per row; for H1-main it is split again across the 21 contrasts (§4A-B). Holm is not used, because H1-main has percentile intervals and no p-value. H1-cons and H1-land are point rows with no inference. H1-all, H1-bond, H2-causal, H3-mag, H3-pct and H3-benefit are not-testable. H3-ext is unadjusted and descriptive.
- **Boundary rules.**
  - p = 0.025 is not significant.
  - |b| = 0.5|b₀| = 0.0435 meets the floor.
  - Band endpoints (exact values in §1) are inside the band.
  - A contrast bound at exactly 0 is neither > 0 nor < 0. b = 0 or a CI endpoint at exactly 0 counts as "CI includes 0".
- **Seeds:** 20261012. **Scripts:** `modern/01_purpose.R`, `02_slaves.R`, `03_sensitivities.R`, `04_verdicts.R`. Results go to `modern/results.md` and `modern/verdicts.csv`.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1-cons | 18.801 ≤ C ≤ 22.979 | A8a default (stated value 20.89) |
| H1-land | 23.202 ≤ L ≤ 28.358 | A8a default (stated value 25.78) |
| H1-main | every one of the 21 simultaneous intervals for Δ_c = L − s_c entirely > 0 | A8 comparative default (">" needs A − B > 0 with the CI excluding 0), as a conjunction over competitors |
| H2-mag | same sign, p < 0.025, \|b\| ≥ 0.0435; credible null if the Bonferroni CI ⊂ (−0.0435, 0.0435) | A3, A4a |

- **No ceilings.** **Plausibility flags** (reported; never decide a verdict): b > 1.5 × 0.087 = 0.1305; C or L above 1.5 × the stated value.
- The verdict uses the stated table value (20.89, 25.78), not the rounded words ("20 per cent"). This follows A8 (point claim X = the authors' headline number), as in P10 H1-25s.

**Disclosure.** S2, S4 and S5 numbers seen before this card, all bearing on the verdicts:
- **Table 5.** Counts under the purpose mapping: consumption 923, land 1,139 (bonds 647), inheritance 238; base n_spec = 4,122 (published 4,418; the gap is in "Other production", 84 in the data against 387 printed). **C = 22.39 and L = 27.63 on the primary universe**; 20.89 and 25.78 on the published base. S3 rebuild: 22.16 and 23.35. Bonds left in Mixed: L = 11.14%, with land (492) still above other production (387 printed) and funeral expenses (383). On these values the primary H1-cons and H1-land point estimates lie inside their default A8a bands. The bands are protocol defaults and were not chosen by the card author, but the universe U was fixed after these values were seen. Its documentary anchor is that the purpose mapping reproduces the **printed counts** (923, 1,139, 238) exactly, not the shares (§9, response 6; §10).
- **Table 6 Panel A, slaves (nominal).**
  - S3 rebuild (true Tobit, N 736, 171 censored): 0.0454 (t 2.55).
  - Stored 570 sample: with `bond`/`year`, 0.0769; with `bond1`/`year_string`, 0.0826 (conventional t 8.65, OLS-HC1 t 7.12).
  - Dependent variable excluding inheritance, `bond`/`year`: 0.0712 (N 564).
  - True Tobit with zeros, `bond1`/`year_string`: 0.0662 (t 3.56).
  - The primary combination (inheritance excluded, `bond1`/`year_string`, HC3) has not been run.
- **Table 6 Panel A, other rows.**
  - Real: stored 178 sample 0.0778 (t 5.35); S3 rebuild real −0.0107 (SE 0.0363).
  - Bonds: 1.050 (t 3.63) on the stored sample; 0.430 (t 0.74) in the true Tobit.
  - Farmer: 0.26 (nominal), −0.26 (real).
- **Panel B.** S3 rebuild wealth 0.0253 (N 565; HC1 t ≈ 9.45 nominal, 5.45 real); exp(0.0185) − 1 = 1.87%.

No bootstrap has been run (neither the v1 Dmin nor the v2 contrasts), nor any participation model, CR2 or cluster estimate, or HC3 estimate. S5 did not examine `household_iden` clusters.

## 8. Verdict tables (central analysis only; checked in order; the first rule that applies decides; exhaustive)
**H1-cons** (A8a band alone; X = C, band [18.801, 22.979]). **H1-land** uses the same table with X = L and band [23.202, 28.358].
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails, or n_spec = 0 | not-testable |
| 1 | X inside the band | confirmed |
| 2 | X below the band | qualified (share below the stated value) |
| 3 | X above the band | qualified (share above the stated value) |

For these point rows "overturned" and "strengthened" are unreachable: A8 point claims carry no inferential direction.

**H1-main** (comparative, conjunction over K = 21 contrasts Δ_c = L − s_c; simultaneous percentile intervals with 0.0125/21 per tail; Family F). Scope: purpose-recorded transactions, bond allocation as in the paper.
| # | Condition | Verdict |
|---|---|---|
| 0 | bootstrap fails, an assertion of §3 fails, K ≠ 21, or more than 2 undefined draws of 49,999 | not-testable |
| 1 | at least one contrast has upper bound < 0 | overturned (another purpose is larger than land) |
| 2 | every contrast has lower bound > 0 | confirmed (land the largest purpose, among purpose-recorded transactions) |
| 3 | otherwise (no contrast has upper < 0, and at least one has lower ≤ 0) | weakened (plurality not established) |

Rules 1 and 2 cannot hold together (a contrast with lower > 0 has upper > 0, and the rules refer to the same set of intervals), and rule 3 covers every remaining case, so the table is exhaustive and exclusive. "Qualified" is unreachable for this row.

**H2-mag** (A3/A4; Family F; all inputs from §4B, HC3 only):
| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails, any hᵢᵢ = 1, or the HC3 SE is non-finite or 0 (no fallback) | not-testable |
| 1 | b < 0 and p < 0.025 | overturned (reversed) |
| 2 | Bonferroni CI ⊂ (−0.0435, 0.0435) | overturned (credible null) |
| 3 | b > 0, p < 0.025, b ≥ 0.0435 | confirmed |
| 4 | b > 0, p < 0.025, b < 0.0435 | qualified (magnitude below the floor) |
| 5 | b > 0, p ≥ 0.025 | weakened |
| 6 | b ≤ 0, p ≥ 0.025 | weakened (direction lost) |

Rules 1–6 cover every finite (b, p, CI): rows 1–4 cover p < 0.025 by the sign and size of b (rule 2 can apply only to b < 0.0435), and rows 5–6 cover p ≥ 0.025. "Strengthened" is not used: the primary corrects the dependent variable on the authors' own sample and upgrades the SEs, but it does not make the design for the same estimand more credible.

**H1-all, H1-bond, H2-causal, H3-mag, H3-pct, H3-benefit:** not-testable (§1). **H3-ext:** different-estimand (coefficient, HC3 SE and CI reported).

**Summaries and coverage.** Report coverage from the runtime outcomes: the number of rows assessed (of H1-cons, H1-land, H1-main, H2-mag, minus any that return not-testable by rule 0), the actual number not-testable (6 by design plus any runtime rule-0 rows), and different-estimand (1). Report the weakest verdict among the assessed rows only (overturned < weakened < qualified < confirmed), excluding not-testable rows; if no row is assessed, report "no assessed rows" and no weakest verdict. Report every row-level verdict. The synthesis must report that one of the four headline cells (`T6B_wealth_nom_coef`), the all-borrowing reading of the Table 5 sentences (H1-all) and the causal, bond and benefit readings could not be assessed, and that every H1 verdict is restricted to purpose-recorded transactions and conditional on the paper's bond-to-land allocation.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P13_FS_codex_S6card.md): approve-with-changes, 6 required changes, all addressed in v2. Codex confirmed that the A8a bands, the A3 floor of 0.0435 and the A4 symmetric null are correctly computed, that no results-informed margin or ceiling is apparent, and that H3's non-voting extension is appropriate.
1. **H1 scope (purpose-recorded transactions; bond allocation).** §1 restricts H1-cons, H1-land and H1-main to purpose-recorded transactions (about 35% of debt-side rows) and makes every H1 verdict conditional on the paper's footnote-57 bond allocation. New row **H1-all** (the all-borrowing reading) is not-testable. §3 states the scope, §8 repeats it in the coverage report, and the synthesis must carry it. Sensitivities 2 and 6 show the alternatives.
2. **H2 population and estimand.** §3 states that excluding inheritance-only debtors implements the paper's own stated target (economic debt), is not an A4d extension, and is counted and listed. The published-sample alternative is sensitivity 13. §0 and §4B describe OLS on debtors as a **reconstruction** of the printed "Tobit", with the censoring command unidentified (S5-1 disputed).
3. **H1-main intervals.** The ordinary percentile bootstrap of Dmin = L − max_c s_c is replaced by simultaneous intervals for the 21 fixed contrasts L − s_c, with the error budget split across contrasts (Bonferroni; B raised to 49,999 so each tail holds about 30 draws). Rules: confirmed if every lower bound > 0, overturned if any upper bound < 0, weakened otherwise, with a failure rule. The v1 Dmin is sensitivity 11, diagnostic only. This remains one primary analysis.
4. **Independence and HC1 fallback.** §2(d) no longer relies on "one inventory per decedent". The primary stays HC3 for fidelity to the published design (no clustering), and sensitivities 12 and 24 report actual cluster counts and sizes (decade; `household_iden`), CR2/Satterthwaite and the wild cluster bootstrap for few clusters. They cannot vote (§10, limitation 7). The automatic HC1 fallback is deleted: leverage one or a non-finite HC3 SE makes H2-mag not-testable, and HC1 is a diagnostic (sensitivity 25).
5. **Sensitivity 14.** The "true Tobit with zeros" is replaced by a participation model (logit and LPM) plus the positive-debt model (the primary), separately labelled, different-estimand and non-voting (sensitivity 16). Sensitivities 15 and 21 (Tobit reconstructions) are labelled diagnostics, not corrective evidence, because censoring at log 0 depends on the currency unit (F3).
6. **Missingness, aggregation, documentary justification.** §3 freezes the unmatched / value-missing / D-missing / genuine-zero rules, unique-join assertions, mutually exclusive categories, complete competitor enumeration (K = 21; Σ competitors + land = n_spec) and the debt-total reconciliation. A failed assertion makes the row not-testable. The documentary evidence for the results-exposed choices: universe U and the purpose mapping are anchored on the **printed counts** (923, 1,139, 238) that the mapping reproduces exactly, and the covariates `bond1` and `year_string` on the published Panel A coefficients, not on any verdict quantity. Both remain results-exposed and are listed in §10. One primary per claim is preserved.

**Optional suggestions.** (1) B raised to 49,999 for H1; the trimming rule and ties are frozen (sensitivity 22: `quantile(type = 7)`, all ties at the cutoff dropped). (2) §10 arithmetic corrected (296 versus 303). Under A9, v2 implements the changes and the compliance check follows on v3.

## 10. Known limitations at freeze
1. **Universe and specification chosen after seeing results.** The purpose mapping and universe U come from S5 (s5_08), which had already produced C = 22.39 and L = 27.63, both inside the default bands. `bond1` and `year_string` were chosen in S5 because they come closest to the published coefficients. The bands are A8a defaults, and the documentary anchor is the printed counts and coefficients (§9, response 6), but the choices were informed by results. Sensitivities 1, 3, 4 and 14 show the alternatives.
2. **Unrecovered base.** The published base is 4,418 and the data give 4,122, a gap of 296. The printed "Other production" is 387 against 84 in the data, a difference of 303, partly offset by 7 elsewhere. If the missing rows were real purpose-stated debts absent from the surviving file, C and L are overstated by about 7%.
3. **Scope and bond allocation of H1.** Verdicts cover purpose-recorded transactions only (about 35%) and follow the paper's allocation of bonds to land. "Land through bonds" (H1-bond) and the all-borrowing reading (H1-all) cannot be tested, and L falls to 11% if the bonds stay in Mixed (sensitivity 2). A bootstrap cannot repair missing purposes.
4. **Reconstruction, not identity.** OLS on debtors reconstructs the published "Tobit" (S5-1 disputed). The inheritance exclusion rests on the table note's wording (Codex rates S5-2 "uncertain" for the printed table), and the inheritance-only debtors who leave S_A are a consequence of that reading.
5. **HC3 is not shown to dominate.** Long and Ervin (2000) do not establish HC3's superiority in this design. If a leverage-one observation occurs (for example a decade cell with one observation), H2-mag is not-testable by pre-specified rule and is not rescued by HC1. The maximum leverage has not yet been seen.
6. **Debtors-only population.** The primary keeps the stored debtors-only sample, restricted to positive economic debt; it is an OLS reconstruction whose identity with the published Tobit is not established. The participation model, the natural test of "rich, not poor", is a changed population under A4d and cannot vote (sensitivity 16).
7. **Dependence not resolved by the primary.** The primary assumes independent errors, as in the published design. Decade shocks, shared households or lenders may violate that. Sensitivities 12 and 24 report it, with CR2 and the wild cluster bootstrap, but with few clusters (decades) any cluster inference is approximate, and a discrepancy does not alter the verdict. The synthesis reports it.
8. **H1-main intervals are conservative.** Bonferroni over 21 contrasts with percentile (not studentized) intervals can give "weakened" when the plurality is real but the margin over a near competitor (funeral expenses, other production) is narrow.
9. **H3 not-testable.** The wealth-index headline cannot be assessed without livestock counts. Extracting them from the MOOC8 XML volumes and linking them to inventories would be a new data construction outside the wave-3 scope. The three-variable index (H3-ext) answers a different question.
10. **Causal readings** (H2-causal, H3-benefit) remain not-testable. The card therefore cannot assess the abstract's "driver" and "benefited" language.
11. **Point rows without inference.** H1-cons and H1-land are judged as descriptions of the transcribed records, and their sampling uncertainty is not part of the verdict.
12. **Bad controls kept.** `bond1` and `both` describe borrowing itself and are kept in the primary to preserve the published estimand (sensitivity 20).
