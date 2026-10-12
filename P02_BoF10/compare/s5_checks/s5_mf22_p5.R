# S5 P02_BoF10: Tables 4-5 on the authors' surviving MF22 (CF, I(1)+drift) series, UECM with 4 lagged differences (p = 5); null size under same design
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(mFilter); library(here)})
source(here("tools","paths.R")); set.seed(20261013)
source(here("P02_BoF10","compare","s5_checks","uecm_fn.R"))
b <- dpath("P02_BoF10","original","Boshoff Fourie Ships","Business Cycle Cape Colony")
cz <- suppressWarnings(read_excel(file.path(b, "causality for med freq.XLS"), 1) |> mutate(across(everything(), as.numeric)))
cat("vars:", names(cz), "\n")
W <- "WHEATMF22"; S <- "SHIPSMF22"
P <- tribble(~id, ~dep, ~ind, ~pub,
 "T4_r1_F","SOWNCORRMF22",S,4.77, "T4_r2_F",S,"SOWNCORRMF22",3.60, "T4_r3_F",W,S,61.77, "T4_r4_F",S,W,91.67,
 "T4_r9_F","VINESMF22",S,6.05, "T4_r10_F",S,"VINESMF22",5.68, "T4_r11_F","WINEMF22",S,4.40, "T4_r12_F",S,"WINEMF22",1.16,
 "T4_r13_F","CATTLEMF22",S,0.54, "T4_r14_F",S,"CATTLEMF22",0.25,
 "T4_r9_F(totvines)","TOTALVINESMF22",S,6.05, "T4_r11_F(totwine)","TOTALWINEMF22",S,4.40,
 "T4_r9_F(vines2)","VINES2MF22",S,6.05, "T4_r11_F(wine2)","WINE2MF22",S,4.40,
 "T5_r1_coef",W,S,4.53, "T5_r2_coef",S,W,2.38, "T5_r7_coef","VINESMF22",S,1.46, "T5_r8_coef",S,"VINESMF22",0.44)
R <- P |> rowwise() |> mutate(as_tibble(as.list(uecm(cz[[dep]], cz[[ind]], 5)))) |> ungroup()
print(as.data.frame(R), digits = 4)
write_csv(R, here("P02_BoF10","compare","s5_checks","mf22_p5_tables45.csv"))
# null: independent RWs (with drift), CF I(1)+drift 12-40, p = 5, n = 93 / 85
nul <- function(n) { e <- matrix(rnorm(2*n), ncol = 2); f <- \(z) as.numeric(cffilter(cumsum(0.01 + z), 12, 40, root = TRUE, drift = TRUE)$cycle)
  uecm(f(e[,1]), f(e[,2]), 5)[c("F","theta")] }
N <- replicate(1000, nul(85))
cat("\nNULL (indep RW, authors' filter, p=5): median F", median(N[1,]), " q95", quantile(N[1,], .95), " q99", quantile(N[1,], .99),
    "\n P(F>4.01)", mean(N[1,] > 4.01), " P(F>24.77)", mean(N[1,] > 24.77), " P(F>61.77)", mean(N[1,] > 61.77), " P(|theta|>2.18)", mean(abs(N[1+1,]) > 2.18), "\n")
write_csv(tibble(F = N[1,], theta = N[2,]), here("P02_BoF10","compare","s5_checks","null_authors_filter_p5.csv"))
