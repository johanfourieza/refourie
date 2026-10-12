# P05_DK — S3 independent R recreation: decisions

Agent: S3 recreation subagent (Claude Opus 5.5), 11 October 2026.
Inputs: the paper (PDF + wiki markdown), `claims/claims.csv`, `claims_spec.md`, PROTOCOL.md, CLAUDE.md, and only the data files on the coordinator's allow-list.
No original code, logs, compare/ or audit.md were opened. The recreation is **not outcome-blind**: the published numbers are in `claims.csv` and were seen before the scripts were written.

## Independence level

- **Table 1, Table 3, Figs 1–4: `full`.** They are built from raw sources: Phillips (1984) Table 13 (mortality), the 1911 populations in `RSA_Pop_1904_70.shp`, the 1918/1937 district shapefiles, the 1907 railway shapefile, monthly district rainfall from 1910 to 1950, the 1936 census volume tables (Tables 1 and 7), and the 1960/1970 census microdata. The fallback `data/processed/all_covariates.csv` is **not** used in any estimate. I read only its header, to check whether it held maize or unemployment data. It holds neither.
- **Table 2 / Fig. 5 (voters' roll), Table 4 (maize yields), Fig. 6 (1980/1996/2011 census microdata): `unavailable`.** None of their source data is on the allow-list. The only voters'-roll file sits in the denied ELIE `.dta` aggregates, and no maize-yield file is allowed. These claims are reported with `status_override = unavailable`.

## Decisions fixed before estimation (pre-declared)

### Unit of analysis and the mortality crosswalk
1. Mortality is deaths per 1,000 (Oct–Dec 1918) from column 7 of Phillips Table 13 ("DEATHS/1000 OF POPULATION"), used as printed. I do not recompute it from deaths and population.
2. Region is the block of Phillips Table 13 in which the district appears: Cape, Transkei, Natal, Zululand, Transvaal, OFS. Cape is the omitted category.
3. Phillips rows are matched by name to `SA_1918.shp` polygons (`StndrdN`) through an explicit crosswalk in `01_clean.R`. When Phillips reports a combined unit, it maps to the 1918 polygon of the first-named district (e.g. "Albert & Venterstad" → albert), because Venterstad, Lady Grey, Klipdam and the others are not separate polygons in 1918.
   - **Paarl/Wellington** is the only Phillips row that covers two 1918 polygons. I **dissolve** paarl + wellington into one unit, so mortality, population and area refer to the same territory. The rainfall file has no wellington series, so the unit takes paarl's rainfall.
   - **Richmond (Natal)** has no polygon in `SA_1918.shp` and drops out. **Lower Umzimkulu** has a polygon but no Phillips row, so it has no mortality and drops out.
   - The resulting N may differ from the published 205. I accept whatever N the data give and report the difference.

### Covariates (1911, 1907, rainfall)
4. **1911 population shares and density.** Source: `RSA_Pop_1904_70.shp` (W_1911, B_1911, C_1911, A_1911). I interpolate these counts by area weighting onto the 1918 units (`sf::st_interpolate_aw`, extensive = TRUE) in an equal-area Albers projection for South Africa (lat_1 = −24, lat_2 = −33, lon_0 = 24, WGS84).
   - Black share = B / (W + B + C + A). Coloured share = C / (W + B + C + A). Asians are in the denominator but in neither share.
   - Density = (W + B + C + A) / area of the 1918 unit in km².
   - Ambiguity: the paper does not say whether "Coloured" includes Indians/Asians, or which 1911 tabulation it uses. **Sensitivity (not primary):** Phillips Table 13 gives B(1911) and I&C(1911) directly for each 1918 unit. Shares from that source use the Phillips TOTAL as denominator (white population there is 1918). This version is reported in `output/sensitivity.csv` only.
5. **Distance to rail.** Distance in km from the centroid of each 1918 unit (computed in the Albers projection) to the nearest 1907 railway line. The railway shapefile has no CRS; its coordinates are longitudes and latitudes, so I assign WGS84. **Primary:** lines that existed in 1907 ("Cape Government Railways…" and "Other Railways"). I exclude features labelled "Do. under construction authorised or proposed". Sensitivity: all features. Regressor: log(1 + km).
6. **Rainfall.** `rain_monthly_1910-1950.csv` is already at 1918 districts (`iaa_cod`). The values are mm, on the evidence of the magnitudes (a Sep/Oct monthly mean of about 43). The regressor is the mean of the monthly September and October values over 1910–1950, divided by 10 to give cm ("Avg. Sept/Oct Rain in Cm"). Ambiguity: "average Sept/Oct rainfall" could also mean the Sep+Oct sum. With the sum, the coefficient would be half as large; I note this but use the mean.
7. **Transforms**, as named in the table rows: log(1 + density), log(1 + km to rail), and shares in levels. Table 1 cols 2 and 4 use log(deaths/1,000). Table 3 uses log(deaths/1,000) as the regressor.

### Table 1
8. OLS, region dummies (Cape omitted). The published SE is HC2 (stated). I report HC2 as the primary SE and conventional OLS SEs alongside (`output/T1_se_both.csv`). The F statistic and R² are the conventional OLS ones (df = k, N − k − 1).
9. **Outliers (cols 3–4).** The paper says only "three outliers excluded based on standard diagnostic tests (residuals vs. fitted value plots and Q-Q plots)". Pre-declared rule: drop the three observations with the largest absolute externally studentised residuals (`rstudent`) from the col 1 (levels) model, and drop **the same three** in col 4. Sensitivity: in col 4, drop the top three from the col 2 (log) model.

### Table 3
10. Outcome: white unemployed in the 1936 census (Table 1, "EUROPEANS" M/F/P) divided by the white population aged 15–64 (Table 7: single years 15–20 plus the groups 21– to 60–). **Total** = persons/persons; **Women** = females unemployed / females 15–64; **Men** = males/males. Ambiguity: the paper names only "the total population of working age white residents". Gender-specific denominators are my reading for cols 2–3.
11. 1936 districts → 1937 polygons by name (manual fixes for misspellings: Fort Beufort, Graff-Reinet, Peddle, Victorica East, Vryheld, Barbeton, Bethulile, etc.). Counts are interpolated by area weighting from 1937 polygons onto the 1918 units, and the rate is formed after aggregation. Walvis Bay and the 1937 polygons with no 1936 row (Clocolan, Umlazi) contribute nothing.
12. Regressors: log(deaths/1,000) + the Table 1 covariates + region FE. HC2 SE primary; conventional SEs reported.
13. Footnote 11 conversions: change in pp for a doubling = β × log(2) × 100. Computed from my unrounded β.

### Figures
14. Fig. 1: choropleth of deaths/1,000 on the 1918 units, with region outlines. Fig. 2: four maps of the covariates. Fig. 3: bivariate scatter of each covariate against deaths/1,000, with a loess smoother (default span 0.75). Fig. 4: unweighted counts by year of birth (census year − age) in the 1960 census (White, Coloured, Indian/Asian files) and in the 1970 census (African 5% file + W/C/A full count), 1910–1930. Figures follow LEAP style and are saved as PDF + PNG.
15. Census microdata and other restricted files: only aggregate counts are written. No rows go to outputs.

### Text claims
16. `txt_p174_ndistricts` = number of polygons in `SA_1918.shp`. `txt_p174_commission` = sum of Phillips "TOTAL DEATHS" over all rows. `txt_p189_iqr_p25/p75` = unweighted 25th/75th percentiles (R type 7) of deaths/1,000 across the estimation units. `txt_p181_black40` = T1 col 1 Black-share coefficient. `txt_p190_u_total/u_men` = footnote-11 conversions. The rest (6%, 300,000, GDP growth, agricultural shares, the 3.27 million women, the Fig. 6 IQR effect, maize numbers) need sources outside the allow-list. They are marked `not-attempted` or `unavailable`.

## Run record (first and only estimation run, 11 Oct 2026)
- Units: 206 (Phillips has 207 rows; Richmond (Natal) has no polygon; Paarl and Wellington are dissolved into one unit; Lower Umzimkulu has no mortality). All covariates and the 1936 rates are non-missing, so N = 206 in T1 cols 1–2 and T3, and 203 in cols 3–4. The published N is 205/202, so one extra unit enters here. I cannot identify it without the original code.
- The pre-declared outlier rule dropped Alexandria, King William's Town (+Keiskammahoek, Middledrift) and Libode. The col 2 rule would drop Knysna, Ingwavuma and Namaqualand instead (sensitivity file). Because the col 4 outliers are chosen from the levels model, the col 4 HC2 SE stays at 0.71, against 0.483 published. Choosing them from the log model gives 2.03 (0.47).
- Phillips total deaths = 162,182, not the 139,471 the Commission reported. Phillips Table 13 holds Phillips's own estimates, so `txt_p174_commission` is not reproducible from this file.

## Post-hoc changes log
- **None made.** One observation is recorded here without changing the specification: my rain coefficients are almost exactly 10× the published ones (T1 col 1: −1.636 vs −0.139; T3 col 1: −0.0038 vs "−0.000"), while every other coefficient is close. The published regressor was therefore probably in **mm**, despite the row label "in Cm". The pre-declared cm scaling is kept in `results_r.csv`. This is a pure rescaling: dividing my rain coefficient and SE by 10 gives the mm version, and no other estimate changes.
- Tables are written as `.tex` by modelsummary (tabularray backend). Compiling them needs the preamble lines that modelsummary prints.
