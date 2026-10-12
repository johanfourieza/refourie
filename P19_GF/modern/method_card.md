# Method card: P19_GF, public sector growth in the British Cape Colony, 1830–1910

Status: v3 (2026-10-12), frozen under A9.
- History: v1 → Codex review (reviews/P19_GF_codex_S6card.md; 7 required changes) → v2 → Codex compliance check (reviews/P19_GF_codex_S6card_v2.md; freeze-after-minor-edits, 5 edits) → v3. No further review (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. The card author chose none of them.

## 0. Type of analysis
The primary analysis is **one corrected central analysis** of type **(i), a correction**. No original code or calculation workbook survives (S1, S2), so the reproduction baseline is the S3 rebuild (`repro_r/`, independence `conditional`). S5 found that the rebuild's two headline share calculations measure a different quantity from the one the paper states. The central analysis corrects this in two ways:

- **C1, public-works aggregate for the railway claim (S5-1, Codex F1).** The rebuild divides railways by the full Table 1 public-works class. The paper's own referent for the abstract claim is Fig A2, "Public works composition" (p.367; cited at p.352, "Fig. A2 in the appendix shows the shares of the expenditure categories"). Its legend has five components. The central denominator is that five-component aggregate.
- **C2, denominator and reading of the public works + debt claim (S5-2, Codex F2).** The rebuild divides by the workbook's `Total Expenditure` and summarises 1870–1909 by a period mean. The paper defines GE explicitly (p.349): "Total government expenditure (GE) is taken to be a summation of all categories", meaning the six Table 1 classes. The central denominator is the sum of the six classes as reconstructed from the workbook. "More than 70% from the 1870s onwards" is a bound on every year (A8 threshold rule), not on a mean.

The analysis is not (ii), an inference-only upgrade, not (iii), uncertainty propagation, and not (iv), a new estimator. The series are complete administrative accounts and not a sample, so there is no sampling distribution. A3 clause 2 (95% CI excludes 0) and the A4a credible-null rule have no object here. The paper makes no odds-ratio or probability claims, so A4c does not apply. Verdicts are deterministic functions of the corrected annual series and the unknown-value bounds (§4, §8). Changed estimands and changed populations (§5B) are reported and never vote (A4d).

Runtime: a few seconds. There is no random draw. The seed is still fixed (`set.seed(19)`) for convention.

## 1. Claims family (headline rows, frozen at S0, union under A1) and interpretations
All five headline rows are descriptive. Margins are the A8/A8a defaults for the type of wording.

- **H1** (`TX_abs_rail70`), a threshold claim over a period.
  - The claim (abstract, p.341): "Owing to strong mining interests, railways accounted for more than 70% of the public works expenditure from the 1880s onwards."
  - The authors' reading: railways, the mining sector's main infrastructure, crowded out roads, harbours and anchorages (p.352).
  - Quantity: the annual share s_t = 100·rail_t / PW^A2_t, where PW^A2 is the Fig A2 aggregate (§3).
  - "From the 1880s onwards" is read as every year in W1 = 1880–1909, the last data year. The paper gives no qualifier such as "typically", so A8 treats the claim as universal.
  - Margin: s_t > 70 for every t in W1.
  - **Scope of a verdict.** A confirmation concerns the five Fig A2 components only (§3). The frozen claims specification also names total public works and Table 1; those readings are the changed estimand in §5B-1. They do not vote.
- **H1-c**, the causal clause "owing to strong mining interests": **not-testable**. The data hold no variation or counterfactual that identifies a cause (Codex F7; interpretation audit reason 4). No H1 verdict speaks to mining influence or crowding out.
- **H2** (`TX_p351_pwdebt70`), a threshold claim over a period.
  - The claim (p.351): "From the 1870s onwards, though, public works and debt servicing account for more than 70% of government expenditure."
  - Quantity: the annual share s_t = 100·(PW^T1_t + DEBT_t) / GE_t, where PW^T1 is the Table 1 public-works class and GE is the sum of the six Table 1 classes (§3).
  - Window W2 = 1870–1909. The claim is universal.
  - Margin: s_t > 70 for every t in W2.
  - **Scope of a verdict.** GE is the paper's stated concept, but the workbook reconstruction omits Table 1 components (§4, §5C-5, §10). A verdict concerns the reconstructed GE.
- **H3** (`T2_r5_c1`), a point claim: total per capita expenditure in 1853 is £2.15 at constant 1861 prices. **Not-testable** (§3).
- **H4** (`T2_r5_c5`), a point claim: total per capita expenditure in 1904 is £6.81 at constant 1861 prices. **Not-testable**.
- **H5** (`T2_r4_c5`), a point claim: per capita public works expenditure in 1904 is £4.46 at constant 1861 prices. **Not-testable**.
  - The authors read H3–H5 as an "austere" pre-mineral state whose per capita spending about trebled, with "the public works ... the biggest of all categories" (p.352).
  - The inputs these claims need, Blue Book population and the De Zwart (2011) price index, were not recovered (S1, S3 decisions.md, S5-3).
  - **A8 bands, stated now for any future amendment if the inputs are recovered** (none is used in this card; A8a does not alter pound-valued levels): H3 [1.935, 2.365], H4 [6.129, 7.491], H5 [4.014, 4.906], each ±10% of the printed value.

**Scope.** These are shares of nominal Blue Book expenditure as transcribed in the May 2019 workbook. Shares do not depend on any deflator or population denominator. Nothing here tests "rapidly accelerated", "led to the growth of the public sector", "crowded out" or "farmers consistently lost". Those claims are causal or qualitative, and the S5 interpretation audit handles them.

## 2. Defects addressed
- **Unstated and inconsistent denominators.** The two ">70%" claims have unstated denominators, and the rebuild's choices do not match the paper's own definitions (S5-1/F1, S5-2/F2). Corrected in C1 and C2.
- **Bound claims summarised by period means.** The rebuild summarised bound claims by period means (F2). The central analysis evaluates every year, and means are descriptive only.
- **Unsupported zero imputation (F4b).** The rebuild turns every missing line item into 0 (`rowSums(..., na.rm = TRUE)`). A blank cell does not establish zero expenditure. The central analysis keeps unknowns and bounds them (§4).
- **Documented but not correctable with these data:**
  - In 1872–1876 the railway line exceeds `Total Expenditure` (1875: 1.94x), probably loan-financed capital (S5-4/F4a). The reconciliation gap is reported (§5C) and does not enter the central denominators, which are sums of line items.
  - Several Table 1 components are absent from the workbook (§4, §5C-5).
- **Not testable:** the Table 2 levels (S5-3/F3).

Sources:
- Peacock and Wiseman (1961), on the functional classification the paper uses;
- Feinstein and Thomas (2002, *Making History Count*), ch. 2–3, on descriptive measures of historical series and the effect of denominators on shares;
- Horowitz and Manski (2006, *Journal of Econometrics*), on bounds under missing data;
- A8 (threshold rule; "every" for universal claims) in AMENDMENTS.md.

## 3. Estimands
**Line items** come from the `Expenditure` sheet of `Abel Gwaindepi CC fiscal records.xlsx`, read with the column cleaning of `repro_r/01_clean.R`, via `dpath("P19_GF", "original", "colonial govt fiscal", ...)`.

- **H1.**
  - rail_t = `Total Railways`.
  - PW^A2_t = `Total Railways` + `Roads & Bridges` + `Works & Buildings` + `Ports and Harbours` + `Telegraph`. These are the five Fig A2 legend components (S0 page-image check; S5-1).
  - Why Fig A2 controls the interpretation: it is the only public-works aggregate the paper shows next to its railway discussion (p.352 cites it for the shares of the expenditure categories), and the abstract claim is about railways within public works. Table 1 has no railway-share statement. This reading is a judgement about the paper's referent. It was made with the S5 numbers in view (§8, disclosure), and the opposite reading is reported in §5B-1.
  - The original estimand is the Fig A2 railway share. The new estimand is the same quantity, computed annually.
- **H2.**
  - PW^T1_t = rail_t + the `pwo` columns of `repro_r/01_clean.R`: Roads & Bridges, Works & Buildings, Conveyance of mails, Telegraph, Post Office, Ports and Harbours, Customs, Mines, Surveyor General, Commissioner for public works.
  - DEBT_t = `National Debt Servicing`.
  - GE_t = hr + adm + mil + law + debt + pw, using the rebuild's Table 1 mapping unchanged (the `classified` column of `repro_r/output/expenditure_classes.csv`).
  - The original estimand is the paper's GE share (p.349 equation, p.351 text). The new estimand is the same, computed annually on the reconstructed GE.
- **H3–H5.** Per capita real expenditure. This needs population and a deflator, which are absent, so there is no new estimand. The H5 composition analogue (§5D S-a) is a different estimand and never votes.

The §5B variants change the denominator definition, the window, the population of years or the summary statistic. These are changed estimands and are labelled as such.

## 4. Primary analysis: the central analysis
- **Script.** `modern/01_primary.R`, self-contained, sourcing `tools/paths.R`. It writes `modern/output/annual_shares.csv`, `modern/output/verdicts.csv`, `modern/output/sensitivities.csv`, `modern/output/missingness_items.csv` and `modern/output/coverage_map.csv`.
- **`annual_shares.csv`** has one row per year and claim: every numerator and denominator component (with NA kept as NA), the point share s⁰_t (unknowns set to 0, the rebuild's convention, descriptive only), the bounds s_lo,t and s_hi,t, the distance s − 70 at each, and the year's state.

**Unknowns are kept, not imputed (Codex 3).**
- A cell that is NA is an *unknown*: it may be a structural zero (no vote that year) or an untranscribed value. The data do not show which. The central analysis therefore does not impute 0.
- Admissible values for an unknown component are [0, M_c], where M_c is the largest observed value of that column in the whole `Expenditure` sheet, all years. M_c is a data-derived cap and not a choice about any year. It is the widest bound the data themselves support: no unknown is assumed to exceed anything the column ever recorded. The card author chose this cap with the S5 numbers in view (§8, disclosure) and did not compute any bound before choosing it.
- s_t = 100·(N_k + U_N)/(D_k + U_N + U_O), where N_k and D_k are the known parts of numerator and denominator, U_N the unknowns in the numerator (they are also in the denominator) and U_O the unknowns in the denominator only. s_t is increasing in U_N and decreasing in U_O. The bounds are therefore the two corners:
  - s_lo,t: U_N = 0 and every denominator-only unknown at M_c;
  - s_hi,t: every numerator unknown at M_c and U_O = 0.
- If no component is unknown in year t, s_lo,t = s_hi,t = s_t.
- **Assumption.** The bound [0, M_c] is an assumption, not an observation. Expenditure is taken to be non-negative, and no unknown exceeds the largest value its column ever takes in the sheet. The monotonicity of s_t above needs non-negative inputs, and the script asserts that every observed component is ≥ 0. A component with a negative observed value makes its years indeterminate and is listed. Every verdict is conditional on this assumption (§10.2).
- **Cap failures.** If a column is wholly unobserved, or M_c is NA or non-finite, the column has no cap. Every year in which that column is unknown and enters the claim is indeterminate.
- The year is **undefined** if the sheet has no row for the year, or the known denominator is NA or non-finite, or the denominator is ≤ 0 under either corner. An undefined year is indeterminate and is never dropped.

**Year states (every year in the window gets exactly one).**
- **above:** s_lo,t > 70 (the claim holds under every admissible fill).
- **counterexample:** s_hi,t ≤ 70 (the claim fails under every admissible fill).
- **indeterminate:** neither, or the year is undefined.
- Let A, C and I be the counts of the three states, with A + C + I = |W|. There is no tolerance on the number of indeterminate years.

**Checks before any verdict (`stopifnot`).**
1. Year keys are unique (a duplicate stops the run). Window years absent from the sheet do not stop the run: the script inserts a row for each, marks it indeterminate, and lists it in the coverage listing, never silently. This keeps a valid counterexample in other years from being suppressed by row 0.
2. Using the rebuild's choices (Table 1 public works for H1, period mean; `Total Expenditure` for H2, period mean; NA = 0), the script reproduces the full-precision `repro_r/results_r.csv` values of TX_abs_rail70 and TX_p351_pwdebt70 with absolute difference < 1e-9. The printed 65.01 and 66.71 are not the comparison targets.
3. The H2 denominator equals `classified` in `repro_r/output/expenditure_classes.csv` year by year when NA = 0.
4. Every column named in the Fig A2 and rebuild Table 1 mappings exists in the sheet, and no column belongs to two classes in the H2 mapping. Table 1 components recorded in `coverage_map.csv` as absent from the workbook are excluded from this assertion.
5. The Fig A2 aggregate is a subset of the Table 1 public-works class.

**Coverage of Table 1 components (Codex 5).** `coverage_map.csv` lists every component named in the paper's Table 1 (p.349–350), the class it belongs to, and whether it is a workbook column. Absent components are at least: Controller and Auditor General, Treasury, Agent General, Immigration, Lands and Agriculture, Lighthouse, Engineer. Each is assigned to its Table 1 class from the paper's text, and the script records whether that class is in the numerator (public works, debt) or only in the denominator. The card does not assert a direction of bias. An omitted public-works item lowers numerator and denominator and so lowers the share; an omitted item of any other class lowers only the denominator and so raises the share. The net direction is not known, and it is a limitation (§10). Absent components cannot be bounded, since the workbook has no column for them.

**No inference.** There is no SE, interval or multiplicity correction, because the data are a census of the accounts and not a sample (§0). Verdict comparisons use unrounded values; results are reported to 2 dp.

**Descriptive summaries, reported next to each verdict and never entering it:** f = share of years with s⁰_t > 70; the mean of s⁰_t; the minimum and maximum of s⁰_t, s_lo,t and s_hi,t; and the list of years in each state.

## 5. Supplementary analyses (exhaustive; reported, never verdict-setting)
Every item is varied **one at a time** from the central analysis. Each gives s_t by year, the state counts A, C, I, and the row of §8 it would reach, labelled "as-if, does not vote".

**5A. Same estimand, different treatment of unknowns.**
1. **Zero-fill point series** (the rebuild's convention): NA = 0, so every year is defined and I = 0 unless the denominator fails. Both claims.
2. **Wider cap:** M_c replaced by 2·M_c.
3. **Narrower cap:** unknowns bounded by the largest observed value of that column in the ten years around t (window clipped at the sheet ends).
4. **Drop-unknown-years:** years with any unknown in a component of the claim are removed from the window, and the rest are evaluated at their point values. The number removed is reported.
5. **Robben Island moved from Law and order to Human resources** (S3 ambiguity 1). This changes no H2 share, because both classes are in GE. Reported as a check.

**5B. Changed estimand or changed population of years (labelled; never votes).**
1. H1 with the Table 1 public-works aggregate PW^T1 as denominator (the S3 baseline; S5-1).
2. H1 period-mean reading: the mean of s⁰_t over 1880–1909 compared with 70.
3. H1 window 1877–1909 (the first Fig A2 years in the 1870s).
4. H2 with `Total Expenditure` as denominator (the S3 baseline).
5. H2 with GE − mil as denominator (the Table 2 construction, defence excluded; S5-2).
6. H2 with public works restricted to PW^A2, GE denominator.
7. H2 window 1880–1909.
8. H2 period-mean reading: the mean of s⁰_t over 1870–1909 compared with 70.
9. **H2 without 1872–1876** (the years in which railways and the classified sum reach or exceed `Total Expenditure`; F4a). This changes the population of years and cannot test the registered universal claim (Codex 6). It is reported here, not as a data-handling variant.

**5C. Diagnostics and measurement checks.**
1. The annual series s⁰_t, s_lo,t and s_hi,t for both claims, with every year at or below 70 listed with its value, and the distance from 70.
2. The ratio classified/`Total Expenditure` by year, 1827–1909, including 1828 (5.74x) and 1855 (1.14x) from Codex's correction of S5-4.
3. **Item-level missingness** (`missingness_items.csv`): for every column entering any claim, the NA count and the years of NA inside W1 and W2, and whether the NA is interior (between observed years) or at an edge.
4. The largest single-year contributions to the minimum of s⁰_t: the numerator and denominator components in that year.
5. **Coverage map** of Table 1 components (§4), with the class of each absent component.
6. **Currency and units.** The predecessor workbook's notes!A7 records a currency conversion. The script records for each of the sheet's non-integer columns whether a notes cell documents a unit. Shares are invariant to a common conversion, so this check addresses only a conversion that differs by column.
7. **Capital versus current.** The years in which a railway line exceeds the classified non-railway total or `Total Expenditure` (the loan-financed signature, F4a), listed with the ratio. No correction is made.
8. **Overlapping categories.** A cross-tab of columns by class. Any column in two classes, or a total column counted alongside its parts, is flagged; the `stopifnot` in §4 check 4 stops the run on overlap.
No independent Monte Carlo is drawn for the unknowns. They are linked accounting quantities, and the bounds above are the treatment.

**5D. Secondary outputs (non-headline; reported, never verdicts).**
- **S-a.** Table 2 composition. Published versus workbook shares of public works, debt, human resources and administration+law within the four-category total for 1853, 1865, 1875, 1891 and 1904, plus the defence share of `Total Expenditure` (S5-3/F3). Also the H5 analogue, 1904 workbook public-works share × 6.81 (a different estimand).
- **S-b.** Maximum deficit 1872–1909, (i) overall (`Total Expenditure` − revenue) and (ii) excluding railway expenditure and railway receipts (F6/S5-5), compared with "up to 2 million pounds".
- **S-c.** Public debt/GDP in 1885, 1899, 1900 and 1909, compared with the text's "close to 230%", "almost 200%" and "above 140%". The national series needs Stone (1999), which was not recovered (F5/S5-7).
- **S-d.** Maximum `Total Railways`, and the maximum single non-railway public-works item, compared with 4.5m and 0.5m (S5-6).

## 6. Fixed choices
- No weights; every year counts equally in the descriptive summaries.
- Shares are computed from nominal series units. They are invariant to any common deflator or population.
- Windows are W1 = 1880–1909 and W2 = 1870–1909, inclusive. The workbook ends in 1909, and the paper's 1910 has no data.
- The threshold is strict, s_t > 70. s_t = 70 counts as not above.
- The Table 1 mapping is the rebuild's, unchanged (§3). The Fig A2 mapping is the five legend components.
- The cap M_c is the sheet-wide column maximum (§4).
- No trimming and no multiplicity family, because there is no inference.

## 7. Margins (A8 defaults)
| Claim | Type | Margin |
|---|---|---|
| H1 | threshold, universal ("from the 1880s onwards") | s_t > 70 for every t in 1880–1909 (PW^A2 denominator) |
| H1-c | causal clause | not-testable |
| H2 | threshold, universal ("from the 1870s onwards") | s_t > 70 for every t in 1870–1909 (GE denominator) |
| H3 | point (2.15) | not-testable; band if ever tested: [1.935, 2.365] |
| H4 | point (6.81) | not-testable; band if ever tested: [6.129, 7.491] |
| H5 | point (4.46) | not-testable; band if ever tested: [4.014, 4.906] |

A8 says "'consistently/always' means every reported unit or period". The registered wording "from the Xs onwards" has no hedge and is read the same way. The A8 majority rule ("typically") is not applied to these claims. The card adds no band, ceiling, mean condition or tolerance. The A8 plausibility flag does not apply, because H1 and H2 are thresholds and not magnitudes.

## 8. Verdict rules (central analysis only; checked in order; the first rule that applies decides; exhaustive)
**Threshold claims H1 and H2.** The quantities are the state counts A, C, I of §4 over the window W, with T = 70.

| # | Condition | Verdict |
|---|---|---|
| 0 | the script fails, or a `stopifnot` check in §4 fails | not-testable |
| 1 | C ≥ 1 (some year is at or below 70 under every admissible fill) | overturned (the universal statement is refuted by a valid counterexample) |
| 2 | C = 0 and I = 0 (A = \|W\|) | confirmed (every year above 70 under every admissible fill) |
| 3 | C = 0 and I = \|W\| (no year determinate) | not-testable |
| 4 | C = 0 and 1 ≤ I < \|W\| (no counterexample, but some years unresolved) | qualified (universality unresolved; every determinate year is above 70) |

- Rows 1–4 partition all (A, C, I) with A + C + I = |W|, whenever row 0 does not apply. The evidential states map as follows: complete valid coverage can establish universality (row 2); a valid counterexample refutes it whatever the other years show (row 1); incomplete coverage without a counterexample leaves it unresolved (rows 3–4).
- **Weakened and strengthened cannot be reached.** The registered claim is universal, so a universal statement either survives, is refuted, or is unresolved. The point quantity changes (C1, C2), so overturned is reachable under A4b.
- Reaching overturned on one valid counterexample is the consequence of reading a universal claim literally (A8). The count of counterexample years, f and the means are reported next to the verdict so a reader sees the size of the failure. They do not enter the rule.
- Exactness: s_lo,t = 70 is not above 70 and is therefore not in state "above"; s_hi,t = 70 is in state "counterexample".

**H1-c, H3, H4, H5:** not-testable (§1). No rule can move them.

**Summary.** Each claim is reported separately; H1–H5 are not aggregated. Next to each verdict the report shows the §5A and §5B values and their as-if rows, labelled "does not vote". Sensitivities never vote.

**Disclosure.** S5 and Codex have already produced the following numbers that bear on these verdicts. They use the NA = 0 convention, which is the §5A-1 series and not the central one.
- **H1.**
  - Fig A2 aggregate: mean 81.83; > 70 in 30/30 years 1880–1909; min 71.43 (1881); max 88.84 (1904); 1877 = 54.9.
  - Table 1 aggregate: mean 65.01; > 70 in 7/30 years (23%).
  - Expected central result: **confirmed** (row 2) if no component of the claim is unknown in a way that leaves a year's lower bound at or below 70 or unresolved. Otherwise **qualified** (row 4); **overturned** (row 1) if a year's upper bound is at or below 70; **not-testable** (row 3) if every year is indeterminate. A year at 71.43 could become indeterminate under the bounds. The card author has not run the bounds.
- **H2.**
  - Classified-sum denominator: mean 68.06; > 70 in 17/40 years (42.5%).
  - `Total Expenditure`: mean 66.71; 5/40 years (12.5%).
  - Excluding defence: mean 72.77; 32/40 years (80%), and 93% of 1880–1909; even then the annual claim fails in 8 years (Codex F2).
  - Fig A2 public works with `Total Expenditure`: mean 57.93.
  - Expected central result: **overturned** (row 1), since 23 years at the point values are at or below 70. The bounds could move some of these to indeterminate, and the result is overturned if at least one survives as a counterexample.
- **H3–H5.**
  - Workbook 1904 public-works share of the four-category total: 57.0%, against 65.5% implied by Table 2. The H5 analogue is 3.88.
  - 1853 public-works share: 45.4%, against 60.5% in Table 2.
  - Defence is 13.4% of 1904 `Total Expenditure`.
  - Nominal total expenditure rose 39-fold between 1853 and 1904.
- **Secondary.**
  - Deficit maxima: 0.97m (1908, overall); 1.19m (1904, classified sum); 2.094m (1909, railway-excluded; Codex F6).
  - Public debt/GDP: 226.2 (1885), 102.0 (1899), 196.6 (1900), about 96 (1909).
  - Railway maximum 4.27m (1903); largest non-railway item 0.30–0.32m.

**How the denominators were chosen.** Both central denominators were chosen from the paper's own definitions: the Fig A2 legend for H1, and the p.349 GE equation for H2. The card author knew the S5 numbers when choosing them. The choices go in opposite directions: H1 is expected to be confirmed and H2 overturned. Each claim's alternative definition (H1 with Table 1: 7/30 years above 70, which would also not confirm; H2 without defence: 32/40 years above 70, where counterexample years remain and the verdict would still be overturned) is reported in §5B and does not vote. The H1 alternative would reverse the expected verdict. The H2 alternative would not. v2 removed every element the card had added to A8 (the 10% undefined-year tolerance, the majority row and the mean-based weakened/overturned split). The only card-specific choices left are the denominator definitions and the data-derived cap M_c (§4). This disclosure does not prove that nothing was tuned.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P19_GF_codex_S6card.md): approve-with-changes, 7 required changes. Responses in v2:
1. **Invented verdict gates removed (§§4, 8).** The 10% undefined-year cutoff, the "0.5 < f < 1 qualified" row and the mean-based weakened/overturned split are deleted. Annual conjunction decides. f and the means are descriptive only. The A8 majority rule is stated as not applying to these universal claims (§7).
2. **Missing-year logic without a tolerance (§4, §8).** Each year gets one of three states (above, counterexample, indeterminate). Complete valid coverage confirms; a valid counterexample overturns whatever else is missing; incomplete coverage with no counterexample is qualified; no determinate year at all is not-testable. The mapping to S6 labels is the table in §8. The card says that weakened is unreachable and that overturned is allowed because the point quantity changes (A4b).
3. **Zero imputation replaced (§4, §5A, audit F4b).** Missing cells are unknowns. Year-level bounds use [0, M_c] per unknown with M_c the sheet-wide column maximum, so partial missingness within a class (railways alone, debt alone) is handled item by item. The zero-fill series becomes sensitivity §5A-1 and the disclosure series. §5C-3 adds item-level missingness. Structural zeros could not be verified, so bounds are used (Horowitz–Manski).
4. **Estimand fidelity (§1, §3).** The card now explains why Fig A2 controls the H1 interpretation and states that a confirmation concerns those five components only; the frozen spec's Table 1 and total-public-works readings are §5B-1. H2 is stated as the paper's GE concept measured on an incomplete reconstruction. Neither tests mining influence or crowding out (H1-c not-testable).
5. **Direction of omitted-item bias (§4, §10.4).** The assertion that omissions raise H2's share is withdrawn. `coverage_map.csv` maps each absent Table 1 component (including Lighthouse and Engineer) to its class and to numerator or denominator. The card states the two opposite effects and does not claim a net direction.
6. **Exclusions relabelled; measurement checks added (§5).** Dropping 1872–1876 moves to §5B-9 as a changed population of years. §5C adds item-level missingness, currency and units, capital versus current, and overlapping-category checks. No Monte Carlo is manufactured for linked accounting uncertainties.
7. **Implementation checks (§4).** `stopifnot` on unique years and complete window coverage before aggregation; the replication check uses full-precision `results_r.csv` with a 1e-9 tolerance; the card says that clustering, PPML, fixed effects, weights and Monte Carlo are inapplicable (§0, §4).

Optional suggestions accepted: annual distance from 70 is reported alongside component values (§4, §5C-1). A9 is followed: v2 here, v3 after the compliance check.

## 10. Known limitations at freeze
1. **The verdicts for H1 and H2 turn on which denominator is used**, and the paper never states either denominator next to its claim. The central choices follow the paper's own referents (Fig A2; the GE equation), but they were made with the S5 numbers in view (§8, disclosure). An adjudicator who reads "public works" in the abstract as the Table 1 class would expect H1 to fail (7/30 years). An adjudicator who reads "government expenditure" on p.351 as the Table 2 total without defence would still expect H2 to be overturned (32/40 years above 70 under the point values, with 8 counterexample years). That reading changes the size of the failure, not the verdict.
2. **The cap M_c is a card choice and an assumption.** It is data-derived and independent of any year, but it was chosen with the S5 numbers in view, and every verdict is conditional on the assumption that unknowns lie in [0, M_c]. A different cap changes which years are indeterminate. §5A-2 and §5A-3 report alternatives, and they do not vote. If many years are indeterminate, H1 may be reported as qualified where the point series would confirm it.
3. **One counterexample overturns.** Reading "from the 1880s onwards" literally makes the verdict rule severe. The number of counterexample years and the descriptive frequencies are reported, and the rule follows A8's "every unit".
4. **GE is incomplete and the direction of the bias is unknown.** Seven or more Table 1 components are absent from the workbook, and they sit in different classes (§4). The reconciliation gap between the classified items and `Total Expenditure` (S5-4/F4a) is unexplained. H2 verdicts concern the reconstructed GE.
5. **No sampling or measurement uncertainty is quantified beyond the bounds.** The series are a single transcription of the Blue Books with values only (S5-8). Transcription error, unit conversion (notes!A7 records a currency conversion) and classification error are addressed only through §5C. A year close to the threshold, such as H1's 71.43 in 1881, is judged deterministically.
6. **H3, H4 and H5 are not-testable.** Testing them needs Blue Book population and the De Zwart (2011) deflator, which have been requested from Abel Gwaindepi (`correspondence/P19_GF_request.md`, a draft that has not been sent). If the inputs arrive, testing would need an AMENDMENTS entry using the bands stated in §1/§7. Shares within a year do not depend on these inputs, so S-a already shows that the Table 2 composition disagrees with the workbook (F3).
7. **H1-c and the paper's other causal claims are not testable** with these data (F7). A confirmed H1 says nothing about mining influence or crowding out.
8. **The windows end in 1909**, not 1910 as the title states.
