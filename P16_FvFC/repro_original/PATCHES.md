# P16_FvFC repro_original: patches

No analysis code for this paper survives (S1), so nothing was copied or patched. `original/Statafiles/creatingslavegroups.do`
is PhD-era code (it post-dates publication, reads the later `opgaafrolle.dta` and drops 1682 and 1716, which the paper keeps). It is not this paper's code and was not run.

## Environment steps (no diffs)
1. **Format conversion.** tidyxl reads only xlsx. `original/Wealth inequality/Ginis.xls` (BIFF8) was opened read-only in Excel through COM and saved as
   `D:/Data/ReplicateMe/P16_FvFC/repro_original/_scratch/Ginis_conv.xlsx` (`Workbooks.Open(src,0,$true); SaveAs(dst,51)`). The original was not modified.
2. `s2_ginis_check.R` (written for S2, not an original file) extracts the formula chain and recalculates it. Sheet1 has 20 formulas, `F3:F22 = G{r}*100`.
   `G3:G22` (the Cape Gini series) and cols A-C (comparison Ginis) are typed constants, so there is no upstream chain to recalculate. Recalculated F equals cached F (max diff 0).

No A' alignment run.
