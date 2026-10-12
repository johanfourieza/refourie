# P30_STB24 S6: deviations from the frozen method card (A5)

Card: `modern/method_card.md` v3, frozen at commit d59616d. The entries below are forced implementation choices or resolutions of points the card leaves open. Unless stated otherwise, each was decided while writing the code, before the quantity it touches was computed. No entry changes a margin, a window, a family, a verdict rule or the primary estimator.

**D1. H1: `hh_id` excluded from the data columns** (results informed: no). The card defines the data columns of the non-observation rule as "all numeric columns except `year`, `row` and `nr`". S3's `households.rds` also carries `hh_id`, a row index (`repro_r/01_clean.R` l.269, `mutate(hh_id = row_number())`) that is positive on every row. Included, it would make the rule vacuous (no row could be removed). It is excluded as an identifier, not a data column. The choice was made from the column definition, before N was computed.

**D2. H5 jackknife units and the minimum-years rule** (results informed: no). The card defines units as the census years in which "the quantity is defined" but H5 means use available-case sets that can differ by category (§3 H5). Implementation: (a) the units of a window are all its census years (every pre-1830 census year has owner rows with men recorded, so each year contributes to at least one mean of every contrast); in a replicate, all drawn occurrences; (b) the five-year minimum is applied to each mean in a contrast: the category must be recorded among owner rows in at least five census years of the window (for ΔC, complete cases). All 19 contrasts pass.

**D3. Undefined occurrences inside a replicate** (results informed: no). H2: a drawn year in which an asset is not recorded is not a unit for that asset (as in the original data); if no drawn year records it, the draw fails. H4: a drawn occurrence whose wine Gini is undefined (Σx* = 0) makes θ* non-finite, so the draw fails. Failure counts are reported in `h2_primary.csv`, `h4_primary.csv` and `h5_primary.csv`.

**D4. H5 within-year resampling** (results informed: no). "Resample its rows" is implemented as resampling all rows of the drawn census year (owners and non-owners) and then computing the owner-household statistics, so the number of owner rows varies across draws, as the household process would.

**D5. Interval type for s5B items 1 and 4** (results informed: no). The card does not state the interval for the within-year (years fixed) and name-cluster (years fixed) designs. With census years fixed, the delete-one-year studentizer does not measure the resampled variation, so these diagnostics report the bootstrap SD and the equal-tailed percentile interval at the family level. Item 3 (year blocks) uses the card's two-stage percentile-t with the window-stratified jackknife. All diagnostic designs use B = 19,999 and the card's seed.

**D6. s5B item 5, "the number of drops that would change its verdict-table row"** (results informed: no). Re-running the bootstrap for each of about 400 leave-one-out data sets was not pre-specified and is not needed for a diagnostic. For each dropped census, θ and the window-stratified jackknife SE are recomputed on the reduced data and combined with the primary t* quantiles of that contrast; the resulting interval is classified with the same §8 category rule.

**D7. s5C items reported as point estimates** (results informed: no). The card lists no interval design for §5C. Each item is reported as a point estimate with its finite-population classification (`supp_5A_5C_points.csv`, `supp_5C13_15_h5.csv`, `supp_5C5_loglinear_trend.csv` with Newey–West SEs as the card states).

**D8. s5D operationalisation** (results informed: no). "The census's vine count" = the census total of `vines`. "Adjacent censuses" = the previous and next census years in the file, exact match on `names_men`. The per-entry table with household names stays on D: (`modern/_scratch/supp_5D_capped_entries_with_names.csv`, A6); the Dropbox copy omits names.

**D9. H2-anchor label** (results informed: no). The card lists inside / below / above [2.97, 3.63]. An interval that straddles a band end would be labelled "overlaps"; the realised interval lies entirely below the band, so the label used is "below".

**D10. Script layout** (results informed: no). The card's script names are kept (01–08). Added: `00_common.R` (shared functions: build with K1–K5 switches, weighted Gini, jackknife, resampling designs) and `09_figures.R`. s5E is produced in `02_h1_count.R`; s5B items 1, 3, 4 and 6, S-b and S-d in the claim scripts 03–06; everything else in `07_supplementary.R`.

**D11. Name key for s5B item 4** (results informed: no). The S3 rule-15 surname parser (`repro_r/02_analysis.R` l.112–127) is re-implemented in base R with the same rules; given names = the text after the comma, or the tokens before the surname. Rows with no man's name are singletons.

**D12. Weighted Gini in the bootstrap** (results informed: no). Resampled Ginis are computed from multinomial row counts on the pre-sorted values with a closed form that equals `ineq::Gini` on the expanded sample (checked to machine precision). This is a computational device, not a change of estimator.

**D13. Runtime and Monte Carlo escalation** (results informed: no). The whole pipeline (01–07, all designs at B = 19,999, 8 workers) ran in about 6 minutes, so no replication count was reduced. No verdict-relevant endpoint lay within 2 MC SE of a §7 boundary, so the B = 49,999 escalation of §4 was never triggered and no row is MC-fragile.
