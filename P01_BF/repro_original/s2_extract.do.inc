* [ENV-extract] write all stored estimates to output/s2_estimates.csv (no analytic content)
file open fh using "$OUT/s2_estimates.csv", write replace
file write fh "model,term,b,se,n,stat" _n
foreach m in T6 L3 {
  local names : colnames S2_`m'_b
  local k = colsof(S2_`m'_b)
  forvalues j = 1/`k' {
    local t : word `j' of `names'
    file write fh "`m'_mfx,`t'," %20.12g (S2_`m'_b[1,`j']) "," %20.12g (S2_`m'_se[1,`j']) "," (S2_`m'_N) "," %12.8g (S2_`m'_r2p) _n
  }
}
foreach m in S2_lpm m1 {
  estimates restore `m'
  matrix B = e(b)
  matrix V = e(V)
  local names : colnames B
  local k = colsof(B)
  forvalues j = 1/`k' {
    local t : word `j' of `names'
    file write fh "`m',`t'," %20.12g (B[1,`j']) "," %20.12g (sqrt(V[`j',`j'])) "," (e(N)) "," %12.8g (e(r2)) _n
  }
}
file close fh
