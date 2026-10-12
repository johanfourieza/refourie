# Card §4 check (c): independent closed-form re-implementation of the two anchors (no R, no S5 output).
import csv, math, sys
claims, out = sys.argv[1], sys.argv[2]
v = {r["claim_id"]: float(r["reported_value"]) for r in csv.DictReader(open(claims, encoding="utf-8")) if r["reported_value"] not in ("", "NA")}
GDP = v["T3_SS"] / (v["T3_pct"] / 100); a = v["T3_a"]; c = v["T3_c"]; pa = v["T3_f"] / a
phi = pa / (c / a); SS = a * pa - c
R = lambda e: (phi ** (1 - e) - 1) / ((1 - e) * (phi - 1))
pax = v["T6_b"] + v["T6_c"]
ak = {"lo": R(0.8) * SS + pax + v["T7_sp_hi"], "hi": R(0.5) * SS + pax + v["T7_sp_lo"]}
f = v["T8_d"] * v["T8_e"] / 100
bg = GDP * (1 - (1 + v["T8_g"] / 100) ** (-32)); gb = 100 * ((GDP / (GDP - v["T8_b"])) ** (1 / 32) - 1)
with open(out, "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["anchor", "k", "b_j", "g_j", "T"])
    for k in ("lo", "hi"):
        w.writerow(["A_g", k, repr(bg), repr(v["T8_g"]), repr(100 * ak[k] / bg + 100 * f / v["T8_g"])])
        w.writerow(["A_b", k, repr(v["T8_b"]), repr(gb), repr(100 * ak[k] / v["T8_b"] + 100 * f / gb)])
