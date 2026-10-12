# P21_LFG S6 deviations from the frozen method card (v3, commit d240e89)

- **D1. Seeds for items 6 and 15.** The card fixes the primary seed only. Items 6a, 6b and 15 use `set.seed(20261012 + 61 / 62 / 15, kind = "L'Ecuyer-CMRG")`. Chosen before any sensitivity draw was run; not informed by results.
- **D2. Cluster audit not committed before the bootstrap.** Card §4 requires `00_cluster_audit.R` and `cluster_audit.csv` to be committed before any bootstrap. The wave-3 instructions forbid commits by the implementer. The audit was written and run before `01_primary.R` existed; its output (7,688 clusters, no missing `index`, no within-year repeats) did not alter the fixed cluster definition. Not informed by results.
- **D3. `lm.fit` in place of `stats::lm` (card §6).** Same design matrix and column order as `repro_r/02_analysis.R`; used for speed in ~33,000 bootstrap fits. The reproduction check matches S3 to 2.2e-16. Rank deficiency is detected via the QR rank (equivalent to an NA coefficient in `lm`). Not informed by results.
- **D4. Verdict-table "test p".** The card defines no p-value. `verdict.csv` reports the largest per-year one-sided normal p for c_t ≤ 0 (unadjusted). It does not decide anything; the band rule (§8A) does.
- **D5. MC precision computed for all years.** Card §4 asks for MC SEs of "the decisive years". The script computes them for L_t and U_t in all 22 years per pair (a superset) and flags any within 2 MC SE of 0.
- **D6. Bootstrap parallelisation.** All cluster draws come from the one sequential L'Ecuyer stream in the main process (as the card requires); only the refitting runs on 6 workers. Runtime 0.4 min (primary) and 0.6 min (items 6, 15); B was not changed.

No package was installed. No analysis outside the card was added.
