# P13_FS S3 recreation: decisions (written before comparison with the original-code outputs)

**Independence level: conditional.** Inputs were the authors' own analysis file `DATA20141122.dta` (ignoring stored `_est_*` markers) and `PURPOSEDATA_20141117.dta`. Only claims.csv, claims_spec.md, the paper and the wiki were read. repro_original, compare, audit.md and the deny-listed workbooks were not read. No individual rows were written to outputs. Genealogical fields were used only in memory, as covariates.

## Data
- The analysis file has 4,288 rows. 128 have no `household_iden` and are blank genealogy-only rows, so I dropped them. That leaves 4,160 inventories with a unique `mooc`. `match` 1 = matched (2,117), 2 = unmatched (2,043).
- Credit and debt transactions per inventory come from the purpose file, one row per transaction side. 12,637 rows have `value_credits` and 12,580 have `value_debt`, matching the paper's totals. Of these, 12,372 credit rows link to the 4,160 inventories; the other 265 mooc ids are not in the analysis file. The credit-side count therefore depends on the file.
- Slave groups: 0, 1–5, 6–10, 11–24, 25+ (the paper's "more than 25" is read as ≥25).

## Ambiguities and choices
1. **Tables 1a/1b obs for transaction counts.** The paper prints obs = 6,706 or 12,580 for ncredit/ndebt. I report obs = total transactions in the sample. The mean, median, min and max are per inventory, so the mean differs from the paper (6.1 against 17). The paper's table is internally inconsistent (spec item 2).
2. **Land present (1a).** obs = inventories with land. mean = share of all inventories in the sample.
3. **Table 3.** Probate columns are computed from `num_slaves` > 0 (percentiles use type 2). The Opgaafrolle column is unavailable (not in the allow-list).
4. **Table 4.** Counts are by transaction row, using codes in `gender_c` (lender) and `gender_d` (borrower): 1 Male, 2 Female, 3 VOC, 4 Church, 5 Orphan Chamber, 6 Other. The codes are assumed from frequencies and no label file was read. The paper's counts (about 6,100 lenders) do not reconcile with 12,637 rows (spec item 6). Percentages use all rows in the sample as base.
5. **Table 5 mapping.** Rows are defined from `purpose_debt` and `category_debt` in the purpose file:
   - Land = (Land, Buildings/Real Estate, Bond or Bonds, with category Production) or Bond/Bonds.
   - Land bought with bond = Bond/Bonds.
   - "Other" is assigned to the category it carries.
   - Percentages in rows 1–27 use the specific-purpose count as base; rows 28–30 use all debt rows.
   - Means are nominal `value_debt`. The paper's 12,636 total (spec item 1) versus my 12,580 rows is a known difference. The mapping of Land (1,139 in the paper) is the main uncertainty.
6. **Table 6 sample.** I use matched inventories with all covariates and a decade non-missing. The y variable is log nominal debt (`debt_value`), with zero-debt inventories set to 0. A left-censored Tobit at 0 is fitted by `survival::survreg`, with SEs from the model variance (conventional; the paper's parentheses are t-statistics). Aliased decade dummies are dropped.
   - Panel B is OLS on inventories with debt > 0 and uses the same controls. Conventional SEs go to results_r.csv. HC1 robust SEs are in `output/T6B_*_robust.csv`.
   - The real-values columns use `debt_infl` and 1699–1793.
   - The `children` variable is missing for 75% of matched inventories. Requiring it gives N = 736 (A nominal) and 565 (B nominal), against the paper's 570 and 251. I could not find a restriction that gives the published N, and none was tried further.
7. **Wealth index (Panel B).** The paper's PCA uses slaves, farms, sheep, cattle, horses and cash. The file has no livestock variables, so my PCA uses slaves, properties and cash only. The index is converted to percentiles 1–100. The first component is signed to correlate positively with slaves. This is a known deviation. `TX_p23_wealth_*` = 100 × the wealth coefficient.
8. **Pseudo R².** 1 − logL(model) / logL(constant-only), which is the Stata Tobit definition.
9. **Figure 6.** Share with debt = 0 and share with `debt_value` > 500 (nominal rds), full sample by slave group.
10. **Text claims (TX).** I computed the claims with an obvious definition. The 13 unavailable rows are listed below.

## Unavailable
- T3_opgaafrolle_* (8): Opgaafrolle data are not on the allow-list.
- T5 (1) and TX (4) cells: a zero-count or undefined cell, or no definable input. These include TX_p9_settler_share, TX_p18_bond_rate, TX_p19_loan_small and TX_p19_loan_large.

## Post-hoc changes log
- Table 4 sums gave NA because of missing codes. I added `na.rm = TRUE`.
- The Tobit via `AER::tobit` failed (aliased decade coefficients). I replaced it with `survreg` on a de-aliased design matrix.
- Rows with NA `year` were dropped from Table 6 because the decade control cannot be built.
- No tuning against the published values was done.

## Headline status (informal tally, within 1% or rounding)
- T1a 97/127, T1b 113/135, T2 26/36, T3 24/24 (probates), T4 23/72, T5 108/269, T6 0/88, TX 13/34, F6 3/10.
- The T6 numbers are well off. The N, the sample rules and the wealth index could not be reproduced from the description. The headline signs are the same: slaves positive (0.045 SE 0.018 nominal) and wealth percentile positive (0.025 SE 0.003).
