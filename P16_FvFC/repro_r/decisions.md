# P16_FvFC — S3 decisions log

Recreation agent, 11 October 2026. Inputs: the paper (PDF/wiki), `claims.csv`, `claims_spec.md`, PROTOCOL.md, CLAUDE.md and the raw workbook `original/Wealth inequality/Time 1663 - 1757 ----  EDITED.xls` (sheet `Data`, 13,569 rows, one row per household-year).

**Independence level: full.** The input is the raw opgaafrol compilation; no code, log or derived file of the authors was opened. **Not outcome-blind**: the published numbers (claims.csv, appendix Table 3) were visible. Disclosure: while checking available tools I ran `ls` on the project root and on `P16_FvFC/repro_original/`, so I saw the file *names* there (PATCHES.md, results_original.csv, s2_ginis_check.R, ginis_xls_vs_figures.csv). I opened none of them.

Decisions D1–D12 were written before 02_analysis.R was first run. Sample-construction choices D2 and D4 were checked against the published appendix Table 3 (N and unweighted means), which is part of the paper.

## Data construction

- **D1. Column codes.** M man, V wife, S sons, D daughters, K knegte (hired hands); SM/SV/SS/SD male, female, boy and girl slaves; PD horses, BSTE cattle, SKPE sheep, VK pigs, WINGST vines, WYN wine; KGS/KGW, RGS/RGW, GGS/GGW wheat, rye and barley sown/harvested; SH flintlocks, PS pistols, DG swords. The workbook has no codebook; these readings follow standard opgaafrol abbreviations.
- **D2. Non-numeric cells → missing → 0.** About 300 cells hold letters (A–Z, probably transcription codes, possibly base-36 numbers ≥10), occupation words in WINGST (VISSER, TIMMER…) or double entries ("2 1"). All are set to missing, and missing counts are set to zero (`output/nonnumeric_cells.csv`). Check: with this rule the per-year farmer slave means reproduce appendix Table 3 to three decimals (e.g. 1709 4.185, 1723 2.645). Decoding letters as A=10… instead gives 1723 = 4.023, which Table 3 does not show. The low 1723 slave mean is therefore probably a transcription-code artefact in the source data. It is flagged for S5.
- **D3. Seed imputation (fn 7).** The paper says seed was "imputed from a bivariate OLS regression of grain harvest on seed sown for all positive values of both items". I regress seed on harvest (the direction needed to predict seed) for each grain, using rows with both positive, and predict seed where harvest>0 and seed=0 (12 wheat, 3 rye and 3 barley rows; `output/seed_imputation.csv`). This affects only the "ST & LT" index, which has no extracted claim.
- **D4. Non-farmer.** Zero on all of horses, cattle, sheep, pigs, vines, wine and grain (sown or harvested). This gives 8,108 farmers and 4,899 non-farmers, matching Table 3 for every year. Dropping wine reclassifies one household.
- **D5. Household size** = M+V+S+D (free family members), minimum 1. Knegte are excluded because they are hired hands, not dependants; `hhsize_k` (adding K) is run as a sensitivity check. Slaves are not household members.
- **D6. 1705 dropped** (fn 8). 20 census years remain; N per year equals Table 3's whole-sample N.

## Index and inequality measures

- **D7. PCA.** For each index, take the first eigenvector of the correlation matrix of the items, estimated on the pooled sample (all 20 years). Index = Σ wⱼ·xⱼ/sdⱼ, not demeaned, which is non-negative. The sign is set so loadings sum positive. "Pooled weights" are estimated separately for the analysis sample: **farmers** for Table 1, Fig 5 and the text Gini claims (Sect. 7.3 analyses farmers only, and Table 1 is the "most robust index" from that section); the **whole settler sample** for Fig 4 (legend: "incl non-farmers"). Variant: farmers scored with whole-sample weights (`weights = pooled_wholesampleW`). Annual weights (Fig 2) re-estimate the PCA within each year; items with zero variance in a year get weight 0.
- **D8. Theil.** Theil T (GE(1)), household-size weighted, computed over positive per capita values only. The paper says the Theil is "completely insensitive to zeroes"; with zeros dropped, the incl-slaves and excl-slaves Theil series are identical by construction.
- **D9. Gini.** Gini of per capita index (household index / household size), with each household weighted by household size, computed as if each person were a separate observation (exact formula for integer weights, no small-sample correction). Zeros are included.
- **D10. Slaves as assetless households (Fig 4).** Each slave becomes a one-person household with index 0. Because Fig 4 includes non-farmers, slaves of all settler households are added. Variant: only farmers' slaves are added (`slaves = incl_farmerslaves`).
- **D11. Fig 5c CI.** The paper does not state the method. The published CIs are symmetric around the point estimate, so I use a normal CI, Gini ± 1.96·SE, where SE is a household bootstrap within year (B = 999, PCA weights held fixed, seed 20100301). Variant: the PCA is re-estimated in each replicate (B = 499). Percentile bounds are also saved. `se` in results_r.csv = fixed-weight bootstrap SE. There are no regressions, so conventional or robust/clustered SEs do not apply.
- **D12. Phillips–Perron (fn 13).** The paper names a "McKinnon approximate P value", which is the label Stata's `pperron` prints. I implement the Stata default: Z(t) from yₜ = a + ρyₜ₋₁ with a constant and no trend, Newey–West lags int(4(T/100)^{2/9}) = 2, and the MacKinnon (1994) approximate p-value. The series is the 20 core 1 farmer Ginis, indexed 1–20 and treated as equally spaced. `tseries::pp.test` (with trend) is reported as a reference.

## Claim mapping

- `text_p13_pigs`: % of all households (1705 excluded) with pigs > 0.
- `text_p23_slave_gap`: mean over the 20 years of Gini(incl slaves) − Gini(excl slaves), Fig 4 series; the year-by-year gap is in `output/fig4_slave_gap.csv`.
- `text_p24_gini_early`: mean core 1 Gini for 1663–1682.
- `text_p29_gini_inclslaves`: minimum over years of the Fig 4 incl-slaves Gini.
- Citations of other authors (Giliomee, Milanovic et al., modern SA) are `not-attempted`.

## Post-hoc changes

- After the first run, I added `output/fig5c_text_comparisons.csv`, which applies fn 14 to the specific year pairs the text names. This is a reporting addition. No primary choice (D1–D12) was changed after the results were seen.
- Informal observation, for S4 to confirm: under D1–D12 most rows land within about 0.005 of the published values. The largest gaps are F5c_1663 (0.527 vs 0.501), the vine weight (T1_r9, 0.314 vs 0.297) and the PP p-value (0.245 vs 0.1485). None of the pre-specified variants was used to close these gaps.
