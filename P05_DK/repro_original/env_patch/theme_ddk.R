# [ENV P1] Minimal stand-in for de Kadt's personal ggplot theme (C:\Users\ddeka\Dropbox\theme_ddk.R, not recovered).
# None of the pipeline scripts call theme_ddk() for a claim-bearing output; the Table 1/3 figures use theme_bw() inline.
theme_ddk <- function(...) ggplot2::theme_bw(...)
