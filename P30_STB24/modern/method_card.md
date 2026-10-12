# Method card: P30_STB24, the Stellenbosch-Drakenstein tax censuses, 1685–1844

Status: v3 (2026-10-11), final under A9; frozen with the commit message "FREEZE S6 card P30".
- History: v1 (written after the S5 reconciliation in `audit.md`, before any modern estimate) → Codex review (reviews/P30_STB24_codex_S6card.md; approve-with-changes, 8 required changes, 2 optional suggestions) → v2 → Codex compliance check (reviews/P30_STB24_codex_S6card_v2.md; revise again, 3 blocking issues, 1 wording edit) → v3. Issues v3 cannot fully resolve are in §10.
- Margins follow AMENDMENTS.md A1, A3, A4, A8 and A8a. Every margin is the A8/A8a default for its wording type; the wording operationalisations that A8 does not fix (windows, "most") are listed as card readings in §7 with their provenance.

Rights class: open. Data stay on D: (A6); scripts read them through `tools/paths.R`. Codex may see this card, the code and aggregate outputs.

## 0. Type of analysis
The primary analysis is **one corrected central analysis**: (i) a correction of verified code and data errors, with (iii) sampling-uncertainty quantification, under the paper's own definitions (unweighted per-household means and Ginis; zeros included under the paper's stated missing-data rule; Fig 7's owner-household sample as coded). It is not (iv), a new estimator.

**A4b, claim by claim.** For H1–H4 the corrections K1, K3, K4 and K5 change the point estimates (K2 touches only the H2-anchor diagnostic), so for these rows the analysis is not (ii), an inference-only upgrade, and "overturned" is reachable. For **H5a–H5c** no verified correction changes the point estimates: K1–K5 do not touch the slave columns, and the central analysis keeps Fig 7's sample and relabel as coded. For H5 the analysis is therefore (ii), an inference-only upgrade, and A4b applies: the ladder is confirmed / qualified (inference-fragile) / weakened, and **"overturned" cannot be reached for H5a, H5b or H5c** (§8).

**Corrections applied in the central analysis** (each verified by re-run in S5):
- **K1 (C1/F1, C2).** Column types are read from all rows, so counts stay counts (wine in leaguers, `cattle_bull`, `cattle_breeding`, the horse and sheep components).
- **K2 (C3/F2).** Fig 5 indices use the labelled base year, 1795, not the coded 1780.
- **K3 (C4/F3).** `horse_riding` enters the horse aggregate.
- **K4 (F3; the paper's own rule, p.434–435).** An aggregate is missing, not zero, for a row on which every component is missing after the year-level zero-fill, i.e. in a census that recorded none of its components.
- **K5 (C6).** Wine entries above 1,000 leaguers are set to missing. Provenance: the threshold was written in S3 `decisions.md` rule 9 (as a sensitivity) before any comparison and used in S5 scenario S4. Provenance is not validity: the source-based support and the per-entry evidence are in §3 step 4 and §5D, and the uncapped results are reported (§5C item 1) and never vote.

Not corrected, because the paper gives no rule or the item is definitional: `sheep_goats_pigs` (F3 sub-point; §5C item 4), the zero-fill rule itself (the paper's stated rule; §5C item 8), and the disputed non-headline items F5, F7 and F8 (Figs 2 and 4 and the census count). The disputed Fig 7 item F6 bears on H5 (§1): the central analysis keeps Fig 7's owner sample and the pre-1738 relabel as coded, and the alternatives are reported (§5C items 13–14).

**One primary analysis per claim.** Each frozen claim (H1–H5, §1) has exactly one verdict row, decided only by its primary analysis (§4) and its verdict table (§8). Diagnostics, alternative inference and every item in §5 are reported and never vote; items that change the population, measurement or estimand are labelled so (A4d). A4b applies to H5 only (above). There are no magnitude claims, so A3's 50% floor and A4a's credible null do not apply; there are no OR or probability claims, so A4c does not apply. The paper prints no stars; `stars05.txt` = 2 is irrelevant.

## 1. Claims family (headline rows, A1 union) and interpretations
**A1 union.** The headline set is the union of both S0 extractors' choices (A1). The first extractor flagged three rows in `claims/claims.csv` (`TX_rows`, `F5_wine_1702`, `TX_gini_lo`). The second extractor's headline cells are in `claims/headline_second.csv` (its `why_headline` column; rows marked `row-context` are supporting digitised points, not headline cells). They map as follows:
- second extractor, Fig 5 wine 1705–15 vs 1795, "stagnation or decline marginally" → the same claim as `F5_wine_1702`, **H2**;
- second extractor, Fig 6 range 0.4–1 → the same claim as `TX_gini_lo`, **H3**;
- second extractor, Fig 6 wine Gini "rises until 1780s then declines" → new verdict row **H4**;
- second extractor, Fig 7 slave ownership → new verdict rows **H5a–H5c**, one per printed statement in the nominated cell.

The second extractor's Fig 6 cell also describes "no evidence of decline" and "crops more unequal than livestock", but its value is the 0.4–1 range; those two statements stay secondary (S-a, S-b) and the reading is listed in §10. The `headline` flags in `claims.csv` record the first extractor only; this card applies the union without editing the frozen S0 files.

The paper is descriptive, so every margin is the A8/A8a default for its wording type. Interpretations are quoted from `claims/claims_spec.md` and the paper.

**H1, the dataset (`TX_rows`, 142,297; text p.435).** "the 144 tax censuses in 127 volumes covering the period 1685 to 1844 included 142,297 rows, each representing a household." Point count; ±10% (A8).

**H2, agricultural output (`F5_wine_1702`; second-extractor Fig 5 cell; p.440).** "the apparent stagnation or even marginal decline in most assets over the eighteenth century." The verdict row is the "most assets" claim: per-household holdings of a majority of the six Fig 5 assets show stagnation or marginal decline between the first and last decades of the eighteenth century. Stagnation or marginal decline = the A8 "similar" band, a ratio within [0.80, 1.25] (§7).
- **Diagnostics (reported, never vote):** H2-anchor, the digitised `F5_wine_1702` = 3.3 against [2.97, 3.63] (A8 point default); H2-wine, the wine row of the per-asset table. The anchor is a one-year digitising misreading (S2; §10), so it cannot carry the claim; wine is one of the six assets and enters the primary through the per-asset table.

**H3, inequality (`TX_gini_lo`, 0.4; second-extractor Fig 6 cell; p.441).** "the Gini coefficients are, on average, remarkably high, ranging between 0.4 and 1 across all assets for most of the period." Threshold claim (A8, T = 0.4): for **every** one of the six assets, the annual Gini is at least 0.4 in **most** (more than half) of the census years in which the asset is recorded. The upper bound 1 holds by construction for non-negative holdings.
- **H3-lo-x** (reported, no verdict): the minimum and the 10th percentile of all asset-year Ginis against [0.37, 0.43] (A8/A8a Gini band).

**H4, wine-output inequality (second-extractor Fig 6 wine cell; p.441–442).** "Inequality in wine output seems to increase until the 1780s and then on average declines." Two A8 ">" comparisons judged jointly: the mean annual wine Gini of the 1780s exceeds that of the years before 1780, and exceeds that of the years after 1789.

**H5, slave ownership (second-extractor Fig 7 cell; p.442–443).** The paper's population is Fig 7's: households owning at least one enslaved person, census years before 1830, two-decade rows.
- **H5a.** "from the start of the period, there are far more enslaved men per household than either enslaved women or children": mean men per owner household exceeds mean women and mean children in **every** two-decade row (A8 ">", with "from the start of the period" read as A8's "consistently"). "Far" has no A8 default and is not tested; the ratios are reported.
- **H5b.** "in the final two decades, after the Slave Trade Act of 1806 … an increase in the share of households with no enslaved men and a decrease in the share of households with no enslaved women": two A8 comparisons, after 1806 against the twenty years before.
- **H5c.** "in the first half of the nineteenth century, the share of enslaved children increases": one A8 ">" comparison within the nineteenth-century part of Fig 7.

**Not-testable wording.** "remarkably high" (no A8 default; the H3 threshold covers the range); "far more" (H5a); the abstract's "Our findings challenge existing interpretations of colonial economic mobility and governance, demonstrating how settler households navigated taxation, labour, and status" (no figure measures mobility, governance or household responses; S5 interpretation audit).

**Secondary outputs (reported, never verdicts; central machinery).**
- **S-a.** "no evidence of a decline in inequality … if anything, it seems to increase": per-asset OLS slope of G on year, Newey–West (lag 3) SEs.
- **S-b.** "crops like wheat and barley exhibiting much higher levels of inequality … than livestock": the year-paired difference of mean G (wheat, barley) minus mean G (horses, sheep, cattle) over years in which all five are recorded, with the H3 bootstrap; A8 ">", report only.
- **S-c.** "considerable shifts in the period between 1795 and 1806": Fig 5 and Fig 6 series 1790–1810 printed.
- **S-d.** Fig 7's third statement, "a considerable increase in households with more than one enslaved woman in the second half of the eighteenth and early nineteenth centuries": the share of owner households with ≥ 2 women by two-decade row.

## 2. Defects addressed
- **(a) Counts read as indicators (C1/F1), changes a conclusion.** Fig 5 "wine" is the share of households reporting wine; post-1716 cattle is a bull indicator; the wine and cattle Ginis are Ginis of indicators. K1.
- **(b) Wrong base year (C3/F2).** K2 (affects the H2-anchor diagnostic only).
- **(c) Incomplete aggregates and artificial zeros (C4/F3).** K3, K4.
- **(d) Vine counts in the wine column (C6).** Latent under (a); it bites once (a) is fixed. K5.
- **(e) No uncertainty anywhere.** The paper reports no interval for any figure.
- **(f) Fig 7 sample and relabel (C9/F6, disputed).** Not corrected; the central analysis follows the paper's definitions and §5C reports the alternatives.

Sources:
- Abadie, Athey, Imbens and Wooldridge (2020, *Econometrica*), on sampling-based versus design-based uncertainty when the population is fully observed;
- Davidson (2009, *J. Econometrics*), on Gini inference;
- Hall (1992, *The Bootstrap and Edgeworth Expansion*) and Efron and Tibshirani (1993), on the percentile-t (studentized) bootstrap;
- Davison and Hinkley (1997, ch. 3.8), on two-stage resampling for multistage designs;
- Cameron, Gelbach and Miller (2008), on studentized bootstrap-t refinements with few clusters (cited for the studentization, not for the pairs scheme used here);
- Montiel Olea and Plagborg-Møller (2019, *J. Applied Econometrics*), on sup-t simultaneous bands;
- Alfani and Ryckbosch (2016, *EEH*), on historical wealth Ginis;
- Wickham et al., `readxl` documentation (`guess_max`), for the type-guessing mechanism.

## 3. Estimands
**Common data.** `stellenbosch_clean.xlsx`, sheet `Sheet1` (`dpath("P30_STB24", "original", "2024F_Stellenbosch", "stellenbosch_clean.xlsx")`), 142,297 rows, 143 census years. Read with `readxl::read_excel(guess_max = 200000)`. Every component column below must then be numeric; a column that is logical and entirely NA is coerced to numeric NA; any other non-numeric component column stops the script.

**Asset construction (per row, executable).**
1. Components: horses `horse_foals, horse_work, horse_riding, horse_breeding, horse_pleasure` (total column `horses`); cattle `cattle_bull, cattle_breeding, cattle_work, cattle_cows, cattle_heifers, cattle_calves` (no total column); sheep `sheep_breeding, sheep_wool, sheep_wether, sheep_goats` (total column `sheep`); single columns `wheat_vol`, `barley_vol`, `wine`.
2. Year-level zero-fill, as coded (l.236–281) and as the paper states: for every column above, in a census year with at least one non-missing value, NA → 0. A column with no value in a year stays NA for that year.
3. Aggregates: horses = `horses` if non-missing, else the sum of the non-missing horse components, else NA (K3, K4). Sheep: the same with `sheep` and its components. Cattle = the sum of the non-missing cattle components, else NA (K4).
4. K5: `wine` > 1,000 → NA, applied after step 2, so a capped entry is missing, not zero, and leaves the wine mean, Gini and denominator of its year. **Support for the rule.** The `wine` column records leaguers of wine (S3 rule 4: vines and brandy excluded), and the file has a separate `vines` column. An entry above 1,000 leaguers in one household-year is of the order of vine counts (S5: 60,000 in 1766), not of household wine output. The rule is blanket: S5 verified contaminated entries, not every entry above 1,000. §5D lists every capped entry with the evidence for or against its being a vine count, and the exclusions and denominator changes by year.
5. An asset is **recorded** in census year t if at least one row has a non-missing aggregate value.

**Slave columns (H5).** `slave_men`, `slave_women`, `slave_sons`, `slave_daughters`, `slave_children`, all numeric (C1 does not touch them), zero-filled by step 2. As coded (l.888–890): for years ≤ 1737, `slave_sons` ← `slave_children` and `slave_children` ← NA. Children = `slave_sons + slave_daughters`. **Owner household:** year < 1830 and any of men, women, sons, daughters > 0 (l.893–895). Two-decade row = floor(year/20)·20, giving rows 1680, 1700, …, 1820 (eight rows; 1820 covers 1820–1829).

**H1.** N = the number of household rows in the raw transcription `stellenbosch_panel_raw.xlsx` (pipeline zip in `original/Data/`, data on D:), identified by S3's locked rule 2 (`repro_r/decisions.md` rule 2), **minus** the non-observation rows in the paper's sense (p.435): both name columns empty and every numeric data column NA or 0 (data columns = all numeric columns except `year`, `row` and `nr`). The analysis-file count (142,297) is the comparator.

**H2.** For asset a ∈ {horses, cattle, sheep, wheat, barley, wine}, windows E = census years 1700–1709 (ten censuses) and L = 1790–1799 (eight: 1797 and 1799 have no census). m_{a,t} = the mean of aggregate a over all rows of census t with non-missing a (zeros included). M_{a,w} = the unweighted mean of m_{a,t} over the census years in w in which a is recorded. r_a = ln(M_{a,L} / M_{a,E}).
- Diagnostic H2-anchor: I = m_{wine,1702} / m_{wine,1795}.

**H3.** G_{a,t} = `ineq::Gini(x)` over all rows of census t with non-missing aggregate a (zeros included), for every recorded asset-year with Σx > 0. T_a = those years; an asset-year with Σx = 0 at the point estimate is listed and excluded from T_a (its Gini is undefined). s_a = |{t ∈ T_a : G_{a,t} ≥ 0.4}| / |T_a|.

**H4.** Using G_{wine,t} from H3 and the census years in T_wine: Ḡ_w = the unweighted mean of G_{wine,t} over t ∈ w, for w = Pre (years < 1780), Peak (1780–1789) and Post (years > 1789). D_rise = Ḡ_Peak − Ḡ_Pre; D_fall = Ḡ_Peak − Ḡ_Post.

**H5.** All means and shares pool the owner-household rows of a window (as Fig 7 pools rows within a two-decade row).
- **Missing values (available case per category, as Fig 7).** After the year-level zero-fill a slave column is NA only on every row of a census year that did not record it. Fig 7 plots each category over the owner rows on which that category is non-missing (`geom_density_ridges` drops NA; the owner filter keeps a row when any recorded column is > 0). The card follows that rule. Men = `slave_men`; women = `slave_women`; children = `slave_sons + slave_daughters`, non-missing only when both are non-missing (after the relabel). The set of owner rows used for a quantity is:
  - mean men, mean women, mean children: the owner rows of the window on which that category is non-missing; each mean in a contrast Δ^W_b or Δ^C_b uses its own set;
  - Z^M (share with zero men) and Z^W (share with zero women): the owner rows on which men (resp. women) are non-missing, zero count over that set;
  - C_w: the owner rows on which men, women and children are all non-missing (complete case, so numerator and denominator use the same rows).
  - A window in which the set for a quantity is empty makes that quantity undefined (§4 failure rule). The number of owner rows and census years entering each set, per window, is reported.
- **H5a.** For each two-decade row b: Δ^W_b = mean men − mean women; Δ^C_b = mean men − mean children. Sixteen contrasts.
- **H5b.** Windows Pre5 = 1787–1806 (the twenty years up to the Act, the width of a Fig 7 row) and Post5 = 1807–1829 (every year after the Act in Fig 7). Z^M_w = share of owner households with zero men; Z^W_w = share with zero women. ΔZ^M = Z^M_Post5 − Z^M_Pre5 (claimed > 0); ΔZ^W = Z^W_Post5 − Z^W_Pre5 (claimed < 0).
- **H5c.** C_w = Σ children / Σ (men + women + children) over owner households in w. ΔC = C_{1820–1829} − C_{1800–1809} (claimed > 0): the first and last decades of the nineteenth century that Fig 7 covers.

## 4. Primary analysis: the central analysis
**Population and the inferential bridge.** The censuses enumerate (nearly) every household, so each annual mean, share and Gini is a finite-population quantity observed without sampling error. Following Abadie et al. (2020), a statement about those observed values needs no sampling inference, and H1 is judged that way. The other claims are statements about conditions over a decade or a period ("over the eighteenth century", "until the 1780s", "after the Slave Trade Act", "for most of the period"). Annual censuses observe those conditions with year-specific harvest, recording and household-composition shocks. The inferential target is therefore the expected holding, share or Gini under a window's conditions: census years within a window are treated as draws from the window's conditions, and households within a year as draws from the process that generated that year's holdings. For H3 the target is the inequality of the process generating holdings in each census year. Read as finite-population descriptions, these intervals are conservative; they make confirmation and refutation equally harder, so they do not favour either verdict. The finite-population point classifications are reported beside every verdict.

**What the intervals omit.** Transcription error, under-reporting (the paper cites wine under-reported "by up to 40 per cent"), boundary changes (Tulbagh, 1806) and recording changes (1804). **Dependence.** Households are not linked across years in this file. That does not make them independent: the same households appear in successive censuses, so annual means within a window are positively correlated, and year draws treated as independent understate variance. With 8–10 census years per window the intervals are few-cluster approximations. Two pre-specified dependence sensitivities (§5B items 3–4) report how much this matters; they never vote (§10).

**H1.** A population count; no inference.

**Bootstrap, common settings.** RNG `L'Ecuyer-CMRG`, `set.seed(20261011)`, B = 19,999 per design. All assets (and all slave columns) of a row are resampled jointly. Quantiles are R type 7.

**Windowed rows (H2, H4, H5): two-stage percentile-t.**
- **Resampling.** In each replicate and each window w: (1) draw |w| census years with replacement from the census years in w; (2) for each drawn year (each occurrence independently), resample its rows iid with replacement at its own size. All windows of a row are drawn in the same replicate. For H4 the annual Ginis are recomputed from the resampled rows.
- **Studentization: window-stratified delete-one-year jackknife.** Let θ depend on windows w = 1, …, W (W = 2 for the H2, H4 Pre/Peak or Peak/Post, H5b and H5c contrasts; W = 1 for each H5a contrast, whose window is its two-decade row). Window w holds n_w census-year units: in the original data, its census years in which the quantity is defined; in a replicate, its drawn occurrences (a year drawn twice is two units). For each unit j of window w, θ_(w,j) is θ recomputed with unit j removed from window w and every other window unchanged. Centring is **within window**: θ̄_(w) = (1/n_w) Σ_j θ_(w,j). Then
  se²(θ) = Σ_w [(n_w − 1)/n_w] Σ_j (θ_(w,j) − θ̄_(w))².
  There is no pooled centring and no further weighting across windows. ŝe applies the formula to the original data; se* applies it to each replicate. A deletion that makes θ_(w,j) non-finite makes se* undefined for that draw (failure rule). t* = (θ* − θ̂)/se*.
- **Interval.** [θ̂ − q_{1−α/2}(t*)·ŝe, θ̂ − q_{α/2}(t*)·ŝe], at the family level α of §6.
- **Minimum years (computability).** If a window holds fewer than five census years in which the relevant quantity is defined at the point estimate, that contrast is undefined. Five is half a ten-year window; the rule was in v1 and was set before the per-asset recording pattern was looked up.

**H3: within-year bootstrap with simultaneous bounds.**
- Rows of every census year are resampled iid with replacement at their own sizes, all years in one replicate; G*_{a,t} is recomputed for every asset-year in T_a. No asset-year is held fixed.
- **Undefined asset-year draws.** G*_{a,t} is undefined in a draw when Σx* = 0 or the value is non-finite. An asset-year with **any** undefined draw is **unresolved**: it is left out of the sup-t calculation and counts as neither supported above nor supported below 0.4. Its count per asset is reported. This rule treats the two directions identically.
- **Sup-t bounds.** Over the asset-years of all six assets with no undefined draw (the set R): se_{a,t} = the bootstrap SD (n − 1); c = the 95% quantile over draws of max_{(a,t) ∈ R, se > 0} |G*_{a,t} − Ĝ_{a,t}|/se_{a,t}; L_{a,t} = Ĝ_{a,t} − c·se_{a,t}, U_{a,t} = Ĝ_{a,t} + c·se_{a,t}. One band covers the whole H3 family at 95% jointly, so no Bonferroni factor is needed. An asset-year with se = 0 has L = U = Ĝ (flagged).
- **Classification.** Supported above: L_{a,t} ≥ 0.4. Supported below: U_{a,t} < 0.4. Otherwise unresolved. For asset a, with n_A supported above and n_B supported below among |T_a|: s_a^lo = n_A/|T_a| and s_a^hi = (|T_a| − n_B)/|T_a|. Every assignment of the unresolved years gives a share in [s_a^lo, s_a^hi], so the bounds treat unresolved classifications conservatively in both directions.
- Why bounds rather than a bootstrap of s_a: s_a is a discontinuous function of the Ginis, and its bootstrap distribution need not approximate its sampling distribution near G = 0.4. Simultaneous Gini bounds propagate into valid bounds on s_a without that step: if the band covers every G_{a,t}, the true share lies in [s_a^lo, s_a^hi].

**Failure rule for the percentile-t rows (symmetric).** A draw is undefined for a contrast when θ* or se* is non-finite, when se* = 0, when a denominator is zero (M*_{a,E} = 0 or M*_{a,L} = 0, an empty window, no owner household in a window), or when no drawn year in a window records the quantity. Intervals use the defined draws of that contrast, and every failure count is reported. If a contrast's failure rate exceeds one-tenth of its family's smallest tail probability, the contrast is **undefined**, whatever the direction of its estimate, and its verdict row applies the not-testable precedence of §8. Thresholds (fixed before any bootstrap was run, by the P10 derivation; in brackets the largest number of failed draws allowed at B = 19,999, rescaled by rate at B = 49,999): Family H2 0.05/12/10 = 0.0417% (8); Family H4 0.05/4/10 = 0.125% (24); Family H5 0.05/38/10 = 0.0132% (2).

**Monte Carlo precision.** The defined draws, in draw order, are split into 10 consecutive batches; each verdict-relevant endpoint (for H3, c and the bounds, with Ĝ fixed) is recomputed per batch; MC SE = SD/√10. If any verdict-relevant endpoint lies within 2 MC SE of a §7 boundary, B is raised to 49,999 (same seed), and that run decides. If an endpoint is still within 2 MC SE of a boundary at 49,999, the 49,999 verdict stands and is flagged "MC-fragile" in the report; there is no further escalation.

**Reported per quantity:** rows per census, census years per window, positive holders per asset-year, the size of R, unresolved counts, failure counts, and the finite-population point classification.

**Checks before any verdict.**
1. With K1–K5 off (types as guessed, base 1780, no riding horses, `rowSums(na.rm = TRUE)` zeros, no cap), the pipeline reproduces `repro_original/output/fig5_mean_values.csv` and `fig6_gini_values.csv` to < 1e-6.
2. With K1, K2, K3 and K5 on and K4 off, it reproduces S5 scenario `S5_all_fixes_base1795` (`compare/s5_checks/output/fig5_index_S5_all_fixes_base1795.csv`, `fig6_gini_S5_all_fixes_base1795.csv`) to < 1e-6.
3. The H1 rule-2 count before removing non-observation rows equals S3's 142,592.
4. The H5 owner-household row count before 1830 equals the 55,940 of S5 (Codex F6).
If a check fails, no verdict is issued until the cause is logged in `modern/DEVIATIONS.md` (A5).

## 5. Supplementary analyses (exhaustive; reported, never verdict-setting)
**5A. Same estimand, one correction at a time.** Each of K1–K5 is switched off in turn, with the others on (point estimates only), for every r_a, s_a, D_rise, D_fall, the H3-lo-x statistics and I. K1–K5 do not touch the H5 quantities.

**5B. Same estimand, alternative inference (diagnostics, never inferential alternatives).**
1. H2 and H4 with within-year resampling only (years fixed), separating household from year variation.
2. Analytic Welch interval for each H2 r_a on the same estimand: delta-method SE from between-year variances, se² = s²_L/(n_L M²_L) + s²_E/(n_E M²_E), Welch–Satterthwaite df, at the Family H2 level. (This replaces v1's difference of mean logs, which was a different estimand.)
3. **Dependence sensitivity 1, year blocks.** The two-stage percentile-t with circular moving blocks of three consecutive census years within each window in place of iid year draws (H2, H4, H5).
4. **Dependence sensitivity 2, name-linked households.** Households linked across years within a window by the exact standardised man's name (surname by the S3 rule-15 parser, plus given names; case, spaces and punctuation removed); rows with no man's name are singletons. Name clusters are resampled with all their years, with census years fixed (H2, H4, H5). The linkage is crude; the number and size of clusters are reported.
5. Leave-one-census-out range of each windowed contrast, and the number of drops that would change its verdict-table row.
6. H3 percentile bounds per asset-year at the Bonferroni level over |R| (pointwise alternative to sup-t), and the finite-population s_a.

**5C. Changed measurement, estimand or population (labelled; A4d).**
1. Wine cap: none; 500 leaguers (alternative data correction; changed measurement).
2. H2 windows 1700–1719 vs 1780–1799 and 1700–1749 vs 1750–1799 (changed estimand).
3. H2 with pooled row-level means within each window instead of the mean of annual means (changed estimand: household rather than year weights).
4. `sheep_goats_pigs` added to the sheep components (changed measurement; Codex F3 sub-point).
5. Log-linear trend: OLS of ln m_{a,t} on year, 1700–1799, per asset, Newey–West (lag 3) SEs (changed estimand: a slope).
6. Ginis over positive holders only (changed population).
7. H3 with years from 1804 onward excluded (record format changes in 1804, `TX_break1804`; changed period).
8. No zero-fill: means and Ginis over non-missing entries only (changed missing-data rule and population).
9. H3 pooled: the share of all asset-years with G ≥ 0.4 (a different reading of "across all assets").
10. Gini with the small-sample factor n/(n − 1) (changed estimator).
11. H4 with Pre = the first decade with wine recorded and Post = the last decade with wine recorded (changed estimand).
12. H4 and S-a with the wine cap off (changed measurement).
13. H5 without the pre-1738 relabel, unsexed `slave_children` excluded from children (changed measurement; the F6 dispute).
14. H5 over all households, not owners only (changed population; the F6 dispute).
15. H5b with Pre5/Post5 = the Fig 7 rows 1780 and 1820; H5c with the nineteenth-century window starting in 1804, after the age-cut change (changed estimand).

**5D. K5 evidence (per entry).** For every `wine` entry above 1,000: census year, row, household name, the value, the same row's `vines`, the household's `wine` in the adjacent censuses (exact name match), and whether the value equals the row's or the census's vine count within ±10%. Reported: the number of capped entries by year, the change in the wine denominator and mean by year, and the number of capped entries for which no vine-count evidence is found. No entry is reinstated on this evidence in the central analysis.

**5E. H1 diagnostics.**
1. The rule-2 count without removing non-observation rows (S3: 142,592), the removed rows by census, and the analysis-file count (142,297) by census.
2. Rows with both names empty but some data; exact duplicate rows within a census.
3. Census years in the data (143) against the paper's 144, and in the raw workbook.

**5F. Data diagnostics.** Aggregate-versus-component conflicts before the zero-fill: rows where the total column (`horses`, `sheep`) and the sum of the components are both non-missing and differ, and rows where zero-filling a missing total would block the component fallback; counts by census and asset.

## 6. Fixed choices
- No weights. Zeros included under the paper's year-level rule (§3 step 2).
- `ineq::Gini(x)`, no small-sample correction. Quantiles type 7.
- Census years as in the data; no interpolation (1797 and 1799 are absent from window L).
- **Multiplicity families** (two-sided):
  - Family H2: {r_a, six assets}, m = 6, Bonferroni, 1 − 0.05/6 (99.167%).
  - Family H3: one 95% sup-t band over all asset-years (§4).
  - Family H4: {D_rise, D_fall}, m = 2, 1 − 0.05/2 (97.5%).
  - Family H5: {16 H5a contrasts, ΔZ^M, ΔZ^W, ΔC}, m = 19, 1 − 0.05/19 (99.737%).
  - H1, the H2 diagnostics, H3-lo-x and S-a to S-d are outside the families.
- Seeds 20261011; `RNGkind("L'Ecuyer-CMRG")`. Scripts: `modern/01_build.R`, `02_h1_count.R`, `03_h2_assets.R`, `04_h3_gini.R`, `05_h4_winegini.R`, `06_h5_slavery.R`, `07_supplementary.R`, `08_verdicts.R`; outputs in `modern/output/` (aggregate CSVs only); scratch on D: via `dscratch()`.
- Verdict comparisons use unrounded values; results are reported to 3 dp (counts exact).
- **Boundary rules.** Band endpoints are inside a band (closed). "Between 0.4 and 1" is inclusive: G = 0.4 counts as at least 0.4, so L = 0.4 is supported above and U = 0.4 is not supported below. "Most" is strict: a share of exactly 0.5 is not a majority. For ">" contrasts, a CI endpoint at exactly 0 counts as "CI includes 0", and a point estimate of exactly 0 is not on the claimed side.

## 7. Margins and their provenance
| Row | Type | Confirm condition | Provenance |
|---|---|---|---|
| H1 | point count | 128,068 ≤ N ≤ 156,526 (142,297 ± 10%) | A8 point default |
| H2 | wording: "stagnation or even marginal decline", "most assets" | at least 4 of 6 assets with ln 0.80 ≤ L(r_a) and U(r_a) ≤ ln 1.25 | A8 "similar" band [0.80, 1.25]; "most" = majority (card reading) |
| H3 | threshold, "for most of the period", "across all assets" | s_a^lo > 0.5 for every asset | A8 threshold default (T = 0.4); "across all" = every asset (A8 "consistently"); "most" = majority (card reading) |
| H4 | two comparisons ">" | CI of D_rise > 0 and CI of D_fall > 0 | A8 comparative default; windows (card reading) |
| H5a | comparisons ">", "from the start of the period" | all 16 CIs > 0 | A8 comparative default; every row (A8 "consistently") |
| H5b | comparisons | CI of ΔZ^M > 0 and CI of ΔZ^W < 0 | A8 comparative default; windows (card reading) |
| H5c | comparison ">" | CI of ΔC > 0 | A8 comparative default; windows (card reading) |
| H2-anchor (diagnostic) | point index | 2.97 ≤ L and U ≤ 3.63 | A8 point default (3.3 ± 10%) |
| H3-lo-x (reported) | point, lower edge | 0.37 ≤ statistic ≤ 0.43 | A8/A8a Gini band |

**Card readings (wording operationalisations A8 does not fix; each needs Codex acceptance as independent of S5 numbers).**
- **"Most" = a majority** (H2: at least 4 of 6 assets; H3: more than half of the recorded years). This is the reading A8 gives "typically", applied by P10 to "mostly".
- **"Stagnation or even marginal decline" = the A8 "similar" band.** A ratio within [0.80, 1.25] contains stagnation and any decline of at most 20%. A credible decline beyond 20% is not "marginal": it is reported as direction-consistent but larger than stated (category D in §8), and it does not count as support. v1's unbounded union is withdrawn.
- **H2 windows.** The first and last decades of the eighteenth century, from "over the eighteenth century". They were fixed in v1 after the S5 1700–1720 vs 1780–1795 ratios had been seen (§10).
- **H4 windows.** Peak = the 1780s, from "until the 1780s"; Pre and Post = every recorded year before and after, from "increase until" and "then on average declines". No S5 statistic exists on these windows; S5 decade means and peak years were seen (§8 disclosure).
- **H5b windows.** Post5 = every Fig 7 year after the Act (1807–1829); Pre5 = the twenty preceding years, the width of a Fig 7 row. Set from the wording; no S5 statistic on Fig 7 shares exists.
- **H5c windows.** The first (1800–1809) and last (1820–1829) nineteenth-century decades in Fig 7. Set from the wording; the 1804 age-cut change falls inside the first window (§10).
- **No ceilings.** A8's plausibility flag (> 1.5× a stated magnitude) concerns magnitude claims; none of the rows is one.

## 8. Verdict rules (primary analysis only; the first rule that applies decides; exhaustive)
`strengthened` is not used: a claim that holds more clearly is reported as confirmed with a note.

**Not-testable precedence (all rows).** An undefined quantity sets not-testable only if some admissible value of it could change the verdict. For H3, H4, H5a and H5b (conjunctions) this is implemented by the order of the rules below: a supported contradiction among the defined quantities decides before missingness, and confirmation requires every quantity. For H2 (a majority rule) it is implemented by bracketing the not-testable assets (below). For H1 and H5c (one quantity) an undefined quantity is not-testable.

**H1** (a population count; no inference):
| # | Condition | Verdict |
|---|---|---|
| 0 | the raw workbook cannot be parsed, or check 3 of §4 fails without a logged cause | not-testable |
| 1 | 128,068 ≤ N ≤ 156,526 | confirmed |
| 2 | N < 128,068 | qualified (count below the stated value) |
| 3 | N > 156,526 | qualified (count above the stated value) |

**H2, step 1: per-asset category** (r_a with its Family H2 interval [L, U]; band B = [ln 0.80, ln 1.25] = [−0.2231, 0.2231]):
| # | Condition | Category |
|---|---|---|
| 0 | r_a not computable or undefined (failure rule or minimum years) | NT |
| 1 | ln 0.80 ≤ L and U ≤ ln 1.25 | C (stagnation or marginal decline established) |
| 2 | L > ln 1.25 | O (credible rise of more than 25%: the direction is reversed) |
| 3 | U < ln 0.80 | D (credible decline of more than 20%: direction consistent, magnitude larger than "marginal") |
| 4 | overlap, r_a ∈ B | Q (consistent but imprecise) |
| 5 | overlap, r_a ∉ B | W |

Containment needs both inequalities; disjointness is strict; every other case is overlap. Rows 1–5 are exclusive and exhaustive when row 0 does not apply.

**H2, step 2: verdict** (n_C, n_D, n_Q, n_W, n_O, n_NT = numbers of assets per category):
| # | Condition | Verdict |
|---|---|---|
| 1 | n_C ≥ 4 | confirmed |
| 2 | n_O ≥ 3 | overturned (at most three of six assets can show no material rise) |
| 3 | n_C + n_D + n_Q ≥ 4 | qualified (a majority did not rise; labelled "larger decline than stated" if n_D > 0, "imprecise" if n_Q > 0) |
| 4 | otherwise | weakened |

**Band disagreement versus reversal (H2 is deliberately direction-sensitive).** The claim is that a majority (at least four of six) of assets did not materially rise. Confirmation needs four assets credibly inside the band. "Overturned" is reserved for a reversal of direction: three assets credibly above the band (O), which leaves no possible majority of non-rising assets. A credible departure from the band on the other side, a decline beyond 20% (D), is a disagreement with the band in the claimed direction, not a reversal: it counts toward the "did not rise" majority of row 3, labels the verdict "larger decline than stated", and never overturns. The two sides of the band are therefore not treated alike, and the card does not claim they are.

**NT assets.** Rows 1–4 are evaluated twice, once with every NT asset set to C and once with every NT asset set to O. If both evaluations give the same verdict, it applies; otherwise H2 is **not-testable**. The verdict is monotone in each asset's category (O < W < Q, D < C), so these two evaluations bracket every assignment. Rows 1 and 2 cannot both hold (4 + 3 > 6).

**H3** (threshold, universal across assets; simultaneous bounds of §4):
| # | Condition | Verdict |
|---|---|---|
| 1 | s_a^hi ≤ 0.5 for at least one asset with T_a non-empty | overturned (a credible minority of years at or above 0.4 for that asset) |
| 2 | T_a empty for any asset | not-testable |
| 3 | s_a^lo > 0.5 for every asset | confirmed |
| 4 | every point s_a > 0.5, some s_a^lo ≤ 0.5 | qualified (inference-fragile) |
| 5 | some point s_a ≤ 0.5, no s_a^hi ≤ 0.5 | weakened |

Row 1 precedes row 2, so an established counterexample is not masked by a missing asset. A missing asset could be either a counterexample or a success, so after row 1 it blocks every other verdict.

**Comparative rows H4, H5a, H5b, H5c** (k contrasts, each with its family interval and a claimed side: > 0 for D_rise, D_fall, every H5a contrast, ΔZ^M and ΔC; < 0 for ΔZ^W):
| # | Condition | Verdict |
|---|---|---|
| 1 | at least one defined contrast has its CI entirely on the opposite side of 0 | H4: overturned (reversed). H5a–H5c: weakened (credible reversal; A4b) |
| 2 | at least one contrast undefined | not-testable |
| 3 | every CI entirely on the claimed side | confirmed |
| 4 | every point estimate on the claimed side, some CI includes 0 | qualified (inference-fragile) |
| 5 | otherwise | weakened |

k = 2 for H4 and H5b, 16 for H5a, 1 for H5c. For k = 1, row 2 applies only when the single contrast is undefined.

**H5 under A4b.** H5a–H5c are inference-only rows (§0), so their ladder is confirmed / qualified (inference-fragile) / weakened, and "overturned" cannot be reached. Row 1 keeps its place in the order, so a credible reversal still decides before missingness, but it yields "weakened", labelled "credible reversal" in the report. H4 keeps the full ladder because K1 and K5 change the wine Ginis.

**Diagnostics and reported rows (no verdict).**
- **H2-anchor:** I with a 95% within-year percentile interval (rows of 1702 and 1795 resampled), labelled inside, below or above [2.97, 3.63]. "Above" means a steeper fall than stated, not a reversal.
- **H2-wine:** the wine row of the step-1 table, with its category.
- **H3-lo-x:** the minimum and p10 of all Ĝ_{a,t}, each labelled inside, below or above [0.37, 0.43].

**Summaries.** H1, H2, H3, H4, H5a, H5b and H5c are reported separately and not aggregated. Beside each verdict the report gives the §5A ranges, the §5B diagnostics (including both dependence sensitivities) and the per-asset table for H2 and H3. None of §5 changes a verdict.

**Disclosure.** S2, S4 and S5 have already produced these numbers bearing on the verdicts.
- **H1.** Analysis file 142,297 rows (exact). S3 rule 2: 142,592; 303 numbered, empty rows in ten censuses 1719–1737 (one with an entry), and −8 net elsewhere. This implies N ≈ 142,290, inside the band, so H1 is expected to be confirmed.
- **H2.** Original code (base 1780): wine index 2.516 at 1702 (3.47 in 1700, 3.29 in 1703); base 1795 alone 2.293; types fixed 0.671 (base 1795, = all S5 fixes). Unconditional wine means 2.133 (1702), 3.150 (1780), 3.180 (1795). The 1717 index is 11.8 without the cap and 0.71 with it. Ratios of the 1780–1795 mean to the 1700–1720 mean of annual means (types fixed): horses 1.74, cattle 0.63, sheep 0.70, wheat 0.29, barley 0.15, wine 0.78 without the cap and 1.34 with it. Codex: exported 1795 indices (base 1780) barley 0.112, sheep 0.453, wine 1.097. Several of these ratios lie outside [0.80, 1.25] on both sides. The move from v1's unbounded union to the A8 band was required by the Codex review and uses the A8 default; it was nonetheless made with these ratios known.
- **H3.** Minimum asset-year Gini 0.340 (as run) → 0.616 (types fixed, and all S5 fixes); p10 0.551 → 0.708; share in [0.4, 1] 0.984 → 1.000 of 837 asset-years; asset-specific minima 0.616–0.850 (Codex); S3 p10 0.709. H3 is expected to be confirmed under any interval design unless many asset-years are unresolved.
- **H4.** Wine Gini decade means 0.79 → 0.93 (types fixed); peak of the centred 11-census rolling mean in 1766 without the cap and 1802 with it. With the cap the peak lies after the 1780s, so D_fall may not be positive.
- **H5.** Fig 7 itself (owner-household densities) and its S2 reproduction; 55,940 owner records of 123,948 pre-1830 records; 350 male counts above 30 dropped by the plotting scale; `slave_sons` empty before 1738 except 5 entries in the 1680s. No mean, share or contrast in §3 H5 has been computed.
- **Secondary.** OLS Gini slopes positive for five of six assets; cattle 1730 Gini 0.620 (Codex).

Not computed: any statistic on the H2 windows (1700–1709, 1790–1799), the H4 windows, or the H5 windows; K4's effect; any bootstrap interval; any H1 count after removing non-observation rows. This disclosure does not prove that nothing was tuned.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P30_STB24_codex_S6card.md): approve-with-changes, 8 required changes, all addressed in v2.
1. **One primary verdict per frozen claim.** The "weakest of H2a, H2b, H2c" summary is deleted. H2 has one verdict row, the "most assets" test (v1's H2c). The digitised anchor (H2-anchor) and the wine contrast (H2-wine) are diagnostics that never vote, so the anchor misreading (§10.1) cannot mechanically overturn the economic claim (§1, §8).
2. **"Marginal decline" no longer unlimited.** v1's union r ≤ ln 1.25 is withdrawn. Stagnation or marginal decline = the A8 "similar" band [0.80, 1.25]. A credible decline beyond 20% is a separate category D, reported as direction-consistent but larger than stated, and it does not count as support (§7, §8 H2 step 1).
3. **Inferential population and dependence.** §4 now explains the bridge from fully enumerated censuses to window-level and process-level inference (Abadie et al. 2020), states that the intervals are conservative for finite-population readings, and states that unlinked households are not independent. Two dependence sensitivities are pre-specified: year-block resampling and name-linked household clusters (§5B items 3–4). The windowed intervals are now percentile-t, studentized by a year-jackknife SE, and Cameron–Gelbach–Miller is cited only for studentization (§2, §4).
4. **H3 indicators replaced.** No asset-year is held fixed. 95% sup-t bounds over all asset-years are propagated into bounds [s_a^lo, s_a^hi] on each majority share. Asset-years with any undefined draw are unresolved and count against confirmation and against refutation alike. The s_a bootstrap is dropped because s_a is discontinuous (§4, §8 H3).
5. **Verdict semantics and missingness precedence.** "Overturned" is reserved for reversals: a credibly larger anchor index is labelled a steeper fall, not overturned (H2-anchor), and a credible large decline in H2 is category D, not O. In H3 and in every comparative row a supported contradiction now decides before missingness, and H2 brackets not-testable assets by monotonicity, so an unresolved quantity sets not-testable only if it could change the verdict (§8).
6. **K5 substantiated.** §3 step 4 gives the source-based support (wine in leaguers, a separate `vines` column, vine-scale values) and says plainly that the rule is blanket. §5D lists every capped entry with its vine-count evidence and reports exclusions and denominator changes by year. The uncapped results are reported in §5C items 1 and 12 and never vote; §0 separates provenance from validity.
7. **Sensitivity labels corrected.** The alternative windows, pooled household weighting and `sheep_goats_pigs` move to §5C as changed estimand or measurement. The Welch diagnostic is redefined on the primary estimand (delta-method SE of the log ratio of means of annual means), §5B item 2.
8. **Headline scope reconciled with A1.** The headline set is the union of both extractors' cells (§1). The second extractor's Fig 6 wine-Gini and Fig 7 cells become verdict rows H4 and H5a–H5c, with A8 default margins and their own families. The card follows A9: this is v2; a compliance check and v3 follow, and unresolved issues are listed in §10 without new gates.

Optional suggestions, both adopted: the action when endpoints remain Monte Carlo-unstable at 49,999 draws (§4: the 49,999 run decides, flagged "MC-fragile"); aggregate-versus-component conflicts before zero-filling (§5F).

**Codex compliance check of v2** (reviews/P30_STB24_codex_S6card_v2.md): revise again; seven earlier changes addressed, change 6 (K5) partly. A8/A8a applied correctly; no undisclosed results-based margin or ceiling; one central analysis per verdict. v3 responses:
1. **A4b claim by claim.** No verified correction changes the H5 point estimates, so H5a–H5c now follow A4b's inference-only ladder and "overturned" is unreachable for them; a credible reversal yields "weakened (credible reversal)". H1–H4 keep the full ladder because K1, K3, K4 and K5 change their point estimates (§0, §8).
2. **Jackknife formula.** The studentizer is now a window-stratified delete-one-year jackknife with within-window centring and the (n_w − 1)/n_w factor per window, summed over windows with no other weights; units in replicates are drawn occurrences (§4).
3. **H5 missing-value denominators.** Available case per category, as Fig 7 plots it: each mean and zero share uses the owner rows on which its category is non-missing; children are non-missing only when sons and daughters both are; the children's share uses complete cases on men, women and children (§3 H5).
4. **H2 "symmetry" wording** replaced by the explicit distinction between band disagreement (D, counts toward "did not rise") and reversal (O, overturns) (§8).
5. **K5 (earlier change 6, partly).** Not fully resolvable without per-entry source checks; it stays in §10 item 3.

## 10. Known limitations at freeze
1. **The H2 anchor is a digitising artefact.** S2 showed `F5_wine_1702` = 3.3 to be a one-year misreading of a jagged series (2.516 at 1702, 3.29 at 1703 in the original code). It is a diagnostic only; the H2 verdict rests on the six-asset test.
2. **Windows chosen after S5.** The H2 windows follow the wording but were fixed after the S5 1700–1720 vs 1780–1795 ratios had been seen; the H4 windows after the S5 wine-Gini decade means and peak years. §5C items 2 and 11 report alternatives.
3. **K5 is blanket and Claude-only.** Codex did not raise C6. The 1,000-leaguer cap was written in S3 before comparisons, but S5 showed that it moves the 1700–1720 wine mean from 4.38 to 2.54 and the wine-Gini peak from 1766 to 1802. §5D documents each capped entry; it does not validate them all. The v2 compliance check rated this change "partly addressed": units, the separate `vines` column and one extreme example do not substantiate every exclusion above 1,000. The cap stays in the central analysis as frozen; the uncapped results (§5C items 1 and 12) are reported beside every affected verdict and never vote.
4. **Card readings.** "Most" = majority (H2, H3) and the H2, H4, H5b and H5c windows are card readings. The v2 compliance check found their S5 exposure disclosed and raised no objection, but did not explicitly accept each reading as independent of S5 numbers.
5. **Few census years and dependence.** Percentile-t intervals with 8–10 census years per window are few-cluster approximations, and households recur across the years of a window. The dependence sensitivities report the effect but do not enter the verdict.
6. **What the intervals omit.** Transcription error, trends in under-reporting, boundary changes (Tulbagh 1806) and recording changes, which the paper itself offers as explanations of the Fig 5 pattern. A trend in under-reporting could produce or mask the H2 pattern and cannot be tested with these data.
7. **H3 is close to determined by S5.** With every corrected asset-year Gini at or above 0.616, H3 is expected to be confirmed under any reasonable interval.
8. **H5 rests on Fig 7's disputed definitions.** The owner-only sample and the pre-1738 relabel are the paper's (F6 disputed between Claude and Codex). The central analysis follows the paper; §5C items 13–14 report the alternatives. The 1804 change in age cuts for children falls inside the H5c first window (§5C item 15).
9. **Secondary statements in a nominated cell.** The second extractor's Fig 6 cell also describes "no evidence of decline" and "crops more unequal than livestock". They are treated as secondary (S-a, S-b) because the cell's value is the 0.4–1 range; a reader who counts them as headline statements would find them reported but not adjudicated.
10. **The `headline` column in `claims.csv` records only the first extractor.** The A1 union is applied in this card; the frozen S0 file is not edited.
11. **H1 rests on S3's row rule.** The raw-to-analysis cleaning step is missing (S1 gap), so the non-observation rule is the paper's words made executable through the locked S3 parser, not the authors' own code.
12. **Disputed non-headline items.** F7, F8 and the one-model F5 concern non-headline outputs and are not adjudicated here.
13. **Computability rules set after S5.** The five-census-year minimum (§4) and the failure thresholds (§4, by the P10 derivation) were written after S5 but before any windowed statistic or bootstrap was computed. They decide only whether a quantity is defined, they apply identically to both directions, and they are not margins.
14. **H5 cannot be overturned (A4b).** Because the central analysis keeps Fig 7's definitions, H5a–H5c are inference-only rows; a credible reversal is reported as "weakened (credible reversal)". A reader who accepts the F6 alternatives (§5C items 13–14) may judge such a reversal more severely; those alternatives change the population or measurement and never vote.
15. **H5 available-case denominators.** Following Fig 7, each H5 mean and zero share uses the owner rows on which its own category is recorded, so the two means in a contrast Δ^W_b or Δ^C_b may rest on different census years when a column is unrecorded in some years of a window. The row and year counts per set are reported; no alternative denominator is pre-specified.
16. **Jackknife studentizer.** The window-stratified jackknife with within-window centring was specified in v3, after the compliance check, but before any windowed statistic or bootstrap was computed. With 8–10 units per window it is itself noisy; this is part of the few-cluster limitation in item 5.
