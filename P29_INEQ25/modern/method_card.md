# Method card: P29_INEQ25, inequality in the Cape Colony, 1685–1844

Status: v3 (2026-10-11), the final revision. It fixes the blocking issues in the Codex compliance check (reviews/P29_INEQ25_codex_S6card_v2.md) and is to be frozen with the commit message "FREEZE S6 card P29".

## 0. Type of analysis
The primary analysis is **one corrected central analysis**. It is (i) a correction of verified code and data errors, with (iii) sampling-uncertainty quantification, under the paper's own valuation choices. It is not (ii), an inference-only upgrade, and not (iv), a new estimator: the estimator, an unweighted household Gini of holdings with zeros included, is the author's.

**Corrections, applied in the central analysis.**
- Fig 2 is rebuilt as price-weighted value instead of a sum of raw quantities (S5-06/07, F01).
- Figs 1 and 2 are computed from the data, not from the script's run-order state (S5-04, F10).
- Bethelsdorp uses the 1814 sheet that the text describes (S5-16, F05).
- Swartrivier sheep, constructed at l.2660 and then omitted, is included (2026 audit item 4, verified by inspection).

The point estimates change, so A4b does not apply. The paper makes no OR or probability claims, so A4c does not apply.

**Inferential verdicts rest only on the central analysis and its multiplicity-adjusted intervals (§4, §8).** The price factorial (§5A) is supplementary. Following A8, it is reported as a range and as the share of scenarios that meet each condition. Those equal-weight shares are assumption-conditional robustness summaries, not probabilities, and they never set a verdict. Changed estimands and changed populations (§5B) are reported separately and cannot set a verdict either (S6, A4d).

## 1. Claims family (headline rows, frozen at S0) and interpretations
The paper is purely descriptive, so every margin is the A8 default for the wording type.

- **H1** (`txt_p8_concl_gini`), a threshold claim with "consistently".
  - The claim: "Measured through ownership of agricultural assets, inequality among households consistently exceeded Gini coefficients of 0.6 – a threshold typically associated with severe levels of inequality" (p.8).
  - The quantitative referent is the total-value basket for settler census households in the Stellenbosch-Drakenstein opgaafrolle (p.4, Fig 1).
  - Margin: G_d > 0.60 at **every** decade node d.
- **H2** (`txt_p5_zero_gini`), a point claim.
  - The claim: "the Gini coefficient rises steeply, reaching 0.92 by the late eighteenth century" (p.5), for the scenario in which enslaved men are separate zero-asset households.
  - It is judged on the 1780 twenty-year period (1780–1799). Margin: [0.89, 0.95], which is 0.92 ± 0.03.
- **H3a** (`txt_p8_beth_cattle`), a point claim.
  - The claim: "Aside from cattle in Bethelsdorp with a Gini of 0.72" (p.8).
  - Margin: [0.69, 0.75].
- **H3a-x**, reported separately and not verdict-setting. This is the "exception" reading of the same clause, that Bethelsdorp cattle is the asset below 0.75. It is tested as a threshold, G < 0.75, using the H3a interval.
- **H3b** (same sentence, `txt_p8_khoe_min`), a threshold claim.
  - The claim: "all other assets have Gini coefficients above 0.75."
  - Margin: G_j > 0.75 for every other asset j.

**Scope.** These are Ginis of agricultural holdings (a mix of stocks and flows; land and financial assets excluded) over census entries, not linked unique individuals. Nothing here concerns comparability with modern income Ginis, which the paper itself disclaims.

**Secondary outputs (reported, never verdicts), computed with the central machinery:**
- **S-a.** All four Fig 2 scenarios, price-weighted. This includes the intro claim "as large as the overall Gini" as a comparative claim under A8: the difference between the zero-asset and settlers-only Ginis by period, with "similar" meaning within ±0.03.
- **S-b.** The 12-sheep scenario against "0.89 to 0.91".
- **S-c.** The 18th-century basket range against "0.6–0.75".
- **S-d.** Fig 5 at owner level:
  - valuation is summed per owner (`Owner_surname` + `Owner_name` + `District_name`);
  - owners only, and with non-owners added under {the uniform 30% share as coded, the 1825 district ownership shares};
  - owner-cluster bootstrap;
  - a matched-owner valuation vs compensation comparison (owners with both recorded), which addresses F02's mismatched denominators.
- **S-e.** The combined Khoe + Swellendam settler Ginis with the filter fixed (S5-01).
- **S-f.** Probate Ginis with the legend corrected and the eight date-like counts set to NA (S5-15).
- **S-g.** Top shares (S5-11).

## 2. Defects addressed
- Fig 2 sums raw units (S5-06, F01), and its text and figure disagree (S5-07).
- Fig 1 depends on run order (S5-04, F10).
- Bethelsdorp uses the wrong vintage (S5-16, F05).
- Swartrivier sheep is omitted (2026 audit item 4).
- The paper reports no uncertainty anywhere.
- Documented but not "fixed" in the central analysis, because the paper gives no rule: the basket omits vines (five priced assets against the stated six; S5-05, F04), and the endpoint years 1685–89 and 1840–44 are dropped because they have no prices (6,591 household-years, F04).

Sources:
- Davidson (2009, *J. Econometrics*), on Gini inference;
- Cameron, Gelbach and Miller (2008) and Cameron and Miller (2015, *JHR*), on cluster resampling and shared shocks;
- Montiel Olea and Plagborg-Møller (2019, *J. Applied Econometrics*), on sup-t bands;
- JCGM 101:2008, for the logic of propagation (applied here only as enumeration, with no joint probability model);
- Alfani and Ryckbosch (2016, *EEH*), on historical wealth Ginis.

## 3. Estimands
The original estimands are those printed in the paper. The new central estimands are as follows.

- **H1.** The decade-pooled Gini (decade = floor(year/10)·10) of v = horses·p_horses + cattle·p_cattle_breeding + sheep·p_sheep + wheat_vol·p_wheat_vol + wine·p_wine.
  - Population: all Stellenbosch-Drakenstein census rows after the code's 19 manual deletions.
  - Prices: decade prices from `price_series.xlsx`.
  - Nodes: decades 1690–1830, i.e. **years 1690–1839, not 1685–1844**.
  - This is the estimand of the printed Fig 1, a **five-asset basket**. The paper's "six assets" is not implementable without a vine price that the data lack. The discrepancy is recorded as a qualification of the claim's wording, and it is not resolved by assumption.
- **H2.** As H1, but over all census rows plus one zero-value row for each enslaved man (`slave_men`), with owners' wealth excluding enslaved people (as coded). The node is the 1780 period, pooled over 1780–1799. Relative to the printed Fig 2 this is a corrected estimand, because the printed figure is a Gini of summed raw counts. It is the "total valued wealth" estimand that the text and the R1 response describe.
- **H3a, H3b.** Single-asset Ginis across household rows within each settlement:
  - Bethelsdorp: the 1814 `Bethelsdorp` sheet of `EBTstation.xlsx`;
  - Groenekloof: `Groenekloof.xlsx`;
  - Swartrivier: `Swartrivier.xlsx`.

  Variable mappings follow l.2540–2717. The assets are cattle (`cattle_breeding`), horses (saddle + breeding), oxen (`cattle_oxen`), sheep and wheat reaped. An asset enters H3b if its column exists in that sheet. Sheep is defined as follows:
  - Groenekloof: wethers + breeding + Spanish;
  - Swartrivier: wethers + breeding;
  - Bethelsdorp: `sheep_goats`.

The variants in §5B change the estimand (aggregation, the wealth basket) or the population (coverage, trimming). They are labelled as such.

## 4. Primary analysis: the central analysis
**Data handling.**
- Asset count NA → 0, as coded (see §5C for the alternative).
- A row with a missing price is dropped from the basket, as coded.
- H1 and H2 use one consistent population base: all census rows. This fixes the base mismatch of S5-06.

**Bootstrap design and what it means.** The superpopulation is a hypothetical repeated draw of households from the process that generated Stellenbosch-Drakenstein (or settlement) holdings in the same period, holding census coverage, recording practice and prices fixed. The intervals capture variability due to the finite number of households and the dependence within a household over time. They **do not** capture transcription error, unrecorded or missing assets, missing census returns, or price uncertainty. These are addressed only descriptively, in §5.

- **H1, H2: household-cluster bootstrap.**
  - Clusters are `hhid_ext_safe`. Rows with a missing id are singleton clusters.
  - Complete household histories are resampled with replacement over the whole panel. All assets of a row are resampled jointly, so each replicate is a valid joint draw across nodes.
  - H2's synthetic zero rows stay attached to their owner's cluster and are regenerated from the resampled owner rows.
  - Independence across households is assumed. Households in the same census year share price, harvest and recording shocks, and prices enter the decade value. §5C reports a year-block diagnostic for this.
  - Reported per node: number of clusters, mean and maximum cluster size, the share of rows with a missing id, and the number of positive holders.
- **H3: iid household resampling, stratified by settlement.** One replicate resamples all three settlements jointly, and all assets of a household together.
- **Replications and Monte Carlo precision.**
  - B = 9,999, seed 20261011, RNG L'Ecuyer-CMRG. This gives about 62 draws in each 0.625% tail.
  - The Monte Carlo SE of each interval endpoint is estimated by splitting the draws into 10 batches.
  - If any verdict-relevant endpoint has MC SE > 0.002, or lies within 2 MC SE of a margin boundary, B is raised to 39,999 (same seed) and the result is reported.
- **Intervals.**
  - Multiplicity family: {H1, H2, H3a, H3b}, Bonferroni, α = 0.0125 (98.75%, two-sided). Quantiles use R type 7.
  - H2 and H3a: percentile intervals.
  - H1 (across decade nodes) and H3b (across assets): sup-t simultaneous bands.
    - se_d is the bootstrap SD.
    - c is the 98.75% quantile of max_d |G*_d − G_d|/se_d, over nodes with se_d > 0.
    - The bounds are L_d = G_d − c·se_d and U_d = G_d + c·se_d.
- **Failed draws and the joint-draw rule.** Failed draws are never silently discarded; every count is reported.
  - A replicate Gini is *undefined* when the replicate holds no positive value for that node (all zeros give 0/0, NaN in `ineq::Gini`), or when it is non-finite for any other reason.
  - **Families.** H1 is one family (all its decade nodes), H3b is one family (all its assets), and H2 and H3a are one-node families.
  - **Common rule.** A draw b is *jointly valid* for a family when every node in that family has a defined Gini in b. All family-level quantities use **only the jointly valid draws, the same set for every node in the family**: se_d, the sup-t critical value c, the percentile endpoints and the Monte Carlo SE. A draw is never used for some nodes and dropped for others.
  - **SD.** se_d is the sample SD (n − 1 denominator) of G*_d over the family's jointly valid draws. The sup-t statistic for draw b is max_d |G*_{d,b} − G_d|/se_d, taken over the nodes with se_d > 0. c is its type-7 98.75% quantile over the jointly valid draws.
  - **Family-level failure policy.** Let V be the number of jointly valid draws.
    - If V ≥ 0.99·B, intervals are computed on those V draws.
    - If V < 0.99·B, the family's intervals are **undefined**, and every claim that depends on the family is not-testable (§8 row 0).
    - The 39,999-draw escalation does not apply to an undefined family, because failure rates do not fall with B.
  - **Zero-SE nodes.** A node with se_d = 0 is left out of the max, and its bounds are L_d = U_d = G_d (flagged). If **every** node in a family has se_d = 0, c is not computed, all bounds equal the point estimates, and the report flags this. The verdict rules then apply to the points.
  - **Monte Carlo SE of an endpoint (batch estimator).**
    - The jointly valid draws, in draw order, are split into K = 10 consecutive batches of floor(V/10) draws each; any remainder is left out of this calculation only.
    - In each batch k, the endpoint is recomputed by the same algorithm: for H1 and H3b, se_d, c and L_d/U_d within the batch, with G_d fixed at the full-sample estimate; for H2 and H3a, the percentile endpoints.
    - MC SE = SD_k(endpoint_k)/√10.
    - The escalation rule above (MC SE > 0.002, or within 2 MC SE of a margin boundary, → B = 39,999 with the same seed) applies to these values.
  - **Provenance of the 1% cutoff (disclosure).** The card author set it in v2 as a conventional small tolerance for failed draws. No bootstrap had been run, and no S5 result informed it. The author did know at the time that only one Groenekloof family owns sheep: that is a paper statement (`txt_p8_groen_sheep`), also cited in §5C. The author did not work out its consequence, and the Codex v2 compliance check pointed it out.
    - With one positive holder among n = 108 households, an iid replicate contains no holder with probability (1 − 1/108)^108 ≈ 0.37.
    - The Groenekloof sheep node therefore fails in about 37% of draws, so V < 0.99·B for the H3b family.
    - **Under this frozen rule, H3b is expected to be not-testable, and so is the H3 summary** (not-testable ranks lowest in §8).
    - H3a, a separate one-node family, is unaffected and keeps its own verdict, which is reported.
    - The rule is kept unchanged at the freeze: changing it now would be informed by the consequence just computed. The report-only analysis S-h (§5C) supplies the information instead. See also §10.
- **Checks before any verdict.** With the corrections switched off (raw-unit Fig 2, 1825 Bethelsdorp sheet, no Swartrivier sheep), the script reproduces the S2 values to < 1e-6 (Fig 1 nodes, Fig 2 lines, Fig 6 points). It also checks that one synthetic zero row is added for each enslaved man (per-year totals equal Σ `slave_men`).

## 5. Supplementary analyses (exhaustive; reported, never verdict-setting)
**5A. Same-estimand price factorial (A8 range and share).** The five-asset basket of the central analysis is kept, and only the prices change.
- Each scenario gives point estimates only, computed on the full data, with no bootstrap.
- For each claim the report gives the range across scenarios and the share meeting the claim's point condition (inside the band, or above the threshold).
- The items are:
  - **V3, cattle:** V3a `cattle_breeding` (central); V3b the mean of breeding, bull and work prices.
  - **V4, prices:** V4a decade prices (central); V4b constant prices, each asset's mean over the 1690–1830 decades.
- That gives 2 × 2 = 4 scenarios each for H1 and H2. H3 has no valuation items.

**5B. Changed estimand or population.**
- Every item is varied **one at a time** from the central analysis, with all other choices at their central levels (decade prices V4a, breeding-cattle price V3a, vines excluded).
- Every item gives **point estimates only**, on the full data, with no bootstrap.
- Results are labelled and never pooled with 5A.

Items:
1. **V2, vine inclusion: a basket change, so a different estimand** (a six-asset basket against the central five-asset basket). It is reported separately for each level:
   - V2b, one year's yield value: vines × (Σ wine / Σ vines over the decade's rows) × p_wine. The yield is computed once on the full data for each decade. V2b counts the same wine flow twice (vines plus wine) and is flagged for double counting.
   - V2c, 0.5 rix-dollars per vine (the undocumented 2026 rule). V2c is **exploratory**.
2. **V1**, coverage: years 1685–89 and 1840–44 priced at the nearest decade price (1690 and 1830) under the central decade prices. This adds nodes 1680 and 1840 if each has ≥ 100 rows. This is the only V1 price regime; the constant-price variant of v2 is withdrawn.
3. **V5**, aggregation: the mean of annual Ginis (the Fig 1 caption) in place of the pooled Gini.
4. **V6**, trimming:
   - A component > 10 × that year's 99th percentile of positive values is set to NA, and the row is dropped. This drops households.
   - **The thresholds are computed once on the full data and are not recomputed within draws.** No bootstrap is run for V6, and in the central analysis no draw is trimmed.
5. **V7**, expanded wealth basket for H2: enslaved people in owners' wealth at 200 × p_sheep (V7b), or at MOOC10 category prices (V7c).
6. A settler-only population (`settler_men > 0` or `settler_women > 0`), for H1 and H2.
7. H2 in the 1760 and 1800 periods.
8. H2 with all enslaved adults as zero-value rows.
9. H3 with the code's `Bethelsdorp1825` sheet.
10. H3b without Swartrivier sheep (the plotted set).
11. Vines capitalised at 6%: a basket change, exploratory (the paper's rate for enslaved people, borrowed here).

**5C. Missingness, influence and diagnostics.**
1. **Missingness.**
   - Share of NA by asset and decade (and by settlement for H3), with the NA→0 rule documented as the code's convention. The opgaafrolle record no explicit zeros, so a blank is read as "none recorded".
   - Report-only alternative (a): rows with every asset NA are dropped as unrecorded.
   - Report-only alternative (b): complete cases for the basket.
2. **Influence.**
   - Leave-one-cluster-out change in each node Gini: the maximum |ΔG| and the identity (row id, year) of the ten most influential households.
   - For H3, the number of positive holders per asset. Assets with fewer than 10 positive holders are flagged, because their Gini is close to 1 by construction (e.g. Groenekloof sheep, one holder).
3. **Diagnostics only (never inferential alternatives).**
   - iid household-year resampling;
   - the raw-unit Fig 2 with the central bootstrap, which isolates the effect of the correction;
   - a year-block bootstrap (census years resampled within decades, households kept intact within years), to gauge shared year shocks.
4. **S-h, H3b on well-supported assets (report only; it never sets the H3b verdict).**
   - H3b is recomputed over the assets with ≥ 10 positive holders (the influence flag in item 2), using the central bootstrap and the §4 joint-draw rule. The ≥ 10 rule was declared in v2, before the 1% consequence was known.
   - The excluded assets are reported as points, with their holder counts.
   - The same analysis is repeated with the zero-replicate convention G* = 0 for undefined draws. This is a convention, not an estimate.

## 6. Fixed choices
- No weights.
- Zeros are included.
- `ineq::Gini(x)`, with no small-sample correction.
- Twenty-year periods start at 1680, and decades are floor(year/10)·10.
- Verdict comparisons use unrounded values; results are reported to 3 dp.
- The boundaries are those given in §8.

## 7. Margins (A8 defaults; none chosen by the card author)
| Claim | Type | Margin |
|---|---|---|
| H1 | threshold, "consistently" | G_d > 0.60 at every decade node 1690–1830 |
| H2 | point (0.92) | [0.89, 0.95] |
| H3a | point (0.72) | [0.69, 0.75] |
| H3a-x (reported) | threshold, "below" | G < 0.75 |
| H3b | threshold, "all other" | G_j > 0.75 for every j |

The bands are closed, and the thresholds are strict ("exceeded", "above").

## 8. Verdict rules (central analysis only; the first rule that applies decides; exhaustive)
**Point claims H2 and H3a.** Band B = [b_lo, b_hi]; central estimate G; 98.75% interval I = [L, U].

| # | Condition | Verdict |
|---|---|---|
| 0 | G is not computable, or I is undefined (§4) | not-testable |
| 1 | containment: b_lo ≤ L and U ≤ b_hi | confirmed |
| 2 | disjoint below: U < b_lo | overturned (credibly below the stated value) |
| 3 | disjoint above: L > b_hi | overturned (credibly above the stated value; the direction of inequality holds, and this is noted) |
| 4 | overlap, G ∈ B | qualified (consistent but imprecise) |
| 5 | overlap, G ∉ B | weakened |

Containment requires **both** inequalities, b_lo ≤ L **and** U ≤ b_hi; the band is closed, so equality on either side is allowed. Disjointness is strict (U < b_lo, or L > b_hi). Every other case is overlap: in particular U = b_lo, or L = b_hi, with the interval reaching outside the band. Rows 1–5 are therefore mutually exclusive and exhaustive whenever row 0 does not apply. For a one-node family whose se = 0 (§4), L = U = G, and the same rules apply.

**Threshold claims H1 and H3b.** Threshold T (0.60 for H1, 0.75 for H3b); simultaneous bounds [L_d, U_d] over the claim's nodes or assets.

| # | Condition | Verdict |
|---|---|---|
| 0 | any required node is undefined, or the central analysis is not computable | not-testable |
| 1 | supported failure: U_d ≤ T for at least one d | overturned |
| 2 | supported exceedance: L_d > T for every d | confirmed |
| 3 | uncertain, all G_d > T | qualified (inference-fragile) |
| 4 | uncertain, some G_d ≤ T | weakened |

Exactness: L_d = T does not count as exceedance (the inequality is strict). U_d = T counts as supported failure.

**H3a-x (reported, no verdict):** supported if U < 0.75, refuted if L ≥ 0.75, uncertain otherwise.

**H3 summary:** the weaker of H3a and H3b, ordered not-testable < overturned < weakened < qualified < confirmed. Member verdicts are reported. H1, H2 and H3 are reported separately and not aggregated.

**Supplementary display.** Next to each verdict the report gives the §5A range and share (price factorial only; vine variants are in §5B), labelled "assumption-conditional; equal weights are not probabilities". The §5B and §5C results are listed by item. None of them changes a verdict.

**Disclosure.** S5 and the earlier audits have already produced the following numbers that bear on these verdicts.
- **H1.**
  - Fig 1 central-equivalent nodes: 0.658–0.829 for 1700–1830, and about 0.74 in 1690.
  - Top-to-bottom run: 0.818–0.901.
  - Vines at one year's yield: maximum change +0.029.
  - Cattle at the mean price: 0.652–0.742 (18th c.).
  - Mean of annual Ginis: 0.655–0.733.
  - Rebuild minimum: 0.6501.
  - 2026 WP (0.5 rix-dollars per vine): 0.74–0.93.
- **H2.** Zero-asset 1780: raw 0.975; price-weighted 0.925 pooled, 0.923 as a mean of annual Ginis.
- **H3a.** Bethelsdorp cattle: 0.695 on the 1814 sheet, 0.718 on the 1825 sheet.
- **H3b.**
  - Bethelsdorp 1814: horses 0.976, oxen 0.985, sheep 0.992.
  - Minimum of the other plotted assets: 0.753 (Groenekloof horses).
  - Swartrivier sheep: not computed.
- **Secondary.**
  - Fig 5 owner level: 0.421–0.649; with non-owners, 0.842–0.952 (30% share) or 0.759–0.947 (1825 shares).
  - Combined Khoe + settler: 0.849, 0.740, 0.714, 0.800.
  - Probates: minimum 0.667; minimum from 1770 is 0.697.
  - Top 1%, 1800–30: 13.6.

No bootstrap interval has been computed. All margins are the A8 defaults, so the card author chose none of them. The 0.695 point estimate lies 0.005 inside the H3a band, which makes H3a sensitive to interval width. That is disclosed here and not adjusted for. This disclosure does not prove that nothing was tuned.

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 8 required changes. Responses:
1. **One central analysis.** The corrected, price-weighted reconstruction under the paper's own valuation choices is the only basis for verdicts (§0, §4). The factorial is supplementary (§5A).
2. **A8 applied exactly.** The margins are H2 [0.89, 0.95], H3a [0.69, 0.75], H1 > 0.60 at every node and H3b > 0.75. The 0.80, 0.50 and 0.60 floors are deleted. The "below 0.75" exception is a separate reported row, H3a-x (§1, §7).
3. **§8 rewritten around the central intervals.** For points: containment, overlap, and disjointness on either side. For thresholds: supported exceedance, uncertain, supported failure. The boundary and undefined cases are explicit. Scenario shares never vote (§8).
4. **Changed estimands and populations separated.** V1, V5, V6 and V7 are moved to §5B and set no verdict. The five- vs six-asset discrepancy and the 1690–1839 coverage are documented in §3. The claim that all scenarios share "the same estimands" is withdrawn.
5. **Bootstrap interpretation corrected.** The superpopulation is defined, and what the intervals exclude is stated. Cluster counts, sizes and missing-id shares are reported. The independence assumption is stated, with a year-block diagnostic. Owner-linked synthetic zeros and joint asset resampling are retained (§4, §5C).
6. **Inference algorithm completed.** B = 9,999 with a Monte Carlo SE rule (escalation to 39,999). The nodes, the quantile type, failed-draw and zero-SE rules are fixed, and nothing is silently discarded. Joint draws are used for the sup-t bands (§4).
7. **Combinations constrained.** The factorial is cut to the same-estimand items V2 × V3 × V4. Endpoint pricing is tied to the V4 level. Vine yields are recomputed on the full data, with no bootstrap in scenarios. V2b is flagged for double counting, and V2c and the 6% capitalisation are labelled exploratory. No joint probability model is claimed (§5).
8. **Missingness and influence added.** NA shares, NA→0 documented with two report-only alternatives, leave-one-cluster-out influence and positive-holder counts with a flag below 10. iid resampling and the raw-unit Fig 2 are diagnostics only (§5C).

Optional suggestions adopted: the matched-owner Fig 5 comparison (S-d) and the synthetic-zero and corrections-off reproduction checks (§4).

**Codex compliance check of v2 (reviews/P29_INEQ25_codex_S6card_v2.md): revise again, 4 blocking issues.** Responses in v3:
1. **Joint inference.** A common joint-draw rule: the same set of jointly valid draws is used for every node of a family. The SD is defined, the family-level failure policy is V ≥ 0.99·B or undefined, the all-zero-SE case is handled, and a 10-batch Monte Carlo SE estimator is specified (§4).
2. **Gate disclosure.** The provenance of the 1% cutoff is disclosed: not results-informed, although the one-holder fact was known. The stated consequence is that H3b, and therefore the H3 summary, are expected to be not-testable, while H3a is unaffected. A report-only S-h is added (§4, §5C 4, §10).
3. **Containment requires both inequalities.** The contradictory prose is replaced (§8).
4. **Supplementary specification.** Vine inclusion (V2b, V2c, and the 6% variant) is moved to §5B as a basket change. The 5A factorial is now V3 × V4 (4 scenarios). The V6 thresholds are computed once on the full data, with no bootstrap. V1 has one price regime (nearest decade under the central decade prices); the constant-price variant is withdrawn (§5).

Note: the v2 response item 7 above described a V2 × V3 × V4 factorial. In v3 that is superseded by item 4 here.

## 10. Known limitations at freeze
1. **H3b and the H3 summary are expected to be not-testable** under the frozen 1% joint-failure rule, because Groenekloof sheep has one positive holder (about 37% undefined draws). The rule was kept to avoid a change informed by its consequence. S-h reports the information without setting a verdict. An independent adjudicator may judge that a different convention for undefined draws is preferable, and any such change would be logged in AMENDMENTS.md as results-informed.
2. **The intervals do not cover** transcription error, unrecorded assets, missing census returns or price uncertainty (§4). The year-block diagnostic is the only check on shared year shocks.
3. **The five-asset central basket** departs from the paper's "six assets", because vines have no price in the data. Vine inclusion is reported only as a changed estimand, under undocumented vine prices.
4. **H1 coverage is 1690–1839**, not the 1685–1844 of the claim. The endpoint years enter only through V1, a non-verdict analysis.
5. **H3a sits near its band edge.** The S5 point estimate of 0.695 lies 0.005 inside [0.69, 0.75], so its verdict may turn on interval width (disclosed in §8).
