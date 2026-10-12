# P02_BoF10 S3 recreation: decisions (written before any comparison with reported values)

**Independence level: conditional.** I read claims.csv (reported values are visible), so the specification was written knowing the targets. No tuning toward targets was done; every choice below was fixed before the first run and no post-hoc change was made, other than the one bug fix logged at the end.

## Data
- Ships: `ships for eviews FROM 1652.xls` (total ships), identical to Beyers (1929) 1701-93 (0 mismatches). Shipdays not used (Table 2 labels the series "Ships").
- Wheat sown/reaped, vines, wine (leggers): Van Duin & Ross.xls, sheet "Agricultural production" (1701-95). Cattle: "Livestock in possession". Wheat exports: "Exports of grains" (1706-93).
- Brunt (2007) wheat: the `WHEAT` column of `agricultural output data for eviews.xls` (1709-93). The file does not label it Brunt; the correlation with VDR reaped is 0.65. Assumption.
- Sample 1701-1793. One year is missing from the VDR sheets (internal NA): linearly interpolated. Exports have 11 internal gaps, also interpolated; each series trimmed to its first and last observed year.
- All series in natural logs.

## Methods
- Band-pass: Christiano-Fitzgerald asymmetric (mFilter::cffilter, root=FALSE, drift=FALSE), applied to each series over its own span. Medium term = 12-40 y component. Table 3 ("2-12 year fluctuations removed") = log series minus its 2-12 y CF component (i.e. low-frequency series including trend). Both readings of the table label are ambiguous.
- Table 2 b: centred 5-year moving average of logs (EViews @movav is trailing; trailing gives identical F, since it only shifts the index).
- Bounds F: unrestricted-ECM, case III (unrestricted intercept, no trend), "lag of four" read as ARDL(4,4): 3 lagged differences of both y and x plus contemporaneous dx. F tests y(t-1)=x(t-1)=0 (2 restrictions). Sensitivity with 4 lagged differences: `output/bounds_F_all.csv`, column F_p5. "Ships -> X" = equation with X dependent.
- Long-run coefficient theta = -b_x/b_y from the same UECM. Conventional OLS delta-method SE is the published analogue (value/se in results_r.csv). Newey-West (lag 4) and HC1 delta SEs are in `output/table5_longrun.csv`.
- Critical values: PSS tables not available; simulated (4000 reps, n=90, null y random walk; x AR(0.5) for lower, random walk for upper): 5.00 / 5.96. The paper's quoted [2.86; 4.01] are not reproduced by simulation under this design. The text_p22_crit rows hold the simulated values.

## Observations (not tuned)
- Medium-term F statistics are in the hundreds (e.g. 235 for ships->wheat reaped vs paper's 61.77). CF-filtered series are smooth, near-deterministic cycles, so lagged levels dominate. Unlike the paper, nearly every cell is "significant". I did not search for settings that lower them (e.g. other filter variants or lag orders); a variant of the filter in EViews (fixed-length, CF options) is the likeliest source of the gap.
- Sensitivity bands (output/sensitivity_bands.csv): 2-8 y and 12-20 y results are also very large; the paper's statement of "no significantly different results" is not testable.
- Long-run coefficients (Table 5): ships->wheat 1.46 (VDR), 2.90 (Brunt), ships->exports 1.51, ships->vines 3.04, all with small conventional SEs. Compare paper 4.53, 2.18, 2.88, 1.46.

## Unavailable / approximate
- Table 1 (all T1_* rows): Schutte (1980) survey, not in the allow-listed data. Unavailable. Includes vdr_n totals.
- text_p5_nonprimary, text_p5_voc, text_p7_visitors: derive from the survey/other sources; unavailable.
- text_p4_exportshare: crude 100*sum(exports)/sum(wheat reaped), 1740-80 (80%); the paper uses "adjusted" production with correction coefficients, so not comparable. Treat as approximate.
- text_p7_burghers: men+women+boys+girls from VDR "Population" sheet (1720: 2063; 1770: 8088; 1795: 14929).
- text_p20_*, text_p22_lag: restated design parameters (not estimates).

## Post-hoc log
1. Critical-value simulation first specified both bounds with stationary/random-walk pairs (y not I(1) under the null); gave lower > upper bound. Fixed so that y is a random walk under H0 (as in PSS). No other changes.
