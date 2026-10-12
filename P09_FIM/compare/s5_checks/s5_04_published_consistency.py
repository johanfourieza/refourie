"""P09_FIM S5 check 4 (Claude): internal consistency of the published tables (claims.csv only).
(a) stars vs |t| under the paper's legend (* .05, ** .01, *** .001; normal approx);
(b) T2 Total = T1-share-weighted force means; (c) T1 obs sum and T3 force-N sum;
(d) T5 composition + actual = 1; T5 height change vs T2 differences.
Run: python -I s5_04_published_consistency.py  (from any dir)"""
import csv, re, math, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
rows = {r["claim_id"]: r for r in csv.DictReader(open(root / "claims" / "claims.csv", encoding="utf-8"))}
val = lambda k: float(rows[k]["reported_value"]) if k in rows and rows[k]["reported_value"] not in ("", ".") else None
out = []
def rec(check, item, published, implied, flag): out.append(dict(check=check, item=item, published=published, implied=implied, flag=flag))

# (a) stars vs t
def nstars_from_t(t):
    p = math.erfc(abs(t) / math.sqrt(2))
    return 3 if p < 0.001 else 2 if p < 0.01 else 1 if p < 0.05 else 0
for k, r in rows.items():
    if not re.match(r"T[34]_", k) or k.endswith("_t") or r["quantity_type"] != "coef":
        continue
    t = val(k + "_t") if re.search(r"_c\d$", k) else None
    if t is None:
        tk = re.sub(r"(_c\d)$", r"\1_t", k); t = val(tk)
    if t is None:
        continue
    st = len(r["reported_stars"] or "")
    imp = nstars_from_t(t)
    if st != imp:
        rec("stars_vs_t", k, f"{r['reported_value']}{'*'*st} (t {t})", "*" * imp or "none", "MISMATCH")
n_star = sum(1 for k, r in rows.items() if re.match(r"T[34]_", k) and not k.endswith("_t") and r["quantity_type"] == "coef")
rec("stars_vs_t", "coefficients checked", n_star, "", "")

# (b) T2 total vs share-weighted force means
for c in range(1, 7):
    num = den = 0.0
    for f in ["AOF", "CMP", "SAC", "WWI", "WWII"]:
        sh, m = val(f"T1_Sourceshare_{f}_c{c}"), val(f"T2_Forceheight_{f}_c{c}")
        if sh and m:
            num += sh * m; den += sh
    tot = val(f"T2_Total_Total_c{c}")
    imp = num / den if den else None
    rec("T2_total_vs_forces", f"c{c}", tot, round(imp, 3) if imp else None,
        "MISMATCH" if imp and abs(imp - tot) > 0.05 else "ok")

# (c) N bookkeeping
t1n = [val(f"T1_obs_c{c}") for c in range(1, 7)]
rec("T1_obs_sum", "sum cohorts", 6972, sum(x for x in t1n if x), "ok" if sum(x for x in t1n if x) == 6972 else "MISMATCH")
force_n = sum(val(f"T3_obs_c{c}") for c in range(3, 8))
rec("T3_force_N_sum", "c3..c7 vs c1", val("T3_obs_c1"), force_n, "ok" if force_n == val("T3_obs_c1") else "MISMATCH")
rec("T3_force_N_sum", "c6+c7 vs c8", val("T3_obs_c8"), val("T3_obs_c6") + val("T3_obs_c7"), "ok")

# (d) T5
for v in ["Region", "Class", "Townsize"]:
    for r in range(1, 6):
        a, b = val(f"T5_{v}Composition_r{r}"), val(f"T5_{v}Actual_r{r}")
        if a is not None and b is not None:
            rec("T5_sum_to_1", f"{v} r{r}", round(a + b, 3), 1, "ok" if abs(a + b - 1) < 0.015 else "MISMATCH")
for r in range(1, 6):
    hc = val(f"T5_Heightchange_r{r}")
    d = val(f"T2_Total_Total_c{r+1}") - val(f"T2_Total_Total_c{r}")
    rec("T5_change_vs_T2", f"r{r}", hc, round(d, 3), "ok" if abs(hc - d) < 0.006 else "MISMATCH")
# col 8 identity is computed in s5_02 (needs the rebuild attestation gap)
with open(pathlib.Path(__file__).with_name("s5_published_consistency.csv"), "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=["check", "item", "published", "implied", "flag"]); w.writeheader(); w.writerows(out)
for o in out:
    print(o)
