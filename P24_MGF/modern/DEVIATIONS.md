# P24_MGF S6 deviations from the frozen method card (v3, commit 3c93b12)

None of the choices below was informed by results; each was fixed while writing `01_reanalysis.R`, before the first run.

- **D1. Register year.** The card lists eight register years. The 1905/1910 workbook carries a year per record and is split on it; for every other file the register year is taken from the file name, so the four entries dated 1926 in the 1925 register file count as 1925. The one 1919 record (a black boy under five) is dropped as the card requires, which moves the black 0–59-month count from S3's 1,210 M / 1,115 F to 1,209 M / 1,115 F. Results did not inform this choice.
- **D2. Tests reported in verdict.csv.** The card names intervals but no test statistic. Reported (non-voting) p-values: exact two-sided binomial test of p = 0.5 for K04, K04-ex and K18-ex; two-sample score test (chi-square, no continuity correction) for KBW; none for the census rows. Results did not inform this choice.
- **D3. Wild bootstrap details (sensitivity 2).** The card gives no B or level. Implemented with fwildclusterboot 0.14.3 (`boottest`, Webb weights, B = 9,999, seed 20261012, clusters = register year). The interval is at 98.33% to match the primary. d04 and d18 come from an intercept-only regression of (male − 0.5); Δ18 comes from a linear probability model of male on a black indicator (black and white children aged 18–59 months). Results did not inform this choice.
- **D4. "Top-20 raw strings" (sensitivity 3b).** Taken in order of frequency from `repro_r/output/race_crosswalk_counts.csv`, which counts all records at all ages. The list contains "Indian", which maps to asian_other and so drops out anyway. Results did not inform this choice.
- **D5. Missing-record deficit (sensitivity 5).** m = N_pub − N_rec uses the S6 sample after the D1 drop (black 0–4: 3,137 − 2,324 = 813; black 18–59m: 621 − 493 = 128; white 18–59m: 147 − 134 = 13). Results did not inform this choice.

No packages installed. Runtime under one minute.
