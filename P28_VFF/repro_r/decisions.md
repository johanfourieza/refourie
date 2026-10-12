# P28_VFF — S3 recreation decisions (written before systematic comparison)

**Independence level: `conditional`.** Only the authors' analysis file (`data.dta`, 138 rows; `data.csv`, 202 rows of which `sample==1` gives the same 138 ids) was available, so the data construction (areal weighting to 1911 boundaries, logs, homeland shares, gridded geography) is shared with the original. No .do/.log/.smcl or output files were opened. The recreation is **not outcome-blind**: the published numbers were visible in `claims.csv` and the paper.

## Sample
- `data.dta` is used as delivered (138 districts, all `sample==1`). Matches the paper's N = 138 and the "exclude the semi-arid west" rule; no further filtering. No weights (none mentioned).

## Variable mapping (paper definition → file variable)
Chosen by the paper's text and table notes, using the Stata variable labels.

| Paper | Variable | Basis | Alternatives present |
|---|---|---|---|
| Settle1830 ("binary variable representing dominant black settlement") | `bl100` (label "Settle1830") | binary + label | `settled1830` (a continuous share in [0,1]; `bl100` = 1 exactly when `settled1830` = 0), thresholds `bl90`…`bl50` |
| Pop1911/1996/2011 ("logged black population densities") | `l_pop1911`, `l_pop1996`, `l_pop2011` (labels match) | label; = log(popdens1911), log(p_96/area), log(popdens2011) | log(p_11/area) differs from `l_pop2011` (max 0.10) — not used |
| Unem1996 / Un1996 ("logged broad unemployment rate") | `l_u1996` (label "Un1996") = log(`u_96`) | label | log(`u_96_old`) (max diff 0.067) |
| **Unem2011 / Un2011** | `l_u2011` = log(`urate2011`) | **Two variables carry the label "Un2011"**: `l_u2011` and `l_u11` = log(`u_11`); corr 0.992, max diff 0.12. Chose `l_u2011` because it belongs to the naming series (`l_pop1911/1996/2011`, `l_u1996/2011`) that defines the other table variables. The paper gives no way to distinguish them. | `l_u11`; sensitivity in `output/sensitivity_alt_unemployment.csv` (also with `u_96_old` for 1996) |
| Light1996 / Lights96 | `l_lights96` (label "Lights96") = log(`lig96`) | label | — |
| Light2011 / Lights2011 | `l_lights11` (label "Lights2011") = log(`lig11`) | label | log(`lights2011`) (an older shapefile mean) |
| Rain ("long-run precipitation levels") | `rain_level` (label "Rain", mm) | "levels"; label | `l_rain` |
| Rugged ("index of terrain") | `tri` (label "Rugged") | label | `l_tri` |
| Soil ("caloric suitability index") | `csi` (label "Caloric Suitability") | index, not logged | `l_csi` |
| Homeland ("proportion of the district … in an apartheid homeland") | `p_homeland` (label "Homeland") | label, share | — |
| NetMig11 ("inverse hyperbolic sine of the number of net migrants") | `l_netmig_11` (label "NetMig11") | label; equals asinh(`nm_11_raw`) to 1e-7, i.e. a count, as the note says | asinh(`nm_11`) (a rate) — not used |

## Specifications (from table layouts)
- Table 1: Pearson correlations on the 138 districts (type not stated; Pearson assumed).
- Table 2: (1) Pop1911~Settle1830; (2) +Rugged+Rain; (3) Homeland~Pop1911+Rugged+Rain; (4) Pop1996~Pop1911+Homeland; (5) +Rugged+Rain; (6) Pop2011~Pop1911+Homeland; (7) +Rugged+Rain; (8) Pop2011~Pop1911+Homeland+Pop1996; (9) +Rugged+Rain.
- Table 3: outcomes Un1996 (1–2), Lights96 (3–4), Un2011 (5–8), Lights2011 (9–12); base Pop1911+Homeland; even columns of each pair and cols 7–8/11–12 add Rugged+Rain; 7 and 11 add Pop2011; 8 and 12 add Pop2011+NetMig11.
- OLS with intercept (fixest::feols).

## Inference
- Paper does not state the SE type. `results_r.csv` reports **iid** SEs (treated as the published analogue; Stata `reg` default). HC1 and Conley SEs are in `output/results_r_se_types.csv`.
- Conley: 100 km cutoff, uniform kernel, great-circle distance, centroids `x_cent`/`y_cent` from the analysis file (label "x/y-coordinate of area centroid"). Checked against polygon centroids of `1911_dc.shp`: 135 name-matched districts, median distance 0 km, max 1.6 km. fixest `vcov_conley` used; `conleyreg` cross-check for headline columns in `output/conleyreg_crosscheck.csv`. Footnote 4's Hsiang (2010) implementation and its small-sample conventions are unknown, so Conley SEs are for later use only.
- F statistic: model F with iid VCOV (fixest `fitstat(.,"f")`), the analogue of Stata `reg`'s F.
- N claims printed "138.000" are compared as 138.

## Not attempted
- TXT_* claims (shares/counts cited from the literature or history: 1913/1936 land shares, 3.5m relocations, 4% growth, WDI ranks, 2.8m ha, "a third of South Africans" in homelands). They are not computable from the analysis file (no national population totals; only the eastern 138 districts). Status `not-attempted`.

## Data cross-check
- Pop1911: Bantu persons (urban+rural, male+female) from `Census 1911.xlsx` ("Return of Population") divided by `area`, for 105 exact name matches. 41% agree within 1%; most others differ by 1–25% (likely district boundary/name harmonisation or a different population column in the authors' construction); duplicate names (Middelburg) break the match. Not used to alter the analysis file; noted only. See `_scratch/check_pop1911.csv`.

## Post-hoc observations (after first run)
Added after the first run. No specification or variable choice was switched.

1. Spot check (headline rows only, not the S4 comparison): T2_r2_c7 = 0.8234 (iid SE 0.0816), T3_r2_c6 = 0.2274 (0.0409), T3_r2_c10 = -2.0254 (0.3538), all N = 138. These coincide with the published values. HC1 SEs (0.137, 0.042, 0.385) do not, so the published SEs look like iid OLS SEs.
2. Alternative Un2011 (`l_u11`, with `u_96_old` for 1996) gives Homeland coefficients of 0.271 / 0.230 / 0.231 / 0.146 in cols 5–8, against 0.269 / 0.227 / 0.228 / 0.138 published. The primary choice (`l_u2011`) is the closer fit. This is recorded post hoc and was not used to choose.
3. Conley 100 km: fixest `vcov_conley` and `conleyreg` (uniform kernel) agree to about 1–2% (for example, Pop1911 in T2 col 7 gives 0.150 vs 0.148). The gap reflects different small-sample conventions.
4. Maps (`03_figures.R`): all 138 analysis-file centroids fall inside a 1911_dc polygon.
