# Method card: P06_FGa, the settlers' fortunes (Cape vs early US tax censuses)

Status: v3 (2026-10-11), final revision after the Codex v1 review (reviews/P06_FGa_codex_S6card.md) and the v2 compliance check (reviews/P06_FGa_codex_S6card_v2.md), under AMENDMENTS.md A8/A8a. To be frozen with the commit message "FREEZE S6 card P06".

## Type of primary analysis

The primary analysis has three parts:
- **(i) Corrections** of verified code and data errors: C1/F1, N1/F2, N2/F3 and C2/F5.
- **(iii) Uncertainty propagation**, reported as assumption ranges. The valuation assumptions are enumerated; the enumeration never decides a verdict. Only the central scenario (§4.2) does.
- **Design-based inference** where the data contain a sample. Only Virginia is sampled.

It is not a new estimator (type iv). Odds ratios: none, so A4c does not apply. A4b does not apply, because the point estimates change.

## 1. Claims, interpretations and primaries (one primary per claim)

The eight `headline=1` rows (A1 union) carry six claims. Each is judged as the authors state it (claims_spec.md (b)–(c)). Each claim is classified under A8.

| Claim | Headline rows | Authors' wording | A8 class | Primary estimand |
|---|---|---|---|---|
| H1 income | `tx_p16_income_cape` 135.1, `tx_p16_income_us` 76 | "Cape farmers were, on average, more affluent"; "significantly better off" | comparative (A > B) | ln R₁, where R₁ = mean recorded agricultural income per farming household, Cape / (Maine + Massachusetts) |
| H2 crops + wine | `tx_p16_cropwine_cape` 190.8 (vs US $55.8 in the text) | crop output including wine and brandy is higher at the Cape | comparative | ln R₂, where R₂ = Cape mean (grain + wine + brandy value) / US mean grain value (Maine + Massachusetts) |
| H3 cattle | `tx_p13_cattle_cape` 33, `tx_p13_cattle_us` 5 | "Cape farmers owned, on average, 33 head of cattle. American farmers owned five." | comparative | ln R₃, where R₃ = mean cattle per farming household, Cape / US (Maine + Massachusetts + covered Virginia, design-weighted; §4.1) |
| H4 enslaved, headline pair | `T1_Virginia_enslaved` 0.74, `T1_Stellenbosch_enslaved` 0.58 | "the Gini for ownership of enslaved people in Virginia is 0.74", against Stellenbosch 0.58 (p.19) | comparative | Δ₄ = G(Virginia, covered farmers) − G(Stellenbosch farmers) |
| H4w enslaved, the authors' general wording | the same rows plus the Table 1 Cape rows | "more concentrated in Virginia than in the Cape districts (even including those at the frontier)" (p.19); "in America was more unequal" (abstract) | universal comparative ("every district") | Δ_d = G(Virginia, covered) − G(d), for each Cape district d ∈ {GR, Stb, Swe, Tul} |
| H5 crop inequality | `T1_GraaffReinet_crops` 0.95 | "crop output … more unequally distributed at the Cape" | universal comparative | Δ_dk = G_crops(d) − G_crops(k), for each Cape district d (4) and each US district k ∈ {Maine, Massachusetts}: 8 pairs |

**Levels.** The headline rows are also point levels (135.1, 76, 190.8, 33, 5, 0.74, 0.58, 0.95). Under A8 each is reported with its ±10% band (±0.03 for Ginis) as a **level check**. Level checks do not decide a verdict, because the claim the authors draw from them is comparative.

**Plausibility flag (A8).** For H1–H3, if the central estimate exceeds 1.5× the published magnitude on the estimand scale (ln R₁ > 1.5 ln 1.778, i.e. R₁ > 2.37; R₂ > 6.32; R₃ > 16.95), a separate **plausibility/comparability flag** is reported, linked to S5's concerns: Cape auction prices for mudden, 6% capitalisation, omitted US output and under-recording. **It does not decide the verdict.**

**Different estimands (reported, never verdict-determining).**
- Pooled-country Ginis.
- Unweighted means of district Ginis (the v1 H4b/H5b). These are new aggregations, not the household inequality the authors describe.
- Owners-only Ginis (the Fig 8 definition).

**Not testable.**
- Any comparison involving Virginia households outside the covered cells (§4.1). This includes "Virginia farmers" as the paper defines them: crop eligibility cannot be observed, because Virginia crops are structurally missing.
- "Amongst the most affluent in the world" (needs outside comparators).
- "Little indication of an imminent reversal of fortunes" (interpretive).
- Unmeasured output (US hay, dairy, non-farm income) and differential under-reporting. Every verdict therefore concerns **output as recorded in the tax censuses**.

## 2. Defects addressed

The following S5 findings are confirmed by both models (audit.md):
- (a) C1/F1: `prod()` sets wheat value to zero.
- (b) N1/F2: Maine and Massachusetts grain quantities are raw bushels × 100/35.2391, while prices are per bushel.
- (c) N2/F3: the farmer filter admits wine-only households, contrary to fn 45.
- (d) C2/F5: the printed US crop mean enters Virginia at zero.

Further defects:
- (e) C4: the valuation rests on single choices: the price set, the capitalisation rate, and Cape mudden priced at Cape auction prices.
- (f) C7/C10/F4: Virginia coverage. Grain and sheep are never recorded; Virginia farmer eligibility therefore rests on cattle; 1795 is wholly excluded; 32 of 2,447 households survive in 1805.
- (g) F6: the cattle means use all households, although the text says "farmers".
- (h) No uncertainty is reported anywhere.

Sources:
- JCGM 101:2008, on propagation; the card does not assign probabilities.
- Rao and Wu (1988), for the rescaling bootstrap under stratified sampling without replacement.
- Cowell and Flachaire (2007), on the sensitivity of Gini inference to tails.
- Lakens (2017), on prespecified bounds.

## 3. Estimands

**Original.** The published values from `FG Replication Code.txt`.

**New.** The §1 estimands on the corrected data (§4.1). Relation to the original, claim by claim:
- **H1, H2.** The same estimands as published (mean per farming household, local valuation in dollars). The central scenario values Cape output at **local Cape prices** (V3 = A), as the paper does: a nominal dollar income at the exchange rate.
  - The common-price scenarios (V3 = B, C) value Cape *physical* output at US prices. They measure a different concept, a common-price quantity comparison of the PPP type.
  - They appear only in the assumption range and are labelled as a different valuation concept.
- **H3.** The authors' *intended* population is farming households (the wording). The published number is an all-household mean (F6). The primary uses the intended population. The published-denominator value is a verification target and a diagnostic.
  - US: Virginia households carry design weight 1/0.20, so that the US mean represents the enumerated and sampled populations in proportion. Maine and Massachusetts carry weight 1.
  - The unweighted published pooling is a sensitivity.
- **H4, H4w.** The same Gini definition as Table 1: farming households, zeros included, `ineq::Gini(corr = FALSE)`. The Virginia population is restricted to covered households. **Scope:** Virginia "farmers" means cattle-owning households in benchmark years with cattle recorded. That is the only Virginia population the data identify.
- **H5.** The Table 1 dollar-valued crop Ginis, compared pair by pair. The district-mean and pooled versions are different estimands (§1).

## 4. Primary analysis

### 4.1 Corrected data and coverage (applied in every scenario)

**Source.** `FourieGarmenApril2020.xlsx`, sheet `Combined` (via `dpath("P06_FGa","original","20 FG Comparisons","Data",…)`), and `Prices.xlsx`, sheets `Final`, `Final2`, `Averages` and `US Decadal Averages`.

**Corrections.**
- **K1 (C1).** V_Wheat = Wheatreaped × PWheat, household by household.
- **K2 (N1).** For District ∈ {Maine, Massachusetts}, divide Wheatreaped, Barleyreaped, Ryereaped, Oatsreaped and Cornreaped by 100/35.2391. No other column changes.
- **K3, structural missingness.** For each District × census Year cell and each of the variables Wheat/Barley/Rye/Oats/Corn reaped, Cattle, Sheep and Slaves: the variable is **structurally missing** in that cell if more than 50% of its rows are NA. Otherwise it is **recorded**.
  - In recorded cells, NA = 0 (the code's convention).
  - In structurally missing cells, the variable is unknown and is never treated as zero.
  - The cell-by-variable map is written to `modern/output/coverage.csv` before any estimate is computed.
- **K4, farmer definition** (the paper's text, p.12 and fn 45: "at least one bushel … or who owned any livestock"). A farming household has at least **one bushel in common units** of any **recorded** grain, or Cattle > 0, or Sheep > 0 (both recorded).
  - **Common unit, frozen.** US quantities after K2 are bushels: the threshold is ≥ 1. Cape quantities are mudden, converted at κ = 2.8377569 bu/mud (1 mud = 1 hl; the same 100/35.2391 factor documented in N1/F2). The Cape threshold is therefore mudden ≥ 1/2.8377569 = 0.35239.
  - Comparison is on unrounded values. The factor is fixed; the alternative κ = 3.0 changes the Cape threshold to 0.3333 and is reported in §5.7.
  - Wine, brandy and horses do not qualify (fn 45).
  - The code's "> 0" rule is a sensitivity.
- **K5, coverage.** A household is **covered** for a claim if every variable that decides its eligibility and its outcome is recorded in its cell.
  - Virginia: grain and sheep are structurally missing everywhere (C7). Virginia households are covered for H3/H4/H4w only in cells where Cattle and (for H4) Slaves are recorded.
  - Uncovered households are excluded and counted. If fewer than 200 covered Virginia farming households remain, every Virginia contrast is not-testable. This floor's provenance is disclosed in §7 and §10.
  - **Coverage share (reported only; it gates nothing).** The number of Virginia sampled households in covered cells, divided by all Virginia sampled households. The denominator counts households whether or not they farm, so non-farming households are not confused with missing coverage. Farmers among covered households are reported separately.
- **K6 (C2, fn 59).** US = Maine + Massachusetts for H1, H2 and H5.
- **Pooling.** Benchmarks are pooled, as published. Household-years are the units (households cannot be linked across benchmarks).

**Verification rule** (before any modern output).
- (a) With K1–K5 switched off, the code's ">0 incl. wine" filter, all households for cattle, unweighted, and valuation at `Final` / r = 0.06 / V3 = A, the pipeline reproduces `repro_original/results_original.csv` for all eight headline rows to below 1e-9. This includes H3's published all-household population (33.457, 4.816).
- (b) With K1 + K2 only, it reproduces the S5 `wheat_units` values in `compare/s5_effects.csv` to below 1e-6.
- A failure stops the run and is logged in `modern/DEVIATIONS.md`.

### 4.2 Central scenario (the only verdict-determining scenario)

K1–K6, with the paper's own valuation choices: `Final` prices (1798–1802 Cape auctions; Stuart and Massachusetts US prices), r = 0.06, and Cape grain at Cape per-mud auction prices (V3 = A).

### 4.3 Sampling structure and inference

**Cape and US enumerations.** The four Cape districts (opgaaf) and Maine and Massachusetts (complete town lists) are **enumerations**. Their means and Ginis are finite-population quantities with **no design-based sampling error**. Their interval is the point itself. No inferential claim ("significantly") is made for contrasts between enumerated populations. Such a contrast is a population description, conditional on recording.

**Virginia** is "a random 20 per cent sample from each county" (p.20) of the counties transcribed.
- The implementer first inspects `Source`, `Veldcornet` and `Sourcenumber` for Virginia rows, to identify county. It reports the number of counties, the households per county and year, and whether any county-year has fewer than two sampled households.
- **Counties identified.** Strata = county × census year. Use the Rao–Wu rescaling bootstrap: resample n_h − 1 households with replacement within each stratum, rescaled with the finite-population correction f = 0.20.
- **Counties not identified.** Strata = census year, with the same bootstrap. The intervals are labelled **approximate (county strata unidentified)**.
- **Conditional inference.** The counties were not sampled at random. Inference is therefore conditional on the transcribed counties, with no extrapolation to Virginia as a whole. Geographic dependence beyond county strata cannot be modelled; this is stated.
- **Singleton strata (frozen).** A stratum with n_h = 1 (where n_h − 1 = 0) is collapsed with its neighbour before resampling: the next county in ascending identifier order within the same census year, or the previous county if it is the last. Collapsing repeats until every stratum has n_h ≥ 2. The FPC f = 0.20 is kept for the collapsed stratum. The collapses are listed in the output. If a census year contains only one covered household, that year is dropped from the bootstrap and the point estimate, and the drop is reported.
- **Coverage map in the bootstrap (frozen).** The structural-missingness map (K3) and the covered-cell set (K5) are computed **once** on the full data and held fixed across replicates. They describe the record-keeping, not the sample draw. Resampling is done within strata over all sampled Virginia households in covered cells, farmers and non-farmers alike. The K4 filter, the weights and the statistic are then recomputed in each replicate, so the number of farmers varies across replicates (domain estimation). Uncovered cells take no part in resampling.
- **Settings.** B = 9,999, seed 20261011 (L'Ecuyer-CMRG).

**Contrasts with a Virginia component** (H3, H4, and the four H4w pairs; H4's pair equals the H4w Stellenbosch pair). The enumerated side is held fixed. Each interval is the percentile interval (quantile type 7) of the replicate contrast.

**Multiplicity: one family, intervals only (Codex 6).**
- The family is the distinct verdict-bearing sampled contrasts: ln R₃, Δ(VA–GR), Δ(VA–Stb), Δ(VA–Swe) and Δ(VA–Tul). That is m = 5.
- All decisions use **Bonferroni simultaneous intervals at 1 − 0.05/5 = 99%**. No p-values or Holm steps enter any decision, so a significance call cannot conflict with an interval.
- H1, H2 and H5 have no sampled component and enter no family.

**Superpopulation bootstrap.** A household bootstrap of the enumerations (stratified by District × Year) is a labelled, model-based sensitivity. It never decides a verdict.

### 4.4 Assumption ranges (reported; not probabilities; never verdict-determining)

- **V1, Cape livestock price set** ∈ {`Final`; `Final2`, the early-eighteenth-century auctions}.
- **V2, capitalisation rate** r ∈ {0.03, 0.06, 0.10}, the same in both countries.
- **V3, Cape grain valuation** ∈ {A: Cape per-mud auction prices; B: US per-bushel `Final` prices × 2.8377569 bu/mud; C: the same × 3.0}.
- **V4, Cape wine price (H2)** ∈ {the four-auction mean in `Final`, $46.66608; Auction 1, 50.625 rd; Auction 3, 52.390625 rd}. The auction prices are converted at the workbook rate (3.931055/3.561536 rd per $).
  - Brandy has one auction price (124 rd) and stays fixed.
  - This limitation is stated: H2's brandy component carries no valuation range.
- **Scenario sets.**
  - H1: V1 × V2 × V3 = 18 scenarios.
  - H2: V3 × V4 = 9 scenarios.
  - H5: V3 = 3 scenarios. Crop Ginis are invariant to V1, V2 and V4.
  - H3 and H4 involve no valuation.
- **Reporting.** For each claim: the min, median and max of the estimand; and the **share of scenarios** meeting each verdict condition of §8, labelled "assumption-conditional (equal weights, not a probability)". The share depends on how the scenarios are enumerated: B and C are near-duplicates. It is therefore descriptive only and decides nothing.
- **Failures.** A scenario that yields a non-finite value is reported and counted as **not meeting** the condition. It is never dropped.
- **Separate reporting.** For each claim, a sensitivity line states whether the central verdict condition holds in all, some or none of the scenarios. That line is descriptive and does not modify the verdict in either direction.

### 4.5 Numerical and failure rules (frozen)
- Unrounded estimates are compared with exact bounds. Ratios are compared on the natural-log scale.
- Zero denominator (a group mean of 0, or no covered households): not-testable for that contrast.
- All-zero or single-household group (Gini undefined): not-testable for that contrast.
- Bootstrap replicates producing a non-finite statistic are counted. If more than 1% fail, the contrast is not-testable. Otherwise the failed replicates are reported and the interval uses the finite replicates.
- `ineq` version recorded. Gini with `corr = FALSE`, zeros included.

## 5. Sensitivities

**Admissible alternatives** (reported; not verdict-determining, A4d):
1. Each V-item varied alone around the central scenario (a tornado table, H1, H2, H5).
2. US grain prices from the Wright decadal averages, matched to the household's benchmark decade. The `Final` price fills empty cells.
3. Each single Cape auction as the Cape livestock price set (`Averages`, Auction1–4; the four-auction mean fills missing items).
4. The Rothenberg US cattle price ($15.29) in place of Stuart's ($16.32).
5. Cape cattle and sheep × 2, the probate–opgaaf gap on p.11 (H1, H3). Also the **break-even** under-recording multiplier on US recorded output, and the break-even omitted US output in dollars, at which R₁ = 1. These are reported as thresholds.
6. Income including wine and brandy; income including horses.
7. Grain eligibility: the code's "> 0" rule instead of "at least one bushel" in common units; and κ = 3.0 instead of 2.8377569 in the Cape threshold (0.3333 mud).
8. H3 unweighted (the published pooling).
9. Like-for-like Virginia comparison: Cape districts restricted to cattle-owning households, matching Virginia's observable eligibility (H3, H4, H4w).
10. Owners-only Ginis (the Fig 8 definition); pooled-country Ginis; district-mean Ginis (different estimands, §1).
11. Crop Ginis on physical quantities, with Cape mudden × 2.8377569 (a definition change).
12. Benchmark-by-benchmark estimates of every claim.
13. Gini tail influence: drop the top 1% of households by outcome, and drop the 10 largest households, in each district (Cowell–Flachaire).
14. The superpopulation household bootstrap of the enumerations (§4.3).
15. The livestock-value Gini by district (the abstract's livestock clause, which has no headline row and gets no verdict).

**Diagnostics only** (they reintroduce known errors or unsupported data and are never alternatives):
- D1 each correction K1/K2 switched off;
- D2 the original filter, which admits wine-only households;
- D3 Virginia entered at zero crop value (the published $55.8 denominator);
- D4 H3 with the published all-household denominator;
- D5 Virginia's uncovered households (the 1795 cells and others) treated as zero instead of unknown;
- D6 the original-code pipeline (verification target).

## 6. Fixed choices
- The seven districts as in `Combined`.
- Design weights only as in §3 (H3). No other weights.
- No trimming in the primary.
- Prices other than V1–V4 fixed at `Final`.
- The enslaved under-16 price (F7) is out of scope (Fig 7 and p.17, not a family member).
- Missingness, coverage and multiplicity as in §4.

## 7. Margins (A8 defaults; no card-chosen bands)
- **Comparative ">"** (H1, H2, H3, H4, every H4w pair, every H5 pair): A − B > 0, with the interval excluding 0 (the ratio scale for H1–H3: ln R > 0).
  - For enumerated contrasts the interval is the point (§4.3).
  - For sampled contrasts it is the Bonferroni 99% interval.
- **Credible null** = "similar" under A8:
  - ratios: the interval lies within ln [0.80, 1.25] = [−0.2231, 0.2231];
  - Ginis: the interval lies within ±0.03.
- **Precedence between direction and similarity (frozen, symmetric).** A directional result takes precedence. An interval entirely above 0 supports ">" (confirmed); an interval entirely below 0 supports the reverse (overturned, reversed). This holds even when the interval also lies inside the similarity band. A credible null applies only when the interval **contains 0** and lies entirely within the band.
  - For enumerated contrasts (degenerate intervals) a credible null therefore arises only when e = 0 exactly.
  - When a directional verdict has its interval inside the similarity band, it carries a non-deciding **"negligible magnitude"** flag.
- **No upper ceiling.** The v1 ceiling of 1.5|b₀| is deleted. Exceeding it triggers only the plausibility flag (§1).
- **Level checks** (§1): ±10% of |X|, or ±0.03 for Ginis. Reported only.

**Disclosure.** The following S5 numbers bearing on these verdicts were seen before this card was written (audit.md; `compare/s5_effects.csv`; reviews/P06_FGa_codex_S5.md):
- **Income after K1 + K2:** Cape $223.06 vs US $33.60 (R₁ = 6.64). Conservative prices: $180.25. At r = 3%: 174.2 vs 29.7. At r = 10%: 288.2 vs 38.8. With the wine-only fix: Cape $225.62. Original-code break-even rates: 2.06% and 3.92%.
- **Crops + wine after K1 + K2:** Cape $278.72 vs US $25.80.
- **Crop Ginis after K1:** GR 0.927, Stb 0.856, Swe 0.700, Tul 0.741, Maine 0.605, Massachusetts 0.726.
- **Enslaved Ginis (code filter):** VA 0.741, Stb 0.575, GR 0.831, Swe 0.745, Tul 0.655. Owners only: VA 0.554 vs Cape 0.462–0.473. Pooled farmers: 0.734 vs 0.741. All households: 0.805 vs 0.796.
- **Virginia coverage (F4):** all 2,377 households excluded in 1795; 32 of 2,447 survive in 1805.
- **Cattle:** farmer means 51.84 vs 8.18; all-household means 33.46 vs 4.82.

**Not seen:** V3 = B/C, V4, `Final2` × r ≠ 0.06 after the corrections, any covered-sample or K4 ("≥ 1") estimate, the design-weighted H3, and every bootstrap interval.

The margins are the A8 defaults and involve no author choice. Two gates remain, and both were set **knowing** the F4 Virginia counts above:
- the 200-household coverage floor (K5);
- the 50% structural-missing rule (K3).

The v2 gates that were removed are the 50% coverage-share gate and the majority thresholds for universal claims. They were also chosen with S5 numbers in view. v3 replaces them with gate-free rules: coverage share is reported only, and universal claims use conjunction rules (§8). The common-unit factor in K4 is the S5-documented N1/F2 factor. This disclosure does not prove that nothing was tuned.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)

`strengthened` is not reachable. The upgrade corrects errors and narrows scope; it does not supply a more credible design for the same estimand.

### Comparative claims (H1, H2, H3, H4) and each pair of H4w and H5
e is the central-scenario estimate (§4.2). I is its interval (§7: degenerate for enumerated contrasts; Bonferroni 99% for sampled contrasts). No other scenario enters.

| # | Condition | Verdict |
|---|---|---|
| 0 | any §4.5 failure rule applies, or (Virginia contrasts) covered households < 200 | not-testable |
| 1 | I entirely below 0 | overturned (reversed) |
| 2 | I entirely above 0 | confirmed |
| 3 | I contains 0 and lies entirely within the credible-null band | overturned (credible null: similar) |
| 4 | I contains 0 and is not entirely within the band | weakened |

**Exhaustiveness.** I is either entirely below 0 (row 1), entirely above 0 (row 2), or contains 0 (rows 3–4).

**Symmetry.** Rows 1 and 2 mirror each other, and the similarity band applies only to intervals that contain 0 (§7). `qualified` is not reachable for single comparisons: there is no magnitude claim (A8 comparative class) and no subset gate.

Each verdict also reports:
- the plausibility flag (§1);
- the negligible-magnitude flag (§7);
- the assumption range, shares and sensitivity line (§4.4);
- the Virginia coverage share (K5);
- the scope note "recorded output only".

### Universal claims (H4w: 4 required pairs; H5: 8 required pairs): conjunction rules
Each pair gets its verdict from the table above. The claim states that **every** pair satisfies ">".

| # | Condition | Verdict |
|---|---|---|
| 0 | no pair testable | not-testable |
| 1 | at least one pair overturned (reversed or credible null): a decisive counterexample | overturned |
| 2 | every required pair confirmed | confirmed |
| 3 | every testable pair confirmed, at least one pair not-testable | qualified (partial coverage; at most qualified) |
| 4 | otherwise: no decisive counterexample, and at least one pair weakened | weakened |

**Exhaustiveness.** Row 1 covers any overturned pair. If no pair is overturned, every pair is confirmed, weakened or not-testable. All confirmed is row 2. Confirmed plus not-testable is row 3. Any weakened pair is row 4. No pair testable is row 0.

The counterexample pairs are named in the output. The H5 pairs are all enumerated contrasts in the central scenario (V3 = A), so their intervals are degenerate.

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 8 required changes. AMENDMENTS.md A8 was applied at the same time. Responses:

1. **Results-informed ceiling.** Deleted from every verdict (§7). Exceeding 1.5× the stated magnitude now triggers only a plausibility/comparability flag that does not decide the verdict (§1, A8).
2. **Scenario-share inference.** Removed. Verdicts rest on one designated central scenario (§4.2), with design-based intervals where a sample exists (§4.3). Enumerations report the range and the share meeting each condition, labelled assumption-conditional and not probabilities. They never affect a verdict (v3: the v2 min–max downgrade is removed). A credible null now requires the interval to lie within the A8 similarity band, not 80% of scenarios (§7, §8).
3. **"Same estimand" assertion.**
   - District-mean and pooled Ginis are reclassified as different estimands and are not verdict-determining (§1, §3).
   - H4w and H5 are judged pair by pair against the authors' wording.
   - V3 = B/C is explained as a common-price quantity concept, distinct from local valuation and range-only (§3).
   - H3's intended farmer population is separated from the published all-household denominator (§3, verification (a), D4).
4. **Coverage before bootstrapping.**
   - Structural missingness is separated from recorded zeros (K3).
   - Coverage is defined, and comparisons are restricted to covered households (K5), with a coverage floor and not-testable otherwise.
   - Virginia "farmers" as the paper defines them are not-testable (§1).
   - Eligibility follows the text's "at least one bushel" (K4), with "> 0" as a sensitivity.
5. **Sampling structure.**
   - The enumerations carry no design-based error and get no inferential claim.
   - For Virginia, county identification is verified first, followed by the Rao–Wu rescaling bootstrap with FPC f = 0.20 in county × year strata, or year strata labelled approximate.
   - Inference is conditional on the transcribed counties. Repeated households and geographic dependence are stated as limits.
   - Unweighted pooling is replaced by design weights for H3, with unweighted pooling as a sensitivity (§4.3, §3).
6. **Multiplicity.** One family (m = 5 sampled contrasts). Decisions use Bonferroni simultaneous 99% intervals only, with no Holm or p-value step. H5 has no sampled component. The "weakest across V3" rule is replaced by the central scenario alone (v3; §4.3, §8).
7. **Numerical and failure rules.** Frozen in §4.5:
   - unrounded estimates against exact bounds;
   - quantile type 7, B = 9,999;
   - zero-denominator, undefined-Gini and failed-replicate rules.

   Verification (a) recovers H3's published all-household population. Failed scenarios count against support and are never dropped (§4.4).
8. **Diagnostics vs alternatives.** Split in §5. Error-reintroducing variants (D1–D6, including Virginia as zeros) are diagnostics only. A wine-price range V4 is added for H2, and the fixed brandy price is stated as a limitation.

Optional suggestions adopted: Gini tail-influence diagnostics (§5.13); break-even under-recording and omitted-output thresholds (§5.5).

### v2 compliance check (reviews/P06_FGa_codex_S6card_v2.md): 6 blocking issues
1. **Central-only.** All min–max downgrades are removed. Only the central scenario decides (§8). Assumption sensitivity is reported separately as a descriptive line that changes no verdict in either direction (§4.4).
2. **Universal claims.** Conjunction rules (§8): confirmation needs every required pair; one reversed or credible-null pair overturns; a missing pair caps the claim at qualified.
3. **Direction vs similarity overlap.** Frozen precedence (§7): direction first, symmetric for both signs. The credible null applies only to intervals that contain 0. Directional results inside the band get a non-deciding negligible-magnitude flag.
4. **Gates.** The 50% coverage-share gate and the majority thresholds are deleted. The remaining gates (200-household floor, 50% structural-missing rule) are disclosed with their provenance (§7, §10). The coverage denominator now counts all sampled households in covered cells against all sampled households, and is reported only (K5).
5. **Eligibility units.** Common-unit conversion frozen: Cape threshold 1/2.8377569 mud, the N1 factor (K4). κ = 3.0 is a reported sensitivity.
6. **Bootstrap.** Singleton strata are collapsed with a neighbouring county, with FPC retained; single-household years are dropped and reported. The coverage map is computed once and held fixed; resampling covers all covered households, and the filter is recomputed in each replicate (§4.3).

## 10. Known limitations at freeze
1. **The 200-household Virginia floor** (K5) was fixed after seeing the F4 counts. It is a minimum for a stable Gini, not derived from a power calculation. It can only make a Virginia contrast not-testable, never change its direction.
2. **The 50% structural-missing threshold** (K3) is a convention fixed after seeing S5. Cells with intermediate NA shares (if any) are listed in `coverage.csv`.
3. **Degenerate intervals for enumerations.** A8's comparative rule then confirms any positive difference, however small. The negligible-magnitude flag reports this but does not decide. A8 provides no magnitude floor for comparative claims, and the card adds none.
4. **County identification for Virginia** is unknown before the run. If counties cannot be identified, the intervals are labelled approximate. Inference is conditional on the transcribed counties, and repeated households across benchmarks cannot be linked.
5. **Virginia eligibility** rests on cattle alone, so the Virginia "farmer" population differs by construction from the Cape's. The like-for-like comparison (§5.9) is reported but does not decide.
6. **Brandy** has a single auction price, so H2 carries no brandy valuation range.
7. **Unmeasured output and differential under-recording** cannot be priced. All verdicts concern recorded output (§1); the break-even thresholds (§5.5) are reported.
