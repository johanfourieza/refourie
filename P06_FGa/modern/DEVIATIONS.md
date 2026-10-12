# P06_FGa S6 implementation deviations (card frozen at 17a056d)

Each entry: what changed, why, and whether results informed it. "Results" means any modern estimate or verdict.
No CRAN packages were installed. Total runtime of scripts 01–07 is about 2 minutes, so no replication counts were halved.

**D1. Verification (b) target and tolerance (forced).** The S5 `wheat_units` values were produced with the rounded divisor 2.837757 (`compare/s5_checks/run_scenarios.R`), while card K2 uses 100/35.2391 = 2.83775692. With the card factor, 54 of 56 rows match to below 1e-6. Two rows (`A1_Massachusetts_crops`, `tx_p15_mass_total`, 37.2091) differ by 1.004e-6 (relative 2.7e-8). With S5's own factor all 56 rows match to 4.6e-13, so the residual is entirely due to the factor's rounding. I treat verification (b) as passed and record both checks in `output/verification.csv`. I also compare against `compare/s5_checks/scenario_results.csv` (the unrounded source of `s5_effects.csv`), because `s5_effects.csv` prints six significant figures and cannot support a 1e-6 absolute test. Against the printed values, the maximum relative difference is 3.9e-6. Results informed: no (only the verification output informed it, before any modern estimate).

**D2. Text "NA" cells (forced).** In `Combined`, Virginia `Sheep`, Maine/Massachusetts `Slaves` and early Cape `Brandy` hold the literal text "NA". The original code's `read_excel` (default guess_max) coerced them to numeric NA. I coerce them explicitly. Verification (a) confirms that this matches the original (8/8 headline rows to 1.4e-14). Results informed: no.

**D3. Mechanical K3/K5 and its consequences (interpretation; card text applied literally).** These decisions were fixed when `coverage.csv` was written, before any estimate. Results informed: no.
- (i) Virginia cattle are coded 0, not NA, in the 1795, 1806 and 1814 cells (and 98.6% zero in 1805). Under K3's NA-share rule, these cells are therefore *recorded*. No Virginia household is uncovered, and the coverage share is 100%, although the card (D5, §2(f)) anticipated 1795 as uncovered. Point estimates are unaffected, because these households are non-farmers either way: there are 2,879 covered Virginia farmers, equal to the original Table 1 N. In the bootstrap, they are resampled as non-farmers (domain estimation).
- (ii) Virginia `Cornreaped` has a 0% NA share (all zeros), so it is "recorded" under mechanical K3. I follow card K5/C7, which treats all Virginia grain as structurally missing. This makes no numerical difference, because the values are zero. `coverage.csv` shows the mechanical status with a note.
- (iii) K5 ("every variable that decides its eligibility and its outcome is recorded") also bites in the Cape. Oats are structurally missing in Graaff-Reinet 1787 and Stellenbosch 1785/1795, and rye and oats in Graaff-Reinet 1798. The outcomes of H1, H2 and H5 contain these grains, so those cells' 4,973 households (2,928 farmers) are uncovered and excluded from H1, H2 and H5. They remain in H3/H4/H4w, whose eligibility uses recorded grains only (K4). The card discusses coverage only for Virginia, but its rule is general, and I applied it as written.
- (iv) As a consequence, diagnostic D5 ("Virginia's uncovered households treated as zero") would be identical to the primary, so I generalised it to *all* uncovered households (the Cape cells above, NA = 0 as in the code). It remains diagnostic only.

**D4. Variables outside the K3 list.** `Wine`, `Brandy` and `Horses` are not in the K3 list, so NA = 0 (code convention). The Cape cells where brandy is missing (GR 1787/1798, Stb 1785/1795) coincide with the cells that are uncovered under D3(iii). Results informed: no.

**D5. Currency of the single-auction livestock prices (§5.3).** The `Averages` rows Auction1–4 are in rixdollars. As for V4 (where the card states the conversion), I convert them at the workbook rate 3.931055/3.561536 rd per $. Results informed: no.

**D6. Implementation details not fixed by the card (no deviation from a stated rule; recorded for transparency).**
- **Random streams.** Seeding uses one L'Ecuyer-CMRG stream per replicate, generated from `set.seed(20261011)` with `nextRNGStream`, so the results do not depend on the number of workers. The §5.14 superpopulation bootstrap uses streams 10,000–19,998. Its Virginia component in replicate b is the design replicate b.
- **Strata.** Rao–Wu strata are county (`Veldcornet`, verified row by row against the raw `County` field) × census `Year`. There are 48 strata, none a singleton, so there were no collapses and no dropped years.
- **Gini.** A weighted Gini (`wgini`) is used, which equals `ineq::Gini(corr = FALSE)` under equal weights. Verification (a) reproduces the Table 1 Ginis to 1e-14.
- **Undefined Ginis in §5.12.** Per-benchmark Virginia Ginis for 1795 and 1805 are undefined (no farmers, or no enslaved people among the 32 farmers) and are reported as not-testable.
- **§5.13 intervals.** §5.13 tail-trimmed Virginia contrasts are reported as point estimates only.
- **Level checks.** The H3 US level check (`tx_p13_cattle_us`) uses the primary estimand, the design-weighted farmer mean.

Results informed: no.
