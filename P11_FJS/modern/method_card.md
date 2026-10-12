# Method card: P11_FJS, public finances under VOC rule at the Cape, 1652–1795

Status: v3 (2026-10-11), final. Frozen under A9 with the commit message "FREEZE S6 card P11"; no further drafts.
- History: v1 → Codex review (reviews/P11_FJS_codex_S6card.md; approve-with-changes, 6 required changes) → v2 → Codex compliance check (reviews/P11_FJS_codex_S6card_v2.md; freeze-after-minor-edits, 4 edits) → v3. Issues v3 does not fully resolve are listed in §10.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. The card author chose no margin, band or threshold. The one deviation from an A8 default (the census reading of H1-rise, §1) rests on wording, follows the reviewer's own suggestion, and was accepted by Codex at the compliance check.

Rights class: open. Data are read from `D:\Data\ReplicateMe\P11_FJS\...` through `tools/paths.R` (A6). Codex may see code, schemas, data and aggregate output.

## 0. Type of analysis
The primary analysis is **one corrected central analysis**. Each verdict row has exactly one primary analysis, and only that analysis decides the verdict.
- **H1 rows (H1-00, H1-73, H1-rise):** (i) a **correction of verified code and code–text errors**. The household tax is rebuilt with the rules the paper states on p.17, and the top-decile share is computed as an actual share of total tax (§2). The point estimates change, so A4b does not apply. All three rows are population descriptions of the two enumerations (§1), so no inference enters any H1 verdict.
- **H2-89 and H2-yrs:** an **arithmetic re-verification of printed secondary inputs**. Neither is a correction. The printed GDP is not shown to be wrong, so substituting the P15 GDP is a vintage substitution and is reported only as sensitivity S18 (Codex RC4).
- **E-prog and SP-rise** (§5B) are (iv) new estimands, labelled `different-estimand`. They cannot confirm or overturn any row.

The paper reports no odds ratios and no probability statements derived from them, so A4c does not apply. No row is an inference-only upgrade, so the A4b ladder does not apply. Changed populations (duplicates removed, complete cases, other years) are sensitivities only (A4d).

## 1. Claims family (frozen headline rows) and interpretations
The three `headline = 1` rows in `claims/claims.csv` map to the verdict rows below. Interpretations are quoted from `claims/claims_spec.md`. Where one printed sentence makes a level statement and a comparison, they are separate rows, each judged on its own margin.

**H1, the tax burden of the richest decile.** Source sentence (p.19): "in 1700, the wealthiest ten percent of individuals at the Cape bore less than fifty percent of the tax burden; by 1773, their burden had increased to above sixty-one percent." Authors' reading (p.20): "These results offer strong evidence that the tax system imposed by the VOC was progressive on the whole, meaning that the wealthiest in society bore most of the tax burden, and that this progressiveness increased over the course of the eighteenth century." Frozen population (`claims_spec.md` (c)): "Households in the 1700 opgaafrol" and "Households in the 1773 opgaafrol".

| Row | Source | Claim | A8 type | Margin |
|---|---|---|---|---|
| H1-00 | `txt_p19_top10_1700` | "less than fifty percent" (1700) | threshold, "less than" | S00 < 50 (A8 default; strict) |
| H1-73 | `txt_p19_top10_1773` | "above sixty-one percent" (1773) | threshold, "above" | S73 > 61 (A8 default; strict) |
| H1-rise | the same sentence | "their burden had increased" | comparative ">" between two enumerations | Δ = S73 − S00 > 0 on the full enumerations (**wording-based A8 exception**: no CI; see below) |
| H1-prog | p.20, abstract, conclusion | "broadly progressive": the average tax rate rises with income | — | **not-testable** |
| H1-incr | p.20, conclusion | "this progressiveness increased", in the same sense | — | **not-testable** |

- **The census reading of H1-rise (A8 exception, Codex RC1).** A8's comparative default requires a CI that excludes 0. A CI needs a sampling or assignment mechanism, and the claim names none. Its wording refers to two finite, fully enumerated populations: "the wealthiest ten percent of individuals at the Cape" in 1700 and in 1773, frozen at S0 as the households in the two opgaafrolle. For a population observed in full, the difference of two population shares carries no sampling uncertainty, and a CI would answer a question about a hypothetical superpopulation that the authors do not pose (Abadie, Athey, Imbens and Wooldridge 2020, *Econometrica*). H1-rise is therefore judged on the sign of Δ, exactly as H1-00 and H1-73 are judged on their point values. This keeps one population reading across the three H1 rows; v1 mixed a census reading for the levels with a superpopulation reading for the change.
  - **Provenance.** The exception follows from the S0 population and the claim's wording, and the review proposed it. The card author knows from S5 that Δ ≈ 17 pp (§7), so the exception's consequence for the verdict is known. A superpopulation CI was not computed, so whether the A8 default would have given the same verdict is not known.
  - **Accepted.** The compliance check accepted the exception, finding that its rationale follows from the frozen population independently of the observed sign of Δ. H1-rise is therefore decided by §8 on the sign of Δ. The superpopulation bootstrap is reported as SP-rise (§5B) and never votes.
- **H1-prog and H1-incr are not-testable (Codex RC3).** Progressivity means that the *average tax rate* (tax divided by income) rises with income, not that tax payments rise with income (Lambert 2001; Kakwani 1977). The data hold no income measure, households are ranked by slaves (a wealth proxy), and the authors themselves say on p.19 that with a wealth ranking "it is not possible to establish whether this is a regressive, proportional or progressive tax". v1 also said that progressivity in output is "fixed by construction". That is withdrawn. Each commodity levy is proportional to its own output, but the rates differ across commodities (10% of grain value, 1 or 3 Rd per leaguer of wine, per-head livestock rates) and the flat poll tax adds a regressive element. The average tax rate on aggregate output therefore varies with each household's output mix, and the mix changes over time. Progressivity in output is an empirical question; progressivity in income cannot be answered because income is absent.
- **The authors' own gloss** ("meaning that the wealthiest in society bore most of the tax burden") is carried by H1-73, and their "increased" by H1-rise. No separate row is added, to avoid counting the same evidence twice.
- **E-prog (different-estimand, reported, never a verdict).** The top slave decile's tax share relative to its share of gross farm output, and the slave-ranked concentration difference K^s_t (§3). It asks a nearby question, whether the slave-rich paid more tax than their share of output. **It is not a Kakwani index:** Kakwani's K ranks units by income and compares the tax concentration curve with the income Lorenz curve. K^s_t ranks by slaves and uses gross farm output as the base, so it is labelled "slave-ranked tax-minus-output concentration" throughout.
- The conclusion's sentence that "wheat and wine producers paid taxes more progressively … than cattle farmers did" (C16) is not a headline row. It is outside the family and is recorded as not assessed.

**H2, deficits.** Source: Image 6 (p.16) and p.16 text. Authors' reading: "The Colony experienced a deficit throughout this period. The deficit to GDP ratio increased to forty percent in 1789 … the consistently significant budget deficits certainly do not reflect a highly extractive system." Abstract: "the Company's expenses exceeded its revenues throughout the period under review".

| Row | Source | Claim | A8 type | Margin |
|---|---|---|---|---|
| H2-89 | `I6_1789_defgdp` | deficit/GDP "forty percent in 1789" | point ratio | 36 ≤ R89 ≤ 44 (A8 point default, ±10% of 40) |
| H2-yrs | `I6_1789_defgdp` reading, p.16 | "a deficit throughout this period" (Image 6, 1777–1794) | threshold, "throughout" | D_t > 0 in every Image 6 year with revenue and expenditure printed (A8: "consistently/always" = every reported unit) |
| H2-full | abstract | expenses exceeded revenues "throughout the period under review" (1652–1795) | threshold | **not-testable** |
| H2-ext | p.16, p.20 | deficits "do not reflect a highly extractive system" | — | **not-testable** |

- **Why the ratio default for H2-89.** Deficit/GDP is a flow divided by GDP, not a share of a whole on [0,1]; it can exceed 100%. `claims.csv` codes it `quantity_type = ratio`. A8's ratio default (±10% of |X|) applies; A8a governs bounded shares only (Codex optional 1).
- **H2-full is not-testable.** The surviving material holds Company revenue and expenditure for 1777–1794 only (Image 6, from De Kock). The workbook sheet `VOC Income (VD&R)` holds pacht income for 1700–1793 but no expenditure.
- **H2-ext is not-testable.** A deficit does not identify who benefited from spending, and the data cannot measure extraction through the Company's monopsony (Codex F1b, disputed in `audit.md`).
- **Scope of H2 confirmations.** Both H2 rows check the arithmetic of printed secondary figures. A confirmation says that Image 6 is internally consistent with the claim; it does not validate De Kock's fiscal data or the unsourced GDP.

**Stars.** No stars or SEs are printed anywhere; `stars05.txt` = 2 by default and plays no role.

## 2. Defects addressed
S5 (Claude C1–C17, Codex F1–F8, reconciled in `audit.md`) found:
- (a) **Share definition (C4, F2).** The workbook's "share of tax" (`Deciles!W24`) is the top group's mean divided by the sum of ten group means, with groups emptied by ties at zero slaves filled with a lower mean. It is not the top decile's share of total tax. Stata's `xtile` also gives unequal groups (268 of 2,702 households in group 10 in 1773). A verified computational error, fixed in the primary.
- (b) **Wine tax (C1, C2, F3).** The surviving do-file taxes wine at 72 stuivers before 1743 (the paper: 1 Rd = 48 st; the published figures used 48) and multiplies post-1743 wine by an undisclosed 0.7. Verified code–text discrepancies, fixed.
- (c) **Grain tax (C8, F4).** Taxed at 10% of output net of seed; the paper says "ten percent of the yield". Verified code–text discrepancy, fixed.
- (d) **Wine imputation (C3, F4).** Households with vines and no recorded wine are given `wingst × 0.0008813`, a constant averaged over all households rather than producers. The paper describes no imputation. Verified; the primary applies the stated rule (no imputation).
- (e) **Duplicates (F8).** 31 excess full-row duplicates, 8 in 1773. Unverified whether they are errors; sensitivity only.
- (f) **GDP provenance (C9, S2-9).** The printed Image 6 GDP survives in no P15 workbook that S2 examined; Codex disputes that its absence from every vintage is established. The printed GDP is not shown to be wrong. **Not corrected**: the primary keeps the printed GDP and S18 reports the P15 substitution.
- (g) **No income measure (C11, C12, F1a).** Not fixable with these data. Handled by the not-testable rows and E-prog.
- (h) **No uncertainty** is reported anywhere. Under the census reading (§1) the H1 verdicts need none; the superpopulation intervals are reported as SP-rise (§5B).

Not addressed (no headline row rests on them): the p.18 revenue and direct-tax figures (C5, F5), the 1777 extrapolation (C6), Image 8's units and coverage (F6), the dropped census years (F7; neither 1700 nor 1773 is dropped), and Image 7's attribution of secondary streams (C17). The hearth-tax district proxy (C13) is bounded by S11.

Sources: Lambert (2001, *The Distribution and Redistribution of Income*) and Kakwani (1977, *Economic Journal*) on progressivity and concentration indices, for E-prog; Abadie et al. (2020, *Econometrica*) on design-based uncertainty in finite populations, for the census reading; Fang and Santos (2019, *Review of Economic Studies*) on bootstrap failure for non-differentiable functionals and Cameron and Miller (2015, *Journal of Human Resources*) on few clusters, for the SP-rise diagnostics; Fourie and Van Zanden (2013, *SAJE*) for the P15 GDP series.

## 3. Estimands
**Household tax (stuivers), applied to every record i of year t in `base.dta` after lines :6–11 (which drop no 1700 or 1773 record).**
- tslaves = sm + sv + ss + sd; assets = bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw; sassets = tslaves + assets. Horses (`pd`) and pigs (`vk`) are not assets, as coded and as p.17 states for horses.
- Poll/hearth: 32 if sassets = 0; 192 if tslaves > 0, assets = 0 and ds = 1; 32 if tslaves > 0, assets = 0 and (ds ≠ 1 or ds missing); 0 otherwise. (As coded; p.17.)
- Wine: 48·wyn if t < 1743; 144·wyn if t > 1743. **No 0.7 factor, no imputation**: `wyn` as recorded. (p.17: 1 Rd before 1743, 3 Rd after.)
- Grain: 0.1 × 48 × (6·kgw + 3·rgw + 3·cgw), on gross reaped quantities. (p.17: 10% of the yield; wheat 6 Rd, barley and rye 3 Rd per muid.)
- Livestock: 1·bste + 0.16·skpe. (p.17.)
- tax_i = poll/hearth + wine + grain + livestock.

**Top-decile share S_t (percent), fractional tie rule.** Within year t, with n_t records:
- k = n_t/10 (not rounded). Let c be the slave count such that #{tslaves > c} < k ≤ #{tslaves ≥ c}.
- Weight w_i = 1 if tslaves_i > c; w_i = (k − #{tslaves > c}) / #{tslaves = c} if tslaves_i = c; w_i = 0 otherwise. Then Σ w_i = k exactly.
- S_t = 100 × Σ w_i·tax_i / Σ tax_i.
- This equals the expected share under uniform random tie-breaking at the cut-point, with the top group exactly one-tenth of records. It is the actual share of total tax that the authors' wording describes.
- **S00 = S_1700, S73 = S_1773, Δ = S73 − S00**, each computed once on all records of the enumeration.

**E-prog (different-estimand).** O_i = 6·kgw + 3·(rgw + cgw) + 3·wyn rixdollars, gross farm output as defined in `compare/s5_checks/s5_progressivity.R` (livestock excluded; wine at 3 Rd per leaguer).
- OS_t = 100 × Σ w_i·O_i / Σ O_i, with the same weights w_i; R_t = S_t / OS_t; ΔR = R73 − R00.
- Concentration indices of tax and of O by slave rank (ties at mid-rank), C^s_tax and C^s_O, and K^s_t = C^s_tax − C^s_O (slave-ranked; not an income-ranked Kakwani index, §1).
- The average tax rate on output by slave decile, Σtax/(48·ΣO), with deciles built by the same fractional rule.

**H2.** Inputs are the printed Image 6 values frozen in `claims/claims.csv`.
- D_t = Exp_t − Rev_t (guilders), computed, not read from the printed Deficit column.
- **R89 = 100 × D_1789 / GDP_1789**, with GDP_1789 the **printed** Image 6 GDP (3,472,000 guilders, `I6_1789_gdp`).
- **H2-yrs universe:** the years in which Image 6 prints both revenue and expenditure: 1777, 1787, 1789, 1792, 1794. 1791 has no printed revenue and is outside the universe (A8: "every reported unit").

## 4. Primary analysis (one per verdict row)
**Common data.** `D:\Data\ReplicateMe\P11_FJS\original\Fourie Jansen Siebrits\base.dta`, all districts, all records of 1700 (n = 438) and 1773 (n = 2,702), as in the published Image 9. No weights. No trimming.

**Missing inputs (Codex RC5; no tolerance).** The estimand is defined over every enumerated record, so S_t is undefined if any record of year t has a missing tax input. Dropping records would change the population (A4d), and imputing them would add a model the paper does not state. If any tax input is missing for a 1700 or 1773 record, every H1 row using that year is not-testable, and the complete-case value is reported as S14. S5 found no missing tax input in any year. Missing `ds` is not a missing tax input; the poll/hearth rule above handles it.

**Checks before any verdict.** With the corrections switched off (48 st before 1743, 0.7 factor, net-of-seed grain, imputation constant 0.0008813, workbook mean-of-means share), the script must reproduce the Image 9 pastes (`Deciles!Q12:W21`) to every printed digit, and the S2 run-A1 household `totaltax` to within 0.01 stuivers. If it does not, every H1 row is not-testable, and the discrepancy is logged in `modern/DEVIATIONS.md` (A5).

**A. H1-00 and H1-73.** S00 and S73 are computed once on the full enumerations and compared with the thresholds. No interval enters these verdicts.

**B. H1-rise.** Δ = S73 − S00 from the same two computations, compared with 0 (census reading, §1). No interval enters this verdict.

**C. H2-89.** R89 from the printed revenue, expenditure and GDP for 1789. No inference enters. If a printed input cannot be read from `claims.csv`, H2-89 is not-testable.

**D. H2-yrs.** D_t for the five universe years, from the frozen printed values. No inference enters.

**Reported with the primary (descriptive, never voting).** For 1700 and 1773: n; the record counts by district (`ds` = 1–4 and missing) and the top-decile weight Σ w_i by district; the cut-point count c and the number of records tied at c; the number of zero-slave records.

**Scripts.** `modern/01_tax.R` (construction and the corrections-off check), `02_shares.R` (S_t, E-prog), `03_deficit.R`, `04_sensitivities.R` (§5A), `05_bootstrap.R` (SP-rise and its diagnostics, §5B), `06_verdicts.R`. Outputs as CSV in `modern/output/`; household-level files only on D: (`dscratch("P11_FJS", "modern")`).

## 5. Admissible sensitivities and reported analyses (exhaustive; never verdict-determining)
### 5A. Sensitivities (same estimand, one choice changed)
Each item changes one choice from the primary and reports S00, S73 and Δ as point values on the full data, unless stated.

**Share definition (C4, F2):**
1. The published construction: run A1 taxes with the workbook mean-of-means share. Diagnostic; it reproduces Image 9.
2. Stata `xtile` group 10, exact sums (unequal groups).
3. Ties kept together: the top group is every record with tslaves ≥ c (it may exceed 10%).
4. Ties broken by tax (the bounds of the tie rule). Records with tslaves = c are sorted by tax, (a) descending and (b) ascending, with ties in tax broken by record order in `base.dta`. The top group is every record with tslaves > c plus the first records of the sorted tied set until the group holds k records. Because k = n_t/10 is fractional, the last record admitted gets weight k − ⌊k⌋ (or the remainder after whole records), so Σ w_i = k exactly, as in the primary.
5. All tax corrections off, primary share rule (isolates the effect of (a) alone).

**Tax construction (C1–C3, C8, C13, C14):**

6. The 0.7 wine factor after 1743 restored.
7. Grain net of seed (floored at 0) restored.
8. Vine imputation restored. **Recipients:** records with wingst > 0 and wyn = 0 (as coded at `fiscalpolicy.do:36-43`); S5 found 576 such records in all retained years, none in 1773, so the item changes only S00 and Δ. Recipient wine = wingst × r, with r:
   - (a) the coded constant 0.0008813;
   - (b) the mean of wyn/wingst among **donors** = records with wingst > 0 and wyn > 0 in the recipient's own census year;
   - (c) the median of the same within-year donor ratios;
   - (d) the mean of wyn/wingst among donors pooled over all census years retained after lines :6–11 (the population the coded constant should have used; S5's "producer mean").
9. The surviving code's 72 stuivers before 1743 (run 0; affects 1700 only).
10. Swellendam (`ds == 4`) poll tax at 36 stuivers (p.13).
11. **Hearth-tax allocation bounds (C13, C14; Codex RC6).** The uncertain set U_t is every record with tslaves > 0 and assets = 0 (any `ds`, missing included), since town residence is unrecorded everywhere. Each record in U_t pays either 32 or 192 stuivers. Ranking is by slaves, so the weights w_i do not change.
    - Each record in U_t gets a liability h_i ∈ {32, 192}; every other record keeps its primary poll/hearth liability. S_t(h) = 100 × Σ w_i·tax_i(h) / Σ tax_i(h), the primary share with the primary weights.
    - (a) Upper bound S_t^max = max of S_t(h) over all admissible h; (b) lower bound S_t^min = min over the same set. No intermediate liability is admissible.
    - **Exact computation.** S_t(h) is a ratio of two functions linear in h, so at the maximum every record with w_i above the optimal share (as a fraction) pays 192 and every record below it pays 32. Sort U_t by w_i descending (ties by record order in `base.dta`); for j = 0, …, |U_t| assign 192 to the first j records and 32 to the rest; S_t^max is the largest of these |U_t| + 1 values. S_t^min is the smallest value from the same procedure with U_t sorted by w_i ascending. Both are exact optima over the admissible set.
    - Bounds on Δ: [S73^min − S00^max, S73^max − S00^min] (the two years' allocations are independent).
    - (c) and (d), the uniform v1 variants for reference: no record pays the hearth tax; records with missing `ds` pay it.
12. Pigs (`vk`) counted as agricultural assets (the pair-B rule, which exempts pig owners from the poll tax).

**Population (A4d; reported, cannot decide):**

13. Full-row duplicates dropped, one record kept per identical row within year (F8).
14. Complete cases, computed only if the missing-input rule (§4) is triggered.

**Coverage and influence:**

15. S_t for all seven Image 9 years (1700, 1719, 1731, 1738, 1741, 1757, 1773), the number of years with S_t > 50, and the number of year-on-year increases.
16. Leave-one-record-out: the maximum |ΔS| in 1700 and 1773, and whether any single deletion moves S00 or S73 across its threshold or Δ across 0.

**H2:**

17. D_t from the printed Deficit column (diagnostic; S2 found it equal to Exp − Rev).
18. **GDP-vintage substitution (Codex RC4).** R89 with GDP_1789 replaced by each of the following, enumerated now:
    - (a) the P15 S2 recalculated primary workbook: `D:\Data\ReplicateMe\P15_FvZ\repro_original\recalc_cells_primary.rds`, sheet `total economy`, column E (col = 5), row = 1789 − 1698, × 1000, as read by `P11_FJS/repro_original/extract_results.R` l.115–117;
    - (b) the same cell in the P15 copy workbook, `recalc_cells_copy.rds`; if that cell is absent or non-numeric, the item is reported as absent.
    - The report states that the currency, price basis (nominal or constant) and geographic coverage of column E have not been shown to match the printed GDP, and gives the ratio of each P15 value to the printed GDP for every Image 6 year in which both exist.

### 5B. Reported analyses under a different estimand
**SP-rise (superpopulation reading of H1; different-estimand).**
- **Population.** A superpopulation of households generated by the same process in each census year. This is not the population the claim describes (§1).
- **Bootstrap.** Within each year, records are drawn iid with replacement (n = 438 and n = 2,702), independently across the two years. In each replicate b the 1700 indices are drawn first (`sample.int(438, 438, replace = TRUE)`), then the 1773 indices. In each draw, taxes are carried with their records, c and the weights w_i are recomputed, and S*00, S*73 and Δ* are computed. E-prog quantities for 1700 and 1773 are computed from the same draws.
- **Other Image 9 years (E-prog only).** For each of 1719, 1731, 1738, 1741 and 1757, a separate bootstrap of the same form: records of year t (all records retained after lines :6–11, n_t) drawn iid with replacement, B = 9,999, with `set.seed(20261011 + t)` set at the start of that year's run. These draws feed only the E-prog decile rates of §5B and never SP-rise.
- B = 9,999 (fixed; no escalation), `set.seed(20261011)` at the start of the main run and again at the start of each diagnostic run (i), (ii) and (iv), R default RNG (Mersenne-Twister, Inversion, Rejection). Percentile 95% intervals, quantile type 7. The Monte Carlo SE of each endpoint is reported, from 10 consecutive batches of 999 draws (the last 9 draws left out of this calculation only): MC SE = SD over batches / √10.
- **No draw is dropped.** A draw with Σ tax* ≤ 0 or a non-finite statistic is counted. If any such draw occurs, the interval for the affected quantity is reported as undefined, with the count, rather than computed on a conditioned subset.
- **Dependence diagnostics (Codex RC2).** Records in a district share harvest, price and recording conditions, so within-year independence is an assumption, not a fact. Reported:
  - (i) a district-stratified bootstrap: records resampled within `ds` (missing `ds` as its own stratum), which holds district composition fixed;
  - (ii) a district-cluster bootstrap within year, with the number of districts stated. With three or four districts per year it is unreliable (Cameron and Miller 2015) and is shown only to indicate the direction of the dependence.
- **Regularity diagnostics (Codex RC2).** S_t depends on the discrete cut-point c, and the share of records tied at c is large. The functional is not smooth where k crosses a mass point, so the ordinary bootstrap need not be consistent there (Fang and Santos 2019). Davidson (2009) covers the Gini and does not validate this statistic. Reported:
  - (iii) the bootstrap distribution of c* in each year, and the share of draws with c* ≠ c;
  - (iv) an m-out-of-n bootstrap with m_t = ⌊n_t/2⌋ (219 in 1700, 1,351 in 1773), drawn with replacement within year, B = 9,999, same seed and draw order as the main run. The interval is centred on the full-sample estimate and assumes the √n rate. For each year, the scaled deviation is d*_t = √(m_t/n_t) × (S*_{t,m} − S_t). The 95% interval for S_t is [S_t − q_{0.975}(d*_t), S_t − q_{0.025}(d*_t)], quantile type 7. For Δ, the scaled deviation combines the two years with their own factors, d*_Δ = d*_1773 − d*_1700 from the same replicate, and the interval is [Δ − q_{0.975}(d*_Δ), Δ − q_{0.025}(d*_Δ)].
- No result of SP-rise or its diagnostics changes any verdict, under any outcome.

**E-prog** (different-estimand): R_t, K^s_t and the average tax rate on output by slave decile for 1700 and 1773, ΔR, and the decile rates for the seven Image 9 years, each with a percentile interval: from the SP-rise main draws for 1700, 1773 and ΔR, and from the separate per-year bootstraps above for the other five years.

## 6. Fixed choices
- **Years:** 1700 and 1773 for the H1 rows; 1789 for H2-89; 1777, 1787, 1789, 1792 and 1794 for H2-yrs. **Unit (H1):** a `base.dta` record (household entry). **Ranking variable:** tslaves. **No weights. No trimming.**
- **Multiplicity:** no verdict row uses inference, so there is no multiplicity family. SP-rise and E-prog intervals are unadjusted and descriptive.
- **Boundaries:**
  - S00 = 50 fails "less than fifty"; S73 = 61 fails "above sixty-one".
  - Δ = 0 is not an increase.
  - Band endpoints 36 and 44 are inside the band.
  - D_t = 0 is not a deficit.
- Verdict comparisons use unrounded values; results are reported to 2 dp (shares) and 1 dp (ratios).
- **Seed:** 20261011.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1-00 | S00 < 50 | A8 threshold default (T stated by the authors) |
| H1-73 | S73 > 61 | A8 threshold default (T stated by the authors) |
| H1-rise | Δ > 0 on the full enumerations | A8 comparative default with a **wording-based exception**: no CI, because the claim describes two complete enumerations (§1). Accepted at the Codex compliance check. |
| H2-89 | 36 ≤ R89 ≤ 44, printed GDP | A8 point default for a ratio (±10% of 40) |
| H2-yrs | D_t > 0 for every universe year | A8 "consistently/always" default |

- No ceilings. A8's plausibility flag applies to magnitude claims only; no row here is one.
- A4a (credible null) does not apply: H1-rise is a comparative row under A8, not a magnitude claim with a published b₀. The magnitude content of the sentence (from below 50 to above 61) is carried jointly by H1-00 and H1-73.

**Disclosure.** S2 and S5 numbers seen before this card, all bearing on the verdicts:
- **Top-decile shares (`compare/s5_effects.csv`), 1773 / 1700:**
  - published construction (A1, workbook share) 61.24 / 45.68; surviving code (run 0) 61.24 / 45.04;
  - exact `xtile` share 62.94 / 46.77 (run 0: 62.94 / 46.10); ten equal groups with random ties 63.10 / 46.77 (run 0: 63.11 / 46.10);
  - no 0.7 factor 61.36 / 45.68 (the C2 text in `audit.md` says 61.40); gross grain 61.78 / 45.48 (the C8 text says 61.82 / 45.53);
  - imputation constant variants, 1700 only: 45.68 (printed mean), 45.25 (producer mean), 45.76 (none);
  - Swellendam 36 st 61.21 / 45.68;
  - pair-B-like construction (no 0.7, no imputation, gross grain): workbook share 61.82 / 45.55; exact share 63.46 / 46.60; random ties 63.63 / 46.60.
- **Pair-B decomposition (`s5_pairB_decomp.csv`).** Step 4 (random ties, gross grain, no 0.7, no imputation) is the primary construction up to the tie rule: 1700 46.60, 1719 51.31, 1731 50.84, 1738 57.69, 1741 59.82, 1757 59.72, 1773 63.64. The independent rebuild (pair B) gives 46.60 → 63.65, which Codex confirms. Implied Δ ≈ 17 pp.
- **Progressivity check (`s5_progressivity.csv`), top-decile share of tax / slaves / output:** 1700 46.8 / 68.1 / 49.7; 1719 51.0 / 60.5 / 55.0; 1731 50.4 / 52.8 / 54.1; 1738 57.5 / 51.1 / 64.6; 1741 59.5 / 58.0 / 64.1; 1757 58.6 / 57.7 / 68.6; 1773 63.1 / 60.1 / 74.8. Zero-slave records: 64% in 1700 and 58% in 1773. Implied R00 ≈ 0.94, R73 ≈ 0.84.
- **H2:** R89 = 40.41 with the printed GDP and 42.24 with the P15 GDP; the P15 series differs from the printed GDP by −8.1% to +4.7% across Image 6 years. Every Image 6 year with both values printed shows a positive deficit (254,000; 1,304,000; 1,403,000; 342,000; 230,000 guilders).
- **Not seen.** The S3 recreation reports household-bootstrap SEs for the top-decile shares (`repro_r/decisions.md` D11, column `se` of `results_r.csv`). The card author has not opened those values; the coordinator may have seen them at S4. No bootstrap interval for Δ or E-prog has been computed, and no district count or hearth-tax bound has been computed.

**Consequence.** Every verdict is effectively known at freeze: S00 ≈ 46.6 < 50, S73 ≈ 63.6 > 61, Δ ≈ 17 > 0, R89 = 40.41 ∈ [36, 44], and all five deficits are positive. The margins are protocol defaults, apart from the H1-rise exception, whose basis is the S0 population and the claim's wording. This disclosure is necessary, but it does not establish that the card's choices are independent of S5 (Codex RC5); §10 records this. The card's contribution is the corrected construction, the explicit not-testable status of the progressivity and extraction readings, and the reported analyses in §5.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
**H1-00** (threshold alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | the corrections-off check fails, the computation fails, or a 1700 record has a missing tax input (§4) | not-testable |
| 1 | S00 < 50 | confirmed |
| 2 | S00 ≥ 50 | qualified (threshold missed) |

**H1-73** (threshold alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | the corrections-off check fails, the computation fails, or a 1773 record has a missing tax input (§4) | not-testable |
| 1 | S73 > 61 | confirmed |
| 2 | S73 ≤ 61 | qualified (threshold missed) |

**Restriction on H1-00 and H1-73 (stated prominently, Codex optional 1).** On these rows "overturned" and "strengthened" are unreachable, whatever the data show: they are threshold descriptions without inference, and a missed threshold is "qualified", as on the P10 point rows. A share far on the wrong side of the threshold (for example S73 = 50) would still be "qualified". The synthesis reports this restriction with the verdicts.

**H1-rise** (comparative ">", census reading, §1):
| # | Condition | Verdict |
|---|---|---|
| 0 | the corrections-off check fails, the computation fails, or either year has a record with a missing tax input | not-testable |
| 1 | Δ > 0 | confirmed |
| 2 | Δ = 0 | weakened (no increase) |
| 3 | Δ < 0 | overturned (the burden fell) |

**H2-89** (A8 point band alone):
| # | Condition | Verdict |
|---|---|---|
| 0 | a printed 1789 input (revenue, expenditure or GDP) cannot be read from `claims.csv` | not-testable |
| 1 | R89 ≤ 0 (no deficit in 1789) | overturned |
| 2 | 36 ≤ R89 ≤ 44 | confirmed |
| 3 | 0 < R89 < 36 | qualified (ratio below the stated value) |
| 4 | R89 > 44 | qualified (ratio above the stated value) |

**H2-yrs** (conjunction over the five universe years):
| # | Condition | Verdict |
|---|---|---|
| 0 | any printed input for a universe year cannot be read from `claims.csv` | not-testable |
| 1 | D_t < 0 in at least one universe year | overturned (a reported year in surplus) |
| 2 | no D_t < 0, and D_t = 0 in at least one year | qualified (a balanced year) |
| 3 | D_t > 0 in all five years | confirmed |

**H1-prog, H1-incr, H2-full, H2-ext:** not-testable. **E-prog and SP-rise:** different-estimand (values and intervals reported). No §5 result enters any table.

**Summaries and coverage.** For H1 and H2 separately, report coverage (rows assessed; rows not-testable; rows different-estimand) and the weakest verdict among the assessed rows. An assessed row is one whose verdict is confirmed, qualified, weakened or overturned; rows that are not-testable or different-estimand are excluded from the weakest-verdict summary and appear only in the coverage counts. The order is overturned < weakened < qualified < confirmed. If no row of the group is assessed, the group summary is not-testable. Every row-level verdict is reported. The summary states that the paper's central interpretation (progressivity, its increase, non-extraction) is not assessed, and that both H2 rows re-verify printed secondary arithmetic.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P11_FJS_codex_S6card.md): approve-with-changes, 6 required changes, all addressed in v2.
1. **H1-rise and the frozen population (§1, §4B, §7, §8).** The superpopulation bootstrap no longer decides H1-rise. H1-rise is judged on Δ = S73 − S00 over the two complete enumerations, the population frozen at S0, under a wording-based A8 exception, with the justification and provenance stated in §1. The bootstrap is relabelled SP-rise, `different-estimand` (§5B). The compliance check accepted the exception (below), so the v2 fallback to `different-estimand` lapses. All three H1 rows now share one population reading.
2. **Bootstrap validity (§4, §5B, §10).** Because SP-rise no longer votes, bootstrap validity no longer affects any verdict. Its assumptions are still examined: district counts and the top-decile weight by district are reported with the primary; district-stratified and district-cluster bootstraps are added, the latter flagged as unreliable with three or four clusters; the non-smoothness at the discrete cut-point is stated, with the distribution of c*, the share of draws with c* ≠ c and an m-out-of-n bootstrap reported. The citation of Davidson as validating this statistic is withdrawn.
3. **Progressivity definition (§1, §3).** Progressivity is now defined by the average tax rate rising with income. The "fixed by construction" argument is withdrawn: differing commodity rates and changing output mix make progressivity in output an empirical question. H1-prog and H1-incr remain not-testable because income is absent. E-prog's K^s_t is labelled a slave-ranked tax-minus-output concentration difference, distinct from an income-ranked Kakwani index, and the average tax rate on output by decile is added.
4. **H2-89 reclassified (§0, §2(f), §3, §5A 18).** The primary uses the printed GDP, so H2-89 is an arithmetic re-verification, not a correction. The P15 substitution is sensitivity S18, labelled a GDP-vintage substitution, with the unverified currency, price basis and coverage stated. §1 and §8 say that the H2 rows cannot validate the underlying fiscal data.
5. **Computational gates (§4, §5B, §7).** The 1% missing-input allowance is removed: any missing tax input makes the year's rows not-testable, with no dropping (A4d) and complete cases as S14. The undefined-draw rule and the 0.25% cutoff are removed: no draw is dropped, and an affected interval is reported as undefined. The boundary-proximity escalation is replaced by a fixed B = 9,999 with a batch Monte Carlo SE. The disclosure in §7 now says that it does not establish independence (§10.1).
6. **Sensitivity specifications (§5A).** S8 now fixes recipients (wingst > 0, wyn = 0) and donors (within-year producers for (b) and (c), all retained years for (d)). S18 enumerates its two P15 vintages by file and cell. S11 is replaced by allocation bounds that let the uncertain hearth-tax liabilities differ inside and outside the top decile, with the implied bounds on Δ; the uniform variants are kept for reference. All remain non-voting.

**Optional suggestions.**
1. The A8 thresholds and the [36, 44] ratio band are kept, with no ceiling and no results-informed margin. A8a is stated to apply to bounded shares only (§1). The restriction that H1-00 and H1-73 cannot be overturned is stated prominently in §8.
2. §6 now lists the years of each row. S4 specifies fractional handling of the marginal tied record. A9's cap applies: v2 now, a compliance check, then v3 frozen.

**Codex compliance check** (reviews/P11_FJS_codex_S6card_v2.md): freeze-after-minor-edits. RC1, RC3, RC4 and RC5 addressed; RC2 and RC6 partly. A8/A8a applied exactly; no undisclosed S5-tuned margin; tables exhaustive; one primary per row. The four edits, all made in v3:
1. **Exception accepted; freeze status.** The pending language in the status block, §1, §7 and §10 is replaced by the acceptance; Status is v3, frozen under A9.
2. **S11.** The fractional-weight formula, which assigned inadmissible intermediate liabilities, is replaced by the exact minimum and maximum of the weighted share over h_i ∈ {32, 192}, with the computation fixed (§5A 11).
3. **§5B.** The m-out-of-n interval is now centred on the full-sample estimate with year-specific √(m_t/n_t) scaling, including for Δ. The bootstrap for the five intermediate E-prog years is defined (separate per-year runs, fixed seeds).
4. **§8 summaries.** Not-testable and different-estimand rows are excluded from the weakest-verdict summary; a group with no assessed row is summarised as not-testable.

## 10. Known limitations at freeze
1. **Verdicts are known in advance.** S5 has already computed S00, S73, Δ, R89 and the five deficits under constructions that coincide with, or bracket, the primary (§7 Disclosure). The card cannot produce an informative test of these rows; it records them. Disclosure does not establish that the card's choices are independent of S5.
2. **The H1-rise exception was adopted with its consequence known.** The census reading is a deviation from A8's comparative default. Its basis is the wording and the S0 population; the review proposed it and the compliance check accepted it. Its consequence (Δ ≈ 17 pp) was nonetheless known when it was adopted, and whether a superpopulation CI would have excluded 0 is not known at freeze.
3. **No sampling uncertainty enters any verdict.** Under the census reading the H1 verdicts treat the opgaafrolle as complete, error-free enumerations. Under-registration, transcription error and the statutory-imputation model are not sampling variation, and nothing in the card quantifies them. A reader who prefers a superpopulation reading can consult SP-rise, whose validity is itself uncertain (items 4 and 5).
4. **SP-rise regularity is unresolved (RC2 partly addressed).** The top-decile share depends on a discrete cut-point with heavy ties; the ordinary bootstrap may be inconsistent there. The c* distribution and the m-out-of-n intervals are diagnostics, not a remedy: the m-out-of-n scaling assumes a √n rate, which is not established for this statistic, and m = ⌊n_t/2⌋ is a convention, not a tuned choice.
5. **Within-year dependence is unresolved.** Districts number three or four per year, too few for reliable cluster inference. The stratified and cluster bootstraps indicate direction only. Records cannot be linked across years.
6. **The paper's central interpretation is not assessed.** Progressivity, its increase, the producer-type comparison and non-extraction are not-testable. E-prog rests on a rough output measure (no livestock, wine at 3 Rd per leaguer, gross output rather than income) inherited from the S5 check and not validated, and its slave ranking is not an income ranking.
7. **Statutory liability, not tax paid.** The estimand is the statutory liability on recorded holdings. p.10 says the tithe fell on grain brought to market and that farmers declared about a third of their harvest; evasion and collection are outside the estimand.
8. **The primary drops the wine imputation.** This is a card reading of p.17, which describes no imputation. Keeping an imputation with a corrected constant was a defensible alternative; it is reported as S8 (1700 only).
9. **Ranking by slaves.** The top decile by slaves is not the top decile by wealth or income. The share of records with zero slaves (58–64% in the headline years) makes the tie rule material; the primary uses the expected value under random tie-breaking.
10. **H2 rests on secondary inputs.** De Kock's revenue and expenditure and the unsourced printed GDP cannot be verified in the project. The H2 rows check arithmetic only. Whether the P15 series measures the same quantity as the printed GDP (currency, price basis, coverage) is not established, so S18 is reported and not used.
11. **Unresolved data issues.** The 31 duplicates (F8) and the district-1 hearth-tax proxy (C13) are bounded only by S13 and S11.
12. **Image 9 coverage.** Only 1700 and 1773 decide verdicts; the intermediate years appear only in S15, so a non-monotone path cannot change any verdict.
