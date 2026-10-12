# P07_FG S6: deviations from, and implementation notes on, the frozen method card

Card: `modern/method_card.md` v3, frozen at commit 17a056d. No analysis outside the card was added. There is no bootstrap (card §5), and the whole pipeline runs in under a minute. A clean rerun of scripts 01–06 reproduced every CSV in `output/` byte for byte. Every item below was fixed in the code before the verdict script was first run. No result informed any of them: each follows from the card's own constants or from the structure of the data.

**D1. Anchor-check tolerance (§4.3 check 3).** The card's divisors are the printed ratios 67.5 and 185.6. Botha's herd (Rds 3,375.2) therefore gives 3,375.2/67.5·λ = 50.003λ labourers, not exactly 50λ. Tas's herd (Rds 2,041.2) gives 2,041.2/185.6 = 10.998, not exactly 11. "Exactly" is applied as |L − target| ≤ 0.005, which is the rounding of the card's own constants. The largest gaps are 0.003 (Botha) and 0.0017 (Tas). All 16 + 4 checks pass.

**D2. Anchor identification and the FvF inputs.**
- Botha is the 1773 district-4 household with surname BOTHA and a herd value of 3,375.2 (±0.05). Tas is the 1709 district-2 household with surname TAS and a herd value of 2,041.2 (±0.05). Each rule matches exactly one row: Tas is Adam Tas, with 20 slaves, so a_Tas = ">5".
- The FvF (2011) Table 6/7 values (Gini 0.837/0.816/0.744; Theil 1.273, between 0.331, within 0.669 for 1757 prices; and the other two bases) are transcribed from `wiki/papers/JF_EtAl_AHistoryWith.md`. Before use, `04_theil.R` checks them against that file by string match.
- Only the 1757-prices column matches 'Inequality'!H3:J3, so a single basis is used (§4.4).

**D3. District 0 in sensitivity 9.** §4.1 says the productivity Totals cover districts 1–3. Sensitivity 9 ("published-run totals, district 0 kept") is meant to reproduce the published run, whose Totals include the district-0 household (C5). So for sensitivity 9 only, the Totals include district 0. It is reported for the central and the coded rule. Applying this rule to the coded rule reproduces the published T5 Total (−43.43%).

**D4. Scope of the sensitivities (implementation note).** As the card specifies:
- Sensitivity 5 (labour allocation) is applied to the central scenario and to 𝒜.
- Sensitivities 2–4 and 6–10 are applied to the central scenario only.
- Sensitivities 9 and 10 also report the coded rule, because that is the basis of the published numbers they are meant to recover.

Sensitivity 6 gives Cape households the divisor that the active S rule gives Drakenstein, including the household's own γ_c.

**D5. g_S in the coded sample (implementation note).** The card's disclosure (§7) quotes g_S ≈ 4.02, which uses the published 7,101 slaves in 1773 (district 0 kept). §3 defines g_S on the same sample as g_K (district 0 dropped: 222 → 7,062), which gives g_S = 4.010 and r_KS = 1.062. The card's definition is used.

**D6. λ crossings (implementation note).** These are found by uniroot on λ ∈ [0.05, 5], with other inputs central. g_K and r_KS do not depend on λ under S = text, so no crossing exists for I1a-mag or I1b.
