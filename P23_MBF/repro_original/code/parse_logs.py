"""Parse full-precision estimates from the S2 Stata logs into results_original.csv (and the A' file).
Run from the project root:  python P23_MBF/repro_original/code/parse_logs.py
Reads only aggregate regression output (coefficient tables); no microdata rows are involved."""
import csv, math, os, re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # P23_MBF/repro_original
LOGS = os.path.join(HERE, "logs")
NUM = r"(-?[0-9]*\.?[0-9]+(?:e[-+]?[0-9]+)?)"


def blocks(log, start_pat):
    """Split a log into estimation blocks that begin with a line matching start_pat."""
    txt = open(os.path.join(LOGS, log), encoding="utf-8", errors="replace").read().splitlines()
    idx = [i for i, l in enumerate(txt) if re.search(start_pat, l)]
    return [txt[a:b] for a, b in zip(idx, idx[1:] + [len(txt)])]


def row(block, name):
    for l in block:
        m = re.match(r"^\s*" + re.escape(name) + r"\s*\|\s+" + NUM + r"\s+" + NUM + r"\s+" + NUM + r"\s+" + NUM, l)
        if m:
            return float(m.group(1)), float(m.group(2)), float(m.group(4))
    return None


def scal(block, pat):
    for l in block:
        m = re.search(pat + r"\s*=\s*([0-9,\.]+)", l)
        if m:
            return float(m.group(1).replace(",", ""))
    return None


def clusters(block):
    for l in block:
        m = re.search(r"adjusted for ([0-9,]+) clusters in (\w+)", l)
        if m:
            return int(m.group(1).replace(",", "")), m.group(2)
    return None, None


def logit_rows(log, prefix, note, geo_counts, cl_note=True):
    out = []
    bl = [b for b in blocks(log, r"^Logistic regression") if scal(b, "Number of obs")]
    for j, b in enumerate(bl, start=1):
        n = scal(b, "Number of obs"); r2 = scal(b, "Pseudo R2"); k, cv = clusters(b)
        c = f"_c{j}"
        for nm, cid in [("d_birth", "br"), ("d_birth_be~p", "ia"), ("d_age_prim~f", "pi")]:
            r = row(b, nm)
            if r:
                out.append([f"{prefix}_{cid}{c}", r[0], r[1], n, "", f"{note}; p={r[2]:.4f}"])
        out += [[f"{prefix}_n{c}", n, "", n, "", note],
                [f"{prefix}_r2{c}", r2, "", n, "", note],
                [f"{prefix}_clus{c}", k, "", n, "", f"{note}; clusters in {cv}"],
                [f"{prefix}_ctrlind{c}", 5, "", "", "", "count of individual controls in the code (age i_age_age d_female d_christian rural)"],
                [f"{prefix}_ctrlgeo{c}", geo_counts[j - 1], "", "", "", "count of geographic controls in the code" +
                 ("; includes d_centraliz (9th control) although the table prints 8" if geo_counts[j - 1] == 9 else "")]]
    return out


rows = []
# ---- Table 2 (original code, exact match with authors' 2_micro.txt) ----
rows += logit_rows("run_t2.log", "T2", "run_t2.do (lines 44-104 of regression_analysis_220131.do); output identical to authors' 2_micro.txt", [0, 8, 0, 8])
# ---- Table 3 (original code: clusters on tribe_co_1) ----
t3 = logit_rows("run_t3.log", "T3", "run_t3.do (lines 282-356); original code clusters on tribe_co_1", [8, 8, 9, 9])
rows += t3

# ---- Table 4 (spatial GS2SLS) ----
sp = [b for b in blocks("run_t4.log", r"^\.\s+spregress") ]
assert len(sp) == 30, len(sp)
panels = ["yrschool"] * 10 + ["abcc"] * 10 + ["gini"] * 10
ctrl = {("abcc", 2): 9, ("abcc", 4): 9, ("gini", 4): 9, ("gini", 10): 9}
for i, b in enumerate(sp):
    p = panels[i]; c = i % 10 + 1
    n = scal(b, "Number of obs"); r2 = scal(b, "Pseudo R2")
    br = row(b, "d_birth_all"); rho = row(b, "e." + p)
    note = "run_t4.do (lines 128-1226 of spatial ...(no ethnic regression).do)" + (
        "; output identical to authors' 1_%s_all.txt" % p if p != "gini" else "; authors' surviving 1_gini_all.txt is an older d_lead_eth run")
    nctrl = 0 if c % 2 == 1 else ctrl.get((p, c), 8)
    rows += [[f"T4_{p}_br_c{c}", br[0], br[1], n, "", note + f"; p={br[2]:.4f}"],
             [f"T4_{p}_rho_c{c}", rho[0], rho[1], n, "", note + f"; p={rho[2]:.4f}"],
             [f"T4_{p}_n_c{c}", n, "", n, "", note],
             [f"T4_{p}_ctrl_c{c}", nctrl, "", "", "", "count of controls in the code" + ("; includes d_centraliz although the table prints 8" if nctrl == 9 else "")],
             [f"T4_{p}_r2_c{c}", r2, "", n, "", note]]

# ---- Table 5 (Murdock logit; original code = authors' 3_dbirthethnic.txt) ----
t5 = [b for b in blocks("run_t5.log", r"^Logistic regression") if scal(b, "Number of obs")]
for j, b in enumerate(t5, start=1):
    n = scal(b, "Number of obs"); r2 = scal(b, "Pseudo R2"); m = row(b, "d_mission")
    note = "run_t5.do (lines 484-535 of 1.4_leaders and murdock (not included).do); output identical to authors' 3_dbirthethnic.txt"
    rows += [[f"T5_mission_c{j}", m[0], m[1], n, "", note + f"; p={m[2]:.4f}"],
             [f"T5_n_c{j}", n, "", n, "", note], [f"T5_r2_c{j}", r2, "", n, "", note]]

# ---- text numbers derived from the original-code Table 2 col 4 ----
d = {r[0]: r for r in rows}
b1, b2 = d["T2_br_c4"][1], d["T2_ia_c4"][1]
rows += [["text_p1575_sum", b1 + b2, "", 5077010, "", "T2 col 4 Birth Region + interaction (original run)"],
         ["text_p1575_or", math.exp(b1 + b2), "", 5077010, "", "exp(T2 col 4 b1+b2) (original run)"],
         ["text_p1575_32pct", 100 * (math.exp(b2) - 1), "", 5077010, "", "100*(exp(interaction)-1), T2 col 4; the text's 32% equals exp(.28)-1"],
         ["text_p1563_countries", 11, "", 5077010, "", "country FE levels in the T2 logits (10 dummies + base)"],
         ["text_p1571_indiv", 5077010, "", 5077010, "", "T2 estimation N; text says 'more than 5 million' (threshold claim, satisfied)"]]
for cid in ["text_p1563_leaders", "text_p1572_6of11", "text_p1570_n623", "text_p1570_n201", "text_p1570_sd20",
            "text_fn15_sd_comb", "text_fn15_mean_comb", "text_fn15_sd_first", "text_fn15_mean_first",
            "text_p1579_max645", "text_p1579_min34", "text_fn1_thyolo40", "text_fn1_thyolo60"]:
    rows.append([cid, "", "", "", "unavailable", "no surviving original code output for this number within S2 scope"])
rows += [["text_p1592_bal_ids", 592, "", 1776, "ambiguous", "balanced panel built in run_t4.do (lines 227-251, xtdes) has 592 ids x 3 decades; appendix panel (633/1899) not produced by the Table 4 code"],
         ["text_p1592_bal_obs", 1776, "", 1776, "ambiguous", "592 x 3 from the same xtdes; see text_p1592_bal_ids"]]

# ---- Table 1: no code or output ----
claims = list(csv.DictReader(open(os.path.join(HERE, "..", "claims", "claims.csv"), encoding="utf-8")))
for c in claims:
    if c["claim_id"].startswith("T1_"):
        rows.append([c["claim_id"], "", "", "", "unavailable", "Table 1 has no generating code or output file (S1)"])

have = {r[0] for r in rows}
missing = [c["claim_id"] for c in claims if c["claim_id"] not in have]
assert not missing, missing


def write(path, rr):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["claim_id", "source", "value", "se", "n", "status_override", "note"])
        for r in rr:
            w.writerow([r[0], "original", *[("%.10g" % x) if isinstance(x, float) else x for x in r[1:4]], r[4], r[5]])


write(os.path.join(HERE, "results_original.csv"), rows)
print("results_original.csv:", len(rows), "rows")

# ---- A' alignment file: T3 with id_birth clusters; T5 cols 3-4 with the specification that matches print ----
ap = []
if os.path.exists(os.path.join(LOGS, "run_t3_Aprime.log")):
    ap += logit_rows("run_t3_Aprime.log", "T3", "A' run_t3_Aprime.do: vce(cluster id_birth) instead of tribe_co_1", [8, 8, 9, 9])
if os.path.exists(os.path.join(LOGS, "run_t5_Aprime.log")):
    t5a = [b for b in blocks("run_t5_Aprime.log", r"^Logistic regression") if scal(b, "Number of obs")]
    for j, b in zip([3, 4], t5a):
        n = scal(b, "Number of obs"); r2 = scal(b, "Pseudo R2"); m = row(b, "d_mission")
        note = "A' run_t5_Aprime.do: " + ("col 3 without meanalt" if j == 3 else "col 4 plus d_capital")
        ap += [[f"T5_mission_c{j}", m[0], m[1], n, "", note + f"; p={m[2]:.4f}"],
               [f"T5_n_c{j}", n, "", n, "", note], [f"T5_r2_c{j}", r2, "", n, "", note]]
apd = {r[0]: r for r in ap}
write(os.path.join(HERE, "results_original_Aprime.csv"), [apd.get(r[0], r) for r in rows])
print("results_original_Aprime.csv:", len(ap), "rows replaced")
