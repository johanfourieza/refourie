# S5 C13/C14: column headers and formulas in Census_1911_occupations.xlsx 'Occupations Sub-Orders'
suppressMessages({library(tidyxl); library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
f <- dpath("P04_CF", "original", "CF Mobility", "Results latest", "Census_1911_occupations.xlsx")
x <- xlsx_cells(f, sheets="Occupations Sub-Orders")
hdr <- x |> filter(row <= 7) |> mutate(v=coalesce(character, as.character(numeric))) |> filter(!is.na(v)) |> select(address, v)
print(as.data.frame(hdr))
q <- x |> filter(col >= 15, !is.na(formula)) |> select(address, formula, numeric)
print(as.data.frame(q))
lab <- x |> filter(col <= 3, row >= 8, row <= 100) |> mutate(v=coalesce(character, as.character(numeric))) |> filter(!is.na(v)) |> select(address, v)
write.csv(lab, dpath("P04_CF", "compare", "_scratch_s5", "census1911_rowlabels.csv"), row.names=FALSE)
## Corrected column references: Q5 with E (European male urban) instead of D; Q15 with G (non-European male urban) instead of F
val <- function(cc, rows) { adr <- paste0(cc, rows); z <- x |> filter(address %in% adr); sum(z$numeric, na.rm=TRUE) }
D <- val("D", 41:44); E <- val("E", 41:44); J <- val("J", 41:44)
cat("D41:44 =", D, " E41:44 =", E, " J41:44 =", J, "\n")
rq15 <- c(61,62,64,66,67,68,70,71,72,74,75,77,78,79,81)
Fv <- val("F", rq15); Gv <- val("G", rq15); Gfull <- val("G", c(61:64,66:68,70:72,74,75,77:81)); Lv <- val("L", c(61:64,66:68,70:72,74,75,77:81))
cat("F(rows of Q15) =", Fv, " G(same rows) =", Gv, " G(Q6 row set) =", Gfull, " L =", Lv, "\n")
Q <- c(W=144648, F=236057, S=93945, U=18912); N <- c(W=59975, F=912152, S=84346, U=132802)
Qc <- Q; Qc["F"] <- Q["F"] - D + E
Nc <- N; Nc["S"] <- N["S"] - Fv + Gv
Nc2 <- N; Nc2["S"] <- Lv + Gfull
pr <- function(v) round(100*v/sum(v), 1)
cat("T4 c2 published:", pr(Q), " corrected (Q5 fix):", pr(Qc), "\n")
cat("T5 white N corrected:", Qc, " total", sum(Qc), "\n")
cat("T5 non-European N corrected (Q15 fix):", Nc, " total", sum(Nc), "\n")
cat("T5 non-European N corrected (Q15 fix, Q6 row set):", Nc2, "\n")
cat("non-white share of farmers: published", round(100*N["F"]/(N["F"]+Q["F"]),1), " corrected", round(100*N["F"]/(N["F"]+Qc["F"]),1), "\n")
cat("non-white share of skilled: published", round(100*N["S"]/(N["S"]+Q["S"]),1), " corrected", round(100*Nc["S"]/(Nc["S"]+Q["S"]),1), "\n")
cat("SAF 1887-1909 vs census farmer gap: published 49.7 vs", pr(Q)["F"], "; corrected", pr(Qc)["F"], "\n")
cat("header check: D41 == E41+F41+G41+H41:", val("D",41) == sum(sapply(c("E","F","G","H"), val, rows=41)),
    "; I41 == J41+K41+L41+M41:", val("I",41) == sum(sapply(c("J","K","L","M"), val, rows=41)), "\n")
