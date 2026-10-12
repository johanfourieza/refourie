# P14_QC S3 decisions (Tier 3, source audit)

**Independence level.** Low by construction. The only surviving input is the article's released workbook (`original/Fourie Kronos/Fourie Quantitative Cape.xlsx`, on D:). It holds the collated secondary series and the formulas that produce the text's growth rates. I treat the workbook's result cells as the "original code" output (`results_original.csv`) and recompute each number from the underlying series cells with my own R code (`results_r.csv`). I did not open the drafts, the ERSA working paper or any other output. I read P27_RW/claims/claims.csv (published EHR 2013 values) only to check the cited sources.

**Reading.** tidyxl, one sheet at a time. Reading all sheets in one call crashes R (segfault, probably the chart sheets and the broken chart relationship noted in S1). The workbook has 5 worksheets (Citation information, Population, PopulationGroups, Demographic, Growth). The other names listed in S1 (SAF, Growth comparison, GDP comparison) are chart sheets with no cells. 291 formulas: `output/formula_inventory.csv`.

**Choices.**
1. Growth rates are compound annual rates, `(end/start)^(1/years) - 1`, the workbook's formula. Years follow the text's windows (1663–1795 = 132; 1701–1795 = 94; 1708–1789 = 81).
2. `TX148_popgr` splices the Fourie–Von Fintel series (1663 = 133, Population!C) with the Van Duin–Ross series (1795 = 14,952, Population!B), as the workbook does in I2:I5. I keep the splice and report the overlap ratio (FvF/VD&R: mean 1.005, range 0.95–1.07) in `output/internal_checks.csv`.
3. `TX149_voc_gr2`: I use the 1708 value (513) as the base, as the text states. The workbook formula W8 uses the 1701 value (531). The corrected rate is 2.36 per cent, not 2.32.
4. Slave counts: the text's numbers (1,838 and 21,474) are in the column labelled "Slaves (Shell)". I recompute from that column and report the "Slaves (VD&R)" column as a check.
5. Table 1 Obs.: no formula exists, so I recompute N from the table's own SD and SE columns (Demographic!N:O), N = (SD/SE)^2. The means and medians are hard-coded, and the GISA microdata needed to recompute them do not survive, so they are `unavailable` in R. The workbook cell values are in `results_original.csv`.
6. Text roundings (`TX151_ls_first`, `TX151_ls_last`) are recomputed by rounding Demographic!L2 and L7.
7. Figure 5: I checked the Growth sheet's 5-row centred moving average (`output/fig5_ma_check.csv`) and compared decade means of the yearly zero-slave series with the published EHR Table 5 all-household means (`output/fig5_vs_P27_T5.csv`). No claim value comes from these checks.

**Impossible.** Life-span means and medians, Fig 4 (no GISA microdata); the paintings shares, the 24/12/10 asset shares, 2,577 households, 28 products and 526 zero-slave households (inventory and auction microdata are held in P27, not here); Khoesan 1660 maximum, 937 convicts, the fiscal ratio, Huguenot families, the 10 generations and the archival counts (9 servants, 75 volumes, 5 auction volumes, f600 cut-off). These have no data in the workbook and are `unavailable`.
