# P23_MBF — S3 independent R recreation: decisions

Written 11 October 2026, before any systematic comparison with the published tables. The agent has seen the published numbers (in the paper and `claims.csv`), so the recreation is **not outcome-blind**.

## Independence level: **conditional**

The only data on the allow-list are the authors' analysis file `1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta` (5,732,407 IPUMS individuals, already restricted to the 11 countries, ages 12–72 and birth decades 1920–1970, with region-level controls merged in) and the ALTT leader tracker. No .do file, log or shapefile was seen. The individual outcome, cohort and exclusion variables are rebuilt from raw IPUMS fields (`age`, `cyear`, `edattain`, `yrschool`, `sex`), but the leader birth-region dummies (`d_birth_all`, `d_birth_coup`, `d_birth_elite`) and all geographic controls are taken as coded by the authors. The data construction is therefore shared with the original.

## Ambiguities and choices

| # | Issue | Choice |
|---|---|---|
| 1 | Outcome *Primary* | `edattain` ∈ {2,3,4} (primary, secondary, university completed) = 1; `edattain` = 1 = 0; unknown (9) = missing. |
| 2 | Year of birth | `cyear − age` (IPUMS gives no birth year). Age at independence = `independence − yob`. |
| 3 | Pre-Independence and exclusion | PreIndep = 1 if age at independence ≥ 14 ("turned 13 before independence"), 0 if ≤ 5 ("turned 6 after"); those aged 6–13 in the independence year are dropped. |
| 4 | Individual controls ("age, age squared, sex, religion and rural") | age, age², female dummy, rural dummy, and religion as two dummies (Muslim, Christian; reference = other/none/unknown). The raw `religion` field is missing for Kenya and Tanzania (1.98 m rows); entering it as a factor would drop those countries and could not give N = 5,077,010. |
| 5 | Geographic controls ("8"; the note lists six) | The six named (tsetse growth rate `tse_r`, railway density, number of tribes, enslaved-persons density, missions dummy, distance to capital) plus the two others named in Sections 4.1 and 6: western-Africa dummy and capital-region dummy. |
| 6 | Fixed effects | Country FE (table notes). Equation (1)'s γ_{i,c} is read as country FE. |
| 7 | Standard errors | Main: cluster-robust by birth region (`id_birth`, 624 units), as stated. Also reported: conventional (IID) ML SEs and HC1-robust. Stata-style small-sample cluster adjustment (fixest default `ssc`). |
| 8 | Pseudo R² | McFadden (1 − LL/LL₀), as Stata `logit` reports. |
| 9 | Table 3 col 1–2 (coup / elite leaders) | Birth Region = `d_birth_coup` / `d_birth_elite` as coded in the file. These are missing for birth regions of non-coup (non-elite) leaders, so those regions drop out; this mirrors the published N falling below 5,077,010. |
| 10 | Table 3 cols 3–4 ("Indep+2", "Indep+3") | Drop individuals whose primary-school ages 6–13 overlap [indep − k, indep + k], k = 2, 3, i.e. age at independence in [6−k, 13+k]. PreIndep then = 1 for age ≥ 14+k. |
| 11 | Weights | None in the regressions (none mentioned). Figure 3 is titled "weighted": `perwt` weights are used there only. |
| 12 | Table 4 unit and outcomes | Region (`id_birth`) × birth decade (`floor(yob/10)*10`), all individuals in the file (no independence-window exclusion; none is stated for Section 6). yrschool = unweighted mean years of schooling. Gini = Gini of individual years of schooling (Thomas et al. 2001 is equivalent to the standard Gini on the individual distribution). |
| 13 | ABCC | Whipple index over all ages in the region-decade cell: Wh = 100 × (share of ages ending in 0 or 5) / (expected share given the age span present in that country-decade; 0.2 for a full ten-year span). ABCC = 100 × (1 − (Wh − 100)/400) if Wh ≥ 100, else 100. No 23–72 age restriction (it would truncate the 1970s cohorts of early censuses). |
| 14 | Spatial weights | The paper uses first-order contiguity of region polygons. No shapefile is on the allow-list. I approximate contiguity by a Delaunay triangulation of region centroids (`lat_id_bir`, `lon_id_bir`), built separately for each decade's sample, row-standardised. Sensitivity: 5 nearest neighbours. This is a known deviation. |
| 15 | Spatial estimator ("generalised spatial two-stage least squares … spatial autoregressive error") | With no spatial lag of y, GS2SLS reduces to the Kelejian–Prucha (1999) GM estimator of ρ followed by spatial FGLS for β. Implemented by hand (spatialreg/sphet are not installed and installing packages requires approval). SEs: conventional FGLS. |
| 16 | Table 4 fixed effects | "Region fixed effects: yes" cannot be identified with one observation per region; read as country FE. ABCC col 1 is labelled "Country FE: No" and is run without FE; all other columns include country FE. |
| 17 | Table 4 "Pseudo R²" | Squared correlation between y and the fitted Xβ (Stata `spregress` convention). |
| 18 | Table 5 | Requires Murdock ethnic-region data (Roome missions, HYDE, Ethnographic Atlas controls), not on the allow-list. **Not attempted.** |
| 19 | Figure 1 (map) | Needs shapefiles; not attempted. Figures 2 and 3 are recreated. |
| 20 | Leader count (33) | From the ALTT CSV: distinct leaders in the 11 countries with `year_enter` 1960–1990. Interim leaders are included as listed; the paper's exclusions are not documented. |
| 21 | Text numbers | n regions = distinct `id_birth`; first-level regions = distinct `geolev1`; footnote 15 area SD/mean across regions, first-level areas = sum of `area_km2` within `geolev1`; 645/34 = distinct regions with yrschool by decade; balanced panel = regions observed in each of 1940, 1950, 1960 (footnote 21); Thyolo = (national − Thyolo)/national mean years of schooling (unweighted) in the 1940s and 1960s; "6 of 11" = countries where the birth-region mean (weighted) exceeds the others' mean in every pre-independence decade and in every post-independence decade. |
| 22 | Table 1 | Reported from the data (independence year, census year, birth-decade range in the file). |

## Data facts observed while building the sample (before estimation)

- The exclusion in item 3 reproduces N = 5,077,010 exactly (5,079,216 before dropping 2,206 unknown `edattain`).
- The census year in the file is 1991 for Uganda (Table 1: 2002) and 2009 for Mali (Table 1: 1998). Birth decades in the file run to the 1970s for every country (Table 1 says 1980 for Kenya, Malawi, Tanzania).
- 29 distinct birth regions carry `d_birth_all = 1`; 624 regions in total.
- ALTT: 49 distinct leaders entered office in 1960–1990 in the 11 countries (incl. interim), not 33.

- Found while fitting (no comparison yet): `d_muslim` and `d_christian` in the file are identical, and both equal 1 exactly when `religion` = 6 (Christian). The religion control is therefore a single Christian dummy; fixest drops the duplicate. `d_western` is constant within country and is absorbed by the country FE, so seven geographic controls are identified.

- No SE is reported for ρ: the Kelejian–Prucha GM step has no standard closed-form SE, and the published ρ SEs come from Stata's GS2SLS variance.

## Run order

`01_clean.R` → `02_analysis.R` → `03_figures.R` → `04_results.R` (assembles `results_r.csv`). `02b_posthoc.R` is the post-hoc variant below. `results_r.csv` holds only the **pre-specified** estimates: cluster SE in `se`, Delaunay W for Table 4. Conventional (IID) and HC1 SEs are in `output/tables23_logit.csv`, and the kNN-5 W results are in `output/table4_spatial.csv`.

## Post-hoc changes (after seeing own results next to the published tables)

1. **Table 3 cols 3–4.** The pre-specified run (all leaders, items 10 and 3) gives N = 4,768,856 / 4,601,669 with 624 clusters. The published values are 4,623,069 / 4,461,147 with 609 clusters, and 609 equals the elite-leader column 2. In `02b_posthoc.R` I re-ran cols 3–4 with Birth Region = `d_birth_elite`, using the same exclusion windows. This reproduces **both Ns and the 609 clusters exactly**, with BR .36 (.15) / .36 (.15) and BR×PI .37 (.18) / .38 (.17), against published .35 (.14) / .35 (.15) and .37 (.18) / .37 (.17). Output: `output/table3_c34_elite_posthoc.csv`. The published "Indep+2/+3" columns therefore appear to use the elite-leader sample, although the table labels their Leaders row "–". `results_r.csv` keeps the pre-specified estimates.
2. **Table 4 sample.** My region-decade panel has 593–624 regions in each decade from 1930 to 1970 and 148 in the 1920s. The paper reports 342/592/635/644/611 and a range of 34–645. Some published decade Ns exceed the 624 distinct `id_birth` values in the analysis file, so the published Table 4 was built from a different aggregate file (Table A8), which is not on the allow-list. I made no change; the difference is reported.
