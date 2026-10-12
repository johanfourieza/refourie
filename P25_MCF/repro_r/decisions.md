# P25_MCF S3 decisions (Tier 3, rebuild of what survives)

**Independence level:** high for what was rebuilt. No original code survives. The scripts were written from the paper's description of the data (Sections 3–4, Eq. IV) and the raw Ekama et al. emancipation dataset. Before writing them I read no output workbook, the 2018 draft or the SAF rows.

**Scripts:** `01_clean.R` (slave rows → owner-level file on D:), `02_analysis.R` (shortfall distribution, sample counts, arithmetic checks, `results_r.csv`). Outputs: `output/owner_coverage_by_district.csv`, `output/shortfall_distribution.csv`, `output/arithmetic_checks.csv`, `output/fig_shortfall_hist.{pdf,png}`.

## Decisions
- **D1 Input version.** `Slawerekords/Slave Emancipation Dataset.xlsx` (sha256 491cac3a…, 36,417 slave rows, 11 districts). S1 chose this copy over the later 2024 copy, which post-dates the paper.
- **D2 Owner unit.** Owner = district × UCL (claim number) × owner surname × forename (6,028 owners). Compensation sits on one row per owner. Valuation sits on every slave's row. 40 owners have two or more compensation entries. These are summed.
- **D3 Sample definitions.** A: compensation recorded and at least one slave valued (closest to the paper's "value and/or compensated value could not be retrieved"). B: A, and every slave valued. C: B, and shortfall > 0 (the paper's Table 1 minimum is £0.88). Sample counts use A. The compensation share uses B.
- **D4 Shortfall.** AS = (Σ valuation − compensation) / number of slaves, which is Eq. (IV), (pS − C)/S. Valuation and compensation are taken in £ as recorded.
- **D5 Arithmetic checks.** Some claims are arithmetic on other published numbers: the population sums on p.6, the wealth-loss range on p.4 and the effect magnitudes on p.11. For these I recomputed the value from the published inputs and recorded it as an r value. The p.11 effect sizes assume that the T2 coefficients are log points per £ of AS. That is how the claims spec codes them, and it is the scale of AS in Table 1.

## Results
- Sample A: N = 3,253 (paper 3,182), with Stellenbosch 969 (paper 1,024) and other districts 2,284 (paper 2,158). The dataset holds only 999 Stellenbosch owners in total, so this version cannot produce the paper's 1,024. The paper probably used a different or extended version, or a different owner definition. Clanwilliam and Swellendam have no valuations in this version, and Cape and Worcester are only partly valued.
- Compensation as a share of valuation is 40.2% in aggregate (B) and 38.0% at the median owner. For A the aggregate is 45.4%. The paper's "40–50%" is borderline consistent. The paper's own Table 1 implies 240.75/659.98 = 36.5%.
- AS in B has mean £53.1 and median £56.0. In C it has mean £60.4, SD £28.9, range £0.45–£189.5. Paper Table 1 (linked 1st-generation sample, N = 324): mean £65.93, SD £30.48, range £0.88–£180. The distributions have a similar shape. The paper's sample is a linked subset, so the values cannot match exactly.

## Impossible, and why
- Everything that depends on the claimants × SAF × opgaafrolle linkage is unavailable: Table 1 rows other than the population analogue above, Tables 2–5, Appendix tables, and the p.5–6 match counts (665, 4,319, 8,204, 314, 1,744, 2,458, 551), p.7 tax, p.14 non-farm share and p.18 stayers. The linked file and match flags do not survive, and re-linking by hand is out of scope (task brief; S1).
- Aggregates that the paper cites from the literature are marked unavailable because they are not computed from the paper's data: 38,000 slaves, £2.8m slave wealth, £1,247,000 provision, 24% slave share of wealth and the 50% wine decline. For context, the dataset holds 36,417 slaves, of whom 21,983 are valued at a total of £1.90m. The recorded compensation totals £1.08m.
- SAF 2014 (personal) was not read. Its sheet1 dimension tag is A1:HA582129 (about 582,000 rows × 209 columns), read from the xlsx XML header only.
- Note: claims.csv holds 11 duplicated claim_ids (T2/T3/T5 "_r2_" Total Tax/Slave vs (Pseudo-)R2). `run_compare.R` fails on them, so both results files keep one row per unique id (295). All these ids are unavailable anyway.
