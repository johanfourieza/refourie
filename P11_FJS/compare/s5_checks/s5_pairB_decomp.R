# P11_FJS S5: decompose the pair-B (independent R rebuild) gap in the top-decile shares, all Image 9 years.
# Steps start from the published construction (A1, workbook share) and switch one pair-B decision at a time.
suppressPackageStartupMessages({ library(tidyverse); library(haven) })
root <- "."; source(file.path(root, "tools", "paths.R"))
p11 <- file.path(root, "P11_FJS"); set.seed(20261011)
src <- new.env(); sys.source(file.path(p11, "compare/s5_checks/s5_scenarios.R"), envir = src)   # reuses imp_tax, shares
with(src, {
  img9 <- c(1700, 1719, 1731, 1738, 1741, 1757, 1773)
  B <- read_csv(file.path(p11, "repro_r/output/image9_top_decile_robustness.csv"), show_col_types = FALSE)
  pigs <- function(d) d |> mutate(poll = ifelse(vk > 0 & assets == 0, 0, poll), totaltax = poll + winetax + wheattax + meattax)
  steps <- list(
    "0 published (A1, wb share)"          = list(o = list(), m = "wb"),
    "1 + ten equal groups, random ties"   = list(o = list(), m = "rand"),
    "2 + grain on gross yield"            = list(o = list(grain = "gross"), m = "rand"),
    "3 + no 0.7 wine factor"              = list(o = list(grain = "gross", post_factor = 1), m = "rand"),
    "4 + no vine imputation"              = list(o = list(grain = "gross", post_factor = 1, wine_const = NA), m = "rand"),
    "5 + pigs exempt from poll tax"       = list(o = list(grain = "gross", post_factor = 1, wine_const = NA), m = "rand", pig = TRUE))
  out <- imap_dfr(steps, function(s, nm) {
    d <- do.call(imp_tax, c(list(base), s$o)); if (isTRUE(s$pig)) d <- pigs(d)
    f <- switch(s$m, wb = share_wb, rand = share_rand)
    tibble(step = nm, year = img9, share = map_dbl(img9, ~ f(d, .x)))
  })
  out <- bind_rows(out, tibble(step = "B  repro_r top_main", year = B$year, share = B$top_main)) |>
    mutate(share = round(share, 2)) |> pivot_wider(names_from = year, values_from = share)
  print(out, width = 200)
  write_csv(out, file.path(p11, "compare/s5_checks/s5_pairB_decomp.csv"))
})
