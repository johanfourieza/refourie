# P04_CF S2 patches

Source: `original/CF Mobility/Data/CF mobility replication.do` (4 Oct 2016, 409 lines), copied verbatim to `repro_original/CF mobility replication.do`.
`OCCUP_to_L&F Groupings.do` and `OCCUP_to_HISCLASS.do` are reference copies only. They were not run, because they expect the 4-generation BCF file (`occupation`, `gf_occupation`, `ggf_occupation`), which is not part of this paper.
All run files are generated from that copy by `build_runs.sh`. Original lines are taken **unchanged by line range** (`sed -n 'a,bp'`); the only new lines are the environment lines listed below. Logs: `logs/run_*.log`.

## Environment patches

### E1. Header in every run file (`version`, ado path, data path)
```diff
+version 15
+clear all
+sysdir set PLUS "`c(pwd)'/ado/plus"
+sysdir set PERSONAL "`c(pwd)'/ado/personal"
+global D "`c(pwd)'/../original/CF Mobility/Data"
```
`version 15`: the do-file has no `version` statement and is dated 2016 (PROTOCOL S2). `outreg2` 2.3.2 and `mstdize` 1.2.0 are installed from SSC into the project-local `ado/plus` (see `env/stata_ado.txt`). The system ado path is not touched.

### E2. Data load (the do-file has no `use` line)
```diff
+use "$D/CF_mobility_replication_data_anonymized.dta", clear      // run_0, B, D, E
```
The anonymised file (5 Oct 2016, the day after the do-file) holds the *outputs* of do-file lines 14–145: `occ_group_first/last`, `f_occ_group_first/last`, `mobility_last`, `intra_mobility`, `period`, `psplit`, `share`, plus `origin`, `prov`, `f_gen`, `first_son`. Its `psplit` × class counts equal the frequencies hard-coded at l.184–201 cell by cell. It therefore is the dataset the analysis sections ran on.

```diff
+use "$D/SAF mobility data_10.08.2017.dta", clear                 // run_0b, A
+drop occ_group_last f_occ_group_last intra_mobility year period
+capture label drop class
+capture label drop per
+capture label drop mobl
```
The 2017 file is the only one with the do-file's *inputs* (`occ_group1–8`, `f_occ_group1–9`, `fathers_dob`). It also carries the 2017 derived outputs and value labels, so `gen`/`rename`/`label define` at l.30, 32, 61, 81, 108, 128, 137, 143 would stop with r(110). Dropping them restores the input state. Used only for the coding-version diagnostic (run A); no claim is taken from it.

**No merge of the two files was done.** They share no key: the anonymised file has a numeric `id` 1–9,494 and the 2017 file a string `individual_id`. A merge would require probabilistic linkage on dob/sibling rank etc., which is an analytic step, not an environment patch.

### E3. Section split (sections that do not depend on failing code)
The full do-file cannot run end to end on any surviving dataset (run_0, run_0b; see "Failures" below). Sections were run separately:

| run file | original lines | data |
|---|---|---|
| `run_A_derive2017.do` | 1–157 | 2017 file (E2) |
| `run_B_tabs2016.do` | 145–157 | anonymised file |
| `run_C1_altham_prelude.do` | 159–365 | none (fails at l.171, kept as evidence) |
| `run_C2_altham.do` | 167–168, 180–365 | none (frequencies hard-coded) |
| `run_D_dropfarmers.do` | 367–378 | anonymised file (fails at l.374) |
| `run_E_logit.do` | 380–409 | anonymised file + E4, E5 |

`run_B` also appends one diagnostic line, labelled as not original code: `bysort psplit: tab f_occ_group_last occ_group_last, row`, i.e. l.178 run on data that still exists. No claim depends on it; it only documents that the hard-coded frequencies match the data.

### E4. Missing `origin_occ_group_share.dta` (l.383) regenerated from the analysis file
```diff
+preserve
+keep period f_occ_group_last share
+duplicates drop
+isid period f_occ_group_last
+save "output/origin_occ_group_share.dta", replace
+restore
+cd output
```
`share` already exists in the anonymised file and is constant within period × father's class (16 cells, `isid` passes). Because the master already holds `share`, `merge m:1` (no `update`) keeps the master values. The regenerated file therefore only lets l.383 run; it cannot change any estimate. All 9,494 rows matched.

### E5. Variable-name alias for model 2 (l.400)
```diff
+gen f_gen_dad = f_gen
```
Model 2 calls `i.f_gen_dad`, which is absent from the 2016 file. In the 2017 file the same variable is called `gen_dad` (mean 1.925637, identical to `f_gen`). Only do-file model 2 uses it, and no published column corresponds to that model (see audit), so no claim depends on this alias. Note: the alias does not inherit the `f_gen[omit] 2` characteristic stored in the dataset, so in model 2 `xi` omits category 1 (the coefficient's sign flips relative to models 1 and 3).

## Analytic patches
None. Nothing in the original lines was edited.

## Failures for non-environment reasons (left as found)
- `run_0_full`, l.30 `rename last f_occ_group_last`: r(110) on the anonymised file (the derived variables already exist). This is expected, because the file is the post-derivation state.
- `run_0b_full2017`, l.171 (`replace psplit = 1 if period == 1 | period == 2`): r(111). The `clear` at l.167 wipes the data before `psplit` is built and tabulated (l.170–178). This is a code-ordering bug.
- `run_C1`, same failure at l.171.
- `run_D`, l.374 `bysort p_split:` r(111): the variable is `psplit`. The block also contains no Altham code ("***re-estimate Altham statistics, then***"), and the do-file's own `preserve` at l.12 would make the `preserve` at l.370 fail with r(621) in a single run.
- `mstdize` block (l.255–276) runs, but `replace rt = `i'` / `replace ct = `i'` assigns the loop index 1–4 instead of the tokenized totals (`` ``i'' ``), so the margins are 2,4,6,8. The totals typed in (1541 4140 2110 1208; 682 5498 1875 944; N=8,999) do not match either sample table (N=4,470 / 5,024). The output table is meaningless and is not used.

## Excel recalculation (Tables 3–5 census columns)
`recalc_census.R` re-evaluates the formula chain of `Census_Comparisons.xlsx` (sheets `Summaries`, `1865 v. 1875`, `1891`) and `Census_1911_occupations.xlsx` (`Occupations Sub-Orders`) from their input cells, using a small evaluator for `+ - * /`, cell references and `SUM()`. All 30 formula cells reproduce their cached values exactly (`output/census_recalc.csv`). Table 5 percentages and totals exist only as pasted values (`R+R Tables.xlsx` 'Table 1+2+3'), so they are computed from the recalculated Ns and flagged in the notes.

## A6 path refactor (environment patch: data location), 2026-10-11
All data files of P04_CF now live under `D:/Data/ReplicateMe/P04_CF/` with the same relative paths (Amendment A6; moves logged in `registry/data_moves.csv`). Path-only edits; no original line and no analytic step changed.
- E1 header (`build_runs.sh` → all `run_*.do`): `global D` now points to the D: copy of `original/CF Mobility/Data`:
```diff
-global D "`c(pwd)'/../original/CF Mobility/Data"
+do "`c(pwd)'/../../tools/paths.do"
+global D "$DATA/P04_CF/original/CF Mobility/Data"
```
- E4 (`run_E_logit.do`): `origin_occ_group_share.dta` is saved to `$DATA/P04_CF/repro_original/output/`, and the run `cd`s there (instead of `output/`) so that l.383 `merge ... using origin_occ_group_share.dta` and the outreg2 `.xls` files stay on D:. After l.409 the three outreg2 `.txt` tables are copied back to `repro_original/output/` and the run returns to `repro_original/`.
- `recalc_census.R`, `repro_r/*.R`, `compare/s5_checks/*`, `modern/01–03`: read data and write `.dta`/`.rds`/scratch through `tools/paths.R` (`dpath()`, `dscratch()`); `s5_cluster.do` loads `tools/paths.do` and is run from `$DATA/P04_CF/compare/_scratch_s5`. Aggregate CSV/.tex/figure outputs stay in the project.
- Rerun after the refactor: all tracked outputs byte-identical; regenerated `.dta`/`.rds` identical in content (Stata/haven `.dta` headers differ only by timestamp).
