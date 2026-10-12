# P19_GF S3 decisions (independent recreation)

**Independence level: conditional.** I used only the paper, its wiki text, claims.csv/claims_spec.md and the two Blue Book workbooks. Conditional, not full, because claims_spec.md (S0) lists the digitised figure values and the paper's own totals that I saw before building anything. No manuscripts, repro_original, compare or audit files were read.

## Nature of the paper
Descriptive; no regressions, SEs or clustering. `se` is empty throughout, so there are no conventional or robust SEs to report. `n` = number of years (or items) behind each value.

## Data
- `Abel Gwaindepi CC fiscal records.xlsx`: sheets Expenditure (1827-1909, 43 cols), Public Debt -Blue Books (1859-1909, with Greyling-Verhoef GDP), Revenue. Earlier workbook `colonialfiscal 18271909.xlsx` matches Total Expenditure exactly (max abs diff 0).
- Expenditure series are non-integer (apparently already deflated); debt and GDP are in the workbook's own units. Shares are unit-free; levels are reported in series units. The paper's price basis (De Zwart 1861) cannot be checked.

## Choices and ambiguities (made before any comparison with published values)
1. **Table 1 mapping** of workbook columns to six classes: see `01_clean.R`. Robben Island put in Law and order (could be Human resources). Customs, Mines, Post Office, Telegraph, Mails, Ports, Surveyor General, Commissioner of Public Works put in Public works (Table 1 lists them there). Columns for Controller and Auditor General, Agent General, Treasury, Immigration, Lands and Agriculture, Lighthouse, Engineer are absent from the workbook.
2. **Denominator**: shares use the workbook's `Total Expenditure`. The classified columns do NOT sum to it: the residual is large (up to 4.7x total in some early years; about -10% to +12% of total in 1890-1909). Alternative denominator (sum of classified columns) is reported in `output/diagnostics.csv` only.
3. **Public works = Total Railways + other public-works columns.** `Total Railways` may overlap with other lines; 1875 looks anomalous (railways 1.06m against 0.60m in 1876), which pushes the 1875 public-works share above 100%.
4. **Point-estimate rules for bound claims**: `TX_p351_pwdebt70` = mean of (public works + debt service) share 1870-1909; `TX_abs_rail70` = mean railway share of public works 1880-1909; `FA2_rail_min/max` = min/max of that share 1880-1909. Minima, fractions of years above 70% are in diagnostics.csv.
5. **Fig 2 claims**: share in the stated year (1905, 1876, 1874), not a peak search. Actual maximum after 1895 is 50.6% (1904).
6. `TX_p341_debt1899` = max public debt/GDP over 1898-1900 (=1900 value, 196.6%); the 1899 value alone is 102.0% because GDP is high in 1899 and falls in 1900. Logged because the claim says "c.1899".
7. `TX_p352_railexp` = maximum of Total Railways (1903), million, series units. `TX_p352_otherinfra` = maximum of any single non-railway public-works column.
8. `TX_p360_deficit` = largest (expenditure - revenue) 1872-1909 from the earlier workbook's `fiscal` sheet, in series units (million).
9. Debt/GDP uses `Total public debt` / workbook GDP. Matches Fig 6 public line (226% 1885, 197% 1900, 96% 1909), and the paper's p.357 "close to 230%".

## Unavailable (inputs not recovered or not in the allow-list)
- All 25 Table 2 claims: need population and the De Zwart price index. Shares-of-total analogue is in `output/table2_shares_analogue.csv` (not a claim comparison).
- `TX_p341_debt1909`, `TX_p357_natpeak`, `F6_nat_*`: need Stone (1999) private debt.
- `TX_p352_miles1873/1910`: railway miles not recovered. `TX_p358_loans`: Crown Agents loans not recovered. `TX_p358_cgrdebt`: needs loan-level railway attribution.
- `TX_p357_aus/can/uk1850/uk1910`: external literature series (Taylor 2013; Eichengreen et al. 2019), not in the data.

## Post-hoc changes
None so far. The `\s` regex fix in 01_clean.R was a syntax repair before any run.
